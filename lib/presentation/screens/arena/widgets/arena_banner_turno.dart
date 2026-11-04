import 'package:flutter/material.dart';
import '../../../../domain/entities/combate/combatente.dart';

/// Banner compacto fixo exibido no topo do modo arena
/// Mantém as informações vitais (Turno, PV, PM, Defesa) SEMPRE visíveis
class ArenaBannerTurno extends StatelessWidget {
  final Combatente combatente;
  final VoidCallback? onAjustarPv;

  const ArenaBannerTurno({
    super.key,
    required this.combatente,
    this.onAjustarPv,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final ehHeroi = combatente.time == TimeCombatente.heroi;

    final double pvPercent = combatente.pvMax > 0
        ? (combatente.pvAtual / combatente.pvMax).clamp(0.0, 1.0)
        : 0.0;

    final Color corPv = pvPercent > 0.5
        ? Colors.greenAccent
        : (pvPercent > 0.25 ? Colors.amberAccent : Colors.redAccent);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border(
          bottom: BorderSide(
            color: ehHeroi ? Colors.blueAccent.withValues(alpha: 0.4) : Colors.redAccent.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // 1. Tag de Time / Indicador de Turno
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: ehHeroi ? const Color(0xFF1E88E5) : const Color(0xFFE53935),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              ehHeroi ? 'HERÓI' : 'AMEAÇA',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 2. Nome do Combatente Atual
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '👉 Turno: ${combatente.nome}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // 3. Indicadores Compactos de PV, PM e Defesa
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: corPv.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: corPv.withValues(alpha: 0.5)),
            ),
            child: Text(
              'PV: ${combatente.pvAtual}/${combatente.pvMax}',
              style: TextStyle(
                color: corPv,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          if (combatente.pmMax > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.lightBlueAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.lightBlueAccent.withValues(alpha: 0.5)),
              ),
              child: Text(
                'PM: ${combatente.pmAtual}/${combatente.pmMax}',
                style: const TextStyle(
                  color: Colors.lightBlueAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white24),
            ),
            child: Text(
              'DEF: ${combatente.defesa}',
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),

          if (onAjustarPv != null) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.tune, size: 18, color: Colors.amberAccent),
              tooltip: 'Ajustar PV / Arbitragem',
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: EdgeInsets.zero,
              onPressed: onAjustarPv,
            ),
          ],
        ],
      ),
    );
  }
}
