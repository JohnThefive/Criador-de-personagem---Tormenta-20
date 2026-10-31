enum CategoriaItemGeral {
  alquimico,
  esoterico,
  vestuario,
  alimentacao,
  ferramenta,
  aventura;

  String get label => switch (this) {
    CategoriaItemGeral.alquimico => 'Alquímico',
    CategoriaItemGeral.esoterico => 'Esotérico',
    CategoriaItemGeral.vestuario => 'Vestuário',
    CategoriaItemGeral.alimentacao => 'Alimentação',
    CategoriaItemGeral.ferramenta => 'Ferramenta',
    CategoriaItemGeral.aventura => 'Equipamento de Aventura',
  };

  static CategoriaItemGeral fromString(String val) {
    return switch (val.toLowerCase().trim()) {
      'alquimico' || 'alquímico' => CategoriaItemGeral.alquimico,
      'esoterico' || 'esotérico' => CategoriaItemGeral.esoterico,
      'vestuario' || 'vestuário' => CategoriaItemGeral.vestuario,
      'alimentacao' || 'alimentação' => CategoriaItemGeral.alimentacao,
      'ferramenta' => CategoriaItemGeral.ferramenta,
      _ => CategoriaItemGeral.aventura,
    };
  }
}

/// Representa um Item Geral de Tormenta 20 (Alquímico, Esotérico, Alimentação, Vestuário, Ferramenta, Aventura)
class ItemGeral {
  final String key;
  final String nome;
  final CategoriaItemGeral categoria;
  final String descricao;
  final int precoTibar;
  final int espacos;

  // Modificadores mecânicos opcionais (ex: Esotérico +1 CD, Vestuário +2 Perícia, +1 Defesa)
  final int bonusDefesa;
  final int bonusCDMagia;
  final int bonusDanoMagia;
  final Map<String, int> bonusPericias;

  const ItemGeral({
    required this.key,
    required this.nome,
    required this.categoria,
    required this.descricao,
    this.precoTibar = 0,
    this.espacos = 1,
    this.bonusDefesa = 0,
    this.bonusCDMagia = 0,
    this.bonusDanoMagia = 0,
    this.bonusPericias = const {},
  });

  bool get ehVestido =>
      categoria == CategoriaItemGeral.vestuario ||
      categoria == CategoriaItemGeral.esoterico ||
      bonusDefesa != 0 ||
      bonusCDMagia != 0 ||
      bonusPericias.isNotEmpty;

  String get efeitoResumo => descricao;

  int get precoTibares => precoTibar;

  factory ItemGeral.fromJson(Map<String, dynamic> json) {
    return ItemGeral(
      key: json['key']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      categoria: CategoriaItemGeral.fromString(
        json['categoria']?.toString() ?? 'aventura',
      ),
      descricao: json['descricao']?.toString() ?? '',
      precoTibar: (json['precoTibar'] as num?)?.toInt() ?? 0,
      espacos: (json['espacos'] as num?)?.toInt() ?? 1,
      bonusDefesa: (json['bonusDefesa'] as num?)?.toInt() ?? 0,
      bonusCDMagia: (json['bonusCDMagia'] as num?)?.toInt() ?? 0,
      bonusDanoMagia: (json['bonusDanoMagia'] as num?)?.toInt() ?? 0,
      bonusPericias:
          (json['bonusPericias'] as Map?)?.map(
            (k, v) => MapEntry(k.toString().toUpperCase(), (v as num).toInt()),
          ) ??
          const {},
    );
  }

  Map<String, dynamic> toJson() => {
    'key': key,
    'nome': nome,
    'categoria': categoria.name,
    'descricao': descricao,
    'precoTibar': precoTibar,
    'espacos': espacos,
    if (bonusDefesa != 0) 'bonusDefesa': bonusDefesa,
    if (bonusCDMagia != 0) 'bonusCDMagia': bonusCDMagia,
    if (bonusDanoMagia != 0) 'bonusDanoMagia': bonusDanoMagia,
    if (bonusPericias.isNotEmpty) 'bonusPericias': bonusPericias,
  };
}

/// Catálogo oficial em memória de Itens Gerais, Melhorias (Itens Superiores) e Encantos (Itens Mágicos) do Tormenta 20 JdA.
class CatalogoItensGeraisEMelhorias {
  static const List<ItemGeral> itensGerais = [
    // ESOTÉRICOS
    ItemGeral(
      key: 'VARINHA_ARCANA',
      nome: 'Varinha Arcana',
      categoria: CategoriaItemGeral.esoterico,
      descricao: 'Aumenta a CD para resistir às suas magias arcanas em +1.',
      precoTibar: 100,
      espacos: 1,
      bonusCDMagia: 1,
    ),
    ItemGeral(
      key: 'CETRO_ELEMENTAL',
      nome: 'Cetro Elemental',
      categoria: CategoriaItemGeral.esoterico,
      descricao: 'Aumenta o dano de magias do elemento escolhido em +1 dado do mesmo tipo.',
      precoTibar: 750,
      espacos: 1,
      bonusDanoMagia: 1,
    ),
    ItemGeral(
      key: 'COSTELA_DE_LICH',
      nome: 'Costela de Lich',
      categoria: CategoriaItemGeral.esoterico,
      descricao: 'Aumenta a CD de suas magias de necromancia em +1 e causa +1d6 de trevas.',
      precoTibar: 300,
      espacos: 1,
      bonusCDMagia: 1,
    ),
    ItemGeral(
      key: 'MEDALHAO_DE_PRATA',
      nome: 'Medalhão de Prata',
      categoria: CategoriaItemGeral.esoterico,
      descricao: 'Diminui em -1 PM o custo de magias de alcance pessoal.',
      precoTibar: 750,
      espacos: 1,
    ),
    ItemGeral(
      key: 'ORBE_CRISTALINO',
      nome: 'Orbe Cristalino',
      categoria: CategoriaItemGeral.esoterico,
      descricao: 'Aumenta o limite de PM que você pode gastar em magias arcanas em +1.',
      precoTibar: 750,
      espacos: 1,
    ),
    ItemGeral(
      key: 'TOMO_HERMETICO',
      nome: 'Tomo Hermético',
      categoria: CategoriaItemGeral.esoterico,
      descricao: 'Aumenta a CD para resistir a magias arcanas de uma escola específica em +2.',
      precoTibar: 1500,
      espacos: 1,
      bonusCDMagia: 2,
    ),

    // ALQUÍMICOS
    ItemGeral(
      key: 'BALSAMO_RESTAURADOR',
      nome: 'Bálsamo Restaurador',
      categoria: CategoriaItemGeral.alquimico,
      descricao: 'Pasta de ervas medicinais. Usar é uma ação padrão e recupera 2d4 PV.',
      precoTibar: 10,
      espacos: 1,
    ),
    ItemGeral(
      key: 'ESSENCIA_DE_MANA',
      nome: 'Essência de Mana',
      categoria: CategoriaItemGeral.alquimico,
      descricao: 'Poção alquímica que recupera 1d4 Pontos de Mana (PM) ao ser bebida.',
      precoTibar: 50,
      espacos: 1,
    ),
    ItemGeral(
      key: 'FOGO_ALQUIMICO',
      nome: 'Fogo Alquímico',
      categoria: CategoriaItemGeral.alquimico,
      descricao: 'Frasco arremessável (alcance curto) que causa 1d6 de dano de fogo e deixa em chamas.',
      precoTibar: 10,
      espacos: 1,
    ),
    ItemGeral(
      key: 'ACIDO',
      nome: 'Ácido (Frasco)',
      categoria: CategoriaItemGeral.alquimico,
      descricao: 'Frasco arremessável que causa 2d4 pontos de dano de ácido (Reflexos CD Des reduz à metade).',
      precoTibar: 10,
      espacos: 1,
    ),
    ItemGeral(
      key: 'BOMBA',
      nome: 'Bomba Alquímica',
      categoria: CategoriaItemGeral.alquimico,
      descricao: 'Granada rudimentar que causa 6d6 de dano de impacto em raio de 3m.',
      precoTibar: 50,
      espacos: 1,
    ),

    // ALIMENTAÇÃO
    ItemGeral(
      key: 'MACARRAO_DE_YUVALIN',
      nome: 'Macarrão de Yuvalin',
      categoria: CategoriaItemGeral.alimentacao,
      descricao: 'Prato quente que concede +5 PV temporários no próximo descanso.',
      precoTibar: 6,
      espacos: 1,
    ),
    ItemGeral(
      key: 'PRATO_DO_AVENTUREIRO',
      nome: 'Prato do Aventureiro',
      categoria: CategoriaItemGeral.alimentacao,
      descricao: 'Aumenta a recuperação de PV em +1 por nível no próximo descanso.',
      precoTibar: 1,
      espacos: 1,
    ),
    ItemGeral(
      key: 'SOPA_DE_PEIXE',
      nome: 'Sopa de Peixe',
      categoria: CategoriaItemGeral.alimentacao,
      descricao: 'Aumenta a recuperação de PM em +1 por nível no próximo descanso.',
      precoTibar: 1,
      espacos: 1,
    ),
    ItemGeral(
      key: 'RACAO_DE_VIAGEM',
      nome: 'Ração de Viagem (por dia)',
      categoria: CategoriaItemGeral.alimentacao,
      descricao: 'Alimentos conservados suficientes para alimentar uma pessoa por um dia.',
      precoTibar: 1,
      espacos: 1,
    ),

    // VESTUÁRIO
    ItemGeral(
      key: 'BOTAS_REFORCADAS',
      nome: 'Botas Reforçadas',
      categoria: CategoriaItemGeral.vestuario,
      descricao: 'Aumenta seu deslocamento em +1,5m para atravessar terreno difícil.',
      precoTibar: 20,
      espacos: 1,
    ),
    ItemGeral(
      key: 'CAPA_ESVOACANTE',
      nome: 'Capa Esvoaçante',
      categoria: CategoriaItemGeral.vestuario,
      descricao: 'Fornece +1 em Enganação.',
      precoTibar: 25,
      espacos: 1,
      bonusPericias: {'ENGANACAO': 1},
    ),
    ItemGeral(
      key: 'CAPA_PESADA',
      nome: 'Capa Pesada',
      categoria: CategoriaItemGeral.vestuario,
      descricao: 'Protege contra intempéries e fornece +1 em Fortitude.',
      precoTibar: 15,
      espacos: 1,
      bonusPericias: {'FORTITUDE': 1},
    ),
    ItemGeral(
      key: 'LUVAS_DE_PELICA',
      nome: 'Luvas de Pelica',
      categoria: CategoriaItemGeral.vestuario,
      descricao: 'Finas e sensíveis, fornecem +1 em Ladinagem.',
      precoTibar: 5,
      espacos: 1,
      bonusPericias: {'LADINAGEM': 1},
    ),
    ItemGeral(
      key: 'MANTO_CAMUFLADO',
      nome: 'Manto Camuflado',
      categoria: CategoriaItemGeral.vestuario,
      descricao: 'Fornece +2 em Furtividade no terreno correspondente.',
      precoTibar: 12,
      espacos: 1,
      bonusPericias: {'FURTIVIDADE': 2},
    ),
    ItemGeral(
      key: 'TABARDO',
      nome: 'Tabardo',
      categoria: CategoriaItemGeral.vestuario,
      descricao: 'Peça de tecido com brasão que fornece +1 em Diplomacia.',
      precoTibar: 10,
      espacos: 1,
      bonusPericias: {'DIPLOMACIA': 1},
    ),
    ItemGeral(
      key: 'TRAJE_DA_CORTE',
      nome: 'Traje da Corte',
      categoria: CategoriaItemGeral.vestuario,
      descricao: 'Roupas luxuosas necessárias para ambientes nobres (+2 em Diplomacia/Nobreza na corte).',
      precoTibar: 100,
      espacos: 1,
      bonusPericias: {'DIPLOMACIA': 2},
    ),

    // FERRAMENTAS E AVENTURA
    ItemGeral(
      key: 'GAZUA',
      nome: 'Gazua',
      categoria: CategoriaItemGeral.ferramenta,
      descricao: 'Ferramenta para Ladinagem (abrir fechaduras sem penalidade de -5).',
      precoTibar: 5,
      espacos: 1,
    ),
    ItemGeral(
      key: 'MALETA_DE_MEDICAMENTOS',
      nome: 'Maleta de Medicamentos',
      categoria: CategoriaItemGeral.ferramenta,
      descricao: 'Necessária para usar a perícia Cura sem penalidade de -5.',
      precoTibar: 50,
      espacos: 1,
    ),
    ItemGeral(
      key: 'SIMBOLO_SAGRADO',
      nome: 'Símbolo Sagrado',
      categoria: CategoriaItemGeral.ferramenta,
      descricao: 'Medalhão ou relíquia de sua divindade. Quando vestido/empunhado, fornece +1 em testes de resistência.',
      precoTibar: 5,
      espacos: 1,
      bonusPericias: {'FORTITUDE': 1, 'REFLEXOS': 1, 'VONTADE': 1},
    ),
  ];

  // MELHORIAS DE ARMAS (ITENS SUPERIORES)
  static const Map<String, String> melhoriasArma = {
    'CERTEIRA': 'Certeira (+1 no teste de ataque)',
    'CRUEL': 'Cruel (+1 nas rolagens de dano)',
    'ATROZ': 'Atroz (+2 nas rolagens de dano; requer Cruel)',
    'PUNGENTE': 'Pungente (+2 no teste de ataque; requer Certeira)',
    'MACICA': 'Maciça (+1 no multiplicador de crítico)',
    'PRECISA': 'Precisa (+1 na margem de ameaça)',
    'EQUILIBRADA': 'Equilibrada (+2 em testes de manobras de combate)',
    'HARMONIZADA': 'Harmonizada (-1 PM em uma habilidade de ataque ativada com a arma)',
    'INJECAO_ALQUIMICA': 'Injeção Alquímica (armazena 2 doses alquímicas para disparo no impacto)',
    'MATERIAL_ACO_RUBI': 'Material Especial: Aço-Rubi (ignora 10 de RD e chance de falha)',
    'MATERIAL_ADAMANTE': 'Material Especial: Adamante (aumenta o dano da arma em um passo)',
    'MATERIAL_GELO_ETERNO': 'Material Especial: Gelo Eterno (+2 pontos de dano de frio)',
    'MATERIAL_MADEIRA_TOLLON': 'Material Especial: Madeira Tollon (conta como mágica e -1 PM em habilidades)',
    'MATERIAL_MITRAL': 'Material Especial: Mitral (+1 na margem de ameaça e pesa -1 espaço)',
  };

  // ENCANTOS DE ARMAS (ITENS MÁGICOS)
  static const Map<String, String> encantosArma = {
    'FORMIDAVEL': 'Formidável (+2 em ataque e dano)',
    'MAGNIFICA': 'Magnífica (+4 em ataque e dano; requer Formidável)',
    'AMEACADORA': 'Ameaçadora (duplica a margem de ameaça da arma)',
    'LANCINANTE': 'Lancinante (multiplica também os bônus numéricos no crítico)',
    'FLAMEJANTE': 'Flamejante (+1d6 de dano de fogo)',
    'CONGELANTE': 'Congelante (+1d6 de dano de frio)',
    'ELETRICA': 'Elétrica (+1d6 de dano de eletricidade)',
    'CORROSIVA': 'Corrosiva (+1d6 de dano de ácido)',
    'SAGRADA': 'Sagrada (+1d6 de luz; +2d6 contra mortos-vivos/abissais)',
    'PROFANA': 'Profana (+1d6 de trevas; +2d6 contra devotos do bem)',
    'VELOZ': 'Veloz (permite gastar 2 PM para um ataque extra)',
    'DEFENSORA': 'Defensora (+2 na Defesa enquanto empunhada)',
  };

  // MELHORIAS DE PROTEÇÕES (ARMADURAS E ESCUDOS SUPERIORES)
  static const Map<String, String> melhoriasProtecao = {
    'REFORCADA': 'Reforçada (+1 na Defesa e +1 na penalidade de armadura)',
    'AJUSTADA': 'Ajustada (diminui a penalidade de armadura em 1)',
    'SOB_MEDIDA': 'Sob Medida (diminui a penalidade de armadura em 2; requer Ajustada)',
    'DELICADA': 'Delicada (permite aplicar +1 da Destreza na Defesa em armaduras pesadas)',
    'SELADA': 'Selada (+1 em todos os testes de resistência)',
    'MATERIAL_ADAMANTE': 'Material Especial: Adamante (concede RD 2 em leve/escudo ou RD 5 em pesada)',
    'MATERIAL_COURACA_KAIJU': 'Material Especial: Couraça de Kaiju (RD 5 e gasto de PM para somar CON na Defesa)',
    'MATERIAL_MITRAL': 'Material Especial: Mitral (penalidade -2 menor e -1 espaço)',
  };

  // ENCANTOS DE PROTEÇÕES (ARMADURAS E ESCUDOS MÁGICOS)
  static const Map<String, String> encantosProtecao = {
    'DEFENSORA': 'Defensora (+2 na Defesa)',
    'GUARDIA': 'Guardiã (+4 na Defesa; requer Defensora)',
    'ABENCOADA': 'Abençoada (Resistência a trevas 10 e +5 contra mortos-vivos)',
    'FORTIFICADA': 'Fortificada (50% de chance de ignorar dano extra de crítico/furtivo)',
    'INVULNERAVEL': 'Invulnerável (RD 5 para leve/escudo ou RD 10 para pesada)',
    'REFLETORA': 'Refletora (gasta PM para refletir magia de volta ao conjurador)',
  };

  static Map<String, String> get melhoriasArmasDisponiveis => melhoriasArma;
  static Map<String, String> get encantosArmasDisponiveis => encantosArma;
  static Map<String, String> get melhoriasProtecoesDisponiveis =>
      melhoriasProtecao;
  static Map<String, String> get encantosProtecoesDisponiveis =>
      encantosProtecao;

  static List<ItemGeral> itensPorCategoria(CategoriaItemGeral categoria) {
    return itensGerais.where((i) => i.categoria == categoria).toList();
  }
}
