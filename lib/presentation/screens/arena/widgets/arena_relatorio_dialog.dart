import 'package:flutter/material.dart';
import '../../../../domain/services/combate_services/arena_stats_collector.dart';
import '../../../../domain/services/combate_services/combate_engine.dart';
import '../../../controllers/combate_controller/combate_state.dart';

void exibirRelatorioFinal(
  BuildContext context,
  CombateState state,
  ArenaStatsCollector stats,
) {
  final vitoria = state.statusCombate == StatusCombate.vitoria;
  final relatorio = stats.gerarRelatorio(
    rodadas: state.rodadaAtual,
    vitoria: vitoria,
  );

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      title: Text(
        vitoria ? '🏆 Vitória na Arena!' : '💀 Derrota na Arena',
        style: TextStyle(
          color: vitoria ? Colors.amber : Colors.redAccent,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rodadas duradas: ${relatorio.rodadasTotais}',
            style: const TextStyle(color: Colors.white),
          ),
          Text(
            'Dano Total Causado: ${relatorio.danoTotalCausado}',
            style: const TextStyle(color: Colors.white),
          ),
          Text(
            'DPR: ${relatorio.dpr.toStringAsFixed(1)}',
            style: const TextStyle(color: Colors.amberAccent),
          ),
          Text(
            'Taxa de Acerto: ${relatorio.taxaAcerto.toStringAsFixed(1)}%',
            style: const TextStyle(color: Colors.white),
          ),
          Text(
            'Golpes Críticos: ${relatorio.totalCriticos}',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFC62828),
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(ctx);
            Navigator.pop(context);
          },
          child: const Text('Voltar à Tela Inicial'),
        ),
      ],
    ),
  );
}
