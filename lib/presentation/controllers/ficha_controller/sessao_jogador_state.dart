import 'package:equatable/equatable.dart';
import '../../../domain/entities/entidade_sessao_lan/sessao_lan_modelos.dart';

class SessaoJogadorState extends Equatable {
  final EstadoConexaoJogador estadoConexao;
  final String codigoSala;
  final String hostManual;
  final String nomeJogador;
  final String? mensagemErro;
  final String? notaDoMestre;
  final SnapshotMesa? ultimoSnapshot;

  const SessaoJogadorState({
    this.estadoConexao = EstadoConexaoJogador.desconectado,
    this.codigoSala = '',
    this.hostManual = '',
    this.nomeJogador = '',
    this.mensagemErro,
    this.notaDoMestre,
    this.ultimoSnapshot,
  });

  bool get codigoValido => RegExp(r'^T20-\d{4}$').hasMatch(codigoSala);

  bool get estaConectado => estadoConexao == EstadoConexaoJogador.conectado;

  bool get podeEditarConexao =>
      estadoConexao == EstadoConexaoJogador.desconectado ||
      estadoConexao == EstadoConexaoJogador.erro;

  SessaoJogadorState copyWith({
    EstadoConexaoJogador? estadoConexao,
    String? codigoSala,
    String? hostManual,
    String? nomeJogador,
    String? mensagemErro,
    bool limparErro = false,
    String? notaDoMestre,
    bool limparNotaMestre = false,
    SnapshotMesa? ultimoSnapshot,
    bool limparSnapshot = false,
  }) {
    return SessaoJogadorState(
      estadoConexao: estadoConexao ?? this.estadoConexao,
      codigoSala: codigoSala ?? this.codigoSala,
      hostManual: hostManual ?? this.hostManual,
      nomeJogador: nomeJogador ?? this.nomeJogador,
      mensagemErro: limparErro ? null : (mensagemErro ?? this.mensagemErro),
      notaDoMestre: limparNotaMestre
          ? null
          : (notaDoMestre ?? this.notaDoMestre),
      ultimoSnapshot: limparSnapshot
          ? null
          : (ultimoSnapshot ?? this.ultimoSnapshot),
    );
  }

  @override
  List<Object?> get props => [
    estadoConexao,
    codigoSala,
    hostManual,
    nomeJogador,
    mensagemErro,
    notaDoMestre,
    ultimoSnapshot,
  ];
}
