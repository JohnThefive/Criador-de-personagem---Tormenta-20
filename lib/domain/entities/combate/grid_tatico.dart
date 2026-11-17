import 'package:equatable/equatable.dart';

enum TipoTerreno {
  normal, // Custo 1.5m ortogonal, 3.0m diagonal
  dificil, // Custo dobro: 3.0m ortogonal, 4.5m diagonal
  obstaculo; // Intransponível

  String get label {
    switch (this) {
      case TipoTerreno.normal:
        return 'Normal';
      case TipoTerreno.dificil:
        return 'Difícil';
      case TipoTerreno.obstaculo:
        return 'Obstáculo';
    }
  }
}

class Posicao2D extends Equatable {
  final int x;
  final int y;

  const Posicao2D(this.x, this.y);

  @override
  List<Object?> get props => [x, y];

  @override
  String toString() => '($x, $y)';

  /// Verifica se é uma posição adjacente (distância Chebyshev == 1)
  bool ehAdjacente(Posicao2D outra) {
    final dx = (x - outra.x).abs();
    final dy = (y - outra.y).abs();
    return (dx <= 1 && dy <= 1) && !(dx == 0 && dy == 0);
  }

  /// Verifica se o movimento de 'this' para 'outra' é na diagonal
  bool ehDiagonal(Posicao2D outra) {
    final dx = (x - outra.x).abs();
    final dy = (y - outra.y).abs();
    return dx == 1 && dy == 1;
  }

  /// Distância Chebyshev (em quadrados do grid T20)
  int distanciaEmQuadrados(Posicao2D outra) {
    final dx = (x - outra.x).abs();
    final dy = (y - outra.y).abs();
    return dx > dy ? dx : dy;
  }

  /// Distância em metros no padrão T20 (1 quadrado = 1.5m)
  double distanciaMetros(Posicao2D outra) => distanciaEmQuadrados(outra) * 1.5;

  /// Retorna todas as células ocupadas por um token N×N com âncora topo-esquerda em `this`.
  List<Posicao2D> celulasOcupadas(int tamanhoQuadrados) {
    final span = tamanhoQuadrados < 1 ? 1 : tamanhoQuadrados;
    if (span == 1) return [this];
    return [
      for (int dx = 0; dx < span; dx++)
        for (int dy = 0; dy < span; dy++) Posicao2D(x + dx, y + dy),
    ];
  }

  /// Distância Chebyshev mínima (em quadrados) entre duas áreas N×N.
  int distanciaParaArea(
    Posicao2D outraOrigem, {
    int tamanhoEsta = 1,
    int tamanhoOutra = 1,
  }) {
    final s1 = tamanhoEsta < 1 ? 1 : tamanhoEsta;
    final s2 = tamanhoOutra < 1 ? 1 : tamanhoOutra;

    final int maxX1 = x + s1 - 1;
    final int maxY1 = y + s1 - 1;
    final int maxX2 = outraOrigem.x + s2 - 1;
    final int maxY2 = outraOrigem.y + s2 - 1;

    final int dx;
    if (maxX1 < outraOrigem.x) {
      dx = outraOrigem.x - maxX1;
    } else if (maxX2 < x) {
      dx = x - maxX2;
    } else {
      dx = 0;
    }

    final int dy;
    if (maxY1 < outraOrigem.y) {
      dy = outraOrigem.y - maxY1;
    } else if (maxY2 < y) {
      dy = y - maxY2;
    } else {
      dy = 0;
    }

    return dx > dy ? dx : dy;
  }

  /// Verifica se duas áreas N×N são adjacentes (distância == 1 quadrado).
  bool ehAdjacenteArea(
    Posicao2D outraOrigem, {
    int tamanhoEsta = 1,
    int tamanhoOutra = 1,
  }) =>
      distanciaParaArea(
        outraOrigem,
        tamanhoEsta: tamanhoEsta,
        tamanhoOutra: tamanhoOutra,
      ) ==
      1;

  /// Distância em metros entre duas áreas N×N (1 quadrado = 1.5m).
  double distanciaMetrosAreas(
    Posicao2D outraOrigem, {
    int tamanhoEsta = 1,
    int tamanhoOutra = 1,
  }) =>
      distanciaParaArea(
        outraOrigem,
        tamanhoEsta: tamanhoEsta,
        tamanhoOutra: tamanhoOutra,
      ) *
      1.5;
}

class GridMapa extends Equatable {
  final int largura;
  final int altura;
  final Map<Posicao2D, TipoTerreno> terrenos;

  const GridMapa({
    this.largura = 10,
    this.altura = 10,
    this.terrenos = const {},
  });

  bool dentroDosLimites(Posicao2D pos) {
    return pos.x >= 0 && pos.x < largura && pos.y >= 0 && pos.y < altura;
  }

  bool areaDentroDosLimites(Posicao2D origem, int tamanhoQuadrados) {
    final span = tamanhoQuadrados < 1 ? 1 : tamanhoQuadrados;
    return origem.x >= 0 &&
        origem.y >= 0 &&
        (origem.x + span) <= largura &&
        (origem.y + span) <= altura;
  }

  TipoTerreno obterTerreno(Posicao2D pos) {
    return terrenos[pos] ?? TipoTerreno.normal;
  }

  @override
  List<Object?> get props => [largura, altura, terrenos];
}
