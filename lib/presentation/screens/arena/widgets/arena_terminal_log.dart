import 'package:flutter/material.dart';

class ArenaTerminalLog extends StatelessWidget {
  final List<String> logs;
  final double? height;
  final bool expanded;

  const ArenaTerminalLog({
    super.key,
    required this.logs,
    this.height,
    this.expanded = false,
  });

  Color _obterCorDoLog(String log) {
    final lower = log.toLowerCase();
    if (lower.contains('acertou') || lower.contains('crítico')) {
      return const Color(0xFF69F0AE); // Verde menta vivo
    }
    if (lower.contains('errou') || lower.contains('falha')) {
      return const Color(0xFFFFAB40); // Laranja aviso
    }
    if (lower.contains('dano') || lower.contains('caiu') || lower.contains('morreu')) {
      return const Color(0xFFFF5252); // Vermelho dano
    }
    if (lower.contains('iniciativa') || lower.contains('turno') || lower.contains('rodada')) {
      return const Color(0xFF40C4FF); // Azul claro sistema
    }
    if (lower.contains('efeito') || lower.contains('magia')) {
      return const Color(0xFFE040FB); // Roxo magia
    }
    return Colors.white70;
  }

  @override
  Widget build(BuildContext context) {
    final logInvertido = logs.reversed.toList();

    return Container(
      height: expanded ? null : (height ?? 90),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F1D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: logs.isEmpty
          ? const Center(
              child: Text(
                'Aguardando primeiras ações de combate...',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            )
          : ListView.builder(
              reverse: true,
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final linha = logInvertido[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    linha,
                    style: TextStyle(
                      color: _obterCorDoLog(linha),
                      fontSize: 11,
                      fontFamily: 'monospace',
                      height: 1.3,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
