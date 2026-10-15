import 'package:flutter_test/flutter_test.dart';
import 'package:t20_creator/domain/entities/combate/combatente.dart';
import 'package:t20_creator/domain/entities/combate/estado_vida_combatente.dart';
import 'package:t20_creator/domain/entities/combate/monstro.dart';
import 'package:t20_creator/domain/entities/equipamento/arma.dart';
import 'package:t20_creator/domain/entities/personagem/personagem.dart';

void main() {
  group('Modelagem Polimórfica de Combatentes (T20)', () {
    test('CombatenteJogador delega corretamente para a ficha do Personagem', () {
      final p = Personagem.inicial().copyWith(
        nome: 'Sir Loras',
        pvAtual: 25,
        pmAtual: 10,
      );

      final combatente = Combatente.doPersonagem(p);

      expect(combatente, isA<CombatenteJogador>());
      expect(combatente.nome, equals('Sir Loras'));
      expect(combatente.time, equals(TimeCombatente.heroi));
      expect(combatente.pvAtual, equals(25));
      expect(combatente.pmAtual, equals(10));
      expect(combatente.defesa, equals(p.defesaFinal));
      expect(combatente.modIniciativa, equals(p.getValorPericia('INICIATIVA')));

      // Testando aplicação de dano
      final ferido = combatente.aplicarDano(10);
      expect(ferido.pvAtual, equals(15));
      expect(ferido, isA<CombatenteJogador>());
      expect((ferido as CombatenteJogador).ficha.nome, equals('Sir Loras'));
    });

    test('CombatenteMonstro adapta ameaça de T20 (Livro das Ameaças)', () {
      const lobisomem = Monstro(
        id: 'lobisomem_alfa',
        nome: 'Lobisomem Alfa',
        nd: '3',
        papel: PapelMonstro.solo,
        tipoCriatura: 'Monstro',
        pvMax: 80,
        defesa: 22,
        deslocamentoMetros: 12.0,
        iniciativa: 8,
        percepcao: 6,
        modForca: 5,
        modDestreza: 4,
        modConstituicao: 4,
        ataques: [
          AtaqueMonstro(
            nome: 'Mordida',
            bonusAtaque: 12,
            dano: '2d6+7',
            margemAmeaca: 19,
            multiplicadorCritico: 2,
            tipoDano: TipoDanoArma.perfuracao,
            descricaoEfeito: 'Transmissão de Licantropia (CD 16)',
          ),
          AtaqueMonstro(
            nome: 'Garras',
            bonusAtaque: 12,
            dano: '1d8+7',
            tipoDano: TipoDanoArma.corte,
          ),
        ],
      );

      final combatente = Combatente.doMonstro(
        lobisomem,
        idInstancia: 'lobo_instancia_1',
      );

      expect(combatente, isA<CombatenteMonstro>());
      expect(combatente.id, equals('lobo_instancia_1'));
      expect(combatente.nome, equals('Lobisomem Alfa'));
      expect(combatente.time, equals(TimeCombatente.inimigo));
      expect(combatente.pvMax, equals(80));
      expect(combatente.pvAtual, equals(80));
      expect(combatente.defesa, equals(22));
      expect(combatente.deslocamentoMetros, equals(12.0));
      expect(combatente.modIniciativa, equals(8));
      expect(combatente.modLuta, equals(12));

      // As armas do monstro devem ser geradas a partir do bloco de ataques
      expect(combatente.armas.length, equals(2));
      expect(combatente.armas[0].nome, equals('Mordida'));
      expect(combatente.armas[0].dano, equals('2d6+7'));
      expect(combatente.armas[0].margemAmeaca, equals(19));
      expect(combatente.armas[1].nome, equals('Garras'));
      expect(combatente.armas[1].dano, equals('1d8+7'));

      // Testando dano e estado de vida
      final ferido = combatente.aplicarDano(40);
      expect(ferido.pvAtual, equals(40));
      expect(ferido.estadoVida, equals(EstadoVidaCombatente.ativo));

      // Dano fatal
      final morto = ferido.aplicarDano(90);
      expect(morto.pvAtual, equals(-50));
      expect(morto.estaMorto, isTrue);
    });

    test('Pattern matching exaustivo no Dart 3 com sealed class Combatente', () {
      final p = Personagem.inicial();
      final jogador = Combatente.doPersonagem(p);
      const monstro = Monstro(
        id: 'goblin',
        nome: 'Goblin',
        nd: '1/4',
        pvMax: 10,
        defesa: 13,
        iniciativa: 4,
      );
      final ameaca = Combatente.doMonstro(monstro);
      const generico = Combatente(
        id: 'npc',
        nome: 'Camponês',
        pvMax: 8,
        pvAtual: 8,
        pmMax: 0,
        pmAtual: 0,
        defesa: 10,
        modIniciativa: 0,
        modLuta: 0,
        modPontaria: 0,
        modPercepcao: 0,
        modForca: 0,
        modDestreza: 0,
        modConstituicao: 0,
      );

      String identificarTipo(Combatente c) {
        return switch (c) {
          CombatenteJogador() => 'jogador',
          CombatenteMonstro() => 'monstro',
          CombatenteGenerico() => 'generico',
        };
      }

      expect(identificarTipo(jogador), equals('jogador'));
      expect(identificarTipo(ameaca), equals('monstro'));
      expect(identificarTipo(generico), equals('generico'));
    });
  });
}
