import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:t20_creator/domain/entities/combate/grid_tatico.dart';
import 'package:t20_creator/domain/entities/combate/tipo_acao.dart';
import 'package:t20_creator/domain/entities/habilidades/modelos_habilidade_duracao.dart';
import 'package:t20_creator/domain/entities/testes/configuracoes_mesa_t20.dart';
import 'package:t20_creator/domain/entities/testes/modelos_teste_t20.dart';
import 'package:t20_creator/domain/services/habilidades_services/duracao_engine.dart';
import 'package:t20_creator/domain/services/habilidades_services/geometria_grid.dart';
import 'package:t20_creator/domain/services/habilidades_services/habilidade_engine.dart';
import 'package:t20_creator/domain/services/habilidades_services/modificador_engine.dart';
import 'package:t20_creator/domain/services/habilidades_services/pm_service.dart';
import 'package:t20_creator/domain/services/habilidades_services/relogio_e_cena_service.dart';
import 'package:t20_creator/domain/services/testes_services/i_rng.dart';
import 'package:t20_creator/domain/services/testes_services/motor_testes_service.dart';

void main() {
  EstadoPersonagemHabilidade criarPersonagemPadrao({
    String id = 'p1',
    Posicao2D posicao = const Posicao2D(0, 0),
    int pmMaxBase = 20,
    int pmAtual = 20,
    int pvAtual = 20,
    int pvMax = 20,
    Map<String, int> niveisPorClasse = const {'Arcanista': 3, 'Guerreiro': 7},
    int nivelTotal = 10,
    List<ItemComponenteInventario> inventario = const [],
  }) {
    return EstadoPersonagemHabilidade(
      id: id,
      posicao: posicao,
      pmState: PMState(
        pmMaxBase: pmMaxBase,
        pmAtual: pmAtual,
      ),
      pvAtual: pvAtual,
      pvMax: pvMax,
      niveisPorClasse: niveisPorClasse,
      nivelTotal: nivelTotal,
      inventario: inventario,
      modPericias: const {'MISTICISMO': 15, 'PERCEPCAO': 8, 'ATLETISMO': 8},
    );
  }

  EstadoMundoHabilidades criarMundoPadrao({
    List<EstadoPersonagemHabilidade>? personagens,
    List<AlvoMapa>? alvos,
    List<Barreira> barreiras = const [],
    ConfiguracoesMesaT20 configuracoes = const ConfiguracoesMesaT20(),
    RelogioDeJogo relogio = const RelogioDeJogo(),
  }) {
    final p1 = criarPersonagemPadrao();
    final listaP = personagens ?? [p1];
    final mapP = <String, EstadoPersonagemHabilidade>{
      for (final p in listaP) p.id: p,
    };
    final mapA = <String, AlvoMapa>{
      for (final p in listaP)
        p.id: AlvoMapa(
          id: p.id,
          nome: p.id,
          tipo: TipoAlvoPermitido.criatura,
          posicao: p.posicao,
          pvAtual: p.pvAtual,
          pvMax: p.pvMax,
        ),
      for (final a in (alvos ?? const <AlvoMapa>[])) a.id: a,
    };
    return EstadoMundoHabilidades(
      configuracoes: configuracoes,
      relogio: relogio,
      personagens: mapP,
      alvosNoMapa: mapA,
      barreiras: barreiras,
    );
  }

  EstadoMundoHabilidades aplicarCiclo(
    EstadoMundoHabilidades mundo,
    ResultadoCicloDuracao ciclo,
  ) {
    return mundo.copyWith(
      efeitos: ciclo.efeitos,
      areasPersistentes: ciclo.areasPersistentes,
      personagens: ciclo.personagens,
      relogio: ciclo.relogio,
      cenaAtual: ciclo.cenaAtual,
      sustentacoesPendentes: ciclo.sustentacoesPendentesPorUsuario,
      paresHabilidadeEventoConsumidos: ciclo.paresHabilidadeEventoConsumidos,
    );
  }

  group('MÓDULO 2 — Casos de Borda: Habilidades (1 a 20)', () {
    test('Caso 1: Habilidade sem ação especificada -> LIVRE', () {
      const hab = Habilidade(
        id: 'h1',
        nome: 'Fúria Rápida',
        tipo: TipoHabilidade.ativada,
        origem: OrigemHabilidade.classe,
        alcance: AlcanceHabilidade.pessoal,
        duracao: Duracao(tipo: TipoDuracao.cena),
      );
      expect(hab.acaoEfetiva, TipoAcao.livre);
    });

    test(
      'Caso 2: Engatilhada usada 2x no mesmo evento -> 2ª rejeitada; evento novo -> permitida',
      () {
        const habReacao = Habilidade(
          id: 'h_reacao',
          nome: 'Campo de Força Reativo',
          tipo: TipoHabilidade.ativada,
          origem: OrigemHabilidade.classe,
          classeId: 'Arcanista',
          gatilho: 'SOFRER_DANO',
          custo: CustoHabilidade(fixo: 1),
          alcance: AlcanceHabilidade.pessoal,
          duracao: Duracao(tipo: TipoDuracao.instantanea),
        );
        expect(habReacao.acaoEfetiva, TipoAcao.reacao);

        final engine = HabilidadeEngine(rng: SequenciaRng([10]));
        var mundo = criarMundoPadrao();

        const ev1 = EventoDeJogo(
          id: 'ev_1',
          tipo: 'SOFRER_DANO',
          dados: {'origemId': 'inimigo1', 'alvoId': 'p1'},
        );

        final emissao = engine.emitirEventoDeJogo(
          mundo: mundo,
          evento: ev1,
          habilidadesPorPersonagem: {
            'p1': [habReacao],
          },
        );
        expect(
          emissao.eventosGerados.any((e) => e['tipo'] == 'GatilhoDisponivel'),
          isTrue,
        );

        // 1ª ativação no ev_1: permitida
        final r1 = engine.ativarHabilidade(
          mundo: mundo,
          usuarioId: 'p1',
          habilidade: habReacao,
          eventoGatilho: ev1,
        );
        expect(r1.resultado.bloqueada, isFalse);
        expect(r1.resultado.falhou, isFalse);
        mundo = r1.mundoAtualizado;

        // 2ª ativação no mesmo ev_1: rejeitada (R23)
        final r2 = engine.ativarHabilidade(
          mundo: mundo,
          usuarioId: 'p1',
          habilidade: habReacao,
          eventoGatilho: ev1,
        );
        expect(r2.resultado.bloqueada, isTrue);
        expect(r2.resultado.motivo, 'GATILHO_JA_CONSUMIDO_NESTE_EVENTO');

        // Novo evento ev_2: permitida novamente
        const ev2 = EventoDeJogo(
          id: 'ev_2',
          tipo: 'SOFRER_DANO',
          dados: {'origemId': 'inimigo1', 'alvoId': 'p1'},
        );
        final r3 = engine.ativarHabilidade(
          mundo: mundo,
          usuarioId: 'p1',
          habilidade: habReacao,
          eventoGatilho: ev2,
        );
        expect(r3.resultado.bloqueada, isFalse);
        expect(r3.resultado.falhou, isFalse);
      },
    );

    test('Caso 3: Conversões: CURTO=6q=9m, MEDIO=20q=30m, LONGO=60q=90m', () {
      expect(AlcanceHabilidade.curto.quadrados, 6);
      expect(AlcanceHabilidade.curto.metros, 9.0);

      expect(AlcanceHabilidade.medio.quadrados, 20);
      expect(AlcanceHabilidade.medio.metros, 30.0);

      expect(AlcanceHabilidade.longo.quadrados, 60);
      expect(AlcanceHabilidade.longo.metros, 90.0);
    });

    test(
      'Caso 4: Custo variável: classe (nível na classe 3, total 10) -> limite 3; raça -> limite 10; custo mínimo 5 com limite 3 -> permite 5',
      () {
        const pmService = PMService();
        final p = criarPersonagemPadrao(
          niveisPorClasse: {'Arcanista': 3, 'Guerreiro': 7},
          nivelTotal: 10,
        );

        const habClasse = Habilidade(
          id: 'hc',
          nome: 'Magia de Classe',
          tipo: TipoHabilidade.ativada,
          origem: OrigemHabilidade.classe,
          classeId: 'Arcanista',
          custo: CustoHabilidade(variavel: CustoVariavel(min: 1)),
          alcance: AlcanceHabilidade.pessoal,
          duracao: Duracao(tipo: TipoDuracao.instantanea),
        );
        expect(pmService.limiteNivel(habClasse, p), 3);
        expect(pmService.limiteEfetivoCustoVariavel(habClasse, p), 3);

        const habRaca = Habilidade(
          id: 'hr',
          nome: 'Poder Racial',
          tipo: TipoHabilidade.ativada,
          origem: OrigemHabilidade.raca,
          custo: CustoHabilidade(variavel: CustoVariavel(min: 1)),
          alcance: AlcanceHabilidade.pessoal,
          duracao: Duracao(tipo: TipoDuracao.instantanea),
        );
        expect(pmService.limiteNivel(habRaca, p), 10);
        expect(pmService.limiteEfetivoCustoVariavel(habRaca, p), 10);

        const habMin5 = Habilidade(
          id: 'hm5',
          nome: 'Magia Cara',
          tipo: TipoHabilidade.ativada,
          origem: OrigemHabilidade.classe,
          classeId: 'Arcanista',
          custo: CustoHabilidade(variavel: CustoVariavel(min: 5)),
          alcance: AlcanceHabilidade.pessoal,
          duracao: Duracao(tipo: TipoDuracao.instantanea),
        );
        expect(pmService.limiteEfetivoCustoVariavel(habMin5, p), 5);
        final val = pmService.validarCustosPreAtivacao(
          habilidade: habMin5,
          personagem: p,
          custoVariavelEscolhido: 5,
        );
        expect(val.valido, isTrue);
      },
    );

    test(
      'Caso 5: Alvo incompatível com confirmação -> falha automática, PM e material consumidos. Sem confirmação -> nada gasto',
      () {
        const habCriatura = Habilidade(
          id: 'h_cura',
          nome: 'Curar Ferimentos',
          tipo: TipoHabilidade.ativada,
          origem: OrigemHabilidade.classe,
          classeId: 'Arcanista',
          custo: CustoHabilidade(fixo: 2, material: ['Erva Real']),
          alcance: AlcanceHabilidade.toque,
          alvosPermitidos: [TipoAlvoPermitido.criatura],
          duracao: Duracao(tipo: TipoDuracao.instantanea),
        );

        final p1 = criarPersonagemPadrao(
          pmAtual: 10,
          inventario: const [
            ItemComponenteInventario(
              id: 'm1',
              nome: 'Erva Real',
              emMaos: true,
              quantidade: 1,
            ),
          ],
        );
        const porta = AlvoMapa(
          id: 'porta_1',
          nome: 'Porta de Madeira',
          tipo: TipoAlvoPermitido.objeto,
          posicao: Posicao2D(1, 0),
        );

        final mundo = criarMundoPadrao(personagens: [p1], alvos: [porta]);
        final engine = HabilidadeEngine(rng: SequenciaRng([10]));

        // Sem confirmação: bloqueado antes de gastar PM/material
        final rSemConf = engine.ativarHabilidade(
          mundo: mundo,
          usuarioId: 'p1',
          habilidade: habCriatura,
          alvosEscolhidosIds: const ['porta_1'],
          confirmarMesmoComAvisos: false,
        );
        expect(rSemConf.resultado.bloqueada, isTrue);
        expect(rSemConf.resultado.custoPago, 0);
        expect(rSemConf.mundoAtualizado.personagens['p1']!.pmState.pmAtual, 10);
        expect(
          rSemConf.mundoAtualizado.personagens['p1']!.inventario.length,
          1,
        );

        // Com confirmação: falha automática após gastar PM e material (R31/R32)
        final rComConf = engine.ativarHabilidade(
          mundo: mundo,
          usuarioId: 'p1',
          habilidade: habCriatura,
          alvosEscolhidosIds: const ['porta_1'],
          confirmarMesmoComAvisos: true,
        );
        expect(rComConf.resultado.bloqueada, isFalse);
        expect(rComConf.resultado.falhou, isTrue);
        expect(rComConf.resultado.motivoFalha, 'ALVO_INCOMPATIVEL');
        expect(rComConf.resultado.custoPago, 2);
        expect(rComConf.mundoAtualizado.personagens['p1']!.pmState.pmAtual, 8);
        expect(
          rComConf.mundoAtualizado.personagens['p1']!.inventario,
          isEmpty,
        );
      },
    );

    test(
      'Caso 6: Penalidade de PM: máx 20, penalidade 4 -> máx 16 e pmAtual 16; ao terminar o efeito, máx 20 e pmAtual segue 16',
      () {
        const habPenalidade = Habilidade(
          id: 'h_pen',
          nome: 'Pacto Arcano',
          tipo: TipoHabilidade.ativada,
          origem: OrigemHabilidade.classe,
          classeId: 'Arcanista',
          custo: CustoHabilidade(fixo: 0, penalidadePM: 4),
          alcance: AlcanceHabilidade.pessoal,
          duracao: Duracao(tipo: TipoDuracao.cena),
        );

        final engine = HabilidadeEngine(rng: SequenciaRng([10]));
        var mundo = criarMundoPadrao();

        final rAtiv = engine.ativarHabilidade(
          mundo: mundo,
          usuarioId: 'p1',
          habilidade: habPenalidade,
        );
        expect(rAtiv.resultado.bloqueada, isFalse);
        mundo = rAtiv.mundoAtualizado;

        final pmDurante = mundo.personagens['p1']!.pmState;
        expect(pmDurante.pmMaxEfetivo, 16);
        expect(pmDurante.pmAtual, 16);

        // Ao encerrar o efeito, pmMaxEfetivo volta para 20, mas pmAtual continua 16
        final efeitoId = rAtiv.resultado.efeitoId!;
        final cicloFim = engine.duracaoEngine.encerrarEfeito(
          efeitoId: efeitoId,
          solicitanteId: 'p1',
          efeitos: mundo.efeitos,
          areasPersistentes: mundo.areasPersistentes,
          personagens: mundo.personagens,
          relogio: mundo.relogio,
          cenaAtual: mundo.cenaAtual,
          sustentacoesPendentes: mundo.sustentacoesPendentes,
          paresConsumidos: mundo.paresHabilidadeEventoConsumidos,
          controleDeAcoes: ControleDeAcoesPermissivo(),
        );
        mundo = aplicarCiclo(mundo, cicloFim);
        final pmDepois = mundo.personagens['p1']!.pmState;
        expect(pmDepois.pmMaxEfetivo, 20);
        expect(pmDepois.pmAtual, 16);
      },
    );

    test(
      'Caso 7: Sacrifício reduz pmMaxBase de forma permanente (e mestre pode restaurar)',
      () {
        const pmService = PMService();
        const habSacrificio = Habilidade(
          id: 'h_sac',
          nome: 'Desejo Sacrificial',
          tipo: TipoHabilidade.ativada,
          origem: OrigemHabilidade.classe,
          custo: CustoHabilidade(fixo: 0, sacrificioPM: 3),
          alcance: AlcanceHabilidade.pessoal,
          duracao: Duracao(tipo: TipoDuracao.instantanea),
        );

        var p = criarPersonagemPadrao(pmMaxBase: 20, pmAtual: 20);
        p = pmService.gastarCustos(
          personagem: p,
          habilidade: habSacrificio,
          custoFinalPM: 0,
        );
        expect(p.pmState.pmMaxBase, 17);
        expect(p.pmState.pmMaxEfetivo, 17);
        expect(p.pmState.pmAtual, 17);

        // Mestre restaura 2 PM sacrificados
        final (restaurado, _) = pmService.restaurarPmSacrificadoPeloMestre(
          state: p.pmState,
          quantidade: 2,
          personagemId: 'p1',
        );
        expect(restaurado.pmMaxBase, 19);
        expect(restaurado.pmMaxEfetivo, 19);
      },
    );

    test(
      'Caso 8: Acúmulo: duas habilidades diferentes +2 e +1 -> +3; a mesma habilidade duas vezes +2 e +2 -> +2',
      () {
        const modEngine = ModificadorEngine();

        final modsDiferentes = [
          const ModificadorAplicado(
            fonteTipo: FonteModificador.habilidade,
            fonteId: 'hab_a',
            alvoCaracteristica: 'ATLETISMO',
            valor: 2,
          ),
          const ModificadorAplicado(
            fonteTipo: FonteModificador.habilidade,
            fonteId: 'hab_b',
            alvoCaracteristica: 'ATLETISMO',
            valor: 1,
          ),
        ];
        expect(modEngine.somarModificadoresAplicados(modsDiferentes), 3);

        final modsMesmaHab = [
          const ModificadorAplicado(
            fonteTipo: FonteModificador.habilidade,
            fonteId: 'hab_a',
            alvoCaracteristica: 'ATLETISMO',
            valor: 2,
          ),
          const ModificadorAplicado(
            fonteTipo: FonteModificador.habilidade,
            fonteId: 'hab_a',
            alvoCaracteristica: 'ATLETISMO',
            valor: 2,
          ),
        ];
        expect(modEngine.somarModificadoresAplicados(modsMesmaHab), 2);
      },
    );

    test(
      'Caso 9: Atributo-chave somado duas vezes na mesma perícia -> só uma vez (e troca de atributo substitui)',
      () {
        const modEngine = ModificadorEngine();

        // Mesmo atributo (CAR) tentando somar duas vezes na mesma perícia
        final modsMesmoAtrib = [
          const ModificadorAplicado(
            fonteTipo: FonteModificador.atributo,
            fonteId: 'CAR',
            alvoCaracteristica: 'DIPLOMACIA',
            valor: 4,
          ),
          const ModificadorAplicado(
            fonteTipo: FonteModificador.atributo,
            fonteId: 'CAR',
            alvoCaracteristica: 'DIPLOMACIA',
            valor: 4,
          ),
        ];
        expect(modEngine.somarModificadoresAplicados(modsMesmoAtrib), 4);

        // Troca de atributo-chave (ex.: usar INT no lugar de FOR em Luta) substitui e não soma
        final modsTrocaAtrib = [
          const ModificadorAplicado(
            fonteTipo: FonteModificador.atributo,
            fonteId: 'FOR',
            alvoCaracteristica: 'LUTA',
            valor: 1,
          ),
          const ModificadorAplicado(
            fonteTipo: FonteModificador.atributo,
            fonteId: 'INT',
            alvoCaracteristica: 'LUTA',
            valor: 5,
            substituiAtributoBase: true,
          ),
        ];
        expect(modEngine.somarModificadoresAplicados(modsTrocaAtrib), 5);
      },
    );

    test('Caso 10: Chance de falha 50% + 50% -> 75% (teto R29)', () {
      const modEngine = ModificadorEngine();
      final res = modEngine.calcularChanceFalha(const [
        ModificadorAplicado(
          fonteTipo: FonteModificador.ambiente,
          fonteId: 'camuflagem_total',
          alvoCaracteristica: 'CHANCE_FALHA',
          valor: 50,
        ),
        ModificadorAplicado(
          fonteTipo: FonteModificador.magia,
          fonteId: 'nevoa_espessa',
          alvoCaracteristica: 'CHANCE_FALHA',
          valor: 50,
        ),
      ]);
      expect(res.chanceTotalBruta, 100);
      expect(res.chanceEfetiva, 75);
    });

    test(
      'Caso 11: Reduções -1 e -2 -> só -2; custo base 2 com -2 -> 1; custo base 0 -> 0',
      () {
        const pmService = PMService();
        const reducoes = [
          ReducaoCusto(fonteId: 'foco_magia', valor: 1),
          ReducaoCusto(fonteId: 'alta_arcana', valor: 2),
        ];

        // Base 4 com reduções -1 e -2 -> usa apenas -2 -> final 2
        expect(
          pmService.calcularCustoFinalPM(custoBase: 4, reducoes: reducoes),
          2,
        );

        // Base 2 com redução -2 -> piso de 1 PM -> final 1
        expect(
          pmService.calcularCustoFinalPM(custoBase: 2, reducoes: reducoes),
          1,
        );

        // Base 0 com redução -2 -> continua 0
        expect(
          pmService.calcularCustoFinalPM(custoBase: 0, reducoes: reducoes),
          0,
        );
      },
    );

    test(
      'Caso 12: Reroll: após declaração -> rejeitado; segundo resultado pior é mantido; alterar CD/bônus após rolar -> rejeitado; segunda repetição -> rejeitada (padrão)',
      () {
        final service = MotorTestesService(rng: SequenciaRng([15, 4, 19]));
        const req = TesteRequest(
          id: 'req_reroll',
          tipo: TipoTeste.comum,
          modo: ModoTeste.pericia,
          cd: 15,
          participantes: ['p1'],
        );

        var estado = service.criarEstadoTeste(
          request: req,
          personagemId: 'p1',
          fonteMod: 'ATLETISMO',
          modBase: 2,
        );
        estado = service.modificarAntesDaRolagem(
          estado: estado,
          novoModificador: const ModificadorAplicado(
            fonteTipo: FonteModificador.mestre,
            fonteId: 'BONUS_MESTRE',
            alvoCaracteristica: 'ATLETISMO',
            valor: 1,
          ),
        );

        // Rolagem inicial: d20 = 15 + 3 = 18
        estado = service.rolarEstadoTeste(estado: estado);
        expect(estado.fase, FaseEstadoTeste.aguardandoDeclaracao);
        expect(estado.resultadoAtual!.d20, 15);
        expect(estado.resultadoAtual!.total, 18);

        // Alterar CD/bônus após rolar -> rejeitado (R30)
        expect(
          () => service.modificarAntesDaRolagem(estado: estado, novaCd: 25),
          throwsA(isA<RegraTesteException>()),
        );

        // 1ª repetição: d20 = 4 (pior que 15) -> novo resultado pior é mantido!
        estado = service.repetirRolagem(estado: estado);
        expect(estado.resultadoAtual!.d20, 4);
        expect(estado.resultadoAtual!.total, 7);
        expect(estado.historicoD20.length, 2);

        // 2ª repetição no mesmo teste -> rejeitada por padrão (maxRepeticoesPorTeste = 1)
        expect(
          () => service.repetirRolagem(estado: estado),
          throwsA(isA<RegraTesteException>()),
        );

        // Declaração do resultado
        estado = service.declararResultadoTeste(estado);
        expect(estado.fase, FaseEstadoTeste.declarado);

        // Reroll após declaração -> rejeitado
        expect(
          () => service.repetirRolagem(estado: estado),
          throwsA(isA<RegraTesteException>()),
        );
      },
    );

    test(
      'Caso 13: Área com origem dentro do alcance e borda além do alcance -> afeta normalmente. Origem além do alcance -> rejeitada',
      () {
        const habEsfera = Habilidade(
          id: 'h_bola_fogo',
          nome: 'Bola de Fogo',
          tipo: TipoHabilidade.ativada,
          origem: OrigemHabilidade.classe,
          classeId: 'Arcanista',
          custo: CustoHabilidade(fixo: 3),
          ehMagia: true,
          alcance: AlcanceHabilidade.curto, // 6 quadrados
          area: Area(
            tipo: TipoArea.esfera,
            tamanhoQuadrados: 4, // 6m de raio
          ),
          duracao: Duracao(tipo: TipoDuracao.instantanea),
        );

        // Alvo na posição (8, 0) está fora do alcance curto (6q), mas dentro da esfera centrada no vértice (6, 0)
        const goblinLonge = AlvoMapa(
          id: 'goblin_1',
          nome: 'Goblin',
          tipo: TipoAlvoPermitido.criatura,
          posicao: Posicao2D(8, 0),
        );

        final mundo = criarMundoPadrao(alvos: [goblinLonge]);
        final engine = HabilidadeEngine(rng: SequenciaRng([10]));

        // Origem no vértice (6, 0) -> distância até vértice = 5 <= 6 (CURTO) -> afeta goblin em (8, 0)
        final rValido = engine.ativarHabilidade(
          mundo: mundo,
          usuarioId: 'p1',
          habilidade: habEsfera,
          areaEscolhida: const Area(
            tipo: TipoArea.esfera,
            tamanhoQuadrados: 4,
            origemVertice: VerticeGrid(6, 0),
          ),
        );
        expect(rValido.resultado.bloqueada, isFalse);
        expect(rValido.resultado.alvosAfetados, contains('goblin_1'));

        // Origem no vértice (8, 0) -> distância até vértice = 7 > 6 -> rejeitada
        final rInvalido = engine.ativarHabilidade(
          mundo: mundo,
          usuarioId: 'p1',
          habilidade: habEsfera,
          areaEscolhida: const Area(
            tipo: TipoArea.esfera,
            tamanhoQuadrados: 4,
            origemVertice: VerticeGrid(8, 0),
          ),
        );
        expect(rInvalido.resultado.bloqueada, isTrue);
        expect(rInvalido.resultado.motivo, 'ORIGEM_FORA_DO_ALCANCE');
      },
    );

    test(
      'Caso 14: Parede visível E barreira invisível bloqueiam linha de efeito; origem atrás de parede -> rejeitada; invocação pode sair da linha de efeito depois',
      () {
        const geo = GeometriaGrid();
        const paredeVisivel = Barreira(
          id: 'b_vis',
          segmentos: [SegmentoBarreira(x1: 3, y1: -5, x2: 3, y2: 5)],
          visivel: true,
        );
        const paredeInvisivel = Barreira(
          id: 'b_invis',
          segmentos: [SegmentoBarreira(x1: 3, y1: -5, x2: 3, y2: 5)],
          visivel: false,
        );

        expect(
          geo.temLinhaDeEfeito(
            origem: const Posicao2D(0, 0),
            destinoCelula: const Posicao2D(5, 0),
            barreiras: const [paredeVisivel],
          ),
          isFalse,
        );
        expect(
          geo.temLinhaDeEfeito(
            origem: const Posicao2D(0, 0),
            destinoCelula: const Posicao2D(5, 0),
            barreiras: const [paredeInvisivel],
          ),
          isFalse,
        );

        // Invocação criada com linha de efeito válida pode se mover para trás da parede depois sem encerrar (R35)
        const habInvocacao = Habilidade(
          id: 'h_invoc',
          nome: 'Conjurar Monstro',
          tipo: TipoHabilidade.ativada,
          origem: OrigemHabilidade.classe,
          classeId: 'Arcanista',
          custo: CustoHabilidade(fixo: 2),
          criaElementoNoMapa: true,
          alcance: AlcanceHabilidade.curto,
          duracao: Duracao(tipo: TipoDuracao.sustentada),
        );

        var mundo = criarMundoPadrao(barreiras: const [paredeVisivel]);
        final engine = HabilidadeEngine(rng: SequenciaRng([10]));

        // Invocar atrás da parede (5, 0) -> rejeitado
        final rAtrasParede = engine.ativarHabilidade(
          mundo: mundo,
          usuarioId: 'p1',
          habilidade: habInvocacao,
          pontoCriacao: const Posicao2D(5, 0),
        );
        expect(rAtrasParede.resultado.bloqueada, isTrue);

        // Invocar na frente da parede (2, 0) -> sucesso
        final rFrenteParede = engine.ativarHabilidade(
          mundo: mundo,
          usuarioId: 'p1',
          habilidade: habInvocacao,
          pontoCriacao: const Posicao2D(2, 0),
          novoTokenIdCriado: 'monstro_1',
        );
        expect(rFrenteParede.resultado.bloqueada, isFalse);
        mundo = rFrenteParede.mundoAtualizado;
        expect(mundo.efeitos.where((e) => e.estaEmJogo).length, 1);

        // Mover o monstro invocado para trás da parede (5, 0) -> continua ativo!
        final mov = engine.moverTokenNoMapa(
          mundo: mundo,
          tokenId: 'monstro_1',
          novaPosicao: const Posicao2D(5, 0),
        );
        expect(
          mov.mundoAtualizado.efeitos.where((e) => e.estaEmJogo).length,
          1,
        );
      },
    );

    test(
      'Caso 15: Área de alcance pessoal não afeta o usuário; área de outros alcances afeta',
      () {
        const habConePessoal = Habilidade(
          id: 'h_cone',
          nome: 'Leque Cromático',
          tipo: TipoHabilidade.ativada,
          origem: OrigemHabilidade.classe,
          classeId: 'Arcanista',
          custo: CustoHabilidade(fixo: 1),
          alcance: AlcanceHabilidade.pessoal,
          area: Area(
            tipo: TipoArea.cone,
            tamanhoQuadrados: 4,
            origemCelula: Posicao2D(0, 0),
            direcaoDestino: Posicao2D(4, 0),
          ),
          duracao: Duracao(tipo: TipoDuracao.instantanea),
        );

        const inimigo = AlvoMapa(
          id: 'inimigo_1',
          nome: 'Orc',
          tipo: TipoAlvoPermitido.criatura,
          posicao: Posicao2D(2, 0),
        );
        final mundo = criarMundoPadrao(alvos: [inimigo]);
        final engine = HabilidadeEngine(rng: SequenciaRng([10]));

        final rPessoal = engine.ativarHabilidade(
          mundo: mundo,
          usuarioId: 'p1',
          habilidade: habConePessoal,
        );
        expect(rPessoal.resultado.bloqueada, isFalse);
        expect(rPessoal.resultado.alvosAfetados, contains('inimigo_1'));
        expect(rPessoal.resultado.alvosAfetados, isNot(contains('p1')));

        // Área de alcance curto centrada perto do usuário afeta o próprio usuário
        const habEsferaCurto = Habilidade(
          id: 'h_explosao',
          nome: 'Explosão de Chamas',
          tipo: TipoHabilidade.ativada,
          origem: OrigemHabilidade.classe,
          classeId: 'Arcanista',
          custo: CustoHabilidade(fixo: 1),
          alcance: AlcanceHabilidade.curto,
          area: Area(
            tipo: TipoArea.esfera,
            tamanhoQuadrados: 2,
            origemVertice: VerticeGrid(1, 1),
          ),
          duracao: Duracao(tipo: TipoDuracao.instantanea),
        );
        final rCurto = engine.ativarHabilidade(
          mundo: mundo,
          usuarioId: 'p1',
          habilidade: habEsferaCurto,
        );
        expect(rCurto.resultado.bloqueada, isFalse);
        expect(rCurto.resultado.alvosAfetados, contains('p1'));
      },
    );

    test(
      'Caso 16: Área não percebida -> exige teste CD 20 + custo em PM (Misticismo se ehMagia)',
      () {
        const habMagiaArea = Habilidade(
          id: 'h_magia_area',
          nome: 'Bola de Fogo',
          tipo: TipoHabilidade.ativada,
          origem: OrigemHabilidade.classe,
          classeId: 'Arcanista',
          custo: CustoHabilidade(fixo: 3),
          ehMagia: true,
          alcance: AlcanceHabilidade.medio,
          area: Area(
            tipo: TipoArea.esfera,
            tamanhoQuadrados: 4,
            origemVertice: VerticeGrid(5, 5),
          ),
          duracao: Duracao(tipo: TipoDuracao.instantanea),
        );

        final mundo = criarMundoPadrao();

        // Rolagem d20 = 5 + Misticismo (15) = 20 vs CD (20 + 3 = 23) -> falha!
        final engineFalha = HabilidadeEngine(rng: SequenciaRng([5]));
        final rFalha = engineFalha.ativarHabilidade(
          mundo: mundo,
          usuarioId: 'p1',
          habilidade: habMagiaArea,
          areaPercebidaPeloUsuario: false,
        );
        expect(rFalha.resultado.falhou, isTrue);
        expect(rFalha.resultado.custoPago, 3);
        expect(rFalha.resultado.resultadoTestePercepcaoArea!.cd, 23);

        // Rolagem d20 = 10 + Misticismo (15) = 25 vs CD 23 -> sucesso!
        final engineSucesso = HabilidadeEngine(rng: SequenciaRng([10]));
        final rSucesso = engineSucesso.ativarHabilidade(
          mundo: mundo,
          usuarioId: 'p1',
          habilidade: habMagiaArea,
          areaPercebidaPeloUsuario: false,
        );
        expect(rSucesso.resultado.falhou, isFalse);
      },
    );

    test(
      'Caso 17: Linha tem 1,5 m de largura por padrão; esfera/cilindro têm origem em vértice do grid',
      () {
        const areaLinha = Area(
          tipo: TipoArea.linha,
          tamanhoQuadrados: 6,
        );
        expect(areaLinha.larguraQuadrados, 1);
        expect(areaLinha.larguraMetros, 1.5);

        const geo = GeometriaGrid();
        const areaEsferaSemVertice = Area(
          tipo: TipoArea.esfera,
          tamanhoQuadrados: 2,
          origemCelula: Posicao2D(2, 2),
        );
        expect(geo.validarOrigemGeometriaArea(areaEsferaSemVertice), isFalse);

        const areaEsferaComVertice = Area(
          tipo: TipoArea.esfera,
          tamanhoQuadrados: 2,
          origemVertice: VerticeGrid(2, 2),
        );
        expect(geo.validarOrigemGeometriaArea(areaEsferaComVertice), isTrue);
        final celulas = geo.calcularQuadradosBrutosArea(areaEsferaComVertice);
        expect(celulas, contains(const Posicao2D(1, 1)));
        expect(celulas, contains(const Posicao2D(2, 2)));
      },
    );

    test('Caso 18: Redirecionar exige ação padrão', () {
      const habRedirecionavel = Habilidade(
        id: 'h_esfera_flam',
        nome: 'Esfera Flamejante',
        tipo: TipoHabilidade.ativada,
        origem: OrigemHabilidade.classe,
        classeId: 'Arcanista',
        custo: CustoHabilidade(fixo: 1),
        permiteRedirecionar: true,
        alcance: AlcanceHabilidade.curto,
        area: Area(
          tipo: TipoArea.esfera,
          tamanhoQuadrados: 1,
          origemVertice: VerticeGrid(2, 2),
        ),
        duracao: Duracao(tipo: TipoDuracao.cena),
      );

      final acoesUsadas = <TipoAcao>[];
      final controleSpy = _ControleAcoesSpy(acoesUsadas);
      final engine = HabilidadeEngine(rng: SequenciaRng([10]));

      var mundo = criarMundoPadrao();
      final rAtiv = engine.ativarHabilidade(
        mundo: mundo,
        usuarioId: 'p1',
        habilidade: habRedirecionavel,
        controleDeAcoes: controleSpy,
      );
      mundo = rAtiv.mundoAtualizado;
      final efeitoId = rAtiv.resultado.efeitoId!;

      acoesUsadas.clear();
      mundo = engine.redirecionarEfeito(
        mundo: mundo,
        efeitoId: efeitoId,
        solicitanteId: 'p1',
        controleDeAcoes: controleSpy,
        novaArea: const Area(
          tipo: TipoArea.esfera,
          tamanhoQuadrados: 1,
          origemVertice: VerticeGrid(4, 4),
        ),
      );
      expect(acoesUsadas, [TipoAcao.padrao]);
    });

    test(
      'Caso 19: Armadura + escudo + 1 item adicional somam na Defesa; um segundo item adicional é ignorado',
      () {
        const modEngine = ModificadorEngine();
        final candidatosDefesa = [
          const ModificadorAplicado(
            fonteTipo: FonteModificador.armadura,
            fonteId: 'cota_malha',
            alvoCaracteristica: 'DEFESA',
            valor: 6,
          ),
          const ModificadorAplicado(
            fonteTipo: FonteModificador.escudo,
            fonteId: 'escudo_pesado',
            alvoCaracteristica: 'DEFESA',
            valor: 2,
          ),
          const ModificadorAplicado(
            fonteTipo: FonteModificador.item,
            fonteId: 'anel_protecao',
            alvoCaracteristica: 'DEFESA',
            valor: 2,
          ),
          const ModificadorAplicado(
            fonteTipo: FonteModificador.item,
            fonteId: 'amuleto_defesa',
            alvoCaracteristica: 'DEFESA',
            valor: 1,
          ),
        ];

        // 6 (armadura) + 2 (escudo) + 2 (maior item adicional) = 10; o +1 é ignorado
        expect(modEngine.somarModificadoresAplicados(candidatosDefesa), 10);
      },
    );

    test(
      'Caso 20: Componente material fora das mãos (emMaos: false) -> ativação bloqueada',
      () {
        const habComMaterial = Habilidade(
          id: 'h_mat',
          nome: 'Pele de Pedra',
          tipo: TipoHabilidade.ativada,
          origem: OrigemHabilidade.classe,
          classeId: 'Arcanista',
          custo: CustoHabilidade(fixo: 2, material: ['Pó de Diamante']),
          alcance: AlcanceHabilidade.pessoal,
          duracao: Duracao(tipo: TipoDuracao.cena),
        );

        final pSemMaos = criarPersonagemPadrao(
          inventario: const [
            ItemComponenteInventario(
              id: 'mat1',
              nome: 'Pó de Diamante',
              emMaos: false,
            ),
          ],
        );
        final mundo = criarMundoPadrao(personagens: [pSemMaos]);
        final engine = HabilidadeEngine(rng: SequenciaRng([10]));

        final r = engine.ativarHabilidade(
          mundo: mundo,
          usuarioId: 'p1',
          habilidade: habComMaterial,
        );
        expect(r.resultado.bloqueada, isTrue);
        expect(r.resultado.motivo, 'CUSTO_INVALIDO_OU_INSUFICIENTE');
      },
    );
  });

  group('MÓDULO 2 — Casos de Borda: Duração (21 a 37)', () {
    test(
      'Caso 21: INSTANTANEA não cria EfeitoAtivo, e a cura de PV permanece depois',
      () {
        const habCura = Habilidade(
          id: 'h_cura_inst',
          nome: 'Curar Ferimentos',
          tipo: TipoHabilidade.ativada,
          origem: OrigemHabilidade.classe,
          classeId: 'Arcanista',
          custo: CustoHabilidade(fixo: 1),
          alcance: AlcanceHabilidade.pessoal,
          duracao: Duracao(tipo: TipoDuracao.instantanea),
          curaPvInstantanea: 8,
        );

        final pFerido = criarPersonagemPadrao(pvAtual: 10, pvMax: 20);
        final mundo = criarMundoPadrao(personagens: [pFerido]);
        final engine = HabilidadeEngine(rng: SequenciaRng([10]));

        final r = engine.ativarHabilidade(
          mundo: mundo,
          usuarioId: 'p1',
          habilidade: habCura,
        );
        expect(r.resultado.bloqueada, isFalse);
        expect(r.resultado.efeitoId, isNull);
        expect(r.mundoAtualizado.efeitos, isEmpty);
        expect(r.mundoAtualizado.personagens['p1']!.pvAtual, 18);
      },
    );

    test(
      'Caso 22: CENA: encerrar a cena expira todos os efeitos de cena e não afeta os de outras durações. Nova cena encerra a anterior',
      () {
        const habCena = Habilidade(
          id: 'h_cena',
          nome: 'Armadura Arcana',
          tipo: TipoHabilidade.ativada,
          origem: OrigemHabilidade.classe,
          classeId: 'Arcanista',
          custo: CustoHabilidade(fixo: 1),
          alcance: AlcanceHabilidade.pessoal,
          duracao: Duracao(tipo: TipoDuracao.cena),
        );
        const habDia = Habilidade(
          id: 'h_dia',
          nome: 'Suporte Ambiental',
          tipo: TipoHabilidade.ativada,
          origem: OrigemHabilidade.classe,
          classeId: 'Arcanista',
          custo: CustoHabilidade(fixo: 1),
          alcance: AlcanceHabilidade.pessoal,
          duracao: Duracao(
            tipo: TipoDuracao.definida,
            definida: DuracaoDefinida(
              quantidade: 1,
              unidade: UnidadeDuracao.dia,
            ),
          ),
        );

        final engine = HabilidadeEngine(rng: SequenciaRng([10]));
        var mundo = criarMundoPadrao();

        mundo = engine
            .ativarHabilidade(
              mundo: mundo,
              usuarioId: 'p1',
              habilidade: habCena,
            )
            .mundoAtualizado;
        mundo = engine
            .ativarHabilidade(
              mundo: mundo,
              usuarioId: 'p1',
              habilidade: habDia,
            )
            .mundoAtualizado;
        expect(mundo.efeitos.where((e) => e.estaEmJogo).length, 2);

        // Iniciar nova cena encerra a cena anterior e expira apenas o efeito de CENA
        final ciclo = engine.duracaoEngine.encerrarCenaEIniciarNova(
          efeitos: mundo.efeitos,
          areasPersistentes: mundo.areasPersistentes,
          personagens: mundo.personagens,
          relogio: mundo.relogio,
          cenaAtual: mundo.cenaAtual,
          sustentacoesPendentes: mundo.sustentacoesPendentes,
          paresConsumidos: mundo.paresHabilidadeEventoConsumidos,
          novaCenaId: 'cena_2',
          novaCenaNome: 'Combate na Masmorra',
        );
        mundo = aplicarCiclo(mundo, ciclo);

        final emJogo = mundo.efeitos.where((e) => e.estaEmJogo).toList();
        expect(emJogo.length, 1);
        expect(emJogo.first.habilidadeId, 'h_dia');
      },
    );

    test(
      'Caso 23: SUSTENTADA: com PM suficiente, pagar mantém e debita 1 PM. Recusar encerra. pmAtual = 0 encerra. Ativação no turno atual não cobra; 1º pagamento é no turno seguinte',
      () {
        const habSust = Habilidade(
          id: 'h_sust',
          nome: 'Velocidade',
          tipo: TipoHabilidade.ativada,
          origem: OrigemHabilidade.classe,
          classeId: 'Arcanista',
          custo: CustoHabilidade(fixo: 3),
          ehMagia: true,
          alcance: AlcanceHabilidade.pessoal,
          duracao: Duracao(tipo: TipoDuracao.sustentada),
        );

        final engine = HabilidadeEngine(rng: SequenciaRng([10]));
        var mundo = criarMundoPadrao(); // rodada 1, pmAtual = 20

        // Ativa na rodada 1 -> gasta 3 PM -> fica com 17 PM
        final rAtiv = engine.ativarHabilidade(
          mundo: mundo,
          usuarioId: 'p1',
          habilidade: habSust,
        );
        mundo = rAtiv.mundoAtualizado;
        expect(mundo.personagens['p1']!.pmState.pmAtual, 17);

        // Início do turno na mesma rodada 1 -> NÃO cobra sustentação
        var ciclo = engine.duracaoEngine.processarInicioTurno(
          personagemId: 'p1',
          rodada: 1,
          efeitos: mundo.efeitos,
          areasPersistentes: mundo.areasPersistentes,
          personagens: mundo.personagens,
          relogio: mundo.relogio,
          cenaAtual: mundo.cenaAtual,
          sustentacoesPendentes: mundo.sustentacoesPendentes,
          paresConsumidos: mundo.paresHabilidadeEventoConsumidos,
          controleDeAcoes: ControleDeAcoesPermissivo(),
        );
        mundo = aplicarCiclo(mundo, ciclo);
        expect(mundo.sustentacoesPendentes, isEmpty);

        // Início do turno na rodada 2 -> gera SustentacaoPendente
        ciclo = engine.duracaoEngine.processarInicioTurno(
          personagemId: 'p1',
          rodada: 2,
          efeitos: mundo.efeitos,
          areasPersistentes: mundo.areasPersistentes,
          personagens: mundo.personagens,
          relogio: mundo.relogio,
          cenaAtual: mundo.cenaAtual,
          sustentacoesPendentes: mundo.sustentacoesPendentes,
          paresConsumidos: mundo.paresHabilidadeEventoConsumidos,
          controleDeAcoes: ControleDeAcoesPermissivo(),
        );
        mundo = aplicarCiclo(mundo, ciclo);
        expect(mundo.sustentacoesPendentes.length, 1);
        final efeitoId = mundo.efeitos.first.id;

        // Pagar mantém e debita 1 PM (17 -> 16)
        ciclo = engine.duracaoEngine.resolverSustentacao(
          efeitoId: efeitoId,
          manter: true,
          efeitos: mundo.efeitos,
          areasPersistentes: mundo.areasPersistentes,
          personagens: mundo.personagens,
          relogio: mundo.relogio,
          cenaAtual: mundo.cenaAtual,
          sustentacoesPendentes: mundo.sustentacoesPendentes,
          paresConsumidos: mundo.paresHabilidadeEventoConsumidos,
          controleDeAcoes: ControleDeAcoesPermissivo(),
        );
        mundo = aplicarCiclo(mundo, ciclo);
        expect(mundo.personagens['p1']!.pmState.pmAtual, 16);
        expect(mundo.efeitos.where((e) => e.estaEmJogo).length, 1);

        // Rodada 3 -> recusar encerra o efeito
        ciclo = engine.duracaoEngine.processarInicioTurno(
          personagemId: 'p1',
          rodada: 3,
          efeitos: mundo.efeitos,
          areasPersistentes: mundo.areasPersistentes,
          personagens: mundo.personagens,
          relogio: mundo.relogio,
          cenaAtual: mundo.cenaAtual,
          sustentacoesPendentes: mundo.sustentacoesPendentes,
          paresConsumidos: mundo.paresHabilidadeEventoConsumidos,
          controleDeAcoes: ControleDeAcoesPermissivo(),
        );
        mundo = aplicarCiclo(mundo, ciclo);
        ciclo = engine.duracaoEngine.resolverSustentacao(
          efeitoId: efeitoId,
          manter: false,
          efeitos: mundo.efeitos,
          areasPersistentes: mundo.areasPersistentes,
          personagens: mundo.personagens,
          relogio: mundo.relogio,
          cenaAtual: mundo.cenaAtual,
          sustentacoesPendentes: mundo.sustentacoesPendentes,
          paresConsumidos: mundo.paresHabilidadeEventoConsumidos,
          controleDeAcoes: ControleDeAcoesPermissivo(),
        );
        mundo = aplicarCiclo(mundo, ciclo);
        expect(mundo.efeitos.where((e) => e.estaEmJogo), isEmpty);

        // Se pmAtual == 0 na virada do turno seguinte, encerra automaticamente
        final pZero = mundo.personagens['p1']!.copyWith(
          pmState: const PMState(pmMaxBase: 20, pmAtual: 3),
        );
        mundo = mundo.copyWith(personagens: {'p1': pZero});
        mundo = engine
            .ativarHabilidade(
              mundo: mundo,
              usuarioId: 'p1',
              habilidade: habSust,
            )
            .mundoAtualizado;
        expect(mundo.personagens['p1']!.pmState.pmAtual, 0);

        ciclo = engine.duracaoEngine.processarInicioTurno(
          personagemId: 'p1',
          rodada: 4,
          efeitos: mundo.efeitos,
          areasPersistentes: mundo.areasPersistentes,
          personagens: mundo.personagens,
          relogio: mundo.relogio,
          cenaAtual: mundo.cenaAtual,
          sustentacoesPendentes: mundo.sustentacoesPendentes,
          paresConsumidos: mundo.paresHabilidadeEventoConsumidos,
          controleDeAcoes: ControleDeAcoesPermissivo(),
        );
        mundo = aplicarCiclo(mundo, ciclo);
        expect(mundo.efeitos.where((e) => e.estaEmJogo), isEmpty);
      },
    );

    test(
      'Caso 24: Duas sustentadas não-magia coexistem e cada uma cobra 1 PM. Duas magias sustentadas: 2ª bloqueada sem confirmação, e com trocar a 1ª encerra. Magia sustentada + sustentada não-magia coexistem',
      () {
        const habMagia1 = Habilidade(
          id: 'm_sust_1',
          nome: 'Velocidade',
          tipo: TipoHabilidade.ativada,
          origem: OrigemHabilidade.classe,
          classeId: 'Arcanista',
          custo: CustoHabilidade(fixo: 1),
          ehMagia: true,
          alcance: AlcanceHabilidade.pessoal,
          duracao: Duracao(tipo: TipoDuracao.sustentada),
        );
        const habMagia2 = Habilidade(
          id: 'm_sust_2',
          nome: 'Voo',
          tipo: TipoHabilidade.ativada,
          origem: OrigemHabilidade.classe,
          classeId: 'Arcanista',
          custo: CustoHabilidade(fixo: 1),
          ehMagia: true,
          alcance: AlcanceHabilidade.pessoal,
          duracao: Duracao(tipo: TipoDuracao.sustentada),
        );
        const habPoder1 = Habilidade(
          id: 'p_sust_1',
          nome: 'Canção de Bardo 1',
          tipo: TipoHabilidade.ativada,
          origem: OrigemHabilidade.poderGeral,
          custo: CustoHabilidade(fixo: 1),
          ehMagia: false,
          alcance: AlcanceHabilidade.pessoal,
          duracao: Duracao(tipo: TipoDuracao.sustentada),
        );
        const habPoder2 = Habilidade(
          id: 'p_sust_2',
          nome: 'Postura Sustentada 2',
          tipo: TipoHabilidade.ativada,
          origem: OrigemHabilidade.poderGeral,
          custo: CustoHabilidade(fixo: 1),
          ehMagia: false,
          alcance: AlcanceHabilidade.pessoal,
          duracao: Duracao(tipo: TipoDuracao.sustentada),
        );

        final engine = HabilidadeEngine(rng: SequenciaRng([10]));
        var mundo = criarMundoPadrao();

        // Ativa 2 sustentadas não-magia + 1 magia sustentada -> todas coexistem!
        mundo = engine
            .ativarHabilidade(
              mundo: mundo,
              usuarioId: 'p1',
              habilidade: habPoder1,
            )
            .mundoAtualizado;
        mundo = engine
            .ativarHabilidade(
              mundo: mundo,
              usuarioId: 'p1',
              habilidade: habPoder2,
            )
            .mundoAtualizado;
        mundo = engine
            .ativarHabilidade(
              mundo: mundo,
              usuarioId: 'p1',
              habilidade: habMagia1,
            )
            .mundoAtualizado;
        expect(mundo.efeitos.where((e) => e.estaEmJogo).length, 3);

        // Tentar ativar 2ª magia sustentada sem confirmar troca -> bloqueada!
        final rBloq = engine.ativarHabilidade(
          mundo: mundo,
          usuarioId: 'p1',
          habilidade: habMagia2,
          confirmarSubstituirMagiaSustentada: false,
        );
        expect(rBloq.resultado.bloqueada, isTrue);
        expect(rBloq.resultado.motivo, 'LIMITE_UMA_MAGIA_SUSTENTADA');

        // Com confirmação de troca -> encerra m_sust_1 e ativa m_sust_2
        final rTroca = engine.ativarHabilidade(
          mundo: mundo,
          usuarioId: 'p1',
          habilidade: habMagia2,
          confirmarSubstituirMagiaSustentada: true,
        );
        expect(rTroca.resultado.bloqueada, isFalse);
        mundo = rTroca.mundoAtualizado;
        final ativosIds =
            mundo.efeitos.where((e) => e.estaEmJogo).map((e) => e.habilidadeId);
        expect(ativosIds, containsAll(['p_sust_1', 'p_sust_2', 'm_sust_2']));
        expect(ativosIds, isNot(contains('m_sust_1')));
      },
    );

    test(
      'Caso 25: Custo de manutenção continua 1 PM mesmo com redução de custo ativa',
      () {
        const habSustComReducao = Habilidade(
          id: 'h_sust_red',
          nome: 'Velocidade Reduzida',
          tipo: TipoHabilidade.ativada,
          origem: OrigemHabilidade.classe,
          classeId: 'Arcanista',
          custo: CustoHabilidade(
            fixo: 3,
            reducoes: [ReducaoCusto(fonteId: 'foco', valor: 2)],
          ),
          ehMagia: true,
          alcance: AlcanceHabilidade.pessoal,
          duracao: Duracao(tipo: TipoDuracao.sustentada),
        );

        final engine = HabilidadeEngine(rng: SequenciaRng([10]));
        var mundo = criarMundoPadrao(); // pmAtual = 20

        // Ativação usa redução (3 - 2 = 1 PM) -> pmAtual = 19
        mundo = engine
            .ativarHabilidade(
              mundo: mundo,
              usuarioId: 'p1',
              habilidade: habSustComReducao,
            )
            .mundoAtualizado;
        expect(mundo.personagens['p1']!.pmState.pmAtual, 19);

        // Sustentação na rodada 2 cobra 1 PM fixo (R27 não reduz para 0!) -> pmAtual = 18
        var ciclo = engine.duracaoEngine.processarInicioTurno(
          personagemId: 'p1',
          rodada: 2,
          efeitos: mundo.efeitos,
          areasPersistentes: mundo.areasPersistentes,
          personagens: mundo.personagens,
          relogio: mundo.relogio,
          cenaAtual: mundo.cenaAtual,
          sustentacoesPendentes: mundo.sustentacoesPendentes,
          paresConsumidos: mundo.paresHabilidadeEventoConsumidos,
          controleDeAcoes: ControleDeAcoesPermissivo(),
        );
        mundo = aplicarCiclo(mundo, ciclo);

        ciclo = engine.duracaoEngine.resolverSustentacao(
          efeitoId: mundo.efeitos.first.id,
          manter: true,
          efeitos: mundo.efeitos,
          areasPersistentes: mundo.areasPersistentes,
          personagens: mundo.personagens,
          relogio: mundo.relogio,
          cenaAtual: mundo.cenaAtual,
          sustentacoesPendentes: mundo.sustentacoesPendentes,
          paresConsumidos: mundo.paresHabilidadeEventoConsumidos,
          controleDeAcoes: ControleDeAcoesPermissivo(),
        );
        mundo = aplicarCiclo(mundo, ciclo);
        expect(mundo.personagens['p1']!.pmState.pmAtual, 18);
      },
    );

    test(
      'Caso 26: DEFINIDA em rodadas: duração 3 ativada na rodada 2 expira na virada para a rodada 5. Com INICIO_TURNO_DO_USUARIO, expira no início do turno dele na rodada 5',
      () {
        const hab3Rodadas = Habilidade(
          id: 'h_3r',
          nome: 'Bênção Curta',
          tipo: TipoHabilidade.ativada,
          origem: OrigemHabilidade.classe,
          classeId: 'Arcanista',
          custo: CustoHabilidade(fixo: 1),
          alcance: AlcanceHabilidade.pessoal,
          duracao: Duracao(
            tipo: TipoDuracao.definida,
            definida: DuracaoDefinida(
              quantidade: 3,
              unidade: UnidadeDuracao.rodada,
            ),
          ),
        );

        const configVirada = ConfiguracoesMesaT20(
          expiracaoRodadas: ModoExpiracaoRodadas.viradaDeRodada,
        );
        final engine = HabilidadeEngine(
          rng: SequenciaRng([10]),
          configuracoes: configVirada,
        );
        var mundo = criarMundoPadrao(
          configuracoes: configVirada,
          relogio: const RelogioDeJogo(rodadaAtual: 2),
        );

        mundo = engine
            .ativarHabilidade(
              mundo: mundo,
              usuarioId: 'p1',
              habilidade: hab3Rodadas,
            )
            .mundoAtualizado;
        expect(mundo.efeitos.first.expiraNaRodada, 5);

        // Rodada 4: ainda ativo
        var ciclo = engine.duracaoEngine.processarAvancoDeRodada(
          novaRodada: 4,
          efeitos: mundo.efeitos,
          areasPersistentes: mundo.areasPersistentes,
          personagens: mundo.personagens,
          relogio: mundo.relogio,
          cenaAtual: mundo.cenaAtual,
          sustentacoesPendentes: mundo.sustentacoesPendentes,
          paresConsumidos: mundo.paresHabilidadeEventoConsumidos,
        );
        mundo = aplicarCiclo(mundo, ciclo);
        expect(mundo.efeitos.where((e) => e.estaEmJogo).length, 1);

        // Virada para a rodada 5 (gatilho padrão VIRADA_DE_RODADA): expira!
        ciclo = engine.duracaoEngine.processarAvancoDeRodada(
          novaRodada: 5,
          efeitos: mundo.efeitos,
          areasPersistentes: mundo.areasPersistentes,
          personagens: mundo.personagens,
          relogio: mundo.relogio,
          cenaAtual: mundo.cenaAtual,
          sustentacoesPendentes: mundo.sustentacoesPendentes,
          paresConsumidos: mundo.paresHabilidadeEventoConsumidos,
        );
        mundo = aplicarCiclo(mundo, ciclo);
        expect(mundo.efeitos.where((e) => e.estaEmJogo), isEmpty);

        // Agora com INICIO_TURNO_DO_USUARIO
        const configInicioTurno = ConfiguracoesMesaT20(
          expiracaoRodadas: ModoExpiracaoRodadas.inicioTurnoDoUsuario,
        );
        final engine2 = HabilidadeEngine(
          rng: SequenciaRng([10]),
          configuracoes: configInicioTurno,
        );
        var mundo2 = criarMundoPadrao(
          configuracoes: configInicioTurno,
          relogio: const RelogioDeJogo(rodadaAtual: 2),
        );
        mundo2 = engine2
            .ativarHabilidade(
              mundo: mundo2,
              usuarioId: 'p1',
              habilidade: hab3Rodadas,
            )
            .mundoAtualizado;

        // Na virada para a rodada 5 ainda não expira, só no início do turno de p1 na rodada 5
        var ciclo2 = engine2.duracaoEngine.processarAvancoDeRodada(
          novaRodada: 5,
          efeitos: mundo2.efeitos,
          areasPersistentes: mundo2.areasPersistentes,
          personagens: mundo2.personagens,
          relogio: mundo2.relogio,
          cenaAtual: mundo2.cenaAtual,
          sustentacoesPendentes: mundo2.sustentacoesPendentes,
          paresConsumidos: mundo2.paresHabilidadeEventoConsumidos,
        );
        mundo2 = aplicarCiclo(mundo2, ciclo2);
        expect(mundo2.efeitos.where((e) => e.estaEmJogo).length, 1);

        ciclo2 = engine2.duracaoEngine.processarInicioTurno(
          personagemId: 'p1',
          rodada: 5,
          efeitos: mundo2.efeitos,
          areasPersistentes: mundo2.areasPersistentes,
          personagens: mundo2.personagens,
          relogio: mundo2.relogio,
          cenaAtual: mundo2.cenaAtual,
          sustentacoesPendentes: mundo2.sustentacoesPendentes,
          paresConsumidos: mundo2.paresHabilidadeEventoConsumidos,
          controleDeAcoes: ControleDeAcoesPermissivo(),
        );
        mundo2 = aplicarCiclo(mundo2, ciclo2);
        expect(mundo2.efeitos.where((e) => e.estaEmJogo), isEmpty);
      },
    );

    test(
      'Caso 27: DEFINIDA em horas: avançar 59 min não expira. Avançar 60 min expira. Avanço grande processa as expirações em ordem cronológica',
      () {
        const hab1Hora = Habilidade(
          id: 'h_1h',
          nome: 'Montaria Arcana (1h)',
          tipo: TipoHabilidade.ativada,
          origem: OrigemHabilidade.classe,
          classeId: 'Arcanista',
          custo: CustoHabilidade(fixo: 1),
          alcance: AlcanceHabilidade.pessoal,
          duracao: Duracao(
            tipo: TipoDuracao.definida,
            definida: DuracaoDefinida(
              quantidade: 1,
              unidade: UnidadeDuracao.hora,
            ),
          ),
        );
        const hab10Min = Habilidade(
          id: 'h_10m',
          nome: 'Visão Mística (10m)',
          tipo: TipoHabilidade.ativada,
          origem: OrigemHabilidade.classe,
          classeId: 'Arcanista',
          custo: CustoHabilidade(fixo: 1),
          alcance: AlcanceHabilidade.pessoal,
          duracao: Duracao(
            tipo: TipoDuracao.definida,
            definida: DuracaoDefinida(
              quantidade: 10,
              unidade: UnidadeDuracao.minuto,
            ),
          ),
        );

        final engine = HabilidadeEngine(rng: SequenciaRng([10]));
        var mundo = criarMundoPadrao();

        mundo = engine
            .ativarHabilidade(
              mundo: mundo,
              usuarioId: 'p1',
              habilidade: hab1Hora,
            )
            .mundoAtualizado;
        mundo = engine
            .ativarHabilidade(
              mundo: mundo,
              usuarioId: 'p1',
              habilidade: hab10Min,
            )
            .mundoAtualizado;

        // Avançar 59 min (3540 s): hab10Min expira; hab1Hora permanece ativa
        final res59m = engine.duracaoEngine.avancarTempoSegundos(
          deltaSegundos: 59 * 60,
          efeitos: mundo.efeitos,
          areasPersistentes: mundo.areasPersistentes,
          personagens: mundo.personagens,
          relogio: mundo.relogio,
          cenaAtual: mundo.cenaAtual,
          sustentacoesPendentes: mundo.sustentacoesPendentes,
          paresConsumidos: mundo.paresHabilidadeEventoConsumidos,
        );
        mundo = aplicarCiclo(mundo, res59m);
        final ativos59 = mundo.efeitos.where((e) => e.estaEmJogo).toList();
        expect(ativos59.length, 1);
        expect(ativos59.first.habilidadeId, 'h_1h');

        // Avançar mais 1 min (60 s): totaliza 60 min -> hab1Hora expira
        final res60m = engine.duracaoEngine.avancarTempoSegundos(
          deltaSegundos: 60,
          efeitos: mundo.efeitos,
          areasPersistentes: mundo.areasPersistentes,
          personagens: mundo.personagens,
          relogio: mundo.relogio,
          cenaAtual: mundo.cenaAtual,
          sustentacoesPendentes: mundo.sustentacoesPendentes,
          paresConsumidos: mundo.paresHabilidadeEventoConsumidos,
        );
        mundo = aplicarCiclo(mundo, res60m);
        expect(mundo.efeitos.where((e) => e.estaEmJogo), isEmpty);
      },
    );

    test(
      'Caso 28: PERMANENTE: avançar 10 dias não expira. encerrarEfeito() funciona',
      () {
        const habPerm = Habilidade(
          id: 'h_perm',
          nome: 'Luz Permanente',
          tipo: TipoHabilidade.ativada,
          origem: OrigemHabilidade.classe,
          classeId: 'Arcanista',
          custo: CustoHabilidade(fixo: 2),
          alcance: AlcanceHabilidade.pessoal,
          duracao: Duracao(tipo: TipoDuracao.permanente),
        );

        final engine = HabilidadeEngine(rng: SequenciaRng([10]));
        var mundo = criarMundoPadrao();

        final r = engine.ativarHabilidade(
          mundo: mundo,
          usuarioId: 'p1',
          habilidade: habPerm,
        );
        mundo = r.mundoAtualizado;
        final efeitoId = r.resultado.efeitoId!;

        // Avançar 10 dias -> continua ativo
        var ciclo = engine.duracaoEngine.avancarTempoSegundos(
          deltaSegundos: 10 * 86400,
          efeitos: mundo.efeitos,
          areasPersistentes: mundo.areasPersistentes,
          personagens: mundo.personagens,
          relogio: mundo.relogio,
          cenaAtual: mundo.cenaAtual,
          sustentacoesPendentes: mundo.sustentacoesPendentes,
          paresConsumidos: mundo.paresHabilidadeEventoConsumidos,
        );
        mundo = aplicarCiclo(mundo, ciclo);
        expect(mundo.efeitos.where((e) => e.estaEmJogo).length, 1);

        // Encerrar voluntariamente -> funciona
        ciclo = engine.duracaoEngine.encerrarEfeito(
          efeitoId: efeitoId,
          solicitanteId: 'p1',
          efeitos: mundo.efeitos,
          areasPersistentes: mundo.areasPersistentes,
          personagens: mundo.personagens,
          relogio: mundo.relogio,
          cenaAtual: mundo.cenaAtual,
          sustentacoesPendentes: mundo.sustentacoesPendentes,
          paresConsumidos: mundo.paresHabilidadeEventoConsumidos,
          controleDeAcoes: ControleDeAcoesPermissivo(),
        );
        mundo = aplicarCiclo(mundo, ciclo);
        expect(mundo.efeitos.where((e) => e.estaEmJogo), isEmpty);
      },
    );

    test(
      'Caso 29: Área persistente: alvo que entra é afetado, e ao sair deixa de ser (modificador revogado). Alvo incompatível ignorado. Usuário em alcance pessoal não afetado. Ao fim do efeito a área some',
      () {
        const habAreaPersistente = Habilidade(
          id: 'h_nevoa',
          nome: 'Névoa Consagrada',
          tipo: TipoHabilidade.ativada,
          origem: OrigemHabilidade.classe,
          classeId: 'Arcanista',
          custo: CustoHabilidade(fixo: 2),
          alcance: AlcanceHabilidade.pessoal,
          alvosPermitidos: [TipoAlvoPermitido.criatura],
          area: Area(
            tipo: TipoArea.quadrado,
            tamanhoQuadrados: 3,
            origemCelula: Posicao2D(0, 0),
          ),
          duracao: Duracao(tipo: TipoDuracao.cena),
          modificadoresGerados: [
            ModificadorAplicado(
              fonteTipo: FonteModificador.magia,
              fonteId: 'h_nevoa',
              alvoCaracteristica: 'DEFESA',
              valor: 2,
            ),
          ],
        );

        const aliadoFora = AlvoMapa(
          id: 'aliado_1',
          nome: 'Paladino',
          tipo: TipoAlvoPermitido.criatura,
          posicao: Posicao2D(5, 5),
        );
        const bauObjeto = AlvoMapa(
          id: 'bau_1',
          nome: 'Baú',
          tipo: TipoAlvoPermitido.objeto,
          posicao: Posicao2D(5, 5),
        );

        final engine = HabilidadeEngine(rng: SequenciaRng([10]));
        var mundo = criarMundoPadrao(alvos: [aliadoFora, bauObjeto]);

        // Cria área em (0,0)..(2,2) com alcance PESSOAL -> usuário p1 em (0,0) NÃO é afetado
        final rAtiv = engine.ativarHabilidade(
          mundo: mundo,
          usuarioId: 'p1',
          habilidade: habAreaPersistente,
        );
        mundo = rAtiv.mundoAtualizado;
        expect(mundo.areasPersistentes.length, 1);
        expect(mundo.areasPersistentes.values.first.alvosDentro, isEmpty);

        // Aliado entra na área -> passa a receber o modificador +2 na DEFESA
        final movEntrada = engine.moverTokenNoMapa(
          mundo: mundo,
          tokenId: 'aliado_1',
          novaPosicao: const Posicao2D(1, 1),
        );
        mundo = movEntrada.mundoAtualizado;
        expect(
          movEntrada.eventosArea.any((e) => e['tipo'] == 'AlvoEntrouNaArea'),
          isTrue,
        );
        expect(
          mundo.areasPersistentes.values.first.alvosDentro,
          contains('aliado_1'),
        );
        final modsAliadoDentro = engine.obterModificadoresResolvidosParaAlvo(
          mundo: mundo,
          alvoId: 'aliado_1',
          caracteristica: 'DEFESA',
        );
        expect(modsAliadoDentro.where((m) => m.aplicado).length, 1);

        // Objeto incompatível entra na área -> ignorado
        final movObjeto = engine.moverTokenNoMapa(
          mundo: mundo,
          tokenId: 'bau_1',
          novaPosicao: const Posicao2D(1, 1),
        );
        mundo = movObjeto.mundoAtualizado;
        expect(movObjeto.eventosArea, isEmpty);

        // Aliado sai da área -> deixa de ser afetado (modificador revogado)
        final movSaida = engine.moverTokenNoMapa(
          mundo: mundo,
          tokenId: 'aliado_1',
          novaPosicao: const Posicao2D(6, 6),
        );
        mundo = movSaida.mundoAtualizado;
        expect(
          movSaida.eventosArea.any((e) => e['tipo'] == 'AlvoSaiuDaArea'),
          isTrue,
        );
        final modsAliadoFora = engine.obterModificadoresResolvidosParaAlvo(
          mundo: mundo,
          alvoId: 'aliado_1',
          caracteristica: 'DEFESA',
        );
        expect(modsAliadoFora, isEmpty);

        // Encerrar efeito remove a área persistente
        final cicloFim = engine.duracaoEngine.encerrarEfeito(
          efeitoId: mundo.efeitos.first.id,
          solicitanteId: 'p1',
          efeitos: mundo.efeitos,
          areasPersistentes: mundo.areasPersistentes,
          personagens: mundo.personagens,
          relogio: mundo.relogio,
          cenaAtual: mundo.cenaAtual,
          sustentacoesPendentes: mundo.sustentacoesPendentes,
          paresConsumidos: mundo.paresHabilidadeEventoConsumidos,
          controleDeAcoes: ControleDeAcoesPermissivo(),
        );
        mundo = aplicarCiclo(mundo, cicloFim);
        expect(mundo.areasPersistentes, isEmpty);
      },
    );

    test(
      'Caso 30: DESCARREGAR: nasce DORMENTE sem modificadores. Gatilho aplica 1x e vai a DESCARREGADO. Duração acabando antes termina EXPIRADO. Mesmo evento não descarrega 2x. Descarregar com INSTANTANEA ou SUSTENTADA é inválido',
      () {
        // Validação: INSTANTANEA ou SUSTENTADA com descarregar é inválido
        const habInvalida = Habilidade(
          id: 'h_inv',
          nome: 'Inválida',
          tipo: TipoHabilidade.ativada,
          origem: OrigemHabilidade.classe,
          alcance: AlcanceHabilidade.pessoal,
          duracao: Duracao(
            tipo: TipoDuracao.sustentada,
            descarregar: ConfigDescarga(gatilho: 'ACERTAR_ATAQUE'),
          ),
        );
        expect(
          () => habInvalida.validarDefinicao(),
          throwsA(isA<RegraTesteException>()),
        );

        const habDescarga = Habilidade(
          id: 'h_toque_chocante_guardado',
          nome: 'Arma Mágica Descarregável',
          tipo: TipoHabilidade.ativada,
          origem: OrigemHabilidade.classe,
          classeId: 'Arcanista',
          custo: CustoHabilidade(fixo: 1),
          alcance: AlcanceHabilidade.pessoal,
          duracao: Duracao(
            tipo: TipoDuracao.cena,
            descarregar: ConfigDescarga(gatilho: 'ACERTAR_ATAQUE'),
          ),
          modificadoresGerados: [
            ModificadorAplicado(
              fonteTipo: FonteModificador.magia,
              fonteId: 'h_toque_chocante_guardado',
              alvoCaracteristica: 'DANO',
              valor: 10,
            ),
          ],
        );

        final engine = HabilidadeEngine(rng: SequenciaRng([10]));
        var mundo = criarMundoPadrao();

        final rAtiv = engine.ativarHabilidade(
          mundo: mundo,
          usuarioId: 'p1',
          habilidade: habDescarga,
        );
        mundo = rAtiv.mundoAtualizado;
        final efeito = mundo.efeitos.first;

        // Nasce DORMENTE e não aplica modificadores enquanto dormente
        expect(efeito.estado, EstadoEfeito.dormente);
        expect(
          engine.obterModificadoresResolvidosParaAlvo(
            mundo: mundo,
            alvoId: 'p1',
            caracteristica: 'DANO',
          ),
          isEmpty,
        );

        // Disparo pelo evento ev_ataque_1 -> descarrega e vai para DESCARREGADO
        const evAtaque = EventoDeJogo(
          id: 'ev_ataque_1',
          tipo: 'ACERTAR_ATAQUE',
        );
        final resDesc = engine.duracaoEngine.dispararGatilhoDescarga(
          evento: evAtaque,
          efeitos: mundo.efeitos,
          areasPersistentes: mundo.areasPersistentes,
          personagens: mundo.personagens,
          relogio: mundo.relogio,
          cenaAtual: mundo.cenaAtual,
          sustentacoesPendentes: mundo.sustentacoesPendentes,
          paresConsumidos: mundo.paresHabilidadeEventoConsumidos,
        );
        mundo = aplicarCiclo(mundo, resDesc);
        expect(mundo.efeitos.first.estado, EstadoEfeito.descarregado);
        expect(mundo.efeitos.first.motivoFim, MotivoFimEfeito.descarga);
      },
    );

    test(
      'Caso 31: Encerrar: o usuário consegue. O alvo não consegue. O mestre consegue. Penalidade de PM liberada, pmMax volta e pmAtual não sobe',
      () {
        const habBuffPenal = Habilidade(
          id: 'h_buff_aliado',
          nome: 'Vínculo Protetor',
          tipo: TipoHabilidade.ativada,
          origem: OrigemHabilidade.classe,
          classeId: 'Arcanista',
          custo: CustoHabilidade(fixo: 1, penalidadePM: 3),
          alcance: AlcanceHabilidade.curto,
          duracao: Duracao(tipo: TipoDuracao.cena),
        );

        const aliado = AlvoMapa(
          id: 'aliado_1',
          nome: 'Guerreiro',
          tipo: TipoAlvoPermitido.criatura,
          posicao: Posicao2D(2, 0),
        );
        final engine = HabilidadeEngine(rng: SequenciaRng([10]));
        var mundo = criarMundoPadrao(alvos: [aliado]);

        final rAtiv = engine.ativarHabilidade(
          mundo: mundo,
          usuarioId: 'p1',
          habilidade: habBuffPenal,
          alvosEscolhidosIds: const ['aliado_1'],
        );
        mundo = rAtiv.mundoAtualizado;
        final efeitoId = rAtiv.resultado.efeitoId!;
        expect(mundo.personagens['p1']!.pmState.pmMaxEfetivo, 17);
        expect(mundo.personagens['p1']!.pmState.pmAtual, 17);

        // O alvo ('aliado_1') NÃO consegue encerrar o efeito do usuário ('p1')
        expect(
          () => engine.duracaoEngine.encerrarEfeito(
            efeitoId: efeitoId,
            solicitanteId: 'aliado_1',
            ehMestre: false,
            efeitos: mundo.efeitos,
            areasPersistentes: mundo.areasPersistentes,
            personagens: mundo.personagens,
            relogio: mundo.relogio,
            cenaAtual: mundo.cenaAtual,
            sustentacoesPendentes: mundo.sustentacoesPendentes,
            paresConsumidos: mundo.paresHabilidadeEventoConsumidos,
            controleDeAcoes: ControleDeAcoesPermissivo(),
          ),
          throwsA(isA<RegraTesteException>()),
        );

        // O usuário ('p1') consegue encerrar
        final cicloUsuario = engine.duracaoEngine.encerrarEfeito(
          efeitoId: efeitoId,
          solicitanteId: 'p1',
          ehMestre: false,
          efeitos: mundo.efeitos,
          areasPersistentes: mundo.areasPersistentes,
          personagens: mundo.personagens,
          relogio: mundo.relogio,
          cenaAtual: mundo.cenaAtual,
          sustentacoesPendentes: mundo.sustentacoesPendentes,
          paresConsumidos: mundo.paresHabilidadeEventoConsumidos,
          controleDeAcoes: ControleDeAcoesPermissivo(),
        );
        expect(
          cicloUsuario.efeitos.where((e) => e.estaEmJogo),
          isEmpty,
        );
        expect(cicloUsuario.personagens['p1']!.pmState.pmMaxEfetivo, 20);
        expect(cicloUsuario.personagens['p1']!.pmState.pmAtual, 17);

        // O mestre também consegue encerrar qualquer efeito
        final cicloMestre = engine.duracaoEngine.encerrarEfeito(
          efeitoId: efeitoId,
          solicitanteId: 'MESTRE',
          ehMestre: true,
          efeitos: mundo.efeitos,
          areasPersistentes: mundo.areasPersistentes,
          personagens: mundo.personagens,
          relogio: mundo.relogio,
          cenaAtual: mundo.cenaAtual,
          sustentacoesPendentes: mundo.sustentacoesPendentes,
          paresConsumidos: mundo.paresHabilidadeEventoConsumidos,
          controleDeAcoes: ControleDeAcoesPermissivo(),
        );
        expect(cicloMestre.efeitos.where((e) => e.estaEmJogo), isEmpty);
      },
    );

    test(
      'Caso 32: Morte: a sustentada encerra (MORTE_DO_USUARIO). CENA, DEFINIDA e PERMANENTE do morto continuam. Remover o token não encerra efeitos',
      () {
        const habSust = Habilidade(
          id: 'h_sust_m',
          nome: 'Sustentada',
          tipo: TipoHabilidade.ativada,
          origem: OrigemHabilidade.classe,
          classeId: 'Arcanista',
          custo: CustoHabilidade(fixo: 1),
          alcance: AlcanceHabilidade.pessoal,
          duracao: Duracao(tipo: TipoDuracao.sustentada),
        );
        const habCena = Habilidade(
          id: 'h_cena_m',
          nome: 'Cena',
          tipo: TipoHabilidade.ativada,
          origem: OrigemHabilidade.classe,
          classeId: 'Arcanista',
          custo: CustoHabilidade(fixo: 1),
          alcance: AlcanceHabilidade.pessoal,
          duracao: Duracao(tipo: TipoDuracao.cena),
        );
        const habPerm = Habilidade(
          id: 'h_perm_m',
          nome: 'Permanente',
          tipo: TipoHabilidade.ativada,
          origem: OrigemHabilidade.classe,
          classeId: 'Arcanista',
          custo: CustoHabilidade(fixo: 1),
          alcance: AlcanceHabilidade.pessoal,
          duracao: Duracao(tipo: TipoDuracao.permanente),
        );

        final engine = HabilidadeEngine(rng: SequenciaRng([10]));
        var mundo = criarMundoPadrao();

        mundo = engine
            .ativarHabilidade(
              mundo: mundo,
              usuarioId: 'p1',
              habilidade: habSust,
            )
            .mundoAtualizado;
        mundo = engine
            .ativarHabilidade(
              mundo: mundo,
              usuarioId: 'p1',
              habilidade: habCena,
            )
            .mundoAtualizado;
        mundo = engine
            .ativarHabilidade(
              mundo: mundo,
              usuarioId: 'p1',
              habilidade: habPerm,
            )
            .mundoAtualizado;
        expect(mundo.efeitos.where((e) => e.estaEmJogo).length, 3);

        // Morte de p1: encerra apenas a SUSTENTADA; CENA e PERMANENTE continuam!
        final cicloMorte = engine.duracaoEngine.processarMortePersonagem(
          personagemId: 'p1',
          efeitos: mundo.efeitos,
          areasPersistentes: mundo.areasPersistentes,
          personagens: mundo.personagens,
          relogio: mundo.relogio,
          cenaAtual: mundo.cenaAtual,
          sustentacoesPendentes: mundo.sustentacoesPendentes,
          paresConsumidos: mundo.paresHabilidadeEventoConsumidos,
        );
        mundo = aplicarCiclo(mundo, cicloMorte);

        final emJogo = mundo.efeitos.where((e) => e.estaEmJogo).toList();
        expect(emJogo.length, 2);
        expect(
          emJogo.map((e) => e.habilidadeId),
          containsAll(['h_cena_m', 'h_perm_m']),
        );

        // Remover o token do mapa também não encerra os efeitos restantes
        mundo = engine.removerTokenDoMapa(mundo: mundo, tokenId: 'p1');
        expect(mundo.efeitos.where((e) => e.estaEmJogo).length, 2);
      },
    );

    test(
      'Caso 33: Reativar no mesmo alvo substitui e reinicia a duração. Em alvo diferente, coexistem. O mesmo bônus não acumula (R29)',
      () {
        const habBuff = Habilidade(
          id: 'h_heroismo',
          nome: 'Heroísmo',
          tipo: TipoHabilidade.ativada,
          origem: OrigemHabilidade.classe,
          classeId: 'Arcanista',
          custo: CustoHabilidade(fixo: 1),
          alcance: AlcanceHabilidade.curto,
          duracao: Duracao(
            tipo: TipoDuracao.definida,
            definida: DuracaoDefinida(
              quantidade: 5,
              unidade: UnidadeDuracao.rodada,
            ),
          ),
        );

        const aliado1 = AlvoMapa(
          id: 'a1',
          nome: 'Aliado 1',
          tipo: TipoAlvoPermitido.criatura,
          posicao: Posicao2D(1, 0),
        );
        const aliado2 = AlvoMapa(
          id: 'a2',
          nome: 'Aliado 2',
          tipo: TipoAlvoPermitido.criatura,
          posicao: Posicao2D(2, 0),
        );

        final engine = HabilidadeEngine(rng: SequenciaRng([10]));
        var mundo = criarMundoPadrao(alvos: [aliado1, aliado2]);

        // Ativa em a1 na rodada 1 -> expira na rodada 6
        mundo = engine
            .ativarHabilidade(
              mundo: mundo,
              usuarioId: 'p1',
              habilidade: habBuff,
              alvosEscolhidosIds: const ['a1'],
            )
            .mundoAtualizado;
        expect(mundo.efeitos.where((e) => e.estaEmJogo).length, 1);
        expect(
          mundo.efeitos.firstWhere((e) => e.estaEmJogo).expiraNaRodada,
          6,
        );

        // Avança para rodada 3 e reativa em a1 -> substitui e reinicia duração (expira na rodada 8)
        final cicloR3 = engine.duracaoEngine.processarAvancoDeRodada(
          novaRodada: 3,
          efeitos: mundo.efeitos,
          areasPersistentes: mundo.areasPersistentes,
          personagens: mundo.personagens,
          relogio: mundo.relogio,
          cenaAtual: mundo.cenaAtual,
          sustentacoesPendentes: mundo.sustentacoesPendentes,
          paresConsumidos: mundo.paresHabilidadeEventoConsumidos,
        );
        mundo = aplicarCiclo(mundo, cicloR3);

        mundo = engine
            .ativarHabilidade(
              mundo: mundo,
              usuarioId: 'p1',
              habilidade: habBuff,
              alvosEscolhidosIds: const ['a1'],
            )
            .mundoAtualizado;
        expect(mundo.efeitos.where((e) => e.estaEmJogo).length, 1);
        expect(
          mundo.efeitos.firstWhere((e) => e.estaEmJogo).expiraNaRodada,
          8,
        );

        // Ativa em a2 (alvo diferente) -> coexistem 2 efeitos ativos (um em a1, outro em a2)
        mundo = engine
            .ativarHabilidade(
              mundo: mundo,
              usuarioId: 'p1',
              habilidade: habBuff,
              alvosEscolhidosIds: const ['a2'],
            )
            .mundoAtualizado;
        expect(mundo.efeitos.where((e) => e.estaEmJogo).length, 2);
      },
    );

    test(
      'Caso 34: Efeito que expira durante AGUARDANDO_DECLARACAO não altera o teste já rolado (R30)',
      () {
        final service = MotorTestesService(rng: SequenciaRng([14]));
        const req = TesteRequest(
          id: 'req_r30',
          tipo: TipoTeste.comum,
          modo: ModoTeste.pericia,
          cd: 15,
          participantes: ['p1'],
        );

        var estado = service.criarEstadoTeste(
          request: req,
          personagemId: 'p1',
          fonteMod: 'ATLETISMO',
          modBase: 2,
          modificadoresExtras: const [
            ModificadorAplicado(
              fonteTipo: FonteModificador.magia,
              fonteId: 'orientacao',
              efeitoId: 'ef_1',
              alvoCaracteristica: 'ATLETISMO',
              valor: 2,
            ),
          ],
        );
        estado = service.rolarEstadoTeste(
          estado: estado,
          efeitosAtivosIds: const {'ef_1'},
        );
        expect(estado.fase, FaseEstadoTeste.aguardandoDeclaracao);
        expect(estado.resultadoAtual!.total, 18); // 14 + 2 + 2

        // Mesmo que 'ef_1' expire antes da declaração, declararResultadoTeste mantém o total 18 já rolado
        estado = service.declararResultadoTeste(estado);
        expect(estado.resultadoAtual!.total, 18);
      },
    );

    test(
      'Caso 35: Reconexão no meio de uma sustentação pendente: o jogador recebe o estado correto, com efeitos, relógio, cena, PM e pendências',
      () {
        const habSust = Habilidade(
          id: 'h_sust_rec',
          nome: 'Velocidade',
          tipo: TipoHabilidade.ativada,
          origem: OrigemHabilidade.classe,
          classeId: 'Arcanista',
          custo: CustoHabilidade(fixo: 3),
          alcance: AlcanceHabilidade.pessoal,
          duracao: Duracao(tipo: TipoDuracao.sustentada),
        );

        final engine = HabilidadeEngine(rng: SequenciaRng([10]));
        var mundo = criarMundoPadrao();
        mundo = engine
            .ativarHabilidade(
              mundo: mundo,
              usuarioId: 'p1',
              habilidade: habSust,
            )
            .mundoAtualizado;
        final ciclo = engine.duracaoEngine.processarInicioTurno(
          personagemId: 'p1',
          rodada: 2,
          efeitos: mundo.efeitos,
          areasPersistentes: mundo.areasPersistentes,
          personagens: mundo.personagens,
          relogio: mundo.relogio,
          cenaAtual: mundo.cenaAtual,
          sustentacoesPendentes: mundo.sustentacoesPendentes,
          paresConsumidos: mundo.paresHabilidadeEventoConsumidos,
          controleDeAcoes: ControleDeAcoesPermissivo(),
        );
        mundo = aplicarCiclo(mundo, ciclo);
        expect(mundo.sustentacoesPendentes.length, 1);

        final jsonSnapshot = mundo.toJson();
        final mundoReconectado = EstadoMundoHabilidades.fromJson(jsonSnapshot);

        expect(mundoReconectado.efeitos.length, 1);
        expect(mundoReconectado.sustentacoesPendentes.length, 1);
        expect(mundoReconectado.relogio.rodadaAtual, 2);
        expect(mundoReconectado.cenaAtual.id, mundo.cenaAtual.id);
        expect(mundoReconectado.personagens['p1']!.pmState.pmAtual, 17);
      },
    );

    test(
      'Caso 36: Reiniciar o app do host restaura efeitos, relógio, cena e PM (salvarEmDisco / restaurarDeDisco)',
      () async {
        const habCena = Habilidade(
          id: 'h_persist',
          nome: 'Escudo da Fé',
          tipo: TipoHabilidade.ativada,
          origem: OrigemHabilidade.classe,
          classeId: 'Arcanista',
          custo: CustoHabilidade(fixo: 2, penalidadePM: 1),
          alcance: AlcanceHabilidade.pessoal,
          duracao: Duracao(tipo: TipoDuracao.cena),
        );

        final engine = HabilidadeEngine(rng: SequenciaRng([10]));
        var mundo = criarMundoPadrao();
        mundo = engine
            .ativarHabilidade(
              mundo: mundo,
              usuarioId: 'p1',
              habilidade: habCena,
            )
            .mundoAtualizado;

        final tempDir = await Directory.systemTemp.createTemp('t20_m2_test_');
        final caminho = '${tempDir.path}/estado_mundo_m2.json';
        try {
          await mundo.salvarEmDisco(caminho);
          final restaurado = await EstadoMundoHabilidades.restaurarDeDisco(
            caminho,
          );
          expect(restaurado.efeitos.length, 1);
          expect(restaurado.efeitos.first.habilidadeId, 'h_persist');
          expect(restaurado.personagens['p1']!.pmState.pmAtual, 18);
          expect(restaurado.personagens['p1']!.pmState.pmMaxEfetivo, 19);
        } finally {
          await tempDir.delete(recursive: true);
        }
      },
    );

    test(
      'Caso 37: Validador: INSTANTANEA com penalidadePM, DEFINIDA sem definida e descarregar sem gatilho são rejeitadas',
      () {
        const instComPenalidade = Habilidade(
          id: 'inv_1',
          nome: 'Inv 1',
          tipo: TipoHabilidade.ativada,
          origem: OrigemHabilidade.classe,
          custo: CustoHabilidade(penalidadePM: 2),
          alcance: AlcanceHabilidade.pessoal,
          duracao: Duracao(tipo: TipoDuracao.instantanea),
        );
        expect(
          () => instComPenalidade.validarDefinicao(),
          throwsA(isA<RegraTesteException>()),
        );

        const defSemDefinida = Habilidade(
          id: 'inv_2',
          nome: 'Inv 2',
          tipo: TipoHabilidade.ativada,
          origem: OrigemHabilidade.classe,
          alcance: AlcanceHabilidade.pessoal,
          duracao: Duracao(tipo: TipoDuracao.definida),
        );
        expect(
          () => defSemDefinida.validarDefinicao(),
          throwsA(isA<RegraTesteException>()),
        );

        const descSemGatilho = Habilidade(
          id: 'inv_3',
          nome: 'Inv 3',
          tipo: TipoHabilidade.ativada,
          origem: OrigemHabilidade.classe,
          alcance: AlcanceHabilidade.pessoal,
          duracao: Duracao(
            tipo: TipoDuracao.cena,
            descarregar: ConfigDescarga(gatilho: ''),
          ),
        );
        expect(
          () => descSemGatilho.validarDefinicao(),
          throwsA(isA<RegraTesteException>()),
        );
      },
    );
  });
}

class _ControleAcoesSpy implements IControleDeAcoes {
  final List<TipoAcao> acoesConsumidas;

  _ControleAcoesSpy(this.acoesConsumidas);

  @override
  bool temAcaoDisponivel(String personagemId, TipoAcao acao) => true;

  @override
  void consumirAcao(String personagemId, TipoAcao acao) {
    acoesConsumidas.add(acao);
  }
}
