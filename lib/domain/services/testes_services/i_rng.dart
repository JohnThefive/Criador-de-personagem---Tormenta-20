import 'dart:math';

/// Interface pura de geração de números aleatórios para injeção determinística nos testes.
abstract interface class IRng {
  /// Rola 1d20, retornando um inteiro entre 1 e 20 (inclusive).
  int rolarD20();

  /// Rola 1d100, retornando um inteiro entre 1 e 100 (inclusive).
  int rolarD100();
}

/// Implementação padrão de [IRng] baseada em `dart:math.Random`.
class RandomRng implements IRng {
  final Random _random;

  RandomRng({Random? random}) : _random = random ?? Random();

  @override
  int rolarD20() => 1 + _random.nextInt(20);

  @override
  int rolarD100() => 1 + _random.nextInt(100);
}

/// Implementação determinística de [IRng] para testes unitários.
/// Recebe os valores exatos de d20 (1..20) e opcionalmente d100 (1..100) em sequência.
class SequenciaRng implements IRng {
  final List<int> _valoresD20;
  final List<int> _valoresD100;
  int _indiceD20 = 0;
  int _indiceD100 = 0;

  SequenciaRng(
    this._valoresD20, {
    List<int> valoresD100 = const [50],
  }) : _valoresD100 = valoresD100;

  @override
  int rolarD20() {
    if (_valoresD20.isEmpty) {
      throw StateError('SequenciaRng: lista de rolagens d20 vazia.');
    }
    if (_indiceD20 >= _valoresD20.length) {
      return _valoresD20.last.clamp(1, 20);
    }
    final valor = _valoresD20[_indiceD20++];
    if (valor < 1 || valor > 20) {
      throw RangeError.range(
        valor,
        1,
        20,
        'd20',
        'Valor de d20 fora do intervalo 1..20',
      );
    }
    return valor;
  }

  @override
  int rolarD100() {
    if (_valoresD100.isEmpty) {
      throw StateError('SequenciaRng: lista de rolagens d100 vazia.');
    }
    if (_indiceD100 >= _valoresD100.length) {
      return _valoresD100.last.clamp(1, 100);
    }
    final valor = _valoresD100[_indiceD100++];
    if (valor < 1 || valor > 100) {
      throw RangeError.range(
        valor,
        1,
        100,
        'd100',
        'Valor de d100 fora do intervalo 1..100',
      );
    }
    return valor;
  }
}
