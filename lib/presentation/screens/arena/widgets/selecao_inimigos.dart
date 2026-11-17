import 'package:flutter/material.dart';
import '../../../../domain/entities/combate/combatente.dart';
import '../../../../domain/entities/combate/inimigos_treino.dart';
import '../../../../domain/entities/combate/monstro.dart';
import '../../../../domain/entities/personagem/personagem.dart';
import '../../../../domain/services/data_services/call_ameacas.dart';
import '../../../widgets/character_avatar_widget.dart';

class SelecaoInimigosView extends StatefulWidget {
  final Personagem heroi;
  final List<Combatente> selecionados;
  final void Function(Combatente c) onToggleInimigo;
  final VoidCallback onAvancar;
  final VoidCallback? onCriarInimigo;

  const SelecaoInimigosView({
    super.key,
    required this.heroi,
    required this.selecionados,
    required this.onToggleInimigo,
    required this.onAvancar,
    this.onCriarInimigo,
  });

  @override
  State<SelecaoInimigosView> createState() => _SelecaoInimigosViewState();
}

class _SelecaoInimigosViewState extends State<SelecaoInimigosView> {
  bool _abaBestiario = false;
  bool _carregandoIndice = false;
  String? _carregandoCriaturaId;
  String _busca = '';
  PapelMonstro? _papelFiltro;
  String? _regiaoFiltro;
  final TextEditingController _buscaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (BancoDeAmeacas.resumos.isEmpty) {
      _carregarBestiario();
    }
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _carregarBestiario() async {
    setState(() => _carregandoIndice = true);
    await BancoDeAmeacas.carregar();
    if (mounted) {
      setState(() => _carregandoIndice = false);
    }
  }

  void _tratarCriarInimigo(BuildContext context) {
    if (widget.onCriarInimigo != null) {
      widget.onCriarInimigo!();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Icon(
              Icons.construction_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Em breve: O Criador de Monstros e Ameaças customizadas estará disponível!',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _alternarAmeacaBestiario(AmeacaResumo resumo) async {
    final existente = widget.selecionados.where((c) {
      if (c.id == resumo.id) return true;
      return c is CombatenteMonstro && c.fichaMonstro.id == resumo.id;
    }).firstOrNull;

    if (existente != null) {
      widget.onToggleInimigo(existente);
      return;
    }

    setState(() => _carregandoCriaturaId = resumo.id);
    final monstro = await BancoDeAmeacas.getByIdAsync(resumo.id);
    if (!mounted) return;
    setState(() => _carregandoCriaturaId = null);

    if (monstro == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível carregar "${resumo.nome}".'),
        ),
      );
      return;
    }

    widget.onToggleInimigo(
      CombatenteMonstro.doMonstro(monstro, time: TimeCombatente.inimigo),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final todosTreino = InimigosTreino.todos;
    final resumosFiltrados = BancoDeAmeacas.filtrarResumos(
      busca: _busca,
      papel: _papelFiltro,
      regiao: _regiaoFiltro,
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header com Avatar unificado do Herói
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              children: [
                CharacterAvatarWidget(
                  personagem: widget.heroi,
                  size: 48,
                  borderRadius: 12,
                  useHero: true,
                  heroTag: 'arena-selector-${widget.heroi.id}',
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.heroi.nome,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${widget.heroi.pvTotal} PV • Defesa ${widget.heroi.defesaFinal} • Inic. +${widget.heroi.getValorPericia("INICIATIVA")}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Escolha os Inimigos para o Teste:',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Seletor Treino vs Bestiário Completo
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Treino')),
                  selected: !_abaBestiario,
                  showCheckmark: false,
                  backgroundColor: const Color(0xFF1E293B),
                  selectedColor: const Color(0xFFC62828),
                  side: BorderSide(
                    color: !_abaBestiario ? Colors.amberAccent : Colors.white24,
                  ),
                  labelStyle: TextStyle(
                    color: !_abaBestiario ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  onSelected: (_) => setState(() => _abaBestiario = false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Bestiário')),
                  selected: _abaBestiario,
                  showCheckmark: false,
                  backgroundColor: const Color(0xFF1E293B),
                  selectedColor: const Color(0xFFC62828),
                  side: BorderSide(
                    color: _abaBestiario ? Colors.amberAccent : Colors.white24,
                  ),
                  labelStyle: TextStyle(
                    color: _abaBestiario ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  onSelected: (_) => setState(() => _abaBestiario = true),
                ),
              ),
            ],
          ),

          if (widget.selecionados.isNotEmpty) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: widget.selecionados.map((s) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InputChip(
                      backgroundColor: Colors.red.shade900.withValues(alpha: 0.65),
                      side: const BorderSide(color: Colors.amberAccent),
                      label: Text(
                        s.tamanhoQuadrados > 1
                            ? '${s.nome} (${s.tamanhoQuadrados}x${s.tamanhoQuadrados})'
                            : s.nome,
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                      deleteIcon: const Icon(
                        Icons.close,
                        size: 14,
                        color: Colors.white70,
                      ),
                      onDeleted: () => widget.onToggleInimigo(s),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          const SizedBox(height: 8),
          if (_abaBestiario) ...[
            TextField(
              controller: _buscaController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Buscar ameaça por nome, ND ou tipo...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 18),
                suffixIcon: _busca.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54, size: 16),
                        onPressed: () {
                          _buscaController.clear();
                          setState(() => _busca = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (v) => setState(() => _busca = v),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('Todos Papéis'),
                    selected: _papelFiltro == null,
                    showCheckmark: false,
                    backgroundColor: const Color(0xFF1E293B),
                    selectedColor: const Color(0xFFC62828),
                    side: BorderSide(
                      color:
                          _papelFiltro == null ? Colors.amberAccent : Colors.white24,
                    ),
                    labelStyle: TextStyle(
                      color: _papelFiltro == null ? Colors.white : Colors.white70,
                      fontWeight:
                          _papelFiltro == null ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    onSelected: (_) => setState(() => _papelFiltro = null),
                  ),
                  const SizedBox(width: 6),
                  ...PapelMonstro.values.map((papel) {
                    final selPapel = _papelFiltro == papel;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(papel.label),
                        selected: selPapel,
                        showCheckmark: false,
                        backgroundColor: const Color(0xFF1E293B),
                        selectedColor: const Color(0xFFC62828),
                        side: BorderSide(
                          color: selPapel ? Colors.amberAccent : Colors.white24,
                        ),
                        labelStyle: TextStyle(
                          color: selPapel ? Colors.white : Colors.white70,
                          fontWeight:
                              selPapel ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (sel) => setState(
                          () => _papelFiltro = sel ? papel : null,
                        ),
                      ),
                    );
                  }),
                  if (BancoDeAmeacas.regioes.isNotEmpty)
                    Container(
                      height: 34,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: _regiaoFiltro,
                          dropdownColor: const Color(0xFF1E293B),
                          iconEnabledColor: Colors.white70,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                          hint: const Text(
                            'Região',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Todas Regiões'),
                            ),
                            ...BancoDeAmeacas.regioes.map(
                              (r) => DropdownMenuItem<String?>(
                                value: r,
                                child: Text(r.replaceAll('_', ' ')),
                              ),
                            ),
                          ],
                          onChanged: (v) => setState(() => _regiaoFiltro = v),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          Expanded(
            child: _abaBestiario
                ? _buildListaBestiario(resumosFiltrados)
                : _buildListaTreino(todosTreino, colorScheme),
          ),

          const SizedBox(height: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF1E293B),
              disabledForegroundColor: Colors.white60,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: widget.selecionados.isEmpty
                      ? Colors.white24
                      : Colors.transparent,
                ),
              ),
            ),
            icon: Icon(
              widget.selecionados.isEmpty
                  ? Icons.touch_app_outlined
                  : Icons.arrow_forward,
            ),
            label: Text(
              widget.selecionados.isEmpty
                  ? 'Selecione ao menos 1 inimigo para avançar'
                  : 'Avançar para Rolagem (${widget.selecionados.length} ${widget.selecionados.length == 1 ? "Inimigo" : "Inimigos"})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            onPressed: widget.selecionados.isNotEmpty ? widget.onAvancar : null,
          ),
        ],
      ),
    );
  }

  Widget _buildListaTreino(
    List<Combatente> todosInimigos,
    ColorScheme colorScheme,
  ) {
    return ListView.separated(
      itemCount: todosInimigos.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Card(
            color: const Color(0xFF1E293B),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: colorScheme.primary.withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 6,
              ),
              leading: CircleAvatar(
                backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
                child: Icon(
                  Icons.add_rounded,
                  color: colorScheme.primary,
                  size: 26,
                ),
              ),
              title: Text(
                'Criar Novo Inimigo',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              subtitle: const Text(
                'Monte uma ameaça customizada com atributos, armas e PV',
                style: TextStyle(color: Colors.white60, fontSize: 11),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Em breve',
                  style: TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              onTap: () => _tratarCriarInimigo(context),
            ),
          );
        }

        final monstro = todosInimigos[index - 1];
        final isSelected = widget.selecionados.any((c) => c.id == monstro.id);

        return ListTile(
          tileColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: isSelected ? Colors.amberAccent : Colors.white12,
            ),
          ),
          leading: CircleAvatar(
            backgroundColor: Colors.red[900],
            child: Text(
              '$index',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          title: Text(
            monstro.nome,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            '${monstro.pvMax} PV • Defesa ${monstro.defesa} • Desloc. ${monstro.deslocamentoMetros}m\nArmas: ${monstro.armas.map((a) => a.nome).join(", ")}',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          trailing: Checkbox(
            value: isSelected,
            activeColor: Colors.amberAccent,
            checkColor: Colors.black,
            onChanged: (_) => widget.onToggleInimigo(monstro),
          ),
          onTap: () => widget.onToggleInimigo(monstro),
        );
      },
    );
  }

  Widget _buildListaBestiario(List<AmeacaResumo> resumos) {
    if (_carregandoIndice) {
      return const Center(child: CircularProgressIndicator());
    }
    if (resumos.isEmpty) {
      return const Center(
        child: Text(
          'Nenhuma ameaça encontrada com os filtros atuais.',
          style: TextStyle(color: Colors.white60, fontSize: 13),
        ),
      );
    }

    return ListView.separated(
      itemCount: resumos.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final r = resumos[index];
        final isSelected = widget.selecionados.any(
          (c) =>
              c.id == r.id ||
              (c is CombatenteMonstro && c.fichaMonstro.id == r.id),
        );
        final carregandoEste = _carregandoCriaturaId == r.id;

        return ListTile(
          tileColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: isSelected ? Colors.amberAccent : Colors.white12,
            ),
          ),
          leading: CircleAvatar(
            backgroundColor: Colors.red[900],
            child: Text(
              r.nd,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            r.nome,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            'ND ${r.nd} • ${r.papel.label} • ${r.tipoCriatura}${r.regiao.isNotEmpty ? " • ${r.regiao.replaceAll('_', ' ')}" : ""}',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          trailing: carregandoEste
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Checkbox(
                  value: isSelected,
                  activeColor: Colors.amberAccent,
                  checkColor: Colors.black,
                  onChanged: (_) => _alternarAmeacaBestiario(r),
                ),
          onTap: carregandoEste ? null : () => _alternarAmeacaBestiario(r),
        );
      },
    );
  }
}
