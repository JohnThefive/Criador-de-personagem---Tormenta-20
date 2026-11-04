import 'package:flutter/material.dart';
import '../../../../domain/entities/combate/combatente.dart';
import '../../../controllers/combate_controller/combate_state.dart';

class ArenaIniciativaBar extends StatelessWidget {
  final CombateState state;

  const ArenaIniciativaBar({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: const Color(0xFF1E293B),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: state.filaIniciativa.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final c = state.filaIniciativa[index];
          final ehAtivo = index == state.indiceTurnoAtual;
          return Chip(
            padding: EdgeInsets.zero,
            backgroundColor: ehAtivo
                ? Colors.amber
                : (c.time == TimeCombatente.heroi
                      ? Colors.blue[900]
                      : Colors.red[900]),
            label: Text(
              '${c.nome} [${c.iniciativaValor}]',
              style: TextStyle(
                color: ehAtivo ? Colors.black : Colors.white,
                fontWeight: ehAtivo ? FontWeight.bold : FontWeight.normal,
                fontSize: 11,
              ),
            ),
          );
        },
      ),
    );
  }
}
