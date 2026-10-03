import 'package:flutter_test/flutter_test.dart';
import 'package:t20_creator/domain/entities/arma.dart';
import 'package:t20_creator/domain/entities/combate/combatente.dart';
import 'package:t20_creator/domain/entities/combate/estado_vida_combatente.dart';
import 'package:t20_creator/domain/entities/combate/grid_tatico.dart';
import 'package:t20_creator/domain/services/combate_engine.dart';
import 'package:t20_creator/domain/services/movimento_engine.dart';
import 'package:t20_creator/presentation/controllers/combate_cubit.dart';

void main() {
  group('1. Ciclo de Vida, Inconsciência e Limite de Morte no T20', () {
    test('Cálculo do Limite de Morte T20: min(-10, -(pvMax / 2))', () {
      const combatenteFraco = Combatente(
        id: 'fraco',
        nome: 'Plebeu',
        pvMax: 10,
        pvAtual: 10,
        pmMax: 0,
        pmAtual: 0,
        defesa: 10,
        deslocamentoMetros: 9.0,
        modIniciativa: 0,
        modLuta: 0,
        modPontaria: 0,
        modPercepcao: 0,
        modForca: 0,
        modDestreza: 0,
        modConstituicao: 0,
      );
      // metade de 10 é 5, logo min(-10, -5) = -10
      expect(combatenteFraco.limiteMorte, -10);

      const combatenteForte = Combatente(
        id: 'forte',
        nome: 'Guerreiro Veterano',
        pvMax: 40,
        pvAtual: 40,
        pmMax: 0,
        pmAtual: 0,
        defesa: 15,
        deslocamentoMetros: 9.0,
        modIniciativa: 0,
        modLuta: 0,
        modPontaria: 0,
        modPercepcao: 0,
        modForca: 0,
        modDestreza: 0,
        modConstituicao: 3,
      );
      // metade de 40 é 20, logo min(-10, -20) = -20
      expect(combatenteForte.limiteMorte, -20);
    });

    test('Dano Letal: Fica inconsciente e sangrando ao chegar a 0 PV ou menos', () {
      const heroi = Combatente(
        id: 'heroi',
        nome: 'Ladino',
        pvMax: 20,
        pvAtual: 5,
        pmMax: 0,
        pmAtual: 0,
        defesa: 14,
        deslocamentoMetros: 9.0,
        modIniciativa: 3,
        modLuta: 2,
        modPontaria: 4,
        modPercepcao: 2,
        modForca: 0,
        modDestreza: 3,
        modConstituicao: 1,
      );

      final ferido = heroi.aplicarDano(8, naoLetal: false);
      expect(ferido.pvAtual, -3);
      expect(ferido.estadoVida, EstadoVidaCombatente.inconscienteSangrando);
      expect(ferido.estaInconsciente, isTrue);
      expect(ferido.estaIncapacitado, isTrue);
    });

    test('Morte Instantânea quando PV atinge ou ultrapassa o Limite de Morte', () {
      const heroi = Combatente(
        id: 'heroi',
        nome: 'Mago',
        pvMax: 16, // Limite de morte = min(-10, -8) = -10
        pvAtual: 2,
        pmMax: 0,
        pmAtual: 0,
        defesa: 11,
        deslocamentoMetros: 9.0,
        modIniciativa: 1,
        modLuta: 0,
        modPontaria: 1,
        modPercepcao: 2,
        modForca: -1,
        modDestreza: 1,
        modConstituicao: 0,
      );

      // Dano de 15 leva PV a -13, que é menor que -10 -> MORTE
      final morto = heroi.aplicarDano(15, naoLetal: false);
      expect(morto.pvAtual, -13);
      expect(morto.estadoVida, EstadoVidaCombatente.morto);
      expect(morto.estaMorto, isTrue);
      expect(morto.estaIncapacitado, isTrue);
    });

    test('Dano Não Letal: Inconsciente estabilizado sem sangrar quando danoNaoLetal >= PV', () {
      const heroi = Combatente(
        id: 'heroi',
        nome: 'Monge',
        pvMax: 20,
        pvAtual: 10,
        pmMax: 0,
        pmAtual: 0,
        defesa: 15,
        deslocamentoMetros: 9.0,
        modIniciativa: 2,
        modLuta: 4,
        modPontaria: 2,
        modPercepcao: 1,
        modForca: 2,
        modDestreza: 2,
        modConstituicao: 2,
      );

      final nocauteado = heroi.aplicarDano(12, naoLetal: true);
      expect(nocauteado.pvAtual, 10); // PV não cai abaixo de 0 por dano não letal
      expect(nocauteado.danoNaoLetal, 12);
      expect(nocauteado.estadoVida, EstadoVidaCombatente.estabilizado);
      expect(nocauteado.estaIncapacitado, isTrue);
      expect(nocauteado.estaInconsciente, isTrue);
    });

    test('Teste de Constituição CD 15 para estabilização de sangramento', () {
      const sangrando = Combatente(
        id: 'sangrando',
        nome: 'Guerreiro Sangrando',
        pvMax: 20,
        pvAtual: -2,
        estadoVida: EstadoVidaCombatente.inconscienteSangrando,
        pmMax: 0,
        pmAtual: 0,
        defesa: 15,
        deslocamentoMetros: 9.0,
        modIniciativa: 1,
        modLuta: 4,
        modPontaria: 1,
        modPercepcao: 0,
        modForca: 2,
        modDestreza: 1,
        modConstituicao: 2,
      );

      // Simula resultado fixo 15 no d20: 15 + 2 = 17 >= 15 -> Estabiliza
      final resSucesso = sangrando.testeEstabilizacaoCon(15, 0);
      expect(resSucesso.$1.estadoVida, EstadoVidaCombatente.estabilizado);
      expect(resSucesso.$1.pvAtual, -2); // PV se mantém

      // Simula resultado 10 no d20: 10 + 2 = 12 < 15 -> Falha, perde 3 PV (dado d6)
      final resFalha = sangrando.testeEstabilizacaoCon(10, 3);
      expect(resFalha.$1.pvAtual, -5);
      expect(resFalha.$1.estadoVida, EstadoVidaCombatente.inconscienteSangrando);
    });

    test('Penalidade de -5 no Ataque para Dano Não Letal com Arma Letal', () {
      const espada = Arma(
        key: 'ESPADA',
        nome: 'Espada',
        descricao: '',
        proficiencia: ProficienciaArma.simples,
        proposito: PropositoArma.corpoACorpo,
        empunhadura: EmpunhaduraArma.umaMao,
        dano: '1d6',
        margemAmeaca: 20,
        multiplicadorCritico: 2,
        tipoDano: TipoDanoArma.corte,
      );

      const atacante = Combatente(
        id: 'atk',
        nome: 'Atacante',
        pvMax: 20,
        pvAtual: 20,
        pmMax: 0,
        pmAtual: 0,
        defesa: 10,
        deslocamentoMetros: 9.0,
        modIniciativa: 0,
        modLuta: 5,
        modPontaria: 0,
        modPercepcao: 0,
        modForca: 2,
        modDestreza: 0,
        modConstituicao: 0,
        armas: [espada],
      );

      const defensor = Combatente(
        id: 'def',
        nome: 'Defensor',
        pvMax: 20,
        pvAtual: 20,
        pmMax: 0,
        pmAtual: 0,
        defesa: 15,
        deslocamentoMetros: 9.0,
        modIniciativa: 0,
        modLuta: 0,
        modPontaria: 0,
        modPercepcao: 0,
        modForca: 0,
        modDestreza: 0,
        modConstituicao: 0,
      );

      final engine = CombateEngine();

      // Com d20 = 10:
      // Ataque normal: 10 + 5 (luta) = 15 >= 15 (defesa) -> Acerto
      final normal = engine.executarAtaque(
        atacante: atacante,
        defensor: defensor,
        arma: espada,
        d20Teste: 10,
        ataqueNaoLetal: false,
      );
      expect(normal.acerto, isTrue);

      // Ataque não letal: 10 + 5 - 5 = 10 < 15 (defesa) -> Erro
      final naoLetal = engine.executarAtaque(
        atacante: atacante,
        defensor: defensor,
        arma: espada,
        d20Teste: 10,
        ataqueNaoLetal: true,
      );
      expect(naoLetal.acerto, isFalse);
      expect(naoLetal.totalAtaque, 10);
    });
  });

  group('2. Motor de Movimentação no Grid Tático 2D (Dijkstra)', () {
    final mapa = GridMapa(
      largura: 8,
      altura: 8,
      terrenos: {
        const Posicao2D(1, 0): TipoTerreno.obstaculo,
        const Posicao2D(0, 1): TipoTerreno.dificil,
      },
    );

    const heroi = Combatente(
      id: 'h1',
      nome: 'Herói',
      time: TimeCombatente.heroi,
      pvMax: 20,
      pvAtual: 20,
      pmMax: 0,
      pmAtual: 0,
      defesa: 10,
      deslocamentoMetros: 9.0, // 9 metros = 6 quadrados normais
      modIniciativa: 0,
      modLuta: 0,
      modPontaria: 0,
      modPercepcao: 0,
      modForca: 0,
      modDestreza: 0,
      modConstituicao: 0,
    );

    test('Custos de Terreno: Ortogonal 1.5m, Diagonal 3.0m, Difícil 3.0m', () {
      final res = MovimentoEngine.calcularAlcancaveis(
        mapa: mapa,
        inicio: const Posicao2D(0, 0),
        deslocamentoMaximoMetros: 9.0,
        posicoesCombatentes: {'h1': const Posicao2D(0, 0)},
        combatentesPorId: {'h1': heroi},
        combatenteAtivoId: 'h1',
      );

      // (1, 0) é obstáculo -> inalcançável
      expect(res.destinosValidos.contains(const Posicao2D(1, 0)), isFalse);

      // (0, 1) é terreno difícil ortogonal -> custo = 1.5 * 2 = 3.0m
      expect(res.custosMetros[const Posicao2D(0, 1)], 3.0);

      // (1, 1) é diagonal em terreno normal -> custo = 3.0m
      expect(res.custosMetros[const Posicao2D(1, 1)], 3.0);
    });

    test('Bloqueio por Inimigo Ativo vs Travessia por Aliado', () {
      const aliado = Combatente(
        id: 'aliado',
        nome: 'Aliado',
        time: TimeCombatente.heroi,
        pvMax: 20,
        pvAtual: 20,
        pmMax: 0,
        pmAtual: 0,
        defesa: 10,
        deslocamentoMetros: 9.0,
        modIniciativa: 0,
        modLuta: 0,
        modPontaria: 0,
        modPercepcao: 0,
        modForca: 0,
        modDestreza: 0,
        modConstituicao: 0,
      );

      const inimigo = Combatente(
        id: 'inimigo',
        nome: 'Orc',
        time: TimeCombatente.inimigo,
        pvMax: 20,
        pvAtual: 20,
        pmMax: 0,
        pmAtual: 0,
        defesa: 10,
        deslocamentoMetros: 9.0,
        modIniciativa: 0,
        modLuta: 0,
        modPontaria: 0,
        modPercepcao: 0,
        modForca: 0,
        modDestreza: 0,
        modConstituicao: 0,
      );

      // Aliado em (0, 1): herói pode atravessar até (0, 2), mas não pode terminar em (0, 1)
      final resComAliado = MovimentoEngine.calcularAlcancaveis(
        mapa: const GridMapa(largura: 5, altura: 5),
        inicio: const Posicao2D(0, 0),
        deslocamentoMaximoMetros: 9.0,
        posicoesCombatentes: {
          'h1': const Posicao2D(0, 0),
          'aliado': const Posicao2D(0, 1),
        },
        combatentesPorId: {
          'h1': heroi,
          'aliado': aliado,
        },
        combatenteAtivoId: 'h1',
      );
      expect(resComAliado.destinosValidos.contains(const Posicao2D(0, 1)), isFalse); // Ocupado
      expect(resComAliado.destinosValidos.contains(const Posicao2D(0, 2)), isTrue); // Pode passar por ele!

      // Inimigo ativo em (0, 1): herói NÃO pode atravessar para (0, 2)
      final resComInimigo = MovimentoEngine.calcularAlcancaveis(
        mapa: const GridMapa(largura: 5, altura: 5),
        inicio: const Posicao2D(0, 0),
        deslocamentoMaximoMetros: 3.0,
        posicoesCombatentes: {
          'h1': const Posicao2D(0, 0),
          'inimigo': const Posicao2D(0, 1),
        },
        combatentesPorId: {
          'h1': heroi,
          'inimigo': inimigo,
        },
        combatenteAtivoId: 'h1',
      );
      // Inimigo bloqueia passagem
      expect(resComInimigo.destinosValidos.contains(const Posicao2D(0, 1)), isFalse);
      expect(resComInimigo.custosMetros.containsKey(const Posicao2D(0, 2)), isFalse);
    });

    test('Travessia sobre Inimigo Caído/Inconsciente custa como Terreno Difícil', () {
      const inimigoCaido = Combatente(
        id: 'inimigo_caido',
        nome: 'Orc Caído',
        time: TimeCombatente.inimigo,
        pvMax: 20,
        pvAtual: -2,
        estadoVida: EstadoVidaCombatente.inconscienteSangrando,
        pmMax: 0,
        pmAtual: 0,
        defesa: 10,
        deslocamentoMetros: 9.0,
        modIniciativa: 0,
        modLuta: 0,
        modPontaria: 0,
        modPercepcao: 0,
        modForca: 0,
        modDestreza: 0,
        modConstituicao: 0,
      );

      final res = MovimentoEngine.calcularAlcancaveis(
        mapa: const GridMapa(largura: 5, altura: 5),
        inicio: const Posicao2D(0, 0),
        deslocamentoMaximoMetros: 9.0,
        posicoesCombatentes: {
          'h1': const Posicao2D(0, 0),
          'inimigo_caido': const Posicao2D(0, 1),
        },
        combatentesPorId: {
          'h1': heroi,
          'inimigo_caido': inimigoCaido,
        },
        combatenteAtivoId: 'h1',
      );

      // Pode atravessar o caído até (0, 2). Custo de passar por ele = 3.0m (terreno difícil) + 1.5m = 4.5m
      expect(res.destinosValidos.contains(const Posicao2D(0, 2)), isTrue);
      expect(res.custosMetros[const Posicao2D(0, 2)], 4.5);
    });
  });

  group('3. Fim de Combate (Vitória e Derrota)', () {
    test('Vitória quando todos os inimigos são mortos ou incapacitados', () {
      final cubit = CombateCubit();
      const h1 = Combatente(
        id: 'h1',
        nome: 'Herói',
        time: TimeCombatente.heroi,
        pvMax: 20,
        pvAtual: 20,
        pmMax: 0,
        pmAtual: 0,
        defesa: 10,
        deslocamentoMetros: 9.0,
        modIniciativa: 10,
        modLuta: 10,
        modPontaria: 0,
        modPercepcao: 0,
        modForca: 2,
        modDestreza: 0,
        modConstituicao: 2,
      );

      const ini = Combatente(
        id: 'ini',
        nome: 'Goblin Fraco',
        time: TimeCombatente.inimigo,
        pvMax: 5,
        pvAtual: 1,
        pmMax: 0,
        pmAtual: 0,
        defesa: 10,
        deslocamentoMetros: 9.0,
        modIniciativa: 0,
        modLuta: 0,
        modPontaria: 0,
        modPercepcao: 0,
        modForca: 0,
        modDestreza: 0,
        modConstituicao: 0,
      );

      cubit.iniciarCombate([h1, ini]);

      // Aplica dano fatal no goblin
      final goblinMorto = ini.aplicarDano(20, naoLetal: false);
      cubit.atualizarCombatente(goblinMorto);

      expect(cubit.state.statusCombate, StatusCombate.vitoria);
      expect(cubit.state.logCombate.last, contains('VITÓRIA'));
    });
  });

  group('4. Validação de Alcance no Grid e IA Tática do Bot', () {
    const espada = Arma(
      key: 'ESPADA',
      nome: 'Espada Longa',
      descricao: '',
      proficiencia: ProficienciaArma.marcial,
      proposito: PropositoArma.corpoACorpo,
      empunhadura: EmpunhaduraArma.umaMao,
      dano: '1d8',
      tipoDano: TipoDanoArma.corte,
    );

    const heroi = Combatente(
      id: 'heroi',
      nome: 'Guerreiro',
      time: TimeCombatente.heroi,
      pvMax: 30,
      pvAtual: 30,
      pmMax: 0,
      pmAtual: 0,
      defesa: 15,
      deslocamentoMetros: 9.0,
      modIniciativa: 10,
      modLuta: 5,
      modPontaria: 0,
      modPercepcao: 0,
      modForca: 3,
      modDestreza: 1,
      modConstituicao: 2,
      armas: [espada],
    );

    const inimigo = Combatente(
      id: 'inimigo',
      nome: 'Orc',
      time: TimeCombatente.inimigo,
      pvMax: 25,
      pvAtual: 25,
      pmMax: 0,
      pmAtual: 0,
      defesa: 14,
      deslocamentoMetros: 9.0,
      modIniciativa: 0,
      modLuta: 4,
      modPontaria: 0,
      modPercepcao: 0,
      modForca: 3,
      modDestreza: 0,
      modConstituicao: 2,
      armas: [espada],
    );

    test('Ataque corpo a corpo é bloqueado quando o inimigo está longe (> 1.5m)', () {
      final cubit = CombateCubit();
      // Heroi em (1, 1) e Inimigo em (5, 5) -> Distância Chebyshev = 4 quadrados = 6.0m
      cubit.iniciarCombate(
        [heroi, inimigo],
        posicoesIniciais: {
          'heroi': const Posicao2D(1, 1),
          'inimigo': const Posicao2D(5, 5),
        },
      );

      cubit.executarAtaque(defensor: inimigo, arma: espada);

      // Ação padrão não deve ser gasta e deve avisar sobre o alcance no log
      expect(cubit.state.acoesPadraoRestantes, 1);
      expect(cubit.state.logCombate.last, contains('fora de alcance'));
    });

    test('Ataque corpo a corpo funciona quando os combatentes estão adjacentes (1.5m)', () {
      final cubit = CombateCubit();
      // Heroi em (1, 1) e Inimigo em (1, 2) -> Adjacente (1.5m)
      cubit.iniciarCombate(
        [heroi, inimigo],
        posicoesIniciais: {
          'heroi': const Posicao2D(1, 1),
          'inimigo': const Posicao2D(1, 2),
        },
      );

      final atacante = cubit.state.combatenteAtual!;
      final defensor =
          cubit.state.filaIniciativa.firstWhere((c) => c.id != atacante.id);

      cubit.executarAtaque(defensor: defensor, arma: espada);

      // Deve consumir a ação padrão e registrar o ataque
      expect(cubit.state.acoesPadraoRestantes, 0);
      expect(
        cubit.state.logCombate.any((l) => l.contains('atacou') || l.contains('acertou') || l.contains('errou')),
        isTrue,
      );
    });

    test('IA do bot move-se taticamente no grid para se aproximar do herói', () {
      final cubit = CombateCubit();
      // Heroi em (1, 1) e Bot em (1, 4) -> 3 quadrados de distância (4.5m)
      cubit.iniciarCombate(
        [heroi, inimigo],
        posicoesIniciais: {
          'inimigo': const Posicao2D(1, 4),
          'heroi': const Posicao2D(1, 1),
        },
      );

      // Avança o turno até ser a vez do bot (Time inimigo)
      while (cubit.state.combatenteAtual?.time != TimeCombatente.inimigo) {
        cubit.proximoTurno();
      }

      final posInicialBot = cubit.state.posicoesCombatentes['inimigo']!;
      cubit.executarTurnoBot();

      final posFinalBot = cubit.state.posicoesCombatentes['inimigo']!;
      // O bot deve ter se movido em direção ao herói (diminuindo a distância)
      expect(
        posFinalBot.distanciaEmQuadrados(const Posicao2D(1, 1)),
        lessThan(posInicialBot.distanciaEmQuadrados(const Posicao2D(1, 1))),
      );
    });
  });
}
