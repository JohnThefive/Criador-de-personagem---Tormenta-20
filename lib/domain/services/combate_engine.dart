import 'dart:math';
import '../entities/arma.dart';
import '../entities/combate/combatente.dart';
import '../entities/combate/estado_vida_combatente.dart';
import '../entities/combate/resultado_ataque.dart';
import '../entities/combate/tipo_dano.dart';

enum StatusCombate { emAndamento, vitoria, derrota }

class CombateEngine {
  final Random _random;

  CombateEngine({Random? random}) : _random = random ?? Random();

  /// Rola 1d20 + Iniciativa e ordena os turnos respeitando os desempates do T20
  List<Combatente> rolarIniciativa(List<Combatente> participantes) {
    final list = <Combatente>[];

    for (final p in participantes) {
      final d20 = _rolarDado(20);
      final total = d20 + p.modIniciativa;
      list.add(p.copyWith(iniciativaValor: total));
    }

    // Ordenação decrescente com regras de desempate
    list.sort((a, b) {
      // 1. Maior valor total de iniciativa
      if (b.iniciativaValor != a.iniciativaValor) {
        return b.iniciativaValor.compareTo(a.iniciativaValor);
      }
      // 2. Desempate T20: Maior bônus da perícia Iniciativa
      if (b.modIniciativa != a.modIniciativa) {
        return b.modIniciativa.compareTo(a.modIniciativa);
      }
      // 3. Persistindo empate: Rolagem d20 extra interna
      return _rolarDado(20).compareTo(_rolarDado(20));
    });

    return list;
  }

  /// Permite atrasar a iniciativa voluntariamente até o limite de (-10 - modIniciativa)
  List<Combatente> atrasarIniciativa({
    required List<Combatente> filaAtual,
    required String combatenteId,
    required int novaIniciativa,
  }) {
    final index = filaAtual.indexWhere((c) => c.id == combatenteId);
    if (index == -1) return filaAtual;

    final combatente = filaAtual[index];
    final limiteMinimo = -10 - combatente.modIniciativa;
    final valorAjustado = max(novaIniciativa, limiteMinimo);

    final atualizada = List<Combatente>.from(filaAtual);
    atualizada[index] = combatente.copyWith(iniciativaValor: valorAjustado);

    atualizada.sort((a, b) => b.iniciativaValor.compareTo(a.iniciativaValor));
    return atualizada;
  }

  /// Processa sangramento e estabilização no início do turno
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

  /// Executa o teste de ataque, cálculo de crítico e dano final (letal ou não letal)
  ResultadoAtaque executarAtaque({
    required Combatente atacante,
    required Combatente defensor,
    required Arma arma,
    bool alvoEngajadoEmCorpoACorpo = false,
    bool mirou = false,
    bool ataqueNaoLetal = false,
    int? d20Teste,
  }) {
    final bool ehCorpoACorpo = arma.ehCorpoACorpo;
    final int bonusPericia = ehCorpoACorpo
        ? atacante.modLuta
        : atacante.modPontaria;

    // Penalidade de disparo à distância contra alvo em combate corpo a corpo (-5),
    // anulada se o atacante usou a ação de movimento para "Mirar"
    int penalidadeDistancia = 0;
    if (!ehCorpoACorpo && alvoEngajadoEmCorpoACorpo && !mirou) {
      penalidadeDistancia = -5;
    }

    // T20: Ataque não letal com arma letal aplica -5 no teste de ataque
    int penalidadeNaoLetal = ataqueNaoLetal ? -5 : 0;

    // Rolagem do teste de ataque
    final d20 = d20Teste ?? _rolarDado(20);
    final totalAtaque =
        d20 + bonusPericia + penalidadeDistancia + penalidadeNaoLetal;

    // Regras de Acerto:
    // - 20 Natural: Acerto automático
    // - 1 Natural: Erro automático
    // - Caso normal: Total >= Defesa do alvo
    final bool ehAcertoAutomatico = (d20 == 20);
    final bool ehErroAutomatico = (d20 == 1);
    final bool acertou =
        ehAcertoAutomatico ||
        (!ehErroAutomatico && totalAtaque >= defensor.defesa);

    // Acerto Crítico (d20 natural >= margemAmeaca da arma)
    final bool ehCritico = acertou && (d20 >= arma.margemAmeaca);

    final tipoDano = TipoDano.fromString(arma.tipoDano.name);

    if (!acertou) {
      final motivoErro = ehErroAutomatico
          ? "Falha Crítica (1 natural)"
          : "Ataque $totalAtaque vs Defesa ${defensor.defesa}";
      return ResultadoAtaque(
        atacanteNome: atacante.nome,
        defensorNome: defensor.nome,
        armaNome: arma.nome,
        acerto: false,
        ehCritico: false,
        valorDadoNatural: d20,
        totalAtaque: totalAtaque,
        defesaAlvo: defensor.defesa,
        danoTotal: 0,
        tipoDano: tipoDano,
        detalheDano: "Errou o ataque ($motivoErro).",
        logResumo:
            "${atacante.nome} atacou ${defensor.nome} com ${arma.nome} e errou [$motivoErro].",
      );
    }

    // Cálculo do Dano
    final dadosInfo = _extrairDadosArma(arma.dano);
    final int qtdDadosBase = dadosInfo.quantidade;
    final int facesDado = dadosInfo.faces;

    // T20: No crítico, apenas os dados da arma são multiplicados
    final int qtdDadosFinais = ehCritico
        ? qtdDadosBase * arma.multiplicadorCritico
        : qtdDadosBase;

    final rolagensDano = <int>[];
    for (int i = 0; i < qtdDadosFinais; i++) {
      rolagensDano.add(_rolarDado(facesDado));
    }
    final int somaDadosDano = rolagensDano.fold(0, (a, b) => a + b);

    // Bônus numérico de Força: apenas corpo a corpo e arremesso (disparo não soma)
    int bonusAtributo = 0;
    if (arma.somaForcaAoDano) {
      bonusAtributo = atacante.modForca;
    }

    final int danoFinal = max(1, somaDadosDano + bonusAtributo);

    final tipoRotulo = ataqueNaoLetal ? "Não Letal" : tipoDano.label;

    final String detalheDanoStr = ehCritico
        ? "CRÍTICO (${arma.criticoFormatado})! Dados: $rolagensDano (Total: $somaDadosDano) + $bonusAtributo (FOR) = $danoFinal de $tipoRotulo"
        : "Dados: $rolagensDano (Total: $somaDadosDano) + $bonusAtributo (FOR) = $danoFinal de $tipoRotulo";

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
      defesaAlvo: defensor.defesa,
      danoTotal: danoFinal,
      tipoDano: tipoDano,
      detalheDano: detalheDanoStr,
      logResumo: resumoStr,
    );
  }

  int _rolarDado(int faces) => _random.nextInt(faces) + 1;

  _DadosArmaInfo _extrairDadosArma(String danoStr) {
    final exp = RegExp(r'^(\d+)[dD](\d+)');
    final match = exp.firstMatch(danoStr.trim());
    if (match != null) {
      return _DadosArmaInfo(
        quantidade: int.parse(match.group(1)!),
        faces: int.parse(match.group(2)!),
      );
    }
    return const _DadosArmaInfo(quantidade: 1, faces: 6);
  }
}

class _DadosArmaInfo {
  final int quantidade;
  final int faces;

  const _DadosArmaInfo({required this.quantidade, required this.faces});
}
