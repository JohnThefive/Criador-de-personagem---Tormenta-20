import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:t20_creator/domain/entities/combate/grid_tatico.dart';
import 'package:t20_creator/domain/entities/combate/monstro.dart';
import 'package:t20_creator/domain/entities/mestre/modelos_mestre.dart';
import 'package:t20_creator/domain/services/data_services/call_ameacas.dart';
import 'package:t20_creator/domain/services/data_services/mestre_storage_service.dart';
import 'package:t20_creator/presentation/controllers/mestre_controller/mestre_cubit.dart';
import 'package:t20_creator/presentation/controllers/mestre_controller/mestre_state.dart';
import 'package:t20_creator/presentation/screens/mestre/theme/mestre_theme.dart';
import 'package:t20_creator/presentation/screens/mestre/widgets/tela_bestiario_mestre.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    BancoDeAmeacas.resetar();
    tempDir = await Directory.systemTemp.createTemp('t20_mestre_test_');
    MestreStorageService.setDiretorioTeste(tempDir);
  });

  tearDown(() async {
    MestreStorageService.setDiretorioTeste(null);
    BancoDeAmeacas.resetar();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Persistência Local do Mestre & Ameaças Customizadas', () {
    test('salva e hidrata estado completo do Mestre + ameaças customizadas', () async {
      final cubit1 = MestreCubit(autoPersistir: false);
      addTearDown(cubit1.close);

      final camp = cubit1.criarCampanha(
        nome: 'Ruínas de Tamu-ra',
        descricao: 'Campanha sob a névoa',
      );
      cubit1.atualizarNotasSessao('Ponte quebrada antes da sala do trono.');
      cubit1.adicionarItemChecklist('Preparar trilha sonora');
      final perigoId = cubit1.state.perigos.first.id;
      if (!cubit1.state.perigos.first.fixado) {
        cubit1.alternarFixarPerigo(perigoId);
      }
      cubit1.favoritarNome('Valerius de Valkaria');

      cubit1.ocultarTodoMapa();
      cubit1.selecionarFerramentaMapa(FerramentaMapaMestre.nevoaDeGuerra);
      cubit1.aoClicarCelulaMapa(const Posicao2D(2, 3), fogModoRevelar: true);

      final custom = cubit1.salvarAmeacaCustomizada(
        const Monstro(
          id: '',
          nome: 'Oni da Névoa',
          nd: '4',
          regiao: 'tamu_ra',
          papel: PapelMonstro.solo,
          tipoCriatura: 'espírito',
          tamanho: 'Grande',
          pvMax: 140,
          pmMax: 24,
          defesa: 21,
          iniciativa: 6,
          ataques: [
            AtaqueMonstro(nome: 'Kanabo', bonusAtaque: 14, dano: '2d10+8'),
          ],
          habilidades: [
            HabilidadeMonstro(
              nome: 'Passo Nebuloso',
              acao: 'movimento',
              custoPm: 3,
              descricao: 'Teleporta-se até 9m pela névoa.',
            ),
          ],
        ),
      );

      cubit1.adicionarAmeacaNoMapa(
        custom,
        posicao: const Posicao2D(4, 4),
        ocultoParaJogadores: true,
        quantidade: 1,
      );
      final tokenAdicionado = cubit1.state.mapaAtual!.tokens.last;
      cubit1.ajustarPvToken(tokenAdicionado.id, -18);
      cubit1.adicionarCondicaoToken(tokenAdicionado.id, 'Lento');

      await cubit1.salvarAgora();

      // Simula fechamento total do app limpando memória do catálogo
      BancoDeAmeacas.resetar();

      final cubit2 = MestreCubit(autoPersistir: false);
      addTearDown(cubit2.close);
      await cubit2.carregarDoDisco();

      expect(cubit2.state.campanhaAtual?.id, equals(camp.id));
      expect(cubit2.state.campanhaAtual?.nome, equals('Ruínas de Tamu-ra'));
      expect(
        cubit2.state.sessaoAtual?.notasSessaoTexto,
        equals('Ponte quebrada antes da sala do trono.'),
      );
      expect(
        cubit2.state.sessaoAtual?.checklistNotas
            .any((i) => i.texto == 'Preparar trilha sonora'),
        isTrue,
      );
      expect(
        cubit2.state.perigos.firstWhere((p) => p.id == perigoId).fixado,
        isTrue,
      );
      expect(cubit2.state.nomesFavoritos, contains('Valerius de Valkaria'));
      expect(
        cubit2.state.mapaAtual?.celulasReveladas,
        equals({const Posicao2D(2, 3)}),
      );

      final tokenRestaurado = cubit2.state.mapaAtual!.tokens
          .firstWhere((t) => t.id == tokenAdicionado.id);
      expect(tokenRestaurado.pvAtual, equals(122));
      expect(tokenRestaurado.condicoes, contains('Lento'));
      expect(tokenRestaurado.monstro?.customizado, isTrue);

      final restauradoCatalogo = BancoDeAmeacas.getById(custom.id);
      expect(restauradoCatalogo, isNotNull);
      expect(restauradoCatalogo!.nome, equals('Oni da Névoa'));
      expect(restauradoCatalogo.customizado, isTrue);
      expect(restauradoCatalogo.ataques.single.nome, equals('Kanabo'));
      expect(
        restauradoCatalogo.habilidades.single.nome,
        equals('Passo Nebuloso'),
      );
    });

    test('excluir todas as campanhas persiste lista vazia sem restaurar seed', () async {
      final cubit1 = MestreCubit(autoPersistir: false);
      addTearDown(cubit1.close);

      for (final c in List.of(cubit1.state.campanhas)) {
        cubit1.excluirCampanha(c.id);
      }
      expect(cubit1.state.campanhas, isEmpty);
      await cubit1.salvarAgora();

      final cubit2 = MestreCubit(autoPersistir: false);
      addTearDown(cubit2.close);
      await cubit2.carregarDoDisco();

      expect(cubit2.state.campanhas, isEmpty);
      expect(cubit2.state.campanhaAtual, isNull);
    });

    testWidgets(
      'TelaBestiarioMestre permite criar, duplicar, editar e excluir ameaça customizada',
      (tester) async {
        const aranhaBase = Monstro(
          id: 'aranha_gigante_base',
          nome: 'Aranha Gigante',
          nd: '2',
          regiao: 'masmorras',
          papel: PapelMonstro.padrao,
          tipoCriatura: 'monstro',
          tamanho: 'Grande',
          pvMax: 52,
          pmMax: 0,
          defesa: 17,
          deslocamentoMetros: 12,
          iniciativa: 5,
          ataques: [
            AtaqueMonstro(nome: 'Mordida', bonusAtaque: 11, dano: '1d8+6'),
          ],
        );
        BancoDeAmeacas.carregarParaTestes(monstros: [aranhaBase]);

        final cubit = MestreCubit(autoPersistir: false);
        addTearDown(cubit.close);

        await tester.pumpWidget(
          MaterialApp(
            theme: MestreCores.homeStyleTheme,
            home: Scaffold(
              body: TelaBestiarioMestre(
                cubit: cubit,
                autoCarregar: false,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Criar nova ameaça do zero
        await tester.tap(find.text('Nova Ameaça'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const ValueKey('editor_ameaca_nome')),
          'Saqueador Corrompido',
        );
        await tester.enterText(
          find.byKey(const ValueKey('editor_ameaca_nd')),
          '3',
        );
        await tester.enterText(
          find.byKey(const ValueKey('editor_ameaca_pv')),
          '55',
        );
        await tester.tap(find.byKey(const ValueKey('editor_ameaca_salvar')));
        await tester.pumpAndSettle();

        expect(find.text('Saqueador Corrompido'), findsOneWidget);
        expect(BancoDeAmeacas.customizadas.length, equals(1));
        expect(BancoDeAmeacas.customizadas.first.pvMax, equals(55));

        // 2. Duplicar e editar criatura padrão do bestiário
        await tester.tap(find.text('Aranha Gigante'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Duplicar e Editar'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const ValueKey('editor_ameaca_nome')),
          'Aranha Sombria',
        );
        await tester.enterText(
          find.byKey(const ValueKey('editor_ameaca_pv')),
          '80',
        );
        await tester.tap(find.byKey(const ValueKey('editor_ameaca_salvar')));
        await tester.pumpAndSettle();

        expect(find.text('Aranha Sombria'), findsOneWidget);
        expect(BancoDeAmeacas.customizadas.length, equals(2));

        // 3. Editar e depois excluir ameaça customizada
        await tester.tap(find.text('Aranha Sombria'));
        await tester.pumpAndSettle();
        expect(find.text('Editar'), findsOneWidget);
        expect(find.text('Excluir'), findsOneWidget);

        await tester.tap(find.text('Editar'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const ValueKey('editor_ameaca_pv')),
          '95',
        );
        await tester.tap(find.byKey(const ValueKey('editor_ameaca_salvar')));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Aranha Sombria'));
        await tester.pumpAndSettle();
        expect(find.text('PV 95'), findsOneWidget);

        await tester.tap(find.text('Excluir'));
        await tester.pumpAndSettle();

        expect(find.text('Aranha Sombria'), findsNothing);
        expect(BancoDeAmeacas.customizadas.length, equals(1));

        // Persistir do widget test no disco e verificar no reload
        await tester.runAsync(() async {
          await cubit.salvarAgora();
        });
        final snap = await tester.runAsync(MestreStorageService.carregar);
        expect(snap, isNotNull);
        expect(
          snap!.ameacasCustomizadas.map((m) => m.nome),
          equals(['Saqueador Corrompido']),
        );
      },
    );

    test(
      'TokenNoMapa omite ficha completa de monstro padrão no JSON e reidrata pelo catálogo',
      () {
        const goblinPadrao = Monstro(
          id: 'goblin_padrao_catalogo',
          nome: 'Goblin Salteador',
          nd: '1/4',
          regiao: 'Reinados',
          pvMax: 6,
          defesa: 14,
          iniciativa: 3,
          customizado: false,
        );
        BancoDeAmeacas.carregarParaTestes(monstros: [goblinPadrao]);

        const token = TokenNoMapa(
          id: 'tok_goblin_1',
          nome: 'Goblin Salteador',
          posicao: Posicao2D(2, 2),
          ehHeroi: false,
          tipo: TipoCombatenteMapa.inimigo,
          pvAtual: 6,
          pvMax: 6,
          monstroId: 'goblin_padrao_catalogo',
          monstro: goblinPadrao,
        );

        final json = token.toJson();
        expect(json['monstroId'], equals('goblin_padrao_catalogo'));
        expect(json.containsKey('monstro'), isFalse);

        final restaurado = TokenNoMapa.fromJson(json);
        expect(restaurado.monstroId, equals('goblin_padrao_catalogo'));
        expect(restaurado.monstro?.nome, equals('Goblin Salteador'));
      },
    );
  });
}
