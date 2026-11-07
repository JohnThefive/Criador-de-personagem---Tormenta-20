import 'package:flutter_test/flutter_test.dart';
import 'package:t20_creator/domain/entities/testes/configuracoes_mesa_t20.dart';
import 'package:t20_creator/domain/entities/testes/eventos_rede_testes.dart';
import 'package:t20_creator/domain/entities/testes/modelos_teste_t20.dart';
import 'package:t20_creator/domain/services/testes_services/i_rng.dart';
import 'package:t20_creator/domain/services/testes_services/motor_testes_service.dart';

void main() {
  group('MotorTestesService - Casos de Borda Obrigatórios (1 a 12)', () {
    test(
      'Caso 1: d20=20 com total < CD -> sucesso; d20=1 com total >= CD -> falha',
      () {
        final motor = MotorTestesService(rng: SequenciaRng([20, 1]));

        // 20 natural com mod -5 => total 15 vs CD 30 => Sucesso automático
        final reqImpossivel = const TesteRequest(
          id: 't_nat20',
          tipo: TipoTeste.comum,
          cd: 30,
          participantes: ['heroi_1'],
          modo: ModoTeste.pericia,
        );
        final res20 = motor.executarTeste(
          request: reqImpossivel,
          personagemId: 'heroi_1',
          fonteMod: 'ATLETISMO',
          modBase: -5,
        );
        expect(res20.d20, 20);
        expect(res20.total, 15);
        expect(res20.nat20, isTrue);
        expect(res20.sucessoCD, isTrue);

        // 1 natural com mod +25 => total 26 vs CD 10 => Falha automática
        final reqFacil = const TesteRequest(
          id: 't_nat1',
          tipo: TipoTeste.comum,
          cd: 10,
          participantes: ['heroi_1'],
          modo: ModoTeste.pericia,
        );
        final res1 = motor.executarTeste(
          request: reqFacil,
          personagemId: 'heroi_1',
          fonteMod: 'ATLETISMO',
          modBase: 25,
        );
        expect(res1.d20, 1);
        expect(res1.total, 26);
        expect(res1.nat1, isTrue);
        expect(res1.sucessoCD, isFalse);
      },
    );

    test(
      'Caso 2: Oposto com empate de total -> desempata pelo maior modificador; empate persistente -> nova rolagem',
      () {
        // Parte A: Empate no total (18 vs 18), mas heroi_B tem maior modificador (+8 vs +5)
        final motorDesempate = MotorTestesService(rng: SequenciaRng([13, 10]));
        final reqOposto = const TesteRequest(
          id: 'op_1',
          tipo: TipoTeste.oposto,
          participantes: ['heroi_A', 'heroi_B'],
          modo: ModoTeste.pericia,
        );

        final rA = motorDesempate.executarTeste(
          request: reqOposto,
          personagemId: 'heroi_A',
          fonteMod: 'LUTA',
          modBase: 5, // 13 + 5 = 18
        );
        final rB = motorDesempate.executarTeste(
          request: reqOposto,
          personagemId: 'heroi_B',
          fonteMod: 'LUTA',
          modBase: 8, // 10 + 8 = 18
        );

        final confronto1 = motorDesempate.resolverConfronto(
          request: reqOposto,
          resultados: [rA, rB],
        );
        expect(rA.total, 18);
        expect(rB.total, 18);
        expect(confronto1.vencedorId, 'heroi_B');
        expect(confronto1.exigeNovaRolagemEmpate, isFalse);

        // Parte B: Empate persistente (mesmo total 17 e mesmo modificador +5)
        final motorEmpatePersistente = MotorTestesService(
          rng: SequenciaRng([12, 12]),
        );
        final rA2 = motorEmpatePersistente.executarTeste(
          request: reqOposto,
          personagemId: 'heroi_A',
          fonteMod: 'LUTA',
          modBase: 5,
        );
        final rB2 = motorEmpatePersistente.executarTeste(
          request: reqOposto,
          personagemId: 'heroi_B',
          fonteMod: 'LUTA',
          modBase: 5,
        );

        final confronto2 = motorEmpatePersistente.resolverConfronto(
          request: reqOposto,
          resultados: [rA2, rB2],
        );
        expect(confronto2.vencedorId, isNull);
        expect(confronto2.exigeNovaRolagemEmpate, isTrue);
        expect(confronto2.empatadosIds, containsAll(['heroi_A', 'heroi_B']));
      },
    );

    test(
      'Caso 3: Misto onde ninguém alcança a CD -> sem vencedor',
      () {
        final motor = MotorTestesService(rng: SequenciaRng([8, 10]));
        final reqMisto = const TesteRequest(
          id: 'misto_1',
          tipo: TipoTeste.misto,
          cd: 20,
          participantes: ['heroi_A', 'heroi_B'],
          modo: ModoTeste.pericia,
        );

        final rA = motor.executarTeste(
          request: reqMisto,
          personagemId: 'heroi_A',
          fonteMod: 'ACROBACIA',
          modBase: 4, // total 12 < 20
        );
        final rB = motor.executarTeste(
          request: reqMisto,
          personagemId: 'heroi_B',
          fonteMod: 'ACROBACIA',
          modBase: 5, // total 15 < 20
        );

        final confronto = motor.resolverConfronto(
          request: reqMisto,
          resultados: [rA, rB],
        );
        expect(rA.sucessoCD, isFalse);
        expect(rB.sucessoCD, isFalse);
        expect(confronto.vencedorId, isNull);
        expect(confronto.exigeNovaRolagemEmpate, isFalse);
      },
    );

    test(
      'Caso 4: Ajudante com total 10 -> +1; 20 -> +2; 9 -> 0',
      () {
        // Rolagens: 8 (+2 = 10), 15 (+5 = 20), 7 (+2 = 9)
        final motor = MotorTestesService(rng: SequenciaRng([8, 15, 7]));

        final ajuda10 = motor.resolverAjuda(
          ajudanteId: 'aj_1',
          pericia: 'DIPLOMACIA',
          modificador: 2, // 8 + 2 = 10 -> +1
        );
        expect(ajuda10.total, 10);
        expect(ajuda10.sucesso, isTrue);
        expect(ajuda10.bonusConcedido, 1);

        final ajuda20 = motor.resolverAjuda(
          ajudanteId: 'aj_2',
          pericia: 'INTUICAO',
          modificador: 5, // 15 + 5 = 20 -> +2
        );
        expect(ajuda20.total, 20);
        expect(ajuda20.sucesso, isTrue);
        expect(ajuda20.bonusConcedido, 2);

        final ajuda9 = motor.resolverAjuda(
          ajudanteId: 'aj_3',
          pericia: 'ENGANACAO',
          modificador: 2, // 7 + 2 = 9 -> 0
        );
        expect(ajuda9.total, 9);
        expect(ajuda9.sucesso, isFalse);
        expect(ajuda9.bonusConcedido, 0);
      },
    );

    test(
      'Caso 5: Escolher 0 bloqueado quando modificador < CD e permitido quando >= CD',
      () {
        final motor = MotorTestesService(rng: SequenciaRng([10]));
        const req = TesteRequest(
          id: 'esc_0',
          tipo: TipoTeste.comum,
          cd: 15,
          participantes: ['heroi_1'],
          modo: ModoTeste.pericia,
        );

        expect(
          motor.podeEscolher(
            opcao: OpcaoEscolher.zero,
            modificadorTotal: 14,
            cd: 15,
            flags: req.flags,
          ),
          isFalse,
        );

        expect(
          () => motor.executarTeste(
            request: req,
            personagemId: 'heroi_1',
            fonteMod: 'CONHECIMENTO',
            modBase: 14,
            opcaoEscolher: OpcaoEscolher.zero,
          ),
          throwsA(
            isA<RegraTesteException>().having(
              (e) => e.codigo,
              'codigo',
              'ESCOLHER_0_MODIFICADOR_INSUFICIENTE',
            ),
          ),
        );

        // Com modificador 15 >= CD 15, Escolher 0 é permitido e resulta em sucesso automático
        final resSucesso = motor.executarTeste(
          request: req,
          personagemId: 'heroi_1',
          fonteMod: 'CONHECIMENTO',
          modBase: 15,
          opcaoEscolher: OpcaoEscolher.zero,
        );
        expect(resSucesso.usouEscolher, OpcaoEscolher.zero);
        expect(resSucesso.sucessoCD, isTrue);
        expect(resSucesso.nat20, isFalse);
      },
    );

    test(
      'Caso 6: Escolher 10/20 bloqueados sem as flags do mestre (e Escolher 20 bloqueado em estendido)',
      () {
        final motor = MotorTestesService(rng: SequenciaRng([10]));
        const reqSemFlags = TesteRequest(
          id: 'esc_10_20',
          tipo: TipoTeste.comum,
          cd: 15,
          participantes: ['heroi_1'],
          modo: ModoTeste.pericia,
          flags: FlagsTeste(semPressao: false, semConsequencia: false),
        );

        // Escolher 10 sem flag semPressao -> bloqueado
        expect(
          () => motor.executarTeste(
            request: reqSemFlags,
            personagemId: 'heroi_1',
            fonteMod: 'OFICIO',
            modBase: 5,
            opcaoEscolher: OpcaoEscolher.dez,
          ),
          throwsA(
            isA<RegraTesteException>().having(
              (e) => e.codigo,
              'codigo',
              'ESCOLHER_10_EXIGE_SEM_PRESSAO',
            ),
          ),
        );

        // Escolher 20 com apenas semPressao (sem semConsequencia) -> bloqueado
        const reqApenasSemPressao = TesteRequest(
          id: 'esc_20_parcial',
          tipo: TipoTeste.comum,
          cd: 25,
          participantes: ['heroi_1'],
          modo: ModoTeste.pericia,
          flags: FlagsTeste(semPressao: true, semConsequencia: false),
        );
        expect(
          () => motor.executarTeste(
            request: reqApenasSemPressao,
            personagemId: 'heroi_1',
            fonteMod: 'OFICIO',
            modBase: 5,
            opcaoEscolher: OpcaoEscolher.vinte,
          ),
          throwsA(
            isA<RegraTesteException>().having(
              (e) => e.codigo,
              'codigo',
              'ESCOLHER_20_FLAGS_INSUFICIENTES',
            ),
          ),
        );

        // Escolher 20 com ambas as flags funciona no teste comum e ativa aviso de 20x tempo, sem 20 natural
        const reqComAmbasFlags = TesteRequest(
          id: 'esc_20_ok',
          tipo: TipoTeste.comum,
          cd: 30, // 20 + 5 = 25 < 30 -> falha, pois escolher 20 NÃO é 20 natural!
          participantes: ['heroi_1'],
          modo: ModoTeste.pericia,
          flags: FlagsTeste(semPressao: true, semConsequencia: true),
        );
        final res20 = motor.executarTeste(
          request: reqComAmbasFlags,
          personagemId: 'heroi_1',
          fonteMod: 'OFICIO',
          modBase: 5,
          opcaoEscolher: OpcaoEscolher.vinte,
        );
        expect(res20.d20, 20);
        expect(res20.total, 25);
        expect(res20.nat20, isFalse);
        expect(res20.sucessoCD, isFalse);
        expect(res20.avisoTempoVinteX, isTrue);

        // Escolher 20 em teste estendido -> bloqueado por padrão (R12)
        final estendido = motor.criarTesteEstendido(
          id: 'est_esc20',
          cdBase: 15,
          metas: {'OFICIO': 3},
        );
        expect(
          () => motor.executarPassoEstendido(
            teste: estendido,
            personagemId: 'heroi_1',
            pericia: 'OFICIO',
            modBase: 5,
            flags: const FlagsTeste(semPressao: true, semConsequencia: true),
            opcaoEscolher: OpcaoEscolher.vinte,
          ),
          throwsA(
            isA<RegraTesteException>().having(
              (e) => e.codigo,
              'codigo',
              'ESCOLHER_20_BLOQUEADO_ESTENDIDO',
            ),
          ),
        );
      },
    );

    test(
      'Caso 7: Estendido - reutilizar perícia no modo aberto -> rejeitar',
      () {
        final motor = MotorTestesService(rng: SequenciaRng([15, 15]));
        var teste = motor.criarTesteEstendido(
          id: 'est_aberto',
          cdBase: 15,
          metas: {'QUALQUER': 3},
          modo: ModoTesteEstendido.aberto,
        );

        // Primeiro uso de SOBREVIVENCIA com descrição -> válido
        final passo1 = motor.executarPassoEstendido(
          teste: teste,
          personagemId: 'heroi_1',
          pericia: 'SOBREVIVENCIA',
          modBase: 5,
          descricaoAcao: 'Seguir rastros na mata fechada',
        );
        teste = passo1.testeAtualizado;
        expect(teste.periciasConsumidas, contains('SOBREVIVENCIA'));

        // Segundo uso de SOBREVIVENCIA (mesmo por outro personagem) -> rejeitado!
        expect(
          () => motor.executarPassoEstendido(
            teste: teste,
            personagemId: 'heroi_2',
            pericia: 'SOBREVIVENCIA',
            modBase: 4,
            descricaoAcao: 'Procurar abrigo',
          ),
          throwsA(
            isA<RegraTesteException>().having(
              (e) => e.codigo,
              'codigo',
              'PERICIA_CONSUMIDA',
            ),
          ),
        );
      },
    );

    test(
      'Caso 8: Estendido - perícia usada para ajudar fica indisponível para o teste principal (e para nova ajuda)',
      () {
        final motor = MotorTestesService(rng: SequenciaRng([12, 15]));
        var teste = motor.criarTesteEstendido(
          id: 'est_ajuda_consumida',
          cdBase: 15,
          metas: {'QUALQUER': 3},
          modo: ModoTesteEstendido.aberto,
        );

        // Ajudante usa INVESTIGACAO para ajudar -> perícia fica consumida no desafio
        final (testeAposAjuda, resultadoAjuda) = motor.registrarAjudaEstendido(
          teste: teste,
          ajudanteId: 'ajudante_1',
          pericia: 'INVESTIGACAO',
          modificador: 3,
        );
        teste = testeAposAjuda;
        expect(resultadoAjuda.sucesso, isTrue);
        expect(teste.periciasConsumidas, contains('INVESTIGACAO'));

        // Líder tenta usar INVESTIGACAO no teste principal -> rejeitado!
        expect(
          () => motor.executarPassoEstendido(
            teste: teste,
            personagemId: 'lider_1',
            pericia: 'INVESTIGACAO',
            modBase: 6,
            descricaoAcao: 'Analisar pistas na fechadura',
            ajudas: [resultadoAjuda],
            flags: const FlagsTeste(ajudantesPermitidos: true, maxAjudantes: 2),
          ),
          throwsA(
            isA<RegraTesteException>().having(
              (e) => e.codigo,
              'codigo',
              'PERICIA_CONSUMIDA',
            ),
          ),
        );
      },
    );

    test(
      'Caso 9: Estendido - 3 falhas antes da meta -> FALHA_TOTAL; último sucesso exatamente antes da 3ª falha -> SUCESSO',
      () {
        // Parte A: 3 falhas antes de atingir a meta de 2 sucessos -> FALHA_TOTAL
        final motorFalha = MotorTestesService(rng: SequenciaRng([2, 18, 3, 4]));
        var testeA = motorFalha.criarTesteEstendido(
          id: 'est_falha',
          cdBase: 15,
          metas: {'ATLETISMO': 2},
        );

        testeA = motorFalha
            .executarPassoEstendido(
              teste: testeA,
              personagemId: 'h1',
              pericia: 'ATLETISMO',
              modBase: 0, // d20=2 -> falha 1
            )
            .testeAtualizado;
        testeA = motorFalha
            .executarPassoEstendido(
              teste: testeA,
              personagemId: 'h1',
              pericia: 'ATLETISMO',
              modBase: 0, // d20=18 -> sucesso 1
            )
            .testeAtualizado;
        testeA = motorFalha
            .executarPassoEstendido(
              teste: testeA,
              personagemId: 'h1',
              pericia: 'ATLETISMO',
              modBase: 0, // d20=3 -> falha 2
            )
            .testeAtualizado;
        expect(testeA.estado, EstadoTesteEstendido.emAndamento);

        testeA = motorFalha
            .executarPassoEstendido(
              teste: testeA,
              personagemId: 'h1',
              pericia: 'ATLETISMO',
              modBase: 0, // d20=4 -> falha 3 => FALHA_TOTAL
            )
            .testeAtualizado;
        expect(testeA.falhas, 3);
        expect(testeA.estado, EstadoTesteEstendido.falhaTotal);

        // Parte B: 2 falhas acumuladas, e então alcança o último sucesso -> SUCESSO
        final motorSucesso = MotorTestesService(
          rng: SequenciaRng([2, 18, 3, 19]),
        );
        var testeB = motorSucesso.criarTesteEstendido(
          id: 'est_sucesso_limite',
          cdBase: 15,
          metas: {'ATLETISMO': 2},
        );

        testeB = motorSucesso
            .executarPassoEstendido(
              teste: testeB,
              personagemId: 'h1',
              pericia: 'ATLETISMO',
              modBase: 0, // falha 1
            )
            .testeAtualizado;
        testeB = motorSucesso
            .executarPassoEstendido(
              teste: testeB,
              personagemId: 'h1',
              pericia: 'ATLETISMO',
              modBase: 0, // sucesso 1
            )
            .testeAtualizado;
        testeB = motorSucesso
            .executarPassoEstendido(
              teste: testeB,
              personagemId: 'h1',
              pericia: 'ATLETISMO',
              modBase: 0, // falha 2
            )
            .testeAtualizado;
        testeB = motorSucesso
            .executarPassoEstendido(
              teste: testeB,
              personagemId: 'h1',
              pericia: 'ATLETISMO',
              modBase: 0, // sucesso 2 (com 2 falhas) => SUCESSO!
            )
            .testeAtualizado;

        expect(testeB.falhas, 2);
        expect(testeB.progresso['ATLETISMO'], 2);
        expect(testeB.estado, EstadoTesteEstendido.sucesso);
      },
    );

    test(
      'Caso 10: CD cumulativa - no teste 4 a CD = base + 6',
      () {
        final motor = MotorTestesService(rng: SequenciaRng([15, 15, 15, 15]));
        var teste = motor.criarTesteEstendido(
          id: 'est_cumulativo',
          cdBase: 10,
          cumulativa: true,
          metas: {'ATLETISMO': 5},
        );

        // Teste 1 (0 realizados antes) -> CD 10
        final p1 = motor.executarPassoEstendido(
          teste: teste,
          personagemId: 'h1',
          pericia: 'ATLETISMO',
          modBase: 5,
        );
        expect(p1.entradaHistorico.cdAplicada, 10);
        teste = p1.testeAtualizado;

        // Teste 2 (1 realizado antes) -> CD 12
        final p2 = motor.executarPassoEstendido(
          teste: teste,
          personagemId: 'h1',
          pericia: 'ATLETISMO',
          modBase: 5,
        );
        expect(p2.entradaHistorico.cdAplicada, 12);
        teste = p2.testeAtualizado;

        // Teste 3 (2 realizados antes) -> CD 14
        final p3 = motor.executarPassoEstendido(
          teste: teste,
          personagemId: 'h1',
          pericia: 'ATLETISMO',
          modBase: 5,
        );
        expect(p3.entradaHistorico.cdAplicada, 14);
        teste = p3.testeAtualizado;

        // Teste 4 (3 realizados antes) -> CD = base (10) + 6 = 16
        expect(teste.calcularCdAtual(), 16);
        final p4 = motor.executarPassoEstendido(
          teste: teste,
          personagemId: 'h1',
          pericia: 'ATLETISMO',
          modBase: 5,
        );
        expect(p4.entradaHistorico.cdAplicada, 16);
      },
    );

    test(
      'Caso 11: Falta de ferramenta aplica -5 uma única vez',
      () {
        final motor = MotorTestesService(rng: SequenciaRng([15]));
        // Mesmo que o personagem esteja sem ferramenta E o mestre marque semFerramenta no pedido,
        // a penalidade deve ser aplicada uma única vez (-5, nunca -10).
        const req = TesteRequest(
          id: 'teste_ferramenta',
          tipo: TipoTeste.comum,
          cd: 15,
          participantes: ['ladino_1'],
          modo: ModoTeste.pericia,
          flags: FlagsTeste(semFerramenta: true),
        );

        final resultado = motor.executarTeste(
          request: req,
          personagemId: 'ladino_1',
          fonteMod: 'LADINAGEM',
          modBase: 7,
          periciaExigeFerramenta: true,
          personagemSemFerramenta: true,
        );

        expect(resultado.penalFerramenta, -5);
        expect(resultado.total, 15 + 7 - 5); // 17
      },
    );

    test(
      'Caso 12: Cliente desconecta no meio de um estendido -> reconecta e recebe o estado correto',
      () {
        final motor = MotorTestesService(rng: SequenciaRng([12, 16, 4]));
        var teste = motor.criarTesteEstendido(
          id: 'est_reconexao',
          cdBase: 14,
          cumulativa: true,
          metas: {'ATLETISMO': 2, 'FURTIVIDADE': 2},
          modo: ModoTesteEstendido.fechado,
          grupo: true,
          participantesGrupo: ['heroi_1', 'heroi_2'],
          penalFalha: const PenalidadeFalhaEstendido(
            penalidadeNumericaPorFalha: -1,
            textoConsequencia: '1d6 de dano de fadiga',
          ),
        );

        // Ajudante consome PERCEPCAO
        final (testeComAjuda, ajuda) = motor.registrarAjudaEstendido(
          teste: teste,
          ajudanteId: 'heroi_3',
          pericia: 'PERCEPCAO',
          modificador: 2,
        );
        teste = testeComAjuda;

        // Passo 1: heroi_1 passa em ATLETISMO
        teste = motor
            .executarPassoEstendido(
              teste: teste,
              personagemId: 'heroi_1',
              pericia: 'ATLETISMO',
              modBase: 5,
              ajudas: [ajuda],
              flags: const FlagsTeste(
                ajudantesPermitidos: true,
                maxAjudantes: 1,
              ),
            )
            .testeAtualizado;

        // Passo 2: heroi_2 falha em FURTIVIDADE
        teste = motor
            .executarPassoEstendido(
              teste: teste,
              personagemId: 'heroi_2',
              pericia: 'FURTIVIDADE',
              modBase: 2,
            )
            .testeAtualizado;

        // Estado no servidor (Mestre) no momento em que heroi_2 desconecta e reconecta
        final estadoServidor = EstadoSessaoTestes(
          testeEstendidoAtivo: teste,
          logResultados: teste.historico.map((e) => e.resultado).toList(),
        );

        final envelopeSnapshot = estadoServidor.criarEventoSnapshotReconexao(
          eventoId: 'evt_sync_99',
          jogadorId: 'heroi_2',
          timestampIso: '2026-11-07T13:35:00Z',
        );

        // Simula tráfego pela rede LAN (serialização para String JSON e desserialização no cliente)
        final rawJson = envelopeSnapshot.toJsonString();
        final envelopeRecebido = EnvelopeEventoRedeTeste.fromJsonString(rawJson);
        final estadoCliente = EstadoSessaoTestes.fromJson(
          envelopeRecebido.payload,
        );

        final estendidoRestaurado = estadoCliente.testeEstendidoAtivo!;
        expect(estendidoRestaurado.id, 'est_reconexao');
        expect(estendidoRestaurado.progresso['ATLETISMO'], 1);
        expect(estendidoRestaurado.progresso['FURTIVIDADE'], 0);
        expect(estendidoRestaurado.falhas, 1);
        expect(estendidoRestaurado.rodadaAtual, 2);
        expect(estendidoRestaurado.jaAgiramNaRodada, isEmpty);
        expect(estendidoRestaurado.periciasConsumidas, contains('PERCEPCAO'));
        expect(estendidoRestaurado.calcularCdAtual(), 18); // 14 + 2*2
        expect(estendidoRestaurado.penalidadeAcumuladaFalhas, -1);
        expect(estendidoRestaurado.estado, EstadoTesteEstendido.emAndamento);
      },
    );
  });

  group('MotorTestesService - Regras Complementares (R6, R14, R19, R20, Secreto)', () {
    test(
      'R14: Metas múltiplas por perícia não transferem excedente por padrão (configurável)',
      () {
        final motorPadrao = MotorTestesService(
          rng: SequenciaRng([15, 15, 15]),
        );
        var teste = motorPadrao.criarTesteEstendido(
          id: 'est_metas',
          cdBase: 10,
          metas: {'ATLETISMO': 1, 'FURTIVIDADE': 1},
        );

        // 1º sucesso em ATLETISMO -> bate a meta de ATLETISMO (1/1)
        teste = motorPadrao
            .executarPassoEstendido(
              teste: teste,
              personagemId: 'h1',
              pericia: 'ATLETISMO',
              modBase: 5,
            )
            .testeAtualizado;
        expect(teste.progresso['ATLETISMO'], 1);
        expect(teste.progresso['FURTIVIDADE'], 0);

        // 2º sucesso em ATLETISMO -> excedente NÃO conta para FURTIVIDADE por padrão
        teste = motorPadrao
            .executarPassoEstendido(
              teste: teste,
              personagemId: 'h1',
              pericia: 'ATLETISMO',
              modBase: 5,
            )
            .testeAtualizado;
        expect(teste.progresso['ATLETISMO'], 1);
        expect(teste.progresso['FURTIVIDADE'], 0);
        expect(teste.estado, EstadoTesteEstendido.emAndamento);
      },
    );

    test(
      'R19 e R20: Penalidade cumulativa por falha e modos de interrupção/retomada',
      () {
        final motor = MotorTestesService(rng: SequenciaRng([2, 12]));
        var teste = motor.criarTesteEstendido(
          id: 'est_penal_interrupcao',
          cdBase: 15,
          metas: {'ATLETISMO': 2},
          penalFalha: const PenalidadeFalhaEstendido(
            penalidadeNumericaPorFalha: -2,
            textoConsequencia: 'Deslizamento de pedras',
          ),
          interrupcaoConta: TipoInterrupcaoEstendido.umaFalha,
        );

        // Passo 1 falha (d20=2) -> falhas = 1, penalidade acumulada passa a ser -2
        final passo1 = motor.executarPassoEstendido(
          teste: teste,
          personagemId: 'h1',
          pericia: 'ATLETISMO',
          modBase: 5,
        );
        teste = passo1.testeAtualizado;
        expect(teste.falhas, 1);
        expect(teste.penalidadeAcumuladaFalhas, -2);
        expect(passo1.entradaHistorico.consequenciaAplicada, 'Deslizamento de pedras');

        // Passo 2 aplica automaticamente -2 de penalidade (d20=12 + mod 5 - 2 = 15 >= CD 15 -> sucesso)
        final passo2 = motor.executarPassoEstendido(
          teste: teste,
          personagemId: 'h1',
          pericia: 'ATLETISMO',
          modBase: 5,
        );
        expect(passo2.resultadoRolagem.penalidadeFalhaCumulativa, -2);
        expect(passo2.resultadoRolagem.total, 15);
        expect(passo2.resultadoRolagem.sucessoCD, isTrue);
        teste = passo2.testeAtualizado;

        // Mestre interrompe com interrupcaoConta = UMA_FALHA -> falhas vai de 1 para 2 e estado = INTERROMPIDO
        teste = motor.interromperTesteEstendido(teste);
        expect(teste.falhas, 2);
        expect(teste.estado, EstadoTesteEstendido.interrompido);

        // Mestre retoma o teste -> volta para EM_ANDAMENTO
        teste = motor.retomarTesteEstendido(teste);
        expect(teste.estado, EstadoTesteEstendido.emAndamento);
      },
    );

    test(
      'Rolagem secreta oculta números na serialização para jogador e exibe tudo para o mestre',
      () {
        final motor = MotorTestesService(rng: SequenciaRng([17]));
        const reqSecreto = TesteRequest(
          id: 'sec_1',
          tipo: TipoTeste.comum,
          cd: 15,
          participantes: ['heroi_1'],
          modo: ModoTeste.pericia,
          flags: FlagsTeste(secreto: true),
        );

        final resultado = motor.executarTeste(
          request: reqSecreto,
          personagemId: 'heroi_1',
          fonteMod: 'PERCEPCAO',
          modBase: 4,
        );

        final jsonMestre = resultado.toJson(visaoMestre: true);
        final jsonJogador = resultado.toJson(visaoMestre: false);

        expect(jsonMestre['d20'], 17);
        expect(jsonMestre['total'], 21);
        expect(jsonMestre['sucessoCD'], isTrue);

        expect(jsonJogador.containsKey('d20'), isFalse);
        expect(jsonJogador.containsKey('total'), isFalse);
        expect(jsonJogador['ocultoParaJogador'], isTrue);
      },
    );

    test(
      'R6 e R9: Bloqueio de nova tentativa quando semNovaTentativa=true e limite de maxAjudantes',
      () {
        final motor = MotorTestesService(rng: SequenciaRng([5, 15]));
        const reqSemRetentativa = TesteRequest(
          id: 'req_r6_r9',
          tipo: TipoTeste.comum,
          cd: 15,
          participantes: ['heroi_1'],
          modo: ModoTeste.pericia,
          flags: FlagsTeste(
            semNovaTentativa: true,
            ajudantesPermitidos: true,
            maxAjudantes: 1,
          ),
          consequenciaFalha: 'A fechadura emperra definitivamente.',
        );

        // Tentativa após já ter falhado anteriormente -> bloqueada (R6)
        expect(
          () => motor.executarTeste(
            request: reqSemRetentativa,
            personagemId: 'heroi_1',
            fonteMod: 'LADINAGEM',
            modBase: 4,
            jaFalhouAnteriormente: true,
          ),
          throwsA(
            isA<RegraTesteException>().having(
              (e) => e.codigo,
              'codigo',
              'NOVA_TENTATIVA_BLOQUEADA',
            ),
          ),
        );

        // Passar 2 ajudantes quando maxAjudantes = 1 -> bloqueado (R9)
        const a1 = AjudaResult(
          ajudanteId: 'aj1',
          pericia: 'LADINAGEM',
          d20: 10,
          total: 12,
          sucesso: true,
          bonusConcedido: 1,
        );
        const a2 = AjudaResult(
          ajudanteId: 'aj2',
          pericia: 'PERCEPCAO',
          d20: 10,
          total: 12,
          sucesso: true,
          bonusConcedido: 1,
        );
        expect(
          () => motor.executarTeste(
            request: reqSemRetentativa,
            personagemId: 'heroi_1',
            fonteMod: 'LADINAGEM',
            modBase: 4,
            ajudas: const [a1, a2],
          ),
          throwsA(
            isA<RegraTesteException>().having(
              (e) => e.codigo,
              'codigo',
              'MAX_AJUDANTES_EXCEDIDO',
            ),
          ),
        );
      },
    );
  });
}
