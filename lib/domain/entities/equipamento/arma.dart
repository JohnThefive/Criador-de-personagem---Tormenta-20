enum ProficienciaArma {
  simples,
  marcial,
  exotica,
  fogo;

  String get label {
    switch (this) {
      case ProficienciaArma.simples:
        return 'Simples';
      case ProficienciaArma.marcial:
        return 'Marcial';
      case ProficienciaArma.exotica:
        return 'Exótica';
      case ProficienciaArma.fogo:
        return 'De Fogo';
    }
  }

  static ProficienciaArma fromString(String val) {
    switch (val.toLowerCase().trim()) {
      case 'marcial':
        return ProficienciaArma.marcial;
      case 'exotica':
      case 'exótica':
        return ProficienciaArma.exotica;
      case 'fogo':
        return ProficienciaArma.fogo;
      case 'simples':
      default:
        return ProficienciaArma.simples;
    }
  }
}

enum PropositoArma {
  corpoACorpo,
  arremesso,
  disparo;

  String get label {
    switch (this) {
      case PropositoArma.corpoACorpo:
        return 'Corpo a Corpo';
      case PropositoArma.arremesso:
        return 'Arremesso';
      case PropositoArma.disparo:
        return 'Disparo';
    }
  }

  static PropositoArma fromString(String val) {
    switch (val.toLowerCase().trim()) {
      case 'arremesso':
        return PropositoArma.arremesso;
      case 'disparo':
        return PropositoArma.disparo;
      case 'corpoacorpo':
      case 'corpo a corpo':
      default:
        return PropositoArma.corpoACorpo;
    }
  }
}

enum EmpunhaduraArma {
  leve,
  umaMao,
  duasMaos;

  String get label {
    switch (this) {
      case EmpunhaduraArma.leve:
        return 'Leve';
      case EmpunhaduraArma.umaMao:
        return 'Uma Mão';
      case EmpunhaduraArma.duasMaos:
        return 'Duas Mãos';
    }
  }

  static EmpunhaduraArma fromString(String val) {
    switch (val.toLowerCase().trim()) {
      case 'leve':
        return EmpunhaduraArma.leve;
      case 'duasmaos':
      case 'duas mãos':
      case 'duas maos':
        return EmpunhaduraArma.duasMaos;
      case 'umamao':
      case 'uma mão':
      case 'uma mao':
      default:
        return EmpunhaduraArma.umaMao;
    }
  }
}

enum TipoDanoArma {
  corte,
  impacto,
  perfuracao;

  String get label {
    switch (this) {
      case TipoDanoArma.corte:
        return 'Corte';
      case TipoDanoArma.impacto:
        return 'Impacto';
      case TipoDanoArma.perfuracao:
        return 'Perfuração';
    }
  }

  static TipoDanoArma fromString(String val) {
    switch (val.toLowerCase().trim()) {
      case 'impacto':
        return TipoDanoArma.impacto;
      case 'perfuracao':
      case 'perfuração':
        return TipoDanoArma.perfuracao;
      case 'corte':
      default:
        return TipoDanoArma.corte;
    }
  }
}

class Arma {
  final String key;
  final String nome;
  final String descricao;
  final ProficienciaArma proficiencia;
  final PropositoArma proposito;
  final EmpunhaduraArma empunhadura;
  final String dano;
  final int margemAmeaca; // ex: 19 ou 20
  final int multiplicadorCritico; // ex: 2, 3, 4
  final TipoDanoArma tipoDano;
  final int espacos;
  final int precoTibar;
  final String alcance;
  final List<String> propriedades;
  final List<String> melhorias;
  final List<String> encantos;

  const Arma({
    required this.key,
    required this.nome,
    required this.descricao,
    required this.proficiencia,
    required this.proposito,
    required this.empunhadura,
    required this.dano,
    this.margemAmeaca = 20,
    this.multiplicadorCritico = 2,
    required this.tipoDano,
    this.espacos = 1,
    this.precoTibar = 0,
    this.alcance = 'Corpo a corpo',
    this.propriedades = const [],
    this.melhorias = const [],
    this.encantos = const [],
  });

  Arma copyWith({
    String? key,
    String? nome,
    String? descricao,
    ProficienciaArma? proficiencia,
    PropositoArma? proposito,
    EmpunhaduraArma? empunhadura,
    String? dano,
    int? margemAmeaca,
    int? multiplicadorCritico,
    TipoDanoArma? tipoDano,
    int? espacos,
    int? precoTibar,
    String? alcance,
    List<String>? propriedades,
    List<String>? melhorias,
    List<String>? encantos,
  }) {
    return Arma(
      key: key ?? this.key,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      proficiencia: proficiencia ?? this.proficiencia,
      proposito: proposito ?? this.proposito,
      empunhadura: empunhadura ?? this.empunhadura,
      dano: dano ?? this.dano,
      margemAmeaca: margemAmeaca ?? this.margemAmeaca,
      multiplicadorCritico: multiplicadorCritico ?? this.multiplicadorCritico,
      tipoDano: tipoDano ?? this.tipoDano,
      espacos: espacos ?? this.espacos,
      precoTibar: precoTibar ?? this.precoTibar,
      alcance: alcance ?? this.alcance,
      propriedades: propriedades ?? this.propriedades,
      melhorias: melhorias ?? this.melhorias,
      encantos: encantos ?? this.encantos,
    );
  }

  /// Bônus de ataque proveniente de melhorias e encantos da arma.
  /// No T20 JdA: Pungente (+2) substitui Certeira (+1); Magnífica (+4) substitui Formidável (+2).
  /// Melhoria e encanto acumulam entre si.
  int get bonusAtaqueMelhorias {
    int bonusMelhoria = 0;
    if (melhorias.contains('PUNGENTE')) {
      bonusMelhoria = 2;
    } else if (melhorias.contains('CERTEIRA')) {
      bonusMelhoria = 1;
    }

    int bonusEncanto = 0;
    if (encantos.contains('MAGNIFICA')) {
      bonusEncanto = 4;
    } else if (encantos.contains('FORMIDAVEL')) {
      bonusEncanto = 2;
    }

    return bonusMelhoria + bonusEncanto;
  }

  /// Bônus numérico de dano proveniente de melhorias e encantos da arma.
  /// No T20 JdA: Atroz (+2) substitui Cruel (+1); Magnífica (+4) substitui Formidável (+2).
  int get bonusDanoMelhorias {
    int bonusMelhoria = 0;
    if (melhorias.contains('ATROZ')) {
      bonusMelhoria = 2;
    } else if (melhorias.contains('CRUEL')) {
      bonusMelhoria = 1;
    }
    if (melhorias.contains('MATERIAL_GELO_ETERNO')) {
      bonusMelhoria += 2;
    }

    int bonusEncanto = 0;
    if (encantos.contains('MAGNIFICA')) {
      bonusEncanto = 4;
    } else if (encantos.contains('FORMIDAVEL')) {
      bonusEncanto = 2;
    }

    return bonusMelhoria + bonusEncanto;
  }

  /// Bônus na Defesa fornecido pelo encanto Defensora (+2).
  int get bonusDefesaEncanto => encantos.contains('DEFENSORA') ? 2 : 0;

  /// Margem de ameaça efetiva considerando Precisa (+1), Mitral (+1) e Ameaçadora (duplica a margem).
  int get margemAmeacaEfetiva {
    int margem = margemAmeaca;
    if (encantos.contains('AMEACADORA')) {
      final int passosBase = (20 - margemAmeaca) + 1;
      margem = 20 - (passosBase * 2) + 1;
    }
    if (melhorias.contains('PRECISA')) margem -= 1;
    if (melhorias.contains('MATERIAL_MITRAL')) margem -= 1;
    return margem.clamp(1, 20);
  }

  /// Multiplicador de crítico efetivo considerando Maciça (+1).
  int get multiplicadorCriticoEfetivo {
    int mult = multiplicadorCritico;
    if (melhorias.contains('MACICA')) mult += 1;
    return mult;
  }

  /// Passo de dano aumentado por Adamante e dados extras elementais de encantos.
  String get danoEfetivo {
    String base = dano;
    if (melhorias.contains('MATERIAL_ADAMANTE')) {
      base = _aumentarPassoDano(base);
    }
    final List<String> extras = [];
    if (encantos.contains('FLAMEJANTE')) extras.add('1d6 fogo');
    if (encantos.contains('CONGELANTE')) extras.add('1d6 frio');
    if (encantos.contains('ELETRICA')) extras.add('1d6 eletr.');
    if (encantos.contains('CORROSIVA')) extras.add('1d6 ácido');
    if (encantos.contains('SAGRADA')) extras.add('1d6 luz');
    if (encantos.contains('PROFANA')) extras.add('1d6 trevas');
    if (extras.isEmpty) return base;
    return '$base + ${extras.join(' + ')}';
  }

  static String _aumentarPassoDano(String d) {
    const passos = {
      '1d4': '1d6',
      '1d6': '1d8',
      '1d8': '1d10',
      '1d10': '1d12',
      '2d4': '2d6',
      '1d12': '3d6',
      '2d6': '2d8',
      '2d8': '2d10',
      '2d10': '3d8',
      '3d6': '4d6',
    };
    return passos[d.trim().toLowerCase()] ?? d;
  }

  int get espacosEfetivos {
    if (melhorias.contains('MATERIAL_MITRAL') && espacos > 0) {
      return (espacos - 1).clamp(0, 20);
    }
    return espacos;
  }

  bool get ehSuperiorOuMagica => melhorias.isNotEmpty || encantos.isNotEmpty;

  /// Formatação do crítico no padrão clássico de Tormenta 20:
  /// Ex: se margem == 20 e mult == 2 -> 'x2'
  /// Se margem == 20 e mult == 3 -> 'x3'
  /// Se margem < 20 e mult == 2 -> '19/x2'
  /// Se margem < 20 e mult == 3 -> '19/x3'
  String get criticoFormatado {
    final m = margemAmeacaEfetiva;
    final mult = multiplicadorCriticoEfetivo;
    if (m >= 20) {
      return 'x$mult';
    }
    return '$m/x$mult';
  }

  bool get ehCorpoACorpo => proposito == PropositoArma.corpoACorpo;
  bool get ehADistancia => !ehCorpoACorpo;

  /// No T20: Corpo a corpo e arremesso somam FOR ao dano; disparo não soma atributo
  bool get somaForcaAoDano =>
      proposito == PropositoArma.corpoACorpo ||
      proposito == PropositoArma.arremesso;

  /// Perícia padrão para testes de ataque
  String get periciaAtaque => ehCorpoACorpo ? 'LUTA' : 'PONTARIA';

  // Flags especiais de armas em Tormenta 20
  bool get ehAdaptavel => propriedades.contains('adaptavel');
  bool get ehAgil => propriedades.contains('agil');
  bool get ehAlongada => propriedades.contains('alongada');
  bool get ehDesbalanceada => propriedades.contains('desbalanceada');
  bool get ehDupla => propriedades.contains('dupla');
  bool get ehVersatil => propriedades.contains('versatil');

  factory Arma.fromJson(Map<String, dynamic> json) {
    return Arma(
      key: json['key'] ?? '',
      nome: json['nome'] ?? '',
      descricao: json['descricao'] ?? '',
      proficiencia: ProficienciaArma.fromString(
        json['proficiencia'] ?? 'simples',
      ),
      proposito: PropositoArma.fromString(json['proposito'] ?? 'corpoACorpo'),
      empunhadura: EmpunhaduraArma.fromString(json['empunhadura'] ?? 'umaMao'),
      dano: json['dano'] ?? '1d6',
      margemAmeaca: (json['margemAmeaca'] as num?)?.toInt() ?? 20,
      multiplicadorCritico:
          (json['multiplicadorCritico'] as num?)?.toInt() ?? 2,
      tipoDano: TipoDanoArma.fromString(json['tipoDano'] ?? 'corte'),
      espacos: (json['espacos'] as num?)?.toInt() ?? 1,
      precoTibar: (json['precoTibar'] as num?)?.toInt() ?? 0,
      alcance: json['alcance'] ?? 'Corpo a corpo',
      propriedades: List<String>.from(json['propriedades'] ?? []),
      melhorias: List<String>.from(json['melhorias'] ?? []),
      encantos: List<String>.from(json['encantos'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'nome': nome,
      'descricao': descricao,
      'proficiencia': proficiencia.name,
      'proposito': proposito.name,
      'empunhadura': empunhadura.name,
      'dano': dano,
      'margemAmeaca': margemAmeaca,
      'multiplicadorCritico': multiplicadorCritico,
      'tipoDano': tipoDano.name,
      'espacos': espacos,
      'precoTibar': precoTibar,
      'alcance': alcance,
      'propriedades': propriedades,
      if (melhorias.isNotEmpty) 'melhorias': melhorias,
      if (encantos.isNotEmpty) 'encantos': encantos,
    };
  }
}
