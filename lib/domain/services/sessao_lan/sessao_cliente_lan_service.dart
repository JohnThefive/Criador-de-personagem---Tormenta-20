import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../../entities/entidade_sessao_lan/sessao_lan_modelos.dart';
import 'sessao_lan_transport.dart';

class SessaoClienteLanService implements SessaoClienteService {
  static const int portaDescobertaUdp = 45455;
  static const int portaPadraoHost = 7777;
  static const int maxBytesMensagem = 262144; // 256 KB
  static const Duration timeoutConexao = Duration(seconds: 10);

  final _eventosCtrl = StreamController<EventoSessaoCliente>.broadcast();
  final _snapshotCtrl = StreamController<SnapshotMesa>.broadcast();

  WebSocket? _socket;
  StreamSubscription<dynamic>? _socketSub;
  bool _desconectadoIntencionalmente = false;
  bool _disposed = false;

  String? _ultimoCodigo;
  SolicitacaoEntradaSessao? _ultimaSolicitacao;
  String? _ultimoHostManual;
  int _tentativasReconexao = 0;
  Timer? _timerReconexao;

  @override
  Stream<EventoSessaoCliente> get eventos => _eventosCtrl.stream;

  @override
  Stream<SnapshotMesa> get streamEstadoMesa => _snapshotCtrl.stream;

  @override
  Future<void> conectar(
    String codigoSala,
    SolicitacaoEntradaSessao solicitacao, {
    String? hostManual,
  }) async {
    _desconectadoIntencionalmente = false;
    _tentativasReconexao = 0;
    _timerReconexao?.cancel();

    final codigo = codigoSala.trim().toUpperCase();
    _ultimoCodigo = codigo;
    _ultimaSolicitacao = solicitacao;
    _ultimoHostManual = hostManual?.trim();

    await _conectarInterno(codigo, solicitacao, hostManual: _ultimoHostManual);
  }

  Future<void> _conectarInterno(
    String codigoSala,
    SolicitacaoEntradaSessao solicitacao, {
    String? hostManual,
  }) async {
    if (_disposed) return;

    _eventosCtrl.add(
      EventoSessaoCliente(
        estado: EstadoConexaoJogador.conectando,
        tipo: TipoEventoSessaoCliente.estadoAlterado,
        codigoSala: codigoSala,
        characterId: solicitacao.characterId,
      ),
    );

    try {
      final destino = (hostManual != null && hostManual.isNotEmpty)
          ? _parseHostManual(hostManual)
          : await _descobrirHostNaLan(codigoSala);

      if (destino == null) {
        _eventosCtrl.add(
          EventoSessaoCliente(
            estado: EstadoConexaoJogador.erro,
            tipo: TipoEventoSessaoCliente.erro,
            codigoSala: codigoSala,
            mensagem:
                'Sala $codigoSala não encontrada na rede Wi-Fi. Use "Conexão avançada" com o IP do Mestre.',
          ),
        );
        return;
      }

      final uri = 'ws://${destino.$1}:${destino.$2}';
      final socket = await WebSocket.connect(uri).timeout(timeoutConexao);

      await _socketSub?.cancel();
      await _socket?.close();
      _socket = socket;
      _tentativasReconexao = 0;

      _socketSub = socket.listen(
        _aoReceberMensagem,
        onDone: _aoFecharSocket,
        onError: (_) => _aoFecharSocket(),
      );

      // Envia pedido de entrada com dados da ficha
      _enviar('join', solicitacao.toJson());
    } catch (e) {
      if (_disposed) return;
      _eventosCtrl.add(
        EventoSessaoCliente(
          estado: EstadoConexaoJogador.erro,
          tipo: TipoEventoSessaoCliente.erro,
          codigoSala: codigoSala,
          mensagem: 'Falha ao conectar ao Mestre ($e).',
        ),
      );
    }
  }

  (String, int)? _parseHostManual(String raw) {
    final partes = raw.split(':');
    final ip = partes.first.trim();
    if (ip.isEmpty) return null;
    final porta = partes.length > 1
        ? (int.tryParse(partes[1].trim()) ?? portaPadraoHost)
        : portaPadraoHost;
    return (ip, porta);
  }

  Future<(String, int)?> _descobrirHostNaLan(String codigoSala) async {
    RawDatagramSocket? udp;
    final completer = Completer<(String, int)?>();

    try {
      udp = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        portaDescobertaUdp,
        reuseAddress: true,
      );
      udp.broadcastEnabled = true;

      final sub = udp.listen((event) {
        if (event != RawSocketEvent.read || completer.isCompleted) return;
        final dg = udp?.receive();
        if (dg == null) return;
        try {
          final json = jsonDecode(utf8.decode(dg.data));
          if (json is! Map) return;
          if (json['app'] != 't20_creator') return;
          if (json['codigoSala']?.toString().toUpperCase() != codigoSala) {
            return;
          }
          // Usa dg.address.address (IP real de quem enviou o pacote na LAN)
          final ipReal = dg.address.address;
          final porta = (json['porta'] as num?)?.toInt() ?? portaPadraoHost;
          completer.complete((ipReal, porta));
        } catch (_) {}
      });

      final resultado = await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => null,
      );
      await sub.cancel();
      return resultado;
    } catch (_) {
      return null;
    } finally {
      udp?.close();
    }
  }

  void _aoReceberMensagem(dynamic raw) {
    if (raw is! String || raw.length > maxBytesMensagem) return;
    try {
      final msg = jsonDecode(raw);
      if (msg is! Map) return;
      final tipo = msg['tipo']?.toString();
      final payload = msg['payload'];
      if (payload is! Map) return;
      final mapa = Map<String, dynamic>.from(payload);

      if (tipo == 'evento') {
        _eventosCtrl.add(EventoSessaoCliente.fromJson(mapa));
      } else if (tipo == 'snapshot_mesa') {
        _snapshotCtrl.add(SnapshotMesa.fromJson(mapa));
      }
    } catch (_) {
      // Ignora mensagem malformada
    }
  }

  void _aoFecharSocket() {
    if (_disposed || _desconectadoIntencionalmente) return;
    if (_tentativasReconexao >= 3 ||
        _ultimoCodigo == null ||
        _ultimaSolicitacao == null) {
      _eventosCtrl.add(
        const EventoSessaoCliente(
          estado: EstadoConexaoJogador.erro,
          tipo: TipoEventoSessaoCliente.erro,
          mensagem: 'Conexão com o Mestre perdida.',
        ),
      );
      return;
    }

    final esperaSegundos = 2 << _tentativasReconexao; // 2s, 4s, 8s
    _tentativasReconexao++;
    _timerReconexao?.cancel();
    _timerReconexao = Timer(Duration(seconds: esperaSegundos), () {
      _conectarInterno(
        _ultimoCodigo!,
        _ultimaSolicitacao!,
        hostManual: _ultimoHostManual,
      );
    });
  }

  void _enviar(String tipo, Map<String, dynamic> payload) {
    final socket = _socket;
    if (socket == null || socket.readyState != WebSocket.open) return;
    socket.add(jsonEncode({'tipo': tipo, 'payload': payload}));
  }

  @override
  Future<void> enviarAtualizacaoPersonagem(
    AtualizacaoPersonagemSessao dto,
  ) async {
    _enviar('atualizacao_personagem', dto.toJson());
  }

  @override
  Future<void> enviarAcaoMapa(Map<String, dynamic> acao) async {
    _enviar('acao_mapa', acao);
  }

  @override
  Future<void> desconectar() async {
    _desconectadoIntencionalmente = true;
    _timerReconexao?.cancel();
    await _socketSub?.cancel();
    _socketSub = null;
    await _socket?.close();
    _socket = null;
    if (!_disposed) {
      _eventosCtrl.add(
        const EventoSessaoCliente(
          estado: EstadoConexaoJogador.desconectado,
          tipo: TipoEventoSessaoCliente.desconectado,
        ),
      );
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    await desconectar();
    _disposed = true;
    await _eventosCtrl.close();
    await _snapshotCtrl.close();
  }
}
