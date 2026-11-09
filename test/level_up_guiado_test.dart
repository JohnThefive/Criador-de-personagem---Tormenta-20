import 'package:flutter_test/flutter_test.dart';
import 'package:t20_creator/domain/entities/personagem/atributos.dart';
import 'package:t20_creator/domain/entities/personagem/classe.dart';
import 'package:t20_creator/domain/entities/personagem/classe_do_personagem.dart';
import 'package:t20_creator/domain/entities/personagem/personagem.dart';
import 'package:t20_creator/domain/entities/personagem/resumo_level_up.dart';
import 'package:t20_creator/domain/repositories/i_personagem_repository.dart';
import 'package:t20_creator/domain/services/data_services/call_classes.dart';
import 'package:t20_creator/domain/services/data_services/call_magias.dart';
import 'package:t20_creator/domain/services/data_services/call_pericias.dart';
import 'package:t20_creator/domain/services/data_services/call_poderes.dart';
import 'package:t20_creator/domain/services/ficha_services/motor_multiclasse_service.dart';
import 'package:t20_creator/domain/services/powers_service/aprendizado_magia_service.dart';
import 'package:t20_creator/presentation/controllers/ficha_controller/ficha_cubit.dart';

class _FakePersonagemRepository implements IPersonagemRepository {
  Personagem? salvo;

  @override
  Future<void> salvar(Personagem p) async {
    salvo = p;
  }

  @override
  Future<List<Personagem>> obterTodos() async => salvo != null ? [salvo!] : [];

  @override
  Future<Personagem?> obterPorId(String id) async => salvo;

  @override
  Future<void> excluir(String id) async {
    salvo = null;
  }
}

Map<String, Atributo> _criarAtributos({
  int forca = 0,
  int des = 0,
  int con = 1,
  int intel = 3,
  int sab = 1,
  int car = 2,
}) {
  return {
    'FOR': Atributo(nome: 'Força', valor: forca),
    'DES': Atributo(nome: 'Destreza', valor: des),
    'CON': Atributo(nome: 'Constituição', valor: con),
    'INT': Atributo(nome: 'Inteligência', valor: intel),
    'SAB': Atributo(nome: 'Sabedoria', valor: sab),
    'CAR': Atributo(nome: 'Carisma', valor: car),
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Classe arcanista;
  late Classe guerreiro;
  late Classe clerigo;
  late Classe bardo;

  setUpAll(() async {
    await BancoDeClasses.carregar();
    await BancoDePericias.carregarPericias();
    await BancoDePoderes.carregar();
    await BancoDePoderesGerais.carregar();
    await BancoDeMagias.carregarMagias();

    arcanista = BancoDeClasses.getById('arcanista')!;
    guerreiro = BancoDeClasses.getById('guerreiro')!;
    clerigo = BancoDeClasses.getById('clerigo')!;
    bardo = BancoDeClasses.getById('bardo')!;
  });

  group('Regras T20 JdA — Desbloqueio de Círculos e Magias por Nível', () {
    test('Conjuradores plenos desbloqueiam círculos nos níveis 1, 5, 9, 13 e 17', () {
      // Arcanista
      expect(AprendizadoMagiaService.circuloDesbloqueadoNoNivel('arcanista', 1), isNull);
      expect(AprendizadoMagiaService.circuloDesbloqueadoNoNivel('arcanista', 4), isNull);
      expect(AprendizadoMagiaService.circuloDesbloqueadoNoNivel('arcanista', 5), equals(2));
      expect(AprendizadoMagiaService.circuloDesbloqueadoNoNivel('arcanista', 6), isNull);
      expect(AprendizadoMagiaService.circuloDesbloqueadoNoNivel('arcanista', 9), equals(3));
      expect(AprendizadoMagiaService.circuloDesbloqueadoNoNivel('arcanista', 13), equals(4));
      expect(AprendizadoMagiaService.circuloDesbloqueadoNoNivel('arcanista', 17), equals(5));

      // Clérigo
      expect(AprendizadoMagiaService.circuloDesbloqueadoNoNivel('clerigo', 5), equals(2));
      expect(AprendizadoMagiaService.circuloDesbloqueadoNoNivel('clerigo', 9), equals(3));
    });

    test('Conjuradores parciais desbloqueiam círculos nos níveis 1, 6, 10 e 14', () {
      // Bardo
      expect(AprendizadoMagiaService.circuloDesbloqueadoNoNivel('bardo', 5), isNull);
      expect(AprendizadoMagiaService.circuloDesbloqueadoNoNivel('bardo', 6), equals(2));
      expect(AprendizadoMagiaService.circuloDesbloqueadoNoNivel('bardo', 10), equals(3));
      expect(AprendizadoMagiaService.circuloDesbloqueadoNoNivel('bardo', 14), equals(4));
    });

    test('Classes não conjuradoras nunca desbloqueiam círculos', () {
      expect(AprendizadoMagiaService.circuloDesbloqueadoNoNivel('guerreiro', 5), isNull);
      expect(AprendizadoMagiaService.circuloDesbloqueadoNoNivel('guerreiro', 20), isNull);
    });

    test('Cálculo de magias ganhas no nível para caminhos de Arcanista', () {
      // Mago: ganha 1 normal + 1 por novo círculo no Nv. 5
      expect(
        AprendizadoMagiaService.magiasGanhasNoNivel('arcanista', 5, caminhoId: 'mago'),
        equals(2),
      );
      expect(
        AprendizadoMagiaService.magiasGanhasNoNivel('arcanista', 4, caminhoId: 'mago'),
        equals(1),
      );

      // Bruxo: 1 por nível
      expect(
        AprendizadoMagiaService.magiasGanhasNoNivel('arcanista', 5, caminhoId: 'bruxo'),
        equals(1),
      );
    });
  });

  group('Domínio — ResumoLevelUp e Subida Guiada', () {
    test('ResumoLevelUp calcula corretamente a transição de Nv 4 para Nv 5 de Arcanista', () {
      var pAnterior = Personagem(
        nome: 'Mago das Estrelas',
        atributos: _criarAtributos(con: 1, intel: 4),
        classes: [
          ClasseDoPersonagem(
            classeDefinicao: arcanista,
            nivel: 4,
            caminhoEscolhido: arcanista.caminhosNivel1.firstWhere((c) => c.nome == 'Mago'),
            poderesEscolhidos: const [],
          ),
        ],
        magiasConhecidas: ['armadura_arcana', 'dardo_mistico', 'explosao_de_chamas'],
      );

      final pAtualizado = MotorMulticlasseService.adquirirNivelEmClasse(
        personagem: pAnterior,
        classeEscolhida: arcanista,
      );

      final resumo = ResumoLevelUp.calcular(
        anterior: pAnterior,
        atualizado: pAtualizado,
        indiceClasse: 0,
      );

      expect(resumo.nomeClasse, equals('Arcanista'));
      expect(resumo.nivelIndividualClasse, equals(5));
      expect(resumo.nivelTotalPersonagem, equals(5));
      expect(resumo.patamar, equals(PatamarJogo.veterano));
      expect(resumo.novoPatamarAlcancado, isTrue);
      expect(resumo.novoCirculoDesbloqueado, equals(2));
      expect(resumo.tipoMagiaDesbloqueada, equals('arcana'));
      expect(resumo.desbloqueouNovoCirculo, isTrue);
      expect(resumo.temPoderPendente, isTrue);
      expect(resumo.temMagiaPendente, isTrue);
      expect(resumo.deltaPV, equals(3)); // Arcanista pvPorNivel = 2 + Con 1 = 3
      expect(resumo.deltaPM, equals(6)); // Arcanista pmPorNivel = 6
    });

    test('FichaCubit.subirNivelComResumo integra persistência e resumo de Level Up', () async {
      final repo = _FakePersonagemRepository();
      final pInicial = Personagem(
        nome: 'Sir Kaleb',
        atributos: _criarAtributos(forca: 3, con: 2),
        classes: [
          ClasseDoPersonagem(
            classeDefinicao: guerreiro,
            nivel: 1,
            poderesEscolhidos: const [],
          ),
        ],
      );

      final cubit = FichaCubit(
        personagemInicial: pInicial,
        repository: repo,
        debounceDuration: Duration.zero,
      );

      final resumo = await cubit.subirNivelComResumo(0);

      expect(resumo, isNotNull);
      expect(resumo!.nivelIndividualClasse, equals(2));
      expect(resumo.nivelTotalPersonagem, equals(2));
      expect(resumo.deltaPV, equals(7)); // Guerreiro pvPorNivel = 5 + Con 2 = 7
      expect(resumo.deltaPM, equals(3)); // Guerreiro pmPorNivel = 3
      expect(resumo.novoCirculoDesbloqueado, isNull);
      expect(resumo.temPoderPendente, isTrue);
      expect(resumo.temMagiaPendente, isFalse);

      expect(cubit.personagem.nivelPersonagem, equals(2));
      expect(repo.salvo?.nivelPersonagem, equals(2));
    });
  });
}
