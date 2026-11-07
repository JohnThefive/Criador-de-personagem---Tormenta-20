/// Define como a interrupção de um Teste Estendido impacta o contador de falhas (R20).
enum TipoInterrupcaoEstendido {
  nada,
  umaFalha,
  falhaTotal,
}

/// R24: Métrica de distância no grid tático.
enum MetricaDistanciaGrid {
  chebyshev,
  alternada,
  euclidiana,
}

/// R41: Modo de cobrança de habilidades sustentadas no início do turno.
enum ModoSustentacao {
  perguntar,
  automatico,
}

/// R42 e R59: Momento de expiração de durações definidas em rodadas.
enum ModoExpiracaoRodadas {
  antesDaMesmaIniciativa,
  viradaDeRodada,
  inicioTurnoDoUsuario,
}

/// R45: Modo de disparo de efeitos com modificador "descarregar".
enum ModoDescarga {
  automatica,
  perguntarAoDono,
}

/// Configurações da mesa para o Motor de Testes (Módulo 1) e Motor de Habilidades e Duração (Módulo 2).
///
/// Centraliza todas as decisões padrão assumidas na especificação (R1–R49),
/// permitindo que o mestre altere qualquer comportamento nas opções da mesa.
class ConfiguracoesMesaT20 {
  // --- MÓDULO 1: TESTES (R1–R21) ---

  /// R3: 20 natural no dado garante sucesso automático contra CD, mesmo se total < CD.
  final bool nat20SucessoAutomaticoContraCd;

  /// R3: 1 natural no dado garante falha automática contra CD, mesmo se total >= CD.
  final bool nat1FalhaAutomaticaContraCd;

  /// R3: Em testes opostos, 20/1 natural decidem automaticamente o vencedor antes do total?
  /// Decisão padrão: `false` (a comparação segue pelo total).
  final bool nat20E1DecidemTesteOposto;

  /// R5: Penalidade aplicada quando a perícia exige ferramenta/kit e o personagem não a possui.
  final int penalidadeSemFerramenta;

  /// R7: CD padrão para o teste de perícia de cada ajudante.
  final int cdAjudaPadrao;

  /// R8: Bônus base concedido pelo ajudante ao passar na CD de ajuda.
  final int bonusBaseAjuda;

  /// R8: Intervalo de pontos acima da CD de ajuda para cada +1 extra.
  final int intervaloBonusExtraAjuda;

  /// R12: Permite usar "Escolher 20" dentro de Testes Estendidos?
  final bool permitirEscolher20EmTesteEstendido;

  /// R14: Em testes estendidos com múltiplas perícias, sucessos acima da meta
  /// de uma perícia contam para abater metas de outras perícias?
  final bool excedenteMetaPericiaContaParaOutras;

  /// R17: Em testes estendidos, a perícia usada para ajudar fica consumida no desafio?
  final bool consumirPericiaAjudaEmTesteEstendido;

  /// R18: Incremento de CD a cada teste realizado quando a dificuldade cumulativa está ativa.
  final int incrementoCdCumulativaEstendido;

  /// R13: Quantidade padrão de falhas que leva à FALHA_TOTAL em um Teste Estendido.
  final int maxFalhasPadraoEstendido;

  /// R20: Comportamento padrão ao interromper um Teste Estendido caso não informado.
  final TipoInterrupcaoEstendido interrupcaoContaPadrao;

  // --- MÓDULO 2: HABILIDADES, MODIFICADORES, GRID E DURAÇÃO (R22–R49) ---

  /// R24: Métrica de cálculo de distância no grid (padrão: Chebyshev).
  final MetricaDistanciaGrid metricaDistancia;

  /// R24: Alcance ILIMITADO exige aprovação do mestre caso a caso (padrão: `true`).
  final bool alcanceIlimitadoExigeAprovacaoMestre;

  /// R27: Reduções de custo de PM acumulam entre si? (padrão: `false`, vale apenas a maior redução).
  final bool reducoesCustoPmAcumulam;

  /// R29: Dentro de uma mesma fonte que não acumula, mantém o melhor bônus e a pior penalidade? (padrão: `true`).
  final bool mesmaFonteMantemMelhorBonusPiorPenalidade;

  /// R29: Quantidade máxima de itens adicionais (além de armadura e escudo) que somam bônus na Defesa (padrão: `1`).
  final int limiteItensAdicionaisDefesa;

  /// R29: Teto percentual para soma de chance de falha (padrão: `75`, mínimo 25% de sucesso).
  final int tetoChanceFalhaPercentual;

  /// R30: Máximo de repetições (rerolls) permitidas por rolagem antes da declaração (padrão: `1`).
  final int maxRerolagensPorTeste;

  /// R30: Timeout opcional em segundos para declaração automática de resultado de teste (`null` = manual).
  final int? timeoutDeclaracaoAutomaticaSegundos;

  /// R34: No teste para atingir área não percebida (CD 20 + PM), usar o custo final em PM já reduzido? (padrão: `true`).
  final bool testeAreaNaoPercebidaUsaCustoFinal;

  /// R34: No cone, a largura na extremidade final é igual ao comprimento? (padrão: `true`).
  final bool coneLarguraFinalIgualComprimento;

  /// R38 / R42: Duração de 1 rodada em segundos de jogo (padrão: `6`).
  final int segundosPorRodada;

  /// R41: Primeiro pagamento de sustentação ocorre apenas no início do próximo turno do usuário (padrão: `true`).
  final bool sustentacaoPrimeiroPagamentoProximoTurno;

  /// R41: Modo de resolução de sustentação no início do turno (padrão: `perguntar`).
  final ModoSustentacao sustentacaoModo;

  /// R42: Momento em que expiram durações definidas em rodadas (padrão: `viradaDeRodada`).
  final ModoExpiracaoRodadas expiracaoRodadas;

  /// R45: Modo de disparo de efeitos dormentes com `descarregar` (padrão: `automatica`).
  final ModoDescarga descargaModo;

  /// R48: Reativar a mesma habilidade pelo mesmo usuário sobre o mesmo alvo substitui a anterior e reinicia a duração? (padrão: `true`).
  final bool reativarMesmoAlvoSubstituiAnterior;

  // --- MÓDULO 3: RESISTÊNCIA, OBJETOS E TIPOS DE EFEITO (R50–R58) ---

  /// R55: Repetir o teste de resistência a cada nova entrada em uma área persistente? (padrão: `false`).
  final bool repetirTesteResistenciaCadaEntradaArea;

  /// R57: Quando um efeito possui múltiplos tipos e o alvo é imune a um deles, se não separável, ignora o efeito inteiro? (padrão: `true`).
  final bool imunidadeParcialOuTotal;

  /// R56: Item mágico solto sempre usa o bônus próprio no teste de resistência? (padrão: `true`).
  final bool itemMagicoSoltoUsaBonusProprio;

  /// R65 e A3: 20 natural garante acerto automático e 1 natural garante erro automático em ataques.
  final bool nat20E1AutomaticoEmAtaque;

  const ConfiguracoesMesaT20({
    this.nat20SucessoAutomaticoContraCd = true,
    this.nat1FalhaAutomaticaContraCd = true,
    this.nat20E1DecidemTesteOposto = false,
    this.nat20E1AutomaticoEmAtaque = true,
    this.penalidadeSemFerramenta = -5,
    this.cdAjudaPadrao = 10,
    this.bonusBaseAjuda = 1,
    this.intervaloBonusExtraAjuda = 10,
    this.permitirEscolher20EmTesteEstendido = false,
    this.excedenteMetaPericiaContaParaOutras = false,
    this.consumirPericiaAjudaEmTesteEstendido = true,
    this.incrementoCdCumulativaEstendido = 2,
    this.maxFalhasPadraoEstendido = 3,
    this.interrupcaoContaPadrao = TipoInterrupcaoEstendido.nada,
    this.metricaDistancia = MetricaDistanciaGrid.chebyshev,
    this.alcanceIlimitadoExigeAprovacaoMestre = true,
    this.reducoesCustoPmAcumulam = false,
    this.mesmaFonteMantemMelhorBonusPiorPenalidade = true,
    this.limiteItensAdicionaisDefesa = 1,
    this.tetoChanceFalhaPercentual = 75,
    this.maxRerolagensPorTeste = 1,
    this.timeoutDeclaracaoAutomaticaSegundos,
    this.testeAreaNaoPercebidaUsaCustoFinal = true,
    this.coneLarguraFinalIgualComprimento = true,
    this.segundosPorRodada = 6,
    this.sustentacaoPrimeiroPagamentoProximoTurno = true,
    this.sustentacaoModo = ModoSustentacao.perguntar,
    this.expiracaoRodadas = ModoExpiracaoRodadas.antesDaMesmaIniciativa,
    this.descargaModo = ModoDescarga.automatica,
    this.reativarMesmoAlvoSubstituiAnterior = true,
    this.repetirTesteResistenciaCadaEntradaArea = false,
    this.imunidadeParcialOuTotal = true,
    this.itemMagicoSoltoUsaBonusProprio = true,
  });

  ConfiguracoesMesaT20 copyWith({
    bool? nat20SucessoAutomaticoContraCd,
    bool? nat1FalhaAutomaticaContraCd,
    bool? nat20E1DecidemTesteOposto,
    int? penalidadeSemFerramenta,
    int? cdAjudaPadrao,
    int? bonusBaseAjuda,
    int? intervaloBonusExtraAjuda,
    bool? permitirEscolher20EmTesteEstendido,
    bool? excedenteMetaPericiaContaParaOutras,
    bool? consumirPericiaAjudaEmTesteEstendido,
    int? incrementoCdCumulativaEstendido,
    int? maxFalhasPadraoEstendido,
    TipoInterrupcaoEstendido? interrupcaoContaPadrao,
    MetricaDistanciaGrid? metricaDistancia,
    bool? alcanceIlimitadoExigeAprovacaoMestre,
    bool? reducoesCustoPmAcumulam,
    bool? mesmaFonteMantemMelhorBonusPiorPenalidade,
    int? limiteItensAdicionaisDefesa,
    int? tetoChanceFalhaPercentual,
    int? maxRerolagensPorTeste,
    int? timeoutDeclaracaoAutomaticaSegundos,
    bool? testeAreaNaoPercebidaUsaCustoFinal,
    bool? coneLarguraFinalIgualComprimento,
    int? segundosPorRodada,
    bool? sustentacaoPrimeiroPagamentoProximoTurno,
    ModoSustentacao? sustentacaoModo,
    ModoExpiracaoRodadas? expiracaoRodadas,
    ModoDescarga? descargaModo,
    bool? reativarMesmoAlvoSubstituiAnterior,
    bool? repetirTesteResistenciaCadaEntradaArea,
    bool? imunidadeParcialOuTotal,
    bool? itemMagicoSoltoUsaBonusProprio,
    bool? nat20E1AutomaticoEmAtaque,
  }) {
    return ConfiguracoesMesaT20(
      nat20SucessoAutomaticoContraCd:
          nat20SucessoAutomaticoContraCd ?? this.nat20SucessoAutomaticoContraCd,
      nat1FalhaAutomaticaContraCd:
          nat1FalhaAutomaticaContraCd ?? this.nat1FalhaAutomaticaContraCd,
      nat20E1DecidemTesteOposto:
          nat20E1DecidemTesteOposto ?? this.nat20E1DecidemTesteOposto,
      nat20E1AutomaticoEmAtaque:
          nat20E1AutomaticoEmAtaque ?? this.nat20E1AutomaticoEmAtaque,
      penalidadeSemFerramenta:
          penalidadeSemFerramenta ?? this.penalidadeSemFerramenta,
      cdAjudaPadrao: cdAjudaPadrao ?? this.cdAjudaPadrao,
      bonusBaseAjuda: bonusBaseAjuda ?? this.bonusBaseAjuda,
      intervaloBonusExtraAjuda:
          intervaloBonusExtraAjuda ?? this.intervaloBonusExtraAjuda,
      permitirEscolher20EmTesteEstendido: permitirEscolher20EmTesteEstendido ??
          this.permitirEscolher20EmTesteEstendido,
      excedenteMetaPericiaContaParaOutras:
          excedenteMetaPericiaContaParaOutras ??
              this.excedenteMetaPericiaContaParaOutras,
      consumirPericiaAjudaEmTesteEstendido:
          consumirPericiaAjudaEmTesteEstendido ??
              this.consumirPericiaAjudaEmTesteEstendido,
      incrementoCdCumulativaEstendido: incrementoCdCumulativaEstendido ??
          this.incrementoCdCumulativaEstendido,
      maxFalhasPadraoEstendido:
          maxFalhasPadraoEstendido ?? this.maxFalhasPadraoEstendido,
      interrupcaoContaPadrao:
          interrupcaoContaPadrao ?? this.interrupcaoContaPadrao,
      metricaDistancia: metricaDistancia ?? this.metricaDistancia,
      alcanceIlimitadoExigeAprovacaoMestre:
          alcanceIlimitadoExigeAprovacaoMestre ??
              this.alcanceIlimitadoExigeAprovacaoMestre,
      reducoesCustoPmAcumulam:
          reducoesCustoPmAcumulam ?? this.reducoesCustoPmAcumulam,
      mesmaFonteMantemMelhorBonusPiorPenalidade:
          mesmaFonteMantemMelhorBonusPiorPenalidade ??
              this.mesmaFonteMantemMelhorBonusPiorPenalidade,
      limiteItensAdicionaisDefesa:
          limiteItensAdicionaisDefesa ?? this.limiteItensAdicionaisDefesa,
      tetoChanceFalhaPercentual:
          tetoChanceFalhaPercentual ?? this.tetoChanceFalhaPercentual,
      maxRerolagensPorTeste:
          maxRerolagensPorTeste ?? this.maxRerolagensPorTeste,
      timeoutDeclaracaoAutomaticaSegundos:
          timeoutDeclaracaoAutomaticaSegundos ??
              this.timeoutDeclaracaoAutomaticaSegundos,
      testeAreaNaoPercebidaUsaCustoFinal: testeAreaNaoPercebidaUsaCustoFinal ??
          this.testeAreaNaoPercebidaUsaCustoFinal,
      coneLarguraFinalIgualComprimento: coneLarguraFinalIgualComprimento ??
          this.coneLarguraFinalIgualComprimento,
      segundosPorRodada: segundosPorRodada ?? this.segundosPorRodada,
      sustentacaoPrimeiroPagamentoProximoTurno:
          sustentacaoPrimeiroPagamentoProximoTurno ??
              this.sustentacaoPrimeiroPagamentoProximoTurno,
      sustentacaoModo: sustentacaoModo ?? this.sustentacaoModo,
      expiracaoRodadas: expiracaoRodadas ?? this.expiracaoRodadas,
      descargaModo: descargaModo ?? this.descargaModo,
      reativarMesmoAlvoSubstituiAnterior: reativarMesmoAlvoSubstituiAnterior ??
          this.reativarMesmoAlvoSubstituiAnterior,
      repetirTesteResistenciaCadaEntradaArea:
          repetirTesteResistenciaCadaEntradaArea ??
              this.repetirTesteResistenciaCadaEntradaArea,
      imunidadeParcialOuTotal:
          imunidadeParcialOuTotal ?? this.imunidadeParcialOuTotal,
      itemMagicoSoltoUsaBonusProprio:
          itemMagicoSoltoUsaBonusProprio ?? this.itemMagicoSoltoUsaBonusProprio,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nat20SucessoAutomaticoContraCd': nat20SucessoAutomaticoContraCd,
      'nat1FalhaAutomaticaContraCd': nat1FalhaAutomaticaContraCd,
      'nat20E1DecidemTesteOposto': nat20E1DecidemTesteOposto,
      'nat20E1AutomaticoEmAtaque': nat20E1AutomaticoEmAtaque,
      'penalidadeSemFerramenta': penalidadeSemFerramenta,
      'cdAjudaPadrao': cdAjudaPadrao,
      'bonusBaseAjuda': bonusBaseAjuda,
      'intervaloBonusExtraAjuda': intervaloBonusExtraAjuda,
      'permitirEscolher20EmTesteEstendido': permitirEscolher20EmTesteEstendido,
      'excedenteMetaPericiaContaParaOutras':
          excedenteMetaPericiaContaParaOutras,
      'consumirPericiaAjudaEmTesteEstendido':
          consumirPericiaAjudaEmTesteEstendido,
      'incrementoCdCumulativaEstendido': incrementoCdCumulativaEstendido,
      'maxFalhasPadraoEstendido': maxFalhasPadraoEstendido,
      'interrupcaoContaPadrao': interrupcaoContaPadrao.name,
      'metricaDistancia': metricaDistancia.name,
      'alcanceIlimitadoExigeAprovacaoMestre':
          alcanceIlimitadoExigeAprovacaoMestre,
      'reducoesCustoPmAcumulam': reducoesCustoPmAcumulam,
      'mesmaFonteMantemMelhorBonusPiorPenalidade':
          mesmaFonteMantemMelhorBonusPiorPenalidade,
      'limiteItensAdicionaisDefesa': limiteItensAdicionaisDefesa,
      'tetoChanceFalhaPercentual': tetoChanceFalhaPercentual,
      'maxRerolagensPorTeste': maxRerolagensPorTeste,
      'timeoutDeclaracaoAutomaticaSegundos':
          timeoutDeclaracaoAutomaticaSegundos,
      'testeAreaNaoPercebidaUsaCustoFinal': testeAreaNaoPercebidaUsaCustoFinal,
      'coneLarguraFinalIgualComprimento': coneLarguraFinalIgualComprimento,
      'segundosPorRodada': segundosPorRodada,
      'sustentacaoPrimeiroPagamentoProximoTurno':
          sustentacaoPrimeiroPagamentoProximoTurno,
      'sustentacaoModo': sustentacaoModo.name,
      'expiracaoRodadas': expiracaoRodadas.name,
      'descargaModo': descargaModo.name,
      'reativarMesmoAlvoSubstituiAnterior': reativarMesmoAlvoSubstituiAnterior,
      'repetirTesteResistenciaCadaEntradaArea':
          repetirTesteResistenciaCadaEntradaArea,
      'imunidadeParcialOuTotal': imunidadeParcialOuTotal,
      'itemMagicoSoltoUsaBonusProprio': itemMagicoSoltoUsaBonusProprio,
    };
  }

  factory ConfiguracoesMesaT20.fromJson(Map<String, dynamic> json) {
    return ConfiguracoesMesaT20(
      nat20SucessoAutomaticoContraCd:
          json['nat20SucessoAutomaticoContraCd'] as bool? ?? true,
      nat1FalhaAutomaticaContraCd:
          json['nat1FalhaAutomaticaContraCd'] as bool? ?? true,
      nat20E1DecidemTesteOposto:
          json['nat20E1DecidemTesteOposto'] as bool? ?? false,
      nat20E1AutomaticoEmAtaque:
          json['nat20E1AutomaticoEmAtaque'] as bool? ?? true,
      penalidadeSemFerramenta: json['penalidadeSemFerramenta'] as int? ?? -5,
      cdAjudaPadrao: json['cdAjudaPadrao'] as int? ?? 10,
      bonusBaseAjuda: json['bonusBaseAjuda'] as int? ?? 1,
      intervaloBonusExtraAjuda: json['intervaloBonusExtraAjuda'] as int? ?? 10,
      permitirEscolher20EmTesteEstendido:
          json['permitirEscolher20EmTesteEstendido'] as bool? ?? false,
      excedenteMetaPericiaContaParaOutras:
          json['excedenteMetaPericiaContaParaOutras'] as bool? ?? false,
      consumirPericiaAjudaEmTesteEstendido:
          json['consumirPericiaAjudaEmTesteEstendido'] as bool? ?? true,
      incrementoCdCumulativaEstendido:
          json['incrementoCdCumulativaEstendido'] as int? ?? 2,
      maxFalhasPadraoEstendido: json['maxFalhasPadraoEstendido'] as int? ?? 3,
      interrupcaoContaPadrao: TipoInterrupcaoEstendido.values.firstWhere(
        (e) => e.name == json['interrupcaoContaPadrao'],
        orElse: () => TipoInterrupcaoEstendido.nada,
      ),
      metricaDistancia: MetricaDistanciaGrid.values.firstWhere(
        (e) => e.name == json['metricaDistancia'],
        orElse: () => MetricaDistanciaGrid.chebyshev,
      ),
      alcanceIlimitadoExigeAprovacaoMestre:
          json['alcanceIlimitadoExigeAprovacaoMestre'] as bool? ?? true,
      reducoesCustoPmAcumulam:
          json['reducoesCustoPmAcumulam'] as bool? ?? false,
      mesmaFonteMantemMelhorBonusPiorPenalidade:
          json['mesmaFonteMantemMelhorBonusPiorPenalidade'] as bool? ?? true,
      limiteItensAdicionaisDefesa:
          json['limiteItensAdicionaisDefesa'] as int? ?? 1,
      tetoChanceFalhaPercentual:
          json['tetoChanceFalhaPercentual'] as int? ?? 75,
      maxRerolagensPorTeste: json['maxRerolagensPorTeste'] as int? ?? 1,
      timeoutDeclaracaoAutomaticaSegundos:
          json['timeoutDeclaracaoAutomaticaSegundos'] as int?,
      testeAreaNaoPercebidaUsaCustoFinal:
          json['testeAreaNaoPercebidaUsaCustoFinal'] as bool? ?? true,
      coneLarguraFinalIgualComprimento:
          json['coneLarguraFinalIgualComprimento'] as bool? ?? true,
      segundosPorRodada: json['segundosPorRodada'] as int? ?? 6,
      sustentacaoPrimeiroPagamentoProximoTurno:
          json['sustentacaoPrimeiroPagamentoProximoTurno'] as bool? ?? true,
      sustentacaoModo: ModoSustentacao.values.firstWhere(
        (e) => e.name == json['sustentacaoModo'],
        orElse: () => ModoSustentacao.perguntar,
      ),
      expiracaoRodadas: ModoExpiracaoRodadas.values.firstWhere(
        (e) => e.name == json['expiracaoRodadas'],
        orElse: () => ModoExpiracaoRodadas.antesDaMesmaIniciativa,
      ),
      descargaModo: ModoDescarga.values.firstWhere(
        (e) => e.name == json['descargaModo'],
        orElse: () => ModoDescarga.automatica,
      ),
      reativarMesmoAlvoSubstituiAnterior:
          json['reativarMesmoAlvoSubstituiAnterior'] as bool? ?? true,
      repetirTesteResistenciaCadaEntradaArea:
          json['repetirTesteResistenciaCadaEntradaArea'] as bool? ?? false,
      imunidadeParcialOuTotal:
          json['imunidadeParcialOuTotal'] as bool? ?? true,
      itemMagicoSoltoUsaBonusProprio:
          json['itemMagicoSoltoUsaBonusProprio'] as bool? ?? true,
    );
  }
}
