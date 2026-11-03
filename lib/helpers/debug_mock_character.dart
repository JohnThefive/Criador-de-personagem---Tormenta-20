import '../domain/entities/personagem/atributos.dart';
import '../domain/entities/personagem/classe_do_personagem.dart';
import '../domain/entities/personagem/personagem.dart';
import '../domain/services/data_services/call_armaduras.dart';
import '../domain/services/data_services/call_armas.dart';
import '../domain/services/data_services/call_classes.dart';
import '../domain/services/data_services/call_origens.dart';
import '../domain/services/data_services/call_racas.dart';

/// Helper responsável por gerar uma ficha de personagem padrão para desenvolvimento
/// e testes no emulador, permitindo acessar o Painel do Jogador sem passar pelo wizard.
class DebugMockCharacter {
  static Personagem criarPersonagemTeste({String id = 'debug_hero'}) {
    final raca = BancoDeRacas.getById('humano');
    final classeDef = BancoDeClasses.getById('guerreiro');
    final origem = BancoDeOrigens.getById('soldado');
    final espada = BancoDeArmas.getByKey('ESPADA_LONGA');
    final armadura = BancoDeArmaduras.getByKey('COURO_BATIDO');
    final escudo = BancoDeArmaduras.getByKey('ESCUDO_PESADO');

    return Personagem(
      id: id,
      nome: 'Valeros (Herói de Teste)',
      idade: 25,
      alinhamento: 'Ordeiro e Bom',
      descricaoAparencia:
          'Guerreiro humano bem equipado para testes rápidos no emulador.',
      raca: raca,
      origem: origem,
      classes: [
        if (classeDef != null)
          ClasseDoPersonagem(classeDefinicao: classeDef, nivel: 1),
      ],
      atributos: const {
        'FOR': Atributo(nome: 'Força', valor: 3),
        'DES': Atributo(nome: 'Destreza', valor: 1),
        'CON': Atributo(nome: 'Constituição', valor: 2),
        'INT': Atributo(nome: 'Inteligência', valor: 0),
        'SAB': Atributo(nome: 'Sabedoria', valor: 1),
        'CAR': Atributo(nome: 'Carisma', valor: 0),
      },
      periciasTreinadas: const ['Luta', 'Fortitude', 'Iniciativa', 'Atletismo'],
      armas: [?espada],
      armaduraEquipada: armadura,
      escudoEquipado: escudo,
      itensInventario: const [
        'Mochila',
        'Saco de Dormir',
        'Traje de Viajante',
        'Corda (15m)',
        'Rações de Viagem (5)',
      ],
      tibares: 50,
    );
  }
}
