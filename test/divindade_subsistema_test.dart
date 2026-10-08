import 'package:flutter_test/flutter_test.dart';
import 'package:t20_creator/domain/entities/atributos.dart';
import 'package:t20_creator/domain/entities/classe.dart';
import 'package:t20_creator/domain/entities/classe_do_personagem.dart';
import 'package:t20_creator/domain/entities/divindade.dart';
import 'package:t20_creator/domain/entities/personagem.dart';
import 'package:t20_creator/domain/services/data_services/call_divindades.dart';
import 'package:t20_creator/domain/services/personagem_storage_service.dart';
import 'package:t20_creator/domain/validators/validador_divindade.dart';
import 'package:t20_creator/presentation/controllers/personagem_cubit.dart';

void main() {
  setUpAll(() async {
    // Garante que o ambiente de teste esteja limpo
  });

  group('Catálogo e Entidade Divindade', () {
    test('BancoDeDivindades deve conter os deuses carregados do JSON', () {
      final deuses = BancoDeDivindades.todas;
      expect(deuses.isNotEmpty, isTrue);
      expect(deuses.length, greaterThanOrEqualTo(6));

      final ids = deuses.map((d) => d.id).toSet();
      expect(ids, containsAll(['khalmyr', 'valkaria', 'wynna', 'allihanna', 'nimb', 'arsenal']));
    });

    test('Cada divindade possui dados válidos e coerentes de T20 JDA', () {
      for (final divindade in BancoDeDivindades.todas) {
        expect(divindade.id.isNotEmpty, isTrue);
        expect(divindade.nome.isNotEmpty, isTrue);
        expect(divindade.titulo.isNotEmpty, isTrue);
        expect(divindade.crencasObjetivos.isNotEmpty, isTrue);
        expect(divindade.simboloSagrado.isNotEmpty, isTrue);
        expect(divindade.armaPreferida.isNotEmpty, isTrue);
        expect(divindade.obrigacoesERestricoes.isNotEmpty, isTrue);
        expect(divindade.poderesConcedidos.length, greaterThanOrEqualTo(3));
      }
    });

    test('Canalização de energia das divindades segue as regras oficiais', () {
      final khalmyr = BancoDeDivindades.getById('khalmyr')!;
      expect(khalmyr.canalizacaoPermitida, equals(CanalizacaoOpcao.apenasPositiva));
      expect(khalmyr.energiaCanalizada, equals(TipoEnergia.positiva));

      final arsenal = BancoDeDivindades.getById('arsenal')!;
      expect(arsenal.canalizacaoPermitida, equals(CanalizacaoOpcao.apenasNegativa));
      expect(arsenal.energiaCanalizada, equals(TipoEnergia.negativa));

      final wynna = BancoDeDivindades.getById('wynna')!;
      expect(wynna.canalizacaoPermitida, equals(CanalizacaoOpcao.qualquer));
      expect(wynna.energiaCanalizada, equals(TipoEnergia.qualquer));
    });
  });

  group('Validador de Elegibilidade de Divindade', () {
    Classe criarClasse(String id, String nome) {
      return Classe(
        idClasse: id,
        nome: nome,
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
        tabelaDeProgressao: const {},
        caminhosDisponiveis: const [],
        habilidadesFixas: const {},
      );
    }

    Personagem criarPersonagemComClasse(String idClasse, String nomeClasse) {
      final cl = criarClasse(idClasse, nomeClasse);
      return Personagem.inicial().copyWith(
        classe_do_personagem: [
          ClasseDoPersonagem(classeDefinicao: cl, nivel: 1),
        ],
      );
    }

    test('Paladino: apenas deuses permitidos em modo estrito (Arsenal, Khalmyr, Valkaria)', () {
      final paladino = criarPersonagemComClasse('paladino', 'Paladino');
      final khalmyr = BancoDeDivindades.getById('khalmyr')!;
      final valkaria = BancoDeDivindades.getById('valkaria')!;
      final arsenal = BancoDeDivindades.getById('arsenal')!;
      final wynna = BancoDeDivindades.getById('wynna')!;
      final allihanna = BancoDeDivindades.getById('allihanna')!;
      final nimb = BancoDeDivindades.getById('nimb')!;

      // Permitidos
      expect(ValidadorDivindade.validarElegibilidade(personagem: paladino, divindade: khalmyr).ehElegivel, isTrue);
      expect(ValidadorDivindade.validarElegibilidade(personagem: paladino, divindade: valkaria).ehElegivel, isTrue);
      expect(ValidadorDivindade.validarElegibilidade(personagem: paladino, divindade: arsenal).ehElegivel, isTrue);

      // Não permitidos
      final resWynna = ValidadorDivindade.validarElegibilidade(personagem: paladino, divindade: wynna);
      expect(resWynna.ehElegivel, isFalse);
      expect(resWynna.motivoIneligibilidade, contains('Paladinos só podem cultuar deuses com tendência compatível'));

      expect(ValidadorDivindade.validarElegibilidade(personagem: paladino, divindade: allihanna).ehElegivel, isFalse);
      expect(ValidadorDivindade.validarElegibilidade(personagem: paladino, divindade: nimb).ehElegivel, isFalse);

      // No modo livre (Homebrew), todos são aceitos
      expect(ValidadorDivindade.validarElegibilidade(personagem: paladino, divindade: wynna, modoEstrito: false).ehElegivel, isTrue);
    });

    test('Druida: apenas Allihanna dentre os atuais em modo estrito', () {
      final druida = criarPersonagemComClasse('druida', 'Druida');
      final allihanna = BancoDeDivindades.getById('allihanna')!;
      final khalmyr = BancoDeDivindades.getById('khalmyr')!;

      expect(ValidadorDivindade.validarElegibilidade(personagem: druida, divindade: allihanna).ehElegivel, isTrue);

      final resKhalmyr = ValidadorDivindade.validarElegibilidade(personagem: druida, divindade: khalmyr);
      expect(resKhalmyr.ehElegivel, isFalse);
      expect(resKhalmyr.motivoIneligibilidade, contains('Druidas só podem cultuar deuses da natureza'));

      // No modo livre, Khalmyr é liberado
      expect(ValidadorDivindade.validarElegibilidade(personagem: druida, divindade: khalmyr, modoEstrito: false).ehElegivel, isTrue);
    });

    test('Identificação correta de Devoto Fiel (Clérigo, Druida, Paladino) vs Devoto Comum', () {
      final clerigo = criarPersonagemComClasse('clerigo', 'Clérigo');
      final druida = criarPersonagemComClasse('druida', 'Druida');
      final paladino = criarPersonagemComClasse('paladino', 'Paladino');
      final guerreiro = criarPersonagemComClasse('guerreiro', 'Guerreiro');
      final ladino = criarPersonagemComClasse('ladino', 'Ladino');

      expect(ValidadorDivindade.ehDevotoFiel(clerigo), isTrue);
      expect(ValidadorDivindade.ehDevotoFiel(druida), isTrue);
      expect(ValidadorDivindade.ehDevotoFiel(paladino), isTrue);

      expect(ValidadorDivindade.ehDevotoFiel(guerreiro), isFalse);
      expect(ValidadorDivindade.ehDevotoFiel(ladino), isFalse);

      expect(ValidadorDivindade.exigeDevocao(paladino), isTrue);
      expect(ValidadorDivindade.exigeDevocao(guerreiro), isFalse);
    });
  });

  group('Regras Mecânicas de Punição Divina', () {
    test('Punição Divina zera PM atual, bloqueia recuperação e desativa poderes concedidos', () {
      final khalmyr = BancoDeDivindades.getById('khalmyr')!;
      var p = Personagem(
        nome: 'Sir Gal',
        atributos: {
          'FOR': const Atributo(nome: 'Força', valor: 2),
          'DES': const Atributo(nome: 'Destreza', valor: 0),
          'CON': const Atributo(nome: 'Constituição', valor: 2),
          'INT': const Atributo(nome: 'Inteligência', valor: 0),
          'SAB': const Atributo(nome: 'Sabedoria', valor: 2),
          'CAR': const Atributo(nome: 'Carisma', valor: 3),
        },
        classes: [
          ClasseDoPersonagem(
            classeDefinicao: Classe(
              idClasse: 'paladino',
              nome: 'Paladino',
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
              tabelaDeProgressao: const {},
              caminhosDisponiveis: const [],
              habilidadesFixas: const {},
            ),
            nivel: 1,
          ),
        ],
        divindade: khalmyr,
        poderesConcedidos: khalmyr.poderesConcedidos.take(2).toList(),
      );

      expect(p.pmTotal, greaterThan(0));
      expect(p.pmAtual, equals(p.pmTotal));
      expect(p.poderesConcedidosAtivos.length, equals(2));
      expect(p.punicaoDivinaAtiva, isFalse);

      // MESTRE APLICA PUNIÇÃO DIVINA
      p = p.aplicarPunicaoDivina();

      expect(p.punicaoDivinaAtiva, isTrue);
      expect(p.pmAtual, equals(0), reason: 'PM deve ser 0 sob punição divina');
      expect(p.poderesConcedidosAtivos, isEmpty, reason: 'Poderes concedidos devem estar desativados');

      // Tenta recuperar PM por descanso/item
      p = p.recuperarPM(10);
      expect(p.pmAtual, equals(0), reason: 'Não pode recuperar PM sob punição divina');

      // Tenta gastar PM
      p = p.gastarPM(2);
      expect(p.pmAtual, equals(0));

      // Tenta restaurar recursos (descanso longo)
      p = p.restaurarRecursos();
      expect(p.pvAtual, equals(p.pvTotal));
      expect(p.pmAtual, equals(0), reason: 'Mesmo restaurando, PM continua 0');

      // MESTRE REVOGA PUNIÇÃO (Penitência cumprida)
      p = p.removerPunicaoDivina();
      expect(p.punicaoDivinaAtiva, isFalse);
      expect(p.poderesConcedidosAtivos.length, equals(2), reason: 'Poderes voltam a ficar ativos');

      // Agora recuperação funciona (limitado a pmTotal)
      p = p.recuperarPM(5);
      expect(p.pmAtual, equals(p.pmTotal));
    });
  });

  group('Reatividade via PersonagemCubit na Etapa 5', () {
    test('Devoto Fiel escolhe 2 poderes concedidos ao invés de 1 no Cubit', () {
      final cubit = PersonagemCubit();
      final khalmyr = BancoDeDivindades.getById('khalmyr')!;

      // Define classe Paladino
      final paladinoClasse = Classe(
        idClasse: 'paladino',
        nome: 'Paladino',
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
        tabelaDeProgressao: const {},
        caminhosDisponiveis: const [],
        habilidadesFixas: const {},
      );

      cubit.selecionarClasse(paladinoClasse);

      // Seleciona Khalmyr
      cubit.selecionarDivindade(khalmyr);

      final state = cubit.state;
      expect(state.divindadeSelecionada?.id, equals('khalmyr'));
      expect(state.poderesConcedidosSelecionados, isEmpty);
      expect(state.cotaPoderesConcedidos, equals(2));
      expect(state.canalizacaoSelecionada, equals(TipoEnergia.positiva));
      // Não concluiu ainda pois precisa de 2 poderes
      expect(state.etapaDivindadeConcluida, isFalse);

      // Seleciona o 1º poder
      cubit.selecionarPoderConcedido(khalmyr.poderesConcedidos[0]);
      expect(cubit.state.poderesConcedidosSelecionados.length, equals(1));
      expect(cubit.state.etapaDivindadeConcluida, isFalse);

      // Seleciona o 2º poder
      cubit.selecionarPoderConcedido(khalmyr.poderesConcedidos[1]);
      expect(cubit.state.poderesConcedidosSelecionados.length, equals(2));
      expect(cubit.state.etapaDivindadeConcluida, isTrue);

      // Consolida
      cubit.consolidarDivindade();
      expect(cubit.state.personagem.divindade?.id, equals('khalmyr'));
      expect(cubit.state.personagem.poderesConcedidos.length, equals(2));
      expect(cubit.state.personagem.canalizacaoEnergia, equals(TipoEnergia.positiva));
    });

    test('Devoto Comum escolhe exatamente 1 poder concedido', () {
      final cubit = PersonagemCubit();
      final khalmyr = BancoDeDivindades.getById('khalmyr')!;

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
        tabelaDeProgressao: const {},
        caminhosDisponiveis: const [],
        habilidadesFixas: const {},
      );

      cubit.selecionarClasse(guerreiroClasse);
      cubit.selecionarDivindade(khalmyr);

      expect(cubit.state.cotaPoderesConcedidos, equals(1));
      expect(cubit.state.poderesConcedidosSelecionados, isEmpty);
      expect(cubit.state.etapaDivindadeConcluida, isFalse);

      cubit.selecionarPoderConcedido(khalmyr.poderesConcedidos[0]);
      expect(cubit.state.poderesConcedidosSelecionados.length, equals(1));
      expect(cubit.state.etapaDivindadeConcluida, isTrue);
    });

    test('Divindade com canalização qualquer exige escolha explícita do usuário', () {
      final cubit = PersonagemCubit();
      final wynna = BancoDeDivindades.getById('wynna')!;

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
        tabelaDeProgressao: const {},
        caminhosDisponiveis: const [],
        habilidadesFixas: const {},
      );

      cubit.selecionarClasse(guerreiroClasse);
      cubit.selecionarDivindade(wynna);

      // Para Guerreiro (devoto comum), ainda não escolheu poder nem canalização
      expect(cubit.state.etapaDivindadeConcluida, isFalse);

      // Escolhe poder
      cubit.selecionarPoderConcedido(wynna.poderesConcedidos.first);
      // Ainda falta canalização
      expect(cubit.state.etapaDivindadeConcluida, isFalse);

      // Escolhe canalização
      cubit.selecionarCanalizacao(TipoEnergia.positiva);
      expect(cubit.state.etapaDivindadeConcluida, isTrue);
    });
  });

  group('Persistência JSON (PersonagemStorageService)', () {
    test('Serialização e desserialização preservam divindade, poderes, canalização e punição divina', () {
      final valkaria = BancoDeDivindades.getById('valkaria')!;
      final pOriginal = Personagem(
        id: 'teste_123',
        nome: 'Aventureira da Ambição',
        atributos: {
          'FOR': const Atributo(nome: 'Força', valor: 1),
          'DES': const Atributo(nome: 'Destreza', valor: 3),
          'CON': const Atributo(nome: 'Constituição', valor: 1),
          'INT': const Atributo(nome: 'Inteligência', valor: 1),
          'SAB': const Atributo(nome: 'Sabedoria', valor: 0),
          'CAR': const Atributo(nome: 'Carisma', valor: 2),
        },
        divindade: valkaria,
        poderesConcedidos: [valkaria.poderesConcedidos[0], valkaria.poderesConcedidos[1]],
        canalizacaoEnergia: TipoEnergia.positiva,
        punicaoDivinaAtiva: true,
      );

      final map = PersonagemStorageService.personagemToMap(pOriginal);
      expect(map['divindadeId'], equals('valkaria'));
      expect(map['canalizacaoEnergia'], equals('positiva'));
      expect(map['punicaoDivinaAtiva'], isTrue);
      expect(map['poderesConcedidosKeys'], equals(['alpinista_social', 'armas_da_ambicao']));

      final pRestaurado = PersonagemStorageService.mapToPersonagem(map);
      expect(pRestaurado.id, equals('teste_123'));
      expect(pRestaurado.divindade?.id, equals('valkaria'));
      expect(pRestaurado.canalizacaoEnergia, equals(TipoEnergia.positiva));
      expect(pRestaurado.punicaoDivinaAtiva, isTrue);
      expect(pRestaurado.pmAtual, equals(0));
      expect(pRestaurado.poderesConcedidos.length, equals(2));
      expect(pRestaurado.poderesConcedidos.map((p) => p.key), containsAll(['alpinista_social', 'armas_da_ambicao']));
    });
  });
}
