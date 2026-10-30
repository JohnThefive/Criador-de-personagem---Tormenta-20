import 'package:flutter/material.dart';
import '../../../domain/entities/personagem/personagem.dart';
import '../../../domain/services/calculo_ficha_service.dart';
import '../../controllers/ficha_cubit.dart';
import 'dialogos_ficha.dart';

/// Botão compacto (>= 44px área útil) para ativar qualquer poder que consuma PM.
class BotaoAtivarPoderPM extends StatelessWidget {
  final String nomePoder;
  final FichaCubit cubit;

  const BotaoAtivarPoderPM({
    super.key,
    required this.nomePoder,
    required this.cubit,
  });

  Future<void> _abrirSeletorCusto(BuildContext context) async {
    final p = cubit.personagem;
    final custoEscolhido = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Ativar: $nomePoder',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'PM disponível: ${p.pmAtual} / ${p.pmTotal}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF0284C7),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [1, 2, 3, 4, 5, 6].map((custo) {
                  final podePagar =
                      !p.punicaoDivinaAtiva && p.pmAtual >= custo;
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(84, 44),
                      backgroundColor: podePagar
                          ? const Color(0xFF0284C7)
                          : const Color(0xFFE2E8F0),
                      foregroundColor: podePagar
                          ? Colors.white
                          : const Color(0xFF94A3B8),
                    ),
                    onPressed: () => Navigator.pop(ctx, custo),
                    child: Text(
                      '-$custo PM',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );

    if (custoEscolhido != null && context.mounted) {
      final ok = await cubit.tentarAtivarComPM(
        custoEscolhido,
        nomeAcao: nomePoder,
      );
      if (!context.mounted) return;
      final msg = ok
          ? '$nomePoder ativado (-$custoEscolhido PM)!'
          : (cubit.state.mensagemErro ?? 'PM insuficiente!');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: ok ? const Color(0xFF0284C7) : const Color(0xFFB91C1C),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Ativar gastando PM',
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _abrirSeletorCusto(context),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 52, minHeight: 44),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF7DD3FC)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt_rounded, size: 15, color: Color(0xFF0369A1)),
                SizedBox(width: 2),
                Text(
                  'PM',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0369A1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Seção de Proficiências, Sentidos Especiais, Deslocamento e RDs Diversas.
class SecaoProficienciasEGerais extends StatelessWidget {
  final Personagem personagem;
  final FichaCubit cubit;

  const SecaoProficienciasEGerais({
    super.key,
    required this.personagem,
    required this.cubit,
  });

  Future<void> _adicionarProficiencia(BuildContext context) async {
    final res = await showDialog<String>(
      context: context,
      builder: (_) => const CampoTextoDialog(
        titulo: 'Nova Proficiência / Imunidade / Sentido',
        label: 'Descrição',
        hint: 'Ex: Armas de Fogo, Visão no Escuro 18m, Escalada 9m...',
        textoBotaoConfirmar: 'ADICIONAR',
      ),
    );
    if (res != null) {
      cubit.adicionarProficienciaExtra(res);
    }
  }

  Future<void> _adicionarRdDiversa(BuildContext context) async {
    final res = await showDialog<String>(
      context: context,
      builder: (_) => const CampoTextoDialog(
        titulo: 'Adicionar RD Específica / Diversa',
        label: 'Tipo e valor da Redução de Dano',
        hint: 'Ex: RD 10 Fogo, RD 5 Trevas, RD 5 Corte...',
        textoBotaoConfirmar: 'ADICIONAR',
      ),
    );
    if (res != null) {
      cubit.adicionarRdDiversa(res);
    }
  }

  @override
  Widget build(BuildContext context) {
    final resumo = CalculoFichaService.extrairProficienciasESentidos(
      personagem,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Deslocamento
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.directions_run_rounded,
                  color: Color(0xFFD32F2F),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Deslocamento Terrestre',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      resumo.deslocamentoBase,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Proficiências & Características Gerais
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Proficiências & Sentidos',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      minimumSize: const Size(44, 44),
                    ),
                    onPressed: () => _adicionarProficiencia(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Adicionar'),
                  ),
                ],
              ),
              if (resumo.proficienciasClasse.isEmpty &&
                  resumo.proficienciasExtras.isEmpty)
                const Text(
                  'Nenhuma proficiência especial registrada.',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                )
              else
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ...resumo.proficienciasClasse.map(
                      (prof) => Chip(
                        backgroundColor: const Color(0xFFF1F5F9),
                        label: Text(
                          prof,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    ...List.generate(resumo.proficienciasExtras.length, (idx) {
                      final extra = resumo.proficienciasExtras[idx];
                      return InputChip(
                        backgroundColor: const Color(0xFFFEF2F2),
                        label: Text(
                          extra,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFB91C1C),
                          ),
                        ),
                        onDeleted: () => cubit.removerProficienciaExtra(idx),
                      );
                    }),
                  ],
                ),
              if (resumo.sentidosEDeslocamentosEspeciais.isNotEmpty) ...[
                const Divider(height: 22),
                const Text(
                  'Sentidos, Imunidades & Movimentação Detectados:',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 8),
                ...resumo.sentidosEDeslocamentosEspeciais.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 3),
                          child: Icon(
                            Icons.visibility_outlined,
                            size: 15,
                            color: Color(0xFFD32F2F),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF334155),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Reduções de Dano Diversas
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reduções de Dano Diversas (RDs)',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Resistências elementais ou específicas (fogo, frio, trevas, corte...)',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      minimumSize: const Size(44, 44),
                    ),
                    onPressed: () => _adicionarRdDiversa(context),
                    icon: const Icon(Icons.add_moderator_outlined, size: 18),
                    label: const Text('Nova RD'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (resumo.rdsDiversas.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Nenhuma RD diversa cadastrada.',
                    style: TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                  ),
                )
              else
                ...List.generate(resumo.rdsDiversas.length, (idx) {
                  final rd = resumo.rdsDiversas[idx];
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.shield_moon_outlined,
                      color: Color(0xFF0284C7),
                      size: 20,
                    ),
                    title: Text(
                      rd,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                    trailing: IconButton(
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      onPressed: () => cubit.removerRdDiversa(idx),
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 19,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }
}

/// Linha do tempo sequencial de Progressão de Personagem (útil para revisão do Mestre e Distinções).
class SecaoProgressaoPersonagem extends StatelessWidget {
  final Personagem personagem;
  final FichaCubit cubit;
  final VoidCallback onGerenciarPoderes;

  const SecaoProgressaoPersonagem({
    super.key,
    required this.personagem,
    required this.cubit,
    required this.onGerenciarPoderes,
  });

  Future<void> _editarNotaNivel(
    BuildContext context,
    EtapaProgressaoNivel etapa,
  ) async {
    final res = await showDialog<String>(
      context: context,
      builder: (_) => CampoTextoDialog(
        titulo: 'Nível ${etapa.nivelPersonagem} — Distinção / Revisão',
        valorInicial: etapa.notaOuDistincao,
        label: 'Poder de distinção, aumento de atributo ou nota do mestre',
        hint: 'Ex: Poder de Distinção Cavaleiro do Corvo, +1 FOR...',
        textoBotaoConfirmar: 'SALVAR',
      ),
    );
    if (res != null) {
      cubit.salvarNotaProgressaoNivel(etapa.nivelPersonagem, res);
    }
  }

  @override
  Widget build(BuildContext context) {
    final etapas = CalculoFichaService.gerarTrilhaProgressao(personagem);

    if (etapas.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text('Nenhuma classe registrada para exibir a progressão.'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.timeline_rounded,
                color: Color(0xFFD32F2F),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Registro nível a nível de classes, poderes e distinções para conferência rápida na mesa.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
                ),
              ),
              TextButton(
                onPressed: onGerenciarPoderes,
                child: const Text('Poderes'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...etapas.map((etapa) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'NÍVEL ${etapa.nivelPersonagem}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${etapa.nomeClasse} ${etapa.nivelNaClasse}${etapa.caminhoEscolhido != null ? " (${etapa.caminhoEscolhido})" : ""}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Anotar distinção ou observação neste nível',
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      onPressed: () => _editarNotaNivel(context, etapa),
                      icon: Icon(
                        etapa.notaOuDistincao.isNotEmpty
                            ? Icons.edit_note_rounded
                            : Icons.note_add_outlined,
                        color: etapa.notaOuDistincao.isNotEmpty
                            ? const Color(0xFFD32F2F)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                if (etapa.marcosIniciais.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: etapa.marcosIniciais
                        .map(
                          (m) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              m,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                if (etapa.habilidadesDeClasse.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Habilidades de Classe: ${etapa.habilidadesDeClasse.join(", ")}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
                if (etapa.nivelNaClasse >= 2) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        etapa.poderEscolhido != null
                            ? Icons.bolt_rounded
                            : Icons.pending_outlined,
                        size: 16,
                        color: etapa.poderEscolhido != null
                            ? const Color(0xFFD32F2F)
                            : const Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          etapa.poderEscolhido != null
                              ? 'Poder escolhido: ${etapa.poderEscolhido!.nome}'
                              : 'Poder de nível pendente de escolha',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: etapa.poderEscolhido != null
                                ? const Color(0xFF0F172A)
                                : const Color(0xFFB45309),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (etapa.notaOuDistincao.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Distinção / Nota: ${etapa.notaOuDistincao}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF92400E),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => cubit.salvarNotaProgressaoNivel(
                            etapa.nivelPersonagem,
                            '',
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: Color(0xFF92400E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }
}
