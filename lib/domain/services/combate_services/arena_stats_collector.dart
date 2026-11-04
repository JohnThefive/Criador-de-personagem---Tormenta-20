import '../../entities/combate/resultado_ataque.dart';

class ArenaReport {
  final int rodadasTotais;
  final int totalAtaquesRealizados;
  final int totalAcertos;
  final int totalCriticos;
  final int danoTotalCausado;
  final int danoTotalRecebido;
  final int pmGasto;
  final bool vitoria;

  const ArenaReport({
    required this.rodadasTotais,
    required this.totalAtaquesRealizados,
    required this.totalAcertos,
    required this.totalCriticos,
    required this.danoTotalCausado,
    required this.danoTotalRecebido,
    required this.pmGasto,
    required this.vitoria,
  });

  /// Dano Médio por Rodada (DPR)
  double get dpr => rodadasTotais > 0 ? danoTotalCausado / rodadasTotais : 0.0;

  /// Taxa de Acerto percentual (0 a 100%)
  double get taxaAcerto => totalAtaquesRealizados > 0
      ? (totalAcertos / totalAtaquesRealizados) * 100
      : 0.0;

  /// Taxa de Crítico em relação aos acertos (0 a 100%)
  double get taxaCritico =>
      totalAcertos > 0 ? (totalCriticos / totalAcertos) * 100 : 0.0;
}

class ArenaStatsCollector {
  int _ataques = 0;
  int _acertos = 0;
  int _criticos = 0;
  int _danoCausado = 0;
  int _danoRecebido = 0;
  int _pmGasto = 0;

  void registrarAtaqueHeroi(ResultadoAtaque r) {
    _ataques++;
    if (r.acerto) {
      _acertos++;
      _danoCausado += r.danoTotal;
      if (r.ehCritico) _criticos++;
    }
  }

  void registrarDanoRecebido(int valor) {
    _danoRecebido += valor;
  }

  void registrarGastoPm(int valor) {
    _pmGasto += valor;
  }

  ArenaReport gerarRelatorio({required int rodadas, required bool vitoria}) {
    return ArenaReport(
      rodadasTotais: rodadas,
      totalAtaquesRealizados: _ataques,
      totalAcertos: _acertos,
      totalCriticos: _criticos,
      danoTotalCausado: _danoCausado,
      danoTotalRecebido: _danoRecebido,
      pmGasto: _pmGasto,
      vitoria: vitoria,
    );
  }
}
