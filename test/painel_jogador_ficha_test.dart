import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:t20_creator/domain/entities/equipamento/arma.dart';
import 'package:t20_creator/domain/entities/equipamento/item_vestido.dart';
import 'package:t20_creator/domain/entities/equipamento/protecao.dart';
import 'package:t20_creator/domain/entities/magia/magia.dart';
import 'package:t20_creator/domain/entities/personagem/atributos.dart';
import 'package:t20_creator/domain/entities/personagem/classe.dart';
import 'package:t20_creator/domain/entities/personagem/classe_do_personagem.dart';
import 'package:t20_creator/domain/entities/personagem/efeito_temporario.dart';
import 'package:t20_creator/domain/entities/personagem/pericias.dart';
import 'package:t20_creator/domain/entities/personagem/personagem.dart';
import 'package:t20_creator/domain/entities/personagem/proficiencias.dart';
import 'package:t20_creator/domain/entities/personagem/raca.dart';
import 'package:t20_creator/domain/repositories/i_personagem_repository.dart';
import 'package:t20_creator/domain/services/calculo_ficha_service.dart';
import 'package:t20_creator/domain/services/data_services/call_magias.dart';
import 'package:t20_creator/domain/services/data_services/call_pericias.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:t20_creator/domain/services/personagem_storage_service.dart';
import 'package:t20_creator/presentation/controllers/ficha_cubit.dart';
import 'package:t20_creator/presentation/screens/ficha/painel_jogador_screen.dart';

class FakePersonagemRepository implements IPersonagemRepository {
  Personagem? salvo;

  @override
  Future<void> salvar(Personagem p) async {
    salvo = p;
  }

  @override
  Future<List<Personagem>> obterTodos() async => salvo != null ? [salvo!] : [];

  @override
  Future<Personagem?> obterPorId(String id) async =>
      salvo?.id == id ? salvo : null;

  @override
  Future<void> excluir(String id) async {
    if (salvo?.id == id) salvo = null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const acro = Pericia(
    key: 'ACROBACIA',
    label: 'Acrobacia',
    atributoChave: 'DES',
    somenteTreinada: false,
    penalidadeArmadura: true,
    descricao: 'Equilíbrio e piruetas.',
    acoesExecutadas: 'Amortecer queda, equilibrar-se',
  );

  const luta = Pericia(
    key: 'LUTA',
    label: 'Luta',
    atributoChave: 'FOR',
    somenteTreinada: false,
    penalidadeArmadura: false,
    descricao: 'Ataques corpo a corpo.',
    acoesExecutadas: 'Atacar corpo a corpo, agarrar',
  );

  const pontaria = Pericia(
    key: 'PONTARIA',
    label: 'Pontaria',
    atributoChave: 'DES',
    somenteTreinada: false,
    penalidadeArmadura: false,
    descricao: 'Ataques à distância.',
    acoesExecutadas: 'Disparar ou arremessar',
  );

  const iniciativa = Pericia(
    key: 'INICIATIVA',
    label: 'Iniciativa',
    atributoChave: 'DES',
    somenteTreinada: false,
    penalidadeArmadura: false,
    descricao: 'Reação em combate.',
    acoesExecutadas: 'Determinar ordem de turno',
  );

  const misticismo = Pericia(
    key: 'MISTICISMO',
    label: 'Misticismo',
    atributoChave: 'INT',
    somenteTreinada: true,
    penalidadeArmadura: false,
    descricao: 'Conhecimento arcano.',
    acoesExecutadas: 'Identificar magias',
  );

  const vontade = Pericia(
    key: 'VONTADE',
    label: 'Vontade',
    atributoChave: 'SAB',
    somenteTreinada: false,
    penalidadeArmadura: false,
    descricao: 'Determinação e resistência mental.',
    acoesExecutadas: 'Resistir a efeitos mentais',
  );

  const diplomacia = Pericia(
    key: 'DIPLOMACIA',
    label: 'Diplomacia',
    atributoChave: 'CAR',
    somenteTreinada: false,
    penalidadeArmadura: false,
    descricao: 'Persuasão e etiqueta.',
    acoesExecutadas: 'Mudar atitude, negociar',
  );

  const atletismo = Pericia(
    key: 'ATLETISMO',
    label: 'Atletismo',
    atributoChave: 'FOR',
    somenteTreinada: false,
    penalidadeArmadura: true,
    descricao: 'Capacidade física bruta.',
    acoesExecutadas: 'Correr, saltar, escalar',
  );

  setUp(() {
    BancoDePericias.carregarParaTestes([
      acro,
      luta,
      pontaria,
      iniciativa,
      misticismo,
      vontade,
      diplomacia,
      atletismo,
    ]);
  });

  group('CalculoFichaService - Domínio de Perícias e Rolagem 1 Toque', () {
    test('detalharPericia decompõe ½ nível, atributo, treino e penalidade de armadura', () {
      final p = Personagem.inicial().copyWith(
        classe_do_personagem: [
          ClasseDoPersonagem(
            classeDefinicao: const Classe(
              idClasse: 'guerreiro',
              nome: 'Guerreiro',
              pvInicial: 20,
              pvPorNivel: 5,
              pmInicial: 3,
              pmPorNivel: 3,
              proficiencias: [
                TipoProficiencia.armadurasPesadas,
                TipoProficiencia.armasMarciais,
              ],
              periciasFixas: ['LUTA', 'FORTITUDE'],
              periciasOpcoes: ['INICIATIVA', 'ACROBACIA'],
              qtdPericiasEscolha: 2,
              descricaoclasse: 'Mestre combatente',
            ),
            nivel: 4, // ½ nível = 2, bônus treino = +2
          ),
        ],
        atributos: {
          'FOR': const Atributo(nome: 'FOR', valor: 3),
          'DES': const Atributo(nome: 'DES', valor: 2),
          'CON': const Atributo(nome: 'CON', valor: 2),
          'INT': const Atributo(nome: 'INT', valor: 0),
          'SAB': const Atributo(nome: 'SAB', valor: 0),
          'CAR': const Atributo(nome: 'CAR', valor: 0),
        },
        periciasTreinadas: ['ACROBACIA', 'LUTA'],
        outrosBonusPericias: {'ACROBACIA': 1},
        armaduraEquipada: const Protecao(
          key: 'armadura_completa',
          nome: 'Armadura Completa',
          descricao: 'Pesada',
          precoEmTibares: 1000,
          bonusDefesa: 8,
          penalidadeArmadura: 5,
          espacos: 5,
          tipo: TipoProtecao.armaduraPesada,
        ),
      );

      final compAcro = CalculoFichaService.detalharPericia(p, 'ACROBACIA');
      expect(compAcro.metadeNivel, equals(2));
      expect(compAcro.modAtributo, equals(2));
      expect(compAcro.ehTreinada, isTrue);
      expect(compAcro.bonusTreino, equals(2));
      expect(compAcro.bonusOutros, equals(1));
      expect(compAcro.penalidadeArmaduraAplicada, equals(5));
      // Total = 2 + 2 + 2 + 1 - 5 = 2
      expect(compAcro.total, equals(2));
      expect(compAcro.parcelas.length, equals(5));

      // Teste de rolagem com dado simulado fixo (15)
      final rolagem = CalculoFichaService.rolarPericia(
        p,
        'ACROBACIA',
        valorDadoFixoParaTeste: 15,
      );
      expect(rolagem.somaDados, equals(15));
      expect(rolagem.totalModificadores, equals(2));
      expect(rolagem.totalFinal, equals(17));
      expect(rolagem.ehCriticoNatural, isFalse);
    });

    test('rolarPericia detecta 20 natural como crítico e 1 natural como falha', () {
      final p = Personagem.inicial();
      final crit = CalculoFichaService.rolarPericia(
        p,
        'LUTA',
        valorDadoFixoParaTeste: 20,
      );
      expect(crit.ehCriticoNatural, isTrue);
      expect(crit.ehFalhaCriticaNatural, isFalse);

      final falha = CalculoFichaService.rolarPericia(
        p,
        'LUTA',
        valorDadoFixoParaTeste: 1,
      );
      expect(falha.ehFalhaCriticaNatural, isTrue);
      expect(falha.ehCriticoNatural, isFalse);
    });

    test('agruparPericiasPorAtributo ordena por atributo e alfabeticamente', () {
      final p = Personagem.inicial();
      final grupos = CalculoFichaService.agruparPericiasPorAtributo(p);

      expect(grupos.isNotEmpty, isTrue);
      final grupoDes = grupos.firstWhere((g) => g.siglaAtributo == 'DES');
      final nomes = grupoDes.pericias.map((cp) => cp.pericia.label).toList();
      // Acrobacia antes de Iniciativa, antes de Pontaria
      expect(nomes, containsAllInOrder(['Acrobacia', 'Iniciativa', 'Pontaria']));
    });

    test('agruparPericiasPorAtributo com penalidadeArmaduraCustom repassa penalidade customizada', () {
      final p = Personagem.inicial();
      final grupos = CalculoFichaService.agruparPericiasPorAtributo(
        p,
        penalidadeArmaduraCustom: 5,
      );

      final grupoDes = grupos.firstWhere((g) => g.siglaAtributo == 'DES');
      final acro = grupoDes.pericias.firstWhere((cp) => cp.pericia.key == 'ACROBACIA');
      expect(acro.penalidadeArmaduraAplicada, equals(5));
      expect(acro.total, equals(-5)); // ½ nível 0 + DES 0 - penalidade 5 = -5
    });

    test('Bônus raciais inatos (Elfo: Graça de Glórienn e Sentidos Élficos) são passivos e aplicados automaticamente', () {
      final elfo = Personagem.inicial().copyWith(
        raca: const Raca(
          id: 'elfo',
          nome: 'Elfo',
          descricaoRaca: 'Elfos são graciosos.',
          icone: 'player',
          modificadores: {'INT': 2, 'DES': 1, 'CON': -1},
          habilidadesRaca: {
            'Graça de Glórienn': 'Seu deslocamento é 12m em vez de 9m.',
            'Sangue Mágico': 'Você recebe +1 ponto de mana por nível.',
            'Sentidos Élficos': 'Você possui visão na penumbra e recebe +2 em testes de Misticismo e Percepção.',
          },
        ),
      );

      // Deslocamento inato de 12m (8 quadrados)
      expect(elfo.deslocamentoBaseMetros, equals(12));
      expect(elfo.deslocamentoEfetivoMetros, equals(12));
      final resumoSentidos = CalculoFichaService.extrairProficienciasESentidos(elfo);
      expect(resumoSentidos.deslocamentoBase, contains('12m'));

      // Sentidos Élficos: +2 inato em Misticismo
      expect(elfo.bonusRacialPericia('MISTICISMO'), equals(2));
      final compMisticismo = CalculoFichaService.detalharPericia(elfo, 'MISTICISMO');
      expect(compMisticismo.bonusRacial, equals(2));
      expect(compMisticismo.parcelas.any((p) => p.rotulo == 'Racial' && p.valor == 2), isTrue);
    });

    test('Bônus inato de Defesa (Minotauro: Couro Rígido) soma diretamente na Defesa sem custo de PM', () {
      final minotauro = Personagem.inicial().copyWith(
        raca: const Raca(
          id: 'minotauro',
          nome: 'Minotauro',
          descricaoRaca: 'Guerreiros de chifres.',
          icone: 'player',
          modificadores: {'FOR': 2, 'CON': 1, 'SAB': -1},
          habilidadesRaca: {
            'Couro Rígido': 'Sua pele é dura como a de um touro. Você recebe +1 na Defesa.',
          },
        ),
      );

      expect(minotauro.bonusRacialDefesa, equals(1));
      final def = CalculoFichaService.detalharDefesaERd(minotauro);
      expect(def.bonusRacialDefesa, equals(1));
      expect(def.defesaFinal, equals(11)); // 10 base + 0 DES + 1 Racial
      expect(def.parcelasDefesa.any((p) => p.rotulo == 'Racial' && p.valor == 1), isTrue);
    });
  });

  group('CalculoFichaService - Defesa, RD, Itens Vestidos e Tibares', () {
    test('Defesa desconsidera DES quando usa armadura pesada e aplica efeitos temporários', () {
      final p = Personagem.inicial().copyWith(
        atributos: {
          'FOR': const Atributo(nome: 'FOR', valor: 0),
          'DES': const Atributo(nome: 'DES', valor: 3),
          'CON': const Atributo(nome: 'CON', valor: 0),
          'INT': const Atributo(nome: 'INT', valor: 0),
          'SAB': const Atributo(nome: 'SAB', valor: 0),
          'CAR': const Atributo(nome: 'CAR', valor: 0),
        },
        armaduraEquipada: const Protecao(
          key: 'cota_malha',
          nome: 'Cota de Malha',
          descricao: 'Pesada',
          precoEmTibares: 150,
          bonusDefesa: 5,
          penalidadeArmadura: 2,
          espacos: 4,
          tipo: TipoProtecao.armaduraPesada,
        ),
        escudoEquipado: const Protecao(
          key: 'escudo_pesado',
          nome: 'Escudo Pesado',
          descricao: 'Escudo',
          precoEmTibares: 30,
          bonusDefesa: 2,
          penalidadeArmadura: 2,
          espacos: 2,
          tipo: TipoProtecao.escudoPesado,
        ),
        rdPadrao: 2,
        outrosBonusDefesa: 1,
        efeitosTemporarios: [
          const EfeitoTemporario(
            id: 'buff_1',
            nome: 'Escudo da Fé',
            tipo: TipoEfeitoTemporario.buff,
            modDefesa: 2,
            ativo: true,
          ),
          const EfeitoTemporario(
            id: 'buff_inativo',
            nome: 'Pele de Pedra',
            tipo: TipoEfeitoTemporario.buff,
            modRd: 5,
            ativo: false,
          ),
        ],
      );

      final def = CalculoFichaService.detalharDefesaERd(p);
      expect(def.destrezaLimitadaPorArmaduraPesada, isTrue);
      expect(def.modDestrezaAplicado, equals(0));
      // Defesa = 10 (base) + 0 (DES pesada) + 5 (armadura) + 2 (escudo) + 1 (outros) + 2 (efeito) = 20
      expect(def.defesaFinal, equals(20));
      // RD Total = 2 (padrão) + 0 (efeito inativo) = 2
      expect(def.rdTotal, equals(2));
    });

    test('4 Slots de itens vestidos e 3 denominações de Tibares', () {
      final p = Personagem.inicial().copyWith(
        armaduraEquipada: const Protecao(
          key: 'armadura_couro',
          nome: 'Armadura de Couro',
          descricao: 'Leve',
          precoEmTibares: 20,
          bonusDefesa: 2,
          penalidadeArmadura: 0,
          espacos: 2,
          tipo: TipoProtecao.armaduraLeve,
        ),
        itensVestidosExtras: [
          const ItemVestido(
            slotIndex: 1,
            nome: 'Capa da Noite',
            beneficio: '+1 Furtividade',
            espacos: 1,
          ),
          const ItemVestido(
            slotIndex: 2,
            nome: 'Botas Aladas',
            beneficio: 'Deslocamento',
            espacos: 1,
          ),
        ],
        tibaresCobre: 45,
        tibares: 120,
        tibaresOuro: 15,
      );

      expect(p.armaduraEquipada?.nome, equals('Armadura de Couro'));
      expect(p.itensVestidosExtras.length, equals(2));
      expect(p.patrimonioTotalTibares, equals(45 * 0.1 + 120 + 15 * 10));
    });
  });

  group('CalculoFichaService - Magias e Gasto Seguro de PM', () {
    test('calcularCustoMagia e tentarGastarPM validam círculos e impedem PM negativo', () {
      const magia1 = Magia(
        id: 'curar_ferimentos',
        nome: 'Curar Ferimentos',
        tipo: 'divina',
        circulo: 1,
        escola: 'evocacao',
        execucao: ExecucaoMagia(tipo: 'padrao'),
        alcance: AlcanceMagia(tipo: 'toque'),
        efeito: EfeitoMagia(tipo: 'alvo'),
        duracao: DuracaoMagia(tipo: 'instantanea'),
        descricao: 'Restaura vida.',
        aprimoramentos: [
          AprimoramentoMagia(
            id: 'apr_1',
            descricao: 'Aumenta a cura em +2d8+2',
            custoAdicionalPM: 2,
          ),
        ],
      );

      // Custo base de 1º círculo = 1 PM
      expect(CalculoFichaService.calcularCustoMagia(magia1, const []), equals(1));
      // Custo com aprimoramento = 1 + 2 = 3 PM
      expect(
        CalculoFichaService.calcularCustoMagia(magia1, [magia1.aprimoramentos[0]]),
        equals(3),
      );

      final pComPM = Personagem.inicial().copyWith(
        classe_do_personagem: [
          ClasseDoPersonagem(
            classeDefinicao: const Classe(
              idClasse: 'arcanista',
              nome: 'Arcanista',
              pvInicial: 8,
              pvPorNivel: 2,
              pmInicial: 6,
              pmPorNivel: 6,
              proficiencias: [],
              periciasFixas: [],
              periciasOpcoes: [],
              qtdPericiasEscolha: 0,
              descricaoclasse: '',
            ),
            nivel: 1,
          ),
        ],
        pmAtual: 2,
      );

      // Gasto possível (1 PM)
      final resSucesso = CalculoFichaService.tentarGastarPM(pComPM, 1);
      expect(resSucesso.sucesso, isTrue);
      expect(resSucesso.personagemAtualizado.pmAtual, equals(1));

      // Gasto além do disponível (3 PM) -> Deve ser bloqueado e manter PM
      final resFalha = CalculoFichaService.tentarGastarPM(pComPM, 3);
      expect(resFalha.sucesso, isFalse);
      expect(resFalha.personagemAtualizado.pmAtual, equals(2));
      expect(resFalha.mensagemErro, contains('PM insuficiente'));
    });

    test('Punição divina bloqueia totalmente o gasto de PM', () {
      final pPunido = Personagem.inicial().copyWith(
        pmAtual: 5,
        punicaoDivinaAtiva: true,
      );
      final res = CalculoFichaService.tentarGastarPM(pPunido, 1);
      expect(res.sucesso, isFalse);
      expect(res.mensagemErro, contains('Punição Divina'));
    });
  });

  group('CalculoFichaService - Adiantamento de Domínio para Combate Futuro', () {
    test('prepararPreviewAtaqueArma calcula ataque, penalidade e crítico corretamente', () {
      const espadaLonga = Arma(
        key: 'espada_longa',
        nome: 'Espada Longa',
        descricao: 'Arma marcial de uma mão',
        proficiencia: ProficienciaArma.marcial,
        proposito: PropositoArma.corpoACorpo,
        empunhadura: EmpunhaduraArma.umaMao,
        dano: '1d8',
        margemAmeaca: 19,
        multiplicadorCritico: 2,
        tipoDano: TipoDanoArma.corte,
      );

      final p = Personagem.inicial().copyWith(
        classe_do_personagem: [
          ClasseDoPersonagem(
            classeDefinicao: const Classe(
              idClasse: 'guerreiro',
              nome: 'Guerreiro',
              pvInicial: 20,
              pvPorNivel: 5,
              pmInicial: 3,
              pmPorNivel: 3,
              proficiencias: [
                TipoProficiencia.armasSimples,
                TipoProficiencia.armasMarciais,
              ],
              periciasFixas: ['LUTA'],
              periciasOpcoes: [],
              qtdPericiasEscolha: 0,
              descricaoclasse: '',
            ),
            nivel: 2, // ½ nível = 1, bônus treino = +2
          ),
        ],
        atributos: {
          'FOR': const Atributo(nome: 'FOR', valor: 3),
          'DES': const Atributo(nome: 'DES', valor: 0),
          'CON': const Atributo(nome: 'CON', valor: 0),
          'INT': const Atributo(nome: 'INT', valor: 0),
          'SAB': const Atributo(nome: 'SAB', valor: 0),
          'CAR': const Atributo(nome: 'CAR', valor: 0),
        },
        periciasTreinadas: ['LUTA'],
      );

      final preview = CalculoFichaService.prepararPreviewAtaqueArma(
        p,
        espadaLonga,
      );
      expect(preview.temProficienciaNaArma, isTrue);
      expect(preview.penalidadeNaoProficiencia, equals(0));
      // Ataque = 1 (½ nível) + 3 (FOR) + 2 (treino) = +6
      expect(preview.bonusAtaqueFinal, equals(6));
      expect(preview.bonusDanoAtributo, equals(3));
      expect(preview.formulaDanoCompleta, equals('1d8+3 (Corte)'));
      expect(preview.criticoFormatado, equals('19/x2'));
    });
  });

  group('PersonagemStorageService - Serialização e Desserialização', () {
    test('Persiste e restaura novos campos de ficha sem perda de dados', () {
      final original = Personagem.inicial().copyWith(
        nome: 'Valeros',
        alinhamento: 'Leal e Neutro',
        idade: 28,
        anotacoes: 'Lembrar de comprar bálsamos.',
        rdPadrao: 3,
        rdsDiversas: ['RD 5 Fogo', 'RD 2 Frio'],
        outrosBonusDefesa: 2,
        outrosBonusCDMagia: 1,
        outrosBonusPericias: {'LUTA': 2, 'ACROBACIA': -1},
        tibaresCobre: 50,
        tibares: 230,
        tibaresOuro: 12,
        itensVestidosExtras: [
          const ItemVestido(
            slotIndex: 1,
            nome: 'Amuleto Protetor',
            beneficio: 'Proteção',
            espacos: 1,
          ),
        ],
        efeitosTemporarios: [
          const EfeitoTemporario(
            id: 'ef_1',
            nome: 'Benção de Valkaria',
            tipo: TipoEfeitoTemporario.buff,
            modPericias: 1,
            modDefesa: 1,
            modRd: 0,
            ativo: true,
          ),
        ],
        notasProgressaoPorNivel: {1: 'Recebeu título honorário do mestre.'},
      );

      final jsonStr = PersonagemStorageService.personagemToJson(original);
      final restaurado = PersonagemStorageService.personagemFromJson(jsonStr);

      expect(restaurado.nome, equals('Valeros'));
      expect(restaurado.alinhamento, equals('Leal e Neutro'));
      expect(restaurado.idade, equals(28));
      expect(restaurado.anotacoes, equals('Lembrar de comprar bálsamos.'));
      expect(restaurado.rdPadrao, equals(3));
      expect(restaurado.rdsDiversas, contains('RD 5 Fogo'));
      expect(restaurado.outrosBonusDefesa, equals(2));
      expect(restaurado.outrosBonusCDMagia, equals(1));
      expect(restaurado.outrosBonusPericias['LUTA'], equals(2));
      expect(restaurado.tibaresCobre, equals(50));
      expect(restaurado.tibares, equals(230));
      expect(restaurado.tibaresOuro, equals(12));
      expect(restaurado.itensVestidosExtras.first.nome, equals('Amuleto Protetor'));
      expect(restaurado.efeitosTemporarios.first.nome, equals('Benção de Valkaria'));
      expect(
        restaurado.notasProgressaoPorNivel[1],
        equals('Recebeu título honorário do mestre.'),
      );
    });
  });

  group('Widget Tests - PainelJogadorScreen (UI Tormenta 20)', () {
    late FakePersonagemRepository repo;
    late Personagem pUi;

    setUp(() {
      repo = FakePersonagemRepository();

      const magiaTeste = Magia(
        id: 'explosao_chamas',
        nome: 'Explosão de Chamas',
        tipo: 'arcana',
        circulo: 1,
        escola: 'evocacao',
        execucao: ExecucaoMagia(tipo: 'padrao'),
        alcance: AlcanceMagia(tipo: 'curto'),
        efeito: EfeitoMagia(tipo: 'area'),
        duracao: DuracaoMagia(tipo: 'instantanea'),
        descricao: 'Cone de fogo.',
        aprimoramentos: [],
      );

      // Injeta no catálogo estático de magias
      BancoDeMagias.carregarParaTestes([magiaTeste]);

      pUi = Personagem.inicial().copyWith(
        nome: 'Kaelen',
        alinhamento: 'Caótico e Bom',
        idade: 22,
        raca: const Raca(
          id: 'humano',
          nome: 'Humano',
          descricaoRaca: 'Versátil',
          icone: 'player',
          modificadores: {},
          habilidadesRaca: {'Versátil': 'Ganha perícias extras'},
        ),
        classe_do_personagem: [
          ClasseDoPersonagem(
            classeDefinicao: const Classe(
              idClasse: 'arcanista',
              nome: 'Arcanista',
              pvInicial: 8,
              pvPorNivel: 2,
              pmInicial: 6,
              pmPorNivel: 6,
              proficiencias: [TipoProficiencia.armasSimples],
              periciasFixas: ['MISTICISMO', 'VONTADE'],
              periciasOpcoes: ['INICIATIVA'],
              qtdPericiasEscolha: 1,
              descricaoclasse: 'Conjurador arcano',
            ),
            nivel: 1,
          ),
        ],
        atributos: {
          'FOR': const Atributo(nome: 'FOR', valor: 0),
          'DES': const Atributo(nome: 'DES', valor: 2),
          'CON': const Atributo(nome: 'CON', valor: 1),
          'INT': const Atributo(nome: 'INT', valor: 4),
          'SAB': const Atributo(nome: 'SAB', valor: 1),
          'CAR': const Atributo(nome: 'CAR', valor: 0),
        },
        periciasTreinadas: ['MISTICISMO', 'VONTADE', 'INICIATIVA'],
        magiasConhecidas: ['explosao_chamas'],
        pvAtual: 8,
        pmAtual: 6,
      );
    });

    testWidgets('Cabeçalho exibe Alinhamento, Idade e Iniciativa rola em 1 toque',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(480, 900));

      await tester.pumpWidget(
        MaterialApp(
          home: PainelJogadorScreen(
            personagemInicial: pUi,
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifica Alinhamento e Idade no topo da tela
      expect(find.byKey(const Key('topo_alinhamento_idade')), findsOneWidget);
      expect(find.textContaining('Caótico e Bom • 22 anos'), findsOneWidget);

      // Dispara rolagem de Iniciativa em 1 toque no cabeçalho
      final btnIniciativa = find.byKey(const Key('btn_rolar_iniciativa_topo'));
      expect(btnIniciativa, findsOneWidget);
      await tester.tap(btnIniciativa);
      await tester.pumpAndSettle();

      // O diálogo deve abrir com a decomposição do cálculo e resultado final
      expect(find.text('Iniciativa'), findsOneWidget);
      expect(find.text('COMPOSIÇÃO DO CÁLCULO'), findsOneWidget);
      expect(find.byKey(const Key('rolagem_valor_dado')), findsOneWidget);
      expect(find.byKey(const Key('rolagem_resultado_final')), findsOneWidget);

      // Fecha o modal de rolagem
      await tester.tap(find.text('Concluir'));
      await tester.pumpAndSettle();
    });

    testWidgets('Aba de Perícias exibe Total ao lado do nome e rola em 1 toque',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(480, 900));

      await tester.pumpWidget(
        MaterialApp(
          home: PainelJogadorScreen(
            personagemInicial: pUi,
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Clica na aba Perícias
      await tester.tap(find.text('Perícias'));
      await tester.pumpAndSettle();

      // Verifica texto de apoio sobre como é calculado o Total
      expect(find.text('Como é calculado o Total da Perícia'), findsOneWidget);

      // Verifica se a linha de Iniciativa está presente com Total
      expect(find.byKey(const Key('pericia_row_INICIATIVA')), findsOneWidget);
      expect(find.byKey(const Key('pericia_total_INICIATIVA')), findsOneWidget);

      // 1 toque na linha de Iniciativa abre o diálogo de rolagem
      await tester.tap(find.byKey(const Key('pericia_row_INICIATIVA')));
      await tester.pumpAndSettle();

      expect(find.text('Iniciativa'), findsNWidgets(2));
      expect(find.text('COMPOSIÇÃO DO CÁLCULO'), findsOneWidget);
      expect(find.byKey(const Key('rolagem_resultado_final')), findsOneWidget);

      await tester.tap(find.text('Concluir'));
      await tester.pumpAndSettle();
    });

    testWidgets('Aba de Magias: Lançar reduz PM, auto-persiste e impede PM negativo',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(480, 900));

      final pComApenas1PM = pUi.copyWith(pmAtual: 1);

      await tester.pumpWidget(
        MaterialApp(
          home: PainelJogadorScreen(
            personagemInicial: pComApenas1PM,
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Clica na aba Magias
      await tester.tap(find.text('Magias'));
      await tester.pumpAndSettle();

      // Verifica o bloco de CD de magia estilizado
      expect(find.text('CD MAGIA'), findsOneWidget);
      expect(find.byKey(const Key('valor_cd_magia')), findsOneWidget);

      // Verifica botão Lançar (-1 PM)
      final btnLancar = find.byKey(const Key('btn_lancar_magia_explosao_chamas'));
      expect(btnLancar, findsOneWidget);

      // Executa o lançamento de magia (1 -> 0 PM)
      await tester.tap(btnLancar);
      await tester.pumpAndSettle();

      // Deve ter deduzido 1 PM e salvo no repositório automaticamente
      expect(repo.salvo?.pmAtual, equals(0));

      // Próxima tentativa com 0 PM deve ser bloqueada sem deixar PM negativo
      await tester.tap(btnLancar);
      await tester.pumpAndSettle();

      expect(repo.salvo?.pmAtual, equals(0));
      expect(find.textContaining('PM insuficiente'), findsOneWidget);
    });

    testWidgets('Isolamento de rebuilds: alterações em anotações ou tibares não quebram nem causam erro na UI do Painel',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(480, 900));

      await tester.pumpWidget(
        MaterialApp(
          home: PainelJogadorScreen(
            personagemInicial: pUi,
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cubit =
          tester.element(find.byType(TabBarView)).read<FichaCubit>();

      // Atualiza anotações e tibares (não devem desestabilizar ou quebrar o Painel ou Abas)
      cubit.atualizarAnotacoes('Nova pista secreta sobre a Tormenta');
      await tester.pump();

      expect(find.text('Kaelen'), findsOneWidget);

      cubit.ajustarTibares(deltaPrata: 100);
      await tester.pump();
      expect(find.text('Kaelen'), findsOneWidget);
    });
  });
}
