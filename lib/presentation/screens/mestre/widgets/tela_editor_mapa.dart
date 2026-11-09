import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../domain/entities/combate/grid_tatico.dart';
import '../../../../domain/entities/mestre/modelos_mestre.dart';
import '../../../controllers/mestre_controller/mestre_cubit.dart';
import '../theme/mestre_theme.dart';

/// PARTE 3 — Tela "Criar/Editar mapa" (Tormenta 20 - Android/Flutter)
/// Tela cheia com canvas de pré-visualização no topo com pinch-zoom e pan.
/// Controles: celular em painel inferior/abas; tablet em painel lateral direito de 320 dp.
class TelaEditorMapa extends StatefulWidget {
  final MapaBatalhaMestre? mapaOriginal;
  final MestreCubit cubit;
  final VoidCallback onSalvo;

  const TelaEditorMapa({
    super.key,
    this.mapaOriginal,
    required this.cubit,
    required this.onSalvo,
  });

  @override
  State<TelaEditorMapa> createState() => _TelaEditorMapaState();
}

class _TelaEditorMapaState extends State<TelaEditorMapa> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _nomeController;
  late TextEditingController _notasController;

  late int _largura;
  late int _altura;
  late double _opacidadeGrid;
  late bool _gridVisivel;
  late PresetFundoMapa _presetFundo;
  String? _imagemCaminhoLocal;
  late double _ajusteOffsetX;
  late double _ajusteOffsetY;
  late double _ajusteEscala;
  late double _ajusteRotacaoGraus;
  late String _corFundoHex;
  late bool _comecarComTudoOculto;
  bool _houveAlteracoes = false;
  bool _imagemGrandeAlerta = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final m = widget.mapaOriginal;

    _largura = m?.largura ?? 16;
    _altura = m?.altura ?? 12;
    _opacidadeGrid = m?.opacidadeGrid ?? 0.4;
    _gridVisivel = m?.gridVisivel ?? true;
    _presetFundo = m?.presetFundo ?? PresetFundoMapa.masmorraPedra;
    _imagemCaminhoLocal = m?.imagemCaminhoLocal;
    _ajusteOffsetX = m?.ajusteOffsetX ?? 0.0;
    _ajusteOffsetY = m?.ajusteOffsetY ?? 0.0;
    _ajusteEscala = m?.ajusteEscala ?? 1.0;
    _ajusteRotacaoGraus = m?.ajusteRotacaoGraus ?? 0.0;
    _corFundoHex = m?.corFundoHex ?? '#1E1E24';
    _comecarComTudoOculto = m != null && m.celulasReveladas.isEmpty;

    _nomeController = TextEditingController(text: m?.nome ?? 'Novo Mapa Tático');
    _notasController = TextEditingController(text: m?.notas ?? '');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nomeController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  void _marcarAlteracao() {
    if (!_houveAlteracoes) {
      setState(() => _houveAlteracoes = true);
    }
  }

  void _salvar() {
    final nome = _nomeController.text.trim().isEmpty ? 'Mapa Sem Nome' : _nomeController.text.trim();
    final celulasReveladas = <Posicao2D>{};
    if (!_comecarComTudoOculto) {
      for (int y = 0; y < _altura; y++) {
        for (int x = 0; x < _largura; x++) {
          celulasReveladas.add(Posicao2D(x, y));
        }
      }
    }

    if (widget.mapaOriginal != null) {
      final mapaEditado = widget.mapaOriginal!.copyWith(
        nome: nome,
        largura: _largura,
        altura: _altura,
        presetFundo: _presetFundo,
        imagemCaminhoLocal: _imagemCaminhoLocal,
        opacidadeGrid: _opacidadeGrid,
        gridVisivel: _gridVisivel,
        ajusteOffsetX: _ajusteOffsetX,
        ajusteOffsetY: _ajusteOffsetY,
        ajusteEscala: _ajusteEscala,
        ajusteRotacaoGraus: _ajusteRotacaoGraus,
        corFundoHex: _corFundoHex,
        notas: _notasController.text.trim(),
        celulasReveladas: celulasReveladas,
      );
      widget.cubit.salvarConfiguracoesMapaCompleto(mapaEditado);
    } else {
      widget.cubit.criarMapa(
        nome: nome,
        largura: _largura,
        altura: _altura,
        preset: _presetFundo,
        imagemCaminhoLocal: _imagemCaminhoLocal,
      );
    }
    widget.onSalvo();
  }

  Future<bool> _aoTentarVoltar() async {
    if (!_houveAlteracoes) return true;
    final sair = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MestreCores.escuroSurface,
        title: const Text('Alterações não salvas', style: TextStyle(color: MestreCores.escuroOnSurface)),
        content: const Text(
          'Você tem alterações não salvas no mapa. Tem certeza de que deseja sair?',
          style: TextStyle(color: MestreCores.escuroOnSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continuar editando', style: TextStyle(color: MestreCores.escuroOuro)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: MestreCores.statusAlertaEscuro),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sair sem salvar'),
          ),
        ],
      ),
    );
    return sair ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_houveAlteracoes,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final ok = await _aoTentarVoltar();
        if (ok && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: MestreCores.escuroBackground,
        appBar: AppBar(
          backgroundColor: MestreCores.escuroSurface,
          foregroundColor: MestreCores.escuroOnSurface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final ok = await _aoTentarVoltar();
              if (ok && context.mounted) Navigator.pop(context);
            },
          ),
          title: Text(
            widget.mapaOriginal != null ? 'Editar Mapa: ${_nomeController.text}' : 'Criar Novo Mapa',
            style: const TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.bold),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: MestreCores.escuroOuro,
                  foregroundColor: MestreCores.escuroOuroTexto,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.save, size: 16),
                label: const Text('Salvar', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: _salvar,
              ),
            ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 840;
            if (isTablet) {
              return Row(
                children: [
                  Expanded(child: _buildCanvasPreview()),
                  const VerticalDivider(color: MestreCores.escuroOutline, width: 1),
                  SizedBox(width: 340, child: _buildPainelControles()),
                ],
              );
            } else {
              return Column(
                children: [
                  Expanded(flex: 3, child: _buildCanvasPreview()),
                  const Divider(color: MestreCores.escuroOutline, height: 1),
                  Expanded(flex: 4, child: _buildPainelControles()),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CANVAS DE PRÉ-VISUALIZAÇÃO (PINCH-ZOOM & PAN)
  // ---------------------------------------------------------------------------

  Widget _buildCanvasPreview() {
    return Container(
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          InteractiveViewer(
            minScale: 0.5,
            maxScale: 3.5,
            boundaryMargin: const EdgeInsets.all(80),
            child: Center(
              child: Container(
                width: _largura * 36.0,
                height: _altura * 36.0,
                decoration: BoxDecoration(
                  color: _obterCorFundoPreset(),
                  border: Border.all(color: MestreCores.escuroOuro.withValues(alpha: 0.6), width: 1.5),
                  boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 10, spreadRadius: 2)],
                ),
                child: Stack(
                  children: [
                    // Imagem de fundo ajustável
                    if (_imagemCaminhoLocal != null)
                      Positioned.fill(
                        child: Transform.translate(
                          offset: Offset(_ajusteOffsetX, _ajusteOffsetY),
                          child: Transform.rotate(
                            angle: _ajusteRotacaoGraus * (3.1415926535 / 180),
                            child: Transform.scale(
                              scale: _ajusteEscala,
                              child: _construirImagemFundo(),
                            ),
                          ),
                        ),
                      ),

                    // Grid Tático Customizado
                    if (_gridVisivel)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _GridEditorPainter(
                            largura: _largura,
                            altura: _altura,
                            opacidade: _opacidadeGrid,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                '$_largura×$_altura (${(_largura * 1.5).toStringAsFixed(1)}m × ${(_altura * 1.5).toStringAsFixed(1)}m) • Use dois dedos para zoom/pan',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirImagemFundo() {
    if (_imagemCaminhoLocal == null) return const SizedBox.shrink();
    if (_imagemCaminhoLocal!.startsWith('/') || _imagemCaminhoLocal!.contains(Platform.pathSeparator)) {
      final file = File(_imagemCaminhoLocal!);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    }
    return Container(
      color: Colors.black45,
      child: const Center(
        child: Icon(Icons.broken_image, color: Colors.white54, size: 36),
      ),
    );
  }

  Color _obterCorFundoPreset() {
    switch (_presetFundo) {
      case PresetFundoMapa.florestaArton:
        return const Color(0xFF132A13);
      case PresetFundoMapa.tavernaMadeira:
        return const Color(0xFF38220F);
      case PresetFundoMapa.desertoHalakTur:
        return const Color(0xFF4A3B18);
      case PresetFundoMapa.areaTormenta:
        return const Color(0xFF3F0B18);
      default:
        return const Color(0xFF1C1917);
    }
  }

  // ---------------------------------------------------------------------------
  // PAINEL DE CONTROLES COM ABAS (GRID, IMAGEM, OPÇÕES)
  // ---------------------------------------------------------------------------

  Widget _buildPainelControles() {
    return Container(
      color: MestreCores.escuroSurface,
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: MestreCores.escuroOuro,
            unselectedLabelColor: MestreCores.escuroOnSurfaceVariant,
            indicatorColor: MestreCores.escuroOuro,
            tabs: const [
              Tab(icon: Icon(Icons.grid_on, size: 18), text: 'Grid'),
              Tab(icon: Icon(Icons.image_outlined, size: 18), text: 'Imagem'),
              Tab(icon: Icon(Icons.settings_outlined, size: 18), text: 'Opções'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAbaGrid(),
                _buildAbaImagem(),
                _buildAbaOpcoes(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ABA 1: GRID
  Widget _buildAbaGrid() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Exibir Linhas do Grid', style: TextStyle(color: MestreCores.escuroOnSurface, fontSize: 13, fontWeight: FontWeight.bold)),
            Switch(
              value: _gridVisivel,
              activeThumbColor: MestreCores.escuroOuro,
              onChanged: (val) {
                setState(() => _gridVisivel = val);
                _marcarAlteracao();
              },
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Steppers Largura e Altura (Máx 30x30)
        _buildStepperLinha('Colunas (Largura)', _largura, (v) {
          setState(() => _largura = v.clamp(4, 30));
          _marcarAlteracao();
        }),
        _buildStepperLinha('Linhas (Altura)', _altura, (v) {
          setState(() => _altura = v.clamp(4, 30));
          _marcarAlteracao();
        }),

        const SizedBox(height: 10),
        const Text(
          'Escala T20: 1 quadrado = 1,5 m de combate.',
          style: TextStyle(color: MestreCores.escuroOnSurfaceVariant, fontSize: 11),
        ),
        const SizedBox(height: 14),

        // Opacidade das Linhas
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Opacidade da Grade', style: TextStyle(color: MestreCores.escuroOnSurface, fontSize: 12)),
            Text('${(_opacidadeGrid * 100).toInt()}%', style: const TextStyle(color: MestreCores.escuroOuro, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: _opacidadeGrid,
          min: 0.1,
          max: 1.0,
          activeColor: MestreCores.escuroOuro,
          onChanged: (v) {
            setState(() => _opacidadeGrid = v);
            _marcarAlteracao();
          },
        ),
      ],
    );
  }

  Widget _buildStepperLinha(String rotulo, int valor, ValueChanged<int> onMudou) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(rotulo, style: const TextStyle(color: MestreCores.escuroOnSurface, fontSize: 12)),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: MestreCores.escuroOuro, size: 20),
                onPressed: valor > 4 ? () => onMudou(valor - 1) : null,
              ),
              Container(
                width: 36,
                alignment: Alignment.center,
                child: Text('$valor', style: MestreCores.estiloMono.copyWith(color: MestreCores.escuroOnSurface, fontSize: 14)),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: MestreCores.escuroOuro, size: 20),
                onPressed: valor < 30 ? () => onMudou(valor + 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ABA 2: IMAGEM
  Widget _buildAbaImagem() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Escolha da Galeria
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: MestreCores.escuroVinho,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(44),
          ),
          icon: const Icon(Icons.photo_library_outlined, size: 18),
          label: const Text('Carregar Imagem da Galeria'),
          onPressed: _selecionarImagemGaleria,
        ),
        if (_imagemGrandeAlerta) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: MestreCores.statusAlertaEscuro.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: MestreCores.statusAlertaEscuro),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber, color: MestreCores.statusAlertaEscuro, size: 16),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Imagem > 5 MB detectada. Pode causar lentidão no host.',
                    style: TextStyle(color: MestreCores.statusAlertaEscuro, fontSize: 11),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _imagemGrandeAlerta = false);
                  },
                  child: const Text('Otimizar', style: TextStyle(color: MestreCores.escuroOuro, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),

        // Presets Temáticos
        const Text('Presets Temáticos de Arton', style: TextStyle(color: MestreCores.escuroOnSurface, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: PresetFundoMapa.values.where((p) => p != PresetFundoMapa.imagemCustomizada).map((preset) {
            final sel = _presetFundo == preset && _imagemCaminhoLocal == null;
            return ChoiceChip(
              label: Text(preset.rotulo, style: const TextStyle(fontSize: 11)),
              selected: sel,
              selectedColor: MestreCores.escuroOuro,
              onSelected: (_) {
                setState(() {
                  _presetFundo = preset;
                  _imagemCaminhoLocal = null;
                });
                _marcarAlteracao();
              },
            );
          }).toList(),
        ),

        const SizedBox(height: 14),
        if (_imagemCaminhoLocal != null) ...[
          const Divider(color: MestreCores.escuroOutline),
          const Text('Ajuste fino da Imagem com o Grid', style: TextStyle(color: MestreCores.escuroOnSurface, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          // Zoom
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Escala / Zoom', style: TextStyle(color: MestreCores.escuroOnSurfaceVariant, fontSize: 11)),
              Text('${_ajusteEscala.toStringAsFixed(2)}x', style: const TextStyle(color: MestreCores.escuroOuro, fontSize: 11)),
            ],
          ),
          Slider(
            value: _ajusteEscala,
            min: 0.5,
            max: 2.5,
            activeColor: MestreCores.escuroOuro,
            onChanged: (v) {
              setState(() => _ajusteEscala = v);
              _marcarAlteracao();
            },
          ),
          // Rotação
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Rotação', style: TextStyle(color: MestreCores.escuroOnSurfaceVariant, fontSize: 11)),
              Text('${_ajusteRotacaoGraus.toInt()}°', style: const TextStyle(color: MestreCores.escuroOuro, fontSize: 11)),
            ],
          ),
          Slider(
            value: _ajusteRotacaoGraus,
            min: -180.0,
            max: 180.0,
            activeColor: MestreCores.escuroOuro,
            onChanged: (v) {
              setState(() => _ajusteRotacaoGraus = v);
              _marcarAlteracao();
            },
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: MestreCores.statusAlertaEscuro),
            icon: const Icon(Icons.delete_outline, size: 16),
            label: const Text('Remover Imagem de Fundo'),
            onPressed: () {
              setState(() => _imagemCaminhoLocal = null);
              _marcarAlteracao();
            },
          ),
        ],
      ],
    );
  }

  Future<void> _selecionarImagemGaleria() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        final length = await picked.length();
        setState(() {
          _imagemCaminhoLocal = picked.path;
          _presetFundo = PresetFundoMapa.imagemCustomizada;
          _imagemGrandeAlerta = length > 5 * 1024 * 1024;
        });
        _marcarAlteracao();
      }
    } catch (_) {}
  }

  // ABA 3: OPÇÕES
  Widget _buildAbaOpcoes() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _nomeController,
          style: const TextStyle(color: MestreCores.escuroOnSurface, fontSize: 13),
          decoration: const InputDecoration(
            labelText: 'Nome do Mapa',
            labelStyle: TextStyle(color: MestreCores.escuroOnSurfaceVariant),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: MestreCores.escuroOutline)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: MestreCores.escuroOuro)),
          ),
          onChanged: (_) => _marcarAlteracao(),
        ),
        const SizedBox(height: 14),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Começar com tudo oculto (Fog of War)', style: TextStyle(color: MestreCores.escuroOnSurface, fontSize: 13, fontWeight: FontWeight.bold)),
          subtitle: const Text('Os jogadores não verão nenhuma célula até que você as revele.', style: TextStyle(color: MestreCores.escuroOnSurfaceVariant, fontSize: 11)),
          value: _comecarComTudoOculto,
          activeThumbColor: MestreCores.escuroOuro,
          onChanged: (val) {
            setState(() => _comecarComTudoOculto = val);
            _marcarAlteracao();
          },
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _notasController,
          maxLines: 4,
          style: const TextStyle(color: MestreCores.escuroOnSurface, fontSize: 12),
          decoration: const InputDecoration(
            labelText: 'Notas do Mestre sobre o Mapa',
            hintText: 'Ex.: Portas trancadas (CD 20), armadilha de poço no corredor leste...',
            labelStyle: TextStyle(color: MestreCores.escuroOnSurfaceVariant),
            hintStyle: TextStyle(color: Colors.white24),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: MestreCores.escuroOutline)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: MestreCores.escuroOuro)),
          ),
          onChanged: (_) => _marcarAlteracao(),
        ),
      ],
    );
  }
}

class _GridEditorPainter extends CustomPainter {
  final int largura;
  final int altura;
  final double opacidade;

  _GridEditorPainter({required this.largura, required this.altura, required this.opacidade});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacidade)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final cellW = size.width / largura;
    final cellH = size.height / altura;

    for (int x = 0; x <= largura; x++) {
      canvas.drawLine(Offset(x * cellW, 0), Offset(x * cellW, size.height), paint);
    }
    for (int y = 0; y <= altura; y++) {
      canvas.drawLine(Offset(0, y * cellH), Offset(size.width, y * cellH), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridEditorPainter oldDelegate) {
    return oldDelegate.largura != largura || oldDelegate.altura != altura || oldDelegate.opacidade != opacidade;
  }
}
