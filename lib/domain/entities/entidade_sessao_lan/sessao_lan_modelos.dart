import 'package:equatable/equatable.dart';
import '../../../presentation/controllers/ficha_controller/ficha_state.dart';
import '../../services/ficha_services/personagem_storage_service.dart';
import '../combate/grid_tatico.dart';
import '../habilidades/modelos_habilidade_duracao.dart';
import '../mestre/modelos_mestre.dart';

/// Utilitário compartilhado para normalização e validação do código de sala LAN (`T20-XXXX`).
class CodigoSalaLan {
  CodigoSalaLan._();

  static final RegExp regexValido = RegExp(r'^T20-\d{4}$');

  /// Normaliza entrada do usuário: uppercase e prefixo `T20-` automático quando
  /// informados 4 dígitos (`7492`) ou `T20XXXX` sem hífen.
  static String normalizar(String raw) {
    final limpo = raw.trim().toUpperCase().replaceAll(
      RegExp(r'[^A-Z0-9-]'),
      '',
    );
    if (limpo.isEmpty) return '';
    if (RegExp(r'^\d{4}$').hasMatch(limpo)) {
      return 'T20-$limpo';
    }
    if (RegExp(r'^T20\d{4}$').hasMatch(limpo)) {
      return 'T20-${limpo.substring(3)}';
    }
    return limpo;
  }

  static bool ehValido(String codigo) =>
      regexValido.hasMatch(normalizar(codigo));
}

/// Estado de conexão da aba Sessão na Ficha do Jogador.
enum EstadoConexaoJogador {
  desconectado,
  conectando,
  aguardandoAprovacao,
  conectado,
  erro,
}

/// Tipo de evento emitido pelo transporte do cliente para o [SessaoJogadorCubit].
enum TipoEventoSessaoCliente {
  estadoAlterado,
  aprovada,
  recusada,
  erro,
  desconectado,
}

/// DTO enviado pelo Jogador ao tentar entrar em uma sessão do Mestre pela LAN.
class SolicitacaoEntradaSessao extends Equatable {
  final String codigoSala;
  final String characterId;
  final String nomePersonagem;
  final String nomeJogador;
  final String classeResumo;
  final int pvAtual;
  final int pvMax;
  final int pmAtual;
  final int pmMax;
  final int defesa;
  final double deslocamentoMetros;
  final Map<String, dynamic>? snapshotPersonagem;
  final String? ipRemoto;

  const SolicitacaoEntradaSessao({
    required this.codigoSala,
    required this.characterId,
    required this.nomePersonagem,
    required this.nomeJogador,
    required this.classeResumo,
    required this.pvAtual,
    required this.pvMax,
    required this.pmAtual,
    required this.pmMax,
    required this.defesa,
    required this.deslocamentoMetros,
    this.snapshotPersonagem,
    this.ipRemoto,
  });

  SolicitacaoEntradaSessao copyWith({
    String? ipRemoto,
  }) {
    return SolicitacaoEntradaSessao(
      codigoSala: codigoSala,
      characterId: characterId,
      nomePersonagem: nomePersonagem,
      nomeJogador: nomeJogador,
      classeResumo: classeResumo,
      pvAtual: pvAtual,
      pvMax: pvMax,
      pmAtual: pmAtual,
      pmMax: pmMax,
      defesa: defesa,
      deslocamentoMetros: deslocamentoMetros,
      snapshotPersonagem: snapshotPersonagem,
      ipRemoto: ipRemoto ?? this.ipRemoto,
    );
  }

  factory SolicitacaoEntradaSessao.fromFichaState(
    FichaState state, {
    required String codigoSala,
    required String nomeJogador,
    bool incluirSnapshot = true,
  }) {
    final p = state.personagem;
    final classes = p.classes.isEmpty
        ? 'Aventureiro 1'
        : p.classes
            .map((c) => '${c.classeDefinicao.nome} ${c.nivel}')
            .join(' / ');

    return SolicitacaoEntradaSessao(
      codigoSala: codigoSala.trim().toUpperCase(),
      characterId: p.id,
      nomePersonagem: p.nome.trim().isEmpty ? 'Herói' : p.nome.trim(),
      nomeJogador: nomeJogador.trim().isEmpty ? 'Jogador' : nomeJogador.trim(),
      classeResumo: classes,
      pvAtual: p.pvAtual,
      pvMax: p.pvTotal,
      pmAtual: p.pmAtual,
      pmMax: p.pmTotal,
      defesa: p.defesaFinal,
      deslocamentoMetros: p.deslocamentoEfetivoMetros.toDouble(),
      snapshotPersonagem:
          incluirSnapshot ? PersonagemStorageService.personagemToMap(p) : null,
    );
  }

  /// Converte 1:1 para o registro de elenco da sessão do Mestre.
  ElencoSessaoEntry toElencoEntry({
    StatusRevisaoFicha statusRevisao = StatusRevisaoFicha.pendente,
    bool conectadoViaLan = true,
    String? ipJogador,
  }) {
    return ElencoSessaoEntry(
      characterId: characterId,
      nomePersonagem: nomePersonagem,
      nomeJogador: nomeJogador,
      classeResumo: classeResumo,
      pvAtual: pvAtual,
      pvMax: pvMax,
      pmAtual: pmAtual,
      pmMax: pmMax,
      defesa: defesa,
      deslocamentoMetros: deslocamentoMetros,
      statusRevisao: statusRevisao,
      conectadoViaLan: conectadoViaLan,
      ipJogador: ipJogador ?? ipRemoto,
    );
  }

  Map<String, dynamic> toJson() => {
        'codigoSala': codigoSala,
        'characterId': characterId,
        'nomePersonagem': nomePersonagem,
        'nomeJogador': nomeJogador,
        'classeResumo': classeResumo,
        'pvAtual': pvAtual,
        'pvMax': pvMax,
        'pmAtual': pmAtual,
        'pmMax': pmMax,
        'defesa': defesa,
        'deslocamentoMetros': deslocamentoMetros,
        if (snapshotPersonagem != null)
          'snapshotPersonagem': snapshotPersonagem,
        if (ipRemoto != null) 'ipRemoto': ipRemoto,
      };

  factory SolicitacaoEntradaSessao.fromJson(Map<String, dynamic> json) {
    return SolicitacaoEntradaSessao(
      codigoSala: (json['codigoSala'] ?? '').toString(),
      characterId: (json['characterId'] ?? '').toString(),
      nomePersonagem: (json['nomePersonagem'] ?? 'Herói').toString(),
      nomeJogador: (json['nomeJogador'] ?? 'Jogador').toString(),
      classeResumo: (json['classeResumo'] ?? '').toString(),
      pvAtual: (json['pvAtual'] as num?)?.toInt() ?? 1,
      pvMax: (json['pvMax'] as num?)?.toInt() ?? 1,
      pmAtual: (json['pmAtual'] as num?)?.toInt() ?? 0,
      pmMax: (json['pmMax'] as num?)?.toInt() ?? 0,
      defesa: (json['defesa'] as num?)?.toInt() ?? 10,
      deslocamentoMetros:
          (json['deslocamentoMetros'] as num?)?.toDouble() ?? 9.0,
      snapshotPersonagem: json['snapshotPersonagem'] is Map
          ? Map<String, dynamic>.from(json['snapshotPersonagem'] as Map)
          : null,
      ipRemoto: json['ipRemoto']?.toString(),
    );
  }

  @override
  List<Object?> get props => [
        codigoSala,
        characterId,
        nomePersonagem,
        nomeJogador,
        classeResumo,
        pvAtual,
        pvMax,
        pmAtual,
        pmMax,
        defesa,
        deslocamentoMetros,
        snapshotPersonagem,
        ipRemoto,
      ];
}

/// Atualização incremental de combate/recursos enviada pelo Jogador conectado.
class AtualizacaoPersonagemSessao extends Equatable {
  final String characterId;
  final int pvAtual;
  final int pvMax;
  final int pmAtual;
  final int pmMax;
  final int defesa;
  final int? iniciativa;
  final List<String>? condicoes;

  const AtualizacaoPersonagemSessao({
    required this.characterId,
    required this.pvAtual,
    required this.pvMax,
    required this.pmAtual,
    required this.pmMax,
    required this.defesa,
    this.iniciativa,
    this.condicoes,
  });

  factory AtualizacaoPersonagemSessao.fromFichaState(FichaState state) {
    final p = state.personagem;
    return AtualizacaoPersonagemSessao(
      characterId: p.id,
      pvAtual: p.pvAtual,
      pvMax: p.pvTotal,
      pmAtual: p.pmAtual,
      pmMax: p.pmTotal,
      defesa: p.defesaFinal,
    );
  }

  Map<String, dynamic> toJson() => {
        'characterId': characterId,
        'pvAtual': pvAtual,
        'pvMax': pvMax,
        'pmAtual': pmAtual,
        'pmMax': pmMax,
        'defesa': defesa,
        if (iniciativa != null) 'iniciativa': iniciativa,
        if (condicoes != null) 'condicoes': condicoes,
      };

  factory AtualizacaoPersonagemSessao.fromJson(Map<String, dynamic> json) {
    return AtualizacaoPersonagemSessao(
      characterId: (json['characterId'] ?? '').toString(),
      pvAtual: (json['pvAtual'] as num?)?.toInt() ?? 0,
      pvMax: (json['pvMax'] as num?)?.toInt() ?? 1,
      pmAtual: (json['pmAtual'] as num?)?.toInt() ?? 0,
      pmMax: (json['pmMax'] as num?)?.toInt() ?? 0,
      defesa: (json['defesa'] as num?)?.toInt() ?? 10,
      iniciativa: (json['iniciativa'] as num?)?.toInt(),
      condicoes: (json['condicoes'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
        characterId,
        pvAtual,
        pvMax,
        pmAtual,
        pmMax,
        defesa,
        iniciativa,
        condicoes,
      ];
}

/// Evento emitido pelo transporte cliente sobre o ciclo de vida da conexão.
class EventoSessaoCliente extends Equatable {
  final EstadoConexaoJogador estado;
  final TipoEventoSessaoCliente tipo;
  final String? codigoSala;
  final String? characterId;
  final String? mensagem;

  const EventoSessaoCliente({
    required this.estado,
    required this.tipo,
    this.codigoSala,
    this.characterId,
    this.mensagem,
  });

  /// Mapeia uma decisão de revisão de ficha do Mestre para o evento correspondente ao cliente.
  factory EventoSessaoCliente.deRevisaoFicha({
    required StatusRevisaoFicha status,
    required String characterId,
    String? codigoSala,
    String? notaRevisao,
  }) {
    return switch (status) {
      StatusRevisaoFicha.aprovada => EventoSessaoCliente(
        estado: EstadoConexaoJogador.conectado,
        tipo: TipoEventoSessaoCliente.aprovada,
        codigoSala: codigoSala,
        characterId: characterId,
        mensagem: notaRevisao,
      ),
      StatusRevisaoFicha.pendente ||
      StatusRevisaoFicha.desatualizada => EventoSessaoCliente(
        estado: EstadoConexaoJogador.aguardandoAprovacao,
        tipo: TipoEventoSessaoCliente.estadoAlterado,
        codigoSala: codigoSala,
        characterId: characterId,
      ),
      StatusRevisaoFicha.alteracoesSolicitadas ||
      StatusRevisaoFicha.recusada => EventoSessaoCliente(
        estado: EstadoConexaoJogador.erro,
        tipo: TipoEventoSessaoCliente.recusada,
        codigoSala: codigoSala,
        characterId: characterId,
        mensagem:
            notaRevisao ??
            (status == StatusRevisaoFicha.alteracoesSolicitadas
                ? 'O Mestre solicitou alterações na ficha.'
                : 'Entrada recusada pelo Mestre.'),
      ),
    };
  }

  Map<String, dynamic> toJson() => {
        'estado': estado.name,
        'tipo': tipo.name,
        if (codigoSala != null) 'codigoSala': codigoSala,
        if (characterId != null) 'characterId': characterId,
        if (mensagem != null) 'mensagem': mensagem,
      };

  factory EventoSessaoCliente.fromJson(Map<String, dynamic> json) {
    return EventoSessaoCliente(
      estado: EstadoConexaoJogador.values.firstWhere(
        (e) => e.name == json['estado']?.toString(),
        orElse: () => EstadoConexaoJogador.desconectado,
      ),
      tipo: TipoEventoSessaoCliente.values.firstWhere(
        (e) => e.name == json['tipo']?.toString(),
        orElse: () => TipoEventoSessaoCliente.estadoAlterado,
      ),
      codigoSala: json['codigoSala']?.toString(),
      characterId: json['characterId']?.toString(),
      mensagem: json['mensagem']?.toString(),
    );
  }

  @override
  List<Object?> get props => [estado, tipo, codigoSala, characterId, mensagem];
}

/// Template de Área de Efeito ativo no mapa da sessão LAN (do Mestre ou de um Jogador).
class AreaEfeitoAtivaLan extends Equatable {
  final String id;
  final String criadorId;
  final String rotulo;
  final TipoArea tipo;
  final double tamanhoMetros;
  final Set<Posicao2D> celulasAfetadas;
  final Set<Posicao2D> celulasBloqueadas;
  final VerticeGrid? centroVertice;
  final bool ehDoMestre;

  const AreaEfeitoAtivaLan({
    required this.id,
    required this.criadorId,
    required this.rotulo,
    required this.tipo,
    required this.tamanhoMetros,
    required this.celulasAfetadas,
    this.celulasBloqueadas = const {},
    this.centroVertice,
    this.ehDoMestre = false,
  });

  /// Filtra as células afetadas para manter apenas aquelas dentro das células reveladas
  /// pelo Fog of War, evitando vazamento de salas ocultas pela rede.
  AreaEfeitoAtivaLan? sanitizadaParaCelulasReveladas(
    Set<Posicao2D> celulasReveladas,
  ) {
    final visiveis = celulasAfetadas.intersection(celulasReveladas);
    if (visiveis.isEmpty) return null;
    return AreaEfeitoAtivaLan(
      id: id,
      criadorId: criadorId,
      rotulo: rotulo,
      tipo: tipo,
      tamanhoMetros: tamanhoMetros,
      celulasAfetadas: visiveis,
      centroVertice: centroVertice,
      ehDoMestre: ehDoMestre,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'criadorId': criadorId,
        'rotulo': rotulo,
        'tipo': tipo.name,
        'tamanhoMetros': tamanhoMetros,
        'celulasAfetadas': celulasAfetadas
            .map((p) => {'x': p.x, 'y': p.y})
            .toList(growable: false),
        if (centroVertice != null) 'centroVertice': centroVertice!.toJson(),
        'ehDoMestre': ehDoMestre,
      };

  factory AreaEfeitoAtivaLan.fromJson(Map<String, dynamic> json) {
    final celsRaw = json['celulasAfetadas'] as List<dynamic>? ?? const [];
    final vertRaw = json['centroVertice'] as Map?;
    return AreaEfeitoAtivaLan(
      id: (json['id'] ?? '').toString(),
      criadorId: (json['criadorId'] ?? '').toString(),
      rotulo: (json['rotulo'] ?? 'Área').toString(),
      tipo: TipoArea.values.firstWhere(
        (e) => e.name == json['tipo']?.toString(),
        orElse: () => TipoArea.esfera,
      ),
      tamanhoMetros: (json['tamanhoMetros'] as num?)?.toDouble() ?? 6.0,
      celulasAfetadas: celsRaw
          .whereType<Map>()
          .map(
            (m) => Posicao2D(
              (m['x'] as num?)?.toInt() ?? 0,
              (m['y'] as num?)?.toInt() ?? 0,
            ),
          )
          .toSet(),
      centroVertice: vertRaw != null
          ? VerticeGrid.fromJson(Map<String, dynamic>.from(vertRaw))
          : null,
      ehDoMestre: json['ehDoMestre'] == true,
    );
  }

  @override
  List<Object?> get props => [
        id,
        criadorId,
        rotulo,
        tipo,
        tamanhoMetros,
        celulasAfetadas,
        celulasBloqueadas,
        centroVertice,
        ehDoMestre,
      ];
}

/// Magia lançada por um Jogador conectado via LAN aguardando resolução rápida (1 toque)
/// pelo Mestre (Total / Metade / Ignorar por alvo ou em lote).
class EventoMagiaLanPendente extends Equatable {
  final String id;
  final String lancadorId;
  final String lancadorNome;
  final String magiaNome;
  final int custoPm;
  final String expressaoDados;
  final int valorRolado;
  final bool ehCura;
  final String? rotuloArea;
  final List<String> alvosPendentesIds;

  const EventoMagiaLanPendente({
    required this.id,
    required this.lancadorId,
    required this.lancadorNome,
    required this.magiaNome,
    required this.custoPm,
    required this.expressaoDados,
    required this.valorRolado,
    required this.ehCura,
    this.rotuloArea,
    required this.alvosPendentesIds,
  });

  int get valorMetade => (valorRolado / 2).floor();

  EventoMagiaLanPendente copyWith({List<String>? alvosPendentesIds}) {
    return EventoMagiaLanPendente(
      id: id,
      lancadorId: lancadorId,
      lancadorNome: lancadorNome,
      magiaNome: magiaNome,
      custoPm: custoPm,
      expressaoDados: expressaoDados,
      valorRolado: valorRolado,
      ehCura: ehCura,
      rotuloArea: rotuloArea,
      alvosPendentesIds: alvosPendentesIds ?? this.alvosPendentesIds,
    );
  }

  @override
  List<Object?> get props => [
        id,
        lancadorId,
        lancadorNome,
        magiaNome,
        custoPm,
        expressaoDados,
        valorRolado,
        ehCura,
        rotuloArea,
        alvosPendentesIds,
      ];
}

/// Snapshot sanitizado do [MapaBatalhaMestre] enviado pelo Host aos jogadores.
/// Nunca inclui tokens ocultos ao jogador nem a ficha completa de monstros do Mestre.
class SnapshotMesa extends Equatable {
  final String mapaId;
  final String nomeMapa;
  final int largura;
  final int altura;
  final int rodadaCombate;
  final String? tokenTurnoAtualId;
  final PresetFundoMapa presetFundo;
  final bool gridVisivel;
  final double opacidadeGrid;
  final Map<Posicao2D, TipoTerreno> terrenos;
  final Set<Posicao2D> celulasReveladas;
  final List<TokenNoMapa> tokensVisiveis;
  final List<AreaEfeitoAtivaLan> areasEfeitoVisiveis;

  const SnapshotMesa({
    required this.mapaId,
    required this.nomeMapa,
    required this.largura,
    required this.altura,
    this.rodadaCombate = 1,
    this.tokenTurnoAtualId,
    this.presetFundo = PresetFundoMapa.masmorraPedra,
    this.gridVisivel = true,
    this.opacidadeGrid = 0.35,
    this.terrenos = const {},
    this.celulasReveladas = const {},
    this.tokensVisiveis = const [],
    this.areasEfeitoVisiveis = const [],
  });

  /// Constrói a visão segura para jogadores a partir de um [MapaBatalhaMestre].
  /// Aplica [projectMapaFor] com [VisaoMestreComoJogador] para jamais vazar
  /// terrenos, tokens ou áreas de efeito em células sob Névoa de Guerra pela rede.
  factory SnapshotMesa.sanitizadoDeMapa(
    MapaBatalhaMestre mapa, {
    List<AreaEfeitoAtivaLan> areasEfeito = const [],
  }) {
    final mapaProjetado = projectMapaFor(const VisaoMestreComoJogador(), mapa);
    final tokensSeguros = mapaProjetado.tokens
        .map(
          (t) => TokenNoMapa(
            id: t.id,
            nome: t.nome,
            posicao: t.posicao,
            ehHeroi: t.ehHeroi,
            tipo: t.tipo,
            pvAtual: t.pvAtual,
            pvMax: t.pvMax,
            pmAtual: t.pmAtual,
            pmMax: t.pmMax,
            defesa: t.defesa,
            deslocamentoMetros: t.deslocamentoMetros,
            tamanhoQuadrados: t.tamanhoQuadrados,
            condicoes: t.condicoes,
            visibilidade: t.visibilidade,
            iniciativa: t.iniciativa,
          ),
        )
        .toList(growable: false);

    final turnoVisivel =
        tokensSeguros.any((t) => t.id == mapaProjetado.tokenTurnoAtualId)
            ? mapaProjetado.tokenTurnoAtualId
            : null;

    final areasSeguras = <AreaEfeitoAtivaLan>[];
    for (final area in areasEfeito) {
      final sanitizada = area.sanitizadaParaCelulasReveladas(
        mapaProjetado.celulasReveladas,
      );
      if (sanitizada != null) {
        areasSeguras.add(sanitizada);
      }
    }

    return SnapshotMesa(
      mapaId: mapaProjetado.id,
      nomeMapa: mapaProjetado.nome,
      largura: mapaProjetado.largura,
      altura: mapaProjetado.altura,
      rodadaCombate: mapaProjetado.rodadaCombate,
      tokenTurnoAtualId: turnoVisivel,
      presetFundo: mapaProjetado.presetFundo,
      gridVisivel: mapaProjetado.gridVisivel,
      opacidadeGrid: mapaProjetado.opacidadeGrid,
      terrenos: Map<Posicao2D, TipoTerreno>.from(mapaProjetado.terrenos),
      celulasReveladas: Set<Posicao2D>.from(mapaProjetado.celulasReveladas),
      tokensVisiveis: tokensSeguros,
      areasEfeitoVisiveis: List.unmodifiable(areasSeguras),
    );
  }

  Map<String, dynamic> toJson() => {
        'mapaId': mapaId,
        'nomeMapa': nomeMapa,
        'largura': largura,
        'altura': altura,
        'rodadaCombate': rodadaCombate,
        if (tokenTurnoAtualId != null) 'tokenTurnoAtualId': tokenTurnoAtualId,
        'presetFundo': presetFundo.name,
        'gridVisivel': gridVisivel,
        'opacidadeGrid': opacidadeGrid,
        'terrenos': terrenos.entries
            .where((e) => e.value != TipoTerreno.normal)
            .map(
              (e) => {
                'x': e.key.x,
                'y': e.key.y,
                'tipo': e.value.name,
              },
            )
            .toList(growable: false),
        'celulasReveladas': celulasReveladas
            .map((p) => {'x': p.x, 'y': p.y})
            .toList(growable: false),
        'tokensVisiveis':
            tokensVisiveis.map((t) => t.toJson()).toList(growable: false),
        if (areasEfeitoVisiveis.isNotEmpty)
          'areasEfeitoVisiveis': areasEfeitoVisiveis
              .map((a) => a.toJson())
              .toList(growable: false),
      };

  factory SnapshotMesa.fromJson(Map<String, dynamic> json) {
    final terrenosRaw = json['terrenos'] as List<dynamic>? ?? const [];
    final reveladasRaw = json['celulasReveladas'] as List<dynamic>? ?? const [];
    final tokensRaw = json['tokensVisiveis'] as List<dynamic>? ?? const [];
    final areasRaw = json['areasEfeitoVisiveis'] as List<dynamic>? ?? const [];

    final mapaTerrenos = <Posicao2D, TipoTerreno>{};
    for (final item in terrenosRaw.whereType<Map>()) {
      final x = (item['x'] as num?)?.toInt();
      final y = (item['y'] as num?)?.toInt();
      final tipoStr = item['tipo']?.toString();
      if (x == null || y == null || tipoStr == null) continue;
      final tipo = TipoTerreno.values.firstWhere(
        (t) => t.name == tipoStr,
        orElse: () => TipoTerreno.normal,
      );
      if (tipo != TipoTerreno.normal) {
        mapaTerrenos[Posicao2D(x, y)] = tipo;
      }
    }

    return SnapshotMesa(
      mapaId: (json['mapaId'] ?? '').toString(),
      nomeMapa: (json['nomeMapa'] ?? 'Mapa').toString(),
      largura: (json['largura'] as num?)?.toInt() ?? 16,
      altura: (json['altura'] as num?)?.toInt() ?? 12,
      rodadaCombate: (json['rodadaCombate'] as num?)?.toInt() ?? 1,
      tokenTurnoAtualId: json['tokenTurnoAtualId']?.toString(),
      presetFundo: PresetFundoMapa.values.firstWhere(
        (e) => e.name == json['presetFundo']?.toString(),
        orElse: () => PresetFundoMapa.masmorraPedra,
      ),
      gridVisivel: json['gridVisivel'] != false,
      opacidadeGrid: (json['opacidadeGrid'] as num?)?.toDouble() ?? 0.35,
      terrenos: mapaTerrenos,
      celulasReveladas: reveladasRaw
          .whereType<Map>()
          .map(
            (m) => Posicao2D(
              (m['x'] as num?)?.toInt() ?? 0,
              (m['y'] as num?)?.toInt() ?? 0,
            ),
          )
          .toSet(),
      tokensVisiveis: tokensRaw
          .whereType<Map>()
          .map((m) => TokenNoMapa.fromJson(Map<String, dynamic>.from(m)))
          .where((t) => t.visivelParaJogadores)
          .toList(growable: false),
      areasEfeitoVisiveis: areasRaw
          .whereType<Map>()
          .map((m) => AreaEfeitoAtivaLan.fromJson(Map<String, dynamic>.from(m)))
          .toList(growable: false),
    );
  }

  @override
  List<Object?> get props => [
        mapaId,
        nomeMapa,
        largura,
        altura,
        rodadaCombate,
        tokenTurnoAtualId,
        presetFundo,
        gridVisivel,
        opacidadeGrid,
        terrenos,
        celulasReveladas,
        tokensVisiveis,
        areasEfeitoVisiveis,
      ];
}
