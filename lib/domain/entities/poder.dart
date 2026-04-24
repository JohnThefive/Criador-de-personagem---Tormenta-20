class Poder {
  final String key;
  final String nome;
  final String descricao;
  final String preRequisitoTexto;
  final int nivelMinimo;
  final List<String> caminhosExigidos;
  final List<String> poderesExigidos;
  final Map<String, int> atributosExigidos;
  final List<String> periciasExigidas;

  const Poder({
    required this.key,
    required this.nome,
    required this.descricao,
    this.preRequisitoTexto = '',
    this.nivelMinimo = 1,
    this.caminhosExigidos = const [],
    this.poderesExigidos = const [],
    this.atributosExigidos = const {},
    this.periciasExigidas = const [],
  });

  factory Poder.fromJson(Map<String, dynamic> json) {
    return Poder(
      key: json['key'],
      nome: json['nome'],
      descricao: json['descricao'],
      preRequisitoTexto: json['preRequisitoTexto'] ?? '',
      nivelMinimo: json['nivelMinimo'] ?? 1,
      caminhosExigidos: List<String>.from(json['caminhosExigidos'] ?? []),
      poderesExigidos: List<String>.from(json['poderesExigidos'] ?? []),
      atributosExigidos: Map<String, int>.from(json['atributosExigidos'] ?? {}),
      periciasExigidas: List<String>.from(json['periciasExigidas'] ?? []),
    );
  }
}
