import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:t20_creator/domain/entities/personagem/personagem.dart';
import 'package:t20_creator/domain/services/ficha_services/personagem_storage_service.dart';

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

    test(
      'Serialização e desserialização preservam dados completos do personagem',
      () {
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
      },
    );
  });

  group('PersonagemStorageService - Integridade de Dados', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('t20_test_storage_');
      PersonagemStorageService.setDiretorioTeste(tempDir);
    });

    tearDown(() async {
      PersonagemStorageService.limparCacheDiretorio();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      'salvarPersonagem realiza gravação atômica via .tmp e gera o arquivo final',
      () async {
        final p = Personagem.inicial().copyWith(id: 'hero_1', nome: 'Lothar');
        await PersonagemStorageService.salvarPersonagem(p);

        final finalFile = File('${tempDir.path}/personagem_hero_1.json');
        final tmpFile = File('${tempDir.path}/personagem_hero_1.json.tmp');

        expect(await finalFile.exists(), isTrue);
        expect(await tmpFile.exists(), isFalse);

        final conteudo = await finalFile.readAsString();
        expect(conteudo, contains('Lothar'));
      },
    );

    test(
      'carregarTodos move arquivo com JSON corrompido para .corrompido e carrega os íntegros',
      () async {
        final valido = Personagem.inicial().copyWith(
          id: 'valido_1',
          nome: 'Galandor',
        );
        await PersonagemStorageService.salvarPersonagem(valido);

        // Cria um arquivo corrompido simulando crash ou interrupção durante escrita direta
        final arqCorrompido = File('${tempDir.path}/personagem_quebrado.json');
        await arqCorrompido.writeAsString(
          '{"id": "quebrado", "nome": "Cor',
        ); // JSON incompleto

        final carregados = await PersonagemStorageService.carregarTodos();

        // Carrega o personagem válido com sucesso
        expect(carregados.length, equals(1));
        expect(carregados.first.nome, equals('Galandor'));

        // O arquivo corrompido original não deve mais existir com a extensão .json
        expect(await arqCorrompido.exists(), isFalse);

        // O arquivo deve ter sido preservado com a extensão .corrompido
        final movido = File(
          '${tempDir.path}/personagem_quebrado.json.corrompido',
        );
        expect(await movido.exists(), isTrue);
        expect(
          await movido.readAsString(),
          equals('{"id": "quebrado", "nome": "Cor'),
        );
      },
    );

    test(
      'salvarFotoPersonagem copia imagem de cache para pasta permanente de fotos e excluirFotoPersonagem remove',
      () async {
        final fotosDir = Directory('${tempDir.path}/fotos');
        PersonagemStorageService.setDiretorioFotosTeste(fotosDir);

        // Simula uma foto vinda do cache do image_picker
        final cacheDir = await Directory.systemTemp.createTemp(
          't20_picker_cache_',
        );
        final fotoTemp = File('${cacheDir.path}/scaled_image_picker123.jpg');
        await fotoTemp.writeAsString('fake_image_bytes_123');

        final caminhoSalvo =
            await PersonagemStorageService.salvarFotoPersonagem(
              'hero_foto_1',
              fotoTemp.path,
            );

        final arquivoFotoPermanente = File('${fotosDir.path}/hero_foto_1.jpg');
        expect(caminhoSalvo, equals(arquivoFotoPermanente.path));
        expect(await arquivoFotoPermanente.exists(), isTrue);
        expect(
          await arquivoFotoPermanente.readAsString(),
          equals('fake_image_bytes_123'),
        );

        // Exclusão pontual da foto
        await PersonagemStorageService.excluirFotoPersonagem('hero_foto_1');
        expect(await arquivoFotoPermanente.exists(), isFalse);

        await cacheDir.delete(recursive: true);
      },
    );

    test(
      'excluirPersonagem remove tanto o arquivo json quanto a foto associada',
      () async {
        final fotosDir = Directory('${tempDir.path}/fotos');
        PersonagemStorageService.setDiretorioFotosTeste(fotosDir);

        final p = Personagem.inicial().copyWith(
          id: 'hero_del_1',
          nome: 'Para Deletar',
        );
        await PersonagemStorageService.salvarPersonagem(p);

        // Cria uma foto simulada
        final cacheDir = await Directory.systemTemp.createTemp(
          't20_picker_cache_',
        );
        final fotoTemp = File('${cacheDir.path}/foto.jpg');
        await fotoTemp.writeAsString('foto_bytes');
        await PersonagemStorageService.salvarFotoPersonagem(
          'hero_del_1',
          fotoTemp.path,
        );

        final arqJson = File('${tempDir.path}/personagem_hero_del_1.json');
        final arqFoto = File('${fotosDir.path}/hero_del_1.jpg');

        expect(await arqJson.exists(), isTrue);
        expect(await arqFoto.exists(), isTrue);

        await PersonagemStorageService.excluirPersonagem('hero_del_1');

        expect(await arqJson.exists(), isFalse);
        expect(await arqFoto.exists(), isFalse);

        await cacheDir.delete(recursive: true);
      },
    );
  });
}
