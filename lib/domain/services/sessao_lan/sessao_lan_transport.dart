import '../../entities/mestre/modelos_mestre.dart';
import '../../entities/entidade_sessao_lan/sessao_lan_modelos.dart';

/// Contrato abstrato de transporte para o cliente (Ficha do Jogador).
abstract class SessaoClienteService {
  Future<void> conectar(
    String codigoSala,
    SolicitacaoEntradaSessao solicitacao, {
    String? hostManual,
  });

  Future<void> desconectar();

  Stream<EventoSessaoCliente> get eventos;

  Stream<SnapshotMesa> get streamEstadoMesa;

  Future<void> enviarAtualizacaoPersonagem(AtualizacaoPersonagemSessao dto);

  Future<void> enviarAcaoMapa(Map<String, dynamic> acao);

  Future<void> dispose();
}

/// Contrato abstrato de transporte para o host (Painel do Mestre).
abstract class SessaoHostService {
  Future<void> iniciar({
    required String ip,
    required int porta,
    required String codigoSala,
  });

  Future<void> encerrar();

  Stream<SolicitacaoEntradaSessao> get solicitacoesEntrada;

  Stream<AtualizacaoPersonagemSessao> get atualizacoesPersonagem;

  Stream<Map<String, dynamic>> get acoesMapa;

  Future<void> notificarRevisaoFicha(
    String characterId,
    StatusRevisaoFicha status, {
    String? notaRevisao,
  });

  Future<void> publicarSnapshotMesa(SnapshotMesa snapshot);

  Future<void> dispose();
}
