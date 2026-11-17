import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:t20_creator/domain/entities/combate/combatente.dart';
import 'package:t20_creator/domain/entities/combate/grid_tatico.dart';
import 'package:t20_creator/domain/entities/combate/monstro.dart';
import 'package:t20_creator/domain/entities/combate/tipo_dano.dart';
import 'package:t20_creator/domain/entities/equipamento/arma.dart';
import 'package:t20_creator/domain/entities/habilidades/modelos_resistencia_efeito.dart';
import 'package:t20_creator/domain/entities/personagem/personagem.dart';
import 'package:t20_creator/domain/services/combate_services/arena_stats_collector.dart';
import 'package:t20_creator/domain/services/combate_services/combate_engine.dart';
import 'package:t20_creator/domain/services/combate_services/movimento_engine.dart';
import 'package:t20_creator/presentation/controllers/combate_controller/combate_cubit.dart';
import 'package:t20_creator/presentation/controllers/combate_controller/combate_state.dart';
import 'package:t20_creator/presentation/screens/arena/widgets/arena_relatorio_dialog.dart';
import 'package:t20_creator/presentation/screens/arena/widgets/rolar_iniciativa_view.dart';
import 'package:t20_creator/presentation/screens/arena/widgets/selecao_inimigos.dart';
import 'package:t20_creator/presentation/screens/arena/widgets/vtt_board_widget.dart';

void main() {
  group('CombatenteMonstro - Tipos, Imunidades, RD, Vulnerabilidade e Recarga', () {
    test('Construto: possui visão no escuro, imunidades inatas e só cura com Ofício artesão', () {
      const golem = Monstro(
        id: 'golem_ferro',
        nome: 'Golem de Ferro',
        nd: '5',
        papel: PapelMonstro.solo,
        tipoCriatura: 'construto',
        tamanho: 'grande',
        pvMax: 100,
        defesa: 22,
        deslocamentoMetros: 9.0,
        iniciativa: 4,
        percepcao: 5,
        fortitude: 12,
        reflexos: 6,
        vontade: 8,
        modForca: 6,
        modDestreza: 0,
        modConstituicao: 4,
        constituicaoNula: true,
        modInteligencia: null,
        rd: {'adamante': 10},
      );

      final combatente = CombatenteMonstro.doMonstro(golem, pvAtual: 60);

      expect(combatente.ehConstruto, isTrue);
      expect(combatente.possuiVisaoNoEscuro, isTrue);
      expect(combatente.imuneACritico, isTrue);
      expect(combatente.tamanhoQuadrados, equals(2));
      expect(combatente.temInteligenciaNula, isTrue);
      expect(combatente.temConstituicaoNula, isTrue);
      expect(combatente.modConstituicao, equals(0));
      expect(combatente.modFortitude, equals(12));

      // Imunidades via ImunidadeService
      expect(combatente.isImuneAEfeitos({TipoEfeito.veneno}), isTrue);
      expect(combatente.isImuneAEfeitos({TipoEfeito.cansaco}), isTrue);
      expect(combatente.isImuneAEfeitos({TipoEfeito.metabolismo}), isTrue);
      expect(combatente.isImuneAEfeitos({TipoEfeito.medo}), isTrue);
      expect(combatente.isImuneAEfeitos({TipoEfeito.mental}), isTrue);

      // Cura mágica comum não recupera PV de Construto
      final aposCuraMagica = combatente.aplicarCura(20, magica: true);
      expect(aposCuraMagica.pvAtual, equals(60));

      // Reparo via Ofício (artesão) recupera PV normalmente
      final aposReparo = combatente.aplicarCura(20, ehReparoConstruto: true);
      expect(aposReparo.pvAtual, equals(80));

      // RD adamante reduz dano físico comum, mas é ignorada por arma de adamante
      final danoComum = combatente.aplicarDano(25, tipo: TipoDano.corte);
      expect(danoComum.pvAtual, equals(45)); // 60 - (25 - 10)
      final danoAdamante = combatente.aplicarDano(
        25,
        tipo: TipoDano.corte,
        armaAdamante: true,
      );
      expect(danoAdamante.pvAtual, equals(35)); // 60 - 25
    });

    test('Morto-vivo: cura com trevas, sofre dano de cura de luz e respeita vulnerabilidade/imunidade', () {
      const vampiro = Monstro(
        id: 'cria_vampira',
        nome: 'Cria Vampira',
        nd: '4',
        papel: PapelMonstro.solo,
        tipoCriatura: 'morto-vivo',
        pvMax: 80,
        defesa: 20,
        deslocamentoMetros: 9.0,
        iniciativa: 8,
        percepcao: 7,
        vontade: 6,
        modForca: 3,
        modDestreza: 4,
        modConstituicao: 0,
        constituicaoNula: true,
        imunidadesDano: ['frio', 'trevas'],
        vulnerabilidadesDano: ['luz'],
        rd: {'geral': 5},
      );

      final combatente = CombatenteMonstro.doMonstro(vampiro, pvAtual: 40);

      expect(combatente.ehMortoVivo, isTrue);
      expect(combatente.possuiVisaoNoEscuro, isTrue);
      expect(combatente.imuneACritico, isTrue);
      expect(combatente.isImuneAEfeitos({TipoEfeito.trevas}), isTrue);

      // Dano de frio: imune -> 0 de dano
      expect(combatente.aplicarDano(30, tipo: TipoDano.frio).pvAtual, equals(40));

      // Dano de trevas: recupera PV (mesmo tendo trevas em imunidadesDano)
      final curadoTrevas = combatente.aplicarDano(15, tipo: TipoDano.trevas);
      expect(curadoTrevas.pvAtual, equals(55));

      // Cura mágica de luz: causa dano (+50% vulnerabilidade = 15, menos RD 5 = 10)
      final feridoPorLuz = combatente.aplicarCura(10, magica: true, ehLuz: true);
      expect(feridoPorLuz.pvAtual, equals(30));

      // Passou na Vontade: reduz cura base à metade (5 -> +50% = 7 -> menos RD 5 = 2)
      final feridoMetade = combatente.aplicarCura(
        10,
        magica: true,
        ehLuz: true,
        passouVontade: true,
      );
      expect(feridoMetade.pvAtual, equals(38));
    });

    test('Atributos nulos: DES nula zera deslocamento e FOR nula bloqueia bônus/Atropelar; fallback para voo', () {
      const pilar = Monstro(
        id: 'obelisco_vivo',
        nome: 'Obelisco Vivo',
        nd: '3',
        papel: PapelMonstro.especial,
        tipoCriatura: 'construto',
        pvMax: 50,
        defesa: 16,
        deslocamentoMetros: 9.0,
        iniciativa: 0,
        percepcao: 4,
        modForca: 4,
        modDestreza: 0,
        modConstituicao: 0,
        forcaNula: true,
        destrezaNula: true,
        constituicaoNula: true,
        modInteligencia: null,
      );

      final obelisco = CombatenteMonstro.doMonstro(pilar);
      expect(obelisco.deslocamentoMetros, equals(0.0));
      expect(obelisco.modForca, equals(0));

      final mov = MovimentoEngine.calcularAlcancaveis(
        mapa: const GridMapa(largura: 6, altura: 6),
        inicio: const Posicao2D(2, 2),
        deslocamentoMaximoMetros: 9.0,
        posicoesCombatentes: {'obelisco_vivo': const Posicao2D(2, 2)},
        combatentesPorId: {'obelisco_vivo': obelisco},
        combatenteAtivoId: 'obelisco_vivo',
      );
      expect(mov.destinosValidos, isEmpty);

      final engine = CombateEngine();
      final alvo = CombatenteMonstro.doMonstro(pilar, idInstancia: 'alvo');
      final resAtropelar = engine.executarAtropelar(
        atacante: obelisco,
        defensor: alvo,
        d20Atacante: 20,
        d20Defensor: 1,
      );
      expect(resAtropelar.atacanteVenceu, isFalse);

      // Ataque físico não soma modForca quando forcaNula == true
      const maca = Arma(
        key: 'maca',
        nome: 'Maça',
        descricao: 'Arma simples',
        proficiencia: ProficienciaArma.simples,
        proposito: PropositoArma.corpoACorpo,
        empunhadura: EmpunhaduraArma.umaMao,
        dano: '1d1',
        tipoDano: TipoDanoArma.impacto,
      );
      final resAtaque = engine.executarAtaque(
        atacante: obelisco,
        defensor: alvo,
        arma: maca,
        d20Teste: 19,
      );
      expect(resAtaque.acerto, isTrue);
      expect(resAtaque.danoTotal, equals(1)); // 1d1 + 0 (sem FOR)

      // Espectro com deslocamento terrestre 0, mas voo 9m
      const alma = Monstro(
        id: 'alma',
        nome: 'Alma Acorrentada',
        nd: '2',
        papel: PapelMonstro.lacaio,
        tipoCriatura: 'morto-vivo',
        pvMax: 20,
        defesa: 14,
        deslocamentoMetros: 0.0,
        deslocamentos: {'voo': 9.0},
        iniciativa: 3,
        percepcao: 2,
        modForca: 0,
        modDestreza: 2,
        modConstituicao: 0,
      );
      expect(CombatenteMonstro.doMonstro(alma).deslocamentoMetros, equals(9.0));
    });

    test('CombateCubit: recarga de habilidade controla PM, ação e bloqueio até recarregar', () {
      const dragao = Monstro(
        id: 'dragao_jovem',
        nome: 'Dragão Jovem',
        nd: '7',
        papel: PapelMonstro.solo,
        tipoCriatura: 'monstro',
        tamanho: 'grande',
        pvMax: 180,
        pmMax: 10,
        defesa: 24,
        deslocamentoMetros: 12.0,
        iniciativa: 10,
        percepcao: 10,
        modForca: 5,
        modDestreza: 2,
        modConstituicao: 4,
        habilidades: [
          HabilidadeMonstro(
            nome: 'Sopro de Fogo',
            acao: 'padrao',
            custoPm: 3,
            recarga: 'movimento',
            descricao: 'Cone de chamas.',
          ),
        ],
      );

      final combDragao = CombatenteMonstro.doMonstro(dragao, time: TimeCombatente.inimigo);
      const heroi = Combatente(
        id: 'h1',
        nome: 'Guerreiro',
        pvMax: 50,
        pvAtual: 50,
        pmMax: 10,
        pmAtual: 10,
        defesa: 18,
        modIniciativa: 1,
        modLuta: 5,
        modPontaria: 2,
        modPercepcao: 2,
        modForca: 3,
        modDestreza: 1,
        modConstituicao: 2,
      );

      final cubit = CombateCubit();
      cubit.iniciarCombate(
        [combDragao, heroi],
        iniciativas: {'dragao_jovem': 20, 'h1': 5},
      );

      final sopro = dragao.habilidades.first;
      cubit.usarHabilidadeMonstro(
        sopro,
        alvo: heroi,
        valorDanoOuCura: 18,
        tipoDano: TipoDano.fogo,
      );

      final dragaoAposUso = cubit.state.combatenteAtual as CombatenteMonstro;
      expect(dragaoAposUso.pmAtual, equals(7));
      expect(dragaoAposUso.habilidadeEmRecarga('Sopro de Fogo'), isTrue);
      expect(
        cubit.state.filaIniciativa.firstWhere((c) => c.id == 'h1').pvAtual,
        equals(32),
      );

      // Novo turno para o dragão: tentar usar em recarga falha; recarregar libera novamente
      cubit.proximoTurno();
      cubit.proximoTurno();

      cubit.usarHabilidadeMonstro(sopro);
      expect(
        cubit.state.logCombate.last,
        contains('precisa ser recarregada'),
      );

      cubit.recarregarHabilidadeMonstro(sopro);
      final dragaoRecarregado = cubit.state.combatenteAtual as CombatenteMonstro;
      expect(dragaoRecarregado.habilidadeEmRecarga('Sopro de Fogo'), isFalse);
      expect(cubit.state.acoesMovimentoRestantes, equals(0));

      cubit.usarHabilidadeMonstro(sopro);
      final dragaoSegundoUso = cubit.state.combatenteAtual as CombatenteMonstro;
      expect(dragaoSegundoUso.pmAtual, equals(4));
      expect(dragaoSegundoUso.habilidadeEmRecarga('Sopro de Fogo'), isTrue);

      cubit.close();
    });
  });

  group('Suporte N×N no MovimentoEngine, Adjacência e CombateCubit', () {
    test('Token Grande (2×2) respeita limites do mapa, obstáculos e inimigos em todas suas células', () {
      const gigante = Monstro(
        id: 'gigante',
        nome: 'Gigante',
        nd: '5',
        papel: PapelMonstro.solo,
        tipoCriatura: 'humanoide',
        tamanho: 'grande',
        pvMax: 120,
        defesa: 20,
        deslocamentoMetros: 6.0,
        iniciativa: 2,
        percepcao: 4,
        modForca: 6,
        modDestreza: 0,
        modConstituicao: 4,
      );

      const heroi = Combatente(
        id: 'heroi',
        nome: 'Paladino',
        pvMax: 40,
        pvAtual: 40,
        pmMax: 10,
        pmAtual: 10,
        defesa: 18,
        modIniciativa: 1,
        modLuta: 5,
        modPontaria: 1,
        modPercepcao: 2,
        modForca: 3,
        modDestreza: 1,
        modConstituicao: 2,
      );

      final combGigante = CombatenteMonstro.doMonstro(gigante);
      final mapa = GridMapa(
        largura: 6,
        altura: 6,
        terrenos: {
          const Posicao2D(3, 1): TipoTerreno.obstaculo,
        },
      );

      final resultado = MovimentoEngine.calcularAlcancaveis(
        mapa: mapa,
        inicio: const Posicao2D(0, 0),
        deslocamentoMaximoMetros: 4.5,
        posicoesCombatentes: const {
          'gigante': Posicao2D(0, 0),
          'heroi': Posicao2D(2, 3),
        },
        combatentesPorId: {
          'gigante': combGigante,
          'heroi': heroi,
        },
        combatenteAtivoId: 'gigante',
      );

      // Não pode parar em x=5 ou y=5 (footprint 2x2 sairia do mapa 6x6)
      expect(resultado.destinosValidos.any((p) => p.x >= 5 || p.y >= 5), isFalse);
      // Não pode ocupar (2, 0) ou (2, 1) porque obstáculo em (3, 1) intersecta o footprint 2x2
      expect(resultado.destinosValidos.contains(const Posicao2D(2, 0)), isFalse);
      expect(resultado.destinosValidos.contains(const Posicao2D(2, 1)), isFalse);
      // Não pode parar sobreposição com herói em (2, 3) -> âncoras (1,2), (2,2), (1,3), (2,3) proibidas
      expect(resultado.destinosValidos.contains(const Posicao2D(1, 2)), isFalse);
      expect(resultado.destinosValidos.contains(const Posicao2D(2, 2)), isFalse);
      // Pode mover para (0, 2), que fica adjacente ao herói em (2, 3) (células (1,2)-(1,3) tocam (2,3))
      expect(resultado.destinosValidos.contains(const Posicao2D(0, 2)), isTrue);
      expect(
        const Posicao2D(0, 2).ehAdjacenteArea(
          const Posicao2D(2, 3),
          tamanhoEsta: 2,
          tamanhoOutra: 1,
        ),
        isTrue,
      );
    });

    test('CombateCubit aceita ataque corpo a corpo em qualquer borda da área N×N do monstro', () {
      const dragao = Monstro(
        id: 'dragao',
        nome: 'Dragão 3x3',
        nd: '10',
        papel: PapelMonstro.solo,
        tipoCriatura: 'monstro',
        tamanho: 'enorme',
        pvMax: 200,
        defesa: 10,
        deslocamentoMetros: 9.0,
        iniciativa: 2,
        percepcao: 5,
        modForca: 6,
        modDestreza: 1,
        modConstituicao: 4,
      );

      const espada = Arma(
        key: 'espada',
        nome: 'Espada',
        descricao: 'Espada longa',
        proficiencia: ProficienciaArma.marcial,
        proposito: PropositoArma.corpoACorpo,
        empunhadura: EmpunhaduraArma.umaMao,
        dano: '1d8',
        margemAmeaca: 19,
        multiplicadorCritico: 2,
        tipoDano: TipoDanoArma.corte,
      );

      const heroi = Combatente(
        id: 'heroi',
        nome: 'Cavaleiro',
        pvMax: 50,
        pvAtual: 50,
        pmMax: 10,
        pmAtual: 10,
        defesa: 18,
        modIniciativa: 1,
        modLuta: 20,
        modPontaria: 1,
        modPercepcao: 2,
        modForca: 3,
        modDestreza: 1,
        modConstituicao: 2,
        armas: [espada],
      );

      final combDragao = CombatenteMonstro.doMonstro(dragao);
      expect(combDragao.tamanhoQuadrados, equals(3));

      final cubit = CombateCubit();
      // Dragão ocupa [5..7]x[3..5]; herói em (8, 5) toca a borda sudeste do 3x3!
      cubit.iniciarCombate(
        [heroi, combDragao],
        posicoesIniciais: const {
          'heroi': Posicao2D(8, 5),
          'dragao': Posicao2D(5, 3),
        },
        iniciativas: const {'heroi': 20, 'dragao': 5},
      );

      cubit.executarAtaque(defensor: combDragao, arma: espada);
      expect(cubit.state.acoesPadraoRestantes, equals(0));
      expect(
        cubit.state.filaIniciativa.firstWhere((c) => c.id == 'dragao').pvAtual,
        lessThan(200),
      );
      cubit.close();
    });
  });

  group('Arena UI - Seleção de Ameaças e Tabuleiro N×N', () {
    testWidgets('SelecaoInimigosView exibe abas Treino e Bestiário e permite selecionar inimigo', (tester) async {
      final selecionados = <Combatente>[];
      final heroi = Personagem(id: 'h_ui', nome: 'Tordek', atributos: const {});

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: const Color(0xFF0F172A),
            body: StatefulBuilder(
              builder: (context, setState) {
                return SelecaoInimigosView(
                  heroi: heroi,
                  selecionados: selecionados,
                  onToggleInimigo: (c) => setState(() {
                    selecionados.any((x) => x.id == c.id)
                        ? selecionados.removeWhere((x) => x.id == c.id)
                        : selecionados.add(c);
                  }),
                  onAvancar: () {},
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Treino'), findsOneWidget);
      expect(find.text('Bestiário'), findsOneWidget);
      expect(find.text('Selecione ao menos 1 inimigo para avançar'), findsOneWidget);
      expect(find.text('Goblin Saqueador'), findsOneWidget);

      await tester.tap(find.text('Goblin Saqueador'));
      await tester.pump();
      expect(selecionados.length, equals(1));
      expect(find.text('Avançar para Rolagem (1 Inimigo)'), findsOneWidget);
    });

    testWidgets('RolarIniciativaView rola iniciativa de múltiplos inimigos e exibe modificadores', (tester) async {
      const aranha = Monstro(
        id: 'aranha_gigante',
        nome: 'Aranha Gigante',
        nd: '2',
        papel: PapelMonstro.solo,
        tipoCriatura: 'animal',
        tamanho: 'grande',
        pvMax: 70,
        defesa: 17,
        deslocamentoMetros: 12.0,
        iniciativa: 6,
        percepcao: 5,
      );
      const zumbi = Monstro(
        id: 'zumbi',
        nome: 'Zumbi',
        nd: '1/2',
        papel: PapelMonstro.lacaio,
        tipoCriatura: 'morto_vivo',
        tamanho: 'medio',
        pvMax: 24,
        defesa: 12,
        deslocamentoMetros: 6.0,
        iniciativa: 1,
        percepcao: 0,
      );

      final combAranha = CombatenteMonstro.doMonstro(aranha);
      final combZumbi = CombatenteMonstro.doMonstro(zumbi);
      final heroi = Personagem(
        id: 'h_inic',
        nome: 'Sir Valen',
        atributos: const {},
        outrosBonusPericias: const {'INICIATIVA': 4},
      );

      Map<String, int>? iniciativasRecebidas;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: const Color(0xFF0F172A),
            body: MediaQuery(
              data: const MediaQueryData(
                size: Size(800, 1000),
                disableAnimations: true,
              ),
              child: RolarIniciativaView(
                heroi: heroi,
                inimigos: [combAranha, combZumbi],
                onIniciarCombate: (_, totaisInimigos) {
                  iniciativasRecebidas = totaisInimigos;
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('🎲 Rolar Iniciativa do Herói'));
      await tester.pumpAndSettle();

      // Mostra modificadores de iniciativa dos inimigos antes de rolar
      expect(find.textContaining('Aranha Gigante (Inic. +6)'), findsOneWidget);
      expect(find.textContaining('Zumbi (Inic. +1)'), findsOneWidget);

      await tester.tap(find.text('Confirmar e Rolar Inimigos (2)'));
      await tester.pumpAndSettle();

      // Deve concluir rolagem de ambos e exibir ordem final com modificadores
      expect(find.text('⚔️ Iniciar Combate!'), findsOneWidget);
      expect(find.textContaining('Aranha Gigante (Inic. +6)'), findsOneWidget);
      expect(find.textContaining('Zumbi (Inic. +1)'), findsOneWidget);

      final btnIniciar = find.text('⚔️ Iniciar Combate!');
      await tester.ensureVisible(btnIniciar);
      await tester.pumpAndSettle();
      await tester.tap(btnIniciar);
      await tester.pump();
      expect(iniciativasRecebidas, isNotNull);
      expect(iniciativasRecebidas!.keys, containsAll(['aranha_gigante', 'zumbi']));
    });

    testWidgets('exibirRelatorioFinal oferece opção de escolher novos inimigos', (tester) async {
      bool retornouParaSelecao = false;
      final state = CombateState(
        statusCombate: StatusCombate.vitoria,
        rodadaAtual: 2,
      );
      final stats = ArenaStatsCollector();

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => exibirRelatorioFinal(
                  context,
                  state,
                  stats,
                  onSelecionarNovosInimigos: () {
                    retornouParaSelecao = true;
                  },
                ),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      final btnNovosInimigos = find.text('Escolher Novos Inimigos');
      expect(btnNovosInimigos, findsOneWidget);
      expect(find.text('Voltar à Tela Inicial'), findsOneWidget);

      await tester.ensureVisible(btnNovosInimigos);
      await tester.pumpAndSettle();
      await tester.tap(btnNovosInimigos);
      await tester.pumpAndSettle();
      expect(retornouParaSelecao, isTrue);
    });

    testWidgets('VttBoardWidget renderiza token 2×2 com indicador de tamanho', (tester) async {
      const ogro = Monstro(
        id: 'ogro',
        nome: 'Ogro',
        nd: '3',
        papel: PapelMonstro.solo,
        tipoCriatura: 'humanoide',
        tamanho: 'grande',
        pvMax: 90,
        defesa: 17,
        deslocamentoMetros: 9.0,
        iniciativa: 1,
        percepcao: 2,
        modForca: 5,
        modDestreza: 0,
        modConstituicao: 3,
      );

      final combOgro = CombatenteMonstro.doMonstro(ogro);
      final state = CombateState(
        filaIniciativa: [combOgro],
        mapaGrid: const GridMapa(largura: 6, altura: 6),
        posicoesCombatentes: const {'ogro': Posicao2D(2, 2)},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: VttBoardWidget(
                state: state,
                onCelulaClicada: (_) {},
                onCombatenteClicado: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('O'), findsOneWidget);
      expect(find.text('2x2'), findsOneWidget);
    });
  });
}
