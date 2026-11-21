import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:t20_creator/domain/entities/combate/combatente.dart';
import 'package:t20_creator/domain/entities/combate/efeito_ativo_combate.dart';
import 'package:t20_creator/domain/entities/combate/grid_tatico.dart';
import 'package:t20_creator/domain/entities/combate/monstro.dart';
import 'package:t20_creator/domain/entities/equipamento/arma.dart';
import 'package:t20_creator/domain/entities/habilidades/modelos_habilidade_duracao.dart';
import 'package:t20_creator/domain/entities/magia/magia.dart';
import 'package:t20_creator/domain/entities/personagem/personagem.dart';
import 'package:t20_creator/domain/services/combate_services/arena_stats_collector.dart';
import 'package:t20_creator/domain/services/combate_services/combate_engine.dart';
import 'package:t20_creator/domain/services/combate_services/dice_roll_service.dart';
import 'package:t20_creator/domain/services/data_services/call_magias.dart';
import 'package:t20_creator/domain/services/habilidades_services/geometria_grid.dart';
import 'package:t20_creator/presentation/controllers/combate_controller/combate_cubit.dart';
import 'package:t20_creator/presentation/controllers/combate_controller/combate_state.dart';
import 'package:t20_creator/presentation/screens/arena/widgets/arena_ataque_sheet.dart';
import 'package:t20_creator/presentation/screens/arena/widgets/arena_magia_sheet.dart';
import 'package:t20_creator/presentation/screens/arena/widgets/arena_relatorio_dialog.dart';

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

    test('aplicarDanoManual aplica dano letal e cura corretamente', () {
      cubit.aplicarDanoManual(
        alvo: inimigo,
        dano: 8,
        descricaoAcao: 'Teste de Dano Manual',
      );

      final inimigoAposDano = cubit.state.filaIniciativa.firstWhere((c) => c.id == 'inimigo_1');
      expect(inimigoAposDano.pvAtual, equals(12));

      // Aplica cura
      cubit.aplicarDanoManual(
        alvo: inimigo,
        dano: 5,
        descricaoAcao: 'Teste de Cura Manual',
        ehCura: true,
      );

      final inimigoAposCura = cubit.state.filaIniciativa.firstWhere((c) => c.id == 'inimigo_1');
      expect(inimigoAposCura.pvAtual, equals(17));
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
            body: Builder(
              builder: (ctx) => MediaQuery(
                data: MediaQuery.of(ctx).copyWith(disableAnimations: true),
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

    test('ArenaStatsCollector calcula métricas (DPR, Taxa de Acerto, Pico de Dano) corretamente', () {
      final stats = ArenaStatsCollector();

      // Ataque 1: Acerto com 15 de dano (não crítico)
      stats.registrarAtaque(acerto: true, ehCritico: false, dano: 15);
      // Ataque 2: Erro
      stats.registrarAtaque(acerto: false, ehCritico: false, dano: 0);
      // Ataque 3: Acerto Crítico com 35 de dano
      stats.registrarAtaque(acerto: true, ehCritico: true, dano: 35);

      // Magia: 2 PM gastos, causou 10 de dano
      stats.registrarMagia(custoPm: 2, dano: 10);

      // Registra dano recebido
      stats.registrarDanoRecebido(12);

      final relatorio = stats.gerarRelatorio(rodadas: 3, vitoria: true);

      expect(relatorio.rodadasTotais, equals(3));
      expect(relatorio.totalAtaquesRealizados, equals(3));
      expect(relatorio.totalAcertos, equals(2));
      expect(relatorio.totalErros, equals(1));
      expect(relatorio.totalCriticos, equals(1));
      expect(relatorio.danoTotalCausado, equals(60)); // 15 + 35 + 10
      expect(relatorio.maiorDanoGolpe, equals(35));
      expect(relatorio.danoTotalRecebido, equals(12));
      expect(relatorio.pmGasto, equals(2));
      expect(relatorio.magiasLancadas, equals(1));
      expect(relatorio.dpr, closeTo(20.0, 0.01)); // 60 / 3
      expect(relatorio.taxaAcerto, closeTo(66.67, 0.1)); // 2 / 3 * 100
      expect(relatorio.taxaCritico, closeTo(50.0, 0.1)); // 1 / 2 acertos * 100
      expect(relatorio.danoMedioPorAcerto, closeTo(30.0, 0.01)); // 60 / 2 = 30.0
      expect(relatorio.vitoria, isTrue);

      // Teste de atualização e sobrescrita de dano recebido
      stats.atualizarDanoRecebido(25);
      expect(stats.danoRecebido, equals(25));

      final relatorioAtualizado = stats.gerarRelatorio(
        rodadas: 3,
        vitoria: true,
        danoRecebidoOverride: 30,
      );
      expect(relatorioAtualizado.danoTotalRecebido, equals(30));
    });

    testWidgets('exibirRelatorioFinal extrai e exibe dano sofrido do combatente heroi', (tester) async {
      final stats = ArenaStatsCollector();
      const monstroHeroi = Monstro(
        id: 'heroi_1',
        nome: 'Sir Valen',
        nd: '1',
        papel: PapelMonstro.solo,
        tipoCriatura: 'Humanoide',
        pvMax: 30,
        defesa: 15,
        deslocamentoMetros: 9.0,
        iniciativa: 15,
        percepcao: 5,
        modForca: 3,
        modDestreza: 2,
        modConstituicao: 2,
        ataques: [],
      );

      // Herói começou com 30 PV e está com 16 PV (sofreu 14 de dano)
      final heroiMachucado = CombatenteMonstro.doMonstro(
        monstroHeroi,
        time: TimeCombatente.heroi,
        pvAtual: 16,
      );

      final state = CombateState(
        filaIniciativa: [heroiMachucado],
        statusCombate: StatusCombate.vitoria,
        rodadaAtual: 2,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => exibirRelatorioFinal(context, state, stats),
              child: const Text('Abrir'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      expect(find.text('VITÓRIA NA ARENA!'), findsOneWidget);
      // O dano sofrido deve ser 14 PV (30 - 16)
      expect(find.text('14 PV'), findsOneWidget);
      expect(stats.danoRecebido, equals(14));
    });

    test(
      'lancarMagia deduz custoPmOverride customizado, registra resumoRolagem e bloqueia se PM for insuficiente',
      () {
        final cubit = CombateCubit();
        addTearDown(cubit.close);

        const magiaSeta = Magia(
          id: 'seta_infalivel',
          nome: 'Seta Infalível de Talude',
          tipo: 'arcana',
          circulo: 1,
          escola: 'Evocação',
          execucao: ExecucaoMagia(tipo: 'padrao'),
          alcance: AlcanceMagia(tipo: 'medio'),
          efeito: EfeitoMagia(tipo: 'alvo'),
          duracao: DuracaoMagia(tipo: 'instantanea'),
          descricao: 'Lança duas setas que causam 2d4+2 pontos de dano de essência.',
          aprimoramentos: [],
        );

        const monstroMago = Monstro(
          id: 'mago_1',
          nome: 'Arcanista',
          nd: '1',
          pvMax: 20,
          pmMax: 10,
          defesa: 13,
          iniciativa: 10,
        );
        const monstroAlvo = Monstro(
          id: 'goblin_1',
          nome: 'Goblin',
          nd: '1/4',
          pvMax: 30,
          defesa: 12,
          iniciativa: 5,
        );

        final mago = CombatenteMonstro.doMonstro(
          monstroMago,
          time: TimeCombatente.heroi,
          pmAtual: 6,
        );
        final goblin = CombatenteMonstro.doMonstro(
          monstroAlvo,
          time: TimeCombatente.inimigo,
        );

        cubit.iniciarCombate(
          [mago, goblin],
          iniciativas: {'mago_1': 20, 'goblin_1': 5},
        );

        // 1. Tenta lançar com 8 PM tendo apenas 6 PM -> falha sem gastar PM
        cubit.lancarMagia(
          magia: magiaSeta,
          alvo: goblin,
          valorDanoOuCura: 14,
          custoPmOverride: 8,
        );
        expect(cubit.state.combatenteAtual?.pmAtual, equals(6));

        // 2. Lança com 4 PM (aprimorada) e rolagem 4d8 -> deduz 4 PM e aplica dano
        cubit.lancarMagia(
          magia: magiaSeta,
          alvo: goblin,
          valorDanoOuCura: 18,
          custoPmOverride: 4,
          resumoRolagem: '4d8 (dados: 5+4+6+3) = 18',
        );

        final magoAtual = cubit.state.filaIniciativa.firstWhere(
          (c) => c.id == 'mago_1',
        );
        final goblinAtual = cubit.state.filaIniciativa.firstWhere(
          (c) => c.id == 'goblin_1',
        );
        expect(magoAtual.pmAtual, equals(2));
        expect(goblinAtual.pvAtual, equals(12));
        expect(
          cubit.state.logCombate.any((l) => l.contains('gastando 4 PM')),
          isTrue,
        );
        expect(
          cubit.state.logCombate.any((l) => l.contains('4d8 (dados: 5+4+6+3) = 18')),
          isTrue,
        );
      },
    );

    testWidgets(
      'ArenaMagiaSheet exibe aprimoramentos (+PM) e permite escolher dado (d2..d100), quantidade, modificador de dano e PM',
      (tester) async {
        const magiaExplosao = Magia(
          id: 'explosao_chamas',
          nome: 'Explosão de Chamas',
          tipo: 'arcana',
          circulo: 1,
          escola: 'Evocação',
          execucao: ExecucaoMagia(tipo: 'padrao'),
          alcance: AlcanceMagia(tipo: 'medio'),
          efeito: EfeitoMagia(tipo: 'cone'),
          duracao: DuracaoMagia(tipo: 'instantanea'),
          descricao: 'Um cone de fogo causa 2d6+1 pontos de dano de fogo.',
          aprimoramentos: [
            AprimoramentoMagia(
              id: 'ap_1',
              custoAdicionalPM: 1,
              descricao: 'aumenta o dano em +1d6+1.',
            ),
            AprimoramentoMagia(
              id: 'ap_truque',
              custoAdicionalPM: 0,
              isTruque: true,
              descricao: 'muda o efeito para uma faísca inofensiva.',
            ),
          ],
        );
        BancoDeMagias.carregarParaTestes([magiaExplosao]);

        final fichaMago = Personagem.inicial().copyWith(
          id: 'p_mago',
          nome: 'Nimbiano',
          pvAtual: 24,
          pmAtual: 12,
          magiasConhecidas: const ['explosao_chamas'],
        );
        final heroi = Combatente.doPersonagem(fichaMago);

        const monstroInimigo = Monstro(
          id: 'orc_1',
          nome: 'Orc',
          nd: '1',
          pvMax: 45,
          defesa: 14,
          iniciativa: 5,
        );
        final inimigo = CombatenteMonstro.doMonstro(
          monstroInimigo,
          time: TimeCombatente.inimigo,
        );

        final cubit = CombateCubit();
        addTearDown(cubit.close);
        cubit.iniciarCombate(
          [heroi, inimigo],
          iniciativas: {heroi.id: 20, inimigo.id: 5},
        );

        final stats = ArenaStatsCollector();
        final rollerDeterministico = DiceRollService(random: Random(42));
        final rollerEsperado = DiceRollService(random: Random(42));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ArenaMagiaSheet(
                heroi: heroi,
                todos: [heroi, inimigo],
                cubit: cubit,
                stats: stats,
                diceRollService: rollerDeterministico,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Seleciona a magia na lista
        await tester.tap(find.text('Explosão de Chamas'));
        await tester.pumpAndSettle();

        // Sugestão inicial extraída da descrição ('2d6+1') e custo base (1 PM)
        expect(find.text('🎲 2d6+1'), findsOneWidget);
        expect(find.text('1 PM'), findsOneWidget);

        // Aprimoramentos (+1 PM e Truque) exibidos no card
        expect(find.text('Aprimoramentos:'), findsOneWidget);
        expect(
          find.textContaining('+1 PM: aumenta o dano em +1d6+1.'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Truque (0 PM): muda o efeito para uma faísca inofensiva.'),
          findsOneWidget,
        );

        // Todos os dados d2, d4, d6, d8, d10, d12, d20 e d100 estão disponíveis
        for (final face in [2, 4, 6, 8, 10, 12, 20, 100]) {
          expect(find.byKey(Key('chip_dado_d$face')), findsOneWidget);
        }

        // Muda o dado para d8, quantidade 2 -> 4, modificador +1 -> +2 (4d8+2) e PM 1 -> 3
        await tester.ensureVisible(find.byKey(const Key('chip_dado_d8')));
        await tester.tap(find.byKey(const Key('chip_dado_d8')));
        await tester.pumpAndSettle();

        await tester.ensureVisible(
          find.byKey(const Key('btn_aumentar_qtd_dados_magia')),
        );
        await tester.tap(find.byKey(const Key('btn_aumentar_qtd_dados_magia')));
        await tester.tap(find.byKey(const Key('btn_aumentar_qtd_dados_magia')));
        await tester.pumpAndSettle();

        await tester.ensureVisible(
          find.byKey(const Key('btn_aumentar_mod_dano_magia')),
        );
        await tester.tap(find.byKey(const Key('btn_aumentar_mod_dano_magia')));
        await tester.pumpAndSettle();

        await tester.ensureVisible(
          find.byKey(const Key('btn_aumentar_pm_magia')),
        );
        await tester.tap(find.byKey(const Key('btn_aumentar_pm_magia')));
        await tester.tap(find.byKey(const Key('btn_aumentar_pm_magia')));
        await tester.pumpAndSettle();

        expect(find.text('🎲 4d8+2'), findsOneWidget);
        expect(find.text('+2'), findsOneWidget);
        expect(find.text('3 PM'), findsOneWidget);

        // Lança a magia rolando 4d8+2 e gastando 3 PM
        await tester.ensureVisible(
          find.byKey(const Key('btn_rolar_magia_total')),
        );
        await tester.tap(find.byKey(const Key('btn_rolar_magia_total')));
        await tester.pumpAndSettle();

        final rolagemEsperada = rollerEsperado.rolarDano(
          expressaoDano: '4d8+2',
        );
        final heroiPosMagia = cubit.state.filaIniciativa.firstWhere(
          (c) => c.id == heroi.id,
        );
        final inimigoPosMagia = cubit.state.filaIniciativa.firstWhere(
          (c) => c.id == inimigo.id,
        );

        expect(heroiPosMagia.pmAtual, equals(12 - 3));
        expect(inimigoPosMagia.pvAtual, equals(45 - rolagemEsperada.total));
        expect(stats.pmGasto, equals(3));
        expect(
          cubit.state.logCombate.any((l) => l.contains('4d8+2 (dados:')),
          isTrue,
        );
      },
    );

    test(
      'EfeitoMagia.extrairAreaPadrao e CombateCubit.calcularPreviewMagia calculam Cone 6m, Cubo 3m (4 quadrados), Esfera 6m e Linha 9m',
      () {
        // 1. Cone de 6m -> TipoArea.cone, 4 quadrados (6m / 1.5m)
        const efeitoCone = EfeitoMagia(tipo: 'area', descricao: 'cone de 6m');
        final areaCone = efeitoCone.extrairAreaPadrao();
        expect(areaCone, isNotNull);
        expect(areaCone!.tipo, equals(TipoArea.cone));
        expect(areaCone.tamanhoQuadrados, equals(4));

        // 2. Cubo / Quadrado de 3m -> TipoArea.cubo, lado 2 quadrados (2x2 = 4 quadradinhos)
        const efeitoCubo = EfeitoMagia(
          tipo: 'area',
          descricao: 'Quadrado de 3m ou 1 objeto',
        );
        final areaCubo = efeitoCubo.extrairAreaPadrao();
        expect(areaCubo, isNotNull);
        expect(areaCubo!.tipo, equals(TipoArea.cubo));
        expect(areaCubo.tamanhoQuadrados, equals(2));

        // 3. Esfera de 6m de raio -> TipoArea.esfera, raio 4 quadrados
        const efeitoEsfera = EfeitoMagia(
          tipo: 'area',
          descricao: 'esfera com 6m de raio',
        );
        final areaEsfera = efeitoEsfera.extrairAreaPadrao();
        expect(areaEsfera, isNotNull);
        expect(areaEsfera!.tipo, equals(TipoArea.esfera));
        expect(areaEsfera.tamanhoQuadrados, equals(4));

        // 4. Linha de 9m -> TipoArea.linha, 6 quadrados
        const efeitoLinha = EfeitoMagia(tipo: 'area', descricao: 'linha de 9m');
        final areaLinha = efeitoLinha.extrairAreaPadrao();
        expect(areaLinha, isNotNull);
        expect(areaLinha!.tipo, equals(TipoArea.linha));
        expect(areaLinha.tamanhoQuadrados, equals(6));

        // 5. Cálculo no grid via CombateCubit.calcularPreviewMagia
        final fichaMago = Personagem.inicial().copyWith(
          id: 'p_mago_aoe',
          nome: 'Vectorius',
          pvAtual: 30,
          pmAtual: 20,
        );
        final heroi = Combatente.doPersonagem(fichaMago);
        const monstro1 = Monstro(
          id: 'orc_a',
          nome: 'Orc A',
          nd: '1',
          pvMax: 30,
          defesa: 12,
          iniciativa: 2,
        );
        const monstro2 = Monstro(
          id: 'orc_b',
          nome: 'Orc B',
          nd: '1',
          pvMax: 30,
          defesa: 12,
          iniciativa: 1,
        );
        final inimigoA = CombatenteMonstro.doMonstro(
          monstro1,
          time: TimeCombatente.inimigo,
        );
        final inimigoB = CombatenteMonstro.doMonstro(
          monstro2,
          time: TimeCombatente.inimigo,
        );

        final cubit = CombateCubit();
        addTearDown(cubit.close);
        // Mapa limpo sem obstáculos para validar contagem exata de quadrados
        cubit.iniciarCombate(
          [heroi, inimigoA, inimigoB],
          mapa: const GridMapa(largura: 10, altura: 8),
          posicoesIniciais: {
            heroi.id: const Posicao2D(1, 3),
            inimigoA.id: const Posicao2D(4, 3),
            inimigoB.id: const Posicao2D(5, 4),
          },
          iniciativas: {heroi.id: 20, inimigoA.id: 10, inimigoB.id: 5},
        );

        const magiaCubo3m = Magia(
          id: 'area_escorregadia',
          nome: 'Área Escorregadia',
          tipo: 'arcana',
          circulo: 1,
          escola: 'convocacao',
          execucao: ExecucaoMagia(tipo: 'padrao'),
          alcance: AlcanceMagia(tipo: 'curto'),
          efeito: EfeitoMagia(tipo: 'area', descricao: 'quadrado de 3m'),
          duracao: DuracaoMagia(tipo: 'cena'),
          descricao: 'Cobre um quadrado de 3m.',
          aprimoramentos: [],
        );

        // Cubo de 3m ancorado em (4,3) ocupa (4,3), (5,3), (4,4), (5,4) = 4 quadradinhos e atinge Orc A e Orc B!
        final previewCubo = cubit.calcularPreviewMagia(
          magia: magiaCubo3m,
          pontoAlvo: const Posicao2D(4, 3),
        );
        expect(previewCubo.celulasArea.length, equals(4));
        expect(
          previewCubo.celulasArea,
          containsAll([
            const Posicao2D(4, 3),
            const Posicao2D(5, 3),
            const Posicao2D(4, 4),
            const Posicao2D(5, 4),
          ]),
        );
        expect(previewCubo.alvosAfetados.length, equals(2));

        // Lança a magia em área aplicando dano nos 2 inimigos dentro do Cubo de 3m
        cubit.lancarMagia(
          magia: magiaCubo3m,
          alvosAfetados: previewCubo.alvosAfetados,
          valorDanoOuCura: 10,
          custoPmOverride: 2,
          resumoArea: 'Cubo / Quadrado 3m (2x2 = 4q)',
        );

        final orcAPos = cubit.state.filaIniciativa.firstWhere(
          (c) => c.id == inimigoA.id,
        );
        final orcBPos = cubit.state.filaIniciativa.firstWhere(
          (c) => c.id == inimigoB.id,
        );
        expect(orcAPos.pvAtual, equals(20));
        expect(orcBPos.pvAtual, equals(20));
      },
    );

    testWidgets(
      'ArenaMagiaSheet pré-seleciona Área de Efeito do JSON, permite alternar entre Cone, Círculo e Cubo de 3m (4 quadradinhos) e sincroniza com o grid',
      (tester) async {
        const magiaCone = Magia(
          id: 'leque_cromatico',
          nome: 'Leque Cromático',
          tipo: 'arcana',
          circulo: 1,
          escola: 'ilusao',
          execucao: ExecucaoMagia(tipo: 'padrao'),
          alcance: AlcanceMagia(tipo: 'pessoal'),
          efeito: EfeitoMagia(tipo: 'area', descricao: 'cone de 4,5m'),
          duracao: DuracaoMagia(tipo: 'instantanea'),
          descricao: 'Um cone de luzes brilhantes causa 2d6 de dano.',
          aprimoramentos: [],
        );
        BancoDeMagias.carregarParaTestes([magiaCone]);

        final fichaMago = Personagem.inicial().copyWith(
          id: 'p_mago_ui_aoe',
          nome: 'Qareen',
          pvAtual: 24,
          pmAtual: 12,
          magiasConhecidas: const ['leque_cromatico'],
        );
        final heroi = Combatente.doPersonagem(fichaMago);
        const monstroInimigo = Monstro(
          id: 'orc_ui',
          nome: 'Orc Alvo',
          nd: '1',
          pvMax: 40,
          defesa: 13,
          iniciativa: 5,
        );
        final inimigo = CombatenteMonstro.doMonstro(
          monstroInimigo,
          time: TimeCombatente.inimigo,
        );

        final cubit = CombateCubit();
        addTearDown(cubit.close);
        cubit.iniciarCombate(
          [heroi, inimigo],
          mapa: const GridMapa(largura: 10, altura: 8),
          posicoesIniciais: {
            heroi.id: const Posicao2D(1, 3),
            inimigo.id: const Posicao2D(3, 3),
          },
          iniciativas: {heroi.id: 20, inimigo.id: 5},
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ArenaMagiaSheet(
                heroi: heroi,
                todos: [heroi, inimigo],
                cubit: cubit,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Leque Cromático'));
        await tester.pumpAndSettle();

        // Verifica que Cone 4,5m foi detectado automaticamente a partir do JSON
        expect(find.text('Cone 4,5m (3q)'), findsOneWidget);
        expect(find.byKey(const Key('mini_grid_magia_preview')), findsOneWidget);
        expect(cubit.state.celulasAreaMagia, isNotEmpty);

        // Muda formato para Cubo / Quadrado e tamanho para 3m (2x2 = 4 quadradinhos)
        await tester.ensureVisible(
          find.byKey(const Key('chip_forma_area_cubo')),
        );
        await tester.tap(find.byKey(const Key('chip_forma_area_cubo')));
        await tester.pumpAndSettle();

        await tester.ensureVisible(
          find.byKey(const Key('chip_tamanho_area_3m')),
        );
        await tester.tap(find.byKey(const Key('chip_tamanho_area_3m')));
        await tester.pumpAndSettle();

        expect(find.text('Cubo / Quadrado 3m (2x2 = 4q)'), findsOneWidget);
        expect(cubit.state.celulasAreaMagia.length, equals(4));
      },
    );

    test(
      'GeometriaGrid segue fielmente todas as formas da ilustração oficial de Tormenta 20 (Cubos, Raios 1,5m/3m/6m, Linha 15m e Cones retos/diagonais 4,5m/6m/9m) e regras de múltiplos alvos e barreiras',
      () {
        const geo = GeometriaGrid();

        // 1. Cubo de 1,5m (1 quadrado) e Cubo de 3m (2x2 = 4 quadrados)
        expect(
          geo
              .calcularQuadradosBrutosArea(
                const Area(
                  tipo: TipoArea.cubo,
                  tamanhoQuadrados: 1,
                  origemCelula: Posicao2D(3, 3),
                ),
              )
              .length,
          equals(1),
        );
        expect(
          geo
              .calcularQuadradosBrutosArea(
                const Area(
                  tipo: TipoArea.cubo,
                  tamanhoQuadrados: 2,
                  origemCelula: Posicao2D(3, 3),
                ),
              )
              .length,
          equals(4),
        );

        // 2. Raios (Esfera centrada na interseção de 4 quadrados):
        // - Raio 1,5m (r=1) -> bloco 2x2 = 4 quadrados
        // - Raio 3m (r=2) -> cantos cortados (2-4-4-2) = 12 quadrados
        // - Raio 6m (r=4) -> forma quase circular de 8 de diâmetro (2-4-6-8-8-6-4-2) = 40 quadrados
        final raio15 = geo.calcularQuadradosBrutosArea(
          const Area(
            tipo: TipoArea.esfera,
            tamanhoQuadrados: 1,
            origemVertice: VerticeGrid(5, 5),
          ),
        );
        expect(raio15.length, equals(4));

        final raio3 = geo.calcularQuadradosBrutosArea(
          const Area(
            tipo: TipoArea.esfera,
            tamanhoQuadrados: 2,
            origemVertice: VerticeGrid(5, 5),
          ),
        );
        expect(raio3.length, equals(12));
        // Os 4 cantos extremos (3,3), (6,3), (3,6), (6,6) devem estar cortados!
        expect(raio3, isNot(contains(const Posicao2D(3, 3))));
        expect(raio3, isNot(contains(const Posicao2D(6, 6))));

        final raio6 = geo.calcularQuadradosBrutosArea(
          const Area(
            tipo: TipoArea.esfera,
            tamanhoQuadrados: 4,
            origemVertice: VerticeGrid(5, 5),
          ),
        );
        expect(raio6.length, equals(40));
        expect(raio6, contains(const Posicao2D(1, 4))); // extremo esquerdo
        expect(raio6, contains(const Posicao2D(8, 4))); // extremo direito
        expect(raio6, isNot(contains(const Posicao2D(1, 1)))); // canto cortado

        // 3. Linha de 15m (r=10): fileira reta de 10 quadrados, 1 de largura
        final linha15 = geo.calcularQuadradosBrutosArea(
          const Area(
            tipo: TipoArea.linha,
            tamanhoQuadrados: 10,
            origemCelula: Posicao2D(1, 3),
            direcaoDestino: Posicao2D(11, 3),
          ),
        );
        expect(linha15.length, equals(10));
        expect(linha15.every((p) => p.y == 3), isTrue);

        // 4. Cones Retos (4,5m = 7q [1,3,3]; 6m = 12q [1,3,3,5]; 9m = 24q [1,3,3,5,5,7])
        expect(
          geo
              .calcularQuadradosBrutosArea(
                const Area(
                  tipo: TipoArea.cone,
                  tamanhoQuadrados: 3,
                  origemCelula: Posicao2D(2, 5),
                  direcaoDestino: Posicao2D(5, 5),
                ),
              )
              .length,
          equals(7),
        );
        expect(
          geo
              .calcularQuadradosBrutosArea(
                const Area(
                  tipo: TipoArea.cone,
                  tamanhoQuadrados: 4,
                  origemCelula: Posicao2D(2, 5),
                  direcaoDestino: Posicao2D(6, 5),
                ),
              )
              .length,
          equals(12),
        );
        expect(
          geo
              .calcularQuadradosBrutosArea(
                const Area(
                  tipo: TipoArea.cone,
                  tamanhoQuadrados: 6,
                  origemCelula: Posicao2D(2, 5),
                  direcaoDestino: Posicao2D(8, 5),
                ),
              )
              .length,
          equals(24),
        );

        // 5. Cones Diagonais (4,5m = 6q [3,2,1]; 6m = 10q [4,3,2,1]; 9m = 21q [6,5,4,3,2,1])
        expect(
          geo
              .calcularQuadradosBrutosArea(
                const Area(
                  tipo: TipoArea.cone,
                  tamanhoQuadrados: 3,
                  origemCelula: Posicao2D(2, 2),
                  direcaoDestino: Posicao2D(5, 5),
                ),
              )
              .length,
          equals(6),
        );
        expect(
          geo
              .calcularQuadradosBrutosArea(
                const Area(
                  tipo: TipoArea.cone,
                  tamanhoQuadrados: 4,
                  origemCelula: Posicao2D(2, 2),
                  direcaoDestino: Posicao2D(6, 6),
                ),
              )
              .length,
          equals(10),
        );
        expect(
          geo
              .calcularQuadradosBrutosArea(
                const Area(
                  tipo: TipoArea.cone,
                  tamanhoQuadrados: 6,
                  origemCelula: Posicao2D(2, 2),
                  direcaoDestino: Posicao2D(8, 8),
                ),
              )
              .length,
          equals(21),
        );

        // 6. Regras de Múltiplos Alvos (inclusive você em alcance não-pessoal) e Barreiras
        final fichaMago = Personagem.inicial().copyWith(
          id: 'p_mago_regras',
          nome: 'Mago',
          pvAtual: 30,
          pmAtual: 20,
        );
        final heroi = Combatente.doPersonagem(fichaMago);
        final inimigo1 = CombatenteMonstro.doMonstro(
          const Monstro(
            id: 'i1',
            nome: 'Goblin 1',
            nd: '1/2',
            pvMax: 20,
            defesa: 12,
            iniciativa: 2,
          ),
          time: TimeCombatente.inimigo,
        );
        final inimigo2 = CombatenteMonstro.doMonstro(
          const Monstro(
            id: 'i2',
            nome: 'Goblin 2 (atrás da parede)',
            nd: '1/2',
            pvMax: 20,
            defesa: 12,
            iniciativa: 1,
          ),
          time: TimeCombatente.inimigo,
        );

        final cubit = CombateCubit();
        addTearDown(cubit.close);
        cubit.iniciarCombate(
          [heroi, inimigo1, inimigo2],
          mapa: GridMapa(
            largura: 12,
            altura: 8,
            terrenos: {const Posicao2D(4, 3): TipoTerreno.obstaculo},
          ),
          posicoesIniciais: {
            heroi.id: const Posicao2D(1, 3),
            inimigo1.id: const Posicao2D(2, 3),
            inimigo2.id: const Posicao2D(6, 3), // atrás do obstáculo em (4,3)
          },
          iniciativas: {heroi.id: 20, inimigo1.id: 10, inimigo2.id: 5},
        );

        // Linha de 15m (10q) apontada para Leste -> bloqueada pela barreira em (4,3)!
        // Deve atingir Goblin 1 em (2,3), mas NÃO atingir Goblin 2 em (6,3) atrás da parede!
        const magiaLinha = Magia(
          id: 'relampago',
          nome: 'Relâmpago',
          tipo: 'arcana',
          circulo: 2,
          escola: 'evocacao',
          execucao: ExecucaoMagia(tipo: 'padrao'),
          alcance: AlcanceMagia(tipo: 'medio'),
          efeito: EfeitoMagia(tipo: 'area', descricao: 'linha de 15m'),
          duracao: DuracaoMagia(tipo: 'instantanea'),
          descricao: 'Causa 6d6 de dano de eletricidade.',
          aprimoramentos: [],
        );

        final previewLinha = cubit.calcularPreviewMagia(
          magia: magiaLinha,
          pontoAlvo: const Posicao2D(6, 3),
        );
        expect(previewLinha.celulasArea, contains(const Posicao2D(2, 3)));
        expect(previewLinha.celulasArea, contains(const Posicao2D(3, 3)));
        expect(previewLinha.celulasArea, isNot(contains(const Posicao2D(6, 3))));
        expect(previewLinha.celulasBloqueadas, contains(const Posicao2D(6, 3)));
        expect(previewLinha.alvosAfetados.map((a) => a.id), contains(inimigo1.id));
        expect(
          previewLinha.alvosAfetados.map((a) => a.id),
          isNot(contains(inimigo2.id)),
        );

        // Esfera de 3m (alcance curto) centrada na interseção (2,3) -> afeta Goblin 1 E o próprio Herói!
        const magiaBola = Magia(
          id: 'bola_fogo',
          nome: 'Bola de Fogo',
          tipo: 'arcana',
          circulo: 2,
          escola: 'evocacao',
          execucao: ExecucaoMagia(tipo: 'padrao'),
          alcance: AlcanceMagia(tipo: 'curto'),
          efeito: EfeitoMagia(tipo: 'area', descricao: 'esfera de 3m de raio'),
          duracao: DuracaoMagia(tipo: 'instantanea'),
          descricao: 'Causa 6d6 de dano de fogo.',
          aprimoramentos: [],
        );
        final previewEsfera = cubit.calcularPreviewMagia(
          magia: magiaBola,
          verticeAlvo: const VerticeGrid(2, 3),
        );
        expect(previewEsfera.centroVertice, equals(const VerticeGrid(2, 3)));
        expect(
          previewEsfera.alvosAfetados.map((a) => a.id),
          containsAll([heroi.id, inimigo1.id]),
        );

        // Aplica dano nos 2 alvos simultaneamente (Herói e Goblin 1)
        cubit.lancarMagia(
          magia: magiaBola,
          alvosAfetados: previewEsfera.alvosAfetados,
          valorDanoOuCura: 8,
          custoPmOverride: 3,
        );
        expect(
          cubit.state.filaIniciativa
              .firstWhere((c) => c.id == heroi.id)
              .pvAtual,
          equals(22),
        );
        expect(
          cubit.state.filaIniciativa
              .firstWhere((c) => c.id == inimigo1.id)
              .pvAtual,
          equals(12),
        );
      },
    );
  });
}
