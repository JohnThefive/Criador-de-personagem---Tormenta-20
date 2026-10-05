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

    test('resolverCaminhoAsset normaliza maiúsculas e aliases para o SVG único canônico', () {
      expect(
        RpgIcon.resolverCaminhoAsset('MInotauro'),
        equals('assets/icons/racas/minotauro.svg'),
      );
      expect(
        RpgIcon.resolverCaminhoAsset('minotauro'),
        equals('assets/icons/racas/minotauro.svg'),
      );
      expect(
        RpgIcon.resolverCaminhoAsset('racas/Minotauro'),
        equals('assets/icons/racas/minotauro.svg'),
      );
      expect(
        RpgIcon.resolverCaminhoAsset('Osteon'),
        equals('assets/icons/racas/osteon.svg'),
      );
      expect(
        RpgIcon.resolverCaminhoAsset('Silfide'),
        equals('assets/icons/racas/silfide.svg'),
      );
      expect(
        RpgIcon.resolverCaminhoAsset('trog'),
        equals('assets/icons/racas/trog.svg'),
      );
      expect(
        RpgIcon.resolverCaminhoAsset('Trog'),
        equals('assets/icons/racas/trog.svg'),
      );
      expect(
        RpgIcon.resolverCaminhoAsset('sereia'),
        equals('assets/icons/racas/sereia_tritao.svg'),
      );
      expect(
        RpgIcon.resolverCaminhoAsset('racas/sereia'),
        equals('assets/icons/racas/sereia_tritao.svg'),
      );
      expect(
        RpgIcon.resolverCaminhoAsset('suraggel(luz)'),
        equals('assets/icons/racas/suraggel_aggelus.svg'),
      );
      expect(
        RpgIcon.resolverCaminhoAsset('suraggel(escuro)'),
        equals('assets/icons/racas/suraggel_sulfure.svg'),
      );
      // Resolução de ícones de classes
      expect(
        RpgIcon.resolverCaminhoAsset('classes/arcanista'),
        equals('assets/icons/classes/arcanista.svg'),
      );
      expect(
        RpgIcon.resolverCaminhoAsset('arcanista'),
        equals('assets/icons/classes/arcanista.svg'),
      );
      expect(
        RpgIcon.resolverCaminhoAsset('Guerreiro'),
        equals('assets/icons/classes/guerreiro.svg'),
      );
      expect(
        RpgIcon.resolverCaminhoAsset('classes/paladino.svg'),
        equals('assets/icons/classes/paladino.svg'),
      );
      expect(
        RpgIcon.resolverCaminhoAsset('lutador'),
        equals('assets/icons/classes/lutador.svg'),
      );
    });
  });
}
