class ExecucaoMagia {
  final String tipo; // 'padrao', 'reacao', 'livre', etc.
  final String? detalhes;

  const ExecucaoMagia({required this.tipo, this.detalhes});

  factory ExecucaoMagia.fromJson(Map<String, dynamic> json) {
    return ExecucaoMagia(
      tipo: json['tipo']?.toString() ?? 'padrao',
      detalhes: json['detalhes']?.toString(),
    );
  }
}

class AlcanceMagia {
  final String tipo; // 'pessoal', 'toque', 'curto', 'medio', 'longo'
  final String? detalhes;

  const AlcanceMagia({required this.tipo, this.detalhes});

  factory AlcanceMagia.fromJson(Map<String, dynamic> json) {
    return AlcanceMagia(
      tipo: json['tipo']?.toString() ?? 'pessoal',
      detalhes: json['detalhes']?.toString(),
    );
  }
}

class EfeitoMagia {
  final String tipo; // 'alvo', 'area', 'efeito'
  final String? descricao;

  const EfeitoMagia({required this.tipo, this.descricao});

  factory EfeitoMagia.fromJson(Map<String, dynamic> json) {
    return EfeitoMagia(
      tipo: json['tipo']?.toString() ?? 'alvo',
      descricao: json['descricao']?.toString(),
    );
  }
}

class DuracaoMagia {
  final String tipo; // 'instantanea', 'cena', 'sustentada', 'dia'
  final String? detalhes;

  const DuracaoMagia({required this.tipo, this.detalhes});

  factory DuracaoMagia.fromJson(Map<String, dynamic> json) {
    return DuracaoMagia(
      tipo: json['tipo']?.toString() ?? 'instantanea',
      detalhes: json['detalhes']?.toString(),
    );
  }
}

class ResistenciaMagia {
  final String? tipoTeste; // 'Vontade', 'Reflexos', 'Fortitude'
  final String resultadoSucesso; // 'nenhuma', 'reduz_metade', 'evita'

  const ResistenciaMagia({this.tipoTeste, required this.resultadoSucesso});

  factory ResistenciaMagia.fromJson(Map<String, dynamic> json) {
    return ResistenciaMagia(
      tipoTeste: json['tipoTeste']?.toString(),
      resultadoSucesso: json['resultadoSucesso']?.toString() ?? 'nenhuma',
    );
  }
}

class AprimoramentoMagia {
  final String id;
  final String descricao;
  final int custoAdicionalPM;
  final String? preRequisitos;
  final bool isTruque;

  const AprimoramentoMagia({
    required this.id,
    required this.descricao,
    required this.custoAdicionalPM,
    this.preRequisitos,
    this.isTruque = false,
  });

  factory AprimoramentoMagia.fromJson(Map<String, dynamic> json) {
    return AprimoramentoMagia(
      id: json['id']?.toString() ?? '',
      descricao: json['descricao']?.toString() ?? '',
      custoAdicionalPM: (json['custoAdicionalPM'] as num?)?.toInt() ?? 0,
      preRequisitos: json['preRequisitos']?.toString(),
      isTruque: json['isTruque'] as bool? ?? false,
    );
  }
}

class Magia {
  final String id;
  final String nome;
  final String tipo; // 'arcana', 'divina' ou 'universal'
  final int circulo; // 1 a 5
  final String escola; // ex: 'abjuracao', 'evocacao'
  final ExecucaoMagia execucao;
  final AlcanceMagia alcance;
  final EfeitoMagia efeito;
  final DuracaoMagia duracao;
  final ResistenciaMagia? resistencia;
  final String descricao;
  final List<AprimoramentoMagia> aprimoramentos;

  const Magia({
    required this.id,
    required this.nome,
    required this.tipo,
    required this.circulo,
    required this.escola,
    required this.execucao,
    required this.alcance,
    required this.efeito,
    required this.duracao,
    this.resistencia,
    required this.descricao,
    required this.aprimoramentos,
  });

  factory Magia.fromJson(Map<String, dynamic> json) {
    return Magia(
      id: json['id']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      tipo: json['tipo']?.toString() ?? 'arcana',
      circulo: (json['circulo'] as num?)?.toInt() ?? 1,
      escola: json['escola']?.toString() ?? 'universal',
      execucao: json['execucao'] is Map<String, dynamic>
          ? ExecucaoMagia.fromJson(json['execucao'] as Map<String, dynamic>)
          : const ExecucaoMagia(tipo: 'padrao'),
      alcance: json['alcance'] is Map<String, dynamic>
          ? AlcanceMagia.fromJson(json['alcance'] as Map<String, dynamic>)
          : const AlcanceMagia(tipo: 'pessoal'),
      efeito: json['efeito'] is Map<String, dynamic>
          ? EfeitoMagia.fromJson(json['efeito'] as Map<String, dynamic>)
          : const EfeitoMagia(tipo: 'alvo'),
      duracao: json['duracao'] is Map<String, dynamic>
          ? DuracaoMagia.fromJson(json['duracao'] as Map<String, dynamic>)
          : const DuracaoMagia(tipo: 'instantanea'),
      resistencia: json['resistencia'] is Map<String, dynamic>
          ? ResistenciaMagia.fromJson(
              json['resistencia'] as Map<String, dynamic>,
            )
          : null,
      descricao: json['descricao']?.toString() ?? '',
      aprimoramentos:
          (json['aprimoramentos'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(AprimoramentoMagia.fromJson)
              .toList() ??
          [],
    );
  }
}
