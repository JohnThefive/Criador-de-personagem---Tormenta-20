import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/personagem/efeito_temporario.dart';
import '../../../domain/entities/personagem/personagem.dart';
import '../../../domain/services/calculo_ficha_service.dart';
import '../../controllers/ficha_cubit.dart';
import '../../controllers/ficha_state.dart';
import 'dialogo_rolagem_dado.dart';
import 'dialogos_ficha.dart';

class AbaGeralView extends StatelessWidget {
  const AbaGeralView({super.key});

  Future<void> _mostrarDialogoAdicionarXP(
    BuildContext context,
    FichaCubit cubit,
  ) async {
    final res = await showDialog<String>(
      context: context,
      builder: (_) => const CampoTextoDialog(
        titulo: 'Adicionar Experiência (XP)',
        label: 'Pontos de XP a somar',
        hint: 'Ex: 300',
        keyboardType: TextInputType.number,
        textoBotaoConfirmar: 'ADICIONAR',
        corBotaoConfirmar: Color(0xFFD32F2F),
      ),
    );

    if (res != null) {
      final valor = int.tryParse(res) ?? 0;
      if (valor > 0) {
        cubit.adicionarXP(valor);
      }
    }
  }

  Future<void> _mostrarDialogoPunicaoDivina(
    BuildContext context,
    FichaCubit cubit,
  ) async {
    final p = cubit.personagem;
    final sobPunicao = p.punicaoDivinaAtiva;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              sobPunicao ? Icons.verified : Icons.warning_amber_rounded,
              color: sobPunicao ? Colors.green[700] : const Color(0xFFD32F2F),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                sobPunicao
                    ? 'Revogar Punição Divina'
                    : 'Aplicar Punição Divina',
                style: const TextStyle(fontSize: 17),
              ),
            ),
          ],
        ),
        content: Text(
          sobPunicao
              ? 'O personagem cumpriu a penitência exigida por ${p.divindade?.nome ?? "sua divindade"}?\n\n'
                    'Ao confirmar, o herói volta a recuperar Pontos de Mana e reativa seus poderes concedidos.'
              : 'Violação de Obrigações & Restrições perante ${p.divindade?.nome ?? "sua divindade"}:\n\n'
                    '• Todos os PM atuais são reduzidos a 0 imediatamente.\n'
                    '• Recuperação e gasto de PM ficam bloqueados.\n'
                    '• Poderes concedidos ficam inativos até a penitência.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: sobPunicao
                  ? Colors.green[700]
                  : const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(sobPunicao ? 'REVOGAR' : 'APLICAR'),
          ),
        ],
      ),
    );

    if (confirmar == true && context.mounted) {
      if (sobPunicao) {
        await cubit.removerPunicaoDivina();
      } else {
        await cubit.aplicarPunicaoDivina();
      }
    }
  }

  void _mostrarModalDescanso(BuildContext context, FichaCubit cubit) {
    final p = cubit.personagem;
    final con = p.getValorFinal('CON');
    final nivel = p.nivelPersonagem > 0 ? p.nivelPersonagem : 1;
    final curaNormalPV = max(1, nivel + con);
    final curaNormalPM = max(1, nivel);

    showModalBottomSheet<void>(
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
              const Row(
                children: [
                  Icon(
                    Icons.nightlight_round,
                    color: Color(0xFF0284C7),
                    size: 26,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Descanso (Tormenta 20)',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.hotel, color: Colors.blueGrey),
                title: const Text(
                  'Descanso Normal',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Recupera +$curaNormalPV PV e +$curaNormalPM PM.',
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  cubit.descansoNormal();
                },
              ),
              ListTile(
                leading: const Icon(Icons.star_rounded, color: Colors.amber),
                title: const Text(
                  'Descanso Confortável',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Recupera o dobro: +${curaNormalPV * 2} PV e +${curaNormalPM * 2} PM.',
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  cubit.descansoConfortavel();
                },
              ),
              ListTile(
                leading: const Icon(Icons.healing_rounded, color: Colors.green),
                title: const Text(
                  'Restaurar 100%',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Restaura todos os Pontos de Vida e Mana.',
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  cubit.descansoCompleto();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _abrirEditorDefesaOutros(
    BuildContext context,
    FichaCubit cubit,
    int valorAtual,
  ) async {
    final res = await showDialog<String>(
      context: context,
      builder: (_) => CampoTextoDialog(
        titulo: 'Bônus "Outros" na Defesa',
        valorInicial: '$valorAtual',
        label: 'Bônus permanente (anéis, poderes, parceiros)',
        hint: 'Ex: 2',
        keyboardType: const TextInputType.numberWithOptions(signed: true),
      ),
    );
    if (res != null) {
      cubit.definirOutrosBonusDefesa(int.tryParse(res) ?? 0);
    }
  }

  Future<void> _abrirEditorRdPadrao(
    BuildContext context,
    FichaCubit cubit,
    int valorAtual,
  ) async {
    final res = await showDialog<String>(
      context: context,
      builder: (_) => CampoTextoDialog(
        titulo: 'Redução de Dano (RD) Padrão',
        valorInicial: '$valorAtual',
        label: 'Valor geral de RD (aplicado a qualquer dano)',
        hint: 'Ex: 5',
        keyboardType: TextInputType.number,
      ),
    );
    if (res != null) {
      cubit.definirRdPadrao(int.tryParse(res) ?? 0);
    }
  }

  Future<void> _abrirCatalogoCondicoes(
    BuildContext context,
    FichaCubit cubit,
  ) async {
    final condicoes = CatalogoCondicoesT20.condicoesPadrao;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Condições & Buffs Rápidos (T20)',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                itemCount: condicoes.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, index) {
                  final preset = condicoes[index];
                  final jaTem = cubit.personagem.efeitosTemporarios.any(
                    (e) => e.id == preset.id,
                  );
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: preset.tipo == TipoEfeitoTemporario.buff
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFFEE2E2),
                      child: Icon(
                        preset.tipo == TipoEfeitoTemporario.buff
                            ? Icons.auto_awesome_rounded
                            : Icons.warning_amber_rounded,
                        size: 20,
                        color: preset.tipo == TipoEfeitoTemporario.buff
                            ? const Color(0xFF15803D)
                            : const Color(0xFFB91C1C),
                      ),
                    ),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            preset.nome,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        if (preset.possuiModificadorNumerico) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              preset.resumoModificadores,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      preset.descricao,
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: jaTem
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF16A34A),
                          )
                        : const Icon(Icons.add_circle_outline_rounded),
                    onTap: () {
                      cubit.adicionarEfeitoTemporario(preset);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirFormularioEfeito(
    BuildContext context,
    FichaCubit cubit, {
    EfeitoTemporario? existente,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _FormularioEfeitoModal(
        existente: existente,
        onSalvar: (efeito) {
          if (existente != null) {
            cubit.atualizarEfeitoTemporario(efeito);
          } else {
            cubit.adicionarEfeitoTemporario(efeito);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FichaCubit, FichaState>(
      builder: (context, state) {
        final cubit = context.read<FichaCubit>();
        final p = state.personagem;
        final compDefesa = CalculoFichaService.detalharDefesaERd(p);

        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
          children: [
            // 1. ATRIBUTOS (GATILHO ROLAGEM 1 TOQUE - HORIZONTAIS / DEITADOS ESTILO T20)
            _buildBarraAtributosHorizontal(context, p),

            const SizedBox(height: 12),

            // 2. BLOCO DE DEFESA AMPLIADO + RD PADRÃO COMPACTO
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Bloco Maior de Defesa (Flex 7)
                  Expanded(
                    flex: 7,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.shield_rounded,
                                    color: Color(0xFF38BDF8),
                                    size: 20,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'DEFESA',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                              InkWell(
                                key: const Key('btn_editar_outros_defesa'),
                                borderRadius: BorderRadius.circular(8),
                                onTap: () => _abrirEditorDefesaOutros(
                                  context,
                                  cubit,
                                  p.outrosBonusDefesa,
                                ),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minHeight: 36,
                                    minWidth: 44,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Outros ${p.outrosBonusDefesa >= 0 ? "+${p.outrosBonusDefesa}" : "${p.outrosBonusDefesa}"}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '${compDefesa.defesaFinal}',
                                key: const Key('valor_defesa_final'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 40,
                                  fontWeight: FontWeight.w900,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  compDefesa.parcelasDefesa
                                      .map(
                                        (parc) =>
                                            '${parc.rotulo} ${parc.rotulo == "Base" ? "10" : parc.valorFormatado}',
                                      )
                                      .join(' • '),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (compDefesa.usaProtecaoSemProficiencia) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFEF4444,
                                ).withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '⚠ Proteção sem proficiência (penalidade em FOR/DES)',
                                style: TextStyle(
                                  color: Color(0xFFFECACA),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Bloco Compacto de RD Padrão (Flex 4)
                  Expanded(
                    flex: 4,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                            onTap: () =>
                                _abrirEditorRdPadrao(context, cubit, p.rdPadrao),
                            child: Column(
                              children: [
                                const Text(
                                  'RD PADRÃO',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${compDefesa.rdTotal}',
                                  key: const Key('valor_rd_padrao'),
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0F172A),
                                    height: 1.05,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _BotaoMiniStepper(
                                icon: Icons.remove,
                                tooltip: 'Reduzir RD padrão',
                                onTap: () => cubit.ajustarRdPadrao(-1),
                              ),
                              const SizedBox(width: 8),
                              _BotaoMiniStepper(
                                icon: Icons.add,
                                tooltip: 'Aumentar RD padrão',
                                onTap: () => cubit.ajustarRdPadrao(1),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 3. RESUMO TÁTICO EXPANDIDO (DESLOCAMENTO, PENALIDADE E CARGA)
            _buildResumoTatico(p),

            const SizedBox(height: 14),

            // 4. EFEITOS TEMPORÁRIOS (BUFFS, DEBUFFS, CONDIÇÕES, PERDA DE VIDA E NOTAS)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.bolt_rounded,
                        color: Color(0xFFD32F2F),
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'Efeitos Temporários & Condições',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      if (p.efeitosTemporarios.isNotEmpty)
                        TextButton(
                          onPressed: cubit.limparEfeitosTemporarios,
                          child: const Text(
                            'Limpar',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  const Text(
                    'Adicione buffs, debuffs, condições, penalidades ou anotações de cena. Modificadores ativos alteram Perícias, Defesa e RD automaticamente.',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const Key('btn_condicoes_rapidas'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 44),
                            foregroundColor: const Color(0xFF334155),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () =>
                              _abrirCatalogoCondicoes(context, cubit),
                          icon: const Icon(Icons.playlist_add_check, size: 18),
                          label: const Text(
                            'Condição T20',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          key: const Key('btn_novo_efeito_temp'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 44),
                            backgroundColor: const Color(0xFFD32F2F),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () =>
                              _abrirFormularioEfeito(context, cubit),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text(
                            'Novo Efeito',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (p.efeitosTemporarios.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Nenhum efeito temporário ativo na cena.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    )
                  else
                    ...p.efeitosTemporarios.map(
                      (ef) => _CardEfeitoTemporario(
                        efeito: ef,
                        onToggle: () =>
                            cubit.alternarAtivacaoEfeitoTemporario(ef.id),
                        onEditar: () => _abrirFormularioEfeito(
                          context,
                          cubit,
                          existente: ef,
                        ),
                        onRemover: () => cubit.removerEfeitoTemporario(ef.id),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 4. ATALHOS DE SESSÃO: DESCANSO, EXPERIÊNCIA E PUNIÇÃO DIVINA
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0369A1),
                      side: const BorderSide(color: Color(0xFFBAE6FD)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _mostrarModalDescanso(context, cubit),
                    icon: const Icon(Icons.nightlight_round, size: 19),
                    label: const Text(
                      'Descansar',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF4338CA),
                      side: const BorderSide(color: Color(0xFFC7D2FE)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _mostrarDialogoAdicionarXP(context, cubit),
                    icon: const Icon(Icons.trending_up_rounded, size: 19),
                    label: Text(
                      'XP: ${p.experienciaAtual}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),

            if (p.divindade != null) ...[
              const SizedBox(height: 12),
              Card(
                margin: EdgeInsets.zero,
                color: p.punicaoDivinaAtiva
                    ? const Color(0xFFFEF2F2)
                    : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: p.punicaoDivinaAtiva
                        ? const Color(0xFFEF4444)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: ListTile(
                  leading: Icon(
                    p.punicaoDivinaAtiva
                        ? Icons.gavel_rounded
                        : Icons.temple_hindu_outlined,
                    color: p.punicaoDivinaAtiva
                        ? const Color(0xFFB91C1C)
                        : const Color(0xFF64748B),
                  ),
                  title: Text(
                    p.punicaoDivinaAtiva
                        ? 'Punição Divina Ativa (${p.divindade!.nome})'
                        : 'Devoção: ${p.divindade!.nome}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      color: p.punicaoDivinaAtiva
                          ? const Color(0xFFB91C1C)
                          : const Color(0xFF0F172A),
                    ),
                  ),
                  subtitle: Text(
                    p.punicaoDivinaAtiva
                        ? 'PM bloqueado e poderes concedidos suspensos. Toque para registrar penitência.'
                        : 'Toque se houver quebra de Obrigações & Restrições.',
                    style: const TextStyle(fontSize: 11.5),
                  ),
                  onTap: () => _mostrarDialogoPunicaoDivina(context, cubit),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildBarraAtributosHorizontal(BuildContext context, Personagem p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Atributos',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            Flexible(
              child: Text(
                'Toque para rolar 1d20 + Atributo',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: CalculoFichaService.ordemAtributos
              .asMap()
              .entries
              .map((entry) {
                final idx = entry.key;
                final sigla = entry.value;
                final valor = p.getValorFinal(sigla);
                final textoValor = valor >= 0 ? '+$valor' : '$valor';

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: idx == 0 ? 0 : 4),
                    child: Semantics(
                      button: true,
                      label: 'Rolar atributo $sigla $textoValor',
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        elevation: 1,
                        shadowColor: Colors.black12,
                        child: InkWell(
                          key: Key('card_atributo_$sigla'),
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => mostrarDialogoRolagemAtributo(
                            context,
                            personagem: p,
                            siglaAtributo: sigla,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFCBD5E1),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Faixa vermelha Tormenta 20
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2.5,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFC62828),
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(7),
                                    ),
                                  ),
                                  child: Text(
                                    sigla,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                // Valor do modificador
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 5,
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      textoValor,
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w900,
                                        color: valor < 0
                                            ? const Color(0xFFB91C1C)
                                            : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              })
              .toList(),
        ),
      ],
    );
  }

  Widget _buildResumoTatico(Personagem p) {
    final penalidade = p.penalidadeArmaduraTotal;
    final estaSobrecarregado = p.estaSobrecarregado;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          // Deslocamento
          Expanded(
            child: _buildItemTatico(
              icone: Icons.directions_run_rounded,
              corIcone: const Color(0xFF0284C7),
              rotulo: 'DESLOCAMENTO',
              valor: '${p.deslocamentoEfetivoMetros}m',
              subtitulo: p.deslocamentoEfetivoMetros != p.deslocamentoBaseMetros
                  ? 'Base ${p.deslocamentoBaseMetros}m'
                  : null,
            ),
          ),
          Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
          // Penalidade de Armadura
          Expanded(
            child: _buildItemTatico(
              icone: Icons.shield_outlined,
              corIcone: penalidade < 0
                  ? const Color(0xFFDC2626)
                  : const Color(0xFF475569),
              rotulo: 'PENALIDADE',
              valor: penalidade == 0 ? '0' : '$penalidade',
              corValor: penalidade < 0 ? const Color(0xFFDC2626) : null,
              subtitulo: 'Armadura/Escudo',
            ),
          ),
          Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
          // Capacidade de Carga
          Expanded(
            child: _buildItemTatico(
              icone: Icons.fitness_center_rounded,
              corIcone: estaSobrecarregado
                  ? const Color(0xFFDC2626)
                  : const Color(0xFF16A34A),
              rotulo: 'CARGA',
              valor: '${p.cargaAtual}/${p.limiteCarga}',
              corValor: estaSobrecarregado ? const Color(0xFFDC2626) : null,
              subtitulo: estaSobrecarregado ? 'Sobrepeso!' : 'Espaços',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemTatico({
    required IconData icone,
    required Color corIcone,
    required String rotulo,
    required String valor,
    Color? corValor,
    String? subtitulo,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icone, size: 13, color: corIcone),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  rotulo,
                  style: const TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 1),
          Text(
            valor,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: corValor ?? const Color(0xFF0F172A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitulo != null)
            Text(
              subtitulo,
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w600,
                color: subtitulo.contains('!')
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF94A3B8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}

class _BotaoMiniStepper extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _BotaoMiniStepper({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: const SizedBox(
            width: 44,
            height: 44,
            child: Center(child: Icon(Icons.exposure, size: 0)),
          ),
        ),
      ),
    ).buildWithIcon(icon, onTap, tooltip);
  }
}

extension on Widget {
  Widget buildWithIcon(IconData icon, VoidCallback onTap, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, size: 18, color: const Color(0xFF334155)),
          ),
        ),
      ),
    );
  }
}

class _CardEfeitoTemporario extends StatelessWidget {
  final EfeitoTemporario efeito;
  final VoidCallback onToggle;
  final VoidCallback onEditar;
  final VoidCallback onRemover;

  const _CardEfeitoTemporario({
    required this.efeito,
    required this.onToggle,
    required this.onEditar,
    required this.onRemover,
  });

  @override
  Widget build(BuildContext context) {
    final corBadge = switch (efeito.tipo) {
      TipoEfeitoTemporario.buff => const Color(0xFF15803D),
      TipoEfeitoTemporario.debuff => const Color(0xFFB91C1C),
      TipoEfeitoTemporario.condicao => const Color(0xFFB45309),
      TipoEfeitoTemporario.nota => const Color(0xFF475569),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: efeito.ativo ? Colors.white : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: efeito.ativo
              ? corBadge.withValues(alpha: 0.4)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onEditar,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              Switch(
                value: efeito.ativo,
                activeThumbColor: corBadge,
                onChanged: (_) => onToggle(),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: corBadge.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            efeito.tipo.label.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              color: corBadge,
                            ),
                          ),
                        ),
                        Text(
                          efeito.nome,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            decoration: efeito.ativo
                                ? null
                                : TextDecoration.lineThrough,
                            color: efeito.ativo
                                ? const Color(0xFF0F172A)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                    if (efeito.possuiModificadorNumerico)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          efeito.resumoModificadores,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: corBadge,
                          ),
                        ),
                      ),
                    if (efeito.descricao.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          efeito.descricao,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Remover efeito',
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed: onRemover,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormularioEfeitoModal extends StatefulWidget {
  final EfeitoTemporario? existente;
  final ValueChanged<EfeitoTemporario> onSalvar;

  const _FormularioEfeitoModal({
    this.existente,
    required this.onSalvar,
  });

  @override
  State<_FormularioEfeitoModal> createState() => _FormularioEfeitoModalState();
}

class _FormularioEfeitoModalState extends State<_FormularioEfeitoModal> {
  late final TextEditingController _nomeCtrl;
  late final TextEditingController _descCtrl;
  late TipoEfeitoTemporario _tipo;
  late int _modPericias;
  late int _modDefesa;
  late int _modRd;

  @override
  void initState() {
    super.initState();
    final e = widget.existente;
    _nomeCtrl = TextEditingController(text: e?.nome ?? '');
    _descCtrl = TextEditingController(text: e?.descricao ?? '');
    _tipo = e?.tipo ?? TipoEfeitoTemporario.buff;
    _modPericias = e?.modPericias ?? 0;
    _modDefesa = e?.modDefesa ?? 0;
    _modRd = e?.modRd ?? 0;
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existente == null
                  ? 'Novo Efeito Temporário'
                  : 'Editar Efeito Temporário',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: TipoEfeitoTemporario.values.map((t) {
                return ChoiceChip(
                  label: Text(t.label),
                  selected: _tipo == t,
                  onSelected: (_) => setState(() => _tipo = t),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nomeCtrl,
              autofocus: widget.existente == null,
              decoration: const InputDecoration(
                labelText: 'Nome do efeito / condição',
                hintText: 'Ex: Oração (+2), Veneno, Perda de PV...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Anotação / duração (opcional)',
                hintText: 'Ex: Dura até o fim da cena',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Modificadores Automáticos (Opcional):',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            _LinhaModificadorForm(
              rotulo: 'Perícias',
              valor: _modPericias,
              onChanged: (v) => setState(() => _modPericias = v),
            ),
            _LinhaModificadorForm(
              rotulo: 'Defesa',
              valor: _modDefesa,
              onChanged: (v) => setState(() => _modDefesa = v),
            ),
            _LinhaModificadorForm(
              rotulo: 'RD Padrão',
              valor: _modRd,
              onChanged: (v) => setState(() => _modRd = v),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 48),
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                final nome = _nomeCtrl.text.trim();
                if (nome.isEmpty) return;
                final salvo = EfeitoTemporario(
                  id:
                      widget.existente?.id ??
                      DateTime.now().microsecondsSinceEpoch.toString(),
                  nome: nome,
                  tipo: _tipo,
                  descricao: _descCtrl.text.trim(),
                  ativo: widget.existente?.ativo ?? true,
                  modPericias: _modPericias,
                  modDefesa: _modDefesa,
                  modRd: _modRd,
                );
                widget.onSalvar(salvo);
                Navigator.pop(context);
              },
              child: const Text(
                'SALVAR EFEITO',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinhaModificadorForm extends StatelessWidget {
  final String rotulo;
  final int valor;
  final ValueChanged<int> onChanged;

  const _LinhaModificadorForm({
    required this.rotulo,
    required this.valor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(rotulo, style: const TextStyle(fontWeight: FontWeight.w600)),
          Row(
            children: [
              IconButton(
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed: () => onChanged((valor - 1).clamp(-30, 30)),
                icon: const Icon(Icons.remove_circle_outline),
              ),
              SizedBox(
                width: 36,
                child: Text(
                  valor > 0 ? '+$valor' : '$valor',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
              IconButton(
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed: () => onChanged((valor + 1).clamp(-30, 30)),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
