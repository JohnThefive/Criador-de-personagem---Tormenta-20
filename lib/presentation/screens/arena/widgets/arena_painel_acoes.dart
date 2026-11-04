import 'package:flutter/material.dart';
import '../../../../domain/entities/combate/combatente.dart';
import '../../../../domain/services/combate_services/arena_stats_collector.dart';
import '../../../controllers/combate_controller/combate_cubit.dart';
import '../../../controllers/combate_controller/combate_state.dart';
import 'arena_arbitragem_dialog.dart';
import 'arena_ataque_sheet.dart';
import 'arena_magia_sheet.dart';

/// Barra de ações táticas do Modo Arena.
///
/// Permite ao jogador:
/// 1. Atacar com armas equipadas (abrindo o ArenaAtaqueSheet com Sistema de Honestidade).
/// 2. Lançar magias conhecidas (abrindo o ArenaMagiaSheet com grimório e efeitos ativos).
/// 3. Alternar o modo de movimento tático no grid.
/// 4. Arbitragem e ajuste rápido na mesa (VTT).
/// 5. Passar o turno.
class ArenaPainelAcoes extends StatelessWidget {
  final CombateCubit cubit;
  final CombateState state;
  final ArenaStatsCollector stats;

  const ArenaPainelAcoes({
    super.key,
    required this.cubit,
    required this.state,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final atual = state.combatenteAtual;
    final ehVezDoHeroi = atual?.time == TimeCombatente.heroi;

    if (!ehVezDoHeroi || atual == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        color: const Color(0xFF1E293B),
        child: Row(
          children: [
            const Icon(Icons.smart_toy_outlined, color: Colors.redAccent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Vez de ${atual?.nome ?? "Inimigo"} (IA)',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text('Executar Ação da IA'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              onPressed: () => cubit.executarTurnoBot(),
            ),
          ],
        ),
      );
    }

    final inimigos = state.filaIniciativa
        .where((c) => c.time == TimeCombatente.inimigo)
        .toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      color: const Color(0xFF1E293B),
      child: Column(
        children: [
          // Resumo de Ações e Deslocamento
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                'Ações: Padrão [${state.acoesPadraoRestantes}] | Movimento [${state.acoesMovimentoRestantes}]',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Deslocamento: ${state.deslocamentoRestanteMetros.toStringAsFixed(1)}m',
                style: const TextStyle(
                  color: Colors.lightBlueAccent,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Botões de Ação Principais
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              // Botão Atacar
              ElevatedButton.icon(
                icon: const Icon(Icons.sports_kabaddi, size: 16),
                label: const Text('Atacar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC62828),
                  foregroundColor: Colors.white,
                ),
                onPressed: state.acoesPadraoRestantes > 0
                    ? () => _iniciarFluxoAtaque(context, atual, inimigos)
                    : null,
              ),

              // Botão Lançar Magia
              ElevatedButton.icon(
                icon: const Icon(Icons.auto_awesome, size: 16),
                label: const Text('Lançar Magia'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
                onPressed: state.acoesPadraoRestantes > 0 && atual.pmAtual > 0
                    ? () => ArenaMagiaSheet.exibir(
                        context,
                        heroi: atual,
                        todos: state.filaIniciativa,
                        cubit: cubit,
                      )
                    : null,
              ),

              // Botão Mover
              ElevatedButton.icon(
                icon: const Icon(Icons.directions_walk, size: 16),
                label: Text(
                  state.modoMovimentoAtivo ? 'Cancelar Mov.' : 'Mover',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: state.modoMovimentoAtivo
                      ? Colors.orange
                      : Colors.blue,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => cubit.alternarModoMovimento(),
              ),

              // Botão Arbitragem VTT na Mesa
              OutlinedButton.icon(
                icon: const Icon(Icons.tune, size: 16, color: Colors.amberAccent),
                label: const Text(
                  'Ajuste Mesa',
                  style: TextStyle(color: Colors.amberAccent),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.amberAccent),
                ),
                onPressed: () => exibirModalArbitragemVtt(context, atual, cubit),
              ),

              // Botão Passar Turno
              OutlinedButton.icon(
                icon: const Icon(Icons.skip_next, size: 16),
                label: const Text('Passar Turno'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                ),
                onPressed: () => cubit.proximoTurno(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _iniciarFluxoAtaque(
    BuildContext context,
    Combatente heroi,
    List<Combatente> inimigos,
  ) {
    if (heroi.armas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este combatente não possui armas equipadas!'),
        ),
      );
      return;
    }

    if (heroi.armas.length == 1) {
      ArenaAtaqueSheet.exibir(
        context,
        heroi: heroi,
        arma: heroi.armas.first,
        inimigos: inimigos,
        efeitosAtivos: state.efeitosAtivos,
        cubit: cubit,
        stats: stats,
      );
      return;
    }

    // Modal seletor de armas se houver mais de uma
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Escolha a Arma para o Ataque:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              ...heroi.armas.map(
                (arma) => ListTile(
                  tileColor: const Color(0xFF0F172A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  leading: Icon(
                    arma.ehCorpoACorpo ? Icons.sports_kabaddi : Icons.gps_fixed,
                    color: Colors.amberAccent,
                  ),
                  title: Text(
                    arma.nome,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Dano: ${arma.dano} (${arma.criticoFormatado})',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    ArenaAtaqueSheet.exibir(
                      context,
                      heroi: heroi,
                      arma: arma,
                      inimigos: inimigos,
                      efeitosAtivos: state.efeitosAtivos,
                      cubit: cubit,
                      stats: stats,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
