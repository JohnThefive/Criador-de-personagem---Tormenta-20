import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/entities/mestre/modelos_mestre.dart';
import '../../../controllers/mestre_controller/mestre_cubit.dart';
import '../../../controllers/mestre_controller/mestre_state.dart';
import '../theme/mestre_theme.dart';

/// PARTE 2 — Tela "Mapas" (Biblioteca + Seleção) (Tormenta 20 - Android/Flutter)
/// Responsabilidade ÚNICA: escolher um mapa já criado e criar a partir dele.
/// Não contém editor aqui.
class TelaBibliotecaMapas extends StatefulWidget {
  final MestreCubit cubit;
  final void Function(MapaBatalhaMestre mapa) onAbrirMesaJogo;
  final void Function({MapaBatalhaMestre? mapaParaEditar}) onAbrirEditorMapa;

  const TelaBibliotecaMapas({
    super.key,
    required this.cubit,
    required this.onAbrirMesaJogo,
    required this.onAbrirEditorMapa,
  });

  @override
  State<TelaBibliotecaMapas> createState() => _TelaBibliotecaMapasState();
}

class _TelaBibliotecaMapasState extends State<TelaBibliotecaMapas> {
  String _filtroBusca = '';
  String _criterioOrdenacao = 'recentes'; // 'recentes', 'nome', 'tamanho'

  List<MapaBatalhaMestre>? _cachedOrigem;
  String _cachedFiltro = '';
  String _cachedCriterio = '';
  List<MapaBatalhaMestre> _cachedOrdenados = const [];

  List<MapaBatalhaMestre> _obterMapasOrdenados(
    List<MapaBatalhaMestre> todosMapas,
  ) {
    if (identical(_cachedOrigem, todosMapas) &&
        _cachedFiltro == _filtroBusca &&
        _cachedCriterio == _criterioOrdenacao) {
      return _cachedOrdenados;
    }

    final termo = _filtroBusca.trim().toLowerCase();
    final filtrados = todosMapas.where((m) {
      if (termo.isEmpty) return true;
      return m.nome.toLowerCase().contains(termo);
    }).toList();

    if (_criterioOrdenacao == 'nome') {
      filtrados.sort((a, b) => a.nome.compareTo(b.nome));
    } else if (_criterioOrdenacao == 'tamanho') {
      filtrados.sort(
        (a, b) => (b.largura * b.altura).compareTo(a.largura * a.altura),
      );
    } else {
      filtrados.sort((a, b) => b.criadoEm.compareTo(a.criadoEm));
    }

    _cachedOrigem = todosMapas;
    _cachedFiltro = _filtroBusca;
    _cachedCriterio = _criterioOrdenacao;
    _cachedOrdenados = filtrados;
    return filtrados;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MestreCores.escuroBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildBarraBuscaEOrdenacao(context),
            Expanded(
              child: BlocSelector<MestreCubit, MestreState,
                  List<MapaBatalhaMestre>>(
                bloc: widget.cubit,
                selector: (s) =>
                    s.aventuraAtual?.mapas ?? const <MapaBatalhaMestre>[],
                builder: (context, todosMapas) {
                  final mapasFiltrados = _obterMapasOrdenados(todosMapas);
                  if (mapasFiltrados.isEmpty) {
                    return _buildEstadoVazio(context);
                  }
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final isTablet = constraints.maxWidth >= 600;
                      if (isTablet) {
                        final colunas = constraints.maxWidth >= 900 ? 4 : 3;
                        return GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: colunas,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.15,
                          ),
                          itemCount: mapasFiltrados.length,
                          itemBuilder: (context, idx) => _buildCardMapaTablet(
                            context,
                            mapasFiltrados[idx],
                          ),
                        );
                      } else {
                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          itemCount: mapasFiltrados.length,
                          itemBuilder: (context, idx) => _buildCardMapaCelular(
                            context,
                            mapasFiltrados[idx],
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: MestreCores.escuroOuro,
        foregroundColor: MestreCores.escuroOuroTexto,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text(
          '+ Novo mapa',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () => widget.onAbrirEditorMapa(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BARRA DE BUSCA E ORDENAÇÃO
  // ---------------------------------------------------------------------------

  Widget _buildBarraBuscaEOrdenacao(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      color: MestreCores.escuroSurface,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              style: const TextStyle(
                color: MestreCores.escuroOnSurface,
                fontSize: 13,
              ),
              decoration: InputDecoration(
                hintText: 'Buscar mapa...',
                hintStyle: const TextStyle(
                  color: MestreCores.escuroOnSurfaceVariant,
                  fontSize: 13,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  size: 18,
                  color: MestreCores.escuroOnSurfaceVariant,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                filled: true,
                fillColor: MestreCores.escuroSurfaceContainer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: MestreCores.escuroOutline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: MestreCores.escuroOutline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: MestreCores.escuroOuro),
                ),
              ),
              onChanged: (val) => setState(() => _filtroBusca = val),
            ),
          ),
          const SizedBox(width: 10),
          DropdownButton<String>(
            value: _criterioOrdenacao,
            dropdownColor: MestreCores.escuroSurfaceContainer,
            underline: const SizedBox.shrink(),
            icon: const Icon(
              Icons.sort,
              color: MestreCores.escuroOuro,
              size: 20,
            ),
            style: const TextStyle(
              color: MestreCores.escuroOnSurface,
              fontSize: 12,
            ),
            items: const [
              DropdownMenuItem(value: 'recentes', child: Text('Mais recentes')),
              DropdownMenuItem(value: 'nome', child: Text('Nome A-Z')),
              DropdownMenuItem(
                value: 'tamanho',
                child: Text('Tamanho do Grid'),
              ),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _criterioOrdenacao = val);
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CARD DE MAPA (CELULAR: LISTA DE 1 COLUNA COM MINIATURA LARGA)
  // ---------------------------------------------------------------------------

  Widget _buildCardMapaCelular(BuildContext context, MapaBatalhaMestre mapa) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: MestreCores.escuroSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: MestreCores.escuroOutline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => widget.onAbrirMesaJogo(mapa),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 120,
              child: _buildMiniaturaGrid(mapa),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mapa.nome,
                          style: const TextStyle(
                            fontFamily: 'serif',
                            color: MestreCores.escuroOnSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Grid: ${mapa.largura}×${mapa.altura} (${(mapa.largura * 1.5).toStringAsFixed(1)}m × ${(mapa.altura * 1.5).toStringAsFixed(1)}m)',
                              style: const TextStyle(
                                color: MestreCores.escuroOnSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '•',
                              style: TextStyle(
                                color: MestreCores.escuroOnSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${mapa.tokens.length} combatentes',
                              style: const TextStyle(
                                color: MestreCores.escuroOuro,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildMenuOpcoesMapa(context, mapa),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CARD DE MAPA (TABLET: GRADE DE 3-4 COLUNAS)
  // ---------------------------------------------------------------------------

  Widget _buildCardMapaTablet(BuildContext context, MapaBatalhaMestre mapa) {
    return Card(
      color: MestreCores.escuroSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: MestreCores.escuroOutline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => widget.onAbrirMesaJogo(mapa),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _buildMiniaturaGrid(mapa)),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mapa.nome,
                          style: const TextStyle(
                            fontFamily: 'serif',
                            color: MestreCores.escuroOnSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${mapa.largura}×${mapa.altura} • ${mapa.tokens.length} tokens',
                          style: const TextStyle(
                            color: MestreCores.escuroOnSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildMenuOpcoesMapa(context, mapa),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MINIATURA DO GRID
  // ---------------------------------------------------------------------------

  Widget _buildMiniaturaGrid(MapaBatalhaMestre mapa) {
    final corFundo = MestreCores.corFundoPreset(mapa.presetFundo);

    return Container(
      color: corFundo,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _MiniaturaGridPainter(
                largura: mapa.largura,
                altura: mapa.altura,
                opacidade: mapa.opacidadeGrid,
              ),
            ),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                '${mapa.largura}×${mapa.altura}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MENU ⋮: RENOMEAR, DUPLICAR, EDITAR (PARTE 3), EXCLUIR
  // ---------------------------------------------------------------------------

  Widget _buildMenuOpcoesMapa(BuildContext context, MapaBatalhaMestre mapa) {
    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.more_vert,
        size: 18,
        color: MestreCores.escuroOnSurfaceVariant,
      ),
      color: MestreCores.escuroSurfaceContainer,
      onSelected: (val) {
        if (val == 'editar') {
          widget.onAbrirEditorMapa(mapaParaEditar: mapa);
        } else if (val == 'renomear') {
          _exibirDialogRenomearMapa(context, mapa);
        } else if (val == 'duplicar') {
          widget.cubit.duplicarMapa(mapa.id);
        } else if (val == 'excluir') {
          _confirmarExclusaoMapa(context, mapa);
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'editar',
          child: Text(
            'Editar (Grade & Imagem)',
            style: TextStyle(color: MestreCores.escuroOuro),
          ),
        ),
        PopupMenuItem(
          value: 'renomear',
          child: Text(
            'Renomear',
            style: TextStyle(color: MestreCores.escuroOnSurface),
          ),
        ),
        PopupMenuItem(
          value: 'duplicar',
          child: Text(
            'Duplicar',
            style: TextStyle(color: MestreCores.escuroOnSurface),
          ),
        ),
        PopupMenuItem(
          value: 'excluir',
          child: Text(
            'Excluir',
            style: TextStyle(color: MestreCores.statusAlertaEscuro),
          ),
        ),
      ],
    );
  }

  void _exibirDialogRenomearMapa(
    BuildContext context,
    MapaBatalhaMestre mapa,
  ) {
    showDialog(
      context: context,
      builder: (_) => _DialogRenomearMapa(
        nomeInicial: mapa.nome,
        onSalvar: (novoNome) => widget.cubit.renomearMapa(mapa.id, novoNome),
      ),
    );
  }

  void _confirmarExclusaoMapa(BuildContext context, MapaBatalhaMestre mapa) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MestreCores.escuroSurface,
        title: const Text(
          'Excluir Mapa',
          style: TextStyle(color: MestreCores.escuroOnSurface),
        ),
        content: Text(
          'Tem certeza que deseja excluir o mapa "${mapa.nome}"?',
          style: const TextStyle(color: MestreCores.escuroOnSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: MestreCores.escuroOnSurfaceVariant),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: MestreCores.statusAlertaEscuro,
            ),
            onPressed: () {
              widget.cubit.excluirMapa(mapa.id);
              Navigator.pop(ctx);
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ESTADO VAZIO
  // ---------------------------------------------------------------------------

  Widget _buildEstadoVazio(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.map_outlined,
              size: 54,
              color: MestreCores.escuroOnSurfaceVariant,
            ),
            const SizedBox(height: 14),
            const Text(
              'Nenhum mapa ainda',
              style: TextStyle(
                fontFamily: 'serif',
                color: MestreCores.escuroOnSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Crie um mapa tático com grid e imagem para a sua sessão.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: MestreCores.escuroOnSurfaceVariant,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: MestreCores.escuroOuro,
                foregroundColor: MestreCores.escuroOuroTexto,
                minimumSize: const Size(180, 48),
              ),
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text(
                'Criar mapa',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () => widget.onAbrirEditorMapa(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogRenomearMapa extends StatefulWidget {
  final String nomeInicial;
  final void Function(String novoNome) onSalvar;

  const _DialogRenomearMapa({
    required this.nomeInicial,
    required this.onSalvar,
  });

  @override
  State<_DialogRenomearMapa> createState() => _DialogRenomearMapaState();
}

class _DialogRenomearMapaState extends State<_DialogRenomearMapa> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.nomeInicial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: MestreCores.escuroSurface,
      title: const Text(
        'Renomear Mapa',
        style: TextStyle(color: MestreCores.escuroOnSurface),
      ),
      content: TextField(
        controller: _controller,
        style: const TextStyle(color: MestreCores.escuroOnSurface),
        decoration: const InputDecoration(
          labelText: 'Novo nome do mapa',
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: MestreCores.escuroOutline),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: MestreCores.escuroOuro),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: MestreCores.escuroOnSurfaceVariant),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: MestreCores.escuroOuro,
            foregroundColor: MestreCores.escuroOuroTexto,
          ),
          onPressed: () {
            widget.onSalvar(_controller.text);
            Navigator.pop(context);
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _MiniaturaGridPainter extends CustomPainter {
  final int largura;
  final int altura;
  final double opacidade;

  _MiniaturaGridPainter({
    required this.largura,
    required this.altura,
    required this.opacidade,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color =
          Colors.white.withValues(alpha: (opacidade * 0.4).clamp(0.05, 0.5))
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final cellW = size.width / largura;
    final cellH = size.height / altura;

    for (int x = 0; x <= largura; x++) {
      canvas.drawLine(
        Offset(x * cellW, 0),
        Offset(x * cellW, size.height),
        paint,
      );
    }
    for (int y = 0; y <= altura; y++) {
      canvas.drawLine(
        Offset(0, y * cellH),
        Offset(size.width, y * cellH),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MiniaturaGridPainter oldDelegate) {
    return oldDelegate.largura != largura ||
        oldDelegate.altura != altura ||
        oldDelegate.opacidade != opacidade;
  }
}
