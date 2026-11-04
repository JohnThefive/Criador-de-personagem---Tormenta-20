import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:t20_creator/domain/entities/combate/combatente.dart';
import 'package:t20_creator/domain/entities/combate/efeito_ativo_combate.dart';
import 'package:t20_creator/domain/entities/combate/monstro.dart';
import 'package:t20_creator/domain/entities/equipamento/arma.dart';
import 'package:t20_creator/domain/services/combate_services/arena_stats_collector.dart';
import 'package:t20_creator/presentation/controllers/combate_controller/combate_cubit.dart';
import 'package:t20_creator/presentation/screens/arena/widgets/arena_ataque_sheet.dart';

void main() {
  group('CombateCubit - Sistema de Honestidade & Efeitos Ativos', () {
    late CombateCubit cubit;
    late CombatenteMonstro heroi;
    late CombatenteMonstro inimigo;

    setUp(() {
      cubit = CombateCubit();
      const monstroHeroi = Monstro(
        id: 'heroi_1',
        nome: 'Sir Valen',
        nd: '1',
        papel: PapelMonstro.solo,
        tipoCriatura: 'Humanoide',
        pvMax: 30,
        pmMax: 10,
        defesa: 15,
        deslocamentoMetros: 9.0,
        iniciativa: 15,
        percepcao: 5,
        modForca: 3,
        modDestreza: 2,
        modConstituicao: 2,
        ataques: [
          AtaqueMonstro(
            nome: 'Espada Longa',
            bonusAtaque: 5,
            dano: '1d8',
            margemAmeaca: 19,
            multiplicadorCritico: 2,
            tipoDano: TipoDanoArma.corte,
          ),
        ],
      );

      const monstroInimigo = Monstro(
        id: 'inimigo_1',
        nome: 'Goblin',
        nd: '1/4',
        papel: PapelMonstro.lacaio,
        tipoCriatura: 'Humanoide',
        pvMax: 20,
        defesa: 13,
        deslocamentoMetros: 9.0,
        iniciativa: 10,
        percepcao: 2,
        modForca: 0,
        modDestreza: 3,
        modConstituicao: 1,
        ataques: [],
      );

      heroi = CombatenteMonstro.doMonstro(
        monstroHeroi,
        time: TimeCombatente.heroi,
        pmAtual: 10,
      );

      inimigo = CombatenteMonstro.doMonstro(
        monstroInimigo,
        time: TimeCombatente.inimigo,
      );

      cubit.iniciarCombate(
        [heroi, inimigo],
        iniciativas: {'heroi_1': 25, 'inimigo_1': 10},
      );
    });

    tearDown(() {
      cubit.close();
    });

    test('adicionarEfeitoAtivo adiciona efeito e deduz PM', () {
      const efeito = EfeitoAtivoCombate(
        id: 'efeito_jade',
        nome: 'Arma de Jade',
        descricaoEfeito: '+1 no ataque e no dano',
        bonusAtaque: 1,
        bonusDano: 1,
        rodadasRestantes: 10,
        combatenteId: 'heroi_1',
      );

      cubit.adicionarEfeitoAtivo(efeito, custoPm: 1);

      expect(cubit.state.efeitosAtivos.length, equals(1));
      expect(cubit.state.efeitosAtivos.first.nome, equals('Arma de Jade'));
      expect(cubit.state.combatenteAtual?.pmAtual, equals(9));
    });

    test('adicionarEfeitoAtivo falha se PM for insuficiente', () {
      const efeito = EfeitoAtivoCombate(
        id: 'efeito_caro',
        nome: 'Poder Máximo',
        descricaoEfeito: 'Buff muito caro',
        rodadasRestantes: 5,
        combatenteId: 'heroi_1',
      );

      cubit.adicionarEfeitoAtivo(efeito, custoPm: 50);

      expect(cubit.state.efeitosAtivos, isEmpty);
      expect(cubit.state.combatenteAtual?.pmAtual, equals(10));
    });

    test('removerEfeitoAtivo remove o efeito correspondente', () {
      const efeito = EfeitoAtivoCombate(
        id: 'efeito_remover',
        nome: 'Bênção',
        descricaoEfeito: '+1 ataque',
        rodadasRestantes: 3,
        combatenteId: 'heroi_1',
      );

      cubit.adicionarEfeitoAtivo(efeito);
      expect(cubit.state.efeitosAtivos.length, equals(1));

      cubit.removerEfeitoAtivo('efeito_remover');
      expect(cubit.state.efeitosAtivos, isEmpty);
    });

    test('proximoTurno decrementa a rodada dos efeitos e remove quando expira', () {
      const efeito = EfeitoAtivoCombate(
        id: 'efeito_curto',
        nome: 'Rapidez',
        descricaoEfeito: 'Dura 1 rodada',
        rodadasRestantes: 1,
        combatenteId: 'heroi_1',
      );

      cubit.adicionarEfeitoAtivo(efeito);
      expect(cubit.state.efeitosAtivos.first.rodadasRestantes, equals(1));

      // Herói passa turno (vai para inimigo, rodada ainda é 1)
      cubit.proximoTurno();
      expect(cubit.state.rodadaAtual, equals(1));
      expect(cubit.state.efeitosAtivos.length, equals(1));

      // Inimigo passa turno (volta para herói, rodada vira 2)
      cubit.proximoTurno();
      expect(cubit.state.rodadaAtual, equals(2));
      // O efeito de 1 rodada expirou e foi removido
      expect(cubit.state.efeitosAtivos, isEmpty);
    });

    test('aplicarDanoManual aplica dano e desfazerUltimoDano reverte', () {
      expect(cubit.podeDesfazerDano, isFalse);

      cubit.aplicarDanoManual(
        alvo: inimigo,
        dano: 8,
        descricaoAcao: 'Teste de Dano Manual',
      );

      final inimigoAposDano = cubit.state.filaIniciativa.firstWhere((c) => c.id == 'inimigo_1');
      expect(inimigoAposDano.pvAtual, equals(12));
      expect(cubit.podeDesfazerDano, isTrue);

      // Reverte o dano
      cubit.desfazerUltimoDano();
      final inimigoAposUndo = cubit.state.filaIniciativa.firstWhere((c) => c.id == 'inimigo_1');
      expect(inimigoAposUndo.pvAtual, equals(20));
      expect(cubit.podeDesfazerDano, isFalse);
    });
  });

  group('ArenaAtaqueSheet Widget Test', () {
    testWidgets('Renderiza ArenaAtaqueSheet com arma, alvo e interações', (tester) async {
      final cubit = CombateCubit();
      const arma = Arma(
        key: 'espada_curta',
        nome: 'Espada Curta',
        descricao: 'Pequena lâmina',
        proficiencia: ProficienciaArma.simples,
        proposito: PropositoArma.corpoACorpo,
        empunhadura: EmpunhaduraArma.leve,
        dano: '1d6',
        margemAmeaca: 19,
        multiplicadorCritico: 2,
        tipoDano: TipoDanoArma.perfuracao,
        espacos: 1,
        precoTibar: 10,
        alcance: '1,5m',
        propriedades: [],
        melhorias: [],
        encantos: [],
      );

      const monstroGuerreiro = Monstro(
        id: 'h1',
        nome: 'Guerreiro',
        nd: '1',
        papel: PapelMonstro.solo,
        tipoCriatura: 'Humanoide',
        pvMax: 20,
        defesa: 14,
        deslocamentoMetros: 9.0,
        iniciativa: 12,
        percepcao: 4,
        modForca: 2,
        modDestreza: 1,
        modConstituicao: 2,
        ataques: [
          AtaqueMonstro(
            nome: 'Espada Curta',
            bonusAtaque: 4,
            dano: '1d6',
            margemAmeaca: 19,
            multiplicadorCritico: 2,
            tipoDano: TipoDanoArma.perfuracao,
          ),
        ],
      );

      const monstroOgro = Monstro(
        id: 'i1',
        nome: 'Ogro',
        nd: '2',
        papel: PapelMonstro.solo,
        tipoCriatura: 'Gigante',
        pvMax: 40,
        defesa: 12,
        deslocamentoMetros: 9.0,
        iniciativa: 8,
        percepcao: 3,
        modForca: 4,
        modDestreza: 0,
        modConstituicao: 3,
        ataques: [],
      );

      final heroi = CombatenteMonstro.doMonstro(
        monstroGuerreiro,
        time: TimeCombatente.heroi,
        pmAtual: 5,
      );

      final inimigo = CombatenteMonstro.doMonstro(
        monstroOgro,
        time: TimeCombatente.inimigo,
      );

      cubit.iniciarCombate([heroi, inimigo]);
      final stats = ArenaStatsCollector();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: ArenaAtaqueSheet(
                heroi: heroi,
                arma: arma,
                inimigos: [inimigo],
                efeitosAtivos: const [],
                cubit: cubit,
                stats: stats,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Espada Curta'), findsOneWidget);
      expect(find.text('Flanco (+2)'), findsOneWidget);
      expect(find.text('Normal'), findsOneWidget);
      expect(find.text('Vantagem'), findsOneWidget);

      // Clica no chip de Flanco
      await tester.tap(find.text('Flanco (+2)'));
      await tester.pumpAndSettle();

      // Botão de Rolar Ataque deve estar presente
      expect(find.byIcon(Icons.casino), findsOneWidget);

      await tester.tap(find.byIcon(Icons.casino));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pumpAndSettle();

      // Deve ter concluído a rolagem e exibir se acertou/errou ou botão de rolar dano
      expect(find.textContaining('vs Defesa: 12'), findsOneWidget);

      cubit.close();
    });
  });
}
