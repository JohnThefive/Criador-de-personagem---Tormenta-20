import 'arma.dart';

class ArmaNaturalForma {
  final String tipo;
  final String dano;
  final String critico;

  const ArmaNaturalForma({
    required this.tipo,
    required this.dano,
    required this.critico,
  });

  factory ArmaNaturalForma.fromJson(Map<String, dynamic> json) {
    return ArmaNaturalForma(
      tipo: json['tipo']?.toString() ?? 'arma_natural',
      dano: json['dano']?.toString() ?? '1d6',
      critico: json['critico']?.toString() ?? '20/x2',
    );
  }

  Map<String, dynamic> toJson() => {
    'tipo': tipo,
    'dano': dano,
    'critico': critico,
  };

  Arma toArma(String nomeForma, [int indice = 1]) {
    int margem = 20;
    int mult = 2;
    if (critico.contains('/')) {
      final partes = critico.split('/');
      margem = int.tryParse(partes[0].trim()) ?? 20;
      final mStr = partes[1].replaceAll('x', '').trim();
      mult = int.tryParse(mStr) ?? 2;
    } else if (critico.contains('x')) {
      final mStr = critico.replaceAll('x', '').trim();
      mult = int.tryParse(mStr) ?? 2;
    }

    final ehDuasArmas = tipo.toLowerCase().contains('duas');
    final nomeArma = ehDuasArmas
        ? 'Arma Natural $indice ($nomeForma)'
        : 'Arma Natural ($nomeForma)';

    return Arma(
      key: 'arma_natural_${nomeForma.toLowerCase().replaceAll(' ', '_')}_$indice',
      nome: nomeArma,
      descricao: 'Arma natural concedida pela $nomeForma.',
      proficiencia: ProficienciaArma.simples,
      proposito: PropositoArma.corpoACorpo,
      empunhadura: EmpunhaduraArma.leve,
      dano: dano,
      margemAmeaca: margem,
      multiplicadorCritico: mult,
      tipoDano: TipoDanoArma.corte,
      espacos: 0,
      precoTibar: 0,
      alcance: 'Corpo a corpo',
      propriedades: ['Natural'],
    );
  }
}

class NivelFormaSelvagem {
  final int custoPm;
  final int nivelMinimo;
  final Map<String, int> modificadores;
  final String? deslocamento;
  final String? deslocamentoVoo;
  final String? tamanho;
  final Map<String, int> modificadoresGerais;
  final List<ArmaNaturalForma> armasNaturais;
  final String? penalidades;
  final List<Map<String, String>> opcoesDeslocamento;

  const NivelFormaSelvagem({
    required this.custoPm,
    required this.nivelMinimo,
    this.modificadores = const {},
    this.deslocamento,
    this.deslocamentoVoo,
    this.tamanho,
    this.modificadoresGerais = const {},
    this.armasNaturais = const [],
    this.penalidades,
    this.opcoesDeslocamento = const [],
  });

  factory NivelFormaSelvagem.fromJson(Map<String, dynamic> json) {
    final rawMod = (json['modificadores'] as Map?) ?? {};
    final mods = rawMod.map(
      (k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0),
    );

    final rawModGerais = (json['modificadoresGerais'] as Map?) ?? {};
    final modsGerais = rawModGerais.map(
      (k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0),
    );

    final rawArmas = (json['armasNaturais'] as List?) ?? [];
    final armas = rawArmas
        .map((a) => ArmaNaturalForma.fromJson(Map<String, dynamic>.from(a as Map)))
        .toList();

    final rawOpcoesDesl = (json['opcoesDeslocamento'] as List?) ?? [];
    final opcoes = rawOpcoesDesl
        .map((o) => (o as Map).map((k, v) => MapEntry(k.toString(), v.toString())))
        .toList();

    return NivelFormaSelvagem(
      custoPm: (json['custoPm'] as num?)?.toInt() ?? 3,
      nivelMinimo: (json['nivelMinimo'] as num?)?.toInt() ?? 1,
      modificadores: mods,
      deslocamento: json['deslocamento']?.toString(),
      deslocamentoVoo: json['deslocamentoVoo']?.toString(),
      tamanho: json['tamanho']?.toString(),
      modificadoresGerais: modsGerais,
      armasNaturais: armas,
      penalidades: json['penalidades']?.toString(),
      opcoesDeslocamento: opcoes,
    );
  }

  Map<String, dynamic> toJson() => {
    'custoPm': custoPm,
    'nivelMinimo': nivelMinimo,
    'modificadores': modificadores,
    'deslocamento': deslocamento,
    'deslocamentoVoo': deslocamentoVoo,
    'tamanho': tamanho,
    'modificadoresGerais': modificadoresGerais,
    'armasNaturais': armasNaturais.map((a) => a.toJson()).toList(),
    'penalidades': penalidades,
    'opcoesDeslocamento': opcoesDeslocamento,
  };
}

class FormaSelvagem {
  final String key;
  final String nome;
  final String descricaoGeral;
  final Map<String, NivelFormaSelvagem> niveis;

  const FormaSelvagem({
    required this.key,
    required this.nome,
    required this.descricaoGeral,
    required this.niveis,
  });

  factory FormaSelvagem.fromJson(Map<String, dynamic> json) {
    final rawNiveis = (json['niveis'] as Map?) ?? {};
    final mapNiveis = <String, NivelFormaSelvagem>{};

    rawNiveis.forEach((k, v) {
      if (v is Map) {
        mapNiveis[k.toString()] = NivelFormaSelvagem.fromJson(
          Map<String, dynamic>.from(v),
        );
      }
    });

    return FormaSelvagem(
      key: json['key']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      descricaoGeral: json['descricaoGeral']?.toString() ?? '',
      niveis: mapNiveis,
    );
  }

  Map<String, dynamic> toJson() => {
    'key': key,
    'nome': nome,
    'descricaoGeral': descricaoGeral,
    'niveis': niveis.map((k, v) => MapEntry(k, v.toJson())),
  };

  /// Retorna o tier elegível conforme o nível de Druida do personagem:
  /// - Nível 12+: superior
  /// - Nível 6+: aprimorada
  /// - Menor que 6: padrao
  String tierParaNivel(int nivelDruida) {
    if (nivelDruida >= 12 && niveis.containsKey('superior')) {
      return 'superior';
    }
    if (nivelDruida >= 6 && niveis.containsKey('aprimorada')) {
      return 'aprimorada';
    }
    return 'padrao';
  }

  NivelFormaSelvagem getNivelParaDruida(int nivelDruida) {
    final tier = tierParaNivel(nivelDruida);
    return niveis[tier] ?? niveis['padrao'] ?? const NivelFormaSelvagem(custoPm: 3, nivelMinimo: 1);
  }
}

/// Representa a transformação ativa no Personagem
class FormaSelvagemAtiva {
  final String formaKey;
  final String nome;
  final String tier; // 'padrao', 'aprimorada', 'superior'
  final int custoPm;
  final Map<String, int> modificadores;
  final String? tamanho;
  final String? deslocamento;
  final int rd;
  final List<ArmaNaturalForma> armasNaturais;

  const FormaSelvagemAtiva({
    required this.formaKey,
    required this.nome,
    required this.tier,
    required this.custoPm,
    this.modificadores = const {},
    this.tamanho,
    this.deslocamento,
    this.rd = 0,
    this.armasNaturais = const [],
  });

  factory FormaSelvagemAtiva.fromFormaENivel({
    required FormaSelvagem forma,
    required int nivelDruida,
  }) {
    final tier = forma.tierParaNivel(nivelDruida);
    final nivel = forma.getNivelParaDruida(nivelDruida);
    final rd = nivel.modificadores['RD'] ?? 0;

    return FormaSelvagemAtiva(
      formaKey: forma.key,
      nome: forma.nome,
      tier: tier,
      custoPm: nivel.custoPm,
      modificadores: Map.from(nivel.modificadores),
      tamanho: nivel.tamanho,
      deslocamento: nivel.deslocamento,
      rd: rd,
      armasNaturais: List.from(nivel.armasNaturais),
    );
  }

  factory FormaSelvagemAtiva.fromJson(Map<String, dynamic> json) {
    final rawMod = (json['modificadores'] as Map?) ?? {};
    final mods = rawMod.map(
      (k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0),
    );

    final rawArmas = (json['armasNaturais'] as List?) ?? [];
    final armas = rawArmas
        .map((a) => ArmaNaturalForma.fromJson(Map<String, dynamic>.from(a as Map)))
        .toList();

    return FormaSelvagemAtiva(
      formaKey: json['formaKey']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      tier: json['tier']?.toString() ?? 'padrao',
      custoPm: (json['custoPm'] as num?)?.toInt() ?? 3,
      modificadores: mods,
      tamanho: json['tamanho']?.toString(),
      deslocamento: json['deslocamento']?.toString(),
      rd: (json['rd'] as num?)?.toInt() ?? 0,
      armasNaturais: armas,
    );
  }

  Map<String, dynamic> toJson() => {
    'formaKey': formaKey,
    'nome': nome,
    'tier': tier,
    'custoPm': custoPm,
    'modificadores': modificadores,
    'tamanho': tamanho,
    'deslocamento': deslocamento,
    'rd': rd,
    'armasNaturais': armasNaturais.map((a) => a.toJson()).toList(),
  };

  /// Converte as armas naturais da forma em objetos `Arma`
  List<Arma> gerarArmas() {
    final List<Arma> lista = [];
    for (int i = 0; i < armasNaturais.length; i++) {
      final armaNat = armasNaturais[i];
      if (armaNat.tipo.toLowerCase().contains('duas')) {
        lista.add(armaNat.toArma(nome, 1));
        lista.add(armaNat.toArma(nome, 2));
      } else {
        lista.add(armaNat.toArma(nome, i + 1));
      }
    }
    return lista;
  }
}
