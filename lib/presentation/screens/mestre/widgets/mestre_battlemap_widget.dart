import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show listEquals, mapEquals, setEquals;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/entities/combate/grid_tatico.dart';
import '../../../../domain/entities/entidade_sessao_lan/sessao_lan_modelos.dart';
import '../../../../domain/entities/habilidades/modelos_habilidade_duracao.dart';
import '../../../../domain/entities/mestre/modelos_mestre.dart';
import '../../../controllers/mestre_controller/mestre_cubit.dart';
import '../../../controllers/mestre_controller/mestre_state.dart';

/// Tabuleiro VTT do Mestre com renderização via CustomPainter + BlocSelector por camada,
/// suporte a Imagem de Fundo na Grid, Fog of War por célula, Terrenos,
/// Alcance de Movimento T20, Áreas de Efeito T20, Medição, Pings e Movimentação animada de Tokens.
class MestreBattlemapWidget extends StatefulWidget {
  final MestreCubit cubit;
  final bool modoMedicao;
  final bool modoPing;
  final bool modoAreaEfeito;
  final bool fogModoRevelar;

  const MestreBattlemapWidget({
    super.key,
    required this.cubit,
    this.modoMedicao = false,
    this.modoPing = false,
    this.modoAreaEfeito = false,
    this.fogModoRevelar = true,
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
    return BlocSelector<MestreCubit, MestreState,
        ({int largura, int altura, bool emPreview})?>(
      bloc: widget.cubit,
      selector: (s) {
        final mapaReal = s.mapaAtual;
        final mapaExibido = s.mapaProjetado;
        if (mapaReal == null || mapaExibido == null) return null;
        return (
          largura: mapaExibido.largura,
          altura: mapaExibido.altura,
          emPreview: s.estaEmPreviewJogador,
        );
      },
      builder: (context, mapInfo) {
        if (mapInfo == null) {
          return const Center(
            child: Text(
              'Nenhum mapa selecionado nesta aventura.',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        final emPreviewJogador = mapInfo.emPreview;

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
                      aspectRatio: mapInfo.largura / mapInfo.altura,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final cellW = constraints.maxWidth / mapInfo.largura;
                          final cellH = constraints.maxHeight / mapInfo.altura;

                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              // CAMADA 1: Imagem de Fundo ou Textura Temática
                              _buildCamadaFundo(),

                              // CAMADA 2: Grid, Terrenos, Fog of War, Alcance + Custos, Medição T20 e Pings
                              _buildCamadaGridEPainter(cellW, cellH),

                              // CAMADA 3: Tokens de Personagens com Animação Suave ao Mover
                              _buildCamadaTokens(cellW, cellH),
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
                  child: _buildBannerStatus(),
                ),

                // 3. Controles Flutuantes de Zoom no Canto Inferior Direito
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: _buildControlesZoom(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCamadaFundo() {
    return Positioned.fill(
      child: BlocSelector<
          MestreCubit,
          MestreState,
          ({
            String? caminho,
            PresetFundoMapa preset,
            double offsetX,
            double offsetY,
            double escala,
            double rotacaoGraus,
          })?>(
        bloc: widget.cubit,
        selector: (s) {
          final mapa = s.mapaProjetado;
          if (mapa == null) return null;
          return (
            caminho: mapa.imagemCaminhoLocal,
            preset: mapa.presetFundo,
            offsetX: mapa.ajusteOffsetX,
            offsetY: mapa.ajusteOffsetY,
            escala: mapa.ajusteEscala,
            rotacaoGraus: mapa.ajusteRotacaoGraus,
          );
        },
        builder: (context, fundo) {
          if (fundo == null) return const SizedBox.shrink();

          final caminho = fundo.caminho;
          final Widget conteudoFundo =
              (caminho != null && caminho.trim().isNotEmpty)
                  ? Image.file(
                      File(caminho),
                      fit: BoxFit.cover,
                      cacheWidth: 1600,
                      errorBuilder: (_, _, _) =>
                          _buildPresetGradient(fundo.preset),
                    )
                  : _buildPresetGradient(fundo.preset);

          return ClipRect(
            child: RepaintBoundary(
              child: Transform.translate(
                offset: Offset(fundo.offsetX, fundo.offsetY),
                child: Transform.rotate(
                  angle: fundo.rotacaoGraus * (math.pi / 180),
                  child: Transform.scale(
                    scale: fundo.escala,
                    child: SizedBox.expand(child: conteudoFundo),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCamadaGridEPainter(double cellW, double cellH) {
    return Positioned.fill(
      child: BlocSelector<MestreCubit, MestreState, _GridLayerSlice?>(
        bloc: widget.cubit,
        selector: (s) {
          final mapaReal = s.mapaAtual;
          final mapaExibido = s.mapaProjetado;
          if (mapaReal == null || mapaExibido == null) return null;
          return _GridLayerSlice(
            mapaReal: mapaReal,
            mapaExibido: mapaExibido,
            emPreviewJogador: s.estaEmPreviewJogador,
            celulasAlcancaveis: s.celulasAlcancaveisToken,
            custosMovimento: s.custosMovimentoToken,
            pontoOrigemMedicao: s.pontoOrigemMedicao,
            pontoDestinoMedicao: s.pontoDestinoMedicao,
            pingsAtivos: s.pingsAtivos,
            areasEfeitoAtivas: s.areasEfeitoAtivas,
            formaAreaMestre: s.formaAreaMestre,
          );
        },
        builder: (context, slice) {
          if (slice == null) return const SizedBox.shrink();

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              final x = (details.localPosition.dx / cellW)
                  .floor()
                  .clamp(0, slice.mapaExibido.largura - 1);
              final y = (details.localPosition.dy / cellH)
                  .floor()
                  .clamp(0, slice.mapaExibido.altura - 1);
              final pos = Posicao2D(x, y);

              if (widget.modoAreaEfeito) {
                final usaVertice =
                    slice.formaAreaMestre == TipoArea.esfera ||
                    slice.formaAreaMestre == TipoArea.cilindro;
                final VerticeGrid? vertice = usaVertice
                    ? VerticeGrid(
                        (details.localPosition.dx / cellW)
                            .round()
                            .clamp(1, math.max(1, slice.mapaExibido.largura - 1)),
                        (details.localPosition.dy / cellH)
                            .round()
                            .clamp(1, math.max(1, slice.mapaExibido.altura - 1)),
                      )
                    : null;
                widget.cubit.projetarAreaMestre(
                  pontoAlvo: pos,
                  verticeAlvo: vertice,
                );
              } else if (widget.modoMedicao) {
                widget.cubit.registrarPontoMedicao(pos);
              } else if (widget.modoPing) {
                widget.cubit.soltarPing(pos);
              } else {
                widget.cubit.aoClicarCelulaMapa(
                  pos,
                  fogModoRevelar: widget.fogModoRevelar,
                );
              }
            },
            child: RepaintBoundary(
              child: CustomPaint(
                key: const ValueKey('battlemap_grid_painter'),
                painter: _BattlemapGridPainter(
                  mapaReal: slice.mapaReal,
                  mapaExibido: slice.mapaExibido,
                  emPreviewJogador: slice.emPreviewJogador,
                  celulasAlcancaveis: slice.celulasAlcancaveis,
                  custosMovimento: slice.custosMovimento,
                  pontoOrigemMedicao: slice.pontoOrigemMedicao,
                  pontoDestinoMedicao: slice.pontoDestinoMedicao,
                  pingsAtivos: slice.pingsAtivos,
                  areasEfeitoAtivas: slice.areasEfeitoAtivas,
                ),
                size: Size.infinite,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCamadaTokens(double cellW, double cellH) {
    return Positioned.fill(
      child: BlocSelector<MestreCubit, MestreState, _TokenLayerSlice?>(
        bloc: widget.cubit,
        selector: (s) {
          final mapaExibido = s.mapaProjetado;
          if (mapaExibido == null) return null;
          return _TokenLayerSlice(
            tokensVisiveis: mapaExibido.tokens,
            tokenSelecionadoId: s.tokenSelecionadoParaMoverId,
            tokenTurnoAtualId: mapaExibido.tokenTurnoAtualId,
            ferramentaMapa: s.ferramentaMapa,
            emPreviewJogador: s.estaEmPreviewJogador,
          );
        },
        builder: (context, slice) {
          if (slice == null) return const SizedBox.shrink();

          return Stack(
            clipBehavior: Clip.none,
            children: [
              for (final token in slice.tokensVisiveis)
                _buildTokenAnimado(
                  token,
                  cellW,
                  cellH,
                  selecionado: slice.tokenSelecionadoId == token.id,
                  turnoAtivo: slice.tokenTurnoAtualId == token.id,
                  ferramentaMapa: slice.ferramentaMapa,
                  emPreviewJogador: slice.emPreviewJogador,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBannerStatus() {
    return BlocSelector<MestreCubit, MestreState,
        ({bool emPreview, FerramentaMapaMestre ferramenta})>(
      bloc: widget.cubit,
      selector: (s) => (
        emPreview: s.estaEmPreviewJogador,
        ferramenta: s.ferramentaMapa,
      ),
      builder: (context, info) {
        final emPreview = info.emPreview;
        final String texto;
        if (emPreview) {
          texto =
              'PREVIEW: VISÃO DO JOGADOR (Células e tokens ocultos filtrados)';
        } else if (widget.modoAreaEfeito) {
          texto =
              'Modo: Área de Efeito T20 — Toque no mapa para posicionar (◎ interseção para Esfera/Cilindro)';
        } else if (widget.modoMedicao) {
          texto =
              'Modo: Medir Distância — Toque na origem e no destino (1□ = 1,5m)';
        } else if (widget.modoPing) {
          texto =
              'Modo: Pings — Toque no mapa para destacar uma posição';
        } else {
          texto = 'Modo: ${info.ferramenta.rotulo} — ${info.ferramenta.dica}';
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: emPreview
                  ? Colors.cyanAccent
                  : Colors.amberAccent.withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                emPreview
                    ? Icons.visibility
                    : (widget.modoMedicao
                        ? Icons.straighten
                        : (widget.modoPing
                            ? Icons.place_outlined
                            : Icons.shield_moon_outlined)),
                size: 16,
                color: emPreview ? Colors.cyanAccent : Colors.amberAccent,
              ),
              const SizedBox(width: 8),
              Text(
                texto,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControlesZoom() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.add, size: 18, color: Colors.white),
            tooltip: 'Aproximar (+)',
            constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
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
            constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
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
            constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
            onPressed: _resetZoom,
          ),
        ],
      ),
    );
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

  Widget _buildTokenAnimado(
    TokenNoMapa token,
    double w,
    double h, {
    required bool selecionado,
    required bool turnoAtivo,
    required FerramentaMapaMestre ferramentaMapa,
    required bool emPreviewJogador,
  }) {
    final span = token.tamanhoQuadrados.clamp(1, 4);
    final Color corBase =
        token.ehHeroi ? const Color(0xFF2563EB) : const Color(0xFFDC2626);
    final bool oculto = !token.visivelParaJogadores;

    final nomeLimpo = token.nome.trim();
    final String iniciais = nomeLimpo.isEmpty
        ? '?'
        : (nomeLimpo.length >= 2
            ? nomeLimpo.substring(0, 2).toUpperCase()
            : nomeLimpo.toUpperCase());
    final String primeiroNome =
        nomeLimpo.isEmpty ? 'Token' : nomeLimpo.split(' ').first;

    return AnimatedPositioned(
      key: ValueKey('token_${token.id}'),
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      left: token.posicao.x * w,
      top: token.posicao.y * h,
      width: w * span,
      height: h * span,
      child: GestureDetector(
        onTap: () {
          if (widget.modoMedicao) {
            widget.cubit.registrarPontoMedicao(token.posicao);
          } else if (widget.modoPing) {
            widget.cubit.soltarPing(token.posicao);
          } else if (ferramentaMapa == FerramentaMapaMestre.nevoaDeGuerra) {
            widget.cubit.aoClicarCelulaMapa(
              token.posicao,
              fogModoRevelar: widget.fogModoRevelar,
            );
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
                  color: turnoAtivo
                      ? Colors.greenAccent
                      : (selecionado ? Colors.amberAccent : Colors.white),
                  width: (turnoAtivo || selecionado) ? 3.0 : 1.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: turnoAtivo
                        ? Colors.greenAccent.withValues(alpha: 0.7)
                        : (selecionado
                            ? Colors.amberAccent.withValues(alpha: 0.6)
                            : Colors.black54),
                    blurRadius: (turnoAtivo || selecionado) ? 10 : 4,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Iniciais do Personagem
                  Text(
                    iniciais,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: span > 1 ? 14 : 11,
                    ),
                  ),

                  if (turnoAtivo)
                    Positioned(
                      key: ValueKey('turno_ativo_${token.id}'),
                      top: 0,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          size: 10,
                          color: Colors.black,
                        ),
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
                        primeiroNome,
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

class _GridLayerSlice {
  final MapaBatalhaMestre mapaReal;
  final MapaBatalhaMestre mapaExibido;
  final bool emPreviewJogador;
  final Set<Posicao2D> celulasAlcancaveis;
  final Map<Posicao2D, double> custosMovimento;
  final Posicao2D? pontoOrigemMedicao;
  final Posicao2D? pontoDestinoMedicao;
  final List<Posicao2D> pingsAtivos;
  final List<AreaEfeitoAtivaLan> areasEfeitoAtivas;
  final TipoArea formaAreaMestre;

  const _GridLayerSlice({
    required this.mapaReal,
    required this.mapaExibido,
    required this.emPreviewJogador,
    required this.celulasAlcancaveis,
    required this.custosMovimento,
    required this.pontoOrigemMedicao,
    required this.pontoDestinoMedicao,
    required this.pingsAtivos,
    required this.areasEfeitoAtivas,
    required this.formaAreaMestre,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _GridLayerSlice &&
        other.mapaReal.largura == mapaReal.largura &&
        other.mapaReal.altura == mapaReal.altura &&
        other.mapaReal.gridVisivel == mapaReal.gridVisivel &&
        other.mapaReal.opacidadeGrid == mapaReal.opacidadeGrid &&
        identical(other.mapaReal.terrenos, mapaReal.terrenos) &&
        identical(other.mapaReal.celulasReveladas, mapaReal.celulasReveladas) &&
        other.emPreviewJogador == emPreviewJogador &&
        identical(other.celulasAlcancaveis, celulasAlcancaveis) &&
        identical(other.custosMovimento, custosMovimento) &&
        other.pontoOrigemMedicao == pontoOrigemMedicao &&
        other.pontoDestinoMedicao == pontoDestinoMedicao &&
        listEquals(other.pingsAtivos, pingsAtivos) &&
        listEquals(other.areasEfeitoAtivas, areasEfeitoAtivas) &&
        other.formaAreaMestre == formaAreaMestre;
  }

  @override
  int get hashCode => Object.hash(
        mapaReal.largura,
        mapaReal.altura,
        mapaReal.gridVisivel,
        mapaReal.opacidadeGrid,
        identityHashCode(mapaReal.terrenos),
        identityHashCode(mapaReal.celulasReveladas),
        emPreviewJogador,
        identityHashCode(celulasAlcancaveis),
        identityHashCode(custosMovimento),
        pontoOrigemMedicao,
        pontoDestinoMedicao,
        Object.hashAll(pingsAtivos),
        Object.hashAll(areasEfeitoAtivas),
        formaAreaMestre,
      );
}

class _TokenLayerSlice {
  final List<TokenNoMapa> tokensVisiveis;
  final String? tokenSelecionadoId;
  final String? tokenTurnoAtualId;
  final FerramentaMapaMestre ferramentaMapa;
  final bool emPreviewJogador;

  const _TokenLayerSlice({
    required this.tokensVisiveis,
    required this.tokenSelecionadoId,
    required this.tokenTurnoAtualId,
    required this.ferramentaMapa,
    required this.emPreviewJogador,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _TokenLayerSlice &&
        listEquals(other.tokensVisiveis, tokensVisiveis) &&
        other.tokenSelecionadoId == tokenSelecionadoId &&
        other.tokenTurnoAtualId == tokenTurnoAtualId &&
        other.ferramentaMapa == ferramentaMapa &&
        other.emPreviewJogador == emPreviewJogador;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(tokensVisiveis),
        tokenSelecionadoId,
        tokenTurnoAtualId,
        ferramentaMapa,
        emPreviewJogador,
      );
}

class _BattlemapGridPainter extends CustomPainter {
  final MapaBatalhaMestre mapaReal;
  final MapaBatalhaMestre mapaExibido;
  final bool emPreviewJogador;
  final Set<Posicao2D> celulasAlcancaveis;
  final Map<Posicao2D, double> custosMovimento;
  final Posicao2D? pontoOrigemMedicao;
  final Posicao2D? pontoDestinoMedicao;
  final List<Posicao2D> pingsAtivos;
  final List<AreaEfeitoAtivaLan> areasEfeitoAtivas;

  _BattlemapGridPainter({
    required this.mapaReal,
    required this.mapaExibido,
    required this.emPreviewJogador,
    required this.celulasAlcancaveis,
    required this.custosMovimento,
    required this.pontoOrigemMedicao,
    required this.pontoDestinoMedicao,
    required this.pingsAtivos,
    required this.areasEfeitoAtivas,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final largura = mapaExibido.largura;
    final altura = mapaExibido.altura;
    if (largura <= 0 || altura <= 0) return;

    final cellW = size.width / largura;
    final cellH = size.height / altura;

    _desenharTerrenos(canvas, cellW, cellH, largura, altura);
    _desenharAlcanceMovimento(canvas, cellW, cellH, largura, altura);
    _desenharAreasEfeito(canvas, cellW, cellH, largura, altura);
    _desenharFogOfWar(canvas, cellW, cellH, largura, altura);
    if (mapaExibido.gridVisivel) {
      _desenharLinhasGrid(canvas, size, cellW, cellH, largura, altura);
    }
    _desenharBordasAlcanceECustos(canvas, cellW, cellH, largura, altura);
    _desenharCentrosAreasEfeito(canvas, cellW, cellH);
    _desenharMedicaoDistancia(canvas, cellW, cellH);
    _desenharPingsAtivos(canvas, cellW, cellH);
  }

  bool _dentroLimites(Posicao2D pos, int largura, int altura) {
    return pos.x >= 0 && pos.x < largura && pos.y >= 0 && pos.y < altura;
  }

  static final Paint _obstaculoFill = Paint()
    ..color = Colors.black.withValues(alpha: 0.72)
    ..style = PaintingStyle.fill;
  static final Paint _obstaculoMark = Paint()
    ..color = Colors.white38
    ..strokeWidth = 1.4
    ..style = PaintingStyle.stroke;
  static final Paint _dificilFill = Paint()
    ..color = const Color(0xFFD97706).withValues(alpha: 0.32)
    ..style = PaintingStyle.fill;
  static final Paint _dificilMark = Paint()
    ..color = Colors.amberAccent.withValues(alpha: 0.85)
    ..strokeWidth = 1.3
    ..style = PaintingStyle.stroke;
  static final Paint _alcanceFill = Paint()
    ..color = const Color(0xFF38BDF8).withValues(alpha: 0.35)
    ..style = PaintingStyle.fill;
  static final Paint _areaMestreFill = Paint()
    ..color = const Color(0xFFF59E0B).withValues(alpha: 0.44)
    ..style = PaintingStyle.fill;
  static final Paint _areaMestreBorder = Paint()
    ..color = Colors.amberAccent
    ..strokeWidth = 1.6
    ..style = PaintingStyle.stroke;
  static final Paint _areaJogadorFill = Paint()
    ..color = const Color(0xFFEC4899).withValues(alpha: 0.40)
    ..style = PaintingStyle.fill;
  static final Paint _areaJogadorBorder = Paint()
    ..color = Colors.pinkAccent
    ..strokeWidth = 1.6
    ..style = PaintingStyle.stroke;
  static final Paint _areaBloqueadaFill = Paint()
    ..color = const Color(0xFF7F1D1D).withValues(alpha: 0.28)
    ..style = PaintingStyle.fill;
  static final Paint _centroVerticeBg = Paint()
    ..color = const Color(0xFF0F172A)
    ..style = PaintingStyle.fill;
  static final Paint _centroVerticeOuter = Paint()
    ..color = Colors.white
    ..strokeWidth = 2.0
    ..style = PaintingStyle.stroke;
  static final Paint _centroVerticeInner = Paint()
    ..color = Colors.amberAccent
    ..strokeWidth = 1.5
    ..style = PaintingStyle.stroke;
  static final Paint _fogPreviewPaint = Paint()
    ..color = const Color(0xFF050811)
    ..style = PaintingStyle.fill;
  static final Paint _fogMestrePaint = Paint()
    ..color = Colors.black.withValues(alpha: 0.48)
    ..style = PaintingStyle.fill;
  static final Paint _previewFogBorder = Paint()
    ..color = Colors.white.withValues(alpha: 0.05)
    ..strokeWidth = 0.5
    ..style = PaintingStyle.stroke;
  static final Paint _gridPaint = Paint()
    ..strokeWidth = 0.6
    ..style = PaintingStyle.stroke;
  static final Paint _alcanceBorder = Paint()
    ..color = Colors.cyanAccent
    ..strokeWidth = 1.5
    ..style = PaintingStyle.stroke;
  static final Paint _pillBgPaint = Paint()
    ..color = Colors.black87
    ..style = PaintingStyle.fill;
  static final Paint _markerFill = Paint()
    ..color = Colors.amberAccent
    ..style = PaintingStyle.fill;
  static final Paint _markerStroke = Paint()
    ..color = Colors.black87
    ..strokeWidth = 1.5
    ..style = PaintingStyle.stroke;
  static final Paint _lineGlow = Paint()
    ..color = Colors.black54
    ..strokeWidth = 4.5
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  static final Paint _linePaint = Paint()
    ..color = Colors.amberAccent
    ..strokeWidth = 2.4
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  static final Paint _pingOuterFill = Paint()
    ..color = Colors.cyanAccent.withValues(alpha: 0.22)
    ..style = PaintingStyle.fill;
  static final Paint _pingOuterStroke = Paint()
    ..color = Colors.cyanAccent
    ..strokeWidth = 2.0
    ..style = PaintingStyle.stroke;
  static final Paint _pingInnerStroke = Paint()
    ..color = Colors.amberAccent
    ..strokeWidth = 1.8
    ..style = PaintingStyle.stroke;
  static final Paint _pingCenterDot = Paint()
    ..color = Colors.amberAccent
    ..style = PaintingStyle.fill;

  static final Map<String, TextPainter> _custoTextCache = {};

  static TextPainter _obterTextPainterCusto(double custo) {
    final label = '${custo.toStringAsFixed(1)}m';
    return _custoTextCache.putIfAbsent(label, () {
      return TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.cyanAccent,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    });
  }

  void _desenharTerrenos(
    Canvas canvas,
    double cellW,
    double cellH,
    int largura,
    int altura,
  ) {
    if (mapaExibido.terrenos.isEmpty) return;

    final minDim = math.min(cellW, cellH);
    for (final entry in mapaExibido.terrenos.entries) {
      final pos = entry.key;
      if (!_dentroLimites(pos, largura, altura)) continue;

      final rect = Rect.fromLTWH(pos.x * cellW, pos.y * cellH, cellW, cellH);
      if (entry.value == TipoTerreno.obstaculo) {
        canvas.drawRect(rect, _obstaculoFill);
        final pad = minDim * 0.28;
        canvas.drawLine(
          Offset(rect.left + pad, rect.top + pad),
          Offset(rect.right - pad, rect.bottom - pad),
          _obstaculoMark,
        );
        canvas.drawLine(
          Offset(rect.right - pad, rect.top + pad),
          Offset(rect.left + pad, rect.bottom - pad),
          _obstaculoMark,
        );
      } else if (entry.value == TipoTerreno.dificil) {
        canvas.drawRect(rect, _dificilFill);
        final iconSize = minDim * 0.24;
        final topRight = Offset(rect.right - 3, rect.top + 3);
        final path = Path()
          ..moveTo(topRight.dx - iconSize, topRight.dy + iconSize)
          ..lineTo(topRight.dx - iconSize * 0.5, topRight.dy)
          ..lineTo(topRight.dx, topRight.dy + iconSize)
          ..close();
        canvas.drawPath(path, _dificilMark);
      }
    }
  }

  void _desenharAlcanceMovimento(
    Canvas canvas,
    double cellW,
    double cellH,
    int largura,
    int altura,
  ) {
    if (celulasAlcancaveis.isEmpty) return;

    for (final pos in celulasAlcancaveis) {
      if (!_dentroLimites(pos, largura, altura)) continue;
      if (emPreviewJogador && !mapaReal.celulasReveladas.contains(pos)) continue;

      final rect = Rect.fromLTWH(pos.x * cellW, pos.y * cellH, cellW, cellH);
      canvas.drawRect(rect, _alcanceFill);
    }
  }

  void _desenharAreasEfeito(
    Canvas canvas,
    double cellW,
    double cellH,
    int largura,
    int altura,
  ) {
    if (areasEfeitoAtivas.isEmpty) return;

    for (final area in areasEfeitoAtivas) {
      final fill = area.ehDoMestre ? _areaMestreFill : _areaJogadorFill;
      final border = area.ehDoMestre ? _areaMestreBorder : _areaJogadorBorder;

      for (final pos in area.celulasAfetadas) {
        if (!_dentroLimites(pos, largura, altura)) continue;
        if (emPreviewJogador && !mapaReal.celulasReveladas.contains(pos)) {
          continue;
        }
        final rect = Rect.fromLTWH(pos.x * cellW, pos.y * cellH, cellW, cellH);
        canvas.drawRect(rect, fill);
        canvas.drawRect(rect, border);
      }

      if (!emPreviewJogador) {
        for (final pos in area.celulasBloqueadas) {
          if (!_dentroLimites(pos, largura, altura)) continue;
          final rect = Rect.fromLTWH(
            pos.x * cellW,
            pos.y * cellH,
            cellW,
            cellH,
          );
          canvas.drawRect(rect, _areaBloqueadaFill);
        }
      }
    }
  }

  void _desenharCentrosAreasEfeito(
    Canvas canvas,
    double cellW,
    double cellH,
  ) {
    if (areasEfeitoAtivas.isEmpty) return;

    for (final area in areasEfeitoAtivas) {
      final v = area.centroVertice;
      if (v == null) continue;
      final center = Offset(v.vx * cellW, v.vy * cellH);
      canvas.drawCircle(center, 7.0, _centroVerticeBg);
      canvas.drawCircle(center, 7.0, _centroVerticeOuter);
      canvas.drawCircle(center, 4.0, _centroVerticeInner);
    }
  }

  void _desenharFogOfWar(
    Canvas canvas,
    double cellW,
    double cellH,
    int largura,
    int altura,
  ) {
    final reveladas = mapaReal.celulasReveladas;
    if (reveladas.length == largura * altura) return;

    final fogPaint = emPreviewJogador ? _fogPreviewPaint : _fogMestrePaint;

    for (int y = 0; y < altura; y++) {
      for (int x = 0; x < largura; x++) {
        final pos = Posicao2D(x, y);
        if (reveladas.contains(pos)) continue;

        final rect = Rect.fromLTWH(x * cellW, y * cellH, cellW, cellH);
        canvas.drawRect(rect, fogPaint);
        if (emPreviewJogador) {
          canvas.drawRect(rect, _previewFogBorder);
        }
      }
    }
  }

  void _desenharLinhasGrid(
    Canvas canvas,
    Size size,
    double cellW,
    double cellH,
    int largura,
    int altura,
  ) {
    _gridPaint.color = Colors.white.withValues(
      alpha: mapaExibido.opacidadeGrid,
    );

    for (int x = 0; x <= largura; x++) {
      final dx = x * cellW;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), _gridPaint);
    }
    for (int y = 0; y <= altura; y++) {
      final dy = y * cellH;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), _gridPaint);
    }
  }

  void _desenharBordasAlcanceECustos(
    Canvas canvas,
    double cellW,
    double cellH,
    int largura,
    int altura,
  ) {
    if (celulasAlcancaveis.isEmpty) return;

    for (final pos in celulasAlcancaveis) {
      if (!_dentroLimites(pos, largura, altura)) continue;
      if (emPreviewJogador && !mapaReal.celulasReveladas.contains(pos)) continue;

      final rect = Rect.fromLTWH(pos.x * cellW, pos.y * cellH, cellW, cellH);
      canvas.drawRect(rect, _alcanceBorder);

      final custo = custosMovimento[pos];
      if (custo != null) {
        final textPainter = _obterTextPainterCusto(custo);
        final bgWidth = textPainter.width + 6;
        final bgHeight = textPainter.height + 2;
        if (bgWidth <= cellW && bgHeight <= cellH) {
          final bgRect = RRect.fromRectAndRadius(
            Rect.fromLTWH(
              rect.right - bgWidth - 2,
              rect.bottom - bgHeight - 2,
              bgWidth,
              bgHeight,
            ),
            const Radius.circular(3),
          );
          canvas.drawRRect(bgRect, _pillBgPaint);
          textPainter.paint(
            canvas,
            Offset(bgRect.left + 3, bgRect.top + 1),
          );
        }
      }
    }
  }

  void _desenharMedicaoDistancia(
    Canvas canvas,
    double cellW,
    double cellH,
  ) {
    final orig = pontoOrigemMedicao;
    if (orig == null) return;

    final origCenter = Offset((orig.x + 0.5) * cellW, (orig.y + 0.5) * cellH);
    final dest = pontoDestinoMedicao;
    if (dest != null) {
      final destCenter = Offset((dest.x + 0.5) * cellW, (dest.y + 0.5) * cellH);

      canvas.drawLine(origCenter, destCenter, _lineGlow);
      canvas.drawLine(origCenter, destCenter, _linePaint);

      canvas.drawCircle(destCenter, 5.0, _markerFill);
      canvas.drawCircle(destCenter, 5.0, _markerStroke);
    }

    canvas.drawCircle(origCenter, 5.0, _markerFill);
    canvas.drawCircle(origCenter, 5.0, _markerStroke);
  }

  void _desenharPingsAtivos(
    Canvas canvas,
    double cellW,
    double cellH,
  ) {
    if (pingsAtivos.isEmpty) return;

    final baseRadius = math.min(cellW, cellH);

    for (final pos in pingsAtivos) {
      final center = Offset((pos.x + 0.5) * cellW, (pos.y + 0.5) * cellH);
      canvas.drawCircle(center, baseRadius * 0.42, _pingOuterFill);
      canvas.drawCircle(center, baseRadius * 0.42, _pingOuterStroke);
      canvas.drawCircle(center, baseRadius * 0.24, _pingInnerStroke);
      canvas.drawCircle(center, 3.0, _pingCenterDot);
    }
  }

  @override
  bool shouldRepaint(covariant _BattlemapGridPainter oldDelegate) {
    return oldDelegate.mapaExibido.largura != mapaExibido.largura ||
        oldDelegate.mapaExibido.altura != mapaExibido.altura ||
        oldDelegate.mapaExibido.gridVisivel != mapaExibido.gridVisivel ||
        oldDelegate.mapaExibido.opacidadeGrid != mapaExibido.opacidadeGrid ||
        oldDelegate.emPreviewJogador != emPreviewJogador ||
        (!identical(oldDelegate.mapaExibido.terrenos, mapaExibido.terrenos) &&
            !mapEquals(oldDelegate.mapaExibido.terrenos, mapaExibido.terrenos)) ||
        (!identical(
              oldDelegate.mapaReal.celulasReveladas,
              mapaReal.celulasReveladas,
            ) &&
            !setEquals(
              oldDelegate.mapaReal.celulasReveladas,
              mapaReal.celulasReveladas,
            )) ||
        (!identical(oldDelegate.celulasAlcancaveis, celulasAlcancaveis) &&
            !setEquals(oldDelegate.celulasAlcancaveis, celulasAlcancaveis)) ||
        (!identical(oldDelegate.custosMovimento, custosMovimento) &&
            !mapEquals(oldDelegate.custosMovimento, custosMovimento)) ||
        oldDelegate.pontoOrigemMedicao != pontoOrigemMedicao ||
        oldDelegate.pontoDestinoMedicao != pontoDestinoMedicao ||
        (!identical(oldDelegate.pingsAtivos, pingsAtivos) &&
            !listEquals(oldDelegate.pingsAtivos, pingsAtivos)) ||
        (!identical(oldDelegate.areasEfeitoAtivas, areasEfeitoAtivas) &&
            !listEquals(oldDelegate.areasEfeitoAtivas, areasEfeitoAtivas));
  }
}
