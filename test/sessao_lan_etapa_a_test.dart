import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:t20_creator/domain/entities/combate/grid_tatico.dart';
import 'package:t20_creator/domain/entities/combate/monstro.dart';
import 'package:t20_creator/domain/entities/mestre/modelos_mestre.dart';
import 'package:t20_creator/domain/entities/personagem/atributos.dart';
import 'package:t20_creator/domain/entities/personagem/classe.dart';
import 'package:t20_creator/domain/entities/personagem/classe_do_personagem.dart';
import 'package:t20_creator/domain/entities/personagem/personagem.dart';
import 'package:t20_creator/domain/entities/personagem/raca.dart';
import 'package:t20_creator/domain/entities/entidade_sessao_lan/sessao_lan_modelos.dart';
import 'package:t20_creator/domain/services/sessao_lan/sessao_loopback_transport.dart';
import 'package:t20_creator/domain/services/sessao_lan/sessao_preferencias_service.dart';
import 'package:t20_creator/presentation/controllers/ficha_controller/ficha_state.dart';
import 'package:t20_creator/presentation/controllers/ficha_controller/sessao_jogador_cubit.dart';
import 'package:t20_creator/presentation/controllers/mestre_controller/mestre_cubit.dart';

Personagem _criarPersonagemTeste({int? pvAtual, int? pmAtual}) {
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
    id: 'char_valeros_1',
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
    pvAtual: pvAtual,
    pmAtual: pmAtual,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Etapa A — Contrato de dados, preferências e Loopback LAN', () {
    test('Normalização e validação do código da sala T20-XXXX', () {
      expect(
        SessaoJogadorCubit.normalizarCodigoSala('7492'),
        equals('T20-7492'),
      );
      expect(
        SessaoJogadorCubit.normalizarCodigoSala(' t201234 '),
        equals('T20-1234'),
      );
      expect(
        SessaoJogadorCubit.normalizarCodigoSala('t20-9999'),
        equals('T20-9999'),
      );

      expect(SessaoJogadorCubit.ehCodigoValido('7492'), isTrue);
      expect(SessaoJogadorCubit.ehCodigoValido('T20-7492'), isTrue);
      expect(SessaoJogadorCubit.ehCodigoValido('T20-123'), isFalse);
      expect(SessaoJogadorCubit.ehCodigoValido('ABC-1234'), isFalse);
    });

    test(
      'SolicitacaoEntradaSessao.fromFichaState, toJson/fromJson e toElencoEntry',
      () {
        final fichaState = FichaState(
          personagem: _criarPersonagemTeste(pvAtual: 40, pmAtual: 11),
        );

        final dto = SolicitacaoEntradaSessao.fromFichaState(
          fichaState,
          codigoSala: 'T20-7492',
          nomeJogador: 'João',
        );

        expect(dto.characterId, equals('char_valeros_1'));
        expect(dto.nomePersonagem, equals('Valeros'));
        expect(dto.nomeJogador, equals('João'));
        expect(dto.classeResumo, equals('Guerreiro 5'));
        expect(dto.pvAtual, equals(40));
        expect(dto.pvMax, equals(fichaState.personagem.pvTotal));
        expect(dto.pmAtual, equals(11));
        expect(dto.pmMax, equals(fichaState.personagem.pmTotal));
        expect(dto.defesa, equals(fichaState.personagem.defesaFinal));
        expect(dto.snapshotPersonagem, isNotNull);

        final roundTrip = SolicitacaoEntradaSessao.fromJson(dto.toJson());
        expect(roundTrip, equals(dto));

        final elenco = dto.toElencoEntry(ipJogador: '192.168.1.50');
        expect(elenco.characterId, equals('char_valeros_1'));
        expect(elenco.statusRevisao, equals(StatusRevisaoFicha.pendente));
        expect(elenco.conectadoViaLan, isTrue);
        expect(elenco.ipJogador, equals('192.168.1.50'));
      },
    );

    test(
      'SnapshotMesa.sanitizadoDeMapa omite tokens ocultos e ficha completa de monstro',
      () {
        final mapa = MapaBatalhaMestre(
          id: 'm1',
          nome: 'Masmorra',
          largura: 10,
          altura: 10,
          tokenTurnoAtualId: 'tok_oculto',
          tokens: const [
            TokenNoMapa(
              id: 'tok_visivel',
              nome: 'Goblin',
              posicao: Posicao2D(3, 3),
              visibilidade: ParaTodos(),
              monstro: Monstro(
                id: 'goblin',
                nome: 'Goblin',
                nd: '1/4',
                pvMax: 6,
                defesa: 13,
                iniciativa: 3,
                tesouro: 'Ouro Secreto',
              ),
            ),
            TokenNoMapa(
              id: 'tok_oculto',
              nome: 'Assassino Oculto',
              posicao: Posicao2D(5, 5),
              visibilidade: SomenteMestre(),
            ),
          ],
        );

        final snap = SnapshotMesa.sanitizadoDeMapa(mapa);
        expect(snap.tokensVisiveis.length, equals(1));
        expect(snap.tokensVisiveis.first.id, equals('tok_visivel'));
        expect(snap.tokensVisiveis.first.monstro, isNull);
        expect(snap.tokenTurnoAtualId, isNull);

        final roundTrip = SnapshotMesa.fromJson(snap.toJson());
        expect(roundTrip.toJson(), equals(snap.toJson()));
      },
    );

    test(
      'SessaoJogadorCubit valida código, persiste preferências e integra via Loopback com MestreCubit',
      () async {
        final dirTemp = await Directory.systemTemp.createTemp(
          't20_sessao_prefs_',
        );
        SessaoPreferenciasService.setDiretorioTeste(dirTemp);
        addTearDown(() async {
          SessaoPreferenciasService.setDiretorioTeste(null);
          if (await dirTemp.exists()) {
            await dirTemp.delete(recursive: true);
          }
        });

        final transport = SessaoLoopbackTransport();
        addTearDown(transport.dispose);

        final mestre = MestreCubit(
          autoPersistir: false,
          sessaoHostService: transport.host,
        );
        addTearDown(mestre.close);

        var fichaAtual = FichaState(
          personagem: _criarPersonagemTeste(pvAtual: 45, pmAtual: 12),
        );

        final jogador = SessaoJogadorCubit(
          clienteService: transport.cliente,
          lerFichaState: () => fichaAtual,
          autoCarregarPreferencias: false,
        );
        addTearDown(jogador.close);

        // Código inválido leva para estado erro
        jogador.definirCodigoSala('12');
        await jogador.conectar();
        expect(jogador.state.estadoConexao, equals(EstadoConexaoJogador.erro));

        // Mestre abre sala com o código padrão da sessão
        mestre.alternarServidorLan();
        await Future<void>.delayed(Duration.zero);
        final codigoSala = mestre.state.sessaoAtual!.codigoSalaLan;

        // Jogador informa apenas os 4 dígitos (normalizado para T20-XXXX) e conecta
        jogador.definirNomeJogador('João');
        jogador.definirCodigoSala(codigoSala.replaceFirst('T20-', ''));
        await jogador.conectar();
        await Future<void>.delayed(Duration.zero);

        expect(
          jogador.state.estadoConexao,
          equals(EstadoConexaoJogador.aguardandoAprovacao),
        );
        final entradaPendente = mestre.state.sessaoAtual!.elenco.firstWhere(
          (e) => e.characterId == 'char_valeros_1',
        );
        expect(
          entradaPendente.statusRevisao,
          equals(StatusRevisaoFicha.pendente),
        );
        expect(mestre.obterSnapshotFichaJogador('char_valeros_1'), isNotNull);

        // Preferências persistidas em disco
        await Future<void>.delayed(const Duration(milliseconds: 30));
        final prefsSalvas = await SessaoPreferenciasService.carregar();
        expect(prefsSalvas.nomeJogador, equals('João'));
        expect(prefsSalvas.ultimoCodigoSala, equals(codigoSala));

        // Mestre aprova ficha -> jogador fica conectado, herói entra no mapa e snapshot chega
        mestre.atualizarStatusRevisaoFicha(
          'char_valeros_1',
          StatusRevisaoFicha.aprovada,
        );
        await Future<void>.delayed(Duration.zero);

        expect(
          jogador.state.estadoConexao,
          equals(EstadoConexaoJogador.conectado),
        );
        expect(jogador.state.ultimoSnapshot, isNotNull);
        expect(
          jogador.state.ultimoSnapshot!.tokensVisiveis.any(
            (t) => t.id == 'char_valeros_1',
          ),
          isTrue,
        );

        // Atualização de PV na ficha chega ao Mestre e ao token no mapa
        fichaAtual = FichaState(
          personagem: _criarPersonagemTeste(pvAtual: 31, pmAtual: 9),
        );
        await jogador.sincronizarPersonagemAtual(fichaAtual);
        await Future<void>.delayed(Duration.zero);

        final elencoAtualizado = mestre.state.sessaoAtual!.elenco.firstWhere(
          (e) => e.characterId == 'char_valeros_1',
        );
        expect(elencoAtualizado.pvAtual, equals(31));
        expect(elencoAtualizado.pmAtual, equals(9));

        final tokenAtualizado = mestre.state.mapaAtual!.tokens.firstWhere(
          (t) => t.id == 'char_valeros_1',
        );
        expect(tokenAtualizado.pvAtual, equals(31));
        expect(tokenAtualizado.pmAtual, equals(9));

        // Desconectar volta ao estado desconectado e limpa snapshot
        await jogador.desconectar();
        await Future<void>.delayed(Duration.zero);
        expect(
          jogador.state.estadoConexao,
          equals(EstadoConexaoJogador.desconectado),
        );
        expect(jogador.state.ultimoSnapshot, isNull);
      },
    );
  });
}
