import 'package:flutter/material.dart';
import '../../../../domain/entities/combate/combatente.dart';
import '../../../../domain/entities/combate/efeito_ativo_combate.dart';

class MiniFichaCombatenteWidget extends StatelessWidget {
  final Combatente combatente;
  final VoidCallback? onAjusteClicado;
  final List<EfeitoAtivoCombate> efeitosAtivos;
  final void Function(String efeitoId)? onRemoverEfeito;

  const MiniFichaCombatenteWidget({
    super.key,
    required this.combatente,
    this.onAjusteClicado,
    this.efeitosAtivos = const [],
    this.onRemoverEfeito,
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
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  combatente.estadoVida.label,
                  style: TextStyle(
                    color: combatente.podeAgir
                        ? Colors.greenAccent
                        : Colors.orangeAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onAjusteClicado != null) ...[
                const SizedBox(width: 6),
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

          // Métricas Rápidas: Defesa, Deslocamento, Ataques e Resistências
          Wrap(
            spacing: 10,
            runSpacing: 4,
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
              if (combatente is CombatenteMonstro) ...[
                _buildBadge(
                  'Fort',
                  '${combatente.modFortitude >= 0 ? "+" : ""}${combatente.modFortitude}',
                  Icons.favorite_border,
                ),
                _buildBadge(
                  'Ref',
                  '${combatente.modReflexos >= 0 ? "+" : ""}${combatente.modReflexos}',
                  Icons.flash_on,
                ),
                _buildBadge(
                  'Von',
                  '${combatente.modVontade >= 0 ? "+" : ""}${combatente.modVontade}',
                  Icons.psychology,
                ),
              ],
            ],
          ),

          if (combatente case final CombatenteMonstro monstroAtual) ...[
            const SizedBox(height: 6),
            _buildThreatBadges(monstroAtual),
          ],

          // Armas Equipadas
          if (combatente.armas.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
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

          // Efeitos Ativos (Sistema de Honestidade)
          if (efeitosAtivos.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: efeitosAtivos.map((e) {
                final bonusStr = [
                  if (e.bonusAtaque != 0) '${e.bonusAtaque > 0 ? "+" : ""}${e.bonusAtaque} Atq',
                  if (e.bonusDano != 0) '${e.bonusDano > 0 ? "+" : ""}${e.bonusDano} Dano',
                ].join(', ');

                return Chip(
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  backgroundColor: Colors.purple.shade900.withValues(alpha: 0.6),
                  side: BorderSide(color: Colors.purpleAccent.withValues(alpha: 0.5)),
                  avatar: const Icon(Icons.auto_awesome, size: 12, color: Colors.purpleAccent),
                  label: Text(
                    '${e.nome}${bonusStr.isNotEmpty ? " ($bonusStr)" : ""} • ${e.rodadasRestantes}r',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  deleteIcon: onRemoverEfeito != null
                      ? const Icon(Icons.close, size: 12, color: Colors.white70)
                      : null,
                  onDeleted: onRemoverEfeito != null ? () => onRemoverEfeito!(e.id) : null,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildThreatBadges(CombatenteMonstro monstro) {
    final ficha = monstro.fichaMonstro;
    final badges = <Widget>[
      _buildMiniPill(
        'ND ${ficha.nd} • ${ficha.papel.label} • ${ficha.tipoCriatura}${ficha.tamanhoQuadrados > 1 ? ' (${ficha.tamanhoQuadrados}x${ficha.tamanhoQuadrados})' : ''}',
        Colors.red.shade900.withValues(alpha: 0.45),
        Colors.redAccent.withValues(alpha: 0.5),
      ),
    ];

    if (ficha.rd.isNotEmpty) {
      final rdTexto = ficha.rd.entries.map((e) => '${e.key} ${e.value}').join(', ');
      badges.add(
        _buildMiniPill(
          'RD: $rdTexto',
          Colors.blueGrey.shade800,
          Colors.lightBlueAccent.withValues(alpha: 0.4),
        ),
      );
    }

    if (ficha.imunidadesDano.isNotEmpty) {
      badges.add(
        _buildMiniPill(
          'Imune dano: ${ficha.imunidadesDano.join(', ')}',
          Colors.teal.shade900.withValues(alpha: 0.5),
          Colors.tealAccent.withValues(alpha: 0.4),
        ),
      );
    }

    if (ficha.vulnerabilidadesDano.isNotEmpty) {
      badges.add(
        _buildMiniPill(
          'Vulnerável: ${ficha.vulnerabilidadesDano.join(', ')}',
          Colors.orange.shade900.withValues(alpha: 0.5),
          Colors.orangeAccent.withValues(alpha: 0.5),
        ),
      );
    }

    final nulos = <String>[
      if (ficha.forcaNula) 'For –',
      if (ficha.destrezaNula) 'Des –',
      if (ficha.constituicaoNula) 'Con –',
      if (ficha.modInteligencia == null) 'Int –',
    ];
    if (nulos.isNotEmpty) {
      badges.add(
        _buildMiniPill(
          'Atrib.: ${nulos.join(', ')}',
          Colors.white10,
          Colors.white24,
        ),
      );
    }

    for (final h in ficha.habilidades.where((h) => h.recarga != null)) {
      final emRecarga = monstro.habilidadeEmRecarga(h.nome);
      badges.add(
        _buildMiniPill(
          '${h.nome}${emRecarga ? ' [EM RECARGA]' : ' [Pronta]'}',
          emRecarga
              ? Colors.amber.shade900.withValues(alpha: 0.4)
              : Colors.green.shade900.withValues(alpha: 0.4),
          emRecarga ? Colors.amberAccent : Colors.greenAccent,
        ),
      );
    }

    return Wrap(spacing: 6, runSpacing: 4, children: badges);
  }

  Widget _buildMiniPill(String texto, Color bg, Color border) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: border),
      ),
      child: Text(
        texto,
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
    );
  }

  Widget _buildBadge(String label, String valor, IconData icone) {
    return Row(
      mainAxisSize: MainAxisSize.min,
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
