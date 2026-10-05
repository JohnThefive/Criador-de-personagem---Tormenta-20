import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:t20_creator/domain/entities/atributos.dart';
import 'package:t20_creator/domain/entities/classe.dart';
import 'package:t20_creator/domain/entities/classe_do_personagem.dart';
import 'package:t20_creator/domain/entities/companheiro_animal.dart';
import 'package:t20_creator/domain/entities/forma_selvagem.dart';
import 'package:t20_creator/domain/entities/personagem.dart';
import 'package:t20_creator/domain/entities/poder.dart';
import 'package:t20_creator/domain/entities/combate/combatente.dart';
import 'package:t20_creator/domain/services/data_services/call_classes.dart';
import 'package:t20_creator/domain/services/data_services/call_companheiros.dart';
import 'package:t20_creator/domain/services/data_services/call_formas_selvagens.dart';
import 'package:t20_creator/domain/services/personagem_storage_service.dart';

void main() {
  setUpAll(() async {
    // Carrega dados de teste se em ambiente VM
    final arquivoClasses = File('assets/data/banco_classe.json');
    if (arquivoClasses.existsSync()) {
      final jsonList = jsonDecode(arquivoClasses.readAsStringSync()) as List;
      BancoDeClasses.carregarParaTestes(
        jsonList.map((e) => Classe.fromJson(e)).toList(),
      );
    }

    final arquivoFormas = File('assets/data/formas_selvagens.json');
    if (arquivoFormas.existsSync()) {
      final jsonList = jsonDecode(arquivoFormas.readAsStringSync()) as List;
      BancoDeFormasSelvagens.carregarParaTestes(
        jsonList.map((e) => FormaSelvagem.fromJson(e)).toList(),
      );
    }

    final arquivoCompanheiros = File('assets/data/tipos_companheiro_animal.json');
    if (arquivoCompanheiros.existsSync()) {
      final jsonMap = jsonDecode(arquivoCompanheiros.readAsStringSync()) as Map<String, dynamic>;
      final jsonList = jsonMap['tipos'] as List;
      BancoDeCompanheiros.carregarParaTestes(
        jsonList.map((e) => TipoCompanheiroAnimal.fromJson(e)).toList(),
      );
    }
  });

  Personagem criarDruidaBase({
    int nivel = 2,
    List<Poder>? poderes,
    String? companheiro,
    FormaSelvagemAtiva? formaAtiva,
  }) {
    final classeDruida = BancoDeClasses.getById('druida')!;
    final classePersonagem = ClasseDoPersonagem(
      classeDefinicao: classeDruida,
      nivel: nivel,
      poderesEscolhidos: poderes ?? [],
    );

    final Map<String, Atributo> atributos = {
      'FOR': const Atributo(nome: 'Força', valor: 2),
      'DES': const Atributo(nome: 'Destreza', valor: 1),
      'CON': const Atributo(nome: 'Constituição', valor: 2),
      'INT': const Atributo(nome: 'Inteligência', valor: 0),
      'SAB': const Atributo(nome: 'Sabedoria', valor: 3),
      'CAR': const Atributo(nome: 'Carisma', valor: 0),
    };

    return Personagem(
      nome: 'Allihanna Protegido',
      atributos: atributos,
      classes: [classePersonagem],
      periciasTreinadas: ['Sobrevivência', 'Vontade', 'Percepção'],
      pvAtual: 24,
      pmAtual: 8,
      formaSelvagemAtiva: formaAtiva,
      tipoCompanheiroAnimal: companheiro,
    );
  }

  group('Druida - Regras de Classe e Caminhos', () {
    test('Druida não possui caminhos arcanos/especializações de 1º nível', () {
      final druida = BancoDeClasses.getById('druida');
      expect(druida, isNotNull);
      expect(druida!.caminhosDisponiveis, isEmpty,
          reason: 'Formas Selvagens não devem ser caminhos arcanos de nível 1');
    });

    test('Banco de Formas Selvagens possui as 5 formas oficiais', () {
      final formas = BancoDeFormasSelvagens.todas;
      expect(formas.length, 5);
      final nomes = formas.map((f) => f.nome).toList();
      expect(
        nomes,
        containsAll([
          'Forma Ágil',
          'Forma Feroz',
          'Forma Resistente',
          'Forma Sorrateira',
          'Forma Veloz'
        ]),
      );
    });

    test('Banco de Companheiros Animais possui os tipos oficiais', () {
      final tipos = BancoDeCompanheiros.todos;
      expect(tipos.isNotEmpty, isTrue);
      final nomes = tipos.map((t) => t.nome).toList();
      expect(
        nomes,
        containsAll([
          'Ajudante',
          'Assassino',
          'Atirador',
          'Fortão',
          'Guardião',
          'Montaria',
          'Perseguidor'
        ]),
      );
    });
  });

  group('Druida - Mecânica de Forma Selvagem', () {
    test('Assumir Forma Feroz consome PM e aplica bônus de FOR e Armas Naturais', () {
      const poderForma = Poder(
        key: 'FORMA_SELVAGEM',
        nome: 'Forma Selvagem',
        descricao: 'Transformação em animal.',
        nivelMinimo: 2,
      );

      final druida = criarDruidaBase(nivel: 2, poderes: [poderForma]);
      expect(druida.temPoderFormaSelvagem, isTrue);
      expect(druida.estaEmFormaSelvagem, isFalse);
      expect(druida.getValorFinal('FOR'), 2);

      final formaFeroz = BancoDeFormasSelvagens.getPorNome('Feroz');
      expect(formaFeroz, isNotNull);

      // Assumir Forma Feroz (nível 2 = tier padrão, custo 3 PM, FOR +6)
      final transformado = druida.assumirFormaSelvagem(formaFeroz!);
      expect(transformado.estaEmFormaSelvagem, isTrue);
      expect(transformado.pmAtual, 5, reason: '8 PM máximo - 3 PM = 5 PM');
      expect(transformado.getValorFinal('FOR'), 8, reason: '2 base + 6 da Forma Feroz = 8');

      // Verifica armas naturais
      expect(transformado.armasEfetivas.length, 1);
      final armaNatural = transformado.armasEfetivas.first;
      expect(armaNatural.dano, '1d8');

      // Combatente gerado tem arma natural equipada
      final combatente = Combatente.doPersonagem(transformado);
      expect(combatente.armas.any((a) => a.dano == '1d8'), isTrue);
    });

    test('Assumir Forma Resistente aumenta Defesa e concede RD', () {
      final druida = criarDruidaBase(nivel: 2);
      final formaResistente = BancoDeFormasSelvagens.getPorNome('Resistente')!;

      final defesaInicial = druida.defesaFinal;
      final transformado = druida.assumirFormaSelvagem(formaResistente);

      // Forma Resistente padrão: Defesa +5, RD 5
      expect(transformado.defesaFinal, defesaInicial + 5);
      expect(transformado.rdTotal, 5);
    });

    test('Forma Selvagem escala de nível (Padrão 2-5, Aprimorada 6-11, Superior 12+)', () {
      final formaFeroz = BancoDeFormasSelvagens.getPorNome('Feroz')!;

      // Nível 2 = Padrão (3 PM)
      final d2 = criarDruidaBase(nivel: 2).assumirFormaSelvagem(formaFeroz);
      expect(d2.formaSelvagemAtiva?.custoPm, 3);
      expect(d2.formaSelvagemAtiva?.tier, 'padrao');

      // Nível 6 = Aprimorada (6 PM)
      final d6 = criarDruidaBase(nivel: 6).assumirFormaSelvagem(formaFeroz);
      expect(d6.formaSelvagemAtiva?.custoPm, 6);
      expect(d6.formaSelvagemAtiva?.tier, 'aprimorada');

      // Nível 12 = Superior (10 PM)
      final d12 = criarDruidaBase(nivel: 12).assumirFormaSelvagem(formaFeroz);
      expect(d12.formaSelvagemAtiva?.custoPm, 10);
      expect(d12.formaSelvagemAtiva?.tier, 'superior');
    });

    test('Forma Selvagem é desfeita imediatamente ao cair inconsciente (PV <= 0) ou morrer', () {
      final formaFeroz = BancoDeFormasSelvagens.getPorNome('Feroz')!;
      final transformado = criarDruidaBase(nivel: 2).assumirFormaSelvagem(formaFeroz);

      expect(transformado.estaEmFormaSelvagem, isTrue);
      expect(transformado.getValorFinal('FOR'), 8);

      // Dano parcial (mantém forma)
      final ferido = transformado.aplicarDano(10);
      expect(ferido.pvAtual, 14);
      expect(ferido.estaEmFormaSelvagem, isTrue);

      // Dano fatal / inconsciente (PV vai a 0 ou menos)
      final inconsciente = ferido.aplicarDano(15); // 14 - 15 = -1 PV
      expect(inconsciente.pvAtual, -1);
      expect(inconsciente.estaEmFormaSelvagem, isFalse,
          reason: 'A Forma Selvagem deve ser desfeita ao atingir PV <= 0');
      expect(inconsciente.formaSelvagemAtiva, isNull);
      expect(inconsciente.getValorFinal('FOR'), 2,
          reason: 'Modificadores da forma voltam ao normal');
    });

    test('Reverter forma manualmente restaura atributos mantendo PV', () {
      final formaFeroz = BancoDeFormasSelvagens.getPorNome('Feroz')!;
      final transformado = criarDruidaBase(nivel: 2).assumirFormaSelvagem(formaFeroz);

      final revertido = transformado.reverterFormaSelvagem();
      expect(revertido.estaEmFormaSelvagem, isFalse);
      expect(revertido.getValorFinal('FOR'), 2);
      expect(revertido.pvAtual, transformado.pvAtual);
    });
  });

  group('Druida - Mecânica de Companheiro Animal', () {
    test('Companheiro Guardião concede +1 na Defesa no estágio iniciante', () {
      const poderComp = Poder(
        key: 'COMPANHEIRO_ANIMAL',
        nome: 'Companheiro Animal',
        descricao: 'Você possui um companheiro animal.',
        nivelMinimo: 2,
      );

      final druida = criarDruidaBase(
        nivel: 2,
        poderes: [poderComp],
        companheiro: 'GUARDIAO',
      );

      expect(druida.temPoderCompanheiroAnimal, isTrue);
      expect(druida.tipoCompanheiroAnimal, 'GUARDIAO');
      // Defesa base: 10 + DES(1) = 11. Com Guardião iniciante (+1): 12.
      expect(druida.defesaFinal, 12);
    });

    test('Companheiro Guardião escala para Veterano no nível 6 (+2 Defesa)', () {
      const poderComp = Poder(
        key: 'COMPANHEIRO_ANIMAL',
        nome: 'Companheiro Animal',
        descricao: 'Você possui um companheiro animal.',
        nivelMinimo: 2,
      );

      final druidaNivel6 = criarDruidaBase(
        nivel: 6,
        poderes: [poderComp],
        companheiro: 'GUARDIAO',
      );
      // Nível 6: Defesa base = 10 + DES(1) = 11. Com Guardião veterano (+2): 13.
      expect(druidaNivel6.defesaFinal, 13);
    });
  });

  group('Druida - Persistência JSON de Forma Selvagem e Companheiro', () {
    test('Salva e restaura personagem com Forma Selvagem e Companheiro Animal', () {
      final formaVeloz = BancoDeFormasSelvagens.getPorNome('Veloz')!;

      final druidaOriginal = criarDruidaBase(
        nivel: 3,
        companheiro: 'GUARDIAO',
      ).assumirFormaSelvagem(formaVeloz);

      final json = PersonagemStorageService.personagemToJson(druidaOriginal);
      final restaurado = PersonagemStorageService.personagemFromJson(json);

      expect(restaurado.estaEmFormaSelvagem, isTrue);
      expect(restaurado.formaSelvagemAtiva?.nome, 'Forma Veloz');
      expect(restaurado.tipoCompanheiroAnimal, 'GUARDIAO');
      expect(restaurado.defesaFinal, druidaOriginal.defesaFinal);
      expect(restaurado.getValorFinal('DES'), druidaOriginal.getValorFinal('DES'));
    });
  });
}
