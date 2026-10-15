import 'package:flutter_test/flutter_test.dart';
import 'package:t20_creator/domain/entities/personagem/personagem.dart';
import 'package:t20_creator/domain/repositories/i_personagem_repository.dart';
import 'package:t20_creator/presentation/controllers/home_cubit.dart';

/// Implementação em memória de [IPersonagemRepository] usada para testes unitários,
/// eliminando a necessidade de mockar canais de plataforma (PathProvider) ou I/O de disco.
class InMemoryPersonagemRepository implements IPersonagemRepository {
  final Map<String, Personagem> _armazenamento = {};

  @override
  Future<void> salvar(Personagem p) async {
    _armazenamento[p.id] = p;
  }

  @override
  Future<List<Personagem>> obterTodos() async {
    return _armazenamento.values.toList();
  }

  @override
  Future<Personagem?> obterPorId(String id) async {
    return _armazenamento[id];
  }

  @override
  Future<void> excluir(String id) async {
    _armazenamento.remove(id);
  }
}

void main() {
  group('IPersonagemRepository & HomeCubit com Injeção de Dependência', () {
    late InMemoryPersonagemRepository repository;
    late HomeCubit homeCubit;

    setUp(() {
      repository = InMemoryPersonagemRepository();
      homeCubit = HomeCubit(repository: repository);
    });

    tearDown(() {
      homeCubit.close();
    });

    test('Deve iniciar com estado de loading e lista vazia', () {
      expect(homeCubit.state.personagens, isEmpty);
    });

    test('Deve carregar personagens salvos no repositório', () async {
      final p1 = Personagem.inicial().copyWith(nome: 'Valeros');
      final p2 = Personagem.inicial().copyWith(nome: 'Seoni');

      await repository.salvar(p1);
      await repository.salvar(p2);

      await homeCubit.carregarPersonagensReais();

      expect(homeCubit.state.carregando, isFalse);
      expect(homeCubit.state.personagens.length, equals(2));
      expect(homeCubit.state.personagens.map((p) => p.nome), containsAll(['Valeros', 'Seoni']));
    });

    test('Deve excluir personagem através do repositório injetado', () async {
      final p = Personagem.inicial().copyWith(nome: 'Harsk');
      await repository.salvar(p);

      await homeCubit.carregarPersonagensReais();
      expect(homeCubit.state.personagens.length, equals(1));

      await homeCubit.excluirPersonagem(p.id);

      expect(homeCubit.state.personagens, isEmpty);
      final excluido = await repository.obterPorId(p.id);
      expect(excluido, isNull);
    });
  });
}
