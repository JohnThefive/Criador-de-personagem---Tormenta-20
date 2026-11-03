import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:t20_creator/domain/services/data_services/catalogo_service.dart';
import 'package:t20_creator/domain/services/ficha_services/personagem_storage_service.dart';
import 'package:t20_creator/presentation/controllers/ficha_controller/personagem_cubit.dart';
import 'package:t20_creator/presentation/controllers/home_controller/home_cubit.dart';
import 'package:t20_creator/presentation/screens/wizard_personagem/char_creation_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempFotosDir;
  late Directory tempPersonagensDir;

  setUpAll(() async {
    await CatalogoService.carregarTodos();
  });

  setUp(() async {
    tempPersonagensDir = await Directory.systemTemp.createTemp('t20_test_wizard_chars_');
    tempFotosDir = await Directory.systemTemp.createTemp('t20_test_wizard_fotos_');
    PersonagemStorageService.setDiretorioTeste(tempPersonagensDir);
    PersonagemStorageService.setDiretorioFotosTeste(tempFotosDir);
  });

  tearDown(() async {
    PersonagemStorageService.limparCacheDiretorio();
    if (await tempFotosDir.exists()) {
      await tempFotosDir.delete(recursive: true);
    }
    if (await tempPersonagensDir.exists()) {
      await tempPersonagensDir.delete(recursive: true);
    }
  });

  Widget criarAppTeste({
    required PersonagemCubit personagemCubit,
    required HomeCubit homeCubit,
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<PersonagemCubit>.value(value: personagemCubit),
        BlocProvider<HomeCubit>.value(value: homeCubit),
      ],
      child: const MaterialApp(
        home: CharacterCreatorScreen(),
      ),
    );
  }

  group('Wizard de Criação de Personagem - Navegação Linear e Unidirecional', () {
    testWidgets(
      'Etapa 0 exibe seta de voltar (arrow_back); ao clicar em Próximo exibe diálogo de confirmação com opções Revisar e Confirmar e Avançar',
      (tester) async {
        final personagemCubit = PersonagemCubit();
        final homeCubit = HomeCubit();

        // Configura atributos zerando compra de pontos para habilitar botão Próximo
        personagemCubit.escolherMetodoAtributos(MetodoAtributos.compra);
        // Distribui pontos até zerar (10 pontos):
        // FOR 2 (custo 2), DES 2 (custo 2), CON 2 (custo 2), INT 2 (custo 2), SAB 2 (custo 2) => total 10
        personagemCubit.alterarAtributoCompra('FOR', 2);
        personagemCubit.alterarAtributoCompra('DES', 2);
        personagemCubit.alterarAtributoCompra('CON', 2);
        personagemCubit.alterarAtributoCompra('INT', 2);
        personagemCubit.alterarAtributoCompra('SAB', 2);
        expect(personagemCubit.state.pontosRestantesCompra, equals(0));

        await tester.pumpWidget(
          criarAppTeste(
            personagemCubit: personagemCubit,
            homeCubit: homeCubit,
          ),
        );
        await tester.pumpAndSettle();

        // Na etapa 0, o AppBar deve exibir arrow_back
        expect(find.byIcon(Icons.arrow_back), findsOneWidget);
        expect(find.byIcon(Icons.close), findsNothing);

        // Botão Próximo deve estar visível
        final botaoProximo = find.text('Próximo');
        expect(botaoProximo, findsOneWidget);

        // Clica em Próximo -> não avança imediatamente, deve exibir modal de confirmação
        await tester.tap(botaoProximo);
        await tester.pumpAndSettle();

        expect(find.text('Confirmar Definir Atributos?'), findsOneWidget);
        expect(
          find.text(
            'Ao avançar, suas escolhas nesta etapa serão consolidadas e você não poderá retornar a ela. Deseja continuar?',
          ),
          findsOneWidget,
        );
        expect(find.text('Revisar'), findsOneWidget);
        expect(find.text('Confirmar e Avançar'), findsOneWidget);

        // Clica em Revisar -> modal fecha e jogador continua na Etapa 0
        await tester.tap(find.text('Revisar'));
        await tester.pumpAndSettle();

        expect(find.text('Confirmar Definir Atributos?'), findsNothing);
        expect(personagemCubit.state.etapaAtual, equals(0));

        // Clica em Próximo novamente e confirma o avanço
        await tester.tap(find.text('Próximo'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Confirmar e Avançar'));
        await tester.pumpAndSettle();

        // Avançou para a Etapa 1
        expect(personagemCubit.state.etapaAtual, equals(1));
        expect(find.text('Escolher Raça'), findsOneWidget);

        // A partir da Etapa 1, o AppBar exibe ícone de fechar (Icons.close) e NÃO arrow_back
        expect(find.byIcon(Icons.close), findsOneWidget);
        expect(find.byIcon(Icons.arrow_back), findsNothing);

        personagemCubit.close();
        homeCubit.close();
      },
    );

    testWidgets(
      'Etapa 1+: Clicar no botão close do AppBar aciona diálogo de desistência; Continuar Criando cancela e mantém na tela',
      (tester) async {
        final personagemCubit = PersonagemCubit();
        final homeCubit = HomeCubit();

        // Configura cubit na etapa 1
        personagemCubit.escolherMetodoAtributos(MetodoAtributos.compra);
        personagemCubit.avancarEtapa();
        expect(personagemCubit.state.etapaAtual, equals(1));

        await tester.pumpWidget(
          criarAppTeste(
            personagemCubit: personagemCubit,
            homeCubit: homeCubit,
          ),
        );
        await tester.pumpAndSettle();

        // Clica no botão de fechar do AppBar
        final botaoClose = find.byIcon(Icons.close);
        expect(botaoClose, findsOneWidget);
        await tester.tap(botaoClose);
        await tester.pumpAndSettle();

        // Diálogo de cancelamento exibido
        expect(
          find.text('Deseja cancelar a criação de personagem?'),
          findsOneWidget,
        );
        expect(
          find.text('Todo o progresso deste aventureiro será descartado.'),
          findsOneWidget,
        );
        expect(find.text('Continuar Criando'), findsOneWidget);
        expect(find.text('Descartar e Sair'), findsOneWidget);

        // Clicar em Continuar Criando mantém na criação sem alterar estado
        await tester.tap(find.text('Continuar Criando'));
        await tester.pumpAndSettle();

        expect(
          find.text('Deseja cancelar a criação de personagem?'),
          findsNothing,
        );
        expect(personagemCubit.state.etapaAtual, equals(1));

        personagemCubit.close();
        homeCubit.close();
      },
    );

    testWidgets(
      'Confirmar descarte da ficha reseta cubit, remove foto órfã e fecha a tela',
      (tester) async {
        final personagemCubit = PersonagemCubit();
        final homeCubit = HomeCubit();

        // Avança e salva uma foto temporária
        personagemCubit.escolherMetodoAtributos(MetodoAtributos.compra);
        personagemCubit.avancarEtapa();

        final charId = personagemCubit.state.personagem.id;
        final arquivoFoto = File('${tempFotosDir.path}/$charId.jpg');
        arquivoFoto.writeAsStringSync('bytes_foto_teste');
        expect(arquivoFoto.existsSync(), isTrue);

        personagemCubit.atualizarFoto(arquivoFoto.path);
        expect(personagemCubit.state.personagem.caminhoFoto, equals(arquivoFoto.path));

        bool telaFechada = false;

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<PersonagemCubit>.value(value: personagemCubit),
              BlocProvider<HomeCubit>.value(value: homeCubit),
            ],
            child: MaterialApp(
              home: Builder(
                builder: (context) {
                  return Scaffold(
                    body: ElevatedButton(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CharacterCreatorScreen(),
                          ),
                        );
                        telaFechada = true;
                      },
                      child: const Text('Abrir Criador'),
                    ),
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Abre a tela de criação
        await tester.tap(find.text('Abrir Criador'));
        await tester.pumpAndSettle();

        // Clica no botão de descarte no AppBar
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        // Confirma "Descartar e Sair"
        await tester.tap(find.text('Descartar e Sair'));
        await tester.pumpAndSettle();

        // A foto deve ter sido excluída do disco
        expect(arquivoFoto.existsSync(), isFalse);

        // O cubit deve ter sido completamente resetado
        expect(personagemCubit.state.etapaAtual, equals(0));
        expect(personagemCubit.state.personagem.caminhoFoto, isNull);
        expect(personagemCubit.state.metodoAtributos, equals(MetodoAtributos.nenhum));

        // A tela de criação foi fechada e voltou para a tela anterior
        expect(telaFechada, isTrue);

        personagemCubit.close();
        homeCubit.close();
      },
    );

    testWidgets(
      'PopScope / Gesto de voltar intercepta e aciona diálogo de cancelamento em vez de voltarEtapa',
      (tester) async {
        final personagemCubit = PersonagemCubit();
        final homeCubit = HomeCubit();

        // Avança até a etapa 2
        personagemCubit.escolherMetodoAtributos(MetodoAtributos.compra);
        personagemCubit.avancarEtapa(); // Etapa 1
        personagemCubit.avancarEtapa(); // Etapa 2
        expect(personagemCubit.state.etapaAtual, equals(2));

        await tester.pumpWidget(
          criarAppTeste(
            personagemCubit: personagemCubit,
            homeCubit: homeCubit,
          ),
        );
        await tester.pumpAndSettle();

        // Simula tentativa de voltar do Android (PopScope)
        final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
        await widgetsAppState.didPopRoute();
        await tester.pumpAndSettle();

        // Diálogo de cancelamento deve ter sido exibido
        expect(
          find.text('Deseja cancelar a criação de personagem?'),
          findsOneWidget,
        );

        // A etapa NÃO deve ter retrocedido para 1
        expect(personagemCubit.state.etapaAtual, equals(2));

        personagemCubit.close();
        homeCubit.close();
      },
    );
  });
}
