import 'package:t20_creator/domain/entities/proficiencias.dart';

import '../entities/classe.dart';

class BancoDeClasses {
  static const List<Classe> todas = [
    Classe(
      idClasse: "arcanista",
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
      periciasOpcoes: [
        "CONHECIMENTO",
        "DIPLOMACIA",
        "ENGANACAO",
        "GUERRA",
        "INICIATIVA",
        "INTIMIDACAO",
        "INTUICAO",
        "INVESTIGACAO",
        "NOBREZA",
        "OFICIO",
        "PERCEPCAO",
      ],

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
          descricao:
              "Usa um Foco Mágico (RD 10, PV = metade do seu). Se destruído, fica atordoado (USA INT).",
          temFocoMagico: true,
        ),
        CaminhoDeClasse(
          nome: "Feiticeiro",
          atributoChave: "CAR",
          descricao:
              "Magia inata através de uma Linhagem. Aprende magias em níveis ímpares (USA CAR).",
          temLinhagem: true,
        ),
        CaminhoDeClasse(
          nome: "Mago",
          atributoChave: "INT",
          descricao:
              "Possui um Grimório. Precisa memorizar magias. Começa com 4 magias (USA INT).",
          temGrimorio: true,
        ),
      ],

      habilidadesFixas: {
        "Magias":
            "Você pode lançar magias arcanas. Você conhece e pode lançar magias de acordo com seu nível de Arcanista. Seu atributo-chave define a CD para resistir às suas magias e a quantidade de PM disponíveis.",
        "Poder do Arcanista":
            "A cada nível, você recebe um Poder de Arcanista à sua escolha, desde que cumpra os pré-requisitos. Você só pode escolher cada poder uma vez, a menos que sua descrição diga o contrário.",
        "Alta Arcana":
            "No 20º nível, seu domínio das artes arcanas é absoluto. O custo em PM de suas magias arcanas é reduzido à metade (após aplicar aprimoramentos e outros efeitos que alterem o custo).",
      },
    ),
    Classe(
      idClasse: "barbaro",
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
        TipoProficiencia.escudos,
      ],
      periciasFixas: ['FORTITUDE', 'LUTA'],
      qtdPericiasEscolha: 4,
      periciasOpcoes: [
        'ADESTRAMENTO',
        'ATLETISMO',
        'CAVALGAR',
        'INICIATIVA',
        'INTIMIDACAO',
        'OFICIO',
        'PERCEPCAO',
        'PONTARIA',
        'SOBREVIVENCIA',
        'VONTADE',
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
        "Instinto Selvagem":
            "No 3o nível, você recebe +1 em rolagens de dano, Percepção e Reflexos. A cada seis níveis, esse bônus aumenta em +1.",
        "Redução de Dano":
            "A partir do 5º nível, graças ao seu vigor, você ignora 2 pontos de dano, a cada 3 níveis, sua RD aumenta em 2 até o máximo de 10",
        "Fúria Titânica":
            "No 20º nível, o bônus de sua Fúria aumenta para +6. Além disso, quando entra em fúria você pode dobrar seu tamanho...",
      },
    ),
    Classe(
      idClasse: "bardo",
      nome: 'Bardo',
      pvInicial: 12,
      pvPorNivel: 3,
      pmInicial: 4,
      pmPorNivel: 4,

      descricaoclasse:
          'Bardos são artistas versáteis que usam música, palavras e emoção para '
          'inspirar aliados e manipular o mundo ao seu redor. Mestres da diplomacia e da criatividade, '
          'combinam magia e habilidade social para influenciar batalhas e histórias.',

      caminhoImagem: 'assets/imagens/classes/bardo.png',

      proficiencias: [TipoProficiencia.armasMarciais],

      periciasFixas: ['Atuação', 'Reflexos'],

      periciasOpcoes: [
        'ACROBACIA',
        'CAVALGAR',
        'CONHECIMENTO',
        'DIPLOMACIA',
        'ENGANAÇÃO',
        'FURTIVIDADE',
        'INICIATIVA',
        'INTUIÇÃO',
        'INVESTIGAÇÃO',
        'JOGATINA',
        'LADINAGEM',
        'LUTA',
        'MISTICISMO',
        'NOBREZA',
        'PERCEPÇÃO',
        'PONTARIA',
        'VONTADE',
      ],

      qtdPericiasEscolha: 6,

      habilidadesFixas: {
        'Inspiração':
            'Gaste uma ação padrão e 2 PM para conceder +1 em testes de perícia '
            'a aliados em alcance curto até o fim da cena. A cada 4 níveis, pode gastar +2 PM '
            'para aumentar o bônus em +1.',

        'Magias':
            'Escolha três escolas de magia. Pode lançar magias arcanas dessas escolas. '
            'Começa com 2 magias de 1º círculo e aprende mais ao evoluir. Usa Carisma como atributo-chave.',

        'Eclético':
            'A partir do 2º nível, pode gastar 1 PM para ser considerado treinado '
            'em uma perícia por um teste.',

        'Artista Completo':
            'No nível 20, pode usar Inspiração como ação livre e reduzir '
            'pela metade o custo em PM de suas habilidades.',
      },

      tabelaDeProgressao: {
        1: ['Inspiração +1', 'Magias (1º círculo)'],
        2: ['Poder de Bardo', 'Eclético'],
        3: ['Poder de Bardo'],
        4: ['Poder de Bardo'],
        5: ['Inspiração +2', 'Poder de Bardo'],
        6: ['Magias (2º círculo)', 'Poder de Bardo'],
        7: ['Poder de Bardo'],
        8: ['Poder de Bardo'],
        9: ['Inspiração +3', 'Poder de Bardo'],
        10: ['Magias (3º círculo)', 'Poder de Bardo'],
        11: ['Poder de Bardo'],
        12: ['Poder de Bardo'],
        13: ['Inspiração +4', 'Poder de Bardo'],
        14: ['Magias (4º círculo)', 'Poder de Bardo'],
        15: ['Poder de Bardo'],
        16: ['Poder de Bardo'],
        17: ['Inspiração +5', 'Poder de Bardo'],
        18: ['Poder de Bardo'],
        19: ['Poder de Bardo'],
        20: ['Artista Completo', 'Poder de Bardo'],
      },

      caminhosDisponiveis: [],
    ),
    Classe(
      idClasse: "bucaneiro",
      nome: "Bucaneiro",
      pvInicial: 16,
      pvPorNivel: 4,
      pmInicial: 3,
      pmPorNivel: 3,

      descricaoclasse:
          'Bucaneiros são aventureiros dos mares e rios, mestres em combate, '
          'sobrevivência e navegação. Podem ser piratas, corsários ou marinheiros militares, '
          'vivendo entre a lei e o caos enquanto exploram águas perigosas e enfrentam grandes desafios.',

      proficiencias: [TipoProficiencia.armasMarciais],

      periciasFixas: ['LUTA_OU_PONTARIA', 'REFLEXOS'],

      periciasOpcoes: [
        'ACROBACIA',
        'ATLETISMO',
        'ATUAÇÃO',
        'ENGANAÇÃO',
        'FORTITUDE',
        'FURTIVIDADE',
        'INICIATIVA',
        'INTIMIDAÇÃO',
        'JOGATINA',
        'LUTA',
        'OFÍCIO',
        'PERCEPÇÃO',
        'PILOTAGEM',
        'PONTARIA',
      ],

      qtdPericiasEscolha: 4,

      habilidadesFixas: {
        'Audácia':
            'Pode gastar 2 PM para somar Carisma em um teste de perícia (exceto ataque).',

        'Insolência':
            'Soma Carisma na Defesa (limitado pelo nível). Não funciona com armadura pesada ou imóvel.',

        'Evasão':
            'Se passar em Reflexos para reduzir dano à metade, evita todo o dano. Requer liberdade de movimento.',

        'Esquiva Sagaz':
            '+1 na Defesa e Reflexos (aumenta a cada 4 níveis). Requer liberdade de movimento.',

        'Panache': 'Recupera 1 PM ao fazer crítico ou reduzir inimigo a 0 PV.',

        'Evasão Aprimorada':
            'Com sucesso em Reflexos: zero dano. Falha: metade do dano.',

        'Sorte de Nimb':
            'Pode gastar 5 PM para refazer um teste. Resultado 11+ vira 20 natural.',
      },

      tabelaDeProgressao: {
        1: ['Audácia', 'Insolência'],
        2: ['Evasão', 'Poder de Bucaneiro'],
        3: ['Esquiva Sagaz +1', 'Poder de Bucaneiro'],
        4: ['Poder de Bucaneiro'],
        5: ['Panache', 'Poder de Bucaneiro'],
        6: ['Poder de Bucaneiro'],
        7: ['Esquiva Sagaz +2', 'Poder de Bucaneiro'],
        8: ['Poder de Bucaneiro'],
        9: ['Poder de Bucaneiro'],
        10: ['Evasão Aprimorada', 'Poder de Bucaneiro'],
        11: ['Esquiva Sagaz +3', 'Poder de Bucaneiro'],
        12: ['Poder de Bucaneiro'],
        13: ['Poder de Bucaneiro'],
        14: ['Poder de Bucaneiro'],
        15: ['Esquiva Sagaz +4', 'Poder de Bucaneiro'],
        16: ['Poder de Bucaneiro'],
        17: ['Poder de Bucaneiro'],
        18: ['Poder de Bucaneiro'],
        19: ['Esquiva Sagaz +5', 'Poder de Bucaneiro'],
        20: ['Sorte de Nimb', 'Poder de Bucaneiro'],
      },

      caminhoImagem: 'assets/imagens/classes/bardo.png',
    ),
    Classe(
      idClasse: "caçador",
      nome: "Caçador",
      descricaoclasse:
          'Caçadores são especialistas em sobrevivência e rastreamento, capazes de prosperar nos ambientes mais hostis de Arton.'
          'Mestres dos ermos, conhecem profundamente a natureza, suas criaturas e perigos, sendo capazes de caçar, emboscar e eliminar seus alvos com precisão e paciência.'
          'Seja enfrentando monstros, guiando aliados por territórios selvagens ou perseguindo presas inteligentes como caçadores de recompensa,'
          'o caçador combina habilidade, conhecimento e instinto.'
          'Embora muitos prefiram o isolamento das florestas e montanhas, sua experiência os torna aliados valiosos em qualquer grupo de aventureiros.',

      caminhoImagem: "assets/images/classes/arcanista_image.png",

      pvInicial: 16,
      pvPorNivel: 4,
      pmInicial: 4,
      pmPorNivel: 4,

      proficiencias: [TipoProficiencia.armasMarciais, TipoProficiencia.escudos],

      periciasFixas: ['LUTA_OU_PONTARIA', 'SOBREVIVÊNCIA'],

      qtdPericiasEscolha: 6,

      periciasOpcoes: [
        'ADESTRAMENTO',
        'ATLETISMO',
        'CAVALGAR',
        'CURA',
        'FORTITUDE',
        'FURTIVIDADE',
        'INICIATIVA',
        'INVESTIGAÇÃO',
        'LUTA',
        'OFICIO',
        'PERCEPÇÃO',
        'PONTARIA',
        'REFLEXOS',
      ],

      tabelaDeProgressao: {
        1: ['Marca da Presa +1d4', 'Rastreador'],
        2: ['Poder de Caçador'],
        3: ['Explorador', 'Poder de Caçador'],
        4: ['Poder de Caçador'],
        5: ['Caminho do Explorador', 'Marca da Presa +1d8', 'Poder de Caçador'],
        6: ['Poder de Caçador'],
        7: ['Explorador', 'Poder de Caçador'],
        8: ['Poder de Caçador'],
        9: ['Marca da Presa +1d12', 'Poder de Caçador'],
        10: ['Poder de Caçador'],
        11: ['Explorador', 'Poder de Caçador'],
        12: ['Poder de Caçador'],
        13: ['Marca da Presa +2d8', 'Poder de Caçador'],
        14: ['Poder de Caçador'],
        15: ['Explorador', 'Poder de Caçador'],
        16: ['Poder de Caçador'],
        17: ['Marca da Presa +2d10', 'Poder de Caçador'],
        18: ['Poder de Caçador'],
        19: ['Explorador', 'Poder de Caçador'],
        20: ['Mestre Caçador', 'Poder de Caçador'],
      },

      habilidadesFixas: {
        'Marca da Presa':
            'Pode gastar 1 PM e uma ação de movimento para marcar uma criatura em alcance curto. '
            'Recebe +1d4 no dano contra ela até o fim da cena. A cada 4 níveis, pode gastar +1 PM '
            'para aumentar o dano (conforme progressão da classe).',

        'Rastreador':
            '+2 em Sobrevivência e pode se mover normalmente ao rastrear sem penalidade.',

        'Explorador':
            'Escolhe um tipo de terreno. Nesse terreno, soma Sabedoria (mínimo +1) na Defesa e em '
            'Acrobacia, Atletismo, Furtividade, Percepção e Sobrevivência. Pode expandir ou melhorar com níveis.',

        'Caminho do Explorador':
            'Ignora terreno difícil e recebe +10 na CD para ser rastreado em terrenos onde possui Explorador.',

        'Mestre Caçador':
            'Pode usar Marca da Presa como ação livre. Pode gastar 5 PM para +2 na margem de ameaça. '
            'Ao derrotar a presa marcada, recupera 5 PM.',
      },
    ),
    // Futuramente adicionaremos BARDO, guerreiro, etc aqui.
  ];
}
