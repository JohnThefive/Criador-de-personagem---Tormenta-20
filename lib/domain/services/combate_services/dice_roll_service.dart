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

/// Serviço desacoplado e testável para rolagens de d20 com Random injetável.
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
}
