import '../services/data_services/call_regras_engenhocas.dart';

class Engenhoca {
  final String id;
  final String nomeCustomizado;
  final String magiaSimuladaKey;
  final int circulo;
  final int custoPmBase;
  final String modoUso; // 'empunhada' ou 'vestida'
  final int cdAtivacaoBase;
  final int usosHoje;
  final bool enguicado;
  final num espacosOcupados;

  const Engenhoca({
    required this.id,
    required this.nomeCustomizado,
    required this.magiaSimuladaKey,
    required this.circulo,
    required this.custoPmBase,
    required this.modoUso,
    required this.cdAtivacaoBase,
    this.usosHoje = 0,
    this.enguicado = false,
    this.espacosOcupados = 1,
  });

  /// CD atual para ativação no dia: aumenta em +5 para cada uso acumulado no mesmo dia
  int get cdAtivacaoAtual => cdAtivacaoBase + (usosHoje * 5);

  /// Custo de fabricação padrão em T$ (100 * CUSTO_PM_MAGIA)
  int get custoFabricacaoTibares => 100 * custoPmBase;

  /// CD do teste de Ofício (engenhoqueiro) para fabricação (20 + CUSTO_PM_MAGIA)
  int get cdFabricacao => 20 + custoPmBase;

  /// Se a engenhoca está apta a ser utilizada (não está enguiçada)
  bool get podeSerUsada => !enguicado;

  Engenhoca copyWith({
    String? id,
    String? nomeCustomizado,
    String? magiaSimuladaKey,
    int? circulo,
    int? custoPmBase,
    String? modoUso,
    int? cdAtivacaoBase,
    int? usosHoje,
    bool? enguicado,
    num? espacosOcupados,
  }) {
    return Engenhoca(
      id: id ?? this.id,
      nomeCustomizado: nomeCustomizado ?? this.nomeCustomizado,
      magiaSimuladaKey: magiaSimuladaKey ?? this.magiaSimuladaKey,
      circulo: circulo ?? this.circulo,
      custoPmBase: custoPmBase ?? this.custoPmBase,
      modoUso: modoUso ?? this.modoUso,
      cdAtivacaoBase: cdAtivacaoBase ?? this.cdAtivacaoBase,
      usosHoje: usosHoje ?? this.usosHoje,
      enguicado: enguicado ?? this.enguicado,
      espacosOcupados: espacosOcupados ?? this.espacosOcupados,
    );
  }

  factory Engenhoca.fromJson(Map<String, dynamic> json) {
    return Engenhoca(
      id: json['id']?.toString() ?? '',
      nomeCustomizado: json['nomeCustomizado']?.toString() ?? '',
      magiaSimuladaKey: json['magiaSimuladaKey']?.toString() ?? '',
      circulo: (json['circulo'] as num?)?.toInt() ?? 1,
      custoPmBase: (json['custoPmBase'] as num?)?.toInt() ?? 1,
      modoUso: json['modoUso']?.toString() ?? 'empunhada',
      cdAtivacaoBase: (json['cdAtivacaoBase'] as num?)?.toInt() ?? 16,
      usosHoje: (json['usosHoje'] as num?)?.toInt() ?? 0,
      enguicado: json['enguicado'] as bool? ?? false,
      espacosOcupados: json['espacosOcupados'] as num? ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nomeCustomizado': nomeCustomizado,
    'magiaSimuladaKey': magiaSimuladaKey,
    'circulo': circulo,
    'custoPmBase': custoPmBase,
    'modoUso': modoUso,
    'cdAtivacaoBase': cdAtivacaoBase,
    'usosHoje': usosHoje,
    'enguicado': enguicado,
    'espacosOcupados': espacosOcupados,
  };
}

class ResultadoValidacaoEngenhoca {
  final bool valido;
  final List<String> erros;
  final int custoPmCalculado;
  final int cdAtivacaoBaseCalculada;
  final int cdFabricacaoCalculada;
  final int custoFabricacaoCalculado;

  const ResultadoValidacaoEngenhoca({
    required this.valido,
    this.erros = const [],
    required this.custoPmCalculado,
    required this.cdAtivacaoBaseCalculada,
    required this.cdFabricacaoCalculada,
    required this.custoFabricacaoCalculado,
  });
}

class ValidadorEngenhoca {
  /// Valida a criação de uma engenhoca segundo as regras de Tormenta 20
  static ResultadoValidacaoEngenhoca validar({
    required String nomeCustomizado,
    required String magiaSimuladaKey,
    required int circulo,
    required String modoUso,
    int? nivelInventor,
    int? quantidadeEngenhocasExistentes,
    int? limiteEngenhocas,
  }) {
    final List<String> erros = [];

    if (nomeCustomizado.trim().isEmpty) {
      erros.add('O nome customizado da engenhoca é obrigatório.');
    }

    if (magiaSimuladaKey.trim().isEmpty) {
      erros.add('A magia simulada pela engenhoca é obrigatória.');
    }

    final modoUsoNorm = modoUso.trim().toLowerCase();
    if (modoUsoNorm != 'empunhada' && modoUsoNorm != 'vestida') {
      erros.add('O modo de uso deve ser "empunhada" ou "vestida".');
    }

    if (circulo < 1 || circulo > 5) {
      erros.add('O círculo da magia simulada deve ser entre 1 e 5.');
    }

    if (nivelInventor != null) {
      final circuloMaximoPermitido = BancoDeRegrasEngenhocas.circuloMaximoParaNivel(nivelInventor);
      if (circulo > circuloMaximoPermitido) {
        erros.add(
          'Um inventor de nível $nivelInventor pode criar engenhocas de até $circuloMaximoPermitidoº círculo (tentou $circuloº círculo).',
        );
      }
    }

    if (quantidadeEngenhocasExistentes != null && limiteEngenhocas != null) {
      if (quantidadeEngenhocasExistentes >= limiteEngenhocas) {
        erros.add(
          'Limite de engenhocas atingido ($quantidadeEngenhocasExistentes/$limiteEngenhocas).',
        );
      }
    }

    final custoPm = BancoDeRegrasEngenhocas.custoPmBaseParaCirculo(circulo);
    final cdAtivacaoBase = BancoDeRegrasEngenhocas.calcularCdAtivacaoBase(custoPm);
    final cdFabricacao = BancoDeRegrasEngenhocas.calcularCdFabricacao(custoPm);
    final custoFabricacao = BancoDeRegrasEngenhocas.calcularCustoFabricacaoTibares(custoPm);

    return ResultadoValidacaoEngenhoca(
      valido: erros.isEmpty,
      erros: erros,
      custoPmCalculado: custoPm,
      cdAtivacaoBaseCalculada: cdAtivacaoBase,
      cdFabricacaoCalculada: cdFabricacao,
      custoFabricacaoCalculado: custoFabricacao,
    );
  }
}
