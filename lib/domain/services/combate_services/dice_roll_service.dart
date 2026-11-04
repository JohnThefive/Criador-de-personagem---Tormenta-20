import 'dart:math';

enum TipoVantagem { normal, vantagem, desvantagem }

/// Resultado imutável e estruturado de uma rolagem de d20.
class ResultadoD20 {
  final int d20;
  final int? d20Segundo;
  final int modificador;
  final String nomeModificador;
  final TipoVantagem tipoVantagem;

  const ResultadoD20({
    required this.d20,
    this.d20Segundo,
    required this.modificador,
    required this.nomeModificador,
    this.tipoVantagem = TipoVantagem.normal,
  });

  int get total => d20 + modificador;
  bool get ehVinteNatural => d20 == 20;
  bool get ehUmNatural => d20 == 1;

  String get modFormatado => modificador >= 0 ? '+$modificador' : '$modificador';

  String get decomposicao {
    if (tipoVantagem != TipoVantagem.normal && d20Segundo != null) {
      final sufixo = tipoVantagem == TipoVantagem.vantagem ? 'Vantagem' : 'Desvantagem';
      return 'd20 ($d20 [dados: $d20, $d20Segundo ($sufixo)]) + $nomeModificador ($modFormatado) = $total';
    }
    return 'd20 ($d20) + $nomeModificador ($modFormatado) = $total';
  }

  @override
  String toString() => 'ResultadoD20(total: $total, $decomposicao)';
}

class ResultadoDano {
  final int total;
  final List<int> dadosRolados;
  final int bonusFixo;
  final bool ehCritico;
  final String decomposicao;

  const ResultadoDano({
    required this.total,
    required this.dadosRolados,
    required this.bonusFixo,
    this.ehCritico = false,
    required this.decomposicao,
  });

  @override
  String toString() => 'ResultadoDano(total: $total, $decomposicao)';
}

/// Serviço desacoplado e testável para rolagens de d20 e dano com Random injetável.
class DiceRollService {
  final Random _random;

  DiceRollService({Random? random}) : _random = random ?? Random();

  /// Executa rolagem de d20 (1 a 20) com suporte a modificador e vantagem/desvantagem
  ResultadoD20 rolarD20({
    int modificador = 0,
    String nomeModificador = 'Modificador',
    TipoVantagem vantagem = TipoVantagem.normal,
  }) {
    final primeiroDado = 1 + _random.nextInt(20);

    if (vantagem == TipoVantagem.normal) {
      return ResultadoD20(
        d20: primeiroDado,
        modificador: modificador,
        nomeModificador: nomeModificador,
        tipoVantagem: TipoVantagem.normal,
      );
    }

    final segundoDado = 1 + _random.nextInt(20);

    final dadoFinal = vantagem == TipoVantagem.vantagem
        ? max(primeiroDado, segundoDado)
        : min(primeiroDado, segundoDado);

    return ResultadoD20(
      d20: dadoFinal,
      d20Segundo: dadoFinal == primeiroDado ? segundoDado : primeiroDado,
      modificador: modificador,
      nomeModificador: nomeModificador,
      tipoVantagem: vantagem,
    );
  }

  /// Rola dados de dano baseados em expressão (ex: "1d8", "1d8+3", "2d6")
  /// Em Tormenta 20, acertos críticos multiplicam a quantidade de dados da arma (ex: 1d8 x2 -> 2d8)
  ResultadoDano rolarDano({
    required String expressaoDano,
    int bonusExtra = 0,
    String? dadoExtra,
    bool ehCritico = false,
    int multiplicadorCritico = 2,
  }) {
    final regex = RegExp(r'(\d+)\s*d\s*(\d+)(?:\s*([+-])\s*(\d+))?', caseSensitive: false);
    final match = regex.firstMatch(expressaoDano.trim());

    int qtdDados = 1;
    int faces = 6;
    int bonusBase = 0;

    if (match != null) {
      qtdDados = int.tryParse(match.group(1) ?? '1') ?? 1;
      faces = int.tryParse(match.group(2) ?? '6') ?? 6;
      if (match.group(3) != null && match.group(4) != null) {
        final sinal = match.group(3) == '-' ? -1 : 1;
        bonusBase = sinal * (int.tryParse(match.group(4)!) ?? 0);
      }
    }

    if (ehCritico) {
      qtdDados *= multiplicadorCritico;
    }

    final dadosRolados = <int>[];
    for (int i = 0; i < qtdDados; i++) {
      dadosRolados.add(1 + _random.nextInt(faces));
    }

    // Processa dado extra opcional (ex: "+1d6")
    if (dadoExtra != null && dadoExtra.trim().isNotEmpty) {
      final extraMatch = RegExp(r'(\d+)\s*d\s*(\d+)', caseSensitive: false).firstMatch(dadoExtra.trim());
      if (extraMatch != null) {
        final extraQtd = int.tryParse(extraMatch.group(1) ?? '1') ?? 1;
        final extraFaces = int.tryParse(extraMatch.group(2) ?? '6') ?? 6;
        for (int i = 0; i < extraQtd; i++) {
          dadosRolados.add(1 + _random.nextInt(extraFaces));
        }
      }
    }

    final somaDados = dadosRolados.fold<int>(0, (a, b) => a + b);
    final totalBonus = bonusBase + bonusExtra;
    final total = max(1, somaDados + totalBonus);

    final prefixoCritico = ehCritico ? ' [CRÍTICO x$multiplicadorCritico]' : '';
    final extraStr = dadoExtra != null && dadoExtra.isNotEmpty ? ' + $dadoExtra' : '';
    final bonusStr = totalBonus != 0 ? (totalBonus > 0 ? ' + $totalBonus' : ' - ${totalBonus.abs()}') : '';

    final decomposicao = '$expressaoDano$prefixoCritico$extraStr (dados: ${dadosRolados.join('+')})$bonusStr = $total';

    return ResultadoDano(
      total: total,
      dadosRolados: dadosRolados,
      bonusFixo: totalBonus,
      ehCritico: ehCritico,
      decomposicao: decomposicao,
    );
  }
}
