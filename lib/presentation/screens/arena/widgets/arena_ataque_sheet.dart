import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../domain/entities/combate/combatente.dart';
import '../../../../domain/entities/combate/efeito_ativo_combate.dart';
import '../../../../domain/entities/equipamento/arma.dart';
import '../../../../domain/services/combate_services/arena_stats_collector.dart';
import '../../../../domain/services/combate_services/calculadora_tatica_t20.dart';
import '../../../../domain/services/combate_services/dice_roll_service.dart';
import '../../../controllers/combate_controller/combate_cubit.dart';
import 'd20_dice.dart';
import 'roll_result_view.dart';

/// Modal bottom sheet para resolução de Ataques no Modo Arena usando o Sistema de Honestidade.
///
/// Apresenta:
/// 1. Modificadores base calculados (Luta/Pontaria da arma).
/// 2. Checkboxes de circunstância (Flanco +2, Vantagem/Desvantagem, Buffs Ativos).
/// 3. Modificador numérico livre e dados extras (+1d6).
/// 4. Animação rápida de D20 icosaedro 3D (~1.0s).
/// 5. Apresentação BG3 do resultado do teste e comparação contra Defesa.
/// 6. Rolagem de dano com multiplicador crítico T20 (apenas dados da arma multiplicam).
/// 7. Confirmação do dano aplicado e encerramento da ação.
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
    final navigator = Navigator.of(context);

    final danoFinal = _resultadoDano?.total ?? 0;
    final acaoDescricao = _acertou
        ? '⚔️ ${widget.heroi.nome} atacou ${_alvo.nome} com ${widget.arma.nome}: ACERTOU! (${_resultadoAtaque?.total ?? 0} vs Defesa ${_alvo.defesa}) causando $danoFinal de dano${_ehCritico ? " [CRÍTICO]" : ""}.'
        : '🛡️ ${widget.heroi.nome} atacou ${_alvo.nome} com ${widget.arma.nome}: ERROU (${_resultadoAtaque?.total ?? 0} vs Defesa ${_alvo.defesa}).';

    widget.stats.registrarAtaque(
      acerto: _acertou,
      ehCritico: _ehCritico,
      dano: danoFinal,
    );

    widget.cubit.aplicarDanoManual(
      alvo: _alvo,
      dano: danoFinal,
      descricaoAcao: acaoDescricao,
      consomeAcaoPadrao: true,
    );

    navigator.pop();
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
            Row(
              children: [
                const Icon(Icons.gps_fixed, size: 14, color: Colors.amberAccent),
                const SizedBox(width: 6),
                Text(
                  'Alvo:',
                  style: textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
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
            Row(
              children: [
                const Icon(Icons.tune, size: 14, color: Colors.cyanAccent),
                const SizedBox(width: 6),
                Text(
                  'Modificadores e Circunstâncias:',
                  style: textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
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
                  backgroundColor: const Color(0xFF0F172A),
                  selectedColor: const Color(0xFF78350F),
                  checkmarkColor: Colors.amberAccent,
                  side: BorderSide(
                    color: _flanco ? Colors.amberAccent : Colors.white24,
                    width: 1.2,
                  ),
                  labelStyle: TextStyle(
                    color: _flanco ? Colors.amberAccent : Colors.white,
                    fontWeight: _flanco ? FontWeight.bold : FontWeight.normal,
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
                    backgroundColor: const Color(0xFF0F172A),
                    selectedColor: const Color(0xFF581C87),
                    checkmarkColor: Colors.purpleAccent,
                    side: BorderSide(
                      color: _aplicarBuffs ? Colors.purpleAccent : Colors.white24,
                      width: 1.2,
                    ),
                    labelStyle: TextStyle(
                      color: _aplicarBuffs ? Colors.purpleAccent : Colors.white,
                      fontWeight: _aplicarBuffs ? FontWeight.bold : FontWeight.normal,
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
                  backgroundColor: const Color(0xFF0F172A),
                  selectedColor: const Color(0xFF1E3A8A),
                  side: BorderSide(
                    color: _vantagem == TipoVantagem.normal
                        ? Colors.lightBlueAccent
                        : Colors.white24,
                    width: 1.2,
                  ),
                  labelStyle: TextStyle(
                    color: _vantagem == TipoVantagem.normal
                        ? Colors.lightBlueAccent
                        : Colors.white,
                    fontWeight: _vantagem == TipoVantagem.normal
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 12,
                  ),
                  onSelected: _ataqueConcluido
                      ? null
                      : (_) => setState(() => _vantagem = TipoVantagem.normal),
                ),
                ChoiceChip(
                  label: const Text('Vantagem'),
                  selected: _vantagem == TipoVantagem.vantagem,
                  backgroundColor: const Color(0xFF0F172A),
                  selectedColor: const Color(0xFF14532D),
                  side: BorderSide(
                    color: _vantagem == TipoVantagem.vantagem
                        ? Colors.greenAccent
                        : Colors.white24,
                    width: 1.2,
                  ),
                  labelStyle: TextStyle(
                    color: _vantagem == TipoVantagem.vantagem
                        ? Colors.greenAccent
                        : Colors.white,
                    fontWeight: _vantagem == TipoVantagem.vantagem
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 12,
                  ),
                  onSelected: _ataqueConcluido
                      ? null
                      : (_) => setState(() => _vantagem = TipoVantagem.vantagem),
                ),
                ChoiceChip(
                  label: const Text('Desvantagem'),
                  selected: _vantagem == TipoVantagem.desvantagem,
                  backgroundColor: const Color(0xFF0F172A),
                  selectedColor: const Color(0xFF7F1D1D),
                  side: BorderSide(
                    color: _vantagem == TipoVantagem.desvantagem
                        ? Colors.redAccent
                        : Colors.white24,
                    width: 1.2,
                  ),
                  labelStyle: TextStyle(
                    color: _vantagem == TipoVantagem.desvantagem
                        ? Colors.redAccent
                        : Colors.white,
                    fontWeight: _vantagem == TipoVantagem.desvantagem
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 12,
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
            // Diagnóstico Tático de Apoio à Decisão (sem emojis)
            _buildPainelAnaliseTatica(),

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
                          ? (_ehCritico ? 'ACERTO CRÍTICO!' : 'ACERTOU O ATAQUE!')
                          : 'ERROU O ATAQUE',
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

            // 6. Seção pós-ataque: Dano se acertou, ou botão direto se errou
            if (_ataqueConcluido) ...[
              if (_acertou) ...[
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
                        'Aceitar Resultado e Aplicar Dano',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      onPressed: _aceitarEAplicar,
                    ),
                  ),
                ],
              ] else ...[
                // QUANDO ERRA O ALVO: Vai DIRETO para Aceitar Resultado sem rolar dano
                const Divider(color: Colors.white24, height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF334155),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text(
                      'Aceitar Resultado (Errou o Ataque)',
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

  Widget _buildPainelAnaliseTatica() {
    final int bonusAtributoDano =
        widget.arma.somaForcaAoDano ? widget.heroi.modForca : 0;
    final avaliacao = CalculadoraTaticaT20.calcularAvaliacaoAtaque(
      arma: widget.arma,
      modAtaqueTotal: _modificadorTotalAtaque,
      modDanoTotal: bonusAtributoDano + _modificadorTotalDano,
      defesaAlvo: _alvo.defesa,
      temVantagem: _vantagem == TipoVantagem.vantagem,
      temDesvantagem: _vantagem == TipoVantagem.desvantagem,
    );

    final Color corProb;
    if (avaliacao.probabilidadeAcerto >= 0.65) {
      corProb = Colors.greenAccent;
    } else if (avaliacao.probabilidadeAcerto >= 0.45) {
      corProb = Colors.amberAccent;
    } else {
      corProb = Colors.orangeAccent;
    }

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_outlined, size: 14, color: Colors.cyanAccent),
              const SizedBox(width: 6),
              const Text(
                'DIAGNÓSTICO TÁTICO',
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              Text(
                'vs Defesa ${_alvo.defesa}',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // 1. Chance de Acerto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Chance de Acerto', style: TextStyle(color: Colors.white60, fontSize: 10)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.gps_fixed, size: 13, color: corProb),
                        const SizedBox(width: 4),
                        Text(
                          avaliacao.probabilidadePercentualFormatada,
                          style: TextStyle(color: corProb, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 28, color: Colors.white12),
              const SizedBox(width: 10),
              // 2. Dano Médio
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Dano Médio', style: TextStyle(color: Colors.white60, fontSize: 10)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.flash_on, size: 13, color: Colors.orangeAccent),
                        const SizedBox(width: 4),
                        Text(
                          '${avaliacao.danoMedioFormatado} PV',
                          style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 28, color: Colors.white12),
              const SizedBox(width: 10),
              // 3. Dano Esperado
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Dano Esperado', style: TextStyle(color: Colors.white60, fontSize: 10)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.trending_up, size: 13, color: Colors.lightGreenAccent),
                        const SizedBox(width: 4),
                        Text(
                          avaliacao.danoEsperadoFormatado,
                          style: const TextStyle(color: Colors.lightGreenAccent, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Margem Crítica: ${widget.arma.margemAmeaca}-20 (x${widget.arma.multiplicadorCritico}) • ${(avaliacao.probabilidadeCritico * 100).toStringAsFixed(0)}% de chance de crítico',
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
