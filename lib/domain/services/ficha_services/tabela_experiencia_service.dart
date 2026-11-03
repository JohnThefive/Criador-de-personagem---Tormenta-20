/// Detalhamento do progresso de Pontos de Experiência (XP) em Tormenta 20.
class ProgressoExperiencia {
  final int nivelAtual;
  final int xpAtual;

  const ProgressoExperiencia({
    required this.nivelAtual,
    required this.xpAtual,
  });

  int get xpBaseNivelAtual => TabelaExperienciaService.xpTotalParaNivel(nivelAtual);
  int get xpNecessarioProximoNivel =>
      TabelaExperienciaService.xpTotalParaNivel(nivelAtual >= 20 ? 20 : nivelAtual + 1);
  int get xpIntervaloNivel =>
      nivelAtual >= 20 ? 0 : xpNecessarioProximoNivel - xpBaseNivelAtual;
  int get xpProgressoNoIntervalo => nivelAtual >= 20
      ? xpIntervaloNivel
      : (xpAtual - xpBaseNivelAtual).clamp(0, xpIntervaloNivel);
  int get xpRestanteProximoNivel => nivelAtual >= 20
      ? 0
      : (xpNecessarioProximoNivel - xpAtual).clamp(0, xpNecessarioProximoNivel);
  int get xpRestanteParaUpar => xpRestanteProximoNivel;
  double get porcentagemProgresso => nivelAtual >= 20
      ? 1.0
      : (xpIntervaloNivel == 0 ? 1.0 : (xpProgressoNoIntervalo / xpIntervaloNivel).clamp(0.0, 1.0));
  double get porcentagem => porcentagemProgresso;
  String get porcentagemFormatada =>
      '${(porcentagem * 100).toStringAsFixed(0)}%';
  bool get temXpSuficienteParaUpar =>
      nivelAtual < 20 && xpAtual >= xpNecessarioProximoNivel;
  bool get nivelMaximoAtingido => nivelAtual >= 20;
}

/// Tabela Oficial de XP Tormenta 20 (Níveis 1 ao 20):
/// Fórmula canônica: XP(N) = (N * (N - 1) / 2) * 1.000
class TabelaExperienciaService {
  static const int nivelMaximo = 20;
  static const int xpNivelMaximo = 190000;

  static int xpTotalParaNivel(int lvl) =>
      lvl <= 1 ? 0 : (lvl >= 20 ? xpNivelMaximo : (lvl * (lvl - 1) ~/ 2) * 1000);

  static int xpIntervaloParaProximoNivel(int lvl) =>
      lvl >= 20 ? 0 : xpTotalParaNivel(lvl + 1) - xpTotalParaNivel(lvl);

  static ProgressoExperiencia calcularProgresso({
    required int nivelAtual,
    required int xpAtual,
  }) => ProgressoExperiencia(nivelAtual: nivelAtual, xpAtual: xpAtual);
}
