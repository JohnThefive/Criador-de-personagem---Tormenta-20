import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:t20_creator/presentation/widgets/rpg_icon.dart';

void main() {
  group('Widget RpgIcon', () {
    testWidgets(
      'Renderiza SvgPicture com caminho relativo e parâmetros padrão',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: RpgIcon(iconName: 'racas/anao')),
          ),
        );

        final svgFinder = find.byType(SvgPicture);
        expect(svgFinder, findsOneWidget);

        final svgWidget = tester.widget<SvgPicture>(svgFinder);
        expect(svgWidget.width, equals(24.0));
        expect(svgWidget.height, equals(24.0));
      },
    );

    testWidgets('Renderiza com tamanho e cor customizados', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RpgIcon(
              iconName: 'racas/elfo',
              size: 48.0,
              color: Colors.amber,
            ),
          ),
        ),
      );

      final svgFinder = find.byType(SvgPicture);
      expect(svgFinder, findsOneWidget);

      final svgWidget = tester.widget<SvgPicture>(svgFinder);
      expect(svgWidget.width, equals(48.0));
      expect(svgWidget.height, equals(48.0));
    });

    testWidgets('Suporta nome direto sem prefixo racas/', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: RpgIcon(iconName: 'dahllan', size: 32.0)),
        ),
      );

      final svgFinder = find.byType(SvgPicture);
      expect(svgFinder, findsOneWidget);
    });
  });
}
