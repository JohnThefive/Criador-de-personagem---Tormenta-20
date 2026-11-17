import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/entities/combate/monstro.dart';
import '../../../../domain/entities/equipamento/arma.dart';
import '../../../../domain/services/combate_services/dice_roll_service.dart';
import '../../../../domain/services/data_services/call_ameacas.dart';
import '../../../controllers/mestre_controller/mestre_cubit.dart';
import '../../../controllers/mestre_controller/mestre_state.dart';

/// Aba/Tela do Bestiário para o Painel do Mestre e Mesa de Jogo.
/// Permite buscar e filtrar ameaças por região, papel e texto, inspecionar
/// a ficha rápida e posicionar instâncias vinculadas no mapa ativo.
class TelaBestiarioMestre extends StatefulWidget {
  final MestreCubit cubit;
  final ValueChanged<Monstro>? onAmeacaAdicionada;
  final bool autoCarregar;

  const TelaBestiarioMestre({
    super.key,
    required this.cubit,
    this.onAmeacaAdicionada,
    this.autoCarregar = true,
  });

  @override
  State<TelaBestiarioMestre> createState() => _TelaBestiarioMestreState();
}

class _TelaBestiarioMestreState extends State<TelaBestiarioMestre> {
  final TextEditingController _buscaController = TextEditingController();
  String _busca = '';
  PapelMonstro? _papelFiltro;
  String? _regiaoFiltro;
  bool _apenasCustomizadas = false;
  bool _carregando = false;
  String? _carregandoId;

  @override
  void initState() {
    super.initState();
    if (widget.autoCarregar && !BancoDeAmeacas.indiceCarregado) {
      _carregarIndice();
    }
  }

  @override
  void didUpdateWidget(covariant TelaBestiarioMestre oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoCarregar &&
        !oldWidget.autoCarregar &&
        !BancoDeAmeacas.indiceCarregado &&
        !_carregando) {
      _carregarIndice();
    }
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _carregarIndice() async {
    setState(() => _carregando = true);
    await BancoDeAmeacas.carregar();
    if (mounted) {
      setState(() => _carregando = false);
    }
  }

  String _formatarRegiao(String regiao) {
    final limpo = regiao.replaceAll('_', ' ').trim();
    if (limpo.isEmpty) return 'Geral';
    return limpo[0].toUpperCase() + limpo.substring(1);
  }

  Future<void> _abrirEditorAmeaca({
    Monstro? base,
    bool duplicar = false,
  }) async {
    final temaAtual = Theme.of(context);
    final salvo = await showModalBottomSheet<Monstro>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: temaAtual.colorScheme.surface,
      builder: (ctx) => Theme(
        data: temaAtual,
        child: _EditorAmeacaSheet(
          base: base,
          duplicar: duplicar,
          onSalvar: widget.cubit.salvarAmeacaCustomizada,
        ),
      ),
    );
    if (salvo != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ameaça "${salvo.nome}" salva no bestiário.')),
      );
    }
  }

  Future<void> _abrirDetalhes(AmeacaResumo resumo) async {
    setState(() => _carregandoId = resumo.id);
    final monstro = await BancoDeAmeacas.getByIdAsync(resumo.id);
    if (!mounted) return;
    setState(() => _carregandoId = null);

    if (monstro == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível carregar "${resumo.nome}".'),
        ),
      );
      return;
    }

    int quantidade = 1;
    bool visivelParaJogadores = false;

    final temaAtual = Theme.of(context);
    final acaoPosFechar = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: temaAtual.colorScheme.surface,
      builder: (ctx) {
        return Theme(
          data: temaAtual,
          child: StatefulBuilder(
            builder: (ctx, setModalState) {
              final colorScheme = Theme.of(ctx).colorScheme;
              return BlocSelector<MestreCubit, MestreState, String?>(
                bloc: widget.cubit,
                selector: (s) => s.mapaAtual?.nome,
                builder: (ctx, nomeMapa) {
                  return DraggableScrollableSheet(
                    expand: false,
                    initialChildSize: 0.72,
                    minChildSize: 0.45,
                    maxChildSize: 0.92,
                    builder: (ctx, scrollController) {
                      return Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              controller: scrollController,
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor:
                                            colorScheme.primaryContainer,
                                        child: Text(
                                          monstro.nd,
                                          style: TextStyle(
                                            color:
                                                colorScheme.onPrimaryContainer,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              monstro.nome,
                                              style: Theme.of(ctx)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            Text(
                                              'ND ${monstro.nd} • ${monstro.papel.label} • ${monstro.tipoCriatura} (${monstro.tamanho})${monstro.customizado ? " • Customizada" : ""}',
                                              style: Theme.of(ctx)
                                                  .textTheme
                                                  .bodySmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      OutlinedButton.icon(
                                        icon: const Icon(
                                          Icons.copy_outlined,
                                          size: 18,
                                        ),
                                        label: const Text('Duplicar e Editar'),
                                        onPressed: () =>
                                            Navigator.pop(ctx, 'duplicar'),
                                      ),
                                      if (monstro.customizado) ...[
                                        OutlinedButton.icon(
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                            size: 18,
                                          ),
                                          label: const Text('Editar'),
                                          onPressed: () =>
                                              Navigator.pop(ctx, 'editar'),
                                        ),
                                        OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: colorScheme.error,
                                          ),
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            size: 18,
                                          ),
                                          label: const Text('Excluir'),
                                          onPressed: () =>
                                              Navigator.pop(ctx, 'excluir'),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  FichaRapidaMonstroCard(monstro: monstro),
                                const SizedBox(height: 8),
                                SwitchListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text(
                                    'Visível aos jogadores ao posicionar',
                                  ),
                                  value: visivelParaJogadores,
                                  onChanged: (v) => setModalState(
                                    () => visivelParaJogadores = v,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Quantidade no mapa:'),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove),
                                          onPressed: quantidade > 1
                                              ? () => setModalState(
                                                    () => quantidade--,
                                                  )
                                              : null,
                                        ),
                                        Text(
                                          '$quantidade',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add),
                                          onPressed: quantidade < 8
                                              ? () => setModalState(
                                                    () => quantidade++,
                                                  )
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                              ),
                            ),
                          ),
                          SafeArea(
                            top: false,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                ),
                                icon: const Icon(
                                  Icons.add_location_alt_outlined,
                                ),
                                label: Text(
                                  nomeMapa == null
                                      ? 'Nenhum mapa ativo selecionado'
                                      : 'Colocar em "$nomeMapa" ($quantidade×)',
                                ),
                                onPressed: nomeMapa == null
                                    ? null
                                    : () {
                                        widget.cubit.adicionarAmeacaNoMapa(
                                          monstro,
                                          ocultoParaJogadores:
                                              !visivelParaJogadores,
                                          quantidade: quantidade,
                                        );
                                        Navigator.pop(ctx);
                                        widget.onAmeacaAdicionada?.call(
                                          monstro,
                                        );
                                        if (widget.onAmeacaAdicionada == null &&
                                            mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                '${quantidade}x ${monstro.nome} adicionado em "$nomeMapa".',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );

    if (!mounted || acaoPosFechar == null) return;
    if (acaoPosFechar == 'duplicar') {
      await _abrirEditorAmeaca(base: monstro, duplicar: true);
    } else if (acaoPosFechar == 'editar') {
      await _abrirEditorAmeaca(base: monstro, duplicar: false);
    } else if (acaoPosFechar == 'excluir') {
      widget.cubit.excluirAmeacaCustomizada(monstro.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ameaça "${monstro.nome}" removida.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<MestreCubit, MestreState, int>(
      bloc: widget.cubit,
      selector: (s) => s.revisaoBestiario,
      builder: (context, _) {
        final colorScheme = Theme.of(context).colorScheme;
        var resumos = BancoDeAmeacas.filtrarResumos(
          busca: _busca,
          papel: _papelFiltro,
          regiao: _regiaoFiltro,
        );
        if (_apenasCustomizadas) {
          resumos = resumos.where((r) => r.customizado).toList();
        }
        final regioes = BancoDeAmeacas.regioes;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _buscaController,
                          decoration: InputDecoration(
                            hintText: 'Buscar ameaça por nome, ND ou tipo...',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHigh,
                            suffixIcon: _busca.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _buscaController.clear();
                                      setState(() => _busca = '');
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            isDense: true,
                          ),
                          onChanged: (v) => setState(() => _busca = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonalIcon(
                        onPressed: () => _abrirEditorAmeaca(),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Nova Ameaça'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (regioes.isNotEmpty) ...[
                          DropdownButtonHideUnderline(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: DropdownButton<String?>(
                                value: _regiaoFiltro,
                                isDense: true,
                                dropdownColor: colorScheme.surfaceContainerHigh,
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                  fontSize: 13,
                                ),
                                hint: const Text('Todas Regiões'),
                                items: [
                                  const DropdownMenuItem<String?>(
                                    value: null,
                                    child: Text('Todas Regiões'),
                                  ),
                                  ...regioes.map(
                                    (r) => DropdownMenuItem<String?>(
                                      value: r,
                                      child: Text(_formatarRegiao(r)),
                                    ),
                                  ),
                                ],
                                onChanged: (v) =>
                                    setState(() => _regiaoFiltro = v),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        FilterChip(
                          label: const Text('Customizadas'),
                          selected: _apenasCustomizadas,
                          onSelected: (sel) =>
                              setState(() => _apenasCustomizadas = sel),
                        ),
                        const SizedBox(width: 6),
                        FilterChip(
                          label: const Text('Todos Papéis'),
                          selected: _papelFiltro == null,
                          onSelected: (_) =>
                              setState(() => _papelFiltro = null),
                        ),
                        const SizedBox(width: 6),
                        ...PapelMonstro.values.map((papel) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: FilterChip(
                              label: Text(papel.label),
                              selected: _papelFiltro == papel,
                              onSelected: (sel) => setState(
                                () => _papelFiltro = sel ? papel : null,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _carregando
                  ? const Center(child: CircularProgressIndicator())
                  : resumos.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Nenhuma ameaça encontrada para os filtros aplicados.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: resumos.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final r = resumos[index];
                            final carregandoEste = _carregandoId == r.id;
                            return Card(
                              margin: EdgeInsets.zero,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      colorScheme.primaryContainer,
                                  child: Text(
                                    r.nd,
                                    style: TextStyle(
                                      color: colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  r.nome,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  'ND ${r.nd} • ${r.papel.label} • ${r.tipoCriatura}${r.regiao.isNotEmpty ? " • ${_formatarRegiao(r.regiao)}" : ""}${r.customizado ? " • Customizada" : ""}',
                                ),
                                trailing: carregandoEste
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.add_circle_outline),
                                onTap: carregandoEste
                                    ? null
                                    : () => _abrirDetalhes(r),
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

/// Resumo tático completo da ficha de combate de um [Monstro] para o Mestre,
/// com rolagem direta de testes/ataques e controle de recarga de habilidades.
class FichaRapidaMonstroCard extends StatefulWidget {
  final Monstro monstro;
  final List<String> habilidadesRecargaGastas;
  final ValueChanged<String>? onAlternarRecarga;
  final Random? random;

  const FichaRapidaMonstroCard({
    super.key,
    required this.monstro,
    this.habilidadesRecargaGastas = const [],
    this.onAlternarRecarga,
    this.random,
  });

  @override
  State<FichaRapidaMonstroCard> createState() =>
      _FichaRapidaMonstroCardState();
}

class _FichaRapidaMonstroCardState extends State<FichaRapidaMonstroCard> {
  TipoVantagem _vantagem = TipoVantagem.normal;
  String? _ultimaRolagemTitulo;
  String? _ultimaRolagemValor;
  String? _ultimaRolagemDetalhe;
  final Set<String> _recargasLocaisGastas = {};

  String _fmtMod(int mod) => mod >= 0 ? '+$mod' : '$mod';

  DiceRollService get _dice => DiceRollService(random: widget.random);

  void _rolarTeste(String titulo, int modificador) {
    final res = _dice.rolarD20(
      modificador: modificador,
      nomeModificador: titulo,
      vantagem: _vantagem,
    );
    final marcador = res.ehVinteNatural
        ? ' • 20 NAT!'
        : (res.ehUmNatural ? ' • 1 NAT!' : '');
    setState(() {
      _ultimaRolagemTitulo = titulo;
      _ultimaRolagemValor = '${res.total}$marcador';
      _ultimaRolagemDetalhe = res.decomposicao;
    });
  }

  void _rolarAtaque(AtaqueMonstro a) {
    final res = _dice.rolarD20(
      modificador: a.bonusAtaque,
      nomeModificador: a.nome,
      vantagem: _vantagem,
    );
    final ehCritico = !res.ehUmNatural && res.d20 >= a.margemAmeaca;
    final dano = _dice.rolarDano(
      expressaoDano: a.dano,
      dadoExtra: a.danoExtra,
      ehCritico: ehCritico,
      multiplicadorCritico: a.multiplicadorCritico,
    );
    final tag = res.ehUmNatural
        ? ' • FALHA CRÍTICA'
        : (ehCritico ? ' • CRÍTICO ×${a.multiplicadorCritico}!' : '');
    setState(() {
      _ultimaRolagemTitulo = a.nome;
      _ultimaRolagemValor = 'Atq ${res.total} • Dano ${dano.total}$tag';
      _ultimaRolagemDetalhe = '${res.decomposicao} | ${dano.decomposicao}';
    });
  }

  bool _habilidadeGasta(String nome) {
    if (widget.onAlternarRecarga != null) {
      return widget.habilidadesRecargaGastas.contains(nome);
    }
    return _recargasLocaisGastas.contains(nome);
  }

  void _alternarRecarga(String nome) {
    if (widget.onAlternarRecarga != null) {
      widget.onAlternarRecarga!(nome);
      return;
    }
    setState(() {
      if (!_recargasLocaisGastas.remove(nome)) {
        _recargasLocaisGastas.add(nome);
      }
    });
  }

  String _formatarDeslocamentos(Monstro m) {
    if (m.deslocamentos.isEmpty) return '${m.deslocamentoMetros}m';
    final partes = m.deslocamentos.entries
        .map((e) => e.key.toLowerCase() == 'terrestre'
            ? '${e.value}m'
            : '${e.key} ${e.value}m')
        .toList();
    return partes.join(', ');
  }

  Widget _chipRolavel(
    BuildContext context, {
    required String texto,
    required VoidCallback onTap,
    TextStyle? style,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: cs.surface.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.casino_outlined, size: 12, color: cs.primary),
            const SizedBox(width: 4),
            Text(texto, style: style),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.monstro;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final rdTexto = m.rd.entries.map((e) => '${e.key} ${e.value}').join(', ');
    final subtipoTexto =
        m.subtipo != null && m.subtipo!.trim().isNotEmpty ? ' (${m.subtipo})' : '';
    final atributos = <(String, int?, bool)>[
      ('FOR', m.modForca, m.forcaNula),
      ('DES', m.modDestreza, m.destrezaNula),
      ('CON', m.modConstituicao, m.constituicaoNula),
      ('INT', m.modInteligencia, m.modInteligencia == null),
      ('SAB', m.modSabedoria, m.modSabedoria == null),
      ('CAR', m.modCarisma, m.modCarisma == null),
    ];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${m.tipoCriatura}$subtipoTexto • ${m.tamanho} • ND ${m.nd}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('PV ${m.pvMax}', style: const TextStyle(fontWeight: FontWeight.bold)),
              if (m.possuiPm)
                Text('PM ${m.pmMax}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Defesa ${m.defesa}'),
              _chipRolavel(
                context,
                texto: 'Inic ${_fmtMod(m.iniciativa)}',
                style: theme.textTheme.bodySmall,
                onTap: () => _rolarTeste('Iniciativa', m.iniciativa),
              ),
              _chipRolavel(
                context,
                texto: 'Perc ${_fmtMod(m.percepcao)}',
                style: theme.textTheme.bodySmall,
                onTap: () => _rolarTeste('Percepção', m.percepcao),
              ),
              Text('Desl ${_formatarDeslocamentos(m)}'),
            ],
          ),
          const SizedBox(height: 6),
          // Modo de rolagem rápida (Normal / Vantagem / Desvantagem)
          Wrap(
            spacing: 4,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Rolagem:',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              for (final modo in [
                (TipoVantagem.normal, 'Normal'),
                (TipoVantagem.vantagem, 'Vant'),
                (TipoVantagem.desvantagem, 'Desv'),
              ])
                ChoiceChip(
                  label: Text(modo.$2, style: const TextStyle(fontSize: 10)),
                  selected: _vantagem == modo.$1,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.zero,
                  onSelected: (_) => setState(() => _vantagem = modo.$1),
                ),
            ],
          ),
          if (_ultimaRolagemTitulo != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_ultimaRolagemTitulo: $_ultimaRolagemValor',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        if (_ultimaRolagemDetalhe != null)
                          Text(
                            _ultimaRolagemDetalhe!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 14),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Limpar rolagem',
                    onPressed: () => setState(() {
                      _ultimaRolagemTitulo = null;
                      _ultimaRolagemValor = null;
                      _ultimaRolagemDetalhe = null;
                    }),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 6),
          // Testes de resistência roláveis
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _chipRolavel(
                context,
                texto: 'Fort ${_fmtMod(m.fortitude)}',
                style: theme.textTheme.bodySmall,
                onTap: () => _rolarTeste('Fortitude', m.fortitude),
              ),
              _chipRolavel(
                context,
                texto: 'Ref ${_fmtMod(m.reflexos)}',
                style: theme.textTheme.bodySmall,
                onTap: () => _rolarTeste('Reflexos', m.reflexos),
              ),
              _chipRolavel(
                context,
                texto: 'Von ${_fmtMod(m.vontade)}',
                style: theme.textTheme.bodySmall,
                onTap: () => _rolarTeste('Vontade', m.vontade),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Atributos (com suporte a "–" quando nulo)
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: atributos.map((attr) {
              final label = attr.$1;
              final val = attr.$2;
              final ehNulo = attr.$3 || val == null;
              if (ehNulo) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Text(
                    '$label –',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }
              return _chipRolavel(
                context,
                texto: '$label ${_fmtMod(val)}',
                style: theme.textTheme.bodySmall,
                onTap: () => _rolarTeste(label, val),
              );
            }).toList(),
          ),
          if (m.sentidos.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Sentidos: ${m.sentidos.join(", ")}',
              style: theme.textTheme.bodySmall,
            ),
          ],
          if (m.pericias.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: m.pericias.entries
                  .map(
                    (p) => _chipRolavel(
                      context,
                      texto: '${p.key} ${_fmtMod(p.value)}',
                      style: theme.textTheme.bodySmall,
                      onTap: () => _rolarTeste(p.key, p.value),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (rdTexto.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('RD: $rdTexto', style: theme.textTheme.bodySmall),
          ],
          if (m.imunidadesEfeitos.isNotEmpty || m.imunidadesDano.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'Imunidades: ${[...m.imunidadesDano, ...m.imunidadesEfeitos].join(", ")}',
              style: theme.textTheme.bodySmall,
            ),
          ],
          if (m.vulnerabilidadesDano.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'Vulnerabilidades: ${m.vulnerabilidadesDano.join(", ")}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.error,
              ),
            ),
          ],
          if (m.habilidadesDefensivas.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'Defesas especiais: ${m.habilidadesDefensivas.join(", ")}',
              style: theme.textTheme.bodySmall,
            ),
          ],
          if (m.ataques.isNotEmpty) ...[
            const Divider(height: 14),
            Text(
              'Ataques (toque para rolar)',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            ...m.ataques.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => _rolarAtaque(a),
                  child: Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.7),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.casino_outlined,
                          size: 14,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '• ${a.nome} (${_fmtMod(a.bonusAtaque)}, ${a.dano}${a.danoExtra != null ? " + ${a.danoExtra}" : ""}, ${a.margemAmeaca}/×${a.multiplicadorCritico})${a.alcance.isNotEmpty && a.alcance.toLowerCase() != "corpo a corpo" ? " [${a.alcance}]" : ""}${a.descricaoEfeito != null ? " — ${a.descricaoEfeito}" : ""}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (m.habilidades.isNotEmpty) ...[
            const Divider(height: 14),
            Text(
              'Habilidades',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            ...m.habilidades.map((h) {
              final gasta = h.possuiRecarga && _habilidadeGasta(h.nome);
              final cdTxt = h.cdResistencia != null
                  ? ', CD ${h.cdResistencia}${h.resistenciaTipo != null ? " ${h.resistenciaTipo}" : ""}'
                  : '';
              return Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '• ${h.nome} (${h.acao}${h.custoPm > 0 ? ", ${h.custoPm} PM" : ""}${h.possuiRecarga ? ", recarga ${h.recarga}" : ""}$cdTxt): ${h.descricao}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          decoration:
                              gasta ? TextDecoration.lineThrough : null,
                          color: gasta
                              ? colorScheme.onSurfaceVariant
                              : null,
                        ),
                      ),
                    ),
                    if (h.possuiRecarga) ...[
                      const SizedBox(width: 6),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _alternarRecarga(h.nome),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: gasta
                                ? colorScheme.errorContainer.withValues(
                                    alpha: 0.7,
                                  )
                                : colorScheme.primaryContainer.withValues(
                                    alpha: 0.65,
                                  ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: gasta
                                  ? colorScheme.error
                                  : colorScheme.primary,
                            ),
                          ),
                          child: Text(
                            gasta ? 'Gasta' : 'Pronta',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: gasta
                                  ? colorScheme.onErrorContainer
                                  : colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
          if (m.equipamento.isNotEmpty ||
              m.tesouro.trim().isNotEmpty ||
              m.recursoExtraivel != null) ...[
            const Divider(height: 14),
            if (m.equipamento.isNotEmpty)
              Text(
                'Equipamento: ${m.equipamento.join(", ")}',
                style: theme.textTheme.bodySmall,
              ),
            if (m.tesouro.trim().isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                'Tesouro: ${m.tesouro}',
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (m.recursoExtraivel != null) ...[
              const SizedBox(height: 2),
              Text(
                'Extração: ${m.recursoExtraivel!.nome} (${m.recursoExtraivel!.pericia} CD ${m.recursoExtraivel!.cdBase})',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _AtaqueDraft {
  final TextEditingController nome;
  final TextEditingController bonus;
  final TextEditingController dano;
  final TextEditingController alcance;
  final TextEditingController efeito;
  final AtaqueMonstro? original;

  _AtaqueDraft({AtaqueMonstro? base})
      : original = base,
        nome = TextEditingController(text: base?.nome ?? 'Golpe'),
        bonus = TextEditingController(text: '${base?.bonusAtaque ?? 6}'),
        dano = TextEditingController(text: base?.dano ?? '1d8+3'),
        alcance = TextEditingController(text: base?.alcance ?? 'Corpo a corpo'),
        efeito = TextEditingController(text: base?.descricaoEfeito ?? '');

  AtaqueMonstro toAtaque() => AtaqueMonstro(
        nome: nome.text.trim().isEmpty ? 'Ataque' : nome.text.trim(),
        bonusAtaque: int.tryParse(bonus.text.trim()) ?? 0,
        dano: dano.text.trim().isEmpty ? '1d6' : dano.text.trim(),
        danoExtra: original?.danoExtra,
        margemAmeaca: original?.margemAmeaca ?? 20,
        multiplicadorCritico: original?.multiplicadorCritico ?? 2,
        tipoDano: original?.tipoDano ?? TipoDanoArma.impacto,
        tipoDanoBruto: original?.tipoDanoBruto,
        alcance: alcance.text.trim().isEmpty
            ? 'Corpo a corpo'
            : alcance.text.trim(),
        acao: original?.acao ?? 'padrao',
        custoPm: original?.custoPm ?? 0,
        descricaoEfeito:
            efeito.text.trim().isEmpty ? null : efeito.text.trim(),
      );

  void dispose() {
    nome.dispose();
    bonus.dispose();
    dano.dispose();
    alcance.dispose();
    efeito.dispose();
  }
}

class _HabilidadeDraft {
  final TextEditingController nome;
  final TextEditingController acao;
  final TextEditingController custoPm;
  final TextEditingController recarga;
  final TextEditingController descricao;
  final HabilidadeMonstro? original;

  _HabilidadeDraft({HabilidadeMonstro? base})
      : original = base,
        nome = TextEditingController(text: base?.nome ?? 'Nova Habilidade'),
        acao = TextEditingController(text: base?.acao ?? 'passiva'),
        custoPm = TextEditingController(text: '${base?.custoPm ?? 0}'),
        recarga = TextEditingController(text: base?.recarga ?? ''),
        descricao = TextEditingController(text: base?.descricao ?? '');

  HabilidadeMonstro toHabilidade() => HabilidadeMonstro(
        nome: nome.text.trim().isEmpty ? 'Habilidade' : nome.text.trim(),
        acao: acao.text.trim().isEmpty ? 'passiva' : acao.text.trim(),
        custoPm: int.tryParse(custoPm.text.trim()) ?? 0,
        recarga: recarga.text.trim().isEmpty ? null : recarga.text.trim(),
        cdResistencia: original?.cdResistencia,
        resistenciaTipo: original?.resistenciaTipo,
        descricao: descricao.text.trim(),
      );

  void dispose() {
    nome.dispose();
    acao.dispose();
    custoPm.dispose();
    recarga.dispose();
    descricao.dispose();
  }
}

class _EditorAmeacaSheet extends StatefulWidget {
  final Monstro? base;
  final bool duplicar;
  final Monstro Function(Monstro) onSalvar;

  const _EditorAmeacaSheet({
    this.base,
    required this.duplicar,
    required this.onSalvar,
  });

  @override
  State<_EditorAmeacaSheet> createState() => _EditorAmeacaSheetState();
}

class _EditorAmeacaSheetState extends State<_EditorAmeacaSheet> {
  static const List<String> _tamanhos = [
    'Minúsculo',
    'Pequeno',
    'Médio',
    'Grande',
    'Enorme',
    'Colossal',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeCtrl;
  late final TextEditingController _ndCtrl;
  late final TextEditingController _tipoCtrl;
  late final TextEditingController _regiaoCtrl;
  late final TextEditingController _pvCtrl;
  late final TextEditingController _pmCtrl;
  late final TextEditingController _defesaCtrl;
  late final TextEditingController _deslocCtrl;
  late final TextEditingController _inicCtrl;
  late final TextEditingController _percCtrl;
  late final TextEditingController _fortCtrl;
  late final TextEditingController _refCtrl;
  late final TextEditingController _vonCtrl;
  late PapelMonstro _papel;
  late String _tamanho;
  late final List<_AtaqueDraft> _ataques;
  late final List<_HabilidadeDraft> _habilidades;

  @override
  void initState() {
    super.initState();
    final b = widget.base;
    final nomeInicial = b == null
        ? ''
        : (widget.duplicar ? '${b.nome} (Custom)' : b.nome);
    _nomeCtrl = TextEditingController(text: nomeInicial);
    _ndCtrl = TextEditingController(text: b?.nd ?? '1');
    _tipoCtrl = TextEditingController(text: b?.tipoCriatura ?? 'Monstro');
    _regiaoCtrl = TextEditingController(text: b?.regiao ?? '');
    _pvCtrl = TextEditingController(text: '${b?.pvMax ?? 20}');
    _pmCtrl = TextEditingController(text: '${b?.pmMax ?? 0}');
    _defesaCtrl = TextEditingController(text: '${b?.defesa ?? 14}');
    _deslocCtrl = TextEditingController(
      text: '${(b?.deslocamentoMetros ?? 9.0).round()}',
    );
    _inicCtrl = TextEditingController(text: '${b?.iniciativa ?? 2}');
    _percCtrl = TextEditingController(text: '${b?.percepcao ?? 2}');
    _fortCtrl = TextEditingController(text: '${b?.fortitude ?? 2}');
    _refCtrl = TextEditingController(text: '${b?.reflexos ?? 2}');
    _vonCtrl = TextEditingController(text: '${b?.vontade ?? 0}');
    _papel = b?.papel ?? PapelMonstro.padrao;
    _tamanho = _tamanhos.contains(b?.tamanho) ? b!.tamanho : 'Médio';
    _ataques = b != null && b.ataques.isNotEmpty
        ? b.ataques.map((a) => _AtaqueDraft(base: a)).toList()
        : (b == null ? [_AtaqueDraft()] : <_AtaqueDraft>[]);
    _habilidades = b != null
        ? b.habilidades.map((h) => _HabilidadeDraft(base: h)).toList()
        : <_HabilidadeDraft>[];
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _ndCtrl.dispose();
    _tipoCtrl.dispose();
    _regiaoCtrl.dispose();
    _pvCtrl.dispose();
    _pmCtrl.dispose();
    _defesaCtrl.dispose();
    _deslocCtrl.dispose();
    _inicCtrl.dispose();
    _percCtrl.dispose();
    _fortCtrl.dispose();
    _refCtrl.dispose();
    _vonCtrl.dispose();
    for (final a in _ataques) {
      a.dispose();
    }
    for (final h in _habilidades) {
      h.dispose();
    }
    super.dispose();
  }

  int _parseInt(TextEditingController c, {int fallback = 0}) =>
      int.tryParse(c.text.trim()) ?? fallback;

  void _salvar() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final b = widget.base;
    final idFinal = (b != null && !widget.duplicar) ? b.id : '';
    final pv = _parseInt(_pvCtrl, fallback: 20).clamp(1, 9999);
    final pm = _parseInt(_pmCtrl, fallback: 0).clamp(0, 9999);
    final defesa = _parseInt(_defesaCtrl, fallback: 14).clamp(1, 99);
    final desloc =
        double.tryParse(_deslocCtrl.text.trim())?.clamp(0.0, 90.0) ?? 9.0;

    final nova = Monstro(
      id: idFinal,
      nome: _nomeCtrl.text.trim(),
      nd: _ndCtrl.text.trim().isEmpty ? '1' : _ndCtrl.text.trim(),
      regiao: _regiaoCtrl.text.trim(),
      papel: _papel,
      tipoCriatura:
          _tipoCtrl.text.trim().isEmpty ? 'Monstro' : _tipoCtrl.text.trim(),
      subtipo: b?.subtipo,
      tamanho: _tamanho,
      pvMax: pv,
      pmMax: pm,
      defesa: defesa,
      deslocamentoMetros: desloc,
      deslocamentos: b?.deslocamentos ?? const {},
      iniciativa: _parseInt(_inicCtrl),
      percepcao: _parseInt(_percCtrl),
      sentidos: b?.sentidos ?? const [],
      fortitude: _parseInt(_fortCtrl),
      reflexos: _parseInt(_refCtrl),
      vontade: _parseInt(_vonCtrl),
      rd: b?.rd ?? const {},
      imunidadesEfeitos: b?.imunidadesEfeitos ?? const [],
      imunidadesDano: b?.imunidadesDano ?? const [],
      vulnerabilidadesDano: b?.vulnerabilidadesDano ?? const [],
      habilidadesDefensivas: b?.habilidadesDefensivas ?? const [],
      modForca: b?.modForca ?? 0,
      modDestreza: b?.modDestreza ?? 0,
      modConstituicao: b?.modConstituicao ?? 0,
      modInteligencia: b?.modInteligencia,
      modSabedoria: b?.modSabedoria,
      modCarisma: b?.modCarisma,
      forcaNula: b?.forcaNula ?? false,
      destrezaNula: b?.destrezaNula ?? false,
      constituicaoNula: b?.constituicaoNula ?? false,
      pericias: b?.pericias ?? const {},
      ataques: _ataques.map((a) => a.toAtaque()).toList(),
      habilidades: _habilidades.map((h) => h.toHabilidade()).toList(),
      equipamento: b?.equipamento ?? const [],
      tesouro: b?.tesouro ?? 'padrao',
      recursoExtraivel: b?.recursoExtraivel,
      customizado: true,
    );

    final salva = widget.onSalvar(nova);
    Navigator.pop(context, salva);
  }

  InputDecoration _dec(BuildContext context, String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        isDense: true,
      );

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final titulo = widget.base == null
        ? 'Nova Ameaça Customizada'
        : (widget.duplicar ? 'Duplicar e Editar Ameaça' : 'Editar Ameaça');

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Form(
            key: _formKey,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          titulo,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    children: [
                      TextFormField(
                        key: const ValueKey('editor_ameaca_nome'),
                        controller: _nomeCtrl,
                        decoration: _dec(context, 'Nome da Ameaça'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Informe o nome'
                            : null,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              key: const ValueKey('editor_ameaca_nd'),
                              controller: _ndCtrl,
                              decoration: _dec(context, 'ND'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<PapelMonstro>(
                              initialValue: _papel,
                              dropdownColor: colorScheme.surfaceContainerHigh,
                              decoration: _dec(context, 'Papel'),
                              items: PapelMonstro.values
                                  .map(
                                    (p) => DropdownMenuItem(
                                      value: p,
                                      child: Text(p.label),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _papel = v);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              initialValue: _tamanho,
                              dropdownColor: colorScheme.surfaceContainerHigh,
                              decoration: _dec(context, 'Tamanho'),
                              items: _tamanhos
                                  .map(
                                    (t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(t),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _tamanho = v);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _tipoCtrl,
                              decoration: _dec(context, 'Tipo de Criatura'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _regiaoCtrl,
                              decoration: _dec(context, 'Região (opcional)'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Combate & Defesas',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              key: const ValueKey('editor_ameaca_pv'),
                              controller: _pvCtrl,
                              keyboardType: TextInputType.number,
                              decoration: _dec(context, 'PV Máx'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              key: const ValueKey('editor_ameaca_pm'),
                              controller: _pmCtrl,
                              keyboardType: TextInputType.number,
                              decoration: _dec(context, 'PM Máx'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              key: const ValueKey('editor_ameaca_defesa'),
                              controller: _defesaCtrl,
                              keyboardType: TextInputType.number,
                              decoration: _dec(context, 'Defesa'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _deslocCtrl,
                              keyboardType: TextInputType.number,
                              decoration: _dec(context, 'Desl. (m)'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _inicCtrl,
                              keyboardType: TextInputType.number,
                              decoration: _dec(context, 'Inic.'),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TextFormField(
                              controller: _percCtrl,
                              keyboardType: TextInputType.number,
                              decoration: _dec(context, 'Perc.'),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TextFormField(
                              controller: _fortCtrl,
                              keyboardType: TextInputType.number,
                              decoration: _dec(context, 'Fort'),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TextFormField(
                              controller: _refCtrl,
                              keyboardType: TextInputType.number,
                              decoration: _dec(context, 'Ref'),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TextFormField(
                              controller: _vonCtrl,
                              keyboardType: TextInputType.number,
                              decoration: _dec(context, 'Von'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Ataques (${_ataques.length})',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          TextButton.icon(
                            onPressed: () =>
                                setState(() => _ataques.add(_AtaqueDraft())),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Adicionar Ataque'),
                          ),
                        ],
                      ),
                      ..._ataques.asMap().entries.map((entry) {
                        final i = entry.key;
                        final a = entry.value;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: TextFormField(
                                        controller: a.nome,
                                        decoration: _dec(context, 'Ataque'),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: TextFormField(
                                        controller: a.bonus,
                                        keyboardType: TextInputType.number,
                                        decoration: _dec(context, 'Bônus'),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: TextFormField(
                                        controller: a.dano,
                                        decoration: _dec(context, 'Dano'),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () => setState(() {
                                        _ataques.removeAt(i).dispose();
                                      }),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Habilidades (${_habilidades.length})',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          TextButton.icon(
                            onPressed: () => setState(
                              () => _habilidades.add(_HabilidadeDraft()),
                            ),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Adicionar Habilidade'),
                          ),
                        ],
                      ),
                      ..._habilidades.asMap().entries.map((entry) {
                        final i = entry.key;
                        final h = entry.value;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: TextFormField(
                                        controller: h.nome,
                                        decoration: _dec(context, 'Nome'),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: TextFormField(
                                        controller: h.acao,
                                        decoration: _dec(context, 'Ação'),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    SizedBox(
                                      width: 58,
                                      child: TextFormField(
                                        controller: h.custoPm,
                                        keyboardType: TextInputType.number,
                                        decoration: _dec(context, 'PM'),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () => setState(() {
                                        _habilidades.removeAt(i).dispose();
                                      }),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: h.descricao,
                                  maxLines: 2,
                                  decoration: _dec(context, 'Descrição'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: FilledButton.icon(
                      key: const ValueKey('editor_ameaca_salvar'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed: _salvar,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Salvar Ameaça'),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
