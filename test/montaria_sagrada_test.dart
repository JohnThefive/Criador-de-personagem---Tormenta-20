import 'package:flutter_test/flutter_test.dart';
import 'package:t20_creator/domain/entities/atributos.dart';
import 'package:t20_creator/domain/entities/classe.dart';
import 'package:t20_creator/domain/entities/classe_do_personagem.dart';
import 'package:t20_creator/domain/entities/montaria_sagrada.dart';
import 'package:t20_creator/domain/entities/personagem.dart';
import 'package:t20_creator/domain/services/data_services/call_montaria_sagrada.dart';
import 'package:t20_creator/domain/services/personagem_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BancoDeRegrasMontariaSagrada', () {
    test('carrega regras do arquivo JSON com sucesso', () {
      final regras = BancoDeRegrasMontariaSagrada.regras;
      expect(regras, isNotEmpty);
      expect(regras['id'], equals('montaria_sagrada'));
      expect(regras['classeOrigem'], equals('paladino'));
      expect(BancoDeRegrasMontariaSagrada.nivelDisponivel, equals(5));
      expect(BancoDeRegrasMontariaSagrada.custoPmInvocacao, equals(2));
      expect(BancoDeRegrasMontariaSagrada.acaoInvocacao, equals('MOVIMENTO'));
    });

    test('calcula tier e deslocamento corretamente por nível de Paladino', () {
      // Nível < 5
      expect(BancoDeRegrasMontariaSagrada.tierParaNivel(4), equals('INICIANTE'));
      expect(BancoDeRegrasMontariaSagrada.deslocamentoParaNivel(4), equals(15));

      // Nível 5 a 10 (Veterano)
      expect(BancoDeRegrasMontariaSagrada.tierParaNivel(5), equals('VETERANO'));
      expect(BancoDeRegrasMontariaSagrada.deslocamentoParaNivel(5), equals(18));
      expect(BancoDeRegrasMontariaSagrada.tierParaNivel(10), equals('VETERANO'));
      expect(BancoDeRegrasMontariaSagrada.deslocamentoParaNivel(10), equals(18));

      // Nível 11+ (Mestre)
      expect(BancoDeRegrasMontariaSagrada.tierParaNivel(11), equals('MESTRE'));
      expect(BancoDeRegrasMontariaSagrada.deslocamentoParaNivel(11), equals(21));
      expect(BancoDeRegrasMontariaSagrada.tierParaNivel(20), equals('MESTRE'));
      expect(BancoDeRegrasMontariaSagrada.deslocamentoParaNivel(20), equals(21));
    });

    test('retorna espécie padrão por tamanho do personagem', () {
      expect(BancoDeRegrasMontariaSagrada.animalPadraoParaTamanho('Pequeno'), equals('Pônei'));
      expect(BancoDeRegrasMontariaSagrada.animalPadraoParaTamanho('Médio'), equals('Cavalo de Guerra'));
      expect(BancoDeRegrasMontariaSagrada.animalPadraoParaTamanho(null), equals('Cavalo de Guerra'));
    });

    test('retorna propriedades e regras textuais', () {
      final props = BancoDeRegrasMontariaSagrada.propriedades;
      expect(props, isNotEmpty);
      expect(props.any((p) => p.contains('Vinculo mental') || p.contains('Vínculo mental')), isTrue);
    });
  });

  group('Entidade MontariaSagrada', () {
    test('instanciação padrão e estado de ativa', () {
      const montaria = MontariaSagrada();
      expect(montaria.nomeCustomizado, equals('Cavalo de Guerra'));
      expect(montaria.especie, equals('Cavalo de Guerra'));
      expect(montaria.isVarianteMundana, isFalse);
      expect(montaria.invocada, isFalse);
      expect(montaria.ativa, isFalse);

      final montariaInvocada = montaria.copyWith(invocada: true);
      expect(montariaInvocada.ativa, isTrue);

      final montariaMundana = montaria.copyWith(isVarianteMundana: true);
      expect(montariaMundana.ativa, isTrue);
    });

    test('serialização toJson e desserialização fromJson', () {
      const montariaOriginal = MontariaSagrada(
        nomeCustomizado: 'Relâmpago',
        especie: 'Grifo',
        isVarianteMundana: true,
        invocada: false,
      );

      final json = montariaOriginal.toJson();
      final reconstruida = MontariaSagrada.fromJson(json);

      expect(reconstruida.nomeCustomizado, equals('Relâmpago'));
      expect(reconstruida.especie, equals('Grifo'));
      expect(reconstruida.isVarianteMundana, isTrue);
      expect(reconstruida.invocada, isFalse);
      expect(reconstruida.ativa, isTrue);
    });
  });

  group('Personagem com Montaria Sagrada', () {
    final classePaladino = Classe(
      idClasse: 'paladino',
      nome: 'Paladino',
      descricaoclasse: 'Guerreiro sagrado',
      icone: 'shield-cross',
      caminhoImagem: '',
      pvInicial: 20,
      pvPorNivel: 5,
      pmInicial: 3,
      pmPorNivel: 3,
      proficiencias: const [],
      periciasFixas: const ['LUTA', 'VONTADE'],
      periciasOpcoes: const [],
      qtdPericiasEscolha: 2,
      tabelaDeProgressao: const {
        1: ['Abençoado'],
        5: ['Bênção da Justiça'],
      },
      caminhosDisponiveis: const [
        CaminhoDeClasse(
          nome: 'Montaria Sagrada',
          atributoChave: 'CAR',
          descricao: 'Invoca montaria',
          nivelLiberado: 5,
        ),
      ],
    );

    Personagem criarPaladino({int nivel = 5, int pmAtual = 10}) {
      return Personagem(
        nome: 'Sir Arthur',
        atributos: {
          'FOR': Atributo(nome: 'Força', valor: 16),
          'DES': Atributo(nome: 'Destreza', valor: 10),
          'CON': Atributo(nome: 'Constituição', valor: 14),
          'INT': Atributo(nome: 'Inteligência', valor: 10),
          'SAB': Atributo(nome: 'Sabedoria', valor: 12),
          'CAR': Atributo(nome: 'Carisma', valor: 16),
        },
        classes: [
          ClasseDoPersonagem(
            classeDefinicao: classePaladino,
            nivel: nivel,
            caminhoEscolhido: const CaminhoDeClasse(
              nome: 'Montaria Sagrada',
              atributoChave: 'CAR',
              descricao: 'Invoca montaria',
              nivelLiberado: 5,
            ),
          ),
        ],
        periciasTreinadas: const ['LUTA', 'VONTADE'],
        pmAtual: pmAtual,
        pvAtual: 45,
      );
    }

    test('identifica corretamente posse da montaria sagrada no nível 5', () {
      final p5 = criarPaladino(nivel: 5);
      expect(p5.nivelPaladino, equals(5));
      expect(p5.temCaminhoMontariaSagrada, isTrue);
      expect(p5.temMontariaSagrada, isTrue);
      expect(p5.tierMontariaSagrada, equals('VETERANO'));
      expect(p5.deslocamentoMontadoMetros, equals(18));

      final p4 = criarPaladino(nivel: 4);
      expect(p4.nivelPaladino, equals(4));
      expect(p4.temMontariaSagrada, isFalse);
    });

    test('escala para tier MESTRE e 21m no nível 11', () {
      final p11 = criarPaladino(nivel: 11);
      expect(p11.tierMontariaSagrada, equals('MESTRE'));
      expect(p11.deslocamentoMontadoMetros, equals(21));
    });

    test('invocar montaria consome 2 PM e ativa status', () {
      final p = criarPaladino(nivel: 5, pmAtual: 10);
      expect(p.montariaSagradaAtiva, isFalse);

      final invocado = p.invocarMontariaSagrada();
      expect(invocado.pmAtual, equals(8));
      expect(invocado.montariaSagradaAtiva, isTrue);
      expect(invocado.montariaSagrada?.invocada, isTrue);

      final dispensado = invocado.dispensarMontariaSagrada();
      expect(dispensado.montariaSagradaAtiva, isFalse);
      expect(dispensado.pmAtual, equals(8)); // Não restitui PM ao dispensar
    });

    test('não permite invocar se PM for menor que 2', () {
      final p = criarPaladino(nivel: 5, pmAtual: 1);
      final tentou = p.invocarMontariaSagrada();
      expect(tentou.pmAtual, equals(1));
      expect(tentou.montariaSagradaAtiva, isFalse);
    });

    test('alternar variante mundana não requer PM e torna ativa', () {
      final p = criarPaladino(nivel: 5, pmAtual: 5);
      final comMundana = p.alternarVarianteMundanaMontaria(true);
      expect(comMundana.montariaSagradaAtiva, isTrue);
      expect(comMundana.montariaSagrada?.isVarianteMundana, isTrue);
      expect(comMundana.pmAtual, equals(5));
    });

    test('persistência salva e carrega montaria sagrada no PersonagemStorageService', () {
      final pOriginal = criarPaladino(nivel: 5, pmAtual: 10).invocarMontariaSagrada();
      final pAtualizado = pOriginal.atualizarMontariaSagrada(
        pOriginal.montariaSagrada!.copyWith(
          nomeCustomizado: 'Sleipnir',
          especie: 'Cavalo de Guerra Divino',
        ),
      );

      final jsonStr = PersonagemStorageService.personagemToJson(pAtualizado);
      final pCarregado = PersonagemStorageService.personagemFromJson(jsonStr);

      expect(pCarregado.montariaSagrada, isNotNull);
      expect(pCarregado.montariaSagrada?.nomeCustomizado, equals('Sleipnir'));
      expect(pCarregado.montariaSagrada?.especie, equals('Cavalo de Guerra Divino'));
      expect(pCarregado.montariaSagrada?.invocada, isTrue);
      expect(pCarregado.montariaSagradaAtiva, isTrue);
    });
  });
}
