import '../combate/grid_tatico.dart';
import '../combate/monstro.dart';

/// ADR-003 §3.1: Controle de visibilidade de qualquer entidade gerenciada pelo Mestre.
sealed class Visibilidade {
  const Visibilidade();

  Map<String, dynamic> toJson();

  factory Visibilidade.fromJson(Map<String, dynamic> json) {
    final tipo = json['tipo'] as String? ?? 'somente_mestre';
    switch (tipo) {
      case 'para_todos':
        return const ParaTodos();
      case 'para_jogadores':
        final ids = (json['playerIds'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toSet();
        return ParaJogadores(ids);
      default:
        return const SomenteMestre();
    }
  }
}

final class SomenteMestre extends Visibilidade {
  const SomenteMestre();

  @override
  Map<String, dynamic> toJson() => {'tipo': 'somente_mestre'};
}

final class ParaJogadores extends Visibilidade {
  final Set<String> playerIds;
  const ParaJogadores(this.playerIds);

  @override
  Map<String, dynamic> toJson() => {
        'tipo': 'para_jogadores',
        'playerIds': playerIds.toList(),
      };
}

final class ParaTodos extends Visibilidade {
  const ParaTodos();

  @override
  Map<String, dynamic> toJson() => {'tipo': 'para_todos'};
}

/// ADR-003 §3.1: Papel para cálculo de projeção segura (`projectFor`).
sealed class PapelView {
  const PapelView();
}

final class VisaoMestre extends PapelView {
  const VisaoMestre();
}

final class VisaoMestreComoJogador extends PapelView {
  final String? playerId;
  const VisaoMestreComoJogador({this.playerId});
}

final class VisaoJogador extends PapelView {
  final String playerId;
  const VisaoJogador(this.playerId);
}

/// RF-M1: Status de revisão e aprovação da ficha de um jogador na sessão.
enum StatusRevisaoFicha {
  pendente('Pendente'),
  aprovada('Aprovada'),
  alteracoesSolicitadas('Alterações Solicitadas'),
  recusada('Recusada'),
  desatualizada('Desatualizada');

  final String rotulo;
  const StatusRevisaoFicha(this.rotulo);
}

/// RF-M5: Nível de automação de regras durante os encontros da sessão.
enum NivelAutomacaoMesa {
  automatico('Automático', 'Rola dados, aplica dano/RD e gasta PM automaticamente.'),
  assistido('Assistido', 'Propõe o resultado e aguarda confirmação do Mestre.'),
  manual('Manual', 'Apenas rastreia iniciativa e PV; o Mestre digita os valores.');

  final String rotulo;
  final String descricao;
  const NivelAutomacaoMesa(this.rotulo, this.descricao);
}

/// Status visual (Frontend) da sala LAN hospedada pelo Mestre.
enum StatusConexaoLan {
  desligado('Sala Offline', 'Nenhuma conexão LAN ativa no momento.'),
  aguardandoJogadores('Sala Aberta (Lobby LAN)', 'Aceitando conexões de jogadores na rede local.'),
  emSessaoAtiva('Sessão Sincronizada', 'Jogadores conectados e recebendo projeções em tempo real.');

  final String rotulo;
  final String descricao;
  const StatusConexaoLan(this.rotulo, this.descricao);
}

/// Presets visuais de fundo para mapas quando nenhuma foto externa é escolhida.
enum PresetFundoMapa {
  masmorraPedra('Masmorra de Pedra'),
  florestaArton('Floresta de Arton'),
  tavernaMadeira('Taverna Acolhedora'),
  desertoHalakTur('Areias de Halak-Tûr'),
  areaTormenta('Área de Tormenta'),
  imagemCustomizada('Imagem da Galeria');

  final String rotulo;
  const PresetFundoMapa(this.rotulo);
}

T _enumByName<T extends Enum>(List<T> values, Object? raw, T fallback) {
  final s = raw?.toString();
  if (s == null) return fallback;
  return values.where((v) => v.name == s).firstOrNull ?? fallback;
}

String _posKey(Posicao2D pos) => '${pos.x},${pos.y}';

Posicao2D? _parsePos(String raw) {
  final partes = raw.split(',');
  if (partes.length != 2) return null;
  final x = int.tryParse(partes[0]);
  final y = int.tryParse(partes[1]);
  if (x == null || y == null) return null;
  return Posicao2D(x, y);
}

/// Representa um jogador e seu personagem vinculados a uma Sessão/Aventura (ElencoEntry).
class ElencoSessaoEntry {
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
  final StatusRevisaoFicha statusRevisao;
  final String? notaRevisao;
  final bool conectadoViaLan;
  final String? ipJogador;

  const ElencoSessaoEntry({
    required this.characterId,
    required this.nomePersonagem,
    required this.nomeJogador,
    required this.classeResumo,
    required this.pvAtual,
    required this.pvMax,
    required this.pmAtual,
    required this.pmMax,
    this.defesa = 15,
    this.deslocamentoMetros = 9.0,
    this.statusRevisao = StatusRevisaoFicha.aprovada,
    this.notaRevisao,
    this.conectadoViaLan = false,
    this.ipJogador,
  });

  ElencoSessaoEntry copyWith({
    String? nomePersonagem,
    String? nomeJogador,
    String? classeResumo,
    int? pvAtual,
    int? pvMax,
    int? pmAtual,
    int? pmMax,
    int? defesa,
    double? deslocamentoMetros,
    StatusRevisaoFicha? statusRevisao,
    String? notaRevisao,
    bool? conectadoViaLan,
    String? ipJogador,
  }) {
    return ElencoSessaoEntry(
      characterId: characterId,
      nomePersonagem: nomePersonagem ?? this.nomePersonagem,
      nomeJogador: nomeJogador ?? this.nomeJogador,
      classeResumo: classeResumo ?? this.classeResumo,
      pvAtual: pvAtual ?? this.pvAtual,
      pvMax: pvMax ?? this.pvMax,
      pmAtual: pmAtual ?? this.pmAtual,
      pmMax: pmMax ?? this.pmMax,
      defesa: defesa ?? this.defesa,
      deslocamentoMetros: deslocamentoMetros ?? this.deslocamentoMetros,
      statusRevisao: statusRevisao ?? this.statusRevisao,
      notaRevisao: notaRevisao ?? this.notaRevisao,
      conectadoViaLan: conectadoViaLan ?? this.conectadoViaLan,
      ipJogador: ipJogador ?? this.ipJogador,
    );
  }

  Map<String, dynamic> toJson() => {
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
        'statusRevisao': statusRevisao.name,
        if (notaRevisao != null) 'notaRevisao': notaRevisao,
        'conectadoViaLan': conectadoViaLan,
        if (ipJogador != null) 'ipJogador': ipJogador,
      };

  factory ElencoSessaoEntry.fromJson(Map<String, dynamic> json) {
    return ElencoSessaoEntry(
      characterId: json['characterId']?.toString() ?? '',
      nomePersonagem: json['nomePersonagem']?.toString() ?? 'Personagem',
      nomeJogador: json['nomeJogador']?.toString() ?? 'Jogador',
      classeResumo: json['classeResumo']?.toString() ?? '',
      pvAtual: (json['pvAtual'] as num?)?.toInt() ?? 20,
      pvMax: (json['pvMax'] as num?)?.toInt() ?? 20,
      pmAtual: (json['pmAtual'] as num?)?.toInt() ?? 10,
      pmMax: (json['pmMax'] as num?)?.toInt() ?? 10,
      defesa: (json['defesa'] as num?)?.toInt() ?? 15,
      deslocamentoMetros: (json['deslocamentoMetros'] as num?)?.toDouble() ?? 9.0,
      statusRevisao: _enumByName(
        StatusRevisaoFicha.values,
        json['statusRevisao'],
        StatusRevisaoFicha.aprovada,
      ),
      notaRevisao: json['notaRevisao']?.toString(),
      conectadoViaLan: json['conectadoViaLan'] == true,
      ipJogador: json['ipJogador']?.toString(),
    );
  }
}

/// Tipo de combatente presente no mapa de batalha (Inimigo, NPC, Aliado ou Herói)
enum TipoCombatenteMapa {
  heroi('Herói'),
  aliado('Aliado'),
  npc('NPC'),
  inimigo('Inimigo');

  final String rotulo;
  const TipoCombatenteMapa(this.rotulo);
}

/// Token posicionado no Mapa de Batalha do Mestre.
class TokenNoMapa {
  final String id;
  final String nome;
  final Posicao2D posicao;
  final bool ehHeroi;
  final TipoCombatenteMapa tipo;
  final int pvAtual;
  final int pvMax;
  final int pmAtual;
  final int pmMax;
  final int defesa;
  final int tamanhoQuadrados; // 1 = 1x1, 2 = 2x2, 3 = 3x3
  final int? iniciativa;
  final List<String> condicoes;
  final String? retrato;
  final double deslocamentoMetros;
  final Visibilidade visibilidade;
  final String? monstroId;
  final Monstro? monstro;
  final List<String> habilidadesGastas;

  const TokenNoMapa({
    required this.id,
    required this.nome,
    required this.posicao,
    this.ehHeroi = true,
    TipoCombatenteMapa? tipo,
    this.pvAtual = 20,
    this.pvMax = 20,
    this.pmAtual = 10,
    this.pmMax = 10,
    this.defesa = 15,
    this.tamanhoQuadrados = 1,
    this.iniciativa,
    this.condicoes = const [],
    this.retrato,
    this.deslocamentoMetros = 9.0,
    this.visibilidade = const ParaTodos(),
    this.monstroId,
    this.monstro,
    this.habilidadesGastas = const [],
  }) : tipo = tipo ?? (ehHeroi ? TipoCombatenteMapa.heroi : TipoCombatenteMapa.inimigo);

  bool get visivelParaJogadores => visibilidade is! SomenteMestre;

  TokenNoMapa copyWith({
    String? nome,
    Posicao2D? posicao,
    bool? ehHeroi,
    TipoCombatenteMapa? tipo,
    int? pvAtual,
    int? pvMax,
    int? pmAtual,
    int? pmMax,
    int? defesa,
    int? tamanhoQuadrados,
    int? iniciativa,
    List<String>? condicoes,
    String? retrato,
    double? deslocamentoMetros,
    Visibilidade? visibilidade,
    String? monstroId,
    Monstro? monstro,
    List<String>? habilidadesGastas,
  }) {
    return TokenNoMapa(
      id: id,
      nome: nome ?? this.nome,
      posicao: posicao ?? this.posicao,
      ehHeroi: ehHeroi ?? this.ehHeroi,
      tipo: tipo ?? this.tipo,
      pvAtual: pvAtual ?? this.pvAtual,
      pvMax: pvMax ?? this.pvMax,
      pmAtual: pmAtual ?? this.pmAtual,
      pmMax: pmMax ?? this.pmMax,
      defesa: defesa ?? this.defesa,
      tamanhoQuadrados: tamanhoQuadrados ?? this.tamanhoQuadrados,
      iniciativa: iniciativa ?? this.iniciativa,
      condicoes: condicoes ?? this.condicoes,
      retrato: retrato ?? this.retrato,
      deslocamentoMetros: deslocamentoMetros ?? this.deslocamentoMetros,
      visibilidade: visibilidade ?? this.visibilidade,
      monstroId: monstroId ?? this.monstroId,
      monstro: monstro ?? this.monstro,
      habilidadesGastas: habilidadesGastas ?? this.habilidadesGastas,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'x': posicao.x,
        'y': posicao.y,
        'ehHeroi': ehHeroi,
        'tipo': tipo.name,
        'pvAtual': pvAtual,
        'pvMax': pvMax,
        'pmAtual': pmAtual,
        'pmMax': pmMax,
        'defesa': defesa,
        'tamanhoQuadrados': tamanhoQuadrados,
        if (iniciativa != null) 'iniciativa': iniciativa,
        if (condicoes.isNotEmpty) 'condicoes': condicoes,
        if (retrato != null) 'retrato': retrato,
        'deslocamentoMetros': deslocamentoMetros,
        'visibilidade': visibilidade.toJson(),
        if (monstroId != null) 'monstroId': monstroId,
        if (monstro != null) 'monstro': monstro!.toJson(),
        if (habilidadesGastas.isNotEmpty) 'habilidadesGastas': habilidadesGastas,
      };

  factory TokenNoMapa.fromJson(Map<String, dynamic> json) {
    final ehHeroi = json['ehHeroi'] != false;
    final monstroJson = json['monstro'];
    return TokenNoMapa(
      id: json['id']?.toString() ?? '',
      nome: json['nome']?.toString() ?? 'Combatente',
      posicao: Posicao2D(
        (json['x'] as num?)?.toInt() ?? 0,
        (json['y'] as num?)?.toInt() ?? 0,
      ),
      ehHeroi: ehHeroi,
      tipo: _enumByName(
        TipoCombatenteMapa.values,
        json['tipo'],
        ehHeroi ? TipoCombatenteMapa.heroi : TipoCombatenteMapa.inimigo,
      ),
      pvAtual: (json['pvAtual'] as num?)?.toInt() ?? 20,
      pvMax: (json['pvMax'] as num?)?.toInt() ?? 20,
      pmAtual: (json['pmAtual'] as num?)?.toInt() ?? 10,
      pmMax: (json['pmMax'] as num?)?.toInt() ?? 10,
      defesa: (json['defesa'] as num?)?.toInt() ?? 15,
      tamanhoQuadrados: (json['tamanhoQuadrados'] as num?)?.toInt() ?? 1,
      iniciativa: (json['iniciativa'] as num?)?.toInt(),
      condicoes: (json['condicoes'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      retrato: json['retrato']?.toString(),
      deslocamentoMetros: (json['deslocamentoMetros'] as num?)?.toDouble() ?? 9.0,
      visibilidade: json['visibilidade'] is Map
          ? Visibilidade.fromJson(
              Map<String, dynamic>.from(json['visibilidade'] as Map),
            )
          : const ParaTodos(),
      monstroId: json['monstroId']?.toString(),
      monstro: monstroJson is Map
          ? Monstro.fromJson(Map<String, dynamic>.from(monstroJson))
          : null,
      habilidadesGastas:
          (json['habilidadesGastas'] as List<dynamic>? ?? const [])
              .map((e) => e.toString())
              .toList(),
    );
  }
}

/// RF-M6 & RF-M7: Mapa de Batalha com suporte a imagem de fundo, grid, terrenos,
/// células reveladas (Fog of War) e tokens móveis.
class MapaBatalhaMestre {
  final String id;
  final String nome;
  final int largura;
  final int altura;
  final PresetFundoMapa presetFundo;
  final String? imagemCaminhoLocal;
  final double opacidadeGrid;
  final bool gridVisivel;
  final double ajusteOffsetX;
  final double ajusteOffsetY;
  final double ajusteEscala;
  final double ajusteRotacaoGraus;
  final String? corFundoHex;
  final String notas;
  final DateTime criadoEm;
  final Map<Posicao2D, TipoTerreno> terrenos;
  final Set<Posicao2D> celulasReveladas;
  final List<TokenNoMapa> tokens;
  final int rodadaCombate;
  final String? tokenTurnoAtualId;

  MapaBatalhaMestre({
    required this.id,
    required this.nome,
    this.largura = 12,
    this.altura = 8,
    this.presetFundo = PresetFundoMapa.masmorraPedra,
    this.imagemCaminhoLocal,
    this.opacidadeGrid = 0.35,
    this.gridVisivel = true,
    this.ajusteOffsetX = 0.0,
    this.ajusteOffsetY = 0.0,
    this.ajusteEscala = 1.0,
    this.ajusteRotacaoGraus = 0.0,
    this.corFundoHex,
    this.notas = '',
    DateTime? criadoEm,
    this.terrenos = const {},
    this.celulasReveladas = const {},
    this.tokens = const [],
    this.rodadaCombate = 1,
    this.tokenTurnoAtualId,
  }) : criadoEm = criadoEm ?? DateTime.now();

  GridMapa get comoGridMapa => GridMapa(
        largura: largura,
        altura: altura,
        terrenos: terrenos,
      );

  MapaBatalhaMestre copyWith({
    String? nome,
    int? largura,
    int? altura,
    PresetFundoMapa? presetFundo,
    String? imagemCaminhoLocal,
    bool limparImagemCustomizada = false,
    double? opacidadeGrid,
    bool? gridVisivel,
    double? ajusteOffsetX,
    double? ajusteOffsetY,
    double? ajusteEscala,
    double? ajusteRotacaoGraus,
    String? corFundoHex,
    String? notas,
    DateTime? criadoEm,
    Map<Posicao2D, TipoTerreno>? terrenos,
    Set<Posicao2D>? celulasReveladas,
    List<TokenNoMapa>? tokens,
    int? rodadaCombate,
    String? tokenTurnoAtualId,
    bool limparTurnoAtual = false,
  }) {
    return MapaBatalhaMestre(
      id: id,
      nome: nome ?? this.nome,
      largura: largura ?? this.largura,
      altura: altura ?? this.altura,
      presetFundo: presetFundo ?? this.presetFundo,
      imagemCaminhoLocal: limparImagemCustomizada
          ? null
          : (imagemCaminhoLocal ?? this.imagemCaminhoLocal),
      opacidadeGrid: opacidadeGrid ?? this.opacidadeGrid,
      gridVisivel: gridVisivel ?? this.gridVisivel,
      ajusteOffsetX: ajusteOffsetX ?? this.ajusteOffsetX,
      ajusteOffsetY: ajusteOffsetY ?? this.ajusteOffsetY,
      ajusteEscala: ajusteEscala ?? this.ajusteEscala,
      ajusteRotacaoGraus: ajusteRotacaoGraus ?? this.ajusteRotacaoGraus,
      corFundoHex: corFundoHex ?? this.corFundoHex,
      notas: notas ?? this.notas,
      criadoEm: criadoEm ?? this.criadoEm,
      terrenos: terrenos ?? this.terrenos,
      celulasReveladas: celulasReveladas ?? this.celulasReveladas,
      tokens: tokens ?? this.tokens,
      rodadaCombate: rodadaCombate ?? this.rodadaCombate,
      tokenTurnoAtualId: limparTurnoAtual
          ? null
          : (tokenTurnoAtualId ?? this.tokenTurnoAtualId),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'largura': largura,
        'altura': altura,
        'presetFundo': presetFundo.name,
        if (imagemCaminhoLocal != null) 'imagemCaminhoLocal': imagemCaminhoLocal,
        'opacidadeGrid': opacidadeGrid,
        'gridVisivel': gridVisivel,
        'ajusteOffsetX': ajusteOffsetX,
        'ajusteOffsetY': ajusteOffsetY,
        'ajusteEscala': ajusteEscala,
        'ajusteRotacaoGraus': ajusteRotacaoGraus,
        if (corFundoHex != null) 'corFundoHex': corFundoHex,
        'notas': notas,
        'criadoEm': criadoEm.toIso8601String(),
        'terrenos': {
          for (final e in terrenos.entries) _posKey(e.key): e.value.name,
        },
        'celulasReveladas': celulasReveladas.map(_posKey).toList(),
        'tokens': tokens.map((t) => t.toJson()).toList(),
        'rodadaCombate': rodadaCombate,
        if (tokenTurnoAtualId != null) 'tokenTurnoAtualId': tokenTurnoAtualId,
      };

  factory MapaBatalhaMestre.fromJson(Map<String, dynamic> json) {
    final terrenos = <Posicao2D, TipoTerreno>{};
    final rawTerrenos = json['terrenos'];
    if (rawTerrenos is Map) {
      for (final e in rawTerrenos.entries) {
        final pos = _parsePos(e.key.toString());
        if (pos != null) {
          terrenos[pos] = _enumByName(TipoTerreno.values, e.value, TipoTerreno.normal);
        }
      }
    }
    final reveladas = <Posicao2D>{};
    final rawRev = json['celulasReveladas'];
    if (rawRev is List) {
      for (final item in rawRev) {
        final pos = _parsePos(item.toString());
        if (pos != null) reveladas.add(pos);
      }
    }
    final tokensList = (json['tokens'] as List?)
            ?.whereType<Map>()
            .map((e) => TokenNoMapa.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        const [];
    return MapaBatalhaMestre(
      id: (json['id'] ?? '').toString(),
      nome: (json['nome'] ?? '').toString(),
      largura: (json['largura'] as num?)?.toInt() ?? 12,
      altura: (json['altura'] as num?)?.toInt() ?? 8,
      presetFundo: _enumByName(
        PresetFundoMapa.values,
        json['presetFundo'],
        PresetFundoMapa.masmorraPedra,
      ),
      imagemCaminhoLocal: json['imagemCaminhoLocal']?.toString(),
      opacidadeGrid: (json['opacidadeGrid'] as num?)?.toDouble() ?? 0.35,
      gridVisivel: json['gridVisivel'] != false,
      ajusteOffsetX: (json['ajusteOffsetX'] as num?)?.toDouble() ?? 0.0,
      ajusteOffsetY: (json['ajusteOffsetY'] as num?)?.toDouble() ?? 0.0,
      ajusteEscala: (json['ajusteEscala'] as num?)?.toDouble() ?? 1.0,
      ajusteRotacaoGraus: (json['ajusteRotacaoGraus'] as num?)?.toDouble() ?? 0.0,
      corFundoHex: json['corFundoHex']?.toString(),
      notas: (json['notas'] ?? '').toString(),
      criadoEm: DateTime.tryParse((json['criadoEm'] ?? '').toString()),
      terrenos: terrenos,
      celulasReveladas: reveladas,
      tokens: tokensList,
      rodadaCombate: (json['rodadaCombate'] as num?)?.toInt() ?? 1,
      tokenTurnoAtualId: json['tokenTurnoAtualId']?.toString(),
    );
  }
}

/// ADR-003 §3.1: Função pura de projeção do Mapa de Batalha (`projectFor`).
/// Garante que na visão do jogador (ou preview do mestre):
/// 1. Tokens com `SomenteMestre` ou em células ocultas não aparecem.
/// 2. Terrenos em células não reveladas não são expostos.
MapaBatalhaMestre projectMapaFor(PapelView papel, MapaBatalhaMestre mapa) {
  if (papel is VisaoMestre) {
    return mapa;
  }

  final terrenosVisiveis = <Posicao2D, TipoTerreno>{};
  for (final entry in mapa.terrenos.entries) {
    if (mapa.celulasReveladas.contains(entry.key)) {
      terrenosVisiveis[entry.key] = entry.value;
    }
  }

  final tokensVisiveis = mapa.tokens.where((t) {
    final naCelulaRevelada = mapa.celulasReveladas.contains(t.posicao);
    if (!naCelulaRevelada) return false;
    if (t.visibilidade is SomenteMestre) return false;
    if (t.visibilidade is ParaJogadores && papel is VisaoJogador) {
      return (t.visibilidade as ParaJogadores).playerIds.contains(papel.playerId);
    }
    return true;
  }).toList();

  return mapa.copyWith(
    terrenos: terrenosVisiveis,
    tokens: tokensVisiveis,
  );
}

/// RF-M2: Anotação do Mestre (privada ou compartilhada com jogadores).
class NotaMestre {
  final String id;
  final String titulo;
  final String conteudo;
  final Visibilidade visibilidade;
  final DateTime atualizadoEm;

  const NotaMestre({
    required this.id,
    required this.titulo,
    required this.conteudo,
    this.visibilidade = const SomenteMestre(),
    required this.atualizadoEm,
  });

  bool get compartilhadaComJogadores => visibilidade is! SomenteMestre;

  NotaMestre copyWith({
    String? titulo,
    String? conteudo,
    Visibilidade? visibilidade,
    DateTime? atualizadoEm,
  }) {
    return NotaMestre(
      id: id,
      titulo: titulo ?? this.titulo,
      conteudo: conteudo ?? this.conteudo,
      visibilidade: visibilidade ?? this.visibilidade,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'titulo': titulo,
        'conteudo': conteudo,
        'visibilidade': visibilidade.toJson(),
        'atualizadoEm': atualizadoEm.toIso8601String(),
      };

  factory NotaMestre.fromJson(Map<String, dynamic> json) {
    final visRaw = json['visibilidade'];
    return NotaMestre(
      id: (json['id'] ?? '').toString(),
      titulo: (json['titulo'] ?? '').toString(),
      conteudo: (json['conteudo'] ?? '').toString(),
      visibilidade: visRaw is Map
          ? Visibilidade.fromJson(Map<String, dynamic>.from(visRaw))
          : const SomenteMestre(),
      atualizadoEm:
          DateTime.tryParse((json['atualizadoEm'] ?? '').toString()) ??
              DateTime.now(),
    );
  }
}

/// RF-M9: Handout (documento, pista ou ilustração entregue aos jogadores).
class HandoutMestre {
  final String id;
  final String titulo;
  final String descricao;
  final bool entregueAosJogadores;
  final List<String> lidoPorJogadores;

  const HandoutMestre({
    required this.id,
    required this.titulo,
    required this.descricao,
    this.entregueAosJogadores = false,
    this.lidoPorJogadores = const [],
  });

  HandoutMestre copyWith({
    String? titulo,
    String? descricao,
    bool? entregueAosJogadores,
    List<String>? lidoPorJogadores,
  }) {
    return HandoutMestre(
      id: id,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      entregueAosJogadores: entregueAosJogadores ?? this.entregueAosJogadores,
      lidoPorJogadores: lidoPorJogadores ?? this.lidoPorJogadores,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'titulo': titulo,
        'descricao': descricao,
        'entregueAosJogadores': entregueAosJogadores,
        'lidoPorJogadores': lidoPorJogadores,
      };

  factory HandoutMestre.fromJson(Map<String, dynamic> json) {
    return HandoutMestre(
      id: (json['id'] ?? '').toString(),
      titulo: (json['titulo'] ?? '').toString(),
      descricao: (json['descricao'] ?? '').toString(),
      entregueAosJogadores: json['entregueAosJogadores'] == true,
      lidoPorJogadores: (json['lidoPorJogadores'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}

/// RF-M4: Cartão de Regra Rápida para o Escudo do Mestre.
class RegraCard {
  final String id;
  final String titulo;
  final String categoria;
  final String corpo;
  final bool fixado;

  const RegraCard({
    required this.id,
    required this.titulo,
    required this.categoria,
    required this.corpo,
    this.fixado = false,
  });

  RegraCard copyWith({bool? fixado}) {
    return RegraCard(
      id: id,
      titulo: titulo,
      categoria: categoria,
      corpo: corpo,
      fixado: fixado ?? this.fixado,
    );
  }
}

/// Status da Sessão de Jogo (Planejada, Em andamento ou Encerrada)
enum StatusSessao {
  planejada('Planejada'),
  emAndamento('Em andamento'),
  encerrada('Encerrada');

  final String rotulo;
  const StatusSessao(this.rotulo);
}

/// Item de checklist para anotações e preparações de sessão
class ItemChecklistNota {
  final String id;
  final String texto;
  final bool concluido;

  const ItemChecklistNota({
    required this.id,
    required this.texto,
    this.concluido = false,
  });

  ItemChecklistNota copyWith({bool? concluido, String? texto}) {
    return ItemChecklistNota(
      id: id,
      texto: texto ?? this.texto,
      concluido: concluido ?? this.concluido,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'texto': texto,
        'concluido': concluido,
      };

  factory ItemChecklistNota.fromJson(Map<String, dynamic> json) {
    return ItemChecklistNota(
      id: (json['id'] ?? '').toString(),
      texto: (json['texto'] ?? '').toString(),
      concluido: json['concluido'] == true,
    );
  }
}

/// Perigo de Tormenta 20 (Terreno, Armadilha ou Ambiente)
class PerigoMestre {
  final String id;
  final String nome;
  final String tipo; // Terreno, Armadilha, Ambiente
  final String cd;
  final String dano;
  final String descricao;
  final bool fixado;

  const PerigoMestre({
    required this.id,
    required this.nome,
    required this.tipo,
    required this.cd,
    required this.dano,
    required this.descricao,
    this.fixado = false,
  });

  PerigoMestre copyWith({bool? fixado}) {
    return PerigoMestre(
      id: id,
      nome: nome,
      tipo: tipo,
      cd: cd,
      dano: dano,
      descricao: descricao,
      fixado: fixado ?? this.fixado,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'tipo': tipo,
        'cd': cd,
        'dano': dano,
        'descricao': descricao,
        'fixado': fixado,
      };

  factory PerigoMestre.fromJson(Map<String, dynamic> json) {
    return PerigoMestre(
      id: (json['id'] ?? '').toString(),
      nome: (json['nome'] ?? '').toString(),
      tipo: (json['tipo'] ?? '').toString(),
      cd: (json['cd'] ?? '').toString(),
      dano: (json['dano'] ?? '').toString(),
      descricao: (json['descricao'] ?? '').toString(),
      fixado: json['fixado'] == true,
    );
  }
}

/// Sessão de Jogo dentro de uma Aventura (onde o Mestre convida os jogadores e opera a mesa).
class SessaoJogo {
  final String id;
  final int numero;
  final String titulo;
  final String objetivoResumo;
  final String? mapaAtivoId;
  final List<ElencoSessaoEntry> elenco;
  final NivelAutomacaoMesa nivelAutomacao;
  final String codigoSalaLan;
  final StatusSessao statusSessao;
  final DateTime data;
  final List<ItemChecklistNota> checklistNotas;
  final String notasSessaoTexto;
  final bool notaFixada;

  SessaoJogo({
    required this.id,
    required this.numero,
    required this.titulo,
    this.objetivoResumo = '',
    this.mapaAtivoId,
    this.elenco = const [],
    this.nivelAutomacao = NivelAutomacaoMesa.automatico,
    this.codigoSalaLan = 'T20-4829',
    this.statusSessao = StatusSessao.emAndamento,
    DateTime? data,
    this.checklistNotas = const [],
    this.notasSessaoTexto = '',
    this.notaFixada = false,
  }) : data = data ?? DateTime.now();

  SessaoJogo copyWith({
    int? numero,
    String? titulo,
    String? objetivoResumo,
    String? mapaAtivoId,
    List<ElencoSessaoEntry>? elenco,
    NivelAutomacaoMesa? nivelAutomacao,
    String? codigoSalaLan,
    StatusSessao? statusSessao,
    DateTime? data,
    List<ItemChecklistNota>? checklistNotas,
    String? notasSessaoTexto,
    bool? notaFixada,
  }) {
    return SessaoJogo(
      id: id,
      numero: numero ?? this.numero,
      titulo: titulo ?? this.titulo,
      objetivoResumo: objetivoResumo ?? this.objetivoResumo,
      mapaAtivoId: mapaAtivoId ?? this.mapaAtivoId,
      elenco: elenco ?? this.elenco,
      nivelAutomacao: nivelAutomacao ?? this.nivelAutomacao,
      codigoSalaLan: codigoSalaLan ?? this.codigoSalaLan,
      statusSessao: statusSessao ?? this.statusSessao,
      data: data ?? this.data,
      checklistNotas: checklistNotas ?? this.checklistNotas,
      notasSessaoTexto: notasSessaoTexto ?? this.notasSessaoTexto,
      notaFixada: notaFixada ?? this.notaFixada,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'numero': numero,
        'titulo': titulo,
        'objetivoResumo': objetivoResumo,
        if (mapaAtivoId != null) 'mapaAtivoId': mapaAtivoId,
        'elenco': elenco.map((e) => e.toJson()).toList(),
        'nivelAutomacao': nivelAutomacao.name,
        'codigoSalaLan': codigoSalaLan,
        'statusSessao': statusSessao.name,
        'data': data.toIso8601String(),
        'checklistNotas': checklistNotas.map((e) => e.toJson()).toList(),
        'notasSessaoTexto': notasSessaoTexto,
        'notaFixada': notaFixada,
      };

  factory SessaoJogo.fromJson(Map<String, dynamic> json) {
    return SessaoJogo(
      id: (json['id'] ?? '').toString(),
      numero: (json['numero'] as num?)?.toInt() ?? 1,
      titulo: (json['titulo'] ?? '').toString(),
      objetivoResumo: (json['objetivoResumo'] ?? '').toString(),
      mapaAtivoId: json['mapaAtivoId']?.toString(),
      elenco: (json['elenco'] as List?)
              ?.whereType<Map>()
              .map((e) => ElencoSessaoEntry.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      nivelAutomacao: _enumByName(
        NivelAutomacaoMesa.values,
        json['nivelAutomacao'],
        NivelAutomacaoMesa.automatico,
      ),
      codigoSalaLan: (json['codigoSalaLan'] ?? 'T20-4829').toString(),
      statusSessao: _enumByName(
        StatusSessao.values,
        json['statusSessao'],
        StatusSessao.emAndamento,
      ),
      data: DateTime.tryParse((json['data'] ?? '').toString()),
      checklistNotas: (json['checklistNotas'] as List?)
              ?.whereType<Map>()
              .map((e) => ItemChecklistNota.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      notasSessaoTexto: (json['notasSessaoTexto'] ?? '').toString(),
      notaFixada: json['notaFixada'] == true,
    );
  }
}

/// RF-M3: Aventura dentro de uma Campanha (contém Sessões, Mapas, Notas e Handouts).
class AventuraMestre {
  final String id;
  final String nome;
  final String sinopse;
  final List<SessaoJogo> sessoes;
  final List<MapaBatalhaMestre> mapas;
  final List<NotaMestre> notas;
  final List<HandoutMestre> handouts;

  const AventuraMestre({
    required this.id,
    required this.nome,
    this.sinopse = '',
    this.sessoes = const [],
    this.mapas = const [],
    this.notas = const [],
    this.handouts = const [],
  });

  AventuraMestre copyWith({
    String? nome,
    String? sinopse,
    List<SessaoJogo>? sessoes,
    List<MapaBatalhaMestre>? mapas,
    List<NotaMestre>? notas,
    List<HandoutMestre>? handouts,
  }) {
    return AventuraMestre(
      id: id,
      nome: nome ?? this.nome,
      sinopse: sinopse ?? this.sinopse,
      sessoes: sessoes ?? this.sessoes,
      mapas: mapas ?? this.mapas,
      notas: notas ?? this.notas,
      handouts: handouts ?? this.handouts,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'sinopse': sinopse,
        'sessoes': sessoes.map((e) => e.toJson()).toList(),
        'mapas': mapas.map((e) => e.toJson()).toList(),
        'notas': notas.map((e) => e.toJson()).toList(),
        'handouts': handouts.map((e) => e.toJson()).toList(),
      };

  factory AventuraMestre.fromJson(Map<String, dynamic> json) {
    return AventuraMestre(
      id: (json['id'] ?? '').toString(),
      nome: (json['nome'] ?? '').toString(),
      sinopse: (json['sinopse'] ?? '').toString(),
      sessoes: (json['sessoes'] as List?)
              ?.whereType<Map>()
              .map((e) => SessaoJogo.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      mapas: (json['mapas'] as List?)
              ?.whereType<Map>()
              .map((e) => MapaBatalhaMestre.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      notas: (json['notas'] as List?)
              ?.whereType<Map>()
              .map((e) => NotaMestre.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      handouts: (json['handouts'] as List?)
              ?.whereType<Map>()
              .map((e) => HandoutMestre.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
    );
  }
}

/// Entidade de topo da hierarquia do Mestre: Campanha -> Aventura -> Sessão.
class CampanhaMestre {
  final String id;
  final String nome;
  final String descricao;
  final String patamar;
  final String? codigoConexaoLan;
  final List<AventuraMestre> aventuras;
  final List<MapaBatalhaMestre> mapas;
  final List<ElencoSessaoEntry> jogadoresConvidados;

  const CampanhaMestre({
    required this.id,
    required this.nome,
    this.descricao = '',
    this.patamar = 'Iniciante (Nível 1 a 4)',
    this.codigoConexaoLan,
    this.aventuras = const [],
    this.mapas = const [],
    this.jogadoresConvidados = const [],
  });

  CampanhaMestre copyWith({
    String? nome,
    String? descricao,
    String? patamar,
    String? codigoConexaoLan,
    bool limparCodigoConexaoLan = false,
    List<AventuraMestre>? aventuras,
    List<MapaBatalhaMestre>? mapas,
    List<ElencoSessaoEntry>? jogadoresConvidados,
  }) {
    return CampanhaMestre(
      id: id,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      patamar: patamar ?? this.patamar,
      codigoConexaoLan: limparCodigoConexaoLan
          ? null
          : (codigoConexaoLan ?? this.codigoConexaoLan),
      aventuras: aventuras ?? this.aventuras,
      mapas: mapas ?? this.mapas,
      jogadoresConvidados: jogadoresConvidados ?? this.jogadoresConvidados,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'descricao': descricao,
        'patamar': patamar,
        if (codigoConexaoLan != null) 'codigoConexaoLan': codigoConexaoLan,
        'aventuras': aventuras.map((e) => e.toJson()).toList(),
        'mapas': mapas.map((e) => e.toJson()).toList(),
        'jogadoresConvidados':
            jogadoresConvidados.map((e) => e.toJson()).toList(),
      };

  factory CampanhaMestre.fromJson(Map<String, dynamic> json) {
    return CampanhaMestre(
      id: (json['id'] ?? '').toString(),
      nome: (json['nome'] ?? '').toString(),
      descricao: (json['descricao'] ?? '').toString(),
      patamar: (json['patamar'] ?? 'Iniciante (Nível 1 a 4)').toString(),
      codigoConexaoLan: json['codigoConexaoLan']?.toString(),
      aventuras: (json['aventuras'] as List?)
              ?.whereType<Map>()
              .map((e) => AventuraMestre.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      mapas: (json['mapas'] as List?)
              ?.whereType<Map>()
              .map((e) => MapaBatalhaMestre.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      jogadoresConvidados: (json['jogadoresConvidados'] as List?)
              ?.whereType<Map>()
              .map((e) => ElencoSessaoEntry.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
    );
  }
}
