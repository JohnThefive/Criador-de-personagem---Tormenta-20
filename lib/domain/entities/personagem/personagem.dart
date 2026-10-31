import 'dart:math';
import 'package:t20_creator/domain/entities/personagem/poder.dart';
import '../equipamento/arma.dart';
import '../equipamento/protecao.dart';
import '../equipamento/item_vestido.dart';
import 'proficiencias.dart';
import 'efeito_temporario.dart';
import '../habilidades_complexas/forma_selvagem.dart';
import '../habilidades_complexas/golpe_pessoal.dart';
import '../habilidades_complexas/engenhoca.dart';
import '../habilidades_complexas/montaria_sagrada.dart';
import '../../services/data_services/call_montaria_sagrada.dart';
import '../../services/regras_carga_service.dart';
import '../../services/motor_modificadores_service.dart';
import '../../services/motor_multiclasse_service.dart';

import 'atributos.dart';
import 'pericias.dart';
import 'raca.dart';
import 'classe_do_personagem.dart';
import 'origem.dart';
import 'divindade.dart';

// imports pras pericias
import '../../services/data_services/call_pericias.dart';

class Personagem {
  final String nome;
  final Map<String, Atributo> atributos; // Atributos BASE (Rolados/Comprados)
  final Raca? raca;
  final List<ClasseDoPersonagem> classes; // Índice [0] é a classe inicial
  final List<String>
  historicoClassesPorNivel; // RF02 / RF12: Histórico cronológico de classe escolhida em cada nível (1..N)
  final List<String> periciasTreinadas;
  final Map<String, int> outrosBonusPericias; // Bônus diversos por perícia ("Outros")

  // Campos referentes a origem e equipamento
  final Origem? origem;
  final List<Poder> poderesGerais; // Armazena poderes de origem / gerais
  final List<String> itensInventario; // Recebe os itens da mochila
  final List<ItemVestido> itensVestidosExtras; // Slots 2, 3 e 4 de itens vestidos (Slot 1 = armaduraEquipada)
  final List<Arma> armas; // Armas equipadas/carregadas
  final Protecao? armaduraEquipada; // Armadura equipada (Slot 1 vestido)
  final Protecao? escudoEquipado; // Escudo equipado (Empunhado)
  final int tibaresCobre; // TC (0,1 T$)
  final int tibares; // Dinheiro padrão em T$ (Tibar de Prata)
  final int tibaresOuro; // TO (10 T$)

  // Defesa, Redução de Dano, Efeitos Temporários e Proficiências extras
  final int outrosBonusDefesa;
  final int rdPadrao;
  final List<String> rdsDiversas;
  final List<String> proficienciasExtras;
  final List<EfeitoTemporario> efeitosTemporarios;

  // Golpes Pessoais (customizados para Guerreiro)
  final List<GolpePessoal> golpesPessoais;

  // Engenhocas (customizadas para Inventor)
  final List<Engenhoca> engenhocas;

  // Campos específicos de poderes de Druida
  final FormaSelvagemAtiva? formaSelvagemAtiva;
  final String? tipoCompanheiroAnimal; // Ex: "GUARDIAO", "FORTAO", "AJUDANTE"

  // Montaria Sagrada (Paladino)
  final MontariaSagrada? montariaSagrada;

  // Campos referentes a divindade e devoção
  final Divindade? divindade;
  final List<Poder> poderesConcedidos;
  final TipoEnergia? canalizacaoEnergia;
  final bool punicaoDivinaAtiva;

  // Magias aprendidas / conhecidas pelo personagem
  final List<String> magiasConhecidas;
  final int outrosBonusCDMagia;

  // Deformidade do Lefou (+2 em 2 perícias OU +2 em 1 perícia + 1 Poder da Tormenta sem perda de Carisma)
  final List<String> periciasDeformidadeLefou;
  final Poder? poderTormentaDeformidade;

  Poder? get poderConcedido =>
      poderesConcedidos.isNotEmpty ? poderesConcedidos.first : null;

  List<Poder> get poderesConcedidosAtivos =>
      punicaoDivinaAtiva ? const [] : poderesConcedidos;

  // Finalização, anotações e progressão do personagem
  final String id; // Identificador único
  final int idade;
  final String alinhamento; // Ex: "Caótico e Bom", "Leal e Neutro"
  final String
  descricaoAparencia; // Breve biografia/descrição escrita pelo jogador
  final String anotacoes; // Texto livre de sessão do jogador
  final Map<int, String> notasProgressaoPorNivel; // Distinções/revisões por nível
  final String? caminhoFoto; // Caminho local da imagem escolhida no celular
  final String tamanho; // Padrão: "Médio"
  final String peso; // Ex: "70 kg"
  final String altura; // Ex: "1.70 m"

  // Estado dinâmico de jogo / sessão
  final int? _pvAtual;
  final int? _pmAtual;
  final int experienciaAtual;

  final List<String> atributosVariaveisRaca;

  int get pvAtual => _pvAtual ?? pvTotal;
  int get pmAtual => punicaoDivinaAtiva ? 0 : (_pmAtual ?? pmTotal);

  Personagem({
    required this.nome,
    required this.atributos,
    this.raca,
    this.classes = const [],
    this.historicoClassesPorNivel = const [],
    this.periciasTreinadas = const [],
    this.outrosBonusPericias = const {},
    // Campos referentes a origem e equipamento
    this.origem,
    this.poderesGerais = const [],
    this.itensInventario = const [],
    this.itensVestidosExtras = const [],
    this.armas = const [],
    this.armaduraEquipada,
    this.escudoEquipado,
    this.tibaresCobre = 0,
    this.tibares = 0,
    this.tibaresOuro = 0,
    // Defesa, RD e efeitos temporários
    this.outrosBonusDefesa = 0,
    this.rdPadrao = 0,
    this.rdsDiversas = const [],
    this.proficienciasExtras = const [],
    this.efeitosTemporarios = const [],
    // Golpes Pessoais (customizados para Guerreiro)
    this.golpesPessoais = const [],
    // Engenhocas (customizadas para Inventor)
    this.engenhocas = const [],
    // Campos específicos de poderes de Druida
    this.formaSelvagemAtiva,
    this.tipoCompanheiroAnimal,
    // Montaria Sagrada (Paladino)
    this.montariaSagrada,
    // Campos referentes a divindade e devoção
    this.divindade,
    List<Poder>? poderesConcedidos,
    Poder? poderConcedido,
    this.canalizacaoEnergia,
    this.punicaoDivinaAtiva = false,
    this.magiasConhecidas = const [],
    this.outrosBonusCDMagia = 0,
    this.periciasDeformidadeLefou = const [],
    this.poderTormentaDeformidade,
    // Campos de personalização (com fallback para id se vier nulo)
    String? id,
    this.idade = 20,
    this.alinhamento = 'Neutro',
    this.descricaoAparencia = '',
    this.anotacoes = '',
    this.notasProgressaoPorNivel = const {},
    this.caminhoFoto,
    this.tamanho = 'Médio',
    this.peso = '70 kg',
    this.altura = '1.70 m',
    this.atributosVariaveisRaca = const [],
    // Recursos em jogo
    int? pvAtual,
    int? pmAtual,
    this.experienciaAtual = 0,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
       poderesConcedidos =
           poderesConcedidos ??
           (poderConcedido != null ? [poderConcedido] : const []),
       _pvAtual = pvAtual,
       _pmAtual = pmAtual;

  bool get exigeDevocao {
    if (classes.isEmpty) return false;
    final idClasse = classes[0].classeDefinicao.idClasse.toLowerCase();
    return idClasse == 'clerigo' ||
        idClasse == 'clérigo' ||
        idClasse == 'druida' ||
        idClasse == 'paladino';
  }

  bool get ehDevoto => divindade != null;

  bool get ehDevotoFiel => exigeDevocao;

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
      historicoClassesPorNivel: const [],
      periciasTreinadas: const [],
      outrosBonusPericias: const {},
      origem: null,
      poderesGerais: const [],
      itensInventario: const [],
      itensVestidosExtras: const [],
      armas: const [],
      armaduraEquipada: null,
      escudoEquipado: null,
      tibaresCobre: 0,
      tibares: 0,
      tibaresOuro: 0,
      outrosBonusDefesa: 0,
      rdPadrao: 0,
      rdsDiversas: const [],
      proficienciasExtras: const [],
      efeitosTemporarios: const [],
      golpesPessoais: const [],
      engenhocas: const [],
      formaSelvagemAtiva: null,
      tipoCompanheiroAnimal: null,
      montariaSagrada: null,
      divindade: null,
      poderConcedido: null,
      magiasConhecidas: const [],
      outrosBonusCDMagia: 0,
      periciasDeformidadeLefou: const [],
      poderTormentaDeformidade: null,
      atributosVariaveisRaca: const [],
      idade: 20,
      alinhamento: 'Neutro',
      descricaoAparencia: '',
      anotacoes: '',
      notasProgressaoPorNivel: const {},
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
    List<String>? atributosVariaveisRaca,
    // ignore: non_constant_identifier_names
    List<ClasseDoPersonagem>? classe_do_personagem,
    List<String>? historicoClassesPorNivel,
    List<String>? periciasTreinadas,
    Map<String, int>? outrosBonusPericias,
    // Campos referentes a origem e equipamento
    Origem? origem,
    List<Poder>? poderesGerais,
    List<String>? itensInventario,
    List<ItemVestido>? itensVestidosExtras,
    List<Arma>? armas,
    Protecao? armaduraEquipada,
    bool anularArmadura = false,
    Protecao? escudoEquipado,
    bool anularEscudo = false,
    int? tibaresCobre,
    int? tibares,
    int? tibaresOuro,
    int? outrosBonusDefesa,
    int? rdPadrao,
    List<String>? rdsDiversas,
    List<String>? proficienciasExtras,
    List<EfeitoTemporario>? efeitosTemporarios,
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
    // Campos referentes a divindade e devoção
    Divindade? divindade,
    List<Poder>? poderesConcedidos,
    Poder? poderConcedido,
    TipoEnergia? canalizacaoEnergia,
    bool anularCanalizacao = false,
    bool? punicaoDivinaAtiva,
    bool anularDivindade = false,
    List<String>? magiasConhecidas,
    int? outrosBonusCDMagia,
    List<String>? periciasDeformidadeLefou,
    Poder? poderTormentaDeformidade,
    bool anularPoderTormentaDeformidade = false,
    // Campos de personalização
    int? idade,
    String? alinhamento,
    String? descricaoAparencia,
    String? anotacoes,
    Map<int, String>? notasProgressaoPorNivel,
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
      atributosVariaveisRaca:
          atributosVariaveisRaca ?? this.atributosVariaveisRaca,
      classes: classe_do_personagem ?? classes,
      historicoClassesPorNivel:
          historicoClassesPorNivel ?? this.historicoClassesPorNivel,
      periciasTreinadas: periciasTreinadas ?? this.periciasTreinadas,
      outrosBonusPericias: outrosBonusPericias ?? this.outrosBonusPericias,
      origem: origem ?? this.origem,
      poderesGerais: poderesGerais ?? this.poderesGerais,
      itensInventario: itensInventario ?? this.itensInventario,
      itensVestidosExtras: itensVestidosExtras ?? this.itensVestidosExtras,
      armas: armas ?? this.armas,
      armaduraEquipada: anularArmadura
          ? null
          : (armaduraEquipada ?? this.armaduraEquipada),
      escudoEquipado: anularEscudo
          ? null
          : (escudoEquipado ?? this.escudoEquipado),
      tibaresCobre: tibaresCobre ?? this.tibaresCobre,
      tibares: tibares ?? this.tibares,
      tibaresOuro: tibaresOuro ?? this.tibaresOuro,
      outrosBonusDefesa: outrosBonusDefesa ?? this.outrosBonusDefesa,
      rdPadrao: rdPadrao ?? this.rdPadrao,
      rdsDiversas: rdsDiversas ?? this.rdsDiversas,
      proficienciasExtras: proficienciasExtras ?? this.proficienciasExtras,
      efeitosTemporarios: efeitosTemporarios ?? this.efeitosTemporarios,
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
      poderesConcedidos: anularDivindade
          ? const []
          : (poderesConcedidos ??
                (poderConcedido != null
                    ? [poderConcedido]
                    : this.poderesConcedidos)),
      canalizacaoEnergia: (anularDivindade || anularCanalizacao)
          ? null
          : (canalizacaoEnergia ?? this.canalizacaoEnergia),
      punicaoDivinaAtiva: anularDivindade
          ? false
          : (punicaoDivinaAtiva ?? this.punicaoDivinaAtiva),
      magiasConhecidas: magiasConhecidas ?? this.magiasConhecidas,
      outrosBonusCDMagia: outrosBonusCDMagia ?? this.outrosBonusCDMagia,
      periciasDeformidadeLefou:
          periciasDeformidadeLefou ?? this.periciasDeformidadeLefou,
      poderTormentaDeformidade: anularPoderTormentaDeformidade
          ? null
          : (poderTormentaDeformidade ?? this.poderTormentaDeformidade),
      idade: idade ?? this.idade,
      alinhamento: alinhamento ?? this.alinhamento,
      descricaoAparencia: descricaoAparencia ?? this.descricaoAparencia,
      anotacoes: anotacoes ?? this.anotacoes,
      notasProgressaoPorNivel:
          notasProgressaoPorNivel ?? this.notasProgressaoPorNivel,
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
    return copyWith(formaSelvagemAtiva: ativa, pmAtual: novoPM);
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
    if (punicaoDivinaAtiva || gasto <= 0) return this;
    final novoPM = (pmAtual - gasto).clamp(0, pmTotal);
    return copyWith(pmAtual: novoPM);
  }

  Personagem recuperarPM(int recuperacao) {
    if (punicaoDivinaAtiva || recuperacao <= 0) return this;
    final novoPM = (pmAtual + recuperacao).clamp(0, pmTotal);
    return copyWith(pmAtual: novoPM);
  }

  Personagem adicionarXP(int xp) {
    if (xp <= 0) return this;
    return copyWith(experienciaAtual: experienciaAtual + xp);
  }

  Personagem restaurarRecursos() {
    return copyWith(
      pvAtual: pvTotal,
      pmAtual: punicaoDivinaAtiva ? 0 : pmTotal,
    );
  }

  /// Aplica a penalidade mecânica de Punição Divina (decretada pelo Mestre)
  Personagem aplicarPunicaoDivina() {
    return copyWith(punicaoDivinaAtiva: true, pmAtual: 0);
  }

  /// Remove a Punição Divina após o cumprimento de penitência
  Personagem removerPunicaoDivina() {
    return copyWith(punicaoDivinaAtiva: false);
  }

  /// Recuperação padrão de descanso (Nível + CON em PV, mínimo 1)
  int get curaDescansoNormalPV =>
      max(1, (nivelPersonagem > 0 ? nivelPersonagem : 1) + getValorFinal('CON'));

  /// Recuperação padrão de descanso (Nível em PM, mínimo 1)
  int get curaDescansoNormalPM =>
      max(1, nivelPersonagem > 0 ? nivelPersonagem : 1);

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

  bool get temPoderEngenhoqueiro =>
      classes.any(
        (c) => c.poderesEscolhidos.any(
          (p) => p.key.toUpperCase() == 'ENGENHOQUEIRO',
        ),
      ) ||
      poderesGerais.any((p) => p.key.toUpperCase() == 'ENGENHOQUEIRO');

  bool get temPoderManutencaoEficiente =>
      classes.any(
        (c) => c.poderesEscolhidos.any(
          (p) => p.key.toUpperCase() == 'MANUTENCAO_EFICIENTE',
        ),
      ) ||
      poderesGerais.any((p) => p.key.toUpperCase() == 'MANUTENCAO_EFICIENTE');

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
      (nivelPaladino >= 5 && temCaminhoMontariaSagrada) ||
      montariaSagrada != null;

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
    final montariaAtual =
        montariaSagrada ??
        MontariaSagrada(
          nomeCustomizado: BancoDeRegrasMontariaSagrada.animalPadraoParaTamanho(
            tamanho,
          ),
          especie: BancoDeRegrasMontariaSagrada.animalPadraoParaTamanho(
            tamanho,
          ),
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
    final montariaAtual =
        montariaSagrada ??
        MontariaSagrada(
          nomeCustomizado: BancoDeRegrasMontariaSagrada.animalPadraoParaTamanho(
            tamanho,
          ),
          especie: BancoDeRegrasMontariaSagrada.animalPadraoParaTamanho(
            tamanho,
          ),
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

  // --- BÔNUS DE EFEITOS TEMPORÁRIOS ATIVOS ---
  int get bonusEfeitosDefesa => efeitosTemporarios
      .where((e) => e.ativo)
      .fold(0, (soma, e) => soma + e.modDefesa);

  int get bonusEfeitosPericias => efeitosTemporarios
      .where((e) => e.ativo)
      .fold(0, (soma, e) => soma + e.modPericias);

  int get bonusEfeitosRd => efeitosTemporarios
      .where((e) => e.ativo)
      .fold(0, (soma, e) => soma + e.modRd);

  int get bonusDeclarativoRd =>
      MotorModificadoresService.calcularBonusDeclarativoRD(this);

  /// Redução de dano padrão total ativa (RD Padrão + Forma Selvagem + Poderes/Equipamentos + Efeitos Temporários)
  int get rdTotal {
    final rdForma = estaEmFormaSelvagem ? formaSelvagemAtiva!.rd : 0;
    final soma = rdPadrao + rdForma + bonusDeclarativoRd + bonusEfeitosRd;
    return soma < 0 ? 0 : soma;
  }

  /// Total de poderes da Tormenta para pré-requisitos e escalonamento (inclui Deformidade do Lefou)
  int get totalPoderesTormenta =>
      MotorModificadoresService.contarPoderesTormentaParaEscalamento(this);

  /// Quantidade de poderes da Tormenta que causam perda de Carisma
  int get poderesTormentaComPerdaCarisma =>
      MotorModificadoresService.contarPoderesTormentaComPerdaCarisma(this);

  /// Perda de Carisma oriunda de Poderes da Tormenta (1 no primeiro + 1 a cada 2 outros)
  int get perdaCarismaTormenta =>
      MotorModificadoresService.calcularPerdaCarismaTormenta(this);

  /// Em Tormenta 20: um personagem reduzido a menos que Car –5 torna-se um NPC sob controle do mestre.
  bool get dominadoPelaTormenta => getValorFinal('CAR') < -5;

  // Este método calcula o valor final para exibir na tela (Base + Raça Fixa + Raça Variável + Forma Selvagem - Perda Tormenta)
  int getValorFinal(String sigla, {List<String>? bonusVariaveis}) {
    final variaveisEfetivos = bonusVariaveis ?? atributosVariaveisRaca;

    int base = atributos[sigla]?.valor ?? 0;
    int bonusFixo = raca?.modificadores[sigla] ?? 0;
    int bonusVariavel = variaveisEfetivos.contains(sigla) ? 1 : 0;
    int bonusForma = 0;
    if (estaEmFormaSelvagem &&
        formaSelvagemAtiva!.modificadores.containsKey(sigla)) {
      bonusForma = formaSelvagemAtiva!.modificadores[sigla]!;
    }
    int penalidadeTormenta = sigla.toUpperCase() == 'CAR'
        ? perdaCarismaTormenta
        : 0;
    return base + bonusFixo + bonusVariavel + bonusForma - penalidadeTormenta;
  }

  // RF03 / RN02 — Nível Total de Personagem (Soma dos níveis individuais de todas as classes)
  int get nivelPersonagem => MotorMulticlasseService.calcularNivelTotal(this);

  // RF10 / RN09 — Patamar de jogo baseado no nível total
  PatamarJogo get patamar => MotorMulticlasseService.identificarPatamar(this);
  String get nomePatamar => patamar.label;

  // RF04 / RN03 — Consulta do nível individual de uma classe específica
  int nivelNaClasse(String idOuNomeClasse) =>
      MotorMulticlasseService.obterNivelIndividualClasse(this, idOuNomeClasse);

  // RF05 / RN08 / RV07 — Consulta das características adquiridas respeitando o nível individual da classe
  List<String> caracteristicasDaClasse(String idOuNomeClasse) =>
      MotorMulticlasseService.obterCaracteristicasAcumuladasDaClasse(
        this,
        idOuNomeClasse,
      );

  // RF11 — Consulta da distribuição dos níveis entre classes
  ResumoDistribuicaoMulticlasse get distribuicaoMulticlasse =>
      MotorMulticlasseService.consultarDistribuicaoNiveis(this);

  String get resumoDistribuicaoClassesTexto =>
      distribuicaoMulticlasse.formatarTexto();

  // RF06 / RN04 / RV05 — Pontos de Vida Totais (PV na multiclasse usa ganho de nível subsequente)
  int get pvTotal => MotorMulticlasseService.calcularPvTotal(this);

  /// Bônus racial de Pontos de Vida (ex: Anão - Duro como Pedra: +3 PV no 1º nível, +1 por nível seguinte)
  int get bonusRacialPV {
    if (classes.isEmpty) return 0;
    final rId = raca?.id.toLowerCase();
    if (rId == 'anao' || rId == 'anão') {
      return 3 + (nivelPersonagem - 1);
    }
    return 0;
  }

  /// Bônus racial de Pontos de Mana (ex: Elfo - Sangue Mágico: +1 PM por nível)
  int get bonusRacialPM {
    if (classes.isEmpty) return 0;
    final rId = raca?.id.toLowerCase();
    if (rId == 'elfo') {
      return nivelPersonagem;
    }
    return 0;
  }

  // RF07 / RN05 — Pontos de Mana Totais (soma de todas as classes)
  int get pmTotal => MotorMulticlasseService.calcularPmTotal(this);

  String? _obterAtributoChaveConjuracao(ClasseDoPersonagem c) {
    return switch (c.classeDefinicao.idClasse.toLowerCase()) {
      'clerigo' || 'clérigo' || 'druida' => 'SAB',
      'bardo' || 'paladino' => 'CAR',
      'arcanista' => c.caminhoEscolhido?.nome == 'Feiticeiro' ? 'CAR' : 'INT',
      _ => null,
    };
  }

  /// Retorna a sigla do atributo-chave principal de conjuração do personagem (ex: INT, SAB, CAR)
  String? get atributoChaveMagiaPrincipal {
    for (final c in classes) {
      final sigla = _obterAtributoChaveConjuracao(c);
      if (sigla != null) return sigla;
    }
    if (raca?.id.toLowerCase() == 'qareen') return 'CAR';
    if (magiasConhecidas.isNotEmpty) return 'INT';
    return null;
  }

  /// Deslocamento base terrestre em metros (ex: Elfo - Graça de Glórienn: 12m; Anão, Golem, Hynne: 6m; Padrão: 9m)
  int get deslocamentoBaseMetros {
    final rId = raca?.id.toLowerCase() ?? '';
    if (rId == 'elfo') return 12;
    if (rId == 'anao' || rId == 'anão' || rId == 'golem' || rId == 'hynne') {
      return 6;
    }
    return 9;
  }

  /// Deslocamento efetivo em metros (Anão e Golem nunca têm deslocamento reduzido por carga ou armadura)
  int get deslocamentoEfetivoMetros {
    final rId = raca?.id.toLowerCase() ?? '';
    final imuneReducao = rId == 'anao' || rId == 'anão' || rId == 'golem';
    int desc = deslocamentoBaseMetros;
    if (!imuneReducao && (usaArmaduraPesada || estaSobrecarregado)) {
      desc = (desc - 3).clamp(1, 99);
    }
    return desc;
  }

  /// Bônus racial inato e passivo de Defesa (ex: Minotauro - Couro Rígido: +1; Trog - Reptiliano: +1; Golem - Chassi: +2)
  int get bonusRacialDefesa {
    final rId = raca?.id.toLowerCase() ?? '';
    if (rId == 'golem') return 2;
    if (rId == 'minotauro' || rId == 'trog') return 1;
    return 0;
  }

  /// Bônus racial inato em perícias (ex: Elfo - Sentidos Élficos: +2 Misticismo e Percepção; Lefou - Deformidade: +2 nas perícias escolhidas; etc.)
  int bonusRacialPericia(String periciaKey) {
    final rId = raca?.id.toLowerCase() ?? '';
    final keyUpper = periciaKey.toUpperCase();
    if (rId == 'lefou') {
      return MotorModificadoresService.calcularBonusDeformidadeLefouPericia(
        this,
        keyUpper,
      );
    } else if (rId == 'elfo') {
      if (keyUpper == 'MISTICISMO' || keyUpper == 'PERCEPCAO') return 2;
    } else if (rId == 'goblin') {
      if (keyUpper == 'FORTITUDE') return 2;
    } else if (rId == 'hynne') {
      if (keyUpper == 'ENGANACAO') return 2;
    } else if (rId == 'suraggel_aggelus') {
      if (keyUpper == 'DIPLOMACIA' || keyUpper == 'INTUICAO') return 2;
    } else if (rId == 'suraggel_sulfure') {
      if (keyUpper == 'ENGANACAO' || keyUpper == 'FURTIVIDADE') return 2;
    }
    return 0;
  }

  /// Bônus declarativo de Poderes (Tormenta e Gerais) e Equipamentos/Itens Vestidos na perícia
  int bonusDeclarativoPericia(String periciaKey) =>
      MotorModificadoresService.calcularBonusDeclarativoPericia(
        this,
        periciaKey,
      );

  // --- CÁLCULO DE DEFESA E PROTEÇÕES (TORMENTA 20) ---
  int get bonusArmadura => armaduraEquipada?.bonusDefesaEfetivo ?? 0;
  int get bonusEscudo => escudoEquipado?.bonusDefesaEfetivo ?? 0;
  bool get usaArmaduraPesada => armaduraEquipada?.ehArmaduraPesada ?? false;

  int get bonusDeclarativoDefesa =>
      MotorModificadoresService.calcularBonusDeclarativoDefesa(this);

  int get bonusFormaDefesa =>
      (estaEmFormaSelvagem &&
              formaSelvagemAtiva!.modificadores.containsKey('DEFESA'))
          ? formaSelvagemAtiva!.modificadores['DEFESA']!
          : 0;

  int get bonusCompanheiroDefesa =>
      (temPoderCompanheiroAnimal && tipoCompanheiroAnimal == 'GUARDIAO')
          ? (nivelDruida >= 12 ? 3 : (nivelDruida >= 6 ? 2 : 1))
          : 0;

  /// Defesa final calculada reativamente:
  /// Defesa = 10 + (usaArmaduraPesada ? bonusDelicada : modDES) + bonusArmadura + bonusEscudo + bonusRacial + bonusForma + bonusCompanheiro + bonusDeclarativoDefesa + outrosBonusDefesa + bonusEfeitosDefesa
  int get defesaFinal {
    final modDes = getValorFinal('DES');
    final modDesAplicado = usaArmaduraPesada
        ? MotorModificadoresService.calcularBonusDestrezaDelicadaArmaduraPesada(
            this,
          )
        : modDes;
    return 10 +
        modDesAplicado +
        bonusArmadura +
        bonusEscudo +
        bonusRacialDefesa +
        bonusFormaDefesa +
        bonusCompanheiroDefesa +
        bonusDeclarativoDefesa +
        outrosBonusDefesa +
        bonusEfeitosDefesa;
  }

  /// Defesa básica sem armaduras (10 + DES)
  int get defesaBase {
    final modDes = getValorFinal('DES');
    return 10 + modDes;
  }

  /// Penalidade total cumulativa de armadura (armadura + escudo + 2 se sobrecarregado)
  late final int penalidadeArmaduraTotal = _calcularPenalidadeArmaduraTotal();

  int _calcularPenalidadeArmaduraTotal() {
    int total =
        (armaduraEquipada?.penalidadeArmaduraEfetiva.abs() ?? 0) +
        (escudoEquipado?.penalidadeArmaduraEfetiva.abs() ?? 0);
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

  // RF08 / RN06 / RV06 — Apenas a classe inicial concede perícias fixas/exclusivas automaticamente!
  late final Set<String> _periciasFixasClasseUpper =
      MotorMulticlasseService.obterPericiasIniciaisClasseConcedidas(this);

  late final Set<String> _periciasTreinadasTotalUpper = {
    ...periciasTreinadas.map((p) => p.toUpperCase()),
    ..._periciasFixasClasseUpper,
  };

  late final Map<String, int> _outrosBonusUpper = outrosBonusPericias.map(
    (k, v) => MapEntry(k.toUpperCase(), v),
  );

  /// Verifica se a perícia é concedida de forma fixa ou exclusiva pela classe inicial (RF08 / RN06)
  bool ehPericiaTreinadaFixaDeClasse(String periciaKey) {
    return _periciasFixasClasseUpper.contains(periciaKey.toUpperCase());
  }

  /// Verifica se o personagem possui treinamento na perícia (manual ou da classe inicial)
  bool ehPericiaTreinada(String periciaKey) {
    return _periciasTreinadasTotalUpper.contains(periciaKey.toUpperCase());
  }

  /// Retorna o bônus diverso ("Outros") cadastrado manualmente para a perícia
  int obterOutrosBonusPericia(String periciaKey) {
    return outrosBonusPericias[periciaKey] ??
        _outrosBonusUpper[periciaKey.toUpperCase()] ??
        0;
  }

  /// Indica se a perícia sofre penalidade de armadura no personagem
  bool periciaSofrePenalidade(Pericia pericia) =>
      pericia.penalidadeArmadura ||
      (usaProtecaoSemProficiencia &&
          (pericia.atributoChave == 'FOR' || pericia.atributoChave == 'DES'));

  // Cálculo final da perícia
  int getValorPericia(String periciaKey, {int? penalidadeArmaduraCustom}) {
    final pericia = BancoDePericias.getByKey(periciaKey);
    final penalidade = penalidadeArmaduraCustom ?? penalidadeArmaduraTotal;
    final penalidadeAplicada = periciaSofrePenalidade(pericia) ? penalidade : 0;

    return (nivelPersonagem / 2).floor() +
        getValorFinal(pericia.atributoChave) +
        (ehPericiaTreinada(periciaKey) ? bonusTreinamento : 0) +
        obterOutrosBonusPericia(periciaKey) +
        bonusRacialPericia(periciaKey) +
        bonusDeclarativoPericia(periciaKey) +
        bonusEfeitosPericias -
        penalidadeAplicada;
  }

  // --- REGRAS DE PROFICIÊNCIAS (RF09 / RN07 / RV06: Multiclasse NÃO concede proficiências iniciais automaticamente) ---
  late final Set<TipoProficiencia> _proficienciasIniciaisClasse =
      MotorMulticlasseService.obterProficienciasIniciaisClasseConcedidas(this);

  bool _temProficienciaExtraTexto(String termo) =>
      proficienciasExtras.any((p) => p.toLowerCase().contains(termo));

  bool get temProficienciaMarcial =>
      _proficienciasIniciaisClasse.contains(TipoProficiencia.armasMarciais) ||
      _temProficienciaExtraTexto('marcia');

  bool get temProficienciaSimples =>
      _proficienciasIniciaisClasse.contains(TipoProficiencia.armasSimples) ||
      _temProficienciaExtraTexto('simples');

  bool get temProficienciaArmadurasLeves =>
      _proficienciasIniciaisClasse.contains(TipoProficiencia.armadurasLeves) ||
      _temProficienciaExtraTexto('armaduras leves') ||
      _temProficienciaExtraTexto('armadura leve');

  bool get temProficienciaArmadurasPesadas =>
      _proficienciasIniciaisClasse.contains(
        TipoProficiencia.armadurasPesadas,
      ) ||
      _temProficienciaExtraTexto('armaduras pesadas') ||
      _temProficienciaExtraTexto('armadura pesada');

  bool get temProficienciaEscudos =>
      _proficienciasIniciaisClasse.contains(TipoProficiencia.escudos) ||
      _temProficienciaExtraTexto('escudo');

  bool get ehArcanista => classes.any(
    (c) => c.classeDefinicao.idClasse.toLowerCase() == 'arcanista',
  );

  // --- PATRIMÔNIO EM TIBARES ---
  /// Equivalente total em T$ considerando TC (0,1 T$), T$ (1 T$) e TO (10 T$)
  double get patrimonioTotalTibares =>
      tibares + (tibaresOuro * 10.0) + (tibaresCobre * 0.1);

  // --- CAPACIDADE DE CARGA (TORMENTA 20) ---
  int get limiteCarga =>
      RegrasCargaService.calcularLimiteCarga(getValorFinal('FOR')) +
      MotorModificadoresService.calcularBonusDeclarativoLimiteCarga(this);

  late final int cargaAtual = RegrasCargaService.calcularEspacosOcupados(
    armas: armas,
    itensInventario: itensInventario,
    armadura: armaduraEquipada,
    escudo: escudoEquipado,
    engenhocas: engenhocas,
    itensVestidosExtras: itensVestidosExtras,
  );

  bool get estaSobrecarregado => cargaAtual > limiteCarga;
}
