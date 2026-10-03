import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/combate/combatente.dart';
import '../../domain/entities/combate/estado_vida_combatente.dart';
import '../../domain/entities/combate/grid_tatico.dart';
import '../../domain/entities/combate/inimigos_treino.dart';
import '../../domain/entities/personagem.dart';
import '../../domain/services/combate_engine.dart';
import '../controllers/combate_cubit.dart';
import '../controllers/combate_state.dart';

class AbaCombateView extends StatefulWidget {
  final Personagem personagem;
  final ValueChanged<Personagem>? onPersonagemAtualizado;

  const AbaCombateView({
    super.key,
    required this.personagem,
    this.onPersonagemAtualizado,
  });

  @override
  State<AbaCombateView> createState() => _AbaCombateViewState();
}

class _AbaCombateViewState extends State<AbaCombateView> {
  Combatente _oponenteSelecionado = InimigosTreino.goblinSaqueador;
  final ScrollController _logScrollController = ScrollController();

  void _rolarLogParaOFim() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScrollController.hasClients) {
        _logScrollController.animateTo(
          _logScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
    // Garantia de scroll após renderização completa dos novos itens da lista
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted && _logScrollController.hasClients) {
        _logScrollController.animateTo(
          _logScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CombateCubit(),
      child: BlocConsumer<CombateCubit, CombateState>(
        listener: (context, state) {
          _rolarLogParaOFim();
          // Sincroniza o PV do personagem com a ficha se ele tomar dano
          final meuHeroi = state.filaIniciativa
              .where((c) => c.nome == widget.personagem.nome)
              .firstOrNull;
          if (meuHeroi != null && meuHeroi.pvAtual != widget.personagem.pvAtual) {
            widget.onPersonagemAtualizado?.call(
              widget.personagem.copyWith(pvAtual: meuHeroi.pvAtual),
            );
          }
        },
        builder: (context, state) {
          final cubit = context.read<CombateCubit>();

          if (!state.combateIniciado) {
            return _buildLobbyPreparacao(context, cubit);
          }

          return _buildArenaCombate(context, state, cubit);
        },
      ),
    );
  }

  // ----------------------------------------------------
  // 1. LOBBY: SELEÇÃO DE OPONENTE E INÍCIO DE BATALHA
  // ----------------------------------------------------
  Widget _buildLobbyPreparacao(BuildContext context, CombateCubit cubit) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 2,
          color: const Color(0xFFFFF7ED),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFFED7AA)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF97316),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.sports_kabaddi_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Arena Tática 2D - Tormenta 20",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF9A3412),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Combate tático com Grid 2D (1,5m), regras reais de sangramento, morte e dano não letal.",
                        style: TextStyle(fontSize: 12.5, color: Color(0xFF7C2D12)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        const Text(
          "Escolha um Oponente de Treino:",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 10),

        ...InimigosTreino.todos.map((inimigo) {
          final selecionado = _oponenteSelecionado.id == inimigo.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(() => _oponenteSelecionado = inimigo),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: selecionado ? const Color(0xFFFEF2F2) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selecionado
                        ? const Color(0xFFB71C1C)
                        : const Color(0xFFE5E7EB),
                    width: selecionado ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: selecionado
                          ? const Color(0xFFB71C1C)
                          : const Color(0xFFE5E7EB),
                      foregroundColor:
                          selecionado ? Colors.white : Colors.black87,
                      child: Text(inimigo.nome[0]),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            inimigo.nome,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "PV: ${inimigo.pvMax} • Defesa: ${inimigo.defesa} • Inic: +${inimigo.modIniciativa}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (selecionado)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFFB71C1C),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),

        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () {
            final heroi = Combatente.doPersonagem(widget.personagem);
            cubit.iniciarCombate([heroi, _oponenteSelecionado]);
          },
          icon: const Icon(Icons.flash_on_rounded),
          label: const Text(
            "ROLAR INICIATIVA E ENTRAR NO GRID",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFB71C1C),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------
  // 2. ARENA DE COMBATE: TABULEIRO 2D, HUD E BOT
  // ----------------------------------------------------
  // ----------------------------------------------------
  // 2. ARENA DE COMBATE: ADAPTATIVA (TABLET / CELULAR)
  // ----------------------------------------------------
  Widget _buildArenaCombate(
    BuildContext context,
    CombateState state,
    CombateCubit cubit,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Breakpoint responsivo para telas largas / tablet em modo horizontal
        final bool modoLandscape = constraints.maxWidth >= 600;

        if (modoLandscape) {
          return _buildArenaCombateLandscape(context, state, cubit, constraints);
        } else {
          return _buildArenaCombatePortrait(context, state, cubit, constraints);
        }
      },
    );
  }

  // ----------------------------------------------------
  // MODO HORIZONTAL / TABLET (SPLIT VIEW EM 2 COLUNAS)
  // ----------------------------------------------------
  Widget _buildArenaCombateLandscape(
    BuildContext context,
    CombateState state,
    CombateCubit cubit,
    BoxConstraints constraints,
  ) {
    final combatenteAtual = state.combatenteAtual;
    final bool ehVezDoJogador = combatenteAtual != null &&
        combatenteAtual.nome == widget.personagem.nome;

    final heroi = state.filaIniciativa
        .firstWhere((c) => c.nome == widget.personagem.nome);
    final inimigo = state.filaIniciativa
        .firstWhere((c) => c.nome != widget.personagem.nome);

    return Column(
      children: [
        if (state.combateTerminado)
          _buildBannerTermino(state),

        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // COLUNA DA ESQUERDA: GRID TÁTICO + PAINEL DE AÇÕES (Flex: 6)
              Expanded(
                flex: 6,
                child: Column(
                  children: [
                    // Grid Tático 2D Virtual adaptativo
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(10, 6, 5, 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111827),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF374151)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: _buildGridTatico2D(context, state, cubit),
                        ),
                      ),
                    ),

                    // Painel de Ações do Jogador / Bot / Fim de Jogo
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 5, 6),
                      child: ehVezDoJogador && !state.combateTerminado
                          ? _buildPainelAcoesJogador(
                              context, state, cubit, heroi, inimigo)
                          : !state.combateTerminado
                              ? _buildPainelAcoesBot(context, cubit, inimigo)
                              : _buildPainelCombateTerminado(context, state, cubit),
                    ),
                  ],
                ),
              ),

              // DIVISOR VERTICAL SUAVE ENTRE TABULEIRO E PAINEL DE STATUS
              const VerticalDivider(
                width: 1,
                thickness: 1,
                color: Color(0xFFE5E7EB),
              ),

              // COLUNA DA DIREITA: HUD + CARDS DE STATUS + LOG DE COMBATE (Flex: 5)
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    // HUD Superior de Rodada e Turno + Botão Reiniciar
                    _buildHudSuperior(state, cubit, ehVezDoJogador),

                    // Cards dos Combatentes (Herói VS Inimigo)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildCardCombatente(
                              combatente: heroi,
                              ehAtivo: combatenteAtual?.id == heroi.id,
                              corTema: const Color(0xFF2563EB),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              "VS",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          Expanded(
                            child: _buildCardCombatente(
                              combatente: inimigo,
                              ehAtivo: combatenteAtual?.id == inimigo.id,
                              corTema: const Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Log de Combate (dedicado com altura total livre)
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(5, 2, 8, 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: _buildLogCombate(state),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------
  // MODO VERTICAL / CELULAR (COLUNA ÚNICA ADAPTATIVA)
  // ----------------------------------------------------
  Widget _buildArenaCombatePortrait(
    BuildContext context,
    CombateState state,
    CombateCubit cubit,
    BoxConstraints constraints,
  ) {
    final combatenteAtual = state.combatenteAtual;
    final bool ehVezDoJogador = combatenteAtual != null &&
        combatenteAtual.nome == widget.personagem.nome;

    final heroi = state.filaIniciativa
        .firstWhere((c) => c.nome == widget.personagem.nome);
    final inimigo = state.filaIniciativa
        .firstWhere((c) => c.nome != widget.personagem.nome);

    // Altura calculada dinamicamente para o grid de acordo com o espaço disponível
    final double gridHeight =
        (constraints.maxHeight * 0.30).clamp(120.0, 155.0);

    return Column(
      children: [
        if (state.combateTerminado)
          _buildBannerTermino(state),

        _buildHudSuperior(state, cubit, ehVezDoJogador),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: _buildCardCombatente(
                  combatente: heroi,
                  ehAtivo: combatenteAtual?.id == heroi.id,
                  corTema: const Color(0xFF2563EB),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  "VS",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ),
              Expanded(
                child: _buildCardCombatente(
                  combatente: inimigo,
                  ehAtivo: combatenteAtual?.id == inimigo.id,
                  corTema: const Color(0xFFDC2626),
                ),
              ),
            ],
          ),
        ),

        // Grid tático virtual
        Container(
          height: gridHeight,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF374151)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _buildGridTatico2D(context, state, cubit),
          ),
        ),

        // Painel de controle
        if (ehVezDoJogador && !state.combateTerminado)
          _buildPainelAcoesJogador(context, state, cubit, heroi, inimigo)
        else if (!state.combateTerminado)
          _buildPainelAcoesBot(context, cubit, inimigo)
        else
          _buildPainelCombateTerminado(context, state, cubit),

        // Log de combate
        Expanded(
          child: _buildLogCombate(state),
        ),
      ],
    );
  }

  // ----------------------------------------------------
  // BANNER DE ENCERRAMENTO (VITÓRIA / DERROTA)
  // ----------------------------------------------------
  Widget _buildBannerTermino(CombateState state) {
    final bool vitoria = state.statusCombate == StatusCombate.vitoria;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      color: vitoria ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            vitoria ? Icons.emoji_events_rounded : Icons.dangerous_rounded,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            vitoria
                ? "VITÓRIA! Oponentes derrotados!"
                : "DERROTA! Seu herói caiu em combate!",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // HUD SUPERIOR DE RODADA, TURNO E REINÍCIO
  // ----------------------------------------------------
  Widget _buildHudSuperior(
    CombateState state,
    CombateCubit cubit,
    bool ehVezDoJogador,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      color: const Color(0xFF1E1E2C),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Rodada ${state.rodadaAtual}",
            style: const TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: ehVezDoJogador
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  ehVezDoJogador ? "SEU TURNO" : "TURNO DO INIMIGO",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10.5,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                tooltip: "Reiniciar Batalha",
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  final h = Combatente.doPersonagem(widget.personagem);
                  cubit.iniciarCombate([h, _oponenteSelecionado]);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // REGISTRO DE BATALHA (LOG COM AUTO-SCROLL)
  // ----------------------------------------------------
  Widget _buildLogCombate(CombateState state) {
    return Container(
      color: const Color(0xFFF9FAFB),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            color: Colors.grey.shade200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.history_edu_rounded, size: 13, color: Color(0xFF4B5563)),
                    SizedBox(width: 4),
                    Text(
                      "Registro de Batalha (Tempo Real)",
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ],
                ),
                Text(
                  "${state.logCombate.length} eventos",
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _logScrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              itemCount: state.logCombate.length,
              itemBuilder: (context, index) {
                final linha = state.logCombate[index];
                final bool ehDano =
                    linha.contains('💥') || linha.contains('acertou');
                final bool ehErro = linha.contains('errou');
                final bool ehCritico = linha.contains('CRÍTICO');
                final bool ehMorte = linha.contains('💀') || linha.contains('VITÓRIA');
                final bool ehAviso = linha.contains('⚠️');

                return Padding(
                  padding: const EdgeInsets.only(bottom: 3.5),
                  child: Text(
                    linha,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: (ehDano || ehCritico || ehMorte || ehAviso)
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: ehCritico
                          ? const Color(0xFFB45309)
                          : ehMorte
                              ? const Color(0xFFDC2626)
                              : ehAviso
                                  ? const Color(0xFFC2410C)
                                  : ehDano
                                      ? const Color(0xFF15803D)
                                      : ehErro
                                          ? const Color(0xFFB91C1C)
                                          : const Color(0xFF374151),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // GRID TÁTICO 2D VIRTUAL (1,5m por célula)
  // ----------------------------------------------------
  Widget _buildGridTatico2D(
    BuildContext context,
    CombateState state,
    CombateCubit cubit,
  ) {
    final mapa = state.mapaGrid;

    return InteractiveViewer(
      constrained: true,
      maxScale: 2.5,
      minScale: 0.8,
      child: Center(
        child: AspectRatio(
          aspectRatio: mapa.largura / mapa.altura,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cellWidth = constraints.maxWidth / mapa.largura;
              final cellHeight = constraints.maxHeight / mapa.altura;

              return Stack(
                children: [
                  // 1. Grid de Terrenos e Células
                  for (int y = 0; y < mapa.altura; y++)
                    for (int x = 0; x < mapa.largura; x++) ...[
                      _buildCelulaGrid(
                        context: context,
                        posicao: Posicao2D(x, y),
                        terreno: mapa.obterTerreno(Posicao2D(x, y)),
                        cellWidth: cellWidth,
                        cellHeight: cellHeight,
                        state: state,
                        cubit: cubit,
                      ),
                    ],

                  // 2. Tokens dos Combatentes
                  for (final entry in state.posicoesCombatentes.entries) ...[
                    _buildTokenCombatente(
                      combatenteId: entry.key,
                      posicao: entry.value,
                      cellWidth: cellWidth,
                      cellHeight: cellHeight,
                      state: state,
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCelulaGrid({
    required BuildContext context,
    required Posicao2D posicao,
    required TipoTerreno terreno,
    required double cellWidth,
    required double cellHeight,
    required CombateState state,
    required CombateCubit cubit,
  }) {
    final bool ehAlcancavel = state.celulasAlcancaveis.contains(posicao);
    final double? custoMetros = state.custosMovimento[posicao];

    Color corFundo = const Color(0xFF1F2937);
    if (terreno == TipoTerreno.obstaculo) {
      corFundo = const Color(0xFF374151); // Rocha/Parede
    } else if (terreno == TipoTerreno.dificil) {
      corFundo = const Color(0xFF451A03); // Terreno difícil / lama
    }

    if (ehAlcancavel) {
      corFundo = const Color(0xFF047857).withValues(alpha: 0.65); // Verde tático
    }

    return Positioned(
      left: posicao.x * cellWidth,
      top: posicao.y * cellHeight,
      width: cellWidth,
      height: cellHeight,
      child: InkWell(
        onTap: ehAlcancavel
            ? () {
                final ativo = state.combatenteAtual;
                if (ativo != null) {
                  cubit.moverCombatente(ativo.id, posicao);
                }
              }
            : null,
        child: Container(
          decoration: BoxDecoration(
            color: corFundo,
            border: Border.all(
              color: ehAlcancavel
                  ? const Color(0xFF34D399)
                  : const Color(0xFF374151),
              width: ehAlcancavel ? 1.5 : 0.5,
            ),
          ),
          child: Center(
            child: ehAlcancavel && custoMetros != null
                ? Text(
                    "${custoMetros.toStringAsFixed(1)}m",
                    style: const TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                : terreno == TipoTerreno.obstaculo
                    ? const Icon(Icons.block, size: 12, color: Colors.grey)
                    : terreno == TipoTerreno.dificil
                        ? const Icon(Icons.terrain, size: 11, color: Colors.amber)
                        : null,
          ),
        ),
      ),
    );
  }

  Widget _buildTokenCombatente({
    required String combatenteId,
    required Posicao2D posicao,
    required double cellWidth,
    required double cellHeight,
    required CombateState state,
  }) {
    final combatente = state.filaIniciativa
        .firstWhere((c) => c.id == combatenteId, orElse: () => state.filaIniciativa.first);
    final bool ehHeroi = combatente.time == TimeCombatente.heroi;
    final bool ehAtivo = state.combatenteAtual?.id == combatenteId;

    return Positioned(
      left: posicao.x * cellWidth + 2,
      top: posicao.y * cellHeight + 2,
      width: cellWidth - 4,
      height: cellHeight - 4,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: ehHeroi ? const Color(0xFF2563EB) : const Color(0xFFDC2626),
          border: Border.all(
            color: ehAtivo ? Colors.amber : Colors.white,
            width: ehAtivo ? 2.5 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: (ehHeroi ? Colors.blue : Colors.red).withValues(alpha: 0.5),
              blurRadius: 4,
            ),
          ],
        ),
        child: Center(
          child: Text(
            combatente.nome[0],
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // CARD DE STATUS DO COMBATENTE
  // ----------------------------------------------------
  Widget _buildCardCombatente({
    required Combatente combatente,
    required bool ehAtivo,
    required Color corTema,
  }) {
    final double pctPv =
        (combatente.pvAtual / (combatente.pvMax > 0 ? combatente.pvMax : 1))
            .clamp(0.0, 1.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: ehAtivo ? corTema : const Color(0xFFE5E7EB),
          width: ehAtivo ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  combatente.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: ehAtivo ? corTema : Colors.black87,
                  ),
                ),
              ),
              _buildBadgeEstadoVida(combatente.estadoVida),
            ],
          ),
          const SizedBox(height: 4),

          // BARRA DE PV
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: pctPv,
              minHeight: 5,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                combatente.pvAtual <= combatente.limiteMorte
                    ? Colors.black
                    : combatente.pvAtual <= 0
                        ? Colors.purple
                        : pctPv > 0.5
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFDC2626),
              ),
            ),
          ),
          const SizedBox(height: 3),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "PV: ${combatente.pvAtual}/${combatente.pvMax}",
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Def: ${combatente.defesa} • ${combatente.deslocamentoMetros}m",
                style: TextStyle(fontSize: 9.5, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeEstadoVida(EstadoVidaCombatente estado) {
    Color corFundo = const Color(0xFFDCFCE7);
    Color corTexto = const Color(0xFF16A34A);

    if (estado == EstadoVidaCombatente.inconscienteSangrando) {
      corFundo = const Color(0xFFFEE2E2);
      corTexto = const Color(0xFFDC2626);
    } else if (estado == EstadoVidaCombatente.estabilizado) {
      corFundo = const Color(0xFFFEF3C7);
      corTexto = const Color(0xFFD97706);
    } else if (estado == EstadoVidaCombatente.morto) {
      corFundo = Colors.black;
      corTexto = Colors.white;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: corFundo,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        estado.label,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          color: corTexto,
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // PAINEL DE CONTROLE DO JOGADOR (AÇÕES, MOVIMENTO, ARMAS)
  // ----------------------------------------------------
  Widget _buildPainelAcoesJogador(
    BuildContext context,
    CombateState state,
    CombateCubit cubit,
    Combatente heroi,
    Combatente inimigo,
  ) {
    final armasHeroi = widget.personagem.armas;
    final posHeroi = state.posicoesCombatentes[heroi.id];
    final posInimigo = state.posicoesCombatentes[inimigo.id];
    final bool adjacente = posHeroi != null &&
        posInimigo != null &&
        posHeroi.ehAdjacente(posInimigo);
    final double distMetros = (posHeroi != null && posInimigo != null)
        ? posHeroi.distanciaMetros(posInimigo)
        : 1.5;

    final temArmaDistancia = armasHeroi.any((a) => !a.ehCorpoACorpo);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. BARRA DE RECURSOS E AÇÕES (WRAP RESPONSIVO - ZERO OVERFLOW)
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildBadgeAcao(
                    "Padrão",
                    state.acoesPadraoRestantes > 0,
                    const Color(0xFFDC2626),
                  ),
                  const SizedBox(width: 4),
                  _buildBadgeAcao(
                    "Movimento",
                    state.acoesMovimentoRestantes > 0,
                    const Color(0xFF2563EB),
                  ),
                ],
              ),

              // Botão Mover no Grid
              OutlinedButton.icon(
                onPressed: state.temAcaoMovimento
                    ? () => cubit.alternarModoMovimento()
                    : null,
                icon: Icon(
                  state.modoMovimentoAtivo
                      ? Icons.close
                      : Icons.directions_walk_rounded,
                  size: 13,
                ),
                label: Text(
                  state.modoMovimentoAtivo
                      ? "Cancelar"
                      : "Mover (${state.deslocamentoRestanteMetros.toStringAsFixed(1)}m)",
                  style: const TextStyle(fontSize: 10.5),
                ),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 0),
                  foregroundColor: state.modoMovimentoAtivo
                      ? Colors.red
                      : const Color(0xFF047857),
                  side: BorderSide(
                    color: state.modoMovimentoAtivo
                        ? Colors.red
                        : const Color(0xFF047857),
                  ),
                ),
              ),

              // Toggle Não-Letal
              FilterChip(
                label: const Text("Não-Letal (-5)"),
                selected: state.ataqueNaoLetalAtivo,
                onSelected: (_) => cubit.alternarAtaqueNaoLetal(),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                labelStyle: const TextStyle(fontSize: 10),
              ),

              // Ação Mirar para armas de disparo
              if (temArmaDistancia)
                OutlinedButton.icon(
                  onPressed: state.temAcaoMovimento && !state.mirouNesteTurno
                      ? () => cubit.executarAcaoMirar()
                      : null,
                  icon: const Icon(Icons.gps_fixed_rounded, size: 13),
                  label: Text(
                    state.mirouNesteTurno ? "Mirou (+)" : "Mirar",
                    style: const TextStyle(fontSize: 10.5),
                  ),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                    foregroundColor: const Color(0xFF2563EB),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 5),

          // 2. LISTA DE ARMAS COM FEEDBACK DE ALCANCE
          if (armasHeroi.isEmpty)
            const Text(
              "Nenhuma arma equipada na ficha!",
              style: TextStyle(fontSize: 11, color: Colors.red),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: armasHeroi.map((arma) {
                final bonusAtaque = arma.ehCorpoACorpo
                    ? heroi.modLuta
                    : heroi.modPontaria;
                final bool foraDeAlcance = arma.ehCorpoACorpo && !adjacente;

                return ElevatedButton.icon(
                  onPressed: state.acoesPadraoRestantes > 0 && heroi.podeAgir
                      ? () => cubit.executarAtaque(defensor: inimigo, arma: arma)
                      : null,
                  icon: Icon(
                    foraDeAlcance
                        ? Icons.not_listed_location_rounded
                        : Icons.colorize_rounded,
                    size: 13,
                  ),
                  label: Text(
                    foraDeAlcance
                        ? "${arma.nome} (Fora de Alcance: ${distMetros.toStringAsFixed(1)}m)"
                        : "Atacar: ${arma.nome} (+$bonusAtaque | ${arma.dano})",
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: foraDeAlcance
                        ? const Color(0xFF6B7280)
                        : const Color(0xFFB71C1C),
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 2),

          // 3. BARRA INFERIOR DE DISTÂNCIA E PASSAGEM DE TURNO
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (adjacente)
                const Row(
                  children: [
                    Icon(Icons.sports_kabaddi, size: 13, color: Colors.green),
                    SizedBox(width: 4),
                    Text(
                      "Inimigo Adjacente (1,5m)",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    const Icon(Icons.radar_rounded, size: 13, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(
                      "Distância: ${distMetros.toStringAsFixed(1)}m",
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              TextButton.icon(
                onPressed: () => cubit.proximoTurno(),
                icon: const Icon(Icons.skip_next_rounded, size: 16),
                label: const Text(
                  "Passar Turno",
                  style: TextStyle(fontSize: 11),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF4B5563),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPainelCombateTerminado(
    BuildContext context,
    CombateState state,
    CombateCubit cubit,
  ) {
    final bool vitoria = state.statusCombate == StatusCombate.vitoria;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: vitoria ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
      child: Row(
        children: [
          Icon(
            vitoria ? Icons.military_tech_rounded : Icons.heart_broken_rounded,
            color: vitoria ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
            size: 22,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  vitoria ? "Batalha Encerrada: Vitória!" : "Batalha Encerrada: Derrota!",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11.5,
                    color: vitoria
                        ? const Color(0xFF15803D)
                        : const Color(0xFF991B1B),
                  ),
                ),
                Text(
                  vitoria
                      ? "Oponentes neutralizados com sucesso."
                      : "Seu combatente caiu em combate.",
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final h = Combatente.doPersonagem(widget.personagem);
              cubit.iniciarCombate([h, _oponenteSelecionado]);
            },
            icon: const Icon(Icons.replay_rounded, size: 15),
            label: const Text("Nova Batalha", style: TextStyle(fontSize: 11)),
            style: ElevatedButton.styleFrom(
              backgroundColor: vitoria
                  ? const Color(0xFF16A34A)
                  : const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPainelAcoesBot(
    BuildContext context,
    CombateCubit cubit,
    Combatente inimigo,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFFFEF2F2),
      child: Row(
        children: [
          const Icon(Icons.smart_toy_outlined, color: Color(0xFFDC2626), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Vez de ${inimigo.nome}. Clique para acionar a IA:",
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF991B1B),
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => cubit.executarTurnoBot(),
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: const Text(
              "Ação da IA",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeAcao(String label, bool disponivel, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: disponivel ? cor.withValues(alpha: 0.1) : Colors.grey[200],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: disponivel ? cor : Colors.grey[400]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            disponivel ? Icons.check_circle : Icons.cancel,
            size: 11,
            color: disponivel ? cor : Colors.grey[500],
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: disponivel ? cor : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
