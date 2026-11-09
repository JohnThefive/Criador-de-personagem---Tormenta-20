import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../domain/entities/combate/grid_tatico.dart';
import '../../../../domain/entities/mestre/modelos_mestre.dart';
import '../../../controllers/mestre_controller/mestre_cubit.dart';
import '../../../controllers/mestre_controller/mestre_state.dart';

/// Tabuleiro VTT do Mestre com suporte a Imagem de Fundo na Grid,
/// Fog of War por célula, Pintura de Terreno e Movimentação animada de Personagens.
class MestreBattlemapWidget extends StatefulWidget {
  final MestreState state;
  final MestreCubit cubit;

  const MestreBattlemapWidget({
    super.key,
    required this.state,
    required this.cubit,
  });

  @override
  State<MestreBattlemapWidget> createState() => _MestreBattlemapWidgetState();
}

class _MestreBattlemapWidgetState extends State<MestreBattlemapWidget> {
  final TransformationController _transformController =
      TransformationController();

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _zoomIn() {
    final matrix = _transformController.value.clone();
    matrix.scaleByDouble(1.25, 1.25, 1.0, 1.0);
    _transformController.value = matrix;
  }

  void _zoomOut() {
    final matrix = _transformController.value.clone();
    matrix.scaleByDouble(0.8, 0.8, 1.0, 1.0);
    _transformController.value = matrix;
  }

  void _resetZoom() {
    _transformController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    final mapaReal = widget.state.mapaAtual;
    final mapaExibido = widget.state.mapaProjetado;

    if (mapaReal == null || mapaExibido == null) {
      return const Center(
        child: Text(
          'Nenhum mapa selecionado nesta aventura.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final emPreviewJogador = widget.state.estaEmPreviewJogador;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B1120),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: emPreviewJogador ? Colors.cyanAccent : Colors.white24,
          width: emPreviewJogador ? 2.0 : 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Stack(
          children: [
            // 1. Área interativa com Zoom e Pan
            InteractiveViewer(
              transformationController: _transformController,
              minScale: 0.5,
              maxScale: 3.5,
              boundaryMargin: const EdgeInsets.all(100),
              child: Center(
                child: AspectRatio(
                  aspectRatio: mapaExibido.largura / mapaExibido.altura,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final cellW = constraints.maxWidth / mapaExibido.largura;
                      final cellH = constraints.maxHeight / mapaExibido.altura;

                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          // CAMADA 1: Imagem de Fundo ou Textura Temática
                          _buildCamadaFundo(mapaExibido),

                          // CAMADA 2: Células da Grid, Terrenos, Fog of War e Alcance de Movimento
                          for (int y = 0; y < mapaExibido.altura; y++)
                            for (int x = 0; x < mapaExibido.largura; x++)
                              _buildCelulaGrid(
                                Posicao2D(x, y),
                                cellW,
                                cellH,
                                mapaReal: mapaReal,
                                mapaProjetado: mapaExibido,
                                emPreviewJogador: emPreviewJogador,
                              ),

                          // CAMADA 3: Tokens de Personagens com Animação Suave ao Mover
                          for (final token in mapaExibido.tokens)
                            _buildTokenAnimado(
                              token,
                              cellW,
                              cellH,
                              emPreviewJogador: emPreviewJogador,
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),

            // 2. Banner de Status da Ferramenta / Preview no Topo Esquerdo
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: emPreviewJogador
                        ? Colors.cyanAccent
                        : Colors.amberAccent.withValues(alpha: 0.6),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      emPreviewJogador
                          ? Icons.visibility
                          : Icons.shield_moon_outlined,
                      size: 16,
                      color: emPreviewJogador
                          ? Colors.cyanAccent
                          : Colors.amberAccent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      emPreviewJogador
                          ? 'PREVIEW: VISÃO DO JOGADOR (Células e tokens ocultos filtrados)'
                          : 'Modo: ${widget.state.ferramentaMapa.rotulo} — ${widget.state.ferramentaMapa.dica}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Controles Flutuantes de Zoom no Canto Inferior Direito
            Positioned(
              right: 10,
              bottom: 10,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon:
                          const Icon(Icons.add, size: 18, color: Colors.white),
                      tooltip: 'Aproximar (+)',
                      constraints:
                          const BoxConstraints(minWidth: 38, minHeight: 38),
                      onPressed: _zoomIn,
                    ),
                    const Divider(color: Colors.white24, height: 1),
                    IconButton(
                      icon: const Icon(
                        Icons.remove,
                        size: 18,
                        color: Colors.white,
                      ),
                      tooltip: 'Afastar (-)',
                      constraints:
                          const BoxConstraints(minWidth: 38, minHeight: 38),
                      onPressed: _zoomOut,
                    ),
                    const Divider(color: Colors.white24, height: 1),
                    IconButton(
                      icon: const Icon(
                        Icons.center_focus_strong,
                        size: 18,
                        color: Colors.amberAccent,
                      ),
                      tooltip: 'Centralizar mapa',
                      constraints:
                          const BoxConstraints(minWidth: 38, minHeight: 38),
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

  Widget _buildCamadaFundo(MapaBatalhaMestre mapa) {
    final caminho = mapa.imagemCaminhoLocal;
    if (caminho != null && caminho.trim().isNotEmpty) {
      final arquivo = File(caminho);
      if (arquivo.existsSync()) {
        return Image.file(
          arquivo,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildPresetGradient(mapa.presetFundo),
        );
      }
    }
    return _buildPresetGradient(mapa.presetFundo);
  }

  Widget _buildPresetGradient(PresetFundoMapa preset) {
    final List<Color> cores = switch (preset) {
      PresetFundoMapa.masmorraPedra => const [
          Color(0xFF1E293B),
          Color(0xFF0F172A),
          Color(0xFF1E1B2E),
        ],
      PresetFundoMapa.florestaArton => const [
          Color(0xFF143326),
          Color(0xFF0D261B),
          Color(0xFF1E3A2F),
        ],
      PresetFundoMapa.tavernaMadeira => const [
          Color(0xFF3E2723),
          Color(0xFF271815),
          Color(0xFF4E342E),
        ],
      PresetFundoMapa.desertoHalakTur => const [
          Color(0xFF5D4037),
          Color(0xFF3E2723),
          Color(0xFF6D4C41),
        ],
      PresetFundoMapa.areaTormenta => const [
          Color(0xFF4A0E17),
          Color(0xFF2B0509),
          Color(0xFF68121F),
        ],
      PresetFundoMapa.imagemCustomizada => const [
          Color(0xFF1E293B),
          Color(0xFF0F172A),
        ],
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: cores,
        ),
      ),
    );
  }

  Widget _buildCelulaGrid(
    Posicao2D pos,
    double w,
    double h, {
    required MapaBatalhaMestre mapaReal,
    required MapaBatalhaMestre mapaProjetado,
    required bool emPreviewJogador,
  }) {
    final bool revelada = mapaReal.celulasReveladas.contains(pos);
    final terreno = mapaProjetado.terrenos[pos] ?? TipoTerreno.normal;
    final bool alcancavel =
        widget.state.celulasAlcancaveisToken.contains(pos);
    final double? custoMetros = widget.state.custosMovimentoToken[pos];

    // Se estiver no Preview de Jogador e a célula não foi revelada, fica 100% opaca (ADR-003 §3.1)
    if (emPreviewJogador && !revelada) {
      return Positioned(
        left: pos.x * w,
        top: pos.y * h,
        width: w,
        height: h,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF050811),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.05),
              width: 0.5,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.cloud,
              size: 14,
              color: Colors.white12,
            ),
          ),
        ),
      );
    }

    Color corCelula = Colors.transparent;
    if (terreno == TipoTerreno.obstaculo) {
      corCelula = Colors.black.withValues(alpha: 0.72);
    } else if (terreno == TipoTerreno.dificil) {
      corCelula = const Color(0xFFD97706).withValues(alpha: 0.32);
    }

    if (alcancavel) {
      corCelula = const Color(0xFF38BDF8).withValues(alpha: 0.35);
    }

    // Na visão do Mestre, células ocultas para os jogadores têm névoa translúcida
    final bool nevoaMestre = !emPreviewJogador && !revelada;

    return Positioned(
      left: pos.x * w,
      top: pos.y * h,
      width: w,
      height: h,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.cubit.aoClicarCelulaMapa(pos),
        child: Container(
          decoration: BoxDecoration(
            color: corCelula,
            border: Border.all(
              color: alcancavel
                  ? Colors.cyanAccent
                  : Colors.white.withValues(alpha: mapaReal.opacidadeGrid),
              width: alcancavel ? 1.5 : 0.6,
            ),
          ),
          child: Stack(
            children: [
              // Indicador de Terreno
              if (terreno == TipoTerreno.obstaculo)
                const Center(
                  child: Icon(
                    Icons.block,
                    size: 16,
                    color: Colors.white38,
                  ),
                )
              else if (terreno == TipoTerreno.dificil)
                const Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(
                      Icons.landscape,
                      size: 12,
                      color: Colors.amberAccent,
                    ),
                  ),
                ),

              // Indicador de Névoa (apenas para o Mestre saber que está oculta aos jogadores)
              if (nevoaMestre)
                Container(
                  color: Colors.black.withValues(alpha: 0.48),
                  alignment: Alignment.bottomLeft,
                  padding: const EdgeInsets.all(2),
                  child: const Icon(
                    Icons.visibility_off,
                    size: 11,
                    color: Colors.white38,
                  ),
                ),

              // Custo de movimento em metros quando um token está selecionado
              if (alcancavel && custoMetros != null)
                Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${custoMetros.toStringAsFixed(1)}m',
                      style: const TextStyle(
                        color: Colors.cyanAccent,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTokenAnimado(
    TokenNoMapa token,
    double w,
    double h, {
    required bool emPreviewJogador,
  }) {
    final bool selecionado =
        widget.state.tokenSelecionadoParaMoverId == token.id;
    final Color corBase =
        token.ehHeroi ? const Color(0xFF2563EB) : const Color(0xFFDC2626);
    final bool oculto = !token.visivelParaJogadores;

    return AnimatedPositioned(
      key: ValueKey('token_${token.id}'),
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      left: token.posicao.x * w,
      top: token.posicao.y * h,
      width: w,
      height: h,
      child: GestureDetector(
        onTap: () {
          if (widget.state.ferramentaMapa ==
              FerramentaMapaMestre.nevoaDeGuerra) {
            widget.cubit.aoClicarCelulaMapa(token.posicao);
          } else {
            widget.cubit.aoClicarTokenNoMapa(token);
          }
        },
        onLongPress: () => widget.cubit.alternarVisibilidadeToken(token.id),
        child: Padding(
          padding: const EdgeInsets.all(3.0),
          child: Opacity(
            opacity: oculto ? 0.65 : 1.0,
            child: Container(
              decoration: BoxDecoration(
                color: corBase,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selecionado ? Colors.amberAccent : Colors.white,
                  width: selecionado ? 3.0 : 1.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: selecionado
                        ? Colors.amberAccent.withValues(alpha: 0.6)
                        : Colors.black54,
                    blurRadius: selecionado ? 8 : 4,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Iniciais do Personagem
                  Text(
                    token.nome.length >= 2
                        ? token.nome.substring(0, 2).toUpperCase()
                        : token.nome.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),

                  // Ícone indicando que o token está oculto para os jogadores (RF-M7)
                  if (oculto && !emPreviewJogador)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.black87,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.visibility_off,
                          size: 10,
                          color: Colors.amberAccent,
                        ),
                      ),
                    ),

                  // Rótulo com Nome na base do Token
                  Positioned(
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        token.nome.split(' ').first,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
