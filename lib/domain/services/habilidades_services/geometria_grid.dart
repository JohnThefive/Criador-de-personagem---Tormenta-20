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

  /// Converte um vetor `(origem -> destino)` em uma das 8 direções do grid
  /// (4 retas: N/S/L/O e 4 diagonais: NE/NO/SE/SO).
  ({int dx, int dy}) direcaoOitoSentidos(Posicao2D origem, Posicao2D destino) {
    final diffX = destino.x - origem.x;
    final diffY = destino.y - origem.y;
    if (diffX == 0 && diffY == 0) {
      return (dx: 1, dy: 0);
    }
    final angulo = atan2(diffY.toDouble(), diffX.toDouble());
    final octante = ((angulo / (pi / 4)).round() % 8 + 8) % 8;
    return switch (octante) {
      0 => (dx: 1, dy: 0), // Leste (→)
      1 => (dx: 1, dy: 1), // Sudeste (↘)
      2 => (dx: 0, dy: 1), // Sul (↓)
      3 => (dx: -1, dy: 1), // Sudoeste (↙)
      4 => (dx: -1, dy: 0), // Oeste (←)
      5 => (dx: -1, dy: -1), // Noroeste (↖)
      6 => (dx: 0, dy: -1), // Norte (↑)
      _ => (dx: 1, dy: -1), // Nordeste (↗)
    };
  }

  /// Calcula todos os quadrados brutos da forma geométrica (antes do filtro de barreiras),
  /// seguindo fielmente a ilustração oficial de Áreas de Efeito do Tormenta 20
  /// (1 quadrado = 1,5 m; diagonais custam 2 quadrados).
  Set<Posicao2D> calcularQuadradosBrutosArea(Area area) {
    final resultado = <Posicao2D>{};
    final r = max(1, area.tamanhoQuadrados);

    switch (area.tipo) {
      case TipoArea.esfera:
      case TipoArea.cilindro:
        // Centro sempre na interseção de 4 quadrados (vértice).
        // Em T20: Raio 1,5m (r=1) -> 2x2 (4q); Raio 3m (r=2) -> 2-4-4-2 (12q);
        // Raio 6m (r=4) -> 2-4-6-8-8-6-4-2 (40q), satisfazendo distX + distY <= r.
        final v = area.origemVertice ??
            VerticeGrid(
              area.celulaReferenciaOrigem.x,
              area.celulaReferenciaOrigem.y,
            );
        for (int x = v.vx - r; x < v.vx + r; x++) {
          for (int y = v.vy - r; y < v.vy + r; y++) {
            final distX = (x + 0.5 - v.coordX).abs();
            final distY = (y + 0.5 - v.coordY).abs();
            if (distX + distY <= r + 1e-9) {
              resultado.add(Posicao2D(x, y));
            }
          }
        }
        break;

      case TipoArea.quadrado:
      case TipoArea.cubo:
        // Cubo 1,5m (r=1) -> 1 quadrado; Cubo 3m (r=2) -> bloco 2x2 (4 quadrados).
        final orig = area.celulaReferenciaOrigem;
        for (int dx = 0; dx < r; dx++) {
          for (int dy = 0; dy < r; dy++) {
            resultado.add(Posicao2D(orig.x + dx, orig.y + dy));
          }
        }
        break;

      case TipoArea.linha:
        // Começa no quadrado adjacente ao personagem e segue reta nas 8 direções.
        final orig = area.celulaReferenciaOrigem;
        final dest = area.direcaoDestino ?? Posicao2D(orig.x + r, orig.y);
        final dir = direcaoOitoSentidos(orig, dest);
        final stepX = dir.dx;
        final stepY = dir.dy;
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
        // Cone T20 nas 8 direções (4 retas e 4 diagonais), iniciando em `orig` (adjacente ao personagem):
        // - Reta: passo d (1..r) tem meia-largura d ~/ 2 -> larguras 1, 3, 3 (4,5m), 1, 3, 3, 5 (6m), 1, 3, 3, 5, 5, 7 (9m).
        // - Diagonal: triângulo retângulo u + v < r (4,5m -> 3+2+1=6q; 6m -> 4+3+2+1=10q; 9m -> 6+5+4+3+2+1=21q).
        final orig = area.celulaReferenciaOrigem;
        final dest = area.direcaoDestino ?? Posicao2D(orig.x + r, orig.y);
        final dir = direcaoOitoSentidos(orig, dest);

        if (dir.dx != 0 && dir.dy != 0) {
          for (int u = 0; u < r; u++) {
            for (int v = 0; v < r - u; v++) {
              resultado.add(
                Posicao2D(orig.x + u * dir.dx, orig.y + v * dir.dy),
              );
            }
          }
        } else {
          final horizontal = dir.dx != 0;
          final sinalPrincipal = horizontal ? dir.dx : dir.dy;
          for (int d = 1; d <= r; d++) {
            final meiaLargura = configuracoes.coneLarguraFinalIgualComprimento
                ? d ~/ 2
                : max(0, (d - 1) ~/ 3);
            for (int lateral = -meiaLargura; lateral <= meiaLargura; lateral++) {
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

  /// Converte todas as células de [TipoTerreno.obstaculo] de um [GridMapa] em [Barreira]s
  /// com leve inset (`1e-3`) para bloquear raios que atravessam obstáculos sem bloquear
  /// falsamente células adjacentes que apenas tocam a quina.
  List<Barreira> construirBarreirasObstaculos(GridMapa mapa) {
    const eps = 1e-3;
    final barreiras = <Barreira>[];
    for (final entry in mapa.terrenos.entries) {
      if (entry.value != TipoTerreno.obstaculo) continue;
      final p = entry.key;
      final x1 = p.x + eps;
      final y1 = p.y + eps;
      final x2 = p.x + 1.0 - eps;
      final y2 = p.y + 1.0 - eps;
      barreiras.add(
        Barreira(
          id: 'obs_${p.x}_${p.y}',
          segmentos: [
            SegmentoBarreira(x1: x1, y1: y1, x2: x2, y2: y1),
            SegmentoBarreira(x1: x2, y1: y1, x2: x2, y2: y2),
            SegmentoBarreira(x1: x2, y1: y2, x2: x1, y2: y2),
            SegmentoBarreira(x1: x1, y1: y2, x2: x1, y2: y1),
          ],
        ),
      );
    }
    return barreiras;
  }

  /// Fonte única de verdade para projetar uma Área de Efeito oficial de Tormenta 20
  /// (Cone 8-direções, Esfera/Cilindro com `◎` na interseção, Cubo/Quadrado, Linha)
  /// sobre um [GridMapa], respeitando limites e bloqueio de linha de efeito por obstáculos.
  ({
    Set<Posicao2D> celulasArea,
    Set<Posicao2D> celulasBloqueadas,
    VerticeGrid? centroVertice,
    ({int dx, int dy})? direcaoAplicada,
    bool origemDentroDoAlcance,
    bool origemTemLinhaDeEfeito,
  }) calcularAreaTaticaNoMapa({
    required GridMapa mapa,
    required Posicao2D posLancador,
    required TipoArea tipoArea,
    required double tamanhoMetros,
    Posicao2D? pontoAlvo,
    VerticeGrid? verticeAlvo,
    double alcanceMaximoMetros = 90.0,
    bool ehAlcancePessoal = false,
    Set<Posicao2D>? celulasAlcancePrecalculadas,
  }) {
    final barreiras = construirBarreirasObstaculos(mapa);
    final tamanhoQuadrados = metrosParaQuadrados(tamanhoMetros).clamp(1, 40);
    final destino = pontoAlvo ?? posLancador;

    final Area areaConfigurada;
    VerticeGrid? centroVertice;
    ({int dx, int dy})? direcaoAplicada;
    bool origemDentroDoAlcance;
    bool origemTemLoE;

    switch (tipoArea) {
      case TipoArea.cone:
      case TipoArea.linha:
        final dir = direcaoOitoSentidos(posLancador, destino);
        direcaoAplicada = dir;
        final origem = Posicao2D(
          posLancador.x + dir.dx,
          posLancador.y + dir.dy,
        );
        final direcaoDestino = Posicao2D(
          origem.x + dir.dx * tamanhoQuadrados,
          origem.y + dir.dy * tamanhoQuadrados,
        );
        areaConfigurada = Area(
          tipo: tipoArea,
          tamanhoQuadrados: tamanhoQuadrados,
          origemCelula: origem,
          direcaoDestino: direcaoDestino,
        );
        origemDentroDoAlcance = true;
        origemTemLoE =
            mapa.dentroDosLimites(origem) &&
            mapa.obterTerreno(origem) != TipoTerreno.obstaculo;
        break;

      case TipoArea.esfera:
      case TipoArea.cilindro:
        final v =
            verticeAlvo ??
            VerticeGrid(
              destino.x.clamp(1, max(1, mapa.largura - 1)),
              destino.y.clamp(1, max(1, mapa.altura - 1)),
            );
        centroVertice = v;
        areaConfigurada = Area(
          tipo: tipoArea,
          tamanhoQuadrados: tamanhoQuadrados,
          alturaQuadrados: tamanhoQuadrados,
          origemVertice: v,
        );
        final maxQuadAlcance = metrosParaQuadrados(alcanceMaximoMetros);
        origemDentroDoAlcance =
            ehAlcancePessoal ||
            calcularDistanciaAteVertice(posLancador, v) <= maxQuadAlcance;
        origemTemLoE = temLinhaDeEfeito(
          origem: posLancador,
          destinoVertice: v,
          barreiras: barreiras,
        );
        break;

      case TipoArea.cubo:
      case TipoArea.quadrado:
      case TipoArea.outro:
        areaConfigurada = Area(
          tipo: tipoArea == TipoArea.quadrado
              ? TipoArea.quadrado
              : TipoArea.cubo,
          tamanhoQuadrados: tamanhoQuadrados,
          alturaQuadrados: tamanhoQuadrados,
          origemCelula: destino,
        );
        origemDentroDoAlcance =
            ehAlcancePessoal ||
            (celulasAlcancePrecalculadas != null
                ? celulasAlcancePrecalculadas.contains(destino)
                : posLancador.distanciaMetros(destino) <=
                      alcanceMaximoMetros + 1e-6);
        origemTemLoE =
            mapa.obterTerreno(destino) != TipoTerreno.obstaculo &&
            temLinhaDeEfeito(
              origem: posLancador,
              destinoCelula: destino,
              barreiras: barreiras,
            );
        break;
    }

    final brutos = calcularQuadradosBrutosArea(areaConfigurada);
    final celulasArea = <Posicao2D>{};
    final celulasBloqueadas = <Posicao2D>{};

    for (final pos in brutos) {
      if (!mapa.dentroDosLimites(pos)) continue;
      if (mapa.obterTerreno(pos) == TipoTerreno.obstaculo) {
        celulasBloqueadas.add(pos);
        continue;
      }
      if (!origemTemLoE) {
        celulasBloqueadas.add(pos);
        continue;
      }

      final bool propaga;
      if (centroVertice != null) {
        propaga = temLinhaDeEfeito(
          origem: pos,
          destinoVertice: centroVertice,
          barreiras: barreiras,
        );
      } else {
        final origemPropagacao =
            (tipoArea == TipoArea.cone || tipoArea == TipoArea.linha)
            ? posLancador
            : areaConfigurada.celulaReferenciaOrigem;
        propaga = temLinhaDeEfeito(
          origem: origemPropagacao,
          destinoCelula: pos,
          barreiras: barreiras,
        );
      }

      if (propaga) {
        celulasArea.add(pos);
      } else {
        celulasBloqueadas.add(pos);
      }
    }

    return (
      celulasArea: celulasArea,
      celulasBloqueadas: celulasBloqueadas,
      centroVertice: centroVertice,
      direcaoAplicada: direcaoAplicada,
      origemDentroDoAlcance: origemDentroDoAlcance,
      origemTemLinhaDeEfeito: origemTemLoE,
    );
  }
}
