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
  final _desconexoesCtrl = StreamController<String>.broadcast();

  HttpServer? _httpServer;
  RawDatagramSocket? _udpSocket;
  Timer? _anuncioTimer;
  String? _codigoSalaAtivo;
  SnapshotMesa? _ultimoSnapshot;

  // characterId -> WebSocket conectado (garante que cada cliente só receba/altere o seu)
  final Map<String, WebSocket> _clientesPorCharId = {};
  final Map<WebSocket, String> _charIdPorSocket = {};
  // Somente characterIds já aprovados pelo Mestre recebem snapshots da mesa e podem enviar ações.
  final Set<String> _clientesAprovados = {};

  @override
  Stream<SolicitacaoEntradaSessao> get solicitacoesEntrada =>
      _solicitacoesCtrl.stream;

  @override
  Stream<AtualizacaoPersonagemSessao> get atualizacoesPersonagem =>
      _atualizacoesCtrl.stream;

  @override
  Stream<Map<String, dynamic>> get acoesMapa => _acoesMapaCtrl.stream;

  @override
  Stream<String> get desconexoesCliente => _desconexoesCtrl.stream;

  int? get portaAtiva => _httpServer?.port;

  static bool _ehIpPrivadoPreferencial(String ip) {
    if (ip.startsWith('192.168.')) return true;
    if (ip.startsWith('172.')) {
      final partes = ip.split('.');
      if (partes.length == 4) {
        final segundo = int.tryParse(partes[1]) ?? 0;
        if (segundo >= 16 && segundo <= 31) return true;
      }
    }
    return false;
  }

  static bool _ehInterfaceCelularOuVpn(String nome) {
    final n = nome.toLowerCase();
    return n.startsWith('rmnet') ||
        n.startsWith('ccmni') ||
        n.startsWith('pdp') ||
        n.startsWith('tun') ||
        n.startsWith('tap') ||
        n.startsWith('ppp') ||
        n.startsWith('dummy') ||
        n.startsWith('clat') ||
        n.startsWith('v4-');
  }

  static bool _ehInterfaceWifiOuHotspot(String nome) {
    final n = nome.toLowerCase();
    return n.contains('wlan') ||
        n.startsWith('ap') ||
        n.contains('swlan') ||
        n.contains('wifi') ||
        n.contains('softap') ||
        n.startsWith('rndis') ||
        n.startsWith('eth') ||
        n.startsWith('en') ||
        n.startsWith('p2p');
  }

  /// Seleciona o melhor IPv4 de LAN dentre os candidatos `(nomeInterface, ip)`.
  /// Prioriza interfaces Wi-Fi/Hotspot (`wlan0`, `ap0`, etc.) e faixas `192.168.x.x` / `172.16-31.x.x`
  /// em vez de redes móveis (`rmnet`, `ccmni`) ou túneis VPN (`tun`).
  static String? selecionarMelhorIpLan(
    Iterable<({String interfaceName, String address})> candidatos,
  ) {
    String? melhorIp;
    int melhorScore = -999;

    for (final c in candidatos) {
      final ip = c.address.trim();
      if (ip.isEmpty || ip.startsWith('127.') || ip.startsWith('169.254.')) {
        continue;
      }
      int score = 0;
      if (_ehInterfaceCelularOuVpn(c.interfaceName)) {
        score -= 50;
      }
      if (_ehInterfaceWifiOuHotspot(c.interfaceName)) {
        score += 40;
      }
      if (_ehIpPrivadoPreferencial(ip)) {
        score += 30;
      } else if (ip.startsWith('10.')) {
        score += 10;
      }
      if (score > melhorScore) {
        melhorScore = score;
        melhorIp = ip;
      }
    }
    return melhorIp;
  }

  @override
  Future<String?> descobrirIpLocal() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      final candidatos = <({String interfaceName, String address})>[];
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) {
            candidatos.add((
              interfaceName: iface.name,
              address: addr.address,
            ));
          }
        }
      }
      return selecionarMelhorIpLan(candidatos);
    } catch (_) {}
    return null;
  }

  Future<List<InternetAddress>> _obterEnderecosBroadcast() async {
    final destinos = <String, InternetAddress>{
      '255.255.255.255': InternetAddress('255.255.255.255'),
    };
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (final iface in interfaces) {
        if (_ehInterfaceCelularOuVpn(iface.name)) continue;
        for (final addr in iface.addresses) {
          if (addr.isLoopback) continue;
          final partes = addr.address.split('.');
          if (partes.length == 4) {
            final bcast = '${partes[0]}.${partes[1]}.${partes[2]}.255';
            destinos[bcast] = InternetAddress(bcast);
          }
        }
      }
    } catch (_) {}
    return destinos.values.toList();
  }

  @override
  Future<void> iniciar({
    required String ip,
    required int porta,
    required String codigoSala,
  }) async {
    await encerrar();
    _codigoSalaAtivo = codigoSala.trim().toUpperCase();

    _httpServer = await HttpServer.bind(
      InternetAddress.anyIPv4,
      porta,
      shared: true,
    );
    _httpServer!.listen((HttpRequest req) async {
      if (!WebSocketTransformer.isUpgradeRequest(req)) {
        req.response
          ..statusCode = HttpStatus.badRequest
          ..close();
        return;
      }
      final ipRemoto = req.connectionInfo?.remoteAddress.address;
      final socket = await WebSocketTransformer.upgrade(req);
      socket.pingInterval = const Duration(seconds: 5);
      _escutarCliente(socket, ipRemoto: ipRemoto);
    });

    var ipReal = await descobrirIpLocal() ?? ip;
    var broadcasts = await _obterEnderecosBroadcast();

    // Anúncio UDP na LAN para descoberta automática pelo código da sala
    _udpSocket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      0,
      reuseAddress: true,
    );
    _udpSocket!.broadcastEnabled = true;

    List<int> gerarAnuncioBytes(String ipAtual) => utf8.encode(
      jsonEncode({
        'app': 't20_creator',
        'codigoSala': _codigoSalaAtivo,
        'ip': ipAtual,
        'porta': _httpServer!.port,
      }),
    );

    var anuncioBytes = gerarAnuncioBytes(ipReal);
    var ciclosDesdeReavaliacao = 0;
    var reavaliandoRede = false;

    void enviarAnuncio() {
      for (final destino in broadcasts) {
        try {
          _udpSocket?.send(anuncioBytes, destino, portaDescobertaUdp);
        } catch (_) {}
      }
    }

    enviarAnuncio();
    _anuncioTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      ciclosDesdeReavaliacao++;
      if (ciclosDesdeReavaliacao >= 5 && !reavaliandoRede) {
        ciclosDesdeReavaliacao = 0;
        reavaliandoRede = true;
        unawaited(() async {
          try {
            if (_httpServer == null || _codigoSalaAtivo == null) return;
            final novoIp = await descobrirIpLocal() ?? ipReal;
            final novosBroadcasts = await _obterEnderecosBroadcast();
            if (_httpServer == null || _codigoSalaAtivo == null) return;
            broadcasts = novosBroadcasts;
            if (novoIp != ipReal) {
              ipReal = novoIp;
              anuncioBytes = gerarAnuncioBytes(ipReal);
            }
          } catch (_) {
          } finally {
            reavaliandoRede = false;
          }
        }());
      }
      enviarAnuncio();
    });
  }

  void _escutarCliente(WebSocket socket, {String? ipRemoto}) {
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

            final socketAnterior = _clientesPorCharId[sol.characterId];
            if (socketAnterior != null && socketAnterior != socket) {
              _charIdPorSocket.remove(socketAnterior);
              unawaited(socketAnterior.close());
            }

            _clientesAprovados.remove(sol.characterId);
            _clientesPorCharId[sol.characterId] = socket;
            _charIdPorSocket[socket] = sol.characterId;
            _solicitacoesCtrl.add(
              sol.copyWith(ipRemoto: ipRemoto ?? sol.ipRemoto),
            );
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
            // Segurança: só aceita atualização do próprio characterId aprovado no socket
            if (_charIdPorSocket[socket] != dto.characterId ||
                !_clientesAprovados.contains(dto.characterId)) {
              return;
            }
            _atualizacoesCtrl.add(dto);
          } else if (tipo == 'acao_mapa') {
            final characterId = mapa['characterId']?.toString();
            // Segurança: jogador aprovado só pode mover/agir com o próprio personagem
            if (characterId == null ||
                _charIdPorSocket[socket] != characterId ||
                !_clientesAprovados.contains(characterId)) {
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
          _clientesAprovados.remove(charId);
          if (!_desconexoesCtrl.isClosed) {
            _desconexoesCtrl.add(charId);
          }
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

    if (status == StatusRevisaoFicha.aprovada) {
      _clientesAprovados.add(characterId);
    } else {
      _clientesAprovados.remove(characterId);
    }

    final evento = EventoSessaoCliente.deRevisaoFicha(
      status: status,
      characterId: characterId,
      codigoSala: _codigoSalaAtivo,
      notaRevisao: notaRevisao,
    );

    _enviar(socket, 'evento', evento.toJson());
    if (status == StatusRevisaoFicha.aprovada && _ultimoSnapshot != null) {
      _enviar(socket, 'snapshot_mesa', _ultimoSnapshot!.toJson());
    }
  }

  @override
  Future<void> publicarSnapshotMesa(SnapshotMesa snapshot) async {
    _ultimoSnapshot = snapshot;
    if (_clientesAprovados.isEmpty) return;
    final rawMsg = jsonEncode({
      'tipo': 'snapshot_mesa',
      'payload': snapshot.toJson(),
    });
    for (final charId in _clientesAprovados) {
      final socket = _clientesPorCharId[charId];
      if (socket != null && socket.readyState == WebSocket.open) {
        socket.add(rawMsg);
      }
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
    _clientesAprovados.clear();

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
    await _desconexoesCtrl.close();
  }
}
