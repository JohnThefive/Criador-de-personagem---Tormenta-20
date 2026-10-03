import 'package:flutter/widgets.dart';
import '../../helpers/icone_rpg_helper.dart';

class Raca {
  final String id;
  final String nome;

  // Campos visuais e lore
  final String descricaoRaca;
  final String icone; // Chave do ícone serializável (ex: "axe", "clover")

  // Mapa de modificadores fixos. Ex: {'CON': 2, 'SAB': 1, 'DES': -1} para Anão
  final Map<String, int> modificadores;

  // Map de habilidades - "Nome: descrição"
  // Ex: {"Visão no Escuro": "Você enxerga no escuro a até 15m..."}
  final Map<String, String> habilidadesRaca;

  // Flags para raças que modificam muitos atributos e habilidades complexas
  final bool ehFlexivel;

  // Raças que possuem penalidades complexas
  final List<String> atributosBloqueados;

  const Raca({
    required this.id,
    required this.nome,
    required this.descricaoRaca,
    required this.icone,
    required this.modificadores,
    this.habilidadesRaca = const {},
    this.ehFlexivel = false,
    this.atributosBloqueados = const [],
  });

  /// Getter que resolve a chave de texto para o IconData vetorial correspondente
  IconData get iconeRaca => IconeRpgHelper.obterIcone(icone);

  factory Raca.fromJson(Map<String, dynamic> json) {
    return Raca(
      id: json['id'] as String? ?? '',
      nome: json['nome'] as String? ?? '',
      descricaoRaca: json['descricaoRaca'] as String? ?? '',
      icone: json['icone'] as String? ?? 'player',
      modificadores:
          (json['modificadores'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toInt()),
          ) ??
          {},
      habilidadesRaca:
          (json['habilidadesRaca'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v.toString()),
          ) ??
          {},
      ehFlexivel: json['ehFlexivel'] as bool? ?? false,
      atributosBloqueados:
          (json['atributosBloqueados'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nome': nome,
    'descricaoRaca': descricaoRaca,
    'icone': icone,
    'modificadores': modificadores,
    'habilidadesRaca': habilidadesRaca,
    'ehFlexivel': ehFlexivel,
    'atributosBloqueados': atributosBloqueados,
  };
}
