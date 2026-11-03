import 'package:flutter_test/flutter_test.dart';
import 'package:t20_creator/domain/entities/personagem/atributos.dart';
import 'package:t20_creator/domain/entities/personagem/classe_do_personagem.dart';
import 'package:t20_creator/domain/entities/personagem/personagem.dart';
import 'package:t20_creator/domain/repositories/i_personagem_repository.dart';
import 'package:t20_creator/domain/services/data_services/call_classes.dart';
import 'package:t20_creator/domain/services/ficha_services/personagem_storage_service.dart';
import 'package:t20_creator/domain/services/ficha_services/tabela_experiencia_service.dart';
import 'package:t20_creator/presentation/controllers/ficha_controller/ficha_cubit.dart';

class _MemoriaPersonagemRepository implements IPersonagemRepository {
  final Map<String, Personagem> _dados = {};

  @override
  Future<void> salvar(Personagem p) async {
    _dados[p.id] = p;
  }

  @override
  Future<List<Personagem>> obterTodos() async => _dados.values.toList();

  @override
  Future<Personagem?> obterPorId(String id) async => _dados[id];

  @override
  Future<void> excluir(String id) async {
    _dados.remove(id);
  }
}

Map<String, Atributo> _criarAtributos() {
  return {
    'FOR': const Atributo(nome: 'Força', valor: 2),
    'DES': const Atributo(nome: 'Destreza', valor: 1),
    'CON': const Atributo(nome: 'Constituição', valor: 2),
    'INT': const Atributo(nome: 'Inteligência', valor: 0),
    'SAB': const Atributo(nome: 'Sabedoria', valor: 0),
    'CAR': const Atributo(nome: 'Carisma', valor: 0),
  };
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await BancoDeClasses.carregar();
  });

  group('Tabela de Experiência Oficial T20 (TabelaExperienciaService)', () {
    test(
      'Valida todos os 20 patamares de XP da tabela oficial de Tormenta 20',
      () {
        final tabelaEsperada = <int, int>{
          1: 0,
          2: 1000,
          3: 3000,
          4: 6000,
          5: 10000,
          6: 15000,
          7: 21000,
          8: 28000,
          9: 36000,
          10: 45000,
          11: 55000,
          12: 66000,
          13: 78000,
          14: 91000,
          15: 105000,
          16: 120000,
          17: 136000,
          18: 153000,
          19: 171000,
          20: 190000,
        };

        for (final entry in tabelaEsperada.entries) {
          expect(
            TabelaExperienciaService.xpTotalParaNivel(entry.key),
            equals(entry.value),
            reason:
                'Nível ${entry.key} deve exigir exatamente ${entry.value} XP cumulativo',
          );
        }
      },
    );

    test('Calcula intervalo e progresso percentual corretamente', () {
      // Nível 1 com 500 XP (precisa de 1.000 para ir ao Nv. 2)
      final progressoNv1 = TabelaExperienciaService.calcularProgresso(
        nivelAtual: 1,
        xpAtual: 500,
      );

      expect(progressoNv1.xpBaseNivelAtual, equals(0));
      expect(progressoNv1.xpNecessarioProximoNivel, equals(1000));
      expect(progressoNv1.xpIntervaloNivel, equals(1000));
      expect(progressoNv1.xpProgressoNoIntervalo, equals(500));
      expect(progressoNv1.xpRestanteProximoNivel, equals(500));
      expect(progressoNv1.porcentagemProgresso, closeTo(0.5, 0.001));
      expect(progressoNv1.porcentagemFormatada, equals('50%'));
      expect(progressoNv1.temXpSuficienteParaUpar, isFalse);

      // Nível 1 com 1.200 XP (já tem mais do que 1.000)
      final progressoPronto = TabelaExperienciaService.calcularProgresso(
        nivelAtual: 1,
        xpAtual: 1200,
      );
      expect(progressoPronto.temXpSuficienteParaUpar, isTrue);
      expect(progressoPronto.xpRestanteProximoNivel, equals(0));
      expect(progressoPronto.porcentagemProgresso, equals(1.0));

      // Nível 2 com 1.500 XP (Base=1.000, Meta=3.000, Intervalo=2.000, Progresso=500 -> 25%)
      final progressoNv2 = TabelaExperienciaService.calcularProgresso(
        nivelAtual: 2,
        xpAtual: 1500,
      );
      expect(progressoNv2.xpBaseNivelAtual, equals(1000));
      expect(progressoNv2.xpNecessarioProximoNivel, equals(3000));
      expect(progressoNv2.xpIntervaloNivel, equals(2000));
      expect(progressoNv2.xpProgressoNoIntervalo, equals(500));
      expect(progressoNv2.xpRestanteProximoNivel, equals(1500));
      expect(progressoNv2.porcentagemProgresso, closeTo(0.25, 0.001));
      expect(progressoNv2.porcentagemFormatada, equals('25%'));

      // Nível 20 (Nível Máximo)
      final progressoNv20 = TabelaExperienciaService.calcularProgresso(
        nivelAtual: 20,
        xpAtual: 200000,
      );
      expect(progressoNv20.nivelMaximoAtingido, isTrue);
      expect(progressoNv20.temXpSuficienteParaUpar, isFalse);
      expect(progressoNv20.porcentagemProgresso, equals(1.0));
    });
  });

  group('Regras de Nível, XP e Modo Tabletop no Personagem', () {
    test(
      'Modo Solo: personagem sempre pode evoluir até o nível 20 independente de XP',
      () {
        final guerreiroDef = BancoDeClasses.getById('guerreiro')!;
        final p = Personagem(
          nome: 'Guerreiro Solo',
          atributos: _criarAtributos(),
          classes: [
            ClasseDoPersonagem(classeDefinicao: guerreiroDef, nivel: 1),
          ],
          experienciaAtual: 0,
          modoTabletopAtivo: false,
        );

        expect(p.podeSubirDeNivel, isTrue);
        expect(p.temXpSuficienteParaSubirNivel, isFalse);
      },
    );

    test(
      'Modo Tabletop: bloqueia subida de nível quando não tem XP e nem permissão do mestre',
      () {
        final guerreiroDef = BancoDeClasses.getById('guerreiro')!;
        final p = Personagem(
          nome: 'Guerreiro de Mesa',
          atributos: _criarAtributos(),
          classes: [
            ClasseDoPersonagem(classeDefinicao: guerreiroDef, nivel: 1),
          ],
          experienciaAtual: 300,
          modoTabletopAtivo: true,
          permissaoMestreSubirNivel: false,
        );

        expect(p.temXpSuficienteParaSubirNivel, isFalse);
        expect(p.permissaoMestreSubirNivel, isFalse);
        expect(p.podeSubirDeNivel, isFalse);
      },
    );

    test(
      'Modo Tabletop: permite subida quando o jogador acumula XP suficiente',
      () {
        final guerreiroDef = BancoDeClasses.getById('guerreiro')!;
        final p = Personagem(
          nome: 'Guerreiro Experiente',
          atributos: _criarAtributos(),
          classes: [
            ClasseDoPersonagem(classeDefinicao: guerreiroDef, nivel: 1),
          ],
          experienciaAtual: 1000, // Exatamente a meta para o Nível 2
          modoTabletopAtivo: true,
          permissaoMestreSubirNivel: false,
        );

        expect(p.temXpSuficienteParaSubirNivel, isTrue);
        expect(p.podeSubirDeNivel, isTrue);
      },
    );

    test(
      'Modo Tabletop: permite subida quando o mestre concede autorização explícita',
      () {
        final guerreiroDef = BancoDeClasses.getById('guerreiro')!;
        final p = Personagem(
          nome: 'Guerreiro com Milestone',
          atributos: _criarAtributos(),
          classes: [
            ClasseDoPersonagem(classeDefinicao: guerreiroDef, nivel: 1),
          ],
          experienciaAtual: 0,
          modoTabletopAtivo: true,
          permissaoMestreSubirNivel: true, // Mestre liberou
        );

        expect(p.temXpSuficienteParaSubirNivel, isFalse);
        expect(p.permissaoMestreSubirNivel, isTrue);
        expect(p.podeSubirDeNivel, isTrue);
      },
    );

    test(
      'Persistência JSON preserva experienciaAtual, modoTabletopAtivo e permissaoMestreSubirNivel',
      () {
        final guerreiroDef = BancoDeClasses.getById('guerreiro')!;
        final original = Personagem(
          nome: 'Zaled',
          atributos: _criarAtributos(),
          classes: [
            ClasseDoPersonagem(classeDefinicao: guerreiroDef, nivel: 3),
          ],
          experienciaAtual: 4500,
          modoTabletopAtivo: true,
          permissaoMestreSubirNivel: false,
        );

        final map = PersonagemStorageService.personagemToMap(original);
        final recuperado = PersonagemStorageService.mapToPersonagem(map);

        expect(recuperado.experienciaAtual, equals(4500));
        expect(recuperado.modoTabletopAtivo, isTrue);
        expect(recuperado.permissaoMestreSubirNivel, isFalse);
        expect(recuperado.nivelPersonagem, equals(3));
      },
    );
  });

  group('FichaCubit - Integração de XP e Modo Tabletop', () {
    test(
      'Bloqueia subida de nível quando modo Tabletop está ativo e sem requisitos',
      () async {
        final repo = _MemoriaPersonagemRepository();
        final guerreiroDef = BancoDeClasses.getById('guerreiro')!;
        final inicial = Personagem(
          nome: 'Herói Tabletop',
          atributos: _criarAtributos(),
          classes: [
            ClasseDoPersonagem(classeDefinicao: guerreiroDef, nivel: 1),
          ],
          experienciaAtual: 200,
          modoTabletopAtivo: true,
          permissaoMestreSubirNivel: false,
        );

        final cubit = FichaCubit(
          repository: repo,
          personagemInicial: inicial,
          debounceDuration: Duration.zero,
        );

        // Tenta alterar nível na classe
        final sucessoClasse = await cubit.alterarNivelClasse(0, 1);
        expect(sucessoClasse, isFalse);
        expect(cubit.state.personagem.nivelPersonagem, equals(1));
        expect(cubit.state.mensagemErro, contains('Tabletop'));

        // Tenta adicionar multiclasse
        final arcanistaDef = BancoDeClasses.getById('arcanista')!;
        final sucessoMulticlasse = await cubit.adicionarMulticlasse(
          arcanistaDef,
        );
        expect(sucessoMulticlasse, isFalse);
        expect(cubit.state.personagem.nivelPersonagem, equals(1));

        // Mestre concede permissão
        await cubit.definirPermissaoMestre(true);
        expect(cubit.state.personagem.podeSubirDeNivel, isTrue);

        // Agora a subida funciona
        final sucessoComPermissao = await cubit.alterarNivelClasse(0, 1);
        expect(sucessoComPermissao, isTrue);
        expect(cubit.state.personagem.nivelPersonagem, equals(2));

        await cubit.close();
      },
    );

    test(
      'Desbloqueia subida de nível automaticamente ao adicionar XP suficiente',
      () async {
        final repo = _MemoriaPersonagemRepository();
        final guerreiroDef = BancoDeClasses.getById('guerreiro')!;
        final inicial = Personagem(
          nome: 'Herói Acumulador de XP',
          atributos: _criarAtributos(),
          classes: [
            ClasseDoPersonagem(classeDefinicao: guerreiroDef, nivel: 1),
          ],
          experienciaAtual: 200,
          modoTabletopAtivo: true,
          permissaoMestreSubirNivel: false,
        );

        final cubit = FichaCubit(
          repository: repo,
          personagemInicial: inicial,
          debounceDuration: Duration.zero,
        );

        expect(cubit.state.personagem.podeSubirDeNivel, isFalse);

        // Jogador ganha +800 XP (Total 1.000 XP)
        await cubit.adicionarXP(800);
        expect(cubit.state.personagem.experienciaAtual, equals(1000));
        expect(cubit.state.personagem.temXpSuficienteParaSubirNivel, isTrue);
        expect(cubit.state.personagem.podeSubirDeNivel, isTrue);

        // Consegue subir para o Nível 2
        final subiu = await cubit.alterarNivelClasse(0, 1);
        expect(subiu, isTrue);
        expect(cubit.state.personagem.nivelPersonagem, equals(2));

        await cubit.close();
      },
    );
  });
}
