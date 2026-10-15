import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttericon/rpg_awesome_icons.dart';
import 'package:t20_creator/helpers/icone_rpg_helper.dart';
import 'package:t20_creator/domain/entities/personagem/raca.dart';
import 'package:t20_creator/domain/services/data_services/call_racas.dart';
import 'package:t20_creator/domain/entities/personagem/personagem.dart';
import 'package:t20_creator/domain/entities/personagem/classe.dart';
import 'package:t20_creator/domain/entities/personagem/classe_do_personagem.dart';
import 'package:t20_creator/domain/entities/personagem/atributos.dart';

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

    test('Arquivo assets/data/banco_racas.json é válido e contém as 18 raças', () {
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

        final svgFile = File('assets/icons/${raca.icone}.svg');
        expect(
          svgFile.existsSync(),
          isTrue,
          reason:
              'O arquivo SVG para ${raca.nome} (${svgFile.path}) deve existir',
        );
      }

      final ids = racas.map((r) => r.id).toSet();
      expect(
        ids.length,
        equals(18),
        reason: 'Todos os IDs de raças devem ser únicos',
      );

      // Valida que o diretório possui exatamente 18 SVGs únicos, sem duplicatas ou maiúsculas
      final dirRacas = Directory('assets/icons/racas');
      expect(dirRacas.existsSync(), isTrue);
      final svgFiles = dirRacas
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.svg'))
          .toList();
      expect(
        svgFiles.length,
        equals(18),
        reason:
            'Deve haver exatamente 18 arquivos SVG em assets/icons/racas (1 para cada raça)',
      );

      for (final file in svgFiles) {
        final fileName = file.uri.pathSegments.last;
        expect(
          fileName,
          equals(fileName.toLowerCase()),
          reason: 'O arquivo $fileName deve estar em minúsculas (padronizado)',
        );
      }
    });

    test('Bônus Raciais de PV e PM para Anão e Elfo', () {
      final guerreiroClasse = Classe(
        idClasse: 'guerreiro',
        nome: 'Guerreiro',
        pvInicial: 20,
        pvPorNivel: 5,
        pmInicial: 3,
        pmPorNivel: 3,
        descricaoclasse: '',
        proficiencias: const [],
        periciasFixas: const [],
        periciasOpcoes: const [],
        qtdPericiasEscolha: 2,
        caminhoImagem: '',
      );

      final anaoRaca = const Raca(
        id: 'anao',
        nome: 'Anão',
        descricaoRaca: 'Duro como Pedra',
        icone: 'axe',
        modificadores: {'CON': 2},
      );

      final elfoRaca = const Raca(
        id: 'elfo',
        nome: 'Elfo',
        descricaoRaca: 'Sangue Mágico',
        icone: 'clover',
        modificadores: {'INT': 2},
      );

      // Anão Nível 1:
      // CON: Base 2 + Raça 2 = 4.
      // Guerreiro pvInicial = 20 + CON (4) = 24.
      // Anão: +3 PV no 1º nível -> Total 27.
      final pAnaoNivel1 = Personagem(
        nome: 'Thorin',
        atributos: {
          'FOR': const Atributo(nome: 'Força', valor: 0),
          'DES': const Atributo(nome: 'Destreza', valor: 0),
          'CON': const Atributo(nome: 'Constituição', valor: 2),
          'INT': const Atributo(nome: 'Inteligência', valor: 0),
          'SAB': const Atributo(nome: 'Sabedoria', valor: 0),
          'CAR': const Atributo(nome: 'Carisma', valor: 0),
        },
        raca: anaoRaca,
        classes: [
          ClasseDoPersonagem(classeDefinicao: guerreiroClasse, nivel: 1),
        ],
      );

      expect(pAnaoNivel1.bonusRacialPV, equals(3));
      expect(pAnaoNivel1.pvTotal, equals(27));

      // Anão Nível 3:
      // CON: Base 2 + Raça 2 = 4.
      // Nível 1: 20 + 4 = 24
      // Nível 2: 5 + 4 = 9
      // Nível 3: 5 + 4 = 9
      // Base classe = 42. Anão (3 + 2 = 5): Total = 47.
      final pAnaoNivel3 = Personagem(
        nome: 'Thorin',
        atributos: {
          'FOR': const Atributo(nome: 'Força', valor: 0),
          'DES': const Atributo(nome: 'Destreza', valor: 0),
          'CON': const Atributo(nome: 'Constituição', valor: 2),
          'INT': const Atributo(nome: 'Inteligência', valor: 0),
          'SAB': const Atributo(nome: 'Sabedoria', valor: 0),
          'CAR': const Atributo(nome: 'Carisma', valor: 0),
        },
        raca: anaoRaca,
        classes: [
          ClasseDoPersonagem(classeDefinicao: guerreiroClasse, nivel: 3),
        ],
      );

      expect(pAnaoNivel3.bonusRacialPV, equals(5));
      expect(pAnaoNivel3.pvTotal, equals(47));

      // Elfo Nível 1:
      // Guerreiro pmInicial = 3.
      // Elfo: +1 PM por nível -> Total 4 PM.
      final pElfoNivel1 = Personagem(
        nome: 'Legolas',
        atributos: {
          'FOR': const Atributo(nome: 'Força', valor: 0),
          'DES': const Atributo(nome: 'Destreza', valor: 0),
          'CON': const Atributo(nome: 'Constituição', valor: 0),
          'INT': const Atributo(nome: 'Inteligência', valor: 0),
          'SAB': const Atributo(nome: 'Sabedoria', valor: 0),
          'CAR': const Atributo(nome: 'Carisma', valor: 0),
        },
        raca: elfoRaca,
        classes: [
          ClasseDoPersonagem(classeDefinicao: guerreiroClasse, nivel: 1),
        ],
      );

      expect(pElfoNivel1.bonusRacialPM, equals(1));
      expect(pElfoNivel1.pmTotal, equals(4));

      // Elfo Nível 5:
      // pmInicial 3 + (3 * 4 = 12) = 15.
      // Elfo (+5 PM) -> Total 20 PM.
      final pElfoNivel5 = Personagem(
        nome: 'Legolas',
        atributos: {
          'FOR': const Atributo(nome: 'Força', valor: 0),
          'DES': const Atributo(nome: 'Destreza', valor: 0),
          'CON': const Atributo(nome: 'Constituição', valor: 0),
          'INT': const Atributo(nome: 'Inteligência', valor: 0),
          'SAB': const Atributo(nome: 'Sabedoria', valor: 0),
          'CAR': const Atributo(nome: 'Carisma', valor: 0),
        },
        raca: elfoRaca,
        classes: [
          ClasseDoPersonagem(classeDefinicao: guerreiroClasse, nivel: 5),
        ],
      );

      expect(pElfoNivel5.bonusRacialPM, equals(5));
      expect(pElfoNivel5.pmTotal, equals(20));
    });
  });
}
