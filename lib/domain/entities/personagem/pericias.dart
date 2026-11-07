class Pericia {
  final String key; // nome da pericia
  final String label;
  final String atributoChave; // 'FOR', 'DES', 'CON', 'INT', 'SAB', 'CAR'
  final bool
  somenteTreinada; // verifica se é preciso treinar para ter a pericia
  final bool penalidadeArmadura; //  verifica se tem penalidade  de armadura
  final String descricao; // descricao curta do que a percia faz
  final String
  acoesExecutadas; // ações que voce pode fazer com bonus graças a pericia
  final bool
  exigeFerramenta; // R5: indica se a perícia exige kit/ferramenta (-5 sem ela)

  const Pericia({
    required this.key,
    required this.label,
    required this.atributoChave,
    required this.somenteTreinada,
    required this.penalidadeArmadura,
    required this.descricao,
    required this.acoesExecutadas,
    this.exigeFerramenta = false,
  });

  factory Pericia.fromJson(Map<String, dynamic> json) {
    return Pericia(
      key: json['key'] as String,
      label: json['label'] as String,
      atributoChave: json['atributoChave'] as String,
      somenteTreinada: json['somenteTreinada'] as bool,
      penalidadeArmadura: json['penalidadeArmadura'] as bool,
      descricao: json['descricao'] as String,
      acoesExecutadas: json['acoesExecutadas'] as String,
      exigeFerramenta: json['exigeFerramenta'] as bool? ?? false,
    );
  }
}
