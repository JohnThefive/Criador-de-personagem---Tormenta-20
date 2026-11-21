import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:t20_creator/domain/entities/combate/grid_tatico.dart';
import 'package:t20_creator/domain/entities/entidade_sessao_lan/sessao_lan_modelos.dart';
import 'package:t20_creator/domain/entities/habilidades/modelos_habilidade_duracao.dart';
import 'package:t20_creator/domain/entities/mestre/modelos_mestre.dart';
import 'package:t20_creator/domain/entities/personagem/atributos.dart';
import 'package:t20_creator/domain/entities/personagem/classe.dart';
import 'package:t20_creator/domain/entities/personagem/classe_do_personagem.dart';
import 'package:t20_creator/domain/entities/personagem/personagem.dart';
import 'package:t20_creator/domain/entities/personagem/raca.dart';
import 'package:t20_creator/domain/repositories/i_personagem_repository.dart';
import 'package:t20_creator/domain/services/sessao_lan/sessao_loopback_transport.dart';
import 'package:t20_creator/presentation/controllers/ficha_controller/ficha_cubit.dart';
import 'package:t20_creator/presentation/controllers/ficha_controller/sessao_jogador_cubit.dart';
import 'package:t20_creator/presentation/controllers/mestre_controller/mestre_cubit.dart';
import 'package:t20_creator/presentation/screens/ficha/widgets/mapa_jogador_screen.dart';
import 'package:t20_creator/presentation/screens/mestre/widgets/tela_mesa_jogo.dart';

class _RepoMemoria implements IPersonagemRepository {
  @override
  Future<void> excluir(String id) async {}

  @override
  Future<Personagem?> obterPorId(String id) async => null;

  @override
  Future<List<Personagem>> obterTodos() async => const [];

  @override
  Future<void> salvar(Personagem p) async {}
}

Personagem _arcanistaTeste() {
  const raca = Raca(
    id: 'elfo',
    nome: 'Elfo',
    descricaoRaca: 'Místico',
    icone: 'person',
    modificadores: {},
  );
  const classe = Classe(
    idClasse: 'arcanista',
    nome: 'Arcanista',
    pvInicial: 8,
    pvPorNivel: 2,
    pmInicial: 6,
    pmPorNivel: 6,
    proficiencias: [],
    periciasFixas: ['Misticismo', 'Vontade'],
    periciasOpcoes: ['Iniciativa', 'Percepção'],
    qtdPericiasEscolha: 2,
    descricaoclasse: 'Conjurador arcano',
  );

  return Personagem(
    id: 'char_arcano_1',
    nome: 'Ezren',
    raca: raca,
    classes: [ClasseDoPersonagem(classeDefinicao: classe, nivel: 5)],
    atributos: const {
      'FOR': Atributo(nome: 'FOR', valor: 0),
      'DES': Atributo(nome: 'DES', valor: 2),
      'CON': Atributo(nome: 'CON', valor: 1),
      'INT': Atributo(nome: 'INT', valor: 4),
      'SAB': Atributo(nome: 'SAB', valor: 1),
      'CAR': Atributo(nome: 'CAR', valor: 0),
    },
    magiasConhecidas: const ['bola_de_fogo'],
    pvAtual: 20,
    pmAtual: 30,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Áreas de Efeito T20 e Magias na Mesa do Mestre & LAN', () {
    test(
      'SnapshotMesa.sanitizadoDeMapa filtra células da área de efeito pela Névoa de Guerra e faz round-trip JSON',
      () {
        final mapa = MapaBatalhaMestre(
          id: 'mapa_1',
          nome: 'Masmorra',
          largura: 10,
          altura: 10,
          celulasReveladas: {
            const Posicao2D(2, 2),
            const Posicao2D(2, 3),
          },
        );
        final area = AreaEfeitoAtivaLan(
          id: 'area_1',
          criadorId: 'char_arcano_1',
          rotulo: 'Raio 1,5m',
          tipo: TipoArea.esfera,
          tamanhoMetros: 1.5,
          centroVertice: const VerticeGrid(3, 3),
          celulasAfetadas: {
            const Posicao2D(2, 2),
            const Posicao2D(2, 3),
            const Posicao2D(3, 2), // Oculta na névoa!
            const Posicao2D(3, 3), // Oculta na névoa!
          },
        );

        final snapshot = SnapshotMesa.sanitizadoDeMapa(
          mapa,
          areasEfeito: [area],
        );

        expect(snapshot.areasEfeitoVisiveis, hasLength(1));
        expect(
          snapshot.areasEfeitoVisiveis.first.celulasAfetadas,
          equals({const Posicao2D(2, 2), const Posicao2D(2, 3)}),
        );
        expect(
          snapshot.areasEfeitoVisiveis.first.centroVertice,
          equals(const VerticeGrid(3, 3)),
        );

        final restaurado = SnapshotMesa.fromJson(snapshot.toJson());
        expect(restaurado.areasEfeitoVisiveis, hasLength(1));
        expect(
          restaurado.areasEfeitoVisiveis.first.rotulo,
          equals('Raio 1,5m'),
        );
        expect(
          restaurado.areasEfeitoVisiveis.first.centroVertice,
          equals(const VerticeGrid(3, 3)),
        );
        expect(
          restaurado.areasEfeitoVisiveis.first.celulasAfetadas,
          equals({const Posicao2D(2, 2), const Posicao2D(2, 3)}),
        );
      },
    );

    test(
      'MestreCubit projeta áreas T20 fiéis (Esfera com centro ◎ na interseção, Cone, Linha) e aplica dano em lote',
      () {
        final mestre = MestreCubit(autoPersistir: false);
        addTearDown(mestre.close);

        // Configura Esfera de 1,5m (ocupa 2x2 = 4 quadrados ao redor da interseção)
        mestre.configurarFerramentaAreaMestre(
          forma: TipoArea.esfera,
          tamanhoMetros: 1.5,
        );
        mestre.projetarAreaMestre(pontoAlvo: const Posicao2D(5, 5));

        expect(mestre.state.areasEfeitoAtivas, hasLength(1));
        final areaEsfera = mestre.state.areasEfeitoAtivas.first;
        expect(areaEsfera.tipo, equals(TipoArea.esfera));
        expect(areaEsfera.centroVertice, isNotNull);
        expect(areaEsfera.celulasAfetadas, hasLength(4));

        // Verifica tokens afetados e aplicação de dano em lote
        final tokensNoMapa = mestre.state.mapaAtual!.tokens;
        expect(tokensNoMapa, isNotEmpty);
        final tokenAlvo = tokensNoMapa.first;
        final pvAntes = tokenAlvo.pvAtual;

        // Projeta área diretamente sobre a posição do tokenAlvo
        mestre.projetarAreaMestre(pontoAlvo: tokenAlvo.posicao);
        final afetados = mestre.tokensAfetadosPelaArea();
        expect(afetados.any((t) => t.id == tokenAlvo.id), isTrue);

        mestre.aplicarDanoOuCuraEmLote(
          tokenIds: [tokenAlvo.id],
          valor: 7,
          motivo: 'Esfera de Fogo (2d6+1)',
        );

        final tokenDepois = mestre.state.mapaAtual!.tokens.firstWhere(
          (t) => t.id == tokenAlvo.id,
        );
        expect(
          tokenDepois.pvAtual,
          equals((pvAntes - 7).clamp(0, tokenAlvo.pvMax)),
        );

        mestre.limparAreasEfeito();
        expect(mestre.state.areasEfeitoAtivas, isEmpty);
      },
    );

    test(
      'Fluxo LAN Opção A: Jogador projeta área e lança magia (NdX + Mod), Mestre resolve Total / Metade / Ignorar em 1 toque',
      () async {
        final transport = SessaoLoopbackTransport();
        addTearDown(transport.dispose);

        final mestre = MestreCubit(
          autoPersistir: false,
          sessaoHostService: transport.host,
        );
        addTearDown(mestre.close);
        mestre.alternarServidorLan();
        await Future<void>.delayed(const Duration(milliseconds: 20));

        final arcanista = _arcanistaTeste();
        final fichaCubit = FichaCubit(
          personagemInicial: arcanista,
          repository: _RepoMemoria(),
          debounceDuration: Duration.zero,
        );
        addTearDown(fichaCubit.close);

        final sessaoJogador = SessaoJogadorCubit(
          clienteService: transport.cliente,
          lerFichaState: () => fichaCubit.state,
          autoCarregarPreferencias: false,
          autoPersistirPreferencias: false,
        );
        addTearDown(sessaoJogador.close);

        sessaoJogador.definirNomeJogador('João');
        sessaoJogador.definirCodigoSala(mestre.state.sessaoAtual!.codigoSalaLan);
        await sessaoJogador.conectar();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        mestre.atualizarStatusRevisaoFicha(
          arcanista.id,
          StatusRevisaoFicha.aprovada,
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Adiciona um segundo inimigo para testar resolução em 2 alvos (Total e Metade)
        mestre.adicionarTokenCustomizadoNoMapa(
          nome: 'Soldado Purista',
          ehHeroi: false,
          pvMax: 20,
          pmMax: 4,
          defesa: 15,
        );

        final inimigos = mestre.state.mapaAtual!.tokens
            .where((t) => t.id != arcanista.id)
            .take(2)
            .toList();
        expect(inimigos.length, greaterThanOrEqualTo(2));
        final alvo1 = inimigos[0];
        final alvo2 = inimigos[1];
        final pv1Antes = alvo1.pvAtual;
        final pv2Antes = alvo2.pvAtual;

        // 1. Jogador projeta a área no mapa e depois lança Bola de Fogo
        await sessaoJogador.projetarAreaNoMapa(
          tipo: TipoArea.esfera,
          tamanhoMetros: 6.0,
          pontoAlvo: const Posicao2D(2, 2),
          rotulo: 'Ezren • Bola de Fogo',
        );
        await sessaoJogador.enviarLancamentoMagiaLan(
          magiaNome: 'Bola de Fogo',
          custoPm: 3,
          expressaoDados: '6d6+4 = 20 [3, 4, 2, 3, 2, 2] + 4',
          valorRolado: 20,
          ehCura: false,
          alvosIds: [alvo1.id, alvo2.id],
          rotuloArea: 'ESFERA 6.0m',
        );
        await Future<void>.delayed(const Duration(milliseconds: 80));

        // A área aparece sincronizada no Mestre e no Snapshot LAN do Jogador
        expect(
          mestre.state.areasEfeitoAtivas.any((a) => a.criadorId == arcanista.id),
          isTrue,
        );
        expect(
          sessaoJogador.state.ultimoSnapshot!.areasEfeitoVisiveis,
          isNotEmpty,
        );

        // 2. O Mestre recebe o card pendente da Opção A com os 2 alvos
        final pendente = mestre.state.magiaLanPendente;
        expect(pendente, isNotNull);
        expect(pendente!.magiaNome, equals('Bola de Fogo'));
        expect(pendente.valorRolado, equals(20));
        expect(pendente.custoPm, equals(3));
        expect(pendente.alvosPendentesIds, containsAll([alvo1.id, alvo2.id]));

        // 3. Mestre ignora o próprio conjurador na borda da área, aplica "Total" (20) no alvo1 e "Metade" (10) no alvo2
        if (mestre.state.magiaLanPendente!.alvosPendentesIds.contains(arcanista.id)) {
          mestre.resolverAlvoMagiaLanPendente(
            tokenId: arcanista.id,
            aplicar: false,
          );
        }
        mestre.resolverAlvoMagiaLanPendente(
          tokenId: alvo1.id,
          aplicar: true,
          ehMetade: false,
        );
        expect(mestre.state.magiaLanPendente, isNotNull);
        expect(
          mestre.state.magiaLanPendente!.alvosPendentesIds,
          equals([alvo2.id]),
        );

        mestre.resolverAlvoMagiaLanPendente(
          tokenId: alvo2.id,
          aplicar: true,
          ehMetade: true,
        );

        // Como todos os alvos foram resolvidos, o card fecha automaticamente
        expect(mestre.state.magiaLanPendente, isNull);

        final alvo1Depois = mestre.state.mapaAtual!.tokens.firstWhere(
          (t) => t.id == alvo1.id,
        );
        final alvo2Depois = mestre.state.mapaAtual!.tokens.firstWhere(
          (t) => t.id == alvo2.id,
        );
        expect(
          alvo1Depois.pvAtual,
          equals((pv1Antes - 20).clamp(0, alvo1.pvMax)),
        );
        expect(
          alvo2Depois.pvAtual,
          equals((pv2Antes - 10).clamp(0, alvo2.pvMax)),
        );
      },
    );

    testWidgets(
      'MapaJogadorScreen exibe barra de Magia / Área T20 e TelaMesaJogo exibe card Opção A de resolução',
      (tester) async {
        final transport = SessaoLoopbackTransport();
        addTearDown(transport.dispose);

        final mestre = MestreCubit(
          autoPersistir: false,
          sessaoHostService: transport.host,
        );
        addTearDown(mestre.close);
        mestre.alternarServidorLan();
        await tester.pump();
        mestre.adicionarTokenCustomizadoNoMapa(
          nome: 'Soldado Purista',
          ehHeroi: false,
          pvMax: 20,
          pmMax: 4,
          defesa: 15,
        );

        final arcanista = _arcanistaTeste();
        final fichaCubit = FichaCubit(
          personagemInicial: arcanista,
          repository: _RepoMemoria(),
          debounceDuration: Duration.zero,
        );
        addTearDown(fichaCubit.close);

        final sessaoJogador = SessaoJogadorCubit(
          clienteService: transport.cliente,
          lerFichaState: () => fichaCubit.state,
          autoCarregarPreferencias: false,
          autoPersistirPreferencias: false,
        );
        addTearDown(sessaoJogador.close);

        sessaoJogador.definirCodigoSala(mestre.state.sessaoAtual!.codigoSalaLan);
        await sessaoJogador.conectar();
        await tester.pump();
        mestre.atualizarStatusRevisaoFicha(
          arcanista.id,
          StatusRevisaoFicha.aprovada,
        );
        await tester.pumpAndSettle();

        await tester.pumpWidget(
          MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider.value(value: fichaCubit),
                BlocProvider.value(value: sessaoJogador),
              ],
              child: const MapaJogadorScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verifica que o botão "✨ Magia / Área T20" está visível na tela do jogador conectado
        expect(
          find.byKey(const Key('btn_toggle_modo_magia_lan_jogador')),
          findsOneWidget,
        );
        expect(find.text('✨ Magia / Área T20'), findsOneWidget);

        // Abre a gaveta de magia no mapa do jogador
        await tester.tap(
          find.byKey(const Key('btn_toggle_modo_magia_lan_jogador')),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('painel_magia_lan_jogador')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('btn_lancar_magia_lan_jogador')),
          findsOneWidget,
        );

        // Simula o lançamento afetando 2 inimigos para verificar o card Opção A na TelaMesaJogo do Mestre
        final inimigos = mestre.state.mapaAtual!.tokens
            .where((t) => t.id != arcanista.id)
            .take(2)
            .toList();
        await sessaoJogador.enviarLancamentoMagiaLan(
          magiaNome: 'Bola de Fogo',
          custoPm: 3,
          expressaoDados: '6d6+2 = 18',
          valorRolado: 18,
          ehCura: false,
          alvosIds: inimigos.map((t) => t.id).toList(),
          rotuloArea: 'ESFERA 6.0m',
        );
        await tester.pumpAndSettle();

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider.value(
              value: mestre,
              child: Scaffold(
                body: TelaMesaJogo(
                  cubit: mestre,
                  onVoltarBiblioteca: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // O card flutuante da Opção A deve aparecer na TelaMesaJogo do Mestre
        expect(
          find.byKey(const Key('card_magia_lan_pendente_mestre')),
          findsOneWidget,
        );
        expect(find.textContaining('Ezren lançou Bola de Fogo'), findsOneWidget);
        expect(
          find.byKey(const Key('btn_magia_lan_total_todos')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('btn_magia_lan_metade_todos')),
          findsOneWidget,
        );
      },
    );
  });
}
