import 'package:t20_creator/domain/entities/origem.dart';
import 'package:t20_creator/domain/entities/poder.dart';

const List<Origem> bancoOrigens = [
  Origem(
    id: 'acolito',
    nome: 'Acólito',
    descricao:
        'Você cresceu cercado por orações, evangelhos e ensinamentos '
        'religiosos, seja por tradição familiar, vocação ou criação '
        'em um templo ou mosteiro.',
    itensIniciais: ['Símbolo sagrado', 'Traje de sacerdote'],
    periciasOpcoes: ['CURA', 'RELIGIAO', 'VONTADE'],
    poderesGeraisOpcoes: [
      Poder(
        key: 'medicina',
        nome: 'Medicina',
        descricao: 'Poder geral Medicina.',
      ),
      Poder(
        key: 'vontade_de_ferro',
        nome: 'Vontade de Ferro',
        descricao: 'Poder geral Vontade de Ferro.',
      ),
    ],
    poderUnico: Poder(
      key: 'membro_da_igreja',
      nome: 'Membro da Igreja',
      descricao:
          'Você consegue hospedagem confortável e informação em '
          'qualquer templo de sua divindade, para você e seus aliados.',
    ),
  ),

  Origem(
    id: 'amigo_animais',
    nome: 'Amigo dos Animais',
    descricao:
        'Você possui facilidade em lidar com animais, seja por ter '
        'trabalhado com eles ou por possuir uma afinidade natural. '
        'Desde a infância, consegue compreendê-los e estabelecer '
        'uma relação especial com eles.',
    itensIniciais: ['Cão de caça, cavalo, pônei ou trobo (escolha um)'],
    periciasOpcoes: ['ADESTRAMENTO', 'CAVALGAR'],
    poderesGeraisOpcoes: [],
    poderUnico: Poder(
      key: 'amigo_especial',
      nome: 'Amigo Especial',
      descricao:
          'Você recebe +5 em testes de Adestramento com animais. '
          'Além disso, possui um animal de estimação que o auxilia '
          'e o acompanha em suas aventuras. Em termos de jogo, é '
          'um parceiro que fornece +2 em uma perícia a sua escolha '
          '(exceto Luta ou Pontaria e aprovada pelo mestre) e não '
          'conta em seu limite de parceiros.',
    ),
  ),

  Origem(
    id: 'aristocrata',
    nome: 'Aristocrata',
    descricao:
        'Você nasceu na nobreza e recebeu uma educação sofisticada, '
        'podendo ter sido instruído em assuntos acadêmicos, política, '
        'torneios de cavalaria ou conjuração arcana, conforme as '
        'tradições de sua linhagem.',
    itensIniciais: ['Joia de família no valor de T\$ 300', 'Traje da corte'],
    periciasOpcoes: ['DIPLOMACIA', 'ENGANACAO', 'NOBREZA'],
    poderesGeraisOpcoes: [
      Poder(
        key: 'comandar',
        nome: 'Comandar',
        descricao: 'Poder geral Comandar.',
      ),
    ],
    poderUnico: Poder(
      key: 'sangue_azul',
      nome: 'Sangue Azul',
      descricao:
          'Você tem alguma influência política, suficiente para ser '
          'tratado com mais leniência pela guarda, conseguir uma '
          'audiência com o nobre local etc.',
    ),
  ),

  Origem(
    id: 'capanga',
    nome: 'Capanga',
    descricao:
        'Você trabalhou como força bruta para algum criminoso, '
        'integrando um bando, quadrilha ou guilda de ladrões. '
        'Sua força e intimidação eram suas principais ferramentas '
        'no mundo do crime.',
    itensIniciais: [
      'Tatuagem ou outro adereço de sua gangue (+1 em Intimidação)',
      'Uma arma simples corpo a corpo',
    ],
    periciasOpcoes: ['LUTA', 'INTIMIDACAO'],
    poderesGeraisOpcoes: [
      Poder(
        key: 'poder_combate_escolha',
        nome: 'Poder de combate à escolha',
        descricao:
            'Você pode escolher um poder de combate que cumpra '
            'todos os seus pré-requisitos.',
      ),
    ],
    poderUnico: Poder(
      key: 'confissao',
      nome: 'Confissão',
      descricao:
          'Você pode usar Intimidação para interrogar sem custo '
          'e em uma hora (veja Investigação).',
    ),
  ),

  Origem(
    id: 'soldado',
    nome: 'Soldado',
    descricao:
        'Você se alistou ou foi convocado para servir em um grande '
        'exército, recebendo treinamento em combate e equipamento '
        'militar. Depois de deixar a vida militar, tornou-se aventureiro.',
    itensIniciais: [
      'Uma arma marcial',
      'Um uniforme militar',
      'Uma insígnia de seu exército',
    ],
    periciasOpcoes: ['FORTITUDE', 'GUERRA', 'LUTA', 'PONTARIA'],
    poderesGeraisOpcoes: [
      Poder(
        key: 'poder_combate_escolha',
        nome: 'Poder de combate à escolha',
        descricao:
            'Você pode escolher um poder de combate que cumpra '
            'todos os seus pré-requisitos.',
      ),
    ],
    poderUnico: Poder(
      key: 'influencia_militar',
      nome: 'Influência Militar',
      descricao:
          'Você fez amigos nas forças armadas. Onde houver '
          'acampamentos ou bases militares, você pode conseguir '
          'hospedagem e informações para você e seus aliados.',
    ),
  ),
];

class BancoDeOrigens {
  static const List<Origem> todas = bancoOrigens;

  static Origem? getById(String id) {
    try {
      return todas.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }
}
