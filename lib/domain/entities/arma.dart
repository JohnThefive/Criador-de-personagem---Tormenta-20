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
  });

  /// Formatação do crítico no padrão clássico de Tormenta 20:
  /// Ex: se margem == 20 e mult == 2 -> 'x2'
  /// Se margem == 20 e mult == 3 -> 'x3'
  /// Se margem < 20 e mult == 2 -> '19/x2'
  /// Se margem < 20 e mult == 3 -> '19/x3'
  String get criticoFormatado {
    if (margemAmeaca >= 20) {
      return 'x$multiplicadorCritico';
    }
    return '$margemAmeaca/x$multiplicadorCritico';
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
    };
  }
}
