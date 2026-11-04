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
      child: BlocConsumer<CombateCubit, CombateState>(
        listener: (context, state) {
          if (state.combateTerminado &&
              !_relatorioExibido &&
              _fase == FaseArena.combateAtivo) {
            _relatorioExibido = true;
            exibirRelatorioFinal(context, state, _stats);
          }
        },
        builder: (context, state) {
          final cubit = context.read<CombateCubit>();
          final atual = state.combatenteAtual;

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
                FaseArena.combateAtivo => Column(
                  children: [
                    ArenaIniciativaBar(state: state),
                    if (atual != null)
                      MiniFichaCombatenteWidget(
                        combatente: atual,
                        onAjusteClicado: () =>
                            exibirModalArbitragemVtt(context, atual, cubit),
                      ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: VttBoardWidget(
                          state: state,
                          onCelulaClicada: (pos) =>
                              atual != null && state.modoMovimentoAtivo
                              ? cubit.moverCombatente(atual.id, pos)
                              : null,
                          onCombatenteClicado: (alvo) =>
                              exibirModalArbitragemVtt(context, alvo, cubit),
                        ),
                      ),
                    ),
                    ArenaPainelAcoes(cubit: cubit, state: state, stats: _stats),
                    ArenaTerminalLog(logs: state.logCombate),
                  ],
                ),
              },
            ),
          );
        },
      ),
    );
  }
}
