import 'package:flutter_test/flutter_test.dart';
import 'package:t20_creator/domain/entities/origem.dart';
import 'package:t20_creator/domain/services/data_services/call_origens.dart';

void main() {
  group('BancoDeOrigens e Entidade Origem', () {
    test('carrega catalogo a partir do JSON de assets e busca por ID e Nome', () {
      final todas = BancoDeOrigens.todas;
      expect(todas, isNotEmpty);

      final acolito = BancoDeOrigens.getById('acolito');
      expect(acolito, isNotNull);
      expect(acolito!.nome, equals('Acólito'));
      expect(acolito.itensIniciais, contains('Símbolo sagrado'));
      expect(acolito.periciasOpcoes, contains('CURA'));
      expect(acolito.poderUnico.key, equals('membro_da_igreja'));

      final porNome = BancoDeOrigens.getByNome('Soldado');
      expect(porNome, isNotNull);
      expect(porNome!.id, equals('soldado'));
    });

    test('Origem.fromJson lida com campos ausentes sem falhar', () {
      final jsonMinimo = {
        'id': 'teste',
        'nome': 'Teste',
        'descricao': 'Origem teste',
      };

      final origem = Origem.fromJson(jsonMinimo);
      expect(origem.id, equals('teste'));
      expect(origem.itensIniciais, isEmpty);
      expect(origem.periciasOpcoes, isEmpty);
      expect(origem.poderesGeraisOpcoes, isEmpty);
      expect(origem.poderUnico.key, isEmpty);
    });
  });
}
