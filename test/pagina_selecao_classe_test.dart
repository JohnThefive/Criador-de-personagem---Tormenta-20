import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:t20_creator/domain/services/data_services/call_classes.dart';
import 'package:t20_creator/domain/services/data_services/catalogo_service.dart';
import 'package:t20_creator/presentation/controllers/ficha_controller/personagem_cubit.dart';
import 'package:t20_creator/presentation/screens/wizard_personagem/widgets/pagina_selecao_classe.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await CatalogoService.carregarTodos();
  });

  group('PaginaSelecaoClasse - Painel Informativo de Proficiências e Equipamentos', () {
    testWidgets(
      'Remove botão placeholder inativo e exibe painel informativo para Guerreiro',
      (tester) async {
        final classeGuerreiro = BancoDeClasses.getById('guerreiro')!;
        final cubit = PersonagemCubit();
        cubit.selecionarClasse(classeGuerreiro);

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<PersonagemCubit>.value(
              value: cubit,
              child: Scaffold(body: PaginaSelecaoClasse(state: cubit.state)),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. O botão inativo "Equipamento inicial" não deve mais existir
        expect(find.widgetWithText(ElevatedButton, 'Equipamento inicial'), findsNothing);

        // 2. Card informativo deve estar presente
        expect(find.text('Proficiências e Equipamentos'), findsOneWidget);

        // 3. Proficiência em Armas (Guerreiro usa Marciais e Simples)
        expect(find.textContaining('Armas Marciais e Simples'), findsOneWidget);

        // 4. Proteções permitidas (Guerreiro usa Leves, Pesadas e Escudos)
        expect(find.textContaining('Armaduras Leves, Pesadas e Escudos'), findsOneWidget);

        // 5. Conjuração / Foco Mágico (Guerreiro é Não-conjuradora)
        expect(find.textContaining('Não-conjuradora'), findsOneWidget);

        // 6. Nota de rodapé contextual
        expect(
          find.text('Você selecionará e equipará suas armas, armadura e escudo na Etapa 6 (Equipamento Inicial).'),
          findsOneWidget,
        );

        cubit.close();
      },
    );

    testWidgets(
      'Exibe proficiências e conjuração corretamente para Arcanista',
      (tester) async {
        final classeArcanista = BancoDeClasses.getById('arcanista')!;
        final cubit = PersonagemCubit();
        cubit.selecionarClasse(classeArcanista);

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<PersonagemCubit>.value(
              value: cubit,
              child: Scaffold(body: PaginaSelecaoClasse(state: cubit.state)),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Arcanista: Apenas Armas Simples, Nenhuma armadura/escudo, Conjuradora Arcana
        expect(find.textContaining('Apenas Armas Simples'), findsOneWidget);
        expect(find.textContaining('Nenhuma'), findsOneWidget);
        expect(find.textContaining('Conjuradora Arcana'), findsOneWidget);

        cubit.close();
      },
    );

    testWidgets(
      'Exibe proficiências e conjuração corretamente para Clérigo',
      (tester) async {
        final classeClerigo = BancoDeClasses.getById('clerigo')!;
        final cubit = PersonagemCubit();
        cubit.selecionarClasse(classeClerigo);

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<PersonagemCubit>.value(
              value: cubit,
              child: Scaffold(body: PaginaSelecaoClasse(state: cubit.state)),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Clérigo: Apenas Armas Simples, Armaduras Leves, Pesadas e Escudos, Conjuradora Divina (SAB)
        expect(find.textContaining('Apenas Armas Simples'), findsOneWidget);
        expect(find.textContaining('Armaduras Leves, Pesadas e Escudos'), findsOneWidget);
        expect(find.textContaining('Conjuradora Divina'), findsOneWidget);
        expect(find.textContaining('SAB'), findsOneWidget);

        cubit.close();
      },
    );
  });
}
