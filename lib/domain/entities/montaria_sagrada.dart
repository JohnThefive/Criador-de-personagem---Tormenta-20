class MontariaSagrada {
  final String nomeCustomizado;
  final String especie;
  final bool isVarianteMundana;
  final bool invocada;

  const MontariaSagrada({
    this.nomeCustomizado = 'Cavalo de Guerra',
    this.especie = 'Cavalo de Guerra',
    this.isVarianteMundana = false,
    this.invocada = false,
  });

  bool get ativa => isVarianteMundana || invocada;

  MontariaSagrada copyWith({
    String? nomeCustomizado,
    String? especie,
    bool? isVarianteMundana,
    bool? invocada,
  }) {
    return MontariaSagrada(
      nomeCustomizado: nomeCustomizado ?? this.nomeCustomizado,
      especie: especie ?? this.especie,
      isVarianteMundana: isVarianteMundana ?? this.isVarianteMundana,
      invocada: invocada ?? this.invocada,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nomeCustomizado': nomeCustomizado,
      'especie': especie,
      'isVarianteMundana': isVarianteMundana,
      'invocada': invocada,
    };
  }

  factory MontariaSagrada.fromJson(Map<String, dynamic> json) {
    return MontariaSagrada(
      nomeCustomizado: (json['nomeCustomizado'] ?? json['nome'] ?? 'Cavalo de Guerra').toString(),
      especie: (json['especie'] ?? 'Cavalo de Guerra').toString(),
      isVarianteMundana: json['isVarianteMundana'] as bool? ?? false,
      invocada: json['invocada'] as bool? ?? false,
    );
  }
}
