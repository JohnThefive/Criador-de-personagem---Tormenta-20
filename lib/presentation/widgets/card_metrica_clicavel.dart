import 'package:flutter/material.dart';

/// Card indicador compacto e clicável usado para exibir métricas ou dados físicos
/// da ficha (ex: moedas de Tibar, Tamanho, Altura, Peso).
class CardMetricaClicavel extends StatelessWidget {
  final Key? keyWidget;
  final String rotulo;
  final String valor;
  final String? subtitulo;
  final Color? corRotulo;
  final double tamanhoRotulo;
  final FontWeight pesoRotulo;
  final double tamanhoValor;
  final FontWeight pesoValor;
  final double minHeight;
  final EdgeInsetsGeometry padding;
  final VoidCallback onTap;

  const CardMetricaClicavel({
    super.key,
    this.keyWidget,
    required this.rotulo,
    required this.valor,
    this.subtitulo,
    this.corRotulo,
    this.tamanhoRotulo = 11,
    this.pesoRotulo = FontWeight.w600,
    this.tamanhoValor = 14,
    this.pesoValor = FontWeight.w800,
    this.minHeight = 48,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        key: keyWidget,
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          constraints: BoxConstraints(minHeight: minHeight),
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                rotulo,
                style: TextStyle(
                  fontSize: tamanhoRotulo,
                  fontWeight: pesoRotulo,
                  color: corRotulo ?? const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                valor,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: tamanhoValor,
                  fontWeight: pesoValor,
                  color: const Color(0xFF0F172A),
                ),
              ),
              if (subtitulo != null) ...[
                Text(
                  subtitulo!,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
