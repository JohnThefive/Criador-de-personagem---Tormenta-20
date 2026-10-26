import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:t20_creator/domain/services/data_services/call_classes.dart';
import 'package:t20_creator/presentation/controllers/personagem_cubit.dart';
import 'package:t20_creator/presentation/screens/wizard_personagem/pagina_pericias.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PaginaSelecaoPericias - Renderização Lazy com Slivers', () {
    testWidgets(
      'Renderiza com CustomScrollView e SliverGrid em vez de Wrap eager',
      (tester) async {
        final classeGuerreiro = BancoDeClasses.getById('guerreiro')!;
        final cubit = PersonagemCubit();
        cubit.selecionarClasse(classeGuerreiro);

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<PersonagemCubit>.value(
              value: cubit,
              child: Scaffold(body: PaginaSelecaoPericias(state: cubit.state)),
            ),
          ),
        );

        // Deve utilizar CustomScrollView e SliverGrid
        expect(find.byType(CustomScrollView), findsOneWidget);
        expect(find.byType(SliverGrid), findsAtLeastNWidgets(2));
        expect(find.byType(SliverToBoxAdapter), findsAtLeastNWidgets(2));

        // As seções principais devem estar presentes
        expect(find.text('Perícias Fixas da Classe'), findsOneWidget);
        expect(find.text('Escolhas da Classe'), findsOneWidget);

        cubit.close();
      },
    );
  });
}
