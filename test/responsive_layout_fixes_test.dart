import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:t20_creator/domain/entities/personagem/atributos.dart';
import 'package:t20_creator/domain/entities/personagem/classe.dart';
import 'package:t20_creator/domain/entities/personagem/classe_do_personagem.dart';
import 'package:t20_creator/domain/entities/personagem/personagem.dart';
import 'package:t20_creator/domain/entities/personagem/proficiencias.dart';
import 'package:t20_creator/domain/entities/personagem/raca.dart';
import 'package:t20_creator/domain/repositories/i_personagem_repository.dart';
import 'package:t20_creator/domain/services/data_services/catalogo_service.dart';
import 'package:t20_creator/presentation/controllers/ficha_controller/personagem_cubit.dart';
import 'package:t20_creator/presentation/screens/ficha/ficha_screen.dart';
import 'package:t20_creator/presentation/screens/ficha/widgets/ficha_cabecalho_widget.dart';
import 'package:t20_creator/presentation/screens/wizard_personagem/widgets/pagina_divindades.dart';
import 'package:t20_creator/presentation/screens/wizard_personagem/widgets/pagina_origens.dart';
import 'package:t20_creator/presentation/screens/wizard_personagem/widgets/pagina_selecao_classe.dart';

class _FakeRepo implements IPersonagemRepository {
  @override
  Future<void> excluir(String id) async {}

  @override
  Future<Personagem?> obterPorId(String id) async => null;

  @override
  Future<List<Personagem>> obterTodos() async => [];

  @override
  Future<void> salvar(Personagem personagem) async {}
}

Personagem _criarPersonagemTeste() {
  return Personagem(
    id: 'p_layout_test',
    nome: 'Valeros Tormenta',
    raca: const Raca(
      id: 'humano',
      nome: 'Humano',
      descricaoRaca: 'Versátil',
      icone: 'humano',
      modificadores: {},
    ),
    classes: [
      ClasseDoPersonagem(
        classeDefinicao: const Classe(
          idClasse: 'guerreiro',
          nome: 'Guerreiro',
          pvInicial: 20,
          pvPorNivel: 5,
          pmInicial: 3,
          pmPorNivel: 3,
          proficiencias: [TipoProficiencia.armasMarciais],
          periciasFixas: ['LUTA'],
          periciasOpcoes: ['INICIATIVA'],
          qtdPericiasEscolha: 1,
          descricaoclasse: 'Combatente marcial.',
        ),
        nivel: 1,
      ),
    ],
    atributos: {
      'FOR': const Atributo(nome: 'FOR', valor: 3),
      'DES': const Atributo(nome: 'DES', valor: 2),
      'CON': const Atributo(nome: 'CON', valor: 2),
      'INT': const Atributo(nome: 'INT', valor: 0),
      'SAB': const Atributo(nome: 'SAB', valor: 1),
      'CAR': const Atributo(nome: 'CAR', valor: 0),
    },
    periciasTreinadas: ['LUTA', 'INICIATIVA'],
    pvAtual: 22,
    pmAtual: 3,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await CatalogoService.carregarTodos();
  });

  group('Problema 1 - Responsividade e zero overflow (Origem, Classe, Divindade)', () {
    for (final width in [320.0, 360.0, 411.0, 800.0]) {
      for (final scale in [1.0, 1.3]) {
        testWidgets(
          'Origem, Classe e Divindade sem overflow em ${width.toInt()}dp (escala ${scale}x)',
          (tester) async {
            final height = width >= 600 ? 600.0 : 800.0;
            await tester.binding.setSurfaceSize(Size(width, height));
            addTearDown(() => tester.binding.setSurfaceSize(null));

            final cubit = PersonagemCubit();
            addTearDown(cubit.close);

            // 1) Origem
            await tester.pumpWidget(
              MediaQuery(
                data: MediaQueryData(
                  size: Size(width, height),
                  textScaler: TextScaler.linear(scale),
                ),
                child: MaterialApp(
                  home: BlocProvider<PersonagemCubit>.value(
                    value: cubit,
                    child: Scaffold(
                      body: BlocBuilder<PersonagemCubit, PersonagemState>(
                        builder: (context, state) =>
                            PaginaSelecaoOrigem(state: state),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();

            // Toca em Acólito para abrir detalhes no mobile (< 600) ou selecionar no wide
            await tester.tap(find.text('Acólito').first);
            await tester.pumpAndSettle();
            await tester.scrollUntilVisible(
              find.text('Benefícios da Origem'),
              200,
              scrollable: find.byType(Scrollable).last,
            );
            expect(find.text('Benefícios da Origem'), findsOneWidget);

            // 2) Classe
            await tester.pumpWidget(
              MediaQuery(
                data: MediaQueryData(
                  size: Size(width, height),
                  textScaler: TextScaler.linear(scale),
                ),
                child: MaterialApp(
                  home: BlocProvider<PersonagemCubit>.value(
                    value: cubit,
                    child: Scaffold(
                      body: BlocBuilder<PersonagemCubit, PersonagemState>(
                        builder: (context, state) =>
                            PaginaSelecaoClasse(state: state),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            await tester.tap(find.text('Arcanista').first);
            await tester.pumpAndSettle();
            await tester.scrollUntilVisible(
              find.text('Caminhos Arcanos'),
              200,
              scrollable: find.byType(Scrollable).last,
            );
            expect(find.text('Caminhos Arcanos'), findsOneWidget);

            // 3) Divindade
            await tester.pumpWidget(
              MediaQuery(
                data: MediaQueryData(
                  size: Size(width, height),
                  textScaler: TextScaler.linear(scale),
                ),
                child: MaterialApp(
                  home: BlocProvider<PersonagemCubit>.value(
                    value: cubit,
                    child: Scaffold(
                      body: BlocBuilder<PersonagemCubit, PersonagemState>(
                        builder: (context, state) =>
                            PaginaSelecaoDivindade(state: state),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            await tester.scrollUntilVisible(
              find.text('Khalmyr'),
              150,
              scrollable: find.byType(Scrollable).first,
            );
            await tester.ensureVisible(find.text('Khalmyr'));
            await tester.pumpAndSettle();
            await tester.tap(find.text('Khalmyr').first);
            await tester.pumpAndSettle();
            await tester.scrollUntilVisible(
              find.text('Obrigações & Restrições'),
              200,
              scrollable: find.byType(Scrollable).last,
            );
            expect(find.text('Obrigações & Restrições'), findsOneWidget);
          },
        );
      }
    }
  });

  group('Problema 2 - Cabeçalho recolhível e paisagem na Ficha', () {
    testWidgets(
      'Retrato 360x800: expandido mostra identidade; após rolar recolhe para Nome + PV + PM e >= 75% área livre',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(360, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          MaterialApp(
            home: FichaScreen(
              personagemInicial: _criarPersonagemTeste(),
              repository: _FakeRepo(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('topo_alinhamento_idade')), findsOneWidget);
        expect(find.byKey(const Key('btn_rolar_iniciativa_topo')), findsOneWidget);

        // Rola o conteúdo para recolher o cabeçalho
        await tester.drag(find.byType(TabBarView), const Offset(0, -300));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('topo_alinhamento_idade')), findsNothing);
        expect(find.text('Valeros Tormenta'), findsOneWidget);
        expect(find.text('PV 22/22'), findsOneWidget);
        expect(find.text('PM 3/3'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(FichaCabecalhoCompactoWidget),
            matching: find.text('-1'),
          ),
          findsNWidgets(2),
        );
        expect(
          find.descendant(
            of: find.byType(FichaCabecalhoCompactoWidget),
            matching: find.text('+1'),
          ),
          findsNWidgets(2),
        );

        final tabBarViewRect = tester.getRect(find.byType(TabBarView));
        expect(tabBarViewRect.height, greaterThanOrEqualTo(800 * 0.75));
      },
    );

    testWidgets(
      'Paisagem 800x360: conteúdo das abas tem >= 60% da altura sem precisar rolar',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 360));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          MaterialApp(
            home: FichaScreen(
              personagemInicial: _criarPersonagemTeste(),
              repository: _FakeRepo(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final tabBarViewRect = tester.getRect(find.byType(TabBarView));
        expect(tabBarViewRect.height, greaterThanOrEqualTo(360 * 0.60));
        expect(tester.takeException(), isNull);
      },
    );
  });
}
