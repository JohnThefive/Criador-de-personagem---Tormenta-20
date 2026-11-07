import '../../entities/combate/resultado_ataque.dart';

class ArenaReport {
  final int rodadasTotais;
  final int totalAtaquesRealizados;
  final int totalAcertos;
  final int totalCriticos;
  final int danoTotalCausado;
  final int maiorDanoGolpe;
  final int danoTotalRecebido;
  final int pmGasto;
  final int magiasLancadas;
  final bool vitoria;

  const ArenaReport({
    required this.rodadasTotais,
    required this.totalAtaquesRealizados,
    required this.totalAcertos,
    required this.totalCriticos,
    required this.danoTotalCausado,
    this.maiorDanoGolpe = 0,
    required this.danoTotalRecebido,
    required this.pmGasto,
    this.magiasLancadas = 0,
    required this.vitoria,
  });

  /// Total de ataques que erraram o alvo
  int get totalErros => totalAtaquesRealizados - totalAcertos;

  /// Dano Médio por Rodada (DPR)
  double get dpr => rodadasTotais > 0 ? danoTotalCausado / rodadasTotais : 0.0;

  /// Taxa de Acerto percentual (0 a 100%)
  double get taxaAcerto => totalAtaquesRealizados > 0
      ? (totalAcertos / totalAtaquesRealizados) * 100
      : 0.0;

  /// Taxa de Crítico em relação aos acertos (0 a 100%)
  double get taxaCritico =>
      totalAcertos > 0 ? (totalCriticos / totalAcertos) * 100 : 0.0;

  /// Dano médio por golpe certeiro
  double get danoMedioPorAcerto =>
      totalAcertos > 0 ? danoTotalCausado / totalAcertos : 0.0;
}

class ArenaStatsCollector {
  int _ataques = 0;
  int _acertos = 0;
  int _criticos = 0;
  int _danoCausado = 0;
  int _maiorDanoGolpe = 0;
  int _danoRecebido = 0;
  int _pmGasto = 0;
  int _magiasLancadas = 0;

  int get ataques => _ataques;
  int get acertos => _acertos;
  int get criticos => _criticos;
  int get danoCausado => _danoCausado;
  int get maiorDanoGolpe => _maiorDanoGolpe;
  int get danoRecebido => _danoRecebido;
  int get pmGasto => _pmGasto;
  int get magiasLancadas => _magiasLancadas;

  /// Registra um ataque (físico ou com arma) com suporte ao sistema de honestidade
  void registrarAtaque({
    required bool acerto,
    required bool ehCritico,
    required int dano,
  }) {
    _ataques++;
    if (acerto) {
      _acertos++;
      _danoCausado += dano;
      if (dano > _maiorDanoGolpe) {
        _maiorDanoGolpe = dano;
      }
      if (ehCritico) _criticos++;
    }
  }

  /// Retrocompatibilidade com motor automático de combate
  void registrarAtaqueHeroi(ResultadoAtaque r) {
    registrarAtaque(
      acerto: r.acerto,
      ehCritico: r.ehCritico,
      dano: r.danoTotal,
    );
  }

  /// Registra lançamento de magia ou ativação de efeito
  void registrarMagia({required int custoPm, int dano = 0}) {
    _pmGasto += custoPm;
    _magiasLancadas++;
    if (dano > 0) {
      _danoCausado += dano;
      if (dano > _maiorDanoGolpe) {
        _maiorDanoGolpe = dano;
      }
    }
  }

  void registrarDanoRecebido(int valor) {
    if (valor > 0) {
      _danoRecebido += valor;
    }
  }

  void registrarGastoPm(int valor) {
    if (valor > 0) {
      _pmGasto += valor;
    }
  }

  void atualizarDanoRecebido(int valor) {
    if (valor > _danoRecebido) {
      _danoRecebido = valor;
    }
  }

  ArenaReport gerarRelatorio({
    required int rodadas,
    required bool vitoria,
    int? danoRecebidoOverride,
  }) {
    final danoFinal = danoRecebidoOverride ?? _danoRecebido;
    return ArenaReport(
      rodadasTotais: rodadas,
      totalAtaquesRealizados: _ataques,
      totalAcertos: _acertos,
      totalCriticos: _criticos,
      danoTotalCausado: _danoCausado,
      maiorDanoGolpe: _maiorDanoGolpe,
      danoTotalRecebido: danoFinal,
      pmGasto: _pmGasto,
      magiasLancadas: _magiasLancadas,
      vitoria: vitoria,
    );
  }
}
