import 'package:flutter_test/flutter_test.dart';
import 'package:t20_creator/domain/entities/atributos.dart';
import 'package:t20_creator/domain/entities/classe.dart';
import 'package:t20_creator/domain/entities/classe_do_personagem.dart';
import 'package:t20_creator/domain/entities/personagem.dart';
import 'package:t20_creator/domain/entities/proficiencias.dart';
import 'package:t20_creator/domain/entities/protecao.dart';
import 'package:t20_creator/domain/entities/arma.dart';
import 'package:t20_creator/domain/services/data_services/call_armaduras.dart';
import 'package:t20_creator/domain/services/data_services/call_classes.dart';

import 'package:t20_creator/domain/services/regras_carga_service.dart';
import 'package:t20_creator/presentation/controllers/personagem_cubit.dart';

void main() {
  group('Módulo de Equipamento Inicial: Armaduras, Escudos e Defesa (Nível 1)', () {
    const guerreiroDef = Classe(
      idClasse: 'guerreiro',
      nome: 'Guerreiro',
      descricaoclasse: 'Especialista em combate e armaduras.',
      caminhoImagem: '',
      pvInicial: 20,
      pvPorNivel: 5,
      pmInicial: 3,
      pmPorNivel: 3,
      proficiencias: [
        TipoProficiencia.armasSimples,
        TipoProficiencia.armasMarciais,
        TipoProficiencia.armadurasPesadas,
        TipoProficiencia.armadurasLeves,
        TipoProficiencia.escudos,
      ],
      periciasFixas: ['FORTITUDE', 'LUTA'],
      qtdPericiasEscolha: 2,
      periciasOpcoes: ['ATLETISMO', 'INICIATIVA'],
      caminhosDisponiveis: [],
      tabelaDeProgressao: {},
      habilidadesFixas: {},
    );

    const ladinoDef = Classe(
      idClasse: 'ladino',
      nome: 'Ladino',
      descricaoclasse: 'Especialista em perícias e furtividade.',
      caminhoImagem: '',
      pvInicial: 12,
      pvPorNivel: 3,
      pmInicial: 4,
      pmPorNivel: 4,
      proficiencias: [
        TipoProficiencia.armasSimples,
        TipoProficiencia.armadurasLeves,
      ],
      periciasFixas: ['LADINAGEM', 'REFLEXOS'],
      qtdPericiasEscolha: 4,
      periciasOpcoes: ['ACROBACIA', 'ATLETISMO', 'ENGANACAO', 'FURTIVIDADE'],
      caminhosDisponiveis: [],
      tabelaDeProgressao: {},
      habilidadesFixas: {},
    );

    final arcanistaDef = BancoDeClasses.todas.firstWhere(
      (c) => c.idClasse == 'arcanista',
    );
    // Definições de proteções para os testes
    const armaduraCouro = Protecao(
      key: 'ARMADURA_COURO',
      nome: 'Armadura de Couro',
      descricao: 'Armadura de couro fervido.',
      tipo: TipoProtecao.armaduraLeve,
      bonusDefesa: 2,
      penalidadeArmadura: 0,
      espacos: 2,
      precoEmTibares: 20,
    );

    const couroBatido = Protecao(
      key: 'COURO_BATIDO',
      nome: 'Couro Batido',
      descricao: 'Couro reforçado com rebites.',
      tipo: TipoProtecao.armaduraLeve,
      bonusDefesa: 3,
      penalidadeArmadura: 1,
      espacos: 2,
      precoEmTibares: 35,
    );

    const gibaoDePeles = Protecao(
      key: 'GIBAO_DE_PELES',
      nome: 'Gibão de Peles',
      descricao: 'Casaco espesso de peles.',
      tipo: TipoProtecao.armaduraLeve,
      bonusDefesa: 4,
      penalidadeArmadura: 3,
      espacos: 2,
      precoEmTibares: 25,
    );

    const brunea = Protecao(
      key: 'BRUNEA',
      nome: 'Brunea',
      descricao: 'Camisa de couro coberta por placas de metal.',
      tipo: TipoProtecao.armaduraPesada,
      bonusDefesa: 5,
      penalidadeArmadura: 2,
      espacos: 5,
      precoEmTibares: 50,
    );

    const escudoLeve = Protecao(
      key: 'ESCUDO_LEVE',
      nome: 'Escudo Leve',
      descricao: 'Escudo de madeira leve.',
      tipo: TipoProtecao.escudoLeve,
      bonusDefesa: 1,
      penalidadeArmadura: 1,
      espacos: 1,
      precoEmTibares: 5,
      danoAtaque: '1d4',
      criticoAtaque: 'x2',
      multiplicadorCriticoAtaque: 2,
    );

    const escudoPesado = Protecao(
      key: 'ESCUDO_PESADO',
      nome: 'Escudo Pesado',
      descricao: 'Escudo grande de ferro ou aço.',
      tipo: TipoProtecao.escudoPesado,
      bonusDefesa: 2,
      penalidadeArmadura: 2,
      espacos: 2,
      precoEmTibares: 15,
      danoAtaque: '1d6',
      criticoAtaque: 'x2',
      multiplicadorCriticoAtaque: 2,
    );

    setUpAll(() {
      BancoDeArmaduras.carregarParaTestes([
        armaduraCouro,
        couroBatido,
        gibaoDePeles,
        brunea,
        escudoLeve,
        escudoPesado,
      ]);
    });

    test('1. Propriedades e Regras da Entidade Protecao', () {
      // Armadura Leve
      expect(armaduraCouro.ehArmaduraLeve, true);
      expect(armaduraCouro.ehArmaduraPesada, false);
      expect(armaduraCouro.ehEscudo, false);
      expect(armaduraCouro.permiteDestrezaNaDefesa, true);
      expect(armaduraCouro.reduzDeslocamento, false);
      expect(armaduraCouro.tempoVestir, 'Ação completa');

      // Armadura Pesada
      expect(brunea.ehArmaduraPesada, true);
      expect(brunea.ehArmaduraLeve, false);
      expect(brunea.permiteDestrezaNaDefesa, false);
      expect(brunea.reduzDeslocamento, true);
      expect(brunea.tempoVestir, '5 minutos');

      // Escudo Leve & Pesado
      expect(escudoLeve.ehEscudo, true);
      expect(escudoLeve.ehEscudoLeve, true);
      expect(escudoLeve.danoAtaque, '1d4');
      expect(escudoLeve.criticoAtaque, 'x2');
      expect(escudoLeve.multiplicadorCriticoAtaque, 2);

      expect(escudoPesado.ehEscudoPesado, true);
      expect(escudoPesado.danoAtaque, '1d6');
    });

    test(
      '2. Cálculo Reativo da Defesa Final (Leve vs Pesada, Escudo e Destreza)',
      () {
        // Personagem com DES = 3 (mod +3)
        final atributosDes3 = {
          'FOR': const Atributo(nome: 'Força', valor: 0),
          'DES': const Atributo(nome: 'Destreza', valor: 3),
          'CON': const Atributo(nome: 'Constituição', valor: 0),
          'INT': const Atributo(nome: 'Inteligência', valor: 0),
          'SAB': const Atributo(nome: 'Sabedoria', valor: 0),
          'CAR': const Atributo(nome: 'Carisma', valor: 0),
        };

        final pSemArmadura = Personagem.inicial().copyWith(
          atributos: atributosDes3,
        );
        // Sem armadura: 10 + DES (+3) = 13
        expect(pSemArmadura.defesaFinal, 13);

        // Com Armadura Leve (+2): 10 + DES (+3) + 2 = 15
        final pArmaduraLeve = pSemArmadura.copyWith(
          armaduraEquipada: armaduraCouro,
        );
        expect(pArmaduraLeve.defesaFinal, 15);

        // Com Armadura Leve (+2) + Escudo Leve (+1): 10 + 3 + 2 + 1 = 16
        final pLeveMaisEscudo = pArmaduraLeve.copyWith(
          escudoEquipado: escudoLeve,
        );
        expect(pLeveMaisEscudo.defesaFinal, 16);

        // Com Armadura Pesada (Brunea +5): Destreza NÃO é somada! 10 + 5 = 15
        final pArmaduraPesada = pSemArmadura.copyWith(armaduraEquipada: brunea);
        expect(pArmaduraPesada.defesaFinal, 15);

        // Com Armadura Pesada (+5) + Escudo Pesado (+2): 10 + 5 + 2 = 17 (sem DES)
        final pPesadaMaisEscudo = pArmaduraPesada.copyWith(
          escudoEquipado: escudoPesado,
        );
        expect(pPesadaMaisEscudo.defesaFinal, 17);
      },
    );

    test('3. Penalidade de Armadura Acumulada, Sobrecarga e Perícias', () {
      // Guerreiro tem proficiência com pesadas e escudos

      // Guerreiro tem proficiência com pesadas e escudos
      final pGuerreiro = Personagem.inicial().copyWith(
        classe_do_personagem: [
          ClasseDoPersonagem(classeDefinicao: guerreiroDef, nivel: 1),
        ],
        armaduraEquipada: brunea, // penalidade 2
        escudoEquipado: escudoPesado, // penalidade 2
      );

      // Penalidade total = 2 (brunea) + 2 (escudo) = 4
      expect(pGuerreiro.penalidadeArmaduraTotal, 4);
      expect(pGuerreiro.usaProtecaoSemProficiencia, false);

      // Em Acrobacia (perícia que sofre penalidade de armadura):
      // DES 0 + metade do nível 0 - penalidade 4 = -4
      expect(pGuerreiro.getValorPericia('ACROBACIA'), -4);

      // Ladino só tem proficiência em armaduras leves e não tem escudo
      final pLadinoInfrator = Personagem.inicial().copyWith(
        classe_do_personagem: [
          ClasseDoPersonagem(classeDefinicao: ladinoDef, nivel: 1),
        ],
        armaduraEquipada: brunea, // PESADA: Sem proficiência!
        escudoEquipado: escudoPesado, // ESCUDO: Sem proficiência!
      );

      expect(pLadinoInfrator.usaProtecaoSemProficiencia, true);
      // Como não tem proficiência, a penalidade se estende a TODAS as perícias de FOR e DES
      // Por exemplo, Atletismo (FOR) ou Luta (FOR) sofrem a penalidade de 4
      expect(pLadinoInfrator.getValorPericia('LUTA'), -4);

      // Penalidade com Sobrecarga (+2 na penalidade)
      // Força 0 -> Limite 10 espaços.
      // Brunea (5) + Escudo Pesado (2) = 7 espaços. Adicionamos 4 itens de 1 espaço = 11 > 10.
      final pSobrecarregado = pGuerreiro.copyWith(
        itensInventario: ['Item 1', 'Item 2', 'Item 3', 'Item 4'],
      );

      expect(pSobrecarregado.cargaAtual, 11);
      expect(pSobrecarregado.estaSobrecarregado, true);
      // Penalidade base (4) + sobrecarga (2) = 6
      expect(pSobrecarregado.penalidadeArmaduraTotal, 6);
      expect(pSobrecarregado.getValorPericia('ACROBACIA'), -6);
    });

    test('4. Elegibilidade de Equipamento Inicial de 1º Nível (Regras T20)', () {
      final pGuerreiro = Personagem.inicial().copyWith(
        classe_do_personagem: [
          ClasseDoPersonagem(classeDefinicao: guerreiroDef, nivel: 1),
        ],
      );
      final pArcanista = Personagem.inicial().copyWith(
        classe_do_personagem: [
          ClasseDoPersonagem(classeDefinicao: arcanistaDef, nivel: 1),
        ],
      );
      final pLadino = Personagem.inicial().copyWith(
        classe_do_personagem: [
          ClasseDoPersonagem(classeDefinicao: ladinoDef, nivel: 1),
        ],
      );

      // Guerreiro: tem pesadas -> pode Brunea; tem escudos -> ganha Escudo Leve
      final opcoesGuerreiro =
          RegrasCargaService.obterProtecoesIniciaisDisponiveis(pGuerreiro);
      expect(opcoesGuerreiro.podeEscolherArmadura, true);
      expect(opcoesGuerreiro.podeEscolherEscudo, true);
      expect(
        opcoesGuerreiro.armadurasIniciais.map((a) => a.key),
        containsAll([
          'ARMADURA_COURO',
          'COURO_BATIDO',
          'GIBAO_DE_PELES',
          'BRUNEA',
        ]),
      );
      expect(
        opcoesGuerreiro.escudosIniciais.map((e) => e.key),
        contains('ESCUDO_LEVE'),
      );

      // Ladino: leves apenas, sem brunea e sem escudo leve
      final opcoesLadino = RegrasCargaService.obterProtecoesIniciaisDisponiveis(
        pLadino,
      );
      expect(opcoesLadino.podeEscolherArmadura, true);
      expect(opcoesLadino.podeEscolherEscudo, false);
      expect(
        opcoesLadino.armadurasIniciais.map((a) => a.key),
        containsAll(['ARMADURA_COURO', 'COURO_BATIDO', 'GIBAO_DE_PELES']),
      );
      expect(
        opcoesLadino.armadurasIniciais.any((a) => a.key == 'BRUNEA'),
        false,
      );
      expect(opcoesLadino.escudosIniciais, isEmpty);

      // Arcanista: Exceção T20 - começa sem armadura
      final opcoesArcanista =
          RegrasCargaService.obterProtecoesIniciaisDisponiveis(pArcanista);
      expect(opcoesArcanista.podeEscolherArmadura, false);
      expect(opcoesArcanista.podeEscolherEscudo, false);
      expect(opcoesArcanista.armadurasIniciais, isEmpty);
      expect(opcoesArcanista.escudosIniciais, isEmpty);
    });

    test('5. Fluxo no Cubit: seleção de armadura, escudo e consolidação', () {
      final cubit = PersonagemCubit();

      cubit.selecionarClasse(guerreiroDef);

      // Armas de teste
      final adaga = const Arma(
        key: 'ADAGA',
        nome: 'Adaga',
        descricao: '',
        proficiencia: ProficienciaArma.simples,
        proposito: PropositoArma.arremesso,
        empunhadura: EmpunhaduraArma.leve,
        dano: '1d4',
        margemAmeaca: 19,
        multiplicadorCritico: 2,
        tipoDano: TipoDanoArma.perfuracao,
        espacos: 1,
        precoTibar: 2,
      );

      final espadaLonga = const Arma(
        key: 'ESPADA_LONGA',
        nome: 'Espada Longa',
        descricao: '',
        proficiencia: ProficienciaArma.marcial,
        proposito: PropositoArma.corpoACorpo,
        empunhadura: EmpunhaduraArma.umaMao,
        dano: '1d8',
        margemAmeaca: 19,
        multiplicadorCritico: 2,
        tipoDano: TipoDanoArma.corte,
        espacos: 1,
        precoTibar: 15,
      );

      cubit.selecionarArmaSimplesInicial(adaga);
      cubit.selecionarArmaMarcialInicial(espadaLonga);

      // Ainda falta armadura
      expect(cubit.state.concluiuEquipamentoInicial, false);

      // Seleciona Brunea e Escudo Leve
      cubit.selecionarArmaduraInicial(brunea);
      expect(cubit.state.concluiuEquipamentoInicial, true);

      cubit.selecionarEscudoInicial(escudoLeve);
      expect(cubit.state.escudoInicial?.nome, 'Escudo Leve');

      // Verifica cálculo da carga em tempo real no State:
      // Adaga (1) + Espada Longa (1) + Brunea (5) + Escudo Leve (1) + Saco de Dormir (1) = 9 espaços
      expect(cubit.state.statusCarga.cargaAtual, 9);
      expect(cubit.state.statusCarga.limiteCarga, 10);
      expect(cubit.state.statusCarga.sobrecarregado, false);

      // Consolidação do equipamento
      cubit.consolidarEquipamentoInicial();

      final pConsolidado = cubit.state.personagem;
      expect(pConsolidado.armas.length, 2);
      expect(pConsolidado.armaduraEquipada?.nome, 'Brunea');
      expect(pConsolidado.escudoEquipado?.nome, 'Escudo Leve');
      // Defesa calculada após consolidação: 10 + 5 (Brunea) + 1 (Escudo) = 16
      expect(pConsolidado.defesaFinal, 16);
      expect(
        pConsolidado.penalidadeArmaduraTotal,
        3,
      ); // 2 da brunea + 1 do escudo
    });
  });
}
