import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:t20_creator/domain/entities/combate/grid_tatico.dart';
import 'package:t20_creator/domain/entities/mestre/modelos_mestre.dart';
import 'package:t20_creator/domain/entities/personagem/atributos.dart';
import 'package:t20_creator/domain/entities/personagem/classe.dart';
import 'package:t20_creator/domain/entities/personagem/classe_do_personagem.dart';
import 'package:t20_creator/domain/entities/personagem/personagem.dart';
import 'package:t20_creator/domain/entities/personagem/raca.dart';
import 'package:t20_creator/domain/entities/entidade_sessao_lan/sessao_lan_modelos.dart'
    show EstadoConexaoJogador;
import 'package:t20_creator/domain/repositories/i_personagem_repository.dart';
import 'package:t20_creator/domain/services/sessao_lan/sessao_cliente_lan_service.dart';
import 'package:t20_creator/domain/services/sessao_lan/sessao_host_lan_service.dart';
import 'package:t20_creator/domain/services/sessao_lan/sessao_loopback_transport.dart';
import 'package:t20_creator/presentation/controllers/ficha_controller/ficha_cubit.dart';
import 'package:t20_creator/presentation/controllers/ficha_controller/ficha_state.dart';
import 'package:t20_creator/presentation/controllers/ficha_controller/sessao_jogador_cubit.dart';
import 'package:t20_creator/presentation/controllers/mestre_controller/mestre_cubit.dart';
import 'package:t20_creator/presentation/screens/ficha/ficha_screen.dart';
import 'package:t20_creator/presentation/screens/ficha/widgets/mapa_jogador_screen.dart';
import 'package:t20_creator/presentation/screens/mestre/mestre_painel_screen.dart';

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

Personagem _heroiTeste() {
  const raca = Raca(
    id: 'humano',
    nome: 'Humano',
    descricaoRaca: 'Versátil',
    icone: 'person',
    modificadores: {},
  );
  const classe = Classe(
    idClasse: 'guerreiro',
    nome: 'Guerreiro',
    pvInicial: 20,
    pvPorNivel: 5,
    pmInicial: 3,
    pmPorNivel: 3,
    proficiencias: [],
    periciasFixas: ['Luta'],
    periciasOpcoes: ['Atletismo', 'Fortitude'],
    qtdPericiasEscolha: 2,
    descricaoclasse: 'Combatente',
  );

  return Personagem(
    id: 'char_lan_1',
    nome: 'Valeros',
    raca: raca,
    classes: [ClasseDoPersonagem(classeDefinicao: classe, nivel: 5)],
    atributos: const {
      'FOR': Atributo(nome: 'FOR', valor: 4),
      'DES': Atributo(nome: 'DES', valor: 2),
      'CON': Atributo(nome: 'CON', valor: 3),
      'INT': Atributo(nome: 'INT', valor: 1),
      'SAB': Atributo(nome: 'SAB', valor: 0),
      'CAR': Atributo(nome: 'CAR', valor: 1),
    },
    pvAtual: 42,
    pmAtual: 14,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Etapa C — Transporte WebSocket real e movimento na MapaJogadorScreen', () {
    test('SessaoHostLanService e SessaoClienteLanService sincronizam entrada, PV e movimento via WebSocket real', () async {
      final host = SessaoHostLanService();
      final cliente = SessaoClienteLanService();
      addTearDown(() async {
        await cliente.dispose();
        await host.dispose();
      });

      final mestre = MestreCubit(
        autoPersistir: false,
        sessaoHostService: host,
      );
      addTearDown(mestre.close);

      final codigoSala = mestre.state.sessaoAtual!.codigoSalaLan;
      // Inicia o host em porta efêmera (0) e liga statusLan no MestreCubit
      await host.iniciar(ip: '127.0.0.1', porta: 0, codigoSala: codigoSala);
      final portaReal = host.portaAtiva!;

      var fichaState = FichaState(personagem: _heroiTeste());
      final jogador = SessaoJogadorCubit(
        clienteService: cliente,
        lerFichaState: () => fichaState,
        autoCarregarPreferencias: false,
        autoPersistirPreferencias: false,
      );
      addTearDown(jogador.close);

      jogador.definirNomeJogador('João');
      jogador.definirCodigoSala(codigoSala);
      jogador.definirHostManual('127.0.0.1:$portaReal');
      await jogador.conectar();

      // Aguarda entrega do handshake join via WebSocket real
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(
        jogador.state.estadoConexao,
        equals(EstadoConexaoJogador.aguardandoAprovacao),
      );
      expect(
        mestre.state.sessaoAtual!.elenco.any(
          (e) =>
              e.characterId == 'char_lan_1' &&
              e.statusRevisao == StatusRevisaoFicha.pendente,
        ),
        isTrue,
      );

      // Mestre aprova -> cliente fica conectado
      mestre.atualizarStatusRevisaoFicha(
        'char_lan_1',
        StatusRevisaoFicha.aprovada,
      );
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(
        jogador.state.estadoConexao,
        equals(EstadoConexaoJogador.conectado),
      );

      // Jogador move o próprio token para célula livre (3, 3) via WebSocket real
      await jogador.moverMeuToken(const Posicao2D(3, 3));
      await Future<void>.delayed(const Duration(milliseconds: 120));

      final tokMovido = mestre.state.mapaAtual!.tokens.firstWhere(
        (t) => t.id == 'char_lan_1',
      );
      expect(tokMovido.posicao, equals(const Posicao2D(3, 3)));

      // Obstáculo (4, 3) do mapa inicial é bloqueado pelo Host
      await jogador.moverMeuToken(const Posicao2D(4, 3));
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(
        mestre.state.mapaAtual!.tokens
            .firstWhere((t) => t.id == 'char_lan_1')
            .posicao,
        equals(const Posicao2D(3, 3)),
      );

      // Segurança: tentar enviar acao_mapa para outro characterId não altera outro token
      await cliente.enviarAcaoMapa({
        'tipo': 'mover',
        'characterId': 'outro_personagem',
        'x': 9,
        'y': 9,
      });
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(
        mestre.state.mapaAtual!.tokens.any(
          (t) => t.posicao == const Posicao2D(9, 9),
        ),
        isFalse,
      );

      // Atualização de PV via WebSocket real
      fichaState = FichaState(
        personagem: _heroiTeste().copyWith(pvAtual: 18),
      );
      await jogador.sincronizarPersonagemAtual(fichaState);
      await Future<void>.delayed(const Duration(milliseconds: 120));

      final tokAtualizado = mestre.state.mapaAtual!.tokens.firstWhere(
        (t) => t.id == 'char_lan_1',
      );
      expect(tokAtualizado.pvAtual, equals(18));
    });

    testWidgets('MapaJogadorScreen permite selecionar o próprio token e movê-lo na grade', (tester) async {
      final transport = SessaoLoopbackTransport();
      addTearDown(transport.dispose);

      final mestre = MestreCubit(
        autoPersistir: false,
        sessaoHostService: transport.host,
      );
      addTearDown(mestre.close);
      mestre.alternarServidorLan();
      await tester.pump();

      final heroi = _heroiTeste();
      final fichaCubit = FichaCubit(
        personagemInicial: heroi,
        repository: _RepoMemoria(),
        debounceDuration: Duration.zero,
      );
      addTearDown(fichaCubit.close);

      final sessaoCubit = SessaoJogadorCubit(
        clienteService: transport.cliente,
        lerFichaState: () => fichaCubit.state,
        autoCarregarPreferencias: false,
        autoPersistirPreferencias: false,
      );
      addTearDown(sessaoCubit.close);

      sessaoCubit.definirCodigoSala(mestre.state.sessaoAtual!.codigoSalaLan);
      await sessaoCubit.conectar();
      await tester.pump();
      mestre.atualizarStatusRevisaoFicha(
        'char_lan_1',
        StatusRevisaoFicha.aprovada,
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider.value(value: fichaCubit),
              BlocProvider.value(value: sessaoCubit),
            ],
            child: const MapaJogadorScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Seleciona o próprio token ('V') e toca em uma célula do grid (ex: centro do grid)
      await tester.tap(find.text('V').first);
      await tester.pumpAndSettle();

      expect(
        find.text('Toque em uma célula revelada para mover seu personagem.'),
        findsOneWidget,
      );

      final gridBox = tester.getRect(find.byType(InteractiveViewer));
      await tester.tapAt(Offset(gridBox.left + 200, gridBox.top + 120));
      await tester.pumpAndSettle();

      final tokPos = mestre.state.mapaAtual!.tokens
          .firstWhere((t) => t.id == 'char_lan_1')
          .posicao;
      expect(tokPos, isNot(equals(const Posicao2D(1, 1))));
    });

    testWidgets('FichaScreen(usarTransporteLan: true) e MestrePainelScreen executam dispose sem erros', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FichaScreen(
            personagemInicial: _heroiTeste(),
            repository: _RepoMemoria(),
            usarTransporteLan: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        MaterialApp(
          home: MestrePainelScreen(
            cubit: MestreCubit(autoPersistir: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pumpAndSettle();
    });
  });
}
