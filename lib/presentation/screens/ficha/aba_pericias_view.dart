import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/services/calculo_ficha_service.dart';
import '../../controllers/ficha_cubit.dart';
import '../../controllers/ficha_state.dart';
import 'dialogo_rolagem_dado.dart';

class AbaPericiasView extends StatefulWidget {
  const AbaPericiasView({super.key});

  @override
  State<AbaPericiasView> createState() => _AbaPericiasViewState();
}

class _AbaPericiasViewState extends State<AbaPericiasView> {
  final TextEditingController _buscaController = TextEditingController();
  bool _apenasTreinadas = false;
  String _termoBusca = '';

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _abrirEditorOutrosBonus(
    BuildContext context,
    FichaCubit cubit,
    ComposicaoPericia comp,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => _DialogoBonusOutrosPericia(
        nomePericia: comp.pericia.label,
        valorInicial: comp.bonusOutros,
        onSalvar: (novoValor) =>
            cubit.definirOutrosBonusPericia(comp.pericia.key, novoValor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FichaCubit, FichaState>(
      buildWhen: (prev, curr) {
        final p1 = prev.personagem;
        final p2 = curr.personagem;
        return p1.atributos != p2.atributos ||
            p1.nivelPersonagem != p2.nivelPersonagem ||
            p1.periciasTreinadas != p2.periciasTreinadas ||
            p1.outrosBonusPericias != p2.outrosBonusPericias ||
            p1.efeitosTemporarios != p2.efeitosTemporarios ||
            p1.classes != p2.classes ||
            p1.raca != p2.raca ||
            p1.penalidadeArmaduraTotal != p2.penalidadeArmaduraTotal ||
            p1.usaProtecaoSemProficiencia != p2.usaProtecaoSemProficiencia;
      },
      builder: (context, state) {
        final cubit = context.read<FichaCubit>();
        final personagem = state.personagem;

        final penArmadura = personagem.penalidadeArmaduraTotal;
        final grupos = CalculoFichaService.agruparPericiasPorAtributo(
          personagem,
          apenasTreinadas: _apenasTreinadas,
          filtroBusca: _termoBusca,
          penalidadeArmaduraCustom: penArmadura,
        );

        final metadeNivel = (personagem.nivelPersonagem / 2).floor();
        final bonusTreino = personagem.bonusTreinamento;

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Bloco de apoio explicando o cálculo do Total
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calculate_outlined,
                        size: 18,
                        color: Color(0xFFD32F2F),
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'Como é calculado o Total da Perícia',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD32F2F).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '1 toque = Rolar',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFD32F2F),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Total = ½ Nível (+$metadeNivel) + Atributo + Treino (+$bonusTreino se treinada) + Outros − Pen. Armadura (${penArmadura > 0 ? "-$penArmadura" : "0"}).',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF475569),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Legenda: ✱ Somente treinada  •  🛡 Sofre penalidade de armadura/sobrecarga',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Barra de busca rápida + Filtro Treinadas
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: TextField(
                      controller: _buscaController,
                      onChanged: (val) => setState(() => _termoBusca = val),
                      style: const TextStyle(fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: 'Buscar perícia (ex: Acrobacia)...',
                        hintStyle: const TextStyle(fontSize: 13),
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _termoBusca.isNotEmpty
                            ? IconButton(
                                tooltip: 'Limpar busca',
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _buscaController.clear();
                                  setState(() => _termoBusca = '');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 0,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFCBD5E1),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFCBD5E1),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 44,
                  child: FilterChip(
                    selected: _apenasTreinadas,
                    selectedColor: const Color(0xFFFEE2E2),
                    checkmarkColor: const Color(0xFFB91C1C),
                    label: const Text(
                      'Treinadas',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onSelected: (v) => setState(() => _apenasTreinadas = v),
                  ),
                ),
              ],
            ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            if (grupos.isEmpty)
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(12, 0, 12, 28),
                sliver: SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 36),
                    child: Center(
                      child: Text(
                        'Nenhuma perícia encontrada para o filtro selecionado.',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 28),
                sliver: SliverList.builder(
                  itemCount: grupos.length,
                  itemBuilder: (context, index) {
                    final grupo = grupos[index];
                    return _BlocoAtributoPericias(
                      key: ValueKey('grupo_pericia_${grupo.siglaAtributo}'),
                      grupo: grupo,
                      onRolarPericia: (comp) => mostrarDialogoRolagemPericia(
                        context,
                        personagem: personagem,
                        periciaKey: comp.pericia.key,
                      ),
                      onAlternarTreino: (comp) =>
                          cubit.alternarTreinoPericia(comp.pericia.key),
                      onEditarOutros: (comp) =>
                          _abrirEditorOutrosBonus(context, cubit, comp),
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

class _BlocoAtributoPericias extends StatelessWidget {
  final GrupoPericiasAtributo grupo;
  final void Function(ComposicaoPericia comp) onRolarPericia;
  final void Function(ComposicaoPericia comp) onAlternarTreino;
  final void Function(ComposicaoPericia comp) onEditarOutros;

  const _BlocoAtributoPericias({
    super.key,
    required this.grupo,
    required this.onRolarPericia,
    required this.onAlternarTreino,
    required this.onEditarOutros,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabeçalho do Grupo de Atributo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD32F2F),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        grupo.siglaAtributo,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${grupo.nomeAtributo} (${grupo.valorAtributoFormatado})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 56,
                      child: Text(
                        'TREINO',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(width: 6),
                    SizedBox(
                      width: 60,
                      child: Text(
                        'OUTROS',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Linhas de perícias em ordem alfabética
          ...List.generate(grupo.pericias.length, (index) {
            final comp = grupo.pericias[index];
            final ehUltima = index == grupo.pericias.length - 1;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _LinhaPericiaWidget(
                  composicao: comp,
                  onRolar: () => onRolarPericia(comp),
                  onAlternarTreino: () => onAlternarTreino(comp),
                  onEditarOutros: () => onEditarOutros(comp),
                ),
                if (!ehUltima)
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _LinhaPericiaWidget extends StatelessWidget {
  final ComposicaoPericia composicao;
  final VoidCallback onRolar;
  final VoidCallback onAlternarTreino;
  final VoidCallback onEditarOutros;

  const _LinhaPericiaWidget({
    required this.composicao,
    required this.onRolar,
    required this.onAlternarTreino,
    required this.onEditarOutros,
  });

  @override
  Widget build(BuildContext context) {
    final p = composicao.pericia;
    final bloqueada = composicao.bloqueadaSemTreino;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          // Área principal clicável em 1 toque para rolar a perícia (>= 48px altura)
          Expanded(
            child: Semantics(
              button: true,
              label:
                  'Rolar ${p.label}, total ${composicao.totalFormatado}${bloqueada ? ", somente treinada" : ""}',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  key: Key('pericia_row_${p.key}'),
                  borderRadius: BorderRadius.circular(10),
                  onTap: onRolar,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 6,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '${p.label}${p.somenteTreinada ? " ✱" : ""}${composicao.sofrePenalidadeArmadura ? " 🛡" : ""}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: composicao.ehTreinada
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: bloqueada
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF0F172A),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // TOTAL AO LADO DO NOME
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: bloqueada
                                      ? const Color(0xFFF1F5F9)
                                      : const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: bloqueada
                                        ? const Color(0xFFCBD5E1)
                                        : const Color(
                                            0xFFD32F2F,
                                          ).withValues(alpha: 0.45),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.casino_outlined,
                                      size: 12,
                                      color: bloqueada
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFFD32F2F),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      composicao.totalFormatado,
                                      key: Key('pericia_total_${p.key}'),
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w900,
                                        color: bloqueada
                                            ? const Color(0xFF64748B)
                                            : const Color(0xFFB91C1C),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            composicao.resumoParcelas,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 4),

          // Botão de TREINO (alvo >= 44x44px)
          Semantics(
            button: true,
            toggled: composicao.ehTreinada,
            label: 'Treino em ${p.label}',
            child: Tooltip(
              message: composicao.ehTreinoFixoClasse
                  ? 'Treinada pela Classe (+${composicao.bonusTreino})'
                  : (composicao.ehTreinada
                        ? 'Remover treino'
                        : 'Marcar como treinada'),
              child: InkWell(
                key: Key('pericia_treino_${p.key}'),
                borderRadius: BorderRadius.circular(10),
                onTap: onAlternarTreino,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 56,
                    minHeight: 44,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: composicao.ehTreinada
                          ? const Color(0xFFECFDF5)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: composicao.ehTreinada
                            ? const Color(0xFF10B981)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          composicao.ehTreinoFixoClasse
                              ? Icons.verified_rounded
                              : (composicao.ehTreinada
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked),
                          size: 15,
                          color: composicao.ehTreinada
                              ? const Color(0xFF059669)
                              : const Color(0xFF94A3B8),
                        ),
                        if (composicao.ehTreinada) ...[
                          const SizedBox(width: 3),
                          Text(
                            '+${composicao.bonusTreino}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF047857),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 6),

          // Campo de OUTROS (bônus diversos, alvo >= 44x44px)
          Semantics(
            button: true,
            label:
                'Editar bônus outros de ${p.label}, atual ${composicao.bonusOutros}',
            child: InkWell(
              key: Key('pericia_outros_${p.key}'),
              borderRadius: BorderRadius.circular(10),
              onTap: onEditarOutros,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 60, minHeight: 44),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: composicao.bonusOutros != 0
                        ? const Color(0xFFEFF6FF)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: composicao.bonusOutros != 0
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      composicao.bonusOutros > 0
                          ? '+${composicao.bonusOutros}'
                          : '${composicao.bonusOutros}',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: composicao.bonusOutros != 0
                            ? const Color(0xFF1D4ED8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogoBonusOutrosPericia extends StatefulWidget {
  final String nomePericia;
  final int valorInicial;
  final ValueChanged<int> onSalvar;

  const _DialogoBonusOutrosPericia({
    required this.nomePericia,
    required this.valorInicial,
    required this.onSalvar,
  });

  @override
  State<_DialogoBonusOutrosPericia> createState() =>
      _DialogoBonusOutrosPericiaState();
}

class _DialogoBonusOutrosPericiaState
    extends State<_DialogoBonusOutrosPericia> {
  late int _valor;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _valor = widget.valorInicial;
    _controller = TextEditingController(text: '$_valor');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _alterar(int novo) {
    final limitado = novo.clamp(-50, 99);
    setState(() {
      _valor = limitado;
      _controller.text = '$limitado';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Outros — ${widget.nomePericia}',
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            ' Some bônus permanentes de poderes, itens vestidos, parceiros ou aprimoramentos.',
            style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: () => _alterar(_valor - 1),
                icon: const Icon(Icons.remove),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 84,
                child: TextField(
                  controller: _controller,
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                  ),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (txt) {
                    final parsed = int.tryParse(txt);
                    if (parsed != null) {
                      _valor = parsed.clamp(-50, 99);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filledTonal(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: () => _alterar(_valor + 1),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_valor != 0)
            TextButton(
              onPressed: () => _alterar(0),
              child: const Text('Zerar bônus (0)'),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('CANCELAR'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(96, 44),
            backgroundColor: const Color(0xFFD32F2F),
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            final parsed = int.tryParse(_controller.text) ?? _valor;
            widget.onSalvar(parsed);
            Navigator.of(context).pop();
          },
          child: const Text('SALVAR'),
        ),
      ],
    );
  }
}
