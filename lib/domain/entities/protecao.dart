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
  });

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
    };
  }
}
