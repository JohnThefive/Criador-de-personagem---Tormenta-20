import '../services/data_services/call_efeitos_golpe_pessoal.dart';

class EfeitoGolpePessoal {
  final String key;
  final String nome;
  final int modificadorPm;
  final String tipo; // 'vantagem' ou 'desvantagem'
  final bool cumulativo;
  final int? limiteEscolhas;
  final List<String> opcoes;
  final String? restricao; // ex: 'arma_arremesso'
  final String? custoVariavel;
  final String descricao;

  const EfeitoGolpePessoal({
    required this.key,
    required this.nome,
    required this.modificadorPm,
    required this.tipo,
    this.cumulativo = false,
    this.limiteEscolhas,
    this.opcoes = const [],
    this.restricao,
    this.custoVariavel,
    required this.descricao,
  });

  bool get ehVantagem => tipo.toLowerCase() == 'vantagem';
  bool get ehDesvantagem => tipo.toLowerCase() == 'desvantagem';

  factory EfeitoGolpePessoal.fromJson(Map<String, dynamic> json) {
    final rawOpcoes = (json['opcoes'] as List?) ?? [];
    return EfeitoGolpePessoal(
      key: json['key']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      modificadorPm: (json['modificadorPm'] as num?)?.toInt() ?? 0,
      tipo: json['tipo']?.toString() ?? 'vantagem',
      cumulativo: json['cumulativo'] as bool? ?? false,
      limiteEscolhas: (json['limiteEscolhas'] as num?)?.toInt(),
      opcoes: rawOpcoes.map((o) => o.toString()).toList(),
      restricao: json['restricao']?.toString(),
      custoVariavel: json['custoVariavel']?.toString(),
      descricao: json['descricao']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'key': key,
    'nome': nome,
    'modificadorPm': modificadorPm,
    'tipo': tipo,
    'cumulativo': cumulativo,
    if (limiteEscolhas != null) 'limiteEscolhas': limiteEscolhas,
    if (opcoes.isNotEmpty) 'opcoes': opcoes,
    if (restricao != null) 'restricao': restricao,
    if (custoVariavel != null) 'custoVariavel': custoVariavel,
    'descricao': descricao,
  };
}

class GolpePessoal {
  final String id;
  final String nome;
  final String? armaKey;
  final String? armaNome;
  final List<String> efeitosKeys;
  final Map<String, dynamic> opcoesEfeitos;
  final int custoPmTotal;

  const GolpePessoal({
    required this.id,
    required this.nome,
    this.armaKey,
    this.armaNome,
    required this.efeitosKeys,
    this.opcoesEfeitos = const {},
    required this.custoPmTotal,
  });

  GolpePessoal copyWith({
    String? id,
    String? nome,
    String? armaKey,
    String? armaNome,
    List<String>? efeitosKeys,
    Map<String, dynamic>? opcoesEfeitos,
    int? custoPmTotal,
  }) {
    return GolpePessoal(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      armaKey: armaKey ?? this.armaKey,
      armaNome: armaNome ?? this.armaNome,
      efeitosKeys: efeitosKeys ?? this.efeitosKeys,
      opcoesEfeitos: opcoesEfeitos ?? this.opcoesEfeitos,
      custoPmTotal: custoPmTotal ?? this.custoPmTotal,
    );
  }

  factory GolpePessoal.fromJson(Map<String, dynamic> json) {
    final rawEfeitos = (json['efeitosKeys'] as List?) ?? [];
    final rawOpcoes = (json['opcoesEfeitos'] as Map?) ?? {};
    return GolpePessoal(
      id: json['id']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      armaKey: json['armaKey']?.toString(),
      armaNome: json['armaNome']?.toString(),
      efeitosKeys: rawEfeitos.map((e) => e.toString()).toList(),
      opcoesEfeitos: Map<String, dynamic>.from(rawOpcoes),
      custoPmTotal: (json['custoPmTotal'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nome': nome,
    if (armaKey != null) 'armaKey': armaKey,
    if (armaNome != null) 'armaNome': armaNome,
    'efeitosKeys': efeitosKeys,
    if (opcoesEfeitos.isNotEmpty) 'opcoesEfeitos': opcoesEfeitos,
    'custoPmTotal': custoPmTotal,
  };
}

class ResultadoValidacaoGolpe {
  final bool valido;
  final List<String> erros;
  final int custoCalculado;

  const ResultadoValidacaoGolpe({
    required this.valido,
    this.erros = const [],
    required this.custoCalculado,
  });
}

class ValidadorGolpePessoal {
  /// Valida todas as regras de T20 para a montagem de um Golpe Pessoal
  static ResultadoValidacaoGolpe validar({
    required String nome,
    required List<String> efeitosKeys,
    required int nivelGuerreiro,
    String? armaKey,
    bool armaEhArremesso = false,
    List<EfeitoGolpePessoal>? catalogoEfeitos,
  }) {
    final List<String> erros = [];

    if (nome.trim().isEmpty) {
      erros.add('O Golpe Pessoal precisa ter um nome.');
    }

    if (efeitosKeys.isEmpty) {
      erros.add('Escolha pelo menos um efeito para o Golpe Pessoal.');
    }

    final catalogo = catalogoEfeitos ?? BancoDeEfeitosGolpePessoal.todos;
    final Map<String, EfeitoGolpePessoal> mapaCatalogo = {
      for (var e in catalogo) e.key.toUpperCase(): e,
    };

    // Contagem de ocorrências de cada efeito
    final Map<String, int> contagem = {};
    int custoTotal = 0;

    for (final key in efeitosKeys) {
      final keyUpper = key.trim().toUpperCase();
      contagem[keyUpper] = (contagem[keyUpper] ?? 0) + 1;

      final efeito = mapaCatalogo[keyUpper];
      if (efeito != null) {
        custoTotal += efeito.modificadorPm;
      }
    }

    // Regra de acúmulo e limites de repetição
    for (final entry in contagem.entries) {
      final efeito = mapaCatalogo[entry.key];
      if (efeito == null) continue;

      if (!efeito.cumulativo && entry.value > 1) {
        erros.add('O efeito "${efeito.nome}" não pode ser escolhido mais de uma vez.');
      } else if (efeito.limiteEscolhas != null && entry.value > efeito.limiteEscolhas!) {
        erros.add(
          'O efeito "${efeito.nome}" permite no máximo ${efeito.limiteEscolhas} escolhas (você escolheu ${entry.value}).',
        );
      }
    }

    // Regra de restrição de arma (ex: Ricocheteante)
    final temQualquerArma = contagem.containsKey('QUALQUER_ARMA');
    for (final key in contagem.keys) {
      final efeito = mapaCatalogo[key];
      if (efeito?.restricao == 'arma_arremesso') {
        if (!temQualquerArma && !armaEhArremesso) {
          erros.add('O efeito "${efeito!.nome}" exige uma arma de arremesso (ou o efeito Qualquer Arma).');
        }
      }
    }

    // Regra de custo mínimo: 1 PM
    if (custoTotal < 1) {
      erros.add('O custo mínimo de um Golpe Pessoal é 1 PM (atualmente totaliza $custoTotal PM).');
    }

    // Regra de custo máximo: nível de guerreiro
    if (custoTotal > nivelGuerreiro) {
      erros.add(
        'O custo total de PM ($custoTotal PM) não pode exceder seu nível de guerreiro ($nivelGuerreiro PM).',
      );
    }

    return ResultadoValidacaoGolpe(
      valido: erros.isEmpty,
      erros: erros,
      custoCalculado: custoTotal,
    );
  }
}
