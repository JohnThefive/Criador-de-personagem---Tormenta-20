enum TipoEfeitoTemporario {
  buff,
  debuff,
  condicao,
  nota;

  String get label => switch (this) {
        TipoEfeitoTemporario.buff => 'Buff',
        TipoEfeitoTemporario.debuff => 'Debuff',
        TipoEfeitoTemporario.condicao => 'Condição',
        TipoEfeitoTemporario.nota => 'Nota',
      };

  static TipoEfeitoTemporario fromString(String? raw) {
    return switch (raw?.toLowerCase().trim()) {
      'buff' => TipoEfeitoTemporario.buff,
      'debuff' => TipoEfeitoTemporario.debuff,
      'condicao' || 'condição' => TipoEfeitoTemporario.condicao,
      _ => TipoEfeitoTemporario.nota,
    };
  }
}

class EfeitoTemporario {
  final String id;
  final String nome;
  final TipoEfeitoTemporario tipo;
  final String descricao;
  final bool ativo;
  final int modPericias;
  final int modDefesa;
  final int modRd;

  const EfeitoTemporario({
    required this.id,
    required this.nome,
    this.tipo = TipoEfeitoTemporario.nota,
    this.descricao = '',
    this.ativo = true,
    this.modPericias = 0,
    this.modDefesa = 0,
    this.modRd = 0,
  });

  bool get possuiModificadorNumerico =>
      modPericias != 0 || modDefesa != 0 || modRd != 0;

  String get resumoModificadores {
    final partes = <String>[];
    if (modPericias != 0) {
      partes.add(
        '${modPericias > 0 ? "+$modPericias" : "$modPericias"} Perícias',
      );
    }
    if (modDefesa != 0) {
      partes.add(
        '${modDefesa > 0 ? "+$modDefesa" : "$modDefesa"} Defesa',
      );
    }
    if (modRd != 0) {
      partes.add('${modRd > 0 ? "+$modRd" : "$modRd"} RD');
    }
    return partes.join(' • ');
  }

  EfeitoTemporario copyWith({
    String? id,
    String? nome,
    TipoEfeitoTemporario? tipo,
    String? descricao,
    bool? ativo,
    int? modPericias,
    int? modDefesa,
    int? modRd,
  }) {
    return EfeitoTemporario(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      tipo: tipo ?? this.tipo,
      descricao: descricao ?? this.descricao,
      ativo: ativo ?? this.ativo,
      modPericias: modPericias ?? this.modPericias,
      modDefesa: modDefesa ?? this.modDefesa,
      modRd: modRd ?? this.modRd,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'tipo': tipo.name,
      'descricao': descricao,
      'ativo': ativo,
      'modPericias': modPericias,
      'modDefesa': modDefesa,
      'modRd': modRd,
    };
  }

  factory EfeitoTemporario.fromJson(Map<String, dynamic> json) {
    return EfeitoTemporario(
      id: json['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      nome: json['nome']?.toString() ?? 'Efeito',
      tipo: TipoEfeitoTemporario.fromString(json['tipo']?.toString()),
      descricao: json['descricao']?.toString() ?? '',
      ativo: json['ativo'] as bool? ?? true,
      modPericias: (json['modPericias'] as num?)?.toInt() ?? 0,
      modDefesa: (json['modDefesa'] as num?)?.toInt() ?? 0,
      modRd: (json['modRd'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Catálogo rápido de Condições oficiais de Tormenta 20 (Edição Jogo do Ano)
class CatalogoCondicoesT20 {
  static List<EfeitoTemporario> get condicoesPadrao => const [
        EfeitoTemporario(
          id: 'cond_abalado',
          nome: 'Abalado',
          tipo: TipoEfeitoTemporario.condicao,
          descricao: '-2 em testes de perícia. Se ficar abalado de novo, fica apavorado.',
          modPericias: -2,
        ),
        EfeitoTemporario(
          id: 'cond_apavorado',
          nome: 'Apavorado',
          tipo: TipoEfeitoTemporario.condicao,
          descricao: '-5 em testes de perícia e não pode se aproximar da fonte do medo.',
          modPericias: -5,
        ),
        EfeitoTemporario(
          id: 'cond_caido',
          nome: 'Caído',
          tipo: TipoEfeitoTemporario.condicao,
          descricao: '-5 em ataques corpo a corpo; -5 Defesa contra corpo a corpo (+5 contra distância). Deslocamento 1,5m.',
          modDefesa: -5,
        ),
        EfeitoTemporario(
          id: 'cond_cego',
          nome: 'Cego',
          tipo: TipoEfeitoTemporario.condicao,
          descricao: 'Desprevenido e lento. -5 em perícias de Força ou Destreza.',
          modDefesa: -5,
        ),
        EfeitoTemporario(
          id: 'cond_desprevenido',
          nome: 'Desprevenido',
          tipo: TipoEfeitoTemporario.condicao,
          descricao: '-5 na Defesa e -5 em Reflexos. Não pode fazer reações.',
          modDefesa: -5,
        ),
        EfeitoTemporario(
          id: 'cond_enjoado',
          nome: 'Enjoado',
          tipo: TipoEfeitoTemporario.condicao,
          descricao: 'Só pode realizar uma ação padrão ou de movimento (não ambas) por rodada.',
        ),
        EfeitoTemporario(
          id: 'cond_fatigado',
          nome: 'Fatigado',
          tipo: TipoEfeitoTemporario.condicao,
          descricao: 'Fraco (-2 em perícias físicas) e vulnerável (-2 na Defesa).',
          modDefesa: -2,
          modPericias: -2,
        ),
        EfeitoTemporario(
          id: 'cond_fraco',
          nome: 'Fraco',
          tipo: TipoEfeitoTemporario.condicao,
          descricao: '-2 em testes de Força, Destreza e Constituição e perícias baseadas neles.',
        ),
        EfeitoTemporario(
          id: 'cond_lento',
          nome: 'Lento',
          tipo: TipoEfeitoTemporario.condicao,
          descricao: 'Deslocamento reduzido à metade e não pode correr ou fazer investidas.',
        ),
        EfeitoTemporario(
          id: 'cond_ofuscado',
          nome: 'Ofuscado',
          tipo: TipoEfeitoTemporario.condicao,
          descricao: '-2 em testes de ataque e de Percepção.',
        ),
        EfeitoTemporario(
          id: 'cond_sangrando',
          nome: 'Sangrando',
          tipo: TipoEfeitoTemporario.condicao,
          descricao: 'No início do turno, teste de Constituição (CD 15) ou perde 1d6 PV.',
        ),
        EfeitoTemporario(
          id: 'cond_vulneravel',
          nome: 'Vulnerável',
          tipo: TipoEfeitoTemporario.condicao,
          descricao: '-2 na Defesa.',
          modDefesa: -2,
        ),
        EfeitoTemporario(
          id: 'buff_inspiracao',
          nome: 'Inspiração (Bardo)',
          tipo: TipoEfeitoTemporario.buff,
          descricao: '+1 (ou maior) em testes de perícia pela cena.',
          modPericias: 1,
        ),
        EfeitoTemporario(
          id: 'buff_escudo_fe',
          nome: 'Escudo da Fé',
          tipo: TipoEfeitoTemporario.buff,
          descricao: '+2 na Defesa pela cena.',
          modDefesa: 2,
        ),
      ];
}
