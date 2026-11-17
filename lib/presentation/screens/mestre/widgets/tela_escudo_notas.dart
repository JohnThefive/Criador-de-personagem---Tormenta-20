import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/entities/mestre/modelos_mestre.dart';
import '../../../controllers/mestre_controller/mestre_cubit.dart';
import '../../../controllers/mestre_controller/mestre_state.dart';
import '../../../widgets/app_safe_scaffold.dart';
import '../theme/mestre_theme.dart';

/// PARTE 5 — Tela "Escudo e Notas" (Tormenta 20 - Android/Flutter)
/// Consulta rápida em 2 toques, busca global e alta densidade de informação.
/// Abas: 1. Condições | 2. Perigos | 3. Personagens | 4. Nomes | 5. Regras de Combate | 6. Notas da Sessão.
class TelaEscudoNotas extends StatefulWidget {
  final MestreCubit cubit;
  final int abaInicial;

  const TelaEscudoNotas({
    super.key,
    required this.cubit,
    this.abaInicial = 0,
  });

  @override
  State<TelaEscudoNotas> createState() => _TelaEscudoNotasState();
}

class _TelaEscudoNotasState extends State<TelaEscudoNotas>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _buscaController = TextEditingController();
  String _termoBusca = '';

  // Filtros do Gerador de Nomes
  String _racaSelecionada = 'Humano';
  String _generoSelecionado = 'Neutro';
  String _tomSelecionado = 'Sério';

  // Checklist de Nova Tarefa e Notas com Debounce
  final TextEditingController _novaTarefaController = TextEditingController();
  final TextEditingController _notasEditorController = TextEditingController();
  Timer? _debounceNotas;

  final Set<String> _condicoesFavoritas = {
    'Caído',
    'Desprevenido',
    'Sangrando',
    'Abalado',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 6,
      vsync: this,
      initialIndex: widget.abaInicial.clamp(0, 5),
    );
    _notasEditorController.text =
        widget.cubit.state.sessaoAtual?.notasSessaoTexto ?? '';
  }

  @override
  void dispose() {
    if (_debounceNotas?.isActive ?? false) {
      _debounceNotas?.cancel();
      if (!widget.cubit.isClosed) {
        widget.cubit.atualizarNotasSessao(_notasEditorController.text);
      }
    } else {
      _debounceNotas?.cancel();
    }
    _tabController.dispose();
    _buscaController.dispose();
    _novaTarefaController.dispose();
    _notasEditorController.dispose();
    super.dispose();
  }

  void _agendarAtualizacaoNotas(String texto) {
    _debounceNotas?.cancel();
    _debounceNotas = Timer(const Duration(milliseconds: 300), () {
      if (!widget.cubit.isClosed) {
        widget.cubit.atualizarNotasSessao(texto);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MestreCores.escuroBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildBarraBuscaGlobal(),
            _buildBarraAbas(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAbaCondicoes(),
                  _buildAbaPerigos(),
                  _buildAbaPersonagens(),
                  _buildAbaNomesAleatorios(),
                  _buildAbaRegrasCombate(),
                  _buildAbaNotas(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BARRA DE BUSCA GLOBAL
  // ---------------------------------------------------------------------------

  Widget _buildBarraBuscaGlobal() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      color: MestreCores.escuroSurface,
      child: TextField(
        controller: _buscaController,
        style: const TextStyle(
          color: MestreCores.escuroOnSurface,
          fontSize: 13,
        ),
        decoration: InputDecoration(
          hintText:
              'Busca rápida no Escudo (condição, perigo, personagem, CD)...',
          hintStyle: const TextStyle(
            color: MestreCores.escuroOnSurfaceVariant,
            fontSize: 12,
          ),
          prefixIcon: const Icon(
            Icons.search,
            size: 18,
            color: MestreCores.escuroOuro,
          ),
          suffixIcon: _termoBusca.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.clear,
                    size: 16,
                    color: MestreCores.escuroOnSurfaceVariant,
                  ),
                  onPressed: () {
                    _buscaController.clear();
                    setState(() => _termoBusca = '');
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          filled: true,
          fillColor: MestreCores.escuroSurfaceContainer,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: MestreCores.escuroOuro,
              width: 1.2,
            ),
          ),
        ),
        onChanged: (val) =>
            setState(() => _termoBusca = val.toLowerCase().trim()),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BARRA DE ABAS COM SCROLL HORIZONTAL
  // ---------------------------------------------------------------------------

  Widget _buildBarraAbas() {
    return Container(
      color: MestreCores.escuroSurface,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: MestreCores.escuroOuro,
        unselectedLabelColor: MestreCores.escuroOnSurfaceVariant,
        indicatorColor: MestreCores.escuroOuro,
        tabAlignment: TabAlignment.start,
        tabs: const [
          Tab(icon: Icon(Icons.emergency_outlined, size: 16), text: 'Condições'),
          Tab(
            icon: Icon(Icons.warning_amber_outlined, size: 16),
            text: 'Perigos',
          ),
          Tab(
            icon: Icon(Icons.groups_2_outlined, size: 16),
            text: 'Personagens',
          ),
          Tab(icon: Icon(Icons.badge_outlined, size: 16), text: 'Nomes'),
          Tab(
            icon: Icon(Icons.gavel_outlined, size: 16),
            text: 'Regras de Combate',
          ),
          Tab(
            icon: Icon(Icons.note_alt_outlined, size: 16),
            text: 'Notas da Sessão',
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ABA 1: CONDIÇÕES (28+ CONDIÇÕES T20 COM EXPANSÃO E APLICAR A TOKEN)
  // ---------------------------------------------------------------------------

  Widget _buildAbaCondicoes() {
    final condicoesFiltradas = _catalogoCondicoesT20.where((c) {
      if (_termoBusca.isEmpty) return true;
      return c.nome.toLowerCase().contains(_termoBusca) ||
          c.efeito.toLowerCase().contains(_termoBusca);
    }).toList();

    condicoesFiltradas.sort((a, b) {
      final aFav = _condicoesFavoritas.contains(a.nome) ? 0 : 1;
      final bFav = _condicoesFavoritas.contains(b.nome) ? 0 : 1;
      if (aFav != bFav) return aFav.compareTo(bFav);
      return a.nome.compareTo(b.nome);
    });

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: condicoesFiltradas.length,
      itemBuilder: (context, index) {
        final cond = condicoesFiltradas[index];
        final ehFav = _condicoesFavoritas.contains(cond.nome);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: MestreCores.escuroSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: ehFav
                  ? MestreCores.escuroOuro.withValues(alpha: 0.5)
                  : MestreCores.escuroOutline,
            ),
          ),
          child: ExpansionTile(
            key: PageStorageKey('cond_${cond.nome}'),
            tilePadding: const EdgeInsets.symmetric(horizontal: 12),
            leading: Icon(
              ehFav ? Icons.star : Icons.star_border,
              size: 18,
              color: ehFav
                  ? MestreCores.escuroOuro
                  : MestreCores.escuroOnSurfaceVariant,
            ),
            title: Row(
              children: [
                Text(
                  cond.nome,
                  style: TextStyle(
                    fontFamily: 'serif',
                    color: ehFav
                        ? MestreCores.escuroOuro
                        : MestreCores.escuroOnSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: MestreCores.escuroVinho.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    cond.tipo,
                    style: const TextStyle(
                      color: MestreCores.escuroOnSurface,
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(
                Icons.person_add_outlined,
                size: 16,
                color: MestreCores.escuroOuro,
              ),
              tooltip: 'Aplicar a um token no mapa',
              onPressed: () => _aplicarCondicaoAoToken(context, cond.nome),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      cond.efeito,
                      style: const TextStyle(
                        color: MestreCores.escuroOnSurfaceVariant,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        BlocSelector<MestreCubit, MestreState,
                            ({String id, String nome})?>(
                          bloc: widget.cubit,
                          selector: (s) {
                            final id = s.tokenSelecionadoParaMoverId;
                            final mapa = s.mapaAtual;
                            if (id == null || mapa == null) return null;
                            final tok =
                                mapa.tokens.where((t) => t.id == id).firstOrNull;
                            if (tok == null) return null;
                            return (id: tok.id, nome: tok.nome);
                          },
                          builder: (context, tokenSel) {
                            if (tokenSel == null) {
                              return TextButton.icon(
                                icon: const Icon(
                                  Icons.person_add_outlined,
                                  size: 14,
                                ),
                                label: const Text(
                                  'Aplicar ao token selecionado',
                                  style: TextStyle(fontSize: 11),
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: MestreCores.escuroOuro,
                                ),
                                onPressed: () =>
                                    _aplicarCondicaoAoToken(context, cond.nome),
                              );
                            }
                            return TextButton.icon(
                              icon: const Icon(Icons.bolt, size: 14),
                              label: Text(
                                'Aplicar em ${tokenSel.nome}',
                                style: const TextStyle(fontSize: 11),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: MestreCores.escuroOuro,
                              ),
                              onPressed: () {
                                widget.cubit.adicionarCondicaoToken(
                                  tokenSel.id,
                                  cond.nome,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Condição "${cond.nome}" aplicada em ${tokenSel.nome}.',
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        TextButton.icon(
                          icon: Icon(
                            ehFav ? Icons.star_border : Icons.star,
                            size: 14,
                          ),
                          label: Text(
                            ehFav ? 'Desafixar' : 'Fixar no topo',
                            style: const TextStyle(fontSize: 11),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: MestreCores.escuroOuro,
                          ),
                          onPressed: () {
                            setState(() {
                              if (ehFav) {
                                _condicoesFavoritas.remove(cond.nome);
                              } else {
                                _condicoesFavoritas.add(cond.nome);
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _aplicarCondicaoAoToken(BuildContext context, String condicao) {
    final tokensIniciais = widget.cubit.state.mapaAtual?.tokens ?? const [];
    if (tokensIniciais.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhum combatente presente no mapa atual.'),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: MestreCores.escuroSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => BlocSelector<MestreCubit, MestreState,
          List<({String id, String nome, bool ehHeroi})>>(
        bloc: widget.cubit,
        selector: (s) => (s.mapaAtual?.tokens ?? const [])
            .map((t) => (id: t.id, nome: t.nome, ehHeroi: t.ehHeroi))
            .toList(),
        builder: (ctx, tokens) => AppBottomSheetContainer(
          scrollable: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Aplicar "$condicao" a qual combatente?',
                style: const TextStyle(
                  fontFamily: 'serif',
                  color: MestreCores.escuroOnSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ...tokens.map((t) {
                final inicial = t.nome.isEmpty
                    ? '?'
                    : t.nome.substring(0, 1).toUpperCase();
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: t.ehHeroi
                        ? MestreCores.escuroVinho
                        : MestreCores.statusAlertaEscuro,
                    radius: 14,
                    child: Text(
                      inicial,
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                  title: Text(
                    t.nome,
                    style: const TextStyle(
                      color: MestreCores.escuroOnSurface,
                      fontSize: 13,
                    ),
                  ),
                  onTap: () {
                    widget.cubit.adicionarCondicaoToken(t.id, condicao);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('"$condicao" aplicada em ${t.nome}!'),
                      ),
                    );
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ABA 2: PERIGOS (TERRENO, ARMADILHA, AMBIENTE COM CD E DANO EM DESTAQUE)
  // ---------------------------------------------------------------------------

  Widget _buildAbaPerigos() {
    return BlocSelector<
        MestreCubit,
        MestreState,
        List<
            ({
              String id,
              String nome,
              String tipo,
              String cd,
              String dano,
              String descricao,
              bool fixado,
            })>>(
      bloc: widget.cubit,
      selector: (s) => s.perigos
          .map(
            (p) => (
              id: p.id,
              nome: p.nome,
              tipo: p.tipo,
              cd: p.cd,
              dano: p.dano,
              descricao: p.descricao,
              fixado: p.fixado,
            ),
          )
          .toList(),
      builder: (context, todosPerigos) {
        final perigos = todosPerigos.where((p) {
          if (_termoBusca.isEmpty) return true;
          return p.nome.toLowerCase().contains(_termoBusca) ||
              p.descricao.toLowerCase().contains(_termoBusca);
        }).toList();

        perigos.sort((a, b) {
          if (a.fixado != b.fixado) return a.fixado ? -1 : 1;
          return a.nome.compareTo(b.nome);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: perigos.length,
          itemBuilder: (context, index) {
            final p = perigos[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              color: MestreCores.escuroSurface,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: p.fixado
                      ? MestreCores.escuroOuro.withValues(alpha: 0.6)
                      : MestreCores.escuroOutline,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                p.tipo == 'Armadilha'
                                    ? Icons.warning_amber
                                    : (p.tipo == 'Terreno'
                                        ? Icons.terrain
                                        : Icons.cloud_outlined),
                                size: 16,
                                color: MestreCores.escuroOuro,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  p.nome,
                                  style: const TextStyle(
                                    fontFamily: 'serif',
                                    color: MestreCores.escuroOnSurface,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            p.fixado
                                ? Icons.push_pin
                                : Icons.push_pin_outlined,
                            size: 16,
                          ),
                          color: p.fixado
                              ? MestreCores.escuroOuro
                              : MestreCores.escuroOnSurfaceVariant,
                          onPressed: () =>
                              widget.cubit.alternarFixarPerigo(p.id),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: MestreCores.escuroVinho,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            p.cd,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: MestreCores.statusAlertaEscuro
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: MestreCores.statusAlertaEscuro,
                            ),
                          ),
                          child: Text(
                            'Dano: ${p.dano}',
                            style: const TextStyle(
                              color: MestreCores.statusAlertaEscuro,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      p.descricao,
                      style: const TextStyle(
                        color: MestreCores.escuroOnSurfaceVariant,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // ABA 3: NOMES ALEATÓRIOS (FILTROS, GERAR, HISTÓRICO, FAVORITAR)
  // ---------------------------------------------------------------------------

  Widget _buildAbaNomesAleatorios() {
    const racas = [
      'Humano',
      'Elfo',
      'Anão',
      'Qareen',
      'Minotauro',
      'Lefou',
      'Goblin',
      'Dahllan',
    ];
    const generos = ['Masculino', 'Feminino', 'Neutro'];
    const tons = ['Sério', 'Épico', 'Rústico', 'Cômico'];

    return BlocSelector<
        MestreCubit,
        MestreState,
        ({
          String? nomeGeradoAtual,
          List<String> nomesFavoritos,
          List<String> historicoNomes,
        })>(
      bloc: widget.cubit,
      selector: (s) => (
        nomeGeradoAtual: s.nomeGeradoAtual,
        nomesFavoritos: s.nomesFavoritos,
        historicoNomes: s.historicoNomes,
      ),
      builder: (context, info) {
        final nomeAtual = info.nomeGeradoAtual ?? 'Clique em Gerar';
        final ehFav = info.nomesFavoritos.contains(nomeAtual);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Origem / Raça:',
              style: TextStyle(
                color: MestreCores.escuroOnSurface,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: racas
                  .map(
                    (r) => ChoiceChip(
                      label: Text(r, style: const TextStyle(fontSize: 11)),
                      selected: _racaSelecionada == r,
                      selectedColor: MestreCores.escuroOuro,
                      onSelected: (_) => setState(() => _racaSelecionada = r),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Gênero:',
                        style: TextStyle(
                          color: MestreCores.escuroOnSurface,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      DropdownButton<String>(
                        value: _generoSelecionado,
                        dropdownColor: MestreCores.escuroSurfaceContainer,
                        isExpanded: true,
                        style: const TextStyle(
                          color: MestreCores.escuroOnSurface,
                          fontSize: 12,
                        ),
                        items: generos
                            .map(
                              (g) => DropdownMenuItem(value: g, child: Text(g)),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _generoSelecionado = v);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tom:',
                        style: TextStyle(
                          color: MestreCores.escuroOnSurface,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      DropdownButton<String>(
                        value: _tomSelecionado,
                        dropdownColor: MestreCores.escuroSurfaceContainer,
                        isExpanded: true,
                        style: const TextStyle(
                          color: MestreCores.escuroOnSurface,
                          fontSize: 12,
                        ),
                        items: tons
                            .map(
                              (t) => DropdownMenuItem(value: t, child: Text(t)),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _tomSelecionado = v);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: MestreCores.escuroSurfaceContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: MestreCores.escuroOuro.withValues(alpha: 0.6),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    nomeAtual,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      color: MestreCores.escuroOuro,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.copy,
                          size: 18,
                          color: MestreCores.escuroOnSurfaceVariant,
                        ),
                        tooltip: 'Copiar nome',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: nomeAtual));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Nome copiado!')),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          ehFav ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                        ),
                        color: ehFav
                            ? Colors.redAccent
                            : MestreCores.escuroOnSurfaceVariant,
                        tooltip: 'Favoritar nome',
                        onPressed: () => widget.cubit.favoritarNome(nomeAtual),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: MestreCores.escuroOuro,
                foregroundColor: MestreCores.escuroOuroTexto,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.casino_outlined, size: 20),
              label: const Text(
                'GERAR NOME',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              onPressed: () {
                widget.cubit.gerarNomeAleatorio(
                  raca: _racaSelecionada,
                  genero: _generoSelecionado,
                  tom: _tomSelecionado,
                );
              },
            ),
            const SizedBox(height: 16),

            if (info.historicoNomes.isNotEmpty) ...[
              const Text(
                'Histórico Recente na Sessão:',
                style: TextStyle(
                  color: MestreCores.escuroOnSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: info.historicoNomes.map((n) {
                  return ActionChip(
                    label: Text(n, style: const TextStyle(fontSize: 10)),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: n));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('"$n" copiado!')),
                      );
                    },
                  );
                }).toList(),
              ),
            ],
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // ABA 4: REGRAS DE COMBATE (FILTRADA PELA BUSCA GLOBAL)
  // ---------------------------------------------------------------------------

  Widget _buildAbaRegrasCombate() {
    final filtradas = _regrasCombateT20.where((r) {
      if (_termoBusca.isEmpty) return true;
      return r.titulo.toLowerCase().contains(_termoBusca) ||
          r.corpo.toLowerCase().contains(_termoBusca);
    }).toList();

    if (filtradas.isEmpty) {
      return const Center(
        child: Text(
          'Nenhuma regra encontrada para a busca.',
          style: TextStyle(color: MestreCores.escuroOnSurfaceVariant),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: filtradas
          .map(
            (r) => _buildSecaoRegraCombate(
              titulo: r.titulo,
              corpo: r.corpo,
            ),
          )
          .toList(),
    );
  }

  Widget _buildSecaoRegraCombate({
    required String titulo,
    required String corpo,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: MestreCores.escuroSurface,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        side: BorderSide(color: MestreCores.escuroOutline),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14),
        title: Text(
          titulo,
          style: const TextStyle(
            fontFamily: 'serif',
            color: MestreCores.escuroOnSurface,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Text(
              corpo,
              style: const TextStyle(
                color: MestreCores.escuroOnSurfaceVariant,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ABA 5: NOTAS DA SESSÃO (DEBOUNCE 300MS + BLOCLISTENER + CHECKLIST)
  // ---------------------------------------------------------------------------

  Widget _buildAbaNotas() {
    return BlocListener<MestreCubit, MestreState>(
      bloc: widget.cubit,
      listenWhen: (prev, curr) => prev.sessaoAtual?.id != curr.sessaoAtual?.id,
      listener: (context, state) {
        _debounceNotas?.cancel();
        _notasEditorController.text = state.sessaoAtual?.notasSessaoTexto ?? '';
      },
      child: BlocSelector<
          MestreCubit,
          MestreState,
          ({
            String? sessaoId,
            String titulo,
            bool notaFixada,
            List<({String id, String texto, bool concluido})> checklist,
          })?>(
        bloc: widget.cubit,
        selector: (s) {
          final ses = s.sessaoAtual;
          if (ses == null) return null;
          return (
            sessaoId: ses.id,
            titulo: ses.titulo,
            notaFixada: ses.notaFixada,
            checklist: ses.checklistNotas
                .map((i) => (id: i.id, texto: i.texto, concluido: i.concluido))
                .toList(),
          );
        },
        builder: (context, info) {
          if (info == null) {
            return const Center(
              child: Text(
                'Nenhuma sessão ativa.',
                style: TextStyle(color: MestreCores.escuroOnSurfaceVariant),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Notas de: ${info.titulo}',
                      style: const TextStyle(
                        fontFamily: 'serif',
                        color: MestreCores.escuroOnSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      info.notaFixada
                          ? Icons.push_pin
                          : Icons.push_pin_outlined,
                      size: 18,
                    ),
                    color: info.notaFixada
                        ? MestreCores.escuroOuro
                        : MestreCores.escuroOnSurfaceVariant,
                    tooltip: 'Fixar nota no topo',
                    onPressed: () => widget.cubit.alternarFixarNotaSessao(),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              const Text(
                'Checklist de Metas da Sessão:',
                style: TextStyle(
                  color: MestreCores.escuroOuro,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              ...info.checklist.map(
                (it) => CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    it.texto,
                    style: TextStyle(
                      color: it.concluido
                          ? MestreCores.escuroOnSurfaceVariant
                          : MestreCores.escuroOnSurface,
                      decoration:
                          it.concluido ? TextDecoration.lineThrough : null,
                      fontSize: 12,
                    ),
                  ),
                  value: it.concluido,
                  activeColor: MestreCores.escuroOuro,
                  checkColor: MestreCores.escuroOuroTexto,
                  secondary: IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 14,
                      color: MestreCores.escuroOnSurfaceVariant,
                    ),
                    onPressed: () => widget.cubit.removerItemChecklist(it.id),
                  ),
                  onChanged: (_) => widget.cubit.alternarItemChecklist(it.id),
                ),
              ),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _novaTarefaController,
                      style: const TextStyle(
                        color: MestreCores.escuroOnSurface,
                        fontSize: 12,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Adicionar meta da sessão...',
                        hintStyle: TextStyle(
                          color: MestreCores.escuroOnSurfaceVariant,
                          fontSize: 11,
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle,
                      color: MestreCores.escuroOuro,
                    ),
                    onPressed: () {
                      final txt = _novaTarefaController.text;
                      if (txt.isNotEmpty) {
                        widget.cubit.adicionarItemChecklist(txt);
                        _novaTarefaController.clear();
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(color: MestreCores.escuroOutline),
              const SizedBox(height: 8),

              const Text(
                'Anotações Livres:',
                style: TextStyle(
                  color: MestreCores.escuroOuro,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _notasEditorController,
                maxLines: 8,
                style: const TextStyle(
                  color: MestreCores.escuroOnSurface,
                  fontSize: 12,
                  height: 1.4,
                ),
                decoration: const InputDecoration(
                  hintText:
                      'Escreva detalhes do ambiente, segredos dos NPCs, pistas reveladas...',
                  hintStyle: TextStyle(color: Colors.white24),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: MestreCores.escuroOutline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: MestreCores.escuroOuro),
                  ),
                ),
                onChanged: _agendarAtualizacaoNotas,
              ),
            ],
          );
        },
      ),
    );
  }

  static const List<({String titulo, String corpo})> _regrasCombateT20 = [
    (
      titulo: 'Economia de Ações por Turno (R60)',
      corpo: '• (1 Padrão + 1 Movimento) OU 2 Movimentos OU 1 Completa.\n'
          '• Ações Livres: qualquer quantidade no próprio turno (mestre pode limitar).\n'
          '• Reações: a qualquer momento, mesmo fora do turno ou sem poder agir.',
    ),
    (
      titulo: 'Ações Padrão & Manobras de Combate (R61)',
      corpo:
          '• Agredir: corpo a corpo (1,5m) ou à distância (-5 se alvo engajado corpo a corpo sem Mirar).\n'
          '• Manobras: Agarrar, Derrubar, Desarmar, Empurrar, Quebrar (teste de Luta oposto).\n'
          '• Fintar: Enganação vs Reflexos. Sucesso: alvo desprevenido contra seu próximo ataque.\n'
          '• Atropelar: avança pelo espaço do alvo (teste oposto de manobra). Livre na Investida.',
    ),
    (
      titulo: 'Modificadores de Combate (R74 & R75)',
      corpo: '• Atacante Caído: -5 no ataque corpo a corpo.\n'
          '• Alvo Caído: -5 na Defesa vs corpo a corpo / +5 vs distância.\n'
          '• Desprevenido: -5 na Defesa e Reflexos.\n'
          '• Flanquear (R75): dois aliados em lados opostos ganham +2 no ataque corpo a corpo.\n'
          '• Cobertura: Leve (+5 Defesa) / Total (não pode ser atacado).\n'
          '• Camuflagem: Leve (20% de falha) / Total ou Cego (50% de falha).',
    ),
    (
      titulo: 'Exemplos de Dificuldade (CD de Testes)',
      corpo: '• Fácil: CD 10 (tarefa simples para novatos).\n'
          '• Médio: CD 15 (desafio razoável de aventureiro).\n'
          '• Difícil: CD 20 (exige treino ou bônus).\n'
          '• Formidável: CD 25 (para heróis veteranos).\n'
          '• Heroico: CD 30 (feito lendário).\n'
          '• Quase Impossível: CD 35+ (nível épico).',
    ),
  ];

  // ---------------------------------------------------------------------------
  // CATÁLOGO COMPLETO DAS 28+ CONDIÇÕES DE TORMENTA 20
  // ---------------------------------------------------------------------------

  static const List<_CondicaoInfo> _catalogoCondicoesT20 = [
    _CondicaoInfo(
      'Abalado',
      'Mental',
      '-2 em testes de perícia. Se ficar abalado novamente, fica Amedrontado.',
    ),
    _CondicaoInfo(
      'Agarrado',
      'Física',
      'Desprevenido e imóvel. -2 nos testes de ataque e só pode usar armas leves.',
    ),
    _CondicaoInfo(
      'Alquebrado',
      'Mental',
      'O custo em PM de todas as suas habilidades e magias aumenta em +1.',
    ),
    _CondicaoInfo(
      'Amedrontado',
      'Mental',
      '-5 em testes de perícia e não pode se aproximar voluntariamente da fonte do medo.',
    ),
    _CondicaoInfo(
      'Atordoado',
      'Mental',
      'Fica desprevenido e não pode realizar nenhuma ação no seu turno.',
    ),
    _CondicaoInfo(
      'Caído',
      'Física',
      '-5 no ataque corpo a corpo, 1,5m deslocamento; Defesa -5 vs corpo a corpo e +5 vs distância.',
    ),
    _CondicaoInfo(
      'Cego',
      'Sentidos',
      'Desprevenido, -5 em perícias baseadas em Força/Destreza, 50% de falha em ataques.',
    ),
    _CondicaoInfo(
      'Confuso',
      'Mental',
      'Comportamento aleatório no início do turno (1d6: ataca aliado, fica parado, etc.).',
    ),
    _CondicaoInfo(
      'Debilitado',
      'Física',
      '-5 em testes de atributos físicos (Força, Destreza, Constituição) e perícias associadas.',
    ),
    _CondicaoInfo(
      'Desprevenido',
      'Física',
      '-5 na Defesa e em Reflexos.',
    ),
    _CondicaoInfo(
      'Enfeitiçado',
      'Mental',
      'Trata o conjurador como um amigo próximo e não realiza ações hostis contra ele.',
    ),
    _CondicaoInfo(
      'Enredado',
      'Física',
      'Deslocamento reduzido à metade, não pode correr nem fazer investida, -2 no ataque.',
    ),
    _CondicaoInfo(
      'Esmagado',
      'Física',
      'Sofre dano contínuo de impacto e fica indefeso até escapar.',
    ),
    _CondicaoInfo(
      'Esmorecido',
      'Mental',
      '-5 em testes de atributos mentais (Inteligência, Sabedoria, Carisma).',
    ),
    _CondicaoInfo(
      'Exausto',
      'Física',
      'Debilitado, lento e vulnerável. Descanso de 1 hora reduz para Fatigado.',
    ),
    _CondicaoInfo(
      'Fascinado',
      'Mental',
      '-5 na Percepção e não pode realizar ações além de observar o efeito fascinante.',
    ),
    _CondicaoInfo(
      'Fatigado',
      'Física',
      '-2 em testes de perícia. Não pode correr nem fazer investida. Se fatigar novamente, fica Exausto.',
    ),
    _CondicaoInfo(
      'Frágil',
      'Física',
      'Redução de Dano (RD) reduzida pela metade e sofre +50% de dano de ataques físicos.',
    ),
    _CondicaoInfo(
      'Furtivo',
      'Sentidos',
      'Inimigos não sabem sua localização exata até realizarem teste de Percepção contra sua Furtividade.',
    ),
    _CondicaoInfo(
      'Imobilizado',
      'Física',
      'Desprevenido, não pode se mover nem falar. Apenas ações mentais são permitidas.',
    ),
    _CondicaoInfo(
      'Inconsciente',
      'Sentidos',
      'Indefeso, desmaia e não pode realizar ações. Ocorre com 0 ou menos PV.',
    ),
    _CondicaoInfo(
      'Indefeso',
      'Física',
      'Desprevenido, sofre -10 na Defesa e falha automaticamente em testes de Reflexos.',
    ),
    _CondicaoInfo(
      'Lento',
      'Física',
      'Todas as formas de deslocamento são reduzidas à metade e não pode correr.',
    ),
    _CondicaoInfo(
      'Ofuscado',
      'Sentidos',
      '-2 em testes de ataque e em testes de Percepção baseados em visão.',
    ),
    _CondicaoInfo(
      'Paralisado',
      'Física',
      'Fica imóvel e indefeso. Apenas ações puramente mentais são possíveis.',
    ),
    _CondicaoInfo(
      'Pasmo',
      'Mental',
      'Não pode realizar nenhuma ação durante a rodada (mantém suas defesas normais).',
    ),
    _CondicaoInfo(
      'Petrificado',
      'Física',
      'Transformado em estátua de pedra: inconsciente e com RD 10 contra todos os danos.',
    ),
    _CondicaoInfo(
      'Sangrando',
      'Física',
      'No início de cada turno, faz teste de Constituição (CD 15) ou perde 1d6 PV.',
    ),
    _CondicaoInfo(
      'Surpreendido',
      'Sentidos',
      'Fica desprevenido e não pode agir na primeira rodada do combate.',
    ),
    _CondicaoInfo(
      'Surdo',
      'Sentidos',
      '-5 em Percepção para ouvir, iniciativa -2 e falha automática para ouvir sons.',
    ),
    _CondicaoInfo(
      'Vulnerável',
      'Física',
      'Sofre -2 na Defesa e não pode aplicar bônus de escudo ou esquiva.',
    ),
  ];

  // ---------------------------------------------------------------------------
  // ABA 3: PERSONAGENS (FICHAS COMPLETAS DOS JOGADORES NA SESSÃO/CAMPANHA)
  // ---------------------------------------------------------------------------

  Widget _buildAbaPersonagens() {
    return BlocBuilder<MestreCubit, MestreState>(
      bloc: widget.cubit,
      builder: (context, state) {
        final elencoSessao = state.sessaoAtual?.elenco ?? const [];
        final convidadosCampanha =
            state.campanhaAtual?.jogadoresConvidados ?? const [];
        final idsVistos = <String>{};
        final todosPersonagens = <ElencoSessaoEntry>[];

        for (final e in elencoSessao) {
          if (idsVistos.add(e.characterId)) {
            todosPersonagens.add(e);
          }
        }
        for (final c in convidadosCampanha) {
          if (idsVistos.add(c.characterId)) {
            todosPersonagens.add(c);
          }
        }

        final filtrados = todosPersonagens.where((p) {
          if (_termoBusca.isEmpty) return true;
          return p.nomePersonagem.toLowerCase().contains(_termoBusca) ||
              p.nomeJogador.toLowerCase().contains(_termoBusca) ||
              p.classeResumo.toLowerCase().contains(_termoBusca);
        }).toList();

        if (filtrados.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.groups_2_outlined,
                    size: 44,
                    color: MestreCores.escuroOnSurfaceVariant,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    todosPersonagens.isEmpty
                        ? 'Nenhum personagem conectado nesta sessão.'
                        : 'Nenhum personagem encontrado para "$_termoBusca".',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: MestreCores.escuroOnSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                  if (todosPersonagens.isEmpty) ...[
                    const SizedBox(height: 6),
                    const Text(
                      'Quando os jogadores se conectarem via LAN, as fichas completas deles (atributos, perícias, magias, inventário e notas) aparecerão aqui.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: MestreCores.escuroOnSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: filtrados.length,
          itemBuilder: (context, index) {
            final entry = filtrados[index];
            final snap = widget.cubit.obterSnapshotFichaJogador(
              entry.characterId,
            );
            return _CardFichaCompletaPersonagemEscudo(
              key: ValueKey('escudo_ficha_${entry.characterId}'),
              cubit: widget.cubit,
              entry: entry,
              snapshotFicha: snap,
              iniciarExpandido: filtrados.length <= 2 || index == 0,
            );
          },
        );
      },
    );
  }
}

class _CardFichaCompletaPersonagemEscudo extends StatefulWidget {
  final MestreCubit cubit;
  final ElencoSessaoEntry entry;
  final Map<String, dynamic>? snapshotFicha;
  final bool iniciarExpandido;

  const _CardFichaCompletaPersonagemEscudo({
    super.key,
    required this.cubit,
    required this.entry,
    required this.snapshotFicha,
    this.iniciarExpandido = false,
  });

  @override
  State<_CardFichaCompletaPersonagemEscudo> createState() =>
      _CardFichaCompletaPersonagemEscudoState();
}

class _CardFichaCompletaPersonagemEscudoState
    extends State<_CardFichaCompletaPersonagemEscudo> {
  late final TextEditingController _notaCtrl;

  @override
  void initState() {
    super.initState();
    _notaCtrl = TextEditingController(text: widget.entry.notaRevisao ?? '');
  }

  @override
  void dispose() {
    _notaCtrl.dispose();
    super.dispose();
  }

  List<String> _lerListaStrings(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((e) {
          if (e is Map && e['nome'] != null) return e['nome'].toString();
          return e.toString();
        })
        .where((s) => s.trim().isNotEmpty)
        .toList();
  }

  List<String> _lerPoderesDoSnapshot(Map<String, dynamic>? snap) {
    if (snap == null) return const [];
    final poderes = <String>[
      ..._lerListaStrings(snap['poderesGeraisKeys']),
      ..._lerListaStrings(snap['poderesConcedidosKeys']),
    ];
    final concedidoUnico = snap['poderConcedidoKey']?.toString().trim() ?? '';
    if (concedidoUnico.isNotEmpty && !poderes.contains(concedidoUnico)) {
      poderes.add(concedidoUnico);
    }
    final classesRaw = snap['classes'];
    if (classesRaw is List) {
      for (final c in classesRaw.whereType<Map>()) {
        for (final p in _lerListaStrings(c['poderesEscolhidosKeys'])) {
          if (!poderes.contains(p)) poderes.add(p);
        }
      }
    }
    return poderes;
  }

  List<String> _lerPericiasDoSnapshot(Map<String, dynamic>? snap) {
    if (snap == null) return const [];
    final pericias = <String>[..._lerListaStrings(snap['periciasTreinadas'])];
    final classesRaw = snap['classes'];
    if (classesRaw is List) {
      for (final c in classesRaw.whereType<Map>()) {
        for (final p in _lerListaStrings(c['periciasExclusivasEscolhidas'])) {
          if (!pericias.contains(p)) pericias.add(p);
        }
      }
    }
    return pericias;
  }

  List<String> _lerArmasDetalhadas(Map<String, dynamic>? snap) {
    if (snap == null) return const [];
    final armasJson = snap['armasJson'];
    if (armasJson is List && armasJson.isNotEmpty) {
      return armasJson
          .map((a) {
            if (a is Map) {
              final nome = (a['nome'] ?? '').toString().trim();
              final dano = (a['dano'] ?? '').toString().trim();
              final crit = (a['critico'] ?? '').toString().trim();
              if (nome.isEmpty) return '';
              final extras = [
                if (dano.isNotEmpty) dano,
                if (crit.isNotEmpty) crit,
              ].join(' / ');
              return extras.isEmpty ? nome : '$nome ($extras)';
            }
            return a.toString();
          })
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return _lerListaStrings(snap['armasKeys']);
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final snap = widget.snapshotFicha;
    final pendente =
        e.statusRevisao == StatusRevisaoFicha.pendente ||
        e.statusRevisao == StatusRevisaoFicha.desatualizada;

    final attrs = snap?['atributos'] is Map
        ? Map<String, dynamic>.from(snap!['atributos'] as Map)
        : const <String, dynamic>{};
    final raca = (snap?['racaNome'] ?? snap?['racaId'] ?? '').toString().trim();
    final origem = (snap?['origemId'] ?? '').toString().trim();
    final divindade = (snap?['divindadeId'] ?? '').toString().trim();
    final alinhamento = (snap?['alinhamento'] ?? '').toString().trim();
    final tamanho = (snap?['tamanho'] ?? '').toString().trim();

    final pericias = _lerPericiasDoSnapshot(snap);
    final poderes = _lerPoderesDoSnapshot(snap);
    final magias = _lerListaStrings(snap?['magiasConhecidas']);
    final armas = _lerArmasDetalhadas(snap);
    final armadura = snap?['armaduraJson'] is Map
        ? (snap!['armaduraJson'] as Map)['nome']?.toString()
        : snap?['armaduraKey']?.toString();
    final escudo = snap?['escudoJson'] is Map
        ? (snap!['escudoJson'] as Map)['nome']?.toString()
        : snap?['escudoKey']?.toString();
    final vestidos = _lerListaStrings(snap?['itensVestidosExtras']);
    final itensMochila = _lerListaStrings(snap?['itensInventario']);
    final anotacoes = (snap?['anotacoes'] ?? '').toString().trim();
    final aparencia = (snap?['descricaoAparencia'] ?? '').toString().trim();
    final tibaresOuro = (snap?['tibaresOuro'] as num?)?.toInt() ?? 0;
    final tibaresPrata = (snap?['tibares'] as num?)?.toInt() ?? 0;
    final tibaresCobre = (snap?['tibaresCobre'] as num?)?.toInt() ?? 0;

    final identidades = <String>[
      if (raca.isNotEmpty) 'Raça: $raca',
      if (origem.isNotEmpty) 'Origem: $origem',
      if (divindade.isNotEmpty) 'Devoção: $divindade',
      if (tamanho.isNotEmpty) 'Tam: $tamanho',
      if (alinhamento.isNotEmpty) alinhamento,
    ];

    final equipamentos = <String>[
      ...armas,
      if (armadura != null && armadura.trim().isNotEmpty) 'Armadura: $armadura',
      if (escudo != null && escudo.trim().isNotEmpty) 'Escudo: $escudo',
      ...vestidos,
      ...itensMochila,
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: MestreCores.escuroSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: pendente
              ? MestreCores.statusAlertaEscuro
              : MestreCores.escuroOuro.withValues(alpha: 0.45),
        ),
      ),
      child: ExpansionTile(
        key: ValueKey('escudo_char_${e.characterId}'),
        initiallyExpanded: widget.iniciarExpandido,
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        iconColor: MestreCores.escuroOuro,
        collapsedIconColor: MestreCores.escuroOnSurfaceVariant,
        leading: CircleAvatar(
          backgroundColor: MestreCores.escuroVinho,
          child: Text(
            e.nomePersonagem.isEmpty
                ? '?'
                : e.nomePersonagem.substring(0, 1).toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                '${e.nomePersonagem} • ${e.classeResumo}',
                style: const TextStyle(
                  fontFamily: 'serif',
                  color: MestreCores.escuroOnSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.circle,
              size: 8,
              color: e.conectadoViaLan
                  ? MestreCores.statusOnlineEscuro
                  : MestreCores.statusOffline,
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _buildChipMetrica(
                'Jogador: ${e.nomeJogador}',
                MestreCores.escuroOnSurfaceVariant,
              ),
              _buildChipMetrica(
                'PV ${e.pvAtual}/${e.pvMax}',
                Colors.redAccent,
              ),
              _buildChipMetrica(
                'PM ${e.pmAtual}/${e.pmMax}',
                Colors.lightBlueAccent,
              ),
              _buildChipMetrica(
                'Def ${e.defesa}',
                MestreCores.escuroOuro,
              ),
              _buildChipMetrica(
                'Desl ${e.deslocamentoMetros.toStringAsFixed(1)}m',
                Colors.cyanAccent,
              ),
            ],
          ),
        ),
        children: [
          const Divider(color: MestreCores.escuroOutline, height: 14),
          if (pendente) ...[
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: MestreCores.statusAlertaEscuro.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: MestreCores.statusAlertaEscuro),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Ficha aguardando aprovação do Mestre',
                      style: TextStyle(
                        color: MestreCores.escuroOnSurface,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => widget.cubit.atualizarStatusRevisaoFicha(
                      e.characterId,
                      StatusRevisaoFicha.recusada,
                    ),
                    child: const Text(
                      'Recusar',
                      style: TextStyle(color: MestreCores.statusAlertaEscuro),
                    ),
                  ),
                  const SizedBox(width: 6),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: MestreCores.escuroOuro,
                      foregroundColor: MestreCores.escuroOuroTexto,
                    ),
                    onPressed: () => widget.cubit.atualizarStatusRevisaoFicha(
                      e.characterId,
                      StatusRevisaoFicha.aprovada,
                    ),
                    child: const Text('Aprovar'),
                  ),
                ],
              ),
            ),
          ],
          if (snap == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Ficha completa ainda não sincronizada via LAN para este personagem.',
                style: TextStyle(
                  color: MestreCores.escuroOnSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            )
          else ...[
            if (identidades.isNotEmpty) ...[
              Text(
                identidades.join(' • '),
                style: const TextStyle(
                  color: MestreCores.escuroOuro,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (attrs.isNotEmpty) ...[
              const Text(
                'Atributos',
                style: TextStyle(
                  color: MestreCores.escuroOnSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: attrs.entries.map((attr) {
                  final val = (attr.value as num?)?.toInt() ?? 0;
                  final fmt = val >= 0 ? '+$val' : '$val';
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: MestreCores.escuroSurfaceContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: MestreCores.escuroOutline),
                    ),
                    child: Text(
                      '${attr.key} $fmt',
                      style: const TextStyle(
                        color: MestreCores.escuroOnSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 11.5,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
            ],
            _buildBlocoFicha(
              icone: Icons.fact_check_outlined,
              titulo: 'Perícias Treinadas (${pericias.length})',
              conteudo: pericias.isEmpty
                  ? 'Nenhuma perícia treinada registrada'
                  : pericias.join(' • '),
            ),
            if (poderes.isNotEmpty)
              _buildBlocoFicha(
                icone: Icons.auto_awesome_outlined,
                titulo: 'Poderes & Habilidades (${poderes.length})',
                conteudo: poderes.join(' • '),
              ),
            _buildBlocoFicha(
              icone: Icons.menu_book_outlined,
              titulo: 'Magias Conhecidas (${magias.length})',
              conteudo: magias.isEmpty
                  ? 'Nenhuma magia aprendida'
                  : magias.join(' • '),
            ),
            _buildBlocoFicha(
              icone: Icons.backpack_outlined,
              titulo: 'Equipamento & Inventário (${equipamentos.length})',
              conteudo: equipamentos.isEmpty
                  ? 'Inventário vazio'
                  : equipamentos.join(' • '),
            ),
            if (tibaresOuro > 0 || tibaresPrata > 0 || tibaresCobre > 0)
              _buildBlocoFicha(
                icone: Icons.paid_outlined,
                titulo: 'Riqueza (Tibares)',
                conteudo:
                    '$tibaresOuro TO • $tibaresPrata T\$ • $tibaresCobre TC',
              ),
            if (aparencia.isNotEmpty)
              _buildBlocoFicha(
                icone: Icons.person_outline,
                titulo: 'Aparência',
                conteudo: aparencia,
              ),
            if (anotacoes.isNotEmpty)
              _buildBlocoFicha(
                icone: Icons.edit_note_rounded,
                titulo: 'Anotações do Jogador',
                conteudo: anotacoes,
              ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _notaCtrl,
                  style: const TextStyle(
                    color: MestreCores.escuroOnSurface,
                    fontSize: 12,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Enviar nota ao jogador',
                    labelStyle: TextStyle(
                      color: MestreCores.escuroOnSurfaceVariant,
                      fontSize: 11.5,
                    ),
                    isDense: true,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: MestreCores.escuroOutline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: MestreCores.escuroOuro),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: MestreCores.escuroOuro,
                  foregroundColor: MestreCores.escuroOuroTexto,
                ),
                icon: const Icon(Icons.send_rounded, size: 15),
                label: const Text('Enviar'),
                onPressed: () {
                  final txt = _notaCtrl.text.trim();
                  if (txt.isEmpty) return;
                  widget.cubit.enviarNotaParaJogadorLan(e.characterId, txt);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Nota enviada para ${e.nomePersonagem}!'),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChipMetrica(String texto, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: cor.withValues(alpha: 0.5), width: 0.8),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: cor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBlocoFicha({
    required IconData icone,
    required String titulo,
    required String conteudo,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: MestreCores.escuroSurfaceContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icone, size: 14, color: MestreCores.escuroOuro),
                const SizedBox(width: 6),
                Text(
                  titulo,
                  style: const TextStyle(
                    color: MestreCores.escuroOuro,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              conteudo,
              style: const TextStyle(
                color: MestreCores.escuroOnSurface,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CondicaoInfo {
  final String nome;
  final String tipo;
  final String efeito;

  const _CondicaoInfo(this.nome, this.tipo, this.efeito);
}
