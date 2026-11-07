import 'package:t20_creator/domain/entities/testes/configuracoes_mesa_t20.dart';

/// R2: Tipos de teste básico.
enum TipoTeste {
  comum,
  oposto,
  misto,
}

/// R1: Fonte do modificador principal do teste.
enum ModoTeste {
  atributo,
  pericia,
}

/// R10–R12: Opções de testes sem rolagem ("Escolher").
enum OpcaoEscolher {
  nenhum,
  zero,
  dez,
  vinte,
}

/// R15: Modo de escolha de perícias em um Teste Estendido.
enum ModoTesteEstendido {
  fechado,
  aberto,
}

/// R21: Estado atual do Teste Estendido.
enum EstadoTesteEstendido {
  emAndamento,
  sucesso,
  falhaTotal,
  interrompido,
}

/// R29: Origem/categoria de um modificador para controle de acúmulo no ModificadorEngine.
enum FonteModificador {
  habilidade,
  pericia,
  item,
  magia,
  parceiro,
  ambiente,
  armadura,
  escudo,
  atributo,
  mestre,
  ajuda,
  ferramenta,
  penalidadeFalha,
}

/// R30: Máquina de estados do ciclo de vida de um teste.
enum FaseEstadoTeste {
  criado,
  modificadoresTravados,
  rolado,
  aguardandoDeclaracao,
  declarado,
}

/// R29: Modificador avaliado pelo [ModificadorEngine] (aplicado ou ignorado com justificativa).
class ModificadorAplicado {
  final FonteModificador fonteTipo;
  final String fonteId;
  final String? efeitoId;
  final String? alvoId;
  final String alvoCaracteristica;
  final int valor;
  final bool aplicado;
  final String? motivoIgnorado;

  /// R29: Quando `true` em um modificador de `ATRIBUTO`, substitui o atributo-chave original.
  final bool substituiAtributoBase;

  const ModificadorAplicado({
    required this.fonteTipo,
    required this.fonteId,
    this.efeitoId,
    this.alvoId,
    required this.alvoCaracteristica,
    required this.valor,
    this.aplicado = true,
    this.motivoIgnorado,
    this.substituiAtributoBase = false,
  });

  ModificadorAplicado copyWith({
    FonteModificador? fonteTipo,
    String? fonteId,
    String? efeitoId,
    String? alvoId,
    String? alvoCaracteristica,
    int? valor,
    bool? aplicado,
    String? motivoIgnorado,
    bool? substituiAtributoBase,
  }) {
    return ModificadorAplicado(
      fonteTipo: fonteTipo ?? this.fonteTipo,
      fonteId: fonteId ?? this.fonteId,
      efeitoId: efeitoId ?? this.efeitoId,
      alvoId: alvoId ?? this.alvoId,
      alvoCaracteristica: alvoCaracteristica ?? this.alvoCaracteristica,
      valor: valor ?? this.valor,
      aplicado: aplicado ?? this.aplicado,
      motivoIgnorado: motivoIgnorado ?? this.motivoIgnorado,
      substituiAtributoBase:
          substituiAtributoBase ?? this.substituiAtributoBase,
    );
  }

  Map<String, dynamic> toJson() => {
        'fonteTipo': fonteTipo.name,
        'fonteId': fonteId,
        'efeitoId': efeitoId,
        'alvoId': alvoId,
        'alvoCaracteristica': alvoCaracteristica,
        'valor': valor,
        'aplicado': aplicado,
        'motivoIgnorado': motivoIgnorado,
        'substituiAtributoBase': substituiAtributoBase,
      };

  factory ModificadorAplicado.fromJson(Map<String, dynamic> json) {
    return ModificadorAplicado(
      fonteTipo: FonteModificador.values.firstWhere(
        (e) => e.name == json['fonteTipo'],
        orElse: () => FonteModificador.habilidade,
      ),
      fonteId: json['fonteId'] as String? ?? '',
      efeitoId: json['efeitoId'] as String?,
      alvoId: json['alvoId'] as String?,
      alvoCaracteristica: json['alvoCaracteristica'] as String? ?? '',
      valor: json['valor'] as int? ?? 0,
      aplicado: json['aplicado'] as bool? ?? true,
      motivoIgnorado: json['motivoIgnorado'] as String?,
      substituiAtributoBase: json['substituiAtributoBase'] as bool? ?? false,
    );
  }
}

/// Exceção de domínio lançada quando uma ação viola as regras do Motor de Testes ou Habilidades.
class RegraTesteException implements Exception {
  final String codigo;
  final String mensagem;

  const RegraTesteException({
    required this.codigo,
    required this.mensagem,
  });

  @override
  String toString() => 'RegraTesteException($codigo): $mensagem';
}

/// Flags configuradas pelo mestre em um pedido de teste (`TesteRequest`).
class FlagsTeste {
  final bool semPressao;
  final bool semConsequencia;
  final bool semFerramenta;
  final bool semNovaTentativa;
  final bool secreto;
  final int maxAjudantes;
  final bool ajudantesPermitidos;

  const FlagsTeste({
    this.semPressao = false,
    this.semConsequencia = false,
    this.semFerramenta = false,
    this.semNovaTentativa = false,
    this.secreto = false,
    this.maxAjudantes = 0,
    this.ajudantesPermitidos = false,
  });

  FlagsTeste copyWith({
    bool? semPressao,
    bool? semConsequencia,
    bool? semFerramenta,
    bool? semNovaTentativa,
    bool? secreto,
    int? maxAjudantes,
    bool? ajudantesPermitidos,
  }) {
    return FlagsTeste(
      semPressao: semPressao ?? this.semPressao,
      semConsequencia: semConsequencia ?? this.semConsequencia,
      semFerramenta: semFerramenta ?? this.semFerramenta,
      semNovaTentativa: semNovaTentativa ?? this.semNovaTentativa,
      secreto: secreto ?? this.secreto,
      maxAjudantes: maxAjudantes ?? this.maxAjudantes,
      ajudantesPermitidos: ajudantesPermitidos ?? this.ajudantesPermitidos,
    );
  }

  Map<String, dynamic> toJson() => {
        'semPressao': semPressao,
        'semConsequencia': semConsequencia,
        'semFerramenta': semFerramenta,
        'semNovaTentativa': semNovaTentativa,
        'secreto': secreto,
        'maxAjudantes': maxAjudantes,
        'ajudantesPermitidos': ajudantesPermitidos,
      };

  factory FlagsTeste.fromJson(Map<String, dynamic> json) {
    return FlagsTeste(
      semPressao: json['semPressao'] as bool? ?? false,
      semConsequencia: json['semConsequencia'] as bool? ?? false,
      semFerramenta: json['semFerramenta'] as bool? ?? false,
      semNovaTentativa: json['semNovaTentativa'] as bool? ?? false,
      secreto: json['secreto'] as bool? ?? false,
      maxAjudantes: json['maxAjudantes'] as int? ?? 0,
      ajudantesPermitidos: json['ajudantesPermitidos'] as bool? ?? false,
    );
  }
}

/// Pedido de teste emitido pelo mestre.
class TesteRequest {
  final String id;
  final TipoTeste tipo;
  final int? cd;
  final List<String> participantes;
  final ModoTeste modo;
  final String? fonteEsperada;
  final int modificadoresMestre;
  final FlagsTeste flags;
  final String? consequenciaFalha;
  final bool emTesteEstendido;

  const TesteRequest({
    required this.id,
    required this.tipo,
    this.cd,
    required this.participantes,
    required this.modo,
    this.fonteEsperada,
    this.modificadoresMestre = 0,
    this.flags = const FlagsTeste(),
    this.consequenciaFalha,
    this.emTesteEstendido = false,
  });

  TesteRequest copyWith({
    String? id,
    TipoTeste? tipo,
    int? cd,
    List<String>? participantes,
    ModoTeste? modo,
    String? fonteEsperada,
    int? modificadoresMestre,
    FlagsTeste? flags,
    String? consequenciaFalha,
    bool? emTesteEstendido,
  }) {
    return TesteRequest(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      cd: cd ?? this.cd,
      participantes: participantes ?? this.participantes,
      modo: modo ?? this.modo,
      fonteEsperada: fonteEsperada ?? this.fonteEsperada,
      modificadoresMestre: modificadoresMestre ?? this.modificadoresMestre,
      flags: flags ?? this.flags,
      consequenciaFalha: consequenciaFalha ?? this.consequenciaFalha,
      emTesteEstendido: emTesteEstendido ?? this.emTesteEstendido,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tipo': tipo.name,
        'cd': cd,
        'participantes': participantes,
        'modo': modo.name,
        'fonteEsperada': fonteEsperada,
        'modificadoresMestre': modificadoresMestre,
        'flags': flags.toJson(),
        'consequenciaFalha': consequenciaFalha,
        'emTesteEstendido': emTesteEstendido,
      };

  factory TesteRequest.fromJson(Map<String, dynamic> json) {
    return TesteRequest(
      id: json['id'] as String,
      tipo: TipoTeste.values.firstWhere(
        (e) => e.name == json['tipo'],
        orElse: () => TipoTeste.comum,
      ),
      cd: json['cd'] as int?,
      participantes: (json['participantes'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      modo: ModoTeste.values.firstWhere(
        (e) => e.name == json['modo'],
        orElse: () => ModoTeste.pericia,
      ),
      fonteEsperada: json['fonteEsperada'] as String?,
      modificadoresMestre: json['modificadoresMestre'] as int? ?? 0,
      flags: json['flags'] != null
          ? FlagsTeste.fromJson(json['flags'] as Map<String, dynamic>)
          : const FlagsTeste(),
      consequenciaFalha: json['consequenciaFalha'] as String?,
      emTesteEstendido: json['emTesteEstendido'] as bool? ?? false,
    );
  }
}

/// R7–R9: Resultado do teste de um ajudante.
class AjudaResult {
  final String ajudanteId;
  final String pericia;
  final int d20;
  final int modificador;
  final int total;
  final int cdAjuda;
  final bool sucesso;
  final int bonusConcedido;

  const AjudaResult({
    required this.ajudanteId,
    required this.pericia,
    required this.d20,
    this.modificador = 0,
    required this.total,
    this.cdAjuda = 10,
    required this.sucesso,
    required this.bonusConcedido,
  });

  Map<String, dynamic> toJson() => {
        'ajudanteId': ajudanteId,
        'pericia': pericia,
        'd20': d20,
        'modificador': modificador,
        'total': total,
        'cdAjuda': cdAjuda,
        'sucesso': sucesso,
        'bonusConcedido': bonusConcedido,
      };

  factory AjudaResult.fromJson(Map<String, dynamic> json) {
    return AjudaResult(
      ajudanteId: json['ajudanteId'] as String,
      pericia: json['pericia'] as String,
      d20: json['d20'] as int,
      modificador: json['modificador'] as int? ?? 0,
      total: json['total'] as int,
      cdAjuda: json['cdAjuda'] as int? ?? 10,
      sucesso: json['sucesso'] as bool,
      bonusConcedido: json['bonusConcedido'] as int,
    );
  }
}

/// Resultado detalhado de uma rolagem/escolha em um teste.
///
/// Refatorado no Módulo 2: armazena o breakdown como `List<ModificadorAplicado>`,
/// produzida pelo `ModificadorEngine`, mantendo getters compatíveis com o Módulo 1.
class RollResult {
  final String testeId;
  final String personagemId;
  final int d20;
  final List<int> d20AnterioresRerolados;
  final String fonteMod;
  final List<ModificadorAplicado> modificadores;
  final int total;
  final int? cd;
  final bool nat20;
  final bool nat1;
  final OpcaoEscolher usouEscolher;
  final bool? sucessoCD;
  final bool secreto;
  final bool avisoTempoVinteX;
  final String? consequenciaTexto;

  RollResult({
    required this.testeId,
    required this.personagemId,
    required this.d20,
    this.d20AnterioresRerolados = const [],
    required this.fonteMod,
    List<ModificadorAplicado>? modificadores,
    int modBase = 0,
    int bonusMestre = 0,
    int penalFerramenta = 0,
    int bonusAjuda = 0,
    int penalidadeFalhaCumulativa = 0,
    required this.total,
    this.cd,
    this.nat20 = false,
    this.nat1 = false,
    this.usouEscolher = OpcaoEscolher.nenhum,
    this.sucessoCD,
    this.secreto = false,
    this.avisoTempoVinteX = false,
    this.consequenciaTexto,
  }) : modificadores = List.unmodifiable(
          modificadores ??
              _construirModificadoresPadrao(
                alvoId: personagemId,
                fonteMod: fonteMod,
                modBase: modBase,
                bonusMestre: bonusMestre,
                penalFerramenta: penalFerramenta,
                bonusAjuda: bonusAjuda,
                penalidadeFalhaCumulativa: penalidadeFalhaCumulativa,
              ),
        );

  static List<ModificadorAplicado> _construirModificadoresPadrao({
    required String alvoId,
    required String fonteMod,
    required int modBase,
    required int bonusMestre,
    required int penalFerramenta,
    required int bonusAjuda,
    required int penalidadeFalhaCumulativa,
  }) {
    final lista = <ModificadorAplicado>[
      ModificadorAplicado(
        fonteTipo: FonteModificador.pericia,
        fonteId: 'BASE_$fonteMod',
        alvoId: alvoId,
        alvoCaracteristica: fonteMod,
        valor: modBase,
        aplicado: true,
      ),
    ];
    if (bonusMestre != 0) {
      lista.add(
        ModificadorAplicado(
          fonteTipo: FonteModificador.mestre,
          fonteId: 'MESTRE',
          alvoId: alvoId,
          alvoCaracteristica: fonteMod,
          valor: bonusMestre,
          aplicado: true,
        ),
      );
    }
    if (penalFerramenta != 0) {
      lista.add(
        ModificadorAplicado(
          fonteTipo: FonteModificador.ferramenta,
          fonteId: 'SEM_FERRAMENTA',
          alvoId: alvoId,
          alvoCaracteristica: fonteMod,
          valor: penalFerramenta,
          aplicado: true,
        ),
      );
    }
    if (bonusAjuda != 0) {
      lista.add(
        ModificadorAplicado(
          fonteTipo: FonteModificador.ajuda,
          fonteId: 'AJUDA_GRUPO',
          alvoId: alvoId,
          alvoCaracteristica: fonteMod,
          valor: bonusAjuda,
          aplicado: true,
        ),
      );
    }
    if (penalidadeFalhaCumulativa != 0) {
      lista.add(
        ModificadorAplicado(
          fonteTipo: FonteModificador.penalidadeFalha,
          fonteId: 'PENALIDADE_FALHA_ESTENDIDO',
          alvoId: alvoId,
          alvoCaracteristica: fonteMod,
          valor: penalidadeFalhaCumulativa,
          aplicado: true,
        ),
      );
    }
    return lista;
  }

  /// Soma dos modificadores aplicados que representam o modificador base da perícia/atributo.
  int get modBase => modificadores
      .where(
        (m) =>
            m.aplicado &&
            (m.fonteId == 'BASE_$fonteMod' ||
                m.fonteTipo == FonteModificador.pericia ||
                m.fonteTipo == FonteModificador.atributo),
      )
      .fold<int>(0, (s, m) => s + m.valor);

  /// Soma dos modificadores aplicados de origem `MESTRE`.
  int get bonusMestre => modificadores
      .where((m) => m.aplicado && m.fonteTipo == FonteModificador.mestre)
      .fold<int>(0, (s, m) => s + m.valor);

  /// Soma das penalidades de falta de ferramenta aplicadas.
  int get penalFerramenta => modificadores
      .where((m) => m.aplicado && m.fonteTipo == FonteModificador.ferramenta)
      .fold<int>(0, (s, m) => s + m.valor);

  /// Soma dos bônus de ajuda aplicados.
  int get bonusAjuda => modificadores
      .where((m) => m.aplicado && m.fonteTipo == FonteModificador.ajuda)
      .fold<int>(0, (s, m) => s + m.valor);

  /// Soma das penalidades cumulativas por falha em teste estendido.
  int get penalidadeFalhaCumulativa => modificadores
      .where(
        (m) => m.aplicado && m.fonteTipo == FonteModificador.penalidadeFalha,
      )
      .fold<int>(0, (s, m) => s + m.valor);

  /// Modificador total somado ao d20 (soma de todos os modificadores com `aplicado == true`).
  int get modificadorTotal => modificadores
      .where((m) => m.aplicado)
      .fold<int>(0, (soma, m) => soma + m.valor);

  /// Texto de log/chat detalhando d20, modificadores (aplicados e ignorados), total, CD e resultado.
  String get detalhamentoLog {
    final partes = <String>[];
    if (usouEscolher == OpcaoEscolher.nenhum) {
      final tagNat = nat20 ? ' [20 NATURAL]' : (nat1 ? ' [1 NATURAL]' : '');
      final rerollStr = d20AnterioresRerolados.isNotEmpty
          ? ' (anterior: ${d20AnterioresRerolados.join(", ")})'
          : '';
      partes.add('d20: $d20$tagNat$rerollStr');
    } else {
      partes.add('Escolher $d20');
    }

    for (final m in modificadores) {
      if (m.aplicado) {
        partes.add('${m.fonteId}: ${_fmtMod(m.valor)}');
      } else {
        partes.add(
          '[IGNORADO ${m.fonteId} (${_fmtMod(m.valor)}): ${m.motivoIgnorado ?? "não acumula"}]',
        );
      }
    }

    final cdStr = cd != null ? ' vs CD $cd' : '';
    final resStr =
        sucessoCD == null ? '' : (sucessoCD! ? ' -> SUCESSO' : ' -> FALHA');
    final avisoStr = avisoTempoVinteX ? ' (leva 20x o tempo normal)' : '';
    final conseqStr = (sucessoCD == false &&
            consequenciaTexto != null &&
            consequenciaTexto!.isNotEmpty)
        ? ' | Consequência: $consequenciaTexto'
        : '';

    return '[$personagemId] (${partes.join(' | ')}) => Total: $total$cdStr$resStr$avisoStr$conseqStr';
  }

  static String _fmtMod(int v) => v >= 0 ? '+$v' : '$v';

  Map<String, dynamic> toJson({bool visaoMestre = true}) {
    if (secreto && !visaoMestre) {
      return {
        'testeId': testeId,
        'personagemId': personagemId,
        'fonteMod': fonteMod,
        'secreto': true,
        'ocultoParaJogador': true,
        'detalhamentoLog':
            '[$personagemId] Rolagem secreta realizada pelo Mestre.',
      };
    }
    return {
      'testeId': testeId,
      'personagemId': personagemId,
      'd20': d20,
      'd20AnterioresRerolados': d20AnterioresRerolados,
      'fonteMod': fonteMod,
      'modificadores': modificadores.map((m) => m.toJson()).toList(),
      'modBase': modBase,
      'bonusMestre': bonusMestre,
      'penalFerramenta': penalFerramenta,
      'bonusAjuda': bonusAjuda,
      'penalidadeFalhaCumulativa': penalidadeFalhaCumulativa,
      'total': total,
      'cd': cd,
      'nat20': nat20,
      'nat1': nat1,
      'usouEscolher': usouEscolher.name,
      'sucessoCD': sucessoCD,
      'secreto': secreto,
      'avisoTempoVinteX': avisoTempoVinteX,
      'consequenciaTexto': consequenciaTexto,
      'detalhamentoLog': detalhamentoLog,
    };
  }

  factory RollResult.fromJson(Map<String, dynamic> json) {
    final modsJson = json['modificadores'] as List<dynamic>?;
    final mods = modsJson
        ?.map(
          (e) => ModificadorAplicado.fromJson(e as Map<String, dynamic>),
        )
        .toList();

    return RollResult(
      testeId: json['testeId'] as String,
      personagemId: json['personagemId'] as String,
      d20: json['d20'] as int? ?? 0,
      d20AnterioresRerolados:
          (json['d20AnterioresRerolados'] as List<dynamic>? ?? [])
              .map((e) => e as int)
              .toList(),
      fonteMod: json['fonteMod'] as String? ?? '',
      modificadores: mods,
      modBase: json['modBase'] as int? ?? 0,
      bonusMestre: json['bonusMestre'] as int? ?? 0,
      penalFerramenta: json['penalFerramenta'] as int? ?? 0,
      bonusAjuda: json['bonusAjuda'] as int? ?? 0,
      penalidadeFalhaCumulativa:
          json['penalidadeFalhaCumulativa'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
      cd: json['cd'] as int?,
      nat20: json['nat20'] as bool? ?? false,
      nat1: json['nat1'] as bool? ?? false,
      usouEscolher: OpcaoEscolher.values.firstWhere(
        (e) => e.name == json['usouEscolher'],
        orElse: () => OpcaoEscolher.nenhum,
      ),
      sucessoCD: json['sucessoCD'] as bool?,
      secreto: json['secreto'] as bool? ?? false,
      avisoTempoVinteX: json['avisoTempoVinteX'] as bool? ?? false,
      consequenciaTexto: json['consequenciaTexto'] as String?,
    );
  }
}

/// R30 e R49: Máquina de estados de um teste em andamento (`CRIADO -> MODS_TRAVADOS -> ROLADO -> AGUARDANDO_DECLARACAO -> DECLARADO`).
class EstadoTeste {
  final TesteRequest request;
  final String personagemId;
  final String fonteMod;
  final FaseEstadoTeste fase;
  final List<ModificadorAplicado> modificadoresCandidatos;
  final List<ModificadorAplicado>? modificadoresTravados;
  final RollResult? resultadoAtual;
  final int rerolagensUsadas;
  final List<int> historicoD20;

  const EstadoTeste({
    required this.request,
    required this.personagemId,
    required this.fonteMod,
    this.fase = FaseEstadoTeste.criado,
    this.modificadoresCandidatos = const [],
    this.modificadoresTravados,
    this.resultadoAtual,
    this.rerolagensUsadas = 0,
    this.historicoD20 = const [],
  });

  EstadoTeste copyWith({
    TesteRequest? request,
    String? personagemId,
    String? fonteMod,
    FaseEstadoTeste? fase,
    List<ModificadorAplicado>? modificadoresCandidatos,
    List<ModificadorAplicado>? modificadoresTravados,
    RollResult? resultadoAtual,
    int? rerolagensUsadas,
    List<int>? historicoD20,
  }) {
    return EstadoTeste(
      request: request ?? this.request,
      personagemId: personagemId ?? this.personagemId,
      fonteMod: fonteMod ?? this.fonteMod,
      fase: fase ?? this.fase,
      modificadoresCandidatos:
          modificadoresCandidatos ?? this.modificadoresCandidatos,
      modificadoresTravados:
          modificadoresTravados ?? this.modificadoresTravados,
      resultadoAtual: resultadoAtual ?? this.resultadoAtual,
      rerolagensUsadas: rerolagensUsadas ?? this.rerolagensUsadas,
      historicoD20: historicoD20 ?? this.historicoD20,
    );
  }

  Map<String, dynamic> toJson({bool visaoMestre = true}) => {
        'request': request.toJson(),
        'personagemId': personagemId,
        'fonteMod': fonteMod,
        'fase': fase.name,
        'modificadoresCandidatos':
            modificadoresCandidatos.map((m) => m.toJson()).toList(),
        'modificadoresTravados':
            modificadoresTravados?.map((m) => m.toJson()).toList(),
        'resultadoAtual': resultadoAtual?.toJson(visaoMestre: visaoMestre),
        'rerolagensUsadas': rerolagensUsadas,
        'historicoD20': historicoD20,
      };

  factory EstadoTeste.fromJson(Map<String, dynamic> json) {
    return EstadoTeste(
      request: TesteRequest.fromJson(json['request'] as Map<String, dynamic>),
      personagemId: json['personagemId'] as String,
      fonteMod: json['fonteMod'] as String,
      fase: FaseEstadoTeste.values.firstWhere(
        (e) => e.name == json['fase'],
        orElse: () => FaseEstadoTeste.criado,
      ),
      modificadoresCandidatos:
          (json['modificadoresCandidatos'] as List<dynamic>? ?? [])
              .map(
                (e) => ModificadorAplicado.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
      modificadoresTravados: json['modificadoresTravados'] != null
          ? (json['modificadoresTravados'] as List<dynamic>)
              .map(
                (e) => ModificadorAplicado.fromJson(e as Map<String, dynamic>),
              )
              .toList()
          : null,
      resultadoAtual: json['resultadoAtual'] != null
          ? RollResult.fromJson(json['resultadoAtual'] as Map<String, dynamic>)
          : null,
      rerolagensUsadas: json['rerolagensUsadas'] as int? ?? 0,
      historicoD20: (json['historicoD20'] as List<dynamic>? ?? [])
          .map((e) => e as int)
          .toList(),
    );
  }
}

/// Resultado consolidado de testes OPOSTOS ou MISTOS (R2).
class ResultadoConfronto {
  final String testeId;
  final TipoTeste tipo;
  final int? cd;
  final List<RollResult> resultadosParticipantes;
  final String? vencedorId;
  final bool exigeNovaRolagemEmpate;
  final List<String> empatadosIds;
  final String logResumo;

  const ResultadoConfronto({
    required this.testeId,
    required this.tipo,
    this.cd,
    required this.resultadosParticipantes,
    this.vencedorId,
    this.exigeNovaRolagemEmpate = false,
    this.empatadosIds = const [],
    required this.logResumo,
  });

  Map<String, dynamic> toJson({bool visaoMestre = true}) => {
        'testeId': testeId,
        'tipo': tipo.name,
        'cd': cd,
        'resultadosParticipantes': resultadosParticipantes
            .map((r) => r.toJson(visaoMestre: visaoMestre))
            .toList(),
        'vencedorId': vencedorId,
        'exigeNovaRolagemEmpate': exigeNovaRolagemEmpate,
        'empatadosIds': empatadosIds,
        'logResumo': logResumo,
      };
}

/// R19: Configuração de penalidade cumulativa por falha em um Teste Estendido.
class PenalidadeFalhaEstendido {
  final int penalidadeNumericaPorFalha;
  final String? textoConsequencia;

  const PenalidadeFalhaEstendido({
    this.penalidadeNumericaPorFalha = 0,
    this.textoConsequencia,
  });

  Map<String, dynamic> toJson() => {
        'penalidadeNumericaPorFalha': penalidadeNumericaPorFalha,
        'textoConsequencia': textoConsequencia,
      };

  factory PenalidadeFalhaEstendido.fromJson(Map<String, dynamic> json) {
    return PenalidadeFalhaEstendido(
      penalidadeNumericaPorFalha:
          json['penalidadeNumericaPorFalha'] as int? ?? 0,
      textoConsequencia: json['textoConsequencia'] as String?,
    );
  }
}

/// Registro individual de cada teste realizado dentro de um [TesteEstendido].
class EntradaHistoricoEstendido {
  final int indiceTeste;
  final int rodada;
  final String personagemId;
  final String pericia;
  final String? descricaoAcao;
  final int cdAplicada;
  final RollResult resultado;
  final List<AjudaResult> ajudas;
  final String? consequenciaAplicada;

  const EntradaHistoricoEstendido({
    required this.indiceTeste,
    required this.rodada,
    required this.personagemId,
    required this.pericia,
    this.descricaoAcao,
    required this.cdAplicada,
    required this.resultado,
    this.ajudas = const [],
    this.consequenciaAplicada,
  });

  Map<String, dynamic> toJson({bool visaoMestre = true}) => {
        'indiceTeste': indiceTeste,
        'rodada': rodada,
        'personagemId': personagemId,
        'pericia': pericia,
        'descricaoAcao': descricaoAcao,
        'cdAplicada': cdAplicada,
        'resultado': resultado.toJson(visaoMestre: visaoMestre),
        'ajudas': ajudas.map((a) => a.toJson()).toList(),
        'consequenciaAplicada': consequenciaAplicada,
      };

  factory EntradaHistoricoEstendido.fromJson(Map<String, dynamic> json) {
    return EntradaHistoricoEstendido(
      indiceTeste: json['indiceTeste'] as int,
      rodada: json['rodada'] as int? ?? 1,
      personagemId: json['personagemId'] as String,
      pericia: json['pericia'] as String,
      descricaoAcao: json['descricaoAcao'] as String?,
      cdAplicada: json['cdAplicada'] as int,
      resultado:
          RollResult.fromJson(json['resultado'] as Map<String, dynamic>),
      ajudas: (json['ajudas'] as List<dynamic>? ?? [])
          .map((e) => AjudaResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      consequenciaAplicada: json['consequenciaAplicada'] as String?,
    );
  }
}

/// R13–R21: Estado imutável e serializável de um Teste Estendido.
class TesteEstendido {
  final String id;
  final int cdBase;
  final bool cumulativa;
  final Map<String, int> metas;
  final Map<String, int> progresso;
  final int falhas;
  final int maxFalhas;
  final ModoTesteEstendido modo;
  final bool grupo;
  final List<String> participantesGrupo;
  final int rodadaAtual;
  final Set<String> jaAgiramNaRodada;
  final Set<String> periciasConsumidas;
  final List<EntradaHistoricoEstendido> historico;
  final PenalidadeFalhaEstendido? penalFalha;
  final TipoInterrupcaoEstendido interrupcaoConta;
  final EstadoTesteEstendido estado;

  const TesteEstendido({
    required this.id,
    required this.cdBase,
    this.cumulativa = false,
    required this.metas,
    required this.progresso,
    this.falhas = 0,
    this.maxFalhas = 3,
    this.modo = ModoTesteEstendido.fechado,
    this.grupo = false,
    this.participantesGrupo = const [],
    this.rodadaAtual = 1,
    this.jaAgiramNaRodada = const {},
    this.periciasConsumidas = const {},
    this.historico = const [],
    this.penalFalha,
    this.interrupcaoConta = TipoInterrupcaoEstendido.nada,
    this.estado = EstadoTesteEstendido.emAndamento,
  });

  int get testesRealizados => historico.length;

  int calcularCdAtual({int incrementoCumulativo = 2}) {
    if (!cumulativa) return cdBase;
    return cdBase + (incrementoCumulativo * testesRealizados);
  }

  int get penalidadeAcumuladaFalhas {
    if (penalFalha == null || falhas == 0) return 0;
    return penalFalha!.penalidadeNumericaPorFalha * falhas;
  }

  int get totalSucessos =>
      progresso.values.fold<int>(0, (soma, atual) => soma + atual);

  int get totalMetas => metas.values.fold<int>(0, (soma, meta) => soma + meta);

  TesteEstendido copyWith({
    String? id,
    int? cdBase,
    bool? cumulativa,
    Map<String, int>? metas,
    Map<String, int>? progresso,
    int? falhas,
    int? maxFalhas,
    ModoTesteEstendido? modo,
    bool? grupo,
    List<String>? participantesGrupo,
    int? rodadaAtual,
    Set<String>? jaAgiramNaRodada,
    Set<String>? periciasConsumidas,
    List<EntradaHistoricoEstendido>? historico,
    PenalidadeFalhaEstendido? penalFalha,
    TipoInterrupcaoEstendido? interrupcaoConta,
    EstadoTesteEstendido? estado,
  }) {
    return TesteEstendido(
      id: id ?? this.id,
      cdBase: cdBase ?? this.cdBase,
      cumulativa: cumulativa ?? this.cumulativa,
      metas: metas ?? this.metas,
      progresso: progresso ?? this.progresso,
      falhas: falhas ?? this.falhas,
      maxFalhas: maxFalhas ?? this.maxFalhas,
      modo: modo ?? this.modo,
      grupo: grupo ?? this.grupo,
      participantesGrupo: participantesGrupo ?? this.participantesGrupo,
      rodadaAtual: rodadaAtual ?? this.rodadaAtual,
      jaAgiramNaRodada: jaAgiramNaRodada ?? this.jaAgiramNaRodada,
      periciasConsumidas: periciasConsumidas ?? this.periciasConsumidas,
      historico: historico ?? this.historico,
      penalFalha: penalFalha ?? this.penalFalha,
      interrupcaoConta: interrupcaoConta ?? this.interrupcaoConta,
      estado: estado ?? this.estado,
    );
  }

  Map<String, dynamic> toJson({bool visaoMestre = true}) => {
        'id': id,
        'cdBase': cdBase,
        'cumulativa': cumulativa,
        'metas': metas,
        'progresso': progresso,
        'falhas': falhas,
        'maxFalhas': maxFalhas,
        'modo': modo.name,
        'grupo': grupo,
        'participantesGrupo': participantesGrupo,
        'rodadaAtual': rodadaAtual,
        'jaAgiramNaRodada': jaAgiramNaRodada.toList(),
        'periciasConsumidas': periciasConsumidas.toList(),
        'historico': historico
            .map((h) => h.toJson(visaoMestre: visaoMestre))
            .toList(),
        'penalFalha': penalFalha?.toJson(),
        'interrupcaoConta': interrupcaoConta.name,
        'estado': estado.name,
      };

  factory TesteEstendido.fromJson(Map<String, dynamic> json) {
    return TesteEstendido(
      id: json['id'] as String,
      cdBase: json['cdBase'] as int,
      cumulativa: json['cumulativa'] as bool? ?? false,
      metas: (json['metas'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, v as int),
      ),
      progresso: (json['progresso'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, v as int),
      ),
      falhas: json['falhas'] as int? ?? 0,
      maxFalhas: json['maxFalhas'] as int? ?? 3,
      modo: ModoTesteEstendido.values.firstWhere(
        (e) => e.name == json['modo'],
        orElse: () => ModoTesteEstendido.fechado,
      ),
      grupo: json['grupo'] as bool? ?? false,
      participantesGrupo: (json['participantesGrupo'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      rodadaAtual: json['rodadaAtual'] as int? ?? 1,
      jaAgiramNaRodada: (json['jaAgiramNaRodada'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toSet(),
      periciasConsumidas: (json['periciasConsumidas'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toSet(),
      historico: (json['historico'] as List<dynamic>? ?? [])
          .map(
            (e) => EntradaHistoricoEstendido.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
      penalFalha: json['penalFalha'] != null
          ? PenalidadeFalhaEstendido.fromJson(
              json['penalFalha'] as Map<String, dynamic>,
            )
          : null,
      interrupcaoConta: TipoInterrupcaoEstendido.values.firstWhere(
        (e) => e.name == json['interrupcaoConta'],
        orElse: () => TipoInterrupcaoEstendido.nada,
      ),
      estado: EstadoTesteEstendido.values.firstWhere(
        (e) => e.name == json['estado'],
        orElse: () => EstadoTesteEstendido.emAndamento,
      ),
    );
  }
}
