/// Representa um dos slots extras de itens vestidos (Slots 2, 3 e 4).
/// No Tormenta 20 JdA, o limite é de 4 itens vestidos simultaneamente,
/// sendo o Slot 1 ocupado pela `armaduraEquipada` quando existente.
class ItemVestido {
  /// Índice do slot extra: 1 (Slot 2), 2 (Slot 3) ou 3 (Slot 4).
  final int slotIndex;
  final String nome;
  final String beneficio;
  final int espacos;
  final int bonusDefesa;
  final int bonusCDMagia;
  final Map<String, int> bonusPericias;

  const ItemVestido({
    required this.slotIndex,
    required this.nome,
    this.beneficio = '',
    this.espacos = 1,
    this.bonusDefesa = 0,
    this.bonusCDMagia = 0,
    this.bonusPericias = const {},
  });

  ItemVestido copyWith({
    int? slotIndex,
    String? nome,
    String? beneficio,
    int? espacos,
    int? bonusDefesa,
    int? bonusCDMagia,
    Map<String, int>? bonusPericias,
  }) {
    return ItemVestido(
      slotIndex: slotIndex ?? this.slotIndex,
      nome: nome ?? this.nome,
      beneficio: beneficio ?? this.beneficio,
      espacos: espacos ?? this.espacos,
      bonusDefesa: bonusDefesa ?? this.bonusDefesa,
      bonusCDMagia: bonusCDMagia ?? this.bonusCDMagia,
      bonusPericias: bonusPericias ?? this.bonusPericias,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'slotIndex': slotIndex,
      'nome': nome,
      'beneficio': beneficio,
      'espacos': espacos,
      if (bonusDefesa != 0) 'bonusDefesa': bonusDefesa,
      if (bonusCDMagia != 0) 'bonusCDMagia': bonusCDMagia,
      if (bonusPericias.isNotEmpty) 'bonusPericias': bonusPericias,
    };
  }

  factory ItemVestido.fromJson(Map<String, dynamic> json) {
    return ItemVestido(
      slotIndex: ((json['slotIndex'] as num?)?.toInt() ?? 1).clamp(1, 3),
      nome: json['nome']?.toString() ?? '',
      beneficio: json['beneficio']?.toString() ?? '',
      espacos: ((json['espacos'] as num?)?.toInt() ?? 1).clamp(0, 10),
      bonusDefesa: (json['bonusDefesa'] as num?)?.toInt() ?? 0,
      bonusCDMagia: (json['bonusCDMagia'] as num?)?.toInt() ?? 0,
      bonusPericias:
          (json['bonusPericias'] as Map?)?.map(
            (k, v) => MapEntry(k.toString().toUpperCase(), (v as num).toInt()),
          ) ??
          const {},
    );
  }
}
