import '../entities/raca.dart';

class BancoDeRacas {
  static const List<Raca> todas = [
    // --- raças que possuem adição de modificador fixo ---
    Raca(
      nome: "Anão",
      descricaoRaca: "Anões são seres atarracados, robustos e teimosos, forjados pelas montanhas e pelas duras tradições de seus clãs.",
      imagemRaca: "assets/images/racas/anao.png", 
      modificadores: {'CON': 2, 'SAB': 1, 'DES': -1},
      habilidadesRaca: {
        "Conhecimento das Rochas": "Você recebe +2 em testes de Percepção e Sobrevivência realizados no subsolo.",
        "Devagar e Sempre": "Seu deslocamento é 6m (em vez de 9m). Porém, ele nunca é reduzido por uso de armadura ou excesso de carga.",
        "Duro na Queda": "Você recebe +3 pontos de vida iniciais e +1 PV por nível.",
        "Herança": "Você recebe a proficiência com uma arma marcial ou exótica a sua escolha que seja machado ou martelo.",
        "Tradição de Heredrimm": "Todas os machados, picaretas, martelos e marretas são armas simples e você recebe +2 em ataques com essas armas"
      },
    ),
     Raca(
       nome: "Dahllan",
       descricaoRaca: "Dahllan são mulheres nascidas da essência da natureza, com seiva correndo nas veias. Ligadas à deusa Allihanna, possuem forte conexão com plantas e animais, sendo ágeis, sábias e capazes de transformar o próprio corpo em madeira viva para se proteger.",
       imagemRaca: "assets/images/racas/dahllan.png",
       modificadores: {'SAB': 2, 'DES': 1, 'INT': -1},
       habilidadesRaca: {
           "Amiga das Plantas": "Você pode lançar a magia Controlar Plantas (atributo chave: SAB). Caso aprenda novamente essa magia, seu custo diminui em –1 PM.",
           "Armadura de Allihanna": "Você pode gastar uma ação de movimento e 1 PM para transformar sua pele em casca de árvore, recebendo +2 na Defesa até o fim da cena.",
           "Empatia Selvagem": "Você pode se comunicar com animais por meio de linguagem corporal e vocalizações. Pode usar Adestramento para mudar atitude ou persuadir animais como se fosse Diplomacia."
     }, 
   ),
    Raca(
      nome: "Elfo",
      descricaoRaca: "Elfos são seres belos, esguios e naturalmente mágicos, vindos de um antigo reino perdido chamado Lenórienn. Mestres das artes, da magia e da guerra, possuem sentidos aguçados e uma graça sobrenatural. Após a queda de sua pátria e de sua antiga deusa, os elfos agora buscam um novo futuro em Arton.",
      imagemRaca: "assets/images/racas/elfo.png",
      modificadores: {'INT': 2, 'DES': 1, 'CON': -1},
      habilidadesRaca: {
        "Graça de Glórienn": "Seu deslocamento é 12m em vez de 9m.",
        "Sangue Mágico": "Você recebe +1 ponto de mana por nível.",
        "Sentidos Élficos": "Você possui visão na penumbra e recebe +2 em testes de Misticismo e Percepção."
    },
  ),
    Raca(
  nome: "Goblin",
  descricaoRaca: "Goblins são pequenos, ágeis e extremamente inventivos. Vivendo nas frestas do mundo civilizado, sobrevivem graças à criatividade, improviso e engenhocas malucas que desafiam a lógica. Muitas vezes subestimados, são especialistas em se virar com qualquer coisa e transformar sucata em ferramentas, armas ou máquinas perigosamente funcionais.",
  imagemRaca: "assets/images/racas/goblin.png",
  modificadores: {'DES': 2, 'INT': 1, 'CAR': -1},
  habilidadesRaca: {
    "Engenhoso": "Você não sofre penalidades em testes de perícia por não usar ferramentas. Se usar a ferramenta necessária, recebe +2 no teste de perícia.",
    "Espelunqueiro": "Você recebe visão no escuro e deslocamento de escalada igual ao seu deslocamento terrestre.",
    "Peste Esguia": "Seu tamanho é Pequeno, mas seu deslocamento permanece 9m.",
    "Rato das Ruas": "Você recebe +2 em Fortitude e sua recuperação de PV e PM nunca é inferior ao seu nível."
  },
),
    Raca(
  nome: "Minotauro",
  descricaoRaca: "Minotauros são guerreiros orgulhosos e disciplinados, descendentes do antigo Império de Tauron. Fortes e resistentes, possuem chifres imponentes e uma presença intimidadora. Mesmo após a morte de seu deus e a queda de seu império, continuam lutando para provar sua força e encontrar um novo lugar em Arton.",
  imagemRaca: "assets/images/racas/minotauro.png",
  modificadores: {'FOR': 2, 'CON': 1, 'SAB': -1},
  habilidadesRaca: {
    "Chifres": "Você possui uma arma natural de chifres (dano 1d6, crítico x2, perfuração). Uma vez por rodada, quando usa a ação agredir para atacar com outra arma, pode gastar 1 PM para fazer um ataque corpo a corpo extra com os chifres.",
    "Medo de altura": "Se estiver adjacente a uma queda de 3m ou mais de altura (como um buraco ou penhasco), você fica abalado.",
    "Couro Rígido": "Sua pele é dura como a de um touro. Você recebe +1 na Defesa.",
    "Faro": "Você tem olfato apurado. Contra inimigos em alcance curto que não possa ver, você não fica desprevenido e camuflagem total lhe causa apenas 20% de chance de falha."
  },
),
    Raca(
  nome: "Qareen",
  descricaoRaca: "Qareen são descendentes de gênios e abençoados pela deusa da magia, Wynna. Carismáticos e generosos, possuem tatuagens místicas chamadas marcas de Wynna que brilham quando usam magia. Para eles, lançar feitiços e realizar pequenos desejos é algo natural, e sua magia se torna ainda mais poderosa quando usada para ajudar outras pessoas.",
  imagemRaca: "assets/images/racas/qareen.png",
  modificadores: {'CAR': 2, 'INT': 1, 'SAB': -1},
  habilidadesRaca: {
    "Desejos": "Se lançar uma magia que alguém tenha pedido desde seu último turno, o custo da magia diminui em –1 PM. Fazer um desejo ao qareen é uma ação livre.",
    "Resistência Elemental": "Conforme sua ascendência, você recebe redução 10 a um tipo de dano. Escolha uma: frio (água), eletricidade (ar), fogo (fogo), ácido (terra), luz (luz) ou trevas (trevas).",
    "Tatuagem Mística": "Você pode lançar uma magia de 1º círculo a sua escolha (atributo chave: CAR). Caso aprenda novamente essa magia, seu custo diminui em –1 PM."
  },
),
    Raca(
  nome: "Golem",
  descricaoRaca: "Golens são construtos artificiais criados por mortais, animados por espíritos elementais aprisionados em corpos de pedra, metal ou outros materiais. Embora muitos sejam feitos para servir como trabalhadores ou soldados, alguns desenvolvem personalidade, inteligência e vontade própria, aventurando-se pelo mundo em busca de propósito.",
  imagemRaca: "assets/images/racas/golem.png",
  modificadores: {'FOR': 2, 'CON': 1, 'CAR': -1},
  habilidadesRaca: {
    "Chassi": "Seu corpo artificial é resistente, mas rígido. Seu deslocamento é 6m, mas não é reduzido por uso de armadura ou excesso de carga. Você recebe +2 na Defesa, mas possui penalidade de armadura –2. Você leva um dia para vestir ou remover uma armadura, pois precisa acoplar suas peças ao chassi. A armadura não conta no limite de itens vestidos.",
    "Criatura Artificial": "Você é do tipo construto. Recebe visão no escuro e imunidade a efeitos de cansaço, metabólicos e de veneno. Não precisa respirar, comer ou dormir, mas também não se beneficia de cura mundana ou itens de alimentação. Precisa permanecer inerte por 8 horas por dia para recarregar sua energia e recuperar PV e PM. A perícia Cura não funciona em você, mas Ofício (artesão) pode ser usada no lugar dela.",
    "Fonte Elemental": "Escolha entre água (frio), ar (eletricidade), fogo (fogo) e terra (ácido). Você é imune a dano desse tipo e se sofrer dano magico desse tipo, é curado PV igual a metade do dano",
    "Propósito de criação":"Você não tem direito a escolher uma origem, mas recebe um poder geral a sua escolha." 
  },
),
    Raca(
  nome: "Hynne",
  descricaoRaca: "Hynne, também conhecidos como halflings ou 'pequeninos', são amantes de boa comida, casas confortáveis e vida tranquila. Apesar disso, quando se aventuram pelo mundo, usam sua agilidade, sorte e carisma para superar perigos. Pequenos e astutos, tornaram-se mercadores habilidosos e especialistas em se virar em situações difíceis.",
  imagemRaca: "assets/images/racas/hynne.png",
  modificadores: {'DES': 2, 'CAR': 1, 'FOR': -1},
  habilidadesRaca: {
    "Arremessador": "Quando faz um ataque à distância com uma funda ou uma arma de arremesso, seu dano aumenta em um passo.",
    "Pequeno e Rechonchudo": "Seu tamanho é Pequeno e seu deslocamento é 6m. Você recebe +2 em Enganação e pode usar Destreza como atributo-chave de Atletismo em vez de Força.",
    "Sorte Salvadora": "Quando faz um teste de resistência, você pode gastar 1 PM para rolar este teste novamente."
  },
),
    Raca(
      nome: "Kliren",
      descricaoRaca: "Uma combinação entre humanos e gnomos, os kliren somam a alta inteligência gnômica e a curiosidade humana, resultando em seres de extrema engenhosidade, criatividade e talento com aparatos mecânicos.",
      imagemRaca:"assets/images/racas/hynne.png",
      modificadores: {'INT': 2, 'CAR': 1, 'FOR': -1},
      habilidadesRaca: {
        "Ossos Frágeis":"Você sofre 1 ponto de dano adicional por dado de dano de impacto.",
        "Vanguardista": "ocê recebe proficiência em armas de fogo e +2 em Ofício (um qualquer, a sua escolha).",
        "Engenhesidade":"Quando faz um teste de perícia, você pode gastar 2 PM para somar sua Inteligência no teste. Você não pode usar esta habilidade em testes de ataque. Caso receba esta habilidade novamente, seu custo é reduzido em –1 PM.",
        "Híbrido": "ua natureza multifacetada fez com que você aprendesse conhecimentos variados. Você se torna treinado em uma perícia a sua escolha (não precisa ser da sua classe)."
  },
    ),
    Raca(
  nome: "Medusa",
  descricaoRaca: "Criaturas reclusas famosas por transformar vítimas em pedra com o olhar, embora apenas as mais antigas e poderosas consigam fazê-lo. Medusas jovens às vezes rejeitam a solidão e crueldade de sua raça, aventurando-se pelo Reinado, fazendo amigos ou integrando grupos de heróis. Quando escondem seus cabelos de serpentes, conseguem se passar por mulheres humanas. Curiosamente, os anões não temem as medusas e frequentemente as consideram belas musas.",
  imagemRaca: "assets/images/racas/medusa.png",
  modificadores: {'DES': 2, 'CAR': 1},
  habilidadesRaca: {
    "Cria de Megalokk": "Você é uma criatura do tipo monstro e recebe visão no escuro.",
    "Natureza Venenosa": "Você recebe resistência a veneno +5 e pode gastar uma ação de movimento e 1 PM para envenenar uma arma que esteja usando. A arma causa perda de 1d12 pontos de vida. O veneno dura até você acertar um ataque ou até o fim da cena (o que acontecer primeiro).",
    "Olhar Atordoante": "Você pode gastar uma ação de movimento e 1 PM para forçar uma criatura em alcance curto a fazer um teste de Fortitude (CD Car). Se a criatura falhar, fica atordoada por uma rodada (apenas uma vez por cena)."
  },
),

    Raca(
  nome: "Sílfide",
  descricaoRaca: "As mais numerosas fadas de Arton, as sílfides são pequenas criaturas aladas com delicadas asas de inseto e grandes olhos escuros. Curiosas, brincalhonas e sempre em busca de diversão, costumam usar magias e ilusões para pregar peças. Apesar de parecerem inocentes e despreocupadas, sua natureza mágica e ligação com o mundo feérico podem torná-las aliadas surpreendentes em uma aventura.",
  imagemRaca: "assets/images/racas/silfide.png",
  modificadores: {'CAR': 2, 'DES': 1, 'FOR': -2},
  habilidadesRaca: {
    "Asas de Borboleta": "Seu tamanho é Minúsculo. Você pode pairar a 1,5m do chão com deslocamento de 9m, ignorando terreno difícil e sendo imune a dano por queda (a menos que esteja inconsciente). Você pode gastar 1 PM por rodada para voar com deslocamento de 12m.",
    "Espírito da Natureza": "Você é uma criatura do tipo espírito, recebe visão na penumbra e pode falar com animais livremente.",
    "Magia das Fadas": "Você pode lançar duas das seguintes magias (atributo-chave Carisma): Criar Ilusão, Enfeitiçar, Luz (como magia arcana) e Sono. Caso aprenda novamente uma dessas magias, seu custo diminui em –1 PM."
  },
),

    Raca(
  nome: "Suraggel (Aggelus)",
  descricaoRaca: "Descendentes de extraplanares divinos ligados à luz, os aggelus exibem traços angelicais e uma presença serena. Embora sejam associados à bondade e à ordem celestial, ainda possuem livre-arbítrio e podem trilhar caminhos inesperados. Sua natureza reflete a herança divina, aproximando-os dos habitantes dos Mundos dos Deuses.",
  imagemRaca: "assets/images/racas/suraggel_aggelus.png",
  modificadores: {'SAB': 2, 'CAR': 1},
  habilidadesRaca: {
    "Herança Divina": "Você é uma criatura do tipo espírito e recebe visão no escuro.",
    "Luz Sagrada": "Você recebe +2 em Diplomacia e Intuição. Além disso, pode lançar Luz (como uma magia divina; atributo-chave Carisma). Caso aprenda novamente essa magia, seu custo diminui em –1 PM."
  },
),

    Raca(
  nome: "Suraggel (Sulfure)",
  descricaoRaca: "Descendentes de extraplanares ligados às trevas abissais, os sulfure apresentam traços demoníacos ou sombrios. Apesar de sua origem associada ao caos e à escuridão, ainda possuem vontade própria e podem surpreender com suas escolhas. Muitos exibem uma natureza astuta, manipuladora ou furtiva.",
  imagemRaca: "assets/images/racas/suraggel_sulfure.png",
  modificadores: {'DES': 2, 'INT': 1},
  habilidadesRaca: {
    "Herança Divina": "Você é uma criatura do tipo espírito e recebe visão no escuro.",
    "Sombras Profanas": "Você recebe +2 em Enganação e Furtividade. Além disso, pode lançar Escuridão (como uma magia divina; atributo-chave Inteligência). Caso aprenda novamente essa magia, seu custo diminui em –1 PM."
  },
),

    Raca(
  nome: "Trog",
  descricaoRaca: "Trogloditas, ou 'trogs', são homens-lagarto primitivos que vivem no subterrâneo e tradicionalmente odeiam outras raças — especialmente aquelas capazes de forjar aço, algo que cobiçam intensamente. Suas tribos costumam emboscar viajantes e atacar povoados, mas alguns poucos rejeitam essa natureza cruel. Esses indivíduos deixam suas tribos e seguem caminhos inesperados, tornando-se aventureiros, druidas, clérigos ou qualquer outro destino que encontrem fora das cavernas.",
  imagemRaca: "assets/images/racas/trog.png",
  modificadores: {'CON': 2, 'FOR': 1, 'INT': -1},
  habilidadesRaca: {
    "Mau Cheiro": "Você pode gastar uma ação padrão e 2 PM para expelir um gás fétido. Todas as criaturas (exceto trogs) em alcance curto devem passar em um teste de Fortitude contra veneno (CD Con) ou ficam enjoadas durante 1d6 rodadas. Uma criatura que passe no teste fica imune a esta habilidade por um dia.",
    "Mordida": "Você possui uma arma natural de mordida (dano 1d6, crítico x2, perfuração). Uma vez por rodada, quando usa a ação agredir para atacar com outra arma, pode gastar 1 PM para fazer um ataque corpo a corpo extra com a mordida.",
    "Reptiliano": "Você é uma criatura do tipo monstro e recebe visão no escuro, +1 na Defesa e, se estiver sem armadura ou roupas pesadas, +5 em Furtividade.",
    "Sangue Frio": "Você sofre 1 ponto de dano adicional por dado de dano de frio."
  },
),

    // --- RAÇAS FLEXÍVEIS (Humano, Lefou, etc) ---
    // *Nota: Para hoje, vamos deixá-las na lista, mas elas precisam 
    // de uma UI extra para escolher onde vai o +1. Deixei vazio por enquanto.*
    Raca(
  nome: "Humano",
  descricaoRaca: "O povo mais numeroso de Arton, humanos são considerados os escolhidos dos deuses. Ambiciosos, adaptáveis e curiosos, espalham-se por todo o continente — dos vales férteis do Reinado às areias do Deserto da Perdição. Filhos de Valkaria, Deusa da Ambição, são exploradores e desbravadores incansáveis, sempre buscando algo além. Sua enorme diversidade cultural, física e de ideias faz com que humanos possam se destacar em qualquer caminho, seja como guerreiros, magos, sacerdotes ou aventureiros.",
  imagemRaca: "assets/images/racas/humano.png",
  modificadores: {},
  habilidadesRaca: {
    "Graça da Ambição": "Filhos de Valkaria, humanos recebem +1 em três atributos diferentes à sua escolha.",
    "Versátil": "Você se torna treinado em duas perícias a sua escolha (não precisam ser da sua classe). Você pode trocar uma dessas perícias por um poder geral a sua escolha."
  },
  ehFlexivel: true,
  atributosBloqueados: [] 
),

    Raca(
  nome: "Lefou",
  descricaoRaca: "Com a influência macabra da Tormenta permeando cada vez mais o mundo, surgiram os lefou. Nasceram deformidades e sinais claros de que a Tormenta tocou sua existência.",
  imagemRaca: "assets/images/racas/lefou.png",
  modificadores: {'CAR': -1},
  habilidadesRaca: {
    "Graça da Brutalidade": "Você recebe +1 em três atributos diferentes à sua escolha (exceto Carisma).",
    "Cria da Tormenta": "Você é uma criatura do tipo monstro e recebe +5 em testes de resistência contra efeitos causados por lefeu e pela Tormenta.",
    "Deformidade": "Você possui características físicas aberrantes que concedem vantagens. Recebe +2 em duas perícias à sua escolha. Cada um desses bônus conta como um poder da Tormenta (exceto para perda de Carisma). Você pode trocar um desses bônus por um poder da Tormenta à sua escolha (ele também não conta para perda de Carisma)."
  },
  ehFlexivel: true,
  atributosBloqueados: ['CAR']
),

    Raca(
  nome: "Osteon",
  descricaoRaca: "Esqueletos conscientes que mantêm memória e vontade próprias. Surgiram após eventos ligados à morte e à necromancia em Arton, sendo capazes de viver como qualquer outra raça.",
  imagemRaca: "assets/images/racas/osteon.png",
  modificadores: {'CON': -1},
  habilidadesRaca: {
    "Atributos Flexíveis": "+1 em três atributos diferentes à sua escolha (exceto Constituição).",
    "Armadura Óssea": "Redução de dano 5 contra corte, frio e perfuração.",
    "Memória Póstuma": "Treinado em uma perícia ou recebe um poder geral. Alternativamente, pode escolher uma habilidade de outra raça humanoide.",
    "Natureza Esquelética": "Tipo morto-vivo; visão no escuro; imune a cansaço, veneno e efeitos metabólicos. Não precisa respirar, comer ou dormir. Cura de luz causa dano e trevas cura PV.",
    "Preço da Não Vida": "Para descansar, deve passar 8h sob estrelas ou no subterrâneo; caso contrário sofre fome."
  },
  ehFlexivel: true,
  atributosBloqueados: ['CON']
),

    Raca(
  nome: "Sereia / Tritão",
  descricaoRaca: "Seres marinhos de torso humanoide e cauda de peixe. Sereias e tritões podem assumir forma bípede para explorar o mundo de Arton, levando sua curiosidade e ligação com os mares para aventuras em terra.",
  imagemRaca: "assets/images/racas/sereia_tritao.png",
  modificadores: {},
  habilidadesRaca: {
    "Atributos Flexíveis": "+1 em três atributos diferentes à sua escolha.",
    "Canção dos Mares": "Pode lançar duas magias entre: Amedrontar, Comando, Despedaçar, Enfeitiçar, Hipnotismo ou Sono (Carisma). Se aprender novamente uma delas, custo –1 PM.",
    "Mestre do Tridente": "Tridente conta como arma simples para você. +2 no dano com azagaias, lanças e tridentes.",
    "Transformação Anfíbia": "Respira na água e possui natação 12m com cauda. Fora d’água ganha pernas (deslocamento 9m). Após 1 dia sem água, não recupera PM com descanso."
  },
  ehFlexivel: true,
  atributosBloqueados: []
),

  ];
}