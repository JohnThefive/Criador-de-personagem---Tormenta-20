import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:t20_creator/presentation/controllers/mestre_controller/mestre_cubit.dart';
import 'package:t20_creator/presentation/screens/home/widgets/home_action_card.dart';
import 'package:t20_creator/presentation/screens/mestre/campanha_detalhe_screen.dart';
import 'package:t20_creator/presentation/screens/mestre/criar_campanha_screen.dart';
import 'package:t20_creator/presentation/screens/mestre/mesa_sessao_screen.dart';
import 'package:t20_creator/presentation/screens/mestre/mestre_painel_screen.dart';
import 'package:t20_creator/presentation/screens/mestre/widgets/drawer_sessao_lan.dart';
import 'package:t20_creator/presentation/screens/mestre/widgets/mestre_empty_state.dart';
import 'package:t20_creator/presentation/screens/mestre/widgets/tela_escudo_notas.dart';
import 'package:t20_creator/presentation/screens/mestre/widgets/tela_mesa_jogo.dart';

void main() {
  group('Painel do Mestre Mobile-First & Fluxo de Criação', () {
    testWidgets(
      'Exibe estado vazio amigável ao excluir todas as campanhas no celular',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final cubit = MestreCubit();
        addTearDown(cubit.close);

        await tester.pumpWidget(
          MaterialApp(home: MestrePainelScreen(cubit: cubit)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Coração de Rubi'), findsOneWidget);

        // Exclui campanha via botão de exclusão e confirma no diálogo
        await tester.tap(find.byTooltip('Excluir campanha'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('EXCLUIR'));
        await tester.pumpAndSettle();

        expect(cubit.state.campanhas, isEmpty);
        expect(find.byType(MestreEmptyState), findsOneWidget);
        expect(find.text('Nenhuma campanha ainda'), findsOneWidget);
        expect(find.text('Nova campanha'), findsOneWidget);
        // No estado vazio a ação fica centralizada no EmptyState, sem FAB duplicado
        expect(find.byType(FloatingActionButton), findsNothing);
      },
    );

    testWidgets(
      'Fluxo completo Campanha -> Aventura -> Sessão sem travamentos e com código LAN opcional',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final cubit = MestreCubit();
        addTearDown(cubit.close);

        await tester.pumpWidget(
          MaterialApp(home: MestrePainelScreen(cubit: cubit)),
        );
        await tester.pumpAndSettle();

        // Abre tela de Nova Campanha via FAB
        await tester.tap(find.text('Nova campanha'));
        await tester.pumpAndSettle();

        expect(find.text('Nova Campanha'), findsOneWidget);
        expect(find.text('Etapa 1 de 3 • Campanha'), findsOneWidget);

        // Valida campo obrigatório
        await tester.tap(find.text('Criar campanha'));
        await tester.pumpAndSettle();
        expect(find.text('Informe o nome da campanha'), findsOneWidget);

        // Preenche nome e código LAN
        final camposCampanha = find.byType(TextFormField);
        await tester.enterText(camposCampanha.at(0), 'A Lenda de Khalmyr');
        await tester.enterText(camposCampanha.at(1), 'T20-7788');
        await tester.tap(find.text('Criar campanha'));
        await tester.pumpAndSettle();

        // Dialog "Campanha criada" -> "Criar aventura" deve navegar com segurança
        expect(find.text('Campanha criada'), findsOneWidget);
        await tester.tap(find.text('Criar aventura'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Etapa 2: Nova Aventura vinculada à campanha recém-criada
        expect(find.text('Nova Aventura'), findsOneWidget);
        expect(find.text('Etapa 2 de 3 • Aventura'), findsOneWidget);

        await tester.enterText(find.byType(TextFormField), 'O Templo Submerso');
        await tester.tap(find.text('Criar aventura'));
        await tester.pumpAndSettle();

        // Dialog "Aventura criada" -> "Criar sessão"
        expect(find.text('Aventura criada'), findsOneWidget);
        await tester.tap(find.text('Criar sessão'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Etapa 3: Nova Sessão vinculada à aventura recém-criada
        expect(find.text('Nova Sessão'), findsOneWidget);
        expect(find.text('Etapa 3 de 3 • Sessão'), findsOneWidget);

        await tester.enterText(
          find.byType(TextFormField),
          'Sessão 1 — O Portão',
        );
        await tester.tap(find.text('Criar sessão'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Verifica hierarquia criada no Cubit e na lista
        final novaCamp = cubit.state.campanhas.firstWhere(
          (c) => c.nome == 'A Lenda de Khalmyr',
        );
        expect(novaCamp.codigoConexaoLan, 'T20-7788');
        expect(novaCamp.aventuras.length, 1);
        expect(novaCamp.aventuras.first.nome, 'O Templo Submerso');
        expect(novaCamp.aventuras.first.sessoes.length, 1);
        expect(
          novaCamp.aventuras.first.sessoes.first.titulo,
          'Sessão 1 — O Portão',
        );

        expect(find.text('A Lenda de Khalmyr'), findsOneWidget);
        expect(find.text('LAN: T20-7788'), findsOneWidget);

        // Abre detalhes da campanha e valida aventuras e sessões visíveis
        await tester.tap(find.text('A Lenda de Khalmyr'));
        await tester.pumpAndSettle();
        expect(find.byType(CampanhaDetalheScreen), findsOneWidget);
        expect(find.text('O Templo Submerso'), findsOneWidget);
        expect(find.text('Sessão 1 — O Portão'), findsOneWidget);
      },
    );

    testWidgets(
      'Botão de confirmação permanece visível acima do teclado virtual',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final cubit = MestreCubit();
        addTearDown(cubit.close);

        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(390, 844),
                viewInsets: EdgeInsets.only(bottom: 320),
              ),
              child: CriarCampanhaScreen(cubit: cubit),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final botaoConfirmar = find.byType(HomeActionCard);
        expect(botaoConfirmar, findsOneWidget);
        expect(
          find.descendant(
            of: botaoConfirmar,
            matching: find.text('Criar campanha'),
          ),
          findsOneWidget,
        );

        final rect = tester.getRect(botaoConfirmar);
        // Acima da borda superior do teclado simulado (844 - 320 = 524)
        expect(rect.bottom, lessThanOrEqualTo(524));
        expect(rect.height, greaterThanOrEqualTo(48));
      },
    );

    testWidgets(
      'Regressão DrawerSessaoLan: SnackBar "Criar aventura agora" funciona após fechar Drawer',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final cubit = MestreCubit();
        addTearDown(cubit.close);
        final scaffoldKey = GlobalKey<ScaffoldState>();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              key: scaffoldKey,
              drawer: DrawerSessaoLan(cubit: cubit),
              body: const Center(child: Text('Host')),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Abre o Drawer e inicia criação de campanha
        scaffoldKey.currentState!.openDrawer();
        await tester.pumpAndSettle();

        await tester.tap(find.text('+ Nova campanha'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(TextField),
          ).first,
          'Campanha Teste Regressão',
        );
        await tester.tap(find.text('Confirmar'));
        await tester.pumpAndSettle();

        // Fecha o Drawer desmontando o contexto antigo da barra lateral
        Navigator.of(scaffoldKey.currentContext!).pop();
        await tester.pumpAndSettle();

        // Toca na ação do SnackBar — não deve lançar exceção de contexto desativado
        expect(find.text('Criar aventura agora'), findsOneWidget);
        await tester.tap(find.text('Criar aventura agora'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Nova Aventura'), findsOneWidget);
      },
    );

    testWidgets(
      'Campanha centraliza jogadores convidados e mapas e abre sessão na Mesa de Jogo com mapa escolhido',
      (tester) async {
        tester.view.physicalSize = const Size(600, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final cubit = MestreCubit();
        addTearDown(cubit.close);

        final camp = cubit.criarCampanha(
          nome: 'Campanha do Oeste',
          codigoConexaoLan: 'T20-9090',
          criarEstruturaPadrao: false,
        );
        final av = cubit.criarAventura(
          campanhaId: camp.id,
          nome: 'Ato Único',
          criarSessaoPadrao: false,
        )!;
        cubit.criarSessao(
          campanhaId: camp.id,
          aventuraId: av.id,
          titulo: 'Sessão de Estreia',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: CampanhaDetalheScreen(
              cubit: cubit,
              campanhaId: camp.id,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Convida um jogador para a campanha
        await tester.tap(find.text('Convidar'));
        await tester.pumpAndSettle();

        final camposConvite = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        );
        await tester.enterText(camposConvite.at(0), 'Lucas');
        await tester.enterText(camposConvite.at(1), 'Valeros');
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Convidar'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Lucas (Valeros)'), findsOneWidget);

        // 2. Envia um mapa da biblioteca para a campanha
        await tester.tap(find.text('Enviar mapa'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Ruínas da Estrada de Yuvalin'));
        await tester.pumpAndSettle();

        expect(
          find.text('Ruínas da Estrada de Yuvalin (12×8)'),
          findsOneWidget,
        );

        // 3. Toca na sessão, escolhe o mapa da campanha e abre a Mesa de Jogo
        await tester.tap(find.text('Sessão de Estreia'));
        await tester.pumpAndSettle();

        expect(
          find.text('1 jogador(es) convidado(s) serão vinculados à sessão.'),
          findsOneWidget,
        );

        await tester.tap(
          find.descendant(
            of: find.byType(BottomSheet),
            matching: find.text('Ruínas da Estrada de Yuvalin'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(MesaSessaoScreen), findsOneWidget);
        expect(find.byType(TelaMesaJogo), findsOneWidget);
        expect(cubit.state.sessaoAtual?.elenco.length, 1);
        expect(
          cubit.state.sessaoAtual?.elenco.first.nomePersonagem,
          'Valeros',
        );
        expect(
          cubit.state.mapaAtual?.nome,
          'Ruínas da Estrada de Yuvalin',
        );

        // 4. Alterna em 1 toque para "Escudo" sem sair da Mesa de Jogo
        final navMesa = find.byType(NavigationBar);
        await tester.tap(
          find.descendant(of: navMesa, matching: find.text('Escudo')),
        );
        await tester.pumpAndSettle();

        expect(find.text('Condições'), findsOneWidget);
        await tester.enterText(
          find.descendant(
            of: find.byType(TelaEscudoNotas),
            matching: find.byType(TextField),
          ).first,
          'Caído',
        );
        await tester.pump();

        // Alterna para "Jogadores" e verifica elenco + código LAN
        await tester.tap(
          find.descendant(of: navMesa, matching: find.text('Jogadores')),
        );
        await tester.pumpAndSettle();

        expect(find.text('Jogadores da Sessão'), findsOneWidget);
        expect(find.text('Código LAN: T20-9090'), findsOneWidget);
        expect(find.text('Valeros'), findsOneWidget);

        // Volta para "Mapa" e depois "Escudo": ambos mantiveram estado intacto
        await tester.tap(
          find.descendant(of: navMesa, matching: find.text('Mapa')),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('Enviar aos jogadores'), findsOneWidget);

        await tester.tap(
          find.descendant(of: navMesa, matching: find.text('Escudo')),
        );
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: find.byType(TelaEscudoNotas),
            matching: find.widgetWithText(TextField, 'Caído'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'MestrePainelScreen alterna entre Campanhas e Escudo em 1 toque pela barra inferior sem abrir Drawer',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          const MaterialApp(home: MestrePainelScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.text('Suas campanhas'), findsOneWidget);

        final navBar = find.byType(NavigationBar);
        await tester.tap(
          find.descendant(of: navBar, matching: find.text('Escudo')),
        );
        await tester.pumpAndSettle();

        expect(find.text('Condições'), findsOneWidget);

        await tester.tap(
          find.descendant(of: navBar, matching: find.text('Campanhas')),
        );
        await tester.pumpAndSettle();

        expect(find.text('Suas campanhas'), findsOneWidget);
      },
    );
  });
}
