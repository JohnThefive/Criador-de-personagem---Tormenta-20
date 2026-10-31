class RegrasCustomizacaoPoder {
  final int custoPmMinimo;
  final String custoPmMaximo;
  final bool permiteMultiplasInstancias;

  const RegrasCustomizacaoPoder({
    this.custoPmMinimo = 1,
    this.custoPmMaximo = 'nivel_do_personagem',
    this.permiteMultiplasInstancias = true,
  });

  factory RegrasCustomizacaoPoder.fromJson(Map<String, dynamic> json) {
    return RegrasCustomizacaoPoder(
      custoPmMinimo:
          (json['custoPmMinimo'] ?? json['custoPmMínimo'] as num?)?.toInt() ??
          1,
      custoPmMaximo:
          json['custoPmMaximo']?.toString() ?? 'nivel_do_personagem',
      permiteMultiplasInstancias:
          json['permiteMultiplasInstancias'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'custoPmMinimo': custoPmMinimo,
    'custoPmMaximo': custoPmMaximo,
    'permiteMultiplasInstancias': permiteMultiplasInstancias,
  };
}

class EscalamentoTormenta {
  final String tipoPasso; // 'outros_poderes' ou 'todos_poderes'
  final int divisor;
  final String efeito;

  const EscalamentoTormenta({
    required this.tipoPasso,
    this.divisor = 2,
    required this.efeito,
  });

  factory EscalamentoTormenta.fromJson(Map<String, dynamic> json) {
    return EscalamentoTormenta(
      tipoPasso: json['tipoPasso']?.toString() ?? 'outros_poderes',
      divisor: (json['divisor'] as num?)?.toInt() ?? 2,
      efeito: json['efeito']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'tipoPasso': tipoPasso,
    'divisor': divisor,
    'efeito': efeito,
  };
}

class Poder {
  final String key;
  final String nome;
  final String descricao;
  final String preRequisitoTexto;
  final int nivelMinimo;
  final List<String> caminhosExigidos;
  final List<String> poderesExigidos;
  final Map<String, int> atributosExigidos;
  final Map<String, int> atributosMaximos;
  final List<String> periciasExigidas;
  final int poderesTormentaMinimos;
  final int? circuloMagicoMinimo;
  final String? categoria;
  final EscalamentoTormenta? escalamentoTormenta;
  final String? referenciaTabela;
  final RegrasCustomizacaoPoder? regrasCustomizacao;
  final String? tipo;
  final String? subTipo;

  const Poder({
    required this.key,
    required this.nome,
    required this.descricao,
    this.preRequisitoTexto = '',
    this.nivelMinimo = 1,
    this.caminhosExigidos = const [],
    this.poderesExigidos = const [],
    this.atributosExigidos = const {},
    this.atributosMaximos = const {},
    this.periciasExigidas = const [],
    this.poderesTormentaMinimos = 0,
    this.circuloMagicoMinimo,
    this.categoria,
    this.escalamentoTormenta,
    this.referenciaTabela,
    this.regrasCustomizacao,
    this.tipo,
    this.subTipo,
  });

  bool get temCustomizacao =>
      referenciaTabela != null || regrasCustomizacao != null;

  bool get ehPoderTormenta =>
      categoria?.toLowerCase() == 'poder_tormenta' ||
      subTipo?.toLowerCase() == 'tormenta';

  static String _formatarIdentificador(String raw) {
    return raw
        .split('_')
        .map(
          (w) =>
              w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '',
        )
        .join(' ');
  }

  factory Poder.fromJson(Map<String, dynamic> json) {
    String prereq = json['preRequisitoTexto']?.toString() ?? '';
    int nivelMin = (json['nivelMinimo'] as num?)?.toInt() ?? 1;
    final List<String> poderesExig = List<String>.from(
      json['poderesExigidos'] ?? [],
    );
    final Map<String, int> atribExig = Map<String, int>.from(
      json['atributosExigidos'] ?? {},
    );
    final Map<String, int> atribMax = Map<String, int>.from(
      json['atributosMaximos'] ?? {},
    );
    final List<String> periciasExig = List<String>.from(
      json['periciasExigidas'] ?? [],
    );
    int tormentaMin = (json['poderesTormentaMinimos'] as num?)?.toInt() ?? 0;
    int? circuloMin = (json['circuloMagicoMinimo'] as num?)?.toInt();

    if (prereq.isEmpty && json['dados_brutos'] != null) {
      final dadosBrutos = json['dados_brutos'];
      if (dadosBrutos is Map && dadosBrutos['prerequisites'] != null) {
        final list = dadosBrutos['prerequisites'];
        if (list is List && list.isNotEmpty) {
          prereq = list.map((e) => e.toString()).join(', ');
        }
      }
    }

    // Extrai pré-requisitos de poderes da Tormenta (prerequisitos)
    if (json['prerequisitos'] is Map) {
      final mapPre = json['prerequisitos'] as Map;
      final List<String> partesTormenta = [];
      final minTorm = (mapPre['poderesTormentaMinimos'] as num?)?.toInt() ?? 0;
      if (minTorm > tormentaMin) {
        tormentaMin = minTorm;
        partesTormenta.add(
          minTorm == 1
              ? 'Outro poder da Tormenta'
              : '$minTorm outros poderes da Tormenta',
        );
      }
      if (mapPre['poderesEspecificos'] is List) {
        for (final pEsp in mapPre['poderesEspecificos'] as List) {
          final pStr = pEsp.toString();
          if (pStr.isNotEmpty && !poderesExig.contains(pStr)) {
            poderesExig.add(pStr);
            partesTormenta.add(_formatarIdentificador(pStr));
          }
        }
      }
      if (mapPre['atributos'] is Map) {
        final mapAtrib = mapPre['atributos'] as Map;
        mapAtrib.forEach((k, v) {
          final keyStr = k.toString().toLowerCase();
          final valInt = (v as num?)?.toInt() ?? 0;
          if (keyStr == 'carisma_maximo' || keyStr == 'car_max') {
            atribMax['CAR'] = valInt;
            partesTormenta.add('CAR $valInt ou menor');
          } else {
            final sigla = keyStr.toUpperCase();
            atribExig[sigla] = valInt;
            partesTormenta.add('$sigla $valInt');
          }
        });
      }
      if (prereq.isEmpty && partesTormenta.isNotEmpty) {
        prereq = partesTormenta.join(', ');
      }
    }

    // Extrai pré-requisitos estruturados de poderes gerais (requirements)
    if (json['requirements'] is List) {
      final List<String> partesTexto = [];
      for (final item in json['requirements'] as List) {
        if (item is! Map) continue;
        final subType = item['sub_type']?.toString() ?? '';
        if (subType != 'hard') continue;

        final reqType = item['type']?.toString() ?? '';
        switch (reqType) {
          case 'attr_value':
            final attr = item['attr']?.toString().toUpperCase() ?? '';
            final val = (item['value'] as num?)?.toInt() ?? 10;
            if (attr.isNotEmpty) {
              atribExig[attr] = val;
              final mod = val >= 10 ? ((val - 10) ~/ 2) : val;
              partesTexto.add('$attr +$mod');
            }
            break;
          case 'level':
          case 'lvl_de_personagem':
          case 'character_lvl':
          case 'character_level':
            final val = (item['value'] as num?)?.toInt() ?? 1;
            if (val > nivelMin) nivelMin = val;
            partesTexto.add('$valº nível de personagem');
            break;
          case 'skill_training':
          case 'expertise':
            final skillRaw = item['skill'] ?? item['id'];
            if (skillRaw is String && skillRaw.isNotEmpty) {
              periciasExig.add(skillRaw.toUpperCase());
              partesTexto.add('Treinado em ${_formatarIdentificador(skillRaw)}');
            } else if (skillRaw is List && skillRaw.isNotEmpty) {
              final nomes = skillRaw
                  .map((s) => _formatarIdentificador(s.toString()))
                  .join(' ou ');
              partesTexto.add('Treinado em $nomes');
            }
            break;
          case 'power':
          case 'feature':
          case 'class_feature':
            final powerRaw = item['power'] ?? item['id'];
            if (powerRaw is String && powerRaw.isNotEmpty) {
              poderesExig.add(powerRaw);
              partesTexto.add(_formatarIdentificador(powerRaw));
            } else if (powerRaw is List && powerRaw.isNotEmpty) {
              final nomes = powerRaw
                  .map((p) => _formatarIdentificador(p.toString()))
                  .join(' ou ');
              partesTexto.add(nomes);
            }
            break;
          case 'magic_circle':
            final val = (item['value'] ?? item['circle'] as num?)?.toInt();
            if (val != null) {
              circuloMin = val;
              partesTexto.add('Lançar magias de $valº círculo');
            }
            break;
        }
      }
      if (prereq.isEmpty && partesTexto.isNotEmpty) {
        prereq = partesTexto.join(', ');
      }
    }

    return Poder(
      key: json['key']?.toString() ?? json['id']?.toString() ?? '',
      nome: json['nome']?.toString() ?? json['name']?.toString() ?? '',
      descricao:
          json['descricao']?.toString() ?? json['description']?.toString() ?? '',
      preRequisitoTexto: prereq,
      nivelMinimo: nivelMin,
      caminhosExigidos: List<String>.from(json['caminhosExigidos'] ?? []),
      poderesExigidos: poderesExig,
      atributosExigidos: atribExig,
      atributosMaximos: atribMax,
      periciasExigidas: periciasExig,
      poderesTormentaMinimos: tormentaMin,
      circuloMagicoMinimo: circuloMin,
      categoria: json['categoria']?.toString(),
      escalamentoTormenta: json['escalamentoTormenta'] is Map
          ? EscalamentoTormenta.fromJson(
              Map<String, dynamic>.from(json['escalamentoTormenta'] as Map),
            )
          : null,
      referenciaTabela: json['referenciaTabela']?.toString(),
      regrasCustomizacao: json['regrasCustomizacao'] != null
          ? RegrasCustomizacaoPoder.fromJson(
              Map<String, dynamic>.from(json['regrasCustomizacao'] as Map),
            )
          : null,
      tipo: json['tipo']?.toString() ?? json['type']?.toString(),
      subTipo: json['subTipo']?.toString() ?? json['sub_type']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'key': key,
    'nome': nome,
    'descricao': descricao,
    if (preRequisitoTexto.isNotEmpty) 'preRequisitoTexto': preRequisitoTexto,
    if (nivelMinimo > 1) 'nivelMinimo': nivelMinimo,
    if (caminhosExigidos.isNotEmpty) 'caminhosExigidos': caminhosExigidos,
    if (poderesExigidos.isNotEmpty) 'poderesExigidos': poderesExigidos,
    if (atributosExigidos.isNotEmpty) 'atributosExigidos': atributosExigidos,
    if (atributosMaximos.isNotEmpty) 'atributosMaximos': atributosMaximos,
    if (periciasExigidas.isNotEmpty) 'periciasExigidas': periciasExigidas,
    if (poderesTormentaMinimos > 0)
      'poderesTormentaMinimos': poderesTormentaMinimos,
    if (circuloMagicoMinimo != null)
      'circuloMagicoMinimo': circuloMagicoMinimo,
    if (categoria != null) 'categoria': categoria,
    if (escalamentoTormenta != null)
      'escalamentoTormenta': escalamentoTormenta!.toJson(),
    if (referenciaTabela != null) 'referenciaTabela': referenciaTabela,
    if (regrasCustomizacao != null)
      'regrasCustomizacao': regrasCustomizacao!.toJson(),
    if (tipo != null) 'tipo': tipo,
    if (subTipo != null) 'subTipo': subTipo,
  };
}
