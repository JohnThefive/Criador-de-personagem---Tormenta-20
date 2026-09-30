import 'classe.dart';
import 'poder.dart'; 
import 'linhagem_arcanista.dart';

class ClasseDoPersonagem {
  final Classe classeDefinicao; // Referência à regra (Bárbaro)
  final int nivel;               // Nível atual nesta classe (ex: 5)
  final List<Poder> poderesEscolhidos;
  final CaminhoDeClasse? caminhoEscolhido;
  final Linhagem? linhagemEscolhida;


  //

  ClasseDoPersonagem({
    required this.classeDefinicao,
    required int nivel,
    this.caminhoEscolhido,
    this.poderesEscolhidos = const [],
    this.linhagemEscolhida,
  }) : nivel = nivel.clamp(1, 20);

  ClasseDoPersonagem copyWith({
    int? nivel, 
    CaminhoDeClasse? caminhoEscolhido,
    List<Poder>? poderesEscolhidos,
    Linhagem? linhagemEscolhida,
  }) {
    return ClasseDoPersonagem(
      classeDefinicao: classeDefinicao,
      nivel: (nivel ?? this.nivel).clamp(1, 20),
      caminhoEscolhido: caminhoEscolhido ?? this.caminhoEscolhido,
      poderesEscolhidos: poderesEscolhidos ?? this.poderesEscolhidos,
      linhagemEscolhida: linhagemEscolhida ?? this.linhagemEscolhida,
    );
  }

  bool get possuiHerancaBasica => linhagemEscolhida != null;
  bool get possuiHerancaAprimorada => poderesEscolhidos.any((p) => p.nome == "Herança Aprimorada");
  bool get possuiHerancaSuperior => poderesEscolhidos.any((p) => p.nome == "Herança Superior");

  /// No Tormenta 20, a cada nível a partir do 2º o personagem ganha um poder de classe.
  int get poderesPermitidos => (nivel - 1).clamp(0, 20);

  /// Quantidade de poderes que ainda podem ser escolhidos para o nível atual.
  int get poderesPendentes =>
      (poderesPermitidos - poderesEscolhidos.length).clamp(0, 20);

  /// Indica se há poderes a serem escolhidos pelo jogador.
  bool get temPoderPendente => poderesPendentes > 0;

  ClasseDoPersonagem adicionarPoder(Poder poder) {
    if (poderesEscolhidos.any((p) => p.key == poder.key)) return this;
    return copyWith(poderesEscolhidos: [...poderesEscolhidos, poder]);
  }

  ClasseDoPersonagem removerPoder(String poderKey) {
    return copyWith(
      poderesEscolhidos:
          poderesEscolhidos.where((p) => p.key != poderKey).toList(),
    );
  }
}