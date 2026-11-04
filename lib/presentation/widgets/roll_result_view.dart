import 'package:flutter/material.dart';
import '../../domain/services/combate_services/dice_roll_service.dart';

/// Apresentação do resultado de rolagem estilo Baldur's Gate 3.
///
/// Exibe número grande centralizado, destaque dramático para 20 Natural (Crítico)
/// e 1 Natural (Falha Crítica), e a decomposição detalhada da rolagem abaixo.
class RollResultView extends StatelessWidget {
  final ResultadoD20 resultado;
  final String? titulo;

  const RollResultView({
    super.key,
    required this.resultado,
    this.titulo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final ehCritico = resultado.ehVinteNatural;
    final ehFalha = resultado.ehUmNatural;

    Color corDestaque = Colors.amberAccent;
    String statusTexto = titulo ?? 'Resultado da Rolagem';

    if (ehCritico) {
      corDestaque = const Color(0xFFFFD700);
      statusTexto = '⭐ CRÍTICO! (20 Natural) ⭐';
    } else if (ehFalha) {
      corDestaque = const Color(0xFFFF5252);
      statusTexto = '💀 FALHA CRÍTICA! (1 Natural) 💀';
    }

    return Semantics(
      label: '$statusTexto: Total ${resultado.total}. ${resultado.decomposicao}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ehCritico
                ? const Color(0xFFFFD700)
                : (ehFalha ? Colors.redAccent : Colors.white24),
            width: ehCritico || ehFalha ? 2.0 : 1.0,
          ),
          boxShadow: ehCritico
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                    blurRadius: 14,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status do Resultado
            Text(
              statusTexto,
              style: textTheme.labelLarge?.copyWith(
                color: corDestaque,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),

            // Número Grande Estilo Baldur's Gate 3
            Text(
              '${resultado.total}',
              style: textTheme.displayLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 54,
                height: 1.1,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),

            // Decomposição Detalhada
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                resultado.decomposicao,
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
