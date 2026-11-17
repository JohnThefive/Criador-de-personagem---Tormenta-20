import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/combate/grid_tatico.dart';
import '../../../domain/entities/entidade_sessao_lan/sessao_lan_modelos.dart';
import '../../../domain/services/sessao_lan/sessao_lan_transport.dart';
import '../../../domain/services/sessao_lan/sessao_preferencias_service.dart';
import 'ficha_state.dart';
import 'sessao_jogador_state.dart';

/// Gerencia o ciclo de conexão do Jogador à mesa LAN do Mestre sem acoplar
/// a entidade [Personagem] à camada de transporte.
class SessaoJogadorCubit extends Cubit<SessaoJogadorState> {
  static final RegExp regexCodigoValido = RegExp(r'^T20-\d{4}$');

  final SessaoClienteService _clienteService;
  final FichaState Function() _lerFichaState;
  final bool _autoPersistirPreferencias;
  final bool _disposeClienteAoFechar;

  StreamSubscription<EventoSessaoCliente>? _eventosSub;
  StreamSubscription<SnapshotMesa>? _snapshotSub;

  SessaoJogadorCubit({
    required SessaoClienteService clienteService,
    required FichaState Function() lerFichaState,
    bool autoCarregarPreferencias = true,
    bool autoPersistirPreferencias = true,
    bool disposeClienteAoFechar = false,
  }) : _clienteService = clienteService,
       _lerFichaState = lerFichaState,
       _autoPersistirPreferencias = autoPersistirPreferencias,
       _disposeClienteAoFechar = disposeClienteAoFechar,
       super(const SessaoJogadorState()) {
    _eventosSub = _clienteService.eventos.listen(_aoReceberEvento);
    _snapshotSub = _clienteService.streamEstadoMesa.listen(_aoReceberSnapshot);
    if (autoCarregarPreferencias) {
      carregarPreferencias();
    }
  }

  /// Normaliza entrada do usuário: uppercase e prefixo `T20-` automático quando
  /// informados 4 dígitos ou `T20XXXX` sem hífen.
  static String normalizarCodigoSala(String raw) {
    final limpo = raw.trim().toUpperCase().replaceAll(
      RegExp(r'[^A-Z0-9-]'),
      '',
    );
    if (limpo.isEmpty) return '';
    if (RegExp(r'^\d{4}$').hasMatch(limpo)) {
      return 'T20-$limpo';
    }
    if (RegExp(r'^T20\d{4}$').hasMatch(limpo)) {
      return 'T20-${limpo.substring(3)}';
    }
    return limpo;
  }

  static bool ehCodigoValido(String codigo) =>
      regexCodigoValido.hasMatch(normalizarCodigoSala(codigo));

  Future<void> carregarPreferencias() async {
    final prefs = await SessaoPreferenciasService.carregar();
    if (isClosed) return;
    emit(
      state.copyWith(
        nomeJogador: prefs.nomeJogador,
        codigoSala: normalizarCodigoSala(prefs.ultimoCodigoSala),
      ),
    );
  }

  void definirCodigoSala(String codigo) {
    final normalizado = normalizarCodigoSala(codigo);
    emit(
      state.copyWith(
        codigoSala: normalizado,
        limparErro: state.estadoConexao == EstadoConexaoJogador.erro,
        estadoConexao: state.estadoConexao == EstadoConexaoJogador.erro
            ? EstadoConexaoJogador.desconectado
            : null,
      ),
    );
  }

  void definirHostManual(String host) {
    emit(state.copyWith(hostManual: host.trim()));
  }

  void definirNomeJogador(String nome) {
    emit(state.copyWith(nomeJogador: nome));
  }

  Future<void> conectar() async {
    final codigoNormalizado = normalizarCodigoSala(state.codigoSala);
    if (!ehCodigoValido(codigoNormalizado)) {
      emit(
        state.copyWith(
          codigoSala: codigoNormalizado,
          estadoConexao: EstadoConexaoJogador.erro,
          mensagemErro: 'Informe um código válido no formato T20-0000.',
        ),
      );
      return;
    }

    if (_autoPersistirPreferencias && SessaoPreferenciasService.podePersistir) {
      unawaited(
        SessaoPreferenciasService.salvar(
          SessaoPreferencias(
            nomeJogador: state.nomeJogador.trim(),
            ultimoCodigoSala: codigoNormalizado,
          ),
        ),
      );
    }

    final solicitacao = SolicitacaoEntradaSessao.fromFichaState(
      _lerFichaState(),
      codigoSala: codigoNormalizado,
      nomeJogador: state.nomeJogador,
    );

    emit(
      state.copyWith(
        codigoSala: codigoNormalizado,
        estadoConexao: EstadoConexaoJogador.conectando,
        limparErro: true,
      ),
    );

    try {
      await _clienteService.conectar(
        codigoNormalizado,
        solicitacao,
        hostManual: state.hostManual.isEmpty ? null : state.hostManual,
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          estadoConexao: EstadoConexaoJogador.erro,
          mensagemErro: 'Não foi possível conectar: $e',
        ),
      );
    }
  }

  Future<void> desconectar() async {
    await _clienteService.desconectar();
    if (isClosed) return;
    emit(
      state.copyWith(
        estadoConexao: EstadoConexaoJogador.desconectado,
        limparErro: true,
        limparNotaMestre: true,
        limparSnapshot: true,
      ),
    );
  }

  Future<void> sincronizarPersonagemAtual(FichaState ficha) async {
    if (state.estadoConexao != EstadoConexaoJogador.conectado) return;
    await _clienteService.enviarAtualizacaoPersonagem(
      AtualizacaoPersonagemSessao.fromFichaState(ficha),
    );
  }

  /// Solicita movimentação apenas do próprio token na sessão conectada.
  Future<void> moverMeuToken(Posicao2D destino) async {
    if (state.estadoConexao != EstadoConexaoJogador.conectado) return;
    final charId = _lerFichaState().personagem.id;
    await _clienteService.enviarAcaoMapa({
      'tipo': 'mover',
      'characterId': charId,
      'x': destino.x,
      'y': destino.y,
    });
  }

  void _aoReceberEvento(EventoSessaoCliente evento) {
    if (isClosed) return;
    final limparTudo =
        evento.estado == EstadoConexaoJogador.desconectado ||
        evento.estado == EstadoConexaoJogador.erro;
    final msg = evento.mensagem?.trim();
    final novaNota =
        evento.estado == EstadoConexaoJogador.conectado &&
            msg != null &&
            msg.isNotEmpty
        ? msg
        : null;

    emit(
      state.copyWith(
        estadoConexao: evento.estado,
        codigoSala: evento.codigoSala ?? state.codigoSala,
        mensagemErro: evento.estado == EstadoConexaoJogador.erro
            ? evento.mensagem
            : null,
        limparErro: evento.estado != EstadoConexaoJogador.erro,
        notaDoMestre: novaNota,
        limparNotaMestre: limparTudo,
        limparSnapshot: limparTudo,
      ),
    );
  }

  void _aoReceberSnapshot(SnapshotMesa snapshot) {
    if (isClosed) return;
    emit(state.copyWith(ultimoSnapshot: snapshot));
  }

  @override
  Future<void> close() async {
    await _eventosSub?.cancel();
    await _snapshotSub?.cancel();
    if (_disposeClienteAoFechar) {
      await _clienteService.dispose();
    }
    return super.close();
  }
}
