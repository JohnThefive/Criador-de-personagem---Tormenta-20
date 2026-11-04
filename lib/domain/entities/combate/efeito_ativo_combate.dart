import 'package:equatable/equatable.dart';

/// Representa um efeito ou magia ativa no combatente sob o sistema de honestidade
class EfeitoAtivoCombate extends Equatable {
  final String id;
  final String nome;
  final String descricaoEfeito;
  final int bonusAtaque;
  final int bonusDano;
  final int rodadasRestantes;
  final String combatenteId;

  const EfeitoAtivoCombate({
    required this.id,
    required this.nome,
    required this.descricaoEfeito,
    this.bonusAtaque = 0,
    this.bonusDano = 0,
    this.rodadasRestantes = 10,
    required this.combatenteId,
  });

  @override
  List<Object?> get props => [
    id,
    nome,
    descricaoEfeito,
    bonusAtaque,
    bonusDano,
    rodadasRestantes,
    combatenteId,
  ];

  EfeitoAtivoCombate copyWith({
    String? id,
    String? nome,
    String? descricaoEfeito,
    int? bonusAtaque,
    int? bonusDano,
    int? rodadasRestantes,
    String? combatenteId,
  }) {
    return EfeitoAtivoCombate(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      descricaoEfeito: descricaoEfeito ?? this.descricaoEfeito,
      bonusAtaque: bonusAtaque ?? this.bonusAtaque,
      bonusDano: bonusDano ?? this.bonusDano,
      rodadasRestantes: rodadasRestantes ?? this.rodadasRestantes,
      combatenteId: combatenteId ?? this.combatenteId,
    );
  }
}
