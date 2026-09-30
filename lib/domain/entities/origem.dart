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
}
