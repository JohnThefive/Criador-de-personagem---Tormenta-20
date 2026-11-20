import 'dart:async';
import '../../entities/mestre/modelos_mestre.dart';
import '../../entities/entidade_sessao_lan/sessao_lan_modelos.dart';
import 'sessao_lan_transport.dart';

/// Transporte em memória (Loopback) ligando [SessaoClienteService] e [SessaoHostService]
/// no mesmo processo, permitindo validar o fluxo completo Ficha ↔ Mestre sem rede real.
class SessaoLoopbackTransport {
  final _eventosClienteCtrl = StreamController<EventoSessaoCliente>.broadcast();
  final _snapshotMesaCtrl = StreamController<SnapshotMesa>.broadcast();
  final _solicitacoesHostCtrl =
      StreamController<SolicitacaoEntradaSessao>.broadcast();
  final _atualizacoesHostCtrl =
      StreamController<AtualizacaoPersonagemSessao>.broadcast();
  final _acoesMapaHostCtrl =
      StreamController<Map<String, dynamic>>.broadcast();
  final _desconexoesHostCtrl = StreamController<String>.broadcast();

  bool _hostAtivo = false;
  String? _codigoSalaAtivo;
  String? _characterIdConectado;
  bool _clienteAprovado = false;
  SnapshotMesa? _ultimoSnapshotPublicado;
  bool _disposed = false;

  late final SessaoClienteService cliente = _LoopbackClienteService(this);
  late final SessaoHostService host = _LoopbackHostService(this);

  bool get hostAtivo => _hostAtivo;
  String? get codigoSalaAtivo => _codigoSalaAtivo;

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _eventosClienteCtrl.close();
    await _snapshotMesaCtrl.close();
    await _solicitacoesHostCtrl.close();
    await _atualizacoesHostCtrl.close();
    await _acoesMapaHostCtrl.close();
    await _desconexoesHostCtrl.close();
  }
}

class _LoopbackClienteService implements SessaoClienteService {
  final SessaoLoopbackTransport _bus;

  _LoopbackClienteService(this._bus);

  @override
  Stream<EventoSessaoCliente> get eventos => _bus._eventosClienteCtrl.stream;

  @override
  Stream<SnapshotMesa> get streamEstadoMesa => _bus._snapshotMesaCtrl.stream;

  @override
  Future<void> conectar(
    String codigoSala,
    SolicitacaoEntradaSessao solicitacao, {
    String? hostManual,
  }) async {
    if (_bus._disposed) return;
    final codigoNormalizado = codigoSala.trim().toUpperCase();

    _bus._eventosClienteCtrl.add(
      EventoSessaoCliente(
        estado: EstadoConexaoJogador.conectando,
        tipo: TipoEventoSessaoCliente.estadoAlterado,
        codigoSala: codigoNormalizado,
        characterId: solicitacao.characterId,
      ),
    );

    if (!_bus._hostAtivo || _bus._codigoSalaAtivo == null) {
      _bus._eventosClienteCtrl.add(
        EventoSessaoCliente(
          estado: EstadoConexaoJogador.erro,
          tipo: TipoEventoSessaoCliente.erro,
          codigoSala: codigoNormalizado,
          mensagem:
              'Nenhuma sala ativa encontrada para o código $codigoNormalizado.',
        ),
      );
      return;
    }

    if (_bus._codigoSalaAtivo != codigoNormalizado) {
      _bus._eventosClienteCtrl.add(
        EventoSessaoCliente(
          estado: EstadoConexaoJogador.erro,
          tipo: TipoEventoSessaoCliente.erro,
          codigoSala: codigoNormalizado,
          mensagem: 'Código da sessão inválido ($codigoNormalizado).',
        ),
      );
      return;
    }

    _bus._characterIdConectado = solicitacao.characterId;
    _bus._clienteAprovado = false;
    _bus._solicitacoesHostCtrl.add(
      solicitacao.copyWith(ipRemoto: solicitacao.ipRemoto ?? '127.0.0.1'),
    );
    _bus._eventosClienteCtrl.add(
      EventoSessaoCliente(
        estado: EstadoConexaoJogador.aguardandoAprovacao,
        tipo: TipoEventoSessaoCliente.estadoAlterado,
        codigoSala: codigoNormalizado,
        characterId: solicitacao.characterId,
      ),
    );
  }

  @override
  Future<void> desconectar() async {
    if (_bus._disposed) return;
    final charIdAnterior = _bus._characterIdConectado;
    _bus._characterIdConectado = null;
    _bus._clienteAprovado = false;
    if (charIdAnterior != null) {
      _bus._desconexoesHostCtrl.add(charIdAnterior);
    }
    _bus._eventosClienteCtrl.add(
      const EventoSessaoCliente(
        estado: EstadoConexaoJogador.desconectado,
        tipo: TipoEventoSessaoCliente.desconectado,
      ),
    );
  }

  @override
  Future<void> enviarAtualizacaoPersonagem(
    AtualizacaoPersonagemSessao dto,
  ) async {
    if (_bus._disposed || !_bus._hostAtivo || !_bus._clienteAprovado) return;
    _bus._atualizacoesHostCtrl.add(dto);
  }

  @override
  Future<void> enviarAcaoMapa(Map<String, dynamic> acao) async {
    if (_bus._disposed || !_bus._hostAtivo || !_bus._clienteAprovado) return;
    final charId = acao['characterId']?.toString();
    if (charId == null || _bus._characterIdConectado != charId) return;
    _bus._acoesMapaHostCtrl.add(Map<String, dynamic>.from(acao));
  }

  @override
  Future<void> dispose() async {}
}

class _LoopbackHostService implements SessaoHostService {
  final SessaoLoopbackTransport _bus;

  _LoopbackHostService(this._bus);

  @override
  Stream<SolicitacaoEntradaSessao> get solicitacoesEntrada =>
      _bus._solicitacoesHostCtrl.stream;

  @override
  Stream<AtualizacaoPersonagemSessao> get atualizacoesPersonagem =>
      _bus._atualizacoesHostCtrl.stream;

  @override
  Stream<Map<String, dynamic>> get acoesMapa => _bus._acoesMapaHostCtrl.stream;

  @override
  Stream<String> get desconexoesCliente => _bus._desconexoesHostCtrl.stream;

  @override
  Future<void> iniciar({
    required String ip,
    required int porta,
    required String codigoSala,
  }) async {
    if (_bus._disposed) return;
    _bus._hostAtivo = true;
    _bus._codigoSalaAtivo = codigoSala.trim().toUpperCase();
  }

  @override
  Future<void> encerrar() async {
    if (_bus._disposed) return;
    _bus._hostAtivo = false;
    _bus._codigoSalaAtivo = null;
    _bus._ultimoSnapshotPublicado = null;
    _bus._clienteAprovado = false;
    if (_bus._characterIdConectado != null) {
      _bus._characterIdConectado = null;
      _bus._eventosClienteCtrl.add(
        const EventoSessaoCliente(
          estado: EstadoConexaoJogador.desconectado,
          tipo: TipoEventoSessaoCliente.desconectado,
          mensagem: 'O Mestre encerrou a sala.',
        ),
      );
    }
  }

  @override
  Future<void> notificarRevisaoFicha(
    String characterId,
    StatusRevisaoFicha status, {
    String? notaRevisao,
  }) async {
    if (_bus._disposed || _bus._characterIdConectado != characterId) return;

    if (status == StatusRevisaoFicha.aprovada) {
      _bus._clienteAprovado = true;
    } else {
      _bus._clienteAprovado = false;
      if (status == StatusRevisaoFicha.alteracoesSolicitadas ||
          status == StatusRevisaoFicha.recusada) {
        _bus._characterIdConectado = null;
      }
    }

    _bus._eventosClienteCtrl.add(
      EventoSessaoCliente.deRevisaoFicha(
        status: status,
        characterId: characterId,
        codigoSala: _bus._codigoSalaAtivo,
        notaRevisao: notaRevisao,
      ),
    );

    if (status == StatusRevisaoFicha.aprovada &&
        _bus._ultimoSnapshotPublicado != null) {
      _bus._snapshotMesaCtrl.add(_bus._ultimoSnapshotPublicado!);
    }
  }

  @override
  Future<void> publicarSnapshotMesa(SnapshotMesa snapshot) async {
    if (_bus._disposed || !_bus._hostAtivo) return;
    _bus._ultimoSnapshotPublicado = snapshot;
    if (_bus._clienteAprovado) {
      _bus._snapshotMesaCtrl.add(snapshot);
    }
  }

  @override
  Future<String?> descobrirIpLocal() async => '127.0.0.1';

  @override
  Future<void> dispose() async {}
}
