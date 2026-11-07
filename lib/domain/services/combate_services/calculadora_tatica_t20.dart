import 'dart:math';
import '../../entities/combate/combatente.dart';
import '../../entities/combate/grid_tatico.dart';
import '../../entities/equipamento/arma.dart';

/// Classificação da vantagem tática concedida por uma posição no grid
enum VantagemTaticaPosicao {
  nenhuma,
  cobertura, // +5 na Defesa e +2 em Reflexos (proteção contra ataques)
  flanco, // +2 no teste de ataque corpo a corpo
  seguraKiting, // Fora do alcance de deslocamento do inimigo (ideal para arqueiros/magos)
  alcanceCorpoACorpo, // Permite golpear imediatamente sem gastar mais movimento
}

/// Avaliação tática determinística de uma posição no grid de combate
class AvaliacaoPosicaoGrid {
  final Posicao2D posicao;
  final bool temCobertura;
  final bool temFlanco;
  final bool ehPosicaoSegura;
  final bool ehAdjacenteInimigo;
  final String rotuloTatico;

  const AvaliacaoPosicaoGrid({
    required this.posicao,
    this.temCobertura = false,
    this.temFlanco = false,
    this.ehPosicaoSegura = false,
    this.ehAdjacenteInimigo = false,
    this.rotuloTatico = '',
  });

  VantagemTaticaPosicao get vantagemPrincipal {
    if (temCobertura) return VantagemTaticaPosicao.cobertura;
    if (temFlanco) return VantagemTaticaPosicao.flanco;
    if (ehPosicaoSegura) return VantagemTaticaPosicao.seguraKiting;
    if (ehAdjacenteInimigo) return VantagemTaticaPosicao.alcanceCorpoACorpo;
    return VantagemTaticaPosicao.nenhuma;
  }
}

/// Avaliação matemática determinística de ataque com uma arma
class AvaliacaoAtaque {
  final double probabilidadeAcerto; // 0.05 a 0.95 (ou ajustado por vantagem)
  final double probabilidadeCritico;
  final double danoMedioNormal;
  final double danoMedioCritico;
  final double danoEsperado;
  final int margemAmeaca;
  final int multiplicadorCritico;

  const AvaliacaoAtaque({
    required this.probabilidadeAcerto,
    required this.probabilidadeCritico,
    required this.danoMedioNormal,
    required this.danoMedioCritico,
    required this.danoEsperado,
    required this.margemAmeaca,
    required this.multiplicadorCritico,
  });

  String get probabilidadePercentualFormatada =>
      '${(probabilidadeAcerto * 100).toStringAsFixed(0)}%';

  String get danoEsperadoFormatado => danoEsperado.toStringAsFixed(1);

  String get danoMedioFormatado => danoMedioNormal.toStringAsFixed(1);
}

/// Serviço de cálculo tático e apoio à decisão para combate de Tormenta 20
class CalculadoraTaticaT20 {
  static final _regexDano = RegExp(r'^(\d+)[dD](\d+)');

  /// Extrai a quantidade de dados e faces da string de dano do T20 (ex: "1d8", "2d6")
  static ({int quantidade, int faces}) extrairDadosArma(String danoStr) {
    final match = _regexDano.firstMatch(danoStr.trim());
    if (match != null) {
      return (
        quantidade: int.parse(match.group(1)!),
        faces: int.parse(match.group(2)!),
      );
    }
    return (quantidade: 1, faces: 6);
  }

  /// Calcula probabilidade de acerto e dano esperado de uma arma contra uma Defesa
  static AvaliacaoAtaque calcularAvaliacaoAtaque({
    required Arma arma,
    required int modAtaqueTotal,
    required int modDanoTotal,
    required int defesaAlvo,
    bool temVantagem = false,
    bool temDesvantagem = false,
  }) {
    // 1. Probabilidade de Acerto Simples no d20 (T20: 1 natural é erro auto, 20 natural é acerto auto)
    final valorAlvo = defesaAlvo - modAtaqueTotal;

    int facesAcerto = 0;
    for (int d = 1; d <= 20; d++) {
      if (d == 1) continue; // 1 é sempre erro
      if (d == 20 || d >= valorAlvo) {
        facesAcerto++;
      }
    }
    final double pAcertoBase = facesAcerto / 20.0;

    // Vantagem e Desvantagem
    double pAcertoFinal;
    if (temVantagem && !temDesvantagem) {
      pAcertoFinal = 1.0 - pow(1.0 - pAcertoBase, 2);
    } else if (temDesvantagem && !temVantagem) {
      pAcertoFinal = pow(pAcertoBase, 2).toDouble();
    } else {
      pAcertoFinal = pAcertoBase;
    }

    // 2. Probabilidade de Crítico (d20 natural >= margemAmeaca, e deve acertar)
    int facesCritico = 0;
    for (int d = 1; d <= 20; d++) {
      if (d == 1) continue;
      if (d >= arma.margemAmeaca && (d == 20 || d >= valorAlvo)) {
        facesCritico++;
      }
    }
    final double pCriticoBase = facesCritico / 20.0;
    double pCriticoFinal;
    if (temVantagem && !temDesvantagem) {
      pCriticoFinal = 1.0 - pow(1.0 - pCriticoBase, 2);
    } else if (temDesvantagem && !temVantagem) {
      pCriticoFinal = pow(pCriticoBase, 2).toDouble();
    } else {
      pCriticoFinal = pCriticoBase;
    }

    // 3. Médias de Dano
    final dados = extrairDadosArma(arma.dano);
    final mediaDadosBase = dados.quantidade * ((dados.faces + 1) / 2.0);
    final danoMedioNormal = max(1.0, mediaDadosBase + modDanoTotal);

    // No T20, no crítico apenas os dados da arma multiplicam
    final mediaDadosCriticos =
        (dados.quantidade * arma.multiplicadorCritico) *
        ((dados.faces + 1) / 2.0);
    final danoMedioCritico = max(1.0, mediaDadosCriticos + modDanoTotal);

    // 4. Dano Esperado (Expected Value)
    final pAcertoNormal = max(0.0, pAcertoFinal - pCriticoFinal);
    final danoEsperado =
        (pAcertoNormal * danoMedioNormal) + (pCriticoFinal * danoMedioCritico);

    return AvaliacaoAtaque(
      probabilidadeAcerto: pAcertoFinal,
      probabilidadeCritico: pCriticoFinal,
      danoMedioNormal: danoMedioNormal,
      danoMedioCritico: danoMedioCritico,
      danoEsperado: danoEsperado,
      margemAmeaca: arma.margemAmeaca,
      multiplicadorCritico: arma.multiplicadorCritico,
    );
  }

  /// Avalia taticamente as células alcançáveis de um personagem no grid
  static Map<Posicao2D, AvaliacaoPosicaoGrid> avaliarPosicoesGrid({
    required Posicao2D posHeroi,
    required Set<Posicao2D> alcancaveis,
    required Combatente heroi,
    required List<Combatente> todosCombatentes,
    required Map<String, Posicao2D> posicoes,
    required GridMapa mapaGrid,
  }) {
    final resultado = <Posicao2D, AvaliacaoPosicaoGrid>{};

    final inimigosVivos = todosCombatentes
        .where((c) => c.time == TimeCombatente.inimigo && c.pvAtual > 0)
        .toList();

    final aliadosVivos = todosCombatentes
        .where((c) => c.time == TimeCombatente.heroi && c.id != heroi.id && c.pvAtual > 0)
        .toList();

    for (final pos in alcancaveis) {
      bool temCobertura = false;
      bool temFlanco = false;
      bool ehPosicaoSegura = false;
      bool ehAdjacenteInimigo = false;
      final rotulos = <String>[];

      for (final inimigo in inimigosVivos) {
        final posInimigo = posicoes[inimigo.id];
        if (posInimigo == null) continue;

        final distInimigo = pos.distanciaMetros(posInimigo);
        final adjacente = pos.ehAdjacente(posInimigo);

        if (adjacente) {
          ehAdjacenteInimigo = true;

          // Flanco (R75): dois aliados ameaçam o mesmo inimigo em lados opostos
          for (final aliado in aliadosVivos) {
            final posAliado = posicoes[aliado.id];
            if (posAliado != null && posAliado.ehAdjacente(posInimigo)) {
              final emLadosOpostos = (pos.x + posAliado.x == 2 * posInimigo.x) &&
                  (pos.y + posAliado.y == 2 * posInimigo.y);
              if (emLadosOpostos) {
                temFlanco = true;
                break;
              }
            }
          }
        }

        // Cobertura: verifica se há obstáculo adjacente à célula candidato
        // que esteja situado na direção do inimigo (mais próximo do inimigo que a célula)
        for (int dx = -1; dx <= 1; dx++) {
          for (int dy = -1; dy <= 1; dy++) {
            if (dx == 0 && dy == 0) continue;
            final vizinho = Posicao2D(pos.x + dx, pos.y + dy);
            if (mapaGrid.obterTerreno(vizinho) == TipoTerreno.obstaculo) {
              final distVizinhoInimigo = vizinho.distanciaMetros(posInimigo);
              if (distVizinhoInimigo < distInimigo) {
                temCobertura = true;
                break;
              }
            }
          }
          if (temCobertura) break;
        }

        // Posição Segura (Kiting): fora do deslocamento de 1 turno do inimigo
        if (distInimigo > inimigo.deslocamentoMetros && !adjacente) {
          ehPosicaoSegura = true;
        }
      }

      if (temCobertura) rotulos.add('Cobertura (+5 Defesa)');
      if (temFlanco) rotulos.add('Flanco (+2 Ataque)');
      if (ehPosicaoSegura && !ehAdjacenteInimigo) rotulos.add('Distância Segura');
      if (ehAdjacenteInimigo && !temFlanco) rotulos.add('Alcance Corpo a Corpo');

      resultado[pos] = AvaliacaoPosicaoGrid(
        posicao: pos,
        temCobertura: temCobertura,
        temFlanco: temFlanco,
        ehPosicaoSegura: ehPosicaoSegura,
        ehAdjacenteInimigo: ehAdjacenteInimigo,
        rotuloTatico: rotulos.join(' • '),
      );
    }

    return resultado;
  }

  /// R75: Verifica se atacante e aliado estão flanqueando o defensor em lados opostos.
  static bool estaoFlanqueando({
    required Posicao2D atacante,
    required Posicao2D aliado,
    required Posicao2D defensor,
  }) {
    if (!atacante.ehAdjacente(defensor)) return false;
    if (!aliado.ehAdjacente(defensor)) return false;
    return (atacante.x + aliado.x == 2 * defensor.x) &&
        (atacante.y + aliado.y == 2 * defensor.y);
  }
}
