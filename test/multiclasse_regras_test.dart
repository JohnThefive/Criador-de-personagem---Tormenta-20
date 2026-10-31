import 'package:flutter_test/flutter_test.dart';
import 'package:t20_creator/domain/entities/personagem/atributos.dart';
import 'package:t20_creator/domain/entities/personagem/classe.dart';
import 'package:t20_creator/domain/entities/personagem/classe_do_personagem.dart';
import 'package:t20_creator/domain/entities/personagem/personagem.dart';
import 'package:t20_creator/domain/entities/personagem/poder.dart';
import 'package:t20_creator/domain/repositories/i_personagem_repository.dart';
import 'package:t20_creator/domain/services/calculo_ficha_service.dart';
import 'package:t20_creator/domain/services/data_services/call_armaduras.dart';
import 'package:t20_creator/domain/services/data_services/call_armas.dart';
import 'package:t20_creator/domain/services/data_services/call_classes.dart';
import 'package:t20_creator/domain/services/data_services/call_magias.dart';
import 'package:t20_creator/domain/services/data_services/call_pericias.dart';
import 'package:t20_creator/domain/services/data_services/call_poderes.dart';
import 'package:t20_creator/domain/services/data_services/call_racas.dart';
import 'package:t20_creator/domain/services/motor_multiclasse_service.dart';
import 'package:t20_creator/domain/services/personagem_storage_service.dart';
import 'package:t20_creator/domain/services/poderes_e_magias/aprendizado_magia_service.dart';
import 'package:t20_creator/domain/services/poderes_e_magias/poder_validador_service.dart';
import 'package:t20_creator/presentation/controllers/ficha_cubit.dart';

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

Map<String, Atributo> _criarAtributos({
  int forca = 0,
  int des = 0,
  int con = 0,
  int intel = 0,
  int sab = 0,
  int car = 0,
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

  late Classe guerreiro;
  late Classe arcanista;
  late Classe paladino;
  late Classe clerigo;

  setUpAll(() async {
    await BancoDePericias.carregarPericias();
    await BancoDeRacas.carregar();
    await BancoDeClasses.carregar();
    await BancoDePoderes.carregar();
    await BancoDePoderesGerais.carregar();
    await BancoDeMagias.carregarMagias();
    await BancoDeArmas.carregar();
    await BancoDeArmaduras.carregar();

    guerreiro = BancoDeClasses.getById('guerreiro')!;
    arcanista = BancoDeClasses.getById('arcanista')!;
    paladino = BancoDeClasses.getById('paladino')!;
    clerigo = BancoDeClasses.getById('clerigo')!;
  });

  group('Requisitos Funcionais e Regras de Negócio de Multiclasse (RF01–RF12 / RN01–RN10)', () {
    test('RF01, RF02, RN01, RN10 e RV04 — Seleção de classe por nível mantém histórico e incrementa apenas a classe escolhida sem perder características anteriores', () {
      var p = Personagem(
        nome: 'Zaled Rayeder',
        atributos: _criarAtributos(con: 1, intel: 3, car: 2),
        classes: [
          ClasseDoPersonagem(
            classeDefinicao: arcanista,
            nivel: 1,
            caminhoEscolhido: arcanista.caminhosNivel1.firstWhere(
              (c) => c.nome == 'Mago',
            ),
          ),
        ],
      );

      // Sobe nível 2 em Arcanista e escolhe um poder de Arcanista
      p = MotorMulticlasseService.adquirirNivelEmClasse(
        personagem: p,
        classeEscolhida: arcanista,
      );
      final poderArcanista = BancoDePoderes.poderesDaClasse('arcanista').first;
      p = p.copyWith(
        classe_do_personagem: [
          p.classes[0].copyWith(poderesEscolhidos: [poderArcanista]),
        ],
      );

      expect(p.nivelPersonagem, equals(2));
      expect(p.nivelNaClasse('arcanista'), equals(2));

      // Nível 3 de personagem: escolhe Paladino (nova classe via multiclasse — RF01)
      p = MotorMulticlasseService.adquirirNivelEmClasse(
        personagem: p,
        classeEscolhida: paladino,
      );

      // RV04: Apenas Paladino recebeu nível 1; Arcanista permaneceu em 2
      expect(p.nivelNaClasse('arcanista'), equals(2));
      expect(p.nivelNaClasse('paladino'), equals(1));
      expect(p.nivelPersonagem, equals(3));

      // RN10: Poderes e caminho anteriormente adquiridos em Arcanista permanecem intactos
      expect(p.classes[0].caminhoEscolhido?.nome, equals('Mago'));
      expect(p.classes[0].poderesEscolhidos, contains(poderArcanista));

      // Nível 4 de personagem: volta a subir Arcanista (Arcanista 3 / Paladino 1)
      p = MotorMulticlasseService.adquirirNivelEmClasse(
        personagem: p,
        classeEscolhida: arcanista,
      );

      expect(p.nivelNaClasse('arcanista'), equals(3));
      expect(p.nivelNaClasse('paladino'), equals(1));
      expect(p.nivelPersonagem, equals(4));

      // RF02: Histórico cronológico registra exatamente a ordem intercalada
      expect(
        p.historicoClassesPorNivel,
        equals(['arcanista', 'arcanista', 'paladino', 'arcanista']),
      );
    });

    test('RF03, RN02 e RV03 — Exemplo oficial: Guerreiro 5 + Arcanista 3 + Paladino 2 = Nível total 10', () {
      final p = Personagem(
        nome: ' Campeão Polivalente ',
        atributos: _criarAtributos(forca: 3, con: 2, intel: 2, car: 2),
        classes: [
          ClasseDoPersonagem(classeDefinicao: guerreiro, nivel: 5),
          ClasseDoPersonagem(classeDefinicao: arcanista, nivel: 3),
          ClasseDoPersonagem(classeDefinicao: paladino, nivel: 2),
        ],
      );

      expect(p.nivelNaClasse('guerreiro'), equals(5));
      expect(p.nivelNaClasse('arcanista'), equals(3));
      expect(p.nivelNaClasse('paladino'), equals(2));
      expect(p.nivelPersonagem, equals(10));
      expect(MotorMulticlasseService.calcularNivelTotal(p), equals(10));

      final validacao = MotorMulticlasseService.validarRegrasMulticlasse(p);
      expect(validacao.valido, isTrue);
    });

    test('RF04, RF05, RN03 e RN08 — Características de classe respeitam exclusivamente o nível individual da classe, nunca o nível total', () {
      // Guerreiro 5 / Paladino 1 -> Nível total 6
      // Paladino recebe Aura Sagrada no nível 3 de Paladino, NÃO no nível total 6!
      final p = Personagem(
        nome: 'Valen',
        atributos: _criarAtributos(forca: 3, car: 2),
        classes: [
          ClasseDoPersonagem(classeDefinicao: guerreiro, nivel: 5),
          ClasseDoPersonagem(classeDefinicao: paladino, nivel: 1),
        ],
      );

      expect(p.nivelPersonagem, equals(6));
      final habsPaladino = p.caracteristicasDaClasse('paladino');
      final habsGuerreiro = p.caracteristicasDaClasse('guerreiro');

      // Paladino Nv. 1 tem apenas habilidades de 1º nível de Paladino (Abençoado, Código do Herói, Golpe Divino)
      expect(
        habsPaladino,
        equals(paladino.tabelaDeProgressao[1]),
      );
      expect(
        habsPaladino.any((h) => h.toLowerCase().contains('aura sagrada')),
        isFalse,
      );
      expect(
        habsPaladino.any((h) => h.toLowerCase().contains('cura pelas mãos')),
        isFalse,
      );

      // Guerreiro Nv. 5 tem habilidades acumuladas dos níveis 1 a 5 de Guerreiro, mas NÃO Ataque Extra (Nv. 6 de Guerreiro)
      expect(
        habsGuerreiro.any((h) => h.toLowerCase().contains('ataque especial')),
        isTrue,
      );
      expect(
        habsGuerreiro.any((h) => h.toLowerCase().contains('durão')),
        isTrue,
      );
      expect(
        habsGuerreiro.any((h) => h.toLowerCase().contains('ataque extra')),
        isFalse,
      );
    });

    test('RF06, RN04 e RV05 — Cálculo de Pontos de Vida na multiclasse concede apenas PV de nível subsequente para novas classes', () {
      // CON = +2
      // Arcanista inicial (pvInicial: 8, pvPorNivel: 2): Nv 1 = 8 + 2 = 10 PV
      // Guerreiro multiclasse (pvInicial: 20, pvPorNivel: 5): Nv 1 subsequente = 5 + 2 = 7 PV (JAMAIS 20 + 2 = 22!)
      // Paladino multiclasse (pvInicial: 20, pvPorNivel: 5): Nv 2 subsequentes = 2 * (5 + 2) = 14 PV
      // Total esperado = 10 + 7 + 14 = 31 PV
      final p = Personagem(
        nome: 'Mago de Batalha',
        atributos: _criarAtributos(con: 2),
        classes: [
          ClasseDoPersonagem(classeDefinicao: arcanista, nivel: 1),
          ClasseDoPersonagem(classeDefinicao: guerreiro, nivel: 1),
          ClasseDoPersonagem(classeDefinicao: paladino, nivel: 2),
        ],
      );

      expect(p.pvTotal, equals(31));
      // Garante que não concedeu pvInicial (20) nem de Guerreiro nem de Paladino
      expect(p.pvTotal, lessThan(20 + 20));
    });

    test('RF07 e RN05 — Cálculo de Pontos de Mana soma os PM provenientes de todas as classes', () {
      // INT = +3, CAR = +2
      // Arcanista (Mago) Nv 3: pmInicial 6 + 2 * 6 (pmPorNivel) + 3 (INT) = 21 PM
      // Paladino Nv 1: 1 * 3 (pmPorNivel) + 2 (CAR - Abençoado) = 5 PM
      // Guerreiro Nv 2: 2 * 3 (pmPorNivel) = 6 PM
      // Total esperado = 21 + 5 + 6 = 32 PM
      final magoPath = arcanista.caminhosNivel1.firstWhere(
        (c) => c.nome == 'Mago',
      );
      final p = Personagem(
        nome: 'Zaled',
        atributos: _criarAtributos(intel: 3, car: 2),
        classes: [
          ClasseDoPersonagem(
            classeDefinicao: arcanista,
            nivel: 3,
            caminhoEscolhido: magoPath,
          ),
          ClasseDoPersonagem(classeDefinicao: paladino, nivel: 1),
          ClasseDoPersonagem(classeDefinicao: guerreiro, nivel: 2),
        ],
      );

      expect(p.pmTotal, equals(32));
    });

    test('RF08, RF09, RN06, RN07 e RV06 — Multiclasse NÃO concede perícias iniciais nem proficiências iniciais automaticamente', () {
      // Classe inicial: Arcanista (Perícias fixas: MISTICISMO, VONTADE; Proficiência: Armas Simples)
      // Nova classe via multiclasse: Guerreiro (Perícias fixas: LUTA, FORTITUDE; Proficiências: Marciais, Armaduras Pesadas, Escudos)
      var p = Personagem(
        nome: 'Elric',
        atributos: _criarAtributos(intel: 3, forca: 2),
        classes: [
          ClasseDoPersonagem(classeDefinicao: arcanista, nivel: 2),
        ],
      );

      p = MotorMulticlasseService.adquirirNivelEmClasse(
        personagem: p,
        classeEscolhida: guerreiro,
      );

      // Perícias da classe inicial continuam treinadas:
      expect(p.ehPericiaTreinada('MISTICISMO'), isTrue);
      expect(p.ehPericiaTreinada('VONTADE'), isTrue);

      // RV06 / RF08: Perícias iniciais de Guerreiro NÃO foram concedidas automaticamente!
      expect(p.ehPericiaTreinada('LUTA'), isFalse);
      expect(p.ehPericiaTreinada('FORTITUDE'), isFalse);

      // RV06 / RF09: Proficiências iniciais de Guerreiro NÃO foram concedidas automaticamente!
      expect(p.temProficienciaSimples, isTrue);
      expect(p.temProficienciaMarcial, isFalse);
      expect(p.temProficienciaArmadurasLeves, isFalse);
      expect(p.temProficienciaArmadurasPesadas, isFalse);
      expect(p.temProficienciaEscudos, isFalse);

      final resumoProfs = CalculoFichaService.extrairProficienciasESentidos(p);
      expect(resumoProfs.proficienciasClasse, equals(['Armas Simples']));
      expect(resumoProfs.proficienciasClasse, isNot(contains('Armas Marciais')));
      expect(
        resumoProfs.proficienciasClasse,
        isNot(contains('Armaduras Pesadas')),
      );

      // Porém, se o jogador adquirir explicitamente via poder Proficiência (proficienciasExtras), funciona normalmente:
      final pComPoderProf = p.copyWith(
        proficienciasExtras: ['Armas Marciais'],
      );
      expect(pComPoderProf.temProficienciaMarcial, isTrue);
    });

    test('RF10 e RN09 — Identifica automaticamente o Patamar de Jogo pelo nível total (Iniciante, Veterano, Campeão, Lenda)', () {
      Personagem criarComNiveis(int nGuerreiro, int nArcanista) {
        return Personagem(
          nome: 'Teste Patamar',
          atributos: _criarAtributos(),
          classes: [
            ClasseDoPersonagem(classeDefinicao: guerreiro, nivel: nGuerreiro),
            if (nArcanista > 0)
              ClasseDoPersonagem(classeDefinicao: arcanista, nivel: nArcanista),
          ],
        );
      }

      // Iniciante: 1–4
      expect(criarComNiveis(1, 0).patamar, equals(PatamarJogo.iniciante));
      expect(criarComNiveis(2, 2).nomePatamar, equals('Iniciante'));

      // Veterano: 5–10
      expect(criarComNiveis(3, 2).patamar, equals(PatamarJogo.veterano));
      expect(criarComNiveis(5, 5).nomePatamar, equals('Veterano'));

      // Campeão: 11–16
      expect(criarComNiveis(6, 5).patamar, equals(PatamarJogo.campeao));
      expect(criarComNiveis(10, 6).nomePatamar, equals('Campeão'));

      // Lenda: 17–20
      expect(criarComNiveis(10, 7).patamar, equals(PatamarJogo.lenda));
      expect(criarComNiveis(12, 8).nomePatamar, equals('Lenda'));
    });

    test('RF11 — Consulta da distribuição de níveis formata exatamente o resumo esperado (Zaled Rayeder)', () {
      final zaled = Personagem(
        nome: 'Zaled Rayeder',
        atributos: _criarAtributos(intel: 3, car: 2),
        classes: [
          ClasseDoPersonagem(classeDefinicao: arcanista, nivel: 3),
          ClasseDoPersonagem(classeDefinicao: paladino, nivel: 1),
        ],
      );

      const textoEsperado =
          'Personagem: Zaled Rayeder\n'
          '\n'
          'Nível total: 4\n'
          'Patamar: Iniciante\n'
          '\n'
          'Classes:\n'
          '- Arcanista: 3\n'
          '- Paladino: 1';

      expect(zaled.resumoDistribuicaoClassesTexto, equals(textoEsperado));
    });

    test('RF12 — Consulta de progressão preserva ordem cronológica intercalada e distingue nível global vs nível da classe (incluindo persistência)', () {
      var zaled = Personagem(
        nome: 'Zaled Rayeder',
        atributos: _criarAtributos(con: 1, intel: 3, car: 2),
        classes: [
          ClasseDoPersonagem(
            classeDefinicao: arcanista,
            nivel: 1,
            caminhoEscolhido: arcanista.caminhosNivel1.firstWhere(
              (c) => c.nome == 'Mago',
            ),
          ),
        ],
      );

      // Nv 2 global -> Paladino 1
      zaled = MotorMulticlasseService.adquirirNivelEmClasse(
        personagem: zaled,
        classeEscolhida: paladino,
      );
      // Nv 3 global -> Arcanista 2
      zaled = MotorMulticlasseService.adquirirNivelEmClasse(
        personagem: zaled,
        classeEscolhida: arcanista,
      );
      // Nv 4 global -> Arcanista 3
      zaled = MotorMulticlasseService.adquirirNivelEmClasse(
        personagem: zaled,
        classeEscolhida: arcanista,
      );
      // Nv 5 global -> Paladino 2 (Alcança Patamar Veterano!)
      zaled = MotorMulticlasseService.adquirirNivelEmClasse(
        personagem: zaled,
        classeEscolhida: paladino,
      );

      // Serializa e desserializa para garantir persistência integral de RF02/RF12
      final jsonMap = PersonagemStorageService.personagemToMap(zaled);
      final restaurado = PersonagemStorageService.mapToPersonagem(jsonMap);

      final trilha = CalculoFichaService.gerarTrilhaProgressao(restaurado);
      expect(trilha.length, equals(5));

      // Nível 1 do Personagem: Arcanista 1 (Inicial, PV = 8 + 1 = 9)
      expect(trilha[0].nivelPersonagem, equals(1));
      expect(trilha[0].nomeClasse, equals('Arcanista'));
      expect(trilha[0].nivelNaClasse, equals(1));
      expect(trilha[0].ehClasseInicial, isTrue);
      expect(trilha[0].pvAdquiridos, equals(9));

      // Nível 2 do Personagem: Paladino 1 (Multiclasse, PV subsequente = 5 + 1 = 6)
      expect(trilha[1].nivelPersonagem, equals(2));
      expect(trilha[1].nomeClasse, equals('Paladino'));
      expect(trilha[1].nivelNaClasse, equals(1));
      expect(trilha[1].ehAquisicaoNovaMulticlasse, isTrue);
      expect(trilha[1].pvAdquiridos, equals(6));

      // Nível 5 do Personagem: Paladino 2 (Novo Patamar Veterano, Cura pelas Mãos)
      expect(trilha[4].nivelPersonagem, equals(5));
      expect(trilha[4].patamar, equals(PatamarJogo.veterano));
      expect(trilha[4].novoPatamarAlcancado, isTrue);
      expect(trilha[4].nomeClasse, equals('Paladino'));
      expect(trilha[4].nivelNaClasse, equals(2));
      expect(
        trilha[4].habilidadesDeClasse.any(
          (h) => h.toLowerCase().contains('cura pelas mãos'),
        ),
        isTrue,
      );
    });
  });

  group('Suite de Regras de Validação Obrigatórias (RV01–RV07)', () {
    test('RV01 — O personagem não pode ultrapassar o nível máximo 20 (domínio e FichaCubit)', () async {
      final pNivel20 = Personagem(
        nome: 'Lenda Máxima',
        atributos: _criarAtributos(forca: 4, con: 3),
        classes: [
          ClasseDoPersonagem(classeDefinicao: guerreiro, nivel: 12),
          ClasseDoPersonagem(classeDefinicao: paladino, nivel: 8),
        ],
      );

      expect(pNivel20.nivelPersonagem, equals(20));

      // Domínio lança ExcecaoValidacaoMulticlasse com código RV01
      expect(
        () => MotorMulticlasseService.adquirirNivelEmClasse(
          personagem: pNivel20,
          classeEscolhida: arcanista,
        ),
        throwsA(
          isA<ExcecaoValidacaoMulticlasse>().having(
            (e) => e.codigoRegra,
            'codigoRegra',
            equals('RV01'),
          ),
        ),
      );

      // FichaCubit bloqueia tanto subir classe existente quanto adicionar nova multiclasse
      final cubit = FichaCubit(
        personagemInicial: pNivel20,
        repository: _MemoriaPersonagemRepository(),
      );
      expect(await cubit.adicionarMulticlasse(arcanista), isFalse);
      expect(await cubit.alterarNivelClasse(0, 1), isFalse);
      expect(cubit.personagem.nivelPersonagem, equals(20));
      expect(cubit.state.mensagemErro, isNotNull);
    });

    test('RV02 — O nível individual de uma classe registrada deve ser inteiro positivo (>= 1)', () {
      expect(
        () => ClasseDoPersonagem(classeDefinicao: guerreiro, nivel: 0),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => ClasseDoPersonagem(classeDefinicao: arcanista, nivel: -2),
        throwsA(isA<ArgumentError>()),
      );

      // Ao remover o único nível de uma classe secundária, ela é removida da lista para nunca ficar com nível 0
      var p = Personagem(
        nome: 'Teste RV02',
        atributos: _criarAtributos(),
        classes: [
          ClasseDoPersonagem(classeDefinicao: guerreiro, nivel: 2),
          ClasseDoPersonagem(classeDefinicao: arcanista, nivel: 1),
        ],
      );
      p = MotorMulticlasseService.removerNivelDeClasse(
        personagem: p,
        indiceClasse: 1,
      );
      expect(p.classes.length, equals(1));
      expect(p.classes.every((c) => c.nivel >= 1), isTrue);
    });

    test('RV03 — A soma dos níveis individuais deve sempre corresponder ao nível total do personagem', () async {
      final cubit = FichaCubit(
        personagemInicial: Personagem(
          nome: 'Teste RV03',
          atributos: _criarAtributos(),
          classes: [ClasseDoPersonagem(classeDefinicao: guerreiro, nivel: 1)],
        ),
        repository: _MemoriaPersonagemRepository(),
      );

      await cubit.subirNivelSelecionandoClasse(arcanista);
      await cubit.subirNivelSelecionandoClasse(paladino);
      await cubit.subirNivelSelecionandoClasse(arcanista);
      await cubit.alterarNivelClasse(0, 2); // Guerreiro +2 -> 3

      final p = cubit.personagem;
      final somaIndividual = p.classes.fold<int>(0, (s, c) => s + c.nivel);
      expect(p.nivelPersonagem, equals(somaIndividual));
      expect(p.nivelPersonagem, equals(6));
      expect(MotorMulticlasseService.validarRegrasMulticlasse(p).valido, isTrue);
    });

    test('RV04 — Ao adquirir nível, apenas a classe selecionada deve ser incrementada', () {
      var p = Personagem(
        nome: 'Teste RV04',
        atributos: _criarAtributos(),
        classes: [
          ClasseDoPersonagem(classeDefinicao: guerreiro, nivel: 3),
          ClasseDoPersonagem(classeDefinicao: arcanista, nivel: 2),
          ClasseDoPersonagem(classeDefinicao: paladino, nivel: 1),
        ],
      );

      p = MotorMulticlasseService.adquirirNivelEmClasse(
        personagem: p,
        classeEscolhida: arcanista,
      );

      expect(p.classes[0].nivel, equals(3));
      expect(p.classes[1].nivel, equals(3));
      expect(p.classes[2].nivel, equals(1));
    });

    test('RV05 — Ao adquirir nova classe, não podem ser aplicados PV de primeiro nível', () {
      final inicial = Personagem(
        nome: 'Teste RV05',
        atributos: _criarAtributos(con: 1),
        classes: [
          // Arcanista Nv 1: 8 + 1 = 9 PV
          ClasseDoPersonagem(classeDefinicao: arcanista, nivel: 1),
        ],
      );
      expect(inicial.pvTotal, equals(9));

      // Adquire Guerreiro Nv 1 (pvInicial = 20, pvPorNivel = 5)
      // Ganho deve ser 5 + 1 = 6 PV (total 15), JAMAIS 20 + 1 = 21 PV (total 30)!
      final comGuerreiro = MotorMulticlasseService.adquirirNivelEmClasse(
        personagem: inicial,
        classeEscolhida: guerreiro,
      );
      expect(comGuerreiro.pvTotal - inicial.pvTotal, equals(6));
      expect(comGuerreiro.pvTotal, equals(15));
    });

    test('RV06 — O sistema não pode conceder perícias e proficiências iniciais automaticamente na multiclasse', () async {
      final cubit = FichaCubit(
        personagemInicial: Personagem(
          nome: 'Teste RV06',
          atributos: _criarAtributos(intel: 2),
          classes: [ClasseDoPersonagem(classeDefinicao: arcanista, nivel: 1)],
        ),
        repository: _MemoriaPersonagemRepository(),
      );

      await cubit.adicionarMulticlasse(paladino);
      final p = cubit.personagem;

      // Paladino tem proficiência em Armas Marciais, Armaduras Pesadas e Escudos, além de Luta/Vontade
      expect(p.temProficienciaMarcial, isFalse);
      expect(p.temProficienciaArmadurasPesadas, isFalse);
      expect(p.temProficienciaEscudos, isFalse);
      expect(p.ehPericiaTreinada('LUTA'), isFalse);
    });

    test('RV07 — Impede que poderes, habilidades ou círculos de magia de uma classe sejam desbloqueados usando o nível de outra classe', () async {
      // Personagem: Arcanista 5 / Guerreiro 1 / Clérigo 1 -> Nível total = 7
      final p = Personagem(
        nome: 'Teste RV07',
        atributos: _criarAtributos(forca: 2, intel: 3, sab: 2),
        classes: [
          ClasseDoPersonagem(classeDefinicao: arcanista, nivel: 5),
          ClasseDoPersonagem(classeDefinicao: guerreiro, nivel: 1),
          ClasseDoPersonagem(classeDefinicao: clerigo, nivel: 1),
        ],
      );

      // 1) Poder de Guerreiro que exige nível >= 3 de Guerreiro
      // Mesmo tendo Nível Total 7, o nível individual em Guerreiro é 1 -> BLOQUEADO!
      final poderesGuerreiroNvAlto = BancoDePoderes.poderesDaClasse(
        'guerreiro',
      ).where((pod) => pod.nivelMinimo >= 3).toList();
      expect(poderesGuerreiroNvAlto, isNotEmpty);
      final poderAltoGuerreiro = poderesGuerreiroNvAlto.first;

      final resNivelInsuficiente = PoderValidadorService.validar(
        poder: poderAltoGuerreiro,
        personagem: p,
        classeDoPersonagem: p.classes[1], // Guerreiro Nv 1
      );
      expect(resNivelInsuficiente.ehElegivel, isFalse);

      // 2) Tentar escolher um poder exclusivo de Guerreiro usando o slot de evolução de Arcanista (Nv 5) -> BLOQUEADO!
      final poderGuerreiroNvBaixo = BancoDePoderes.poderesDaClasse('guerreiro')
          .firstWhere(
            (pod) =>
                pod.nivelMinimo <= 2 &&
                pod.poderesExigidos.isEmpty &&
                pod.atributosExigidos.isEmpty &&
                pod.periciasExigidas.isEmpty,
          );

      final resClasseCruzada = PoderValidadorService.validar(
        poder: poderGuerreiroNvBaixo,
        personagem: p,
        classeDoPersonagem: p.classes[0], // Slot de Arcanista!
      );
      expect(resClasseCruzada.ehElegivel, isFalse);
      expect(
        resClasseCruzada.pendencias.any(
          (item) => item.descricao.toLowerCase().contains('exclusivo'),
        ),
        isTrue,
      );

      // 3) Auditoria de estado RV07 detecta poder de classe com nível superior ao nível individual
      final invalido = Personagem(
        nome: 'Invalido RV07',
        atributos: _criarAtributos(),
        classes: [
          ClasseDoPersonagem(classeDefinicao: arcanista, nivel: 5),
          ClasseDoPersonagem(
            classeDefinicao: guerreiro,
            nivel: 2,
            poderesEscolhidos: [
              const Poder(
                key: 'TESTE_NV6',
                nome: 'Poder Nv 6',
                descricao: 'Exige nível 6 na classe',
                nivelMinimo: 6,
              ),
            ],
          ),
        ],
      );
      final auditoria = MotorMulticlasseService.validarRegrasMulticlasse(
        invalido,
      );
      expect(auditoria.valido, isFalse);
      expect(
        auditoria.violacoes.any((v) => v.codigoRegra == 'RV07'),
        isTrue,
      );

      // 4) Magias por tradição (Arcanista 5 libera 2º círculo ARCANO, mas Clérigo 1 só libera 1º círculo DIVINO!)
      expect(
        AprendizadoMagiaService.obterCirculoMaximoPorTipoMagia(p, 'arcana'),
        equals(2),
      );
      expect(
        AprendizadoMagiaService.obterCirculoMaximoPorTipoMagia(p, 'divina'),
        equals(1),
      );

      final magiaArcana2 = BancoDeMagias.todas.firstWhere(
        (m) => m.circulo == 2 && m.tipo.toLowerCase() == 'arcana',
      );
      final magiaDivina2 = BancoDeMagias.todas.firstWhere(
        (m) => m.circulo == 2 && m.tipo.toLowerCase() == 'divina',
      );

      expect(
        AprendizadoMagiaService.podeAprenderMagiaNoPersonagem(p, magiaArcana2),
        isTrue,
      );
      expect(
        AprendizadoMagiaService.podeAprenderMagiaNoPersonagem(p, magiaDivina2),
        isFalse,
      );

      final cubit = FichaCubit(
        personagemInicial: p,
        repository: _MemoriaPersonagemRepository(),
      );
      expect(
        await cubit.adicionarMagiaConhecida(
          magiaArcana2.id,
          validarCirculoClasse: true,
        ),
        isTrue,
      );
      expect(
        await cubit.adicionarMagiaConhecida(
          magiaDivina2.id,
          validarCirculoClasse: true,
        ),
        isFalse,
      );
      expect(cubit.state.mensagemErro, contains('RV07'));
    });
  });
}
