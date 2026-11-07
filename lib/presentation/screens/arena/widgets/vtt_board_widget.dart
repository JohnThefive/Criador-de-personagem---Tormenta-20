import 'package:flutter/material.dart';
import 'package:t20_creator/presentation/controllers/combate_controller/combate_state.dart';
import '../../../../domain/entities/combate/combatente.dart';
import '../../../../domain/entities/combate/grid_tatico.dart';
import '../../../../domain/services/combate_services/calculadora_tatica_t20.dart';

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

                      // Avaliações táticas para as células alcançáveis
                      final Map<Posicao2D, AvaliacaoPosicaoGrid> avaliacoesTaticas;
                      final atual = widget.state.combatenteAtual;
                      if (widget.state.modoMovimentoAtivo &&
                          atual != null &&
                          widget.state.posicoesCombatentes.containsKey(atual.id)) {
                        final posAtual = widget.state.posicoesCombatentes[atual.id]!;
                        avaliacoesTaticas = CalculadoraTaticaT20.avaliarPosicoesGrid(
                          posHeroi: posAtual,
                          alcancaveis: widget.state.celulasAlcancaveis,
                          heroi: atual,
                          todosCombatentes: widget.state.filaIniciativa,
                          posicoes: widget.state.posicoesCombatentes,
                          mapaGrid: widget.state.mapaGrid,
                        );
                      } else {
                        avaliacoesTaticas = const {};
                      }

                      return Stack(
                        children: [
                          // 1. Grade e Terrenos com Apoio Tático
                          for (int y = 0; y < mapa.altura; y++)
                            for (int x = 0; x < mapa.largura; x++)
                              _buildCell(
                                Posicao2D(x, y),
                                cellWidth,
                                cellHeight,
                                avaliacoesTaticas[Posicao2D(x, y)],
                              ),

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

            // HUD Tático de Apoio à Decisão (ativo durante o modo movimento)
            if (widget.state.modoMovimentoAtivo)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.90),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_outlined, size: 13, color: Color(0xFF38BDF8)),
                      SizedBox(width: 4),
                      Text('Cobertura (+5 Def)', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      SizedBox(width: 10),
                      Icon(Icons.gps_fixed, size: 13, color: Color(0xFFFBBF24)),
                      SizedBox(width: 4),
                      Text('Flanco (+2 Atq)', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      SizedBox(width: 10),
                      Icon(Icons.directions_run, size: 13, color: Color(0xFF34D399)),
                      SizedBox(width: 4),
                      Text('Zona Segura', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
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

  Widget _buildCell(Posicao2D pos, double w, double h, AvaliacaoPosicaoGrid? avaliacao) {
    final terreno = widget.state.mapaGrid.obterTerreno(pos);
    final alcancavel = widget.state.celulasAlcancaveis.contains(pos);

    Color corFundo = const Color(0xFF0F172A);
    Color corBorda = Colors.white12;
    double larguraBorda = 0.5;
    IconData? iconeTatico;
    Color corIcone = Colors.transparent;

    if (terreno == TipoTerreno.obstaculo) {
      corFundo = Colors.black87;
    } else if (terreno == TipoTerreno.dificil) {
      corFundo = const Color(0xFF334155);
    }

    if (alcancavel) {
      larguraBorda = 1.5;
      if (avaliacao?.temCobertura == true) {
        corFundo = const Color(0xFF0284C7).withValues(alpha: 0.35);
        corBorda = const Color(0xFF38BDF8);
        iconeTatico = Icons.shield_outlined;
        corIcone = const Color(0xFF38BDF8);
      } else if (avaliacao?.temFlanco == true) {
        corFundo = const Color(0xFFD97706).withValues(alpha: 0.35);
        corBorda = const Color(0xFFFBBF24);
        iconeTatico = Icons.gps_fixed;
        corIcone = const Color(0xFFFBBF24);
      } else if (avaliacao?.ehPosicaoSegura == true) {
        corFundo = const Color(0xFF059669).withValues(alpha: 0.35);
        corBorda = const Color(0xFF34D399);
        iconeTatico = Icons.directions_run;
        corIcone = const Color(0xFF34D399);
      } else if (avaliacao?.ehAdjacenteInimigo == true) {
        corFundo = const Color(0xFFB91C1C).withValues(alpha: 0.30);
        corBorda = const Color(0xFFF87171);
        iconeTatico = Icons.sports_kabaddi;
        corIcone = const Color(0xFFF87171);
      } else {
        corFundo = Colors.blue.withValues(alpha: 0.35);
        corBorda = Colors.lightBlueAccent;
      }
    }

    return Positioned(
      left: pos.x * w,
      top: pos.y * h,
      width: w,
      height: h,
      child: Tooltip(
        message: avaliacao?.rotuloTatico.isNotEmpty == true
            ? '${widget.state.custosMovimento[pos]?.toStringAsFixed(1)}m • ${avaliacao!.rotuloTatico}'
            : (alcancavel ? '${widget.state.custosMovimento[pos]?.toStringAsFixed(1)}m' : ''),
        child: InkWell(
          onTap: () => widget.onCelulaClicada(pos),
          child: Container(
            decoration: BoxDecoration(
              color: corFundo,
              border: Border.all(color: corBorda, width: larguraBorda),
            ),
            child: Stack(
              children: [
                if (alcancavel)
                  Center(
                    child: Text(
                      '${widget.state.custosMovimento[pos]?.toStringAsFixed(1)}m',
                      style: TextStyle(
                        color: corBorda,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else if (terreno == TipoTerreno.obstaculo)
                  const Center(
                    child: Icon(Icons.block, color: Colors.white24, size: 14),
                  ),

                if (iconeTatico != null)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Icon(iconeTatico, size: 11, color: corIcone),
                  ),
              ],
            ),
          ),
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
