import 'package:t20_creator/domain/entities/proficiencias.dart';

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
          descricao: "Usa um Foco Mágico (RD 10, PV = metade do seu). Se destruído, fica atordoado (USA INT).",
          temFocoMagico: true,
        ),
        CaminhoDeClasse(
          nome: "Feiticeiro",
          atributoChave: "CAR",
          descricao: "Magia inata através de uma Linhagem. Aprende magias em níveis ímpares (USA CAR).",
          temLinhagem: true,
        ),
        CaminhoDeClasse(
          nome: "Mago",
          atributoChave: "INT",
          descricao: "Possui um Grimório. Precisa memorizar magias. Começa com 4 magias (USA INT).",
          temGrimorio: true,
        ),
      ],

    habilidadesFixas: {
  "Magias": "Você pode lançar magias arcanas. Você conhece e pode lançar magias de acordo com seu nível de Arcanista. Seu atributo-chave define a CD para resistir às suas magias e a quantidade de PM disponíveis.",
  "Poder do Arcanista": "A cada nível, você recebe um Poder de Arcanista à sua escolha, desde que cumpra os pré-requisitos. Você só pode escolher cada poder uma vez, a menos que sua descrição diga o contrário.",
  "Alta Arcana": "No 20º nível, seu domínio das artes arcanas é absoluto. O custo em PM de suas magias arcanas é reduzido à metade (após aplicar aprimoramentos e outros efeitos que alterem o custo)."
   },

   poderesDaClasse: {
  "Arcano de Batalha": "Quando lança uma magia que cause dano, você soma seu atributo-chave na rolagem de dano.",
  "Aumento de Atributo": "Você recebe +1 em um atributo. Pode escolher este poder várias vezes, mas apenas uma vez por patamar para o mesmo atributo.",
  "Caldeirão do Bruxo": "Você pode criar poções como se tivesse o poder geral Preparar Poção. Se já o tiver, pode criar poções de até 5º círculo. Pré-requisitos: Bruxo, treinado em Ofício (alquimista).",
  "Conhecimento Mágico": "Você aprende duas magias de qualquer círculo que possa lançar. Pode escolher este poder várias vezes.",
  "Contramágica Aprimorada": "Uma vez por rodada, você pode fazer uma contramágica como reação. Pré-requisito: Dissipar Magia.",
  "Envolto em Mistério": "Você recebe +5 em Enganação e Intimidação contra pessoas ignorantes ou supersticiosas, conforme definido pelo mestre.",
  "Escriba Arcano": "Você pode aprender magias copiando pergaminhos ou grimórios. O custo é um dia de trabalho e T250 por PM da magia. Pré-requisitos: Mago, treinado em Ofício (escriba).",
  "Especialista em Escola": "Escolha uma escola de magia. A CD para resistir às suas magias dessa escola aumenta em +2. Pré-requisito: Bruxo ou Mago.",
  "Familiar": "Você possui um animal mágico que o auxilia. Ele concede benefícios conforme regras específicas de Familiar.",
  "Fluxo de Mana": "Você pode manter dois efeitos sustentados ativos simultaneamente com uma única ação livre, pagando seus custos normalmente. Pré-requisito: 10º nível de Arcanista.",
  "Foco Vital": "Se estiver segurando seu foco mágico e sofrer dano que o levaria a 0 PV ou menos, você fica com 1 PV e o foco perde PV igual ao excedente. Se o foco for destruído, você sofre o dano restante. Pré-requisito: Bruxo.",
  "Fortalecimento Arcano": "A CD para resistir às suas magias aumenta em +1. Se puder lançar magias de 4º círculo, aumenta em +2. Pré-requisito: 5º nível de Arcanista.",
  "Herança Aprimorada": "Você recebe a herança aprimorada de sua linhagem sobrenatural. Pré-requisitos: Feiticeiro, 6º nível de Arcanista.",
  "Herança Superior": "Você recebe a herança superior de sua linhagem sobrenatural. Pré-requisitos: Herança Aprimorada, 11º nível de Arcanista.",
  "Magia Pungente": "Ao lançar uma magia, você pode pagar 1 PM para aumentar em +2 a CD para resistir a ela.",
  "Mestre em Escola": "Escolha uma escola de magia. O custo para lançar magias dessa escola diminui em –1 PM. Pré-requisitos: Especialista em Escola (mesma escola), 8º nível de Arcanista.",
  "Poder Mágico": "Você recebe +1 PM por nível de Arcanista. Se escolher este poder no 4º nível, recebe 4 PM adicionais. Ao subir de nível, recebe +1 PM adicional por nível.",
  "Raio Arcano": "Você pode gastar uma ação padrão para causar 1d8 de dano de essência em alcance curto. O dano aumenta em +1d8 por círculo acima do 1º que puder lançar. Reflexos (CD atributo-chave) reduz à metade. Conta como magia.",
  "Raio Elemental": "Ao usar Raio Arcano, pode pagar 1 PM para causar dano elemental (ácido, eletricidade, fogo, frio ou trevas). Se o alvo falhar no teste, sofre condição adicional conforme o elemento. Pré-requisito: Raio Arcano.",
  "Raio Poderoso": "O dano do Raio Arcano aumenta para d12 e seu alcance passa a médio. Pré-requisito: Raio Arcano.",
  "Tinta do Mago": "Você pode criar pergaminhos como se tivesse Escrever Pergaminho. Se já o tiver, o custo é reduzido à metade. Pré-requisitos: Mago, treinado em Ofício (escriba)."
}
    ),
    Classe(
      nome: "Bárbaro",
      descricaoclasse: """
      Arte feita por: Vitor Ervilha magallhães
      
      Um combatente primitivo, que usa fúria e instintos para destruir seus inimigos.""",
      caminhoImagem: "assets/images/classes/barbaro.png",
      pvInicial: 24,
      pvPorNivel: 6,
      pmInicial: 3,
      pmPorNivel: 3,
      // Proficiências: Incluí armas simples e armaduras leves, que são padrão para marciais no T20, além das citadas
      proficiencias: [
        TipoProficiencia.armasSimples, 
        TipoProficiencia.armasMarciais, 
        TipoProficiencia.armadurasLeves, 
        TipoProficiencia.escudos
      ], 
      periciasFixas: ['FORTITUDE', 'LUTA'],
      qtdPericiasEscolha: 4,
      periciasOpcoes: [
        'ADESTRAMENTO', 'ATLETISMO', 'CAVALGAR', 'INICIATIVA', 
        'INTIMIDACAO', 'OFICIO', 'PERCEPCAO', 'PONTARIA', 
        'SOBREVIVENCIA', 'VONTADE'
      ],
      caminhosDisponiveis: [], // Bárbaro não escolhe caminho no Nível 1
      tabelaDeProgressao: {
        1: ["Fúria +2"],
        2: ["Poder de Bárbaro"],
        3: ["Instinto Selvagem +1", "Poder de Bárbaro"],
        4: ["Poder de Bárbaro"],
        5: ["Poder de Bárbaro", "Redução de Dano 2"],
        6: ["Fúria +3", "Poder de Bárbaro"],
        7: ["Poder de Bárbaro"],
        8: ["Poder de Bárbaro", "Redução de Dano 4"],
        9: ["Instinto Selvagem +2", "Poder de Bárbaro"],
        10: ["Poder de Bárbaro"],
        11: ["Fúria +4", "Poder de Bárbaro", "Redução de Dano 6"],
        12: ["Poder de Bárbaro"],
        13: ["Poder de Bárbaro"],
        14: ["Poder de Bárbaro", "Redução de Dano 8"],
        15: ["Instinto Selvagem +3", "Poder de Bárbaro"],
        16: ["Fúria +5", "Poder de Bárbaro"],
        17: ["Poder de Bárbaro", "Redução de Dano 10"],
        18: ["Poder de Bárbaro"],
        19: ["Poder de Bárbaro"],
        20: ["Fúria Titânica", "Poder de Bárbaro"],
      },
      habilidadesFixas: {
        "Fúria": "Você pode gastar 2 PM para invocar uma fúria selvagem...",
        "Instinto Selvagem": "No 3o nível, você recebe +1 em rolagens de dano, Percepção e Reflexos. A cada seis níveis, esse bônus aumenta em +1.",
        "Redução de Dano": "A partir do 5º nível, graças ao seu vigor, você ignora 2 pontos de dano, a cada 3 níveis, sua RD aumenta em 2 até o máximo de 10",
        "Fúria Titânica": "No 20º nível, o bônus de sua Fúria aumenta para +6. Além disso, quando entra em fúria você pode dobrar seu tamanho...",
      },
      poderesDaClasse: {
        "Alma de Bronze": "Quando entra em fúria, você recebe uma quantidade de pontos de vida temporários igual a metade do seu nível + mod. Força.",
        "Aumento de Atributo": "Você recebe +2 em um atributo a sua escolha...",
        "Brado Assustador": "Você pode gastar uma ação de movimento e 1 PM para soltar um berro feroz. Inimigos devem fazer teste de Vontade...",
        "Crítico Brutal": "Seu multiplicador de crítico com ataques corpo a corpo aumenta em +1.",
        "Destruidor": "Quando causa dano com arma de duas mãos, pode rolar novamente resultados 1 ou 2.",
        "Espírito Inquebrável": "Enquanto está em fúria, você não fica inconsciente por estar com 0 ou menos PV.",
        "Golpe Poderoso": "Você pode gastar 1 PM  para causar um dado extra de dano do mesmo tipo (Golpe corpo a corpo ou aremesso)" ,
        "Ímpeto": "Você pode gastar 1 pm para Aumentar seu deslocamento em 6m+ por rodada" ,
        "Investida Imprudente": "aumenta sua penalidade na Defesa pela investida para –5 para receber um bônus de +1d12 na rolagem de dano deste ataque.",
        "Pele de Aço": "O bônus de Pele de Ferro aumenta para +8. Pré-requisitos: Pele de Ferro, 8o nível de bárbaro.",
        "Sangue dos Inimigos": "em fúria, quando faz um acerto crítico ou Mata um inimigo, você recebe um bônus cumulativo de +1 em testes de ataque e rolagens de dano, limitado pelo seu nível, até o fim da cena.",
        "Superstição": "Você odeia magia, o que faz com que seja mais resistente a ela. Você recebe resistência a magia +5",
        "Totem Espiritual": "Você soma sua Sabedoria no seu total de pontos de mana. Escolha um animal totémico e Você aprende e pode lançar uma magia definida pelo animal escolhido (atributo-chave Sabedoria) e pode lançá-la mesmo em fúria. Pré-requisitos: Sab 1, 4o nível de bárbaro.",
        "Vigor Primal":"Você pode gastar uma ação de movimento e uma quantidade de PM limitada por sua Constituição. Para cada PM que gastar, você recupera 1d12 pontos de vida.",
        "Esquiva Sobrenatural": "Seus instintos ficam tão apurados que você nunca fica surpreendido.",
        "Força Indomável.": "Gasta 1 PM para somar seu nível em um teste de Força ou Atletismo. Você pode usar esta habilidade depois de rolar o dado, mas deve usá-la antes de o mestre dizer se você passou ou não.",
        "Frenesi": "Se estiver em fúria e usar a ação atacar para fazer um ataque corpo a corpo, você pode gastar 2 PM para fazer um ataque adicional.",
        "Fúria da Savana": "Seu deslocamento aumenta em +3m. Quando usa Fúria, você aplica o bônus em ataque e dano também a armas de arremesso.",
        "Fúria Raivosa": "e sua Fúria for terminar por você não ter atacado nem sido alvo de um efeito hostil, você pode pagar 1 PM para continuar em fúria nesta rodada. Se você atacar ou for atacado na rodada seguinte, sua fúria continua normalmente."
      },
    ),
    // Futuramente adicionaremos BARDO, guerreiro, etc aqui.
  ];
}