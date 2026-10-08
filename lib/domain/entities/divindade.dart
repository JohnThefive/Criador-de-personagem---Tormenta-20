import 'poder.dart';

/// Opções de canalização de energia permitidas pela divindade.
enum CanalizacaoOpcao {
  apenasPositiva,
  apenasNegativa,
  qualquer,
}

/// Tipo de energia que pode ser canalizada pelo devoto.
enum TipoEnergia {
  positiva,
  negativa,
  qualquer,
}

/// Entidade imutável que representa uma divindade do Panteão de Tormenta 20.
class Divindade {
  final String id;
  final String nome;
  final String titulo; // Ex: "O Deus da Justiça", "A Deusa da Ambição"
  final String crencasObjetivos;
  final String simboloSagrado;
  final CanalizacaoOpcao canalizacaoPermitida;
  final String armaPreferidaId;
  final List<String> obrigacoesERestricoes;
  final List<String> classesPermitidas; // Vazio = todas; ou IDs de classes com restrição específica
  final List<String> poderesConcedidosIds;
  final List<Poder> poderesConcedidos;

  const Divindade({
    required this.id,
    required this.nome,
    required this.titulo,
    required this.crencasObjetivos,
    required this.simboloSagrado,
    required this.canalizacaoPermitida,
    required this.armaPreferidaId,
    this.obrigacoesERestricoes = const [],
    this.classesPermitidas = const [],
    this.poderesConcedidosIds = const [],
    this.poderesConcedidos = const [],
  });

  // Getters para compatibilidade reversa com códigos anteriores
  String get descricao => crencasObjetivos;
  String get armaPreferida => armaPreferidaId;
  String get textoObrigacoesERestricoes => obrigacoesERestricoes.join('\n\n');

  TipoEnergia get energiaCanalizada {
    switch (canalizacaoPermitida) {
      case CanalizacaoOpcao.apenasPositiva:
        return TipoEnergia.positiva;
      case CanalizacaoOpcao.apenasNegativa:
        return TipoEnergia.negativa;
      case CanalizacaoOpcao.qualquer:
        return TipoEnergia.qualquer;
    }
  }

  factory Divindade.fromJson(Map<String, dynamic> json) {
    CanalizacaoOpcao parseCanalizacao(dynamic valor) {
      final str = valor?.toString().trim().toLowerCase() ?? '';
      if (str == 'apenasnegativa' || str == 'negativa') {
        return CanalizacaoOpcao.apenasNegativa;
      }
      if (str == 'qualquer') {
        return CanalizacaoOpcao.qualquer;
      }
      return CanalizacaoOpcao.apenasPositiva;
    }

    final poderesList = (json['poderesConcedidos'] as List<dynamic>? ?? [])
        .map((p) => Poder.fromJson(Map<String, dynamic>.from(p as Map)))
        .toList();

    final List<String> poderesIds = List<String>.from(json['poderesConcedidosIds'] ?? const []);
    if (poderesIds.isEmpty && poderesList.isNotEmpty) {
      poderesIds.addAll(poderesList.map((p) => p.key));
    }

    return Divindade(
      id: json['id']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      titulo: json['titulo']?.toString() ?? '',
      crencasObjetivos: (json['crencasObjetivos'] ?? json['descricao'])?.toString() ?? '',
      simboloSagrado: json['simboloSagrado']?.toString() ?? '',
      canalizacaoPermitida: parseCanalizacao(json['canalizacaoPermitida']),
      armaPreferidaId: (json['armaPreferidaId'] ?? json['armaPreferida'])?.toString() ?? '',
      obrigacoesERestricoes: List<String>.from(json['obrigacoesERestricoes'] ?? const []),
      classesPermitidas: List<String>.from(json['classesPermitidas'] ?? const []),
      poderesConcedidosIds: poderesIds,
      poderesConcedidos: poderesList,
    );
  }

  Map<String, dynamic> toJson() {
    String canalizacaoString() {
      switch (canalizacaoPermitida) {
        case CanalizacaoOpcao.apenasPositiva:
          return 'apenasPositiva';
        case CanalizacaoOpcao.apenasNegativa:
          return 'apenasNegativa';
        case CanalizacaoOpcao.qualquer:
          return 'qualquer';
      }
    }

    return {
      'id': id,
      'nome': nome,
      'titulo': titulo,
      'crencasObjetivos': crencasObjetivos,
      'simboloSagrado': simboloSagrado,
      'canalizacaoPermitida': canalizacaoString(),
      'armaPreferidaId': armaPreferidaId,
      'obrigacoesERestricoes': obrigacoesERestricoes,
      'classesPermitidas': classesPermitidas,
      'poderesConcedidosIds': poderesConcedidosIds,
      'poderesConcedidos': poderesConcedidos.map((p) => {
        'key': p.key,
        'nome': p.nome,
        'descricao': p.descricao,
      }).toList(),
    };
  }

  Divindade copyWith({
    String? id,
    String? nome,
    String? titulo,
    String? crencasObjetivos,
    String? simboloSagrado,
    CanalizacaoOpcao? canalizacaoPermitida,
    String? armaPreferidaId,
    List<String>? obrigacoesERestricoes,
    List<String>? classesPermitidas,
    List<String>? poderesConcedidosIds,
    List<Poder>? poderesConcedidos,
  }) {
    return Divindade(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      titulo: titulo ?? this.titulo,
      crencasObjetivos: crencasObjetivos ?? this.crencasObjetivos,
      simboloSagrado: simboloSagrado ?? this.simboloSagrado,
      canalizacaoPermitida: canalizacaoPermitida ?? this.canalizacaoPermitida,
      armaPreferidaId: armaPreferidaId ?? this.armaPreferidaId,
      obrigacoesERestricoes: obrigacoesERestricoes ?? this.obrigacoesERestricoes,
      classesPermitidas: classesPermitidas ?? this.classesPermitidas,
      poderesConcedidosIds: poderesConcedidosIds ?? this.poderesConcedidosIds,
      poderesConcedidos: poderesConcedidos ?? this.poderesConcedidos,
    );
  }
}
