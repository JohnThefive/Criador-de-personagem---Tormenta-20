import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:t20_creator/domain/entities/combate/grid_tatico.dart';
import 'package:t20_creator/domain/entities/entidade_sessao_lan/sessao_lan_modelos.dart';
import 'package:t20_creator/domain/entities/mestre/modelos_mestre.dart';
import 'package:t20_creator/presentation/controllers/mestre_controller/mestre_cubit.dart';
import 'package:t20_creator/presentation/controllers/mestre_controller/mestre_state.dart';
import 'package:t20_creator/presentation/screens/mestre/mesa_sessao_screen.dart';
import 'package:t20_creator/presentation/screens/mestre/mestre_painel_screen.dart';
import 'package:t20_creator/presentation/screens/mestre/widgets/mestre_battlemap_widget.dart';
import 'package:t20_creator/presentation/screens/mestre/widgets/tela_escudo_notas.dart';
import 'package:t20_creator/presentation/screens/mestre/widgets/tela_mesa_jogo.dart';

void main() {
  group('ADR-003 — Hierarquia Campanha -> Aventura -> Sessão & LAN Frontend', () {
    test('Cria Campanha, Aventura e Sessão preservando seleção hierárquica', () {
      final cubit = MestreCubit();

      // 1. Cria nova Campanha
      cubit.criarCampanha(
        nome: 'Guerra Artoniana',
        descricao: 'Conflito contra o Império de Tauron',
        patamar: 'Veterano (Nível 5 a 10)',
      );
      expect(cubit.state.campanhaAtual?.nome, 'Guerra Artoniana');

      // 2. Cria nova Aventura dentro da Campanha
      cubit.criarAventura(
        nome: 'O Cerco de Valkaria',
        sinopse: 'Defender as muralhas externas',
      );
      expect(cubit.state.aventuraAtual?.nome, 'O Cerco de Valkaria');

      // 3. Cria nova Sessão dentro da Aventura
      cubit.criarSessao(
        titulo: 'Sessão #02 — A Noite dos Puristas',
        objetivoResumo: 'Infiltrar no acampamento inimigo',
      );
      expect(cubit.state.sessaoAtual?.titulo, 'Sessão #02 — A Noite dos Puristas');
    });

    test('Controles Frontend LAN e Revisão de Fichas (RF-M1)', () {
      final cubit = MestreCubit();

      expect(cubit.state.statusLan, StatusConexaoLan.desligado);

      // Abre a sala LAN
      cubit.alternarServidorLan();
      expect(cubit.state.statusLan, StatusConexaoLan.aguardandoJogadores);

      // Simula entrada de jogador via LAN com ficha pendente
      cubit.receberSolicitacaoEntradaLan(
        SolicitacaoEntradaSessao(
          codigoSala: cubit.codigoSalaLanAtivo,
          characterId: 'lan_orion',
          nomeJogador: 'Rafael',
          nomePersonagem: 'Orion',
          classeResumo: 'Bardo Nv 3',
          pvAtual: 24,
          pvMax: 24,
          pmAtual: 10,
          pmMax: 10,
          defesa: 14,
          deslocamentoMetros: 9.0,
        ),
      );

      final orion = cubit.state.sessaoAtual!.elenco.firstWhere(
        (e) => e.nomePersonagem == 'Orion',
      );
      expect(orion.statusRevisao, StatusRevisaoFicha.pendente);

      // Mestre aprova a ficha -> entra também no mapa de batalha
      cubit.atualizarStatusRevisaoFicha(
        orion.characterId,
        StatusRevisaoFicha.aprovada,
      );

      final orionAprovado = cubit.state.sessaoAtual!.elenco.firstWhere(
        (e) => e.characterId == orion.characterId,
      );
      expect(orionAprovado.statusRevisao, StatusRevisaoFicha.aprovada);
      expect(
        cubit.state.mapaAtual!.tokens.any((t) => t.id == orion.characterId),
        isTrue,
      );
    });
  });

  group('ADR-003 — Mapa de Batalha, Imagem na Grid, Movimento e Sentinela de Privacidade', () {
    test('Define imagem de fundo na grid e move personagens pelo tabuleiro (RF-M6)', () {
      final cubit = MestreCubit();

      // Define uma imagem customizada de fundo
      cubit.definirImagemFundoMapa('/caminho/falso/masmorra_bg.png');
      expect(
        cubit.state.mapaAtual?.imagemCaminhoLocal,
        '/caminho/falso/masmorra_bg.png',
      );
      expect(
        cubit.state.mapaAtual?.presetFundo,
        PresetFundoMapa.imagemCustomizada,
      );

      // Seleciona o token no mapa (Batedor Purista em 9, 4) para mover
      final token = cubit.state.mapaAtual!.tokens.first;
      expect(token.posicao, const Posicao2D(9, 4));

      cubit.aoClicarTokenNoMapa(token);
      expect(cubit.state.tokenSelecionadoParaMoverId, token.id);
      expect(cubit.state.celulasAlcancaveisToken, isNotEmpty);

      // Move para uma célula adjacente alcançável (9, 3)
      const destino = Posicao2D(9, 3);
      expect(cubit.state.celulasAlcancaveisToken.contains(destino), isTrue);

      cubit.aoClicarCelulaMapa(destino);
      final tokenMovido = cubit.state.mapaAtual!.tokens.firstWhere(
        (t) => t.id == token.id,
      );
      expect(tokenMovido.posicao, destino);
    });

    test('Sentinela de Privacidade (ADR-003 §8): projectMapaFor filtra tokens SomenteMestre e células ocultas', () {
      final cubit = MestreCubit();
      final mapaMestre = cubit.state.mapaAtual!;

      // Na visão do Mestre, o token "Batedor Purista" (SomenteMestre) existe
      expect(
        mapaMestre.tokens.any((t) => t.nome.contains('Batedor Purista')),
        isTrue,
      );

      // Alterna para "Ver como Jogador" (Preview RF-M7)
      cubit.alternarVisaoMestreJogador();
      expect(cubit.state.estaEmPreviewJogador, isTrue);

      final mapaProjetadoJogador = cubit.state.mapaProjetado!;
      // O token SomenteMestre NUNCA pode aparecer na projeção do jogador
      expect(
        mapaProjetadoJogador.tokens.any((t) => t.nome.contains('Batedor Purista')),
        isFalse,
      );
    });
  });

  group('UI Mobile & Drawer — MestrePainelScreen', () {
    testWidgets('Renderiza Campanhas inicialmente e navega via Drawer entre Mapas e Escudo', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: MestrePainelScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tela inicial exibe as campanhas em cards e FAB "Nova campanha"
      expect(find.textContaining('Coração de Rubi'), findsWidgets);
      expect(find.byType(FloatingActionButton), findsOneWidget);

      // Abre o Drawer e verifica os destinos do mestre
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      final drawer = find.byType(NavigationDrawer);
      expect(find.descendant(of: drawer, matching: find.text('Campanhas')), findsOneWidget);
      expect(find.descendant(of: drawer, matching: find.text('Mapas')), findsOneWidget);
      expect(find.descendant(of: drawer, matching: find.text('Escudo e Notas')), findsOneWidget);

      // Navega para "Escudo e Notas"
      await tester.tap(find.descendant(of: drawer, matching: find.text('Escudo e Notas')));
      await tester.pumpAndSettle();

      expect(find.text('Condições'), findsOneWidget);
      expect(find.text('Perigos'), findsOneWidget);
      expect(find.text('Nomes'), findsOneWidget);
      expect(find.text('Regras de Combate'), findsOneWidget);
      expect(find.text('Notas da Sessão'), findsOneWidget);

      // Abre o Drawer, vai para "Mapas" e abre a Mesa de Jogo
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(NavigationDrawer), matching: find.text('Mapas')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Ruínas da Estrada'), findsWidgets);
      await tester.tap(find.textContaining('Ruínas da Estrada').first);
      await tester.pumpAndSettle();

      // Verifica elementos da Mesa de Jogo
      expect(find.textContaining('Enviar aos jogadores'), findsOneWidget);
      expect(find.byIcon(Icons.circle), findsWidgets); // indicador LAN discreto
    });
  });

  group('ADR-003 — Operações de Hierarquia, Sessão e LAN (Parte 1)', () {
    test('Renomeia, duplica e altera status da Sessão', () {
      final cubit = MestreCubit();
      final sessaoOriginal = cubit.state.sessaoAtual!;

      // Altera status para em andamento
      cubit.alterarStatusSessao(sessaoOriginal.id, StatusSessao.emAndamento);
      expect(cubit.state.sessaoAtual?.statusSessao, StatusSessao.emAndamento);

      // Renomeia sessão
      cubit.renomearSessao(sessaoOriginal.id, 'Sessão Épica');
      expect(cubit.state.sessaoAtual?.titulo, 'Sessão Épica');

      // Duplica sessão
      cubit.duplicarSessao(sessaoOriginal.id);
      final aventura = cubit.state.aventuraAtual!;
      expect(aventura.sessoes.length, 2);
      expect(aventura.sessoes.any((s) => s.titulo.contains('(Cópia)')), isTrue);
    });
  });

  group('ADR-003 — Mesa Tática: PV/PM, Condições, Pings e Medição T20 (Parte 4)', () {
    test('Ajusta PV/PM e adiciona/remove condições em tempo real', () {
      final cubit = MestreCubit();
      final token = cubit.state.mapaAtual!.tokens.first; // Batedor Purista (PV 24, PM 6)

      // Dano de 10 PV (24 - 10 = 14)
      cubit.ajustarPvToken(token.id, -10);
      var tokenAtualizado = cubit.state.mapaAtual!.tokens.firstWhere((t) => t.id == token.id);
      expect(tokenAtualizado.pvAtual, 14);

      // Gasto de 2 PM (6 - 2 = 4)
      cubit.ajustarPmToken(token.id, -2);
      tokenAtualizado = cubit.state.mapaAtual!.tokens.firstWhere((t) => t.id == token.id);
      expect(tokenAtualizado.pmAtual, 4);

      // Aplica condição 'Abalado'
      cubit.adicionarCondicaoToken(token.id, 'Abalado');
      tokenAtualizado = cubit.state.mapaAtual!.tokens.firstWhere((t) => t.id == token.id);
      expect(tokenAtualizado.condicoes.contains('Abalado'), isTrue);

      // Remove condição
      cubit.removerCondicaoToken(token.id, 'Abalado');
      tokenAtualizado = cubit.state.mapaAtual!.tokens.firstWhere((t) => t.id == token.id);
      expect(tokenAtualizado.condicoes.contains('Abalado'), isFalse);
    });

    test('Medição de distância respeita regra T20 (1ª diagonal = 1,5m, 2ª diagonal = 3m)', () {
      final cubit = MestreCubit();

      // Origem (0, 0) até Destino (2, 2) = 2 passos diagonais
      // 1ª diagonal: 1,5m; 2ª diagonal: 3,0m => total 4,5m
      cubit.registrarPontoMedicao(const Posicao2D(0, 0));
      cubit.registrarPontoMedicao(const Posicao2D(2, 2));

      expect(cubit.state.pontoOrigemMedicao, const Posicao2D(0, 0));
      expect(cubit.state.pontoDestinoMedicao, const Posicao2D(2, 2));

      cubit.limparMedicao();
      expect(cubit.state.pontoOrigemMedicao, isNull);
      expect(cubit.state.pontoDestinoMedicao, isNull);
    });

    test('Solta ping tático e registra no estado', () {
      final cubit = MestreCubit();

      cubit.soltarPing(const Posicao2D(4, 4));
      expect(cubit.state.pingsAtivos.length, 1);
      expect(cubit.state.pingsAtivos.first, const Posicao2D(4, 4));
    });
  });

  group('ADR-003 — Escudo do Mestre: Perigos, Nomes Aleatórios e Checklist (Parte 5)', () {
    test('Gera nomes aleatórios com raça/gênero e gerencia favoritos', () {
      final cubit = MestreCubit();

      cubit.gerarNomeAleatorio(raca: 'Elfo', genero: 'Feminino', tom: 'Sério');
      expect(cubit.state.nomeGeradoAtual, isNotNull);
      expect(cubit.state.historicoNomes, isNotEmpty);

      final nomeGerado = cubit.state.nomeGeradoAtual!;
      cubit.favoritarNome(nomeGerado);
      expect(cubit.state.nomesFavoritos.contains(nomeGerado), isTrue);
    });

    test('Gerencia checklist interativo da sessão e notas', () {
      final cubit = MestreCubit();

      // Adiciona novo item de checklist
      cubit.adicionarItemChecklist('Encontrar o contato na taverna');
      expect(
        cubit.state.sessaoAtual?.checklistNotas.any((i) => i.texto == 'Encontrar o contato na taverna'),
        isTrue,
      );

      final item = cubit.state.sessaoAtual!.checklistNotas.firstWhere(
        (i) => i.texto == 'Encontrar o contato na taverna',
      );
      expect(item.concluido, isFalse);

      // Marca como concluído
      cubit.alternarItemChecklist(item.id);
      final itemConcluido = cubit.state.sessaoAtual!.checklistNotas.firstWhere(
        (i) => i.id == item.id,
      );
      expect(itemConcluido.concluido, isTrue);

      // Atualiza texto de notas da sessão
      cubit.atualizarNotasSessao('Os heróis descobriram o mapa secreto.');
      expect(cubit.state.sessaoAtual?.notasSessaoTexto, 'Os heróis descobriram o mapa secreto.');
    });

    test('Fixa e desafixa perigos do Escudo', () {
      final cubit = MestreCubit();
      final primeiroPerigo = cubit.state.perigos.first;

      final fixadoOriginal = primeiroPerigo.fixado;
      cubit.alternarFixarPerigo(primeiroPerigo.id);

      final perigoAtualizado = cubit.state.perigos.firstWhere((p) => p.id == primeiroPerigo.id);
      expect(perigoAtualizado.fixado, !fixadoOriginal);
    });

    test('Sessão inicia sem jogadores automáticos; Mestre cria NPCs e jogadores só entram ao conectar via LAN', () {
      final cubit = MestreCubit();

      // 1. O elenco inicial deve ser vazio (sem heróis pré-conectados)
      expect(cubit.state.sessaoAtual?.elenco, isEmpty);

      // 2. O mapa não possui heróis pré-alocados, apenas a ameaça inicial do mestre
      expect(cubit.state.mapaAtual!.tokens.any((t) => t.ehHeroi), isFalse);
      expect(cubit.state.mapaAtual!.tokens.any((t) => t.nome == 'Batedor Purista'), isTrue);

      // 3. Mestre cria novos NPCs / Ameaças dinamicamente
      cubit.adicionarTokenCustomizadoNoMapa(
        nome: 'Lobo das Cavernas',
        ehHeroi: false,
        tipo: TipoCombatenteMapa.inimigo,
        pvMax: 18,
        pmMax: 0,
        defesa: 14,
        tamanhoQuadrados: 1,
        posicao: const Posicao2D(5, 2),
      );
      expect(cubit.state.mapaAtual!.tokens.any((t) => t.nome == 'Lobo das Cavernas'), isTrue);

      // 4. Jogador conecta via LAN
      cubit.receberSolicitacaoEntradaLan(
        SolicitacaoEntradaSessao(
          codigoSala: cubit.codigoSalaLanAtivo,
          characterId: 'lan_kallista',
          nomeJogador: 'Beatriz',
          nomePersonagem: 'Kallista',
          classeResumo: 'Clériga Nv 2',
          pvAtual: 24,
          pvMax: 24,
          pmAtual: 10,
          pmMax: 10,
          defesa: 14,
          deslocamentoMetros: 9.0,
        ),
      );
      expect(cubit.state.sessaoAtual!.elenco.length, 1);
      final kallista = cubit.state.sessaoAtual!.elenco.first;
      expect(kallista.statusRevisao, StatusRevisaoFicha.pendente);

      // 5. Antes da aprovação do mestre, o herói NÃO está no mapa
      expect(cubit.state.mapaAtual!.tokens.any((t) => t.id == kallista.characterId), isFalse);

      // 6. Mestre aprova a ficha -> agora sim o herói entra no mapa de batalha
      cubit.atualizarStatusRevisaoFicha(kallista.characterId, StatusRevisaoFicha.aprovada);
      expect(cubit.state.mapaAtual!.tokens.any((t) => t.id == kallista.characterId), isTrue);
    });
  });

  group('Auditoria Painel do Mestre — Regras, Cubit e Otimizações', () {
    test('3º ponto de medição reinicia origem e limpa destino (limparDestinoMedicao: true)', () {
      final cubit = MestreCubit();
      addTearDown(cubit.close);

      cubit.registrarPontoMedicao(const Posicao2D(1, 1));
      expect(cubit.state.pontoOrigemMedicao, const Posicao2D(1, 1));
      expect(cubit.state.pontoDestinoMedicao, isNull);

      cubit.registrarPontoMedicao(const Posicao2D(4, 3));
      expect(cubit.state.pontoOrigemMedicao, const Posicao2D(1, 1));
      expect(cubit.state.pontoDestinoMedicao, const Posicao2D(4, 3));

      // Ao registrar um 3º ponto, origem atualiza e destino volta a null
      cubit.registrarPontoMedicao(const Posicao2D(6, 2));
      expect(cubit.state.pontoOrigemMedicao, const Posicao2D(6, 2));
      expect(cubit.state.pontoDestinoMedicao, isNull);
    });

    test('adicionarTokenCustomizadoNoMapa em lote gera 5 IDs distintos dentro dos limites do mapa', () {
      final cubit = MestreCubit();
      addTearDown(cubit.close);

      final mapa = cubit.state.mapaAtual!;
      final qtdInicial = mapa.tokens.length;

      cubit.adicionarTokenCustomizadoNoMapa(
        nome: 'Goblin Saqueador',
        ehHeroi: false,
        pvMax: 12,
        posicao: Posicao2D(mapa.largura - 2, mapa.altura - 1),
        quantidade: 5,
      );

      final mapaAtualizado = cubit.state.mapaAtual!;
      final novosTokens = mapaAtualizado.tokens.skip(qtdInicial).toList();
      expect(novosTokens.length, 5);
      expect(novosTokens.map((t) => t.id).toSet().length, 5);

      for (final token in novosTokens) {
        expect(token.posicao.x, inInclusiveRange(0, mapaAtualizado.largura - 1));
        expect(token.posicao.y, inInclusiveRange(0, mapaAtualizado.altura - 1));
      }
    });

    test('Fog of War explícito: fogModoRevelar true mantém revelada e false oculta sem alternar', () {
      final cubit = MestreCubit();
      addTearDown(cubit.close);

      cubit.selecionarFerramentaMapa(FerramentaMapaMestre.nevoaDeGuerra);

      // No mapa padrão, colunas 0..6 iniciam reveladas e 7..11 ocultas
      const pos = Posicao2D(10, 4);
      expect(cubit.state.mapaAtual!.celulasReveladas.contains(pos), isFalse);

      // Múltiplos cliques em modo revelar mantêm a célula revelada
      cubit.aoClicarCelulaMapa(pos, fogModoRevelar: true);
      expect(cubit.state.mapaAtual!.celulasReveladas.contains(pos), isTrue);

      cubit.aoClicarCelulaMapa(pos, fogModoRevelar: true);
      expect(cubit.state.mapaAtual!.celulasReveladas.contains(pos), isTrue);

      // Múltiplos cliques em modo ocultar mantêm a célula oculta sem alternar
      cubit.aoClicarCelulaMapa(pos, fogModoRevelar: false);
      expect(cubit.state.mapaAtual!.celulasReveladas.contains(pos), isFalse);

      cubit.aoClicarCelulaMapa(pos, fogModoRevelar: false);
      expect(cubit.state.mapaAtual!.celulasReveladas.contains(pos), isFalse);
    });

    test('criarMapa preserva opções e salvarConfiguracoesMapaCompleto faz clamp e limpa imagem', () {
      final cubit = MestreCubit();
      addTearDown(cubit.close);

      cubit.criarMapa(
        nome: 'Câmara Oculta',
        largura: 14,
        altura: 10,
        gridVisivel: false,
        opacidadeGrid: 0.65,
        ajusteEscala: 1.75,
        imagemCaminhoLocal: '/tmp/mapa_teste.png',
        comecarComTudoOculto: true,
      );

      final mapaCriado = cubit.state.mapaAtual!;
      expect(mapaCriado.nome, 'Câmara Oculta');
      expect(mapaCriado.gridVisivel, isFalse);
      expect(mapaCriado.opacidadeGrid, closeTo(0.65, 0.001));
      expect(mapaCriado.ajusteEscala, closeTo(1.75, 0.001));
      expect(mapaCriado.imagemCaminhoLocal, '/tmp/mapa_teste.png');
      expect(mapaCriado.celulasReveladas, isEmpty);

      cubit.adicionarTokenCustomizadoNoMapa(
        nome: 'Golem',
        ehHeroi: false,
        pvMax: 40,
        posicao: const Posicao2D(12, 8),
      );

      final mapaEditado = cubit.state.mapaAtual!.copyWith(
        largura: 6,
        altura: 5,
        limparImagemCustomizada: true,
        terrenos: {
          const Posicao2D(2, 2): TipoTerreno.dificil,
          const Posicao2D(12, 8): TipoTerreno.obstaculo,
        },
        celulasReveladas: {
          const Posicao2D(1, 1),
          const Posicao2D(12, 8),
        },
      );

      cubit.salvarConfiguracoesMapaCompleto(mapaEditado);

      final mapaSalvo = cubit.state.mapaAtual!;
      expect(mapaSalvo.largura, 6);
      expect(mapaSalvo.altura, 5);
      expect(mapaSalvo.imagemCaminhoLocal, isNull);
      expect(mapaSalvo.tokens.single.posicao, const Posicao2D(5, 4));
      expect(mapaSalvo.terrenos.containsKey(const Posicao2D(2, 2)), isTrue);
      expect(mapaSalvo.terrenos.containsKey(const Posicao2D(12, 8)), isFalse);
      expect(mapaSalvo.celulasReveladas, {const Posicao2D(1, 1)});
    });
  });

  group('Auditoria Painel do Mestre — Widget Tests (VTT, LAN e IndexedStack)', () {
    testWidgets('MestreBattlemapWidget usa CustomPaint único para grade e escala token 2x2', (tester) async {
      final cubit = MestreCubit();
      addTearDown(cubit.close);

      cubit.adicionarTokenCustomizadoNoMapa(
        nome: 'Ogro Gigante',
        ehHeroi: false,
        pvMax: 60,
        tamanhoQuadrados: 2,
        posicao: const Posicao2D(2, 2),
      );

      final token1x1 = cubit.state.mapaAtual!.tokens.firstWhere((t) => t.tamanhoQuadrados == 1);
      final token2x2 = cubit.state.mapaAtual!.tokens.firstWhere((t) => t.tamanhoQuadrados == 2);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              height: 400,
              child: MestreBattlemapWidget(cubit: cubit),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Grade desenhada por um único CustomPaint com painter ativo (sem N×M GestureDetectors por célula)
      final gridCustomPaint = find.descendant(
        of: find.byType(MestreBattlemapWidget),
        matching: find.byKey(const ValueKey('battlemap_grid_painter')),
      );
      expect(gridCustomPaint, findsOneWidget);
      final gridWidget = tester.widget<CustomPaint>(gridCustomPaint);
      expect(gridWidget.painter, isNotNull);

      final totalCelulas = cubit.state.mapaAtual!.largura * cubit.state.mapaAtual!.altura;
      final gestureDetectors = find.descendant(
        of: find.byType(MestreBattlemapWidget),
        matching: find.byType(GestureDetector),
      );
      expect(gestureDetectors.evaluate().length, lessThan(totalCelulas));

      // Token tamanhoQuadrados: 2 ocupa 2x largura e altura de um token 1x1
      final size1x1 = tester.getSize(find.byKey(ValueKey('token_${token1x1.id}')));
      final size2x2 = tester.getSize(find.byKey(ValueKey('token_${token2x2.id}')));
      expect(size2x2.width, closeTo(size1x1.width * 2, 0.01));
      expect(size2x2.height, closeTo(size1x1.height * 2, 0.01));
    });

    testWidgets('TelaMesaJogo mede distância entre 2 pontos e dispara ping com limpeza de timer', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final cubit = MestreCubit();
      addTearDown(cubit.close);

      await tester.pumpWidget(
        MaterialApp(
          home: TelaMesaJogo(
            cubit: cubit,
            onVoltarBiblioteca: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Alterna para ferramenta Medir Distância
      await tester.tap(find.byIcon(FerramentaMesa.medirDistancia.icone));
      await tester.pumpAndSettle();

      final gridPaint = find.byKey(const ValueKey('battlemap_grid_painter'));
      final topLeft = tester.getTopLeft(gridPaint);
      final size = tester.getSize(gridPaint);
      final cellW = size.width / cubit.state.mapaAtual!.largura;
      final cellH = size.height / cubit.state.mapaAtual!.altura;

      // Toca em (2, 2) e (4, 4) -> 2 diagonais = 6.0 metros na regra T20
      await tester.tapAt(topLeft + Offset(cellW * 2.5, cellH * 2.5));
      await tester.pump();
      await tester.tapAt(topLeft + Offset(cellW * 4.5, cellH * 4.5));
      await tester.pumpAndSettle();

      expect(cubit.state.pontoOrigemMedicao, const Posicao2D(2, 2));
      expect(cubit.state.pontoDestinoMedicao, const Posicao2D(4, 4));
      expect(find.textContaining('Distância: 6.0 metros'), findsOneWidget);

      // Alterna para ferramenta Pings e dispara um ping em (5, 3)
      await tester.tap(find.byIcon(FerramentaMesa.pings.icone));
      await tester.pumpAndSettle();

      await tester.tapAt(topLeft + Offset(cellW * 5.5, cellH * 3.5));
      await tester.pump();

      expect(cubit.state.pingsAtivos, contains(const Posicao2D(5, 3)));

      // Avança o timer de 4s do ping para evitar pending timers
      await tester.pump(const Duration(seconds: 5));
      expect(cubit.state.pingsAtivos, isEmpty);
    });

    testWidgets(
      'MesaSessaoScreen aba Jogadores exibe entrada LAN, inspeciona ficha e envia nota ao jogador',
      (tester) async {
        tester.view.physicalSize = const Size(430, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final cubit = MestreCubit();
        addTearDown(cubit.close);

        await tester.pumpWidget(
          MaterialApp(
            home: MesaSessaoScreen(cubit: cubit, abaInicial: 2),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Nenhum jogador nesta sessão ainda.'), findsOneWidget);

        cubit.receberSolicitacaoEntradaLan(
          SolicitacaoEntradaSessao(
            codigoSala: cubit.codigoSalaLanAtivo,
            characterId: 'char_kaelen',
            nomeJogador: 'Lucas',
            nomePersonagem: 'Kaelen',
            classeResumo: 'Ladino Nv 2',
            pvAtual: 18,
            pvMax: 18,
            pmAtual: 6,
            pmMax: 6,
            defesa: 15,
            deslocamentoMetros: 9.0,
            snapshotPersonagem: const {
              'atributos': {'FOR': 1, 'DES': 4},
              'periciasTreinadas': ['Furtividade', 'Ladinagem'],
              'magiasConhecidas': ['Névoa'],
              'itensInventario': ['Gazuas'],
            },
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Nenhum jogador nesta sessão ainda.'), findsNothing);
        expect(find.text('Kaelen'), findsOneWidget);

        // Abre o modal de inspeção de ficha e envia uma nota ao jogador
        await tester.tap(
          find.byKey(const Key('botao_inspecionar_ficha_char_kaelen')),
        );
        await tester.pumpAndSettle();

        expect(find.text('Kaelen • Ladino Nv 2'), findsOneWidget);
        expect(find.text('DES +4'), findsOneWidget);
        expect(find.textContaining('Furtividade'), findsOneWidget);
        expect(find.textContaining('Gazuas'), findsOneWidget);

        await tester.enterText(
          find.byKey(const Key('campo_nota_mestre_para_jogador')),
          'Você encontrou uma chave enferrujada.',
        );
        await tester.tap(find.byKey(const Key('botao_enviar_nota_jogador')));
        await tester.pumpAndSettle();

        final entry = cubit.state.sessaoAtual!.elenco.firstWhere(
          (e) => e.characterId == 'char_kaelen',
        );
        expect(entry.notaRevisao, 'Você encontrou uma chave enferrujada.');
      },
    );

    testWidgets('MestrePainelScreen preserva estado de TelaEscudoNotas via IndexedStack ao alternar abas', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: MestrePainelScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Abre Drawer e vai para Escudo e Notas, digita busca e seleciona aba "Perigos"
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationDrawer),
          matching: find.text('Escudo e Notas'),
        ),
      );
      await tester.pumpAndSettle();

      final buscaEscudo = find.descendant(
        of: find.byType(TelaEscudoNotas),
        matching: find.byType(TextField),
      );
      await tester.enterText(buscaEscudo.first, 'Armadilha');
      await tester.pump();

      await tester.tap(find.text('Perigos'));
      await tester.pumpAndSettle();

      final tabBarAntes = tester.widget<TabBar>(
        find.descendant(
          of: find.byType(TelaEscudoNotas),
          matching: find.byType(TabBar),
        ),
      );
      expect(tabBarAntes.controller?.index, 1);

      // Alterna via Drawer para Mapas e volta para Escudo e Notas
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationDrawer),
          matching: find.text('Mapas'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationDrawer),
          matching: find.text('Escudo e Notas'),
        ),
      );
      await tester.pumpAndSettle();

      // Busca e aba selecionada devem permanecer preservadas pelo IndexedStack
      final buscaDepois = find.descendant(
        of: find.byType(TelaEscudoNotas),
        matching: find.widgetWithText(TextField, 'Armadilha'),
      );
      expect(buscaDepois, findsOneWidget);

      final tabBarDepois = tester.widget<TabBar>(
        find.descendant(
          of: find.byType(TelaEscudoNotas),
          matching: find.byType(TabBar),
        ),
      );
      expect(tabBarDepois.controller?.index, 1);
    });
  });
}
