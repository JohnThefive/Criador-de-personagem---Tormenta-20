import 'package:flutter_test/flutter_test.dart';
import 'package:t20_creator/domain/entities/equipamento/arma.dart';
import 'package:t20_creator/domain/entities/equipamento/protecao.dart';
import 'package:t20_creator/domain/entities/personagem/classe.dart';
import 'package:t20_creator/domain/entities/personagem/proficiencias.dart';
import 'package:t20_creator/presentation/controllers/personagem_cubit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PersonagemCubit - Navegação de Etapas e Consistência de Estado', () {
    late PersonagemCubit cubit;

    setUp(() {
      cubit = PersonagemCubit();
    });

    tearDown(() {
      cubit.close();
    });

    test(
      'Etapa 1 -> Etapa 0: Voltar da Raça para Atributos preserva atributos comprados',
      () {
        cubit.escolherMetodoAtributos(MetodoAtributos.compra);
        cubit.alterarAtributoCompra('FOR', 2);
        cubit.alterarAtributoCompra('DES', 1);

        expect(cubit.state.personagem.atributos['FOR']!.valor, equals(2));
        expect(cubit.state.personagem.atributos['DES']!.valor, equals(1));
        expect(cubit.state.pontosRestantesCompra, lessThan(10));

        // Avança para a Etapa 1 (Raça)
        cubit.avancarEtapa();
        expect(cubit.state.etapaAtual, equals(1));

        // Volta para a Etapa 0 (Atributos)
        cubit.voltarEtapa();
        expect(cubit.state.etapaAtual, equals(0));

        // Atributos e pontos devem permanecer intactos (não sofrer hard reset)
        expect(cubit.state.personagem.atributos['FOR']!.valor, equals(2));
        expect(cubit.state.personagem.atributos['DES']!.valor, equals(1));
        expect(cubit.state.metodoAtributos, equals(MetodoAtributos.compra));
        expect(cubit.state.pontosRestantesCompra, lessThan(10));
      },
    );

    test(
      'Etapa 0 com método selecionado: Voltar retorna para MetodoAtributos.nenhum',
      () {
        cubit.escolherMetodoAtributos(MetodoAtributos.compra);
        expect(cubit.state.metodoAtributos, equals(MetodoAtributos.compra));

        cubit.voltarEtapa();
        expect(cubit.state.metodoAtributos, equals(MetodoAtributos.nenhum));
        expect(cubit.state.etapaAtual, equals(0));
      },
    );

    test(
      'Trocar de Classe: limpa perícias dependentes, magias e equipamentos marciais/pesados incompatíveis',
      () {
        const classeGuerreiro = Classe(
          idClasse: 'guerreiro',
          nome: 'Guerreiro',
          descricaoclasse: 'Mestre do combate.',
          pvInicial: 20,
          pvPorNivel: 5,
          pmInicial: 3,
          pmPorNivel: 3,
          periciasFixas: ['Luta', 'Fortitude'],
          qtdPericiasEscolha: 2,
          periciasOpcoes: ['Pontaria', 'Iniciativa', 'Atletismo'],
          proficiencias: [
            TipoProficiencia.armasSimples,
            TipoProficiencia.armasMarciais,
            TipoProficiencia.armadurasPesadas,
            TipoProficiencia.escudos,
          ],
        );

        const classeArcanista = Classe(
          idClasse: 'arcanista',
          nome: 'Arcanista',
          descricaoclasse: 'Conjurador arcano.',
          pvInicial: 8,
          pvPorNivel: 2,
          pmInicial: 6,
          pmPorNivel: 6,
          periciasFixas: ['Misticismo', 'Vontade'],
          qtdPericiasEscolha: 2,
          periciasOpcoes: ['Conhecimento', 'Iniciativa', 'Oficio'],
          proficiencias: [TipoProficiencia.armasSimples],
        );

        const armaMarcial = Arma(
          key: 'espada_longa',
          nome: 'Espada Longa',
          descricao: 'Uma espada balanceada.',
          proficiencia: ProficienciaArma.marcial,
          proposito: PropositoArma.corpoACorpo,
          empunhadura: EmpunhaduraArma.umaMao,
          dano: '1d8',
          tipoDano: TipoDanoArma.corte,
        );

        const armaduraPesada = Protecao(
          key: 'cota_de_malha',
          nome: 'Cota de Malha',
          descricao: 'Armadura pesada de anéis entrelaçados.',
          precoEmTibares: 150,
          espacos: 2,
          tipo: TipoProtecao.armaduraPesada,
          bonusDefesa: 5,
          penalidadeArmadura: 2,
        );

        // Seleciona Guerreiro e configura seleções
        cubit.selecionarClasse(classeGuerreiro);
        cubit.togglePericiaClasse('Iniciativa');
        cubit.selecionarArmaMarcialInicial(armaMarcial);
        cubit.selecionarArmaduraInicial(armaduraPesada);
        cubit.definirMagias(['bola_de_fogo']);

        expect(cubit.state.selecoesPericiaClasse, contains('Iniciativa'));
        expect(cubit.state.armaMarcialInicial, isNotNull);
        expect(cubit.state.armaduraInicial, isNotNull);
        expect(cubit.state.magiasSelecionadas, contains('bola_de_fogo'));

        // Agora troca de classe para Arcanista
        cubit.selecionarClasse(classeArcanista);

        // Verifica se o estado dependente foi resetado
        expect(
          cubit.state.personagem.classes[0].classeDefinicao.idClasse,
          equals('arcanista'),
        );
        expect(cubit.state.selecoesPericiaClasse, isEmpty);
        expect(cubit.state.selecoesPericiaInteligencia, isEmpty);
        expect(cubit.state.magiasSelecionadas, isEmpty);
        expect(cubit.state.personagem.magiasConhecidas, isEmpty);
        expect(cubit.state.armaMarcialInicial, isNull);
        expect(cubit.state.armaduraInicial, isNull);
      },
    );

    test('Trocar caminho de classe no Arcanista limpa magias e linhagem', () {
      const classeArcanista = Classe(
        idClasse: 'arcanista',
        nome: 'Arcanista',
        descricaoclasse: 'Conjurador arcano.',
        pvInicial: 8,
        pvPorNivel: 2,
        pmInicial: 6,
        pmPorNivel: 6,
        periciasFixas: ['Misticismo', 'Vontade'],
        qtdPericiasEscolha: 2,
        periciasOpcoes: ['Conhecimento'],
        proficiencias: [TipoProficiencia.armasSimples],
      );

      const caminhoMago = CaminhoDeClasse(
        nome: 'Mago',
        atributoChave: 'INT',
        descricao: 'Estuda magias.',
      );

      const caminhoFeiticeiro = CaminhoDeClasse(
        nome: 'Feiticeiro',
        atributoChave: 'CAR',
        descricao: 'Magia inata.',
      );

      cubit.selecionarClasse(classeArcanista);
      cubit.selecionarCaminhoDaClasse(caminhoMago);
      cubit.definirMagias(['dardo_mistico', 'armadura_arcana']);

      expect(cubit.state.magiasSelecionadas.length, equals(2));

      // Troca caminho para Feiticeiro
      cubit.selecionarCaminhoDaClasse(caminhoFeiticeiro);

      expect(
        cubit.state.personagem.classes[0].caminhoEscolhido?.nome,
        equals('Feiticeiro'),
      );
      expect(cubit.state.magiasSelecionadas, isEmpty);
      expect(cubit.state.personagem.magiasConhecidas, isEmpty);
      expect(cubit.state.personagem.classes[0].linhagemEscolhida, isNull);
    });
  });
}
