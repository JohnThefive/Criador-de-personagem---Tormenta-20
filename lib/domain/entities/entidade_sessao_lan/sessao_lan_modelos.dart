import 'package:equatable/equatable.dart';
import '../../../presentation/controllers/ficha_controller/ficha_state.dart';
import '../../services/ficha_services/personagem_storage_service.dart';
import '../combate/grid_tatico.dart';
import '../mestre/modelos_mestre.dart';

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
  });

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
      ipJogador: ipJogador,
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
  });

  /// Constrói a visão segura para jogadores a partir de um [MapaBatalhaMestre].
  factory SnapshotMesa.sanitizadoDeMapa(MapaBatalhaMestre mapa) {
    final tokensSeguros = mapa.tokens
        .where((t) => t.visivelParaJogadores)
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
        tokensSeguros.any((t) => t.id == mapa.tokenTurnoAtualId)
            ? mapa.tokenTurnoAtualId
            : null;

    return SnapshotMesa(
      mapaId: mapa.id,
      nomeMapa: mapa.nome,
      largura: mapa.largura,
      altura: mapa.altura,
      rodadaCombate: mapa.rodadaCombate,
      tokenTurnoAtualId: turnoVisivel,
      presetFundo: mapa.presetFundo,
      gridVisivel: mapa.gridVisivel,
      opacidadeGrid: mapa.opacidadeGrid,
      terrenos: Map<Posicao2D, TipoTerreno>.from(mapa.terrenos),
      celulasReveladas: Set<Posicao2D>.from(mapa.celulasReveladas),
      tokensVisiveis: tokensSeguros,
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
      };

  factory SnapshotMesa.fromJson(Map<String, dynamic> json) {
    final terrenosRaw = json['terrenos'] as List<dynamic>? ?? const [];
    final reveladasRaw = json['celulasReveladas'] as List<dynamic>? ?? const [];
    final tokensRaw = json['tokensVisiveis'] as List<dynamic>? ?? const [];

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
      ];
}
