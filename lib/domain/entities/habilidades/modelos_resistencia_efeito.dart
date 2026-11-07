import 'package:t20_creator/domain/entities/testes/modelos_teste_t20.dart';

/// R50: Tipos oficiais de Testes de Resistência do Tormenta 20.
enum TipoResistencia {
  fortitude,
  reflexos,
  vontade,
}

/// R53: Tipos de resultado possíveis para um teste de resistência.
enum TipoResultadoResistencia {
  anula,
  parcial,
  metade,
  desacredita,
  falha,
}

/// R57: Tipos e descritores fundamentais de efeitos, magias e habilidades.
enum TipoEfeito {
  arcano,
  atordoamento,
  cansaco,
  climatico,
  cura,
  dano,
  divino,
  luz,
  magico,
  medo,
  mental,
  metabolismo,
  metamorfose,
  movimento,
  perdaDeVida,
  sentidos,
  trevas,
  veneno,
}

/// R57: Tipos de criatura para apuração de imunidades inatas do T20.
enum TipoCriatura {
  humanoide,
  animal,
  monstro,
  construto,
  mortoVivo,
  espirito,
  outro,
}

/// Bônus nas três resistências básicas do T20 (Fortitude, Reflexos, Vontade).
class BonusResistencia {
  final int fortitude;
  final int reflexos;
  final int vontade;

  const BonusResistencia({
    this.fortitude = 0,
    this.reflexos = 0,
    this.vontade = 0,
  });

  int paraTipo(TipoResistencia tipo) => switch (tipo) {
        TipoResistencia.fortitude => fortitude,
        TipoResistencia.reflexos => reflexos,
        TipoResistencia.vontade => vontade,
      };

  BonusResistencia copyWith({
    int? fortitude,
    int? reflexos,
    int? vontade,
  }) {
    return BonusResistencia(
      fortitude: fortitude ?? this.fortitude,
      reflexos: reflexos ?? this.reflexos,
      vontade: vontade ?? this.vontade,
    );
  }

  Map<String, dynamic> toJson() => {
        'fortitude': fortitude,
        'reflexos': reflexos,
        'vontade': vontade,
      };

  factory BonusResistencia.fromJson(Map<String, dynamic> json) {
    return BonusResistencia(
      fortitude: json['fortitude'] as int? ?? 0,
      reflexos: json['reflexos'] as int? ?? 0,
      vontade: json['vontade'] as int? ?? 0,
    );
  }
}

/// R57: Modelo de Criatura para checagem de imunidades e resistências.
class Criatura {
  final String id;
  final String nome;
  final TipoCriatura tipoCriatura;
  final int? inteligencia; // null = inteligência nula (R57)
  final Set<TipoEfeito> imunidades;
  final BonusResistencia bonusResistencia;

  const Criatura({
    required this.id,
    required this.nome,
    this.tipoCriatura = TipoCriatura.humanoide,
    this.inteligencia = 10,
    this.imunidades = const {},
    this.bonusResistencia = const BonusResistencia(),
  });

  bool get temInteligenciaNula => inteligencia == null;

  Criatura copyWith({
    String? id,
    String? nome,
    TipoCriatura? tipoCriatura,
    int? inteligencia,
    bool anularInteligencia = false,
    Set<TipoEfeito>? imunidades,
    BonusResistencia? bonusResistencia,
  }) {
    return Criatura(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      tipoCriatura: tipoCriatura ?? this.tipoCriatura,
      inteligencia:
          anularInteligencia ? null : (inteligencia ?? this.inteligencia),
      imunidades: imunidades ?? this.imunidades,
      bonusResistencia: bonusResistencia ?? this.bonusResistencia,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'tipoCriatura': tipoCriatura.name,
        'inteligencia': inteligencia,
        'imunidades': imunidades.map((e) => e.name).toList(),
        'bonusResistencia': bonusResistencia.toJson(),
      };

  factory Criatura.fromJson(Map<String, dynamic> json) {
    return Criatura(
      id: json['id'] as String,
      nome: json['nome'] as String? ?? '',
      tipoCriatura: TipoCriatura.values.firstWhere(
        (e) => e.name == json['tipoCriatura'],
        orElse: () => TipoCriatura.humanoide,
      ),
      inteligencia: json['inteligencia'] as int?,
      imunidades: (json['imunidades'] as List<dynamic>? ?? [])
          .map((e) => TipoEfeito.values.firstWhere(
                (t) => t.name == e,
                orElse: () => TipoEfeito.dano,
              ))
          .toSet(),
      bonusResistencia: json['bonusResistencia'] != null
          ? BonusResistencia.fromJson(
              json['bonusResistencia'] as Map<String, dynamic>)
          : const BonusResistencia(),
    );
  }
}

/// R56: Modelo de Item/Objeto no mapa ou inventário para regras de dano e resistência.
class ItemObjeto {
  final String id;
  final String nome;
  final bool magico;
  final String? carregadoPor; // null = objeto solto; preenchido = carregado
  final int bonusResistencia; // padrão 0
  final int pvAtual;
  final int pvMax;

  const ItemObjeto({
    required this.id,
    required this.nome,
    this.magico = false,
    this.carregadoPor,
    this.bonusResistencia = 0,
    this.pvAtual = 10,
    this.pvMax = 10,
  });

  bool get estaCarregado => carregadoPor != null && carregadoPor!.isNotEmpty;
  bool get estaSolto => !estaCarregado;

  ItemObjeto copyWith({
    String? id,
    String? nome,
    bool? magico,
    String? carregadoPor,
    int? bonusResistencia,
    int? pvAtual,
    int? pvMax,
  }) {
    return ItemObjeto(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      magico: magico ?? this.magico,
      carregadoPor: carregadoPor ?? this.carregadoPor,
      bonusResistencia: bonusResistencia ?? this.bonusResistencia,
      pvAtual: pvAtual ?? this.pvAtual,
      pvMax: pvMax ?? this.pvMax,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'magico': magico,
        'carregadoPor': carregadoPor,
        'bonusResistencia': bonusResistencia,
        'pvAtual': pvAtual,
        'pvMax': pvMax,
      };

  factory ItemObjeto.fromJson(Map<String, dynamic> json) {
    return ItemObjeto(
      id: json['id'] as String,
      nome: json['nome'] as String? ?? 'Item',
      magico: json['magico'] as bool? ?? false,
      carregadoPor: json['carregadoPor'] as String?,
      bonusResistencia: json['bonusResistencia'] as int? ?? 0,
      pvAtual: json['pvAtual'] as int? ?? 10,
      pvMax: json['pvMax'] as int? ?? 10,
    );
  }
}

/// R50 e R53: Configuração de teste de resistência de uma habilidade.
class HabilidadeResistencia {
  final TipoResistencia tipo;
  final TipoResultadoResistencia resultado;

  const HabilidadeResistencia({
    required this.tipo,
    this.resultado = TipoResultadoResistencia.anula,
  });

  Map<String, dynamic> toJson() => {
        'tipo': tipo.name,
        'resultado': resultado.name,
      };

  factory HabilidadeResistencia.fromJson(Map<String, dynamic> json) {
    return HabilidadeResistencia(
      tipo: TipoResistencia.values.firstWhere(
        (e) => e.name == json['tipo'],
        orElse: () => TipoResistencia.fortitude,
      ),
      resultado: TipoResultadoResistencia.values.firstWhere(
        (e) => e.name == json['resultado'],
        orElse: () => TipoResultadoResistencia.anula,
      ),
    );
  }
}

/// R54: Teste opcional ou alternativo de perícia para resistir ao efeito.
class ResistePericia {
  final String pericia;
  final int? cd; // Se null, usa a CD calculada da resistência da habilidade

  const ResistePericia({
    required this.pericia,
    this.cd,
  });

  Map<String, dynamic> toJson() => {
        'pericia': pericia,
        'cd': cd,
      };

  factory ResistePericia.fromJson(Map<String, dynamic> json) {
    return ResistePericia(
      pericia: json['pericia'] as String,
      cd: json['cd'] as int?,
    );
  }
}

/// R53: Detalhes do efeito aplicado quando o resultado da resistência for PARCIAL.
class HabilidadeEfeitoParcial {
  final String? descricao;
  final int? danoPvParcial;
  final int? curaPvParcial;
  final List<ModificadorAplicado> modificadoresParciais;

  const HabilidadeEfeitoParcial({
    this.descricao,
    this.danoPvParcial,
    this.curaPvParcial,
    this.modificadoresParciais = const [],
  });

  Map<String, dynamic> toJson() => {
        'descricao': descricao,
        'danoPvParcial': danoPvParcial,
        'curaPvParcial': curaPvParcial,
        'modificadoresParciais':
            modificadoresParciais.map((m) => m.toJson()).toList(),
      };

  factory HabilidadeEfeitoParcial.fromJson(Map<String, dynamic> json) {
    return HabilidadeEfeitoParcial(
      descricao: json['descricao'] as String?,
      danoPvParcial: json['danoPvParcial'] as int?,
      curaPvParcial: json['curaPvParcial'] as int?,
      modificadoresParciais:
          (json['modificadoresParciais'] as List<dynamic>? ?? [])
              .map((e) => ModificadorAplicado.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }
}

/// R52 e R53: Resultado completo da resolução de um teste de resistência.
class ResultadoResistencia {
  final String alvoId;
  final TipoResistencia? tipo;
  final String? pericia;
  final int cd;
  final int? d20;
  final int total;
  final bool sucesso;
  final TipoResultadoResistencia resultadoAplicado;
  final bool falhaAutomatica;
  final bool sucessoAutomatico;
  final String log;

  const ResultadoResistencia({
    required this.alvoId,
    this.tipo,
    this.pericia,
    required this.cd,
    this.d20,
    required this.total,
    required this.sucesso,
    required this.resultadoAplicado,
    this.falhaAutomatica = false,
    this.sucessoAutomatico = false,
    this.log = '',
  });

  Map<String, dynamic> toJson() => {
        'alvoId': alvoId,
        'tipo': tipo?.name,
        'pericia': pericia,
        'cd': cd,
        'd20': d20,
        'total': total,
        'sucesso': sucesso,
        'resultadoAplicado': resultadoAplicado.name,
        'falhaAutomatica': falhaAutomatica,
        'sucessoAutomatico': sucessoAutomatico,
        'log': log,
      };

  factory ResultadoResistencia.fromJson(Map<String, dynamic> json) {
    return ResultadoResistencia(
      alvoId: json['alvoId'] as String,
      tipo: json['tipo'] != null
          ? TipoResistencia.values.firstWhere((e) => e.name == json['tipo'])
          : null,
      pericia: json['pericia'] as String?,
      cd: json['cd'] as int,
      d20: json['d20'] as int?,
      total: json['total'] as int,
      sucesso: json['sucesso'] as bool,
      resultadoAplicado: TipoResultadoResistencia.values.firstWhere(
        (e) => e.name == json['resultadoAplicado'],
        orElse: () => TipoResultadoResistencia.anula,
      ),
      falhaAutomatica: json['falhaAutomatica'] as bool? ?? false,
      sucessoAutomatico: json['sucessoAutomatico'] as bool? ?? false,
      log: json['log'] as String? ?? '',
    );
  }
}
