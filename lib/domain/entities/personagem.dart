import 'package:t20_creator/domain/entities/poder.dart';

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

  // Campos referentes a origem
  final Origem? origem;
  final List<Poder> poderesGerais; // Armazena poderes de origem / gerais
  final List<String> itensInventario; // Recebe os itens gratuitos da origem

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

  Personagem({
    required this.nome,
    required this.atributos,
    this.raca,
    this.classes = const [],
    this.periciasTreinadas = const [],
    // Campos referentes a origem
    this.origem,
    this.poderesGerais = const [],
    this.itensInventario = const [],
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
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

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
      divindade: null,
      poderConcedido: null,
      idade: 20,
      alinhamento: 'Neutro',
      descricaoAparencia: '',
      caminhoFoto: null,
      tamanho: 'Médio',
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
    // Campos referentes a origem
    Origem? origem,
    List<Poder>? poderesGerais,
    List<String>? itensInventario,
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
      divindade: anularDivindade ? null : (divindade ?? this.divindade),
      poderConcedido: anularDivindade
          ? null
          : (poderConcedido ?? this.poderConcedido),
      idade: idade ?? this.idade,
      alinhamento: alinhamento ?? this.alinhamento,
      descricaoAparencia: descricaoAparencia ?? this.descricaoAparencia,
      caminhoFoto: anularFoto ? null : (caminhoFoto ?? this.caminhoFoto),
      tamanho: tamanho ?? this.tamanho,
    );
  }

  // Este método calcula o valor final para exibir na tela (Base + Raça Fixa + Raça Variável)
  int getValorFinal(String sigla, {List<String> bonusVariaveis = const []}) {
    int base = atributos[sigla]?.valor ?? 0;
    int bonusFixo = raca?.modificadores[sigla] ?? 0;
    int bonusVariavel = bonusVariaveis.contains(sigla) ? 1 : 0;
    return base + bonusFixo + bonusVariavel;
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

  // --- CÁLCULO DE DEFESA BÁSICA ---
  int get defesaBase {
    final modDes = getValorFinal('DES');
    return 10 + modDes;
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
  int getValorPericia(String periciaKey, {int penalidadeArmaduraAtual = 0}) {
    final pericia = BancoDePericias.getByKey(periciaKey);

    int metadeNivel = (nivelPersonagem / 2).floor();
    int modAtributo = getValorFinal(pericia.atributoChave);

    bool ehTreinada = periciasTreinadas.contains(periciaKey);
    int bonusTreino = ehTreinada ? bonusTreinamento : 0;

    int penalidade = 0;
    if (pericia.penalidadeArmadura) {
      penalidade = penalidadeArmaduraAtual;
    }

    return metadeNivel + modAtributo + bonusTreino - penalidade;
  }
}
