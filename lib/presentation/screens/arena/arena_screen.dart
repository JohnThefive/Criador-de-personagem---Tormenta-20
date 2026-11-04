import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:t20_creator/presentation/screens/arena/widgets/selecao_inimigos.dart';
import 'package:t20_creator/presentation/widgets/vtt_board_widget.dart';

import '../../../domain/entities/combate/combatente.dart';
import '../../../domain/entities/combate/grid_tatico.dart';
import '../../../domain/entities/combate/inimigos_treino.dart';
import '../../../domain/entities/personagem/personagem.dart';
import '../../../domain/services/combate_services/arena_stats_collector.dart';
import '../../../domain/services/ficha_services/personagem_storage_service.dart';
import '../../controllers/combate_controller/combate_cubit.dart';
import '../../controllers/combate_controller/combate_state.dart';

import 'widgets/arena_arbitragem_dialog.dart';
import 'widgets/arena_banner_turno.dart';
import 'widgets/arena_iniciativa_bar.dart';
import 'widgets/arena_painel_acoes.dart';
import 'widgets/arena_relatorio_dialog.dart';
import 'widgets/arena_terminal_log.dart';
import 'widgets/mini_ficha_combatente_widget.dart';
import 'widgets/rolar_iniciativa_view.dart';

enum FaseArena { selecaoInimigos, rolarIniciativa, combateAtivo }

class ArenaScreen extends StatefulWidget {
  final Personagem personagemOriginal;

  const ArenaScreen({super.key, required this.personagemOriginal});

  @override
  State<ArenaScreen> createState() => _ArenaScreenState();
}

class _ArenaScreenState extends State<ArenaScreen> {
  late final Personagem _clonePersonagem;
  final ArenaStatsCollector _stats = ArenaStatsCollector();
  FaseArena _fase = FaseArena.selecaoInimigos;
  final List<Combatente> _inimigosEscolhidos = [];

  bool _relatorioExibido = false;

  @override
  void initState() {
    super.initState();
    final jsonStr = PersonagemStorageService.personagemToJson(
      widget.personagemOriginal,
    );
    _clonePersonagem = PersonagemStorageService.personagemFromJson(jsonStr);
    _inimigosEscolhidos.add(InimigosTreino.orcGuerreiro);
  }

  void _iniciarCombateComIniciativas(
    CombateCubit cubit,
    int totalHeroi,
    Map<String, int> totaisInimigos,
  ) {
    final heroi = Combatente.doPersonagem(_clonePersonagem);
    final posicoes = <String, Posicao2D>{heroi.id: const Posicao2D(1, 3)};

    int yIni = 2;
    for (final inimigo in _inimigosEscolhidos) {
      posicoes[inimigo.id] = Posicao2D(8, yIni);
      yIni = (yIni + 2).clamp(0, 7);
    }

    final mapaIniciativas = <String, int>{
      heroi.id: totalHeroi,
      ...totaisInimigos,
    };

    cubit.iniciarCombate(
      [heroi, ..._inimigosEscolhidos],
      posicoesIniciais: posicoes,
      iniciativas: mapaIniciativas,
    );

    setState(() {
      _fase = FaseArena.combateAtivo;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CombateCubit(),
      child: BlocListener<CombateCubit, CombateState>(
        listener: (context, state) {
          if (state.combateTerminado &&
              !_relatorioExibido &&
              _fase == FaseArena.combateAtivo) {
            _relatorioExibido = true;
            exibirRelatorioFinal(context, state, _stats);
          }
        },
        child: Builder(
          builder: (context) {
            final cubit = context.read<CombateCubit>();

            return Scaffold(
              backgroundColor: const Color(0xFF0F172A),
              appBar: AppBar(
                backgroundColor: const Color(0xFFC62828),
                title: const Text(
                  'Arena Tática T20',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Reiniciar Arena',
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ArenaScreen(
                          personagemOriginal: widget.personagemOriginal,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              body: SafeArea(
                child: switch (_fase) {
                  FaseArena.selecaoInimigos => SelecaoInimigosView(
                    heroi: _clonePersonagem,
                    selecionados: _inimigosEscolhidos,
                    onToggleInimigo: (c) => setState(() {
                      _inimigosEscolhidos.any((x) => x.id == c.id)
                          ? _inimigosEscolhidos.removeWhere((x) => x.id == c.id)
                          : _inimigosEscolhidos.add(c);
                    }),
                    onAvancar: () =>
                        setState(() => _fase = FaseArena.rolarIniciativa),
                  ),
                  FaseArena.rolarIniciativa => RolarIniciativaView(
                    heroi: _clonePersonagem,
                    inimigos: _inimigosEscolhidos,
                    onIniciarCombate: (totalHeroi, totaisInimigos) =>
                        _iniciarCombateComIniciativas(
                          cubit,
                          totalHeroi,
                          totaisInimigos,
                        ),
                  ),
                  FaseArena.combateAtivo => LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 720;
                      if (isWide) {
                        return _buildWideLayout(context, cubit);
                      } else {
                        return _buildNarrowLayout(context, cubit);
                      }
                    },
                  ),
                },
              ),
            );
          },
        ),
      ),
    );
  }

  // ==========================================
  // LAYOUT TELAS LARGAS / TABLET (LADO A LADO)
  // ==========================================
  Widget _buildWideLayout(BuildContext context, CombateCubit cubit) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Metade Esquerda: Tabuleiro Tático + Barra de Iniciativa
        Expanded(
          flex: 6,
          child: Column(
            children: [
              _buildIniciativaBar(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _buildGridBoard(cubit),
                ),
              ),
            ],
          ),
        ),

        // Divisor vertical sutil
        const VerticalDivider(color: Colors.white12, width: 1),

        // 2. Metade Direita: Painel Informativo (Mini-Ficha, Ações, Log de Combate)
        Expanded(
          flex: 5,
          child: Container(
            color: const Color(0xFF131D31),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildMiniFicha(cubit),
                _buildPainelAcoes(cubit),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.terminal, color: Colors.greenAccent, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'LOG DE COMBATE',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                    child: _buildTerminalLog(expanded: true),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // LAYOUT TELAS ESTREITAS / CELULAR RETRATO
  // ==========================================
  Widget _buildNarrowLayout(BuildContext context, CombateCubit cubit) {
    return Column(
      children: [
        // Topo Fixo: Iniciativa e Banner com PV/PM do turno SEMPRE visíveis
        _buildIniciativaBar(),
        _buildBannerTurno(cubit),

        // Área Central: Tabuleiro Tático + Painel Recolhível
        Expanded(
          child: Stack(
            children: [
              // 1. Grid Tático com Zoom/Pan preenchendo a tela
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
                  child: _buildGridBoard(cubit),
                ),
              ),

              // 2. Painel Recolhível Inferior (DraggableScrollableSheet)
              DraggableScrollableSheet(
                initialChildSize: 0.38,
                minChildSize: 0.16,
                maxChildSize: 0.85,
                snap: true,
                snapSizes: const [0.16, 0.38, 0.85],
                builder: (context, scrollController) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E293B),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius: 10,
                          offset: Offset(0, -3),
                        ),
                      ],
                    ),
                    child: ListView(
                      controller: scrollController,
                      padding: EdgeInsets.zero,
                      children: [
                        // Puxador de arrastar (Grab handle)
                        Center(
                          child: Container(
                            margin: const EdgeInsets.only(top: 8, bottom: 6),
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white38,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),

                        // Ações Rápidas (visíveis no tamanho recolhido)
                        _buildPainelAcoes(cubit),

                        // Mini Ficha Detalhada (visível ao expandir)
                        _buildMiniFicha(cubit),

                        // Terminal de Log
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          child: Text(
                            'Histórico de Combate',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 0, 10, 16),
                          child: _buildTerminalLog(height: 140),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // COMPONENTES COM RECONSTRUÇÃO ISOLADA
  // ==========================================

  Widget _buildIniciativaBar() {
    return BlocBuilder<CombateCubit, CombateState>(
      buildWhen: (prev, curr) =>
          prev.filaIniciativa != curr.filaIniciativa ||
          prev.indiceTurnoAtual != curr.indiceTurnoAtual,
      builder: (context, state) {
        return ArenaIniciativaBar(state: state);
      },
    );
  }

  Widget _buildBannerTurno(CombateCubit cubit) {
    return BlocBuilder<CombateCubit, CombateState>(
      buildWhen: (prev, curr) =>
          prev.combatenteAtual != curr.combatenteAtual ||
          prev.combatenteAtual?.pvAtual != curr.combatenteAtual?.pvAtual ||
          prev.combatenteAtual?.pmAtual != curr.combatenteAtual?.pmAtual,
      builder: (context, state) {
        final atual = state.combatenteAtual;
        if (atual == null) return const SizedBox.shrink();
        return ArenaBannerTurno(
          combatente: atual,
          onAjustarPv: () => exibirModalArbitragemVtt(context, atual, cubit),
        );
      },
    );
  }

  Widget _buildGridBoard(CombateCubit cubit) {
    return BlocBuilder<CombateCubit, CombateState>(
      buildWhen: (previous, current) {
        return previous.posicoesCombatentes != current.posicoesCombatentes ||
            previous.celulasAlcancaveis != current.celulasAlcancaveis ||
            previous.mapaGrid != current.mapaGrid ||
            previous.combatenteAtual?.id != current.combatenteAtual?.id ||
            previous.modoMovimentoAtivo != current.modoMovimentoAtivo ||
            previous.filaIniciativa != current.filaIniciativa;
      },
      builder: (context, state) {
        final atual = state.combatenteAtual;
        return VttBoardWidget(
          state: state,
          onCelulaClicada: (pos) =>
              atual != null && state.modoMovimentoAtivo
                  ? cubit.moverCombatente(atual.id, pos)
                  : null,
          onCombatenteClicado: (alvo) =>
              exibirModalArbitragemVtt(context, alvo, cubit),
        );
      },
    );
  }

  Widget _buildMiniFicha(CombateCubit cubit) {
    return BlocBuilder<CombateCubit, CombateState>(
      buildWhen: (prev, curr) =>
          prev.combatenteAtual != curr.combatenteAtual ||
          prev.combatenteAtual?.pvAtual != curr.combatenteAtual?.pvAtual ||
          prev.combatenteAtual?.pmAtual != curr.combatenteAtual?.pmAtual ||
          prev.combatenteAtual?.condicoesAtivas != curr.combatenteAtual?.condicoesAtivas ||
          prev.efeitosAtivos != curr.efeitosAtivos,
      builder: (context, state) {
        final atual = state.combatenteAtual;
        if (atual == null) return const SizedBox.shrink();
        final efeitosDoCombatente = state.efeitosAtivos
            .where((e) => e.combatenteId == atual.id)
            .toList();
        return MiniFichaCombatenteWidget(
          combatente: atual,
          efeitosAtivos: efeitosDoCombatente,
          onRemoverEfeito: (id) => cubit.removerEfeitoAtivo(id),
          onAjusteClicado: () =>
              exibirModalArbitragemVtt(context, atual, cubit),
        );
      },
    );
  }

  Widget _buildPainelAcoes(CombateCubit cubit) {
    return BlocBuilder<CombateCubit, CombateState>(
      buildWhen: (prev, curr) =>
          prev.combatenteAtual != curr.combatenteAtual ||
          prev.modoMovimentoAtivo != curr.modoMovimentoAtivo ||
          prev.acoesPadraoRestantes != curr.acoesPadraoRestantes ||
          prev.acoesMovimentoRestantes != curr.acoesMovimentoRestantes ||
          prev.deslocamentoRestanteMetros != curr.deslocamentoRestanteMetros ||
          prev.combatenteAtual?.pmAtual != curr.combatenteAtual?.pmAtual ||
          prev.filaIniciativa != curr.filaIniciativa,
      builder: (context, state) {
        return ArenaPainelAcoes(cubit: cubit, state: state, stats: _stats);
      },
    );
  }

  Widget _buildTerminalLog({bool expanded = false, double? height}) {
    return BlocSelector<CombateCubit, CombateState, List<String>>(
      selector: (state) => state.logCombate,
      builder: (context, logs) {
        return ArenaTerminalLog(
          logs: logs,
          expanded: expanded,
          height: height,
        );
      },
    );
  }
}
