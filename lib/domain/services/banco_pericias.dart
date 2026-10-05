import '../entities/pericias.dart';

class BancoDePericias {
  static const List<Pericia> todas = [
    Pericia(
      key: 'ACROBACIA',
      label: 'Acrobacia',
      atributoChave: 'DES',
      somenteTreinada: false,
      penalidadeArmadura: true,
      descricao: 'Você consegue fazer proezas acrobáticas.',
      acoesExecutadas:
          'Amortecer queda, equilíbrio, escapar, levantar-se rapidamente, passar por inimigo.',
    ),
    Pericia(
      key: 'ADESTRAMENTO',
      label: 'Adestramento',
      atributoChave: 'CAR',
      somenteTreinada: true,
      penalidadeArmadura: false,
      descricao: 'Você sabe lidar com animais.',
      acoesExecutadas: 'Acalmar animal, manejar animal.',
    ),
    Pericia(
      key: 'ATLETISMO',
      label: 'Atletismo',
      atributoChave: 'FOR',
      somenteTreinada: false,
      penalidadeArmadura: false,
      descricao: 'Esta perícia é utilizada para realizar façanhas atléticas.',
      acoesExecutadas: 'Escalar, natação, salto, corrida.',
    ),
    Pericia(
      key: 'ATUACAO',
      label: 'Atuação',
      atributoChave: 'CAR',
      somenteTreinada: true,
      penalidadeArmadura: false,
      descricao:
          'Você sabe fazer apresentações artísticas, incluindo música, dança e dramaturgia.',
      acoesExecutadas: 'Impressionar, Apresentar-se.',
    ),
    Pericia(
      key: 'CAVALGAR',
      label: 'Cavalgar',
      atributoChave: 'DES',
      somenteTreinada: false,
      penalidadeArmadura: false,
      descricao:
          'Você sabe conduzir animais de montaria, como cavalos, trobos e grifos.',
      acoesExecutadas: 'Conduzirm, Galopar, Montar Rapidamente',
    ),
    Pericia(
      key: 'CONHECIMENTO',
      label: 'Conhecimento',
      atributoChave: 'INT',
      somenteTreinada: true,
      penalidadeArmadura: false,
      descricao:
          'Você é um estudioso de assuntos gerais, como história e geografia.',
      acoesExecutadas: 'Lembrar informação, Saber de Idiomas.',
    ),
    Pericia(
      key: 'CURA',
      label: 'Cura',
      atributoChave: 'SAB',
      somenteTreinada: false,
      penalidadeArmadura: false,
      descricao: 'Você sabe tratar ferimentos, doenças e venenos.',
      acoesExecutadas:
          'Cuidados Prolongados, Necropsia, Primeiros socorros, Tratemento(precisa de Treinamento)',
    ),
    Pericia(
      key: 'DIPLOMACIA',
      label: 'Diplomacia',
      atributoChave: 'CAR',
      somenteTreinada: false,
      penalidadeArmadura: false,
      descricao: 'Você usa lábia e argumentação para convencer outras pessoas.',
      acoesExecutadas: 'Mudar atitude, Barganha, Persuação.',
    ),
    Pericia(
      key: 'ENGANACAO',
      label: 'Enganação',
      atributoChave: 'CAR',
      somenteTreinada: false,
      penalidadeArmadura: false,
      descricao: 'Você engana pessoas com mentiras, falsificações e disfarces.',
      acoesExecutadas:
          'Disfarce, Falsificação, Fintar, Insinuação, Intriga, Mentir',
    ),
    Pericia(
      key: 'FORTITUDE',
      label: 'Fortitude',
      atributoChave: 'CON',
      somenteTreinada: false,
      penalidadeArmadura: false,
      descricao: 'Esta perícia mede seu vigor e resistência física.',
      acoesExecutadas: 'Teste de resistência contra venenos, doenças e fadiga.',
    ),
    Pericia(
      key: 'FURTIVIDADE',
      label: 'Furtividade',
      atributoChave: 'DES',
      somenteTreinada: false,
      penalidadeArmadura: true,
      descricao: 'Você pode se esconder nas sombras e andar sem fazer barulho.',
      acoesExecutadas:
          'Esconder-se, mover-se furtivamente, seguir alvo sem ser percebido',
    ),
    Pericia(
      key: 'GUERRA',
      label: 'Guerra',
      atributoChave: 'INT',
      somenteTreinada: true,
      penalidadeArmadura: false,
      descricao: 'Você foi educado em tática, estratégia e logística.',
      acoesExecutadas: 'Reconhecer terreno, Plano de ação',
    ),
    Pericia(
      key: 'INICIATIVA',
      label: 'Iniciativa',
      atributoChave: 'DES',
      somenteTreinada: false,
      penalidadeArmadura: false,
      descricao:
          'Esta perícia determina sua velocidade de reação em situações de perigo.',
      acoesExecutadas: 'Agir primeiro no combate.',
    ),
    Pericia(
      key: 'INTIMIDACAO',
      label: 'Intimidação',
      atributoChave: 'CAR',
      somenteTreinada: false,
      penalidadeArmadura: false,
      descricao: 'Você pode assustar ou coagir outras pessoas.',
      acoesExecutadas: 'Coagir, assustar.',
    ),
    Pericia(
      key: 'INTUICAO',
      label: 'Intuição',
      atributoChave: 'SAB',
      somenteTreinada: false,
      penalidadeArmadura: false,
      descricao: 'Esta perícia mede seu “sexto sentido”.',
      acoesExecutadas:
          'Perceber blefe, pressentimento, ler a pessoa, perceber ilusões.',
    ),
    Pericia(
      key: 'INVESTIGACAO',
      label: 'Investigação',
      atributoChave: 'INT',
      somenteTreinada: false,
      penalidadeArmadura: false,
      descricao: 'Você sabe como descobrir pistas e informações.',
      acoesExecutadas: 'Procurar, interrogar.',
    ),
    Pericia(
      key: 'JOGATINA',
      label: 'Jogatina',
      atributoChave: 'CAR',
      somenteTreinada: true,
      penalidadeArmadura: false,
      descricao: 'Você sabe ganhar dinheiro com jogos de azar.',
      acoesExecutadas: 'Ganhar dinheiro, trapacear em jogos de cartas/dados.',
    ),
    Pericia(
      key: 'LADINAGEM',
      label: 'Ladinagem',
      atributoChave: 'DES',
      somenteTreinada: true,
      penalidadeArmadura: true,
      descricao:
          'Com mãos leves e mente suja, você sabe exercer as tarefas de um ladrão.',
      acoesExecutadas: 'Abrir fechaduras,Ocultar, Bater Carteira, Sabotagem',
    ),
    Pericia(
      key: 'LUTA',
      label: 'Luta',
      atributoChave: 'FOR',
      somenteTreinada: false,
      penalidadeArmadura: false,
      descricao:
          'Mede sua capacidade de luta corpo a corpo, com armas brancas ou desarmado.',
      acoesExecutadas:
          'Atacar corpo a corpo, agarrar, derrubar, desarmar, empurrar, quebrar.',
    ),
    Pericia(
      key: 'MISTICISMO',
      label: 'Misticismo',
      atributoChave: 'INT',
      somenteTreinada: true,
      penalidadeArmadura: false,
      descricao:
          'Esta perícia envolve o conhecimento de magias, itens mágicos e fenômenos sobrenaturais',
      acoesExecutadas:
          'Detectar magias, identificar criatura (fadas, mortos-vivos), identificar item mágico, informação, lançar magia armadurado.',
    ),
    Pericia(
      key: 'NOBREZA',
      label: 'Nobreza',
      atributoChave: 'INT',
      somenteTreinada: true,
      penalidadeArmadura: false,
      descricao:
          'Você recebeu a educação de um nobre. Sabe desde supervisionar uma colheita a se portar em um baile.',
      acoesExecutadas:
          'Etiqueta, conhecer brasões, Informação de casas nobres ',
    ),
    Pericia(
      key: 'OFICIO',
      label: 'Ofício (Geral)',
      atributoChave: 'INT',
      somenteTreinada: false,
      penalidadeArmadura: false,
      descricao:
          'Permite fabricar itens de uma categoria específica (ex: Armeiro, Alquimista, Engenhoqueiro).',
      acoesExecutadas:
          'Fabricar item, ganhar sustento, reparar item.',
    ),
    Pericia(
      key: 'OFICIO_ENGENHOQUEIRO',
      label: 'Ofício (Engenhoqueiro)',
      atributoChave: 'INT',
      somenteTreinada: true,
      penalidadeArmadura: false,
      descricao:
          'Permite projetar, fabricar, ativar e consertar engenhocas e dispositivos tecnológicos.',
      acoesExecutadas:
          'Fabricar engenhoca, ativar engenhoca, consertar engenhoca enguiçada.',
    ),
    Pericia(
      key: 'OFICIO_ALQUIMISTA',
      label: 'Ofício (Alquimista)',
      atributoChave: 'INT',
      somenteTreinada: true,
      penalidadeArmadura: false,
      descricao:
          'Permite preparar itens alquímicos, poções, ácidos, venenos e bombas.',
      acoesExecutadas:
          'Fabricar itens alquímicos e poções, identificar substâncias químicas.',
    ),
    Pericia(
      key: 'OFICIO_ARMEIRO',
      label: 'Ofício (Armeiro)',
      atributoChave: 'INT',
      somenteTreinada: true,
      penalidadeArmadura: false,
      descricao:
          'Permite forjar, modificar e reparar armas, escudos e armaduras.',
      acoesExecutadas:
          'Fabricar armas e proteções, aplicar melhorias de equipamento, reparar itens danificados.',
    ),
    Pericia(
      key: 'OFICIO_COZINHEIRO',
      label: 'Ofício (Culinária)',
      atributoChave: 'INT',
      somenteTreinada: false,
      penalidadeArmadura: false,
      descricao:
          'Permite cozinhar pratos especiais, rações de viagem e refeições nutritivas com bônus temporários.',
      acoesExecutadas:
          'Cozinhar pratos especiais, identificar alimentos envenenados ou estragados.',
    ),
    Pericia(
      key: 'OFICIO_ARTESANATO',
      label: 'Ofício (Artesanato / Geral)',
      atributoChave: 'INT',
      somenteTreinada: false,
      penalidadeArmadura: false,
      descricao:
          'Permite confeccionar itens de vestuário, couro, madeira, alvenaria e artigos gerais.',
      acoesExecutadas:
          'Fabricar itens comuns de artesanato, reparos em artigos do dia a dia.',
    ),
    Pericia(
      key: 'PERCEPCAO',
      label: 'Percepção',
      atributoChave: 'SAB',
      somenteTreinada: false,
      penalidadeArmadura: false,
      descricao: 'Você nota coisas usando os sentidos.',
      acoesExecutadas:
          'Observar, ouvir, perceber coisas escondidas, contrapor Furtividade.',
    ),
    Pericia(
      key: 'PILOTAGEM',
      label: 'Pilotagem',
      atributoChave: 'DES',
      somenteTreinada: true,
      penalidadeArmadura: false,
      descricao: 'Você sabe operar veículos como carroças, barcos e balões.',
      acoesExecutadas:
          'Conduzir veículo, manobras perigosas, combater embarcado.',
    ),
    Pericia(
      key: 'PONTARIA',
      label: 'Pontaria',
      atributoChave: 'DES',
      somenteTreinada: false,
      penalidadeArmadura: false,
      descricao:
          'Mede sua capacidade de mira, seja com armas de arremesso, seja com armas de disparo.',
      acoesExecutadas: 'Atacar à distância.',
    ),
    Pericia(
      key: 'REFLEXOS',
      label: 'Reflexos',
      atributoChave: 'DES',
      somenteTreinada: false,
      penalidadeArmadura: false,
      descricao:
          'Mede sua capacidade de evitar armadilhas, explosões e ameaças rápidas.',
      acoesExecutadas:
          'Teste de resistência contra ataques em área, magias de Evocação e armadilhas.',
    ),
    Pericia(
      key: 'RELIGIAO',
      label: 'Religião',
      atributoChave: 'SAB',
      somenteTreinada: true,
      penalidadeArmadura: false,
      descricao:
          'Você possui conhecimento sobre os deuses e as religiões de Arton.',
      acoesExecutadas:
          'Conhecimento divino, identificar criatura/item (celestiais, demônios, mortos-vivos), Rito.',
    ),
    Pericia(
      key: 'SOBREVIVENCIA',
      label: 'Sobrevivência',
      atributoChave: 'SAB',
      somenteTreinada: false,
      penalidadeArmadura: false,
      descricao:
          'Você pode se guiar nos ermos e reconhecer e evitar perigos da natureza.',
      acoesExecutadas:
          'Acampamento, Identificar criaturas da floresta, Orientar-se, Rastrear (se for treinado).',
    ),
    Pericia(
      key: 'VONTADE',
      label: 'Vontade',
      atributoChave: 'SAB',
      somenteTreinada: false,
      penalidadeArmadura: false,
      descricao: 'Esta perícia envolve sua concentração e força de vontade.',
      acoesExecutadas:
          'Teste de resistência contra intimidação, ilusões, encantamentos e medo.',
    ),
  ];

  // Método auxiliar para buscar uma perícia pela chave de forma segura
  static Pericia getByKey(String key) {
    return todas.firstWhere(
      (p) => p.key == key,
      // Retorna um fallback caso tente buscar uma perícia que não existe (evita crash)
      orElse: () => const Pericia(
        key: 'UNKNOWN',
        label: 'Desconhecida',
        atributoChave: 'INT',
        somenteTreinada: false,
        penalidadeArmadura: false,
        descricao: 'Perícia não encontrada.',
        acoesExecutadas: 'Nenhuma',
      ),
    );
  }
}
