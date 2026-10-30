/// Representa um dos slots extras de itens vestidos (Slots 2, 3 e 4).
/// No Tormenta 20 JdA, o limite é de 4 itens vestidos simultaneamente,
/// sendo o Slot 1 ocupado pela `armaduraEquipada` quando existente.
class ItemVestido {
  /// Índice do slot extra: 1 (Slot 2), 2 (Slot 3) ou 3 (Slot 4).
  final int slotIndex;
  final String nome;
  final String beneficio;
  final int espacos;

  const ItemVestido({
    required this.slotIndex,
    required this.nome,
    this.beneficio = '',
    this.espacos = 1,
  });

  ItemVestido copyWith({
    int? slotIndex,
    String? nome,
    String? beneficio,
    int? espacos,
  }) {
    return ItemVestido(
      slotIndex: slotIndex ?? this.slotIndex,
      nome: nome ?? this.nome,
      beneficio: beneficio ?? this.beneficio,
      espacos: espacos ?? this.espacos,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'slotIndex': slotIndex,
      'nome': nome,
      'beneficio': beneficio,
      'espacos': espacos,
    };
  }

  factory ItemVestido.fromJson(Map<String, dynamic> json) {
    return ItemVestido(
      slotIndex: ((json['slotIndex'] as num?)?.toInt() ?? 1).clamp(1, 3),
      nome: json['nome']?.toString() ?? '',
      beneficio: json['beneficio']?.toString() ?? '',
      espacos: ((json['espacos'] as num?)?.toInt() ?? 1).clamp(0, 10),
    );
  }
}
