import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../domain/entities/combate/combatente.dart';
import '../../../../domain/entities/combate/efeito_ativo_combate.dart';
import '../../../../domain/entities/magia/magia.dart';
import '../../../../domain/services/combate_services/arena_stats_collector.dart';
import '../../../../domain/services/data_services/call_magias.dart';
import '../../../controllers/combate_controller/combate_cubit.dart';

/// Modal bottom sheet para gerenciamento e lançamento de magias no Modo Arena.
///
/// Implementa a filosofia do Foundry VTT / Sistema de Honestidade:
/// 1. Card completo da magia com metadados (Execução, Alcance métrico, Duração, CD).
/// 2. Botão "Ativar Efeito" para registrar buffs ativos com duração e bônus.
/// 3. Botão "Copiar para o Log" para registrar o efeito descritivo.
/// 4. Resolução rápida de dano/cura com suporte a meio dano (sucesso na CD).
class ArenaMagiaSheet extends StatefulWidget {
  final Combatente heroi;
  final List<Combatente> todos;
  final CombateCubit cubit;
  final ArenaStatsCollector? stats;

  const ArenaMagiaSheet({
    super.key,
    required this.heroi,
    required this.todos,
    required this.cubit,
    this.stats,
  });

  static Future<void> exibir(
    BuildContext context, {
    required Combatente heroi,
    required List<Combatente> todos,
    required CombateCubit cubit,
    ArenaStatsCollector? stats,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => ArenaMagiaSheet(
        heroi: heroi,
        todos: todos,
        cubit: cubit,
        stats: stats,
      ),
    );
  }

  @override
  State<ArenaMagiaSheet> createState() => _ArenaMagiaSheetState();
}

class _ArenaMagiaSheetState extends State<ArenaMagiaSheet> {
  Magia? _magiaSelecionada;
  Combatente? _alvo;
  final TextEditingController _valorDanoCuraController = TextEditingController();

  // Campos para Ativar Efeito
  int _bonusAtqEfeito = 0;
  int _bonusDanoEfeito = 0;
  int _duracaoRodadas = 10;

  @override
  void initState() {
    super.initState();
    final inimigos = widget.todos.where((c) => c.time == TimeCombatente.inimigo && c.pvAtual > 0).toList();
    _alvo = inimigos.isNotEmpty ? inimigos.first : widget.todos.first;
  }

  @override
  void dispose() {
    _valorDanoCuraController.dispose();
    super.dispose();
  }

  int _calcularCdMagia() {
    if (widget.heroi is CombatenteJogador) {
      final jogador = widget.heroi as CombatenteJogador;
      final modInt = jogador.ficha.getValorFinal('INT');
      final modSab = jogador.ficha.getValorFinal('SAB');
      final modCar = jogador.ficha.getValorFinal('CAR');
      final modChave = max(modInt, max(modSab, modCar));
      return 10 + (jogador.ficha.nivelPersonagem ~/ 2) + modChave;
    }
    return 12;
  }

  void _selecionarMagia(Magia magia) {
    setState(() {
      _magiaSelecionada = magia;
      // Heurística de sugestão de bônus para buffs comuns como Arma de Jade
      if (magia.nome.toLowerCase().contains('jade') || magia.nome.toLowerCase().contains('arma')) {
        _bonusAtqEfeito = 1;
        _bonusDanoEfeito = 1;
      } else if (magia.nome.toLowerCase().contains('bênção') || magia.nome.toLowerCase().contains('bencao')) {
        _bonusAtqEfeito = 1;
        _bonusDanoEfeito = 0;
      } else {
        _bonusAtqEfeito = 0;
        _bonusDanoEfeito = 0;
      }
    });
  }

  void _ativarEfeitoBuff(int custoPm) {
    final magia = _magiaSelecionada!;
    final efeito = EfeitoAtivoCombate(
      id: '${magia.id}_${DateTime.now().millisecondsSinceEpoch}',
      nome: magia.nome,
      descricaoEfeito: magia.descricao,
      bonusAtaque: _bonusAtqEfeito,
      bonusDano: _bonusDanoEfeito,
      rodadasRestantes: _duracaoRodadas,
      combatenteId: widget.heroi.id,
    );

    widget.stats?.registrarMagia(custoPm: custoPm);
    widget.cubit.adicionarEfeitoAtivo(efeito, custoPm: custoPm);
    Navigator.pop(context);
  }

  void _copiarParaOLog(int custoPm) {
    final magia = _magiaSelecionada!;
    final log = '📜 [Grimório] ${widget.heroi.nome} consultou/ativou ${magia.nome} (Círculo ${magia.circulo} • ${magia.escola} • Custo $custoPm PM): ${magia.descricao}';
    widget.cubit.aplicarAjusteVtt(
      combatenteId: widget.heroi.id,
      valor: 0,
      motivo: log,
    );
  }

  void _lancarMagiaDanoOuCura(int custoPm, bool ehCura, {bool ehMetade = false}) {
    final magia = _magiaSelecionada!;
    final valor = int.tryParse(_valorDanoCuraController.text) ?? 0;
    final danoFinal = ehCura ? 0 : (ehMetade ? (valor / 2).floor() : valor);

    widget.stats?.registrarMagia(custoPm: custoPm, dano: danoFinal);
    Navigator.pop(context);
    widget.cubit.lancarMagia(
      magia: magia,
      alvo: _alvo,
      valorDanoOuCura: ehMetade ? (valor / 2).floor() : valor,
      ehCura: ehCura,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final magiasIds = widget.heroi is CombatenteJogador
        ? (widget.heroi as CombatenteJogador).ficha.magiasConhecidas
        : <String>[];

    if (magiasIds.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_stories, size: 48, color: Colors.white38),
            const SizedBox(height: 12),
            Text(
              'Este personagem não conhece nenhuma magia.',
              style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final magias = magiasIds.map((id) => BancoDeMagias.getById(id)).toList();

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
            // Topo: Cabeçalho com PM e CD
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.indigoAccent, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Grimório de Magias (PM: ${widget.heroi.pmAtual}/${widget.heroi.pmMax})',
                    style: textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
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

            // Se nenhuma magia selecionada: exibe a lista
            if (_magiaSelecionada == null) ...[
              Text(
                'Selecione uma magia para usar ou consultar:',
                style: textTheme.bodySmall?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 10),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: magias.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (ctx, idx) {
                  final magia = magias[idx];
                  final custo = widget.cubit.calcularCustoPmMagia(magia);
                  final temPm = widget.heroi.pmAtual >= custo;

                  return ListTile(
                    tileColor: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    leading: CircleAvatar(
                      backgroundColor: temPm ? Colors.indigo : Colors.grey.shade800,
                      child: Text(
                        '${magia.circulo}º',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      magia.nome,
                      style: TextStyle(
                        color: temPm ? Colors.white : Colors.white38,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'Custo: $custo PM • ${magia.escola} • Alcance: ${magia.alcance.tipo}',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: Colors.white38),
                    onTap: () => _selecionarMagia(magia),
                  );
                },
              ),
            ] else ...[
              // Card da Magia Selecionada
              _buildCardMagiaDetalhado(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCardMagiaDetalhado(BuildContext context) {
    final magia = _magiaSelecionada!;
    final custo = widget.cubit.calcularCustoPmMagia(magia);
    final temPm = widget.heroi.pmAtual >= custo;
    final alcanceMetros = widget.cubit.calcularAlcanceMetrosMagia(magia.alcance);
    final cdMagia = _calcularCdMagia();
    final ehCura = magia.escola.toLowerCase().contains('cura') ||
        magia.nome.toLowerCase().contains('curar');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Botão Voltar para a Lista
        TextButton.icon(
          icon: const Icon(Icons.arrow_back, size: 16, color: Colors.indigoAccent),
          label: const Text('Voltar para a Lista de Magias', style: TextStyle(color: Colors.indigoAccent)),
          onPressed: () => setState(() => _magiaSelecionada = null),
        ),
        const SizedBox(height: 6),

        // Cabeçalho da Magia
        Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.indigo,
              child: Text(
                '${magia.circulo}º',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    magia.nome,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${magia.escola} • Custo: $custo PM (CD $cdMagia)',
                    style: const TextStyle(
                      color: Colors.amberAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Badges de Metadados
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _buildBadge('Execução', magia.execucao.tipo),
            _buildBadge('Alcance', '${magia.alcance.tipo} (${alcanceMetros.toStringAsFixed(1)}m)'),
            _buildBadge('Duração', magia.duracao.tipo),
            _buildBadge(
              'Resistência',
              magia.resistencia?.tipoTeste != null
                  ? '${magia.resistencia!.tipoTeste} (${magia.resistencia!.resultadoSucesso})'
                  : 'Nenhuma',
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Descrição da Magia
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          constraints: const BoxConstraints(maxHeight: 140),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white12),
          ),
          child: SingleChildScrollView(
            child: Text(
              magia.descricao,
              style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Seletor de Alvo (se não for pessoal)
        if (magia.alcance.tipo.toLowerCase() != 'pessoal') ...[
          const Text(
            '🎯 Alvo:',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 4),
          DropdownButton<Combatente>(
            isExpanded: true,
            dropdownColor: const Color(0xFF0F172A),
            value: _alvo,
            items: widget.todos.map((c) {
              return DropdownMenuItem(
                value: c,
                child: Text(
                  '${c.nome} (${c.pvAtual}/${c.pvMax} PV)',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              );
            }).toList(),
            onChanged: (novo) {
              if (novo != null) setState(() => _alvo = novo);
            },
          ),
          const SizedBox(height: 12),
        ],

        // -------------------------------------------------------------
        // PILARES FOUNDRY VTT: Ativar Efeito vs Lançar Magia vs Copiar
        // -------------------------------------------------------------
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_fix_high, size: 16, color: Colors.purpleAccent),
                  SizedBox(width: 6),
                  Text(
                    'Opção 1: Ativar como Efeito / Buff Ativo',
                    style: TextStyle(
                      color: Colors.purpleAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Bônus Atq: ', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      IconButton(
                        icon: const Icon(Icons.remove, size: 16, color: Colors.white70),
                        onPressed: () => setState(() => _bonusAtqEfeito--),
                      ),
                      Text('+$_bonusAtqEfeito', style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add, size: 16, color: Colors.white70),
                        onPressed: () => setState(() => _bonusAtqEfeito++),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Bônus Dano: ', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      IconButton(
                        icon: const Icon(Icons.remove, size: 16, color: Colors.white70),
                        onPressed: () => setState(() => _bonusDanoEfeito--),
                      ),
                      Text('+$_bonusDanoEfeito', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add, size: 16, color: Colors.white70),
                        onPressed: () => setState(() => _bonusDanoEfeito++),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Duração: ', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      IconButton(
                        icon: const Icon(Icons.remove, size: 16, color: Colors.white70),
                        onPressed: _duracaoRodadas > 1 ? () => setState(() => _duracaoRodadas--) : null,
                      ),
                      Text('$_duracaoRodadas r', style: const TextStyle(color: Colors.lightBlueAccent, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add, size: 16, color: Colors.white70),
                        onPressed: () => setState(() => _duracaoRodadas++),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: temPm ? Colors.purple.shade700 : Colors.grey.shade800,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(
                    temPm ? '✨ Ativar Efeito ($custo PM)' : 'PM Insuficiente ($custo PM)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: temPm ? () => _ativarEfeitoBuff(custo) : null,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Opção 2: Dano ou Cura
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ehCura ? '💚 Opção 2: Aplicar Cura' : '💥 Opção 2: Aplicar Dano',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _valorDanoCuraController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: ehCura ? 'Valor da Cura' : 'Valor do Dano Rolado',
                  hintText: 'Ex: 12',
                  hintStyle: const TextStyle(color: Colors.white38),
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: temPm ? Colors.indigo : Colors.grey.shade800,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: temPm ? () => _lancarMagiaDanoOuCura(custo, ehCura) : null,
                        child: Text(
                          ehCura ? 'Curar ($custo PM)' : 'Dano Total ($custo PM)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                  if (!ehCura && _alvo != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orangeAccent,
                            side: const BorderSide(color: Colors.orangeAccent),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: temPm
                              ? () => _lancarMagiaDanoOuCura(custo, ehCura, ehMetade: true)
                              : null,
                          child: const Text(
                            'Metade (Passou CD)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Opção 3: Copiar para o Log
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: const BorderSide(color: Colors.white24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.content_copy, size: 16),
            label: const Text('📋 Copiar Descrição para o Log'),
            onPressed: () => _copiarParaOLog(custo),
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(String label, String valor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(color: Colors.white54, fontSize: 10)),
          Text(
            valor,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
