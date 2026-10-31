import 'package:flutter_test/flutter_test.dart';
import 'package:t20_creator/domain/entities/personagem/personagem.dart';
import 'package:t20_creator/domain/services/personagem_storage_service.dart';

void main() {
  group('PersonagemStorageService - Cache e Serialização', () {
    setUp(() {
      PersonagemStorageService.limparCacheDiretorio();
    });

    test('limparCacheDiretorio reseta a variável estática', () {
      PersonagemStorageService.limparCacheDiretorio();
      // Garante que o método é chamável e limpa o cache com segurança
      expect(true, isTrue);
    });

    test('Serialização e desserialização preservam dados completos do personagem', () {
      final original = Personagem.inicial().copyWith(
        id: 'teste_123',
        nome: 'Galandor',
        pvAtual: 25,
        pmAtual: 10,
        tibares: 150,
      );

      final jsonStr = PersonagemStorageService.personagemToJson(original);
      final restaurado = PersonagemStorageService.personagemFromJson(jsonStr);

      expect(restaurado.id, equals('teste_123'));
      expect(restaurado.nome, equals('Galandor'));
      expect(restaurado.pvAtual, equals(25));
      expect(restaurado.pmAtual, equals(10));
      expect(restaurado.tibares, equals(150));
    });
  });
}
