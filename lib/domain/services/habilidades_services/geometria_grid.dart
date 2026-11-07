import 'dart:math';

import 'package:t20_creator/domain/entities/combate/grid_tatico.dart';
import 'package:t20_creator/domain/entities/habilidades/modelos_habilidade_duracao.dart';
import 'package:t20_creator/domain/entities/testes/configuracoes_mesa_t20.dart';

/// Preview geométrico de uma área no grid antes ou durante a confirmação (R34).
class PreviewAreaGrid {
  final Set<Posicao2D> quadradosAfetados;
  final Set<Posicao2D> quadradosBloqueadosPorBarreira;
  final List<String> alvosAfetadosIds;
  final bool origemDentroDoAlcance;
  final bool origemTemLinhaDeEfeito;

  const PreviewAreaGrid({
    required this.quadradosAfetados,
    this.quadradosBloqueadosPorBarreira = const {},
    required this.alvosAfetadosIds,
    required this.origemDentroDoAlcance,
    required this.origemTemLinhaDeEfeito,
  });
}

/// R24, R32, R33 e R34: Serviço puro de geometria tática no grid (1 quadrado = 1,5 m),
/// cálculo de alcances, raycast de linha de efeito e propagação de áreas.
class GeometriaGrid {
  final ConfiguracoesMesaT20 configuracoes;

  const GeometriaGrid({
    this.configuracoes = const ConfiguracoesMesaT20(),
  });

  /// Converte quadrados para metros (1 quadrado = 1,5 m).
  double quadradosParaMetros(int quadrados) =>
      quadrados * kMetrosPorQuadradoT20;

  /// Converte metros para quadrados inteiros.
  int metrosParaQuadrados(double metros) =>
      (metros / kMetrosPorQuadradoT20).round();

  /// R24: Calcula a distância em quadrados entre duas posições segundo a métrica da mesa.
  int calcularDistanciaQuadrados(Posicao2D a, Posicao2D b) {
    final dx = (a.x - b.x).abs();
    final dy = (a.y - b.y).abs();

    switch (configuracoes.metricaDistancia) {
      case MetricaDistanciaGrid.chebyshev:
        return max(dx, dy);
      case MetricaDistanciaGrid.alternada:
        final maior = max(dx, dy);
        final menor = min(dx, dy);
        return maior + ((menor * 3) ~/ 2);
      case MetricaDistanciaGrid.euclidiana:
        return sqrt((dx * dx) + (dy * dy)).floor();
    }
  }

  /// Calcula a distância em quadrados de uma célula `origem` até um vértice de interseção `vertice`.
  int calcularDistanciaAteVertice(Posicao2D origem, VerticeGrid vertice) {
    // O vértice (vx, vy) toca os quadrados (vx-1, vy-1), (vx, vy-1), (vx-1, vy) e (vx, vy).
    final dx = origem.x < vertice.vx
        ? (vertice.vx - 1 - origem.x)
        : (origem.x - vertice.vx);
    final dy = origem.y < vertice.vy
        ? (vertice.vy - 1 - origem.y)
        : (origem.y - vertice.vy);
    return max(0, max(dx, dy));
  }

  /// R24: Verifica se um ponto/alvo está dentro do alcance da habilidade a partir de `posicaoUsuario`.
  bool estaDentroDoAlcance({
    required Posicao2D posicaoUsuario,
    required AlcanceHabilidade alcance,
    Posicao2D? destinoCelula,
    VerticeGrid? destinoVertice,
  }) {
    final maxQuad = alcance.quadrados;
    if (maxQuad == null) {
      // Alcance ILIMITADO não possui restrição numérica de quadrados
      return true;
    }

    if (destinoVertice != null) {
      return calcularDistanciaAteVertice(posicaoUsuario, destinoVertice) <=
          maxQuad;
    }

    final destino = destinoCelula ?? posicaoUsuario;
    return calcularDistanciaQuadrados(posicaoUsuario, destino) <= maxQuad;
  }

  // ===========================================================================
  // R33: LINHA DE EFEITO (RAYCAST CONTRA SEGMENTOS DE BARREIRA)
  // ===========================================================================

  /// R33 (Caso de Borda 14): Verifica se há linha de efeito desobstruída entre dois pontos.
  /// Qualquer barreira sólida com `bloqueiaEfetivamente == true` (visível OU invisível) bloqueia.
  bool temLinhaDeEfeito({
    required Posicao2D origem,
    Posicao2D? destinoCelula,
    VerticeGrid? destinoVertice,
    List<Barreira> barreiras = const [],
    bool sobrescritaMestre = false,
  }) {
    if (sobrescritaMestre) return true;
    if (barreiras.isEmpty) return true;

    final double x0 = origem.x + 0.5;
    final double y0 = origem.y + 0.5;
    final double x1 = destinoVertice != null
        ? destinoVertice.coordX
        : ((destinoCelula ?? origem).x + 0.5);
    final double y1 = destinoVertice != null
        ? destinoVertice.coordY
        : ((destinoCelula ?? origem).y + 0.5);

    if ((x0 - x1).abs() < 1e-6 && (y0 - y1).abs() < 1e-6) {
      return true;
    }

    return !_raioInterceptaBarreira(x0, y0, x1, y1, barreiras);
  }

  bool _temLinhaDeEfeitoDeOrigemAreaParaCelula({
    required Area area,
    required Posicao2D celulaDestino,
    required List<Barreira> barreiras,
    bool sobrescritaMestre = false,
  }) {
    if (sobrescritaMestre || barreiras.isEmpty) return true;
    final double x0 = area.origemVertice != null
        ? area.origemVertice!.coordX
        : (area.celulaReferenciaOrigem.x + 0.5);
    final double y0 = area.origemVertice != null
        ? area.origemVertice!.coordY
        : (area.celulaReferenciaOrigem.y + 0.5);
    final double x1 = celulaDestino.x + 0.5;
    final double y1 = celulaDestino.y + 0.5;

    if ((x0 - x1).abs() < 1e-6 && (y0 - y1).abs() < 1e-6) {
      return true;
    }

    return !_raioInterceptaBarreira(x0, y0, x1, y1, barreiras);
  }

  bool _raioInterceptaBarreira(
    double x0,
    double y0,
    double x1,
    double y1,
    List<Barreira> barreiras,
  ) {
    for (final barreira in barreiras) {
      if (!barreira.bloqueiaEfetivamente) continue;
      for (final seg in barreira.segmentos) {
        if (_segmentosSeCruzam(x0, y0, x1, y1, seg.x1, seg.y1, seg.x2, seg.y2)) {
          return true;
        }
      }
    }
    return false;
  }

  bool _segmentosSeCruzam(
    double ax,
    double ay,
    double bx,
    double by,
    double cx,
    double cy,
    double dx,
    double dy,
  ) {
    double orientacao(
      double px,
      double py,
      double qx,
      double qy,
      double rx,
      double ry,
    ) {
      return (qy - py) * (rx - qx) - (qx - px) * (ry - qy);
    }

    bool noSegmento(
      double px,
      double py,
      double qx,
      double qy,
      double rx,
      double ry,
    ) {
      return qx <= max(px, rx) + 1e-9 &&
          qx >= min(px, rx) - 1e-9 &&
          qy <= max(py, ry) + 1e-9 &&
          qy >= min(py, ry) - 1e-9;
    }

    final o1 = orientacao(ax, ay, bx, by, cx, cy);
    final o2 = orientacao(ax, ay, bx, by, dx, dy);
    final o3 = orientacao(cx, cy, dx, dy, ax, ay);
    final o4 = orientacao(cx, cy, dx, dy, bx, by);

    if (((o1 > 1e-9 && o2 < -1e-9) || (o1 < -1e-9 && o2 > 1e-9)) &&
        ((o3 > 1e-9 && o4 < -1e-9) || (o3 < -1e-9 && o4 > 1e-9))) {
      return true;
    }

    if (o1.abs() <= 1e-9 && noSegmento(ax, ay, cx, cy, bx, by)) return true;
    if (o2.abs() <= 1e-9 && noSegmento(ax, ay, dx, dy, bx, by)) return true;
    if (o3.abs() <= 1e-9 && noSegmento(cx, cy, ax, ay, dx, dy)) return true;
    if (o4.abs() <= 1e-9 && noSegmento(cx, cy, bx, by, dx, dy)) return true;

    return false;
  }

  // ===========================================================================
  // R34: GEOMETRIA DE ÁREAS E PROPAGAÇÃO COM BARREIRAS
  // ===========================================================================

  /// R34 (Caso de Borda 17): Verifica se a área de ESFERA ou CILINDRO possui origem em vértice do grid.
  bool validarOrigemGeometriaArea(Area area) {
    if (area.tipo == TipoArea.esfera || area.tipo == TipoArea.cilindro) {
      return area.origemVertice != null;
    }
    return area.origemCelula != null || area.origemVertice != null;
  }

  /// Calcula todos os quadrados brutos da forma geométrica (antes do filtro de barreiras).
  Set<Posicao2D> calcularQuadradosBrutosArea(Area area) {
    final resultado = <Posicao2D>{};
    final r = max(1, area.tamanhoQuadrados);

    switch (area.tipo) {
      case TipoArea.esfera:
      case TipoArea.cilindro:
        final v = area.origemVertice ??
            VerticeGrid(
              area.celulaReferenciaOrigem.x,
              area.celulaReferenciaOrigem.y,
            );
        for (int x = v.vx - r; x < v.vx + r; x++) {
          for (int y = v.vy - r; y < v.vy + r; y++) {
            final distX = (x + 0.5 - v.coordX).abs();
            final distY = (y + 0.5 - v.coordY).abs();
            if (max(distX, distY) <= r) {
              resultado.add(Posicao2D(x, y));
            }
          }
        }
        break;

      case TipoArea.quadrado:
      case TipoArea.cubo:
        final orig = area.celulaReferenciaOrigem;
        for (int dx = 0; dx < r; dx++) {
          for (int dy = 0; dy < r; dy++) {
            resultado.add(Posicao2D(orig.x + dx, orig.y + dy));
          }
        }
        break;

      case TipoArea.linha:
        final orig = area.celulaReferenciaOrigem;
        final dest = area.direcaoDestino ?? Posicao2D(orig.x + r, orig.y);
        final dx = (dest.x - orig.x).sign;
        final dy = (dest.y - orig.y).sign;
        final stepX = (dx == 0 && dy == 0) ? 1 : dx;
        final stepY = dy;
        final largura = max(1, area.larguraQuadrados);

        for (int passo = 0; passo < r; passo++) {
          final cx = orig.x + passo * stepX;
          final cy = orig.y + passo * stepY;
          for (int w = 0; w < largura; w++) {
            if (stepX != 0 && stepY == 0) {
              resultado.add(Posicao2D(cx, cy + w));
            } else if (stepY != 0 && stepX == 0) {
              resultado.add(Posicao2D(cx + w, cy));
            } else {
              resultado.add(Posicao2D(cx + w, cy));
            }
          }
        }
        break;

      case TipoArea.cone:
        final orig = area.celulaReferenciaOrigem;
        final dest = area.direcaoDestino ?? Posicao2D(orig.x + r, orig.y);
        final diffX = dest.x - orig.x;
        final diffY = dest.y - orig.y;
        final horizontal = diffX.abs() >= diffY.abs();
        final sinalPrincipal = horizontal
            ? (diffX >= 0 ? 1 : -1)
            : (diffY >= 0 ? 1 : -1);

        // No passo d (1..r), a largura na extremidade é d (na extremidade r, largura = r)
        for (int d = 1; d <= r; d++) {
          final larguraPasso =
              configuracoes.coneLarguraFinalIgualComprimento ? d : max(1, d ~/ 2);
          final offsetInicial = -(larguraPasso ~/ 2);
          for (int k = 0; k < larguraPasso; k++) {
            final lateral = offsetInicial + k;
            if (horizontal) {
              resultado.add(
                Posicao2D(orig.x + (d - 1) * sinalPrincipal, orig.y + lateral),
              );
            } else {
              resultado.add(
                Posicao2D(orig.x + lateral, orig.y + (d - 1) * sinalPrincipal),
              );
            }
          }
        }
        break;

      case TipoArea.outro:
        final orig = area.celulaReferenciaOrigem;
        if (area.mascaraCustomizada.isEmpty) {
          resultado.add(orig);
        } else {
          for (final offset in area.mascaraCustomizada) {
            resultado.add(Posicao2D(orig.x + offset.x, orig.y + offset.y));
          }
        }
        break;
    }

    return resultado;
  }

  /// R34 (Casos de Borda 13, 14, 15, 17): Calcula o preview e os alvos atingidos pela área,
  /// respeitando propagação bloqueada por barreiras, elevação (cubo/cilindro),
  /// tipos de alvo permitidos e exclusão do usuário em alcance PESSOAL.
  PreviewAreaGrid calcularPreviewArea({
    required Posicao2D posicaoUsuario,
    required String usuarioId,
    required AlcanceHabilidade alcanceHabilidade,
    required List<TipoAlvoPermitido> alvosPermitidos,
    required Area area,
    required List<AlvoMapa> alvosNoMapa,
    List<Barreira> barreiras = const [],
    bool sobrescritaMestreLinhaEfeito = false,
  }) {
    final dentroDoAlcance = estaDentroDoAlcance(
      posicaoUsuario: posicaoUsuario,
      alcance: alcanceHabilidade,
      destinoCelula: area.origemCelula,
      destinoVertice: area.origemVertice,
    );

    final temLoEOrigem = temLinhaDeEfeito(
      origem: posicaoUsuario,
      destinoCelula: area.origemCelula,
      destinoVertice: area.origemVertice,
      barreiras: barreiras,
      sobrescritaMestre: sobrescritaMestreLinhaEfeito,
    );

    final brutos = calcularQuadradosBrutosArea(area);
    final afetados = <Posicao2D>{};
    final bloqueados = <Posicao2D>{};

    for (final celula in brutos) {
      final propaga = _temLinhaDeEfeitoDeOrigemAreaParaCelula(
        area: area,
        celulaDestino: celula,
        barreiras: barreiras,
        sobrescritaMestre: sobrescritaMestreLinhaEfeito,
      );
      if (propaga) {
        afetados.add(celula);
      } else {
        bloqueados.add(celula);
      }
    }

    // R34 e Caso de Borda 15: Habilidades de alcance PESSOAL não afetam o próprio usuário
    // salvo indicação contrária (`area.afetaUsuario == true`). Demais alcances afetam o usuário.
    final bool deveAfetarUsuario =
        area.afetaUsuario ?? (alcanceHabilidade != AlcanceHabilidade.pessoal);

    final alvosAtingidos = <String>[];
    for (final alvo in alvosNoMapa) {
      if (alvo.id == usuarioId && !deveAfetarUsuario) {
        continue;
      }
      if (!alvosPermitidos.contains(alvo.tipo)) {
        continue;
      }
      if (!afetados.contains(alvo.posicao)) {
        continue;
      }
      if (!_respeitaElevacaoArea(area, alvo.elevacaoQuadrados)) {
        continue;
      }
      alvosAtingidos.add(alvo.id);
    }

    return PreviewAreaGrid(
      quadradosAfetados: Set.unmodifiable(afetados),
      quadradosBloqueadosPorBarreira: Set.unmodifiable(bloqueados),
      alvosAfetadosIds: List.unmodifiable(alvosAtingidos),
      origemDentroDoAlcance: dentroDoAlcance,
      origemTemLinhaDeEfeito: temLoEOrigem,
    );
  }

  bool _respeitaElevacaoArea(Area area, int elevacaoAlvo) {
    if (area.tipo == TipoArea.cilindro || area.tipo == TipoArea.cubo) {
      final minZ = area.elevacaoBaseQuadrados;
      final maxZ = minZ + max(1, area.alturaQuadrados) - 1;
      return elevacaoAlvo >= minZ && elevacaoAlvo <= maxZ;
    }
    return true;
  }
}
