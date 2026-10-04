class TipoCompanheiroAnimal {
  final String key;
  final String nome;
  final String descricao;
  final List<String> exemplos;
  final Map<String, String> beneficiosPorTier;
  final String? origem;

  const TipoCompanheiroAnimal({
    required this.key,
    required this.nome,
    required this.descricao,
    this.exemplos = const [],
    this.beneficiosPorTier = const {},
    this.origem,
  });

  factory TipoCompanheiroAnimal.fromJson(Map<String, dynamic> json) {
    final rawExemplos = (json['exemplos'] as List?) ?? [];
    final rawBen = (json['beneficiosPorTier'] as Map?) ?? {};

    return TipoCompanheiroAnimal(
      key: json['key']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      descricao: json['descricao']?.toString() ?? '',
      exemplos: rawExemplos.map((e) => e.toString()).toList(),
      beneficiosPorTier: rawBen.map((k, v) => MapEntry(k.toString(), v.toString())),
      origem: json['origem']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'key': key,
    'nome': nome,
    'descricao': descricao,
    'exemplos': exemplos,
    'beneficiosPorTier': beneficiosPorTier,
    if (origem != null) 'origem': origem,
  };

  /// Retorna o tier do companheiro conforme o nível de Druida:
  /// - Nível 12+: mestre
  /// - Nível 6+: veterano
  /// - Menor que 6: iniciante
  static String tierParaNivel(int nivelDruida) {
    if (nivelDruida >= 12) return 'mestre';
    if (nivelDruida >= 6) return 'veterano';
    return 'iniciante';
  }

  String getBeneficioParaNivel(int nivelDruida) {
    final tier = tierParaNivel(nivelDruida);
    return beneficiosPorTier[tier] ?? beneficiosPorTier.values.firstOrNull ?? '';
  }
}
