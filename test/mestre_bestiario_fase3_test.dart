import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:t20_creator/domain/entities/combate/grid_tatico.dart';
import 'package:t20_creator/domain/entities/combate/monstro.dart';
import 'package:t20_creator/domain/services/data_services/call_ameacas.dart';
import 'package:t20_creator/presentation/controllers/mestre_controller/mestre_cubit.dart';
import 'package:t20_creator/presentation/screens/mestre/mestre_painel_screen.dart';
import 'package:t20_creator/presentation/screens/mestre/widgets/tela_bestiario_mestre.dart';
import 'package:t20_creator/presentation/screens/mestre/widgets/tela_mesa_jogo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Fase 3 — Painel do Mestre, Bestiário e Vínculo TokenNoMapa ↔ Monstro', () {
    test(
      'MestreCubit.adicionarAmeacaNoMapa vincula Monstro ao TokenNoMapa e respeita tamanho N×N',
      () {
        final cubit = MestreCubit();
        addTearDown(cubit.close);

        const ogro = Monstro(
          id: 'ogro_teste',
          nome: 'Ogro Teste',
          nd: '3',
          regiao: 'ermos',
          papel: PapelMonstro.solo,
          tipoCriatura: 'humanoide',
          tamanho: 'grande',
          pvMax: 90,
          pmMax: 0,
          defesa: 17,
          deslocamentoMetros: 9.0,
          iniciativa: 1,
          fortitude: 9,
          reflexos: 3,
          vontade: 2,
          ataques: [
            AtaqueMonstro(nome: 'Tacape', bonusAtaque: 12, dano: '2d8+9'),
          ],
        );

        final mapa = cubit.state.mapaAtual!;
        cubit.adicionarAmeacaNoMapa(
          ogro,
          posicao: Posicao2D(mapa.largura - 1, mapa.altura - 1),
          ocultoParaJogadores: true,
          quantidade: 1,
        );

        final tokenCriado = cubit.state.mapaAtual!.tokens.firstWhere(
          (t) => t.monstroId == 'ogro_teste',
        );
        expect(tokenCriado.monstro, equals(ogro));
        expect(tokenCriado.tamanhoQuadrados, equals(2));
        expect(tokenCriado.pvMax, equals(90));
        expect(tokenCriado.defesa, equals(17));
        expect(tokenCriado.visivelParaJogadores, isFalse);
        // Coordenada limitada para caber o footprint 2×2 dentro do grid
        expect(tokenCriado.posicao.x, lessThanOrEqualTo(mapa.largura - 2));
        expect(tokenCriado.posicao.y, lessThanOrEqualTo(mapa.altura - 2));

        // Seleção do token calcula alcance N×N via MovimentoEngine
        cubit.aoClicarTokenNoMapa(tokenCriado);
        expect(cubit.state.tokenSelecionadoParaMoverId, equals(tokenCriado.id));
        expect(cubit.state.celulasAlcancaveisToken, isNotEmpty);
      },
    );

    testWidgets(
      'MestrePainelScreen exibe aba Bestiário com filtro de região e adiciona criatura ao mapa',
      (tester) async {
        await tester.runAsync(() async {
          await BancoDeAmeacas.carregar();
          if (BancoDeAmeacas.regioes.isNotEmpty) {
            await BancoDeAmeacas.carregarRegiao(BancoDeAmeacas.regioes.first);
          }
        });
        expect(BancoDeAmeacas.regioes, isNotEmpty);

        tester.view.physicalSize = const Size(420, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final cubit = MestreCubit();
        addTearDown(cubit.close);

        await tester.pumpWidget(
          MaterialApp(home: MestrePainelScreen(cubit: cubit)),
        );
        await tester.pumpAndSettle();

        final navBar = find.byType(NavigationBar);
        await tester.tap(
          find.descendant(of: navBar, matching: find.text('Bestiário')),
        );
        await tester.pumpAndSettle();

        expect(find.byType(TelaBestiarioMestre), findsOneWidget);
        expect(find.text('Todas Regiões'), findsOneWidget);

        // Filtra por uma região específica disponível no catálogo
        final primeiraRegiao = BancoDeAmeacas.regioes.first;
        final rotuloRegiao =
            primeiraRegiao.replaceAll('_', ' ').trim()[0].toUpperCase() +
            primeiraRegiao.replaceAll('_', ' ').trim().substring(1);

        await tester.tap(find.text('Todas Regiões'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(rotuloRegiao).last);
        await tester.pumpAndSettle();

        final primeiraCriatura = BancoDeAmeacas.filtrarResumos(
          regiao: primeiraRegiao,
        ).first;
        await tester.tap(find.text(primeiraCriatura.nome).first);
        await tester.pumpAndSettle();

        final btnColocar = find.textContaining('Colocar em "');
        expect(btnColocar, findsOneWidget);
        await tester.tap(btnColocar);
        await tester.pumpAndSettle();

        expect(
          cubit.state.mapaAtual!.tokens.any(
            (t) => t.monstroId == primeiraCriatura.id,
          ),
          isTrue,
        );
      },
    );

    testWidgets(
      'TelaMesaJogo exibe Ficha Rápida de Combate ao selecionar token vinculado a Monstro e botão Escolher do Bestiário',
      (tester) async {
        tester.view.physicalSize = const Size(800, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final cubit = MestreCubit();
        addTearDown(cubit.close);

        const goblin = Monstro(
          id: 'goblin_mesa',
          nome: 'Goblin Chefe',
          nd: '2',
          papel: PapelMonstro.chefe,
          tipoCriatura: 'humanoide',
          tamanho: 'pequeno',
          pvMax: 45,
          pmMax: 8,
          defesa: 18,
          deslocamentoMetros: 9.0,
          iniciativa: 6,
          fortitude: 5,
          reflexos: 7,
          vontade: 3,
          rd: {'fogo': 5},
          ataques: [
            AtaqueMonstro(nome: 'Cimitarra', bonusAtaque: 11, dano: '1d6+5'),
          ],
          habilidades: [
            HabilidadeMonstro(
              nome: 'Ataque Furtivo',
              acao: 'passiva',
              descricao: '+2d6 de dano contra alvos desprevenidos.',
            ),
          ],
        );

        cubit.adicionarAmeacaNoMapa(goblin);
        final tokenGoblin = cubit.state.mapaAtual!.tokens.firstWhere(
          (t) => t.monstroId == 'goblin_mesa',
        );
        cubit.aoClicarTokenNoMapa(tokenGoblin);

        await tester.runAsync(() => BancoDeAmeacas.carregar());

        await tester.pumpWidget(
          MaterialApp(
            home: TelaMesaJogo(cubit: cubit, onVoltarBiblioteca: () {}),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Goblin Chefe'), findsWidgets);
        expect(find.textContaining('ND 2 (Chefe)'), findsOneWidget);
        expect(find.text('Ficha Rápida de Combate'), findsOneWidget);

        // Arrasta a mini ficha flutuante pelo handle e verifica deslocamento
        final posAntes = tester.getTopLeft(find.byIcon(Icons.drag_indicator));
        await tester.drag(
          find.byIcon(Icons.drag_indicator),
          const Offset(-120, 80),
        );
        await tester.pumpAndSettle();
        final posDepois = tester.getTopLeft(find.byIcon(Icons.drag_indicator));
        expect(posDepois.dx, lessThan(posAntes.dx));
        expect(posDepois.dy, greaterThan(posAntes.dy));

        // Minimiza mantendo o token selecionado (alcance tático ativo) e expande depois
        await tester.tap(find.byTooltip('Minimizar ficha'));
        await tester.pumpAndSettle();
        expect(find.text('Ficha Rápida de Combate'), findsNothing);
        expect(cubit.state.tokenSelecionadoParaMoverId, equals(tokenGoblin.id));

        await tester.tap(find.byTooltip('Expandir ficha'));
        await tester.pumpAndSettle();
        expect(find.text('Ficha Rápida de Combate'), findsOneWidget);

        await tester.tap(find.text('Ficha Rápida de Combate'));
        await tester.pumpAndSettle();

        expect(find.textContaining('Cimitarra (+11, 1d6+5'), findsOneWidget);
        expect(find.textContaining('Ataque Furtivo (passiva)'), findsOneWidget);

        // Verifica acesso ao Bestiário com fundo escuro consistente (sem branco-no-branco)
        await tester.tap(find.byTooltip('Adicionar Token'));
        await tester.pumpAndSettle();
        expect(find.text('Escolher do Bestiário'), findsOneWidget);

        await tester.tap(find.text('Escolher do Bestiário'));
        await tester.pumpAndSettle();
        expect(find.byType(TelaBestiarioMestre), findsOneWidget);
        final bottomSheet = tester.widget<BottomSheet>(
          find.byType(BottomSheet),
        );
        expect(bottomSheet.backgroundColor?.computeLuminance(), lessThan(0.2));
      },
    );
  });
}
