import 'package:flutter_test/flutter_test.dart';
import 'package:t20_creator/domain/entities/personagem/origem.dart';
import 'package:t20_creator/domain/services/data_services/call_origens.dart';
import 'package:t20_creator/domain/services/data_services/call_poderes.dart';
import 'package:t20_creator/presentation/controllers/personagem_cubit.dart';

void main() {
  group('BancoDeOrigens, BancoDePoderesGerais e Entidade Origem', () {
    test(
      'carrega catalogo a partir do JSON normalizado e resolve poderUnicoId e poderesGeraisOpcoesIds',
      () {
        final todas = BancoDeOrigens.todas;
        expect(todas.length, greaterThanOrEqualTo(35));

        final acolito = BancoDeOrigens.getById('acolito');
        expect(acolito, isNotNull);
        expect(acolito!.nome, equals('Acólito'));
        expect(acolito.itensIniciais, contains('Símbolo sagrado'));
        expect(acolito.periciasOpcoes, contains('CURA'));
        expect(acolito.poderUnicoId, equals('membro_da_igreja'));
        expect(acolito.poderUnico.key, equals('membro_da_igreja'));
        expect(acolito.poderUnico.nome, equals('Membro da Igreja'));
        expect(acolito.poderUnico.descricao, isNotEmpty);

        // Verifica que poderesGeraisOpcoesIds foram resolvidos no catálogo de Poderes Gerais
        expect(
          acolito.poderesGeraisOpcoesIds,
          containsAll(['medicina', 'vontade_de_ferro']),
        );
        final chavesResolvidas = acolito.poderesGeraisOpcoes
            .map((p) => p.key)
            .toList();
        expect(
          chavesResolvidas,
          containsAll(['medicina', 'vontade_de_ferro']),
        );

        // Verifica que todas as origens possuem poderUnico resolvido com descrição
        for (final origem in todas) {
          expect(
            origem.poderUnico.key,
            isNotEmpty,
            reason: 'Origem ${origem.id} sem poderUnico.key',
          );
          expect(
            origem.poderUnico.nome,
            isNotEmpty,
            reason: 'Origem ${origem.id} sem poderUnico.nome',
          );
          expect(
            origem.poderUnico.descricao,
            isNotEmpty,
            reason: 'Origem ${origem.id} (${origem.poderUnicoId}) sem descrição',
          );
        }
      },
    );

    test(
      'disponibiliza lista completa de poderes_combate.json quando escolhaLivrePoderCombate for verdadeiro',
      () {
        final poderesCombate = BancoDePoderesGerais.poderesCombate;
        expect(poderesCombate, isNotEmpty);

        final soldado = BancoDeOrigens.getById('soldado');
        expect(soldado, isNotNull);
        expect(soldado!.escolhaLivrePoderCombate, isTrue);
        expect(soldado.poderUnico.key, equals('influencia_militar'));

        // Todos os poderes de combate devem estar nas opções do Soldado
        final chavesSoldado = soldado.poderesGeraisOpcoes
            .map((p) => p.key)
            .toSet();
        for (final pc in poderesCombate) {
          expect(
            chavesSoldado.contains(pc.key),
            isTrue,
            reason: 'Poder de combate ${pc.key} deveria estar em Soldado',
          );
        }

        // Guarda tem "investigador" (Destino) + todos os poderes de combate
        final guarda = BancoDeOrigens.getById('guarda')!;
        expect(guarda.escolhaLivrePoderCombate, isTrue);
        final chavesGuarda = guarda.poderesGeraisOpcoes
            .map((p) => p.key)
            .toSet();
        expect(chavesGuarda, contains('investigador'));
        expect(chavesGuarda.length, equals(poderesCombate.length + 1));

        // Origem sem escolhaLivrePoderCombate não deve receber todos os poderes de combate
        final acolito = BancoDeOrigens.getById('acolito')!;
        expect(acolito.escolhaLivrePoderCombate, isFalse);
        expect(acolito.poderesGeraisOpcoes.length, equals(2));
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

    test(
      'PersonagemCubit bloqueia seleção de perícia de origem já treinada na classe',
      () {
        final cubit = PersonagemCubit();
        final soldado = BancoDeOrigens.getById('soldado')!;

        // Simula classe com LUTA e FORTITUDE treinadas
        cubit.emit(
          cubit.state.copyWith(selecoesPericiaClasse: ['LUTA', 'FORTITUDE']),
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
      },
    );

    test(
      'PersonagemCubit permite concluir origem Amnésico (1 único benefício selecionável)',
      () {
        final cubit = PersonagemCubit();
        final amnesico = BancoDeOrigens.getById('amnesico')!;

        cubit.selecionarOrigem(amnesico);
        expect(cubit.state.metaBeneficiosOrigem, equals(1));
        expect(cubit.state.concluiuOrigem, isFalse);

        cubit.togglePoderOrigem(amnesico.poderUnico);
        expect(cubit.state.concluiuOrigem, isTrue);
      },
    );
  });
}
