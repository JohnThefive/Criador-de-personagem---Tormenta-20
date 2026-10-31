import 'package:flutter_test/flutter_test.dart';
import 'package:t20_creator/domain/entities/personagem/classe.dart';
import 'package:t20_creator/domain/entities/personagem/classe_do_personagem.dart';
import 'package:t20_creator/domain/entities/personagem/personagem.dart';
import 'package:t20_creator/domain/repositories/i_personagem_repository.dart';
import 'package:t20_creator/presentation/controllers/ficha_cubit.dart';

class FakePersonagemRepository implements IPersonagemRepository {
  Personagem? salvo;
  int chamadasSalvar = 0;

  @override
  Future<void> salvar(Personagem p) async {
    salvo = p;
    chamadasSalvar++;
  }

  @override
  Future<List<Personagem>> obterTodos() async => salvo != null ? [salvo!] : [];

  @override
  Future<Personagem?> obterPorId(String id) async => salvo?.id == id ? salvo : null;

  @override
  Future<void> excluir(String id) async {
    if (salvo?.id == id) salvo = null;
  }
}

void main() {
  group('FichaCubit - Testes Unitários de Regras da Ficha', () {
    late FakePersonagemRepository repo;
    late Personagem personagemBase;

    setUp(() {
      repo = FakePersonagemRepository();
      const classeGuerreiro = Classe(
        idClasse: 'guerreiro',
        nome: 'Guerreiro',
        pvInicial: 20,
        pvPorNivel: 5,
        pmInicial: 3,
        pmPorNivel: 3,
        proficiencias: [],
        periciasFixas: [],
        periciasOpcoes: [],
        qtdPericiasEscolha: 2,
        descricaoclasse: 'Mestre das armas.',
      );

      personagemBase = Personagem.inicial().copyWith(
        nome: 'Sir Loras',
        classe_do_personagem: [
          ClasseDoPersonagem(
            classeDefinicao: classeGuerreiro,
            nivel: 1,
          ),
        ],
        pvAtual: 20,
        pmAtual: 3,
      );
    });

    test('Dano e Cura de PV alteram estado e persistem', () async {
      final cubit = FichaCubit(
        personagemInicial: personagemBase,
        repository: repo,
        debounceDuration: Duration.zero,
      );

      await cubit.aplicarDano(7);
      expect(cubit.state.personagem.pvAtual, equals(13));
      expect(repo.salvo?.pvAtual, equals(13));

      await cubit.curarPV(4);
      expect(cubit.state.personagem.pvAtual, equals(17));
      expect(repo.salvo?.pvAtual, equals(17));
    });

    test('Debounce agrupa múltiplos cliques rápidos de PV/PM em uma única gravação em disco', () async {
      final cubit = FichaCubit(
        personagemInicial: personagemBase,
        repository: repo,
        debounceDuration: const Duration(milliseconds: 100),
      );

      // 5 cliques rápidos de -1 PV consecutivos
      await cubit.aplicarDano(1);
      await cubit.aplicarDano(1);
      await cubit.aplicarDano(1);
      await cubit.aplicarDano(1);
      await cubit.aplicarDano(1);

      // Estado reage instantaneamente na memória/UI
      expect(cubit.state.personagem.pvAtual, equals(15));
      // Mas o disco ainda não foi atingido devido ao debounce
      expect(repo.chamadasSalvar, equals(0));

      // Aguarda expiração da janela de debounce
      await Future.delayed(const Duration(milliseconds: 140));

      // Gravou apenas 1 vez em disco com o valor final acumulado
      expect(repo.chamadasSalvar, equals(1));
      expect(repo.salvo?.pvAtual, equals(15));

      await cubit.close();
    });

    test('Gasto e Recuperação de PM respeitam limites e punição divina', () async {
      final cubit = FichaCubit(personagemInicial: personagemBase, repository: repo);

      await cubit.gastarPM(2);
      expect(cubit.state.personagem.pmAtual, equals(1));

      // Recupera normal
      final ok = await cubit.recuperarPM(2);
      expect(ok, isTrue);
      expect(cubit.state.personagem.pmAtual, equals(3));

      // Aplica punição divina
      await cubit.aplicarPunicaoDivina();
      expect(cubit.state.personagem.punicaoDivinaAtiva, isTrue);
      expect(cubit.state.personagem.pmAtual, equals(0));

      // Tentativa de recuperar PM durante punição é bloqueada
      final bloqueado = await cubit.recuperarPM(2);
      expect(bloqueado, isFalse);
      expect(cubit.state.personagem.pmAtual, equals(0));

      // Remove punição
      await cubit.removerPunicaoDivina();
      expect(cubit.state.personagem.punicaoDivinaAtiva, isFalse);
    });

    test('Alteração de nível incrementa nível e preserva integridade', () async {
      final cubit = FichaCubit(personagemInicial: personagemBase, repository: repo);

      final subiu = await cubit.alterarNivel(1);
      expect(subiu, isTrue);
      expect(cubit.state.personagem.classes[0].nivel, equals(2));

      // Não pode passar de 20
      for (int i = 0; i < 25; i++) {
        await cubit.alterarNivel(1);
      }
      expect(cubit.state.personagem.classes[0].nivel, equals(20));
    });

    test('Descanso restaura recursos conforme regras de T20', () async {
      final cubit = FichaCubit(personagemInicial: personagemBase, repository: repo);

      await cubit.aplicarDano(15);
      await cubit.gastarPM(3);
      expect(cubit.state.personagem.pvAtual, equals(5));
      expect(cubit.state.personagem.pmAtual, equals(0));

      await cubit.descansoNormal();
      expect(cubit.state.personagem.pvAtual, greaterThan(5));
      expect(cubit.state.personagem.pmAtual, greaterThan(0));

      await cubit.descansoCompleto();
      expect(cubit.state.personagem.pvAtual, equals(cubit.state.personagem.pvTotal));
      expect(cubit.state.personagem.pmAtual, equals(cubit.state.personagem.pmTotal));
    });
  });
}
