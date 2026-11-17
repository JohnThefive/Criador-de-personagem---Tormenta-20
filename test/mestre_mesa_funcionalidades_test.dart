import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:t20_creator/domain/entities/combate/monstro.dart';
import 'package:t20_creator/domain/entities/mestre/modelos_mestre.dart';
import 'package:t20_creator/presentation/controllers/mestre_controller/mestre_cubit.dart';
import 'package:t20_creator/presentation/screens/mestre/widgets/tela_bestiario_mestre.dart';
import 'package:t20_creator/presentation/screens/mestre/widgets/tela_escudo_notas.dart';
import 'package:t20_creator/presentation/screens/mestre/widgets/tela_mesa_jogo.dart';

class _SeqRandom implements Random {
  final List<int> valores;
  int _idx = 0;

  _SeqRandom(this.valores);

  @override
  int nextInt(int max) {
    final v = valores[_idx % valores.length];
    _idx++;
    return v % max;
  }

  @override
  bool nextBool() => nextInt(2) == 0;

  @override
  double nextDouble() => nextInt(100) / 100.0;
}

Monstro _bossTeste() {
  return const Monstro(
    id: 'boss_teste',
    nome: 'Dragão Jovem Teste',
    nd: '7',
    regiao: 'montanhas',
    papel: PapelMonstro.solo,
    tipoCriatura: 'Monstro',
    subtipo: 'Dragão',
    tamanho: 'Grande',
    pvMax: 483,
    pmMax: 40,
    defesa: 28,
    deslocamentoMetros: 12,
    deslocamentos: {'Terrestre': 12, 'Voo': 24},
    iniciativa: 6,
    percepcao: 11,
    sentidos: ['Visão no escuro', 'Percepção às cegas'],
    fortitude: 14,
    reflexos: 10,
    vontade: 9,
    rd: {'corte': 10, 'fogo': 20},
    imunidadesDano: ['Fogo'],
    imunidadesEfeitos: ['Paralisia'],
    vulnerabilidadesDano: ['Frio'],
    habilidadesDefensivas: ['Escamas Refletoras'],
    modForca: 7,
    modDestreza: 1,
    modConstituicao: 6,
    modInteligencia: null,
    modSabedoria: 2,
    modCarisma: 3,
    forcaNula: false,
    destrezaNula: false,
    constituicaoNula: false,
    pericias: {'Intimidação': 13, 'Atletismo': 15},
    ataques: [
      AtaqueMonstro(
        nome: 'Mordida',
        bonusAtaque: 21,
        dano: '2d8+12',
        margemAmeaca: 19,
        multiplicadorCritico: 2,
        alcance: '3m',
      ),
    ],
    habilidades: [
      HabilidadeMonstro(
        nome: 'Sopro Flamejante',
        acao: 'padrao',
        custoPm: 3,
        recarga: '1d4 rodadas',
        cdResistencia: 22,
        resistenciaTipo: 'Ref',
        descricao: 'Causa 8d6 de dano de fogo em cone.',
      ),
    ],
    equipamento: ['Amuleto Dracônico'],
    tesouro: 'Dobro',
    recursoExtraivel: RecursoExtraivelMonstro(
      nome: 'Escama Ígnea',
      pericia: 'Sobrevivência',
      cdBase: 22,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Mesa do Mestre — 5 novas funcionalidades', () {
    test(
      'Rastreador de Iniciativa no Cubit: rolar, ordenar, editar, avançar rodada e encerrar + JSON recarga',
      () {
        final cubit = MestreCubit();
        addTearDown(cubit.close);

        final boss = _bossTeste();
        cubit.adicionarAmeacaNoMapa(boss);
        cubit.adicionarTokenCustomizadoNoMapa(
          nome: 'Valeros',
          ehHeroi: true,
          tipo: TipoCombatenteMapa.heroi,
          pvMax: 50,
          pmMax: 15,
          defesa: 20,
          iniciativa: 3,
        );

        // nextInt(20) = 9 -> d20=10. Boss: 10+6=16; Valeros (mantido via manterHeroisComValor): 3 -> ou sem manter: 10
        cubit.rolarIniciativaCena(random: _SeqRandom([9, 9]));

        final mapa = cubit.state.mapaAtual!;
        final tokBoss =
            mapa.tokens.firstWhere((t) => t.nome.contains('Dragão'));
        final tokHeroi =
            mapa.tokens.firstWhere((t) => t.nome.contains('Valeros'));

        expect(tokBoss.iniciativa, equals(16));
        expect(tokHeroi.iniciativa, equals(10));
        expect(mapa.rodadaCombate, equals(1));
        final ordemInicial = MestreCubit.ordenarTokensPorIniciativa(
          mapa.tokens,
        );
        expect(mapa.tokenTurnoAtualId, equals(ordemInicial.first.id));

        // Avança por todos os combatentes da rodada 1 até voltar ao 1º na rodada 2
        for (int i = 1; i < ordemInicial.length; i++) {
          cubit.avancarTurno();
          expect(
            cubit.state.mapaAtual!.tokenTurnoAtualId,
            equals(ordemInicial[i].id),
          );
          expect(cubit.state.mapaAtual!.rodadaCombate, equals(1));
        }

        // Ao fechar a volta, volta ao 1º e incrementa rodada para 2
        cubit.avancarTurno();
        expect(
          cubit.state.mapaAtual!.tokenTurnoAtualId,
          equals(ordemInicial.first.id),
        );
        expect(cubit.state.mapaAtual!.rodadaCombate, equals(2));

        // Editar iniciativa do herói para 25 coloca-o no topo da fila e preserva com manterHeroisComValor
        cubit.definirIniciativaToken(tokHeroi.id, 25);
        cubit.rolarIniciativaCena(
          manterHeroisComValor: true,
          random: _SeqRandom([4]),
        );
        final ordenados = MestreCubit.ordenarTokensPorIniciativa(
          cubit.state.mapaAtual!.tokens,
        );
        expect(ordenados.first.id, equals(tokHeroi.id));
        expect(ordenados.first.iniciativa, equals(25));

        // Alternar recarga persiste em TokenNoMapa.toJson/fromJson
        cubit.alternarRecargaHabilidadeToken(tokBoss.id, 'Sopro Flamejante');
        final atualizado = cubit.state.mapaAtual!.tokens
            .firstWhere((t) => t.id == tokBoss.id);
        expect(atualizado.habilidadesGastas, contains('Sopro Flamejante'));

        final roundTrip = TokenNoMapa.fromJson(atualizado.toJson());
        expect(roundTrip.habilidadesGastas, contains('Sopro Flamejante'));

        cubit.encerrarCombate();
        expect(cubit.state.mapaAtual!.tokenTurnoAtualId, isNull);
        expect(cubit.state.mapaAtual!.rodadaCombate, equals(1));
      },
    );

    testWidgets(
      'TelaMesaJogo: Iniciativa destaca token ativo, dano em lote aplica RD e botão Bestiário abre em 1 toque',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 820);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final cubit = MestreCubit();
        addTearDown(cubit.close);

        final boss = _bossTeste();
        cubit.adicionarAmeacaNoMapa(boss);
        final tokBoss = cubit.state.mapaAtual!.tokens
            .firstWhere((t) => t.monstroId == 'boss_teste');

        await tester.pumpWidget(
          MaterialApp(
            home: TelaMesaJogo(
              cubit: cubit,
              onVoltarBiblioteca: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Abrir rastreador de iniciativa, rolar e conferir destaque no mapa
        await tester.tap(find.byTooltip('Rastreador de Iniciativa'));
        await tester.pumpAndSettle();

        expect(find.text('Rd 1'), findsOneWidget);
        await tester.tap(find.text('Rolar'));
        await tester.pumpAndSettle();

        final ativoId = cubit.state.mapaAtual!.tokenTurnoAtualId!;
        expect(find.byKey(ValueKey('turno_ativo_$ativoId')), findsOneWidget);

        await tester.tap(find.byTooltip('Encerrar combate'));
        await tester.pumpAndSettle();
        expect(
          find.byKey(ValueKey('turno_ativo_$ativoId')),
          findsNothing,
        );

        // 2. Selecionar token -> PV em lote (42 dano com RD corte 10 = -32 PV => 451)
        cubit.aoClicarTokenNoMapa(tokBoss);
        await tester.pumpAndSettle();

        await tester.tap(find.text('PV: 483/483'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).last, '42');
        await tester.pumpAndSettle();

        await tester.tap(find.text('corte 10'));
        await tester.pumpAndSettle();
        expect(find.text('Dano final com RD (corte 10): 32'), findsOneWidget);

        await tester.tap(find.text('Aplicar Dano'));
        await tester.pumpAndSettle();

        final bossPosDano = cubit.state.mapaAtual!.tokens
            .firstWhere((t) => t.id == tokBoss.id);
        expect(bossPosDano.pvAtual, equals(451));

        // 3. Controle de recarga dentro da MiniFicha
        await tester.ensureVisible(find.text('Ficha Rápida de Combate'));
        await tester.tap(find.text('Ficha Rápida de Combate'));
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Pronta'));
        await tester.tap(find.text('Pronta'));
        await tester.pumpAndSettle();

        final bossPosRecarga = cubit.state.mapaAtual!.tokens
            .firstWhere((t) => t.id == tokBoss.id);
        expect(bossPosRecarga.habilidadesGastas, contains('Sopro Flamejante'));

        // Fechar mini ficha para acessar dock livremente e testar 1 toque Bestiário
        cubit.aoClicarTokenNoMapa(bossPosRecarga);
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Bestiário'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.text('Customizado'), findsOneWidget);
        expect(find.text('Escolher do Bestiário'), findsOneWidget);
        expect(find.byType(TelaBestiarioMestre), findsOneWidget);
      },
    );

    testWidgets(
      'FichaRapidaMonstroCard exibe ficha completa, rola ataques/perícias e alterna recarga',
      (tester) async {
        final boss = _bossTeste();
        String? habAlternada;

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(useMaterial3: true),
            home: Scaffold(
              body: SingleChildScrollView(
                child: FichaRapidaMonstroCard(
                  monstro: boss,
                  // nextInt(20)=19 -> d20=20 (crítico!), próximo 4d8: 4,4,4,4 -> (5+5+5+5)+12 = 32
                  random: _SeqRandom([19, 4, 4, 4, 4, 9]),
                  onAlternarRecarga: (h) => habAlternada = h,
                ),
              ),
            ),
          ),
        );

        expect(find.textContaining('Dragão'), findsWidgets);
        expect(find.textContaining('Voo 24.0m'), findsOneWidget);
        expect(find.text('INT –'), findsOneWidget);
        expect(find.text('FOR +7'), findsOneWidget);
        expect(find.text('Intimidação +13'), findsOneWidget);
        expect(
          find.textContaining('Sentidos: Visão no escuro, Percepção às cegas'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Equipamento: Amuleto Dracônico'),
          findsOneWidget,
        );
        expect(find.text('Tesouro: Dobro'), findsOneWidget);
        expect(
          find.textContaining('Extração: Escama Ígnea (Sobrevivência CD 22)'),
          findsOneWidget,
        );
        expect(find.textContaining('CD 22 Ref'), findsOneWidget);

        // Rolar ataque Mordida (d20=20 + 21 = 41, crítico x2)
        await tester.tap(find.textContaining('Mordida (+21, 2d8+12'));
        await tester.pumpAndSettle();

        expect(find.textContaining('Mordida: Atq 41 • Dano 32 • CRÍTICO ×2!'),
            findsOneWidget);

        // Rolar perícia Intimidação (d20=10 + 13 = 23)
        await tester.tap(find.text('Intimidação +13'));
        await tester.pumpAndSettle();
        expect(find.text('Intimidação: 23'), findsOneWidget);

        // Toggle de recarga
        await tester.tap(find.text('Pronta'));
        await tester.pumpAndSettle();
        expect(habAlternada, equals('Sopro Flamejante'));
      },
    );

    testWidgets(
      'TelaEscudoNotas aplica condição expandida diretamente no token selecionado em 1 toque',
      (tester) async {
        final cubit = MestreCubit();
        addTearDown(cubit.close);

        cubit.adicionarAmeacaNoMapa(_bossTeste());
        final token = cubit.state.mapaAtual!.tokens.first;
        cubit.aoClicarTokenNoMapa(token);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TelaEscudoNotas(cubit: cubit),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Abalado'));
        await tester.pumpAndSettle();

        expect(find.text('Aplicar em ${token.nome}'), findsOneWidget);

        await tester.tap(find.text('Aplicar em ${token.nome}'));
        await tester.pumpAndSettle();

        final atualizado = cubit.state.mapaAtual!.tokens
            .firstWhere((t) => t.id == token.id);
        expect(atualizado.condicoes, contains('Abalado'));
      },
    );
  });
}
