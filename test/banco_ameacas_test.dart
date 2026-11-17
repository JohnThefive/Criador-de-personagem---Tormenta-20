import 'package:flutter_test/flutter_test.dart';
import 'package:t20_creator/domain/entities/combate/monstro.dart';
import 'package:t20_creator/domain/services/data_services/call_ameacas.dart';
import 'package:t20_creator/domain/services/data_services/catalogo_service.dart';

void main() {
  group('BancoDeAmeacas e Camada de Dados de Ameaças', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      CatalogoService.resetar();
      await CatalogoService.carregarTodos();
    });

    tearDown(() {
      BancoDeAmeacas.mesclarCustomizadas(const []);
    });

    test('CatalogoService carrega apenas o índice leve (564 resumos) com lazy-loading', () {
      expect(BancoDeAmeacas.resumos.length, equals(564));
      expect(BancoDeAmeacas.regioes.length, equals(38));
      expect(BancoDeAmeacas.carregadas, isEmpty);

      final resumo = BancoDeAmeacas.getResumoById('abahddon');
      expect(resumo, isNotNull);
      expect(resumo!.nome, equals('Abahddon, Lorde das Profundezas'));
      expect(resumo.nd, equals('20'));
      expect(resumo.regiao, equals('abissais'));
      expect(resumo.papel, equals(PapelMonstro.solo));
      expect(resumo.tipoCriatura, equals('espirito'));

      expect(BancoDeAmeacas.getResumoById('ABAHDDON')?.id, equals('abahddon'));
      expect(BancoDeAmeacas.getResumoById('id_que_nao_existe'), isNull);
    });

    test('getByIdAsync carrega a região sob demanda (lazy-loading)', () async {
      expect(BancoDeAmeacas.regiaoCarregada('abissais'), isFalse);
      expect(BancoDeAmeacas.getById('abahddon'), isNull);

      final abahddon = await BancoDeAmeacas.getByIdAsync('abahddon');
      expect(abahddon, isNotNull);
      expect(BancoDeAmeacas.regiaoCarregada('abissais'), isTrue);
      expect(abahddon!.pvMax, equals(2555));
      expect(abahddon.pmMax, equals(156));
      expect(abahddon.defesa, equals(64));
      expect(abahddon.tamanhoQuadrados, equals(2)); // grande = 2x2
      expect(abahddon.rd['luz'], equals(20));
      expect(abahddon.imunidadesDano, containsAll(['acido', 'fogo', 'veneno']));
      expect(abahddon.deslocamentos['voo'], equals(18.0));
      expect(abahddon.ataques.length, greaterThanOrEqualTo(3));
      expect(abahddon.habilidades, isNotEmpty);
      expect(abahddon.possuiPm, isTrue);

      // Chamada síncrona O(1) após lazy-loading
      expect(BancoDeAmeacas.getById('abahddon')?.nome, equals(abahddon.nome));
    });

    test('carregarRegiao tolera região vazia ou inexistente sem falhar', () async {
      await BancoDeAmeacas.carregarRegiao('regiao_inexistente_vazia');
      expect(BancoDeAmeacas.regiaoCarregada('regiao_inexistente_vazia'), isTrue);
    });

    test('filtros por região, ND, papel, tipo e busca funcionam no índice', () {
      final especiaisKally = BancoDeAmeacas.filtrarResumos(
        regiao: 'igreja_de_kallyadranoch',
        papel: PapelMonstro.especial,
        tipo: 'humanoide',
      );
      expect(especiaisKally, isNotEmpty);
      expect(
        especiaisKally.any((r) => r.id == 'acolito_de_kally'),
        isTrue,
      );

      final ndUmQuarto = BancoDeAmeacas.filtrarResumos(nd: '1/4');
      expect(ndUmQuarto, isNotEmpty);
      expect(ndUmQuarto.every((r) => r.ndNumerico == 0.25), isTrue);

      final porNome = BancoDeAmeacas.filtrarResumos(busca: 'Abahddon');
      expect(porNome.length, equals(1));
      expect(porNome.first.id, equals('abahddon'));
    });

    test('carregarTodasRegioes desserializa todas as 564 criaturas e casos de borda', () async {
      await BancoDeAmeacas.carregarTodasRegioes();
      expect(BancoDeAmeacas.carregadas.length, equals(564));

      // Criatura com voo e deslocamento terrestre 0
      final alma = BancoDeAmeacas.getById('alma_acorrentada');
      expect(alma, isNotNull);
      expect(alma!.deslocamentoMetros, equals(9.0));
      expect(alma.deslocamentos['terrestre'], equals(0.0));
      expect(alma.deslocamentos['voo'], equals(9.0));

      // Criatura com atributos nulos ("–")
      final rival = BancoDeAmeacas.getById('rival_espelho');
      if (rival != null) {
        expect(rival.destrezaNula, isTrue);
        expect(rival.atributoDes, isNull);
      }

      // Round-trip toJson -> fromJson
      final jsonRoundTrip = alma.toJson();
      final reconstruida = Monstro.fromJson(jsonRoundTrip);
      expect(reconstruida.id, equals(alma.id));
      expect(reconstruida.nome, equals(alma.nome));
      expect(reconstruida.pvMax, equals(alma.pvMax));
      expect(reconstruida.deslocamentos, equals(alma.deslocamentos));
    });

    test('mesclarCustomizadas adiciona, sobrescreve e remove ameaças do Mestre', () {
      const custom = Monstro(
        id: 'chefe_campanha_1',
        nome: 'Lorde da Mina Rubra',
        nd: '6',
        regiao: 'campanha_propria',
        papel: PapelMonstro.solo,
        tipoCriatura: 'Humanoide',
        pvMax: 180,
        pmMax: 30,
        defesa: 24,
        iniciativa: 7,
      );

      BancoDeAmeacas.mesclarCustomizadas([custom]);

      expect(BancoDeAmeacas.getById('chefe_campanha_1')?.customizado, isTrue);
      expect(BancoDeAmeacas.getResumoById('chefe_campanha_1')?.customizado, isTrue);
      expect(BancoDeAmeacas.regioes, contains('campanha_propria'));
      expect(
        BancoDeAmeacas.filtrarResumos(regiao: 'campanha_propria').length,
        equals(1),
      );

      BancoDeAmeacas.removerCustomizada('chefe_campanha_1');
      expect(BancoDeAmeacas.getById('chefe_campanha_1'), isNull);
      expect(BancoDeAmeacas.getResumoById('chefe_campanha_1'), isNull);
    });
  });
}
