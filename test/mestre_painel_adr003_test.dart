import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:t20_creator/domain/entities/combate/grid_tatico.dart';
import 'package:t20_creator/domain/entities/mestre/modelos_mestre.dart';
import 'package:t20_creator/presentation/controllers/mestre_controller/mestre_cubit.dart';
import 'package:t20_creator/presentation/controllers/mestre_controller/mestre_state.dart';
import 'package:t20_creator/presentation/screens/mestre/mestre_painel_screen.dart';

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
      cubit.simularPedidoEntradaJogadorLan(
        nomeJogador: 'Rafael',
        nomePersonagem: 'Orion',
        classeResumo: 'Bardo Nv 3',
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

  group('UI Tablet & Mobile — MestrePainelScreen (Novo Design)', () {
    testWidgets('Renderiza layout Tablet com NavigationRail e navega entre Mapas e Escudo', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: MestrePainelScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verifica o chip de contexto no topo (Parte 0)
      expect(find.textContaining('Coração de Rubi'), findsWidgets);

      // Verifica os 2 destinos do NavigationRail (Parte 0)
      expect(find.text('Mapas'), findsWidgets);
      expect(find.text('Escudo e Notas'), findsWidgets);

      // Na tela inicial (Biblioteca de Mapas - Parte 2), verifica cards de mapas e FAB
      expect(find.textContaining('Ruínas da Estrada'), findsWidgets);
      expect(find.byType(FloatingActionButton), findsOneWidget);

      // Navega para a aba "Escudo e Notas" (Parte 5)
      await tester.tap(find.text('Escudo e Notas').first);
      await tester.pumpAndSettle();

      // Verifica as abas do Escudo
      expect(find.text('Condições'), findsOneWidget);
      expect(find.text('Perigos'), findsOneWidget);
      expect(find.text('Nomes'), findsOneWidget);
      expect(find.text('Regras de Combate'), findsOneWidget);
      expect(find.text('Notas da Sessão'), findsOneWidget);

      // Volta para Mapas e clica no mapa para abrir a Mesa de Jogo (Parte 4)
      await tester.tap(find.text('Mapas').first);
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Ruínas da Estrada').first);
      await tester.pumpAndSettle();

      // Verifica elementos da Mesa de Jogo (Parte 4)
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
      cubit.simularPedidoEntradaJogadorLan(
        nomeJogador: 'Beatriz',
        nomePersonagem: 'Kallista',
        classeResumo: 'Clériga Nv 2',
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
}
