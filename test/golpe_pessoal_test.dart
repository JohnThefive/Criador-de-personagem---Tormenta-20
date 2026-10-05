import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:t20_creator/domain/entities/classe.dart';
import 'package:t20_creator/domain/entities/golpe_pessoal.dart';
import 'package:t20_creator/domain/entities/personagem.dart';
import 'package:t20_creator/domain/entities/poder.dart';
import 'package:t20_creator/domain/services/data_services/call_efeitos_golpe_pessoal.dart';
import 'package:t20_creator/domain/services/data_services/call_classes.dart';
import 'package:t20_creator/domain/services/personagem_storage_service.dart';

void main() {
  setUpAll(() {
    // Carrega dados de teste se em ambiente VM
    final arquivoEfeitos = File('assets/data/efeitos_golpe_pessoal.json');
    if (arquivoEfeitos.existsSync()) {
      final jsonList = jsonDecode(arquivoEfeitos.readAsStringSync()) as List;
      BancoDeEfeitosGolpePessoal.carregarParaTestes(
        jsonList.map((e) => EfeitoGolpePessoal.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      );
    }

    final arquivoClasses = File('assets/data/banco_classe.json');
    if (arquivoClasses.existsSync()) {
      final jsonList = jsonDecode(arquivoClasses.readAsStringSync()) as List;
      BancoDeClasses.carregarParaTestes(
        jsonList.map((e) => Classe.fromJson(e)).toList(),
      );
    }
  });

  group('BancoDeEfeitosGolpePessoal', () {
    test('deve carregar todos os efeitos do arquivo json', () {
      final efeitos = BancoDeEfeitosGolpePessoal.todos;
      expect(efeitos.isNotEmpty, isTrue);
      expect(efeitos.length, equals(17));
    });

    test('deve localizar efeitos por chave independente de case', () {
      final amplo = BancoDeEfeitosGolpePessoal.getByKey('amplo');
      expect(amplo, isNotNull);
      expect(amplo!.nome, equals('Amplo'));
      expect(amplo.modificadorPm, equals(3));
      expect(amplo.cumulativo, isFalse);

      final letal = BancoDeEfeitosGolpePessoal.getByKey('LETAL');
      expect(letal, isNotNull);
      expect(letal!.limiteEscolhas, equals(2));
    });

    test('deve filtrar vantagens e desvantagens corretamente', () {
      final vantagens = BancoDeEfeitosGolpePessoal.vantagens;
      final desvantagens = BancoDeEfeitosGolpePessoal.desvantagens;

      expect(vantagens.isNotEmpty, isTrue);
      expect(desvantagens.isNotEmpty, isTrue);
      expect(vantagens.every((e) => e.ehVantagem), isTrue);
      expect(desvantagens.every((e) => e.ehDesvantagem), isTrue);
      expect(vantagens.length + desvantagens.length, equals(BancoDeEfeitosGolpePessoal.todos.length));
    });
  });

  group('Poder e RegrasCustomizacaoPoder', () {
    test('deve mapear referenciaTabela e regrasCustomizacao do JSON de Golpe Pessoal', () {
      final jsonPoder = {
        "key": "GOLPE_PESSOAL",
        "nome": "Golpe Pessoal",
        "tipo": "classe",
        "descricao": "Você cria uma técnica especial.",
        "referenciaTabela": "efeitos_golpe_pessoal",
        "regrasCustomizacao": {
          "custoPmMínimo": 1,
          "custoPmMaximo": "nivel_do_personagem",
          "permiteMultiplasInstancias": true
        }
      };

      final poder = Poder.fromJson(jsonPoder);
      expect(poder.referenciaTabela, equals('efeitos_golpe_pessoal'));
      expect(poder.regrasCustomizacao, isNotNull);
      expect(poder.regrasCustomizacao!.custoPmMinimo, equals(1));
      expect(poder.regrasCustomizacao!.custoPmMaximo, equals('nivel_do_personagem'));
      expect(poder.regrasCustomizacao!.permiteMultiplasInstancias, isTrue);
    });
  });

  group('ValidadorGolpePessoal', () {
    test('deve rejeitar golpe sem nome', () {
      final res = ValidadorGolpePessoal.validar(
        nome: '',
        efeitosKeys: ['AMPLO'],
        nivelGuerreiro: 5,
      );
      expect(res.valido, isFalse);
      expect(res.erros.any((e) => e.contains('nome')), isTrue);
    });

    test('deve rejeitar golpe sem efeitos', () {
      final res = ValidadorGolpePessoal.validar(
        nome: 'Golpe Fantasma',
        efeitosKeys: [],
        nivelGuerreiro: 5,
      );
      expect(res.valido, isFalse);
      expect(res.erros.any((e) => e.contains('pelo menos um efeito')), isTrue);
    });

    test('deve aprovar golpe válido com custo >= 1 e <= nível do guerreiro', () {
      // AMPLO (+3 PM) em guerreiro nível 3 -> Custo 3 PM <= 3 PM -> Válido
      final res = ValidadorGolpePessoal.validar(
        nome: 'Corte Amplo',
        efeitosKeys: ['AMPLO'],
        nivelGuerreiro: 3,
      );
      expect(res.valido, isTrue);
      expect(res.custoCalculado, equals(3));
      expect(res.erros, isEmpty);
    });

    test('deve rejeitar golpe com custo excedendo o nível de guerreiro', () {
      // AMPLO (+3 PM) + IMPACTANTE (+1 PM) = 4 PM > nível 2 -> Inválido
      final res = ValidadorGolpePessoal.validar(
        nome: 'Impacto Devastador',
        efeitosKeys: ['AMPLO', 'IMPACTANTE'],
        nivelGuerreiro: 2,
      );
      expect(res.valido, isFalse);
      expect(res.custoCalculado, equals(4));
      expect(res.erros.any((e) => e.contains('não pode exceder seu nível de guerreiro')), isTrue);
    });

    test('deve rejeitar golpe com custo total < 1 PM (ex: desvantagem reduzindo demais)', () {
      // IMPACTANTE (+1 PM) + LENTO (-2 PM) = -1 PM < 1 PM -> Inválido
      final res = ValidadorGolpePessoal.validar(
        nome: 'Golpe Desajeitado',
        efeitosKeys: ['IMPACTANTE', 'LENTO'],
        nivelGuerreiro: 5,
      );
      expect(res.valido, isFalse);
      expect(res.custoCalculado, equals(-1));
      expect(res.erros.any((e) => e.contains('custo mínimo de um Golpe Pessoal é 1 PM')), isTrue);
    });

    test('deve rejeitar efeito não cumulativo repetido', () {
      // AMPLO não é cumulativo
      final res = ValidadorGolpePessoal.validar(
        nome: 'Super Amplo',
        efeitosKeys: ['AMPLO', 'AMPLO'],
        nivelGuerreiro: 5,
      );
      expect(res.valido, isFalse);
      expect(res.erros.any((e) => e.contains('não pode ser escolhido mais de uma vez')), isTrue);
    });

    test('deve respeitar limite de escolhas em efeito cumulativo (ex: LETAL limite 2)', () {
      // LETAL x2 em guerreiro nível 5 -> Válido (custo 4 PM)
      final resValido = ValidadorGolpePessoal.validar(
        nome: 'Golpe Fatal',
        efeitosKeys: ['LETAL', 'LETAL'],
        nivelGuerreiro: 5,
      );
      expect(resValido.valido, isTrue);
      expect(resValido.custoCalculado, equals(4));

      // LETAL x3 -> Rejeitado (limite é 2)
      final resInvalido = ValidadorGolpePessoal.validar(
        nome: 'Golpe Hiper Fatal',
        efeitosKeys: ['LETAL', 'LETAL', 'LETAL'],
        nivelGuerreiro: 10,
      );
      expect(resInvalido.valido, isFalse);
      expect(resInvalido.erros.any((e) => e.contains('permite no máximo 2 escolhas')), isTrue);
    });

    test('deve exigir arma de arremesso para RICOCHETEANTE a menos que QUALQUER_ARMA seja usado', () {
      // RICOCHETEANTE sem arremesso e sem qualquer arma -> Rejeitado
      final resSemArremesso = ValidadorGolpePessoal.validar(
        nome: 'Ricochete Espada',
        efeitosKeys: ['RICOCHETEANTE'],
        nivelGuerreiro: 5,
        armaEhArremesso: false,
      );
      expect(resSemArremesso.valido, isFalse);
      expect(resSemArremesso.erros.any((e) => e.contains('exige uma arma de arremesso')), isTrue);

      // Com arma de arremesso -> Válido
      final resComArremesso = ValidadorGolpePessoal.validar(
        nome: 'Ricochete Adaga',
        efeitosKeys: ['RICOCHETEANTE'],
        nivelGuerreiro: 5,
        armaEhArremesso: true,
      );
      expect(resComArremesso.valido, isTrue);

      // Com QUALQUER_ARMA mesmo sem arma de arremesso -> Válido
      final resComQualquerArma = ValidadorGolpePessoal.validar(
        nome: 'Ricochete Místico',
        efeitosKeys: ['RICOCHETEANTE', 'QUALQUER_ARMA'],
        nivelGuerreiro: 5,
        armaEhArremesso: false,
      );
      expect(resComQualquerArma.valido, isTrue);
    });
  });

  group('Persistência e Integração de GolpePessoal em Personagem', () {
    test('deve serializar e desserializar GolpePessoal isoladamente', () {
      const golpe = GolpePessoal(
        id: 'gp_001',
        nome: 'Trovão Flamejante',
        armaKey: 'espada_longa',
        armaNome: 'Espada Longa',
        efeitosKeys: ['ELEMENTAL', 'DEVASTADOR'],
        opcoesEfeitos: {'ELEMENTAL': 'fogo'},
        custoPmTotal: 3,
      );

      final map = golpe.toJson();
      final restaurado = GolpePessoal.fromJson(map);

      expect(restaurado.id, equals(golpe.id));
      expect(restaurado.nome, equals(golpe.nome));
      expect(restaurado.armaKey, equals(golpe.armaKey));
      expect(restaurado.armaNome, equals(golpe.armaNome));
      expect(restaurado.efeitosKeys, equals(golpe.efeitosKeys));
      expect(restaurado.opcoesEfeitos['ELEMENTAL'], equals('fogo'));
      expect(restaurado.custoPmTotal, equals(3));
    });

    test('deve salvar e carregar Personagem com lista de Golpes Pessoais via PersonagemStorageService', () {
      final personagemOriginal = Personagem.inicial().copyWith(
        nome: 'Sir Loras',
        golpesPessoais: [
          const GolpePessoal(
            id: 'gp_01',
            nome: 'Impacto Trovejante',
            armaKey: 'machado_batalha',
            armaNome: 'Machado de Batalha',
            efeitosKeys: ['IMPACTANTE', 'ATORDOANTE'],
            custoPmTotal: 3,
          ),
          const GolpePessoal(
            id: 'gp_02',
            nome: 'Estocada Precisa',
            armaKey: 'florete',
            armaNome: 'Florete',
            efeitosKeys: ['PRECISO', 'LETAL'],
            custoPmTotal: 3,
          ),
        ],
      );

      final jsonString = PersonagemStorageService.personagemToJson(personagemOriginal);
      final personagemCarregado = PersonagemStorageService.personagemFromJson(jsonString);

      expect(personagemCarregado.nome, equals('Sir Loras'));
      expect(personagemCarregado.golpesPessoais.length, equals(2));

      final g1 = personagemCarregado.golpesPessoais[0];
      expect(g1.id, equals('gp_01'));
      expect(g1.nome, equals('Impacto Trovejante'));
      expect(g1.efeitosKeys, equals(['IMPACTANTE', 'ATORDOANTE']));
      expect(g1.custoPmTotal, equals(3));

      final g2 = personagemCarregado.golpesPessoais[1];
      expect(g2.id, equals('gp_02'));
      expect(g2.nome, equals('Estocada Precisa'));
      expect(g2.efeitosKeys, equals(['PRECISO', 'LETAL']));
      expect(g2.custoPmTotal, equals(3));
    });
  });
}
