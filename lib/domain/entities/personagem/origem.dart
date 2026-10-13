import 'poder.dart';

class Origem {
  final String id;
  final String nome;
  final String descricao;
  final List<String> itensIniciais;
  final List<String> periciasOpcoes;
  final List<Poder> poderesGeraisOpcoes;
  final Poder poderUnico; // Poder exclusivo desta origem

  const Origem({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.itensIniciais,
    required this.periciasOpcoes,
    required this.poderesGeraisOpcoes,
    required this.poderUnico,
  });

  factory Origem.fromJson(Map<String, dynamic> json) {
    return Origem(
      id: json['id'] as String? ?? '',
      nome: json['nome'] as String? ?? '',
      descricao: json['descricao'] as String? ?? '',
      itensIniciais: List<String>.from(json['itensIniciais'] ?? []),
      periciasOpcoes: List<String>.from(json['periciasOpcoes'] ?? []),
      poderesGeraisOpcoes: (json['poderesGeraisOpcoes'] as List? ?? [])
          .map((p) => Poder.fromJson(p as Map<String, dynamic>))
          .toList(),
      poderUnico: json['poderUnico'] != null
          ? Poder.fromJson(json['poderUnico'] as Map<String, dynamic>)
          : const Poder(key: '', nome: '', descricao: ''),
    );
  }
}
