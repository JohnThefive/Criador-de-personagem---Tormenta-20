import 'package:flutter_test/flutter_test.dart';
import 'package:t20_creator/domain/entities/personagem/poder.dart';
import 'package:t20_creator/domain/services/data_services/call_armaduras.dart';
import 'package:t20_creator/domain/services/data_services/call_armas.dart';
import 'package:t20_creator/domain/services/data_services/call_classes.dart';
import 'package:t20_creator/domain/services/data_services/call_companheiros.dart';
import 'package:t20_creator/domain/services/data_services/call_divindades.dart';
import 'package:t20_creator/domain/services/data_services/call_efeitos_golpe_pessoal.dart';
import 'package:t20_creator/domain/services/data_services/call_formas_selvagens.dart';
import 'package:t20_creator/domain/services/data_services/call_magias.dart';
import 'package:t20_creator/domain/services/data_services/call_origens.dart';
import 'package:t20_creator/domain/services/data_services/call_pericias.dart';
import 'package:t20_creator/domain/services/data_services/call_poderes.dart';
import 'package:t20_creator/domain/services/data_services/call_racas.dart';

void main() {
  group('Indexação O(1) de Bancos de Dados Estáticos', () {
    test('BancoDePoderes indexa e recupera poderes em O(1)', () {
      final mockPoder = const Poder(
        key: 'ATAQUE_PODEROSO',
        nome: 'Ataque Poderoso',
        descricao: 'Dano extra em combate corpo a corpo',
      );

      BancoDePoderes.carregarParaTestes({
        'GUERREIRO': [mockPoder],
      });

      expect(BancoDePoderes.getByKey('ATAQUE_PODEROSO'), isNotNull);
      expect(BancoDePoderes.getByKey('ataque_poderoso'), isNotNull);
      expect(BancoDePoderes.getByKey('ATAQUE_PODEROSO')?.nome, equals('Ataque Poderoso'));
      expect(BancoDePoderes.getByKey('PODER_INEXISTENTE'), isNull);
    });

    test('BancoDePericias indexa e recupera pericias em O(1)', () {
      final pericia = BancoDePericias.getByKey('LUTA');
      expect(pericia.key, equals('LUTA'));
      expect(pericia.label, equals('Luta'));

      final periciaMin = BancoDePericias.getByKey('luta');
      expect(periciaMin.key, equals('LUTA'));

      final desconhecida = BancoDePericias.getByKey('PERICIA_FALSA');
      expect(desconhecida.key, equals('UNKNOWN'));
    });

    test('BancoDeMagias indexa e recupera magias em O(1)', () {
      final magia = BancoDeMagias.getById('curar_ferimentos');
      expect(magia.id, equals('curar_ferimentos'));
      expect(magia.nome, equals('Curar Ferimentos'));

      final desconhecida = BancoDeMagias.getById('magia_fantasma_xyz');
      expect(desconhecida.id, equals('UNKNOWN'));
    });

    test('BancoDeArmas indexa e recupera armas em O(1)', () {
      final arma = BancoDeArmas.getByKey('ESPADA_LONGA');
      expect(arma, isNotNull);
      expect(arma!.nome, equals('Espada Longa'));

      expect(BancoDeArmas.getByKey('espada_longa'), isNotNull);
      expect(BancoDeArmas.getByKey('ARMA_NAO_EXISTE'), isNull);
    });

    test('BancoDeArmaduras indexa e recupera protecoes em O(1)', () {
      final armadura = BancoDeArmaduras.getByKey('ARMADURA_COURO');
      expect(armadura, isNotNull);
      expect(armadura!.nome, equals('Armadura de Couro'));

      expect(BancoDeArmaduras.getByKey('armadura_couro'), isNotNull);
      expect(BancoDeArmaduras.getByKey('PROTECAO_INEXISTENTE'), isNull);
    });

    test('BancoDeClasses indexa e recupera classes por id e nome em O(1)', () {
      final classe = BancoDeClasses.getById('guerreiro');
      expect(classe, isNotNull);
      expect(classe!.nome, equals('Guerreiro'));

      final porNome = BancoDeClasses.getByNome('Guerreiro');
      expect(porNome, isNotNull);
      expect(porNome!.idClasse, equals('guerreiro'));
    });

    test('BancoDeRacas indexa e recupera racas por id e nome em O(1)', () {
      final raca = BancoDeRacas.getById('humano');
      expect(raca, isNotNull);
      expect(raca!.nome, equals('Humano'));

      final porNome = BancoDeRacas.getByNome('Humano');
      expect(porNome, isNotNull);
      expect(porNome!.id, equals('humano'));
    });

    test('BancoDeOrigens indexa e recupera origens por id e nome em O(1)', () {
      final origem = BancoDeOrigens.getById('acolito');
      expect(origem, isNotNull);
      expect(origem!.nome, equals('Acólito'));

      final porNome = BancoDeOrigens.getByNome('Acólito');
      expect(porNome, isNotNull);
      expect(porNome!.id, equals('acolito'));
    });

    test('BancoDeDivindades indexa e recupera divindades por id e nome em O(1)', () {
      final divindade = BancoDeDivindades.getById('valkaria');
      expect(divindade, isNotNull);
      expect(divindade!.nome, equals('Valkaria'));

      final porNome = BancoDeDivindades.getByNome('Valkaria');
      expect(porNome, isNotNull);
      expect(porNome!.id, equals('valkaria'));
    });

    test('BancoDeFormasSelvagens indexa e recupera formas em O(1)', () {
      final todas = BancoDeFormasSelvagens.todas;
      expect(todas, isNotEmpty);

      final primeira = todas.first;
      final forma = BancoDeFormasSelvagens.getByKey(primeira.key);
      expect(forma, isNotNull);
      expect(forma!.key, equals(primeira.key));

      final porNome = BancoDeFormasSelvagens.getPorNome(primeira.nome);
      expect(porNome, isNotNull);
      expect(porNome!.nome, equals(primeira.nome));
    });

    test('BancoDeCompanheiros indexa e recupera companheiros em O(1)', () {
      final comp = BancoDeCompanheiros.getByKey('GUARDIAO');
      expect(comp, isNotNull);
      expect(comp!.nome, equals('Guardião'));
    });

    test('BancoDeEfeitosGolpePessoal indexa e recupera efeitos em O(1)', () {
      final efeito = BancoDeEfeitosGolpePessoal.getByKey('AMPLO');
      expect(efeito, isNotNull);
      expect(efeito!.nome, equals('Amplo'));
    });
  });
}
