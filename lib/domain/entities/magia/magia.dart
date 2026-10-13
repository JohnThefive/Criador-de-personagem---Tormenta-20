class ExecucaoMagia {
  final String tipo; // 'padrao', 'reacao', 'livre', etc.
  final String? detalhes;

  const ExecucaoMagia({required this.tipo, this.detalhes});

  factory ExecucaoMagia.fromJson(Map<String, dynamic> json) {
    return ExecucaoMagia(
      tipo: json['tipo'] as String,
      detalhes: json['detalhes'] as String?,
    );
  }
}

class AlcanceMagia {
  final String tipo; // 'pessoal', 'toque', 'curto', 'medio', 'лго'
  final String? detalhes;

  const AlcanceMagia({required this.tipo, this.detalhes});

  factory AlcanceMagia.fromJson(Map<String, dynamic> json) {
    return AlcanceMagia(
      tipo: json['tipo'] as String,
      detalhes: json['detalhes'] as String?,
    );
  }
}

class EfeitoMagia {
  final String tipo; // 'alvo', 'area', 'efeito'
  final String? descricao;

  const EfeitoMagia({required this.tipo, this.descricao});

  factory EfeitoMagia.fromJson(Map<String, dynamic> json) {
    return EfeitoMagia(
      tipo: json['tipo'] as String,
      descricao: json['descricao'] as String?,
    );
  }
}

class DuracaoMagia {
  final String tipo; // 'instantanea', 'cena', 'sustentada', 'dia'
  final String? detalhes;

  const DuracaoMagia({required this.tipo, this.detalhes});

  factory DuracaoMagia.fromJson(Map<String, dynamic> json) {
    return DuracaoMagia(
      tipo: json['tipo'] as String,
      detalhes: json['detalhes'] as String?,
    );
  }
}

class ResistenciaMagia {
  final String? tipoTeste; // 'Vontade', 'Reflexos', 'Fortitude'
  final String resultadoSucesso; // 'nenhuma', 'reduz_metade', 'evita'

  const ResistenciaMagia({this.tipoTeste, required this.resultadoSucesso});

  factory ResistenciaMagia.fromJson(Map<String, dynamic> json) {
    return ResistenciaMagia(
      tipoTeste: json['tipoTeste'] as String?,
      resultadoSucesso: json['resultadoSucesso'] as String? ?? 'nenhuma',
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
      id: json['id'] as String,
      descricao: json['descricao'] as String,
      custoAdicionalPM: json['custoAdicionalPM'] as int? ?? 0,
      preRequisitos: json['preRequisitos'] as String?,
      isTruque: json['isTruque'] as bool? ?? false,
    );
  }
}

class Magia {
  final String id;
  final String nome;
  final String tipo; // 'arcana' ou 'divina'
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
      id: json['id'] as String,
      nome: json['nome'] as String,
      tipo: json['tipo'] as String,
      circulo: json['circulo'] as int,
      escola: json['escola'] as String,
      execucao: ExecucaoMagia.fromJson(
        json['execucao'] as Map<String, dynamic>,
      ),
      alcance: AlcanceMagia.fromJson(json['alcance'] as Map<String, dynamic>),
      efeito: EfeitoMagia.fromJson(json['efeito'] as Map<String, dynamic>),
      duracao: DuracaoMagia.fromJson(json['duracao'] as Map<String, dynamic>),
      resistencia: json['resistencia'] != null
          ? ResistenciaMagia.fromJson(
              json['resistencia'] as Map<String, dynamic>,
            )
          : null,
      descricao: json['descricao'] as String,
      aprimoramentos:
          (json['aprimoramentos'] as List<dynamic>?)
              ?.map(
                (e) => AprimoramentoMagia.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }
}
