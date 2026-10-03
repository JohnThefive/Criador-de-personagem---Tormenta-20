import 'package:flutter_test/flutter_test.dart';
import 'package:t20_creator/domain/entities/arma.dart';
import 'package:t20_creator/domain/entities/protecao.dart';
import 'package:t20_creator/domain/entities/atributos.dart';
import 'package:t20_creator/domain/entities/classe_do_personagem.dart';
import 'package:t20_creator/domain/entities/personagem.dart';
import 'package:t20_creator/domain/services/banco_classes.dart';
import 'package:t20_creator/domain/services/regras_carga_service.dart';
import 'package:t20_creator/presentation/controllers/personagem_cubit.dart';

void main() {
  group('Módulo de Equipamento Inicial e Armas (Nível 1) - Tormenta 20', () {
    // 4 Armas de exemplo especificadas
    final adaga = const Arma(
      key: 'ADAGA',
      nome: 'Adaga',
      descricao: 'Lâmina curta afiada dos dois lados.',
      proficiencia: ProficienciaArma.simples,
      proposito: PropositoArma.arremesso,
      empunhadura: EmpunhaduraArma.leve,
      dano: '1d4',
      margemAmeaca: 19,
      multiplicadorCritico: 2,
      tipoDano: TipoDanoArma.perfuracao,
      espacos: 1,
      precoTibar: 2,
      propriedades: ['agil'],
    );

    final espadaLonga = const Arma(
      key: 'ESPADA_LONGA',
      nome: 'Espada Longa',
      descricao: 'Arma clássica de cavalaria e corte.',
      proficiencia: ProficienciaArma.marcial,
      proposito: PropositoArma.corpoACorpo,
      empunhadura: EmpunhaduraArma.umaMao,
      dano: '1d8',
      margemAmeaca: 19,
      multiplicadorCritico: 2,
      tipoDano: TipoDanoArma.corte,
      espacos: 1,
      precoTibar: 15,
      propriedades: ['adaptavel'],
    );

    final arcoCurto = const Arma(
      key: 'ARCO_CURTO',
      nome: 'Arco Curto',
      descricao: 'Arco de caça leve.',
      proficiencia: ProficienciaArma.simples,
      proposito: PropositoArma.disparo,
      empunhadura: EmpunhaduraArma.duasMaos,
      dano: '1d6',
      margemAmeaca: 20,
      multiplicadorCritico: 3,
      tipoDano: TipoDanoArma.perfuracao,
      espacos: 2,
      precoTibar: 30,
    );

    final machadoDeBatalha = const Arma(
      key: 'MACHADO_DE_BATALHA',
      nome: 'Machado de Batalha',
      descricao: 'Lâmina pesada de ferro.',
      proficiencia: ProficienciaArma.marcial,
      proposito: PropositoArma.corpoACorpo,
      empunhadura: EmpunhaduraArma.umaMao,
      dano: '1d8',
      margemAmeaca: 20,
      multiplicadorCritico: 3,
      tipoDano: TipoDanoArma.corte,
      espacos: 1,
      precoTibar: 10,
    );

    test('1. Atributos da Arma e formatação de crítico', () {
      expect(adaga.criticoFormatado, '19/x2');
      expect(adaga.ehCorpoACorpo, false);
      expect(adaga.ehADistancia, true);
      expect(adaga.somaForcaAoDano, true); // Arremesso soma Força!
      expect(adaga.periciaAtaque, 'PONTARIA');
      expect(adaga.ehAgil, true);

      expect(espadaLonga.criticoFormatado, '19/x2');
      expect(espadaLonga.ehCorpoACorpo, true);
      expect(espadaLonga.somaForcaAoDano, true);
      expect(espadaLonga.periciaAtaque, 'LUTA');
      expect(espadaLonga.ehAdaptavel, true);

      expect(arcoCurto.criticoFormatado, 'x3');
      expect(arcoCurto.ehADistancia, true);
      expect(arcoCurto.somaForcaAoDano, false); // Disparo NÃO soma Força!
      expect(arcoCurto.periciaAtaque, 'PONTARIA');
      expect(arcoCurto.espacos, 2);

      expect(machadoDeBatalha.criticoFormatado, 'x3');
      expect(machadoDeBatalha.ehCorpoACorpo, true);
      expect(machadoDeBatalha.somaForcaAoDano, true);
    });

    test('2. Capacidade de Carga e Sobrecarga baseada na Força', () {
      // Força 0: Limite = 10
      expect(RegrasCargaService.calcularLimiteCarga(0), 10);

      // Força +3: Limite = 10 + 2*3 = 16
      expect(RegrasCargaService.calcularLimiteCarga(3), 16);

      // Força -1: Limite = 10 + 2*(-1) = 8
      expect(RegrasCargaService.calcularLimiteCarga(-1), 8);

      // Força -2: Limite = 10 + 2*(-2) = 6
      expect(RegrasCargaService.calcularLimiteCarga(-2), 6);

      final personagemFraco = Personagem(
        nome: 'Mago Frágil',
        atributos: {
          'FOR': const Atributo(nome: 'Força', valor: -1), // Limite 8
          'DES': const Atributo(nome: 'Destreza', valor: 2),
          'CON': const Atributo(nome: 'Constituição', valor: 0),
          'INT': const Atributo(nome: 'Inteligência', valor: 3),
          'SAB': const Atributo(nome: 'Sabedoria', valor: 0),
          'CAR': const Atributo(nome: 'Carisma', valor: 0),
        },
        armas: [arcoCurto, espadaLonga], // 2 + 1 = 3 espaços
        itensInventario: [
          'Saco de Dormir', // 1 espaço
          'Corda de 15m',   // 1 espaço
          'Tocha',          // 1 espaço
          'Rações (x3)',    // 1 espaço
          'Mochila',        // 0 espaço
          'Traje de Viajante', // 0 espaço
        ],
      );

      // Carga atual = 3 (armas) + 4 (itens) = 7 espaços (abaixo do limite de 8)
      expect(personagemFraco.limiteCarga, 8);
      expect(personagemFraco.cargaAtual, 7);
      expect(personagemFraco.estaSobrecarregado, false);

      // Adicionando mais 2 itens de 1 espaço cada (carga total = 9 > 8)
      final personagemSobrecarregado = personagemFraco.copyWith(
        itensInventario: [
          ...personagemFraco.itensInventario,
          'Grimório Pesado',
          'Barril Pequeno',
        ],
      );

      expect(personagemSobrecarregado.cargaAtual, 9);
      expect(personagemSobrecarregado.estaSobrecarregado, true);
    });

    test('3. Regras de Equipamento Inicial e Armas Disponíveis por Proficiência', () {
      final classeBarbaro = BancoDeClasses.todas.firstWhere(
        (c) => c.idClasse.toUpperCase() == 'BARBARO',
        orElse: () => BancoDeClasses.todas.first,
      );

      final classeArcanista = BancoDeClasses.todas.firstWhere(
        (c) => c.idClasse.toUpperCase() == 'ARCANISTA',
        orElse: () => BancoDeClasses.todas.first,
      );

      final barbaro = Personagem(
        nome: 'Bárbaro Marcial',
        atributos: {
          'FOR': const Atributo(nome: 'Força', valor: 3),
          'DES': const Atributo(nome: 'Destreza', valor: 1),
          'CON': const Atributo(nome: 'Constituição', valor: 2),
          'INT': const Atributo(nome: 'Inteligência', valor: 0),
          'SAB': const Atributo(nome: 'Sabedoria', valor: 0),
          'CAR': const Atributo(nome: 'Carisma', valor: 0),
        },
        classes: [
          ClasseDoPersonagem(classeDefinicao: classeBarbaro, nivel: 1),
        ],
      );

      final arcanista = Personagem(
        nome: 'Arcanista Simples',
        atributos: {
          'FOR': const Atributo(nome: 'Força', valor: 0),
          'DES': const Atributo(nome: 'Destreza', valor: 1),
          'CON': const Atributo(nome: 'Constituição', valor: 0),
          'INT': const Atributo(nome: 'Inteligência', valor: 3),
          'SAB': const Atributo(nome: 'Sabedoria', valor: 0),
          'CAR': const Atributo(nome: 'Carisma', valor: 0),
        },
        classes: [
          ClasseDoPersonagem(classeDefinicao: classeArcanista, nivel: 1),
        ],
      );

      // Bárbaro tem proficiência marcial -> pode escolher Simples E Marcial!
      expect(barbaro.temProficienciaMarcial, true);
      final opcoesBarbaro = RegrasCargaService.obterArmasIniciaisDisponiveis(barbaro);
      expect(opcoesBarbaro.podeEscolherSimples, true);
      expect(opcoesBarbaro.podeEscolherMarcial, true);
      expect(opcoesBarbaro.totalArmasPermitidas, 2);

      // Arcanista NÃO tem proficiência marcial -> pode escolher apenas 1 Simples!
      expect(arcanista.temProficienciaMarcial, false);
      final opcoesArcanista = RegrasCargaService.obterArmasIniciaisDisponiveis(arcanista);
      expect(opcoesArcanista.podeEscolherSimples, true);
      expect(opcoesArcanista.podeEscolherMarcial, false);
      expect(opcoesArcanista.totalArmasPermitidas, 1);
    });

    test('4. Fluxo no Cubit: seleção de armas e consolidação de equipamento inicial', () {
      final cubit = PersonagemCubit();

      // Configura classe Barbaro (marcial)
      final classeBarbaro = BancoDeClasses.todas.firstWhere(
        (c) => c.nome.toLowerCase() == 'bárbaro',
      );
      cubit.selecionarClasse(classeBarbaro);

      expect(cubit.state.personagem.temProficienciaMarcial, true);
      expect(cubit.state.concluiuEquipamentoInicial, false);

      // Escolhe arma simples
      cubit.selecionarArmaSimplesInicial(adaga);
      expect(cubit.state.armaSimplesInicial?.nome, 'Adaga');
      // Ainda falta a marcial para bárbaro
      expect(cubit.state.concluiuEquipamentoInicial, false);

      // Escolhe arma marcial
      cubit.selecionarArmaMarcialInicial(espadaLonga);
      expect(cubit.state.armaMarcialInicial?.nome, 'Espada Longa');
      // Bárbaro ainda precisa escolher armadura inicial
      expect(cubit.state.concluiuEquipamentoInicial, false);

      const armaduraCouro = Protecao(
        key: 'ARMADURA_DE_COURO',
        nome: 'Armadura de Couro',
        descricao: 'Feita de couro fervido em óleo.',
        tipo: TipoProtecao.armaduraLeve,
        bonusDefesa: 2,
        penalidadeArmadura: 0,
        espacos: 1,
        precoEmTibares: 20,
      );
      cubit.selecionarArmaduraInicial(armaduraCouro);
      expect(cubit.state.concluiuEquipamentoInicial, true);

      // Verifica carga em tempo real no State
      // 10 (base) + 0 (modForca) = 10 espacos
      // Adaga (1) + Espada Longa (1) + Armadura de Couro (1) + Saco de dormir (1) + Mochila (0) + Traje (0) = 4 espacos
      expect(cubit.state.statusCarga.cargaAtual, 4);
      expect(cubit.state.statusCarga.limiteCarga, 10);
      expect(cubit.state.statusCarga.sobrecarregado, false);

      // Avança da etapa 6 -> consolida o equipamento
      // Simula estar na etapa 6
      cubit.emitirEstadoParaTeste(cubit.state.copyWith(etapaAtual: 6));
      cubit.avancarEtapa();

      expect(cubit.state.etapaAtual, 7);
      expect(cubit.state.personagem.armas.length, 2);
      expect(cubit.state.personagem.armas.map((a) => a.nome), containsAll(['Adaga', 'Espada Longa']));
      expect(cubit.state.personagem.armaduraEquipada?.nome, 'Armadura de Couro');
      expect(cubit.state.personagem.itensInventario, containsAll(['Mochila', 'Saco de Dormir', 'Traje de Viajante']));
      expect(cubit.state.personagem.tibares, greaterThanOrEqualTo(4));
    });
  });
}
