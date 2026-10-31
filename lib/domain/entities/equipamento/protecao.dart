enum TipoProtecao {
  armaduraLeve,
  armaduraPesada,
  escudoLeve,
  escudoPesado;

  String get label {
    switch (this) {
      case TipoProtecao.armaduraLeve:
        return 'Armadura Leve';
      case TipoProtecao.armaduraPesada:
        return 'Armadura Pesada';
      case TipoProtecao.escudoLeve:
        return 'Escudo Leve';
      case TipoProtecao.escudoPesado:
        return 'Escudo Pesado';
    }
  }

  static TipoProtecao fromString(String val) {
    switch (val.toLowerCase().trim()) {
      case 'armadurapesada':
      case 'armadura pesada':
      case 'pesada':
        return TipoProtecao.armaduraPesada;
      case 'escudoleve':
      case 'escudo leve':
        return TipoProtecao.escudoLeve;
      case 'escudopesado':
      case 'escudo pesado':
        return TipoProtecao.escudoPesado;
      case 'armaduraleve':
      case 'armadura leve':
      case 'leve':
      default:
        return TipoProtecao.armaduraLeve;
    }
  }
}

class Protecao {
  final String key;
  final String nome;
  final String descricao;
  final int precoEmTibares;
  final int bonusDefesa;
  final int penalidadeArmadura;
  final int espacos;
  final TipoProtecao tipo;

  // Ataque com Escudo (T20: se proficiente em marciais, pode golpear com escudo)
  final String? danoAtaque;
  final String? criticoAtaque;
  final int multiplicadorCriticoAtaque;
  final List<String> melhorias;
  final List<String> encantos;

  const Protecao({
    required this.key,
    required this.nome,
    required this.descricao,
    required this.precoEmTibares,
    required this.bonusDefesa,
    required this.penalidadeArmadura,
    required this.espacos,
    required this.tipo,
    this.danoAtaque,
    this.criticoAtaque = 'x2',
    this.multiplicadorCriticoAtaque = 2,
    this.melhorias = const [],
    this.encantos = const [],
  });

  Protecao copyWith({
    String? key,
    String? nome,
    String? descricao,
    int? precoEmTibares,
    int? bonusDefesa,
    int? penalidadeArmadura,
    int? espacos,
    TipoProtecao? tipo,
    String? danoAtaque,
    String? criticoAtaque,
    int? multiplicadorCriticoAtaque,
    List<String>? melhorias,
    List<String>? encantos,
  }) {
    return Protecao(
      key: key ?? this.key,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      precoEmTibares: precoEmTibares ?? this.precoEmTibares,
      bonusDefesa: bonusDefesa ?? this.bonusDefesa,
      penalidadeArmadura: penalidadeArmadura ?? this.penalidadeArmadura,
      espacos: espacos ?? this.espacos,
      tipo: tipo ?? this.tipo,
      danoAtaque: danoAtaque ?? this.danoAtaque,
      criticoAtaque: criticoAtaque ?? this.criticoAtaque,
      multiplicadorCriticoAtaque:
          multiplicadorCriticoAtaque ?? this.multiplicadorCriticoAtaque,
      melhorias: melhorias ?? this.melhorias,
      encantos: encantos ?? this.encantos,
    );
  }

  /// Bônus de Defesa extra proveniente de melhorias (Reforçada +1) e encantos (Guardiã +4 ou Defensora +2).
  int get bonusDefesaMelhorias {
    int extra = 0;
    if (melhorias.contains('REFORCADA')) extra += 1;
    if (encantos.contains('GUARDIA')) {
      extra += 4;
    } else if (encantos.contains('DEFENSORA')) {
      extra += 2;
    }
    return extra;
  }

  int get bonusDefesaEfetivo => bonusDefesa + bonusDefesaMelhorias;

  /// Penalidade de armadura efetiva considerando Reforçada (aumenta 1), Ajustada (-1), Sob Medida (-2) e Mitral (-2).
  /// Nota: `penalidadeArmadura` no JSON costuma vir negativa (ex: -2) ou positiva; normalizamos a magnitude e mantemos o sinal original ou <= 0.
  int get penalidadeArmaduraEfetiva {
    int magnitude = penalidadeArmadura.abs();
    if (melhorias.contains('REFORCADA')) magnitude += 1;
    if (melhorias.contains('SOB_MEDIDA')) {
      magnitude -= 2;
    } else if (melhorias.contains('AJUSTADA')) {
      magnitude -= 1;
    }
    if (melhorias.contains('MATERIAL_MITRAL')) magnitude -= 2;
    if (magnitude <= 0) return 0;
    return penalidadeArmadura < 0 ? -magnitude : magnitude;
  }

  /// Redução de Dano (RD) concedida por materiais especiais (Adamante, Couraça de Kaiju) e encantos (Invulnerável).
  int get rdMelhorias {
    int rd = 0;
    if (melhorias.contains('MATERIAL_ADAMANTE')) {
      rd += ehArmaduraPesada ? 5 : 2;
    }
    if (melhorias.contains('MATERIAL_COURACA_KAIJU')) {
      rd += 5;
    }
    if (encantos.contains('INVULNERAVEL')) {
      rd += ehArmaduraPesada ? 10 : 5;
    }
    return rd;
  }

  /// Bônus em testes de resistência (Selada: +1 em Fortitude, Reflexos e Vontade).
  int get bonusResistenciaMelhorias => melhorias.contains('SELADA') ? 1 : 0;

  /// Se é uma armadura pesada com a melhoria Delicada, permite somar até +1 da Destreza na Defesa.
  bool get possuiMelhoriaDelicada => melhorias.contains('DELICADA');

  int get espacosEfetivos {
    if (melhorias.contains('MATERIAL_MITRAL') && espacos > 0) {
      return (espacos - 1).clamp(0, 20);
    }
    return espacos;
  }

  bool get ehSuperiorOuMagica => melhorias.isNotEmpty || encantos.isNotEmpty;

  /// No T20: Armaduras leves e escudos permitem somar Destreza à Defesa.
  /// Armaduras pesadas NÃO aplicam o bônus de Destreza.
  bool get permiteDestrezaNaDefesa => tipo != TipoProtecao.armaduraPesada;

  /// Identifica se o item é um escudo
  bool get ehEscudo =>
      tipo == TipoProtecao.escudoLeve || tipo == TipoProtecao.escudoPesado;

  /// Identifica se o item é uma armadura (leve ou pesada)
  bool get ehArmadura => !ehEscudo;

  /// Atalhos para subtipos
  bool get ehArmaduraPesada => tipo == TipoProtecao.armaduraPesada;
  bool get ehArmaduraLeve => tipo == TipoProtecao.armaduraLeve;
  bool get ehEscudoLeve => tipo == TipoProtecao.escudoLeve;
  bool get ehEscudoPesado => tipo == TipoProtecao.escudoPesado;

  /// Armaduras pesadas reduzem o deslocamento em 3m
  bool get reduzDeslocamento => ehArmaduraPesada;

  /// Tempo para vestir conforme regras do Tormenta 20
  String get tempoVestir {
    if (ehEscudo) return 'Ação de movimento';
    if (ehArmaduraPesada) return '5 minutos';
    return 'Ação completa';
  }

  /// Tempo para remover
  String get tempoRemover {
    if (ehEscudo) return 'Ação de movimento';
    if (ehArmaduraPesada) return '5 minutos';
    return 'Ação completa';
  }

  factory Protecao.fromJson(Map<String, dynamic> json) {
    return Protecao(
      key: json['key'] ?? '',
      nome: json['nome'] ?? '',
      descricao: json['descricao'] ?? '',
      precoEmTibares: (json['precoEmTibares'] as num?)?.toInt() ?? 0,
      bonusDefesa: (json['bonusDefesa'] as num?)?.toInt() ?? 0,
      penalidadeArmadura: (json['penalidadeArmadura'] as num?)?.toInt() ?? 0,
      espacos: (json['espacos'] as num?)?.toInt() ?? 1,
      tipo: TipoProtecao.fromString(json['tipo'] ?? 'armaduraLeve'),
      danoAtaque: json['danoAtaque'],
      criticoAtaque: json['criticoAtaque'] ?? 'x2',
      multiplicadorCriticoAtaque:
          (json['multiplicadorCriticoAtaque'] as num?)?.toInt() ?? 2,
      melhorias: List<String>.from(json['melhorias'] ?? []),
      encantos: List<String>.from(json['encantos'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'nome': nome,
      'descricao': descricao,
      'precoEmTibares': precoEmTibares,
      'bonusDefesa': bonusDefesa,
      'penalidadeArmadura': penalidadeArmadura,
      'espacos': espacos,
      'tipo': tipo.name,
      'danoAtaque': danoAtaque,
      'criticoAtaque': criticoAtaque,
      'multiplicadorCriticoAtaque': multiplicadorCriticoAtaque,
      if (melhorias.isNotEmpty) 'melhorias': melhorias,
      if (encantos.isNotEmpty) 'encantos': encantos,
    };
  }
}
