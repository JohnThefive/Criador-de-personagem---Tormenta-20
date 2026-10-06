import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:t20_creator/domain/entities/atributos.dart';
import 'package:t20_creator/domain/entities/classe.dart';
import 'package:t20_creator/domain/entities/classe_do_personagem.dart';
import 'package:t20_creator/domain/entities/engenhoca.dart';
import 'package:t20_creator/domain/entities/personagem.dart';
import 'package:t20_creator/domain/entities/poder.dart';
import 'package:t20_creator/domain/services/banco_pericias.dart';
import 'package:t20_creator/domain/services/data_services/call_classes.dart';
import 'package:t20_creator/domain/services/data_services/call_regras_engenhocas.dart';
import 'package:t20_creator/domain/services/personagem_storage_service.dart';
import 'package:t20_creator/domain/services/poder_validador_service.dart';
import 'package:t20_creator/domain/services/regras_carga_service.dart';

void main() {
  setUpAll(() {
    final arquivoClasses = File('assets/data/classes_data/banco_classe.json');
    if (arquivoClasses.existsSync()) {
      final jsonList = jsonDecode(arquivoClasses.readAsStringSync()) as List;
      BancoDeClasses.carregarParaTestes(
        jsonList.map((e) => Classe.fromJson(e)).toList(),
      );
    }

    final arquivoRegras = File('assets/data/classes_data/especifico_classe/inventor/regras_engenhocas.json');
    if (arquivoRegras.existsSync()) {
      final jsonMap = jsonDecode(arquivoRegras.readAsStringSync()) as Map<String, dynamic>;
      BancoDeRegrasEngenhocas.carregarParaTestes(jsonMap);
    }
  });

  group('Engenhoca - Payload e Serialização', () {
    test('deve desserializar e serializar exatamente o payload solicitado pelo usuário', () {
      final rawPayload = [
        {
          "id": "engenhoca_01",
          "nomeCustomizado": "Canhão Portátil a Vapor",
          "magiaSimuladaKey": "BOLA_DE_FOGO",
          "circulo": 2,
          "custoPmBase": 3,
          "modoUso": "empunhada",
          "cdAtivacaoBase": 18,
          "usosHoje": 0,
          "enguicado": false,
          "espacosOcupados": 1
        },
        {
          "id": "engenhoca_02",
          "nomeCustomizado": "Gabinete de Choque Cardíaco",
          "magiaSimuladaKey": "CURAR_FERIMENTOS",
          "circulo": 1,
          "custoPmBase": 1,
          "modoUso": "vestida",
          "cdAtivacaoBase": 16,
          "usosHoje": 1,
          "enguicado": false,
          "espacosOcupados": 1
        }
      ];

      final engenhocas = rawPayload.map((map) => Engenhoca.fromJson(map)).toList();

      expect(engenhocas.length, equals(2));

      final e1 = engenhocas[0];
      expect(e1.id, equals('engenhoca_01'));
      expect(e1.nomeCustomizado, equals('Canhão Portátil a Vapor'));
      expect(e1.magiaSimuladaKey, equals('BOLA_DE_FOGO'));
      expect(e1.circulo, equals(2));
      expect(e1.custoPmBase, equals(3));
      expect(e1.modoUso, equals('empunhada'));
      expect(e1.cdAtivacaoBase, equals(18));
      expect(e1.usosHoje, equals(0));
      expect(e1.enguicado, isFalse);
      expect(e1.espacosOcupados, equals(1));
      expect(e1.cdAtivacaoAtual, equals(18)); // 18 + 0*5
      expect(e1.podeSerUsada, isTrue);

      final e2 = engenhocas[1];
      expect(e2.id, equals('engenhoca_02'));
      expect(e2.nomeCustomizado, equals('Gabinete de Choque Cardíaco'));
      expect(e2.magiaSimuladaKey, equals('CURAR_FERIMENTOS'));
      expect(e2.circulo, equals(1));
      expect(e2.custoPmBase, equals(1));
      expect(e2.modoUso, equals('vestida'));
      expect(e2.cdAtivacaoBase, equals(16));
      expect(e2.usosHoje, equals(1));
      expect(e2.enguicado, isFalse);
      expect(e2.espacosOcupados, equals(1));
      expect(e2.cdAtivacaoAtual, equals(21)); // 16 + 1*5 = 21

      // Reserialização idêntica
      final serialized = engenhocas.map((e) => e.toJson()).toList();
      expect(serialized, equals(rawPayload));
    });
  });

  group('Regras de Engenhocas e Progressão de Inventor', () {
    test('deve calcular círculos máximos com base no nível de inventor', () {
      expect(BancoDeRegrasEngenhocas.circuloMaximoParaNivel(1), equals(1));
      expect(BancoDeRegrasEngenhocas.circuloMaximoParaNivel(5), equals(1));
      expect(BancoDeRegrasEngenhocas.circuloMaximoParaNivel(6), equals(2));
      expect(BancoDeRegrasEngenhocas.circuloMaximoParaNivel(9), equals(2));
      expect(BancoDeRegrasEngenhocas.circuloMaximoParaNivel(10), equals(3));
      expect(BancoDeRegrasEngenhocas.circuloMaximoParaNivel(13), equals(3));
      expect(BancoDeRegrasEngenhocas.circuloMaximoParaNivel(14), equals(4));
      expect(BancoDeRegrasEngenhocas.circuloMaximoParaNivel(17), equals(4));
      expect(BancoDeRegrasEngenhocas.circuloMaximoParaNivel(18), equals(5));
      expect(BancoDeRegrasEngenhocas.circuloMaximoParaNivel(20), equals(5));
    });

    test('deve calcular custos e CDs de fabricação e ativação base', () {
      // 1º Círculo: 1 PM
      expect(BancoDeRegrasEngenhocas.custoPmBaseParaCirculo(1), equals(1));
      expect(BancoDeRegrasEngenhocas.calcularCdAtivacaoBase(1), equals(16)); // 15 + 1
      expect(BancoDeRegrasEngenhocas.calcularCdFabricacao(1), equals(21)); // 20 + 1
      expect(BancoDeRegrasEngenhocas.calcularCustoFabricacaoTibares(1), equals(100)); // 100 * 1

      // 2º Círculo: 3 PM
      expect(BancoDeRegrasEngenhocas.custoPmBaseParaCirculo(2), equals(3));
      expect(BancoDeRegrasEngenhocas.calcularCdAtivacaoBase(3), equals(18)); // 15 + 3
      expect(BancoDeRegrasEngenhocas.calcularCdFabricacao(3), equals(23)); // 20 + 3
      expect(BancoDeRegrasEngenhocas.calcularCustoFabricacaoTibares(3), equals(300)); // 100 * 3
    });

    test('deve calcular limite de engenhocas e bônus de Manutenção Eficiente', () {
      // INT 3, sem poder -> limite 3
      expect(BancoDeRegrasEngenhocas.calcularLimiteEngenhocas(inteligencia: 3), equals(3));

      // INT 4 com Manutenção Eficiente -> limite 7 (4 + 3)
      expect(
        BancoDeRegrasEngenhocas.calcularLimiteEngenhocas(
          inteligencia: 4,
          temManutencaoEficiente: true,
        ),
        equals(7),
      );

      // Espaço: 1 normal, 0.5 com Manutenção Eficiente
      expect(BancoDeRegrasEngenhocas.espacoOcupadoPorEngenhoca(), equals(1.0));
      expect(BancoDeRegrasEngenhocas.espacoOcupadoPorEngenhoca(temManutencaoEficiente: true), equals(0.5));
    });
  });

  group('ValidadorEngenhoca', () {
    test('deve validar criação de engenhoca com sucesso', () {
      final resultado = ValidadorEngenhoca.validar(
        nomeCustomizado: 'Pistola de Dardos Sônicos',
        magiaSimuladaKey: 'AMEDRONTAR',
        circulo: 1,
        modoUso: 'empunhada',
        nivelInventor: 2,
        quantidadeEngenhocasExistentes: 1,
        limiteEngenhocas: 3,
      );

      expect(resultado.valido, isTrue);
      expect(resultado.erros, isEmpty);
      expect(resultado.custoPmCalculado, equals(1));
      expect(resultado.cdAtivacaoBaseCalculada, equals(16));
    });

    test('deve rejeitar engenhoca de círculo superior ao nível do inventor', () {
      // Nível 3 só pode 1º círculo; tentando 2º círculo
      final resultado = ValidadorEngenhoca.validar(
        nomeCustomizado: 'Raio Congelante',
        magiaSimuladaKey: 'BOLA_DE_FOGO',
        circulo: 2,
        modoUso: 'empunhada',
        nivelInventor: 3,
      );

      expect(resultado.valido, isFalse);
      expect(resultado.erros.any((e) => e.contains('pode criar engenhocas de até 1º círculo')), isTrue);
    });

    test('deve rejeitar criação quando atinge o limite máximo de engenhocas', () {
      final resultado = ValidadorEngenhoca.validar(
        nomeCustomizado: 'Escudo Cinético',
        magiaSimuladaKey: 'ARMADURA_ARCANA',
        circulo: 1,
        modoUso: 'vestida',
        nivelInventor: 2,
        quantidadeEngenhocasExistentes: 3,
        limiteEngenhocas: 3,
      );

      expect(resultado.valido, isFalse);
      expect(resultado.erros.any((e) => e.contains('Limite de engenhocas atingido')), isTrue);
    });
  });

  group('Integração de Engenhocas na Ficha do Personagem', () {
    Personagem criarInventor({
      int nivel = 3,
      int inteligencia = 4,
      List<Poder>? poderes,
      List<Engenhoca>? engenhocas,
    }) {
      final classeInventor = BancoDeClasses.getById('inventor')!;
      final classePersonagem = ClasseDoPersonagem(
        classeDefinicao: classeInventor,
        nivel: nivel,
        poderesEscolhidos: poderes ?? [],
      );

      return Personagem(
        nome: 'Dok, o Artífice',
        atributos: {
          'FOR': const Atributo(nome: 'Força', valor: 0),
          'DES': const Atributo(nome: 'Destreza', valor: 2),
          'CON': const Atributo(nome: 'Constituição', valor: 1),
          'INT': Atributo(nome: 'Inteligência', valor: inteligencia),
          'SAB': const Atributo(nome: 'Sabedoria', valor: 1),
          'CAR': const Atributo(nome: 'Carisma', valor: 0),
        },
        classes: [classePersonagem],
        engenhocas: engenhocas ?? const [],
      );
    }

    test('deve identificar nível e poderes de inventor na ficha', () {
      const poderEngenhoqueiro = Poder(
        key: 'ENGENHOQUEIRO',
        nome: 'Engenhoqueiro',
        descricao: 'Fabrica engenhocas.',
      );
      const poderManutencao = Poder(
        key: 'MANUTENCAO_EFICIENTE',
        nome: 'Manutenção Eficiente',
        descricao: '+3 no limite e 0.5 de espaço.',
      );

      final p = criarInventor(
        nivel: 5,
        inteligencia: 4,
        poderes: [poderEngenhoqueiro, poderManutencao],
      );

      expect(p.nivelInventor, equals(5));
      expect(p.temPoderEngenhoqueiro, isTrue);
      expect(p.temPoderManutencaoEficiente, isTrue);
      expect(p.limiteEngenhocas, equals(7)); // 4 base + 3 de Manutenção Eficiente
    });

    test('deve manipular ciclo de vida de engenhoca (ativação, enguiço, conserto e descanso)', () {
      const e = Engenhoca(
        id: 'eng_01',
        nomeCustomizado: 'Raiador Elétrico',
        magiaSimuladaKey: 'TOQUE_CHOCANTE',
        circulo: 1,
        custoPmBase: 1,
        modoUso: 'empunhada',
        cdAtivacaoBase: 16,
      );

      var p = criarInventor(engenhocas: [e]);
      expect(p.engenhocas.length, equals(1));
      expect(p.engenhocas.first.usosHoje, equals(0));
      expect(p.engenhocas.first.cdAtivacaoAtual, equals(16));

      // Ativar engenhoca primeira vez (+5 na CD)
      p = p.ativarEngenhoca('eng_01');
      expect(p.engenhocas.first.usosHoje, equals(1));
      expect(p.engenhocas.first.cdAtivacaoAtual, equals(21));

      // Ativar engenhoca segunda vez
      p = p.ativarEngenhoca('eng_01');
      expect(p.engenhocas.first.usosHoje, equals(2));
      expect(p.engenhocas.first.cdAtivacaoAtual, equals(26));

      // Enguiçar
      p = p.enguicarEngenhoca('eng_01');
      expect(p.engenhocas.first.enguicado, isTrue);
      expect(p.engenhocas.first.podeSerUsada, isFalse);

      // Consertar
      p = p.consertarEngenhoca('eng_01');
      expect(p.engenhocas.first.enguicado, isFalse);
      expect(p.engenhocas.first.podeSerUsada, isTrue);

      // Descanso diário zera usosHoje
      p = p.descansarEngenhocas();
      expect(p.engenhocas.first.usosHoje, equals(0));
      expect(p.engenhocas.first.cdAtivacaoAtual, equals(16));
    });

    test('deve contabilizar espaços de engenhocas no cálculo de carga do inventário', () {
      const e1 = Engenhoca(
        id: 'eng_01',
        nomeCustomizado: 'Item A',
        magiaSimuladaKey: 'M1',
        circulo: 1,
        custoPmBase: 1,
        modoUso: 'empunhada',
        cdAtivacaoBase: 16,
        espacosOcupados: 1,
      );
      const e2 = Engenhoca(
        id: 'eng_02',
        nomeCustomizado: 'Item B',
        magiaSimuladaKey: 'M2',
        circulo: 1,
        custoPmBase: 1,
        modoUso: 'vestida',
        cdAtivacaoBase: 16,
        espacosOcupados: 1,
      );

      final p = criarInventor(engenhocas: [e1, e2]);
      expect(p.espacosTotaisEngenhocas, equals(2));

      final statusCarga = RegrasCargaService.avaliarCarga(p);
      // Limite = 10 + 2*FOR(0) = 10; Carga = 2 (duas engenhocas de 1 espaço)
      expect(statusCarga.cargaAtual, equals(2));
      expect(statusCarga.limiteCarga, equals(10));
      expect(statusCarga.sobrecarregado, isFalse);
    });

    test('deve salvar e recarregar personagem com engenhocas no PersonagemStorageService', () {
      final pOriginal = criarInventor(
        engenhocas: [
          const Engenhoca(
            id: 'engenhoca_01',
            nomeCustomizado: 'Canhão Portátil a Vapor',
            magiaSimuladaKey: 'BOLA_DE_FOGO',
            circulo: 2,
            custoPmBase: 3,
            modoUso: 'empunhada',
            cdAtivacaoBase: 18,
            usosHoje: 0,
            enguicado: false,
            espacosOcupados: 1,
          ),
          const Engenhoca(
            id: 'engenhoca_02',
            nomeCustomizado: 'Gabinete de Choque Cardíaco',
            magiaSimuladaKey: 'CURAR_FERIMENTOS',
            circulo: 1,
            custoPmBase: 1,
            modoUso: 'vestida',
            cdAtivacaoBase: 16,
            usosHoje: 1,
            enguicado: false,
            espacosOcupados: 1,
          ),
        ],
      );

      final jsonStr = PersonagemStorageService.personagemToJson(pOriginal);
      final pCarregado = PersonagemStorageService.personagemFromJson(jsonStr);

      expect(pCarregado.engenhocas.length, equals(2));

      final e1 = pCarregado.engenhocas[0];
      expect(e1.id, equals('engenhoca_01'));
      expect(e1.nomeCustomizado, equals('Canhão Portátil a Vapor'));
      expect(e1.magiaSimuladaKey, equals('BOLA_DE_FOGO'));
      expect(e1.circulo, equals(2));
      expect(e1.custoPmBase, equals(3));
      expect(e1.modoUso, equals('empunhada'));
      expect(e1.cdAtivacaoBase, equals(18));
      expect(e1.usosHoje, equals(0));
      expect(e1.enguicado, isFalse);
      expect(e1.espacosOcupados, equals(1));

      final e2 = pCarregado.engenhocas[1];
      expect(e2.id, equals('engenhoca_02'));
      expect(e2.nomeCustomizado, equals('Gabinete de Choque Cardíaco'));
      expect(e2.magiaSimuladaKey, equals('CURAR_FERIMENTOS'));
      expect(e2.circulo, equals(1));
      expect(e2.custoPmBase, equals(1));
      expect(e2.modoUso, equals('vestida'));
      expect(e2.cdAtivacaoBase, equals(16));
      expect(e2.usosHoje, equals(1));
      expect(e2.enguicado, isFalse);
      expect(e2.espacosOcupados, equals(1));
    });
  });

  group('Ofícios e Elegibilidade de Poder Engenhoqueiro', () {
    test('deve catalogar os ofícios específicos em BancoDePericias', () {
      final pEngenhoqueiro = BancoDePericias.getByKey('OFICIO_ENGENHOQUEIRO');
      expect(pEngenhoqueiro.key, equals('OFICIO_ENGENHOQUEIRO'));
      expect(pEngenhoqueiro.label, equals('Ofício (Engenhoqueiro)'));

      final pAlquimista = BancoDePericias.getByKey('OFICIO_ALQUIMISTA');
      expect(pAlquimista.label, equals('Ofício (Alquimista)'));

      final pArmeiro = BancoDePericias.getByKey('OFICIO_ARMEIRO');
      expect(pArmeiro.label, equals('Ofício (Armeiro)'));

      final pCozinheiro = BancoDePericias.getByKey('OFICIO_COZINHEIRO');
      expect(pCozinheiro.label, equals('Ofício (Culinária)'));

      final pArtesanato = BancoDePericias.getByKey('OFICIO_ARTESANATO');
      expect(pArtesanato.label, contains('Artesanato'));
    });

    test('deve validar elegibilidade para o poder ENGENHOQUEIRO', () {
      final classeInventor = BancoDeClasses.getById('inventor')!;
      final classePersonagem = ClasseDoPersonagem(
        classeDefinicao: classeInventor,
        nivel: 2,
      );

      const poderEngenhoqueiro = Poder(
        key: 'ENGENHOQUEIRO',
        nome: 'Engenhoqueiro',
        descricao: 'Fabrica engenhocas.',
        periciasExigidas: ['OFICIO_ENGENHOQUEIRO'],
        atributosExigidos: {'INT': 3},
      );

      // Personagem com INT 3 e OFICIO_ENGENHOQUEIRO treinado -> Elegível!
      final personagemElegivel = Personagem(
        nome: 'Dok',
        atributos: {
          'FOR': const Atributo(nome: 'Força', valor: 0),
          'DES': const Atributo(nome: 'Destreza', valor: 0),
          'CON': const Atributo(nome: 'Constituição', valor: 0),
          'INT': const Atributo(nome: 'Inteligência', valor: 3),
          'SAB': const Atributo(nome: 'Sabedoria', valor: 0),
          'CAR': const Atributo(nome: 'Carisma', valor: 0),
        },
        classes: [classePersonagem],
        periciasTreinadas: ['OFICIO_ENGENHOQUEIRO', 'VONTADE'],
      );

      final resultadoElegivel = PoderValidadorService.validar(
        poder: poderEngenhoqueiro,
        personagem: personagemElegivel,
        classeDoPersonagem: classePersonagem,
      );
      expect(resultadoElegivel.ehElegivel, isTrue);

      // Personagem SEM OFICIO_ENGENHOQUEIRO -> Inelegível!
      final personagemSemOficio = personagemElegivel.copyWith(
        periciasTreinadas: ['VONTADE'],
      );
      final resultadoSemOficio = PoderValidadorService.validar(
        poder: poderEngenhoqueiro,
        personagem: personagemSemOficio,
        classeDoPersonagem: classePersonagem,
      );
      expect(resultadoSemOficio.ehElegivel, isFalse);
      expect(
        resultadoSemOficio.requisitos.any((r) => r.descricao.contains('Engenhoqueiro') && !r.atendido),
        isTrue,
      );
    });
  });
}
