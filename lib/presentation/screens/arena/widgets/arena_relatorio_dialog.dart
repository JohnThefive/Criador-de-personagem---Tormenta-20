import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../domain/entities/combate/combatente.dart';
import '../../../../domain/entities/personagem/personagem.dart';
import '../../../../domain/services/combate_services/arena_stats_collector.dart';
import '../../../../domain/services/combate_services/combate_engine.dart';
import '../../../controllers/combate_controller/combate_state.dart';

/// Modal de Relatório e Estatísticas de Batalha da Arena Tática.
///
/// Apresenta um sumário detalhado e útil de desempenho do combatente:
/// - Dano Total Causado e DPR (Dano por Rodada)
/// - Taxa de Acerto (%) e total de acertos vs erros
/// - Golpes Críticos (quantidade e % sobre acertos)
/// - Maior Dano em um único golpe (pico de dano)
/// - Dano Sofrido e Recursos Gastos (PM e Magias)
void exibirRelatorioFinal(
  BuildContext context,
  CombateState state,
  ArenaStatsCollector stats, {
  Personagem? clonePersonagem,
}) {
  final vitoria = state.statusCombate == StatusCombate.vitoria;

  // Extrai o dano sofrido a partir do clone do personagem
  int danoSofridoCalculado = stats.danoRecebido;
  final heroi = state.filaIniciativa
      .where((c) => c.time == TimeCombatente.heroi)
      .firstOrNull;

  if (heroi != null) {
    final pvOriginal = clonePersonagem?.pvAtual ?? heroi.pvMax;
    final danoLetal = max(0, pvOriginal - heroi.pvAtual);
    final danoTotal = danoLetal + heroi.danoNaoLetal;
    if (danoTotal > danoSofridoCalculado) {
      danoSofridoCalculado = danoTotal;
      stats.atualizarDanoRecebido(danoTotal);
    }

    if (clonePersonagem != null) {
      final pmGastoCalculado = max(0, clonePersonagem.pmAtual - heroi.pmAtual);
      if (pmGastoCalculado > stats.pmGasto) {
        stats.registrarGastoPm(pmGastoCalculado - stats.pmGasto);
      }
    }
  }

  final relatorio = stats.gerarRelatorio(
    rodadas: state.rodadaAtual,
    vitoria: vitoria,
    danoRecebidoOverride: danoSofridoCalculado,
  );

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final textTheme = theme.textTheme;

      return Dialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Cabeçalho: Ícone e Título com Destaque
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: vitoria
                            ? Colors.amber.withValues(alpha: 0.2)
                            : Colors.red.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: vitoria ? Colors.amberAccent : Colors.redAccent,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        vitoria ? Icons.emoji_events : Icons.sentiment_very_dissatisfied,
                        color: vitoria ? Colors.amberAccent : Colors.redAccent,
                        size: 34,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    vitoria ? 'VITÓRIA NA ARENA!' : 'DERROTA EM COMBATE',
                    textAlign: TextAlign.center,
                    style: textTheme.titleLarge?.copyWith(
                      color: vitoria ? Colors.amberAccent : Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Batalha finalizada em ${relatorio.rodadasTotais} ${relatorio.rodadasTotais == 1 ? "rodada" : "rodadas"}',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 16),

                  // 2. Seção: Desempenho Ofensivo
                  const Row(
                    children: [
                      Icon(Icons.local_fire_department, size: 16, color: Colors.orangeAccent),
                      SizedBox(width: 6),
                      Text(
                        'DESEMPENHO OFENSIVO',
                        style: TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          label: 'Dano Total Causado',
                          valor: '${relatorio.danoTotalCausado} PV',
                          icone: Icons.flash_on,
                          corValor: Colors.orangeAccent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMetricCard(
                          label: 'DPR (Dano / Rodada)',
                          valor: relatorio.dpr.toStringAsFixed(1),
                          icone: Icons.speed,
                          corValor: Colors.amberAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          label: 'Taxa de Acerto',
                          valor: '${relatorio.taxaAcerto.toStringAsFixed(1)}%',
                          subtitulo: '${relatorio.totalAcertos}/${relatorio.totalAtaquesRealizados} acertos',
                          icone: Icons.gps_fixed,
                          corValor: Colors.greenAccent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMetricCard(
                          label: 'Golpes Críticos',
                          valor: '${relatorio.totalCriticos}',
                          subtitulo: '${relatorio.taxaCritico.toStringAsFixed(1)}% dos acertos',
                          icone: Icons.star,
                          corValor: Colors.yellowAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildMetricCard(
                    label: 'Maior Dano em 1 Golpe',
                    valor: '${relatorio.maiorDanoGolpe} PV',
                    icone: Icons.bolt,
                    corValor: Colors.lightGreenAccent,
                    isWide: true,
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 16),

                  // 3. Seção: Defesa e Gestão de Recursos
                  const Row(
                    children: [
                      Icon(Icons.shield_outlined, size: 16, color: Colors.lightBlueAccent),
                      SizedBox(width: 6),
                      Text(
                        'DEFESA & RECURSOS GASTOS',
                        style: TextStyle(
                          color: Colors.lightBlueAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          label: 'Dano Sofrido',
                          valor: '${relatorio.danoTotalRecebido} PV',
                          icone: Icons.heart_broken_outlined,
                          corValor: Colors.redAccent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMetricCard(
                          label: 'PM Consumido',
                          valor: '${relatorio.pmGasto} PM',
                          subtitulo: '${relatorio.magiasLancadas} magias usadas',
                          icone: Icons.auto_awesome,
                          corValor: Colors.purpleAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 4. Botão de Saída
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC62828),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text(
                        'Voltar à Tela Inicial',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildMetricCard({
  required String label,
  required String valor,
  String? subtitulo,
  required IconData icone,
  required Color corValor,
  bool isWide = false,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFF0F172A),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.white12),
    ),
    child: Row(
      children: [
        Icon(icone, size: 20, color: corValor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                valor,
                style: TextStyle(
                  color: corValor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (subtitulo != null) ...[
                const SizedBox(height: 1),
                Text(
                  subtitulo,
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}
