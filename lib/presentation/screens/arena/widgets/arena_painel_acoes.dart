import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../domain/entities/combate/combatente.dart';
import '../../../../domain/entities/equipamento/arma.dart';
import '../../../../domain/entities/magia/magia.dart';
import '../../../../domain/services/combate_services/arena_stats_collector.dart';
import '../../../../domain/services/data_services/call_magias.dart';
import '../../../controllers/combate_controller/combate_cubit.dart';
import '../../../controllers/combate_controller/combate_state.dart';
import 'arena_arbitragem_dialog.dart';

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
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              // Botão Atacar (Pilar 1: Modificadores Circunstanciais)
              ElevatedButton.icon(
                icon: const Icon(Icons.sports_kabaddi, size: 16),
                label: const Text('Atacar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC62828),
                  foregroundColor: Colors.white,
                ),
                onPressed: state.acoesPadraoRestantes > 0
                    ? () => _abrirModalAtaque(context, atual, inimigos)
                    : null,
              ),

              // Botão Lançar Magia (Pilar 2: Chat Card de Magias)
              ElevatedButton.icon(
                icon: const Icon(Icons.auto_awesome, size: 16),
                label: const Text('Lançar Magia'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
                onPressed: state.acoesPadraoRestantes > 0 && atual.pmAtual > 0
                    ? () => _abrirModalMagias(
                        context,
                        atual,
                        state.filaIniciativa,
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

              // Botão Arbitragem VTT na Mesa (Pilar 3)
              OutlinedButton.icon(
                icon: const Icon(Icons.tune, size: 16, color: Colors.amberAccent),
                label: const Text(
                  'Ajuste Mesa',
                  style: TextStyle(color: Colors.amberAccent),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.amberAccent),
                ),
                onPressed: () => exibirModalArbitragemVtt(context, atual, cubit),
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

  // ==========================================
  // PILAR 1: ATAQUE COM MODIFICADORES CIRCUNSTANCIAIS
  // ==========================================
  void _abrirModalAtaque(
    BuildContext context,
    Combatente heroi,
    List<Combatente> inimigos,
  ) {
    if (heroi.armas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este combatente não possui armas equipadas!'),
        ),
      );
      return;
    }

    if (heroi.armas.length == 1) {
      _abrirSheetConfigurarAtaque(context, heroi, heroi.armas.first, inimigos);
      return;
    }

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
              const Text(
                'Escolha a Arma para o Ataque:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              ...heroi.armas.map(
                (arma) => ListTile(
                  tileColor: const Color(0xFF0F172A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
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
                  subtitle: Text(
                    'Dano: ${arma.dano} (${arma.criticoFormatado})',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _abrirSheetConfigurarAtaque(context, heroi, arma, inimigos);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _abrirSheetConfigurarAtaque(
    BuildContext context,
    Combatente heroi,
    Arma arma,
    List<Combatente> inimigos,
  ) {
    final vivos = inimigos.where((c) => c.pvAtual > 0).toList();
    if (vivos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não há inimigos vivos para atacar!')),
      );
      return;
    }

    Combatente alvo = vivos.first;
    int bonusAtaque = 0;
    int bonusDano = 0;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final modBase = arma.ehCorpoACorpo ? heroi.modLuta : heroi.modPontaria;

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
                // Cabeçalho da Arma
                Row(
                  children: [
                    Icon(
                      arma.ehCorpoACorpo ? Icons.sports_kabaddi : Icons.gps_fixed,
                      color: Colors.amberAccent,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            arma.nome,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Dano Base: ${arma.dano} (${arma.criticoFormatado}) • Teste: 1d20+${modBase + bonusAtaque}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
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

                // Seletor de Alvo
                const Text(
                  '🎯 Escolha o Alvo:',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButton<Combatente>(
                  isExpanded: true,
                  dropdownColor: const Color(0xFF0F172A),
                  value: alvo,
                  items: vivos
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(
                            '${c.nome} (Defesa ${c.defesa} • ${c.pvAtual}/${c.pvMax} PV)',
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (novo) {
                    if (novo != null) setModalState(() => alvo = novo);
                  },
                ),
                const SizedBox(height: 12),

                // Pilar 1: Modificador de Ataque
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Modificador no Ataque:',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      bonusAtaque >= 0 ? '+$bonusAtaque' : '$bonusAtaque',
                      style: TextStyle(
                        color: bonusAtaque > 0
                            ? Colors.greenAccent
                            : (bonusAtaque < 0 ? Colors.redAccent : Colors.white),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildModChip(
                        '-5',
                        bonusAtaque == -5,
                        () => setModalState(() => bonusAtaque = -5),
                      ),
                      _buildModChip(
                        '-2',
                        bonusAtaque == -2,
                        () => setModalState(() => bonusAtaque = -2),
                      ),
                      _buildModChip(
                        '+0',
                        bonusAtaque == 0,
                        () => setModalState(() => bonusAtaque = 0),
                      ),
                      _buildModChip(
                        '+1 (Jade)',
                        bonusAtaque == 1,
                        () => setModalState(() => bonusAtaque = 1),
                      ),
                      _buildModChip(
                        '+2 (Flanco)',
                        bonusAtaque == 2,
                        () => setModalState(() => bonusAtaque = 2),
                      ),
                      _buildModChip(
                        '+5',
                        bonusAtaque == 5,
                        () => setModalState(() => bonusAtaque = 5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Pilar 1: Modificador de Dano
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Modificador no Dano:',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      bonusDano >= 0 ? '+$bonusDano' : '$bonusDano',
                      style: TextStyle(
                        color: bonusDano > 0
                            ? Colors.greenAccent
                            : (bonusDano < 0 ? Colors.redAccent : Colors.white),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildModChip(
                        '+0',
                        bonusDano == 0,
                        () => setModalState(() => bonusDano = 0),
                      ),
                      _buildModChip(
                        '+1 (Jade)',
                        bonusDano == 1,
                        () => setModalState(() => bonusDano = 1),
                      ),
                      _buildModChip(
                        '+2',
                        bonusDano == 2,
                        () => setModalState(() => bonusDano = 2),
                      ),
                      _buildModChip(
                        '+5',
                        bonusDano == 5,
                        () => setModalState(() => bonusDano = 5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Botão de Ataque
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC62828),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.sports_kabaddi),
                    label: Text(
                      '⚔️ Rolar Ataque vs Defesa ${alvo.defesa}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      cubit.executarAtaque(
                        defensor: alvo,
                        arma: arma,
                        bonusAtaqueExtra: bonusAtaque,
                        bonusDanoExtra: bonusDano,
                      );
                      if (cubit.state.ultimoResultadoAtaque != null) {
                        stats.registrarAtaqueHeroi(cubit.state.ultimoResultadoAtaque!);
                      }
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // PILAR 2: CARD DE AÇÃO / CHAT CARD PARA MAGIAS
  // ==========================================
  void _abrirModalMagias(
    BuildContext context,
    Combatente heroi,
    List<Combatente> todos,
  ) {
    final magiasIds = heroi is CombatenteJogador
        ? heroi.ficha.magiasConhecidas
        : <String>[];
    if (magiasIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este personagem não conhece magias!')),
      );
      return;
    }

    final magias = magiasIds.map((id) => BancoDeMagias.getById(id)).toList();

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
              Text(
                'Grimório de Magias (PM: ${heroi.pmAtual}/${heroi.pmMax})',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: magias.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final magia = magias[index];
                    final custo = cubit.calcularCustoPmMagia(magia);
                    final temPm = heroi.pmAtual >= custo;

                    return ListTile(
                      tileColor: const Color(0xFF0F172A),
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue[900],
                        child: Text(
                          '${magia.circulo}º',
                          style: const TextStyle(color: Colors.white),
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
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.white38,
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        _exibirCardMagia(context, heroi, magia, todos);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _exibirCardMagia(
    BuildContext context,
    Combatente heroi,
    Magia magia,
    List<Combatente> todos,
  ) {
    final custo = cubit.calcularCustoPmMagia(magia);
    final alcanceMetros = cubit.calcularAlcanceMetrosMagia(magia.alcance);
    final temPm = heroi.pmAtual >= custo;

    // Cálculo da CD de Magia em Tormenta 20: 10 + metade do nível + atributo-chave
    int cdMagia = 12;
    if (heroi is CombatenteJogador) {
      final modInt = heroi.ficha.getValorFinal('INT');
      final modSab = heroi.ficha.getValorFinal('SAB');
      final modCar = heroi.ficha.getValorFinal('CAR');
      final modChave = max(modInt, max(modSab, modCar));
      cdMagia = 10 + (heroi.ficha.nivelPersonagem ~/ 2) + modChave;
    }

    final rolagemController = TextEditingController();
    Combatente? alvo = todos.firstWhere(
      (c) => c.time == TimeCombatente.inimigo && c.pvAtual > 0,
      orElse: () => todos.first,
    );
    bool ehCura = magia.escola.toLowerCase().contains('cura') ||
        magia.nome.toLowerCase().contains('curar');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabeçalho do Card
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.indigo,
                        child: Text(
                          '${magia.circulo}º',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
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
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 16),

                  // Metadados da Magia (Execução, Alcance, Duração, Resistência)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildInfoBadge('Execução', magia.execucao.tipo),
                      _buildInfoBadge(
                        'Alcance',
                        '${magia.alcance.tipo} (${alcanceMetros.toStringAsFixed(1)}m)',
                      ),
                      _buildInfoBadge('Duração', magia.duracao.tipo),
                      _buildInfoBadge(
                        'Resistência',
                        magia.resistencia?.tipoTeste != null
                            ? '${magia.resistencia!.tipoTeste} (${magia.resistencia!.resultadoSucesso})'
                            : 'Nenhuma',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Descrição Completa da Magia (Card T20)
                  Container(
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
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Seletor de Alvo (se não for alcance pessoal)
                  if (magia.alcance.tipo.toLowerCase() != 'pessoal') ...[
                    const Text(
                      '🎯 Alvo da Magia:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    DropdownButton<Combatente>(
                      isExpanded: true,
                      dropdownColor: const Color(0xFF0F172A),
                      value: alvo,
                      items: todos
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(
                                '${c.nome} (${c.pvAtual}/${c.pvMax} PV)',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (novo) {
                        if (novo != null) setModalState(() => alvo = novo);
                      },
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Campo de Rolagem de Dados de Dano / Cura (Pilar 3: Arbitragem rápida)
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: rolagemController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: ehCura
                                ? 'Cura Rolada nos Dados'
                                : 'Dano Rolado nos Dados',
                            hintText: 'Ex: 14 (opcional)',
                            hintStyle: const TextStyle(color: Colors.white38),
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
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Botão Principal: Lançar Magia (Gasta PM e Ação)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: temPm ? Colors.indigo : Colors.grey[800],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.auto_awesome),
                      label: Text(
                        temPm
                            ? '✨ Lançar ${magia.nome} (Gastar $custo PM)'
                            : 'PM Insuficiente ($custo PM)',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: temPm
                          ? () {
                              final v = int.tryParse(rolagemController.text);
                              Navigator.pop(ctx);
                              cubit.lancarMagia(
                                magia: magia,
                                alvo: alvo,
                                valorDanoOuCura: v,
                                ehCura: ehCura,
                              );
                            }
                          : null,
                    ),
                  ),

                  // Botões Rápidos de Resolução se houver valor de dano digitado
                  if (alvo != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orangeAccent,
                              side: const BorderSide(color: Colors.orangeAccent),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: const Text(
                              '🛡️ Metade (Passou CD)',
                              style: TextStyle(fontSize: 11),
                            ),
                            onPressed: () {
                              final v = int.tryParse(rolagemController.text) ?? 0;
                              if (v > 0) {
                                Navigator.pop(ctx);
                                cubit.lancarMagia(
                                  magia: magia,
                                  alvo: null,
                                  valorDanoOuCura: null,
                                );
                                cubit.aplicarAjusteVtt(
                                  combatenteId: alvo!.id,
                                  valor: v,
                                  motivo: '${magia.nome} (resistiu na CD $cdMagia)',
                                  ehMetade: true,
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Digite o valor rolado no dano!'),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModChip(String label, bool selecionado, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        selected: selecionado,
        label: Text(label, style: const TextStyle(fontSize: 11)),
        selectedColor: Colors.amberAccent,
        backgroundColor: const Color(0xFF0F172A),
        labelStyle: TextStyle(
          color: selecionado ? Colors.black : Colors.white,
          fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (_) => onTap(),
      ),
    );
  }

  Widget _buildInfoBadge(String label, String valor) {
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
      ),
    );
  }
}
