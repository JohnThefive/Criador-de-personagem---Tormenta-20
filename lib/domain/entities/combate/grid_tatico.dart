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

  TipoTerreno obterTerreno(Posicao2D pos) {
    return terrenos[pos] ?? TipoTerreno.normal;
  }

  @override
  List<Object?> get props => [largura, altura, terrenos];
}
