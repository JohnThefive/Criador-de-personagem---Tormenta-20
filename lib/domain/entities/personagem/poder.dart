class RegrasCustomizacaoPoder {
  final int custoPmMinimo;
  final String custoPmMaximo;
  final bool permiteMultiplasInstancias;

  const RegrasCustomizacaoPoder({
    this.custoPmMinimo = 1,
    this.custoPmMaximo = 'nivel_do_personagem',
    this.permiteMultiplasInstancias = true,
  });

  factory RegrasCustomizacaoPoder.fromJson(Map<String, dynamic> json) {
    return RegrasCustomizacaoPoder(
      custoPmMinimo: (json['custoPmMinimo'] ?? json['custoPmMínimo'] as num?)?.toInt() ?? 1,
      custoPmMaximo: json['custoPmMaximo']?.toString() ?? 'nivel_do_personagem',
      permiteMultiplasInstancias: json['permiteMultiplasInstancias'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'custoPmMinimo': custoPmMinimo,
    'custoPmMaximo': custoPmMaximo,
    'permiteMultiplasInstancias': permiteMultiplasInstancias,
  };
}

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
  final String? referenciaTabela;
  final RegrasCustomizacaoPoder? regrasCustomizacao;

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
    this.referenciaTabela,
    this.regrasCustomizacao,
  });

  bool get temCustomizacao => referenciaTabela != null || regrasCustomizacao != null;

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
      referenciaTabela: json['referenciaTabela']?.toString(),
      regrasCustomizacao: json['regrasCustomizacao'] != null
          ? RegrasCustomizacaoPoder.fromJson(
              Map<String, dynamic>.from(json['regrasCustomizacao'] as Map),
            )
          : null,
    );
  }
}
