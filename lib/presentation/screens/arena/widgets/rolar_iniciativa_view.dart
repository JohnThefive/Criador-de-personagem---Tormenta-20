import 'package:flutter/material.dart';
import '../../../../domain/entities/personagem/personagem.dart';

class RolarIniciativaView extends StatelessWidget {
  final Personagem heroi;
  final bool rolando;
  final VoidCallback onRolar;

  const RolarIniciativaView({
    super.key,
    required this.heroi,
    required this.rolando,
    required this.onRolar,
  });

  @override
  Widget build(BuildContext context) {
    final modIniciativa = heroi.getValorPericia('INICIATIVA');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.casino, size: 80, color: Colors.amberAccent),
            const SizedBox(height: 16),
            const Text(
              'Rolagem de Iniciativa',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${heroi.nome} tem bônus de Iniciativa: +$modIniciativa',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 24),
            if (rolando)
              const CircularProgressIndicator(color: Colors.amberAccent)
            else
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amberAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 28),
                label: const Text(
                  '🎲 Rolar Iniciativa (1d20)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                onPressed: onRolar,
              ),
          ],
        ),
      ),
    );
  }
}
