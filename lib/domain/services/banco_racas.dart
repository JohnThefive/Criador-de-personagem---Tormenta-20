import '../entities/raca.dart';

class BancoDeRacas {
  static const List<Raca> todas = [
    // --- raças que possuem adição de modificador fixo ---
    Raca(
      nome: "Anão",
      modificadores: {'CON': 2, 'SAB': 1, 'DES': -1},
      habilidades: ["Conhecimento das Rochas", "Devagar e Sempre", "Duro como pedra", "Tradição de Heredrimm"],
    ),
    Raca(
      nome: "Dahllan",
      modificadores: {'SAB': 2, 'DES': 1, 'INT': -1},
      habilidades: ["Amiga das Plantas", "Armadura de Allihanna", "Empatia Selvagem"],
    ),
    Raca(
      nome: "Elfo",
      modificadores: {'INT': 2, 'DES': 1, 'CON': -1},
      habilidades: ["Graça de Glórienn", "Sangue Mágico", "Sentidos Élficos"],
    ),
    Raca(
      nome: "Goblin",
      modificadores: {'DES': 2, 'INT': 1, 'CAR': -1},
      habilidades: ["Engenhoso", "Espelunqueiro", "Peste Eguia", "Rato das Ruas"],
    ),
    Raca(
      nome: "Minotauro",
      modificadores: {'FOR': 2, 'CON': 1, 'SAB': -1},
      habilidades: ["Chifres", "Couro Rígido", "Faro", "Medo de Altura"],
    ),
    Raca(
      nome: "Qareen",
      modificadores: {'CAR': 2, 'INT': 1, 'SAB': -1},
      habilidades: ["Herança Mística","Resistência Elemental","Tatuagem Mística"],
    ),
    Raca(
      nome: "Golem",
      modificadores: {'FOR': 2, 'CON': 1, 'CAR': -1},
      habilidades: ["Chassi", "Criatura Artificial", "Fonte Elemental", "Propósito De Criação"],
    ),
    Raca(
      nome: "Hynne",
      modificadores: {'DES': 2, 'CAR': 1, 'FOR': -1},
      habilidades: ["Arremessador", "Pequeno e Rechonchudo", "Sorte Salvadora"],
    ),
    Raca(
      nome: "Kliren",
      modificadores: {'INT': 2, 'CAR': 1, 'FOR': -1},
      habilidades: ["Híbrido", "Engenhosidade", "Ossos Frágeis", "Vanguardista"],
    ),
    Raca(
      nome: "Medusa",
      modificadores: {'DES': 2, 'CAR': 1}, 
      habilidades: ["Natureza Venenosa", "Olhar Atordoante", "Cria de Megalokk"],
    ),

    Raca(
      nome: "Sílfide",
      modificadores: {'CAR': 2, 'DES': 1, "FOR": -2}, 
      habilidades: ["Assas de Borboleta", "Espírito da Natureza", "Magia das Fadas"],
    ),

    Raca(
      nome: "Suraggel (Aggelus)",
      modificadores: {'SAB': 2, 'CAR': 1, "DES": 1}, 
      habilidades: ["Herança Divina", "Luz Sagrada"],
    ),

    Raca(
      nome: "Suraggel (Sulfure)",
      modificadores: {'SAB': 2, 'CAR': 1, "INT": 1}, 
      habilidades: ["Herança Divina", "Sombras Profanas"],
    ),

    Raca(
      nome: "Trog",
      modificadores: {'CON': 2, 'FOR': 1, 'INT': -1},
      habilidades: ["Mau Cheiro", "Mordida", "Reptiliano", "Sangue Frio"],
    ),

    // --- RAÇAS FLEXÍVEIS (Humano, Lefou, etc) ---
    // *Nota: Para hoje, vamos deixá-las na lista, mas elas precisam 
    // de uma UI extra para escolher onde vai o +1. Deixei vazio por enquanto.*
    Raca(
      nome: "Humano",
      modificadores: {}, 
      habilidades: ["Graça da Ambição", "Versátil"], // graça da ambição: +1 em 3 que escolher
      ehFlexivel: true,
      atributosBloqueados: [] // Flag para a UI saber que precisa abrir um seletor
    ),

    Raca(
      nome: "Lefou",
      modificadores: {'CAR': -1}, 
      habilidades: ["Graça da brutalidade", "Cria Da Tormenta", "Deformidade"], //graça da brutalidade: +1 em 3 que escolher - carisma
      ehFlexivel: true,
      atributosBloqueados: ['CAR'] // Flag para a UI saber que precisa abrir um seletor - carisma
    ),

    Raca(
      nome: "Osteon",
      modificadores: {'COS': -1}, 
      habilidades: ["Armadura Óssea", "Memória Póstuma", "Natureza Esquelética", "Preço da Não Vida"],
      ehFlexivel: true,// +1 em 3 atributos diferentes (menos constituição)
      atributosBloqueados: ["COS"]
    ),

    Raca(
      nome: "Sereia/Tritão",
      modificadores: {}, 
      habilidades: ["Canção dos Mares", "Mestre do Tridente", "Transformação Anfíbia"],
      ehFlexivel: true, // +1 em 3 atributos diferentes 
      atributosBloqueados: [],
    ),

  ];
}