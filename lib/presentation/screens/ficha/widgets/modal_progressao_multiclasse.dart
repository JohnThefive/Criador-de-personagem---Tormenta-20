import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/entities/personagem/classe.dart';
import '../../../../domain/entities/personagem/personagem.dart';
import '../../../../domain/services/data_services/call_classes.dart';
import '../../../controllers/ficha_controller/ficha_cubit.dart';
import '../../../controllers/ficha_controller/ficha_state.dart';
import '../../wizard_personagem/selecao_poderes_screen.dart';

/// Exibe diálogo informativo sobre a importância e permanência do nível em Tormenta 20.
void mostrarInfoNivel(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('A Importância do Nível'),
      content: const Text(
        'O nível em Tormenta 20 é definitivo e permanente:\n\n'
        '• Aumenta Pontos de Vida (PV) e Mana (PM);\n'
        '• Metade do nível é somada em todas as perícias;\n'
        '• Desbloqueia poderes de classe, gerais e novos círculos de magia;\n'
        '• Avança o patamar do herói (Iniciante, Veterano, Campeão e Lenda).',
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD32F2F),
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Entendido'),
        ),
      ],
    ),
  );
}

/// Valida se o personagem pode evoluir (respeitando Modo Tabletop e XP) e solicita confirmação.
void verificarEExecutarEvolucao({
  required BuildContext context,
  required Personagem personagem,
  required String nomeClasse,
  required int novoNivelIndividual,
  required int novoNivelTotal,
  required VoidCallback onExecutar,
}) {
  if (personagem.modoTabletopAtivo && !personagem.podeSubirDeNivel) {
    final progresso = personagem.progressoXP;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Evolução Bloqueada (Tabletop)'),
        content: Text(
          'No Modo Tabletop, a subida para o Nível $novoNivelTotal exige permissão do mestre ou ${progresso.xpRestanteParaUpar} XP restantes.\n\n'
          'XP Atual: ${personagem.experienciaAtual} / ${progresso.xpNecessarioProximoNivel} XP.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
    return;
  }

  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Confirmar Evolução'),
      content: Text(
        'Subir para o Nível $novoNivelIndividual em $nomeClasse (Nível Total $novoNivelTotal)?\n\n'
        'A evolução em Tormenta 20 é permanente.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('CANCELAR'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD32F2F),
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(ctx);
            onExecutar();
          },
          child: const Text('CONFIRMAR'),
        ),
      ],
    ),
  );
}

/// Abre o modal responsivo de Progressão de Níveis e Multiclasse.
Future<void> mostrarModalProgressaoEMulticlasse(
  BuildContext context,
  FichaCubit cubit,
) async {
  final todasClasses = BancoDeClasses.todas;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (modalCtx) {
      return BlocProvider.value(
        value: cubit,
        child: BlocBuilder<FichaCubit, FichaState>(
          builder: (ctx, state) {
            final p = state.personagem;
            final dist = p.distribuicaoMulticlasse;
            final idsJaPossuidos = p.classes
                .map((c) => c.classeDefinicao.idClasse.toLowerCase())
                .toSet();
            final classesDisponiveis = todasClasses
                .where(
                  (c) => !idsJaPossuidos.contains(c.idClasse.toLowerCase()),
                )
                .toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.78,
              minChildSize: 0.45,
              maxChildSize: 0.94,
              expand: false,
              builder: (_, scrollController) => Padding(
                padding: const EdgeInsets.all(16),
                child: ListView(
                  controller: scrollController,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.trending_up_rounded,
                          color: Color(0xFFD32F2F),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Progressão & Multiclasse (Nível ${p.nivelPersonagem}/20)',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.info_outline_rounded,
                            color: Color(0xFFD32F2F),
                            size: 20,
                          ),
                          tooltip: 'A Importância do Nível',
                          onPressed: () => mostrarInfoNivel(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Banner informativo clicável sobre a permanência e importância do nível
                    InkWell(
                      onTap: () => mostrarInfoNivel(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: Color(0xFFD32F2F),
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'A evolução de nível em Tormenta 20 é permanente. Toque para entender a importância do nível.',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF991B1B),
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: Color(0xFFD32F2F),
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // RF10 / RF11 — Resumo da Distribuição de Níveis e Patamar
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'Personagem: ${dist.nomePersonagem}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: const Color(0xFFFCA5A5),
                                  ),
                                ),
                                child: Text(
                                  'Patamar: ${dist.patamar.label} (${dist.patamar.faixaNiveis})',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFB91C1C),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Nível total: ${dist.nivelTotal} • PV: ${p.pvTotal} • PM: ${p.pmTotal}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155),
                            ),
                          ),
                          if (dist.classes.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: dist.classes.map((c) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Text(
                                    '${c.nomeClasse}: ${c.nivel}',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Progresso de XP Compacto
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'XP: ${p.experienciaAtual} / ${p.progressoXP.xpNecessarioProximoNivel} (${p.progressoXP.porcentagemFormatada})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11.5,
                                ),
                              ),
                              if (p.modoTabletopAtivo)
                                Text(
                                  p.podeSubirDeNivel
                                      ? 'Evolução Liberada'
                                      : 'Requer ${p.progressoXP.xpRestanteParaUpar} XP / Mestre',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: p.podeSubirDeNivel
                                        ? Colors.green.shade800
                                        : Colors.amber.shade900,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: p.nivelPersonagem >= 20
                                  ? 1.0
                                  : p.progressoXP.porcentagem,
                              minHeight: 6,
                              backgroundColor: const Color(0xFFE2E8F0),
                              valueColor: const AlwaysStoppedAnimation(
                                Color(0xFFD97706),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),
                    const Text(
                      'CLASSES REGISTRADAS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF475569),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(p.classes.length, (idx) {
                      final cl = p.classes[idx];
                      final pendentes = cl.poderesPendentes;
                      final habsNivelAtual =
                          cl.classeDefinicao.tabelaDeProgressao[cl.nivel] ??
                          const <String>[];
                      final caminhosNivel1 =
                          cl.classeDefinicao.caminhosNivel1;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${cl.classeDefinicao.nome}${idx == 0 ? " (Inicial)" : " (Multiclasse)"}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14.5,
                                          ),
                                        ),
                                        if (cl.caminhoEscolhido != null)
                                          Text(
                                            cl.caminhoEscolhido!.nome,
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              color: Colors.black54,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    'Nív ${cl.nivel}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    tooltip: 'Adquirir nível nesta classe',
                                    onPressed: p.nivelPersonagem < 20
                                        ? () => verificarEExecutarEvolucao(
                                            context: context,
                                            personagem: p,
                                            nomeClasse:
                                                cl.classeDefinicao.nome,
                                            novoNivelIndividual: cl.nivel + 1,
                                            novoNivelTotal:
                                                p.nivelPersonagem + 1,
                                            onExecutar: () => cubit
                                                .alterarNivelClasse(idx, 1),
                                          )
                                        : null,
                                    icon: const Icon(
                                      Icons.add_circle_outline,
                                      color: Color(0xFFD32F2F),
                                    ),
                                  ),
                                ],
                              ),
                              if (habsNivelAtual.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'No Nv. ${cl.nivel} da classe: ${habsNivelAtual.join(", ")}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ],
                              if (caminhosNivel1.length > 1) ...[
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: caminhosNivel1.map((cam) {
                                    final selecionado =
                                        cl.caminhoEscolhido?.nome == cam.nome;
                                    return ChoiceChip(
                                      selected: selecionado,
                                      visualDensity: VisualDensity.compact,
                                      label: Text(
                                        cam.nome,
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      onSelected: (_) => cubit
                                          .definirCaminhoClasse(idx, cam),
                                    );
                                  }).toList(),
                                ),
                              ],
                              if (cl.nivel >= 2)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () async {
                                      Navigator.pop(modalCtx);
                                      final atualizado =
                                          await Navigator.push<Personagem>(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  SelecaoPoderesScreen(
                                                    personagem: p,
                                                    indiceClasse: idx,
                                                  ),
                                            ),
                                          );
                                      if (context.mounted && atualizado != null) {
                                        cubit.atualizarPersonagem(atualizado);
                                      }
                                    },
                                    icon: Icon(
                                      Icons.auto_fix_high,
                                      size: 16,
                                      color: pendentes > 0
                                          ? Colors.amber.shade900
                                          : const Color(0xFF1E293B),
                                    ),
                                    label: Text(
                                      pendentes > 0
                                          ? 'Escolher Poderes ($pendentes pendente(s))'
                                          : 'Gerenciar Poderes (${cl.poderesEscolhidos.length}/${cl.nivel - 1})',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                        color: pendentes > 0
                                            ? Colors.amber.shade900
                                            : const Color(0xFF1E293B),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                    if (p.nivelPersonagem < 20 &&
                        classesDisponiveis.isNotEmpty) ...[
                      const Divider(height: 24),
                      const Text(
                        'ADQUIRIR NOVA CLASSE — MULTICLASSE (NÍVEL 1)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF475569),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Regras T20: concede PV de nível subsequente e soma os PM da nova classe; não concede perícias nem proficiências iniciais automaticamente.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: classesDisponiveis.map((Classe novaCl) {
                          return ActionChip(
                            avatar: const Icon(
                              Icons.add,
                              size: 16,
                              color: Color(0xFFD32F2F),
                            ),
                            label: Text(
                              '${novaCl.nome} (+${novaCl.pvPorNivel} PV / +${novaCl.pmPorNivel} PM)',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            onPressed: () => verificarEExecutarEvolucao(
                              context: context,
                              personagem: p,
                              nomeClasse: novaCl.nome,
                              novoNivelIndividual: 1,
                              novoNivelTotal: p.nivelPersonagem + 1,
                              onExecutar: () =>
                                  cubit.adicionarMulticlasse(novaCl),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      );
    },
  );
}
