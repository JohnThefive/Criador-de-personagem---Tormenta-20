import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/equipamento/arma.dart';
import '../../../domain/entities/combate/combatente.dart';
import '../../../domain/entities/combate/grid_tatico.dart';
import '../../../domain/entities/combate/tipo_acao.dart';
import '../../../domain/services/combate_services/combate_engine.dart';
import '../../../domain/services/combate_services/movimento_engine.dart';
import 'combate_state.dart';
import '../../../domain/entities/magia/magia.dart';

class CombateCubit extends Cubit<CombateState> {
  final CombateEngine _engine;

  CombateCubit({CombateEngine? engine})
    : _engine = engine ?? CombateEngine(),
      super(const CombateState());

  /// 1. Inicia o combate, define posições no grid 2D e rola a iniciativa
  void iniciarCombate(
    List<Combatente> participantes, {
    GridMapa? mapa,
    Map<String, Posicao2D>? posicoesIniciais,
  }) {
    if (participantes.isEmpty) return;

    // Mapa tático padrão com alguns terrenos difíceis e obstáculos
    final gridPadrao =
        mapa ??
        GridMapa(
          largura: 10,
          altura: 8,
          terrenos: {
            const Posicao2D(4, 2): TipoTerreno.obstaculo,
            const Posicao2D(4, 3): TipoTerreno.obstaculo,
            const Posicao2D(5, 4): TipoTerreno.dificil,
            const Posicao2D(5, 5): TipoTerreno.dificil,
          },
        );

    // Posicionamento inicial se não fornecido (Heróis à esquerda, Inimigos à direita)
    final posicoes = <String, Posicao2D>{};
    if (posicoesIniciais != null) {
      posicoes.addAll(posicoesIniciais);
    } else {
      int yHeroi = 3;
      int yInimigo = 3;
      for (final p in participantes) {
        if (p.time == TimeCombatente.heroi) {
          posicoes[p.id] = Posicao2D(1, yHeroi++);
        } else {
          posicoes[p.id] = Posicao2D(8, yInimigo++);
        }
      }
    }

    final filaOrdenada = _engine.rolarIniciativa(participantes);
    final primeiro = filaOrdenada.first;

    final novoLog = [
      "⚔️ Combate iniciado! Rodada 1.",
      ...filaOrdenada.map(
        (c) => "• ${c.nome} (${c.time.name}): Iniciativa ${c.iniciativaValor}",
      ),
      "👉 É o turno de ${primeiro.nome}.",
    ];

    emit(
      state.copyWith(
        filaIniciativa: filaOrdenada,
        rodadaAtual: 1,
        indiceTurnoAtual: 0,
        acoesPadraoRestantes: 1,
        acoesMovimentoRestantes: 1,
        deslocamentoRestanteMetros: primeiro.deslocamentoMetros,
        mirouNesteTurno: false,
        ataqueNaoLetalAtivo: false,
        modoMovimentoAtivo: false,
        mapaGrid: gridPadrao,
        posicoesCombatentes: posicoes,
        celulasAlcancaveis: const {},
        custosMovimento: const {},
        statusCombate: StatusCombate.emAndamento,
        logCombate: novoLog,
        limparUltimoAtaque: true,
      ),
    );
  }

  /// 2. Consome recursos da economia de ações do T20
  bool gastarAcao(TipoAcao tipo) {
    switch (tipo) {
      case TipoAcao.padrao:
        if (state.acoesPadraoRestantes > 0) {
          emit(
            state.copyWith(
              acoesPadraoRestantes: state.acoesPadraoRestantes - 1,
            ),
          );
          return true;
        }
        return false;

      case TipoAcao.movimento:
        if (state.acoesMovimentoRestantes > 0) {
          emit(
            state.copyWith(
              acoesMovimentoRestantes: state.acoesMovimentoRestantes - 1,
            ),
          );
          return true;
        }
        // Conversão T20: Ação Padrão pode virar Ação de Movimento
        if (state.acoesPadraoRestantes > 0) {
          emit(
            state.copyWith(
              acoesPadraoRestantes: state.acoesPadraoRestantes - 1,
              logCombate: [
                ...state.logCombate,
                "🔄 ${state.combatenteAtual?.nome} converteu 1 Ação Padrão em Movimento.",
              ],
            ),
          );
          return true;
        }
        return false;

      case TipoAcao.completa:
        if (state.acoesPadraoRestantes > 0 &&
            state.acoesMovimentoRestantes > 0) {
          emit(
            state.copyWith(acoesPadraoRestantes: 0, acoesMovimentoRestantes: 0),
          );
          return true;
        }
        return false;

      case TipoAcao.livre:
      case TipoAcao.reacao:
        return true;
    }
  }

  /// 3. Ativa/desativa o destaque do Grid para movimentação
  void alternarModoMovimento() {
    if (state.modoMovimentoAtivo) {
      emit(
        state.copyWith(
          modoMovimentoAtivo: false,
          celulasAlcancaveis: const {},
          custosMovimento: const {},
        ),
      );
      return;
    }

    final atual = state.combatenteAtual;
    if (atual == null || !atual.podeAgir) return;

    final posAtual = state.posicoesCombatentes[atual.id];
    if (posAtual == null) return;

    if (!state.temAcaoMovimento && state.deslocamentoRestanteMetros <= 0) {
      emit(
        state.copyWith(
          logCombate: [
            ...state.logCombate,
            "⚠️ ${atual.nome} não possui Ação de Movimento ou deslocamento restante!",
          ],
        ),
      );
      return;
    }

    final combatentesMap = {for (final c in state.filaIniciativa) c.id: c};

    final resultado = MovimentoEngine.calcularAlcancaveis(
      mapa: state.mapaGrid,
      inicio: posAtual,
      deslocamentoMaximoMetros: state.deslocamentoRestanteMetros,
      posicoesCombatentes: state.posicoesCombatentes,
      combatentesPorId: combatentesMap,
      combatenteAtivoId: atual.id,
    );

    emit(
      state.copyWith(
        modoMovimentoAtivo: true,
        celulasAlcancaveis: resultado.destinosValidos,
        custosMovimento: resultado.custosMetros,
      ),
    );
  }

  /// 4. Move o combatente para uma célula de destino válida no Grid
  void moverCombatente(
    String combatenteId,
    Posicao2D destino, {
    double? custo,
  }) {
    if (custo == null && !state.celulasAlcancaveis.contains(destino)) return;

    final custoGasto = custo ?? state.custosMovimento[destino] ?? 0.0;
    final combatente = state.filaIniciativa.firstWhere(
      (c) => c.id == combatenteId,
    );

    // Desconta Ação de Movimento se ainda não foi consumida
    if (state.acoesMovimentoRestantes > 0) {
      gastarAcao(TipoAcao.movimento);
    }

    final novoRestante = (state.deslocamentoRestanteMetros - custoGasto).clamp(
      0.0,
      99.0,
    );

    final novasPosicoes = Map<String, Posicao2D>.from(
      state.posicoesCombatentes,
    );
    novasPosicoes[combatenteId] = destino;

    emit(
      state.copyWith(
        posicoesCombatentes: novasPosicoes,
        deslocamentoRestanteMetros: novoRestante,
        modoMovimentoAtivo: false,
        celulasAlcancaveis: const {},
        custosMovimento: const {},
        logCombate: [
          ...state.logCombate,
          "🚶 ${combatente.nome} moveu-se para $destino (gastou ${custoGasto.toStringAsFixed(1)}m).",
        ],
      ),
    );
  }

  /// 5. Alterna a intenção de dano letal vs não letal
  void alternarAtaqueNaoLetal() {
    final novoModo = !state.ataqueNaoLetalAtivo;
    emit(
      state.copyWith(
        ataqueNaoLetalAtivo: novoModo,
        logCombate: [
          ...state.logCombate,
          novoModo
              ? "🛡️ Modo de Dano Não Letal ATIVADO (-5 no teste de ataque)."
              : "⚔️ Modo de Dano Letal reativado.",
        ],
      ),
    );
  }

  /// 6. Executa a ação de movimento "Mirar"
  void executarAcaoMirar() {
    if (!gastarAcao(TipoAcao.movimento)) return;

    emit(
      state.copyWith(
        mirouNesteTurno: true,
        logCombate: [
          ...state.logCombate,
          "🎯 ${state.combatenteAtual?.nome} usou ação de movimento para Mirar.",
        ],
      ),
    );
  }

  /// 7. Executa o ataque, aplica dano (letal ou não) e verifica fim de combate
  void executarAtaque({
    required Combatente defensor,
    required Arma arma,
    bool alvoEngajadoEmCorpoACorpo = false,
    int bonusAtaqueExtra = 0,
    int bonusDanoExtra = 0,
  }) {
    final atacante = state.combatenteAtual;
    if (atacante == null) return;

    // Validação de Alcance no Grid Tático do T20
    final posAtacante = state.posicoesCombatentes[atacante.id];
    final posDefensor = state.posicoesCombatentes[defensor.id];
    if (posAtacante != null && posDefensor != null) {
      final bool ehAdjacente = posAtacante.ehAdjacente(posDefensor);
      if (arma.ehCorpoACorpo && !ehAdjacente) {
        final distMetros = posAtacante.distanciaMetros(posDefensor);
        emit(
          state.copyWith(
            logCombate: [
              ...state.logCombate,
              "⚠️ ${defensor.nome} está fora de alcance (${distMetros.toStringAsFixed(1)}m)! Armas corpo a corpo exigem adjacência (1,5m). Use a Ação de Movimento para se aproximar.",
            ],
          ),
        );
        return;
      }
    }

    if (!gastarAcao(TipoAcao.padrao)) {
      emit(
        state.copyWith(
          logCombate: [
            ...state.logCombate,
            "⚠️ ${atacante.nome} não possui Ação Padrão disponível para agredir neste turno!",
          ],
        ),
      );
      return;
    }

    final resultado = _engine.executarAtaque(
      atacante: atacante,
      defensor: defensor,
      arma: arma,
      alvoEngajadoEmCorpoACorpo: alvoEngajadoEmCorpoACorpo,
      mirou: state.mirouNesteTurno,
      ataqueNaoLetal: state.ataqueNaoLetalAtivo,
      bonusAtaqueExtra: bonusAtaqueExtra,
      bonusDanoExtra: bonusDanoExtra,
    );

    // Aplica o dano no defensor usando as regras de ciclo de vida do T20
    List<Combatente> novaFila = state.filaIniciativa;
    if (resultado.acerto && resultado.danoTotal > 0) {
      novaFila = novaFila.map((c) {
        if (c.id == defensor.id) {
          return c.aplicarDano(
            resultado.danoTotal,
            naoLetal: state.ataqueNaoLetalAtivo,
          );
        }
        return c;
      }).toList();
    }

    final statusFinal = _engine.verificarFimDeCombate(novaFila);

    final novoLog = [
      ...state.logCombate,
      resultado.logResumo,
      if (resultado.acerto) "💥 ${resultado.detalheDano}",
    ];

    if (statusFinal == StatusCombate.vitoria) {
      novoLog.add("🏆 VITÓRIA! Todos os oponentes foram derrotados!");
    } else if (statusFinal == StatusCombate.derrota) {
      novoLog.add("💀 DERROTA! Todos os heróis caíram em combate!");
    }

    emit(
      state.copyWith(
        filaIniciativa: novaFila,
        ultimoResultadoAtaque: resultado,
        statusCombate: statusFinal,
        logCombate: novoLog,
      ),
    );
  }

  /// Atualiza o combatente na fila de iniciativa e recalcula status de vitória/derrota
  void atualizarCombatente(Combatente atualizado) {
    final novaFila = state.filaIniciativa.map((c) {
      return c.id == atualizado.id ? atualizado : c;
    }).toList();

    final statusFinal = _engine.verificarFimDeCombate(novaFila);
    final novoLog = List<String>.from(state.logCombate);
    if (statusFinal == StatusCombate.vitoria &&
        state.statusCombate != StatusCombate.vitoria) {
      novoLog.add("🏆 VITÓRIA! Todos os oponentes foram derrotados!");
    } else if (statusFinal == StatusCombate.derrota &&
        state.statusCombate != StatusCombate.derrota) {
      novoLog.add("💀 DERROTA! Todos os heróis caíram em combate!");
    }

    emit(
      state.copyWith(
        filaIniciativa: novaFila,
        statusCombate: statusFinal,
        logCombate: novoLog,
      ),
    );
  }

  /// 8. Atrasar Ação
  void atrasarIniciativa(int novaIniciativa) {
    final atual = state.combatenteAtual;
    if (atual == null) return;

    final novaFila = _engine.atrasarIniciativa(
      filaAtual: state.filaIniciativa,
      combatenteId: atual.id,
      novaIniciativa: novaIniciativa,
    );

    emit(
      state.copyWith(
        filaIniciativa: novaFila,
        logCombate: [
          ...state.logCombate,
          "⏳ ${atual.nome} atrasou sua iniciativa para $novaIniciativa.",
        ],
      ),
    );
  }

  /// 9. Passa para o próximo turno, processa sangramento e cicla rodada
  void proximoTurno() {
    if (state.filaIniciativa.isEmpty) return;

    int proximoIndex = state.indiceTurnoAtual + 1;
    int novaRodada = state.rodadaAtual;

    if (proximoIndex >= state.filaIniciativa.length) {
      proximoIndex = 0;
      novaRodada++;
    }

    var novoCombatente = state.filaIniciativa[proximoIndex];
    final novosLogs = <String>[];

    // Processa início do turno (ex: Teste de Sangramento / Estabilização)
    List<Combatente> filaAtualizada = List.from(state.filaIniciativa);
    final (combatenteAposInicio, logInicio) = _engine.processarInicioTurno(
      novoCombatente,
    );

    if (logInicio.isNotEmpty) {
      novosLogs.add(logInicio);
      filaAtualizada[proximoIndex] = combatenteAposInicio;
      novoCombatente = combatenteAposInicio;
    }

    final statusFinal = _engine.verificarFimDeCombate(filaAtualizada);

    novosLogs.add(
      "Turno de ${novoCombatente.nome} [${novoCombatente.estadoVida.label}] (Rodada $novaRodada).",
    );

    emit(
      state.copyWith(
        filaIniciativa: filaAtualizada,
        indiceTurnoAtual: proximoIndex,
        rodadaAtual: novaRodada,
        acoesPadraoRestantes: 1,
        acoesMovimentoRestantes: 1,
        deslocamentoRestanteMetros: novoCombatente.deslocamentoMetros,
        mirouNesteTurno: false,
        modoMovimentoAtivo: false,
        celulasAlcancaveis: const {},
        custosMovimento: const {},
        statusCombate: statusFinal,
        limparUltimoAtaque: true,
        logCombate: [...state.logCombate, ...novosLogs],
      ),
    );
  }

  /// Converte o tipo de alcance da Magia para a distância máxima em metros no T20
  double calcularAlcanceMetrosMagia(AlcanceMagia alcance) {
    switch (alcance.tipo.toLowerCase()) {
      case 'pessoal':
        return 0.0;
      case 'toque':
        return 1.5;
      case 'curto':
        return 9.0;
      case 'medio':
      case 'médio':
        return 30.0;
      case 'longo':
        return 90.0;
      default:
        return 9.0;
    }
  }

  /// Retorna o custo base de PM em Tormenta 20 conforme o círculo da magia
  int calcularCustoPmMagia(Magia magia) {
    switch (magia.circulo) {
      case 1:
        return 1;
      case 2:
        return 3;
      case 3:
        return 6;
      case 4:
        return 10;
      case 5:
        return 15;
      default:
        return magia.circulo;
    }
  }

  /// Executa o lançamento de magia com validação de PM, ação e alcance métrico
  void lancarMagia({
    required Magia magia,
    Combatente? alvo,
    int? valorDanoOuCura,
    bool ehCura = false,
  }) {
    final lancador = state.combatenteAtual;
    if (lancador == null) return;
    final custoPm = calcularCustoPmMagia(magia);
    // 1. Validação de PM suficiente
    if (lancador.pmAtual < custoPm) {
      emit(
        state.copyWith(
          logCombate: [
            ...state.logCombate,
            "⚠️ ${lancador.nome} não possui PM suficiente para lançar ${magia.nome}! (Exige $custoPm PM, tem ${lancador.pmAtual} PM).",
          ],
        ),
      );
      return;
    }
    // 2. Validação da Ação exigida (padrão, movimento, etc.)
    final tipoAcao = magia.execucao.tipo.toLowerCase().contains('movimento')
        ? TipoAcao.movimento
        : TipoAcao.padrao;
    if (!gastarAcao(tipoAcao)) {
      emit(
        state.copyWith(
          logCombate: [
            ...state.logCombate,
            "⚠️ ${lancador.nome} não possui ação disponível para lançar ${magia.nome}!",
          ],
        ),
      );
      return;
    }

    // 3. Validação de Alcance no Grid Tático
    final alcanceMaximo = calcularAlcanceMetrosMagia(magia.alcance);
    final posLancador = state.posicoesCombatentes[lancador.id];
    if (alvo != null &&
        posLancador != null &&
        magia.alcance.tipo != 'pessoal') {
      final posAlvo = state.posicoesCombatentes[alvo.id];
      if (posAlvo != null) {
        final distMetros = posLancador.distanciaMetros(posAlvo);
        if (distMetros > alcanceMaximo) {
          emit(
            state.copyWith(
              logCombate: [
                ...state.logCombate,
                "⚠️ Alvo fora de alcance para ${magia.nome}! Distância: ${distMetros.toStringAsFixed(1)}m (Alcance ${magia.alcance.tipo}: ${alcanceMaximo}m).",
              ],
            ),
          );
          return;
        }
      }
    }
    // 4. Deduz o PM do Lançador e atualiza a fila de combate
    final lancadorComMenosPm = lancador.copyWith(
      pmAtual: lancador.pmAtual - custoPm,
    );
    List<Combatente> novaFila = state.filaIniciativa.map((c) {
      return c.id == lancador.id ? lancadorComMenosPm : c;
    }).toList();
    // 5. Aplica dano ou cura no alvo se especificado
    final novosLogs = <String>[
      "✨ ${lancador.nome} lançou ${magia.nome} gastando $custoPm PM (restam ${lancadorComMenosPm.pmAtual} PM).",
    ];
    if (alvo != null && valorDanoOuCura != null && valorDanoOuCura > 0) {
      novaFila = novaFila.map((c) {
        if (c.id == alvo.id) {
          if (ehCura) {
            novosLogs.add("💚 ${alvo.nome} foi curado em $valorDanoOuCura PV!");
            return c.aplicarCura(valorDanoOuCura);
          } else {
            novosLogs.add(
              "💥 ${alvo.nome} sofreu $valorDanoOuCura de dano mágico de ${magia.nome}!",
            );
            return c.aplicarDano(valorDanoOuCura);
          }
        }
        return c;
      }).toList();
    }
    final statusFinal = _engine.verificarFimDeCombate(novaFila);
    emit(
      state.copyWith(
        filaIniciativa: novaFila,
        statusCombate: statusFinal,
        logCombate: [...state.logCombate, ...novosLogs],
      ),
    );
  }

  /// 10. Aplica ajuste direto de dano ou cura no combatente (Pilar VTT: Resolução Rápida na Mesa)
  void aplicarAjusteVtt({
    required String combatenteId,
    required int valor,
    required String motivo,
    bool ehCura = false,
    bool ehMetade = false,
  }) {
    final valorFinal = ehMetade ? (valor / 2).floor() : valor;
    if (valorFinal <= 0) return;

    final novosLogs = <String>[];
    final novaFila = state.filaIniciativa.map((c) {
      if (c.id == combatenteId) {
        if (ehCura) {
          novosLogs.add("💚 ${c.nome} recuperou $valorFinal PV ($motivo).");
          return c.aplicarCura(valorFinal);
        } else {
          final prefixo = ehMetade ? "💥 [1/2 Dano (Resistiu)]" : "💥 [Dano Total]";
          novosLogs.add("$prefixo ${c.nome} sofreu $valorFinal de dano ($motivo).");
          return c.aplicarDano(valorFinal);
        }
      }
      return c;
    }).toList();

    final statusFinal = _engine.verificarFimDeCombate(novaFila);
    emit(
      state.copyWith(
        filaIniciativa: novaFila,
        statusCombate: statusFinal,
        logCombate: [...state.logCombate, ...novosLogs],
      ),
    );
  }

  /// 11. IA Tática do Bot: move-se no grid em direção ao herói se necessário e agride
  void executarTurnoBot() {
    final bot = state.combatenteAtual;
    if (bot == null || !bot.podeAgir) {
      proximoTurno();
      return;
    }

    final heroiAlvo = state.filaIniciativa.firstWhere(
      (c) => c.time == TimeCombatente.heroi && c.pvAtual > 0,
      orElse: () => state.filaIniciativa.first,
    );

    final posBot = state.posicoesCombatentes[bot.id];
    final posHeroi = state.posicoesCombatentes[heroiAlvo.id];
    final arma = bot.armas.isNotEmpty ? bot.armas.first : null;

    // 1. Se tem arma corpo a corpo e não está adjacente ao herói, move-se em direção a ele
    if (posBot != null &&
        posHeroi != null &&
        arma != null &&
        arma.ehCorpoACorpo &&
        !posBot.ehAdjacente(posHeroi)) {
      if (state.temAcaoMovimento) {
        final alcancaveis = MovimentoEngine.calcularAlcancaveis(
          mapa: state.mapaGrid,
          inicio: posBot,
          deslocamentoMaximoMetros: state.deslocamentoRestanteMetros > 0
              ? state.deslocamentoRestanteMetros
              : bot.deslocamentoMetros,
          posicoesCombatentes: state.posicoesCombatentes,
          combatentesPorId: {for (var c in state.filaIniciativa) c.id: c},
          combatenteAtivoId: bot.id,
        );

        // Seleciona a célula válida que mais aproxima o bot do herói
        Posicao2D? melhorDestino;
        int menorDistancia = posBot.distanciaEmQuadrados(posHeroi);

        for (final destino in alcancaveis.destinosValidos) {
          final dist = destino.distanciaEmQuadrados(posHeroi);
          if (dist < menorDistancia) {
            menorDistancia = dist;
            melhorDestino = destino;
          }
        }

        if (melhorDestino != null) {
          moverCombatente(
            bot.id,
            melhorDestino,
            custo: alcancaveis.custosMetros[melhorDestino],
          );
        }
      }
    }

    // 2. Se tiver ação padrão, verifica se tem alcance e agride
    final posBotFinal = state.posicoesCombatentes[bot.id];
    if (arma != null && state.acoesPadraoRestantes > 0) {
      final bool podeAtacar =
          !arma.ehCorpoACorpo ||
          (posBotFinal != null &&
              posHeroi != null &&
              posBotFinal.ehAdjacente(posHeroi));

      if (podeAtacar) {
        executarAtaque(defensor: heroiAlvo, arma: arma);
      } else {
        emit(
          state.copyWith(
            logCombate: [
              ...state.logCombate,
              "🛡️ ${bot.nome} aproximou-se, mas ainda não possui alcance para golpear.",
            ],
          ),
        );
      }
    } else {
      emit(
        state.copyWith(
          logCombate: [
            ...state.logCombate,
            "💤 ${bot.nome} aguarda atentamente.",
          ],
        ),
      );
    }

    proximoTurno();
  }
}
