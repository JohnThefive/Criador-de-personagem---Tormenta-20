import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:t20_creator/presentation/screens/ficha/ficha_screen.dart';
import 'package:t20_creator/presentation/screens/ficha/widgets/aba_sessao_view.dart';

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

Personagem _personagemTeste() {
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
    id: 'char_b_1',
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

  group('Etapa B — Aba Sessão na FichaScreen e AbaSessaoView', () {
    testWidgets('FichaScreen exibe 7ª aba Sessão após Notas e sincroniza PV ao atualizar ficha', (tester) async {
      final transport = SessaoLoopbackTransport();
      addTearDown(transport.dispose);

      final mestre = MestreCubit(
        autoPersistir: false,
        sessaoHostService: transport.host,
      );
      addTearDown(mestre.close);
      mestre.alternarServidorLan();
      await tester.pump();
      final codigoSala = mestre.state.sessaoAtual!.codigoSalaLan;

      await tester.pumpWidget(
        MaterialApp(
          home: FichaScreen(
            personagemInicial: _personagemTeste(),
            repository: _RepoMemoria(),
            sessaoClienteService: transport.cliente,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifica ordem das abas: Notas seguida de Sessão
      expect(find.text('Notas'), findsOneWidget);
      expect(find.text('Sessão'), findsOneWidget);

      await tester.ensureVisible(find.text('Sessão'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sessão'));
      await tester.pumpAndSettle();

      expect(find.text('Entrar na Sessão do Mestre'), findsOneWidget);
      expect(find.textContaining('Valeros • Guerreiro 5'), findsOneWidget);

      // Botão Conectar desabilitado inicialmente
      final btnConectar = tester.widget<FilledButton>(
        find.byKey(const Key('botao_conectar_mesa')),
      );
      expect(btnConectar.onPressed, isNull);

      await tester.enterText(
        find.byKey(const Key('campo_codigo_sessao')),
        codigoSala,
      );
      await tester.pump();

      await tester.ensureVisible(
        find.byKey(const Key('botao_conectar_mesa')),
      );
      await tester.tap(find.byKey(const Key('botao_conectar_mesa')));
      await tester.pumpAndSettle();

      expect(find.text('Aguardando aprovação do Mestre'), findsOneWidget);

      // Mestre aprova
      mestre.atualizarStatusRevisaoFicha(
        'char_b_1',
        StatusRevisaoFicha.aprovada,
      );
      await tester.pumpAndSettle();

      expect(find.text('Conectado na sessão $codigoSala'), findsOneWidget);
      expect(find.byKey(const Key('mini_mapa_aba_sessao')), findsOneWidget);
      expect(find.text('Abrir Mapa da Mesa'), findsOneWidget);

      // Jogador pode expandir o mini-mapa global e continuar vendo-o em outras abas (ex: Geral)
      await tester.tap(find.byKey(const Key('toggle_mini_mapa_ficha')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mini_mapa_global_ficha')), findsOneWidget);

      await tester.ensureVisible(find.text('Geral'));
      await tester.tap(find.text('Geral'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mini_mapa_global_ficha')), findsOneWidget);

      // Alteração de PV no FichaCubit dispara sincronização para o MestreCubit
      final ctxView = tester.element(find.byType(TabBarView));
      final fichaCubit = ctxView.read<FichaCubit>();
      await fichaCubit.atualizarPersonagem(
        fichaCubit.personagem.copyWith(pvAtual: 29),
        salvar: false,
      );
      await tester.pumpAndSettle();

      final elenco = mestre.state.sessaoAtual!.elenco.firstWhere(
        (e) => e.characterId == 'char_b_1',
      );
      expect(elenco.pvAtual, equals(29));
    });

    testWidgets('AbaSessaoView mostra erro amigável, conexão manual e confirmação ao desconectar', (tester) async {
      final transport = SessaoLoopbackTransport();
      addTearDown(transport.dispose);

      final mestre = MestreCubit(
        autoPersistir: false,
        sessaoHostService: transport.host,
      );
      addTearDown(mestre.close);

      final fichaCubit = FichaCubit(
        personagemInicial: _personagemTeste(),
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

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiBlocProvider(
              providers: [
                BlocProvider.value(value: fichaCubit),
                BlocProvider.value(value: sessaoCubit),
              ],
              child: const AbaSessaoView(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Abre seção avançada / manual
      await tester.tap(find.text('Conexão avançada / manual'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('campo_host_manual_sessao')),
        findsOneWidget,
      );

      // Tenta conectar sem sala aberta -> exibe erro
      await tester.enterText(
        find.byKey(const Key('campo_codigo_sessao')),
        '7492',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('botao_conectar_mesa')));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Nenhuma sala ativa encontrada'),
        findsOneWidget,
      );

      // Abre sala no Mestre e conecta
      mestre.alternarServidorLan();
      await tester.pump();
      final codigoSala = mestre.state.sessaoAtual!.codigoSalaLan;
      await tester.enterText(
        find.byKey(const Key('campo_codigo_sessao')),
        codigoSala,
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('botao_conectar_mesa')));
      await tester.pumpAndSettle();

      expect(find.text('Aguardando aprovação do Mestre'), findsOneWidget);

      // Desconectar pede confirmação
      await tester.tap(find.byKey(const Key('botao_desconectar_mesa')));
      await tester.pumpAndSettle();
      expect(find.text('Desconectar da mesa?'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Desconectar'));
      await tester.pumpAndSettle();

      expect(find.text('Entrar na Sessão do Mestre'), findsOneWidget);
    });

    testWidgets('Mestre inspeciona magias, inventário e notas do jogador e envia Nota do Mestre', (tester) async {
      final transport = SessaoLoopbackTransport();
      addTearDown(transport.dispose);

      final mestre = MestreCubit(
        autoPersistir: false,
        sessaoHostService: transport.host,
      );
      addTearDown(mestre.close);
      mestre.alternarServidorLan();
      await tester.pump();
      final codigoSala = mestre.state.sessaoAtual!.codigoSalaLan;

      final personagemRico = _personagemTeste().copyWith(
        magiasConhecidas: const ['Bola de Fogo'],
        itensInventario: const ['Corda de Cânhamo'],
        anotacoes: 'Procurar o artefato',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: FichaScreen(
            personagemInicial: personagemRico,
            repository: _RepoMemoria(),
            sessaoClienteService: transport.cliente,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Sessão'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sessão'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('campo_codigo_sessao')),
        codigoSala,
      );
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const Key('botao_conectar_mesa')),
      );
      await tester.tap(find.byKey(const Key('botao_conectar_mesa')));
      await tester.pumpAndSettle();

      mestre.atualizarStatusRevisaoFicha(
        'char_b_1',
        StatusRevisaoFicha.aprovada,
      );
      await tester.pumpAndSettle();

      // Snapshot no Mestre contém magias, inventário e anotações
      final snap = mestre.obterSnapshotFichaJogador('char_b_1')!;
      expect(snap['magiasConhecidas'], contains('Bola de Fogo'));
      expect(snap['itensInventario'], contains('Corda de Cânhamo'));
      expect(snap['anotacoes'], equals('Procurar o artefato'));

      // Mestre envia nota e jogador visualiza imediatamente na AbaSessaoView
      mestre.enviarNotaParaJogadorLan(
        'char_b_1',
        'Chave enferrujada encontrada!',
      );
      await tester.pumpAndSettle();

      expect(find.text('Nota do Mestre'), findsOneWidget);
      expect(find.text('Chave enferrujada encontrada!'), findsOneWidget);
    });
  });
}
