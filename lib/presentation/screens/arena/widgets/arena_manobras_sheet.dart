import 'package:flutter/material.dart';
import '../../../../domain/entities/combate/combatente.dart';
import '../../../../domain/entities/equipamento/arma.dart';
import '../../../controllers/combate_controller/combate_cubit.dart';
import '../../../controllers/combate_controller/combate_state.dart';

/// Modal Tático de Manobras de Batalha (R61, R63, R76).
///
/// Disponível para QUALQUER personagem segundo as regras do Tormenta 20:
/// 1. Fintar (Ação Padrão, Enganação vs Reflexos -> Alvo Desprevenido)
/// 2. Atropelar (Movimento/Padrão, Luta vs Luta -> Alvo Caído)
/// 3. Investida (Ação Completa, +2 Ataque, -2 Defesa)
/// 4. Manobra Quebrar (Ação Padrão, dano contra item/arma do oponente)
class ArenaManobrasSheet extends StatefulWidget {
  final Combatente heroi;
  final List<Combatente> inimigos;
  final CombateCubit cubit;
  final CombateState state;

  const ArenaManobrasSheet({
    super.key,
    required this.heroi,
    required this.inimigos,
    required this.cubit,
    required this.state,
  });

  static void exibir(
    BuildContext context, {
    required Combatente heroi,
    required List<Combatente> inimigos,
    required CombateCubit cubit,
    required CombateState state,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => ArenaManobrasSheet(
        heroi: heroi,
        inimigos: inimigos,
        cubit: cubit,
        state: state,
      ),
    );
  }

  @override
  State<ArenaManobrasSheet> createState() => _ArenaManobrasSheetState();
}

enum TipoManobraSelecionada { fintar, atropelar, investida, quebrar }

class _ArenaManobrasSheetState extends State<ArenaManobrasSheet> {
  TipoManobraSelecionada _manobraSelecionada = TipoManobraSelecionada.fintar;
  late Combatente _alvoSelecionado;
  Arma? _armaSelecionada;

  // Parâmetros para manobra Quebrar
  String _tipoItemQuebrar = 'Arma'; // 'Arma' ou 'Escudo'

  @override
  void initState() {
    super.initState();
    final vivos = widget.inimigos.where((i) => i.pvAtual > 0).toList();
    _alvoSelecionado = vivos.isNotEmpty ? vivos.first : widget.inimigos.first;
    _armaSelecionada = widget.heroi.armas.isNotEmpty
        ? widget.heroi.armas.first
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final vivos = widget.inimigos.where((i) => i.pvAtual > 0).toList();

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabeçalho
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFD97706),
                child: Icon(
                  Icons.sports_martial_arts,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manobras de Batalha (T20)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Ações táticas abertas a todos os personagens',
                      style: TextStyle(color: Colors.amberAccent, fontSize: 11),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 20),

          // Seletor de Manobras (Segmented / Abas)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildOpcaoManobra(
                tipo: TipoManobraSelecionada.fintar,
                titulo: 'Fintar',
                icone: Icons.visibility_off,
                cor: Colors.purpleAccent,
              ),
              _buildOpcaoManobra(
                tipo: TipoManobraSelecionada.atropelar,
                titulo: 'Atropelar',
                icone: Icons.directions_run,
                cor: Colors.deepOrangeAccent,
              ),
              _buildOpcaoManobra(
                tipo: TipoManobraSelecionada.investida,
                titulo: 'Investida',
                icone: Icons.bolt,
                cor: Colors.redAccent,
              ),
              _buildOpcaoManobra(
                tipo: TipoManobraSelecionada.quebrar,
                titulo: 'Quebrar',
                icone: Icons.gavel,
                cor: Colors.tealAccent,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Descrição da Manobra Selecionada
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white12),
            ),
            child: _buildDescricaoRegra(),
          ),
          const SizedBox(height: 14),

          // Seletor de Alvo Inimigo
          const Text(
            'Selecione o Alvo:',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<Combatente>(
            initialValue: vivos.contains(_alvoSelecionado)
                ? _alvoSelecionado
                : vivos.firstOrNull,
            dropdownColor: const Color(0xFF1E293B),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: const Color(0xFF0F172A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.white24),
              ),
            ),
            style: const TextStyle(color: Colors.white, fontSize: 13),
            items: vivos.map((inimigo) {
              final status = inimigo.condicoesAtivas.isNotEmpty
                  ? " [${inimigo.condicoesAtivas.map((c) => c.name).join(', ')}]"
                  : "";
              return DropdownMenuItem<Combatente>(
                value: inimigo,
                child: Text(
                  "${inimigo.nome} (PV ${inimigo.pvAtual}/${inimigo.pvMax})$status",
                ),
              );
            }).toList(),
            onChanged: (novo) {
              if (novo != null) setState(() => _alvoSelecionado = novo);
            },
          ),

          // Opção extra para manobra Quebrar: item alvo
          if (_manobraSelecionada == TipoManobraSelecionada.quebrar) ...[
            const SizedBox(height: 12),
            const Text(
              'Item / Equipamento Alvo:',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Arma (RD 5, PV 10)'),
                    selected: _tipoItemQuebrar == 'Arma',
                    selectedColor: Colors.teal,
                    onSelected: (sel) {
                      if (sel) setState(() => _tipoItemQuebrar = 'Arma');
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Escudo (RD 5, PV 15)'),
                    selected: _tipoItemQuebrar == 'Escudo',
                    selectedColor: Colors.teal,
                    onSelected: (sel) {
                      if (sel) setState(() => _tipoItemQuebrar = 'Escudo');
                    },
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 18),

          // Botão de Confirmação e Execução
          ElevatedButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: Text(_rotuloBotaoExecutar()),
            style: ElevatedButton.styleFrom(
              backgroundColor: _corBotaoExecutar(),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _podeExecutar() ? () => _executarManobra(context) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildOpcaoManobra({
    required TipoManobraSelecionada tipo,
    required String titulo,
    required IconData icone,
    required Color cor,
  }) {
    final selecionada = _manobraSelecionada == tipo;
    return ChoiceChip(
      avatar: Icon(icone, size: 16, color: selecionada ? Colors.white : cor),
      label: Text(titulo),
      selected: selecionada,
      selectedColor: cor.withValues(alpha: 0.8),
      backgroundColor: const Color(0xFF0F172A),
      labelStyle: TextStyle(
        color: selecionada ? Colors.white : Colors.white70,
        fontWeight: selecionada ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      onSelected: (sel) {
        if (sel) setState(() => _manobraSelecionada = tipo);
      },
    );
  }

  Widget _buildDescricaoRegra() {
    switch (_manobraSelecionada) {
      case TipoManobraSelecionada.fintar:
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🎭 Fintar (Ação Padrão — R61)',
              style: TextStyle(
                color: Colors.purpleAccent,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            SizedBox(height: 4),
            Text(
              '• Alcance curto (até 9m). Teste de Enganação vs Reflexos do alvo.\n'
              '• Sucesso: O alvo fica DESPREVENIDO (-5 na Defesa) contra seu próximo ataque até o fim do seu próximo turno.',
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        );

      case TipoManobraSelecionada.atropelar:
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🏃 Atropelar (Movimento ou Padrão — R61)',
              style: TextStyle(
                color: Colors.deepOrangeAccent,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            SizedBox(height: 4),
            Text(
              '• Manobra oposta de Luta vs Luta durante o avanço.\n'
              '• Atacante vence: O alvo CAI NO CHÃO (-5 Defesa corpo a corpo) e você continua o movimento.\n'
              '• Alvo vence: Permanece de pé e interrompe o seu deslocamento.',
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        );

      case TipoManobraSelecionada.investida:
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '⚡ Investida (Ação Completa — R63)',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            SizedBox(height: 4),
            Text(
              '• Avança em linha reta (mínimo 3m, até 2x seu deslocamento) e desfere um ataque corpo a corpo.\n'
              '• Bônus: +2 no teste de ataque.\n'
              '• Penalidade: -2 na sua própria Defesa até o início do seu próximo turno.',
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        );

      case TipoManobraSelecionada.quebrar:
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🔨 Manobra Quebrar (Ação Padrão — R76)',
              style: TextStyle(
                color: Colors.tealAccent,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            SizedBox(height: 4),
            Text(
              '• Golpeia diretamente a arma ou escudo empunhado pelo oponente.\n'
              '• Ataque corpo a corpo contra a Defesa do item. O dano que superar a Redução de Dano (RD) do material é deduzido dos PV do objeto até destruí-lo.',
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        );
    }
  }

  bool _podeExecutar() {
    switch (_manobraSelecionada) {
      case TipoManobraSelecionada.fintar:
      case TipoManobraSelecionada.quebrar:
        return widget.state.acoesPadraoRestantes > 0;

      case TipoManobraSelecionada.atropelar:
        return widget.state.acoesMovimentoRestantes > 0 ||
            widget.state.acoesPadraoRestantes > 0;

      case TipoManobraSelecionada.investida:
        return widget.state.acoesPadraoRestantes > 0 &&
            widget.state.acoesMovimentoRestantes > 0;
    }
  }

  String _rotuloBotaoExecutar() {
    if (!_podeExecutar()) {
      if (_manobraSelecionada == TipoManobraSelecionada.investida) {
        return 'Requer Ação Completa (Padrão + Movimento)';
      }
      return 'Sem Ações Disponíveis';
    }

    switch (_manobraSelecionada) {
      case TipoManobraSelecionada.fintar:
        return 'Executar Fintar';
      case TipoManobraSelecionada.atropelar:
        return 'Executar Atropelar';
      case TipoManobraSelecionada.investida:
        return 'Desferir Investida (+2 Atq / -2 Def)';
      case TipoManobraSelecionada.quebrar:
        return 'Executar Quebrar ($_tipoItemQuebrar)';
    }
  }

  Color _corBotaoExecutar() {
    if (!_podeExecutar()) return Colors.grey.shade700;
    switch (_manobraSelecionada) {
      case TipoManobraSelecionada.fintar:
        return Colors.purple.shade700;
      case TipoManobraSelecionada.atropelar:
        return Colors.deepOrange.shade700;
      case TipoManobraSelecionada.investida:
        return const Color(0xFFC62828);
      case TipoManobraSelecionada.quebrar:
        return Colors.teal.shade700;
    }
  }

  void _executarManobra(BuildContext context) {
    Navigator.pop(context);

    switch (_manobraSelecionada) {
      case TipoManobraSelecionada.fintar:
        widget.cubit.executarFintar(defensor: _alvoSelecionado);
        break;

      case TipoManobraSelecionada.atropelar:
        widget.cubit.executarAtropelar(defensor: _alvoSelecionado);
        break;

      case TipoManobraSelecionada.investida:
        final arma =
            _armaSelecionada ??
            (widget.heroi.armas.isNotEmpty ? widget.heroi.armas.first : null);
        if (arma == null) {
          widget.cubit.registrarLog(
            '⚠️ ${widget.heroi.nome} não possui armas para investir!',
          );
          return;
        }
        widget.cubit.executarInvestida(defensor: _alvoSelecionado, arma: arma);
        break;

      case TipoManobraSelecionada.quebrar:
        final arma =
            _armaSelecionada ??
            (widget.heroi.armas.isNotEmpty ? widget.heroi.armas.first : null);
        if (arma == null) {
          widget.cubit.registrarLog(
            '⚠️ ${widget.heroi.nome} não possui armas para quebrar!',
          );
          return;
        }

        final bool ehArma = _tipoItemQuebrar == 'Arma';
        widget.cubit.executarManobraQuebrar(
          defensor: _alvoSelecionado,
          armaAtacante: arma,
          nomeItem: ehArma ? 'Arma' : 'Escudo',
          defesaItem: ehArma ? 12 : 14,
          pvItem: ehArma ? 10 : 15,
          rdItem: 5,
        );
        break;
    }
  }
}
