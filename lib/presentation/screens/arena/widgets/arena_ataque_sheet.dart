import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../domain/entities/combate/combatente.dart';
import '../../../../domain/entities/combate/efeito_ativo_combate.dart';
import '../../../../domain/entities/equipamento/arma.dart';
import '../../../../domain/services/combate_services/arena_stats_collector.dart';
import '../../../../domain/services/combate_services/dice_roll_service.dart';
import '../../../controllers/combate_controller/combate_cubit.dart';
import '../../../widgets/d20_dice.dart';
import '../../../widgets/roll_result_view.dart';

/// Modal bottom sheet para resolução de Ataques no Modo Arena usando o Sistema de Honestidade.
///
/// Apresenta:
/// 1. Modificadores base calculados (Luta/Pontaria da arma).
/// 2. Checkboxes de circunstância (Flanco +2, Vantagem/Desvantagem, Buffs Ativos).
/// 3. Modificador numérico livre e dados extras (+1d6).
/// 4. Animação rápida de D20 icosaedro 3D (~1.0s).
/// 5. Apresentação BG3 do resultado do teste e comparação contra Defesa.
/// 6. Rolagem de dano com multiplicador crítico T20 (apenas dados da arma multiplicam).
/// 7. Confirmação com ação de desfazer dano.
class ArenaAtaqueSheet extends StatefulWidget {
  final Combatente heroi;
  final Arma arma;
  final List<Combatente> inimigos;
  final List<EfeitoAtivoCombate> efeitosAtivos;
  final CombateCubit cubit;
  final ArenaStatsCollector stats;

  const ArenaAtaqueSheet({
    super.key,
    required this.heroi,
    required this.arma,
    required this.inimigos,
    required this.efeitosAtivos,
    required this.cubit,
    required this.stats,
  });

  static Future<void> exibir(
    BuildContext context, {
    required Combatente heroi,
    required Arma arma,
    required List<Combatente> inimigos,
    required List<EfeitoAtivoCombate> efeitosAtivos,
    required CombateCubit cubit,
    required ArenaStatsCollector stats,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => ArenaAtaqueSheet(
        heroi: heroi,
        arma: arma,
        inimigos: inimigos,
        efeitosAtivos: efeitosAtivos,
        cubit: cubit,
        stats: stats,
      ),
    );
  }

  @override
  State<ArenaAtaqueSheet> createState() => _ArenaAtaqueSheetState();
}

class _ArenaAtaqueSheetState extends State<ArenaAtaqueSheet> {
  final DiceRollService _diceService = DiceRollService();

  late Combatente _alvo;
  bool _flanco = false;
  TipoVantagem _vantagem = TipoVantagem.normal;
  bool _aplicarBuffs = true;
  int _bonusManualAtaque = 0;
  int _bonusManualDano = 0;
  String? _dadoExtra;

  // Estado da Rolagem de Ataque
  bool _rolandoAtaque = false;
  ResultadoD20? _resultadoAtaque;
  bool _ataqueConcluido = false;
  bool _acertou = false;
  bool _ehCritico = false;

  // Estado da Rolagem de Dano
  ResultadoDano? _resultadoDano;

  @override
  void initState() {
    super.initState();
    final vivos = widget.inimigos.where((c) => c.pvAtual > 0).toList();
    _alvo = vivos.isNotEmpty ? vivos.first : widget.inimigos.first;
  }

  int get _bonusBuffsAtaque {
    if (!_aplicarBuffs) return 0;
    return widget.efeitosAtivos
        .where((e) => e.combatenteId == widget.heroi.id)
        .fold<int>(0, (soma, e) => soma + e.bonusAtaque);
  }

  int get _bonusBuffsDano {
    if (!_aplicarBuffs) return 0;
    return widget.efeitosAtivos
        .where((e) => e.combatenteId == widget.heroi.id)
        .fold<int>(0, (soma, e) => soma + e.bonusDano);
  }

  int get _modBaseAtaque => widget.arma.ehCorpoACorpo
      ? widget.heroi.modLuta
      : widget.heroi.modPontaria;

  int get _modificadorTotalAtaque =>
      _modBaseAtaque +
      (_flanco ? 2 : 0) +
      _bonusBuffsAtaque +
      _bonusManualAtaque;

  int get _modificadorTotalDano => _bonusBuffsDano + _bonusManualDano;

  void _executarRolagemAtaque() {
    HapticFeedback.mediumImpact();
    setState(() {
      _rolandoAtaque = true;
      _ataqueConcluido = false;
      _resultadoAtaque = _diceService.rolarD20(
        modificador: _modificadorTotalAtaque,
        nomeModificador: 'Modificadores',
        vantagem: _vantagem,
      );
    });
  }

  void _aoConcluirAnimacaoD20() {
    if (!mounted || _resultadoAtaque == null) return;

    final d20 = _resultadoAtaque!.d20;
    final total = _resultadoAtaque!.total;
    final margemAmeaca = widget.arma.margemAmeaca;

    final ehVinteNat = _resultadoAtaque!.ehVinteNatural;
    final ehUmNat = _resultadoAtaque!.ehUmNatural;
    final ehCritico = ehVinteNat || (d20 >= margemAmeaca && total >= _alvo.defesa);
    final acertou = !ehUmNat && (ehVinteNat || total >= _alvo.defesa);

    setState(() {
      _rolandoAtaque = false;
      _ataqueConcluido = true;
      _acertou = acertou;
      _ehCritico = ehCritico;
    });

    if (ehCritico) {
      HapticFeedback.heavyImpact();
    } else if (acertou) {
      HapticFeedback.lightImpact();
    }
  }

  void _executarRolagemDano() {
    HapticFeedback.mediumImpact();
    final res = _diceService.rolarDano(
      expressaoDano: widget.arma.dano,
      bonusExtra: _modificadorTotalDano,
      dadoExtra: _dadoExtra,
      ehCritico: _ehCritico,
      multiplicadorCritico: widget.arma.multiplicadorCritico,
    );

    setState(() {
      _resultadoDano = res;
    });
  }

  void _aceitarEAplicar() {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final danoFinal = _resultadoDano?.total ?? 0;
    final acaoDescricao = _acertou
        ? '⚔️ ${widget.heroi.nome} atacou ${_alvo.nome} com ${widget.arma.nome}: ACERTOU! (${_resultadoAtaque?.total ?? 0} vs Defesa ${_alvo.defesa}) causando $danoFinal de dano${_ehCritico ? " [CRÍTICO]" : ""}.'
        : '🛡️ ${widget.heroi.nome} atacou ${_alvo.nome} com ${widget.arma.nome}: ERROU (${_resultadoAtaque?.total ?? 0} vs Defesa ${_alvo.defesa}).';

    widget.cubit.aplicarDanoManual(
      alvo: _alvo,
      dano: danoFinal,
      descricaoAcao: acaoDescricao,
      consomeAcaoPadrao: true,
    );

    navigator.pop();

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(
          _acertou
              ? 'Dano de $danoFinal aplicado a ${_alvo.nome}!'
              : 'Ataque contra ${_alvo.nome} errou.',
        ),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Desfazer Dano',
          textColor: Colors.amberAccent,
          onPressed: () {
            widget.cubit.desfazerUltimoDano();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final vivos = widget.inimigos.where((c) => c.pvAtual > 0).toList();

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Cabeçalho da Arma
            Row(
              children: [
                Icon(
                  widget.arma.ehCorpoACorpo ? Icons.sports_kabaddi : Icons.gps_fixed,
                  color: Colors.amberAccent,
                  size: 26,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.arma.nome,
                        style: textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Dano: ${widget.arma.dano} (${widget.arma.criticoFormatado}) • Base: 1d20+$_modBaseAtaque',
                        style: textTheme.bodySmall?.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  tooltip: 'Fechar',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 16),

            // 2. Seletor de Alvo
            Text(
              '🎯 Alvo:',
              style: textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            DropdownButton<Combatente>(
              isExpanded: true,
              dropdownColor: const Color(0xFF0F172A),
              value: _alvo,
              items: vivos.map((c) {
                return DropdownMenuItem(
                  value: c,
                  child: Text(
                    '${c.nome} (Defesa ${c.defesa} • ${c.pvAtual}/${c.pvMax} PV)',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                );
              }).toList(),
              onChanged: _ataqueConcluido
                  ? null
                  : (novo) {
                      if (novo != null) setState(() => _alvo = novo);
                    },
            ),
            const SizedBox(height: 12),

            // 3. Modificadores Circunstanciais (Sistema de Honestidade)
            Text(
              '⚙️ Modificadores e Circunstâncias:',
              style: textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Flanco (+2)
                FilterChip(
                  label: const Text('Flanco (+2)'),
                  selected: _flanco,
                  selectedColor: Colors.amberAccent.withValues(alpha: 0.3),
                  checkmarkColor: Colors.amberAccent,
                  labelStyle: TextStyle(
                    color: _flanco ? Colors.amberAccent : Colors.white70,
                    fontSize: 12,
                  ),
                  onSelected: _ataqueConcluido
                      ? null
                      : (val) => setState(() => _flanco = val),
                ),

                // Buffs Ativos
                if (widget.efeitosAtivos.isNotEmpty)
                  FilterChip(
                    label: Text('Buffs (+$_bonusBuffsAtaque Atq / +$_bonusBuffsDano Dano)'),
                    selected: _aplicarBuffs,
                    selectedColor: Colors.purpleAccent.withValues(alpha: 0.3),
                    checkmarkColor: Colors.purpleAccent,
                    labelStyle: TextStyle(
                      color: _aplicarBuffs ? Colors.purpleAccent : Colors.white70,
                      fontSize: 12,
                    ),
                    onSelected: _ataqueConcluido
                        ? null
                        : (val) => setState(() => _aplicarBuffs = val),
                  ),

                // Vantagem / Desvantagem
                ChoiceChip(
                  label: const Text('Normal'),
                  selected: _vantagem == TipoVantagem.normal,
                  onSelected: _ataqueConcluido
                      ? null
                      : (_) => setState(() => _vantagem = TipoVantagem.normal),
                ),
                ChoiceChip(
                  label: const Text('Vantagem'),
                  selected: _vantagem == TipoVantagem.vantagem,
                  selectedColor: Colors.greenAccent.withValues(alpha: 0.3),
                  labelStyle: TextStyle(
                    color: _vantagem == TipoVantagem.vantagem
                        ? Colors.greenAccent
                        : Colors.white70,
                  ),
                  onSelected: _ataqueConcluido
                      ? null
                      : (_) => setState(() => _vantagem = TipoVantagem.vantagem),
                ),
                ChoiceChip(
                  label: const Text('Desvantagem'),
                  selected: _vantagem == TipoVantagem.desvantagem,
                  selectedColor: Colors.redAccent.withValues(alpha: 0.3),
                  labelStyle: TextStyle(
                    color: _vantagem == TipoVantagem.desvantagem
                        ? Colors.redAccent
                        : Colors.white70,
                  ),
                  onSelected: _ataqueConcluido
                      ? null
                      : (_) => setState(() => _vantagem = TipoVantagem.desvantagem),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Modificador Numérico Livre e Dados Extras
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Text(
                        'Extra Atq: ',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 18, color: Colors.white70),
                        tooltip: 'Diminuir ataque',
                        onPressed: _ataqueConcluido ? null : () => setState(() => _bonusManualAtaque--),
                      ),
                      Text(
                        '${_bonusManualAtaque >= 0 ? "+" : ""}$_bonusManualAtaque',
                        style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 18, color: Colors.white70),
                        tooltip: 'Aumentar ataque',
                        onPressed: _ataqueConcluido ? null : () => setState(() => _bonusManualAtaque++),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      const Text(
                        'Extra Dano: ',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 18, color: Colors.white70),
                        tooltip: 'Diminuir dano',
                        onPressed: _ataqueConcluido ? null : () => setState(() => _bonusManualDano--),
                      ),
                      Text(
                        '${_bonusManualDano >= 0 ? "+" : ""}$_bonusManualDano',
                        style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 18, color: Colors.white70),
                        tooltip: 'Aumentar dano',
                        onPressed: _ataqueConcluido ? null : () => setState(() => _bonusManualDano++),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 4. Área de Rolagem do D20
            Center(
              child: Column(
                children: [
                  Semantics(
                    label: 'Dado D20 de ataque',
                    child: D20Dice(
                      valorFinal: _resultadoAtaque?.d20,
                      rolando: _rolandoAtaque,
                      size: 110,
                      duracao: const Duration(milliseconds: 1000),
                      onRolagemConcluida: _aoConcluirAnimacaoD20,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (_resultadoAtaque != null && _ataqueConcluido) ...[
                    RollResultView(
                      resultado: _resultadoAtaque!,
                      titulo: _acertou
                          ? (_ehCritico ? '⭐ ACERTO CRÍTICO! ⭐' : '⚔️ ACERTOU! ⚔️')
                          : '🛡️ ERROU! 🛡️',
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _acertou
                            ? Colors.green.shade900.withValues(alpha: 0.5)
                            : Colors.red.shade900.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _acertou ? Colors.greenAccent : Colors.redAccent,
                        ),
                      ),
                      child: Text(
                        'Ataque: ${_resultadoAtaque!.total} vs Defesa: ${_alvo.defesa}',
                        style: TextStyle(
                          color: _acertou ? Colors.greenAccent : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 5. Botão de Rolar Ataque
            if (!_ataqueConcluido)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC62828),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.casino),
                  label: Text(
                    _rolandoAtaque
                        ? 'Rolando...'
                        : '⚔️ Rolar Ataque (1d20${_modificadorTotalAtaque >= 0 ? "+" : ""}$_modificadorTotalAtaque)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  onPressed: _rolandoAtaque ? null : _executarRolagemAtaque,
                ),
              ),

            // 6. Seção de Dano após o ataque
            if (_ataqueConcluido) ...[
              const Divider(color: Colors.white24, height: 20),
              Text(
                '💥 Rolagem de Dano (${widget.arma.dano}${_ehCritico ? " [CRÍTICO x${widget.arma.multiplicadorCritico}]" : ""}):',
                style: textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              if (_resultadoDano == null)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade800,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.flash_on),
                    label: Text(
                      _ehCritico ? '⚡ Rolar Dano Crítico!' : 'Rolar Dano',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: _executarRolagemDano,
                  ),
                )
              else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orangeAccent),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Total de Dano: ${_resultadoDano!.total}',
                        style: const TextStyle(
                          color: Colors.orangeAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _resultadoDano!.decomposicao,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text(
                      'Aceitar Resultado e Aplicar',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    onPressed: _aceitarEAplicar,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
