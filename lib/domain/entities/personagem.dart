import 'package:t20_creator/domain/entities/poder.dart';
import 'arma.dart';
import 'protecao.dart';
import 'proficiencias.dart';
import 'forma_selvagem.dart';
import 'golpe_pessoal.dart';
import 'engenhoca.dart';
import 'montaria_sagrada.dart';
import '../services/data_services/call_montaria_sagrada.dart';
import '../services/regras_carga_service.dart';

import 'atributos.dart';
import 'raca.dart';
import 'classe_do_personagem.dart';
import 'origem.dart';
import 'divindade.dart';

// imports pras pericias
import '../services/banco_pericias.dart';

class Personagem {
  final String nome;
  final Map<String, Atributo> atributos; // Atributos BASE (Rolados/Comprados)
  final Raca? raca;
  final List<ClasseDoPersonagem> classes; // Índice [0] é a classe inicial
  final List<String> periciasTreinadas;

  // Campos referentes a origem e equipamento
  final Origem? origem;
  final List<Poder> poderesGerais; // Armazena poderes de origem / gerais
  final List<String> itensInventario; // Recebe os itens gratuitos da origem
  final List<Arma> armas; // Armas equipadas/carregadas
  final Protecao? armaduraEquipada; // Armadura equipada
  final Protecao? escudoEquipado; // Escudo equipado
  final int tibares; // Dinheiro em T$ (Tibar)

  // Golpes Pessoais (customizados para Guerreiro)
  final List<GolpePessoal> golpesPessoais;

  // Engenhocas (customizadas para Inventor)
  final List<Engenhoca> engenhocas;

  // Campos específicos de poderes de Druida
  final FormaSelvagemAtiva? formaSelvagemAtiva;
  final String? tipoCompanheiroAnimal; // Ex: "GUARDIAO", "FORTAO", "AJUDANTE"

  // Montaria Sagrada (Paladino)
  final MontariaSagrada? montariaSagrada;

  // Campos referentes a divindade
  final Divindade? divindade;
  final Poder? poderConcedido;

  // Finalização e personalização do personagem
  final String id; // Identificador único
  final int idade;
  final String alinhamento; // Ex: "Caótico e Bom", "Leal e Neutro"
  final String
  descricaoAparencia; // Breve biografia/descrição escrita pelo jogador
  final String? caminhoFoto; // Caminho local da imagem escolhida no celular
  final String tamanho; // Padrão: "Médio"
  final String peso; // Ex: "70 kg"
  final String altura; // Ex: "1.70 m"

  // Estado dinâmico de jogo / sessão
  final int? _pvAtual;
  final int? _pmAtual;
  final int experienciaAtual;

  int get pvAtual => _pvAtual ?? pvTotal;
  int get pmAtual => _pmAtual ?? pmTotal;

  Personagem({
    required this.nome,
    required this.atributos,
    this.raca,
    this.classes = const [],
    this.periciasTreinadas = const [],
    // Campos referentes a origem e equipamento
    this.origem,
    this.poderesGerais = const [],
    this.itensInventario = const [],
    this.armas = const [],
    this.armaduraEquipada,
    this.escudoEquipado,
    this.tibares = 0,
    // Golpes Pessoais (customizados para Guerreiro)
    this.golpesPessoais = const [],
    // Engenhocas (customizadas para Inventor)
    this.engenhocas = const [],
    // Campos específicos de poderes de Druida
    this.formaSelvagemAtiva,
    this.tipoCompanheiroAnimal,
    // Montaria Sagrada (Paladino)
    this.montariaSagrada,
    // Campos referentes a divindade
    this.divindade,
    this.poderConcedido,
    // Campos de personalização (com fallback para id se vier nulo)
    String? id,
    this.idade = 20,
    this.alinhamento = 'Neutro',
    this.descricaoAparencia = '',
    this.caminhoFoto,
    this.tamanho = 'Médio',
    this.peso = '70 kg',
    this.altura = '1.70 m',
    // Recursos em jogo
    int? pvAtual,
    int? pmAtual,
    this.experienciaAtual = 0,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
       _pvAtual = pvAtual,
       _pmAtual = pmAtual;

  bool get ehDevoto => divindade != null;

  bool get exigeDevocao {
    if (classes.isEmpty) return false;
    final idClasse = classes[0].classeDefinicao.idClasse.toLowerCase();
    return idClasse == 'clerigo' ||
        idClasse == 'clérigo' ||
        idClasse == 'druida' ||
        idClasse == 'paladino';
  }

  factory Personagem.inicial() {
    return Personagem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nome: 'Novo Aventureiro',
      atributos: {
        'FOR': const Atributo(nome: 'Força', valor: 0),
        'DES': const Atributo(nome: 'Destreza', valor: 0),
        'CON': const Atributo(nome: 'Constituição', valor: 0),
        'INT': const Atributo(nome: 'Inteligência', valor: 0),
        'SAB': const Atributo(nome: 'Sabedoria', valor: 0),
        'CAR': const Atributo(nome: 'Carisma', valor: 0),
      },
      raca: null,
      classes: const [],
      periciasTreinadas: const [],
      origem: null,
      poderesGerais: const [],
      itensInventario: const [],
      armas: const [],
      armaduraEquipada: null,
      escudoEquipado: null,
      tibares: 0,
      golpesPessoais: const [],
      engenhocas: const [],
      formaSelvagemAtiva: null,
      tipoCompanheiroAnimal: null,
      montariaSagrada: null,
      divindade: null,
      poderConcedido: null,
      idade: 20,
      alinhamento: 'Neutro',
      descricaoAparencia: '',
      caminhoFoto: null,
      tamanho: 'Médio',
      peso: '70 kg',
      altura: '1.70 m',
      pvAtual: null,
      pmAtual: null,
      experienciaAtual: 0,
    );
  }

  Personagem copyWith({
    String? id,
    String? nome,
    Map<String, Atributo>? atributos,
    Raca? raca,
    // ignore: non_constant_identifier_names
    List<ClasseDoPersonagem>? classe_do_personagem,
    List<String>? periciasTreinadas,
    // Campos referentes a origem e equipamento
    Origem? origem,
    List<Poder>? poderesGerais,
    List<String>? itensInventario,
    List<Arma>? armas,
    Protecao? armaduraEquipada,
    bool anularArmadura = false,
    Protecao? escudoEquipado,
    bool anularEscudo = false,
    int? tibares,
    List<GolpePessoal>? golpesPessoais,
    List<Engenhoca>? engenhocas,
    // Campos de poderes de Druida
    FormaSelvagemAtiva? formaSelvagemAtiva,
    bool anularFormaSelvagem = false,
    String? tipoCompanheiroAnimal,
    bool anularCompanheiro = false,
    // Montaria Sagrada (Paladino)
    MontariaSagrada? montariaSagrada,
    bool anularMontaria = false,
    // Campos referentes a divindade
    Divindade? divindade,
    Poder? poderConcedido,
    bool anularDivindade = false,
    // Campos de personalização
    int? idade,
    String? alinhamento,
    String? descricaoAparencia,
    String? caminhoFoto,
    bool anularFoto = false,
    String? tamanho,
    String? peso,
    String? altura,
    // Recursos dinâmicos em jogo
    int? pvAtual,
    int? pmAtual,
    int? experienciaAtual,
  }) {
    return Personagem(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      atributos: atributos ?? this.atributos,
      raca: raca ?? this.raca,
      classes: classe_do_personagem ?? classes,
      periciasTreinadas: periciasTreinadas ?? this.periciasTreinadas,
      origem: origem ?? this.origem,
      poderesGerais: poderesGerais ?? this.poderesGerais,
      itensInventario: itensInventario ?? this.itensInventario,
      armas: armas ?? this.armas,
      armaduraEquipada: anularArmadura
          ? null
          : (armaduraEquipada ?? this.armaduraEquipada),
      escudoEquipado: anularEscudo
          ? null
          : (escudoEquipado ?? this.escudoEquipado),
      tibares: tibares ?? this.tibares,
      golpesPessoais: golpesPessoais ?? this.golpesPessoais,
      engenhocas: engenhocas ?? this.engenhocas,
      formaSelvagemAtiva: anularFormaSelvagem
          ? null
          : (formaSelvagemAtiva ?? this.formaSelvagemAtiva),
      tipoCompanheiroAnimal: anularCompanheiro
          ? null
          : (tipoCompanheiroAnimal ?? this.tipoCompanheiroAnimal),
      montariaSagrada: anularMontaria
          ? null
          : (montariaSagrada ?? this.montariaSagrada),
      divindade: anularDivindade ? null : (divindade ?? this.divindade),
      poderConcedido: anularDivindade
          ? null
          : (poderConcedido ?? this.poderConcedido),
      idade: idade ?? this.idade,
      alinhamento: alinhamento ?? this.alinhamento,
      descricaoAparencia: descricaoAparencia ?? this.descricaoAparencia,
      caminhoFoto: anularFoto ? null : (caminhoFoto ?? this.caminhoFoto),
      tamanho: tamanho ?? this.tamanho,
      peso: peso ?? this.peso,
      altura: altura ?? this.altura,
      pvAtual: pvAtual ?? _pvAtual,
      pmAtual: pmAtual ?? _pmAtual,
      experienciaAtual: experienciaAtual ?? this.experienciaAtual,
    );
  }

  // --- MÉTODOS DE MANIPULAÇÃO DE RECURSOS EM JOGO ---

  Personagem aplicarDano(int dano) {
    if (dano <= 0) return this;
    final novoPV = pvAtual - dano;
    // Se ficar inconsciente (<= 0) ou morrer, a Forma Selvagem é desfeita imediatamente!
    final bool reverteuForma = novoPV <= 0 && estaEmFormaSelvagem;
    return copyWith(
      pvAtual: novoPV,
      formaSelvagemAtiva: reverteuForma ? null : formaSelvagemAtiva,
      anularFormaSelvagem: reverteuForma,
    );
  }

  Personagem assumirFormaSelvagem(FormaSelvagem forma) {
    final ativa = FormaSelvagemAtiva.fromFormaENivel(
      forma: forma,
      nivelDruida: nivelDruida,
    );
    final novoPM = (pmAtual - ativa.custoPm).clamp(0, pmTotal);
    return copyWith(
      formaSelvagemAtiva: ativa,
      pmAtual: novoPM,
    );
  }

  Personagem reverterFormaSelvagem() {
    return copyWith(anularFormaSelvagem: true);
  }

  Personagem curarPV(int cura) {
    if (cura <= 0) return this;
    final novoPV = (pvAtual + cura).clamp(0, pvTotal);
    return copyWith(pvAtual: novoPV);
  }

  Personagem gastarPM(int gasto) {
    if (gasto <= 0) return this;
    final novoPM = (pmAtual - gasto).clamp(0, pmTotal);
    return copyWith(pmAtual: novoPM);
  }

  Personagem recuperarPM(int recuperacao) {
    if (recuperacao <= 0) return this;
    final novoPM = (pmAtual + recuperacao).clamp(0, pmTotal);
    return copyWith(pmAtual: novoPM);
  }

  Personagem adicionarXP(int xp) {
    if (xp <= 0) return this;
    return copyWith(experienciaAtual: experienciaAtual + xp);
  }

  Personagem restaurarRecursos() {
    return copyWith(pvAtual: pvTotal, pmAtual: pmTotal);
  }

  // Getters específicos de Druida
  bool get estaEmFormaSelvagem => formaSelvagemAtiva != null;

  bool get temPoderFormaSelvagem => classes.any(
    (c) => c.poderesEscolhidos.any((p) => p.key == 'FORMA_SELVAGEM'),
  );

  bool get temPoderCompanheiroAnimal => classes.any(
    (c) => c.poderesEscolhidos.any((p) => p.key == 'COMPANHEIRO_ANIMAL'),
  );

  int get nivelDruida =>
      classes
          .where((c) => c.classeDefinicao.idClasse.toLowerCase() == 'druida')
          .firstOrNull
          ?.nivel ??
      0;

  // Getters e métodos específicos de Inventor e Engenhocas
  int get nivelInventor =>
      classes
          .where((c) => c.classeDefinicao.idClasse.toLowerCase() == 'inventor')
          .firstOrNull
          ?.nivel ??
      0;

  bool get temPoderEngenhoqueiro => classes.any(
    (c) => c.poderesEscolhidos.any((p) => p.key.toUpperCase() == 'ENGENHOQUEIRO'),
  ) || poderesGerais.any((p) => p.key.toUpperCase() == 'ENGENHOQUEIRO');

  bool get temPoderManutencaoEficiente => classes.any(
    (c) => c.poderesEscolhidos.any((p) => p.key.toUpperCase() == 'MANUTENCAO_EFICIENTE'),
  ) || poderesGerais.any((p) => p.key.toUpperCase() == 'MANUTENCAO_EFICIENTE');

  /// Limite de engenhocas ativas sustentadas pelo personagem:
  /// Baseado em Inteligência (+3 se possuir Manutenção Eficiente). Mínimo 0.
  int get limiteEngenhocas {
    final int baseInt = getValorFinal('INT');
    final int extra = temPoderManutencaoEficiente ? 3 : 0;
    final int total = baseInt + extra;
    return total < 0 ? 0 : total;
  }

  /// Espaços totais de inventário ocupados pelas engenhocas
  num get espacosTotaisEngenhocas =>
      engenhocas.fold<num>(0, (soma, e) => soma + e.espacosOcupados);

  Personagem adicionarEngenhoca(Engenhoca engenhoca) {
    return copyWith(engenhocas: [...engenhocas, engenhoca]);
  }

  Personagem removerEngenhoca(String idEngenhoca) {
    return copyWith(
      engenhocas: engenhocas.where((e) => e.id != idEngenhoca).toList(),
    );
  }

  Personagem atualizarEngenhoca(Engenhoca engenhocaAtualizada) {
    return copyWith(
      engenhocas: engenhocas
          .map((e) => e.id == engenhocaAtualizada.id ? engenhocaAtualizada : e)
          .toList(),
    );
  }

  Personagem ativarEngenhoca(String idEngenhoca) {
    return copyWith(
      engenhocas: engenhocas.map((e) {
        if (e.id == idEngenhoca) {
          return e.copyWith(usosHoje: e.usosHoje + 1);
        }
        return e;
      }).toList(),
    );
  }

  Personagem enguicarEngenhoca(String idEngenhoca) {
    return copyWith(
      engenhocas: engenhocas.map((e) {
        if (e.id == idEngenhoca) {
          return e.copyWith(enguicado: true);
        }
        return e;
      }).toList(),
    );
  }

  Personagem consertarEngenhoca(String idEngenhoca) {
    return copyWith(
      engenhocas: engenhocas.map((e) {
        if (e.id == idEngenhoca) {
          return e.copyWith(enguicado: false);
        }
        return e;
      }).toList(),
    );
  }

  Personagem descansarEngenhocas() {
    return copyWith(
      engenhocas: engenhocas.map((e) => e.copyWith(usosHoje: 0)).toList(),
    );
  }

  // Getters e métodos específicos de Paladino e Montaria Sagrada
  int get nivelPaladino =>
      classes
          .where((c) => c.classeDefinicao.idClasse.toLowerCase() == 'paladino')
          .firstOrNull
          ?.nivel ??
      0;

  bool get temCaminhoMontariaSagrada {
    final clPaladino = classes
        .where((c) => c.classeDefinicao.idClasse.toLowerCase() == 'paladino')
        .firstOrNull;
    if (clPaladino == null) return false;
    final nomeCaminho = clPaladino.caminhoEscolhido?.nome.toLowerCase() ?? '';
    return nomeCaminho.contains('montaria');
  }

  bool get temMontariaSagrada =>
      (nivelPaladino >= 5 && temCaminhoMontariaSagrada) || montariaSagrada != null;

  bool get montariaSagradaAtiva =>
      temMontariaSagrada && (montariaSagrada?.ativa ?? false);

  String get tierMontariaSagrada =>
      BancoDeRegrasMontariaSagrada.tierParaNivel(nivelPaladino);

  int get deslocamentoMontadoMetros =>
      BancoDeRegrasMontariaSagrada.deslocamentoParaNivel(nivelPaladino);

  Personagem atualizarMontariaSagrada(MontariaSagrada montaria) {
    return copyWith(montariaSagrada: montaria);
  }

  Personagem invocarMontariaSagrada() {
    final custo = BancoDeRegrasMontariaSagrada.custoPmInvocacao;
    if (pmAtual < custo) return this;
    final montariaAtual = montariaSagrada ??
        MontariaSagrada(
          nomeCustomizado: BancoDeRegrasMontariaSagrada.animalPadraoParaTamanho(tamanho),
          especie: BancoDeRegrasMontariaSagrada.animalPadraoParaTamanho(tamanho),
        );
    return copyWith(
      pmAtual: (pmAtual - custo).clamp(0, pmTotal),
      montariaSagrada: montariaAtual.copyWith(invocada: true),
    );
  }

  Personagem dispensarMontariaSagrada() {
    if (montariaSagrada == null) return this;
    return copyWith(
      montariaSagrada: montariaSagrada!.copyWith(invocada: false),
    );
  }

  Personagem alternarVarianteMundanaMontaria(bool mundana) {
    final montariaAtual = montariaSagrada ??
        MontariaSagrada(
          nomeCustomizado: BancoDeRegrasMontariaSagrada.animalPadraoParaTamanho(tamanho),
          especie: BancoDeRegrasMontariaSagrada.animalPadraoParaTamanho(tamanho),
        );
    return copyWith(
      montariaSagrada: montariaAtual.copyWith(isVarianteMundana: mundana),
    );
  }

  /// Retorna as armas efetivas do personagem (se transformado, retorna as armas naturais da forma selvagem)
  List<Arma> get armasEfetivas {
    if (estaEmFormaSelvagem) {
      return formaSelvagemAtiva!.gerarArmas();
    }
    return armas;
  }

  /// Redução de dano total ativa
  int get rdTotal => estaEmFormaSelvagem ? formaSelvagemAtiva!.rd : 0;

  // Este método calcula o valor final para exibir na tela (Base + Raça Fixa + Raça Variável + Forma Selvagem)
  int getValorFinal(String sigla, {List<String> bonusVariaveis = const []}) {
    int base = atributos[sigla]?.valor ?? 0;
    int bonusFixo = raca?.modificadores[sigla] ?? 0;
    int bonusVariavel = bonusVariaveis.contains(sigla) ? 1 : 0;
    int bonusForma = 0;
    if (estaEmFormaSelvagem &&
        formaSelvagemAtiva!.modificadores.containsKey(sigla)) {
      bonusForma = formaSelvagemAtiva!.modificadores[sigla]!;
    }
    return base + bonusFixo + bonusVariavel + bonusForma;
  }

  // Nível de Personagem (Soma dos níveis de todas as classes)
  int get nivelPersonagem {
    if (classes.isEmpty) return 0;
    return classes.fold(0, (soma, c) => soma + c.nivel);
  }

  // Pontos de Vida Totais (PV)
  int get pvTotal {
    if (classes.isEmpty) return 0;

    int con = getValorFinal('CON');
    int totalPV = 0;

    for (int i = 0; i < classes.length; i++) {
      final item = classes[i];
      final regras = item.classeDefinicao;
      final bool ehClasseInicial = (i == 0);

      if (ehClasseInicial) {
        totalPV += regras.pvInicial + con;
        if (item.nivel > 1) {
          int ganhoPorNivel = regras.pvPorNivel + con;
          if (ganhoPorNivel < 1) ganhoPorNivel = 1;
          totalPV += ganhoPorNivel * (item.nivel - 1);
        }
      } else {
        int ganhoPorNivel = regras.pvPorNivel + con;
        if (ganhoPorNivel < 1) ganhoPorNivel = 1;
        totalPV += ganhoPorNivel * item.nivel;
      }
    }
    return totalPV;
  }

  // Pontos de Mana Totais (PM)
  int get pmTotal {
    if (classes.isEmpty) return 0;

    int totalPM = 0;

    for (int i = 0; i < classes.length; i++) {
      final item = classes[i];
      final regras = item.classeDefinicao;

      if (i == 0) {
        totalPM += regras.pmInicial;
        if (item.nivel > 1) {
          totalPM += regras.pmPorNivel * (item.nivel - 1);
        }
      } else {
        totalPM += regras.pmPorNivel * item.nivel;
      }

      if (item.caminhoEscolhido != null) {
        String siglaChave = item.caminhoEscolhido!.atributoChave;
        int valorAtributoChave = getValorFinal(siglaChave);
        totalPM += valorAtributoChave;
      }
    }
    return totalPM;
  }

  // --- CÁLCULO DE DEFESA E PROTEÇÕES (TORMENTA 20) ---
  int get bonusArmadura => armaduraEquipada?.bonusDefesa ?? 0;
  int get bonusEscudo => escudoEquipado?.bonusDefesa ?? 0;
  bool get usaArmaduraPesada => armaduraEquipada?.ehArmaduraPesada ?? false;

  /// Defesa final calculada reativamente:
  /// Defesa = 10 + (usaArmaduraPesada ? 0 : modDES) + bonusArmadura + bonusEscudo + bonusForma + bonusCompanheiro
  int get defesaFinal {
    final modDes = getValorFinal('DES');
    final modDesAplicado = usaArmaduraPesada ? 0 : modDes;
    int bonusForma = 0;
    if (estaEmFormaSelvagem &&
        formaSelvagemAtiva!.modificadores.containsKey('DEFESA')) {
      bonusForma = formaSelvagemAtiva!.modificadores['DEFESA']!;
    }
    final bonusCompanheiro = (temPoderCompanheiroAnimal && tipoCompanheiroAnimal == 'GUARDIAO')
        ? (nivelDruida >= 12 ? 3 : (nivelDruida >= 6 ? 2 : 1))
        : 0;
    return 10 +
        modDesAplicado +
        bonusArmadura +
        bonusEscudo +
        bonusForma +
        bonusCompanheiro;
  }

  /// Defesa básica sem armaduras (10 + DES)
  int get defesaBase {
    final modDes = getValorFinal('DES');
    return 10 + modDes;
  }

  /// Penalidade total cumulativa de armadura (armadura + escudo + 2 se sobrecarregado)
  int get penalidadeArmaduraTotal {
    int total =
        (armaduraEquipada?.penalidadeArmadura ?? 0) +
        (escudoEquipado?.penalidadeArmadura ?? 0);
    if (estaSobrecarregado) {
      total += 2; // T20: sobrecarga adiciona -2 de penalidade de armadura
    }
    return total;
  }

  /// Verifica se o personagem está usando armadura ou escudo sem a proficiência necessária
  bool get usaProtecaoSemProficiencia {
    if (armaduraEquipada != null) {
      if (armaduraEquipada!.ehArmaduraPesada &&
          !temProficienciaArmadurasPesadas) {
        return true;
      }
      if (armaduraEquipada!.ehArmaduraLeve && !temProficienciaArmadurasLeves) {
        return true;
      }
    }
    if (escudoEquipado != null && !temProficienciaEscudos) {
      return true;
    }
    return false;
  }

  // PV do Foco Mágico (Regra Específica do Arcanista Bruxo)
  int get pvDoFocoMagico {
    for (var item in classes) {
      if (item.caminhoEscolhido?.temFocoMagico == true) {
        return (pvTotal / 2).floor();
      }
    }
    return 0;
  }

  // Bônus baseado no nível do personagem
  int get bonusTreinamento {
    if (nivelPersonagem >= 15) return 6;
    if (nivelPersonagem >= 7) return 4;
    return 2;
  }

  // Cálculo final da perícia
  int getValorPericia(String periciaKey, {int? penalidadeArmaduraCustom}) {
    final pericia = BancoDePericias.getByKey(periciaKey);

    int metadeNivel = (nivelPersonagem / 2).floor();
    int modAtributo = getValorFinal(pericia.atributoChave);

    bool ehTreinada = periciasTreinadas.contains(periciaKey);
    int bonusTreino = ehTreinada ? bonusTreinamento : 0;

    final penalidade = penalidadeArmaduraCustom ?? penalidadeArmaduraTotal;

    int penalidadeAplicada = 0;
    if (pericia.penalidadeArmadura) {
      penalidadeAplicada = penalidade;
    } else if (usaProtecaoSemProficiencia &&
        (pericia.atributoChave == 'FOR' || pericia.atributoChave == 'DES')) {
      // Regra T20: se não tiver proficiência, a penalidade afeta TODAS as perícias de FOR e DES
      penalidadeAplicada = penalidade;
    }

    return metadeNivel + modAtributo + bonusTreino - penalidadeAplicada;
  }

  // --- REGRAS DE PROFICIÊNCIAS ---
  bool get temProficienciaMarcial => classes.any(
    (c) => c.classeDefinicao.proficiencias.contains(
      TipoProficiencia.armasMarciais,
    ),
  );

  bool get temProficienciaSimples => classes.any(
    (c) =>
        c.classeDefinicao.proficiencias.contains(TipoProficiencia.armasSimples),
  );

  bool get temProficienciaArmadurasLeves => classes.any(
    (c) => c.classeDefinicao.proficiencias.contains(
      TipoProficiencia.armadurasLeves,
    ),
  );

  bool get temProficienciaArmadurasPesadas => classes.any(
    (c) => c.classeDefinicao.proficiencias.contains(
      TipoProficiencia.armadurasPesadas,
    ),
  );

  bool get temProficienciaEscudos => classes.any(
    (c) => c.classeDefinicao.proficiencias.contains(TipoProficiencia.escudos),
  );

  bool get ehArcanista => classes.any(
    (c) => c.classeDefinicao.idClasse.toLowerCase() == 'arcanista',
  );

  // --- CAPACIDADE DE CARGA (TORMENTA 20) ---
  int get limiteCarga =>
      RegrasCargaService.calcularLimiteCarga(getValorFinal('FOR'));

  int get cargaAtual => RegrasCargaService.calcularEspacosOcupados(
    armas: armas,
    itensInventario: itensInventario,
    armadura: armaduraEquipada,
    escudo: escudoEquipado,
  );

  bool get estaSobrecarregado => cargaAtual > limiteCarga;
}
