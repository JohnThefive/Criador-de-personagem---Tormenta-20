import 'package:flutter/material.dart';
import '../../../../domain/entities/combate/combatente.dart';

class MiniFichaCombatenteWidget extends StatelessWidget {
  final Combatente combatente;
  final VoidCallback? onAjusteClicado;

  const MiniFichaCombatenteWidget({
    super.key,
    required this.combatente,
    this.onAjusteClicado,
  });

  @override
  Widget build(BuildContext context) {
    final ehHeroi = combatente.time == TimeCombatente.heroi;
    final pvPorcentagem = combatente.pvMax > 0
        ? (combatente.pvAtual / combatente.pvMax).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ehHeroi ? Colors.blueAccent : Colors.redAccent,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Linha Superior: Nome, Tag e Estado
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: ehHeroi ? Colors.blue[900] : Colors.red[900],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  ehHeroi ? 'HERÓI' : 'AMEAÇA',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  combatente.nome,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                combatente.estadoVida.label,
                style: TextStyle(
                  color: combatente.podeAgir
                      ? Colors.greenAccent
                      : Colors.orangeAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (onAjusteClicado != null) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: onAjusteClicado,
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amberAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Colors.amberAccent.withValues(alpha: 0.6),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.tune, size: 12, color: Colors.amberAccent),
                        SizedBox(width: 3),
                        Text(
                          'Ajustar PV',
                          style: TextStyle(
                            color: Colors.amberAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),

          // Barras de PV e PM
          Row(
            children: [
              // Barra de Vida
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'PV',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${combatente.pvAtual}/${combatente.pvMax}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pvPorcentagem,
                        minHeight: 6,
                        backgroundColor: Colors.white12,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          pvPorcentagem > 0.5
                              ? Colors.green
                              : (pvPorcentagem > 0.25
                                    ? Colors.amber
                                    : Colors.red),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Barra de Mana
              if (combatente.pmMax > 0)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'PM',
                            style: TextStyle(
                              color: Colors.lightBlueAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${combatente.pmAtual}/${combatente.pmMax}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (combatente.pmAtual / combatente.pmMax).clamp(
                            0.0,
                            1.0,
                          ),
                          minHeight: 6,
                          backgroundColor: Colors.white12,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.lightBlueAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Métricas Rápidas: Defesa, Deslocamento e Ataques
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBadge('Defesa', '${combatente.defesa}', Icons.shield),
              _buildBadge(
                'Desloc.',
                '${combatente.deslocamentoMetros.toStringAsFixed(1)}m',
                Icons.directions_walk,
              ),
              _buildBadge(
                'Luta',
                '+${combatente.modLuta}',
                Icons.sports_kabaddi,
              ),
              _buildBadge(
                'Pontaria',
                '+${combatente.modPontaria}',
                Icons.gps_fixed,
              ),
            ],
          ),

          // Armas Equipadas
          if (combatente.armas.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: combatente.armas.map((a) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '🗡️ ${a.nome} (${a.dano}, ${a.criticoFormatado})',
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadge(String label, String valor, IconData icone) {
    return Row(
      children: [
        Icon(icone, size: 12, color: Colors.white54),
        const SizedBox(width: 3),
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
        Text(
          valor,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
