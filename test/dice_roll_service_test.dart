import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:t20_creator/domain/services/combate_services/dice_roll_service.dart';

class FakeRandom implements Random {
  final List<int> valoresNextInt;
  int _index = 0;

  FakeRandom(this.valoresNextInt);

  @override
  int nextInt(int max) {
    if (_index >= valoresNextInt.length) {
      return 0;
    }
    return valoresNextInt[_index++];
  }

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0.0;
}

void main() {
  group('DiceRollService - Rolagens de D20', () {
    test('Rolagem normal calcula total e identificação de 20 natural', () {
      // nextInt(20) retornando 19 resulta em 1 + 19 = 20
      final fake = FakeRandom([19]);
      final service = DiceRollService(random: fake);

      final resultado = service.rolarD20(modificador: 3, nomeModificador: 'Iniciativa');

      expect(resultado.d20, 20);
      expect(resultado.modificador, 3);
      expect(resultado.total, 23);
      expect(resultado.ehVinteNatural, isTrue);
      expect(resultado.ehUmNatural, isFalse);
      expect(resultado.decomposicao, 'd20 (20) + Iniciativa (+3) = 23');
    });

    test('Rolagem normal identifica 1 natural', () {
      // nextInt(20) retornando 0 resulta em 1 + 0 = 1
      final fake = FakeRandom([0]);
      final service = DiceRollService(random: fake);

      final resultado = service.rolarD20(modificador: -2, nomeModificador: 'Penalidade');

      expect(resultado.d20, 1);
      expect(resultado.total, -1);
      expect(resultado.ehVinteNatural, isFalse);
      expect(resultado.ehUmNatural, isTrue);
      expect(resultado.decomposicao, 'd20 (1) + Penalidade (-2) = -1');
    });

    test('Vantagem escolhe o maior entre dois dados', () {
      // Primeiro dado: 4 (5 no total), Segundo dado: 16 (17 no total)
      final fake = FakeRandom([4, 16]);
      final service = DiceRollService(random: fake);

      final resultado = service.rolarD20(
        modificador: 4,
        nomeModificador: 'Ataque',
        vantagem: TipoVantagem.vantagem,
      );

      expect(resultado.d20, 17);
      expect(resultado.d20Segundo, 5);
      expect(resultado.total, 21);
      expect(resultado.tipoVantagem, TipoVantagem.vantagem);
      expect(resultado.decomposicao, contains('Vantagem'));
    });

    test('Desvantagem escolhe o menor entre dois dados', () {
      // Primeiro dado: 18 (19 no total), Segundo dado: 3 (4 no total)
      final fake = FakeRandom([18, 3]);
      final service = DiceRollService(random: fake);

      final resultado = service.rolarD20(
        modificador: 2,
        nomeModificador: 'Luta',
        vantagem: TipoVantagem.desvantagem,
      );

      expect(resultado.d20, 4);
      expect(resultado.d20Segundo, 19);
      expect(resultado.total, 6);
      expect(resultado.tipoVantagem, TipoVantagem.desvantagem);
      expect(resultado.decomposicao, contains('Desvantagem'));
    });

    test('rolarDano calcula expressão de dano normal com bônus', () {
      // nextInt(8) retornando 5 resulta em 1 + 5 = 6
      final fake = FakeRandom([5]);
      final service = DiceRollService(random: fake);

      final resultado = service.rolarDano(
        expressaoDano: '1d8+3',
        bonusExtra: 1, // ex: +1 de Arma de Jade
      );

      expect(resultado.dadosRolados, [6]);
      expect(resultado.bonusFixo, 4); // 3 da arma + 1 de bônus extra
      expect(resultado.total, 10);
      expect(resultado.ehCritico, isFalse);
    });

    test('rolarDano multiplica dados da arma no acerto crítico e inclui dados extras', () {
      // Arma 1d8 com crítico x2 rola 2 dados: 7 (8) e 6 (7)
      // Dado extra 1d6 rola 1 dado: 3 (4)
      final fake = FakeRandom([7, 6, 3]);
      final service = DiceRollService(random: fake);

      final resultado = service.rolarDano(
        expressaoDano: '1d8+3',
        bonusExtra: 2,
        dadoExtra: '1d6',
        ehCritico: true,
        multiplicadorCritico: 2,
      );

      expect(resultado.dadosRolados, [8, 7, 4]);
      expect(resultado.bonusFixo, 5); // 3 da arma + 2 extra
      expect(resultado.total, 24); // 8 + 7 + 4 + 5 = 24
      expect(resultado.ehCritico, isTrue);
    });
  });
}
