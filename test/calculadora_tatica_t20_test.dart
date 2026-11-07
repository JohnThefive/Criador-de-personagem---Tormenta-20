import 'package:flutter_test/flutter_test.dart';
import 'package:t20_creator/domain/entities/combate/combatente.dart';
import 'package:t20_creator/domain/entities/combate/grid_tatico.dart';
import 'package:t20_creator/domain/entities/combate/monstro.dart';
import 'package:t20_creator/domain/entities/equipamento/arma.dart';
import 'package:t20_creator/domain/services/combate_services/calculadora_tatica_t20.dart';

void main() {
  group('CalculadoraTaticaT20 - Dano Esperado e Probabilidade de Acerto', () {
    const espadaLonga = Arma(
      key: 'espada_longa',
      nome: 'Espada Longa',
      descricao: '',
      proficiencia: ProficienciaArma.marcial,
      proposito: PropositoArma.corpoACorpo,
      empunhadura: EmpunhaduraArma.umaMao,
      dano: '1d8',
      margemAmeaca: 19,
      multiplicadorCritico: 2,
      tipoDano: TipoDanoArma.corte,
    );

    test('extrairDadosArma separa quantidade e faces corretamente', () {
      final d1d8 = CalculadoraTaticaT20.extrairDadosArma('1d8');
      expect(d1d8.quantidade, equals(1));
      expect(d1d8.faces, equals(8));

      final d2d6 = CalculadoraTaticaT20.extrairDadosArma('2d6');
      expect(d2d6.quantidade, equals(2));
      expect(d2d6.faces, equals(6));
    });

    test('calcularAvaliacaoAtaque calcula probabilidade no d20 (55% contra Defesa 15 com mod +5)', () {
      // Defesa 15, Mod +5 => precisa de 10 no d20 (faces 10 a 20 = 11 faces / 20 = 55%)
      final avaliacao = CalculadoraTaticaT20.calcularAvaliacaoAtaque(
        arma: espadaLonga,
        modAtaqueTotal: 5,
        modDanoTotal: 3,
        defesaAlvo: 15,
      );

      expect(avaliacao.probabilidadeAcerto, closeTo(0.55, 0.001));
      expect(avaliacao.probabilidadePercentualFormatada, equals('55%'));
      // Margem 19 => faces 19 e 20 são críticas (2 faces / 20 = 10%)
      expect(avaliacao.probabilidadeCritico, closeTo(0.10, 0.001));
      // Dano normal: 1d8 (4.5) + 3 = 7.5
      expect(avaliacao.danoMedioNormal, closeTo(7.5, 0.01));
      // Dano crítico: 2d8 (9.0) + 3 = 12.0
      expect(avaliacao.danoMedioCritico, closeTo(12.0, 0.01));
      // Dano esperado: (0.45 * 7.5) + (0.10 * 12.0) = 3.375 + 1.2 = 4.575
      expect(avaliacao.danoEsperado, closeTo(4.575, 0.01));
      expect(avaliacao.danoEsperadoFormatado, equals('4.6'));
    });

    test('Vantagem aumenta chance de acerto e Desvantagem diminui', () {
      final normal = CalculadoraTaticaT20.calcularAvaliacaoAtaque(
        arma: espadaLonga,
        modAtaqueTotal: 5,
        modDanoTotal: 3,
        defesaAlvo: 15,
      );

      final comVantagem = CalculadoraTaticaT20.calcularAvaliacaoAtaque(
        arma: espadaLonga,
        modAtaqueTotal: 5,
        modDanoTotal: 3,
        defesaAlvo: 15,
        temVantagem: true,
      );

      final comDesvantagem = CalculadoraTaticaT20.calcularAvaliacaoAtaque(
        arma: espadaLonga,
        modAtaqueTotal: 5,
        modDanoTotal: 3,
        defesaAlvo: 15,
        temDesvantagem: true,
      );

      expect(comVantagem.probabilidadeAcerto, greaterThan(normal.probabilidadeAcerto));
      // 1 - (1 - 0.55)^2 = 1 - 0.45^2 = 1 - 0.2025 = 0.7975 (aprox 80%)
      expect(comVantagem.probabilidadeAcerto, closeTo(0.7975, 0.001));

      expect(comDesvantagem.probabilidadeAcerto, lessThan(normal.probabilidadeAcerto));
      // 0.55^2 = 0.3025 (aprox 30%)
      expect(comDesvantagem.probabilidadeAcerto, closeTo(0.3025, 0.001));
    });

    test('Respeita limites T20: 1 é sempre erro (máx 95%) e 20 é sempre acerto (mín 5%)', () {
      // Modificador absurdo (+30 vs Defesa 10)
      final autoHit = CalculadoraTaticaT20.calcularAvaliacaoAtaque(
        arma: espadaLonga,
        modAtaqueTotal: 30,
        modDanoTotal: 0,
        defesaAlvo: 10,
      );
      expect(autoHit.probabilidadeAcerto, closeTo(0.95, 0.001));

      // Defesa absurda (50 vs Mod +0)
      final autoMiss = CalculadoraTaticaT20.calcularAvaliacaoAtaque(
        arma: espadaLonga,
        modAtaqueTotal: 0,
        modDanoTotal: 0,
        defesaAlvo: 50,
      );
      expect(autoMiss.probabilidadeAcerto, closeTo(0.05, 0.001));
    });
  });

  group('CalculadoraTaticaT20 - Avaliação de Posicionamento no Grid', () {
    const monstroHeroi = Monstro(
      id: 'heroi_1',
      nome: 'Guerreiro',
      nd: '1',
      papel: PapelMonstro.solo,
      tipoCriatura: 'Humanoide',
      pvMax: 30,
      defesa: 16,
      deslocamentoMetros: 9.0,
      iniciativa: 12,
      percepcao: 2,
      modForca: 3,
      modDestreza: 2,
      modConstituicao: 2,
      ataques: [],
    );

    const monstroOrc = Monstro(
      id: 'orc_1',
      nome: 'Orc',
      nd: '1',
      papel: PapelMonstro.solo,
      tipoCriatura: 'Humanoide',
      pvMax: 35,
      defesa: 14,
      deslocamentoMetros: 9.0, // 6 quadrados
      iniciativa: 10,
      percepcao: 1,
      modForca: 3,
      modDestreza: 1,
      modConstituicao: 2,
      ataques: [],
    );

    final heroi = CombatenteMonstro.doMonstro(monstroHeroi, time: TimeCombatente.heroi);
    final orc = CombatenteMonstro.doMonstro(monstroOrc, time: TimeCombatente.inimigo);

    test('Identifica Cobertura quando há obstáculo entre herói e inimigo', () {
      // Grid com obstáculo em (4, 3)
      final mapa = GridMapa(
        largura: 10,
        altura: 10,
        terrenos: {
          const Posicao2D(4, 3): TipoTerreno.obstaculo,
        },
      );

      final posicoes = {
        'heroi_1': const Posicao2D(1, 3),
        'orc_1': const Posicao2D(8, 3),
      };

      // Célula (3, 3) é adjacente ao obstáculo (4, 3) que está em direção ao Orc (8, 3)
      final avaliacoes = CalculadoraTaticaT20.avaliarPosicoesGrid(
        posHeroi: const Posicao2D(1, 3),
        alcancaveis: {const Posicao2D(3, 3), const Posicao2D(1, 4)},
        heroi: heroi,
        todosCombatentes: [heroi, orc],
        posicoes: posicoes,
        mapaGrid: mapa,
      );

      final posComCobertura = avaliacoes[const Posicao2D(3, 3)];
      expect(posComCobertura, isNotNull);
      expect(posComCobertura!.temCobertura, isTrue);
      expect(posComCobertura.rotuloTatico, contains('Cobertura'));

      final posSemCobertura = avaliacoes[const Posicao2D(1, 4)];
      expect(posSemCobertura!.temCobertura, isFalse);
    });

    test('Identifica Distância Segura (Kiting) além do deslocamento de 9m do Orc', () {
      const mapa = GridMapa(largura: 15, altura: 10);
      final posicoes = {
        'heroi_1': const Posicao2D(0, 3),
        'orc_1': const Posicao2D(8, 3), // distância de 8 quadrados = 12 metros
      };

      final avaliacoes = CalculadoraTaticaT20.avaliarPosicoesGrid(
        posHeroi: const Posicao2D(0, 3),
        alcancaveis: {
          const Posicao2D(0, 3), // 12 metros do Orc (> 9m)
          const Posicao2D(6, 3), // 2 quadrados = 3 metros do Orc (<= 9m)
        },
        heroi: heroi,
        todosCombatentes: [heroi, orc],
        posicoes: posicoes,
        mapaGrid: mapa,
      );

      expect(avaliacoes[const Posicao2D(0, 3)]!.ehPosicaoSegura, isTrue);
      expect(avaliacoes[const Posicao2D(6, 3)]!.ehPosicaoSegura, isFalse);
    });
  });
}
