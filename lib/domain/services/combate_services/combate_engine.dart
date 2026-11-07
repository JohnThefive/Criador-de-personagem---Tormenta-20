import 'dart:math';
import '../../entities/combate/combatente.dart';
import '../../entities/combate/estado_vida_combatente.dart';
import '../../entities/combate/resultado_ataque.dart';
import '../../entities/combate/tipo_acao.dart';
import '../../entities/combate/tipo_dano.dart';
import '../../entities/equipamento/arma.dart';
import '../../entities/testes/configuracoes_mesa_t20.dart';
import '../../entities/testes/modelos_teste_t20.dart';
import '../habilidades_services/modificador_engine.dart';
import '../testes_services/i_rng.dart';

enum StatusCombate { emAndamento, vitoria, derrota }

/// R61: Representação de uma Ação Preparada (gatilho e ação a executar como reação).
class AcaoPreparada {
  final String combatenteId;
  final String condicaoGatilho;
  final TipoAcao tipoAcao;
  final int iniciativaOriginal;

  const AcaoPreparada({
    required this.combatenteId,
    required this.condicaoGatilho,
    required this.tipoAcao,
    required this.iniciativaOriginal,
  });
}

/// R61: Resultado da ação padrão Fintar (Enganação vs Reflexos).
class ResultadoFintar {
  final bool sucesso;
  final int totalEnganacao;
  final int totalReflexos;
  final Combatente defensorAtualizado;
  final String log;

  const ResultadoFintar({
    required this.sucesso,
    required this.totalEnganacao,
    required this.totalReflexos,
    required this.defensorAtualizado,
    required this.log,
  });
}

/// R61: Resultado da ação Atropelar durante o movimento ou investida.
class ResultadoAtropelar {
  final bool atacanteVenceu;
  final int totalAtacante;
  final int totalDefensor;
  final Combatente defensorAtualizado;
  final String log;

  const ResultadoAtropelar({
    required this.atacanteVenceu,
    required this.totalAtacante,
    required this.totalDefensor,
    required this.defensorAtualizado,
    required this.log,
  });
}

/// R63: Resultado da ação completa Investida.
class ResultadoInvestida {
  final ResultadoAtaque ataque;
  final double distanciaPercorrida;
  final int penalidadeDefesaAtacante;
  final String log;

  const ResultadoInvestida({
    required this.ataque,
    required this.distanciaPercorrida,
    this.penalidadeDefesaAtacante = -2,
    required this.log,
  });
}

/// R63: Resultado da ação completa Golpe de Misericórdia.
class ResultadoGolpeDeMisericordia {
  final ResultadoAtaque ataque;
  final int dadoD4;
  final bool morteInstantanea;
  final Combatente defensorAtualizado;
  final String log;

  const ResultadoGolpeDeMisericordia({
    required this.ataque,
    required this.dadoD4,
    required this.morteInstantanea,
    required this.defensorAtualizado,
    required this.log,
  });
}

/// R76: Resultado de ataque a objeto ou manobra Quebrar.
class ResultadoQuebrarObjeto {
  final bool acerto;
  final int danoCausado;
  final int pvRestantesObjeto;
  final bool objetoDestruido;
  final String log;

  const ResultadoQuebrarObjeto({
    required this.acerto,
    required this.danoCausado,
    required this.pvRestantesObjeto,
    required this.objetoDestruido,
    required this.log,
  });
}

class CombateEngine {
  final Random _random;
  final IRng _rng;
  final ConfiguracoesMesaT20 configuracoes;
  final ModificadorEngine modEngine;

  CombateEngine({
    IRng? rng,
    Random? random,
    this.configuracoes = const ConfiguracoesMesaT20(),
    ModificadorEngine? modEngine,
  })  : _random = random ?? Random(),
        _rng = rng ?? RandomRng(random: random),
        modEngine =
            modEngine ?? ModificadorEngine(configuracoes: configuracoes);

  /// R68: Rola a Iniciativa para o combate:
  /// - Cada jogador faz seu teste individual (1d20 + Iniciativa).
  /// - O mestre faz UM teste para os inimigos (usando o menor modificador entre eles).
  /// - Empates resolvidos por maior modificador de perícia e persistindo por id determinístico.
  List<Combatente> rolarIniciativa(
    List<Combatente> participantes, {
    int? d20InimigoForcado,
    Map<String, int>? d20JogadoresForcados,
  }) {
    final list = <Combatente>[];
    final herois =
        participantes.where((c) => c.time == TimeCombatente.heroi).toList();
    final inimigos =
        participantes.where((c) => c.time == TimeCombatente.inimigo).toList();

    // Se todos forem de mesmo time ou não houver separação herói/inimigo explícita
    if (herois.isEmpty || inimigos.isEmpty) {
      for (final p in participantes) {
        final d20 = d20JogadoresForcados?[p.id] ?? _rolarDado(20);
        final total = d20 + p.modIniciativa;
        list.add(p.copyWith(iniciativaValor: total));
      }
      return ordenarIniciativa(list);
    }

    // Cada jogador faz um teste (R68)
    for (final h in herois) {
      final d20 = d20JogadoresForcados?[h.id] ?? _rolarDado(20);
      final total = d20 + h.modIniciativa;
      list.add(h.copyWith(iniciativaValor: total));
    }

    // O mestre faz UM teste para os inimigos (menor bônus entre eles) (R68)
    final menorModInimigos =
        inimigos.map((e) => e.modIniciativa).reduce(min);
    final d20Inimigo = d20InimigoForcado ?? _rolarDado(20);
    final totalInimigos = d20Inimigo + menorModInimigos;
    for (final inimigo in inimigos) {
      list.add(inimigo.copyWith(iniciativaValor: totalInimigos));
    }

    return ordenarIniciativa(list);
  }

  /// Ordena os combatentes respeitando valores pré-definidos de iniciativa e desempates do T20 (R68)
  List<Combatente> ordenarIniciativa(List<Combatente> participantes) {
    final list = List<Combatente>.from(participantes);
    list.sort((a, b) {
      if (b.iniciativaValor != a.iniciativaValor) {
        return b.iniciativaValor.compareTo(a.iniciativaValor);
      }
      if (b.modIniciativa != a.modIniciativa) {
        return b.modIniciativa.compareTo(a.modIniciativa);
      }
      return a.id.compareTo(b.id);
    });
    return list;
  }

  /// A1 / Regra das ruas: O mestre ajusta diretamente a iniciativa ou reordena a fila
  List<Combatente> ajustarIniciativaPorArbitragem({
    required List<Combatente> filaAtual,
    required String combatenteId,
    required int novaIniciativa,
  }) {
    final index = filaAtual.indexWhere((c) => c.id == combatenteId);
    if (index == -1) return filaAtual;

    final atualizada = List<Combatente>.from(filaAtual);
    atualizada[index] =
        filaAtual[index].copyWith(iniciativaValor: novaIniciativa);
    return ordenarIniciativa(atualizada);
  }

  /// Mantido para retrocompatibilidade: redireciona para [ajustarIniciativaPorArbitragem]
  List<Combatente> atrasarIniciativa({
    required List<Combatente> filaAtual,
    required String combatenteId,
    required int novaIniciativa,
  }) {
    return ajustarIniciativaPorArbitragem(
      filaAtual: filaAtual,
      combatenteId: combatenteId,
      novaIniciativa: novaIniciativa,
    );
  }

  /// R61 e A5: Prepara uma ação para ser executada como reação quando o gatilho ocorrer
  AcaoPreparada prepararAcao({
    required String combatenteId,
    required String condicaoGatilho,
    required TipoAcao tipoAcao,
    required int iniciativaOriginal,
  }) {
    return AcaoPreparada(
      combatenteId: combatenteId,
      condicaoGatilho: condicaoGatilho,
      tipoAcao: tipoAcao,
      iniciativaOriginal: iniciativaOriginal,
    );
  }

  /// R61 e A5: Dispara ação preparada; após agir, a Iniciativa fica imediatamente antes do gatilho
  List<Combatente> dispararAcaoPreparada({
    required List<Combatente> filaAtual,
    required String combatenteId,
    required int iniciativaGatilho,
  }) {
    return ajustarIniciativaPorArbitragem(
      filaAtual: filaAtual,
      combatenteId: combatenteId,
      novaIniciativa: iniciativaGatilho + 1,
    );
  }

  /// R61: Fintar (Enganação vs Reflexos, alcance curto)
  /// Sucesso: alvo desprevenido contra o próximo ataque do atacante
  ResultadoFintar executarFintar({
    required Combatente atacante,
    required Combatente defensor,
    int? d20Enganacao,
    int? d20Reflexos,
    int modEnganacaoAtacante = 0,
    int modReflexosDefensor = 0,
  }) {
    final d20Atk = d20Enganacao ?? _rolarDado(20);
    final d20Def = d20Reflexos ?? _rolarDado(20);
    final totalAtk = d20Atk + modEnganacaoAtacante;
    final totalDef = d20Def + modReflexosDefensor;
    final sucesso = totalAtk >= totalDef;

    Combatente novoDefensor = defensor;
    if (sucesso) {
      final conds = List<CondicaoCombatente>.from(defensor.condicoesAtivas);
      if (!conds.contains(CondicaoCombatente.desprevenido)) {
        conds.add(CondicaoCombatente.desprevenido);
      }
      novoDefensor = defensor.copyWith(condicoesAtivas: conds);
    }

    return ResultadoFintar(
      sucesso: sucesso,
      totalEnganacao: totalAtk,
      totalReflexos: totalDef,
      defensorAtualizado: novoDefensor,
      log: sucesso
          ? "${atacante.nome} fintou ${defensor.nome} com sucesso (Enganação $totalAtk vs Reflexos $totalDef)! Alvo fica desprevenido."
          : "${atacante.nome} falhou em fintar ${defensor.nome} (Enganação $totalAtk vs Reflexos $totalDef).",
    );
  }

  /// R61: Atropelar durante o movimento ou investida (Luta oposta)
  /// Atacante vence: alvo cai e avanço continua. Alvo vence: de pé e interrompe avanço.
  ResultadoAtropelar executarAtropelar({
    required Combatente atacante,
    required Combatente defensor,
    int? d20Atacante,
    int? d20Defensor,
  }) {
    final d20Atk = d20Atacante ?? _rolarDado(20);
    final d20Def = d20Defensor ?? _rolarDado(20);
    final totalAtk = d20Atk + atacante.modLuta;
    final totalDef = d20Def + defensor.modLuta;
    final atacanteVenceu = totalAtk >= totalDef;

    Combatente defensorAtualizado = defensor;
    if (atacanteVenceu) {
      final conds = List<CondicaoCombatente>.from(defensor.condicoesAtivas);
      if (!conds.contains(CondicaoCombatente.caido)) {
        conds.add(CondicaoCombatente.caido);
      }
      defensorAtualizado = defensor.copyWith(condicoesAtivas: conds);
    }

    return ResultadoAtropelar(
      atacanteVenceu: atacanteVenceu,
      totalAtacante: totalAtk,
      totalDefensor: totalDef,
      defensorAtualizado: defensorAtualizado,
      log: atacanteVenceu
          ? "💥 ${atacante.nome} atropelou ${defensor.nome} (Luta $totalAtk vs $totalDef)! O alvo caiu no chão e o avanço continua."
          : "🛡️ ${defensor.nome} resistiu ao atropelamento (Luta $totalDef vs $totalAtk), mantendo-se de pé e interrompendo o avanço.",
    );
  }

  /// R63: Investida (linha reta até 2x deslocamento, mín 3m, proibida em terreno difícil, +2 ataque / -2 Defesa)
  ResultadoInvestida executarInvestida({
    required Combatente atacante,
    required Combatente defensor,
    required Arma arma,
    required double distanciaMetros,
    bool terrenoDificil = false,
    int? d20Teste,
  }) {
    if (terrenoDificil) {
      throw ArgumentError("Investida é proibida em terreno difícil (R63).");
    }
    if (distanciaMetros < 3.0) {
      throw ArgumentError(
          "Investida exige deslocamento mínimo de 3 metros (R63).");
    }
    final dobroDeslocamento = atacante.deslocamentoMetros * 2;
    if (distanciaMetros > dobroDeslocamento) {
      throw ArgumentError(
          "Distância excede o dobro do deslocamento ($dobroDeslocamento m) (R63).");
    }

    final resAtaque = executarAtaque(
      atacante: atacante,
      defensor: defensor,
      arma: arma,
      d20Teste: d20Teste,
      bonusAtaqueExtra: 2,
    );

    return ResultadoInvestida(
      ataque: resAtaque,
      distanciaPercorrida: distanciaMetros,
      penalidadeDefesaAtacante: -2,
      log:
          "⚡ Investida de ${atacante.nome} percorrendo ${distanciaMetros}m (+2 no ataque, -2 na Defesa): ${resAtaque.logResumo}",
    );
  }

  /// R63: Golpe de Misericórdia (alvo adjacente e indefeso, crítico automático, d4 morte instantânea)
  ResultadoGolpeDeMisericordia executarGolpeDeMisericordia({
    required Combatente atacante,
    required Combatente defensor,
    required Arma arma,
    bool ehNpcSecundario = false,
    int? d4Morte,
  }) {
    if (!defensor.estaIndefeso) {
      throw StateError(
          "Golpe de Misericórdia só pode ser executado contra alvo indefeso (R63).");
    }

    // Crítico automático (R63)
    final resAtaque = executarAtaque(
      atacante: atacante,
      defensor: defensor,
      arma: arma,
      d20Teste: 20,
    );

    final d4 = d4Morte ?? _rolarDado(4);
    final morreuInstantaneamente = ehNpcSecundario ? (d4 <= 3) : (d4 == 1);

    Combatente defensorPosGolpe = defensor.aplicarDano(resAtaque.danoTotal);
    if (morreuInstantaneamente) {
      defensorPosGolpe =
          defensorPosGolpe.copyWith(estadoVida: EstadoVidaCombatente.morto);
    }

    return ResultadoGolpeDeMisericordia(
      ataque: resAtaque,
      dadoD4: d4,
      morteInstantanea: morreuInstantaneamente,
      defensorAtualizado: defensorPosGolpe,
      log: morreuInstantaneamente
          ? "💀 Golpe de Misericórdia! ${atacante.nome} causou ${resAtaque.danoTotal} de dano crítico e MORTE INSTANTÂNEA em ${defensor.nome} (d4: $d4)!"
          : "⚔️ Golpe de Misericórdia em ${defensor.nome}: ${resAtaque.danoTotal} de dano crítico (d4: $d4 - sobreviveu à morte instantânea).",
    );
  }

  /// R76: Ataque contra Objeto ou manobra Quebrar
  ResultadoQuebrarObjeto executarManobraQuebrar({
    required Combatente atacante,
    required Arma armaAtacante,
    required int defesaObjeto,
    required int pvMaxObjeto,
    required int pvAtualObjeto,
    int rdObjeto = 0,
    int? d20Teste,
  }) {
    final d20 = d20Teste ?? _rolarDado(20);
    final totalAtk = d20 + atacante.modLuta + armaAtacante.bonusAtaqueMelhorias;
    final acertou = totalAtk >= defesaObjeto;

    if (!acertou) {
      return ResultadoQuebrarObjeto(
        acerto: false,
        danoCausado: 0,
        pvRestantesObjeto: pvAtualObjeto,
        objetoDestruido: false,
        log: "${atacante.nome} tentou quebrar o objeto e errou (Ataque $totalAtk vs Defesa $defesaObjeto).",
      );
    }

    final dadosInfo = _extrairDadosArma(armaAtacante.dano);
    int danoBruto = 0;
    for (int i = 0; i < dadosInfo.quantidade; i++) {
      danoBruto += _rolarDado(dadosInfo.faces);
    }
    danoBruto += dadosInfo.bonusFixo +
        armaAtacante.bonusDanoMelhorias +
        atacante.modForca;

    final danoEfetivo = max(0, danoBruto - rdObjeto);
    final novosPv = max(0, pvAtualObjeto - danoEfetivo);
    final destruido = novosPv <= 0;

    return ResultadoQuebrarObjeto(
      acerto: true,
      danoCausado: danoEfetivo,
      pvRestantesObjeto: novosPv,
      objetoDestruido: destruido,
      log: destruido
          ? "💥 ${atacante.nome} acertou o objeto causando $danoEfetivo de dano (após RD $rdObjeto) e DESTRUIU o objeto!"
          : "🔨 ${atacante.nome} causou $danoEfetivo de dano no objeto (PV: $novosPv/$pvMaxObjeto).",
    );
  }

  /// Processa sangramento e estabilização no início do turno (R71)
  (Combatente, String) processarInicioTurno(Combatente combatente) {
    if (combatente.estadoVida == EstadoVidaCombatente.inconscienteSangrando) {
      final d20 = _rolarDado(20);
      final d6Sangramento = _rolarDado(6);
      return combatente.testeEstabilizacaoCon(d20, d6Sangramento);
    }
    return (combatente, "");
  }

  /// Verifica se o combate chegou ao fim (Vitória ou Derrota)
  StatusCombate verificarFimDeCombate(List<Combatente> participantes) {
    final heroisVivos = participantes
        .where((c) => c.time == TimeCombatente.heroi && c.podeAgir)
        .toList();

    final inimigosVivos = participantes
        .where((c) => c.time == TimeCombatente.inimigo && c.podeAgir)
        .toList();

    if (inimigosVivos.isEmpty && heroisVivos.isNotEmpty) {
      return StatusCombate.vitoria;
    }

    if (heroisVivos.isEmpty) {
      return StatusCombate.derrota;
    }

    return StatusCombate.emAndamento;
  }

  /// Executa o teste de ataque, cálculo de crítico, modificadores situacionais e dano (R65, R66, R67, R74, I4, I5)
  ResultadoAtaque executarAtaque({
    required Combatente atacante,
    required Combatente defensor,
    required Arma arma,
    bool alvoEngajadoEmCorpoACorpo = false,
    bool mirou = false,
    bool ataqueNaoLetal = false,
    bool alcanceDobrado = false,
    bool posicaoElevada = false,
    bool flanqueando = false,
    bool coberturaLeve = false,
    bool coberturaTotal = false,
    bool camuflagemLeve = false,
    bool camuflagemTotal = false,
    int? d20Teste,
    int? d100ChanceFalha,
    int bonusAtaqueExtra = 0,
    int bonusDanoExtra = 0,
  }) {
    final tipoDano = TipoDano.fromString(arma.tipoDano.name);

    // R74: Cobertura total = não pode ser atacado
    if (coberturaTotal) {
      return ResultadoAtaque(
        atacanteNome: atacante.nome,
        defensorNome: defensor.nome,
        armaNome: arma.nome,
        acerto: false,
        ehCritico: false,
        valorDadoNatural: 0,
        totalAtaque: 0,
        defesaAlvo: defensor.defesa,
        danoTotal: 0,
        tipoDano: tipoDano,
        detalheDano: "Alvo possui Cobertura Total e não pode ser atacado (R74).",
        logResumo:
            "${atacante.nome} não pode atacar ${defensor.nome} devido à Cobertura Total.",
      );
    }

    // R74 e I4: Avaliação de Chance de Falha (camuflagem leve 20%, total 50%, cego 50%, teto 75%)
    final listaChances = <ModificadorAplicado>[];
    if (atacante.estaCego) {
      listaChances.add(
        const ModificadorAplicado(
          fonteTipo: FonteModificador.ambiente,
          fonteId: 'CEGO',
          alvoCaracteristica: 'CHANCE_FALHA',
          valor: 50,
        ),
      );
    }
    if (camuflagemTotal) {
      listaChances.add(
        const ModificadorAplicado(
          fonteTipo: FonteModificador.ambiente,
          fonteId: 'CAMUFLAGEM_TOTAL',
          alvoCaracteristica: 'CHANCE_FALHA',
          valor: 50,
        ),
      );
    } else if (camuflagemLeve) {
      listaChances.add(
        const ModificadorAplicado(
          fonteTipo: FonteModificador.ambiente,
          fonteId: 'CAMUFLAGEM_LEVE',
          alvoCaracteristica: 'CHANCE_FALHA',
          valor: 20,
        ),
      );
    }

    if (listaChances.isNotEmpty) {
      final resFalha = modEngine.calcularChanceFalha(
        listaChances,
        rng: d100ChanceFalha != null
            ? SequenciaRng([10], valoresD100: [d100ChanceFalha])
            : _rng,
      );
      if (resFalha.falhou) {
        return ResultadoAtaque(
          atacanteNome: atacante.nome,
          defensorNome: defensor.nome,
          armaNome: arma.nome,
          acerto: false,
          ehCritico: false,
          valorDadoNatural: d20Teste ?? 0,
          totalAtaque: 0,
          defesaAlvo: defensor.defesa,
          danoTotal: 0,
          tipoDano: tipoDano,
          detalheDano:
              "Errou por Chance de Falha (${resFalha.chanceEfetiva}%, d100: ${resFalha.d100Rolado}).",
          logResumo:
              "${atacante.nome} errou o ataque em ${defensor.nome} por chance de falha (${resFalha.chanceEfetiva}%).",
        );
      }
    }

    final bool ehCorpoACorpo = arma.ehCorpoACorpo;
    final int bonusPericia =
        ehCorpoACorpo ? atacante.modLuta : atacante.modPontaria;

    // Modificadores no Teste de Ataque (R61, R72, R74)
    int modAtaque =
        bonusPericia + arma.bonusAtaqueMelhorias + bonusAtaqueExtra;

    if (!ehCorpoACorpo && alvoEngajadoEmCorpoACorpo && !mirou) {
      modAtaque -= 5; // R61
    }
    if (!ehCorpoACorpo && alcanceDobrado) {
      modAtaque -= 5; // R61
    }
    if (ataqueNaoLetal) {
      modAtaque -= 5; // R72
    }
    if (atacante.estaCaido) {
      modAtaque -= 5; // R74
    }
    if (posicaoElevada) {
      modAtaque += 2; // R74
    }
    if (flanqueando && ehCorpoACorpo) {
      modAtaque += 2; // R74, R75
    }
    if (atacante.estaInvisivel && !defensor.estaCego) {
      modAtaque += 5; // R74
    }

    // Modificadores na Defesa do Alvo (R74)
    int defesaEfetiva = defensor.defesa;
    if (defensor.estaCaido) {
      defesaEfetiva += ehCorpoACorpo ? -5 : 5; // R74
    }
    if (defensor.estaCego) {
      defesaEfetiva -= 5; // R74
    }
    if (defensor.estaDesprevenido) {
      defesaEfetiva -= 5; // R74
    }
    if (coberturaLeve) {
      defesaEfetiva += 5; // R74
    }

    // Rolagem do d20
    final d20 = d20Teste ?? _rolarDado(20);
    final totalAtaque = d20 + modAtaque;

    // Regras de Acerto (R65, A3)
    final bool ehAcertoAutomatico =
        configuracoes.nat20E1AutomaticoEmAtaque && (d20 == 20);
    final bool ehErroAutomatico =
        configuracoes.nat20E1AutomaticoEmAtaque && (d20 == 1);
    final bool acertou = ehAcertoAutomatico ||
        (!ehErroAutomatico && totalAtaque >= defesaEfetiva);

    // Acerto Crítico (R67): arma.margemAmeacaEfetiva; criaturas imunes recebem dano normal
    final margem = arma.margemAmeacaEfetiva;
    final bool ehCritico = acertou &&
        (d20 >= margem) &&
        !defensor.imuneACritico;

    if (!acertou) {
      final motivoErro = ehErroAutomatico
          ? "Falha Crítica (1 natural)"
          : "Ataque $totalAtaque vs Defesa $defesaEfetiva";
      return ResultadoAtaque(
        atacanteNome: atacante.nome,
        defensorNome: defensor.nome,
        armaNome: arma.nome,
        acerto: false,
        ehCritico: false,
        valorDadoNatural: d20,
        totalAtaque: totalAtaque,
        defesaAlvo: defesaEfetiva,
        danoTotal: 0,
        tipoDano: tipoDano,
        detalheDano: "Errou o ataque ($motivoErro).",
        logResumo:
            "${atacante.nome} atacou ${defensor.nome} com ${arma.nome} e errou [$motivoErro].",
      );
    }

    // Cálculo do Dano (R65, R67)
    final dadosInfo = _extrairDadosArma(
      arma.danoEfetivo.isNotEmpty ? arma.danoEfetivo : arma.dano,
    );
    final int qtdDadosBase = dadosInfo.quantidade;
    final int facesDado = dadosInfo.faces;

    final int multiplicador =
        ehCritico ? arma.multiplicadorCriticoEfetivo : 1;
    final int qtdDadosFinais = qtdDadosBase * multiplicador;

    final rolagensDano = <int>[];
    for (int i = 0; i < qtdDadosFinais; i++) {
      rolagensDano.add(_rolarDado(facesDado));
    }
    final int somaDadosDano = rolagensDano.fold(0, (a, b) => a + b);

    // Bônus de Força em corpo a corpo e arremesso (R65)
    int bonusAtributo = 0;
    if (arma.somaForcaAoDano) {
      bonusAtributo = atacante.modForca;
    }

    // Crítico não multiplica bônus numéricos nem dados extras (R67)
    final int danoFinal = max(
      1,
      somaDadosDano +
          dadosInfo.bonusFixo +
          arma.bonusDanoMelhorias +
          bonusAtributo +
          bonusDanoExtra,
    );

    final tipoRotulo = ataqueNaoLetal ? "Não Letal" : tipoDano.label;

    final String detalheDanoStr = ehCritico
        ? "CRÍTICO (${arma.criticoFormatado})! Dados: $rolagensDano (Total: $somaDadosDano) + $bonusAtributo (FOR) + ${dadosInfo.bonusFixo + arma.bonusDanoMelhorias + bonusDanoExtra} = $danoFinal de $tipoRotulo"
        : "Dados: $rolagensDano (Total: $somaDadosDano) + $bonusAtributo (FOR) + ${dadosInfo.bonusFixo + arma.bonusDanoMelhorias + bonusDanoExtra} = $danoFinal de $tipoRotulo";

    final String resumoStr = ehCritico
        ? "${atacante.nome} acertou um CRÍTICO em ${defensor.nome} com ${arma.nome}! Dano: $danoFinal ($tipoRotulo)."
        : "${atacante.nome} acertou ${defensor.nome} com ${arma.nome}! Dano: $danoFinal ($tipoRotulo).";

    return ResultadoAtaque(
      atacanteNome: atacante.nome,
      defensorNome: defensor.nome,
      armaNome: arma.nome,
      acerto: true,
      ehCritico: ehCritico,
      valorDadoNatural: d20,
      totalAtaque: totalAtaque,
      defesaAlvo: defesaEfetiva,
      danoTotal: danoFinal,
      tipoDano: tipoDano,
      detalheDano: detalheDanoStr,
      logResumo: resumoStr,
    );
  }

  int _rolarDado(int faces) {
    if (faces == 20) return _rng.rolarD20();
    if (faces == 100) return _rng.rolarD100();
    return _random.nextInt(faces) + 1;
  }

  static final _regexDanoArma =
      RegExp(r'^(\d+)[dD](\d+)(?:\s*([+-])\s*(\d+))?');

  _DadosArmaInfo _extrairDadosArma(String danoStr) {
    final match = _regexDanoArma.firstMatch(danoStr.trim());
    if (match != null) {
      final qtd = int.parse(match.group(1)!);
      final faces = int.parse(match.group(2)!);
      int bonusFixo = 0;
      if (match.group(3) != null && match.group(4) != null) {
        final sinal = match.group(3) == '-' ? -1 : 1;
        bonusFixo = sinal * int.parse(match.group(4)!);
      }
      return _DadosArmaInfo(
        quantidade: qtd,
        faces: faces,
        bonusFixo: bonusFixo,
      );
    }
    return const _DadosArmaInfo(quantidade: 1, faces: 6, bonusFixo: 0);
  }
}

class _DadosArmaInfo {
  final int quantidade;
  final int faces;
  final int bonusFixo;

  const _DadosArmaInfo({
    required this.quantidade,
    required this.faces,
    this.bonusFixo = 0,
  });
}
