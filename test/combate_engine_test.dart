import 'package:flutter_test/flutter_test.dart';
import 'package:t20_creator/domain/entities/arma.dart';
import 'package:t20_creator/domain/entities/combate/combatente.dart';
import 'package:t20_creator/domain/entities/combate/grid_tatico.dart';
import 'package:t20_creator/domain/services/combate_engine.dart';
import 'package:t20_creator/presentation/controllers/combate_cubit.dart';

void main() {
  group('Núcleo Bélico de Combate Tormenta 20', () {
    const espadaLonga = Arma(
      key: 'ESPADA_LONGA',
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

    final guerreiro = const Combatente(
      id: 'guerreiro_1',
      nome: 'Guerreiro Humano',
      time: TimeCombatente.heroi,
      pvMax: 25,
      pvAtual: 25,
      pmMax: 3,
      pmAtual: 3,
      defesa: 17,
      deslocamentoMetros: 9.0,
      modIniciativa: 4,
      modLuta: 6,
      modPontaria: 1,
      modPercepcao: 0,
      modForca: 3,
      modDestreza: 1,
      modConstituicao: 2,
      armas: [espadaLonga],
    );

    final orc = const Combatente(
      id: 'orc_1',
      nome: 'Guerreiro Orc',
      time: TimeCombatente.inimigo,
      pvMax: 20,
      pvAtual: 20,
      pmMax: 0,
      pmAtual: 0,
      defesa: 14,
      deslocamentoMetros: 9.0,
      modIniciativa: 1,
      modLuta: 5,
      modPontaria: 0,
      modPercepcao: -1,
      modForca: 4,
      modDestreza: 0,
      modConstituicao: 3,
      armas: [espadaLonga],
    );

    test('1. Rolagem e Desempate de Iniciativa', () {
      final engine = CombateEngine();
      final fila = engine.rolarIniciativa([guerreiro, orc]);

      expect(fila.length, 2);
      expect(
        fila.first.iniciativaValor,
        greaterThanOrEqualTo(fila.last.iniciativaValor),
      );
    });

    test('2. Ataque Normal e Crítico no T20', () {
      final engine = CombateEngine();
      final resultado = engine.executarAtaque(
        atacante: guerreiro,
        defensor: orc,
        arma: espadaLonga,
      );

      expect(resultado.atacanteNome, 'Guerreiro Humano');
      if (resultado.acerto) {
        expect(
          resultado.danoTotal,
          greaterThanOrEqualTo(4),
        ); // Mínimo 1 dado (1) + 3 (FOR)
      } else {
        expect(resultado.danoTotal, 0);
      }
    });

    test('3. Fluxo Completo no CombateCubit e Economia de Ações', () {
      final cubit = CombateCubit();
      cubit.iniciarCombate(
        [guerreiro, orc],
        posicoesIniciais: {
          'guerreiro_1': const Posicao2D(1, 1),
          'orc_1': const Posicao2D(1, 2),
        },
      );

      expect(cubit.state.combateIniciado, true);
      expect(cubit.state.rodadaAtual, 1);
      expect(cubit.state.acoesPadraoRestantes, 1);
      expect(cubit.state.acoesMovimentoRestantes, 1);

      // Identifica o combatente ativo e o adversário na fila
      final ativo = cubit.state.combatenteAtual!;
      final adversario =
          cubit.state.filaIniciativa.firstWhere((c) => c.id != ativo.id);

      // Executa ataque (gasta Ação Padrão)
      cubit.executarAtaque(defensor: adversario, arma: espadaLonga);
      expect(cubit.state.acoesPadraoRestantes, 0);

      // Tenta atacar de novo sem ação: é bloqueado
      cubit.executarAtaque(defensor: adversario, arma: espadaLonga);
      expect(
        cubit.state.logCombate.last,
        contains('não possui Ação Padrão disponível'),
      );

      // Passa o turno para o próximo combatente da fila de iniciativa
      final proximoEsperado = cubit.state.filaIniciativa[1].nome;
      cubit.proximoTurno();
      expect(cubit.state.combatenteAtual?.nome, proximoEsperado);
      expect(cubit.state.acoesPadraoRestantes, 1);

      // Executa ação do Bot e cicla de volta para a rodada seguinte
      cubit.executarTurnoBot();
      expect(cubit.state.indiceTurnoAtual, 0);
    });
  });
}
