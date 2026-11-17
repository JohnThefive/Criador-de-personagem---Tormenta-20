import '../equipamento/arma.dart';

/// Papel tático da ameaça em combate no Tormenta 20.
enum PapelMonstro {
  lacaio('Lacaio'),
  especial('Especial'),
  padrao('Padrão'),
  solo('Solo'),
  chefe('Chefe');

  final String label;
  const PapelMonstro(this.label);

  /// Converte string do catálogo JSON ou rótulo para [PapelMonstro].
  static PapelMonstro fromString(String? val) {
    switch (val?.toLowerCase().trim()) {
      case 'lacaio':
        return PapelMonstro.lacaio;
      case 'especial':
        return PapelMonstro.especial;
      case 'solo':
        return PapelMonstro.solo;
      case 'chefe':
        return PapelMonstro.chefe;
      case 'padrao':
      case 'padrão':
      default:
        return PapelMonstro.padrao;
    }
  }
}

/// Entrada leve do índice de ameaças (`assets/data/ameacas/index.json`) para lazy-loading.
class AmeacaResumo {
  final String id;
  final String nome;
  final String nd;
  final String regiao;
  final PapelMonstro papel;
  final String tipoCriatura;
  final bool customizado;

  const AmeacaResumo({
    required this.id,
    required this.nome,
    required this.nd,
    required this.regiao,
    this.papel = PapelMonstro.solo,
    this.tipoCriatura = 'monstro',
    this.customizado = false,
  });

  /// Valor numérico do ND para ordenação e filtros (ex.: "1/4" ou "0.25" -> 0.25).
  double get ndNumerico => parseNdNumerico(nd);

  static double parseNdNumerico(String nd) {
    final limpo = nd.trim().toUpperCase();
    if (limpo == '1/4') return 0.25;
    if (limpo == '1/2') return 0.5;
    if (limpo == 'S') return 20.0;
    if (limpo == 'S+') return 21.0;
    return double.tryParse(limpo.replaceAll(',', '.')) ?? 0.0;
  }

  factory AmeacaResumo.fromJson(Map<String, dynamic> json) {
    return AmeacaResumo(
      id: (json['id'] ?? '').toString(),
      nome: (json['nome'] ?? '').toString(),
      nd: (json['nd'] ?? '1').toString(),
      regiao: (json['regiao'] ?? '').toString(),
      papel: PapelMonstro.fromString(json['papel']?.toString()),
      tipoCriatura: (json['tipo'] ?? json['tipoCriatura'] ?? 'monstro')
          .toString(),
      customizado: json['customizado'] as bool? ?? false,
    );
  }

  factory AmeacaResumo.fromMonstro(Monstro monstro) {
    return AmeacaResumo(
      id: monstro.id,
      nome: monstro.nome,
      nd: monstro.nd,
      regiao: monstro.regiao,
      papel: monstro.papel,
      tipoCriatura: monstro.tipoCriatura,
      customizado: monstro.customizado,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'nd': nd,
        'regiao': regiao,
        'papel': papel.name,
        'tipo': tipoCriatura,
        if (customizado) 'customizado': true,
      };
}

/// Recurso extraível do corpo da criatura (Sobrevivência/Ofício CD 15 + ND).
class RecursoExtraivelMonstro {
  final String nome;
  final String pericia;
  final int cdBase;

  const RecursoExtraivelMonstro({
    required this.nome,
    required this.pericia,
    required this.cdBase,
  });

  factory RecursoExtraivelMonstro.fromJson(Map<String, dynamic> json) {
    return RecursoExtraivelMonstro(
      nome: (json['nome'] ?? '').toString(),
      pericia: (json['pericia'] ?? 'sobrevivencia').toString(),
      cdBase: (json['cdBase'] as num?)?.toInt() ?? 15,
    );
  }

  Map<String, dynamic> toJson() => {
        'nome': nome,
        'pericia': pericia,
        'cdBase': cdBase,
      };
}

/// Habilidade ou ação especial estruturada da ameaça.
class HabilidadeMonstro {
  final String nome;
  final String acao; // passiva, livre, movimento, padrao, completa, reacao
  final int custoPm;
  final String? recarga;
  final int? cdResistencia;
  final String? resistenciaTipo;
  final String descricao;

  const HabilidadeMonstro({
    required this.nome,
    this.acao = 'passiva',
    this.custoPm = 0,
    this.recarga,
    this.cdResistencia,
    this.resistenciaTipo,
    required this.descricao,
  });

  bool get ehPassiva => acao.toLowerCase().trim() == 'passiva';
  bool get possuiRecarga => recarga != null && recarga!.trim().isNotEmpty;

  factory HabilidadeMonstro.fromJson(Map<String, dynamic> json) {
    return HabilidadeMonstro(
      nome: (json['nome'] ?? '').toString(),
      acao: (json['acao'] ?? 'passiva').toString(),
      custoPm: (json['custoPm'] as num?)?.toInt() ?? 0,
      recarga: json['recarga']?.toString(),
      cdResistencia: (json['cdResistencia'] as num?)?.toInt(),
      resistenciaTipo: json['resistenciaTipo']?.toString(),
      descricao: (json['descricao'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'nome': nome,
        'acao': acao,
        'custoPm': custoPm,
        'recarga': recarga,
        'cdResistencia': cdResistencia,
        'resistenciaTipo': resistenciaTipo,
        'descricao': descricao,
      };
}

/// Ataque configurado no bloco de ações da ameaça.
class AtaqueMonstro {
  final String nome;
  final int bonusAtaque; // ex: +8
  final String dano; // ex: "1d8+4"
  final String? danoExtra; // ex: "2d8 essencia"
  final int margemAmeaca; // ex: 20
  final int multiplicadorCritico; // ex: 2
  final TipoDanoArma tipoDano;
  final String? tipoDanoBruto;
  final String alcance; // "Corpo a corpo", "Curto", "Médio"
  final String acao; // padrao, livre, completa...
  final int custoPm;
  final String? descricaoEfeito; // ex: "Veneno (CD 14)"

  const AtaqueMonstro({
    required this.nome,
    required this.bonusAtaque,
    required this.dano,
    this.danoExtra,
    this.margemAmeaca = 20,
    this.multiplicadorCritico = 2,
    this.tipoDano = TipoDanoArma.impacto,
    this.tipoDanoBruto,
    this.alcance = 'Corpo a corpo',
    this.acao = 'padrao',
    this.custoPm = 0,
    this.descricaoEfeito,
  });

  static TipoDanoArma _parseTipoDanoArma(String? raw) {
    final norm = (raw ?? '').toLowerCase().trim();
    if (norm.contains('perfuracao') || norm.contains('perfuração')) {
      return TipoDanoArma.perfuracao;
    }
    if (norm.contains('corte')) {
      return TipoDanoArma.corte;
    }
    return TipoDanoArma.impacto;
  }

  factory AtaqueMonstro.fromJson(Map<String, dynamic> json) {
    final bruto = json['tipoDano']?.toString();
    return AtaqueMonstro(
      nome: (json['nome'] ?? 'Ataque').toString(),
      bonusAtaque: (json['bonusAtaque'] as num?)?.toInt() ?? 0,
      dano: (json['dano'] ?? '1d4').toString(),
      danoExtra: json['danoExtra']?.toString(),
      margemAmeaca: (json['margemAmeaca'] as num?)?.toInt() ?? 20,
      multiplicadorCritico: (json['multiplicadorCritico'] as num?)?.toInt() ?? 2,
      tipoDano: _parseTipoDanoArma(bruto),
      tipoDanoBruto: bruto,
      alcance: (json['alcance'] ?? 'Corpo a corpo').toString(),
      acao: (json['acao'] ?? 'padrao').toString(),
      custoPm: (json['custoPm'] as num?)?.toInt() ?? 0,
      descricaoEfeito:
          (json['efeitoAdicional'] ?? json['descricaoEfeito'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'nome': nome,
        'bonusAtaque': bonusAtaque,
        'dano': dano,
        'danoExtra': danoExtra,
        'margemAmeaca': margemAmeaca,
        'multiplicadorCritico': multiplicadorCritico,
        'tipoDano': tipoDanoBruto ?? tipoDano.name,
        'alcance': alcance,
        'acao': acao,
        'custoPm': custoPm,
        'efeitoAdicional': descricaoEfeito,
      };

  /// Converte para a representação de [Arma] do sistema para reuso no motor de combate.
  Arma toArma(String idAmeaca) {
    return Arma(
      key: '${idAmeaca}_${nome.toLowerCase().replaceAll(' ', '_')}',
      nome: nome,
      descricao: descricaoEfeito ?? 'Ataque de criatura',
      proficiencia: ProficienciaArma.simples,
      proposito: alcance.toLowerCase().contains('corpo')
          ? PropositoArma.corpoACorpo
          : PropositoArma.disparo,
      empunhadura: EmpunhaduraArma.umaMao,
      dano: dano,
      margemAmeaca: margemAmeaca,
      multiplicadorCritico: multiplicadorCritico,
      tipoDano: tipoDano,
      alcance: alcance,
    );
  }
}

/// Ficha completa de uma criatura/ameaça de Tormenta 20.
class Monstro {
  final String id;
  final String nome;
  final String nd; // Ex: "1/4", "0.5", "1", "5", "S"
  final String regiao; // Ex: "masmorras", "abissais"
  final PapelMonstro papel;
  final String tipoCriatura; // Humanoide, Monstro, Morto-vivo, Animal, Construto, Espírito
  final String? subtipo;
  final String tamanho; // Minúsculo, Pequeno, Médio, Grande, Enorme, Colossal
  final int pvMax;
  final int pmMax;
  final int defesa;
  final double deslocamentoMetros;
  final Map<String, double> deslocamentos;
  final int iniciativa;
  final int percepcao;
  final List<String> sentidos;
  final int fortitude;
  final int reflexos;
  final int vontade;
  final Map<String, int> rd;
  final List<String> imunidadesEfeitos;
  final List<String> imunidadesDano;
  final List<String> vulnerabilidadesDano;
  final List<String> habilidadesDefensivas;
  final int modForca;
  final int modDestreza;
  final int modConstituicao;
  final int? modInteligencia;
  final int? modSabedoria;
  final int? modCarisma;
  final bool forcaNula;
  final bool destrezaNula;
  final bool constituicaoNula;
  final Map<String, int> pericias;
  final List<AtaqueMonstro> ataques;
  final List<HabilidadeMonstro> habilidades;
  final List<String> equipamento;
  final String tesouro;
  final RecursoExtraivelMonstro? recursoExtraivel;
  final bool customizado;

  const Monstro({
    required this.id,
    required this.nome,
    required this.nd,
    this.regiao = '',
    this.papel = PapelMonstro.padrao,
    this.tipoCriatura = 'Monstro',
    this.subtipo,
    this.tamanho = 'Médio',
    required this.pvMax,
    this.pmMax = 0,
    required this.defesa,
    this.deslocamentoMetros = 9.0,
    this.deslocamentos = const {},
    required this.iniciativa,
    this.percepcao = 0,
    this.sentidos = const [],
    this.fortitude = 0,
    this.reflexos = 0,
    this.vontade = 0,
    this.rd = const {},
    this.imunidadesEfeitos = const [],
    this.imunidadesDano = const [],
    this.vulnerabilidadesDano = const [],
    this.habilidadesDefensivas = const [],
    this.modForca = 0,
    this.modDestreza = 0,
    this.modConstituicao = 0,
    this.modInteligencia,
    this.modSabedoria,
    this.modCarisma,
    this.forcaNula = false,
    this.destrezaNula = false,
    this.constituicaoNula = false,
    this.pericias = const {},
    this.ataques = const [],
    this.habilidades = const [],
    this.equipamento = const [],
    this.tesouro = 'padrao',
    this.recursoExtraivel,
    this.customizado = false,
  });

  /// Quantidade de quadrados ocupados em cada eixo no grid tático (T20 JdA p. 106).
  int get tamanhoQuadrados {
    switch (tamanho.toLowerCase().trim()) {
      case 'grande':
        return 2;
      case 'enorme':
        return 3;
      case 'colossal':
        return 6;
      case 'minusculo':
      case 'minúsculo':
      case 'pequeno':
      case 'medio':
      case 'médio':
      default:
        return 1;
    }
  }

  /// Valor de atributo ou `null` quando a ficha traz "–".
  int? get atributoFor => forcaNula ? null : modForca;
  int? get atributoDes => destrezaNula ? null : modDestreza;
  int? get atributoCon => constituicaoNula ? null : modConstituicao;
  int? get atributoInt => modInteligencia;
  int? get atributoSab => modSabedoria;
  int? get atributoCar => modCarisma;

  /// Verdadeiro se a ameaça possui habilidades com custo de PM ou PM > 0.
  bool get possuiPm => pmMax > 0;

  static double _extrairDeslocamentoPrincipal(Map<String, double> mapa) {
    final terrestre = mapa['terrestre'] ?? 0.0;
    if (terrestre > 0) return terrestre;
    final voo = mapa['voo'] ?? 0.0;
    if (voo > 0) return voo;
    double maior = 0.0;
    for (final v in mapa.values) {
      if (v > maior) maior = v;
    }
    return maior;
  }

  static List<String> _lerListaString(dynamic raw) {
    if (raw is! List) return const [];
    return raw.map((e) => e.toString()).toList(growable: false);
  }

  static Map<String, int> _lerMapaInt(dynamic raw) {
    if (raw is! Map) return const {};
    final out = <String, int>{};
    raw.forEach((k, v) {
      if (v is num) out[k.toString()] = v.toInt();
    });
    return out;
  }

  static Map<String, double> _lerMapaDouble(dynamic raw) {
    if (raw is! Map) return const {};
    final out = <String, double>{};
    raw.forEach((k, v) {
      if (v is num) out[k.toString()] = v.toDouble();
    });
    return out;
  }

  factory Monstro.fromJson(Map<String, dynamic> json) {
    final resistencias = (json['resistencias'] as Map<String, dynamic>?) ?? const {};
    final attrs = (json['atributos'] as Map<String, dynamic>?) ?? const {};
    final deslMap = _lerMapaDouble(json['deslocamento']);
    final deslPrincipal = deslMap.isNotEmpty
        ? _extrairDeslocamentoPrincipal(deslMap)
        : ((json['deslocamentoMetros'] as num?)?.toDouble() ?? 9.0);

    final rawFor = attrs['for'] as num?;
    final rawDes = attrs['des'] as num?;
    final rawCon = attrs['con'] as num?;
    final rawInt = attrs['int'] as num?;
    final rawSab = attrs['sab'] as num?;
    final rawCar = attrs['car'] as num?;

    final hasAttrsMap = json.containsKey('atributos');

    final ataquesRaw = json['ataques'] as List<dynamic>? ?? const [];
    final habilidadesRaw = json['habilidades'] as List<dynamic>? ?? const [];

    return Monstro(
      id: (json['id'] ?? '').toString(),
      nome: (json['nome'] ?? '').toString(),
      nd: (json['nd'] ?? '1').toString(),
      regiao: (json['regiao'] ?? '').toString(),
      papel: PapelMonstro.fromString(json['papel']?.toString()),
      tipoCriatura: (json['tipo'] ?? json['tipoCriatura'] ?? 'Monstro')
          .toString(),
      subtipo: json['subtipo']?.toString(),
      tamanho: (json['tamanho'] ?? 'Médio').toString(),
      pvMax: (json['pv'] as num?)?.toInt() ??
          (json['pvMax'] as num?)?.toInt() ??
          1,
      pmMax: (json['pm'] as num?)?.toInt() ??
          (json['pmMax'] as num?)?.toInt() ??
          0,
      defesa: (json['defesa'] as num?)?.toInt() ?? 10,
      deslocamentoMetros: deslPrincipal,
      deslocamentos: deslMap,
      iniciativa: (json['iniciativa'] as num?)?.toInt() ?? 0,
      percepcao: (json['percepcao'] as num?)?.toInt() ?? 0,
      sentidos: _lerListaString(json['sentidos']),
      fortitude: (resistencias['fortitude'] as num?)?.toInt() ??
          (json['fortitude'] as num?)?.toInt() ??
          0,
      reflexos: (resistencias['reflexos'] as num?)?.toInt() ??
          (json['reflexos'] as num?)?.toInt() ??
          0,
      vontade: (resistencias['vontade'] as num?)?.toInt() ??
          (json['vontade'] as num?)?.toInt() ??
          0,
      rd: _lerMapaInt(json['rd']),
      imunidadesEfeitos: _lerListaString(json['imunidadesEfeitos']),
      imunidadesDano: _lerListaString(json['imunidadesDano']),
      vulnerabilidadesDano: _lerListaString(json['vulnerabilidadesDano']),
      habilidadesDefensivas: _lerListaString(json['habilidadesDefensivas']),
      modForca: rawFor?.toInt() ?? (json['modForca'] as num?)?.toInt() ?? 0,
      modDestreza: rawDes?.toInt() ?? (json['modDestreza'] as num?)?.toInt() ?? 0,
      modConstituicao:
          rawCon?.toInt() ?? (json['modConstituicao'] as num?)?.toInt() ?? 0,
      modInteligencia: rawInt?.toInt(),
      modSabedoria: rawSab?.toInt(),
      modCarisma: rawCar?.toInt(),
      forcaNula: hasAttrsMap && attrs['for'] == null,
      destrezaNula: hasAttrsMap && attrs['des'] == null,
      constituicaoNula: hasAttrsMap && attrs['con'] == null,
      pericias: _lerMapaInt(json['pericias']),
      ataques: ataquesRaw
          .whereType<Map<String, dynamic>>()
          .map(AtaqueMonstro.fromJson)
          .toList(growable: false),
      habilidades: habilidadesRaw.map((item) {
        if (item is Map<String, dynamic>) {
          return HabilidadeMonstro.fromJson(item);
        }
        return HabilidadeMonstro(nome: item.toString(), descricao: item.toString());
      }).toList(growable: false),
      equipamento: _lerListaString(json['equipamento']),
      tesouro: (json['tesouro'] ?? 'padrao').toString(),
      recursoExtraivel: json['recursoExtraivel'] is Map<String, dynamic>
          ? RecursoExtraivelMonstro.fromJson(
              json['recursoExtraivel'] as Map<String, dynamic>,
            )
          : null,
      customizado: json['customizado'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'nd': nd,
        'regiao': regiao,
        'papel': papel.name,
        'tipo': tipoCriatura,
        'subtipo': subtipo,
        'tamanho': tamanho,
        'iniciativa': iniciativa,
        'percepcao': percepcao,
        'sentidos': sentidos,
        'defesa': defesa,
        'resistencias': {
          'fortitude': fortitude,
          'reflexos': reflexos,
          'vontade': vontade,
        },
        'rd': rd,
        'imunidadesEfeitos': imunidadesEfeitos,
        'imunidadesDano': imunidadesDano,
        'vulnerabilidadesDano': vulnerabilidadesDano,
        'habilidadesDefensivas': habilidadesDefensivas,
        'pv': pvMax,
        'pm': pmMax,
        'deslocamento': deslocamentos.isNotEmpty
            ? deslocamentos
            : {
                'terrestre': deslocamentoMetros,
                'voo': 0.0,
                'natacao': 0.0,
                'escalada': 0.0,
                'escavacao': 0.0,
              },
        'atributos': {
          'for': atributoFor,
          'des': atributoDes,
          'con': atributoCon,
          'int': atributoInt,
          'sab': atributoSab,
          'car': atributoCar,
        },
        'pericias': pericias,
        'ataques': ataques.map((a) => a.toJson()).toList(),
        'habilidades': habilidades.map((h) => h.toJson()).toList(),
        'equipamento': equipamento,
        'tesouro': tesouro,
        'recursoExtraivel': recursoExtraivel?.toJson(),
        if (customizado) 'customizado': true,
      };
}
