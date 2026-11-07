import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:t20_creator/domain/entities/personagem/personagem.dart';
import 'package:t20_creator/presentation/screens/arena/arena_screen.dart';
import 'package:t20_creator/presentation/screens/arena/widgets/arena_banner_turno.dart';
import 'package:t20_creator/presentation/screens/arena/widgets/arena_iniciativa_bar.dart';
import 'package:t20_creator/presentation/screens/arena/widgets/arena_terminal_log.dart';
import 'package:t20_creator/presentation/screens/arena/widgets/vtt_board_widget.dart';

void main() {
  final heroi = Personagem(
    nome: 'Sir Valen',
    atributos: {},
    classes: [],
    historicoClassesPorNivel: [],
    periciasTreinadas: ['INICIATIVA', 'LUTA'],
    outrosBonusPericias: {'INICIATIVA': 4, 'LUTA': 5},
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

  testWidgets('ArenaScreen avança para combate ativo e renderiza layout responsivo', (tester) async {
    // Define dimensões para simular celular retrato (estreito)
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(400, 800),
            disableAnimations: true,
          ),
          child: ArenaScreen(personagemOriginal: heroi),
        ),
      ),
    );

    // 1. Fase Inicial: Seleção de Inimigos
    expect(find.text('Escolha os Inimigos para o Teste:'), findsOneWidget);
    final botaoAvancar = find.text('Avançar para Rolagem (1 Inimigo)');
    expect(botaoAvancar, findsOneWidget);

    // 2. Avança para rolagem de iniciativa
    await tester.tap(botaoAvancar);
    await tester.pumpAndSettle();

    expect(find.text('Rolagem de Iniciativa'), findsOneWidget);
    expect(find.text('🎲 Rolar Iniciativa do Herói'), findsOneWidget);

    // 3. Rola iniciativa do herói
    await tester.tap(find.text('🎲 Rolar Iniciativa do Herói'));
    await tester.pumpAndSettle();

    // Confirma e rola iniciativa do inimigo
    final btnConfirmar = find.textContaining('Confirmar e Rolar');
    expect(btnConfirmar, findsOneWidget);
    await tester.tap(btnConfirmar);
    await tester.pumpAndSettle();

    // Iniciar combate
    expect(find.text('⚔️ Iniciar Combate!'), findsOneWidget);
    await tester.tap(find.text('⚔️ Iniciar Combate!'));
    await tester.pumpAndSettle();

    // 4. Combate Ativo no Layout Estreito
    expect(find.byType(ArenaIniciativaBar), findsOneWidget);
    expect(find.byType(ArenaBannerTurno), findsOneWidget);
    expect(find.byType(VttBoardWidget), findsOneWidget);
    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
  });

  testWidgets('ArenaScreen renderiza layout lado a lado em telas largas (tablet/desktop)', (tester) async {
    // Define dimensões para simular tablet / tela larga
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(1024, 768),
            disableAnimations: true,
          ),
          child: ArenaScreen(personagemOriginal: heroi),
        ),
      ),
    );

    // Avança direto pelas etapas
    await tester.tap(find.text('Avançar para Rolagem (1 Inimigo)'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('🎲 Rolar Iniciativa do Herói'));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Confirmar e Rolar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('⚔️ Iniciar Combate!'));
    await tester.pumpAndSettle();

    // Verifica layout lado a lado (Row com duas metades)
    expect(find.text('LOG DE COMBATE'), findsOneWidget);
    expect(find.byType(ArenaTerminalLog), findsOneWidget);
    expect(find.byType(VttBoardWidget), findsOneWidget);
    expect(find.byType(DraggableScrollableSheet), findsNothing);
  });
}
