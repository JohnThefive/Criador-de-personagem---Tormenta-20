import '../arma.dart';
import 'combatente.dart';
import 'estado_vida_combatente.dart';

class InimigosTreino {
  // Arma dos Goblins
  static const adagaGoblin = Arma(
    key: 'ADAGA_GOBLIN',
    nome: 'Adaga Enferrujada',
    descricao: 'Adaga curta serrilhada.',
    proficiencia: ProficienciaArma.simples,
    proposito: PropositoArma.corpoACorpo,
    empunhadura: EmpunhaduraArma.leve,
    dano: '1d4',
    margemAmeaca: 19,
    multiplicadorCritico: 2,
    tipoDano: TipoDanoArma.perfuracao,
  );

  // Arma do Orc
  static const machadoOrc = Arma(
    key: 'MACHADO_ORC',
    nome: 'Machado de Batalha',
    descricao: 'Machado pesado de ferro fundido.',
    proficiencia: ProficienciaArma.marcial,
    proposito: PropositoArma.corpoACorpo,
    empunhadura: EmpunhaduraArma.umaMao,
    dano: '1d8',
    margemAmeaca: 20,
    multiplicadorCritico: 3,
    tipoDano: TipoDanoArma.corte,
  );

  // 1. Boneco de Treino (Passivo)
  static final bonecoDeTreino = Combatente(
    id: 'dummy_1',
    nome: 'Boneco de Madeira',
    time: TimeCombatente.inimigo,
    estadoVida: EstadoVidaCombatente.ativo,
    pvMax: 30,
    pvAtual: 30,
    pmMax: 0,
    pmAtual: 0,
    defesa: 10,
    iniciativaValor: -5,
    deslocamentoMetros: 0.0,
    modIniciativa: -5,
    modLuta: 0,
    modPontaria: 0,
    modPercepcao: 0,
    modForca: 0,
    modDestreza: 0,
    modConstituicao: 0,
    armas: const [],
  );

  // 2. Goblin Saqueador
  static final goblinSaqueador = Combatente(
    id: 'goblin_1',
    nome: 'Goblin Saqueador',
    time: TimeCombatente.inimigo,
    estadoVida: EstadoVidaCombatente.ativo,
    pvMax: 12,
    pvAtual: 12,
    pmMax: 0,
    pmAtual: 0,
    defesa: 14,
    iniciativaValor: 0,
    deslocamentoMetros: 9.0,
    modIniciativa: 3,
    modLuta: 3,
    modPontaria: 4,
    modPercepcao: 1,
    modForca: -1,
    modDestreza: 3,
    modConstituicao: 1,
    armas: const [adagaGoblin],
  );

  // 3. Orc Guerreiro
  static final orcGuerreiro = Combatente(
    id: 'orc_1',
    nome: 'Orc Guerreiro',
    time: TimeCombatente.inimigo,
    estadoVida: EstadoVidaCombatente.ativo,
    pvMax: 24,
    pvAtual: 24,
    pmMax: 0,
    pmAtual: 0,
    defesa: 15,
    iniciativaValor: 0,
    deslocamentoMetros: 9.0,
    modIniciativa: 1,
    modLuta: 6,
    modPontaria: 1,
    modPercepcao: 0,
    modForca: 3,
    modDestreza: 1,
    modConstituicao: 2,
    armas: const [machadoOrc],
  );

  static List<Combatente> get todos => [
    bonecoDeTreino,
    goblinSaqueador,
    orcGuerreiro,
  ];
}
