import 'package:flutter_test/flutter_test.dart';
import 'package:t20_creator/domain/entities/combate/combatente.dart';
import 'package:t20_creator/domain/entities/combate/estado_vida_combatente.dart';
import 'package:t20_creator/domain/entities/combate/grid_tatico.dart';
import 'package:t20_creator/domain/entities/combate/tipo_acao.dart';
import 'package:t20_creator/domain/entities/combate/tipo_dano.dart';
import 'package:t20_creator/domain/entities/equipamento/arma.dart';
import 'package:t20_creator/domain/entities/habilidades/modelos_habilidade_duracao.dart';
import 'package:t20_creator/domain/entities/testes/configuracoes_mesa_t20.dart';
import 'package:t20_creator/domain/services/combate_services/calculadora_tatica_t20.dart';
import 'package:t20_creator/domain/services/combate_services/combate_engine.dart';
import 'package:t20_creator/domain/services/combate_services/movimento_engine.dart';
import 'package:t20_creator/domain/services/habilidades_services/duracao_engine.dart';
import 'package:t20_creator/domain/services/habilidades_services/relogio_e_cena_service.dart';
import 'package:t20_creator/domain/services/testes_services/i_rng.dart';
import 'package:t20_creator/presentation/controllers/combate_controller/combate_cubit.dart';

void main() {
  const espadaLonga = Arma(
    key: 'espada_longa',
    nome: 'Espada Longa',
    descricao: '',
    proficiencia: ProficienciaArma.marcial,
    proposito: PropositoArma.corpoACorpo,
    empunhadura: EmpunhaduraArma.umaMao,
    dano: '1d8',
    margemAmeaca: 19,
    multiplicadorCritico: 2,
    tipoDano: TipoDanoArma.corte,
  );

  const arcoCurto = Arma(
    key: 'arco_curto',
    nome: 'Arco Curto',
    descricao: '',
    proficiencia: ProficienciaArma.simples,
    proposito: PropositoArma.disparo,
    empunhadura: EmpunhaduraArma.duasMaos,
    dano: '1d6',
    margemAmeaca: 20,
    multiplicadorCritico: 3,
    tipoDano: TipoDanoArma.perfuracao,
    alcance: 'Curto',
  );

  group('Auditoria R59 & I2 — Duração em Rodadas e TurnClock', () {
    test('Duração em rodadas expira imediatamente antes da mesma iniciativa (R59)', () {
      final duracaoEngine = DuracaoEngine(
        configuracoes: const ConfiguracoesMesaT20(
          expiracaoRodadas: ModoExpiracaoRodadas.antesDaMesmaIniciativa,
        ),
      );

      final efeito = EfeitoAtivo(
        id: 'ef_1',
        habilidadeId: 'bencao',
        nomeHabilidade: 'Bênção',
        usuarioId: 'heroi_1',
        alvos: const ['heroi_1'],
        duracao: const Duracao(
          tipo: TipoDuracao.definida,
          definida: DuracaoDefinida(quantidade: 2, unidade: UnidadeDuracao.rodada),
        ),
        estado: EstadoEfeito.ativo,
        inicio: const InicioEfeito(
          tempoSegundos: 6,
          rodada: 1,
          cenaId: 'cena_1',
          iniciativa: 15,
        ),
        expiraNaRodada: 3, // Começou na 1, dura 2 -> expira na 3 antes da ini 15
        modificadores: const [],
      );

      // Rodada 2: ainda ativo
      var resultado = duracaoEngine.processarInicioTurno(
        personagemId: 'heroi_1',
        rodada: 2,
        efeitos: [efeito],
        areasPersistentes: const {},
        personagens: const {},
        relogio: const RelogioDeJogo(rodadaAtual: 2, tempoSegundos: 12),
        cenaAtual: const Cena(id: 'cena_1', nome: 'Combate', ativa: true, inicioSegundos: 0),
        sustentacoesPendentes: const {},
        paresConsumidos: const {},
        controleDeAcoes: ControleDeAcoesPermissivo(),
        iniciativaTurno: 15,
      );
      expect(resultado.efeitos.first.estaEmJogo, isTrue);

      // Rodada 3: antes da iniciativa 15 (quando chega a iniciativa 15) -> expira!
      resultado = duracaoEngine.processarInicioTurno(
        personagemId: 'heroi_1',
        rodada: 3,
        efeitos: [efeito],
        areasPersistentes: const {},
        personagens: const {},
        relogio: const RelogioDeJogo(rodadaAtual: 3, tempoSegundos: 18),
        cenaAtual: const Cena(id: 'cena_1', nome: 'Combate', ativa: true, inicioSegundos: 0),
        sustentacoesPendentes: const {},
        paresConsumidos: const {},
        controleDeAcoes: ControleDeAcoesPermissivo(),
        iniciativaTurno: 15,
      );
      expect(resultado.efeitos.first.estado, EstadoEfeito.expirado);
    });
  });

  group('Auditoria R60 & I3 — Economia de Ações por Turno', () {
    test('ControleDeAcoesCombate: 1 padrão + 1 movimento, conversão de padrão em movimento e ação completa', () {
      final controle = ControleDeAcoesCombate();
      controle.iniciarTurno('heroi_1');

      // Inicialmente tem padrão e movimento
      expect(controle.temAcaoDisponivel('heroi_1', TipoAcao.padrao), isTrue);
      expect(controle.temAcaoDisponivel('heroi_1', TipoAcao.movimento), isTrue);
      expect(controle.temAcaoDisponivel('heroi_1', TipoAcao.completa), isTrue);
      expect(controle.temAcaoDisponivel('heroi_1', TipoAcao.livre), isTrue);
      expect(controle.temAcaoDisponivel('heroi_1', TipoAcao.reacao), isTrue);

      // Consome movimento
      controle.consumirAcao('heroi_1', TipoAcao.movimento);
      expect(controle.acoesMovimentoRestantes('heroi_1'), 0);
      expect(controle.acoesPadraoRestantes('heroi_1'), 1);

      // Pode converter padrão em um 2º movimento
      expect(controle.temAcaoDisponivel('heroi_1', TipoAcao.movimento), isTrue);
      controle.consumirAcao('heroi_1', TipoAcao.movimento);
      expect(controle.acoesPadraoRestantes('heroi_1'), 0);
      expect(controle.temAcaoDisponivel('heroi_1', TipoAcao.padrao), isFalse);
      expect(controle.temAcaoDisponivel('heroi_1', TipoAcao.movimento), isFalse);

      // Livre e reação continuam sempre disponíveis (A4)
      expect(controle.temAcaoDisponivel('heroi_1', TipoAcao.livre), isTrue);
      expect(controle.temAcaoDisponivel('heroi_1', TipoAcao.reacao), isTrue);
    });
  });

  group('Auditoria R61, R63 & A5 — Ações Especiais de Combate', () {
    const atacante = Combatente(
      id: 'atk',
      nome: 'Guerreiro',
      pvMax: 30,
      pvAtual: 30,
      pmMax: 10,
      pmAtual: 10,
      defesa: 15,
      modIniciativa: 4,
      modLuta: 6,
      modPontaria: 4,
      modPercepcao: 2,
      modForca: 3,
      modDestreza: 2,
      modConstituicao: 2,
      armas: [espadaLonga],
    );

    const defensor = Combatente(
      id: 'def',
      nome: 'Monstro',
      pvMax: 40,
      pvAtual: 40,
      pmMax: 0,
      pmAtual: 0,
      defesa: 14,
      modIniciativa: 1,
      modLuta: 4,
      modPontaria: 1,
      modPercepcao: 0,
      modForca: 2,
      modDestreza: 0,
      modConstituicao: 2,
    );

    test('Fintar: Enganação vs Reflexos, alvo fica desprevenido com sucesso (R61)', () {
      final engine = CombateEngine();
      final resSucesso = engine.executarFintar(
        atacante: atacante,
        defensor: defensor,
        d20Enganacao: 15,
        d20Reflexos: 10,
        modEnganacaoAtacante: 5,
        modReflexosDefensor: 2,
      );
      expect(resSucesso.sucesso, isTrue);
      expect(resSucesso.defensorAtualizado.estaDesprevenido, isTrue);
    });

    test('Preparar Ação: ajusta a iniciativa para antes do gatilho ao disparar (R61 / A5)', () {
      final engine = CombateEngine();
      final filaInicial = [
        atacante.copyWith(iniciativaValor: 20),
        defensor.copyWith(iniciativaValor: 12),
      ];

      final preparou = engine.prepararAcao(
        combatenteId: atacante.id,
        condicaoGatilho: 'Quando o monstro se aproximar',
        tipoAcao: TipoAcao.padrao,
        iniciativaOriginal: 20,
      );
      expect(preparou.combatenteId, atacante.id);

      // Dispara quando o monstro age em iniciativa 12
      final filaAposDisparo = engine.dispararAcaoPreparada(
        filaAtual: filaInicial,
        combatenteId: atacante.id,
        iniciativaGatilho: 12,
      );
      final atacanteAtualizado = filaAposDisparo.firstWhere((c) => c.id == atacante.id);
      expect(atacanteAtualizado.iniciativaValor, 13);
      expect(filaAposDisparo.first.id, atacante.id);
    });

    test('Investida: exige min 3m, dobro de deslocamento e aplica +2 ataque / -2 Defesa (R63)', () {
      final engine = CombateEngine();

      expect(
        () => engine.executarInvestida(
          atacante: atacante,
          defensor: defensor,
          arma: espadaLonga,
          distanciaMetros: 2.0, // menor que 3m
        ),
        throwsArgumentError,
      );

      final res = engine.executarInvestida(
        atacante: atacante,
        defensor: defensor,
        arma: espadaLonga,
        distanciaMetros: 6.0,
        d20Teste: 10,
      );
      // d20 (10) + modLuta (6) + investida (+2) = 18 >= 14 (defesa) -> acerto
      expect(res.ataque.acerto, isTrue);
      expect(res.ataque.totalAtaque, 18);
      expect(res.penalidadeDefesaAtacante, -2);
    });

    test('Golpe de Misericórdia: exige alvo indefeso, crítico automático e d4 de morte instantânea (R63)', () {
      final engine = CombateEngine();
      final defensorIndefeso = defensor.copyWith(
        condicoesAtivas: [CondicaoCombatente.indefeso],
      );

      // Rolagem d4 = 1 mata personagem importante / herói (25% chance)
      final resMorte = engine.executarGolpeDeMisericordia(
        atacante: atacante,
        defensor: defensorIndefeso,
        arma: espadaLonga,
        ehNpcSecundario: false,
        d4Morte: 1,
      );
      expect(resMorte.ataque.ehCritico, isTrue);
      expect(resMorte.morteInstantanea, isTrue);
      expect(resMorte.defensorAtualizado.estaMorto, isTrue);

      // Rolagem d4 = 2 não mata herói
      final resSobreviveu = engine.executarGolpeDeMisericordia(
        atacante: atacante,
        defensor: defensorIndefeso,
        arma: espadaLonga,
        ehNpcSecundario: false,
        d4Morte: 2,
      );
      expect(resSobreviveu.morteInstantanea, isFalse);
    });

    test('Atropelar: teste de Luta oposto, derruba alvo com sucesso (R61)', () {
      final engine = CombateEngine();
      final res = engine.executarAtropelar(
        atacante: atacante,
        defensor: defensor,
        d20Atacante: 12, // 12 + 6 = 18
        d20Defensor: 8, // 8 + 4 = 12
      );
      expect(res.atacanteVenceu, isTrue);
      expect(res.defensorAtualizado.estaCaido, isTrue);
    });
  });

  group('Auditoria R67 & R68 — Crítico, Imunidades e Iniciativa de Inimigos', () {
    test('Iniciativa de Inimigos (R68): Mestre faz UM teste para inimigos usando menor bônus', () {
      const orc1 = Combatente(
        id: 'orc1',
        nome: 'Orc Guerreiro',
        time: TimeCombatente.inimigo,
        pvMax: 20,
        pvAtual: 20,
        pmMax: 0,
        pmAtual: 0,
        defesa: 14,
        modIniciativa: 4,
        modLuta: 4,
        modPontaria: 2,
        modPercepcao: 1,
        modForca: 3,
        modDestreza: 2,
        modConstituicao: 2,
      );

      const orc2 = Combatente(
        id: 'orc2',
        nome: 'Orc Chefe',
        time: TimeCombatente.inimigo,
        pvMax: 30,
        pvAtual: 30,
        pmMax: 0,
        pmAtual: 0,
        defesa: 16,
        modIniciativa: 2, // Menor modificador entre os inimigos
        modLuta: 6,
        modPontaria: 3,
        modPercepcao: 2,
        modForca: 4,
        modDestreza: 1,
        modConstituicao: 3,
      );

      const heroi = Combatente(
        id: 'heroi',
        nome: 'Guerreiro',
        time: TimeCombatente.heroi,
        pvMax: 25,
        pvAtual: 25,
        pmMax: 0,
        pmAtual: 0,
        defesa: 15,
        modIniciativa: 3,
        modLuta: 5,
        modPontaria: 1,
        modPercepcao: 2,
        modForca: 3,
        modDestreza: 1,
        modConstituicao: 2,
      );

      final engine = CombateEngine();
      // d20InimigoForcado = 10 -> 10 + min(4, 2) = 12 para ambos os orcs
      // d20Heroi = 15 -> 15 + 3 = 18
      final fila = engine.rolarIniciativa(
        [heroi, orc1, orc2],
        d20InimigoForcado: 10,
        d20JogadoresForcados: {'heroi': 15},
      );

      final rOrc1 = fila.firstWhere((c) => c.id == 'orc1');
      final rOrc2 = fila.firstWhere((c) => c.id == 'orc2');
      final rHeroi = fila.firstWhere((c) => c.id == 'heroi');

      expect(rHeroi.iniciativaValor, 18);
      expect(rOrc1.iniciativaValor, 12);
      expect(rOrc2.iniciativaValor, 12);
    });

    test('Criatura imune a crítico recebe dano normal sem multiplicar (R67)', () {
      const atacante = Combatente(
        id: 'atk',
        nome: 'Guerreiro',
        pvMax: 20,
        pvAtual: 20,
        pmMax: 0,
        pmAtual: 0,
        defesa: 10,
        modIniciativa: 0,
        modLuta: 5,
        modPontaria: 0,
        modPercepcao: 0,
        modForca: 3,
        modDestreza: 0,
        modConstituicao: 0,
        armas: [espadaLonga],
      );

      const golem = Combatente(
        id: 'golem',
        nome: 'Golem de Ferro',
        pvMax: 40,
        pvAtual: 40,
        pmMax: 0,
        pmAtual: 0,
        defesa: 12,
        modIniciativa: 0,
        modLuta: 5,
        modPontaria: 0,
        modPercepcao: 0,
        modForca: 4,
        modDestreza: 0,
        modConstituicao: 4,
        imuneACritico: true, // Imunidade a crítico
      );

      final engine = CombateEngine();
      // d20 = 20 acerta e atinge margem de ameaça, mas golem é imune a crítico
      final res = engine.executarAtaque(
        atacante: atacante,
        defensor: golem,
        arma: espadaLonga,
        d20Teste: 20,
      );

      expect(res.acerto, isTrue);
      expect(res.ehCritico, isFalse);
    });
  });

  group('Auditoria R69 & R70 — Surpresa no Combate', () {
    test('Surpreendido pula a 1ª rodada e age normalmente a partir da 2ª (R69, R70)', () {
      const heroi = Combatente(
        id: 'heroi',
        nome: 'Guerreiro',
        time: TimeCombatente.heroi,
        pvMax: 20,
        pvAtual: 20,
        pmMax: 0,
        pmAtual: 0,
        defesa: 15,
        modIniciativa: 5,
        modLuta: 4,
        modPontaria: 2,
        modPercepcao: 2,
        modForca: 2,
        modDestreza: 2,
        modConstituicao: 2,
      );

      const monstroSurpreendido = Combatente(
        id: 'monstro',
        nome: 'Goblin Emboscado',
        time: TimeCombatente.inimigo,
        pvMax: 10,
        pvAtual: 10,
        pmMax: 0,
        pmAtual: 0,
        defesa: 13,
        modIniciativa: 1,
        modLuta: 2,
        modPontaria: 3,
        modPercepcao: 0,
        modForca: 0,
        modDestreza: 3,
        modConstituicao: 0,
        condicoesAtivas: [CondicaoCombatente.surpreendido],
      );

      final cubit = CombateCubit();
      cubit.iniciarCombate(
        [heroi, monstroSurpreendido],
        iniciativas: {'heroi': 15, 'monstro': 10},
      );

      expect(cubit.state.combatenteAtual?.id, 'heroi');
      expect(cubit.state.rodadaAtual, 1);

      // Heroi encerra seu turno: próximo seria o monstro, mas ele pula porque está surpreendido na rodada 1!
      cubit.proximoTurno();

      // Já avança para a Rodada 2 e é a vez do Heroi novamente (e o monstro perde a surpresa)
      expect(cubit.state.rodadaAtual, 2);
      final monstroNaRodada2 = cubit.state.filaIniciativa.firstWhere((c) => c.id == 'monstro');
      expect(monstroNaRodada2.ehSurpreendido, isFalse);
    });
  });

  group('Auditoria R71, R72 & I6 — PV, Dano Não Letal e Cura', () {
    test('Dano não letal acumula sem matar; cura recupera primeiro dano não letal (R71, R72)', () {
      const monge = Combatente(
        id: 'monge',
        nome: 'Monge',
        pvMax: 20,
        pvAtual: 15,
        pmMax: 0,
        pmAtual: 0,
        defesa: 15,
        modIniciativa: 2,
        modLuta: 4,
        modPontaria: 2,
        modPercepcao: 2,
        modForca: 2,
        modDestreza: 2,
        modConstituicao: 2,
      );

      // Dano não-letal de 15: iguala PV atual (15) -> estabilizado/desmaiado, PV intacto
      final nocauteado = monge.aplicarDano(15, naoLetal: true);
      expect(nocauteado.pvAtual, 15);
      expect(nocauteado.danoNaoLetal, 15);
      expect(nocauteado.estadoVida, EstadoVidaCombatente.estabilizado);
      expect(nocauteado.estaInconsciente, isTrue);

      // Cura de 10: remove 10 do dano não letal (resta 5)
      final parcialmenteCurado = nocauteado.aplicarCura(10);
      expect(parcialmenteCurado.danoNaoLetal, 5);
      expect(parcialmenteCurado.pvAtual, 15); // Sobra 0 para PV
      expect(parcialmenteCurado.estadoVida, EstadoVidaCombatente.ativo); // 5 < 15 -> acorda!

      // Cura de 10: remove os 5 restantes de dano não letal e cura 5 de PV (15 -> 20)
      final totalmenteCurado = parcialmenteCurado.aplicarCura(10);
      expect(totalmenteCurado.danoNaoLetal, 0);
      expect(totalmenteCurado.pvAtual, 20);
      expect(totalmenteCurado.estadoVida, EstadoVidaCombatente.ativo);
    });
  });

  group('Auditoria R73 — Movimentação Através de Inimigo Caído/Indefeso', () {
    test('Atravessa inimigo caído ou indefeso contando como terreno difícil (R73)', () {
      const mapa = GridMapa(largura: 5, altura: 1);
      const heroi = Combatente(
        id: 'heroi',
        nome: 'Guerreiro',
        time: TimeCombatente.heroi,
        pvMax: 20,
        pvAtual: 20,
        pmMax: 0,
        pmAtual: 0,
        defesa: 15,
        modIniciativa: 0,
        modLuta: 0,
        modPontaria: 0,
        modPercepcao: 0,
        modForca: 0,
        modDestreza: 0,
        modConstituicao: 0,
      );

      const inimigoEmPe = Combatente(
        id: 'ini_pe',
        nome: 'Inimigo Em Pé',
        time: TimeCombatente.inimigo,
        pvMax: 20,
        pvAtual: 20,
        pmMax: 0,
        pmAtual: 0,
        defesa: 10,
        modIniciativa: 0,
        modLuta: 0,
        modPontaria: 0,
        modPercepcao: 0,
        modForca: 0,
        modDestreza: 0,
        modConstituicao: 0,
      );

      const inimigoCaido = Combatente(
        id: 'ini_caido',
        nome: 'Inimigo Caído',
        time: TimeCombatente.inimigo,
        pvMax: 20,
        pvAtual: 20,
        pmMax: 0,
        pmAtual: 0,
        defesa: 10,
        modIniciativa: 0,
        modLuta: 0,
        modPontaria: 0,
        modPercepcao: 0,
        modForca: 0,
        modDestreza: 0,
        modConstituicao: 0,
        condicoesAtivas: [CondicaoCombatente.caido],
      );

      // Inimigo em pé bloqueia passagem
      final resBloqueado = MovimentoEngine.calcularAlcancaveis(
        mapa: mapa,
        inicio: const Posicao2D(0, 0),
        deslocamentoMaximoMetros: 9.0,
        posicoesCombatentes: {
          'heroi': const Posicao2D(0, 0),
          'ini_pe': const Posicao2D(1, 0),
        },
        combatentesPorId: {'heroi': heroi, 'ini_pe': inimigoEmPe},
        combatenteAtivoId: 'heroi',
      );
      expect(resBloqueado.destinosValidos.contains(const Posicao2D(2, 0)), isFalse);

      // Inimigo caído permite travessia (como terreno difícil)
      final resPermitido = MovimentoEngine.calcularAlcancaveis(
        mapa: mapa,
        inicio: const Posicao2D(0, 0),
        deslocamentoMaximoMetros: 9.0,
        posicoesCombatentes: {
          'heroi': const Posicao2D(0, 0),
          'ini_caido': const Posicao2D(1, 0),
        },
        combatentesPorId: {'heroi': heroi, 'ini_caido': inimigoCaido},
        combatenteAtivoId: 'heroi',
      );
      expect(resPermitido.destinosValidos.contains(const Posicao2D(2, 0)), isTrue);
    });
  });

  group('Auditoria R74, R75 & I4 — Chance de Falha e Flanquear em Lados Opostos', () {
    test('Chance de falha acumula até teto de 75% e d100 faz errar automaticamente (R74, I4)', () {
      const atacanteCego = Combatente(
        id: 'atk',
        nome: 'Atacante Cego',
        pvMax: 20,
        pvAtual: 20,
        pmMax: 0,
        pmAtual: 0,
        defesa: 10,
        modIniciativa: 0,
        modLuta: 10,
        modPontaria: 0,
        modPercepcao: 0,
        modForca: 2,
        modDestreza: 0,
        modConstituicao: 0,
        condicoesAtivas: [CondicaoCombatente.cego], // 50%
      );

      const defensor = Combatente(
        id: 'def',
        nome: 'Alvo',
        pvMax: 20,
        pvAtual: 20,
        pmMax: 0,
        pmAtual: 0,
        defesa: 10,
        modIniciativa: 0,
        modLuta: 0,
        modPontaria: 0,
        modPercepcao: 0,
        modForca: 0,
        modDestreza: 0,
        modConstituicao: 0,
      );

      final engine = CombateEngine();

      // Cego (50%) + Camuflagem leve (20%) = 70% de falha. d100 = 50 <= 70 -> Falha!
      final resFalha = engine.executarAtaque(
        atacante: atacanteCego,
        defensor: defensor,
        arma: espadaLonga,
        camuflagemLeve: true,
        d20Teste: 20,
        d100ChanceFalha: 50,
      );
      expect(resFalha.acerto, isFalse);
      expect(resFalha.detalheDano, contains('Chance de Falha'));

      // d100 = 85 > 70 -> Supera chance de falha e acerta
      final resSucesso = engine.executarAtaque(
        atacante: atacanteCego,
        defensor: defensor,
        arma: espadaLonga,
        camuflagemLeve: true,
        d20Teste: 20,
        d100ChanceFalha: 85,
      );
      expect(resSucesso.acerto, isTrue);
    });

    test('Flanquear exige estritamente lados opostos em relação ao defensor (R75)', () {
      // Inimigo no centro (4, 4)
      const posInimigo = Posicao2D(4, 4);

      // Aliado 1 à esquerda (3, 4), Aliado 2 à direita (5, 4): Lados opostos!
      final flancoOposto = CalculadoraTaticaT20.estaoFlanqueando(
        atacante: const Posicao2D(3, 4),
        aliado: const Posicao2D(5, 4),
        defensor: posInimigo,
      );
      expect(flancoOposto, isTrue);

      // Diagonal oposta: (3, 3) e (5, 5)
      final flancoDiag = CalculadoraTaticaT20.estaoFlanqueando(
        atacante: const Posicao2D(3, 3),
        aliado: const Posicao2D(5, 5),
        defensor: posInimigo,
      );
      expect(flancoDiag, isTrue);

      // Adjacentes em 90 graus (3, 4) e (4, 3): NÃO é flanco!
      final flancoInvalido = CalculadoraTaticaT20.estaoFlanqueando(
        atacante: const Posicao2D(3, 4),
        aliado: const Posicao2D(4, 3),
        defensor: posInimigo,
      );
      expect(flancoInvalido, isFalse);
    });
  });

  group('Auditoria R76 — Objetos e Manobra Quebrar', () {
    test('Manobra Quebrar objeto: RD reduz dano, objeto destruído quando PV <= 0 (R76)', () {
      const atacante = Combatente(
        id: 'atk',
        nome: 'Guerreiro com Machado',
        pvMax: 20,
        pvAtual: 20,
        pmMax: 0,
        pmAtual: 0,
        defesa: 10,
        modIniciativa: 0,
        modLuta: 5,
        modPontaria: 0,
        modPercepcao: 0,
        modForca: 4,
        modDestreza: 0,
        modConstituicao: 0,
      );

      final engine = CombateEngine();

      // Escudo de Madeira: Defesa 15, PV 10, RD 5
      final res = engine.executarManobraQuebrar(
        atacante: atacante,
        armaAtacante: espadaLonga,
        defesaObjeto: 15,
        pvMaxObjeto: 10,
        pvAtualObjeto: 10,
        rdObjeto: 5,
        d20Teste: 12, // 12 + 5 = 17 >= 15 -> acerto
      );

      expect(res.acerto, isTrue);
      // Dano = 1d8 + 4 (FOR) - 5 (RD)
      expect(res.pvRestantesObjeto, lessThanOrEqualTo(10));
    });
  });

  group('Auditoria I1 — Morte Dispara Evento de Morte e Encerra Sustentadas (R47)', () {
    test('Morte no combate emite PersonagemMorreu e cancela sustentadas do usuário', () {
      final eventos = <EventoTurnClock>[];
      final cubit = CombateCubit(
        engine: CombateEngine(rng: SequenciaRng([15])),
        onEventoTurnClock: (ev) => eventos.add(ev),
      );

      const heroi = Combatente(
        id: 'heroi',
        nome: 'Guerreiro Letal',
        pvMax: 30,
        pvAtual: 30,
        pmMax: 0,
        pmAtual: 0,
        defesa: 15,
        modIniciativa: 5,
        modLuta: 10,
        modPontaria: 0,
        modPercepcao: 0,
        modForca: 5,
        modDestreza: 0,
        modConstituicao: 0,
        armas: [espadaLonga],
      );

      const minion = Combatente(
        id: 'goblin',
        nome: 'Goblin Frágil',
        time: TimeCombatente.inimigo,
        pvMax: 4,
        pvAtual: 2, // Limite de morte = min(-10, -2) = -10
        pmMax: 0,
        pmAtual: 0,
        defesa: 10,
        modIniciativa: 0,
        modLuta: 0,
        modPontaria: 0,
        modPercepcao: 0,
        modForca: 0,
        modDestreza: 0,
        modConstituicao: 0,
      );

      cubit.iniciarCombate(
        [heroi, minion],
        iniciativas: {'heroi': 20, 'goblin': 10},
        posicoesIniciais: {
          'heroi': const Posicao2D(1, 1),
          'goblin': const Posicao2D(2, 1),
        },
      );

      // Ataque que causa dano letal massivo (> 12 de dano leva goblin para <= -10 -> MORTO)
      cubit.executarAtaque(
        defensor: minion,
        arma: espadaLonga,
        bonusDanoExtra: 20,
      );

      expect(eventos.any((e) => e is PersonagemMorreu && e.personagemId == 'goblin'), isTrue);
    });
  });
}
