import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../../entities/mestre/modelos_mestre.dart';
import '../../entities/entidade_sessao_lan/sessao_lan_modelos.dart';
import 'sessao_lan_transport.dart';

class SessaoHostLanService implements SessaoHostService {
  static const int portaDescobertaUdp = 45455;
  static const int maxBytesMensagem = 262144; // 256 KB

  final _solicitacoesCtrl =
      StreamController<SolicitacaoEntradaSessao>.broadcast();
  final _atualizacoesCtrl =
      StreamController<AtualizacaoPersonagemSessao>.broadcast();
  final _acoesMapaCtrl = StreamController<Map<String, dynamic>>.broadcast();

  HttpServer? _httpServer;
  RawDatagramSocket? _udpSocket;
  Timer? _anuncioTimer;
  String? _codigoSalaAtivo;
  SnapshotMesa? _ultimoSnapshot;

  // characterId -> WebSocket conectado (garante que cada cliente só receba/altere o seu)
  final Map<String, WebSocket> _clientesPorCharId = {};
  final Map<WebSocket, String> _charIdPorSocket = {};

  @override
  Stream<SolicitacaoEntradaSessao> get solicitacoesEntrada =>
      _solicitacoesCtrl.stream;

  @override
  Stream<AtualizacaoPersonagemSessao> get atualizacoesPersonagem =>
      _atualizacoesCtrl.stream;

  @override
  Stream<Map<String, dynamic>> get acoesMapa => _acoesMapaCtrl.stream;

  int? get portaAtiva => _httpServer?.port;

  @override
  Future<void> iniciar({
    required String ip,
    required int porta,
    required String codigoSala,
  }) async {
    await encerrar();
    _codigoSalaAtivo = codigoSala.trim().toUpperCase();

    _httpServer = await HttpServer.bind(InternetAddress.anyIPv4, porta);
    _httpServer!.listen((HttpRequest req) async {
      if (!WebSocketTransformer.isUpgradeRequest(req)) {
        req.response
          ..statusCode = HttpStatus.badRequest
          ..close();
        return;
      }
      final socket = await WebSocketTransformer.upgrade(req);
      _escutarCliente(socket);
    });

    // Anúncio UDP na LAN para descoberta automática pelo código da sala
    _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    _udpSocket!.broadcastEnabled = true;
    final anuncioBytes = utf8.encode(
      jsonEncode({
        'app': 't20_creator',
        'codigoSala': _codigoSalaAtivo,
        'ip': ip,
        'porta': _httpServer!.port,
      }),
    );

    _anuncioTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      try {
        _udpSocket?.send(
          anuncioBytes,
          InternetAddress('255.255.255.255'),
          portaDescobertaUdp,
        );
      } catch (_) {}
    });
  }

  void _escutarCliente(WebSocket socket) {
    socket.listen(
      (raw) {
        if (raw is! String || raw.length > maxBytesMensagem) return;
        try {
          final msg = jsonDecode(raw);
          if (msg is! Map) return;
          final tipo = msg['tipo']?.toString();
          final payload = msg['payload'];
          if (payload is! Map) return;
          final mapa = Map<String, dynamic>.from(payload);

          if (tipo == 'join') {
            final sol = SolicitacaoEntradaSessao.fromJson(mapa);
            if (sol.codigoSala.trim().toUpperCase() != _codigoSalaAtivo) {
              _enviar(
                socket,
                'evento',
                EventoSessaoCliente(
                  estado: EstadoConexaoJogador.erro,
                  tipo: TipoEventoSessaoCliente.erro,
                  codigoSala: sol.codigoSala,
                  mensagem: 'Código da sessão inválido.',
                ).toJson(),
              );
              return;
            }
            _clientesPorCharId[sol.characterId] = socket;
            _charIdPorSocket[socket] = sol.characterId;
            _solicitacoesCtrl.add(sol);
            _enviar(
              socket,
              'evento',
              EventoSessaoCliente(
                estado: EstadoConexaoJogador.aguardandoAprovacao,
                tipo: TipoEventoSessaoCliente.estadoAlterado,
                codigoSala: _codigoSalaAtivo,
                characterId: sol.characterId,
              ).toJson(),
            );
          } else if (tipo == 'atualizacao_personagem') {
            final dto = AtualizacaoPersonagemSessao.fromJson(mapa);
            // Segurança: só aceita atualização do próprio characterId autenticado no socket
            if (_charIdPorSocket[socket] != dto.characterId) return;
            _atualizacoesCtrl.add(dto);
          } else if (tipo == 'acao_mapa') {
            final characterId = mapa['characterId']?.toString();
            // Segurança: jogador só pode mover/agir com o próprio personagem
            if (characterId == null || _charIdPorSocket[socket] != characterId) {
              return;
            }
            _acoesMapaCtrl.add(mapa);
          }
        } catch (_) {
          // Ignora JSON malformado sem derrubar o host
        }
      },
      onDone: () {
        final charId = _charIdPorSocket.remove(socket);
        if (charId != null && _clientesPorCharId[charId] == socket) {
          _clientesPorCharId.remove(charId);
        }
      },
      onError: (_) {},
    );
  }

  void _enviar(WebSocket socket, String tipo, Map<String, dynamic> payload) {
    if (socket.readyState != WebSocket.open) return;
    socket.add(jsonEncode({'tipo': tipo, 'payload': payload}));
  }

  @override
  Future<void> notificarRevisaoFicha(
    String characterId,
    StatusRevisaoFicha status, {
    String? notaRevisao,
  }) async {
    final socket = _clientesPorCharId[characterId];
    if (socket == null) return;

    final evento = switch (status) {
      StatusRevisaoFicha.aprovada => EventoSessaoCliente(
        estado: EstadoConexaoJogador.conectado,
        tipo: TipoEventoSessaoCliente.aprovada,
        codigoSala: _codigoSalaAtivo,
        characterId: characterId,
        mensagem: notaRevisao,
      ),
      StatusRevisaoFicha.pendente ||
      StatusRevisaoFicha.desatualizada => EventoSessaoCliente(
        estado: EstadoConexaoJogador.aguardandoAprovacao,
        tipo: TipoEventoSessaoCliente.estadoAlterado,
        codigoSala: _codigoSalaAtivo,
        characterId: characterId,
      ),
      StatusRevisaoFicha.alteracoesSolicitadas ||
      StatusRevisaoFicha.recusada => EventoSessaoCliente(
        estado: EstadoConexaoJogador.erro,
        tipo: TipoEventoSessaoCliente.recusada,
        codigoSala: _codigoSalaAtivo,
        characterId: characterId,
        mensagem: notaRevisao ?? 'Entrada recusada pelo Mestre.',
      ),
    };

    _enviar(socket, 'evento', evento.toJson());
    if (status == StatusRevisaoFicha.aprovada && _ultimoSnapshot != null) {
      _enviar(socket, 'snapshot_mesa', _ultimoSnapshot!.toJson());
    }
  }

  @override
  Future<void> publicarSnapshotMesa(SnapshotMesa snapshot) async {
    _ultimoSnapshot = snapshot;
    for (final socket in _clientesPorCharId.values) {
      _enviar(socket, 'snapshot_mesa', snapshot.toJson());
    }
  }

  @override
  Future<void> encerrar() async {
    _anuncioTimer?.cancel();
    _anuncioTimer = null;
    _udpSocket?.close();
    _udpSocket = null;

    final socketsAtivos = List<WebSocket>.from(_clientesPorCharId.values);
    _clientesPorCharId.clear();
    _charIdPorSocket.clear();

    for (final s in socketsAtivos) {
      _enviar(
        s,
        'evento',
        const EventoSessaoCliente(
          estado: EstadoConexaoJogador.desconectado,
          tipo: TipoEventoSessaoCliente.desconectado,
          mensagem: 'O Mestre encerrou a sala.',
        ).toJson(),
      );
      await s.close();
    }
    await _httpServer?.close(force: true);
    _httpServer = null;
    _codigoSalaAtivo = null;
  }

  @override
  Future<void> dispose() async {
    await encerrar();
    await _solicitacoesCtrl.close();
    await _atualizacoesCtrl.close();
    await _acoesMapaCtrl.close();
  }
}
