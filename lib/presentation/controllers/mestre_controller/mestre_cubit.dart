import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/combate/combatente.dart';
import '../../../domain/entities/combate/grid_tatico.dart';
import '../../../domain/entities/combate/monstro.dart';
import '../../../domain/entities/mestre/catalogo_mestre_padrao.dart';
import '../../../domain/entities/mestre/modelos_mestre.dart';
import '../../../domain/entities/entidade_sessao_lan/sessao_lan_modelos.dart';
import '../../../domain/services/combate_services/movimento_engine.dart';
import '../../../domain/services/data_services/call_ameacas.dart';
import '../../../domain/services/data_services/mestre_storage_service.dart';
import '../../../domain/services/sessao_lan/sessao_lan_transport.dart';
import 'mestre_state.dart';

class MestreCubit extends Cubit<MestreState> {
  static const int maxLogsRedeLan = 50;
  static const Duration _intervaloCoalescingSnapshotLan = Duration(
    milliseconds: 50,
  );
  static const Duration _debouncePersistenciaPadrao = Duration(
    milliseconds: 250,
  );
  static const Duration _debouncePersistenciaMapa = Duration(
    milliseconds: 800,
  );

  final bool _autoPersistir;
  Timer? _timerPersistencia;
  Timer? _timerSnapshotLan;
  MapaBatalhaMestre? _mapaPendenteSnapshotLan;
  bool _ultimaMudancaEhEdicaoMapa = false;
  bool _hidratando = false;
  bool _pendenciaSalvar = false;

  SessaoHostService? _hostService;
  StreamSubscription<SolicitacaoEntradaSessao>? _solicitacoesLanSub;
  StreamSubscription<AtualizacaoPersonagemSessao>? _atualizacoesLanSub;
  StreamSubscription<Map<String, dynamic>>? _acoesMapaLanSub;
  StreamSubscription<String>? _desconexoesLanSub;
  final Map<String, Map<String, dynamic>> _snapshotsFichasLan = {};

  MestreCubit({bool autoPersistir = true, SessaoHostService? sessaoHostService})
    : _autoPersistir = autoPersistir,
      super(_criarEstadoInicial()) {
    if (sessaoHostService != null) {
      vincularSessaoHostService(sessaoHostService);
    }
    if (_autoPersistir) {
      unawaited(carregarDoDisco());
    }
  }

  List<String> _anexarLogRedeLan(String mensagem) {
    final lista = [...state.logsRedeLan, mensagem];
    if (lista.length <= maxLogsRedeLan) return lista;
    return lista.sublist(lista.length - maxLogsRedeLan);
  }

  void _agendarPublicacaoSnapshotLan(MapaBatalhaMestre mapa) {
    if (_hostService == null || state.statusLan == StatusConexaoLan.desligado) {
      return;
    }
    _mapaPendenteSnapshotLan = mapa;
    if (_timerSnapshotLan?.isActive ?? false) return;
    _timerSnapshotLan = Timer(
      _intervaloCoalescingSnapshotLan,
      _despacharSnapshotLanPendente,
    );
  }

  void _despacharSnapshotLanPendente() {
    _timerSnapshotLan = null;
    final mapa = _mapaPendenteSnapshotLan;
    _mapaPendenteSnapshotLan = null;
    if (isClosed ||
        mapa == null ||
        _hostService == null ||
        state.statusLan == StatusConexaoLan.desligado) {
      return;
    }
    unawaited(
      _hostService!.publicarSnapshotMesa(
        SnapshotMesa.sanitizadoDeMapa(mapa),
      ),
    );
  }

  /// Vincula ou troca o transporte host LAN consumido pelo Painel do Mestre.
  void vincularSessaoHostService(SessaoHostService? host) {
    unawaited(_solicitacoesLanSub?.cancel());
    unawaited(_atualizacoesLanSub?.cancel());
    unawaited(_acoesMapaLanSub?.cancel());
    unawaited(_desconexoesLanSub?.cancel());
    _hostService = host;
    if (host == null) return;
    _solicitacoesLanSub = host.solicitacoesEntrada.listen(
      (solicitacao) => receberSolicitacaoEntradaLan(solicitacao),
    );
    _atualizacoesLanSub = host.atualizacoesPersonagem.listen(
      aplicarAtualizacaoPersonagemLan,
    );
    _acoesMapaLanSub = host.acoesMapa.listen(aplicarAcaoMapaJogadorLan);
    _desconexoesLanSub = host.desconexoesCliente.listen(
      marcarJogadorDesconectadoLan,
    );
    unawaited(() async {
      final ip = await host.descobrirIpLocal();
      if (!isClosed && ip != null && ip.isNotEmpty && ip != state.ipHostLocal) {
        emit(state.copyWith(ipHostLocal: ip));
      }
    }());
  }

  /// Snapshot completo da ficha enviado pelo jogador via LAN (se disponível).
  Map<String, dynamic>? obterSnapshotFichaJogador(String characterId) =>
      _snapshotsFichasLan[characterId];

  static final Random _random = Random();
  int _idSeq = 0;

  String _nextId(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch}_${++_idSeq}';

  @override
  void onChange(Change<MestreState> change) {
    super.onChange(change);
    final ehEdicaoMapa = _ultimaMudancaEhEdicaoMapa;
    _ultimaMudancaEhEdicaoMapa = false;
    if (!_autoPersistir || _hidratando || !MestreStorageService.podePersistir) {
      return;
    }
    _pendenciaSalvar = true;
    _timerPersistencia?.cancel();
    _timerPersistencia = Timer(
      ehEdicaoMapa ? _debouncePersistenciaMapa : _debouncePersistenciaPadrao,
      () => unawaited(salvarAgora()),
    );
  }

  @override
  Future<void> close() async {
    await _solicitacoesLanSub?.cancel();
    await _atualizacoesLanSub?.cancel();
    await _acoesMapaLanSub?.cancel();
    await _desconexoesLanSub?.cancel();
    _timerSnapshotLan?.cancel();
    _timerSnapshotLan = null;
    _mapaPendenteSnapshotLan = null;
    _timerPersistencia?.cancel();
    if (_autoPersistir && _pendenciaSalvar) {
      await salvarAgora();
    }
    return super.close();
  }

  /// Carrega o último estado salvo do Mestre e mescla ameaças customizadas.
  Future<void> carregarDoDisco() async {
    final snap = await MestreStorageService.carregar();
    if (snap == null || isClosed) return;

    _hidratando = true;
    try {
      BancoDeAmeacas.mesclarCustomizadas(snap.ameacasCustomizadas);
      final temCampanhas = snap.campanhas.isNotEmpty;
      emit(
        state.copyWith(
          campanhas: snap.campanhas,
          limparSelecaoContexto: true,
          campanhaSelecionadaId: temCampanhas
              ? snap.campanhaSelecionadaId
              : null,
          aventuraSelecionadaId: temCampanhas
              ? snap.aventuraSelecionadaId
              : null,
          sessaoSelecionadaId: temCampanhas ? snap.sessaoSelecionadaId : null,
          mapaSelecionadoId: temCampanhas ? snap.mapaSelecionadoId : null,
          perigos: snap.perigos ?? state.perigos,
          historicoNomes: snap.historicoNomes,
          nomeGeradoAtual: snap.nomeGeradoAtual,
          nomesFavoritos: snap.nomesFavoritos,
          limparTokenSelecionado: true,
          celulasAlcancaveisToken: const {},
          custosMovimentoToken: const {},
          revisaoBestiario: state.revisaoBestiario + 1,
        ),
      );
      _pendenciaSalvar = false;
    } finally {
      _hidratando = false;
    }
  }

  /// Persiste imediatamente o estado atual do Mestre e suas ameaças customizadas.
  Future<void> salvarAgora() async {
    _timerPersistencia?.cancel();
    _pendenciaSalvar = false;
    await MestreStorageService.salvar(
      MestreEstadoPersistido(
        campanhas: state.campanhas,
        campanhaSelecionadaId: state.campanhaSelecionadaId,
        aventuraSelecionadaId: state.aventuraSelecionadaId,
        sessaoSelecionadaId: state.sessaoSelecionadaId,
        mapaSelecionadoId: state.mapaSelecionadoId,
        perigos: state.perigos,
        historicoNomes: state.historicoNomes,
        nomeGeradoAtual: state.nomeGeradoAtual,
        nomesFavoritos: state.nomesFavoritos,
        ameacasCustomizadas: BancoDeAmeacas.customizadas,
      ),
    );
  }

  /// Cria ou atualiza uma ameaça customizada do Mestre no catálogo e persiste.
  Monstro salvarAmeacaCustomizada(Monstro monstro) {
    final idFinal = monstro.id.trim().isEmpty
        ? _nextId('custom_ameaca')
        : monstro.id.trim();
    final normalizado = Monstro(
      id: idFinal,
      nome: monstro.nome.trim(),
      nd: monstro.nd,
      regiao: monstro.regiao,
      papel: monstro.papel,
      tipoCriatura: monstro.tipoCriatura,
      subtipo: monstro.subtipo,
      tamanho: monstro.tamanho,
      pvMax: monstro.pvMax,
      pmMax: monstro.pmMax,
      defesa: monstro.defesa,
      deslocamentoMetros: monstro.deslocamentoMetros,
      deslocamentos: monstro.deslocamentos,
      iniciativa: monstro.iniciativa,
      percepcao: monstro.percepcao,
      sentidos: monstro.sentidos,
      fortitude: monstro.fortitude,
      reflexos: monstro.reflexos,
      vontade: monstro.vontade,
      rd: monstro.rd,
      imunidadesEfeitos: monstro.imunidadesEfeitos,
      imunidadesDano: monstro.imunidadesDano,
      vulnerabilidadesDano: monstro.vulnerabilidadesDano,
      habilidadesDefensivas: monstro.habilidadesDefensivas,
      modForca: monstro.modForca,
      modDestreza: monstro.modDestreza,
      modConstituicao: monstro.modConstituicao,
      modInteligencia: monstro.modInteligencia,
      modSabedoria: monstro.modSabedoria,
      modCarisma: monstro.modCarisma,
      forcaNula: monstro.forcaNula,
      destrezaNula: monstro.destrezaNula,
      constituicaoNula: monstro.constituicaoNula,
      pericias: monstro.pericias,
      ataques: monstro.ataques,
      habilidades: monstro.habilidades,
      equipamento: monstro.equipamento,
      tesouro: monstro.tesouro,
      recursoExtraivel: monstro.recursoExtraivel,
      customizado: true,
    );
    BancoDeAmeacas.adicionarOuAtualizarCustomizada(normalizado);
    emit(state.copyWith(revisaoBestiario: state.revisaoBestiario + 1));
    return normalizado;
  }

  /// Remove uma ameaça customizada do catálogo e atualiza a persistência.
  void excluirAmeacaCustomizada(String id) {
    BancoDeAmeacas.removerCustomizada(id);
    emit(state.copyWith(revisaoBestiario: state.revisaoBestiario + 1));
  }

  static MestreState _criarEstadoInicial() {
    // Conjunto de células inicialmente reveladas no mapa de exemplo
    final reveladasIniciais = <Posicao2D>{};
    for (int y = 0; y < 8; y++) {
      for (int x = 0; x < 7; x++) {
        reveladasIniciais.add(Posicao2D(x, y));
      }
    }

    final mapaInicial = MapaBatalhaMestre(
      id: 'mapa_1',
      nome: 'Ruínas da Estrada de Yuvalin',
      largura: 12,
      altura: 8,
      presetFundo: PresetFundoMapa.florestaArton,
      terrenos: {
        const Posicao2D(4, 2): TipoTerreno.obstaculo,
        const Posicao2D(4, 3): TipoTerreno.obstaculo,
        const Posicao2D(5, 4): TipoTerreno.dificil,
        const Posicao2D(5, 5): TipoTerreno.dificil,
        const Posicao2D(8, 1): TipoTerreno.obstaculo,
        const Posicao2D(8, 2): TipoTerreno.obstaculo,
      },
      celulasReveladas: reveladasIniciais,
      tokens: const [
        TokenNoMapa(
          id: 'tok_ameaca_1',
          nome: 'Batedor Purista',
          posicao: Posicao2D(9, 4),
          ehHeroi: false,
          tipo: TipoCombatenteMapa.inimigo,
          pvAtual: 24,
          pvMax: 24,
          pmAtual: 6,
          pmMax: 6,
          defesa: 16,
          deslocamentoMetros: 9.0,
          visibilidade: SomenteMestre(),
        ),
      ],
    );

    final sessaoInicial = SessaoJogo(
      id: 'sessao_1',
      numero: 1,
      titulo: 'Sessão #01 — Emboscada na Estrada Real',
      objetivoResumo:
          'Os heróis escoltam a caravana até Yuvalin e precisam atravessar as ruínas antigas.',
      mapaAtivoId: 'mapa_1',
      codigoSalaLan: 'T20-7492',
      checklistNotas: const [
        ItemChecklistNota(
          id: 'chk_1',
          texto: 'Apresentar a caravana e o comerciante Thalon',
          concluido: true,
        ),
        ItemChecklistNota(
          id: 'chk_2',
          texto: 'Emboscada dos batedores puristas na curva do rio',
          concluido: false,
        ),
        ItemChecklistNota(
          id: 'chk_3',
          texto: 'Pistas sobre a mina abandonada no norte',
          concluido: false,
        ),
      ],
      notasSessaoTexto:
          'Clima úmido e chuvoso. Visibilidade média. O líder dos puristas possui um broche com o símbolo do Deus da Guerra.',
      elenco: const [],
    );

    final aventuraInicial = AventuraMestre(
      id: 'av_1',
      nome: 'Ato I: O Segredo das Minas',
      sinopse:
          'Investigações sobre contrabando de aço-rubi nos arredores da guilda de mineradores.',
      sessoes: [sessaoInicial],
      mapas: [
        mapaInicial,
        MapaBatalhaMestre(
          id: 'mapa_2',
          nome: 'Taverna do Javali Dourado',
          largura: 10,
          altura: 8,
          presetFundo: PresetFundoMapa.tavernaMadeira,
          celulasReveladas: reveladasIniciais,
        ),
      ],
      notas: [
        NotaMestre(
          id: 'nota_1',
          titulo: 'Segredo do Capataz Ezequias',
          conteudo:
              'Ezequias guarda uma chave de bronze no bolso interno. CD 20 de Percepção ou Ladinagem para notar.',
          visibilidade: const SomenteMestre(),
          atualizadoEm: DateTime(2026, 11, 7),
        ),
        NotaMestre(
          id: 'nota_2',
          titulo: 'Rumor da Cidade: A Caravana Perdida',
          conteudo:
              'A Guilda Mercante oferece 200 T\$ por informações sobre o carregamento desaparecido no norte.',
          visibilidade: const ParaTodos(),
          atualizadoEm: DateTime(2026, 11, 7),
        ),
      ],
      handouts: const [
        HandoutMestre(
          id: 'hand_1',
          titulo: 'Carta Selada da Guilda',
          descricao:
              'Pergaminho com o selo de Yuvalin autorizando a passagem pelos portões leste.',
          entregueAosJogadores: true,
          lidoPorJogadores: ['Lucas', 'Mariana'],
        ),
      ],
    );

    final campanhaInicial = CampanhaMestre(
      id: 'camp_1',
      nome: 'Coração de Rubi',
      descricao:
          'Jornada épica através de Arton contra a corrupção da Tormenta.',
      patamar: 'Iniciante (Nível 1 a 4)',
      aventuras: [aventuraInicial],
      mapas: aventuraInicial.mapas,
    );

    return MestreState(
      campanhas: [campanhaInicial],
      campanhaSelecionadaId: campanhaInicial.id,
      aventuraSelecionadaId: aventuraInicial.id,
      sessaoSelecionadaId: sessaoInicial.id,
      mapaSelecionadoId: mapaInicial.id,
      perigos: CatalogoMestrePadrao.perigosPadraoT20,
      logsRedeLan: const [
        '[Sistema] Painel do Mestre inicializado (Modo Offline / Preparação).',
      ],
    );
  }

  // ===========================================================================
  // 1. HIERARQUIA: CAMPANHA -> AVENTURA -> SESSÃO
  // ===========================================================================

  /// Gera um código curto de sala LAN no formato `T20-XXXX`.
  String gerarCodigoLanSugerido() => 'T20-${1000 + _random.nextInt(8999)}';

  /// Normaliza um código de sala para o formato `T20-XXXX` quando informados
  /// apenas 4 dígitos (`7492`) ou `T207492` sem hífen.
  static String normalizarCodigoLan(String raw) =>
      CodigoSalaLan.normalizar(raw);

  /// Retorna o código LAN efetivo da sessão/campanha ativa normalizado.
  String get codigoSalaLanAtivo {
    final sesCodigo = state.sessaoAtual?.codigoSalaLan.trim();
    if (sesCodigo != null && sesCodigo.isNotEmpty) {
      return normalizarCodigoLan(sesCodigo);
    }
    final campCodigo = state.campanhaAtual?.codigoConexaoLan?.trim();
    if (campCodigo != null && campCodigo.isNotEmpty) {
      return normalizarCodigoLan(campCodigo);
    }
    return 'T20-0000';
  }

  Future<void> _sincronizarHostLanAtivo() async {
    if (_hostService == null || state.statusLan == StatusConexaoLan.desligado) {
      return;
    }
    final codigoSala = codigoSalaLanAtivo;
    final ipDetectado = await _hostService!.descobrirIpLocal();
    final ipFinal = (ipDetectado != null && ipDetectado.isNotEmpty)
        ? ipDetectado
        : state.ipHostLocal;
    if (!isClosed && ipFinal != state.ipHostLocal) {
      emit(
        state.copyWith(
          ipHostLocal: ipFinal,
          logsRedeLan: _anexarLogRedeLan(
            '🌐 [Host LAN] IP local detectado: $ipFinal:${state.portaHostLan}.',
          ),
        ),
      );
    }
    await _hostService!.iniciar(
      ip: ipFinal,
      porta: state.portaHostLan,
      codigoSala: codigoSala,
    );
    final mapa = state.mapaAtual;
    if (mapa != null) {
      await _hostService!.publicarSnapshotMesa(
        SnapshotMesa.sanitizadoDeMapa(mapa),
      );
    }
  }

  /// Envia um mapa para o acervo da campanha (adiciona ou atualiza pelo id).
  void enviarMapaParaCampanha({
    required String campanhaId,
    required MapaBatalhaMestre mapa,
  }) {
    final camp = state.campanhas.where((c) => c.id == campanhaId).firstOrNull;
    if (camp == null) return;

    final existe = camp.mapas.any((m) => m.id == mapa.id);
    final mapasAtualizados = existe
        ? camp.mapas.map((m) => m.id == mapa.id ? mapa : m).toList()
        : [...camp.mapas, mapa];

    emit(
      state.copyWith(
        campanhas: _substituirCampanha(camp.copyWith(mapas: mapasAtualizados)),
      ),
    );
  }

  /// Convida/registra um jogador diretamente na campanha para uso nas sessões.
  void convidarJogadorCampanha({
    required String campanhaId,
    required String nomeJogador,
    String nomePersonagem = '',
    String classeResumo = 'Aventureiro Nv 1',
  }) {
    final camp = state.campanhas.where((c) => c.id == campanhaId).firstOrNull;
    final jogador = nomeJogador.trim();
    if (camp == null || jogador.isEmpty) return;

    final heroi = nomePersonagem.trim().isEmpty
        ? jogador
        : nomePersonagem.trim();
    final novo = ElencoSessaoEntry(
      characterId: _nextId('chr'),
      nomePersonagem: heroi,
      nomeJogador: jogador,
      classeResumo: classeResumo,
      statusRevisao: StatusRevisaoFicha.aprovada,
      pvAtual: 20,
      pvMax: 20,
      pmAtual: 6,
      pmMax: 6,
    );

    emit(
      state.copyWith(
        campanhas: _substituirCampanha(
          camp.copyWith(
            jogadoresConvidados: [...camp.jogadoresConvidados, novo],
          ),
        ),
      ),
    );
  }

  /// Remove um jogador convidado da campanha.
  void removerJogadorCampanha({
    required String campanhaId,
    required String characterId,
  }) {
    final camp = state.campanhas.where((c) => c.id == campanhaId).firstOrNull;
    if (camp == null) return;

    emit(
      state.copyWith(
        campanhas: _substituirCampanha(
          camp.copyWith(
            jogadoresConvidados: camp.jogadoresConvidados
                .where((j) => j.characterId != characterId)
                .toList(),
          ),
        ),
      ),
    );
  }

  /// Ativa a sessão escolhida, vincula os jogadores convidados da campanha e
  /// prepara o mapa selecionado da campanha para jogar na Mesa de Jogo.
  void abrirSessaoComMapa({
    required String campanhaId,
    required String aventuraId,
    required String sessaoId,
    String? mapaId,
  }) {
    final camp = state.campanhas.where((c) => c.id == campanhaId).firstOrNull;
    if (camp == null) return;
    final av = camp.aventuras.where((a) => a.id == aventuraId).firstOrNull;
    if (av == null) return;
    final ses = av.sessoes.where((s) => s.id == sessaoId).firstOrNull;
    if (ses == null) return;

    var mapasAv = av.mapas;
    if (mapaId != null && !mapasAv.any((m) => m.id == mapaId)) {
      final mapaCampanha = camp.mapas.where((m) => m.id == mapaId).firstOrNull;
      if (mapaCampanha != null) {
        mapasAv = [...mapasAv, mapaCampanha];
      }
    }

    final idsElenco = ses.elenco.map((e) => e.characterId).toSet();
    final elencoAtualizado = [
      ...ses.elenco,
      ...camp.jogadoresConvidados.where(
        (j) => !idsElenco.contains(j.characterId),
      ),
    ];

    final sesAtualizada = ses.copyWith(
      mapaAtivoId: mapaId ?? ses.mapaAtivoId,
      elenco: elencoAtualizado,
    );
    final avAtualizada = av.copyWith(
      mapas: mapasAv,
      sessoes: av.sessoes
          .map((s) => s.id == sessaoId ? sesAtualizada : s)
          .toList(),
    );
    final campAtualizada = camp.copyWith(
      aventuras: camp.aventuras
          .map((a) => a.id == aventuraId ? avAtualizada : a)
          .toList(),
    );

    emit(
      state.copyWith(
        campanhas: _substituirCampanha(campAtualizada),
        campanhaSelecionadaId: campanhaId,
        aventuraSelecionadaId: aventuraId,
        sessaoSelecionadaId: sessaoId,
        mapaSelecionadoId: mapaId ?? state.mapaSelecionadoId,
      ),
    );
    unawaited(_sincronizarHostLanAtivo());
  }

  void selecionarCampanha(String campanhaId) {
    final camp = state.campanhas.where((c) => c.id == campanhaId).firstOrNull;
    if (camp == null) return;
    final primAventura = camp.aventuras.firstOrNull;
    final primSessao = primAventura?.sessoes.firstOrNull;
    final primMapa = primAventura?.mapas.firstOrNull;

    emit(
      state.copyWith(
        campanhaSelecionadaId: camp.id,
        aventuraSelecionadaId: primAventura?.id,
        sessaoSelecionadaId: primSessao?.id,
        mapaSelecionadoId: primSessao?.mapaAtivoId ?? primMapa?.id,
        limparSelecaoContexto: true,
        limparTokenSelecionado: true,
        celulasAlcancaveisToken: const {},
      ),
    );
    unawaited(_sincronizarHostLanAtivo());
  }

  CampanhaMestre criarCampanha({
    required String nome,
    String descricao = '',
    String patamar = 'Iniciante (Nível 1 a 4)',
    String? codigoConexaoLan,
    bool criarEstruturaPadrao = true,
  }) {
    final id = _nextId('camp');
    final codigoNormalizado = normalizarCodigoLan(codigoConexaoLan ?? '');
    final codigoFinal =
        codigoNormalizado.isEmpty ? null : codigoNormalizado;

    if (!criarEstruturaPadrao) {
      final novaCampanha = CampanhaMestre(
        id: id,
        nome: nome.trim().isEmpty ? 'Nova Campanha T20' : nome.trim(),
        descricao: descricao.trim(),
        patamar: patamar,
        codigoConexaoLan: codigoFinal,
        aventuras: const [],
      );

      emit(
        state.copyWith(
          campanhas: [...state.campanhas, novaCampanha],
          campanhaSelecionadaId: novaCampanha.id,
          aventuraSelecionadaId: null,
          sessaoSelecionadaId: null,
          mapaSelecionadoId: null,
          limparSelecaoContexto: true,
          limparTokenSelecionado: true,
          celulasAlcancaveisToken: const {},
        ),
      );
      return novaCampanha;
    }

    final avId = _nextId('av');
    final sesId = _nextId('ses');
    final mapId = _nextId('map');

    final reveladas = <Posicao2D>{
      for (int y = 0; y < 8; y++)
        for (int x = 0; x < 10; x++) Posicao2D(x, y),
    };

    final novoMapa = MapaBatalhaMestre(
      id: mapId,
      nome: 'Mapa Principal',
      largura: 10,
      altura: 8,
      celulasReveladas: reveladas,
    );

    final novaSessao = SessaoJogo(
      id: sesId,
      numero: 1,
      titulo: 'Sessão #01 — Início da Jornada',
      objetivoResumo: 'Reunir o grupo e introduzir o gancho da aventura.',
      mapaAtivoId: mapId,
      codigoSalaLan: codigoFinal ?? gerarCodigoLanSugerido(),
    );

    final novaAventura = AventuraMestre(
      id: avId,
      nome: 'Aventura 1: O Chamado',
      sinopse: descricao,
      sessoes: [novaSessao],
      mapas: [novoMapa],
    );

    final novaCampanha = CampanhaMestre(
      id: id,
      nome: nome.trim().isEmpty ? 'Nova Campanha T20' : nome.trim(),
      descricao: descricao.trim(),
      patamar: patamar,
      codigoConexaoLan: codigoFinal,
      aventuras: [novaAventura],
    );

    emit(
      state.copyWith(
        campanhas: [...state.campanhas, novaCampanha],
        campanhaSelecionadaId: novaCampanha.id,
        aventuraSelecionadaId: novaAventura.id,
        sessaoSelecionadaId: novaSessao.id,
        mapaSelecionadoId: novoMapa.id,
      ),
    );
    return novaCampanha;
  }

  void selecionarAventura(String aventuraId) {
    final camp = state.campanhaAtual;
    if (camp == null) return;
    final av = camp.aventuras.where((a) => a.id == aventuraId).firstOrNull;
    if (av == null) return;
    final primSessao = av.sessoes.firstOrNull;
    final primMapa = av.mapas.firstOrNull;

    emit(
      state.copyWith(
        campanhaSelecionadaId: camp.id,
        aventuraSelecionadaId: av.id,
        sessaoSelecionadaId: primSessao?.id,
        mapaSelecionadoId: primSessao?.mapaAtivoId ?? primMapa?.id,
        limparSelecaoContexto: true,
        limparTokenSelecionado: true,
        celulasAlcancaveisToken: const {},
      ),
    );
    unawaited(_sincronizarHostLanAtivo());
  }

  AventuraMestre? criarAventura({
    String? campanhaId,
    required String nome,
    String sinopse = '',
    bool criarSessaoPadrao = true,
  }) {
    final camp = campanhaId != null
        ? state.campanhas.where((c) => c.id == campanhaId).firstOrNull
        : state.campanhaAtual;
    if (camp == null) return null;

    final avId = _nextId('av');

    if (!criarSessaoPadrao) {
      final novaAv = AventuraMestre(
        id: avId,
        nome: nome.trim().isEmpty ? 'Nova Aventura' : nome.trim(),
        sinopse: sinopse.trim(),
        sessoes: const [],
        mapas: const [],
      );
      final campanhas = _substituirCampanha(
        camp.copyWith(aventuras: [...camp.aventuras, novaAv]),
      );
      emit(
        state.copyWith(
          campanhas: campanhas,
          campanhaSelecionadaId: camp.id,
          aventuraSelecionadaId: novaAv.id,
          sessaoSelecionadaId: null,
          mapaSelecionadoId: null,
          limparSelecaoContexto: true,
          limparTokenSelecionado: true,
          celulasAlcancaveisToken: const {},
        ),
      );
      return novaAv;
    }

    final sesId = _nextId('ses');
    final mapId = _nextId('map');

    final reveladas = <Posicao2D>{
      for (int y = 0; y < 8; y++)
        for (int x = 0; x < 10; x++) Posicao2D(x, y),
    };

    final novoMapa = MapaBatalhaMestre(
      id: mapId,
      nome: 'Mapa Tático 1',
      largura: 10,
      altura: 8,
      celulasReveladas: reveladas,
    );

    final novaSessao = SessaoJogo(
      id: sesId,
      numero: 1,
      titulo: 'Sessão #01 — ${nome.trim()}',
      objetivoResumo: sinopse.trim(),
      mapaAtivoId: mapId,
      codigoSalaLan: camp.codigoConexaoLan ?? gerarCodigoLanSugerido(),
    );

    final novaAv = AventuraMestre(
      id: avId,
      nome: nome.trim().isEmpty ? 'Nova Aventura' : nome.trim(),
      sinopse: sinopse.trim(),
      sessoes: [novaSessao],
      mapas: [novoMapa],
    );

    final campanhas = _substituirCampanha(
      camp.copyWith(aventuras: [...camp.aventuras, novaAv]),
    );
    emit(
      state.copyWith(
        campanhas: campanhas,
        campanhaSelecionadaId: camp.id,
        aventuraSelecionadaId: novaAv.id,
        sessaoSelecionadaId: novaSessao.id,
        mapaSelecionadoId: novoMapa.id,
      ),
    );
    return novaAv;
  }

  void selecionarSessao(String sessaoId) {
    final av = state.aventuraAtual;
    if (av == null) return;
    final ses = av.sessoes.where((s) => s.id == sessaoId).firstOrNull;
    if (ses == null) return;

    emit(
      state.copyWith(
        sessaoSelecionadaId: ses.id,
        mapaSelecionadoId: ses.mapaAtivoId ?? state.mapaSelecionadoId,
      ),
    );
    unawaited(_sincronizarHostLanAtivo());
  }

  SessaoJogo? criarSessao({
    String? campanhaId,
    String? aventuraId,
    required String titulo,
    String objetivoResumo = '',
  }) {
    final camp = campanhaId != null
        ? state.campanhas.where((c) => c.id == campanhaId).firstOrNull
        : state.campanhaAtual;
    if (camp == null) return null;

    final av = aventuraId != null
        ? camp.aventuras.where((a) => a.id == aventuraId).firstOrNull
        : state.aventuraAtual;
    if (av == null) return null;

    final proximoNumero = av.sessoes.length + 1;
    final novaSessao = SessaoJogo(
      id: _nextId('ses'),
      numero: proximoNumero,
      titulo: titulo.trim().isEmpty ? 'Sessão #$proximoNumero' : titulo.trim(),
      objetivoResumo: objetivoResumo.trim(),
      mapaAtivoId: av.mapas.firstOrNull?.id,
      elenco: av.sessoes.lastOrNull?.elenco ?? const [],
      codigoSalaLan: camp.codigoConexaoLan ?? gerarCodigoLanSugerido(),
    );

    final avAtualizada = av.copyWith(sessoes: [...av.sessoes, novaSessao]);
    final campAtualizada = camp.copyWith(
      aventuras: camp.aventuras
          .map((a) => a.id == av.id ? avAtualizada : a)
          .toList(),
    );

    emit(
      state.copyWith(
        campanhas: _substituirCampanha(campAtualizada),
        campanhaSelecionadaId: camp.id,
        aventuraSelecionadaId: av.id,
        sessaoSelecionadaId: novaSessao.id,
      ),
    );
    return novaSessao;
  }

  // ===========================================================================
  // 2. FRONTEND DE CONEXÃO LAN E CONVITE DE JOGADORES (ADR-004 UI + RF-M1)
  // ===========================================================================

  void alternarServidorLan() {
    final novoStatus = state.statusLan == StatusConexaoLan.desligado
        ? StatusConexaoLan.aguardandoJogadores
        : StatusConexaoLan.desligado;

    final codigoSala = codigoSalaLanAtivo;
    final logMsg = novoStatus == StatusConexaoLan.aguardandoJogadores
        ? '📡 [Host LAN] Sala aberta em ${state.ipHostLocal}:${state.portaHostLan} (Código: $codigoSala).'
        : '🔌 [Host LAN] Sala encerrada pelo Mestre.';

    if (novoStatus == StatusConexaoLan.desligado) {
      _timerSnapshotLan?.cancel();
      _timerSnapshotLan = null;
      _mapaPendenteSnapshotLan = null;
    }

    emit(
      state.copyWith(
        statusLan: novoStatus,
        logsRedeLan: _anexarLogRedeLan(logMsg),
      ),
    );

    if (_hostService != null) {
      if (novoStatus == StatusConexaoLan.aguardandoJogadores) {
        unawaited(_sincronizarHostLanAtivo());
      } else {
        unawaited(_hostService!.encerrar());
      }
    }
  }

  void gerarNovoCodigoSalaLan() {
    final ses = state.sessaoAtual;
    if (ses == null) return;
    final novoCodigo = 'T20-${1000 + _random.nextInt(8999)}';
    var campanhas = _substituirSessao(
      ses.copyWith(codigoSalaLan: novoCodigo),
    );
    if (campanhas == null) return;
    final campAtual = state.campanhaAtual;
    if (campAtual != null &&
        campAtual.codigoConexaoLan != null &&
        campAtual.codigoConexaoLan!.isNotEmpty) {
      campanhas = campanhas
          .map(
            (c) => c.id == campAtual.id
                ? c.copyWith(codigoConexaoLan: novoCodigo)
                : c,
          )
          .toList();
    }
    emit(
      state.copyWith(
        campanhas: campanhas,
        logsRedeLan: _anexarLogRedeLan(
          '🔑 Novo código PIN da sala gerado: $novoCodigo.',
        ),
      ),
    );
    unawaited(_sincronizarHostLanAtivo());
  }

  /// Recebe uma [SolicitacaoEntradaSessao] real ou via Loopback e coloca no
  /// elenco com status [StatusRevisaoFicha.pendente] para aprovação do Mestre.
  void receberSolicitacaoEntradaLan(
    SolicitacaoEntradaSessao solicitacao, {
    String? ipJogador,
  }) {
    final ses = state.sessaoAtual;
    if (ses == null) return;

    final codigoRecebido = normalizarCodigoLan(solicitacao.codigoSala);
    final codigoSessao = normalizarCodigoLan(ses.codigoSalaLan);
    final codigoCampanha = normalizarCodigoLan(
      state.campanhaAtual?.codigoConexaoLan ?? '',
    );
    if (codigoRecebido != codigoSessao &&
        (codigoCampanha.isEmpty || codigoRecebido != codigoCampanha)) {
      return;
    }

    if (solicitacao.snapshotPersonagem != null) {
      _snapshotsFichasLan[solicitacao.characterId] =
          solicitacao.snapshotPersonagem!;
    }

    final ipFinal = ipJogador ?? solicitacao.ipRemoto ?? 'LAN';
    final entrada = solicitacao.toElencoEntry(
      statusRevisao: StatusRevisaoFicha.pendente,
      conectadoViaLan: true,
      ipJogador: ipFinal,
    );

    final existe = ses.elenco.any((e) => e.characterId == entrada.characterId);
    final novoElenco = existe
        ? ses.elenco
              .map((e) => e.characterId == entrada.characterId ? entrada : e)
              .toList()
        : [...ses.elenco, entrada];

    final campanhas = _substituirSessao(ses.copyWith(elenco: novoElenco));
    if (campanhas == null) return;

    emit(
      state.copyWith(
        campanhas: campanhas,
        logsRedeLan: _anexarLogRedeLan(
          '📩 [JOIN / LAN] ${entrada.nomeJogador} ($ipFinal) enviou a ficha "${entrada.nomePersonagem}" (Aguardando Revisão RF-M1).',
        ),
      ),
    );
  }

  /// Marca um jogador como desconectado no elenco quando o socket LAN cai ou fecha.
  void marcarJogadorDesconectadoLan(String characterId) {
    final ses = state.sessaoAtual;
    if (ses == null) return;

    final alvo = ses.elenco
        .where((e) => e.characterId == characterId)
        .firstOrNull;
    if (alvo == null || !alvo.conectadoViaLan) return;

    final novoElenco = ses.elenco
        .map(
          (e) => e.characterId == characterId
              ? e.copyWith(conectadoViaLan: false)
              : e,
        )
        .toList();

    final campanhas = _substituirSessao(ses.copyWith(elenco: novoElenco));
    if (campanhas == null) return;

    emit(
      state.copyWith(
        campanhas: campanhas,
        logsRedeLan: _anexarLogRedeLan(
          '🔌 [LAN] ${alvo.nomePersonagem} (${alvo.nomeJogador}) desconectou da sala.',
        ),
      ),
    );
  }

  /// Aplica atualização de PV/PM/Defesa enviada pelo Jogador conectado via LAN.
  void aplicarAtualizacaoPersonagemLan(AtualizacaoPersonagemSessao dto) {
    final ses = state.sessaoAtual;
    if (ses == null) return;

    final novoElenco = ses.elenco.map((e) {
      if (e.characterId != dto.characterId) return e;
      return e.copyWith(
        pvAtual: dto.pvAtual,
        pvMax: dto.pvMax,
        pmAtual: dto.pmAtual,
        pmMax: dto.pmMax,
        defesa: dto.defesa,
      );
    }).toList();

    final campanhas = _substituirSessao(ses.copyWith(elenco: novoElenco));
    if (campanhas != null) {
      emit(state.copyWith(campanhas: campanhas));
    }

    final mapa = state.mapaAtual;
    if (mapa == null) return;
    final temToken = mapa.tokens.any((t) => t.id == dto.characterId);
    if (!temToken) return;

    final novosTokens = mapa.tokens.map((t) {
      if (t.id != dto.characterId) return t;
      return t.copyWith(
        pvAtual: dto.pvAtual.clamp(0, dto.pvMax),
        pvMax: dto.pvMax,
        pmAtual: dto.pmAtual.clamp(0, dto.pmMax),
        pmMax: dto.pmMax,
        defesa: dto.defesa,
        iniciativa: dto.iniciativa ?? t.iniciativa,
        condicoes: dto.condicoes ?? t.condicoes,
      );
    }).toList();

    _atualizarMapaAtual(mapa.copyWith(tokens: novosTokens));
  }

  /// RF-M1: Aprova, solicita alterações ou recusa a ficha de um jogador da sessão.
  void atualizarStatusRevisaoFicha(
    String characterId,
    StatusRevisaoFicha novoStatus, {
    String? notaRevisao,
  }) {
    final ses = state.sessaoAtual;
    if (ses == null) return;

    ElencoSessaoEntry? heroiAprovado;
    final novoElenco = ses.elenco.map((e) {
      if (e.characterId == characterId) {
        final atualizado = e.copyWith(
          statusRevisao: novoStatus,
          notaRevisao: notaRevisao,
        );
        if (novoStatus == StatusRevisaoFicha.aprovada) {
          heroiAprovado = atualizado;
        }
        return atualizado;
      }
      return e;
    }).toList();

    _atualizarSessaoAtual(ses.copyWith(elenco: novoElenco));

    if (heroiAprovado != null) {
      adicionarHeroiNoMapa(heroiAprovado!);
    }

    if (_hostService != null) {
      unawaited(
        _hostService!.notificarRevisaoFicha(
          characterId,
          novoStatus,
          notaRevisao: notaRevisao,
        ),
      );
      final mapa = state.mapaAtual;
      if (mapa != null && state.statusLan != StatusConexaoLan.desligado) {
        unawaited(
          _hostService!.publicarSnapshotMesa(
            SnapshotMesa.sanitizadoDeMapa(mapa),
          ),
        );
      }
    }
  }

  /// Envia uma nota do Mestre para o jogador conectado via LAN sem alterar seu status de aprovação.
  void enviarNotaParaJogadorLan(String characterId, String nota) {
    final ses = state.sessaoAtual;
    if (ses == null) return;
    final notaLimpa = nota.trim();
    if (notaLimpa.isEmpty) return;

    ElencoSessaoEntry? alvo;
    final novoElenco = ses.elenco.map((e) {
      if (e.characterId == characterId) {
        alvo = e.copyWith(notaRevisao: notaLimpa);
        return alvo!;
      }
      return e;
    }).toList();

    if (alvo == null) return;
    _atualizarSessaoAtual(ses.copyWith(elenco: novoElenco));
    if (_hostService != null) {
      unawaited(
        _hostService!.notificarRevisaoFicha(
          characterId,
          alvo!.statusRevisao,
          notaRevisao: notaLimpa,
        ),
      );
    }
  }

  void removerPersonagemDaSessao(String characterId) {
    final ses = state.sessaoAtual;
    if (ses == null) return;
    _atualizarSessaoAtual(
      ses.copyWith(
        elenco: ses.elenco.where((e) => e.characterId != characterId).toList(),
      ),
    );
  }

  // ===========================================================================
  // 3. MAPAS DE BATALHA, IMAGEM DE FUNDO E MOVIMENTAÇÃO NO GRID (RF-M6, RF-M7)
  // ===========================================================================

  void selecionarMapa(String mapaId) {
    final ses = state.sessaoAtual;
    final campanhas = ses != null
        ? _substituirSessao(ses.copyWith(mapaAtivoId: mapaId))
        : null;
    emit(
      state.copyWith(
        campanhas: campanhas,
        mapaSelecionadoId: mapaId,
        limparTokenSelecionado: true,
        celulasAlcancaveisToken: const {},
        custosMovimentoToken: const {},
      ),
    );
    final mapa = state.mapaAtual;
    if (mapa != null &&
        _hostService != null &&
        state.statusLan != StatusConexaoLan.desligado) {
      unawaited(
        _hostService!.publicarSnapshotMesa(
          SnapshotMesa.sanitizadoDeMapa(mapa),
        ),
      );
    }
  }

  void criarMapa({
    required String nome,
    required int largura,
    required int altura,
    PresetFundoMapa preset = PresetFundoMapa.masmorraPedra,
    String? imagemCaminhoLocal,
    double opacidadeGrid = 0.35,
    bool gridVisivel = true,
    double ajusteOffsetX = 0.0,
    double ajusteOffsetY = 0.0,
    double ajusteEscala = 1.0,
    double ajusteRotacaoGraus = 0.0,
    String? corFundoHex,
    String notas = '',
    bool comecarComTudoOculto = false,
  }) {
    final av = state.aventuraAtual;
    if (av == null) return;

    final id = _nextId('map');
    final l = largura.clamp(4, 30);
    final a = altura.clamp(4, 30);

    final reveladas = comecarComTudoOculto
        ? const <Posicao2D>{}
        : <Posicao2D>{
            for (int y = 0; y < a; y++)
              for (int x = 0; x < l; x++) Posicao2D(x, y),
          };

    // Posiciona automaticamente o elenco aprovado da sessão atual no novo mapa
    final tokensIniciais = <TokenNoMapa>[];
    final elenco = state.sessaoAtual?.elenco ?? const [];
    int idxY = 1;
    for (final e in elenco.where(
      (el) => el.statusRevisao == StatusRevisaoFicha.aprovada,
    )) {
      tokensIniciais.add(
        TokenNoMapa(
          id: e.characterId,
          nome: e.nomePersonagem,
          posicao: Posicao2D(1, idxY.clamp(0, a - 1)),
          ehHeroi: true,
          pvAtual: e.pvAtual,
          pvMax: e.pvMax,
          deslocamentoMetros: e.deslocamentoMetros,
          visibilidade: const ParaTodos(),
        ),
      );
      idxY++;
    }

    final novoMapa = MapaBatalhaMestre(
      id: id,
      nome: nome.trim().isEmpty ? 'Novo Mapa Tático' : nome.trim(),
      largura: l,
      altura: a,
      presetFundo: imagemCaminhoLocal != null
          ? PresetFundoMapa.imagemCustomizada
          : preset,
      imagemCaminhoLocal: imagemCaminhoLocal,
      opacidadeGrid: opacidadeGrid.clamp(0.05, 1.0),
      gridVisivel: gridVisivel,
      ajusteOffsetX: ajusteOffsetX,
      ajusteOffsetY: ajusteOffsetY,
      ajusteEscala: ajusteEscala,
      ajusteRotacaoGraus: ajusteRotacaoGraus,
      corFundoHex: corFundoHex,
      notas: notas.trim(),
      celulasReveladas: reveladas,
      tokens: tokensIniciais,
    );

    _atualizarAventuraAtual(
      av.copyWith(mapas: [...av.mapas, novoMapa]),
      mapaSelecionadoId: novoMapa.id,
    );
    final camp = state.campanhaAtual;
    if (camp != null) {
      enviarMapaParaCampanha(campanhaId: camp.id, mapa: novoMapa);
    }
  }

  void definirImagemFundoMapa(String caminhoImagem) {
    final mapa = state.mapaAtual;
    if (mapa == null) return;
    _atualizarMapaAtual(
      mapa.copyWith(
        imagemCaminhoLocal: caminhoImagem,
        presetFundo: PresetFundoMapa.imagemCustomizada,
      ),
    );
  }

  void selecionarFerramentaMapa(FerramentaMapaMestre ferramenta) {
    emit(
      state.copyWith(
        ferramentaMapa: ferramenta,
        limparTokenSelecionado: true,
        celulasAlcancaveisToken: const {},
      ),
    );
  }

  /// RF-M7: Alterna entre a Visão do Mestre e o Preview "Ver como Jogador".
  void alternarVisaoMestreJogador() {
    final novoPapel = state.estaEmPreviewJogador
        ? const VisaoMestre()
        : const VisaoMestreComoJogador();
    emit(state.copyWith(papelVisualizacao: novoPapel));
  }

  void adicionarHeroiNoMapa(ElencoSessaoEntry heroi, {Posicao2D? posicao}) {
    final mapa = state.mapaAtual;
    if (mapa == null) return;

    final jaExiste = mapa.tokens.any((t) => t.id == heroi.characterId);
    if (jaExiste && posicao == null) return;

    final posFinal =
        posicao ??
        Posicao2D(1, (mapa.tokens.length + 1).clamp(0, mapa.altura - 1));

    final novoToken = TokenNoMapa(
      id: heroi.characterId,
      nome: heroi.nomePersonagem,
      posicao: posFinal,
      ehHeroi: true,
      tipo: TipoCombatenteMapa.heroi,
      pvAtual: heroi.pvAtual,
      pvMax: heroi.pvMax,
      pmAtual: heroi.pmAtual,
      pmMax: heroi.pmMax,
      defesa: heroi.defesa,
      deslocamentoMetros: heroi.deslocamentoMetros,
      visibilidade: const ParaTodos(),
    );

    final novosTokens = [
      ...mapa.tokens.where((t) => t.id != heroi.characterId),
      novoToken,
    ];

    _atualizarMapaAtual(mapa.copyWith(tokens: novosTokens));
  }

  void adicionarTokenCustomizadoNoMapa({
    required String nome,
    required bool ehHeroi,
    required int pvMax,
    int pmMax = 10,
    int defesa = 15,
    int? iniciativa,
    int tamanhoQuadrados = 1,
    TipoCombatenteMapa? tipo,
    bool ocultoParaJogadores = false,
    Posicao2D? posicao,
    int quantidade = 1,
  }) {
    final mapa = state.mapaAtual;
    if (mapa == null || quantidade <= 0) return;

    final nomeBase = nome.trim().isEmpty ? 'Combatente' : nome.trim();
    final basePos =
        posicao ??
        Posicao2D(
          ehHeroi ? 2 : (mapa.largura - 2).clamp(0, mapa.largura - 1),
          (mapa.tokens.length + 1).clamp(0, mapa.altura - 1),
        );
    final baseX = basePos.x.clamp(0, mapa.largura - 1);
    final baseY = basePos.y.clamp(0, mapa.altura - 1);
    final tipoFinal =
        tipo ??
        (ehHeroi ? TipoCombatenteMapa.heroi : TipoCombatenteMapa.inimigo);
    final visFinal = ocultoParaJogadores
        ? const SomenteMestre()
        : const ParaTodos();

    final novosTokens = <TokenNoMapa>[];
    for (int i = 0; i < quantidade; i++) {
      final linearX = baseX + i;
      final px = linearX % mapa.largura;
      final py = (baseY + linearX ~/ mapa.largura) % mapa.altura;
      novosTokens.add(
        TokenNoMapa(
          id: _nextId('tok'),
          nome: quantidade > 1 ? '$nomeBase #${i + 1}' : nomeBase,
          posicao: Posicao2D(px, py),
          ehHeroi: ehHeroi,
          tipo: tipoFinal,
          pvAtual: pvMax,
          pvMax: pvMax,
          pmAtual: pmMax,
          pmMax: pmMax,
          defesa: defesa,
          iniciativa: iniciativa,
          tamanhoQuadrados: tamanhoQuadrados,
          visibilidade: visFinal,
        ),
      );
    }

    _atualizarMapaAtual(
      mapa.copyWith(tokens: [...mapa.tokens, ...novosTokens]),
    );
  }

  /// Adiciona uma ou mais instâncias de uma ameaça do Bestiário vinculadas à sua ficha [Monstro].
  void adicionarAmeacaNoMapa(
    Monstro monstro, {
    Posicao2D? posicao,
    bool ocultoParaJogadores = true,
    int quantidade = 1,
  }) {
    final mapa = state.mapaAtual;
    if (mapa == null || quantidade <= 0) return;

    final combatenteBase = CombatenteMonstro.doMonstro(monstro);
    final span = monstro.tamanhoQuadrados.clamp(1, mapa.largura);
    final maxX = (mapa.largura - span).clamp(0, mapa.largura - 1);
    final maxY = (mapa.altura - span).clamp(0, mapa.altura - 1);
    final basePos =
        posicao ??
        Posicao2D(
          (mapa.largura - span - 1).clamp(0, maxX),
          (mapa.tokens.length + 1).clamp(0, maxY),
        );
    final visFinal = ocultoParaJogadores
        ? const SomenteMestre()
        : const ParaTodos();

    final novosTokens = <TokenNoMapa>[];
    for (int i = 0; i < quantidade; i++) {
      final px = (basePos.x + i).clamp(0, maxX);
      final py = (basePos.y + ((basePos.x + i) > maxX ? 1 : 0)).clamp(0, maxY);
      novosTokens.add(
        TokenNoMapa(
          id: _nextId('tok_mon'),
          nome: quantidade > 1 ? '${monstro.nome} #${i + 1}' : monstro.nome,
          posicao: Posicao2D(px, py),
          ehHeroi: false,
          tipo: TipoCombatenteMapa.inimigo,
          pvAtual: monstro.pvMax,
          pvMax: monstro.pvMax,
          pmAtual: monstro.pmMax,
          pmMax: monstro.pmMax,
          defesa: monstro.defesa,
          tamanhoQuadrados: monstro.tamanhoQuadrados,
          iniciativa: monstro.iniciativa,
          deslocamentoMetros: combatenteBase.deslocamentoMetros,
          visibilidade: visFinal,
          monstroId: monstro.id,
          monstro: monstro,
        ),
      );
    }

    _atualizarMapaAtual(
      mapa.copyWith(tokens: [...mapa.tokens, ...novosTokens]),
    );
  }

  /// RF-M7: Revela ou oculta um token específico no mapa para os jogadores.
  void alternarVisibilidadeToken(String tokenId) {
    final mapa = state.mapaAtual;
    if (mapa == null) return;

    final novosTokens = mapa.tokens.map((t) {
      if (t.id == tokenId) {
        final novaVis = t.visivelParaJogadores
            ? const SomenteMestre()
            : const ParaTodos();
        return t.copyWith(visibilidade: novaVis);
      }
      return t;
    }).toList();

    _atualizarMapaAtual(mapa.copyWith(tokens: novosTokens));
  }

  void removerTokenDoMapa(String tokenId) {
    final mapa = state.mapaAtual;
    if (mapa == null) return;
    final restantes = mapa.tokens.where((t) => t.id != tokenId).toList();
    String? proximoTurno = mapa.tokenTurnoAtualId;
    var limparTurno = false;
    if (mapa.tokenTurnoAtualId == tokenId) {
      if (restantes.isEmpty) {
        proximoTurno = null;
        limparTurno = true;
      } else {
        final ordenados = ordenarTokensPorIniciativa(mapa.tokens);
        final idx = ordenados.indexWhere((t) => t.id == tokenId);
        final candidatas = ordenados.where((t) => t.id != tokenId).toList();
        proximoTurno =
            candidatas[idx >= 0 && idx < candidatas.length ? idx : 0].id;
      }
    }
    final campanhas = _substituirMapa(
      mapa.copyWith(
        tokens: restantes,
        tokenTurnoAtualId: proximoTurno,
        limparTurnoAtual: limparTurno,
      ),
    );
    if (campanhas == null) return;
    final limparSel = state.tokenSelecionadoParaMoverId == tokenId;
    emit(
      state.copyWith(
        campanhas: campanhas,
        limparTokenSelecionado: limparSel,
        celulasAlcancaveisToken: limparSel ? const {} : null,
        custosMovimentoToken: limparSel ? const {} : null,
      ),
    );
  }

  /// Seleciona um token no mapa e calcula seu alcance tático usando `MovimentoEngine` (R73).
  void aoClicarTokenNoMapa(TokenNoMapa token) {
    final mapa = state.mapaAtual;
    if (mapa == null) return;

    if (state.tokenSelecionadoParaMoverId == token.id) {
      emit(
        state.copyWith(
          limparTokenSelecionado: true,
          celulasAlcancaveisToken: const {},
          custosMovimentoToken: const {},
        ),
      );
      return;
    }

    // Se estiver em modo Movimento Livre do Mestre, todas as células livres são válidas
    if (state.movimentoLivreMestre) {
      final ocupadas = mapa.tokens.map((t) => t.posicao).toSet();
      final todasLivres = <Posicao2D>{
        for (int y = 0; y < mapa.altura; y++)
          for (int x = 0; x < mapa.largura; x++)
            if (!ocupadas.contains(Posicao2D(x, y))) Posicao2D(x, y),
      };
      emit(
        state.copyWith(
          ferramentaMapa: FerramentaMapaMestre.moverPersonagens,
          tokenSelecionadoParaMoverId: token.id,
          celulasAlcancaveisToken: todasLivres,
          custosMovimentoToken: const {},
        ),
      );
      return;
    }

    // Cálculo tático oficial T20 via MovimentoEngine
    final posicoes = <String, Posicao2D>{
      for (final t in mapa.tokens) t.id: t.posicao,
    };
    final combatentes = <String, Combatente>{
      for (final t in mapa.tokens)
        t.id: t.monstro != null
            ? CombatenteMonstro.doMonstro(
                t.monstro!,
                idInstancia: t.id,
                time: t.ehHeroi ? TimeCombatente.heroi : TimeCombatente.inimigo,
                pvAtual: t.pvAtual,
                pmAtual: t.pmAtual,
              )
            : Combatente(
                id: t.id,
                nome: t.nome,
                time: t.ehHeroi ? TimeCombatente.heroi : TimeCombatente.inimigo,
                pvMax: t.pvMax,
                pvAtual: t.pvAtual,
                pmMax: t.pmMax,
                pmAtual: t.pmAtual,
                defesa: t.defesa,
                deslocamentoMetros: t.deslocamentoMetros,
                modIniciativa: t.iniciativa ?? 0,
                modLuta: 0,
                modPontaria: 0,
                modPercepcao: 0,
                modForca: 0,
                modDestreza: 0,
                modConstituicao: 0,
              ),
    };

    final resultado = MovimentoEngine.calcularAlcancaveis(
      mapa: mapa.comoGridMapa,
      inicio: token.posicao,
      deslocamentoMaximoMetros: token.deslocamentoMetros,
      posicoesCombatentes: posicoes,
      combatentesPorId: combatentes,
      combatenteAtivoId: token.id,
    );

    emit(
      state.copyWith(
        ferramentaMapa: FerramentaMapaMestre.moverPersonagens,
        tokenSelecionadoParaMoverId: token.id,
        celulasAlcancaveisToken: resultado.destinosValidos,
        custosMovimentoToken: resultado.custosMetros,
      ),
    );
  }

  /// Interação principal ao tocar em uma célula $(x, y)$ do Grid de Batalha.
  /// Move um token para [novaPos] respeitando os limites do grid e obstáculos.
  void moverToken(String tokenId, Posicao2D novaPos) {
    final mapa = state.mapaAtual;
    if (mapa == null) return;
    if (novaPos.x < 0 ||
        novaPos.y < 0 ||
        novaPos.x >= mapa.largura ||
        novaPos.y >= mapa.altura) {
      return;
    }

    final token = mapa.tokens.where((t) => t.id == tokenId).firstOrNull;
    if (token == null) return;

    final ocupadas = novaPos.celulasOcupadas(token.tamanhoQuadrados);
    final foraOuBloqueado = ocupadas.any(
      (c) =>
          c.x < 0 ||
          c.y < 0 ||
          c.x >= mapa.largura ||
          c.y >= mapa.altura ||
          mapa.terrenos[c] == TipoTerreno.obstaculo,
    );
    if (foraOuBloqueado) return;

    final novosTokens = mapa.tokens
        .map((t) => t.id == tokenId ? t.copyWith(posicao: novaPos) : t)
        .toList();
    _atualizarMapaAtual(mapa.copyWith(tokens: novosTokens));
  }

  /// Processa ações de mapa enviadas por um jogador via LAN após validação de identidade no Host.
  /// Valida de forma autoritativa: aprovação, Fog of War, colisão com outros tokens e alcance (MovimentoEngine).
  void aplicarAcaoMapaJogadorLan(Map<String, dynamic> acao) {
    final tipo = acao['tipo']?.toString();
    final charId = acao['characterId']?.toString();
    if (tipo != 'mover' || charId == null || charId.isEmpty) return;

    final x = (acao['x'] as num?)?.toInt();
    final y = (acao['y'] as num?)?.toInt();
    if (x == null || y == null) return;

    final ses = state.sessaoAtual;
    final aprovado = ses?.elenco.any(
          (e) =>
              e.characterId == charId &&
              e.statusRevisao == StatusRevisaoFicha.aprovada,
        ) ??
        false;
    if (!aprovado) return;

    final mapa = state.mapaAtual;
    if (mapa == null) return;
    final token = mapa.tokens.where((t) => t.id == charId).firstOrNull;
    if (token == null) return;

    final destino = Posicao2D(x, y);
    if (destino == token.posicao) return;

    // 1. Não permite mover para célula fora dos limites ou sob Névoa de Guerra
    final celulasDestino = destino.celulasOcupadas(token.tamanhoQuadrados);
    final invalidaOuOculta = celulasDestino.any(
      (c) =>
          c.x < 0 ||
          c.y < 0 ||
          c.x >= mapa.largura ||
          c.y >= mapa.altura ||
          !mapa.celulasReveladas.contains(c) ||
          mapa.terrenos[c] == TipoTerreno.obstaculo,
    );
    if (invalidaOuOculta) return;

    // 2. Validação de colisão com outros tokens presentes no mapa
    final celulasOcupadasPorOutros = <Posicao2D>{
      for (final outro in mapa.tokens)
        if (outro.id != token.id)
          ...outro.posicao.celulasOcupadas(outro.tamanhoQuadrados),
    };
    if (celulasDestino.any(celulasOcupadasPorOutros.contains)) return;

    // 3. Validação autoritativa de alcance pelo MovimentoEngine
    final posicoes = <String, Posicao2D>{
      for (final t in mapa.tokens) t.id: t.posicao,
    };
    final combatentes = <String, Combatente>{
      for (final t in mapa.tokens)
        t.id: Combatente(
          id: t.id,
          nome: t.nome,
          time: t.ehHeroi ? TimeCombatente.heroi : TimeCombatente.inimigo,
          pvMax: t.pvMax,
          pvAtual: t.pvAtual,
          pmMax: t.pmMax,
          pmAtual: t.pmAtual,
          defesa: t.defesa,
          deslocamentoMetros: t.deslocamentoMetros,
          modIniciativa: t.iniciativa ?? 0,
          modLuta: 0,
          modPontaria: 0,
          modPercepcao: 0,
          modForca: 0,
          modDestreza: 0,
          modConstituicao: 0,
        ),
    };

    final resultado = MovimentoEngine.calcularAlcancaveis(
      mapa: mapa.comoGridMapa,
      inicio: token.posicao,
      deslocamentoMaximoMetros: token.deslocamentoMetros,
      posicoesCombatentes: posicoes,
      combatentesPorId: combatentes,
      combatenteAtivoId: token.id,
    );
    if (!resultado.destinosValidos.contains(destino)) return;

    moverToken(charId, destino);
  }

  void aoClicarCelulaMapa(Posicao2D pos, {bool? fogModoRevelar}) {
    final mapa = state.mapaAtual;
    if (mapa == null) return;

    switch (state.ferramentaMapa) {
      case FerramentaMapaMestre.moverPersonagens:
        final tokenId = state.tokenSelecionadoParaMoverId;
        if (tokenId == null) {
          // Se clicou numa célula onde há um token, seleciona esse token
          final tokNaCelula = mapa.tokens
              .where(
                (t) =>
                    t.posicao.celulasOcupadas(t.tamanhoQuadrados).contains(pos),
              )
              .firstOrNull;
          if (tokNaCelula != null) {
            aoClicarTokenNoMapa(tokNaCelula);
          }
          return;
        }

        final podeMover =
            state.movimentoLivreMestre ||
            state.celulasAlcancaveisToken.contains(pos);
        if (!podeMover) return;

        final novosTokens = mapa.tokens.map((t) {
          if (t.id == tokenId) {
            return t.copyWith(posicao: pos);
          }
          return t;
        }).toList();

        final mapaMovido = mapa.copyWith(tokens: novosTokens);
        final campanhas = _substituirMapa(mapaMovido);
        if (campanhas == null) return;
        emit(
          state.copyWith(
            campanhas: campanhas,
            limparTokenSelecionado: true,
            celulasAlcancaveisToken: const {},
            custosMovimentoToken: const {},
          ),
        );
        if (_hostService != null &&
            state.statusLan != StatusConexaoLan.desligado) {
          unawaited(
            _hostService!.publicarSnapshotMesa(
              SnapshotMesa.sanitizadoDeMapa(mapaMovido),
            ),
          );
        }
        break;

      case FerramentaMapaMestre.posicionarTokens:
        final elenco = state.sessaoAtual?.elenco ?? const [];
        final heroiId =
            state.heroiSelecionadoParaPosicionarId ??
            elenco.firstOrNull?.characterId;
        if (heroiId == null) return;
        final heroi = elenco.where((e) => e.characterId == heroiId).firstOrNull;
        if (heroi != null) {
          adicionarHeroiNoMapa(heroi, posicao: pos);
        }
        break;

      case FerramentaMapaMestre.pintarTerreno:
        final novosTerrenos = Map<Posicao2D, TipoTerreno>.from(mapa.terrenos);
        if (state.pincelTerreno == TipoTerreno.normal ||
            novosTerrenos[pos] == state.pincelTerreno) {
          novosTerrenos.remove(pos);
        } else {
          novosTerrenos[pos] = state.pincelTerreno;
        }
        _atualizarMapaAtual(mapa.copyWith(terrenos: novosTerrenos));
        break;

      case FerramentaMapaMestre.nevoaDeGuerra:
        final jaRevelada = mapa.celulasReveladas.contains(pos);
        if (fogModoRevelar == true && jaRevelada) return;
        if (fogModoRevelar == false && !jaRevelada) return;
        final novasReveladas = Set<Posicao2D>.from(mapa.celulasReveladas);
        if (fogModoRevelar == true) {
          novasReveladas.add(pos);
        } else if (fogModoRevelar == false) {
          novasReveladas.remove(pos);
        } else {
          if (jaRevelada) {
            novasReveladas.remove(pos);
          } else {
            novasReveladas.add(pos);
          }
        }
        _atualizarMapaAtual(mapa.copyWith(celulasReveladas: novasReveladas));
        break;
    }
  }

  void revelarTodoMapa() {
    final mapa = state.mapaAtual;
    if (mapa == null) return;
    final todas = <Posicao2D>{
      for (int y = 0; y < mapa.altura; y++)
        for (int x = 0; x < mapa.largura; x++) Posicao2D(x, y),
    };
    _atualizarMapaAtual(mapa.copyWith(celulasReveladas: todas));
  }

  void ocultarTodoMapa() {
    final mapa = state.mapaAtual;
    if (mapa == null) return;
    _atualizarMapaAtual(mapa.copyWith(celulasReveladas: const {}));
  }

  // ===========================================================================
  // HELPERS INTERNOS IMUTÁVEIS
  // ===========================================================================

  List<CampanhaMestre> _substituirCampanha(CampanhaMestre campAtualizada) {
    return state.campanhas.map((c) {
      return c.id == campAtualizada.id ? campAtualizada : c;
    }).toList();
  }

  List<CampanhaMestre>? _substituirAventura(AventuraMestre avAtualizada) {
    final camp = state.campanhaAtual;
    if (camp == null) return null;
    final novasAventuras = camp.aventuras.map((a) {
      return a.id == avAtualizada.id ? avAtualizada : a;
    }).toList();
    return _substituirCampanha(camp.copyWith(aventuras: novasAventuras));
  }

  List<CampanhaMestre>? _substituirSessao(SessaoJogo sesAtualizada) {
    final av = state.aventuraAtual;
    if (av == null) return null;
    final novasSessoes = av.sessoes.map((s) {
      return s.id == sesAtualizada.id ? sesAtualizada : s;
    }).toList();
    return _substituirAventura(av.copyWith(sessoes: novasSessoes));
  }

  List<CampanhaMestre>? _substituirMapa(MapaBatalhaMestre mapaAtualizado) {
    final camp = state.campanhaAtual;
    final av = state.aventuraAtual;
    if (camp == null || av == null) return null;

    final novosMapasAventura = av.mapas
        .map((m) => m.id == mapaAtualizado.id ? mapaAtualizado : m)
        .toList();
    final avAtualizada = av.copyWith(mapas: novosMapasAventura);
    final novasAventuras = camp.aventuras
        .map((a) => a.id == avAtualizada.id ? avAtualizada : a)
        .toList();
    final novosMapasCampanha = camp.mapas
        .map((m) => m.id == mapaAtualizado.id ? mapaAtualizado : m)
        .toList();

    return _substituirCampanha(
      camp.copyWith(
        aventuras: novasAventuras,
        mapas: novosMapasCampanha,
      ),
    );
  }

  void _atualizarCampanhaAtual(
    CampanhaMestre campAtualizada, {
    String? aventuraSelecionadaId,
    String? sessaoSelecionadaId,
    String? mapaSelecionadoId,
  }) {
    emit(
      state.copyWith(
        campanhas: _substituirCampanha(campAtualizada),
        aventuraSelecionadaId: aventuraSelecionadaId,
        sessaoSelecionadaId: sessaoSelecionadaId,
        mapaSelecionadoId: mapaSelecionadoId,
      ),
    );
  }

  void _atualizarAventuraAtual(
    AventuraMestre avAtualizada, {
    String? sessaoSelecionadaId,
    String? mapaSelecionadoId,
  }) {
    final campanhas = _substituirAventura(avAtualizada);
    if (campanhas == null) return;
    emit(
      state.copyWith(
        campanhas: campanhas,
        sessaoSelecionadaId: sessaoSelecionadaId,
        mapaSelecionadoId: mapaSelecionadoId,
      ),
    );
  }

  void _atualizarSessaoAtual(SessaoJogo sesAtualizada) {
    final campanhas = _substituirSessao(sesAtualizada);
    if (campanhas == null) return;
    emit(state.copyWith(campanhas: campanhas));
  }

  void _atualizarMapaAtual(MapaBatalhaMestre mapaAtualizado) {
    final campanhas = _substituirMapa(mapaAtualizado);
    if (campanhas == null) return;
    _ultimaMudancaEhEdicaoMapa = true;
    emit(state.copyWith(campanhas: campanhas));
    _agendarPublicacaoSnapshotLan(mapaAtualizado);
  }

  // ===========================================================================
  // GERENCIAMENTO DA HIERARQUIA: RENOMEAR, DUPLICAR, EXCLUIR
  // ===========================================================================

  void renomearCampanha(String id, String novoNome) {
    final camp = state.campanhas.where((c) => c.id == id).firstOrNull;
    if (camp == null) return;
    final atualizada = camp.copyWith(
      nome: novoNome.trim().isEmpty ? camp.nome : novoNome.trim(),
    );
    _atualizarCampanhaAtual(atualizada);
  }

  void duplicarCampanha(String id) {
    final camp = state.campanhas.where((c) => c.id == id).firstOrNull;
    if (camp == null) return;
    final clone = CampanhaMestre(
      id: _nextId('camp'),
      nome: '${camp.nome} (Cópia)',
      descricao: camp.descricao,
      patamar: camp.patamar,
      codigoConexaoLan: camp.codigoConexaoLan,
      aventuras: camp.aventuras,
    );
    emit(state.copyWith(campanhas: [...state.campanhas, clone]));
  }

  void excluirCampanha(String id) {
    final novas = state.campanhas.where((c) => c.id != id).toList();
    final proxima = novas.firstOrNull;
    final proxAv = proxima?.aventuras.firstOrNull;
    final proxSes = proxAv?.sessoes.firstOrNull;
    final proxMap = proxAv?.mapas.firstOrNull;

    emit(
      state.copyWith(
        campanhas: novas,
        campanhaSelecionadaId: proxima?.id,
        aventuraSelecionadaId: proxAv?.id,
        sessaoSelecionadaId: proxSes?.id,
        mapaSelecionadoId: proxSes?.mapaAtivoId ?? proxMap?.id,
        limparSelecaoContexto: true,
        limparTokenSelecionado: true,
        celulasAlcancaveisToken: const {},
        custosMovimentoToken: const {},
      ),
    );
  }

  void renomearAventura(String id, String novoNome) {
    final camp = state.campanhaAtual;
    if (camp == null) return;
    final av = camp.aventuras.where((a) => a.id == id).firstOrNull;
    if (av == null) return;
    _atualizarAventuraAtual(
      av.copyWith(nome: novoNome.trim().isEmpty ? av.nome : novoNome.trim()),
    );
  }

  void duplicarAventura(String id) {
    final camp = state.campanhaAtual;
    if (camp == null) return;
    final av = camp.aventuras.where((a) => a.id == id).firstOrNull;
    if (av == null) return;
    final clone = AventuraMestre(
      id: _nextId('av'),
      nome: '${av.nome} (Cópia)',
      sinopse: av.sinopse,
      sessoes: av.sessoes,
      mapas: av.mapas,
      notas: av.notas,
      handouts: av.handouts,
    );
    final novasAventuras = [...camp.aventuras, clone];
    _atualizarCampanhaAtual(camp.copyWith(aventuras: novasAventuras));
  }

  void excluirAventura(String id, {String? campanhaId}) {
    final camp = campanhaId != null
        ? state.campanhas.where((c) => c.id == campanhaId).firstOrNull
        : state.campanhaAtual;
    if (camp == null) return;
    final novasAventuras = camp.aventuras.where((a) => a.id != id).toList();
    final proxAv = novasAventuras.firstOrNull;
    final proxSes = proxAv?.sessoes.firstOrNull;
    final proxMap = proxAv?.mapas.firstOrNull;
    final campanhas = _substituirCampanha(
      camp.copyWith(aventuras: novasAventuras),
    );
    emit(
      state.copyWith(
        campanhas: campanhas,
        campanhaSelecionadaId: camp.id,
        aventuraSelecionadaId: proxAv?.id,
        sessaoSelecionadaId: proxSes?.id,
        mapaSelecionadoId: proxSes?.mapaAtivoId ?? proxMap?.id,
        limparSelecaoContexto: true,
      ),
    );
  }

  void renomearSessao(String id, String novoTitulo) {
    final av = state.aventuraAtual;
    if (av == null) return;
    final ses = av.sessoes.where((s) => s.id == id).firstOrNull;
    if (ses == null) return;
    _atualizarSessaoAtual(
      ses.copyWith(
        titulo: novoTitulo.trim().isEmpty ? ses.titulo : novoTitulo.trim(),
      ),
    );
  }

  void duplicarSessao(String id) {
    final av = state.aventuraAtual;
    if (av == null) return;
    final ses = av.sessoes.where((s) => s.id == id).firstOrNull;
    if (ses == null) return;
    final clone = SessaoJogo(
      id: _nextId('ses'),
      numero: av.sessoes.length + 1,
      titulo: '${ses.titulo} (Cópia)',
      objetivoResumo: ses.objetivoResumo,
      mapaAtivoId: ses.mapaAtivoId,
      elenco: ses.elenco,
      nivelAutomacao: ses.nivelAutomacao,
      codigoSalaLan: 'T20-${1000 + _random.nextInt(8999)}',
      statusSessao: ses.statusSessao,
      data: DateTime.now(),
      checklistNotas: ses.checklistNotas,
      notasSessaoTexto: ses.notasSessaoTexto,
      notaFixada: ses.notaFixada,
    );
    _atualizarAventuraAtual(av.copyWith(sessoes: [...av.sessoes, clone]));
  }

  void excluirSessao(String id, {String? campanhaId, String? aventuraId}) {
    final camp = campanhaId != null
        ? state.campanhas.where((c) => c.id == campanhaId).firstOrNull
        : state.campanhaAtual;
    if (camp == null) return;
    final av = aventuraId != null
        ? camp.aventuras.where((a) => a.id == aventuraId).firstOrNull
        : state.aventuraAtual;
    if (av == null) return;

    final novasSessoes = av.sessoes.where((s) => s.id != id).toList();
    final avAtualizada = av.copyWith(sessoes: novasSessoes);
    final campAtualizada = camp.copyWith(
      aventuras: camp.aventuras
          .map((a) => a.id == av.id ? avAtualizada : a)
          .toList(),
    );

    emit(
      state.copyWith(
        campanhas: _substituirCampanha(campAtualizada),
        campanhaSelecionadaId: camp.id,
        aventuraSelecionadaId: av.id,
        sessaoSelecionadaId: novasSessoes.firstOrNull?.id,
        limparSelecaoContexto: true,
      ),
    );
  }

  void alterarStatusSessao(String id, StatusSessao novoStatus) {
    final av = state.aventuraAtual;
    if (av == null) return;
    final ses = av.sessoes.where((s) => s.id == id).firstOrNull;
    if (ses == null) return;
    _atualizarSessaoAtual(ses.copyWith(statusSessao: novoStatus));
  }

  // ===========================================================================
  // GERENCIAMENTO DA BIBLIOTECA DE MAPAS (PARTE 2)
  // ===========================================================================

  void renomearMapa(String id, String novoNome) {
    final av = state.aventuraAtual;
    if (av == null) return;
    final mapa = av.mapas.where((m) => m.id == id).firstOrNull;
    if (mapa == null) return;
    _atualizarMapaAtual(
      mapa.copyWith(
        nome: novoNome.trim().isEmpty ? mapa.nome : novoNome.trim(),
      ),
    );
  }

  void duplicarMapa(String id) {
    final av = state.aventuraAtual;
    if (av == null) return;
    final mapa = av.mapas.where((m) => m.id == id).firstOrNull;
    if (mapa == null) return;
    final mapaClonado = MapaBatalhaMestre(
      id: _nextId('map'),
      nome: '${mapa.nome} (Cópia)',
      largura: mapa.largura,
      altura: mapa.altura,
      presetFundo: mapa.presetFundo,
      imagemCaminhoLocal: mapa.imagemCaminhoLocal,
      opacidadeGrid: mapa.opacidadeGrid,
      gridVisivel: mapa.gridVisivel,
      ajusteOffsetX: mapa.ajusteOffsetX,
      ajusteOffsetY: mapa.ajusteOffsetY,
      ajusteEscala: mapa.ajusteEscala,
      ajusteRotacaoGraus: mapa.ajusteRotacaoGraus,
      corFundoHex: mapa.corFundoHex,
      notas: mapa.notas,
      terrenos: Map.from(mapa.terrenos),
      celulasReveladas: Set.from(mapa.celulasReveladas),
      tokens: List.from(mapa.tokens),
    );
    _atualizarAventuraAtual(av.copyWith(mapas: [...av.mapas, mapaClonado]));
  }

  void excluirMapa(String id) {
    final av = state.aventuraAtual;
    if (av == null || av.mapas.length <= 1) return;
    final novosMapas = av.mapas.where((m) => m.id != id).toList();
    _atualizarAventuraAtual(av.copyWith(mapas: novosMapas));
  }

  void salvarConfiguracoesMapaCompleto(MapaBatalhaMestre mapaEditado) {
    final l = mapaEditado.largura.clamp(4, 30);
    final a = mapaEditado.altura.clamp(4, 30);

    bool dentroDoGrid(Posicao2D p) =>
        p.x >= 0 && p.x < l && p.y >= 0 && p.y < a;

    final tokensAjustados = mapaEditado.tokens.map((t) {
      return t.copyWith(
        posicao: Posicao2D(
          t.posicao.x.clamp(0, l - 1),
          t.posicao.y.clamp(0, a - 1),
        ),
      );
    }).toList();

    final terrenosFiltrados = <Posicao2D, TipoTerreno>{
      for (final entry in mapaEditado.terrenos.entries)
        if (dentroDoGrid(entry.key)) entry.key: entry.value,
    };

    final reveladasFiltradas = mapaEditado.celulasReveladas
        .where(dentroDoGrid)
        .toSet();

    _atualizarMapaAtual(
      mapaEditado.copyWith(
        largura: l,
        altura: a,
        tokens: tokensAjustados,
        terrenos: terrenosFiltrados,
        celulasReveladas: reveladasFiltradas,
      ),
    );
  }

  // ===========================================================================
  // COMBATENTES E TOKENS (PARTE 4)
  // ===========================================================================

  void ajustarPvToken(String tokenId, int delta) {
    final mapa = state.mapaAtual;
    if (mapa == null) return;
    final novosTokens = mapa.tokens.map((t) {
      if (t.id == tokenId) {
        final novoPv = (t.pvAtual + delta).clamp(-100, t.pvMax * 2);
        return t.copyWith(pvAtual: novoPv);
      }
      return t;
    }).toList();
    _atualizarMapaAtual(mapa.copyWith(tokens: novosTokens));
  }

  void ajustarPmToken(String tokenId, int delta) {
    final mapa = state.mapaAtual;
    if (mapa == null) return;
    final novosTokens = mapa.tokens.map((t) {
      if (t.id == tokenId) {
        final novoPm = (t.pmAtual + delta).clamp(0, t.pmMax * 2);
        return t.copyWith(pmAtual: novoPm);
      }
      return t;
    }).toList();
    _atualizarMapaAtual(mapa.copyWith(tokens: novosTokens));
  }

  void adicionarCondicaoToken(String tokenId, String condicao) {
    final mapa = state.mapaAtual;
    if (mapa == null) return;
    final novosTokens = mapa.tokens.map((t) {
      if (t.id == tokenId && !t.condicoes.contains(condicao)) {
        return t.copyWith(condicoes: [...t.condicoes, condicao]);
      }
      return t;
    }).toList();
    _atualizarMapaAtual(mapa.copyWith(tokens: novosTokens));
  }

  void removerCondicaoToken(String tokenId, String condicao) {
    final mapa = state.mapaAtual;
    if (mapa == null) return;
    final novosTokens = mapa.tokens.map((t) {
      if (t.id == tokenId) {
        final novas = t.condicoes.where((c) => c != condicao).toList();
        return t.copyWith(condicoes: novas);
      }
      return t;
    }).toList();
    _atualizarMapaAtual(mapa.copyWith(tokens: novosTokens));
  }

  /// Marca ou desmarca uma habilidade com recarga como gasta no token.
  void alternarRecargaHabilidadeToken(String tokenId, String nomeHabilidade) {
    final mapa = state.mapaAtual;
    if (mapa == null) return;
    final novosTokens = mapa.tokens.map((t) {
      if (t.id != tokenId) return t;
      final gastas = t.habilidadesGastas.contains(nomeHabilidade)
          ? t.habilidadesGastas.where((h) => h != nomeHabilidade).toList()
          : [...t.habilidadesGastas, nomeHabilidade];
      return t.copyWith(habilidadesGastas: gastas);
    }).toList();
    _atualizarMapaAtual(mapa.copyWith(tokens: novosTokens));
  }

  /// Ordena tokens por iniciativa decrescente (desempate por bônus de monstro, depois nome).
  static List<TokenNoMapa> ordenarTokensPorIniciativa(
    List<TokenNoMapa> tokens,
  ) {
    final copia = List<TokenNoMapa>.of(tokens);
    copia.sort((a, b) {
      final cmpInic = (b.iniciativa ?? -999).compareTo(a.iniciativa ?? -999);
      if (cmpInic != 0) return cmpInic;
      final cmpMod = (b.monstro?.iniciativa ?? 0).compareTo(
        a.monstro?.iniciativa ?? 0,
      );
      if (cmpMod != 0) return cmpMod;
      return a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
    });
    return copia;
  }

  /// Rola 1d20 + modificador para os combatentes da cena, reinicia na rodada 1 e destaca o 1º turno.
  void rolarIniciativaCena({
    bool manterHeroisComValor = false,
    Random? random,
  }) {
    final mapa = state.mapaAtual;
    if (mapa == null || mapa.tokens.isEmpty) return;
    final rng = random ?? _random;

    final atualizados = mapa.tokens.map((t) {
      if (manterHeroisComValor && t.ehHeroi && t.iniciativa != null) {
        return t;
      }
      final mod = t.monstro?.iniciativa ?? 0;
      final rolado = 1 + rng.nextInt(20) + mod;
      return t.copyWith(iniciativa: rolado);
    }).toList();

    final ordenados = ordenarTokensPorIniciativa(atualizados);
    _atualizarMapaAtual(
      mapa.copyWith(
        tokens: atualizados,
        rodadaCombate: 1,
        tokenTurnoAtualId: ordenados.first.id,
      ),
    );
  }

  /// Atualiza manualmente o valor de iniciativa de um token (ex: rolagem física de jogador).
  void definirIniciativaToken(String tokenId, int valor) {
    final mapa = state.mapaAtual;
    if (mapa == null) return;
    final novosTokens = mapa.tokens
        .map((t) => t.id == tokenId ? t.copyWith(iniciativa: valor) : t)
        .toList();
    _atualizarMapaAtual(mapa.copyWith(tokens: novosTokens));
  }

  /// Avança o turno ativo na fila de iniciativa; incrementa a rodada ao reiniciar a volta.
  void avancarTurno() {
    final mapa = state.mapaAtual;
    if (mapa == null || mapa.tokens.isEmpty) return;
    final ordenados = ordenarTokensPorIniciativa(mapa.tokens);
    final idxAtual = ordenados.indexWhere(
      (t) => t.id == mapa.tokenTurnoAtualId,
    );

    if (idxAtual == -1) {
      _atualizarMapaAtual(mapa.copyWith(tokenTurnoAtualId: ordenados.first.id));
      return;
    }

    final ehUltimo = idxAtual + 1 >= ordenados.length;
    final proxIdx = ehUltimo ? 0 : idxAtual + 1;
    _atualizarMapaAtual(
      mapa.copyWith(
        rodadaCombate: ehUltimo ? mapa.rodadaCombate + 1 : mapa.rodadaCombate,
        tokenTurnoAtualId: ordenados[proxIdx].id,
      ),
    );
  }

  /// Encerra o rastreador de turnos na cena atual sem remover tokens.
  void encerrarCombate() {
    final mapa = state.mapaAtual;
    if (mapa == null) return;
    _atualizarMapaAtual(
      mapa.copyWith(rodadaCombate: 1, limparTurnoAtual: true),
    );
  }

  void enviarMapaAosJogadores() {
    final mapa = state.mapaAtual;
    if (mapa != null &&
        _hostService != null &&
        state.statusLan != StatusConexaoLan.desligado) {
      unawaited(
        _hostService!.publicarSnapshotMesa(
          SnapshotMesa.sanitizadoDeMapa(mapa),
        ),
      );
    }
    emit(state.copyWith(enviandoMapaAosJogadores: true));
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!isClosed) {
        emit(
          state.copyWith(
            enviandoMapaAosJogadores: false,
            ultimoEnvioMapa: DateTime.now(),
          ),
        );
      }
    });
  }

  void registrarPontoMedicao(Posicao2D pos) {
    if (state.pontoOrigemMedicao == null || state.pontoDestinoMedicao != null) {
      emit(state.copyWith(pontoOrigemMedicao: pos, limparDestinoMedicao: true));
    } else {
      emit(state.copyWith(pontoDestinoMedicao: pos));
    }
  }

  void limparMedicao() {
    emit(state.copyWith(limparMedicao: true));
  }

  void soltarPing(Posicao2D pos) {
    final lista = [...state.pingsAtivos, pos];
    emit(state.copyWith(pingsAtivos: lista));
    Future.delayed(const Duration(seconds: 4), () {
      if (!isClosed) {
        final atualizados = state.pingsAtivos.where((p) => p != pos).toList();
        emit(state.copyWith(pingsAtivos: atualizados));
      }
    });
  }

  // ===========================================================================
  // NOTAS DA SESSÃO E CHECKLIST (PARTE 5)
  // ===========================================================================

  void atualizarNotasSessao(String texto) {
    final ses = state.sessaoAtual;
    if (ses == null) return;
    _atualizarSessaoAtual(ses.copyWith(notasSessaoTexto: texto));
  }

  void alternarFixarNotaSessao() {
    final ses = state.sessaoAtual;
    if (ses == null) return;
    _atualizarSessaoAtual(ses.copyWith(notaFixada: !ses.notaFixada));
  }

  void adicionarItemChecklist(String texto) {
    final ses = state.sessaoAtual;
    if (ses == null || texto.trim().isEmpty) return;
    final item = ItemChecklistNota(id: _nextId('chk'), texto: texto.trim());
    _atualizarSessaoAtual(
      ses.copyWith(checklistNotas: [...ses.checklistNotas, item]),
    );
  }

  void alternarItemChecklist(String itemId) {
    final ses = state.sessaoAtual;
    if (ses == null) return;
    final novos = ses.checklistNotas.map((it) {
      return it.id == itemId ? it.copyWith(concluido: !it.concluido) : it;
    }).toList();
    _atualizarSessaoAtual(ses.copyWith(checklistNotas: novos));
  }

  void removerItemChecklist(String itemId) {
    final ses = state.sessaoAtual;
    if (ses == null) return;
    final novos = ses.checklistNotas.where((it) => it.id != itemId).toList();
    _atualizarSessaoAtual(ses.copyWith(checklistNotas: novos));
  }

  // ===========================================================================
  // PERIGOS E GERADOR DE NOMES (PARTE 5)
  // ===========================================================================

  void alternarFixarPerigo(String perigoId) {
    final novos = state.perigos.map((p) {
      return p.id == perigoId ? p.copyWith(fixado: !p.fixado) : p;
    }).toList();
    emit(state.copyWith(perigos: novos));
  }

  void gerarNomeAleatorio({
    required String raca,
    required String genero,
    required String tom,
  }) {
    final nomesBanco =
        CatalogoMestrePadrao.bancoNomesPorRaca[raca] ??
        CatalogoMestrePadrao.bancoNomesPorRaca['Humano']!;
    final sobrenomes =
        CatalogoMestrePadrao.bancoSobrenomesPorRaca[raca] ??
        CatalogoMestrePadrao.bancoSobrenomesPorRaca['Humano']!;

    final poolNomes = _filtrarPorGenero(nomesBanco, genero);
    final primeiroNome = poolNomes[_random.nextInt(poolNomes.length)];
    final sobrenome = _escolherSobrenomePorTom(sobrenomes, tom);

    final nomeCompleto = '$primeiroNome $sobrenome';
    final historico = [nomeCompleto, ...state.historicoNomes.take(19)];
    emit(
      state.copyWith(nomeGeradoAtual: nomeCompleto, historicoNomes: historico),
    );
  }

  List<String> _filtrarPorGenero(List<String> nomes, String genero) {
    if (genero == 'Feminino') {
      final fem = nomes
          .where((n) => n.endsWith('a') || n.endsWith('n') || n.endsWith('y'))
          .toList();
      if (fem.isNotEmpty) return fem;
    } else if (genero == 'Masculino') {
      final masc = nomes.where((n) => !n.endsWith('a')).toList();
      if (masc.isNotEmpty) return masc;
    }
    return nomes;
  }

  String _escolherSobrenomePorTom(List<String> sobrenomes, String tom) {
    final base = sobrenomes[_random.nextInt(sobrenomes.length)];
    switch (tom) {
      case 'Épico':
        const titulosEpicos = ['o Destemido', 'Lâmina-Rubra', 'da Aurora'];
        return _random.nextBool()
            ? base
            : '$base, ${titulosEpicos[_random.nextInt(titulosEpicos.length)]}';
      case 'Cômico':
        const apelidos = ['Pés-Trocados', 'Quebra-Caneco', 'Sem-Sortudo'];
        return apelidos[_random.nextInt(apelidos.length)];
      case 'Rústico':
        const rusticos = ['da Pedra', 'do Mato', 'Couro-Cru'];
        return _random.nextBool()
            ? base
            : rusticos[_random.nextInt(rusticos.length)];
      default:
        return base;
    }
  }

  void favoritarNome(String nome) {
    if (state.nomesFavoritos.contains(nome)) {
      final novos = state.nomesFavoritos.where((n) => n != nome).toList();
      emit(state.copyWith(nomesFavoritos: novos));
    } else {
      emit(state.copyWith(nomesFavoritos: [nome, ...state.nomesFavoritos]));
    }
  }
}
