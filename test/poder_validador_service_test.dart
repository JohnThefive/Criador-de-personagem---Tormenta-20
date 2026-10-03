import 'package:flutter_test/flutter_test.dart';
import 'package:t20_creator/domain/entities/atributos.dart';
import 'package:t20_creator/domain/entities/classe.dart';
import 'package:t20_creator/domain/entities/classe_do_personagem.dart';
import 'package:t20_creator/domain/entities/personagem.dart';
import 'package:t20_creator/domain/entities/poder.dart';
import 'package:t20_creator/domain/services/data_services/call_classes.dart';
import 'package:t20_creator/domain/services/poder_validador_service.dart';

void main() {
  group('Evolução e PoderValidadorService - Tormenta 20', () {
    final classeGuerreiro = BancoDeClasses.todas.firstWhere(
      (c) => c.idClasse.toUpperCase() == 'GUERREIRO',
      orElse: () => BancoDeClasses.todas.first,
    );

    test('ClasseDoPersonagem calcula poderesPermitidos e poderesPendentes', () {
      final nivel1 = ClasseDoPersonagem(
        classeDefinicao: classeGuerreiro,
        nivel: 1,
      );
      expect(nivel1.poderesPermitidos, 0);
      expect(nivel1.poderesPendentes, 0);
      expect(nivel1.temPoderPendente, false);

      final nivel2 = ClasseDoPersonagem(
        classeDefinicao: classeGuerreiro,
        nivel: 2,
      );
      expect(nivel2.poderesPermitidos, 1);
      expect(nivel2.poderesPendentes, 1);
      expect(nivel2.temPoderPendente, true);

      // Adicionando 1 poder no nível 2
      final poder1 = const Poder(
        key: 'GOLPE_PODEROSO',
        nome: 'Golpe Poderoso',
        descricao: 'Mais dano',
      );
      final nivel2ComPoder = nivel2.adicionarPoder(poder1);
      expect(nivel2ComPoder.poderesEscolhidos.length, 1);
      expect(nivel2ComPoder.poderesPendentes, 0);
      expect(nivel2ComPoder.temPoderPendente, false);

      // Subindo para o nível 5
      final nivel5 = nivel2ComPoder.copyWith(nivel: 5);
      expect(nivel5.poderesPermitidos, 4);
      expect(nivel5.poderesPendentes, 3);
      expect(nivel5.temPoderPendente, true);
    });

    test('Valida nível mínimo e requisitos de atributos', () {
      final personagem = Personagem(
        nome: 'Kallian',
        atributos: {
          'FOR': const Atributo(
            nome: 'Força',
            valor: 2,
          ), // Mod +2 (equivalente a 14/15)
          'DES': const Atributo(nome: 'Destreza', valor: 0),
          'CON': const Atributo(nome: 'Constituição', valor: 1),
          'INT': const Atributo(nome: 'Inteligência', valor: 0),
          'SAB': const Atributo(nome: 'Sabedoria', valor: 0),
          'CAR': const Atributo(nome: 'Carisma', valor: 0),
        },
        classes: [
          ClasseDoPersonagem(classeDefinicao: classeGuerreiro, nivel: 2),
        ],
      );

      final poderNivelAlto = const Poder(
        key: 'GOLPE_AVASSALADOR',
        nome: 'Golpe Avassalador',
        descricao: 'Dano massivo',
        nivelMinimo: 6,
      );

      final resNivel = PoderValidadorService.validar(
        personagem: personagem,
        classeDoPersonagem: personagem.classes.first,
        poder: poderNivelAlto,
      );

      expect(resNivel.ehElegivel, false);
      expect(
        resNivel.pendencias.any((r) => r.descricao.contains('6º nível')),
        true,
      );

      final poderFor13 = const Poder(
        key: 'DESTRUIDOR',
        nome: 'Destruidor',
        descricao: 'Rerrola 1 ou 2 no dano',
        atributosExigidos: {'FOR': 13}, // Exige mod +1, personagem tem +2
      );

      final resFor = PoderValidadorService.validar(
        personagem: personagem,
        classeDoPersonagem: personagem.classes.first,
        poder: poderFor13,
      );

      expect(resFor.ehElegivel, true);
      expect(resFor.requisitos.first.atendido, true);
    });

    test('Valida caminho de classe exigido', () {
      final caminhoBruxo = const CaminhoDeClasse(
        nome: 'Bruxo',
        descricao: 'Usa foco mágico',
        atributoChave: 'INT',
        temFocoMagico: true,
      );

      final personagemBruxo = Personagem(
        nome: 'Vectorius',
        atributos: {
          'FOR': const Atributo(nome: 'Força', valor: 0),
          'DES': const Atributo(nome: 'Destreza', valor: 0),
          'CON': const Atributo(nome: 'Constituição', valor: 0),
          'INT': const Atributo(nome: 'Inteligência', valor: 3),
          'SAB': const Atributo(nome: 'Sabedoria', valor: 0),
          'CAR': const Atributo(nome: 'Carisma', valor: 0),
        },
        classes: [
          ClasseDoPersonagem(
            classeDefinicao: classeGuerreiro,
            nivel: 3,
            caminhoEscolhido: caminhoBruxo,
          ),
        ],
      );

      final poderMago = const Poder(
        key: 'TINTA_DO_MAGO',
        nome: 'Tinta do Mago',
        descricao: 'Escreve pergaminhos',
        caminhosExigidos: ['Mago'],
      );

      final res = PoderValidadorService.validar(
        personagem: personagemBruxo,
        classeDoPersonagem: personagemBruxo.classes.first,
        poder: poderMago,
      );

      expect(res.ehElegivel, false);
      expect(
        res.pendencias.any((r) => r.descricao.contains('Caminho: Mago')),
        true,
      );
    });
  });
}
