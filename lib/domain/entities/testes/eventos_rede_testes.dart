import 'dart:convert';

import 'package:t20_creator/domain/entities/testes/configuracoes_mesa_t20.dart';
import 'package:t20_creator/domain/entities/testes/modelos_teste_t20.dart';
import 'package:t20_creator/domain/entities/habilidades/modelos_resistencia_efeito.dart';

/// Tipos de eventos de rede trocados via LAN entre Mestre (Host) e Jogadores (Clientes).
enum TipoEventoRedeTeste {
  // Mestre -> Jogadores (Módulo 1: Testes)
  mestrePedidoTeste,
  mestreRespostaAjuda,
  mestreResultadoTeste,
  mestreConfrontoResolvido,
  mestreEstendidoAtualizado,
  mestreConfiguracoesMesa,
  mestreSnapshotReconexao,

  // Jogador -> Mestre (Módulo 1: Testes)
  jogadorSolicitarAjuda,
  jogadorExecutarTeste,
  jogadorExecutarPassoEstendido,
  jogadorSolicitarReconexao,

  // Módulo 2: Habilidades e Duração (Intenções e Eventos de Rede)
  usarHabilidadeIntent,
  gatilhoDisponivel,
  resultadoAtivacao,
  pmAtualizado,
  testeDeclarado,
  efeitoAtivado,
  efeitoAtualizado,
  efeitoEncerrado,
  sustentacaoPendente,
  sustentacaoResolvida,
  cenaIniciada,
  cenaEncerrada,
  tempoAvancado,
  alvoEntrouNaArea,
  alvoSaiuDaArea,
  descargaDisparada,
  encerrarEfeitoIntent,
  eventoDeJogo,

  // Módulo 3: Resistência, Objetos e Tipos de Efeito (R50–R58)
  testeResistenciaSolicitado,
  resistenciaResolvida,
  avisarAliadosIntent,
  confirmarAvisoAliados,
}

/// Envelope padronizado JSON para tráfego de eventos do Motor de Testes na LAN.
class EnvelopeEventoRedeTeste {
  final String eventoId;
  final TipoEventoRedeTeste tipo;
  final String remetenteId;
  final String? destinatarioId; // null = broadcast para a mesa
  final String timestampIso;
  final Map<String, dynamic> payload;

  const EnvelopeEventoRedeTeste({
    required this.eventoId,
    required this.tipo,
    required this.remetenteId,
    this.destinatarioId,
    required this.timestampIso,
    required this.payload,
  });

  Map<String, dynamic> toJson() => {
        'eventoId': eventoId,
        'tipo': tipo.name,
        'remetenteId': remetenteId,
        'destinatarioId': destinatarioId,
        'timestampIso': timestampIso,
        'payload': payload,
      };

  String toJsonString() => jsonEncode(toJson());

  factory EnvelopeEventoRedeTeste.fromJson(Map<String, dynamic> json) {
    return EnvelopeEventoRedeTeste(
      eventoId: json['eventoId'] as String,
      tipo: TipoEventoRedeTeste.values.firstWhere(
        (e) => e.name == json['tipo'],
      ),
      remetenteId: json['remetenteId'] as String,
      destinatarioId: json['destinatarioId'] as String?,
      timestampIso: json['timestampIso'] as String,
      payload: Map<String, dynamic>.from(json['payload'] as Map),
    );
  }

  factory EnvelopeEventoRedeTeste.fromJsonString(String rawJson) {
    return EnvelopeEventoRedeTeste.fromJson(
      jsonDecode(rawJson) as Map<String, dynamic>,
    );
  }
}

/// Estado sincronizável da sessão de testes (usado no Host e reconstruído no Cliente ao reconectar).
class EstadoSessaoTestes {
  final ConfiguracoesMesaT20 configuracoes;
  final List<TesteRequest> pedidosAtivos;
  final TesteEstendido? testeEstendidoAtivo;
  final List<RollResult> logResultados;

  const EstadoSessaoTestes({
    this.configuracoes = const ConfiguracoesMesaT20(),
    this.pedidosAtivos = const [],
    this.testeEstendidoAtivo,
    this.logResultados = const [],
  });

  EstadoSessaoTestes copyWith({
    ConfiguracoesMesaT20? configuracoes,
    List<TesteRequest>? pedidosAtivos,
    TesteEstendido? testeEstendidoAtivo,
    bool limparTesteEstendido = false,
    List<RollResult>? logResultados,
  }) {
    return EstadoSessaoTestes(
      configuracoes: configuracoes ?? this.configuracoes,
      pedidosAtivos: pedidosAtivos ?? this.pedidosAtivos,
      testeEstendidoAtivo: limparTesteEstendido
          ? null
          : (testeEstendidoAtivo ?? this.testeEstendidoAtivo),
      logResultados: logResultados ?? this.logResultados,
    );
  }

  /// Gera o snapshot JSON para sincronização (Caso de Borda 12: cliente desconecta no meio
  /// de um teste estendido -> reconecta e recebe o estado exato atualizado).
  /// Quando `visaoMestre == false`, oculta os detalhes numéricos de rolagens secretas.
  Map<String, dynamic> toJson({bool visaoMestre = false}) => {
        'configuracoes': configuracoes.toJson(),
        'pedidosAtivos': pedidosAtivos.map((p) => p.toJson()).toList(),
        'testeEstendidoAtivo':
            testeEstendidoAtivo?.toJson(visaoMestre: visaoMestre),
        'logResultados': logResultados
            .map((r) => r.toJson(visaoMestre: visaoMestre))
            .toList(),
      };

  factory EstadoSessaoTestes.fromJson(Map<String, dynamic> json) {
    return EstadoSessaoTestes(
      configuracoes: json['configuracoes'] != null
          ? ConfiguracoesMesaT20.fromJson(
              json['configuracoes'] as Map<String, dynamic>,
            )
          : const ConfiguracoesMesaT20(),
      pedidosAtivos: (json['pedidosAtivos'] as List<dynamic>? ?? [])
          .map((e) => TesteRequest.fromJson(e as Map<String, dynamic>))
          .toList(),
      testeEstendidoAtivo: json['testeEstendidoAtivo'] != null
          ? TesteEstendido.fromJson(
              json['testeEstendidoAtivo'] as Map<String, dynamic>,
            )
          : null,
      logResultados: (json['logResultados'] as List<dynamic>? ?? [])
          .map((e) => RollResult.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Cria um [EnvelopeEventoRedeTeste] de snapshot de reconexão para um jogador específico.
  EnvelopeEventoRedeTeste criarEventoSnapshotReconexao({
    required String eventoId,
    required String jogadorId,
    required String timestampIso,
  }) {
    return EnvelopeEventoRedeTeste(
      eventoId: eventoId,
      tipo: TipoEventoRedeTeste.mestreSnapshotReconexao,
      remetenteId: 'MESTRE',
      destinatarioId: jogadorId,
      timestampIso: timestampIso,
      payload: toJson(visaoMestre: false),
    );
  }
}

/// Payload do evento [TipoEventoRedeTeste.testeResistenciaSolicitado]:
/// O Host solicita a um jogador que faça seu teste de resistência.
class TesteResistenciaSolicitadoPayload {
  final String solicitacaoId;
  final String alvoId;
  final String habilidadeId;
  final String nomeHabilidade;
  final TipoResistencia? tipoResistencia;
  final String? pericia;
  final int cd;
  final TipoResultadoResistencia resultadoEsperado;
  final bool ehMagia;

  const TesteResistenciaSolicitadoPayload({
    required this.solicitacaoId,
    required this.alvoId,
    required this.habilidadeId,
    required this.nomeHabilidade,
    this.tipoResistencia,
    this.pericia,
    required this.cd,
    required this.resultadoEsperado,
    this.ehMagia = false,
  });

  Map<String, dynamic> toJson() => {
        'solicitacaoId': solicitacaoId,
        'alvoId': alvoId,
        'habilidadeId': habilidadeId,
        'nomeHabilidade': nomeHabilidade,
        'tipoResistencia': tipoResistencia?.name,
        'pericia': pericia,
        'cd': cd,
        'resultadoEsperado': resultadoEsperado.name,
        'ehMagia': ehMagia,
      };

  factory TesteResistenciaSolicitadoPayload.fromJson(Map<String, dynamic> json) {
    return TesteResistenciaSolicitadoPayload(
      solicitacaoId: json['solicitacaoId'] as String,
      alvoId: json['alvoId'] as String,
      habilidadeId: json['habilidadeId'] as String,
      nomeHabilidade: json['nomeHabilidade'] as String,
      tipoResistencia: json['tipoResistencia'] != null
          ? TipoResistencia.values.firstWhere(
              (e) => e.name == json['tipoResistencia'],
              orElse: () => TipoResistencia.fortitude,
            )
          : null,
      pericia: json['pericia'] as String?,
      cd: json['cd'] as int,
      resultadoEsperado: TipoResultadoResistencia.values.firstWhere(
        (e) => e.name == json['resultadoEsperado'],
        orElse: () => TipoResultadoResistencia.anula,
      ),
      ehMagia: json['ehMagia'] as bool? ?? false,
    );
  }
}

/// Payload do evento [TipoEventoRedeTeste.resistenciaResolvida]:
/// Resultado do teste de resistência (d20, modificador, total e sucesso/falha).
class ResistenciaResolvidaPayload {
  final ResultadoResistencia resultado;
  final String habilidadeId;
  final String nomeHabilidade;

  const ResistenciaResolvidaPayload({
    required this.resultado,
    required this.habilidadeId,
    required this.nomeHabilidade,
  });

  Map<String, dynamic> toJson() => {
        'resultado': resultado.toJson(),
        'habilidadeId': habilidadeId,
        'nomeHabilidade': nomeHabilidade,
      };

  factory ResistenciaResolvidaPayload.fromJson(Map<String, dynamic> json) {
    return ResistenciaResolvidaPayload(
      resultado: ResultadoResistencia.fromJson(
        json['resultado'] as Map<String, dynamic>,
      ),
      habilidadeId: json['habilidadeId'] as String,
      nomeHabilidade: json['nomeHabilidade'] as String,
    );
  }
}

/// Payload da intenção [TipoEventoRedeTeste.avisarAliadosIntent]:
/// O jogador que desacreditou uma ilusão manifesta intenção de avisar aliados (ação livre).
class AvisarAliadosIntentPayload {
  final String avisadorId;
  final String efeitoIlusaoId;
  final List<String> aliadosAlvoIds;

  const AvisarAliadosIntentPayload({
    required this.avisadorId,
    required this.efeitoIlusaoId,
    required this.aliadosAlvoIds,
  });

  Map<String, dynamic> toJson() => {
        'avisadorId': avisadorId,
        'efeitoIlusaoId': efeitoIlusaoId,
        'aliadosAlvoIds': aliadosAlvoIds,
      };

  factory AvisarAliadosIntentPayload.fromJson(Map<String, dynamic> json) {
    return AvisarAliadosIntentPayload(
      avisadorId: json['avisadorId'] as String,
      efeitoIlusaoId: json['efeitoIlusaoId'] as String,
      aliadosAlvoIds: (json['aliadosAlvoIds'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
    );
  }
}

/// Payload do evento [TipoEventoRedeTeste.confirmarAvisoAliados]:
/// O Mestre confirma quais aliados foram de fato avisados.
class ConfirmarAvisoAliadosPayload {
  final String avisadorId;
  final String efeitoIlusaoId;
  final List<String> aliadosConfirmadosIds;

  const ConfirmarAvisoAliadosPayload({
    required this.avisadorId,
    required this.efeitoIlusaoId,
    required this.aliadosConfirmadosIds,
  });

  Map<String, dynamic> toJson() => {
        'avisadorId': avisadorId,
        'efeitoIlusaoId': efeitoIlusaoId,
        'aliadosConfirmadosIds': aliadosConfirmadosIds,
      };

  factory ConfirmarAvisoAliadosPayload.fromJson(Map<String, dynamic> json) {
    return ConfirmarAvisoAliadosPayload(
      avisadorId: json['avisadorId'] as String,
      efeitoIlusaoId: json['efeitoIlusaoId'] as String,
      aliadosConfirmadosIds:
          (json['aliadosConfirmadosIds'] as List<dynamic>? ?? [])
              .map((e) => e as String)
              .toList(),
    );
  }
}
