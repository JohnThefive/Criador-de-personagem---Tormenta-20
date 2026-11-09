import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/combate/combatente.dart';
import '../../../domain/entities/combate/grid_tatico.dart';
import '../../../domain/entities/mestre/modelos_mestre.dart';
import '../../../domain/entities/personagem/personagem.dart';
import '../../../domain/services/combate_services/movimento_engine.dart';
import 'mestre_state.dart';

class MestreCubit extends Cubit<MestreState> {
  MestreCubit() : super(_criarEstadoInicial());

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
        ItemChecklistNota(id: 'chk_1', texto: 'Apresentar a caravana e o comerciante Thalon', concluido: true),
        ItemChecklistNota(id: 'chk_2', texto: 'Emboscada dos batedores puristas na curva do rio', concluido: false),
        ItemChecklistNota(id: 'chk_3', texto: 'Pistas sobre a mina abandonada no norte', concluido: false),
      ],
      notasSessaoTexto: 'Clima úmido e chuvoso. Visibilidade média. O líder dos puristas possui um broche com o símbolo do Deus da Guerra.',
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
    );

    return MestreState(
      campanhas: [campanhaInicial],
      campanhaSelecionadaId: campanhaInicial.id,
      aventuraSelecionadaId: aventuraInicial.id,
      sessaoSelecionadaId: sessaoInicial.id,
      mapaSelecionadoId: mapaInicial.id,
      regrasRapidas: _regrasPadraoT20,
      perigos: _perigosPadraoT20,
      logsRedeLan: const [
        '[Sistema] Painel do Mestre inicializado (Modo Offline / Preparação).',
      ],
    );
  }

  // ===========================================================================
  // 1. HIERARQUIA: CAMPANHA -> AVENTURA -> SESSÃO
  // ===========================================================================

  void selecionarCampanha(String campanhaId) {
    final camp =
        state.campanhas.where((c) => c.id == campanhaId).firstOrNull;
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
        limparTokenSelecionado: true,
        celulasAlcancaveisToken: const {},
      ),
    );
  }

  void criarCampanha({
    required String nome,
    required String descricao,
    required String patamar,
  }) {
    final id = 'camp_${DateTime.now().millisecondsSinceEpoch}';
    final avId = 'av_${DateTime.now().millisecondsSinceEpoch}';
    final sesId = 'ses_${DateTime.now().millisecondsSinceEpoch}';
    final mapId = 'map_${DateTime.now().millisecondsSinceEpoch}';

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
      codigoSalaLan: 'T20-${1000 + Random().nextInt(8999)}',
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
        aventuraSelecionadaId: av.id,
        sessaoSelecionadaId: primSessao?.id,
        mapaSelecionadoId: primSessao?.mapaAtivoId ?? primMapa?.id,
        limparTokenSelecionado: true,
        celulasAlcancaveisToken: const {},
      ),
    );
  }

  void criarAventura({required String nome, required String sinopse}) {
    final camp = state.campanhaAtual;
    if (camp == null) return;

    final avId = 'av_${DateTime.now().millisecondsSinceEpoch}';
    final sesId = 'ses_${DateTime.now().millisecondsSinceEpoch}';
    final mapId = 'map_${DateTime.now().millisecondsSinceEpoch}';

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
      codigoSalaLan: 'T20-${1000 + Random().nextInt(8999)}',
    );

    final novaAv = AventuraMestre(
      id: avId,
      nome: nome.trim().isEmpty ? 'Nova Aventura' : nome.trim(),
      sinopse: sinopse.trim(),
      sessoes: [novaSessao],
      mapas: [novoMapa],
    );

    _atualizarCampanhaAtual(
      camp.copyWith(aventuras: [...camp.aventuras, novaAv]),
      aventuraSelecionadaId: novaAv.id,
      sessaoSelecionadaId: novaSessao.id,
      mapaSelecionadoId: novoMapa.id,
    );
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
  }

  void criarSessao({
    required String titulo,
    required String objetivoResumo,
  }) {
    final av = state.aventuraAtual;
    if (av == null) return;

    final proximoNumero = av.sessoes.length + 1;
    final novaSessao = SessaoJogo(
      id: 'ses_${DateTime.now().millisecondsSinceEpoch}',
      numero: proximoNumero,
      titulo: titulo.trim().isEmpty
          ? 'Sessão #$proximoNumero'
          : titulo.trim(),
      objetivoResumo: objetivoResumo.trim(),
      mapaAtivoId: av.mapas.firstOrNull?.id,
      elenco: av.sessoes.lastOrNull?.elenco ?? const [],
      codigoSalaLan: 'T20-${1000 + Random().nextInt(8999)}',
    );

    _atualizarAventuraAtual(
      av.copyWith(sessoes: [...av.sessoes, novaSessao]),
      sessaoSelecionadaId: novaSessao.id,
    );
  }

  // ===========================================================================
  // 2. FRONTEND DE CONEXÃO LAN E CONVITE DE JOGADORES (ADR-004 UI + RF-M1)
  // ===========================================================================

  void alternarServidorLan() {
    final novoStatus = state.statusLan == StatusConexaoLan.desligado
        ? StatusConexaoLan.aguardandoJogadores
        : StatusConexaoLan.desligado;

    final logMsg = novoStatus == StatusConexaoLan.aguardandoJogadores
        ? '📡 [Host LAN] Sala aberta em ${state.ipHostLocal}:${state.portaHostLan} (Código: ${state.sessaoAtual?.codigoSalaLan ?? "T20-0000"}).'
        : '🔌 [Host LAN] Sala encerrada pelo Mestre.';

    emit(
      state.copyWith(
        statusLan: novoStatus,
        logsRedeLan: [...state.logsRedeLan, logMsg],
      ),
    );
  }

  void iniciarSincronizacaoSessaoLan() {
    emit(
      state.copyWith(
        statusLan: StatusConexaoLan.emSessaoAtiva,
        logsRedeLan: [
          ...state.logsRedeLan,
          '⚡ [Host LAN] Sessão ativa! Projeções enviadas para os jogadores aprovados.',
        ],
      ),
    );
  }

  void gerarNovoCodigoSalaLan() {
    final ses = state.sessaoAtual;
    if (ses == null) return;
    final novoCodigo = 'T20-${1000 + Random().nextInt(8999)}';
    _atualizarSessaoAtual(ses.copyWith(codigoSalaLan: novoCodigo));
    emit(
      state.copyWith(
        logsRedeLan: [
          ...state.logsRedeLan,
          '🔑 Novo código PIN da sala gerado: $novoCodigo.',
        ],
      ),
    );
  }

  /// Adiciona um personagem salvo no próprio aparelho para dentro da sessão atual e no mapa.
  void convidarPersonagemLocalParaSessao(
    Personagem p, {
    String nomeJogador = 'Jogador Convidado',
  }) {
    final ses = state.sessaoAtual;
    if (ses == null) return;

    final comb = Combatente.doPersonagem(p);
    final classeStr = p.classes.isNotEmpty
        ? '${p.classes.first.classeDefinicao.nome} Nv ${p.nivelPersonagem}'
        : 'Nível ${p.nivelPersonagem}';

    final novaEntrada = ElencoSessaoEntry(
      characterId: p.id,
      nomePersonagem: p.nome,
      nomeJogador: nomeJogador,
      classeResumo: classeStr,
      pvAtual: p.pvTotal,
      pvMax: p.pvTotal,
      pmAtual: p.pmTotal,
      pmMax: p.pmTotal,
      defesa: comb.defesa,
      deslocamentoMetros: comb.deslocamentoMetros,
      statusRevisao: StatusRevisaoFicha.aprovada,
      conectadoViaLan: state.statusLan != StatusConexaoLan.desligado,
      ipJogador: '192.168.1.${110 + ses.elenco.length}',
    );

    final elencoAtualizado = [
      ...ses.elenco.where((e) => e.characterId != p.id),
      novaEntrada,
    ];
    _atualizarSessaoAtual(ses.copyWith(elenco: elencoAtualizado));

    // Também adiciona o token no mapa ativo se ainda não estiver lá
    adicionarHeroiNoMapa(novaEntrada);

    emit(
      state.copyWith(
        logsRedeLan: [
          ...state.logsRedeLan,
          '✅ Herói "${p.nome}" ($classeStr) integrado à sessão e posicionado no mapa.',
        ],
      ),
    );
  }

  /// Simula (Frontend) o recebimento de um pedido de conexão de jogador via LAN para revisão do Mestre (RF-M1).
  void simularPedidoEntradaJogadorLan({
    required String nomeJogador,
    required String nomePersonagem,
    required String classeResumo,
    int pvMax = 24,
    int pmMax = 10,
  }) {
    final ses = state.sessaoAtual;
    if (ses == null) return;

    final id = 'lan_${DateTime.now().millisecondsSinceEpoch}';
    final ip = '192.168.1.${115 + ses.elenco.length}';
    final novoConvidado = ElencoSessaoEntry(
      characterId: id,
      nomePersonagem: nomePersonagem.trim().isEmpty ? 'Thorin' : nomePersonagem.trim(),
      nomeJogador: nomeJogador.trim().isEmpty ? 'Jogador LAN' : nomeJogador.trim(),
      classeResumo: classeResumo.trim().isEmpty ? 'Paladino Nv 2' : classeResumo.trim(),
      pvAtual: pvMax,
      pvMax: pvMax,
      pmAtual: pmMax,
      pmMax: pmMax,
      statusRevisao: StatusRevisaoFicha.pendente,
      conectadoViaLan: true,
      ipJogador: ip,
    );

    _atualizarSessaoAtual(
      ses.copyWith(elenco: [...ses.elenco, novoConvidado]),
    );

    emit(
      state.copyWith(
        logsRedeLan: [
          ...state.logsRedeLan,
          '📩 [JOIN / LAN] $nomeJogador ($ip) enviou a ficha "$nomePersonagem" (Aguardando Revisão RF-M1).',
        ],
      ),
    );
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

  /// RF-M3: Restaura PV e PM de todos os personagens da sessão (Descanso da Equipe).
  void aplicarDescansoEquipe() {
    final ses = state.sessaoAtual;
    if (ses == null) return;

    final novoElenco = ses.elenco
        .map((e) => e.copyWith(pvAtual: e.pvMax, pmAtual: e.pmMax))
        .toList();
    _atualizarSessaoAtual(ses.copyWith(elenco: novoElenco));

    emit(
      state.copyWith(
        logsRedeLan: [
          ...state.logsRedeLan,
          '⛺ [Campanha] Descanso aplicado: PV e PM de todo o elenco foram restaurados.',
        ],
      ),
    );
  }

  void alterarNivelAutomacaoSessao(NivelAutomacaoMesa novoNivel) {
    final ses = state.sessaoAtual;
    if (ses == null) return;
    _atualizarSessaoAtual(ses.copyWith(nivelAutomacao: novoNivel));
  }

  // ===========================================================================
  // 3. MAPAS DE BATALHA, IMAGEM DE FUNDO E MOVIMENTAÇÃO NO GRID (RF-M6, RF-M7)
  // ===========================================================================

  void selecionarMapa(String mapaId) {
    final ses = state.sessaoAtual;
    if (ses != null) {
      _atualizarSessaoAtual(ses.copyWith(mapaAtivoId: mapaId));
    }
    emit(
      state.copyWith(
        mapaSelecionadoId: mapaId,
        limparTokenSelecionado: true,
        celulasAlcancaveisToken: const {},
      ),
    );
  }

  void criarMapa({
    required String nome,
    required int largura,
    required int altura,
    PresetFundoMapa preset = PresetFundoMapa.masmorraPedra,
    String? imagemCaminhoLocal,
  }) {
    final av = state.aventuraAtual;
    if (av == null) return;

    final id = 'map_${DateTime.now().millisecondsSinceEpoch}';
    final l = largura.clamp(5, 24);
    final a = altura.clamp(5, 20);

    final reveladas = <Posicao2D>{
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
      celulasReveladas: reveladas,
      tokens: tokensIniciais,
    );

    _atualizarAventuraAtual(
      av.copyWith(mapas: [...av.mapas, novoMapa]),
      mapaSelecionadoId: novoMapa.id,
    );
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

  void alterarPresetFundoMapa(PresetFundoMapa preset) {
    final mapa = state.mapaAtual;
    if (mapa == null) return;
    _atualizarMapaAtual(
      mapa.copyWith(
        presetFundo: preset,
        limparImagemCustomizada: preset != PresetFundoMapa.imagemCustomizada,
      ),
    );
  }

  void alterarDimensoesGrid(int novaLargura, int novaAltura) {
    final mapa = state.mapaAtual;
    if (mapa == null) return;
    final l = novaLargura.clamp(5, 24);
    final a = novaAltura.clamp(5, 20);

    // Ajusta posições de tokens caso fiquem fora do novo limite
    final tokensAjustados = mapa.tokens.map((t) {
      return t.copyWith(
        posicao: Posicao2D(
          t.posicao.x.clamp(0, l - 1),
          t.posicao.y.clamp(0, a - 1),
        ),
      );
    }).toList();

    _atualizarMapaAtual(
      mapa.copyWith(
        largura: l,
        altura: a,
        tokens: tokensAjustados,
      ),
    );
  }

  void alterarOpacidadeGrid(double novaOpacidade) {
    final mapa = state.mapaAtual;
    if (mapa == null) return;
    _atualizarMapaAtual(mapa.copyWith(opacidadeGrid: novaOpacidade.clamp(0.1, 1.0)));
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

  void selecionarPincelTerreno(TipoTerreno terreno) {
    emit(state.copyWith(pincelTerreno: terreno));
  }

  void alternarMovimentoLivreMestre() {
    final novoLivre = !state.movimentoLivreMestre;
    emit(
      state.copyWith(
        movimentoLivreMestre: novoLivre,
        celulasAlcancaveisToken: const {},
        limparTokenSelecionado: true,
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

  void selecionarHeroiParaPosicionar(String characterId) {
    emit(
      state.copyWith(
        heroiSelecionadoParaPosicionarId: characterId,
        ferramentaMapa: FerramentaMapaMestre.posicionarTokens,
      ),
    );
  }

  void adicionarHeroiNoMapa(ElencoSessaoEntry heroi, {Posicao2D? posicao}) {
    final mapa = state.mapaAtual;
    if (mapa == null) return;

    final jaExiste = mapa.tokens.any((t) => t.id == heroi.characterId);
    if (jaExiste && posicao == null) return;

    final posFinal = posicao ??
        Posicao2D(
          1,
          (mapa.tokens.length + 1).clamp(0, mapa.altura - 1),
        );

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
  }) {
    final mapa = state.mapaAtual;
    if (mapa == null) return;

    final pos = posicao ??
        Posicao2D(
          ehHeroi ? 2 : (mapa.largura - 2).clamp(0, mapa.largura - 1),
          (mapa.tokens.length + 1).clamp(0, mapa.altura - 1),
        );

    final novoToken = TokenNoMapa(
      id: 'tok_${DateTime.now().millisecondsSinceEpoch}',
      nome: nome.trim().isEmpty ? 'Combatente' : nome.trim(),
      posicao: pos,
      ehHeroi: ehHeroi,
      tipo: tipo ?? (ehHeroi ? TipoCombatenteMapa.heroi : TipoCombatenteMapa.inimigo),
      pvAtual: pvMax,
      pvMax: pvMax,
      pmAtual: pmMax,
      pmMax: pmMax,
      defesa: defesa,
      iniciativa: iniciativa,
      tamanhoQuadrados: tamanhoQuadrados,
      visibilidade:
          ocultoParaJogadores ? const SomenteMestre() : const ParaTodos(),
    );

    _atualizarMapaAtual(mapa.copyWith(tokens: [...mapa.tokens, novoToken]));
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
    _atualizarMapaAtual(
      mapa.copyWith(
        tokens: mapa.tokens.where((t) => t.id != tokenId).toList(),
      ),
    );
    if (state.tokenSelecionadoParaMoverId == tokenId) {
      emit(
        state.copyWith(
          limparTokenSelecionado: true,
          celulasAlcancaveisToken: const {},
        ),
      );
    }
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
        t.id: Combatente(
          id: t.id,
          nome: t.nome,
          time: t.ehHeroi ? TimeCombatente.heroi : TimeCombatente.inimigo,
          pvMax: t.pvMax,
          pvAtual: t.pvAtual,
          pmMax: 0,
          pmAtual: 0,
          defesa: 15,
          deslocamentoMetros: t.deslocamentoMetros,
          modIniciativa: 0,
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
  void aoClicarCelulaMapa(Posicao2D pos) {
    final mapa = state.mapaAtual;
    if (mapa == null) return;

    switch (state.ferramentaMapa) {
      case FerramentaMapaMestre.moverPersonagens:
        final tokenId = state.tokenSelecionadoParaMoverId;
        if (tokenId == null) {
          // Se clicou numa célula onde há um token, seleciona esse token
          final tokNaCelula =
              mapa.tokens.where((t) => t.posicao == pos).firstOrNull;
          if (tokNaCelula != null) {
            aoClicarTokenNoMapa(tokNaCelula);
          }
          return;
        }

        final podeMover = state.movimentoLivreMestre ||
            state.celulasAlcancaveisToken.contains(pos);
        if (!podeMover) return;

        final novosTokens = mapa.tokens.map((t) {
          if (t.id == tokenId) {
            return t.copyWith(posicao: pos);
          }
          return t;
        }).toList();

        _atualizarMapaAtual(mapa.copyWith(tokens: novosTokens));
        emit(
          state.copyWith(
            limparTokenSelecionado: true,
            celulasAlcancaveisToken: const {},
            custosMovimentoToken: const {},
          ),
        );
        break;

      case FerramentaMapaMestre.posicionarTokens:
        final elenco = state.sessaoAtual?.elenco ?? const [];
        final heroiId = state.heroiSelecionadoParaPosicionarId ??
            elenco.firstOrNull?.characterId;
        if (heroiId == null) return;
        final heroi =
            elenco.where((e) => e.characterId == heroiId).firstOrNull;
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
        final novasReveladas = Set<Posicao2D>.from(mapa.celulasReveladas);
        if (novasReveladas.contains(pos)) {
          novasReveladas.remove(pos);
        } else {
          novasReveladas.add(pos);
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
  // 4. ESCUDO DO MESTRE: NOTAS, HANDOUTS E REGRAS RÁPIDAS (RF-M2, RF-M4, RF-M9)
  // ===========================================================================

  void criarNotaMestre({
    required String titulo,
    required String conteudo,
    required bool compartilharComJogadores,
  }) {
    final av = state.aventuraAtual;
    if (av == null) return;

    final novaNota = NotaMestre(
      id: 'nota_${DateTime.now().millisecondsSinceEpoch}',
      titulo: titulo.trim().isEmpty ? 'Anotação de Sessão' : titulo.trim(),
      conteudo: conteudo.trim(),
      visibilidade: compartilharComJogadores
          ? const ParaTodos()
          : const SomenteMestre(),
      atualizadoEm: DateTime.now(),
    );

    _atualizarAventuraAtual(av.copyWith(notas: [novaNota, ...av.notas]));
  }

  void alternarVisibilidadeNota(String notaId) {
    final av = state.aventuraAtual;
    if (av == null) return;

    final novasNotas = av.notas.map((n) {
      if (n.id == notaId) {
        final novaVis = n.compartilhadaComJogadores
            ? const SomenteMestre()
            : const ParaTodos();
        return n.copyWith(visibilidade: novaVis, atualizadoEm: DateTime.now());
      }
      return n;
    }).toList();

    _atualizarAventuraAtual(av.copyWith(notas: novasNotas));
  }

  void criarHandout({
    required String titulo,
    required String descricao,
    bool entregarAgora = true,
  }) {
    final av = state.aventuraAtual;
    if (av == null) return;

    final novoHandout = HandoutMestre(
      id: 'hand_${DateTime.now().millisecondsSinceEpoch}',
      titulo: titulo.trim().isEmpty ? 'Documento / Pista' : titulo.trim(),
      descricao: descricao.trim(),
      entregueAosJogadores: entregarAgora,
    );

    _atualizarAventuraAtual(
      av.copyWith(handouts: [novoHandout, ...av.handouts]),
    );
  }

  void alternarEntregaHandout(String handoutId) {
    final av = state.aventuraAtual;
    if (av == null) return;

    final novosHandouts = av.handouts.map((h) {
      if (h.id == handoutId) {
        return h.copyWith(entregueAosJogadores: !h.entregueAosJogadores);
      }
      return h;
    }).toList();

    _atualizarAventuraAtual(av.copyWith(handouts: novosHandouts));
  }

  void atualizarBuscaRegra(String termo) {
    emit(state.copyWith(buscaRegra: termo));
  }

  void alternarFixarRegra(String regraId) {
    final novasRegras = state.regrasRapidas.map((r) {
      if (r.id == regraId) {
        return r.copyWith(fixado: !r.fixado);
      }
      return r;
    }).toList();
    emit(state.copyWith(regrasRapidas: novasRegras));
  }

  // ===========================================================================
  // HELPERS INTERNOS IMUTÁVEIS
  // ===========================================================================

  void _atualizarCampanhaAtual(
    CampanhaMestre campAtualizada, {
    String? aventuraSelecionadaId,
    String? sessaoSelecionadaId,
    String? mapaSelecionadoId,
  }) {
    final novasCampanhas = state.campanhas.map((c) {
      return c.id == campAtualizada.id ? campAtualizada : c;
    }).toList();

    emit(
      state.copyWith(
        campanhas: novasCampanhas,
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
    final camp = state.campanhaAtual;
    if (camp == null) return;

    final novasAventuras = camp.aventuras.map((a) {
      return a.id == avAtualizada.id ? avAtualizada : a;
    }).toList();

    _atualizarCampanhaAtual(
      camp.copyWith(aventuras: novasAventuras),
      sessaoSelecionadaId: sessaoSelecionadaId,
      mapaSelecionadoId: mapaSelecionadoId,
    );
  }

  void _atualizarSessaoAtual(SessaoJogo sesAtualizada) {
    final av = state.aventuraAtual;
    if (av == null) return;

    final novasSessoes = av.sessoes.map((s) {
      return s.id == sesAtualizada.id ? sesAtualizada : s;
    }).toList();

    _atualizarAventuraAtual(av.copyWith(sessoes: novasSessoes));
  }

  void _atualizarMapaAtual(MapaBatalhaMestre mapaAtualizado) {
    final av = state.aventuraAtual;
    if (av == null) return;

    final novosMapas = av.mapas.map((m) {
      return m.id == mapaAtualizado.id ? mapaAtualizado : m;
    }).toList();

    _atualizarAventuraAtual(av.copyWith(mapas: novosMapas));
  }

  // ===========================================================================
  // GERENCIAMENTO DA HIERARQUIA: RENOMEAR, DUPLICAR, EXCLUIR
  // ===========================================================================

  void renomearCampanha(String id, String novoNome) {
    final camp = state.campanhas.where((c) => c.id == id).firstOrNull;
    if (camp == null) return;
    final atualizada = camp.copyWith(nome: novoNome.trim().isEmpty ? camp.nome : novoNome.trim());
    _atualizarCampanhaAtual(atualizada);
  }

  void duplicarCampanha(String id) {
    final camp = state.campanhas.where((c) => c.id == id).firstOrNull;
    if (camp == null) return;
    final clone = CampanhaMestre(
      id: 'camp_${DateTime.now().millisecondsSinceEpoch}',
      nome: '${camp.nome} (Cópia)',
      descricao: camp.descricao,
      patamar: camp.patamar,
      aventuras: camp.aventuras,
    );
    emit(state.copyWith(campanhas: [...state.campanhas, clone]));
  }

  void excluirCampanha(String id) {
    if (state.campanhas.length <= 1) return;
    final novas = state.campanhas.where((c) => c.id != id).toList();
    emit(state.copyWith(
      campanhas: novas,
      campanhaSelecionadaId: novas.first.id,
      aventuraSelecionadaId: novas.first.aventuras.firstOrNull?.id,
      sessaoSelecionadaId: novas.first.aventuras.firstOrNull?.sessoes.firstOrNull?.id,
      mapaSelecionadoId: novas.first.aventuras.firstOrNull?.mapas.firstOrNull?.id,
    ));
  }

  void renomearAventura(String id, String novoNome) {
    final camp = state.campanhaAtual;
    if (camp == null) return;
    final av = camp.aventuras.where((a) => a.id == id).firstOrNull;
    if (av == null) return;
    _atualizarAventuraAtual(av.copyWith(nome: novoNome.trim().isEmpty ? av.nome : novoNome.trim()));
  }

  void duplicarAventura(String id) {
    final camp = state.campanhaAtual;
    if (camp == null) return;
    final av = camp.aventuras.where((a) => a.id == id).firstOrNull;
    if (av == null) return;
    final clone = AventuraMestre(
      id: 'av_${DateTime.now().millisecondsSinceEpoch}',
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

  void excluirAventura(String id) {
    final camp = state.campanhaAtual;
    if (camp == null || camp.aventuras.length <= 1) return;
    final novasAventuras = camp.aventuras.where((a) => a.id != id).toList();
    _atualizarCampanhaAtual(camp.copyWith(aventuras: novasAventuras));
  }

  void renomearSessao(String id, String novoTitulo) {
    final av = state.aventuraAtual;
    if (av == null) return;
    final ses = av.sessoes.where((s) => s.id == id).firstOrNull;
    if (ses == null) return;
    _atualizarSessaoAtual(ses.copyWith(titulo: novoTitulo.trim().isEmpty ? ses.titulo : novoTitulo.trim()));
  }

  void duplicarSessao(String id) {
    final av = state.aventuraAtual;
    if (av == null) return;
    final ses = av.sessoes.where((s) => s.id == id).firstOrNull;
    if (ses == null) return;
    final clone = SessaoJogo(
      id: 'ses_${DateTime.now().millisecondsSinceEpoch}',
      numero: av.sessoes.length + 1,
      titulo: '${ses.titulo} (Cópia)',
      objetivoResumo: ses.objetivoResumo,
      mapaAtivoId: ses.mapaAtivoId,
      elenco: ses.elenco,
      nivelAutomacao: ses.nivelAutomacao,
      codigoSalaLan: 'T20-${1000 + Random().nextInt(8999)}',
      statusSessao: ses.statusSessao,
      data: DateTime.now(),
      checklistNotas: ses.checklistNotas,
      notasSessaoTexto: ses.notasSessaoTexto,
      notaFixada: ses.notaFixada,
    );
    _atualizarAventuraAtual(av.copyWith(sessoes: [...av.sessoes, clone]));
  }

  void excluirSessao(String id) {
    final av = state.aventuraAtual;
    if (av == null || av.sessoes.length <= 1) return;
    final novasSessoes = av.sessoes.where((s) => s.id != id).toList();
    _atualizarAventuraAtual(av.copyWith(sessoes: novasSessoes));
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
    _atualizarMapaAtual(mapa.copyWith(nome: novoNome.trim().isEmpty ? mapa.nome : novoNome.trim()));
  }

  void duplicarMapa(String id) {
    final av = state.aventuraAtual;
    if (av == null) return;
    final mapa = av.mapas.where((m) => m.id == id).firstOrNull;
    if (mapa == null) return;
    final novoId = 'map_${DateTime.now().millisecondsSinceEpoch}';
    final mapaClonado = MapaBatalhaMestre(
      id: novoId,
      nome: '${mapa.nome} (Cópia)',
      largura: mapa.largura,
      altura: mapa.altura,
      presetFundo: mapa.presetFundo,
      imagemCaminhoLocal: mapa.imagemCaminhoLocal,
      opacidadeGrid: mapa.opacidadeGrid,
      gridVisivel: mapa.gridVisivel,
      corLinhasHex: mapa.corLinhasHex,
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
    _atualizarMapaAtual(mapaEditado);
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
      if (t.id == tokenId) {
        if (!t.condicoes.contains(condicao)) {
          return t.copyWith(condicoes: [...t.condicoes, condicao]);
        }
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

  void duplicarToken(String tokenId, int quantidade) {
    final mapa = state.mapaAtual;
    if (mapa == null) return;
    final tokenBase = mapa.tokens.where((t) => t.id == tokenId).firstOrNull;
    if (tokenBase == null) return;
    final novos = <TokenNoMapa>[];
    for (int i = 1; i <= quantidade; i++) {
      if (mapa.tokens.length + novos.length >= 25) break;
      final novoId = 'tok_${DateTime.now().millisecondsSinceEpoch}_$i';
      novos.add(
        tokenBase.copyWith(
          nome: '${tokenBase.nome} #$i',
          posicao: Posicao2D(
            (tokenBase.posicao.x + i) % mapa.largura,
            tokenBase.posicao.y,
          ),
        ),
      );
    }
    _atualizarMapaAtual(mapa.copyWith(tokens: [...mapa.tokens, ...novos]));
  }

  void enviarMapaAosJogadores() {
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
    if (state.pontoOrigemMedicao == null) {
      emit(state.copyWith(pontoOrigemMedicao: pos, pontoDestinoMedicao: null));
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
    final item = ItemChecklistNota(
      id: 'chk_${DateTime.now().millisecondsSinceEpoch}',
      texto: texto.trim(),
    );
    _atualizarSessaoAtual(ses.copyWith(checklistNotas: [...ses.checklistNotas, item]));
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
    final nomesBanco = _bancoNomesPorRaca[raca] ?? _bancoNomesPorRaca['Humano']!;
    final sobrenomes = _bancoSobrenomesPorRaca[raca] ?? _bancoSobrenomesPorRaca['Humano']!;
    final random = Random();
    final primeiroNome = nomesBanco[random.nextInt(nomesBanco.length)];
    final sobrenome = sobrenomes[random.nextInt(sobrenomes.length)];
    final nomeCompleto = '$primeiroNome $sobrenome';
    final historico = [nomeCompleto, ...state.historicoNomes.take(19)];
    emit(state.copyWith(nomeGeradoAtual: nomeCompleto, historicoNomes: historico));
  }

  void favoritarNome(String nome) {
    if (state.nomesFavoritos.contains(nome)) {
      final novos = state.nomesFavoritos.where((n) => n != nome).toList();
      emit(state.copyWith(nomesFavoritos: novos));
    } else {
      emit(state.copyWith(nomesFavoritos: [nome, ...state.nomesFavoritos]));
    }
  }

  static const List<PerigoMestre> _perigosPadraoT20 = [
    PerigoMestre(
      id: 'per_areia_movedica',
      nome: 'Areia Movediça',
      tipo: 'Terreno',
      cd: 'CD 15 Atletismo',
      dano: 'Afogamento (1d6 PV/rodada se submergir)',
      descricao:
          'Entrar no quadrado custa 3m de deslocamento. Teste de Atletismo no início do turno para não afundar. Cada rodada falha puxa o personagem mais fundo.',
      fixado: true,
    ),
    PerigoMestre(
      id: 'per_poco_estacas',
      nome: 'Poço com Estacas de Ferro',
      tipo: 'Armadilha',
      cd: 'CD 20 Percepção / Ladinagem',
      dano: '3d6 impacto + 2d6 perfuração',
      descricao:
          'Alçapão camuflado com 6 metros de profundidade. Vítimas caem sofrendo dano de queda e empalamento, ficando presas nas estacas enferrujadas.',
      fixado: true,
    ),
    PerigoMestre(
      id: 'per_frio_uivantes',
      nome: 'Frio Extremo das Uivantes',
      tipo: 'Ambiente',
      cd: 'CD 15 Fortitude (por hora)',
      dano: '1d6 dano de frio e Fatigado',
      descricao:
          'Sem agasalhos de pele ou calor mágico, falha no teste causa dano letal de frio e a condição Fatigado (que escala para Exausto e Inconsciente).',
      fixado: true,
    ),
    PerigoMestre(
      id: 'per_lava',
      nome: 'Lava Vulcânica',
      tipo: 'Terreno',
      cd: 'CD 20 Reflexos',
      dano: '6d6 fogo (toque) / 12d6 fogo (imersão)',
      descricao:
          'Contato direto queima imediatamente. Imersão parcial incinera equipamentos inflamáveis e causa dano contínuo extremo até ser retirado.',
    ),
    PerigoMestre(
      id: 'per_gas_asfixiante',
      nome: 'Gás de Enxofre Asfixiante',
      tipo: 'Ambiente',
      cd: 'CD 18 Fortitude',
      dano: '2d4 perda de vida e Asfixiado',
      descricao:
          'Vazamento subterrâneo denso. Falha causa condição Enjoado e impede a respiração natural. Ignora redução de dano (perda de vida direta).',
    ),
    PerigoMestre(
      id: 'per_runa_explosiva',
      nome: 'Runa Arcana Explosiva',
      tipo: 'Armadilha',
      cd: 'CD 22 Misticismo',
      dano: '4d8 essência / fogo (raio 4,5m)',
      descricao:
          'Glifo gravado no piso que detona ao ser pisado. Reflexos CD 22 reduz o dano à metade. Dispersar exige sucesso em teste de Misticismo.',
    ),
  ];

  static const Map<String, List<String>> _bancoNomesPorRaca = {
    'Humano': ['Aldor', 'Thalon', 'Valen', 'Brendan', 'Elenor', 'Selena', 'Gareth', 'Mirian', 'Lorcan', 'Kaelen'],
    'Elfo': ['Eladrien', 'Faenor', 'Sylvana', 'Thalion', 'Alysia', 'Kaelis', 'Liadon', 'Sariel', 'Galanodel', 'Celeborn'],
    'Anão': ['Thorin', 'Balgur', 'Durnan', 'Helga', 'Brunhild', 'Orgrim', 'Kragan', 'Dwalin', 'Keldor', 'Moradin'],
    'Qareen': ['Zahir', 'Yasmin', 'Aziz', 'Soraya', 'Jamil', 'Farah', 'Malik', 'Samira', 'Tariq', 'Layla'],
    'Minotauro': ['Tauron', 'Asterios', 'Kragor', 'Gorgon', 'Bravus', 'Thorgar', 'Minos', 'Corax', 'Voldur', 'Rorik'],
    'Lefou': ['Keth', 'Xylar', 'Vorz', 'Nyx', 'Malakor', 'Zalthor', 'Kyros', 'Gorgath', 'Veth', 'Szar'],
    'Goblin': ['Grik', 'Snikt', 'Razz', 'Nokk', 'Pip', 'Zul', 'Blix', 'Krag', 'Snarl', 'Grib'],
    'Dahllan': ['Flora', 'Silvia', 'Daphne', 'Dryas', 'Verdan', 'Linden', 'Bramble', 'Rowan', 'Briar', 'Ivy'],
  };

  static const Map<String, List<String>> _bancoSobrenomesPorRaca = {
    'Humano': ['de Valkaria', 'Ferrobraço', 'da Colina', 'Valente', 'do Vento', 'Machado-Largo', 'Guarda-Real', 'Corvomar'],
    'Elfo': ['Folha-de-Prata', 'Estrela-D’Alva', 'do Rio Silente', 'Raio-da-Manhã', 'Canto-Verde', 'Luar-Eterno', 'Passo-Leve'],
    'Anão': ['Barba-de-Ferro', 'Martelo-Pesado', 'Mina-Profunda', 'Quebra-Rochas', 'Escudo-de-Bronze', 'Pedra-Negra'],
    'Qareen': ['al-Zahir', 'do Fogo-Fátuo', 'da Brisa-Doce', 'al-Hassan', 'das Areias-Douradas', 'do Poço-Azul'],
    'Minotauro': ['Chifre-de-Aço', 'Fúria-de-Tauron', 'Labiríntico', 'Forte-como-Montanha', 'Casco-Bruto'],
    'Lefou': ['Sangue-Rubro', 'Olhar-Torto', 'do Vazio', 'Pele-de-Quitina', 'Toque-da-Mancha'],
    'Goblin': ['Dente-Torto', 'Ladrão-de-Carvão', 'Fura-Bolso', 'Mão-Leve', 'Pavio-Curto', 'Trabuco'],
    'Dahllan': ['Raiz-Firme', 'Flor-de-Espinho', 'do Carvalho-Antigo', 'Casca-Verde', 'da Floresta-Alta'],
  };

  static const List<RegraCard> _regrasPadraoT20 = [
    RegraCard(
      id: 'reg_caido',
      titulo: 'Caído (Condição)',
      categoria: 'Condição',
      corpo:
          '• -5 nos ataques corpo a corpo; deslocamento reduzido a 1,5m.\n• Defesa: -5 contra ataques corpo a corpo e +5 contra ataques à distância.\n• Levantar-se gasta uma Ação de Movimento.',
      fixado: true,
    ),
    RegraCard(
      id: 'reg_desprevenido',
      titulo: 'Desprevenido (Condição)',
      categoria: 'Condição',
      corpo:
          '• A criatura sofre -5 na Defesa e em Reflexos.\n• Você fica desprevenido contra inimigos que não possa perceber.',
      fixado: true,
    ),
    RegraCard(
      id: 'reg_flanquear',
      titulo: 'Flanquear (R75)',
      categoria: 'Combate',
      corpo:
          '• Dois aliados ameaçando o mesmo inimigo em lados estritamente opostos recebem +2 nos testes de ataque corpo a corpo.\n• Não se aplica a ataques à distância.',
      fixado: true,
    ),
    RegraCard(
      id: 'reg_manobras',
      titulo: 'Manobras: Agarrar, Derrubar, Desarmar, Empurrar, Quebrar',
      categoria: 'Ação Padrão',
      corpo:
          '• Substitui um ataque corpo a corpo por um teste oposto de Luta.\n• Qualquer personagem pode executar manobras de combate.',
    ),
    RegraCard(
      id: 'reg_camuflagem',
      titulo: 'Camuflagem e Cobertura (R74)',
      categoria: 'Ambiente',
      corpo:
          '• Cobertura Leve: +5 na Defesa e Reflexos.\n• Camuflagem Leve: 20% de chance de falha.\n• Camuflagem Total / Atacante Cego: 50% de chance de falha (acumula até o teto de 75%).',
    ),
    RegraCard(
      id: 'reg_morte',
      titulo: 'Ferimentos, Sangramento e Morte (R71)',
      categoria: 'Combate',
      corpo:
          '• Com 0 ou menos PV: cai inconsciente e sangrando.\n• Início do turno: teste de Constituição (CD 15). Sucesso estabiliza; falha perde 1d6 PV.\n• Morte: ao atingir -10 PV ou metade dos PV máximos negativos (o que for menor).',
    ),
  ];
}
