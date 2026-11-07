import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:t20_creator/domain/entities/combate/inimigos_treino.dart';
import 'package:t20_creator/domain/entities/personagem/personagem.dart';
import 'package:t20_creator/presentation/screens/arena/widgets/rolar_iniciativa_view.dart';
import 'package:t20_creator/presentation/screens/arena/widgets/d20_dice.dart';
import 'package:t20_creator/presentation/screens/arena/widgets/roll_result_view.dart';

void main() {
  final heroi = Personagem(
    nome: 'Sir Valen',
    atributos: {},
    classes: [],
    historicoClassesPorNivel: [],
    periciasTreinadas: ['INICIATIVA'],
    outrosBonusPericias: {'INICIATIVA': 4},
    poderesGerais: [],
    itensInventario: [],
    itensVestidosExtras: [],
    armas: [],
    tibaresCobre: 0,
    tibares: 0,
    tibaresOuro: 0,
    outrosBonusDefesa: 0,
    rdPadrao: 0,
    rdsDiversas: [],
    proficienciasExtras: [],
    efeitosTemporarios: [],
    golpesPessoais: [],
  );

  testWidgets('RolarIniciativaView exibe d20 icosaédrico e avança etapas', (tester) async {
    bool combateIniciado = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(
              size: Size(800, 1000),
              disableAnimations: true,
            ),
            child: RolarIniciativaView(
              heroi: heroi,
              inimigos: [InimigosTreino.orcGuerreiro],
              onIniciarCombate: (h, inimigos) {
                combateIniciado = true;
              },
            ),
          ),
        ),
      ),
    );

    // 1. Estado Inicial
    expect(find.text('Rolagem de Iniciativa'), findsOneWidget);
    expect(find.byType(D20Dice), findsOneWidget);
    expect(find.text('🎲 Rolar Iniciativa do Herói'), findsOneWidget);

    // 2. Toca para rolar iniciativa do herói
    await tester.tap(find.text('🎲 Rolar Iniciativa do Herói'));
    await tester.pumpAndSettle();

    // 3. Resultado BG3 do herói é exibido
    expect(find.byType(RollResultView), findsOneWidget);
    expect(find.textContaining('Confirmar e Rolar'), findsOneWidget);

    // 4. Toca para confirmar e rolar do inimigo
    await tester.tap(find.textContaining('Confirmar e Rolar'));
    await tester.pumpAndSettle();

    // 5. Ordem Final exibida com botão de iniciar combate
    expect(find.text('⚔️ Iniciar Combate!'), findsOneWidget);

    // 6. Iniciar combate
    await tester.tap(find.text('⚔️ Iniciar Combate!'));
    await tester.pump();
    expect(combateIniciado, isTrue);
  });
}
