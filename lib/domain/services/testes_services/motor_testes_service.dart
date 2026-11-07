import 'dart:math';

import 'package:t20_creator/domain/entities/testes/configuracoes_mesa_t20.dart';
import 'package:t20_creator/domain/entities/testes/modelos_teste_t20.dart';
import 'package:t20_creator/domain/services/habilidades_services/modificador_engine.dart';
import 'package:t20_creator/domain/services/testes_services/i_rng.dart';

/// Resultado de um passo executado dentro de um [TesteEstendido].
class ResultadoPassoEstendido {
  final TesteEstendido testeAtualizado;
  final RollResult resultadoRolagem;
  final EntradaHistoricoEstendido entradaHistorico;

  const ResultadoPassoEstendido({
    required this.testeAtualizado,
    required this.resultadoRolagem,
    required this.entradaHistorico,
  });
}

/// Motor puro de regras para Testes Básicos, Opostos, Mistos, Ajuda,
/// Escolher 0/10/20, Máquina de Estados de Teste (R30) e Testes Estendidos de Tormenta 20.
///
/// Sem dependências de UI ou rede. Totalmente determinístico via injeção de [IRng].
class MotorTestesService {
  final IRng _rng;
  final ConfiguracoesMesaT20 configuracoes;
  final ModificadorEngine _modificadorEngine;

  MotorTestesService({
    required IRng rng,
    this.configuracoes = const ConfiguracoesMesaT20(),
    ModificadorEngine? modificadorEngine,
  })  : _rng = rng,
        _modificadorEngine =
            modificadorEngine ?? ModificadorEngine(configuracoes: configuracoes);

  /// Cria uma nova instância com configurações da mesa atualizadas.
  MotorTestesService comConfiguracoes(ConfiguracoesMesaT20 novasConfiguracoes) {
    return MotorTestesService(
      rng: _rng,
      configuracoes: novasConfiguracoes,
      modificadorEngine: ModificadorEngine(configuracoes: novasConfiguracoes),
    );
  }

  // ===========================================================================
  // REGRAS R10–R12: ELEGIBILIDADE DE TESTES SEM ROLAGEM ("ESCOLHER 0 / 10 / 20")
  // ===========================================================================

  /// Verifica se uma opção de [OpcaoEscolher] é elegível no contexto atual.
  bool podeEscolher({
    required OpcaoEscolher opcao,
    required int modificadorTotal,
    required int? cd,
    required FlagsTeste flags,
    bool emTesteEstendido = false,
  }) {
    switch (opcao) {
      case OpcaoEscolher.nenhum:
        return true;
      case OpcaoEscolher.zero:
        if (cd == null) return false;
        return modificadorTotal >= cd;
      case OpcaoEscolher.dez:
        return flags.semPressao;
      case OpcaoEscolher.vinte:
        if (emTesteEstendido &&
            !configuracoes.permitirEscolher20EmTesteEstendido) {
          return false;
        }
        return flags.semPressao && flags.semConsequencia;
    }
  }

  /// Retorna a lista de opções de [OpcaoEscolher] disponíveis para exibição na UI (R12).
  List<OpcaoEscolher> opcoesEscolherElegiveis({
    required int modificadorTotal,
    required int? cd,
    required FlagsTeste flags,
    bool emTesteEstendido = false,
  }) {
    return [
      OpcaoEscolher.zero,
      OpcaoEscolher.dez,
      OpcaoEscolher.vinte,
    ]
        .where(
          (opcao) => podeEscolher(
            opcao: opcao,
            modificadorTotal: modificadorTotal,
            cd: cd,
            flags: flags,
            emTesteEstendido: emTesteEstendido,
          ),
        )
        .toList();
  }

  void _validarOpcaoEscolher({
    required OpcaoEscolher opcao,
    required int modificadorTotal,
    required int? cd,
    required FlagsTeste flags,
    required bool emTesteEstendido,
  }) {
    if (opcao == OpcaoEscolher.nenhum) return;

    if (opcao == OpcaoEscolher.zero) {
      if (cd == null) {
        throw const RegraTesteException(
          codigo: 'ESCOLHER_0_SEM_CD',
          mensagem: 'Escolher 0 exige uma CD definida.',
        );
      }
      if (modificadorTotal < cd) {
        throw RegraTesteException(
          codigo: 'ESCOLHER_0_MODIFICADOR_INSUFICIENTE',
          mensagem:
              'Escolher 0 bloqueado: modificador total ($modificadorTotal) é menor que a CD ($cd).',
        );
      }
    } else if (opcao == OpcaoEscolher.dez) {
      if (!flags.semPressao) {
        throw const RegraTesteException(
          codigo: 'ESCOLHER_10_EXIGE_SEM_PRESSAO',
          mensagem:
              'Escolher 10 bloqueado: o mestre precisa marcar a flag "sem pressão".',
        );
      }
    } else if (opcao == OpcaoEscolher.vinte) {
      if (emTesteEstendido &&
          !configuracoes.permitirEscolher20EmTesteEstendido) {
        throw const RegraTesteException(
          codigo: 'ESCOLHER_20_BLOQUEADO_ESTENDIDO',
          mensagem: 'Escolher 20 é bloqueado em testes estendidos.',
        );
      }
      if (!flags.semPressao || !flags.semConsequencia) {
        throw const RegraTesteException(
          codigo: 'ESCOLHER_20_FLAGS_INSUFICIENTES',
          mensagem:
              'Escolher 20 bloqueado: o mestre precisa marcar "sem pressão" e "sem consequência por falha".',
        );
      }
    }
  }

  // ===========================================================================
  // REGRAS R5: CÁLCULO DE PENALIDADE DE FERRAMENTA
  // ===========================================================================

  /// R5 e Caso de Borda 11: Se a perícia exige ferramenta e o personagem não a tem
  /// (ou o mestre marcou `semFerramenta` no pedido), aplica -5 uma única vez.
  int calcularPenalidadeFerramenta({
    required ModoTeste modo,
    required bool periciaExigeFerramenta,
    required bool personagemSemFerramenta,
    required bool flagMestreSemFerramenta,
  }) {
    if (modo != ModoTeste.pericia) return 0;
    final faltaFerramenta =
        (periciaExigeFerramenta && personagemSemFerramenta) ||
            flagMestreSemFerramenta;
    return faltaFerramenta ? configuracoes.penalidadeSemFerramenta : 0;
  }

  // ===========================================================================
  // REGRAS R7–R9: AJUDA
  // ===========================================================================

  /// R8: Calcula o bônus concedido por um ajudante dado seu total e se obteve sucesso.
  int calcularBonusAjuda({
    required int totalAjudante,
    required bool sucesso,
  }) {
    if (!sucesso) return 0;
    final cdAjuda = configuracoes.cdAjudaPadrao;
    final intervalo = max(1, configuracoes.intervaloBonusExtraAjuda);
    final extras =
        totalAjudante >= cdAjuda ? (totalAjudante - cdAjuda) ~/ intervalo : 0;
    return configuracoes.bonusBaseAjuda + extras;
  }

  /// R7–R8: Executa o teste de perícia de um ajudante contra a CD de ajuda (padrão 10).
  AjudaResult resolverAjuda({
    required String ajudanteId,
    required String pericia,
    required int modificador,
    int bonusMestre = 0,
    bool periciaExigeFerramenta = false,
    bool personagemSemFerramenta = false,
    bool flagMestreSemFerramenta = false,
  }) {
    final d20 = _rng.rolarD20();
    final penalFerramenta = calcularPenalidadeFerramenta(
      modo: ModoTeste.pericia,
      periciaExigeFerramenta: periciaExigeFerramenta,
      personagemSemFerramenta: personagemSemFerramenta,
      flagMestreSemFerramenta: flagMestreSemFerramenta,
    );
    final modEfetivo = modificador + bonusMestre + penalFerramenta;
    final total = d20 + modEfetivo;
    final cdAjuda = configuracoes.cdAjudaPadrao;

    final nat20 = d20 == 20;
    final nat1 = d20 == 1;

    final bool sucesso;
    if (nat20 && configuracoes.nat20SucessoAutomaticoContraCd) {
      sucesso = true;
    } else if (nat1 && configuracoes.nat1FalhaAutomaticaContraCd) {
      sucesso = false;
    } else {
      sucesso = total >= cdAjuda;
    }

    final bonus = calcularBonusAjuda(
      totalAjudante: total,
      sucesso: sucesso,
    );

    return AjudaResult(
      ajudanteId: ajudanteId,
      pericia: pericia,
      d20: d20,
      modificador: modEfetivo,
      total: total,
      cdAjuda: cdAjuda,
      sucesso: sucesso,
      bonusConcedido: bonus,
    );
  }

  // ===========================================================================
  // REGRAS R1–R6, R10–R12, R29: TESTE INDIVIDUAL COM MODIFICADOR ENGINE
  // ===========================================================================

  List<ModificadorAplicado> _montarListaModificadores({
    required TesteRequest request,
    required String personagemId,
    required String fonteMod,
    required int modBase,
    required bool periciaExigeFerramenta,
    required bool personagemSemFerramenta,
    required List<AjudaResult> ajudas,
    required int penalidadeFalhaCumulativa,
    required List<ModificadorAplicado> modificadoresExtras,
    Set<String>? efeitosAtivosIds,
  }) {
    final candidatos = <ModificadorAplicado>[
      ModificadorAplicado(
        fonteTipo: request.modo == ModoTeste.pericia
            ? FonteModificador.pericia
            : FonteModificador.atributo,
        fonteId: 'BASE_$fonteMod',
        alvoId: personagemId,
        alvoCaracteristica: fonteMod,
        valor: modBase,
      ),
      ...modificadoresExtras.map(
        (m) => m.copyWith(
          alvoId: m.alvoId ?? personagemId,
          alvoCaracteristica:
              m.alvoCaracteristica.isEmpty ? fonteMod : m.alvoCaracteristica,
        ),
      ),
    ];

    if (request.modificadoresMestre != 0) {
      candidatos.add(
        ModificadorAplicado(
          fonteTipo: FonteModificador.mestre,
          fonteId: 'MESTRE',
          alvoId: personagemId,
          alvoCaracteristica: fonteMod,
          valor: request.modificadoresMestre,
        ),
      );
    }

    final penalFerramenta = calcularPenalidadeFerramenta(
      modo: request.modo,
      periciaExigeFerramenta: periciaExigeFerramenta,
      personagemSemFerramenta: personagemSemFerramenta,
      flagMestreSemFerramenta: request.flags.semFerramenta,
    );
    if (penalFerramenta != 0) {
      candidatos.add(
        ModificadorAplicado(
          fonteTipo: FonteModificador.ferramenta,
          fonteId: 'SEM_FERRAMENTA',
          alvoId: personagemId,
          alvoCaracteristica: fonteMod,
          valor: penalFerramenta,
        ),
      );
    }

    for (final a in ajudas) {
      if (a.bonusConcedido != 0) {
        candidatos.add(
          ModificadorAplicado(
            fonteTipo: FonteModificador.ajuda,
            fonteId: 'AJUDA_${a.ajudanteId}',
            alvoId: personagemId,
            alvoCaracteristica: fonteMod,
            valor: a.bonusConcedido,
          ),
        );
      }
    }

    if (penalidadeFalhaCumulativa != 0) {
      candidatos.add(
        ModificadorAplicado(
          fonteTipo: FonteModificador.penalidadeFalha,
          fonteId: 'PENALIDADE_FALHA_ESTENDIDO',
          alvoId: personagemId,
          alvoCaracteristica: fonteMod,
          valor: penalidadeFalhaCumulativa,
        ),
      );
    }

    return _modificadorEngine.resolverModificadores(
      candidatos,
      efeitosAtivosIds: efeitosAtivosIds,
    );
  }

  /// Executa o teste de um personagem para um [TesteRequest], produzindo
  /// o breakdown `List<ModificadorAplicado>` via [ModificadorEngine].
  RollResult executarTeste({
    required TesteRequest request,
    required String personagemId,
    required String fonteMod,
    required int modBase,
    bool periciaExigeFerramenta = false,
    bool personagemSemFerramenta = false,
    List<AjudaResult> ajudas = const [],
    List<ModificadorAplicado> modificadoresExtras = const [],
    Set<String>? efeitosAtivosIds,
    OpcaoEscolher opcaoEscolher = OpcaoEscolher.nenhum,
    int penalidadeFalhaCumulativa = 0,
    bool jaFalhouAnteriormente = false,
  }) {
    if (jaFalhouAnteriormente && request.flags.semNovaTentativa) {
      throw RegraTesteException(
        codigo: 'NOVA_TENTATIVA_BLOQUEADA',
        mensagem:
            'Novas tentativas não são permitidas neste teste (${request.consequenciaFalha ?? "sem nova tentativa"}).',
      );
    }

    if (ajudas.isNotEmpty) {
      if (!request.flags.ajudantesPermitidos) {
        throw const RegraTesteException(
          codigo: 'AJUDA_NAO_PERMITIDA',
          mensagem: 'O mestre não habilitou ajuda para este teste.',
        );
      }
      if (ajudas.length > request.flags.maxAjudantes) {
        throw RegraTesteException(
          codigo: 'MAX_AJUDANTES_EXCEDIDO',
          mensagem:
              'Quantidade de ajudantes (${ajudas.length}) excede o máximo permitido pelo mestre (${request.flags.maxAjudantes}).',
        );
      }
    }

    if ((request.tipo == TipoTeste.comum || request.tipo == TipoTeste.misto) &&
        request.cd == null) {
      throw const RegraTesteException(
        codigo: 'CD_OBRIGATORIA',
        mensagem: 'Testes do tipo COMUM ou MISTO exigem uma CD definida.',
      );
    }

    final modificadoresResolvidos = _montarListaModificadores(
      request: request,
      personagemId: personagemId,
      fonteMod: fonteMod,
      modBase: modBase,
      periciaExigeFerramenta: periciaExigeFerramenta,
      personagemSemFerramenta: personagemSemFerramenta,
      ajudas: ajudas,
      penalidadeFalhaCumulativa: penalidadeFalhaCumulativa,
      modificadoresExtras: modificadoresExtras,
      efeitosAtivosIds: efeitosAtivosIds,
    );

    final modificadorTotal = modificadoresResolvidos
        .where((m) => m.aplicado)
        .fold<int>(0, (s, m) => s + m.valor);

    _validarOpcaoEscolher(
      opcao: opcaoEscolher,
      modificadorTotal: modificadorTotal,
      cd: request.cd,
      flags: request.flags,
      emTesteEstendido: request.emTesteEstendido,
    );

    return _calcularRollResultComModificadoresTravados(
      request: request,
      personagemId: personagemId,
      fonteMod: fonteMod,
      modificadoresTravados: modificadoresResolvidos,
      opcaoEscolher: opcaoEscolher,
      d20AnterioresRerolados: const [],
    );
  }

  RollResult _calcularRollResultComModificadoresTravados({
    required TesteRequest request,
    required String personagemId,
    required String fonteMod,
    required List<ModificadorAplicado> modificadoresTravados,
    required OpcaoEscolher opcaoEscolher,
    required List<int> d20AnterioresRerolados,
  }) {
    final modificadorTotal = modificadoresTravados
        .where((m) => m.aplicado)
        .fold<int>(0, (s, m) => s + m.valor);

    final int d20;
    final bool nat20;
    final bool nat1;

    switch (opcaoEscolher) {
      case OpcaoEscolher.nenhum:
        d20 = _rng.rolarD20();
        nat20 = d20 == 20;
        nat1 = d20 == 1;
        break;
      case OpcaoEscolher.zero:
        d20 = 0;
        nat20 = false;
        nat1 = false;
        break;
      case OpcaoEscolher.dez:
        d20 = 10;
        nat20 = false;
        nat1 = false;
        break;
      case OpcaoEscolher.vinte:
        d20 = 20;
        nat20 = false;
        nat1 = false;
        break;
    }

    final total = d20 + modificadorTotal;

    bool? sucessoCD;
    if (request.cd != null) {
      if (opcaoEscolher == OpcaoEscolher.zero) {
        sucessoCD = true;
      } else if (nat20 && configuracoes.nat20SucessoAutomaticoContraCd) {
        sucessoCD = true;
      } else if (nat1 && configuracoes.nat1FalhaAutomaticaContraCd) {
        sucessoCD = false;
      } else {
        sucessoCD = total >= request.cd!;
      }
    }

    return RollResult(
      testeId: request.id,
      personagemId: personagemId,
      d20: d20,
      d20AnterioresRerolados: d20AnterioresRerolados,
      fonteMod: fonteMod,
      modificadores: modificadoresTravados,
      total: total,
      cd: request.cd,
      nat20: nat20,
      nat1: nat1,
      usouEscolher: opcaoEscolher,
      sucessoCD: sucessoCD,
      secreto: request.flags.secreto,
      avisoTempoVinteX: opcaoEscolher == OpcaoEscolher.vinte,
      consequenciaTexto: sucessoCD == false ? request.consequenciaFalha : null,
    );
  }

  // ===========================================================================
  // REGRAS R30 E R49: MÁQUINA DE ESTADOS DO TESTE E REPETIÇÃO DE ROLAGEM
  // ===========================================================================

  /// R30: Cria um [EstadoTeste] na fase inicial `CRIADO`.
  EstadoTeste criarEstadoTeste({
    required TesteRequest request,
    required String personagemId,
    required String fonteMod,
    required int modBase,
    bool periciaExigeFerramenta = false,
    bool personagemSemFerramenta = false,
    List<AjudaResult> ajudas = const [],
    List<ModificadorAplicado> modificadoresExtras = const [],
    int penalidadeFalhaCumulativa = 0,
  }) {
    final candidatos = _montarListaModificadores(
      request: request,
      personagemId: personagemId,
      fonteMod: fonteMod,
      modBase: modBase,
      periciaExigeFerramenta: periciaExigeFerramenta,
      personagemSemFerramenta: personagemSemFerramenta,
      ajudas: ajudas,
      penalidadeFalhaCumulativa: penalidadeFalhaCumulativa,
      modificadoresExtras: modificadoresExtras,
    );

    return EstadoTeste(
      request: request,
      personagemId: personagemId,
      fonteMod: fonteMod,
      fase: FaseEstadoTeste.criado,
      modificadoresCandidatos: candidatos,
    );
  }

  /// R30 (Caso de Borda 12): Aplica novos modificadores ou muda a CD APENAS antes da rolagem (`CRIADO`).
  EstadoTeste modificarAntesDaRolagem({
    required EstadoTeste estado,
    ModificadorAplicado? novoModificador,
    int? novaCd,
  }) {
    if (estado.fase != FaseEstadoTeste.criado) {
      throw RegraTesteException(
        codigo: 'MODIFICADORES_JA_TRAVADOS',
        mensagem:
            'Bônus ou mudanças na CD só podem ser aplicados antes da rolagem (fase atual: ${estado.fase.name}).',
      );
    }

    final reqAtualizado =
        novaCd != null ? estado.request.copyWith(cd: novaCd) : estado.request;
    final novosCandidatos = novoModificador != null
        ? [...estado.modificadoresCandidatos, novoModificador]
        : estado.modificadoresCandidatos;

    return estado.copyWith(
      request: reqAtualizado,
      modificadoresCandidatos: List.unmodifiable(novosCandidatos),
    );
  }

  /// R30 e R49: Trava os modificadores (`MODIFICADORES_TRAVADOS`), executa a rolagem (`ROLADO`)
  /// e avança para `AGUARDANDO_DECLARACAO`.
  /// Efeitos que expirarem ANTES desta chamada (não presentes em `efeitosAtivosIds`) não contam;
  /// efeitos que expirarem DEPOIS desta chamada continuam valendo até o fim deste teste!
  EstadoTeste rolarEstadoTeste({
    required EstadoTeste estado,
    OpcaoEscolher opcaoEscolher = OpcaoEscolher.nenhum,
    Set<String>? efeitosAtivosIds,
  }) {
    if (estado.fase != FaseEstadoTeste.criado &&
        estado.fase != FaseEstadoTeste.modificadoresTravados) {
      throw RegraTesteException(
        codigo: 'TESTE_JA_ROLADO',
        mensagem: 'O teste já foi rolado (fase atual: ${estado.fase.name}).',
      );
    }

    final travados = _modificadorEngine.resolverModificadores(
      estado.modificadoresCandidatos,
      efeitosAtivosIds: efeitosAtivosIds,
    );

    final modTotal =
        travados.where((m) => m.aplicado).fold<int>(0, (s, m) => s + m.valor);

    _validarOpcaoEscolher(
      opcao: opcaoEscolher,
      modificadorTotal: modTotal,
      cd: estado.request.cd,
      flags: estado.request.flags,
      emTesteEstendido: estado.request.emTesteEstendido,
    );

    final resultado = _calcularRollResultComModificadoresTravados(
      request: estado.request,
      personagemId: estado.personagemId,
      fonteMod: estado.fonteMod,
      modificadoresTravados: travados,
      opcaoEscolher: opcaoEscolher,
      d20AnterioresRerolados: const [],
    );

    return estado.copyWith(
      fase: FaseEstadoTeste.aguardandoDeclaracao,
      modificadoresTravados: travados,
      resultadoAtual: resultado,
      historicoD20: opcaoEscolher == OpcaoEscolher.nenhum
          ? [resultado.d20]
          : const [],
    );
  }

  /// R30 (Caso de Borda 12): Repete a rolagem de d20 enquanto estiver em `AGUARDANDO_DECLARACAO`.
  /// O novo d20 substitui obrigatoriamente o anterior (mesmo que seja pior), e o d20 antigo fica no log.
  EstadoTeste repetirRolagem({
    required EstadoTeste estado,
  }) {
    if (estado.fase == FaseEstadoTeste.declarado) {
      throw const RegraTesteException(
        codigo: 'REROLL_APOS_DECLARACAO',
        mensagem:
            'Não é permitido repetir a rolagem após o mestre declarar o resultado.',
      );
    }
    if (estado.fase != FaseEstadoTeste.aguardandoDeclaracao ||
        estado.resultadoAtual == null ||
        estado.modificadoresTravados == null) {
      throw RegraTesteException(
        codigo: 'FASE_INVALIDA_PARA_REROLL',
        mensagem:
            'A repetição de rolagem só pode ser usada em AGUARDANDO_DECLARACAO (fase atual: ${estado.fase.name}).',
      );
    }

    if (estado.resultadoAtual!.usouEscolher != OpcaoEscolher.nenhum) {
      throw const RegraTesteException(
        codigo: 'REROLL_EM_ESCOLHER_BLOQUEADO',
        mensagem:
            'Testes com Escolher 0/10/20 não geram rolagem de d20 e não permitem repetição.',
      );
    }

    if (estado.rerolagensUsadas >= configuracoes.maxRerolagensPorTeste) {
      throw RegraTesteException(
        codigo: 'LIMITE_REROLL_ATINGIDO',
        mensagem:
            'Limite máximo de repetições por rolagem (${configuracoes.maxRerolagensPorTeste}) já foi atingido.',
      );
    }

    final anteriores = <int>[
      ...estado.resultadoAtual!.d20AnterioresRerolados,
      estado.resultadoAtual!.d20,
    ];

    final novoResultado = _calcularRollResultComModificadoresTravados(
      request: estado.request,
      personagemId: estado.personagemId,
      fonteMod: estado.fonteMod,
      modificadoresTravados: estado.modificadoresTravados!,
      opcaoEscolher: OpcaoEscolher.nenhum,
      d20AnterioresRerolados: List.unmodifiable(anteriores),
    );

    return estado.copyWith(
      resultadoAtual: novoResultado,
      rerolagensUsadas: estado.rerolagensUsadas + 1,
      historicoD20: List.unmodifiable([
        ...estado.historicoD20,
        novoResultado.d20,
      ]),
    );
  }

  /// R30: Declara o resultado final do teste, encerrando a janela de repetições (`DECLARADO`).
  EstadoTeste declararResultadoTeste(EstadoTeste estado) {
    if (estado.fase != FaseEstadoTeste.aguardandoDeclaracao &&
        estado.fase != FaseEstadoTeste.rolado) {
      throw RegraTesteException(
        codigo: 'DECLARACAO_FASE_INVALIDA',
        mensagem:
            'O teste precisa estar em AGUARDANDO_DECLARACAO para ser declarado (fase: ${estado.fase.name}).',
      );
    }
    return estado.copyWith(fase: FaseEstadoTeste.declarado);
  }

  // ===========================================================================
  // REGRAS R2 E R3: RESOLUÇÃO DE TESTES OPOSTOS E MISTOS
  // ===========================================================================

  ResultadoConfronto resolverConfronto({
    required TesteRequest request,
    required List<RollResult> resultados,
  }) {
    if (resultados.isEmpty) {
      throw const RegraTesteException(
        codigo: 'SEM_PARTICIPANTES',
        mensagem: 'Não há resultados para resolver o confronto.',
      );
    }

    List<RollResult> concorrentes = List<RollResult>.from(resultados);

    if (request.tipo == TipoTeste.misto) {
      if (request.cd == null) {
        throw const RegraTesteException(
          codigo: 'CD_OBRIGATORIA_MISTO',
          mensagem: 'Teste MISTO exige uma CD definida.',
        );
      }
      concorrentes = concorrentes.where((r) => r.sucessoCD == true).toList();
      if (concorrentes.isEmpty) {
        return ResultadoConfronto(
          testeId: request.id,
          tipo: request.tipo,
          cd: request.cd,
          resultadosParticipantes: resultados,
          vencedorId: null,
          exigeNovaRolagemEmpate: false,
          empatadosIds: const [],
          logResumo:
              'Teste Misto (CD ${request.cd}): Nenhum participante alcançou a CD. Sem vencedor.',
        );
      }
    }

    if (configuracoes.nat20E1DecidemTesteOposto) {
      final comNat20 = concorrentes.where((r) => r.nat20).toList();
      if (comNat20.isNotEmpty) {
        concorrentes = comNat20;
      } else {
        final semNat1 = concorrentes.where((r) => !r.nat1).toList();
        if (semNat1.isNotEmpty) {
          concorrentes = semNat1;
        }
      }
    }

    final maiorTotal = concorrentes.map((r) => r.total).reduce(max);
    final empatadosTotal =
        concorrentes.where((r) => r.total == maiorTotal).toList();

    if (empatadosTotal.length == 1) {
      final vencedor = empatadosTotal.first;
      return ResultadoConfronto(
        testeId: request.id,
        tipo: request.tipo,
        cd: request.cd,
        resultadosParticipantes: resultados,
        vencedorId: vencedor.personagemId,
        exigeNovaRolagemEmpate: false,
        empatadosIds: const [],
        logResumo:
            'Vencedor: ${vencedor.personagemId} com total ${vencedor.total}.',
      );
    }

    final maiorModificador =
        empatadosTotal.map((r) => r.modificadorTotal).reduce(max);
    final empatadosModificador = empatadosTotal
        .where((r) => r.modificadorTotal == maiorModificador)
        .toList();

    if (empatadosModificador.length == 1) {
      final vencedor = empatadosModificador.first;
      return ResultadoConfronto(
        testeId: request.id,
        tipo: request.tipo,
        cd: request.cd,
        resultadosParticipantes: resultados,
        vencedorId: vencedor.personagemId,
        exigeNovaRolagemEmpate: false,
        empatadosIds: const [],
        logResumo:
            'Empate no total ($maiorTotal). Vencedor no desempate por maior modificador (${vencedor.modificadorTotal}): ${vencedor.personagemId}.',
      );
    }

    final empatadosIds =
        empatadosModificador.map((r) => r.personagemId).toList();
    return ResultadoConfronto(
      testeId: request.id,
      tipo: request.tipo,
      cd: request.cd,
      resultadosParticipantes: resultados,
      vencedorId: null,
      exigeNovaRolagemEmpate: true,
      empatadosIds: empatadosIds,
      logResumo:
          'Empate persistente entre ${empatadosIds.join(", ")} (total $maiorTotal, mod $maiorModificador). Nova rolagem necessária!',
    );
  }

  // ===========================================================================
  // REGRAS R13–R21: TESTE ESTENDIDO
  // ===========================================================================

  TesteEstendido criarTesteEstendido({
    required String id,
    required int cdBase,
    bool cumulativa = false,
    required Map<String, int> metas,
    int? maxFalhas,
    ModoTesteEstendido modo = ModoTesteEstendido.fechado,
    bool grupo = false,
    List<String> participantesGrupo = const [],
    PenalidadeFalhaEstendido? penalFalha,
    TipoInterrupcaoEstendido? interrupcaoConta,
  }) {
    if (metas.isEmpty || metas.values.any((m) => m <= 0)) {
      throw const RegraTesteException(
        codigo: 'METAS_INVALIDAS',
        mensagem:
            'O Teste Estendido deve possuir ao menos uma meta com valor maior que zero.',
      );
    }

    final metasNormalizadas = <String, int>{};
    final progressoInicial = <String, int>{};
    for (final entry in metas.entries) {
      final chave = _normalizarPericia(entry.key);
      metasNormalizadas[chave] = entry.value;
      progressoInicial[chave] = 0;
    }

    return TesteEstendido(
      id: id,
      cdBase: cdBase,
      cumulativa: cumulativa,
      metas: Map.unmodifiable(metasNormalizadas),
      progresso: Map.unmodifiable(progressoInicial),
      falhas: 0,
      maxFalhas: maxFalhas ?? configuracoes.maxFalhasPadraoEstendido,
      modo: modo,
      grupo: grupo,
      participantesGrupo: List.unmodifiable(participantesGrupo),
      rodadaAtual: 1,
      jaAgiramNaRodada: const {},
      periciasConsumidas: const {},
      historico: const [],
      penalFalha: penalFalha,
      interrupcaoConta:
          interrupcaoConta ?? configuracoes.interrupcaoContaPadrao,
      estado: EstadoTesteEstendido.emAndamento,
    );
  }

  (TesteEstendido, AjudaResult) registrarAjudaEstendido({
    required TesteEstendido teste,
    required String ajudanteId,
    required String pericia,
    required int modificador,
    int bonusMestre = 0,
    bool periciaExigeFerramenta = false,
    bool personagemSemFerramenta = false,
    bool flagMestreSemFerramenta = false,
  }) {
    _garantirEstendidoEmAndamento(teste);

    final chavePericia = _normalizarPericia(pericia);
    if (teste.periciasConsumidas.contains(chavePericia)) {
      throw RegraTesteException(
        codigo: 'PERICIA_CONSUMIDA',
        mensagem:
            'A perícia "$chavePericia" já foi consumida neste teste estendido e não pode ser usada para ajudar.',
      );
    }

    final resultadoAjuda = resolverAjuda(
      ajudanteId: ajudanteId,
      pericia: chavePericia,
      modificador: modificador,
      bonusMestre: bonusMestre,
      periciaExigeFerramenta: periciaExigeFerramenta,
      personagemSemFerramenta: personagemSemFerramenta,
      flagMestreSemFerramenta: flagMestreSemFerramenta,
    );

    final novasConsumidas = Set<String>.from(teste.periciasConsumidas);
    if (configuracoes.consumirPericiaAjudaEmTesteEstendido) {
      novasConsumidas.add(chavePericia);
    }

    final testeAtualizado = teste.copyWith(
      periciasConsumidas: Set.unmodifiable(novasConsumidas),
    );

    return (testeAtualizado, resultadoAjuda);
  }

  ResultadoPassoEstendido executarPassoEstendido({
    required TesteEstendido teste,
    required String personagemId,
    required String pericia,
    required int modBase,
    String? descricaoAcao,
    List<AjudaResult> ajudas = const [],
    List<ModificadorAplicado> modificadoresExtras = const [],
    FlagsTeste flags = const FlagsTeste(),
    int bonusMestre = 0,
    bool periciaExigeFerramenta = false,
    bool personagemSemFerramenta = false,
    OpcaoEscolher opcaoEscolher = OpcaoEscolher.nenhum,
  }) {
    _garantirEstendidoEmAndamento(teste);

    final chavePericia = _normalizarPericia(pericia);

    if (teste.periciasConsumidas.contains(chavePericia)) {
      throw RegraTesteException(
        codigo: 'PERICIA_CONSUMIDA',
        mensagem:
            'A perícia "$chavePericia" já foi consumida neste teste estendido e não pode ser reutilizada.',
      );
    }

    for (final ajuda in ajudas) {
      final chaveAjuda = _normalizarPericia(ajuda.pericia);
      if (chaveAjuda == chavePericia &&
          configuracoes.consumirPericiaAjudaEmTesteEstendido) {
        throw RegraTesteException(
          codigo: 'PERICIA_CONSUMIDA',
          mensagem:
              'A perícia "$chavePericia" foi usada para ajudar e ficou indisponível para o teste principal.',
        );
      }
    }

    if (teste.modo == ModoTesteEstendido.aberto) {
      if (descricaoAcao == null || descricaoAcao.trim().isEmpty) {
        throw const RegraTesteException(
          codigo: 'DESCRICAO_ACAO_OBRIGATORIA',
          mensagem:
              'No modo ABERTO, o jogador deve descrever como aplica a perícia escolhida.',
        );
      }
    } else {
      if (!teste.metas.containsKey(chavePericia) &&
          !teste.metas.containsKey('QUALQUER')) {
        throw RegraTesteException(
          codigo: 'PERICIA_NAO_PERMITIDA_NO_DESAFIO',
          mensagem:
              'A perícia "$chavePericia" não faz parte das metas exigidas neste teste estendido.',
        );
      }
    }

    if (teste.grupo && teste.participantesGrupo.isNotEmpty) {
      if (!teste.participantesGrupo.contains(personagemId)) {
        throw RegraTesteException(
          codigo: 'PARTICIPANTE_FORA_DO_GRUPO',
          mensagem:
              'O personagem "$personagemId" não faz parte do grupo deste teste estendido.',
        );
      }
      if (teste.jaAgiramNaRodada.contains(personagemId)) {
        throw RegraTesteException(
          codigo: 'JA_AGIU_NA_RODADA',
          mensagem:
              'O participante "$personagemId" já realizou seu teste na rodada ${teste.rodadaAtual}.',
        );
      }
    }

    final cdAtual = teste.calcularCdAtual(
      incrementoCumulativo: configuracoes.incrementoCdCumulativaEstendido,
    );

    final penalidadeAcumulada = teste.penalidadeAcumuladaFalhas;

    final requestPasso = TesteRequest(
      id: '${teste.id}_passo_${teste.testesRealizados + 1}',
      tipo: TipoTeste.comum,
      cd: cdAtual,
      participantes: [personagemId],
      modo: ModoTeste.pericia,
      fonteEsperada: chavePericia,
      modificadoresMestre: bonusMestre,
      flags: flags,
      consequenciaFalha: teste.penalFalha?.textoConsequencia,
      emTesteEstendido: true,
    );

    final resultadoRolagem = executarTeste(
      request: requestPasso,
      personagemId: personagemId,
      fonteMod: chavePericia,
      modBase: modBase,
      periciaExigeFerramenta: periciaExigeFerramenta,
      personagemSemFerramenta: personagemSemFerramenta,
      ajudas: ajudas,
      modificadoresExtras: modificadoresExtras,
      opcaoEscolher: opcaoEscolher,
      penalidadeFalhaCumulativa: penalidadeAcumulada,
    );

    final novasPericiasConsumidas = Set<String>.from(teste.periciasConsumidas);
    if (configuracoes.consumirPericiaAjudaEmTesteEstendido) {
      for (final ajuda in ajudas) {
        novasPericiasConsumidas.add(_normalizarPericia(ajuda.pericia));
      }
    }
    if (teste.modo == ModoTesteEstendido.aberto) {
      novasPericiasConsumidas.add(chavePericia);
    }

    final novoProgresso = Map<String, int>.from(teste.progresso);
    int novasFalhas = teste.falhas;
    String? consequenciaAplicada;

    if (resultadoRolagem.sucessoCD == true) {
      _incrementarProgressoEstendido(
        metas: teste.metas,
        progresso: novoProgresso,
        chavePericia: chavePericia,
      );
    } else {
      novasFalhas += 1;
      consequenciaAplicada = teste.penalFalha?.textoConsequencia;
    }

    int novaRodada = teste.rodadaAtual;
    final novosQueAgiram = Set<String>.from(teste.jaAgiramNaRodada);
    if (teste.grupo) {
      novosQueAgiram.add(personagemId);
      if (teste.participantesGrupo.isNotEmpty &&
          novosQueAgiram.length >= teste.participantesGrupo.length) {
        novaRodada += 1;
        novosQueAgiram.clear();
      }
    }

    final entrada = EntradaHistoricoEstendido(
      indiceTeste: teste.testesRealizados + 1,
      rodada: teste.rodadaAtual,
      personagemId: personagemId,
      pericia: chavePericia,
      descricaoAcao: descricaoAcao,
      cdAplicada: cdAtual,
      resultado: resultadoRolagem,
      ajudas: List.unmodifiable(ajudas),
      consequenciaAplicada: consequenciaAplicada,
    );

    final novoHistorico = List<EntradaHistoricoEstendido>.unmodifiable([
      ...teste.historico,
      entrada,
    ]);

    final EstadoTesteEstendido novoEstado;
    if (novasFalhas >= teste.maxFalhas) {
      novoEstado = EstadoTesteEstendido.falhaTotal;
    } else if (_todasMetasCumpridas(teste.metas, novoProgresso)) {
      novoEstado = EstadoTesteEstendido.sucesso;
    } else {
      novoEstado = EstadoTesteEstendido.emAndamento;
    }

    final testeAtualizado = teste.copyWith(
      progresso: Map.unmodifiable(novoProgresso),
      falhas: novasFalhas,
      rodadaAtual: novaRodada,
      jaAgiramNaRodada: Set.unmodifiable(novosQueAgiram),
      periciasConsumidas: Set.unmodifiable(novasPericiasConsumidas),
      historico: novoHistorico,
      estado: novoEstado,
    );

    return ResultadoPassoEstendido(
      testeAtualizado: testeAtualizado,
      resultadoRolagem: resultadoRolagem,
      entradaHistorico: entrada,
    );
  }

  TesteEstendido interromperTesteEstendido(TesteEstendido teste) {
    _garantirEstendidoEmAndamento(teste);

    switch (teste.interrupcaoConta) {
      case TipoInterrupcaoEstendido.nada:
        return teste.copyWith(estado: EstadoTesteEstendido.interrompido);
      case TipoInterrupcaoEstendido.umaFalha:
        final novasFalhas = teste.falhas + 1;
        final novoEstado = novasFalhas >= teste.maxFalhas
            ? EstadoTesteEstendido.falhaTotal
            : EstadoTesteEstendido.interrompido;
        return teste.copyWith(
          falhas: novasFalhas,
          estado: novoEstado,
        );
      case TipoInterrupcaoEstendido.falhaTotal:
        return teste.copyWith(
          falhas: teste.maxFalhas,
          estado: EstadoTesteEstendido.falhaTotal,
        );
    }
  }

  TesteEstendido retomarTesteEstendido(TesteEstendido teste) {
    if (teste.estado != EstadoTesteEstendido.interrompido) {
      throw RegraTesteException(
        codigo: 'NAO_INTERROMPIDO',
        mensagem:
            'Apenas testes estendidos no estado INTERROMPIDO podem ser retomados (estado atual: ${teste.estado.name}).',
      );
    }
    return teste.copyWith(estado: EstadoTesteEstendido.emAndamento);
  }

  TesteEstendido reiniciarTesteEstendido(TesteEstendido teste) {
    final progressoZerado = <String, int>{
      for (final chave in teste.metas.keys) chave: 0,
    };
    return teste.copyWith(
      progresso: Map.unmodifiable(progressoZerado),
      falhas: 0,
      rodadaAtual: 1,
      jaAgiramNaRodada: const {},
      periciasConsumidas: const {},
      historico: const [],
      estado: EstadoTesteEstendido.emAndamento,
    );
  }

  // ===========================================================================
  // MÉTODOS AUXILIARES PRIVADOS
  // ===========================================================================

  String _normalizarPericia(String pericia) => pericia.trim().toUpperCase();

  void _garantirEstendidoEmAndamento(TesteEstendido teste) {
    if (teste.estado != EstadoTesteEstendido.emAndamento) {
      throw RegraTesteException(
        codigo: 'TESTE_ESTENDIDO_ENCERRADO',
        mensagem:
            'O Teste Estendido não está em andamento (estado atual: ${teste.estado.name}).',
      );
    }
  }

  void _incrementarProgressoEstendido({
    required Map<String, int> metas,
    required Map<String, int> progresso,
    required String chavePericia,
  }) {
    if (metas.containsKey(chavePericia)) {
      final atual = progresso[chavePericia] ?? 0;
      final metaPericia = metas[chavePericia]!;
      if (atual < metaPericia) {
        progresso[chavePericia] = atual + 1;
        return;
      }
      if (configuracoes.excedenteMetaPericiaContaParaOutras) {
        for (final entry in metas.entries) {
          final progOutra = progresso[entry.key] ?? 0;
          if (progOutra < entry.value) {
            progresso[entry.key] = progOutra + 1;
            return;
          }
        }
      } else if (metas.containsKey('QUALQUER')) {
        final atualQualquer = progresso['QUALQUER'] ?? 0;
        if (atualQualquer < metas['QUALQUER']!) {
          progresso['QUALQUER'] = atualQualquer + 1;
        }
      }
      return;
    }

    if (metas.containsKey('QUALQUER')) {
      final atualQualquer = progresso['QUALQUER'] ?? 0;
      final metaQualquer = metas['QUALQUER']!;
      if (atualQualquer < metaQualquer) {
        progresso['QUALQUER'] = atualQualquer + 1;
      }
    }
  }

  bool _todasMetasCumpridas(
    Map<String, int> metas,
    Map<String, int> progresso,
  ) {
    for (final entry in metas.entries) {
      if ((progresso[entry.key] ?? 0) < entry.value) {
        return false;
      }
    }
    return true;
  }
}
