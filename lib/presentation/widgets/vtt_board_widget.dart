import 'package:flutter/material.dart';
import 'package:t20_creator/presentation/controllers/combate_controller/combate_state.dart';
import '../../../../domain/entities/combate/combatente.dart';
import '../../../../domain/entities/combate/grid_tatico.dart';

class VttBoardWidget extends StatefulWidget {
  final CombateState state;
  final void Function(Posicao2D destino) onCelulaClicada;
  final void Function(Combatente alvo) onCombatenteClicado;
  final TransformationController? transformationController;

  const VttBoardWidget({
    super.key,
    required this.state,
    required this.onCelulaClicada,
    required this.onCombatenteClicado,
    this.transformationController,
  });

  @override
  State<VttBoardWidget> createState() => _VttBoardWidgetState();
}

class _VttBoardWidgetState extends State<VttBoardWidget> {
  late final TransformationController _controller;
  bool _internalController = false;

  @override
  void initState() {
    super.initState();
    if (widget.transformationController != null) {
      _controller = widget.transformationController!;
    } else {
      _controller = TransformationController();
      _internalController = true;
    }
  }

  @override
  void dispose() {
    if (_internalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _zoomIn() {
    final matrix = _controller.value.clone();
    matrix.scaleByDouble(1.25, 1.25, 1.0, 1.0);
    _controller.value = matrix;
  }

  void _zoomOut() {
    final matrix = _controller.value.clone();
    matrix.scaleByDouble(0.8, 0.8, 1.0, 1.0);
    _controller.value = matrix;
  }

  void _resetZoom() {
    _controller.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    final mapa = widget.state.mapaGrid;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Tabuleiro com Zoom/Pan suave via InteractiveViewer
            InteractiveViewer(
              transformationController: _controller,
              minScale: 0.5,
              maxScale: 3.0,
              boundaryMargin: const EdgeInsets.all(80),
              clipBehavior: Clip.hardEdge,
              child: Center(
                child: AspectRatio(
                  aspectRatio: mapa.largura / mapa.altura,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final cellWidth = constraints.maxWidth / mapa.largura;
                      final cellHeight = constraints.maxHeight / mapa.altura;

                      return Stack(
                        children: [
                          // 1. Grade e Terrenos
                          for (int y = 0; y < mapa.altura; y++)
                            for (int x = 0; x < mapa.largura; x++)
                              _buildCell(Posicao2D(x, y), cellWidth, cellHeight),

                          // 2. Combatentes sobre o grid
                          for (final entry in widget.state.posicoesCombatentes.entries)
                            _buildToken(entry.key, entry.value, cellWidth, cellHeight),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),

            // Controles de Zoom Flutuantes no canto inferior direito
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add, size: 18, color: Colors.white),
                      tooltip: 'Aproximar zoom (+)',
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      padding: EdgeInsets.zero,
                      onPressed: _zoomIn,
                    ),
                    const Divider(color: Colors.white24, height: 1),
                    IconButton(
                      icon: const Icon(Icons.remove, size: 18, color: Colors.white),
                      tooltip: 'Afastar zoom (-)',
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      padding: EdgeInsets.zero,
                      onPressed: _zoomOut,
                    ),
                    const Divider(color: Colors.white24, height: 1),
                    IconButton(
                      icon: const Icon(Icons.restart_alt, size: 18, color: Colors.amberAccent),
                      tooltip: 'Resetar visualização',
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      padding: EdgeInsets.zero,
                      onPressed: _resetZoom,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCell(Posicao2D pos, double w, double h) {
    final terreno = widget.state.mapaGrid.obterTerreno(pos);
    final alcancavel = widget.state.celulasAlcancaveis.contains(pos);

    Color corFundo = const Color(0xFF0F172A);
    if (terreno == TipoTerreno.obstaculo) {
      corFundo = Colors.black87;
    } else if (terreno == TipoTerreno.dificil) {
      corFundo = const Color(0xFF334155);
    }

    if (alcancavel) {
      corFundo = Colors.blue.withValues(alpha: 0.35);
    }

    return Positioned(
      left: pos.x * w,
      top: pos.y * h,
      width: w,
      height: h,
      child: InkWell(
        onTap: () => widget.onCelulaClicada(pos),
        child: Container(
          decoration: BoxDecoration(
            color: corFundo,
            border: Border.all(
              color: alcancavel ? Colors.lightBlueAccent : Colors.white12,
              width: alcancavel ? 1.5 : 0.5,
            ),
          ),
          child: alcancavel
              ? Center(
                  child: Text(
                    '${widget.state.custosMovimento[pos]?.toStringAsFixed(1)}m',
                    style: const TextStyle(
                      color: Colors.lightBlueAccent,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : (terreno == TipoTerreno.obstaculo
                    ? const Icon(Icons.block, color: Colors.white24, size: 14)
                    : null),
        ),
      ),
    );
  }

  Widget _buildToken(String id, Posicao2D pos, double w, double h) {
    final combatente = widget.state.filaIniciativa.firstWhere(
      (c) => c.id == id,
      orElse: () => Combatente(
        id: id,
        nome: '?',
        pvMax: 1,
        pvAtual: 1,
        pmMax: 0,
        pmAtual: 0,
        defesa: 10,
        modIniciativa: 0,
        modLuta: 0,
        modPontaria: 0,
        modPercepcao: 0,
        modForca: 0,
        modDestreza: 0,
        modConstituicao: 0,
      ),
    );

    final bool ehVez = widget.state.combatenteAtual?.id == id;
    final bool ehHeroi = combatente.time == TimeCombatente.heroi;

    return Positioned(
      left: pos.x * w + 2,
      top: pos.y * h + 2,
      width: w - 4,
      height: h - 4,
      child: Tooltip(
        message: '${combatente.nome} (${combatente.pvAtual}/${combatente.pvMax} PV | Def: ${combatente.defesa})',
        child: Semantics(
          label: 'Token de ${combatente.nome}, ${combatente.pvAtual} de ${combatente.pvMax} pontos de vida',
          button: true,
          child: GestureDetector(
            onTap: () => widget.onCombatenteClicado(combatente),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ehHeroi ? const Color(0xFF1E88E5) : const Color(0xFFE53935),
                border: Border.all(
                  color: ehVez ? Colors.amberAccent : Colors.white,
                  width: ehVez ? 2.5 : 1.2,
                ),
                boxShadow: ehVez
                    ? [
                        const BoxShadow(
                          color: Colors.amberAccent,
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  combatente.nome.isNotEmpty
                      ? combatente.nome[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
