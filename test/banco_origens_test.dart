import 'package:flutter_test/flutter_test.dart';
import 'package:t20_creator/domain/entities/personagem/origem.dart';
import 'package:t20_creator/domain/services/data_services/call_origens.dart';
import 'package:t20_creator/presentation/controllers/personagem_cubit.dart';

void main() {
  group('BancoDeOrigens e Entidade Origem', () {
    test(
      'carrega catalogo a partir do JSON de assets e busca por ID e Nome',
      () {
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
      },
    );

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

    test('PersonagemCubit bloqueia seleção de perícia de origem já treinada na classe', () {
      final cubit = PersonagemCubit();
      final soldado = BancoDeOrigens.getById('soldado')!;

      // Simula classe com LUTA e FORTITUDE treinadas
      cubit.emit(
        cubit.state.copyWith(
          selecoesPericiaClasse: ['LUTA', 'FORTITUDE'],
        ),
      );

      cubit.selecionarOrigem(soldado);

      // Soldado oferece LUTA e PONTARIA
      expect(soldado.periciasOpcoes, contains('LUTA'));
      expect(soldado.periciasOpcoes, contains('PONTARIA'));

      // LUTA já está treinada na classe, então periciaJaTreinada deve ser true
      expect(cubit.state.periciaJaTreinada('LUTA'), isTrue);
      expect(cubit.state.periciaJaTreinada('PONTARIA'), isFalse);

      // Tenta selecionar LUTA pela origem -> não deve ser selecionada
      cubit.togglePericiaOrigem('LUTA');
      expect(cubit.state.periciasEscolhidasOrigem, isNot(contains('LUTA')));

      // Seleciona PONTARIA -> deve ser selecionada normalmente
      cubit.togglePericiaOrigem('PONTARIA');
      expect(cubit.state.periciasEscolhidasOrigem, contains('PONTARIA'));
    });
  });
}
