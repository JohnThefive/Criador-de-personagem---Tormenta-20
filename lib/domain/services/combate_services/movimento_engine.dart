import '../../entities/combate/combatente.dart';
import '../../entities/combate/grid_tatico.dart';

class ResultadoCalculoMovimento {
  final Map<Posicao2D, double> custosMetros;
  final Set<Posicao2D> destinosValidos;
  final Map<Posicao2D, Posicao2D?> antecessores;

  const ResultadoCalculoMovimento({
    required this.custosMetros,
    required this.destinosValidos,
    required this.antecessores,
  });

  List<Posicao2D> obterCaminhoAte(Posicao2D destino) {
    if (!destinosValidos.contains(destino)) return const [];
    final caminho = <Posicao2D>[];
    Posicao2D? atual = destino;

    while (atual != null) {
      caminho.add(atual);
      atual = antecessores[atual];
    }

    return caminho.reversed.toList();
  }
}

class MovimentoEngine {
  /// Calcula todas as células alcançáveis a partir de uma posição inicial,
  /// respeitando custos de terreno, diagonais, aliados e inimigos do T20.
  static ResultadoCalculoMovimento calcularAlcancaveis({
    required GridMapa mapa,
    required Posicao2D inicio,
    required double deslocamentoMaximoMetros,
    required Map<String, Posicao2D> posicoesCombatentes,
    required Map<String, Combatente> combatentesPorId,
    required String combatenteAtivoId,
  }) {
    final combatenteAtivo = combatentesPorId[combatenteAtivoId];
    final TimeCombatente timeAtivo =
        combatenteAtivo?.time ?? TimeCombatente.heroi;
    final int spanAtivo = combatenteAtivo?.tamanhoQuadrados ?? 1;

    // Criatura com DES nula ("–") ou sem deslocamento não pode se mover.
    if (combatenteAtivo?.temDestrezaNula == true ||
        deslocamentoMaximoMetros <= 0) {
      return ResultadoCalculoMovimento(
        custosMetros: {inicio: 0.0},
        destinosValidos: const {},
        antecessores: {inicio: null},
      );
    }

    // Mapeamento de ocupantes em todas as células do seu footprint N×N.
    final ocupantesPorPosicao = <Posicao2D, Combatente>{};
    for (final entry in posicoesCombatentes.entries) {
      final cId = entry.key;
      final pos = entry.value;
      if (cId != combatenteAtivoId && combatentesPorId.containsKey(cId)) {
        final ocupante = combatentesPorId[cId]!;
        for (final celula in pos.celulasOcupadas(ocupante.tamanhoQuadrados)) {
          ocupantesPorPosicao[celula] = ocupante;
        }
      }
    }

    final custos = <Posicao2D, double>{inicio: 0.0};
    final antecessores = <Posicao2D, Posicao2D?>{inicio: null};
    final fila = PriorityQueue<_NodoMovimento>(
      (a, b) => a.custo.compareTo(b.custo),
    );

    fila.add(_NodoMovimento(inicio, 0.0));

    while (fila.isNotEmpty) {
      final atual = fila.removeFirst();

      if (atual.custo > (custos[atual.posicao] ?? double.infinity)) {
        continue;
      }

      // Explora 8 direções (4 ortogonais + 4 diagonais)
      for (int dx = -1; dx <= 1; dx++) {
        for (int dy = -1; dy <= 1; dy++) {
          if (dx == 0 && dy == 0) continue;

          final vizinho = Posicao2D(atual.posicao.x + dx, atual.posicao.y + dy);

          if (!mapa.areaDentroDosLimites(vizinho, spanAtivo)) continue;

          bool podeEntrar = true;
          bool temTerrenoDificil = false;
          bool ocupanteContaComoTerrenoDificil = false;

          for (final celula in vizinho.celulasOcupadas(spanAtivo)) {
            final terreno = mapa.obterTerreno(celula);
            if (terreno == TipoTerreno.obstaculo) {
              podeEntrar = false;
              break;
            }
            if (terreno == TipoTerreno.dificil) {
              temTerrenoDificil = true;
            }

            final ocupante = ocupantesPorPosicao[celula];
            if (ocupante != null && ocupante.time != timeAtivo) {
              // R73: Inimigos só se caídos/indefesos ou incapazes de agir; conta como terreno difícil
              final permiteAtravessar =
                  ocupante.estaCaido ||
                  ocupante.estaIndefeso ||
                  !ocupante.podeAgir;
              if (!permiteAtravessar) {
                podeEntrar = false;
                break;
              }
              ocupanteContaComoTerrenoDificil = true;
            }
          }

          if (!podeEntrar) continue;

          final bool ehDiag = (dx.abs() == 1 && dy.abs() == 1);
          final bool ehTerrenoDificil =
              temTerrenoDificil || ocupanteContaComoTerrenoDificil;

          // Regras de custo em metros:
          // Ortogonal normal: 1.5m
          // Diagonal normal: 3.0m
          // Ortogonal difícil: 3.0m
          // Diagonal difícil: 4.5m
          double custoPasso;
          if (ehDiag) {
            custoPasso = ehTerrenoDificil ? 4.5 : 3.0;
          } else {
            custoPasso = ehTerrenoDificil ? 3.0 : 1.5;
          }

          final novoCusto = atual.custo + custoPasso;

          if (novoCusto <= deslocamentoMaximoMetros) {
            final custoAnterior = custos[vizinho] ?? double.infinity;
            if (novoCusto < custoAnterior) {
              custos[vizinho] = novoCusto;
              antecessores[vizinho] = atual.posicao;
              fila.add(_NodoMovimento(vizinho, novoCusto));
            }
          }
        }
      }
    }

    // Destinos válidos: Qualquer âncora alcançável (diferente do início)
    // cujo footprint N×N NÃO sobreponha nenhum combatente (aliado ou inimigo)
    final destinosValidos = <Posicao2D>{};
    for (final entry in custos.entries) {
      final pos = entry.key;
      if (pos == inicio) continue;
      final sobrepoeOcupante = pos
          .celulasOcupadas(spanAtivo)
          .any(ocupantesPorPosicao.containsKey);
      if (!sobrepoeOcupante) {
        destinosValidos.add(pos);
      }
    }

    return ResultadoCalculoMovimento(
      custosMetros: custos,
      destinosValidos: destinosValidos,
      antecessores: antecessores,
    );
  }
}

class _NodoMovimento {
  final Posicao2D posicao;
  final double custo;

  _NodoMovimento(this.posicao, this.custo);
}

/// Fila de prioridade simples para o algoritmo de Dijkstra
class PriorityQueue<E> {
  final List<E> _elements = [];
  final int Function(E, E) _comparator;

  PriorityQueue(this._comparator);

  bool get isNotEmpty => _elements.isNotEmpty;

  void add(E element) {
    _elements.add(element);
    _elements.sort(_comparator);
  }

  E removeFirst() {
    return _elements.removeAt(0);
  }
}
