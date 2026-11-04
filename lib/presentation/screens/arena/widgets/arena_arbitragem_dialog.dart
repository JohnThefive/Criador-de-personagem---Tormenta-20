import 'package:flutter/material.dart';
import '../../../../domain/entities/combate/combatente.dart';
import '../../../controllers/combate_controller/combate_cubit.dart';

/// Modal de Arbitragem Rápida na Mesa (Pilar 3: VTT Tabletop Assistant)
/// Permite ao jogador ou mestre aplicar dano total, metade do dano (teste de resistência)
/// ou cura diretamente em qualquer combatente.
void exibirModalArbitragemVtt(
  BuildContext context,
  Combatente combatente,
  CombateCubit cubit,
) {
  final valorController = TextEditingController(text: '10');
  final motivoController = TextEditingController(text: 'Efeito / Magia');

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1E293B),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final ehHeroi = combatente.time == TimeCombatente.heroi;

          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho com Nome e PV atual
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: ehHeroi ? Colors.blue[900] : Colors.red[900],
                      child: Icon(
                        ehHeroi ? Icons.shield : Icons.sports_kabaddi,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            combatente.nome,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'PV: ${combatente.pvAtual}/${combatente.pvMax} • Defesa: ${combatente.defesa}',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(color: Colors.white24, height: 20),

                const Text(
                  '⚡ Arbitragem Rápida de PV (Mesa VTT)',
                  style: TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                // Campo de Valor e Atalhos Rápidos (+5, +10)
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: valorController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Valor (PV)',
                          labelStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildPresetChip(
                      '+5',
                      () {
                        final v = int.tryParse(valorController.text) ?? 0;
                        setModalState(() => valorController.text = '${v + 5}');
                      },
                    ),
                    const SizedBox(width: 4),
                    _buildPresetChip(
                      '+10',
                      () {
                        final v = int.tryParse(valorController.text) ?? 0;
                        setModalState(() => valorController.text = '${v + 10}');
                      },
                    ),
                    const SizedBox(width: 4),
                    _buildPresetChip(
                      '+20',
                      () {
                        final v = int.tryParse(valorController.text) ?? 0;
                        setModalState(() => valorController.text = '${v + 20}');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Campo de Motivo (ex: Bola de Fogo, Arma de Jade, Queda, Veneno)
                TextField(
                  controller: motivoController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Motivo / Origem',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Botões de Resolução
                Row(
                  children: [
                    // Dano Total
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.flash_on, size: 16),
                        label: const Text('Dano Total', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[800],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () {
                          final v = int.tryParse(valorController.text) ?? 0;
                          if (v > 0) {
                            cubit.aplicarAjusteVtt(
                              combatenteId: combatente.id,
                              valor: v,
                              motivo: motivoController.text.trim().isEmpty
                                  ? 'Dano direto'
                                  : motivoController.text.trim(),
                              ehCura: false,
                              ehMetade: false,
                            );
                            Navigator.pop(ctx);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Metade (Teste de Resistência)
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.shield_outlined, size: 16),
                        label: const Text('Metade (Resistiu)', style: TextStyle(fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[800],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () {
                          final v = int.tryParse(valorController.text) ?? 0;
                          if (v > 0) {
                            cubit.aplicarAjusteVtt(
                              combatenteId: combatente.id,
                              valor: v,
                              motivo: motivoController.text.trim().isEmpty
                                  ? 'Passou na resistência'
                                  : '${motivoController.text.trim()} (resistiu)',
                              ehCura: false,
                              ehMetade: true,
                            );
                            Navigator.pop(ctx);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Cura
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.favorite, size: 16),
                        label: const Text('Curar', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () {
                          final v = int.tryParse(valorController.text) ?? 0;
                          if (v > 0) {
                            cubit.aplicarAjusteVtt(
                              combatenteId: combatente.id,
                              valor: v,
                              motivo: motivoController.text.trim().isEmpty
                                  ? 'Cura direta'
                                  : motivoController.text.trim(),
                              ehCura: true,
                              ehMetade: false,
                            );
                            Navigator.pop(ctx);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Widget _buildPresetChip(String label, VoidCallback onTap) {
  return ActionChip(
    backgroundColor: const Color(0xFF0F172A),
    side: const BorderSide(color: Colors.white24),
    label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
    onPressed: onTap,
  );
}
