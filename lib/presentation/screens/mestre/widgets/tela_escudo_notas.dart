import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../domain/entities/mestre/modelos_mestre.dart';
import '../../../controllers/mestre_controller/mestre_cubit.dart';
import '../../../controllers/mestre_controller/mestre_state.dart';
import '../theme/mestre_theme.dart';

/// PARTE 5 — Tela "Escudo e Notas" (Tormenta 20 - Android/Flutter)
/// Consulta rápida em 2 toques, busca global e alta densidade de informação.
/// Abas: 1. Condições | 2. Perigos | 3. Nomes Aleatórios | 4. Regras de Combate | 5. Notas da Sessão.
class TelaEscudoNotas extends StatefulWidget {
  final MestreState state;
  final MestreCubit cubit;

  const TelaEscudoNotas({
    super.key,
    required this.state,
    required this.cubit,
  });

  @override
  State<TelaEscudoNotas> createState() => _TelaEscudoNotasState();
}

class _TelaEscudoNotasState extends State<TelaEscudoNotas> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _buscaController = TextEditingController();
  String _termoBusca = '';

  // Filtros do Gerador de Nomes
  String _racaSelecionada = 'Humano';
  String _generoSelecionado = 'Neutro';
  String _tomSelecionado = 'Sério';

  // Checklist de Nova Tarefa
  final TextEditingController _novaTarefaController = TextEditingController();
  final TextEditingController _notasEditorController = TextEditingController();

  final Set<String> _condicoesFavoritas = {'Caído', 'Desprevenido', 'Sangrando', 'Abalado'};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _notasEditorController.text = widget.state.sessaoAtual?.notasSessaoTexto ?? '';
  }

  @override
  void didUpdateWidget(covariant TelaEscudoNotas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.sessaoAtual?.id != widget.state.sessaoAtual?.id) {
      _notasEditorController.text = widget.state.sessaoAtual?.notasSessaoTexto ?? '';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _buscaController.dispose();
    _novaTarefaController.dispose();
    _notasEditorController.dispose();
    super.dispose();
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
        style: const TextStyle(color: MestreCores.escuroOnSurface, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Busca rápida no Escudo (condição, perigo, manobra, CD)...',
          hintStyle: const TextStyle(color: MestreCores.escuroOnSurfaceVariant, fontSize: 12),
          prefixIcon: const Icon(Icons.search, size: 18, color: MestreCores.escuroOuro),
          suffixIcon: _termoBusca.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 16, color: MestreCores.escuroOnSurfaceVariant),
                  onPressed: () {
                    _buscaController.clear();
                    setState(() => _termoBusca = '');
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          filled: true,
          fillColor: MestreCores.escuroSurfaceContainer,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: MestreCores.escuroOuro, width: 1.2),
          ),
        ),
        onChanged: (val) => setState(() => _termoBusca = val.toLowerCase().trim()),
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
          Tab(icon: Icon(Icons.warning_amber_outlined, size: 16), text: 'Perigos'),
          Tab(icon: Icon(Icons.badge_outlined, size: 16), text: 'Nomes'),
          Tab(icon: Icon(Icons.gavel_outlined, size: 16), text: 'Regras de Combate'),
          Tab(icon: Icon(Icons.note_alt_outlined, size: 16), text: 'Notas da Sessão'),
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
      return c.nome.toLowerCase().contains(_termoBusca) || c.efeito.toLowerCase().contains(_termoBusca);
    }).toList();

    // Ordenação: favoritas/fixadas primeiro
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
            side: BorderSide(color: ehFav ? MestreCores.escuroOuro.withValues(alpha: 0.5) : MestreCores.escuroOutline),
          ),
          child: ExpansionTile(
            key: PageStorageKey('cond_${cond.nome}'),
            tilePadding: const EdgeInsets.symmetric(horizontal: 12),
            leading: Icon(
              ehFav ? Icons.star : Icons.star_border,
              size: 18,
              color: ehFav ? MestreCores.escuroOuro : MestreCores.escuroOnSurfaceVariant,
            ),
            title: Row(
              children: [
                Text(
                  cond.nome,
                  style: TextStyle(
                    fontFamily: 'serif',
                    color: ehFav ? MestreCores.escuroOuro : MestreCores.escuroOnSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: MestreCores.escuroVinho.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(cond.tipo, style: const TextStyle(color: MestreCores.escuroOnSurface, fontSize: 9)),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.person_add_outlined, size: 16, color: MestreCores.escuroOuro),
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
                      style: const TextStyle(color: MestreCores.escuroOnSurfaceVariant, fontSize: 12, height: 1.4),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          icon: Icon(ehFav ? Icons.star_border : Icons.star, size: 14),
                          label: Text(ehFav ? 'Desafixar' : 'Fixar no topo', style: const TextStyle(fontSize: 11)),
                          style: TextButton.styleFrom(foregroundColor: MestreCores.escuroOuro),
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
    final tokens = widget.state.mapaAtual?.tokens ?? [];
    if (tokens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nenhum combatente presente no mapa atual.')));
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: MestreCores.escuroSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Aplicar "$condicao" a qual combatente?', style: const TextStyle(fontFamily: 'serif', color: MestreCores.escuroOnSurface, fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...tokens.map((t) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: t.ehHeroi ? MestreCores.escuroVinho : MestreCores.statusAlertaEscuro,
                    radius: 14,
                    child: Text(t.nome.substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 11)),
                  ),
                  title: Text(t.nome, style: const TextStyle(color: MestreCores.escuroOnSurface, fontSize: 13)),
                  onTap: () {
                    widget.cubit.adicionarCondicaoToken(t.id, condicao);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"$condicao" aplicada em ${t.nome}!')));
                  },
                )),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ABA 2: PERIGOS (TERRENO, ARMADILHA, AMBIENTE COM CD E DANO EM DESTAQUE)
  // ---------------------------------------------------------------------------

  Widget _buildAbaPerigos() {
    final perigos = widget.state.perigos.where((p) {
      if (_termoBusca.isEmpty) return true;
      return p.nome.toLowerCase().contains(_termoBusca) || p.descricao.toLowerCase().contains(_termoBusca);
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
            side: BorderSide(color: p.fixado ? MestreCores.escuroOuro.withValues(alpha: 0.6) : MestreCores.escuroOutline),
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
                                : (p.tipo == 'Terreno' ? Icons.terrain : Icons.cloud_outlined),
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
                      icon: Icon(p.fixado ? Icons.push_pin : Icons.push_pin_outlined, size: 16),
                      color: p.fixado ? MestreCores.escuroOuro : MestreCores.escuroOnSurfaceVariant,
                      onPressed: () => widget.cubit.alternarFixarPerigo(p.id),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: MestreCores.escuroVinho,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(p.cd, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: MestreCores.statusAlertaEscuro.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: MestreCores.statusAlertaEscuro),
                      ),
                      child: Text('Dano: ${p.dano}', style: const TextStyle(color: MestreCores.statusAlertaEscuro, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  p.descricao,
                  style: const TextStyle(color: MestreCores.escuroOnSurfaceVariant, fontSize: 12, height: 1.3),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // ABA 3: NOMES ALEATÓRIOS (FILTROS, GERAR, HISTÓRICO, FAVORITAR)
  // ---------------------------------------------------------------------------

  Widget _buildAbaNomesAleatorios() {
    const racas = ['Humano', 'Elfo', 'Anão', 'Qareen', 'Minotauro', 'Lefou', 'Goblin', 'Dahllan'];
    const generos = ['Masculino', 'Feminino', 'Neutro'];
    const tons = ['Sério', 'Épico', 'Rústico', 'Cômico'];

    final nomeAtual = widget.state.nomeGeradoAtual ?? 'Clique em Gerar';
    final ehFav = widget.state.nomesFavoritos.contains(nomeAtual);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Seletor de Raça
        const Text('Origem / Raça:', style: TextStyle(color: MestreCores.escuroOnSurface, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: racas.map((r) => ChoiceChip(
                label: Text(r, style: const TextStyle(fontSize: 11)),
                selected: _racaSelecionada == r,
                selectedColor: MestreCores.escuroOuro,
                onSelected: (_) => setState(() => _racaSelecionada = r),
              )).toList(),
        ),
        const SizedBox(height: 12),

        // Gênero e Tom
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Gênero:', style: TextStyle(color: MestreCores.escuroOnSurface, fontSize: 11, fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    value: _generoSelecionado,
                    dropdownColor: MestreCores.escuroSurfaceContainer,
                    isExpanded: true,
                    style: const TextStyle(color: MestreCores.escuroOnSurface, fontSize: 12),
                    items: generos.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
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
                  const Text('Tom:', style: TextStyle(color: MestreCores.escuroOnSurface, fontSize: 11, fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    value: _tomSelecionado,
                    dropdownColor: MestreCores.escuroSurfaceContainer,
                    isExpanded: true,
                    style: const TextStyle(color: MestreCores.escuroOnSurface, fontSize: 12),
                    items: tons.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
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

        // Display do Nome Gerado Grande
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: MestreCores.escuroSurfaceContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: MestreCores.escuroOuro.withValues(alpha: 0.6)),
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
                    icon: const Icon(Icons.copy, size: 18, color: MestreCores.escuroOnSurfaceVariant),
                    tooltip: 'Copiar nome',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: nomeAtual));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nome copiado!')));
                    },
                  ),
                  IconButton(
                    icon: Icon(ehFav ? Icons.favorite : Icons.favorite_border, size: 18),
                    color: ehFav ? Colors.redAccent : MestreCores.escuroOnSurfaceVariant,
                    tooltip: 'Favoritar nome',
                    onPressed: () => widget.cubit.favoritarNome(nomeAtual),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Botão Grande Gerar
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: MestreCores.escuroOuro,
            foregroundColor: MestreCores.escuroOuroTexto,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.casino_outlined, size: 20),
          label: const Text('GERAR NOME', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          onPressed: () {
            widget.cubit.gerarNomeAleatorio(
              raca: _racaSelecionada,
              genero: _generoSelecionado,
              tom: _tomSelecionado,
            );
          },
        ),
        const SizedBox(height: 16),

        // Histórico Recente
        if (widget.state.historicoNomes.isNotEmpty) ...[
          const Text('Histórico Recente na Sessão:', style: TextStyle(color: MestreCores.escuroOnSurfaceVariant, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: widget.state.historicoNomes.map((n) {
              return ActionChip(
                label: Text(n, style: const TextStyle(fontSize: 10)),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: n));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"$n" copiado!')));
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // ABA 4: REGRAS DE COMBATE (ACORDEÃO RECOLHÍVEL E TABELAS COM CABEÇALHO FIXO)
  // ---------------------------------------------------------------------------

  Widget _buildAbaRegrasCombate() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _buildSecaoRegraCombate(
          titulo: 'Economia de Ações por Turno (R60)',
          corpo: '• (1 Padrão + 1 Movimento) OU 2 Movimentos OU 1 Completa.\n'
              '• Ações Livres: qualquer quantidade no próprio turno (mestre pode limitar).\n'
              '• Reações: a qualquer momento, mesmo fora do turno ou sem poder agir.',
        ),
        _buildSecaoRegraCombate(
          titulo: 'Ações Padrão & Manobras de Combate (R61)',
          corpo: '• Agredir: corpo a corpo (1,5m) ou à distância (-5 se alvo engajado corpo a corpo sem Mirar).\n'
              '• Manobras: Agarrar, Derrubar, Desarmar, Empurrar, Quebrar (teste de Luta oposto).\n'
              '• Fintar: Enganação vs Reflexos. Sucesso: alvo desprevenido contra seu próximo ataque.\n'
              '• Atropelar: avança pelo espaço do alvo (teste oposto de manobra). Livre na Investida.',
        ),
        _buildSecaoRegraCombate(
          titulo: 'Modificadores de Combate (R74 & R75)',
          corpo: '• Atacante Caído: -5 no ataque corpo a corpo.\n'
              '• Alvo Caído: -5 na Defesa vs corpo a corpo / +5 vs distância.\n'
              '• Desprevenido: -5 na Defesa e Reflexos.\n'
              '• Flanquear (R75): dois aliados em lados opostos ganham +2 no ataque corpo a corpo.\n'
              '• Cobertura: Leve (+5 Defesa) / Total (não pode ser atacado).\n'
              '• Camuflagem: Leve (20% de falha) / Total ou Cego (50% de falha).',
        ),
        _buildSecaoRegraCombate(
          titulo: 'Exemplos de Dificuldade (CD de Testes)',
          corpo: '• Fácil: CD 10 (tarefa simples para novatos).\n'
              '• Médio: CD 15 (desafio razoável de aventureiro).\n'
              '• Difícil: CD 20 (exige treino ou bônus).\n'
              '• Formidável: CD 25 (para heróis veteranos).\n'
              '• Heroico: CD 30 (feito lendário).\n'
              '• Quase Impossível: CD 35+ (nível épico).',
        ),
      ],
    );
  }

  Widget _buildSecaoRegraCombate({required String titulo, required String corpo}) {
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
              style: const TextStyle(color: MestreCores.escuroOnSurfaceVariant, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ABA 5: NOTAS DA SESSÃO (EDITOR SIMPLES + CHECKLIST VINCULADO À SESSÃO)
  // ---------------------------------------------------------------------------

  Widget _buildAbaNotas() {
    final sessao = widget.state.sessaoAtual;
    if (sessao == null) {
      return const Center(child: Text('Nenhuma sessão ativa.', style: TextStyle(color: MestreCores.escuroOnSurfaceVariant)));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Notas de: ${sessao.titulo}',
                style: const TextStyle(fontFamily: 'serif', color: MestreCores.escuroOnSurface, fontSize: 14, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: Icon(sessao.notaFixada ? Icons.push_pin : Icons.push_pin_outlined, size: 18),
              color: sessao.notaFixada ? MestreCores.escuroOuro : MestreCores.escuroOnSurfaceVariant,
              tooltip: 'Fixar nota no topo',
              onPressed: () => widget.cubit.alternarFixarNotaSessao(),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Checklist de Metas da Sessão
        const Text('Checklist de Metas da Sessão:', style: TextStyle(color: MestreCores.escuroOuro, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        ...sessao.checklistNotas.map((it) => CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(
                it.texto,
                style: TextStyle(
                  color: it.concluido ? MestreCores.escuroOnSurfaceVariant : MestreCores.escuroOnSurface,
                  decoration: it.concluido ? TextDecoration.lineThrough : null,
                  fontSize: 12,
                ),
              ),
              value: it.concluido,
              activeColor: MestreCores.escuroOuro,
              checkColor: MestreCores.escuroOuroTexto,
              secondary: IconButton(
                icon: const Icon(Icons.close, size: 14, color: MestreCores.escuroOnSurfaceVariant),
                onPressed: () => widget.cubit.removerItemChecklist(it.id),
              ),
              onChanged: (_) => widget.cubit.alternarItemChecklist(it.id),
            )),

        // Adicionar novo item no checklist
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _novaTarefaController,
                style: const TextStyle(color: MestreCores.escuroOnSurface, fontSize: 12),
                decoration: const InputDecoration(
                  hintText: 'Adicionar meta da sessão...',
                  hintStyle: TextStyle(color: MestreCores.escuroOnSurfaceVariant, fontSize: 11),
                  isDense: true,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle, color: MestreCores.escuroOuro),
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

        // Editor de Anotações Livres
        const Text('Anotações Livres:', style: TextStyle(color: MestreCores.escuroOuro, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: _notasEditorController,
          maxLines: 8,
          style: const TextStyle(color: MestreCores.escuroOnSurface, fontSize: 12, height: 1.4),
          decoration: const InputDecoration(
            hintText: 'Escreva detalhes do ambiente, segredos dos NPCs, pistas reveladas...',
            hintStyle: TextStyle(color: Colors.white24),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: MestreCores.escuroOutline)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: MestreCores.escuroOuro)),
          ),
          onChanged: (texto) => widget.cubit.atualizarNotasSessao(texto),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // CATÁLOGO COMPLETO DAS 28+ CONDIÇÕES DE TORMENTA 20
  // ---------------------------------------------------------------------------

  static const List<_CondicaoInfo> _catalogoCondicoesT20 = [
    _CondicaoInfo('Abalado', 'Mental', '-2 em testes de perícia. Se ficar abalado novamente, fica Amedrontado.'),
    _CondicaoInfo('Agarrado', 'Física', 'Desprevenido e imóvel. -2 nos testes de ataque e só pode usar armas leves.'),
    _CondicaoInfo('Alquebrado', 'Mental', 'O custo em PM de todas as suas habilidades e magias aumenta em +1.'),
    _CondicaoInfo('Amedrontado', 'Mental', '-5 em testes de perícia e não pode se aproximar voluntariamente da fonte do medo.'),
    _CondicaoInfo('Atordoado', 'Mental', 'Fica desprevenido e não pode realizar nenhuma ação no seu turno.'),
    _CondicaoInfo('Caído', 'Física', '-5 no ataque corpo a corpo, 1,5m deslocamento; Defesa -5 vs corpo a corpo e +5 vs distância.'),
    _CondicaoInfo('Cego', 'Sentidos', 'Desprevenido, -5 em perícias baseadas em Força/Destreza, 50% de falha em ataques.'),
    _CondicaoInfo('Confuso', 'Mental', 'Comportamento aleatório no início do turno (1d6: ataca aliado, fica parado, etc.).'),
    _CondicaoInfo('Debilitado', 'Física', '-5 em testes de atributos físicos (Força, Destreza, Constituição) e perícias associadas.'),
    _CondicaoInfo('Desprevenido', 'Física', '-5 na Defesa e em Reflexos.'),
    _CondicaoInfo('Enfeitiçado', 'Mental', 'Trata o conjurador como um amigo próximo e não realiza ações hostis contra ele.'),
    _CondicaoInfo('Enredado', 'Física', 'Deslocamento reduzido à metade, não pode correr nem fazer investida, -2 no ataque.'),
    _CondicaoInfo('Esmagado', 'Física', 'Sofre dano contínuo de impacto e fica indefeso até escapar.'),
    _CondicaoInfo('Esmorecido', 'Mental', '-5 em testes de atributos mentais (Inteligência, Sabedoria, Carisma).'),
    _CondicaoInfo('Exausto', 'Física', 'Debilitado, lento e vulnerável. Descanso de 1 hora reduz para Fatigado.'),
    _CondicaoInfo('Fascinado', 'Mental', '-5 na Percepção e não pode realizar ações além de observar o efeito fascinante.'),
    _CondicaoInfo('Fatigado', 'Física', '-2 em testes de perícia. Não pode correr nem fazer investida. Se fatigar novamente, fica Exausto.'),
    _CondicaoInfo('Frágil', 'Física', 'Redução de Dano (RD) reduzida pela metade e sofre +50% de dano de ataques físicos.'),
    _CondicaoInfo('Furtivo', 'Sentidos', 'Inimigos não sabem sua localização exata até realizarem teste de Percepção contra sua Furtividade.'),
    _CondicaoInfo('Imobilizado', 'Física', 'Desprevenido, não pode se mover nem falar. Apenas ações mentais são permitidas.'),
    _CondicaoInfo('Inconsciente', 'Sentidos', 'Indefeso, desmaia e não pode realizar ações. Ocorre com 0 ou menos PV.'),
    _CondicaoInfo('Indefeso', 'Física', 'Desprevenido, sofre -10 na Defesa e falha automaticamente em testes de Reflexos.'),
    _CondicaoInfo('Lento', 'Física', 'Todas as formas de deslocamento são reduzidas à metade e não pode correr.'),
    _CondicaoInfo('Ofuscado', 'Sentidos', '-2 em testes de ataque e em testes de Percepção baseados em visão.'),
    _CondicaoInfo('Paralisado', 'Física', 'Fica imóvel e indefeso. Apenas ações puramente mentais são possíveis.'),
    _CondicaoInfo('Pasmo', 'Mental', 'Não pode realizar nenhuma ação durante a rodada (mantém suas defesas normais).'),
    _CondicaoInfo('Petrificado', 'Física', 'Transformado em estátua de pedra: inconsciente e com RD 10 contra todos os danos.'),
    _CondicaoInfo('Sangrando', 'Física', 'No início de cada turno, faz teste de Constituição (CD 15) ou perde 1d6 PV.'),
    _CondicaoInfo('Surpreendido', 'Sentidos', 'Fica desprevenido e não pode agir na primeira rodada do combate.'),
    _CondicaoInfo('Surdo', 'Sentidos', '-5 em Percepção para ouvir, iniciativa -2 e falha automática para ouvir sons.'),
    _CondicaoInfo('Vulnerável', 'Física', 'Sofre -2 na Defesa e não pode aplicar bônus de escudo ou esquiva.'),
  ];
}

class _CondicaoInfo {
  final String nome;
  final String tipo;
  final String efeito;

  const _CondicaoInfo(this.nome, this.tipo, this.efeito);
}
