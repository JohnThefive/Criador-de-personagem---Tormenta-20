import '../entities/classe.dart';

class BancoDeClasses {
  static const List<Classe> todas = [
    Classe(
      nome: "Arcanista",
      descricaoclasse: """
      Arte feita por Odmir Fortes 

      A magia é a força mais poderosa e misteriosa de Arton, presente em maravilhas, criaturas e artefatos lendários.
      O arcanista é seu maior estudioso, capaz de dobrar a realidade por meio de dedicação e conhecimento.
      Esse poder pode gerar arrogância, humildade ou até loucura diante dos segredos do universo.
      Frágeis no início, tornam-se líderes formidáveis à medida que dominam rituais, objetos místicos ou poderes inatos.
      """,
      caminhoImagem: "assets/images/classes/arcanista_image.png",
      pvInicial: 8,
      pvPorNivel: 2,
      pmInicial: 6,
      pmPorNivel: 6,
      proficiencias: [], // Nenhuma proficiência concedida
      periciasFixas: ["MISTICISMO", "VONTADE"],
      qtdPericiasEscolha: 2,
      periciasOpcoes: ["CONHECIMENTO","DIPLOMACIA", "ENGANACAO", "GUERRA", "INICIATIVA", "INTIMIDACAO", "INTUICAO", "INVESTIGACAO", "NOBREZA", "OFICIO","PERCEPCAO"],

      tabelaDeProgressao: {
        1: ["Escolha do Caminho", "Magias de 1º Círculo"],
        2: ["Poder de Arcanista"],
        3: ["Poder de Arcanista"],
        4: ["Poder de Arcanista"],
        5: ["Poder de Arcanista", "Magias de 2º Círculo"],
        6: ["Poder de Arcanista"],
        7: ["Poder de Arcanista"],
        8: ["Poder de Arcanista"],
        9: ["Poder de Arcanista", "Magias de 3º Círculo"],
        10: ["Poder de Arcanista"],
        11: ["Poder de Arcanista"],
        12: ["Poder de Arcanista"],
        13: ["Poder de Arcanista", "Magias de 4º Círculo"],
        14: ["Poder de Arcanista"],
        15: ["Poder de Arcanista"],
        16: ["Poder de Arcanista"],
        17: ["Poder de Arcanista", "Magias de 5º Círculo"],
        18: ["Poder de Arcanista"],
        19: ["Poder de Arcanista"],
        20: ["Poder de Arcanista", "Alta Arcana"],
      },
      caminhosDisponiveis: [
        CaminhoDeClasse(
          nome: "Bruxo",
          atributoChave: "INT",
          descricao: "Usa um Foco Mágico (RD 10, PV = metade do seu). Se destruído, fica atordoado.",
          temFocoMagico: true,
        ),
        CaminhoDeClasse(
          nome: "Feiticeiro",
          atributoChave: "CAR",
          descricao: "Magia inata através de uma Linhagem. Aprende magias em níveis ímpares.",
          temLinhagem: true,
        ),
        CaminhoDeClasse(
          nome: "Mago",
          atributoChave: "INT",
          descricao: "Possui um Grimório. Precisa memorizar magias. Começa com 4 magias.",
          temGrimorio: true,
        ),

      ],
    ),
    // Futuramente adicionaremos Guerreiro, Bárbaro, etc aqui.
  ];
}