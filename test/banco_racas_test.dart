import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttericon/rpg_awesome_icons.dart';
import 'package:t20_creator/helpers/icone_rpg_helper.dart';
import 'package:t20_creator/domain/entities/raca.dart';
import 'package:t20_creator/domain/services/data_services/call_racas.dart';

void main() {
  group('Entidade Raca, IconeRpgHelper e BancoDeRacas', () {
    test('IconeRpgHelper mapeia chaves conhecidas e faz fallback seguro', () {
      expect(IconeRpgHelper.obterIcone('axe'), equals(RpgAwesome.axe));
      expect(IconeRpgHelper.obterIcone('clover'), equals(RpgAwesome.clover));
      expect(
        IconeRpgHelper.obterIcone('feathered_wing'),
        equals(RpgAwesome.feathered_wing),
      );
      expect(IconeRpgHelper.obterIcone('player'), equals(RpgAwesome.player));

      // Fallback
      expect(
        IconeRpgHelper.obterIcone('chave_inexistente'),
        equals(RpgAwesome.player),
      );
      expect(IconeRpgHelper.obterIcone(null), equals(RpgAwesome.player));
    });

    test('Raca deve serializar e desserializar corretamente via JSON', () {
      final jsonExemplo = {
        'id': 'anao',
        'nome': 'Anão',
        'descricaoRaca': 'Anões são robustos.',
        'icone': 'axe',
        'modificadores': {'CON': 2, 'SAB': 1, 'DES': -1},
        'habilidadesRaca': {'Duro na Queda': '+3 PV'},
        'ehFlexivel': false,
        'atributosBloqueados': <String>[],
      };

      final raca = Raca.fromJson(jsonExemplo);
      expect(raca.id, equals('anao'));
      expect(raca.nome, equals('Anão'));
      expect(raca.icone, equals('axe'));
      expect(raca.iconeRaca, equals(RpgAwesome.axe));
      expect(raca.modificadores['CON'], equals(2));
      expect(raca.habilidadesRaca['Duro na Queda'], equals('+3 PV'));
      expect(raca.ehFlexivel, isFalse);

      final mapGerado = raca.toJson();
      expect(mapGerado['id'], equals('anao'));
      expect(mapGerado['icone'], equals('axe'));
    });

    test('BancoDeRacas busca por id e por nome', () {
      final racaHumano = const Raca(
        id: 'humano',
        nome: 'Humano',
        descricaoRaca: 'Adaptáveis.',
        icone: 'player',
        modificadores: {},
        ehFlexivel: true,
      );

      final racaAnao = const Raca(
        id: 'anao',
        nome: 'Anão',
        descricaoRaca: 'Robustos.',
        icone: 'axe',
        modificadores: {'CON': 2},
      );

      BancoDeRacas.carregarParaTestes([racaHumano, racaAnao]);

      expect(BancoDeRacas.todas.length, equals(2));
      expect(BancoDeRacas.getById('humano')?.nome, equals('Humano'));
      expect(BancoDeRacas.getById('ANAO')?.nome, equals('Anão'));
      expect(BancoDeRacas.getByNome('Anão')?.id, equals('anao'));
      expect(BancoDeRacas.getById('inexistente'), isNull);
    });

    test(
      'Arquivo assets/data/banco_racas.json é válido e contém as 18 raças',
      () {
        final file = File('assets/data/banco_racas.json');
        expect(
          file.existsSync(),
          isTrue,
          reason: 'O arquivo banco_racas.json deve existir',
        );

        final content = file.readAsStringSync();
        final List<dynamic> jsonList = jsonDecode(content);

        expect(jsonList.length, equals(18));

        final racas = jsonList
            .map((e) => Raca.fromJson(e as Map<String, dynamic>))
            .toList();
        expect(racas.length, equals(18));

        for (final raca in racas) {
          expect(raca.id, isNotEmpty);
          expect(raca.nome, isNotEmpty);
          expect(raca.descricaoRaca, isNotEmpty);
          expect(raca.icone, isNotEmpty);
          expect(raca.iconeRaca, isNotNull);
        }

        final ids = racas.map((r) => r.id).toSet();
        expect(
          ids.length,
          equals(18),
          reason: 'Todos os IDs de raças devem ser únicos',
        );
      },
    );
  });
}
