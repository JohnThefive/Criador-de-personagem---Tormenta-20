import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/equipamento/arma.dart';
import '../../../domain/entities/equipamento/item_geral.dart';
import '../../../domain/entities/equipamento/item_vestido.dart';
import '../../../domain/entities/equipamento/protecao.dart';
import '../../../domain/services/data_services/call_armaduras.dart';
import '../../../domain/services/data_services/call_armas.dart';
import '../../../domain/services/regras_carga_service.dart';
import '../../controllers/ficha_cubit.dart';
import '../../controllers/ficha_state.dart';
import '../../widgets/card_metrica_clicavel.dart';
import 'dialogos_ficha.dart';

class AbaInventarioView extends StatelessWidget {
  const AbaInventarioView({super.key});

  Future<void> _editarMoeda(
    BuildContext context, {
    required String titulo,
    required int valorAtual,
    required ValueChanged<int> onSalvar,
  }) async {
    final res = await showDialog<int>(
      context: context,
      builder: (_) => _DialogoCarteiraMoeda(
        titulo: titulo,
        valorAtual: valorAtual,
      ),
    );
    if (res != null) {
      onSalvar(res);
    }
  }

  Future<void> _selecionarArmaduraSlot1(
    BuildContext context,
    FichaCubit cubit,
  ) async {
    final armaduras = [
      ...BancoDeArmaduras.armadurasLeves(),
      ...BancoDeArmaduras.armadurasPesadas(),
    ];
    final atual = cubit.personagem.armaduraEquipada;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Slot 1 Vestido — Armadura',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  if (atual != null)
                    TextButton.icon(
                      onPressed: () {
                        cubit.equiparArmadura(null);
                        Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Desequipar'),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                itemCount: armaduras.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, idx) {
                  final arm = armaduras[idx];
                  final equipada = atual?.key == arm.key;
                  return ListTile(
                    selected: equipada,
                    leading: Icon(
                      arm.ehArmaduraPesada
                          ? Icons.security_rounded
                          : Icons.shield_outlined,
                      color: equipada
                          ? const Color(0xFFD32F2F)
                          : const Color(0xFF475569),
                    ),
                    title: Text(
                      arm.nome,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      'Defesa +${arm.bonusDefesa} • Pen. -${arm.penalidadeArmadura} • ${arm.espacos} esp. • ${arm.ehArmaduraPesada ? "Pesada" : "Leve"}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: equipada
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFFD32F2F),
                          )
                        : null,
                    onTap: () {
                      cubit.equiparArmadura(arm);
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

  Future<void> _selecionarEscudo(
    BuildContext context,
    FichaCubit cubit,
  ) async {
    final escudos = BancoDeArmaduras.escudos();
    final atual = cubit.personagem.escudoEquipado;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Escudo Empunhado',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  if (atual != null)
                    TextButton(
                      onPressed: () {
                        cubit.equiparEscudo(null);
                        Navigator.pop(ctx);
                      },
                      child: const Text('Desequipar'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              ...escudos.map((esc) {
                final equipado = atual?.key == esc.key;
                return ListTile(
                  leading: const Icon(Icons.shield_rounded),
                  title: Text(
                    esc.nome,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    'Defesa +${esc.bonusDefesa} • Pen. -${esc.penalidadeArmadura} • ${esc.espacos} esp.',
                  ),
                  trailing: equipado
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFFD32F2F),
                        )
                      : null,
                  onTap: () {
                    cubit.equiparEscudo(esc);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editarSlotVestidoExtra(
    BuildContext context,
    FichaCubit cubit, {
    required int slotIndex,
    ItemVestido? atual,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _DialogoSlotVestidoExtra(
        numeroSlotVisual: slotIndex + 1,
        existente: atual,
        onSalvar: (item) => cubit.salvarItemVestidoExtra(item),
        onRemover: () => cubit.removerItemVestidoExtra(slotIndex),
      ),
    );
  }

  Future<void> _selecionarNovaArma(
    BuildContext context,
    FichaCubit cubit,
  ) async {
    final todasArmas = BancoDeArmas.todas;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Adicionar Arma ao Inventário',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                itemCount: todasArmas.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, idx) {
                  final arma = todasArmas[idx];
                  return ListTile(
                    dense: true,
                    title: Text(
                      arma.nome,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      'Dano ${arma.dano} (${arma.criticoFormatado}) • ${arma.proficiencia.label} • ${arma.espacos} esp.',
                    ),
                    trailing: const Icon(
                      Icons.add_circle_outline,
                      color: Color(0xFFD32F2F),
                    ),
                    onTap: () {
                      cubit.adicionarArmaInventario(arma);
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

  Future<void> _adicionarOuEditarItemMochila(
    BuildContext context,
    FichaCubit cubit, {
    int? index,
    String valorInicial = '',
  }) async {
    final texto = await showDialog<String>(
      context: context,
      builder: (_) => CampoTextoDialog(
        titulo: index == null ? 'Adicionar Item na Mochila' : 'Editar Item',
        valorInicial: valorInicial,
        label: 'Nome do item (opcional: "(2 esp)" ou "(0 esp)")',
        hint: 'Ex: Bálsamo Restaurador, Corda (1 esp)...',
        textoBotaoConfirmar: index == null ? 'ADICIONAR' : 'SALVAR',
      ),
    );

    if (texto != null) {
      if (index == null) {
        cubit.adicionarItemMochila(texto);
      } else {
        cubit.editarItemMochila(index, texto);
      }
    }
  }

  Future<void> _mostrarModalMelhoriasArma(
    BuildContext context,
    FichaCubit cubit,
    int indexArma,
    Arma armaInicial,
  ) async {
    final melhorias = List<String>.from(armaInicial.melhorias);
    final encantos = List<String>.from(armaInicial.encantos);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          void toggleMelhoria(String id) {
            setModalState(() {
              if (melhorias.contains(id)) {
                melhorias.remove(id);
              } else if (melhorias.length < 4) {
                melhorias.add(id);
              }
            });
          }

          void toggleEncanto(String id) {
            setModalState(() {
              if (encantos.contains(id)) {
                encantos.remove(id);
              } else if (encantos.length < 3) {
                encantos.add(id);
              }
            });
          }

          final preview = armaInicial.copyWith(
            melhorias: List<String>.from(melhorias),
            encantos: List<String>.from(encantos),
          );

          return DraggableScrollableSheet(
            initialChildSize: 0.78,
            minChildSize: 0.5,
            maxChildSize: 0.94,
            expand: false,
            builder: (_, scrollController) => Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                controller: scrollController,
                children: [
                  Text(
                    'Melhorias & Encantos — ${armaInicial.nome}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Dano ${preview.danoEfetivo} (${preview.criticoFormatado}) • Atq +${preview.bonusAtaqueMelhorias} • Dano +${preview.bonusDanoMelhorias} • ${preview.espacosEfetivos} esp.',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFB91C1C),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'MELHORIAS SUPERIORES (${melhorias.length}/4)',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: CatalogoItensGeraisEMelhorias
                        .melhoriasArmasDisponiveis
                        .entries
                        .map((e) {
                          final sel = melhorias.contains(e.key);
                          return FilterChip(
                            selected: sel,
                            label: Text(
                              e.value,
                              style: const TextStyle(fontSize: 11.5),
                            ),
                            selectedColor: const Color(0xFFFEE2E2),
                            checkmarkColor: const Color(0xFFB91C1C),
                            onSelected: (_) => toggleMelhoria(e.key),
                          );
                        })
                        .toList(),
                  ),
                  const Divider(height: 24),
                  Text(
                    'ENCANTOS MÁGICOS (${encantos.length}/3)',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: CatalogoItensGeraisEMelhorias
                        .encantosArmasDisponiveis
                        .entries
                        .map((e) {
                          final sel = encantos.contains(e.key);
                          return FilterChip(
                            selected: sel,
                            label: Text(
                              e.value,
                              style: const TextStyle(fontSize: 11.5),
                            ),
                            selectedColor: const Color(0xFFE0E7FF),
                            checkmarkColor: const Color(0xFF3730A3),
                            onSelected: (_) => toggleEncanto(e.key),
                          );
                        })
                        .toList(),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 46),
                    ),
                    onPressed: () {
                      cubit.atualizarArmaInventario(indexArma, preview);
                      Navigator.pop(ctx);
                    },
                    child: const Text(
                      'APLICAR MELHORIAS & ENCANTOS',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _mostrarModalMelhoriasProtecao(
    BuildContext context,
    FichaCubit cubit,
    Protecao protecaoInicial, {
    required bool ehEscudo,
  }) async {
    final melhorias = List<String>.from(protecaoInicial.melhorias);
    final encantos = List<String>.from(protecaoInicial.encantos);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          void toggleMelhoria(String id) {
            setModalState(() {
              if (melhorias.contains(id)) {
                melhorias.remove(id);
              } else if (melhorias.length < 4) {
                melhorias.add(id);
              }
            });
          }

          void toggleEncanto(String id) {
            setModalState(() {
              if (encantos.contains(id)) {
                encantos.remove(id);
              } else if (encantos.length < 3) {
                encantos.add(id);
              }
            });
          }

          final preview = protecaoInicial.copyWith(
            melhorias: List<String>.from(melhorias),
            encantos: List<String>.from(encantos),
          );

          return DraggableScrollableSheet(
            initialChildSize: 0.72,
            minChildSize: 0.45,
            maxChildSize: 0.92,
            expand: false,
            builder: (_, scrollController) => Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                controller: scrollController,
                children: [
                  Text(
                    'Melhorias & Encantos — ${protecaoInicial.nome}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Defesa +${preview.bonusDefesaEfetivo} • Pen. -${preview.penalidadeArmaduraEfetiva.abs()} • RD ${preview.rdMelhorias} • ${preview.espacosEfetivos} esp.',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFB91C1C),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'MELHORIAS SUPERIORES (${melhorias.length}/4)',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: CatalogoItensGeraisEMelhorias
                        .melhoriasProtecoesDisponiveis
                        .entries
                        .map((e) {
                          final sel = melhorias.contains(e.key);
                          return FilterChip(
                            selected: sel,
                            label: Text(
                              e.value,
                              style: const TextStyle(fontSize: 11.5),
                            ),
                            selectedColor: const Color(0xFFFEE2E2),
                            checkmarkColor: const Color(0xFFB91C1C),
                            onSelected: (_) => toggleMelhoria(e.key),
                          );
                        })
                        .toList(),
                  ),
                  const Divider(height: 24),
                  Text(
                    'ENCANTOS MÁGICOS (${encantos.length}/3)',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: CatalogoItensGeraisEMelhorias
                        .encantosProtecoesDisponiveis
                        .entries
                        .map((e) {
                          final sel = encantos.contains(e.key);
                          return FilterChip(
                            selected: sel,
                            label: Text(
                              e.value,
                              style: const TextStyle(fontSize: 11.5),
                            ),
                            selectedColor: const Color(0xFFE0E7FF),
                            checkmarkColor: const Color(0xFF3730A3),
                            onSelected: (_) => toggleEncanto(e.key),
                          );
                        })
                        .toList(),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 46),
                    ),
                    onPressed: () {
                      if (ehEscudo) {
                        cubit.equiparEscudo(preview);
                      } else {
                        cubit.equiparArmadura(preview);
                      }
                      Navigator.pop(ctx);
                    },
                    child: const Text(
                      'APLICAR MELHORIAS & ENCANTOS',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _abrirCatalogoItensGerais(
    BuildContext context,
    FichaCubit cubit,
  ) async {
    CategoriaItemGeral? filtroCat;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final itens = filtroCat == null
              ? CatalogoItensGeraisEMelhorias.itensGerais
              : CatalogoItensGeraisEMelhorias.itensPorCategoria(filtroCat!);

          return DraggableScrollableSheet(
            initialChildSize: 0.78,
            minChildSize: 0.5,
            maxChildSize: 0.94,
            expand: false,
            builder: (_, scrollController) => Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Catálogo de Itens Gerais (T20)',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Alquímicos, Esotéricos, Vestuário, Alimentação e Ferramentas.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            selected: filtroCat == null,
                            label: const Text('Todos'),
                            onSelected: (_) =>
                                setModalState(() => filtroCat = null),
                          ),
                        ),
                        ...CategoriaItemGeral.values.map((cat) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              selected: filtroCat == cat,
                              label: Text(cat.label),
                              onSelected: (_) =>
                                  setModalState(() => filtroCat = cat),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: itens.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (_, idx) {
                        final item = itens[idx];
                        return ListTile(
                          dense: true,
                          title: Text(
                            '${item.nome} (T\$ ${item.precoTibares})',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            '${item.categoria.label} • ${item.espacos} esp. • ${item.efeitoResumo}',
                            style: const TextStyle(fontSize: 11.5),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (item.ehVestido)
                                TextButton(
                                  onPressed: () {
                                    cubit.adicionarItemGeral(
                                      item,
                                      vestirEmSlotLivre: true,
                                    );
                                    Navigator.pop(ctx);
                                  },
                                  child: const Text(
                                    'Vestir',
                                    style: TextStyle(fontSize: 11.5),
                                  ),
                                ),
                              IconButton(
                                tooltip: 'Adicionar na mochila',
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                  color: Color(0xFFD32F2F),
                                ),
                                onPressed: () {
                                  cubit.adicionarItemGeral(item);
                                  Navigator.pop(ctx);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FichaCubit, FichaState>(
      buildWhen: (prev, curr) {
        final p1 = prev.personagem;
        final p2 = curr.personagem;
        return p1.armas != p2.armas ||
            p1.armaduraEquipada != p2.armaduraEquipada ||
            p1.escudoEquipado != p2.escudoEquipado ||
            p1.itensVestidosExtras != p2.itensVestidosExtras ||
            p1.itensInventario != p2.itensInventario ||
            p1.engenhocas != p2.engenhocas ||
            p1.tibares != p2.tibares ||
            p1.tibaresCobre != p2.tibaresCobre ||
            p1.tibaresOuro != p2.tibaresOuro ||
            p1.cargaAtual != p2.cargaAtual ||
            p1.limiteCarga != p2.limiteCarga ||
            p1.atributos != p2.atributos;
      },
      builder: (context, state) {
        final cubit = context.read<FichaCubit>();
        final p = state.personagem;
        final carga = RegrasCargaService.avaliarCarga(p);
        final progressoCarga = carga.limiteCarga > 0
            ? (carga.cargaAtual / carga.limiteCarga).clamp(0.0, 1.0)
            : 1.0;

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. ÁREA DE CARGAS (ESPAÇOS / CAPACIDADE)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: carga.sobrecarregado
                    ? const Color(0xFFFEF2F2)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: carga.sobrecarregado
                      ? const Color(0xFFEF4444)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.fitness_center_rounded,
                            size: 18,
                            color: carga.sobrecarregado
                                ? const Color(0xFFB91C1C)
                                : const Color(0xFF334155),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Capacidade de Carga',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${carga.cargaAtual} / ${carga.limiteCarga} espaços (Máx: ${carga.cargaMaximaAbsoluta})',
                        key: const Key('texto_resumo_carga'),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12.5,
                          color: carga.sobrecarregado
                              ? const Color(0xFFB91C1C)
                              : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  LinearProgressIndicator(
                    value: progressoCarga,
                    minHeight: 9,
                    borderRadius: BorderRadius.circular(6),
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      carga.sobrecarregado
                          ? const Color(0xFFDC2626)
                          : (progressoCarga > 0.8
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFF10B981)),
                    ),
                  ),
                  if (carga.sobrecarregado) ...[
                    const SizedBox(height: 6),
                    const Text(
                      '⚠ Sobrecarregado: Defesa limitada, -2 de penalidade de armadura e -3m no deslocamento!',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFB91C1C),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 2. CONTROLE DE TIBARES EM DENOMINAÇÕES (TC, T$, TO)
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
                      const Row(
                        children: [
                          Icon(
                            Icons.monetization_on_rounded,
                            color: Color(0xFFD97706),
                            size: 19,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Bolsa de Tibares',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Total equiv.: T\$ ${p.patrimonioTotalTibares.toStringAsFixed(1)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: CardMetricaClicavel(
                          keyWidget: const Key('card_tibar_cobre'),
                          rotulo: 'TC',
                          subtitulo: 'Cobre (0,1)',
                          valor: '${p.tibaresCobre}',
                          corRotulo: const Color(0xFF9A3412),
                          tamanhoRotulo: 11.5,
                          pesoRotulo: FontWeight.w900,
                          tamanhoValor: 18,
                          pesoValor: FontWeight.w900,
                          minHeight: 62,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          onTap: () => _editarMoeda(
                            context,
                            titulo: 'Tibares de Cobre (TC)',
                            valorAtual: p.tibaresCobre,
                            onSalvar: (v) => cubit.definirTibares(cobre: v),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CardMetricaClicavel(
                          keyWidget: const Key('card_tibar_prata'),
                          rotulo: 'T\$',
                          subtitulo: 'Padrão (1)',
                          valor: '${p.tibares}',
                          corRotulo: const Color(0xFF334155),
                          tamanhoRotulo: 11.5,
                          pesoRotulo: FontWeight.w900,
                          tamanhoValor: 18,
                          pesoValor: FontWeight.w900,
                          minHeight: 62,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          onTap: () => _editarMoeda(
                            context,
                            titulo: 'Tibares Padrão (T\$)',
                            valorAtual: p.tibares,
                            onSalvar: (v) => cubit.definirTibares(prata: v),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CardMetricaClicavel(
                          keyWidget: const Key('card_tibar_ouro'),
                          rotulo: 'TO',
                          subtitulo: 'Ouro (10)',
                          valor: '${p.tibaresOuro}',
                          corRotulo: const Color(0xFFB45309),
                          tamanhoRotulo: 11.5,
                          pesoRotulo: FontWeight.w900,
                          tamanhoValor: 18,
                          pesoValor: FontWeight.w900,
                          minHeight: 62,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          onTap: () => _editarMoeda(
                            context,
                            titulo: 'Tibares de Ouro (TO)',
                            valorAtual: p.tibaresOuro,
                            onSalvar: (v) => cubit.definirTibares(ouro: v),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 3. QUATRO SLOTS SEPARADOS PARA ITENS VESTIDOS (SLOT 1 = ARMADURA)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Itens Vestidos (Limite: 4 Slots)',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'Regra T20 JdA',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Slot 1: Armadura Equipada
            _SlotItemVestidoCard(
              key: const Key('slot_vestido_1'),
              numeroSlot: 1,
              rotuloTipo: 'Armadura',
              titulo: p.armaduraEquipada != null
                  ? '${p.armaduraEquipada!.nome}${p.armaduraEquipada!.ehSuperiorOuMagica ? " ✨" : ""}'
                  : 'Sem armadura equipada',
              subtitulo: p.armaduraEquipada != null
                  ? 'Defesa +${p.armaduraEquipada!.bonusDefesaEfetivo} • Pen. -${p.armaduraEquipada!.penalidadeArmaduraEfetiva.abs()}${p.armaduraEquipada!.rdMelhorias > 0 ? " • RD ${p.armaduraEquipada!.rdMelhorias}" : ""}'
                  : 'Toque para vestir uma armadura do catálogo',
              espacos: p.armaduraEquipada?.espacosEfetivos ?? 0,
              ocupado: p.armaduraEquipada != null,
              icone: Icons.shield_outlined,
              onTap: () => _selecionarArmaduraSlot1(context, cubit),
              onConfigurarMelhorias: p.armaduraEquipada != null
                  ? () => _mostrarModalMelhoriasProtecao(
                        context,
                        cubit,
                        p.armaduraEquipada!,
                        ehEscudo: false,
                      )
                  : null,
            ),
            // Slots 2, 3 e 4: Itens Vestidos Extras
            for (int slotIdx = 1; slotIdx <= 3; slotIdx++)
              Builder(
                builder: (_) {
                  final itemExtra = p.itensVestidosExtras
                      .where((i) => i.slotIndex == slotIdx)
                      .firstOrNull;
                  return _SlotItemVestidoCard(
                    key: Key('slot_vestido_${slotIdx + 1}'),
                    numeroSlot: slotIdx + 1,
                    rotuloTipo: 'Vestuário',
                    titulo: itemExtra?.nome ?? 'Slot ${slotIdx + 1} livre',
                    subtitulo: itemExtra != null
                        ? (itemExtra.beneficio.isNotEmpty
                              ? itemExtra.beneficio
                              : 'Item vestido equipado')
                        : 'Toque para equipar capa, botas, amuleto, anel...',
                    espacos: itemExtra?.espacos ?? 0,
                    ocupado: itemExtra != null,
                    icone: Icons.checkroom_rounded,
                    onTap: () => _editarSlotVestidoExtra(
                      context,
                      cubit,
                      slotIndex: slotIdx,
                      atual: itemExtra,
                    ),
                  );
                },
              ),

            const SizedBox(height: 12),

            // ESCUDO EMPUNHADO & ARMAS CARREGADAS
            Container(
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Empunhados & Armas',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () => _selecionarEscudo(context, cubit),
                            icon: const Icon(Icons.shield_rounded, size: 16),
                            label: Text(
                              p.escudoEquipado?.nome ?? 'Escudo',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Adicionar arma',
                            constraints: const BoxConstraints(
                              minWidth: 44,
                              minHeight: 44,
                            ),
                            onPressed: () =>
                                _selecionarNovaArma(context, cubit),
                            icon: const Icon(
                              Icons.add_circle,
                              color: Color(0xFFD32F2F),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (p.escudoEquipado == null && p.armas.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        'Nenhum escudo ou arma carregada.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    )
                  else ...[
                    if (p.escudoEquipado != null)
                      _LinhaCompactaEquipamento(
                        icone: Icons.shield_rounded,
                        nome:
                            '${p.escudoEquipado!.nome}${p.escudoEquipado!.ehSuperiorOuMagica ? " ✨" : ""} (Empunhado)',
                        detalhe:
                            '+${p.escudoEquipado!.bonusDefesaEfetivo} Def • Pen. -${p.escudoEquipado!.penalidadeArmaduraEfetiva.abs()}${p.escudoEquipado!.rdMelhorias > 0 ? " • RD ${p.escudoEquipado!.rdMelhorias}" : ""}',
                        espacos: p.escudoEquipado!.espacosEfetivos,
                        onConfigurarMelhorias: () =>
                            _mostrarModalMelhoriasProtecao(
                              context,
                              cubit,
                              p.escudoEquipado!,
                              ehEscudo: true,
                            ),
                        onRemover: () => cubit.equiparEscudo(null),
                      ),
                    ...List.generate(p.armas.length, (idx) {
                      final Arma a = p.armas[idx];
                      final extrasAtqDano =
                          (a.bonusAtaqueMelhorias > 0 ||
                              a.bonusDanoMelhorias > 0)
                          ? ' • +${a.bonusAtaqueMelhorias} Atq / +${a.bonusDanoMelhorias} Dano'
                          : '';
                      return _LinhaCompactaEquipamento(
                        icone: Icons.colorize_rounded,
                        nome: '${a.nome}${a.ehSuperiorOuMagica ? " ✨" : ""}',
                        detalhe:
                            'Dano ${a.danoEfetivo} (${a.criticoFormatado}) • ${a.tipoDano.label}$extrasAtqDano',
                        espacos: a.espacosEfetivos,
                        onConfigurarMelhorias: () =>
                            _mostrarModalMelhoriasArma(context, cubit, idx, a),
                        onRemover: () => cubit.removerArmaInventario(idx),
                      );
                    }),
                  ],
                ],
              ),
            ),

                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),

            // 4. MOCHILA OTIMIZADA (CABEÇALHO + SLIVERLIST VIRTUALIZADO)
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                12,
                0,
                12,
                p.itensInventario.isEmpty ? 28 : 0,
              ),
              sliver: SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: p.itensInventario.isEmpty
                        ? BorderRadius.circular(14)
                        : const BorderRadius.vertical(top: Radius.circular(14)),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 8, 8, 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Mochila (${p.itensInventario.length} itens)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            TextButton.icon(
                              key: const Key('btn_catalogo_itens_gerais'),
                              style: TextButton.styleFrom(
                                minimumSize: const Size(40, 44),
                                foregroundColor: const Color(0xFF1E293B),
                              ),
                              onPressed: () =>
                                  _abrirCatalogoItensGerais(context, cubit),
                              icon: const Icon(
                                Icons.inventory_2_outlined,
                                size: 17,
                              ),
                              label: const Text(
                                'Catálogo T20',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              key: const Key('btn_adicionar_item_mochila'),
                              style: TextButton.styleFrom(
                                minimumSize: const Size(44, 44),
                                foregroundColor: const Color(0xFFD32F2F),
                              ),
                              onPressed: () =>
                                  _adicionarOuEditarItemMochila(context, cubit),
                              icon: const Icon(Icons.add_rounded, size: 20),
                              label: const Text(
                                'Novo Item',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      if (p.itensInventario.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 22),
                          child: Center(
                            child: Text(
                              'Mochila vazia. Toque em "Novo Item" para registrar consumíveis e equipamentos.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            if (p.itensInventario.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 28),
                sliver: SliverList.builder(
                  itemCount: p.itensInventario.length,
                  itemBuilder: (context, idx) {
                    final item = p.itensInventario[idx];
                    final esp = RegrasCargaService.obterEspacoItem(item);
                    final ehUltimo = idx == p.itensInventario.length - 1;
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          left: const BorderSide(color: Color(0xFFE2E8F0)),
                          right: const BorderSide(color: Color(0xFFE2E8F0)),
                          bottom: ehUltimo
                              ? const BorderSide(color: Color(0xFFE2E8F0))
                              : BorderSide.none,
                        ),
                        borderRadius: ehUltimo
                            ? const BorderRadius.vertical(
                                bottom: Radius.circular(14),
                              )
                            : BorderRadius.zero,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => _adicionarOuEditarItemMochila(
                              context,
                              cubit,
                              index: idx,
                              valorInicial: item,
                            ),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 44),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      '${idx + 1}.',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item,
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                    ),
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
                                        '$esp esp',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF475569),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Remover $item',
                                      constraints: const BoxConstraints(
                                        minWidth: 44,
                                        minHeight: 44,
                                      ),
                                      padding: EdgeInsets.zero,
                                      onPressed: () =>
                                          cubit.removerItemMochila(idx),
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        size: 18,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (!ehUltimo)
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SlotItemVestidoCard extends StatelessWidget {
  final int numeroSlot;
  final String rotuloTipo;
  final String titulo;
  final String subtitulo;
  final int espacos;
  final bool ocupado;
  final IconData icone;
  final VoidCallback onTap;
  final VoidCallback? onConfigurarMelhorias;

  const _SlotItemVestidoCard({
    super.key,
    required this.numeroSlot,
    required this.rotuloTipo,
    required this.titulo,
    required this.subtitulo,
    required this.espacos,
    required this.ocupado,
    required this.icone,
    required this.onTap,
    this.onConfigurarMelhorias,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: ocupado ? Colors.white : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(minHeight: 54),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ocupado
                    ? const Color(0xFFD32F2F).withValues(alpha: 0.4)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: ocupado
                        ? const Color(0xFFFEF2F2)
                        : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '$numeroSlot',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: ocupado
                            ? const Color(0xFFB91C1C)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: TextStyle(
                          fontWeight: ocupado
                              ? FontWeight.w800
                              : FontWeight.w600,
                          fontSize: 13.5,
                          color: ocupado
                              ? const Color(0xFF0F172A)
                              : const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        subtitulo,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (onConfigurarMelhorias != null)
                  IconButton(
                    tooltip: 'Melhorias e Encantos',
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: onConfigurarMelhorias,
                    icon: const Icon(
                      Icons.auto_awesome_outlined,
                      size: 18,
                      color: Color(0xFFD97706),
                    ),
                  ),
                if (ocupado)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$espacos esp',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  const Icon(
                    Icons.add_circle_outline,
                    size: 20,
                    color: Color(0xFF94A3B8),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LinhaCompactaEquipamento extends StatelessWidget {
  final IconData icone;
  final String nome;
  final String detalhe;
  final int espacos;
  final VoidCallback? onConfigurarMelhorias;
  final VoidCallback onRemover;

  const _LinhaCompactaEquipamento({
    required this.icone,
    required this.nome,
    required this.detalhe,
    required this.espacos,
    this.onConfigurarMelhorias,
    required this.onRemover,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icone, size: 17, color: const Color(0xFF475569)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  detalhe,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          if (onConfigurarMelhorias != null)
            IconButton(
              tooltip: 'Melhorias e Encantos',
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: EdgeInsets.zero,
              onPressed: onConfigurarMelhorias,
              icon: const Icon(
                Icons.auto_awesome_outlined,
                size: 18,
                color: Color(0xFFD97706),
              ),
            ),
          Text(
            '$espacos esp',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
            ),
          ),
          IconButton(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            onPressed: onRemover,
            icon: const Icon(Icons.close, size: 18, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}

class _DialogoCarteiraMoeda extends StatefulWidget {
  final String titulo;
  final int valorAtual;

  const _DialogoCarteiraMoeda({
    required this.titulo,
    required this.valorAtual,
  });

  @override
  State<_DialogoCarteiraMoeda> createState() => _DialogoCarteiraMoedaState();
}

class _DialogoCarteiraMoedaState extends State<_DialogoCarteiraMoeda> {
  late int _saldo;
  late final TextEditingController _deltaCtrl;

  @override
  void initState() {
    super.initState();
    _saldo = widget.valorAtual;
    _deltaCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _deltaCtrl.dispose();
    super.dispose();
  }

  void _somar(int delta) {
    setState(() {
      _saldo = (_saldo + delta).clamp(0, 9999999);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titulo, style: const TextStyle(fontSize: 17)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$_saldo',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [-10, -1, 1, 10, 100].map((d) {
              return ActionChip(
                label: Text(d > 0 ? '+$d' : '$d'),
                onPressed: () => _somar(d),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _deltaCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Ou definir valor exato',
              border: OutlineInputBorder(),
            ),
            onChanged: (txt) {
              final v = int.tryParse(txt);
              if (v != null && v >= 0) {
                setState(() => _saldo = v);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCELAR'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD32F2F),
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.pop(context, _saldo),
          child: const Text('CONFIRMAR'),
        ),
      ],
    );
  }
}

class _DialogoSlotVestidoExtra extends StatefulWidget {
  final int numeroSlotVisual;
  final ItemVestido? existente;
  final ValueChanged<ItemVestido> onSalvar;
  final VoidCallback onRemover;

  const _DialogoSlotVestidoExtra({
    required this.numeroSlotVisual,
    this.existente,
    required this.onSalvar,
    required this.onRemover,
  });

  @override
  State<_DialogoSlotVestidoExtra> createState() =>
      _DialogoSlotVestidoExtraState();
}

class _DialogoSlotVestidoExtraState extends State<_DialogoSlotVestidoExtra> {
  late final TextEditingController _nomeCtrl;
  late final TextEditingController _beneficioCtrl;
  late int _espacos;

  @override
  void initState() {
    super.initState();
    _nomeCtrl = TextEditingController(text: widget.existente?.nome ?? '');
    _beneficioCtrl = TextEditingController(
      text: widget.existente?.beneficio ?? '',
    );
    _espacos = widget.existente?.espacos ?? 1;
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _beneficioCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Slot ${widget.numeroSlotVisual} — Item Vestido'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nomeCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nome do item vestido',
                hintText: 'Ex: Manto do Carisma, Botas Velozes...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _beneficioCtrl,
              decoration: const InputDecoration(
                labelText: 'Benefício / Efeito',
                hintText: 'Ex: +1 em Diplomacia, +3m deslocamento',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Espaços ocupados:',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                DropdownButton<int>(
                  value: _espacos,
                  items: [0, 1, 2, 3, 4, 5]
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text('$e ${e == 1 ? "espaço" : "espaços"}'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _espacos = v);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        if (widget.existente != null)
          TextButton(
            onPressed: () {
              widget.onRemover();
              Navigator.pop(context);
            },
            child: const Text(
              'DESEQUIPAR',
              style: TextStyle(color: Colors.red),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCELAR'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD32F2F),
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            widget.onSalvar(
              ItemVestido(
                slotIndex: widget.numeroSlotVisual - 1,
                nome: _nomeCtrl.text.trim(),
                beneficio: _beneficioCtrl.text.trim(),
                espacos: _espacos,
              ),
            );
            Navigator.pop(context);
          },
          child: const Text('SALVAR'),
        ),
      ],
    );
  }
}
