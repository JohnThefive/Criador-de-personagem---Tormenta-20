import 'package:flutter_test/flutter_test.dart';
import 'package:t20_creator/domain/entities/equipamento/item_geral.dart';
import 'package:t20_creator/domain/entities/equipamento/item_vestido.dart';
import 'package:t20_creator/domain/entities/personagem/atributos.dart';
import 'package:t20_creator/domain/entities/personagem/classe_do_personagem.dart';
import 'package:t20_creator/domain/entities/personagem/personagem.dart';
import 'package:t20_creator/domain/entities/personagem/raca.dart';
import 'package:t20_creator/domain/repositories/i_personagem_repository.dart';
import 'package:t20_creator/domain/services/calculo_ficha_service.dart';
import 'package:t20_creator/domain/services/data_services/call_armaduras.dart';
import 'package:t20_creator/domain/services/data_services/call_armas.dart';
import 'package:t20_creator/domain/services/data_services/call_classes.dart';
import 'package:t20_creator/domain/services/data_services/call_magias.dart';
import 'package:t20_creator/domain/services/data_services/call_pericias.dart';
import 'package:t20_creator/domain/services/data_services/call_poderes.dart';
import 'package:t20_creator/domain/services/data_services/call_racas.dart';
import 'package:t20_creator/domain/services/motor_modificadores_service.dart';
import 'package:t20_creator/domain/services/personagem_storage_service.dart';
import 'package:t20_creator/domain/services/poderes_e_magias/aprendizado_magia_service.dart';
import 'package:t20_creator/presentation/controllers/evolucao_cubit.dart';
import 'package:t20_creator/presentation/controllers/ficha_cubit.dart';
import 'package:t20_creator/presentation/controllers/personagem_cubit.dart';

class _FakePersonagemRepository implements IPersonagemRepository {
  final Map<String, Personagem> _db = {};

  @override
  Future<void> salvar(Personagem p) async {
    _db[p.id] = p;
  }

  @override
  Future<List<Personagem>> obterTodos() async => _db.values.toList();

  @override
  Future<Personagem?> obterPorId(String id) async => _db[id];

  @override
  Future<void> excluir(String id) async {
    _db.remove(id);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await BancoDePericias.carregarPericias();
    await BancoDeClasses.carregar();
    await BancoDePoderes.carregar();
    await BancoDePoderesGerais.carregar();
    await BancoDeMagias.carregarMagias();
    await BancoDeArmas.carregar();
    await BancoDeArmaduras.carregar();
  });

  Map<String, Atributo> criarAtributos({
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

  group('1. Poderes da Tormenta e Regra de Perda de Carisma', () {
    test('deve carregar o catálogo de Poderes da Tormenta dos assets', () {
      final poderesTormenta = BancoDePoderesGerais.poderesTormenta;
      expect(poderesTormenta, isNotEmpty);
      expect(
        poderesTormenta.any((p) => p.key.toLowerCase() == 'anatomia_insana'),
        isTrue,
      );
      expect(
        poderesTormenta.any((p) => p.key.toLowerCase() == 'carapaca'),
        isTrue,
      );
      expect(
        poderesTormenta.every((p) => p.ehPoderTormenta),
        isTrue,
      );
    });

    test(
      'deve perder 1 de Carisma no 1º poder da Tormenta e +1 a cada dois outros, tornando-se NPC se CAR < -5',
      () {
        final guerreiro = BancoDeClasses.getById('guerreiro')!;
        final p1 = BancoDePoderesGerais.getByKey('anatomia_insana')!;
        final p2 = BancoDePoderesGerais.getByKey('antenas')!;
        final p3 = BancoDePoderesGerais.getByKey('carapaca')!;
        final p4 = BancoDePoderesGerais.getByKey('empunhadura_rubra')!;
        final p5 = BancoDePoderesGerais.getByKey('visco_rubro')!;

        Personagem criarComPoderes(
          List<dynamic> poderes, {
          int carInicial = 0,
        }) {
          return Personagem(
            nome: 'Cultista Rubro',
            atributos: criarAtributos(car: carInicial),
            classes: [
              ClasseDoPersonagem(
                classeDefinicao: guerreiro,
                nivel: 6,
                poderesEscolhidos: poderes.cast(),
              ),
            ],
          );
        }

        // 0 poderes -> perda 0
        final semTormenta = criarComPoderes([]);
        expect(semTormenta.perdaCarismaTormenta, equals(0));
        expect(semTormenta.getValorFinal('CAR'), equals(0));

        // 1 poder -> perde 1 de Carisma
        final umPoder = criarComPoderes([p1]);
        expect(umPoder.poderesTormentaComPerdaCarisma, equals(1));
        expect(umPoder.perdaCarismaTormenta, equals(1));
        expect(umPoder.getValorFinal('CAR'), equals(-1));

        // 2 poderes -> ainda perde apenas 1 de Carisma (precisa de dois outros para perder mais 1)
        final doisPoderes = criarComPoderes([p1, p2]);
        expect(doisPoderes.poderesTormentaComPerdaCarisma, equals(2));
        expect(doisPoderes.perdaCarismaTormenta, equals(1));
        expect(doisPoderes.getValorFinal('CAR'), equals(-1));

        // 3 poderes (1 + 2 outros) -> perde 2 de Carisma
        final tresPoderes = criarComPoderes([p1, p2, p3]);
        expect(tresPoderes.poderesTormentaComPerdaCarisma, equals(3));
        expect(tresPoderes.perdaCarismaTormenta, equals(2));
        expect(tresPoderes.getValorFinal('CAR'), equals(-2));

        // 5 poderes (1 + 4 outros) -> perde 3 de Carisma
        final cincoPoderes = criarComPoderes([p1, p2, p3, p4, p5]);
        expect(cincoPoderes.poderesTormentaComPerdaCarisma, equals(5));
        expect(cincoPoderes.perdaCarismaTormenta, equals(3));
        expect(cincoPoderes.getValorFinal('CAR'), equals(-3));

        // Personagem com CAR inicial -3 que recebe 5 poderes da Tormenta -> CAR final = -6 (< -5 -> NPC!)
        final dominado = criarComPoderes([p1, p2, p3, p4, p5], carInicial: -3);
        expect(dominado.getValorFinal('CAR'), equals(-6));
        expect(dominado.dominadoPelaTormenta, isTrue);

        // Personagem com CAR final = -5 ainda não foi dominado (apenas menor que -5)
        final noLimite = criarComPoderes([p1, p2, p3, p4, p5], carInicial: -2);
        expect(noLimite.getValorFinal('CAR'), equals(-5));
        expect(noLimite.dominadoPelaTormenta, isFalse);
      },
    );

    test(
      'deve escalar bônus passivos de Antenas e Carapaça conforme outros poderes da Tormenta',
      () {
        final guerreiro = BancoDeClasses.getById('guerreiro')!;
        final antenas = BancoDePoderesGerais.getByKey('antenas')!;
        final carapaca = BancoDePoderesGerais.getByKey('carapaca')!;
        final anatomia = BancoDePoderesGerais.getByKey('anatomia_insana')!;
        final empunhadura = BancoDePoderesGerais.getByKey('empunhadura_rubra')!;
        final visco = BancoDePoderesGerais.getByKey('visco_rubro')!;

        // Com 5 poderes da Tormenta (4 "outros" poderes além de Antenas/Carapaça):
        // Escalamento = 1 base + (4 ~/ 2) = +3 em Iniciativa/Percepção/Vontade e +3 na Defesa!
        final p = Personagem(
          nome: 'Aberrante',
          atributos: criarAtributos(),
          classes: [
            ClasseDoPersonagem(
              classeDefinicao: guerreiro,
              nivel: 6,
              poderesEscolhidos: [
                antenas,
                carapaca,
                anatomia,
                empunhadura,
                visco,
              ],
            ),
          ],
        );

        expect(p.totalPoderesTormenta, equals(5));
        expect(p.bonusDeclarativoDefesa, equals(3));
        expect(p.defesaFinal, equals(13));
        expect(p.bonusDeclarativoPericia('INICIATIVA'), equals(3));
        expect(p.bonusDeclarativoPericia('PERCEPCAO'), equals(3));
        expect(p.bonusDeclarativoPericia('VONTADE'), equals(3));
      },
    );
  });

  group('2. Poder Racial Deformidade do Lefou', () {
    final racaLefou = BancoDeRacas.todas.firstWhere(
      (r) => r.id.toLowerCase() == 'lefou',
      orElse: () => const Raca(
        id: 'lefou',
        nome: 'Lefou',
        descricaoRaca: 'Cria da Tormenta',
        icone: 'skull',
        modificadores: {'CAR': -1},
        ehFlexivel: true,
        atributosBloqueados: ['CAR'],
      ),
    );

    test(
      'Lefou com +2 em duas perícias deve contar como 2 poderes da Tormenta sem perder Carisma extra',
      () {
        final guerreiro = BancoDeClasses.getById('guerreiro')!;
        final lefou = Personagem(
          nome: 'Lefou Lutador',
          raca: racaLefou,
          atributos: criarAtributos(car: 0),
          periciasDeformidadeLefou: ['LUTA', 'INTIMIDACAO'],
          classes: [
            ClasseDoPersonagem(classeDefinicao: guerreiro, nivel: 1),
          ],
        );

        // +2 nas duas perícias escolhidas
        expect(lefou.bonusRacialPericia('LUTA'), equals(2));
        expect(lefou.bonusRacialPericia('INTIMIDACAO'), equals(2));
        expect(lefou.bonusRacialPericia('ACROBACIA'), equals(0));

        // Conta como 2 poderes da Tormenta para pré-requisitos e escalonamento
        expect(lefou.totalPoderesTormenta, equals(2));

        // Mas NÃO conta para perda de Carisma da Tormenta!
        expect(lefou.poderesTormentaComPerdaCarisma, equals(0));
        expect(lefou.perdaCarismaTormenta, equals(0));
        // Apenas o modificador racial fixo do Lefou (-1 CAR) se aplica
        expect(lefou.getValorFinal('CAR'), equals(-1));
      },
    );

    test(
      'Lefou que troca 1 bônus de perícia por 1 Poder da Tormenta recebe ambos sem perda de Carisma',
      () {
        final guerreiro = BancoDeClasses.getById('guerreiro')!;
        final carapaca = BancoDePoderesGerais.getByKey('carapaca')!;

        final cubit = PersonagemCubit();
        cubit.selecionarRaca(racaLefou);
        cubit.togglePericiaDeformidadeLefou('LUTA');
        cubit.togglePericiaDeformidadeLefou('FORTITUDE');
        expect(
          cubit.state.personagem.periciasDeformidadeLefou.length,
          equals(2),
        );

        // Ao escolher 1 Poder da Tormenta na Deformidade, a lista de perícias da Deformidade é limitada a 1
        cubit.selecionarPoderTormentaDeformidade(carapaca);
        final lefou = cubit.state.personagem.copyWith(
          classe_do_personagem: [
            ClasseDoPersonagem(classeDefinicao: guerreiro, nivel: 1),
          ],
        );

        expect(lefou.periciasDeformidadeLefou, equals(['LUTA']));
        expect(lefou.poderTormentaDeformidade?.key, equals('carapaca'));
        expect(lefou.bonusRacialPericia('LUTA'), equals(2));
        expect(lefou.bonusRacialPericia('FORTITUDE'), equals(0));

        // 1 perícia da Deformidade + 1 poder da Tormenta da Deformidade = 2 poderes da Tormenta no total
        expect(lefou.totalPoderesTormenta, equals(2));
        // Nenhum dos dois causa perda de Carisma
        expect(lefou.poderesTormentaComPerdaCarisma, equals(0));
        expect(lefou.perdaCarismaTormenta, equals(0));

        // E a Carapaça escolhida na Deformidade já concede +1 na Defesa!
        expect(lefou.bonusDeclarativoDefesa, equals(1));
      },
    );
  });

  group('3. EvolucaoCubit: Poder de Classe OU Poder Geral por Nível', () {
    test(
      'deve permitir escolher entre Poder de Classe ou Poder Geral consumindo o mesmo limite de slots (nivel - 1)',
      () async {
        final repo = _FakePersonagemRepository();
        final guerreiro = BancoDeClasses.getById('guerreiro')!;
        final p = Personagem(
          nome: 'Valente',
          atributos: criarAtributos(forca: 2, con: 2),
          periciasTreinadas: ['LUTA', 'FORTITUDE'],
          classes: [
            ClasseDoPersonagem(classeDefinicao: guerreiro, nivel: 3),
          ],
        );

        final cubit = EvolucaoCubit(personagem: p, repository: repo);
        // Nível 3 = 2 poderes disponíveis no total
        expect(cubit.state.poderesPermitidos, equals(2));
        expect(cubit.state.poderesPendentes, equals(2));

        // 1. Escolhe um Poder de Classe na aba Classe
        cubit.alterarCategoria(CategoriaEvolucaoPoder.classe);
        final itemPoderClasse = cubit.state.todosItens.firstWhere(
          (item) => item.podeAprender,
        );
        await cubit.aprenderPoder(itemPoderClasse.poder);
        expect(cubit.state.poderesPendentes, equals(1));

        // 2. Alterna para a aba Tormenta e escolhe um Poder da Tormenta no 2º slot
        cubit.alterarCategoria(CategoriaEvolucaoPoder.tormenta);
        final itemAnatomia = cubit.state.todosItens.firstWhere(
          (item) => item.poder.key.toLowerCase() == 'anatomia_insana',
        );
        await cubit.aprenderPoder(itemAnatomia.poder);
        expect(cubit.state.poderesPendentes, equals(0));

        // 3. Tentar escolher um 3º poder (Combate ou Classe) sem slots restantes emite erro e não adiciona
        cubit.alterarCategoria(CategoriaEvolucaoPoder.combate);
        final itemCombate = cubit.state.todosItens.firstWhere(
          (item) => item.podeAprender,
        );
        await cubit.aprenderPoder(itemCombate.poder);
        expect(
          cubit.state.classeAtual.poderesEscolhidos.length,
          equals(2),
        );
        expect(cubit.state.mensagemErro, isNotNull);
        await cubit.close();
      },
    );
  });

  group('4. Catálogo de Magias (1º ao 5º Círculos) e Progressão', () {
    test('deve carregar magias de todos os 5 círculos', () {
      for (int c = 1; c <= 5; c++) {
        final magiasCirculo = BancoDeMagias.todas
            .where((m) => m.circulo == c)
            .toList();
        expect(
          magiasCirculo,
          isNotEmpty,
          reason: 'O $cº círculo de magias deveria estar carregado',
        );
      }
    });

    test(
      'deve desbloquear do 1º ao 5º círculo nos níveis corretos e calcular magias pendentes no level-up',
      () {
        final arcanista = BancoDeClasses.getById('arcanista')!;
        expect(
          AprendizadoMagiaService.obterCirculoMaximoClasse(
            arcanista.idClasse,
            1,
          ),
          equals(1),
        );
        expect(
          AprendizadoMagiaService.obterCirculoMaximoClasse(
            arcanista.idClasse,
            5,
          ),
          equals(2),
        );
        expect(
          AprendizadoMagiaService.obterCirculoMaximoClasse(
            arcanista.idClasse,
            9,
          ),
          equals(3),
        );
        expect(
          AprendizadoMagiaService.obterCirculoMaximoClasse(
            arcanista.idClasse,
            13,
          ),
          equals(4),
        );
        expect(
          AprendizadoMagiaService.obterCirculoMaximoClasse(
            arcanista.idClasse,
            17,
          ),
          equals(5),
        );

        // Arcanista nível 1 começa com 3 magias; no nível 5 deve conhecer 3 + 4 = 7 magias
        final pNivel5 = Personagem(
          nome: 'Mago',
          atributos: criarAtributos(intel: 4),
          classes: [
            ClasseDoPersonagem(classeDefinicao: arcanista, nivel: 5),
          ],
          magiasConhecidas: BancoDeMagias.todas
              .where((m) => m.circulo == 1)
              .take(3)
              .map((m) => m.id)
              .toList(),
        );
        expect(
          AprendizadoMagiaService.obterCirculoMaximoPersonagem(pNivel5),
          equals(2),
        );
        expect(
          AprendizadoMagiaService.calcularTotalMagiasEsperadasPersonagem(
            pNivel5,
          ),
          equals(7),
        );
        expect(
          AprendizadoMagiaService.calcularMagiasPendentesPersonagem(pNivel5),
          equals(4),
        );
      },
    );
  });

  group('5. Itens Gerais, Melhorias (Superiores) e Encantos (Mágicos)', () {
    test(
      'Arma com melhorias e encantos deve alterar ataque, dano, margem de ameaça, crítico, defesa e espaços',
      () {
        final espadaBase = BancoDeArmas.todas.firstWhere(
          (a) => a.nome.toLowerCase().contains('espada longa'),
        );
        final espadaCustom = espadaBase.copyWith(
          melhorias: [
            'CERTEIRA',
            'CRUEL',
            'PRECISA',
            'MACICA',
            'MATERIAL_MITRAL',
          ],
          encantos: ['FORMIDAVEL', 'AMEACADORA', 'DEFENSORA'],
        );

        // Ataque: +1 (Certeira) + 2 (Formidável) = +3
        expect(espadaCustom.bonusAtaqueMelhorias, equals(3));
        // Dano: +1 (Cruel) + 2 (Formidável) = +3
        expect(espadaCustom.bonusDanoMelhorias, equals(3));
        // Defesa: +2 (Defensora)
        expect(espadaCustom.bonusDefesaEncanto, equals(2));
        // Multiplicador de crítico: x2 base + 1 (Maciça) = 3
        expect(espadaCustom.multiplicadorCriticoEfetivo, equals(3));
        // Margem de ameaça reduzida (Ameaçadora + Precisa + Mitral)
        expect(
          espadaCustom.margemAmeacaEfetiva,
          lessThan(espadaBase.margemAmeaca),
        );
        // Espaços: reduz 1 pelo Mitral
        expect(
          espadaCustom.espacosEfetivos,
          equals((espadaBase.espacos - 1).clamp(0, 99)),
        );
      },
    );

    test(
      'Proteção com melhorias e encantos e ItemGeral vestido devem alterar Defesa, RD, Penalidade e CD de Magia',
      () {
        final arcanista = BancoDeClasses.getById('arcanista')!;
        final armaduraPesada = BancoDeArmaduras.todas.firstWhere(
          (a) => a.ehArmaduraPesada,
        );

        final armaduraSuperior = armaduraPesada.copyWith(
          melhorias: ['REFORCADA', 'DELICADA', 'SELADA', 'MATERIAL_ADAMANTE'],
          encantos: ['DEFENSORA'],
        );

        final varinha = CatalogoItensGeraisEMelhorias.itensGerais.firstWhere(
          (i) => i.key == 'TOMO_HERMETICO',
        );

        final p = Personagem(
          nome: 'Mago de Batalha',
          atributos: criarAtributos(des: 3, intel: 4),
          classes: [
            ClasseDoPersonagem(classeDefinicao: arcanista, nivel: 4),
          ],
          armaduraEquipada: armaduraSuperior,
          itensVestidosExtras: [
            ItemVestido(
              slotIndex: 1,
              nome: varinha.nome,
              beneficio: varinha.efeitoResumo,
              espacos: varinha.espacos,
              bonusCDMagia: varinha.bonusCDMagia,
            ),
          ],
        );

        // Armadura pesada com Delicada aplica +1 da Destreza na Defesa
        expect(
          MotorModificadoresService.calcularBonusDestrezaDelicadaArmaduraPesada(
            p,
          ),
          equals(1),
        );
        // RD 5 do Adamante em armadura pesada
        expect(p.rdTotal, equals(5));
        // Selada concede +1 em Fortitude, Reflexos e Vontade
        expect(p.bonusDeclarativoPericia('FORTITUDE'), equals(1));
        expect(p.bonusDeclarativoPericia('REFLEXOS'), equals(1));
        expect(p.bonusDeclarativoPericia('VONTADE'), equals(1));

        // CD de Magia: 10 + metade do nível (2) + INT (4) + Tomo Hermético (+2) = 18
        final cd = CalculoFichaService.detalharCDMagia(p);
        expect(cd.cdTotal, equals(18));
      },
    );
  });

  group('6. Multiclasse (Níveis 2–20) e Persistência Completa', () {
    test(
      'FichaCubit deve adicionar multiclasse, alterar níveis por classe e persistir/restaurar todos os novos campos',
      () async {
        final repo = _FakePersonagemRepository();

        final guerreiro = BancoDeClasses.getById('guerreiro')!;
        final arcanista = BancoDeClasses.getById('arcanista')!;
        final carapaca = BancoDePoderesGerais.getByKey('carapaca')!;
        final racaLefou = BancoDeRacas.todas.firstWhere(
          (r) => r.id.toLowerCase() == 'lefou',
          orElse: () => const Raca(
            id: 'lefou',
            nome: 'Lefou',
            descricaoRaca: 'Cria da Tormenta',
            icone: 'skull',
            modificadores: {'CAR': -1},
            ehFlexivel: true,
            atributosBloqueados: ['CAR'],
          ),
        );

        final armaInicial = BancoDeArmas.todas.first.copyWith(
          melhorias: ['CERTEIRA'],
          encantos: ['FORMIDAVEL'],
        );

        final inicial = Personagem(
          id: 'pers_multiclasse_1',
          nome: 'Kaelen',
          raca: racaLefou,
          atributos: criarAtributos(forca: 3, con: 2, intel: 3),
          periciasDeformidadeLefou: ['LUTA'],
          poderTormentaDeformidade: carapaca,
          classes: [
            ClasseDoPersonagem(classeDefinicao: guerreiro, nivel: 3),
          ],
          armas: [armaInicial],
        );

        final cubit = FichaCubit(
          personagemInicial: inicial,
          repository: repo,
          debounceDuration: const Duration(milliseconds: 5),
        );

        // Adiciona Multiclasse em Arcanista (inicia nível 1, total 4)
        await cubit.adicionarMulticlasse(arcanista);
        expect(cubit.state.personagem.classes.length, equals(2));
        expect(cubit.state.personagem.nivelPersonagem, equals(4));

        // Sobe Arcanista em +4 níveis -> nível 5 (total nível 8)
        await cubit.alterarNivelClasse(1, 4);
        expect(cubit.state.personagem.classes[1].nivel, equals(5));
        expect(cubit.state.personagem.nivelPersonagem, equals(8));
        expect(
          AprendizadoMagiaService.obterCirculoMaximoPersonagem(
            cubit.state.personagem,
          ),
          equals(2),
        );

        // Adiciona um item geral vestido
        final capa = CatalogoItensGeraisEMelhorias.itensGerais.firstWhere(
          (i) => i.key == 'CAPA_PESADA',
        );
        await cubit.adicionarItemGeral(capa, vestirEmSlotLivre: true);
        expect(
          cubit.state.personagem.bonusDeclarativoPericia('FORTITUDE'),
          equals(1),
        );

        // Testa serialização e desserialização completa no PersonagemStorageService
        final jsonMap = PersonagemStorageService.personagemToMap(
          cubit.state.personagem,
        );
        final restaurado = PersonagemStorageService.mapToPersonagem(jsonMap);

        expect(restaurado.classes.length, equals(2));
        expect(restaurado.classes[0].nivel, equals(3));
        expect(restaurado.classes[1].nivel, equals(5));
        expect(restaurado.periciasDeformidadeLefou, equals(['LUTA']));
        expect(restaurado.poderTormentaDeformidade?.key, equals('carapaca'));
        expect(restaurado.armas.first.melhorias, contains('CERTEIRA'));
        expect(restaurado.armas.first.encantos, contains('FORMIDAVEL'));
        expect(
          restaurado.itensVestidosExtras.first.bonusPericias['FORTITUDE'],
          equals(1),
        );

        await cubit.close();
      },
    );
  });
}
