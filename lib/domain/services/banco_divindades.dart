import '../entities/divindade.dart';
import '../entities/poder.dart';

const List<Divindade> bancoDivindades = [
  Divindade(
    id: 'khalmyr',
    nome: 'Khalmyr',
    titulo: 'Deus da Justiça e da Ordem',
    simboloSagrado: 'Uma espada sobre uma balança de dois pratos',
    energiaCanalizada: TipoEnergia.positiva,
    armaPreferida: 'Espada Longa',
    descricao:
        'Líder tradicional do Panteão, Khalmyr personifica a justiça, a ordem, '
        'a honra e as leis. Seus seguidores são paladinos, juízes, nobres e '
        'guerreiros honrados que buscam trazer estabilidade e paz a Arton.',
    obrigacoesERestricoes:
        'Você é proibido de mentir, trapacear, roubar ou desobedecer uma lei justa. '
        'Nunca pode atacar um oponente indefeso, desarmado ou pelas costas. '
        'Violação: Se quebrar estas regras, você perde todos os seus Pontos de Mana '
        'imediatamente e só pode recuperá-los após uma penitência aceita pelo mestre.',
    poderesConcedidos: [
      Poder(
        key: 'coragem_total',
        nome: 'Coragem Total',
        descricao: 'Você é imune a efeitos de medo, mágicos ou não.',
      ),
      Poder(
        key: 'dom_da_verdade',
        nome: 'Dom da Verdade',
        descricao:
            'Você pode gastar 1 PM para receber +5 em testes de Intuição '
            'para perceber mentiras até o fim da cena.',
      ),
      Poder(
        key: 'espada_justiceira',
        nome: 'Espada Justiceira',
        descricao:
            'Você pode gastar 1 PM para fazer sua arma corpo a corpo causar '
            '+1d6 de dano de essência até o fim do combate.',
      ),
    ],
  ),

  Divindade(
    id: 'valkaria',
    nome: 'Valkaria',
    titulo: 'Deusa da Ambição e dos Aventureiros',
    simboloSagrado: 'Uma estátua de mulher com mãos acorrentadas erguidas',
    energiaCanalizada: TipoEnergia.positiva,
    armaPreferida: 'Chicote',
    descricao:
        'Criadora da humanidade, Valkaria incentiva a superação de limites, '
        'a exploração do desconhecido e a busca incessante pela glória. '
        'É a deusa suprema dos aventureiros e de quem não aceita o destino imposto.',
    obrigacoesERestricoes:
        'Você não pode recusar um convite para uma aventura ou uma missão heroica '
        'legítima, e nunca pode permanecer no mesmo vilarejo ou cidade por mais de um mês. '
        'Violação: Se quebrar estas regras, você perde todos os seus Pontos de Mana '
        'até realizar uma penitência em nome de Valkaria.',
    poderesConcedidos: [
      Poder(
        key: 'alpinista_social',
        nome: 'Alpinista Social',
        descricao:
            'Você pode usar seu carisma no lugar de sabedoria em testes de perícia '
            'e recebe +2 em testes de Diplomacia com figuras de autoridade.',
      ),
      Poder(
        key: 'armas_da_ambicao',
        nome: 'Armas da Ambição',
        descricao:
            'Você recebe +1 em testes de ataque e na margem de ameaça de acerto crítico '
            'com a arma preferida da deusa ou com qualquer arma corpo a corpo.',
      ),
      Poder(
        key: 'liberdade_divina',
        nome: 'Liberdade Divina',
        descricao:
            'Você pode gastar 1 PM para se libertar instantaneamente de efeitos '
            'de imobilização, paralisia ou agarrar.',
      ),
    ],
  ),

  Divindade(
    id: 'wynna',
    nome: 'Wynna',
    titulo: 'Deusa da Magia',
    simboloSagrado: 'Um anel metálico de três aros entrelaçados',
    energiaCanalizada: TipoEnergia.qualquer,
    armaPreferida: 'Adaga',
    descricao:
        'Wynna ama a magia acima de todas as coisas e a concede generosamente a '
        'todos os mortais. Ela não faz distinção entre o bem e o mal, ensinando '
        'que a magia é a maior dádiva concedida aos povos de Arton.',
    obrigacoesERestricoes:
        'Você é proibido de matar qualquer criatura capaz de lançar magias e não pode '
        'destruir ou se desfazer de itens mágicos permanentemente. '
        'Violação: Se violar esta obrigação, você perde todos os seus Pontos de Mana '
        'até que realize uma penitência sagrada.',
    poderesConcedidos: [
      Poder(
        key: 'bencao_do_mana',
        nome: 'Bênção do Mana',
        descricao:
            'Você recebe +1 Ponto de Mana adicional para cada patamar de nível.',
      ),
      Poder(
        key: 'centelha_magica',
        nome: 'Centelha Mágica',
        descricao:
            'Você aprende uma magia de 1º círculo adicional, arcana ou divina, '
            'a sua escolha.',
      ),
      Poder(
        key: 'teurgista_mistico',
        nome: 'Teurgista Místico',
        descricao:
            'Suas magias arcanas podem ser lançadas como divinas, e suas magias divinas '
            'podem ser lançadas como arcanas.',
      ),
    ],
  ),

  Divindade(
    id: 'allihanna',
    nome: 'Allihanna',
    titulo: 'Deusa da Natureza e dos Animais',
    simboloSagrado: 'Uma flor de quatro pétalas ou a pegada de um animal',
    energiaCanalizada: TipoEnergia.positiva,
    armaPreferida: 'Bordão',
    descricao:
        'Gentil e protetora, Allihanna cuida das florestas, dos animais e dos '
        'ermos. Ela prega a harmonia com o mundo natural e o respeito aos seres vivos, '
        'sendo venerada por caçadores, druidas, bárbaros e povos tribais.',
    obrigacoesERestricoes:
        'Você não pode usar armaduras ou escudos feitos de metal e nunca pode matar '
        'animais selvagens exceto em legítima defesa de sua vida. '
        'Violação: Se violar, perde todos os seus Pontos de Mana até purificar-se '
        'em uma floresta ou santuário natural.',
    poderesConcedidos: [
      Poder(
        key: 'dedo_verde',
        nome: 'Dedo Verde',
        descricao:
            'Você aprende e pode lançar a magia Controlar Plantas. Se já a conhece, '
            'seu custo diminui em -1 PM.',
      ),
      Poder(
        key: 'descanso_natural',
        nome: 'Descanso Natural',
        descricao:
            'Para você, dormir sob o céu aberto em ambiente natural conta como '
            'condições de descanso confortáveis para recuperação de PV e PM.',
      ),
      Poder(
        key: 'voz_dos_monstros',
        nome: 'Voz dos Monstros',
        descricao:
            'Você consegue se comunicar livremente com animais e criaturas do tipo monstro.',
      ),
    ],
  ),

  Divindade(
    id: 'nimb',
    nome: 'Nimb',
    titulo: 'Deus da Sorte, do Acaso e do Caos',
    simboloSagrado: 'Um dado de seis faces com pontos multicoloridos',
    energiaCanalizada: TipoEnergia.qualquer,
    armaPreferida: 'Adaga ou Maça',
    descricao:
        'Inconstante e imprevisível, Nimb governa os golpes de sorte e as marés '
        'de azar. Seus devotos abraçam a incerteza e acreditam que tentar controlar '
        'o destino é uma grande tolice.',
    obrigacoesERestricoes:
        'Você nunca pode recusar uma aposta ou um jogo de azar em que haja risco. '
        'Sempre que se deparar com uma encruzilhada ou dúvida, deve lançar uma moeda '
        'ou dado para decidir sua ação. '
        'Violação: A quebra da regra zera seus Pontos de Mana até o mestre decretar '
        'um ato caótico de penitência.',
    poderesConcedidos: [
      Poder(
        key: 'poder_oculto',
        nome: 'Poder Oculto',
        descricao:
            'Você pode gastar 2 PM para rolar 1d6. Em 1, nada acontece; de 2 a 5 você '
            'recebe +2 em um atributo; em 6 você recebe +4 em todos os atributos até o fim da cena.',
      ),
      Poder(
        key: 'sorte_dos_loucos',
        nome: 'Sorte dos Loucos',
        descricao:
            'Você pode gastar 1 PM para rerrolar qualquer teste recém-realizado, '
            'ficando obrigatoriamente com o novo resultado.',
      ),
      Poder(
        key: 'transmissao_da_loucura',
        nome: 'Transmissão da Loucura',
        descricao:
            'Você pode gastar 2 PM para forçar um alvo em alcance curto a ficar confuso '
            'por 1 rodada (Vontade anula).',
      ),
    ],
  ),

  Divindade(
    id: 'arsenal',
    nome: 'Arsenal',
    titulo: 'Deus da Guerra e da Conquista',
    simboloSagrado: 'Um martelo de guerra sobre uma espada larga cruzada',
    energiaCanalizada: TipoEnergia.negativa,
    armaPreferida: 'Martelo de Guerra',
    descricao:
        'Anteriormente o sumo-sacerdote de Keenn, Arsenal conquistou a divindade '
        'através da força pura e estratégia bélica. Ele ensina que a vitória pertence '
        'aos mais fortes, mais preparados e que nunca recuam no campo de batalha.',
    obrigacoesERestricoes:
        'Você nunca pode fugir de um combate militar nem recusar um duelo honroso '
        'contra um líder ou campeão inimigo. '
        'Violação: Se fugir de uma luta ou recusar combate, você perde todos os seus '
        'Pontos de Mana até derrotar um inimigo em combate solo.',
    poderesConcedidos: [
      Poder(
        key: 'conjurar_arma',
        nome: 'Conjurar Arma',
        descricao:
            'Você pode gastar 1 PM para materializar qualquer arma corpo a corpo ou '
            'de arremesso em suas mãos por uma cena.',
      ),
      Poder(
        key: 'foco_em_arma_arsenal',
        nome: 'Foco em Arma (Arsenal)',
        descricao:
            'Você recebe o poder geral Foco em Arma com sua arma favorita, ganhando '
            '+2 em testes de ataque com ela.',
      ),
      Poder(
        key: 'sangue_de_ferro',
        nome: 'Sangue de Ferro',
        descricao:
            'Você pode gastar 2 PM para ganhar Redução de Dano (RD) 3 até o fim do combate.',
      ),
    ],
  ),
];

class BancoDeDivindades {
  static const List<Divindade> todas = bancoDivindades;

  static Divindade? getById(String id) {
    try {
      return todas.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }
}
