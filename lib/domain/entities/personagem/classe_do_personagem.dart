import 'classe.dart';
import 'poder.dart';
import '../habilidades_complexas/linhagem_arcanista.dart';

class ClasseDoPersonagem {
  final Classe classeDefinicao; // Referência à regra (Bárbaro)
  final int nivel; // Nível atual nesta classe (ex: 5)
  final Map<String, String> periciasExclusivasEscolhidas;
  final List<Poder> poderesEscolhidos;
  final CaminhoDeClasse? caminhoEscolhido;
  final Linhagem? linhagemEscolhida;

  ClasseDoPersonagem({
    required this.classeDefinicao,
    required int nivel,
    this.periciasExclusivasEscolhidas = const {},
    this.caminhoEscolhido,
    this.poderesEscolhidos = const [],
    this.linhagemEscolhida,
  }) : nivel = _validarNivelIndividual(nivel);

  static int _validarNivelIndividual(int valor) {
    if (valor < 1 || valor > 20) {
      throw ArgumentError.value(
        valor,
        'nivel',
        'RV02: O nível individual de uma classe registrada deve ser um inteiro positivo entre 1 e 20.',
      );
    }
    return valor;
  }

  ClasseDoPersonagem copyWith({
    Classe? classeDefinicao,
    int? nivel,
    Map<String, String>? periciasExclusivasEscolhidas,
    CaminhoDeClasse? caminhoEscolhido,
    bool anularCaminho = false,
    List<Poder>? poderesEscolhidos,
    Linhagem? linhagemEscolhida,
    bool anularLinhagem = false,
  }) {
    return ClasseDoPersonagem(
      classeDefinicao: classeDefinicao ?? this.classeDefinicao,
      nivel: _validarNivelIndividual(nivel ?? this.nivel),
      periciasExclusivasEscolhidas:
          periciasExclusivasEscolhidas ?? this.periciasExclusivasEscolhidas,
      caminhoEscolhido: anularCaminho
          ? null
          : (caminhoEscolhido ?? this.caminhoEscolhido),
      poderesEscolhidos: poderesEscolhidos ?? this.poderesEscolhidos,
      linhagemEscolhida: anularLinhagem
          ? null
          : (linhagemEscolhida ?? this.linhagemEscolhida),
    );
  }

  bool get possuiHerancaBasica => linhagemEscolhida != null;
  bool get possuiHerancaAprimorada =>
      poderesEscolhidos.any((p) => p.nome == "Herança Aprimorada");
  bool get possuiHerancaSuperior =>
      poderesEscolhidos.any((p) => p.nome == "Herança Superior");

  /// RF04 / RF05 / RN08 — Características da tabela de progressão adquiridas até o nível individual desta classe.
  List<String> get caracteristicasAdquiridas {
    final lista = <String>[];
    for (int n = 1; n <= nivel; n++) {
      lista.addAll(classeDefinicao.tabelaDeProgressao[n] ?? const <String>[]);
    }
    return List.unmodifiable(lista);
  }

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
      poderesEscolhidos: poderesEscolhidos
          .where((p) => p.key != poderKey)
          .toList(),
    );
  }
}
