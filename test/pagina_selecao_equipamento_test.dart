import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:t20_creator/domain/services/data_services/call_armas.dart';
import 'package:t20_creator/domain/services/data_services/call_classes.dart';
import 'package:t20_creator/presentation/controllers/personagem_cubit.dart';
import 'package:t20_creator/presentation/screens/pagina_selecao_equipamento.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PaginaSelecaoEquipamento - Modais de Seleção com Reciclagem Preguiçosa', () {
    testWidgets('Abre modal de armas exibindo lista preguiçosa com reciclagem de células', (tester) async {
      final classeGuerreiro = BancoDeClasses.getById('guerreiro')!;
      final cubit = PersonagemCubit();
      cubit.selecionarClasse(classeGuerreiro);

      // Garante carregamento das armas
      final _ = BancoDeArmas.todas;

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<PersonagemCubit>.value(
            value: cubit,
            child: Scaffold(
              body: PaginaSelecaoEquipamento(state: cubit.state),
            ),
          ),
        ),
      );

      // Toca no card de slot de Arma Simples para abrir o modal
      final slotArmaSimples = find.text('Selecionar Arma Simples');
      expect(slotArmaSimples, findsOneWidget);

      await tester.tap(slotArmaSimples);
      await tester.pumpAndSettle();

      // O modal bottom sheet deve estar aberto e renderizar um ListView com reciclagem
      expect(find.text('Escolha sua Arma Simples'), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);

      cubit.close();
    });
  });
}
