import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttericon/rpg_awesome_icons.dart';
import 'package:t20_creator/domain/entities/classe.dart';
import 'package:t20_creator/domain/entities/proficiencias.dart';
import 'package:t20_creator/domain/services/data_services/call_classes.dart';
import 'package:t20_creator/helpers/icone_rpg_helper.dart';

void main() {
  group('Entidade Classe, CaminhoDeClasse e BancoDeClasses', () {
    test('IconeRpgHelper mapeia os ícones das classes corretamente', () {
      expect(
        IconeRpgHelper.obterIcone('crystal_ball'),
        equals(RpgAwesome.crystal_ball),
      );
      expect(IconeRpgHelper.obterIcone('axe'), equals(RpgAwesome.axe));
      expect(IconeRpgHelper.obterIcone('harp'), equals(RpgAwesome.ocarina));
      expect(
        IconeRpgHelper.obterIcone('saber-and-pistol'),
        equals(RpgAwesome.crossed_sabres),
      );
      expect(
        IconeRpgHelper.obterIcone('crossbow'),
        equals(RpgAwesome.crossbow),
      );
    });

    test('CaminhoDeClasse serializa e desserializa via JSON', () {
      final jsonCaminho = {
        'nome': 'Bruxo',
        'atributoChave': 'INT',
        'descricao': 'Usa um foco mágico.',
        'temFocoMagico': true,
        'temLinhagem': false,
        'temGrimorio': false,
      };

      final caminho = CaminhoDeClasse.fromJson(jsonCaminho);
      expect(caminho.nome, equals('Bruxo'));
      expect(caminho.atributoChave, equals('INT'));
      expect(caminho.descricao, equals('Usa um foco mágico.'));
      expect(caminho.temFocoMagico, isTrue);
      expect(caminho.temLinhagem, isFalse);

      final map = caminho.toJson();
      expect(map['nome'], equals('Bruxo'));
      expect(map['atributoChave'], equals('INT'));
      expect(map['temFocoMagico'], isTrue);
    });

    test(
      'Classe serializa e desserializa via JSON e mantém compatibilidade de getters',
      () {
        final jsonClasse = {
          'id': 'arcanista',
          'nome': 'Arcanista',
          'descricaoClasse': 'Usuário de magias arcanas.',
          'icone': 'crystal_ball',
          'pvInicial': 8,
          'pvPorNivel': 2,
          'pmInicial': 6,
          'pmPorNivel': 6,
          'proficiencias': ['LEVES'],
          'periciasFixas': ['MISTICISMO', 'VONTADE'],
          'qtdPericiasEscolha': 2,
          'periciasOpcoes': ['CONHECIMENTO', 'DIPLOMACIA'],
          'tabelaDeProgressao': {
            '1': ['Escolha do Caminho', 'Magias de 1º Círculo'],
            '2': ['Poder de Arcanista'],
          },
          'caminhosDisponiveis': [
            {
              'nome': 'Bruxo',
              'atributoChave': 'INT',
              'descricao': 'Foco',
              'temFocoMagico': true,
              'temLinhagem': false,
              'temGrimorio': false,
            },
          ],
          'habilidadesFixasNivel': {
            '1': ['Magias'],
          },
        };

        final classe = Classe.fromJson(jsonClasse);

        // Verificação de getters principais e legados
        expect(classe.id, equals('arcanista'));
        expect(classe.idClasse, equals('arcanista'));
        expect(classe.nome, equals('Arcanista'));
        expect(classe.descricaoClasse, equals('Usuário de magias arcanas.'));
        expect(classe.descricaoclasse, equals('Usuário de magias arcanas.'));
        expect(classe.icone, equals('crystal_ball'));
        expect(classe.iconeClasse, equals(RpgAwesome.crystal_ball));
        expect(classe.pvInicial, equals(8));
        expect(classe.pvPorNivel, equals(2));
        expect(classe.pmInicial, equals(6));
        expect(classe.pmPorNivel, equals(6));
        expect(classe.proficiencias, contains(TipoProficiencia.armadurasLeves));
        expect(classe.periciasFixas, equals(['MISTICISMO', 'VONTADE']));
        expect(classe.qtdPericiasEscolha, equals(2));
        expect(classe.periciasOpcoes, equals(['CONHECIMENTO', 'DIPLOMACIA']));
        expect(classe.caminhosDisponiveis.length, equals(1));
        expect(classe.caminhosDisponiveis.first.nome, equals('Bruxo'));
        expect(classe.tabelaDeProgressao[1]?.length, equals(2));

        // Teste de exportação toJson
        final mapGerado = classe.toJson();
        expect(mapGerado['id'], equals('arcanista'));
        expect(mapGerado['nome'], equals('Arcanista'));
        expect(mapGerado['icone'], equals('crystal_ball'));
        expect(mapGerado['pvInicial'], equals(8));
      },
    );

    test(
      'BancoDeClasses busca por id e por nome com insensibilidade a maiúsculas',
      () {
        const c1 = Classe(
          idClasse: 'arcanista',
          nome: 'Arcanista',
          descricaoclasse: 'Mago',
          icone: 'crystal_ball',
          pvInicial: 8,
          pvPorNivel: 2,
          pmInicial: 6,
          pmPorNivel: 6,
          proficiencias: [],
          periciasFixas: [],
          qtdPericiasEscolha: 2,
          periciasOpcoes: [],
        );

        const c2 = Classe(
          idClasse: 'barbaro',
          nome: 'Bárbaro',
          descricaoclasse: 'Fúria',
          icone: 'axe',
          pvInicial: 24,
          pvPorNivel: 6,
          pmInicial: 3,
          pmPorNivel: 3,
          proficiencias: [],
          periciasFixas: [],
          qtdPericiasEscolha: 4,
          periciasOpcoes: [],
        );

        BancoDeClasses.carregarParaTestes([c1, c2]);

        expect(BancoDeClasses.todas.length, equals(2));
        expect(BancoDeClasses.getById('arcanista')?.nome, equals('Arcanista'));
        expect(BancoDeClasses.getById('ARCANISTA')?.nome, equals('Arcanista'));
        expect(BancoDeClasses.getById('barbaro')?.nome, equals('Bárbaro'));
        expect(
          BancoDeClasses.getByNome('Bárbaro')?.idClasse,
          equals('barbaro'),
        );
        expect(
          BancoDeClasses.getByNome('bárbaro')?.idClasse,
          equals('barbaro'),
        );
        expect(BancoDeClasses.getById('inexistente'), isNull);
      },
    );

    test(
      'Arquivo assets/data/banco_classe.json é válido e carrega as 5 classes do catálogo',
      () {
        final file = File('assets/data/banco_classe.json');
        expect(
          file.existsSync(),
          isTrue,
          reason: 'O arquivo banco_classe.json deve existir em assets/data/',
        );

        final content = file.readAsStringSync();
        final List<dynamic> jsonList = jsonDecode(content);

        expect(jsonList.length, equals(5));

        final classes = jsonList
            .map((e) => Classe.fromJson(e as Map<String, dynamic>))
            .toList();
        expect(classes.length, equals(5));

        final idsEsperados = {
          'arcanista',
          'barbaro',
          'bardo',
          'bucaneiro',
          'cacador',
        };
        final idsEncontrados = classes.map((c) => c.idClasse).toSet();
        expect(idsEncontrados, equals(idsEsperados));

        for (final classe in classes) {
          expect(classe.idClasse, isNotEmpty);
          expect(classe.nome, isNotEmpty);
          expect(classe.descricaoClasse, isNotEmpty);
          expect(classe.icone, isNotEmpty);
          expect(classe.iconeClasse, isNotNull);
          expect(classe.pvInicial, greaterThan(0));
          expect(classe.pvPorNivel, greaterThan(0));
          expect(classe.pmInicial, greaterThan(0));
          expect(classe.pmPorNivel, greaterThan(0));
          expect(classe.periciasOpcoes, isNotEmpty);
          expect(classe.tabelaDeProgressao, isNotEmpty);
        }

        // Verificações específicas de classes com caminhos
        final arcanista = classes.firstWhere((c) => c.idClasse == 'arcanista');
        expect(arcanista.caminhosDisponiveis.length, equals(3));
        expect(
          arcanista.caminhosDisponiveis.map((c) => c.nome),
          containsAll(['Bruxo', 'Feiticeiro', 'Mago']),
        );

        // Verificações de Caçador e Bucaneiro
        final cacador = classes.firstWhere((c) => c.idClasse == 'cacador');
        expect(cacador.nome, equals('Caçador'));
        expect(cacador.pvInicial, equals(16));

        final bucaneiro = classes.firstWhere((c) => c.idClasse == 'bucaneiro');
        expect(bucaneiro.nome, equals('Bucaneiro'));
        expect(bucaneiro.icone, equals('saber-and-pistol'));
      },
    );
  });
}
