import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget de D20 tridimensional desenhado via CustomPainter (Ícosaedro Geométrico).
///
/// Apresenta:
/// 1. Faces triangulares icosaédricas com iluminação e profundidade visual.
/// 2. Animação de rotação com perspectiva (Matrix4), quique e desaceleração (~1.5s).
/// 3. Respeito estrito a `MediaQuery.disableAnimations`.
/// 4. Feedback tátil (`HapticFeedback`) ao pousar.
class D20Dice extends StatefulWidget {
  final int? valorFinal;
  final bool rolando;
  final double size;
  final VoidCallback? onRolagemConcluida;
  final Color? corPrimaria;
  final Color? corBorda;

  const D20Dice({
    super.key,
    this.valorFinal,
    this.rolando = false,
    this.size = 130,
    this.onRolagemConcluida,
    this.corPrimaria,
    this.corBorda,
  });

  @override
  State<D20Dice> createState() => _D20DiceState();
}

class _D20DiceState extends State<D20Dice> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rotacaoAnim;
  late final Animation<double> _quiqueAnim;
  final Random _shuffleRandom = Random();
  int _valorExibido = 20;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _rotacaoAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.decelerate,
    );

    _quiqueAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -35.0)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -35.0, end: 0.0)
            .chain(CurveTween(curve: Curves.bounceOut)),
        weight: 65,
      ),
    ]).animate(_controller);

    _controller.addListener(() {
      if (_controller.value < 0.85) {
        // Embaralha faces enquanto gira em alta velocidade
        setState(() {
          _valorExibido = 1 + _shuffleRandom.nextInt(20);
        });
      } else if (widget.valorFinal != null && _valorExibido != widget.valorFinal) {
        // Assenta no valor final pré-sorteado
        setState(() {
          _valorExibido = widget.valorFinal!;
        });
      }
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        HapticFeedback.mediumImpact();
        if (widget.valorFinal != null) {
          setState(() {
            _valorExibido = widget.valorFinal!;
          });
        }
        widget.onRolagemConcluida?.call();
      }
    });
  }

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      if (widget.rolando) {
        _iniciarAnimacao();
      } else if (widget.valorFinal != null) {
        _valorExibido = widget.valorFinal!;
      }
    }
  }

  @override
  void didUpdateWidget(covariant D20Dice oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rolando && !oldWidget.rolando) {
      _iniciarAnimacao();
    } else if (!widget.rolando && widget.valorFinal != null) {
      _valorExibido = widget.valorFinal!;
    }
  }

  void _iniciarAnimacao() {
    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (disableAnimations) {
      if (widget.valorFinal != null) {
        _valorExibido = widget.valorFinal!;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onRolagemConcluida?.call();
        }
      });
      return;
    }

    _controller.forward(from: 0.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    final corCorpo = widget.corPrimaria ??
        (colorScheme.brightness == Brightness.dark
            ? const Color(0xFF8B0000) // Vermelho Rubi Tormenta
            : colorScheme.primary);
    final corBordas = widget.corBorda ?? Colors.amberAccent;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final double t = disableAnimations ? 1.0 : _rotacaoAnim.value;
          final double yOffset = disableAnimations ? 0.0 : _quiqueAnim.value;

          // Rotação tridimensional com desaceleração
          final anguloGiro = (1.0 - t) * 4 * pi;
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.002) // Perspectiva 3D
            ..setTranslationRaw(0.0, yOffset, 0.0)
            ..rotateX(sin(anguloGiro * 0.7) * 0.4)
            ..rotateY(anguloGiro)
            ..rotateZ(cos(anguloGiro * 0.5) * 0.2);

          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: CustomPaint(
                painter: _IcosaedroD20Painter(
                  corPrincipal: corCorpo,
                  corBordas: corBordas,
                  valor: _valorExibido,
                  brilhoCritico: _valorExibido == 20 && !widget.rolando,
                  brilhoFalha: _valorExibido == 1 && !widget.rolando,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Painter geométrico que projeta as 10 faces frontais de um icosaedro regular (d20).
class _IcosaedroD20Painter extends CustomPainter {
  final Color corPrincipal;
  final Color corBordas;
  final int valor;
  final bool brilhoCritico;
  final bool brilhoFalha;

  _IcosaedroD20Painter({
    required this.corPrincipal,
    required this.corBordas,
    required this.valor,
    required this.brilhoCritico,
    required this.brilhoFalha,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final double R = size.width * 0.47;

    // Vértices do hexágono externo
    final List<Offset> outerVertices = [];
    for (int i = 0; i < 6; i++) {
      final double angulo = -pi / 6 + i * (pi / 3);
      outerVertices.add(Offset(cx + R * cos(angulo), cy + R * sin(angulo)));
    }

    // Vértices do triângulo invertido central
    final double rInner = R * 0.58;
    final List<Offset> innerVertices = [];
    for (int i = 0; i < 3; i++) {
      final double angulo = pi / 2 + i * (2 * pi / 3);
      innerVertices.add(Offset(cx + rInner * cos(angulo), cy + rInner * sin(angulo)));
    }

    final i0 = innerVertices[0]; // Ponto inferior
    final i1 = innerVertices[1]; // Ponto superior esquerdo
    final i2 = innerVertices[2]; // Ponto superior direito

    final v0 = outerVertices[0]; // Topo direito
    final v1 = outerVertices[1]; // Meio direito
    final v2 = outerVertices[2]; // Fundo direito
    final v3 = outerVertices[3]; // Fundo esquerdo
    final v4 = outerVertices[4]; // Meio esquerdo
    final v5 = outerVertices[5]; // Topo esquerdo

    // Paleta de sombreamento 3D das faces
    Color corFaceCentral = corPrincipal;
    if (brilhoCritico) {
      corFaceCentral = const Color(0xFFFFD700); // Ouro radiante
    } else if (brilhoFalha) {
      corFaceCentral = const Color(0xFF4A0000); // Preto / Carmesim sombrio
    }

    // 1. Face central (onde fica o número)
    _desenharTriangulo(
      canvas,
      i0,
      i1,
      i2,
      corFaceCentral,
      iluminacao: 1.25,
    );

    // 2. Três faces internas adjacentes
    _desenharTriangulo(canvas, i1, i2, v0, corPrincipal, iluminacao: 1.05);
    _desenharTriangulo(canvas, i1, i2, v5, corPrincipal, iluminacao: 0.95);
    _desenharTriangulo(canvas, i0, i1, v3, corPrincipal, iluminacao: 0.85);
    _desenharTriangulo(canvas, i0, i1, v4, corPrincipal, iluminacao: 0.90);
    _desenharTriangulo(canvas, i0, i2, v1, corPrincipal, iluminacao: 0.80);
    _desenharTriangulo(canvas, i0, i2, v2, corPrincipal, iluminacao: 0.75);

    // 3. Traçado das arestas icosaédricas
    final paintBorda = Paint()
      ..color = brilhoCritico
          ? Colors.amber
          : (brilhoFalha ? Colors.redAccent : corBordas.withValues(alpha: 0.85))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeJoin = StrokeJoin.round;

    final Path wireframe = Path()
      // Triângulo central
      ..moveTo(i0.dx, i0.dy)
      ..lineTo(i1.dx, i1.dy)
      ..lineTo(i2.dx, i2.dy)
      ..close()
      // Conexões com vértices externos
      ..moveTo(i1.dx, i1.dy)..lineTo(v5.dx, v5.dy)
      ..moveTo(i1.dx, i1.dy)..lineTo(v4.dx, v4.dy)
      ..moveTo(i1.dx, i1.dy)..lineTo(v0.dx, v0.dy)
      ..moveTo(i2.dx, i2.dy)..lineTo(v0.dx, v0.dy)
      ..moveTo(i2.dx, i2.dy)..lineTo(v1.dx, v1.dy)
      ..moveTo(i0.dx, i0.dy)..lineTo(v2.dx, v2.dy)
      ..moveTo(i0.dx, i0.dy)..lineTo(v3.dx, v3.dy)
      // Perímetro do hexágono
      ..moveTo(v0.dx, v0.dy)
      ..lineTo(v1.dx, v1.dy)
      ..lineTo(v2.dx, v2.dy)
      ..lineTo(v3.dx, v3.dy)
      ..lineTo(v4.dx, v4.dy)
      ..lineTo(v5.dx, v5.dy)
      ..close();

    canvas.drawPath(wireframe, paintBorda);

    // 4. Desenha o número no centro da face triangular central
    final centroFaceCentral = Offset(
      (i0.dx + i1.dx + i2.dx) / 3,
      (i0.dy + i1.dy + i2.dy) / 3,
    );

    final textSpan = TextSpan(
      text: '$valor',
      style: TextStyle(
        color: brilhoCritico ? Colors.black : Colors.white,
        fontSize: size.width * 0.22,
        fontWeight: FontWeight.w900,
        fontFamily: 'serif',
        shadows: [
          Shadow(
            color: brilhoCritico ? Colors.amberAccent : Colors.black87,
            blurRadius: brilhoCritico ? 8 : 4,
          ),
        ],
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        centroFaceCentral.dx - textPainter.width / 2,
        centroFaceCentral.dy - textPainter.height / 2,
      ),
    );
  }

  void _desenharTriangulo(
    Canvas canvas,
    Offset a,
    Offset b,
    Offset c,
    Color base, {
    double iluminacao = 1.0,
  }) {
    final path = Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(b.dx, b.dy)
      ..lineTo(c.dx, c.dy)
      ..close();

    final corSombreada = HSLColor.fromColor(base)
        .withLightness(
          (HSLColor.fromColor(base).lightness * iluminacao).clamp(0.05, 0.95),
        )
        .toColor();

    final paint = Paint()
      ..color = corSombreada
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _IcosaedroD20Painter oldDelegate) {
    return oldDelegate.valor != valor ||
        oldDelegate.brilhoCritico != brilhoCritico ||
        oldDelegate.brilhoFalha != brilhoFalha ||
        oldDelegate.corPrincipal != corPrincipal ||
        oldDelegate.corBordas != corBordas;
  }
}
