import 'package:flutter/material.dart';
import '../../../../domain/entities/combate/combatente.dart';
import '../../../../domain/services/combate_services/arena_stats_collector.dart';
import '../../../../domain/services/combate_services/calculadora_tatica_t20.dart';
import '../../../controllers/combate_controller/combate_cubit.dart';
import '../../../controllers/combate_controller/combate_state.dart';
import 'arena_arbitragem_dialog.dart';
import 'arena_ataque_sheet.dart';
import 'arena_magia_sheet.dart';

/// Barra de ações táticas do Modo Arena.
///
/// Permite ao jogador:
/// 1. Atacar com armas equipadas (abrindo o ArenaAtaqueSheet com Sistema de Honestidade).
/// 2. Lançar magias conhecidas (abrindo o ArenaMagiaSheet com grimório e efeitos ativos).
/// 3. Alternar o modo de movimento tático no grid.
/// 4. Arbitragem e ajuste rápido na mesa (VTT).
/// 5. Passar o turno.
class ArenaPainelAcoes extends StatelessWidget {
  final CombateCubit cubit;
  final CombateState state;
  final ArenaStatsCollector stats;

  const ArenaPainelAcoes({
    super.key,
    required this.cubit,
    required this.state,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final atual = state.combatenteAtual;
    final ehVezDoHeroi = atual?.time == TimeCombatente.heroi;

    if (!ehVezDoHeroi || atual == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        color: const Color(0xFF1E293B),
        child: Row(
          children: [
            const Icon(Icons.smart_toy_outlined, color: Colors.redAccent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Vez de ${atual?.nome ?? "Inimigo"} (IA)',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text('Executar Ação da IA'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              onPressed: () => cubit.executarTurnoBot(),
            ),
          ],
        ),
      );
    }

    final inimigos = state.filaIniciativa
        .where((c) => c.time == TimeCombatente.inimigo)
        .toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      color: const Color(0xFF1E293B),
      child: Column(
        children: [
          // Resumo de Ações e Deslocamento
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                'Ações: Padrão [${state.acoesPadraoRestantes}] | Movimento [${state.acoesMovimentoRestantes}]',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Deslocamento: ${state.deslocamentoRestanteMetros.toStringAsFixed(1)}m',
                style: const TextStyle(
                  color: Colors.lightBlueAccent,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Botões de Ação Principais
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              // Botão Atacar
              ElevatedButton.icon(
                icon: const Icon(Icons.sports_kabaddi, size: 16),
                label: const Text('Atacar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC62828),
                  foregroundColor: Colors.white,
                ),
                onPressed: state.acoesPadraoRestantes > 0
                    ? () => _iniciarFluxoAtaque(context, atual, inimigos)
                    : null,
              ),

              // Botão Lançar Magia
              ElevatedButton.icon(
                icon: const Icon(Icons.auto_awesome, size: 16),
                label: const Text('Lançar Magia'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
                onPressed: state.acoesPadraoRestantes > 0 && atual.pmAtual > 0
                    ? () => ArenaMagiaSheet.exibir(
                        context,
                        heroi: atual,
                        todos: state.filaIniciativa,
                        cubit: cubit,
                        stats: stats,
                      )
                    : null,
              ),

              // Botão Mover
              ElevatedButton.icon(
                icon: const Icon(Icons.directions_walk, size: 16),
                label: Text(
                  state.modoMovimentoAtivo ? 'Cancelar Mov.' : 'Mover',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: state.modoMovimentoAtivo
                      ? Colors.orange
                      : Colors.blue,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => cubit.alternarModoMovimento(),
              ),

              // Botão Arbitragem VTT na Mesa
              OutlinedButton.icon(
                icon: const Icon(
                  Icons.tune,
                  size: 16,
                  color: Colors.amberAccent,
                ),
                label: const Text(
                  'Ajuste Mesa',
                  style: TextStyle(color: Colors.amberAccent),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.amberAccent),
                ),
                onPressed: () =>
                    exibirModalArbitragemVtt(context, atual, cubit),
              ),

              // Botão Passar Turno
              OutlinedButton.icon(
                icon: const Icon(Icons.skip_next, size: 16),
                label: const Text('Passar Turno'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                ),
                onPressed: () => cubit.proximoTurno(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _iniciarFluxoAtaque(
    BuildContext context,
    Combatente heroi,
    List<Combatente> inimigos,
  ) {
    if (heroi.armas.isEmpty) {
      cubit.registrarLog(
        '⚠️ ${heroi.nome} não possui armas equipadas para atacar!',
      );
      return;
    }

    if (heroi.armas.length == 1) {
      ArenaAtaqueSheet.exibir(
        context,
        heroi: heroi,
        arma: heroi.armas.first,
        inimigos: inimigos,
        efeitosAtivos: state.efeitosAtivos,
        cubit: cubit,
        stats: stats,
      );
      return;
    }

    // Diagnóstico comparativo de armas para apoio à decisão
    final alvoPadrao = inimigos.where((c) => c.pvAtual > 0).firstOrNull ?? inimigos.first;
    final avaliacoesArmas = <String, AvaliacaoAtaque>{};
    for (final arma in heroi.armas) {
      final modAtq = (arma.ehCorpoACorpo ? heroi.modLuta : heroi.modPontaria) + arma.bonusAtaqueMelhorias;
      final modDano = arma.somaForcaAoDano ? heroi.modForca : 0;
      avaliacoesArmas[arma.key] = CalculadoraTaticaT20.calcularAvaliacaoAtaque(
        arma: arma,
        modAtaqueTotal: modAtq,
        modDanoTotal: modDano,
        defesaAlvo: alvoPadrao.defesa,
      );
    }

    String? melhorDanoKey;
    double maxED = -1;
    String? melhorAcertoKey;
    double maxAcerto = -1;

    for (final entry in avaliacoesArmas.entries) {
      if (entry.value.danoEsperado > maxED) {
        maxED = entry.value.danoEsperado;
        melhorDanoKey = entry.key;
      }
      if (entry.value.probabilidadeAcerto > maxAcerto) {
        maxAcerto = entry.value.probabilidadeAcerto;
        melhorAcertoKey = entry.key;
      }
    }

    // Modal seletor de armas se houver mais de uma
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.compare_arrows, size: 18, color: Colors.cyanAccent),
                  const SizedBox(width: 8),
                  const Text(
                    'Escolha a Arma para o Ataque:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'vs Defesa ${alvoPadrao.defesa}',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...heroi.armas.map((arma) {
                final aval = avaliacoesArmas[arma.key];
                final ehMelhorDano = arma.key == melhorDanoKey && heroi.armas.length > 1;
                final ehMelhorAcerto = arma.key == melhorAcertoKey && !ehMelhorDano && heroi.armas.length > 1;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: ListTile(
                    tileColor: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: ehMelhorDano
                            ? Colors.amberAccent.withValues(alpha: 0.5)
                            : (ehMelhorAcerto ? Colors.cyanAccent.withValues(alpha: 0.5) : Colors.white12),
                      ),
                    ),
                    leading: Icon(
                      arma.ehCorpoACorpo ? Icons.sports_kabaddi : Icons.gps_fixed,
                      color: Colors.amberAccent,
                    ),
                    title: Text(
                      arma.nome,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dano: ${arma.dano} (${arma.criticoFormatado})',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        if (aval != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Acerto: ${aval.probabilidadePercentualFormatada} • Dano Esperado: ${aval.danoEsperadoFormatado} PV',
                            style: const TextStyle(color: Colors.cyanAccent, fontSize: 11),
                          ),
                        ],
                      ],
                    ),
                    trailing: ehMelhorDano
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF78350F),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.amberAccent),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.trending_up, size: 12, color: Colors.amberAccent),
                                SizedBox(width: 4),
                                Text(
                                  'MAIOR DANO',
                                  style: TextStyle(
                                    color: Colors.amberAccent,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : (ehMelhorAcerto
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0C4A6E),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.cyanAccent),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.gps_fixed, size: 12, color: Colors.cyanAccent),
                                    SizedBox(width: 4),
                                    Text(
                                      'MAIOR ACERTO',
                                      style: TextStyle(
                                        color: Colors.cyanAccent,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : null),
                    onTap: () {
                      Navigator.pop(ctx);
                      ArenaAtaqueSheet.exibir(
                        context,
                        heroi: heroi,
                        arma: arma,
                        inimigos: inimigos,
                        efeitosAtivos: state.efeitosAtivos,
                        cubit: cubit,
                        stats: stats,
                      );
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
