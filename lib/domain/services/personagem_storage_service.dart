import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../entities/personagem.dart';
import '../entities/atributos.dart';
import 'banco_racas.dart';
import 'banco_classes.dart';
import 'banco_origens.dart';
import 'banco_divindades.dart';
import 'banco_poderes.dart';
import 'banco_armas.dart';
import '../entities/classe_do_personagem.dart';
import '../entities/poder.dart';
import '../entities/arma.dart';

class PersonagemStorageService {
  // Retorna a pasta interna onde o app tem permissão de escrita no Android
  static Future<Directory> _getDiretorioPersonagens() async {
    final appDir = await getApplicationDocumentsDirectory();
    final pasta = Directory('${appDir.path}/personagens');
    if (!await pasta.exists()) {
      await pasta.create(recursive: true);
    }
    return pasta;
  }

  // 1. SALVAR PERSONAGEM
  static Future<void> salvarPersonagem(Personagem p) async {
    final pasta = await _getDiretorioPersonagens();
    final arquivo = File('${pasta.path}/personagem_${p.id}.json');

    // Converte o Personagem em Map e depois em String JSON
    final jsonString = jsonEncode(_personagemToMap(p));
    await arquivo.writeAsString(jsonString);
  }

  // 2. CARREGAR TODOS OS PERSONAGENS SALVOS
  static Future<List<Personagem>> carregarTodos() async {
    final pasta = await _getDiretorioPersonagens();
    final arquivos = pasta.listSync().whereType<File>().where(
      (f) => f.path.endsWith('.json'),
    );

    List<Personagem> lista = [];
    for (var arq in arquivos) {
      try {
        final conteudo = await arq.readAsString();
        final map = jsonDecode(conteudo);
        lista.add(_mapToPersonagem(map));
      } catch (e) {
        if (kDebugMode) {
          print("Erro ao carregar personagem do arquivo ${arq.path}: $e");
        }
      }
    }
    return lista;
  }

  // 3. EXCLUIR PERSONAGEM
  static Future<void> excluirPersonagem(String id) async {
    final pasta = await _getDiretorioPersonagens();
    final arquivo = File('${pasta.path}/personagem_$id.json');
    if (await arquivo.exists()) {
      await arquivo.delete();
    }
  }

  // SERIALIZAÇÃO (Personagem -> Map)
  static Map<String, dynamic> _personagemToMap(Personagem p) {
    return {
      'id': p.id,
      'nome': p.nome,
      'idade': p.idade,
      'alinhamento': p.alinhamento,
      'descricaoAparencia': p.descricaoAparencia,
      'caminhoFoto': p.caminhoFoto,
      'tamanho': p.tamanho,
      'peso': p.peso,
      'altura': p.altura,
      'pvAtual': p.pvAtual,
      'pmAtual': p.pmAtual,
      'experienciaAtual': p.experienciaAtual,
      'racaNome': p.raca?.nome,
      'origemId': p.origem?.id,
      'divindadeId': p.divindade?.id,
      'poderConcedidoKey': p.poderConcedido?.key,
      'itensInventario': p.itensInventario,
      'armasKeys': p.armas.map((a) => a.key).toList(),
      'tibares': p.tibares,
      'periciasTreinadas': p.periciasTreinadas,
      'atributos': p.atributos.map((k, v) => MapEntry(k, v.valor)),
      'classes': p.classes
          .map(
            (c) => {
              'idClasse': c.classeDefinicao.idClasse,
              'nivel': c.nivel,
              'caminho': c.caminhoEscolhido?.nome,
              'poderesEscolhidosKeys':
                  c.poderesEscolhidos.map((pod) => pod.key).toList(),
            },
          )
          .toList(),
    };
  }

  // DESSERIALIZAÇÃO (Map -> Personagem)
  static Personagem _mapToPersonagem(Map<String, dynamic> map) {
    // Reconstrói atributos
    final Map<String, dynamic> rawAtrib = map['atributos'] ?? {};
    final Map<String, Atributo> atribs = {
      'FOR': Atributo(nome: 'Força', valor: rawAtrib['FOR'] ?? 0),
      'DES': Atributo(nome: 'Destreza', valor: rawAtrib['DES'] ?? 0),
      'CON': Atributo(nome: 'Constituição', valor: rawAtrib['CON'] ?? 0),
      'INT': Atributo(nome: 'Inteligência', valor: rawAtrib['INT'] ?? 0),
      'SAB': Atributo(nome: 'Sabedoria', valor: rawAtrib['SAB'] ?? 0),
      'CAR': Atributo(nome: 'Carisma', valor: rawAtrib['CAR'] ?? 0),
    };

    // Reconstrói raça, origem e divindade pelos catálogos existentes
    final raca = map['racaNome'] != null
        ? BancoDeRacas.todas.firstWhere(
            (r) => r.nome == map['racaNome'],
            orElse: () => BancoDeRacas.todas.first,
          )
        : null;

    final origem = map['origemId'] != null
        ? BancoDeOrigens.getById(map['origemId'])
        : null;

    final divindade = map['divindadeId'] != null
        ? BancoDeDivindades.getById(map['divindadeId'])
        : null;

    Poder? poderConcedido;
    if (divindade != null && map['poderConcedidoKey'] != null) {
      poderConcedido = divindade.poderesConcedidos
          .where((p) => p.key == map['poderConcedidoKey'])
          .firstOrNull;
    }

    // Reconstrói classes com caminho e poderes escolhidos
    List<ClasseDoPersonagem> classesList = [];
    if (map['classes'] != null) {
      for (var c in map['classes']) {
        final def = BancoDeClasses.todas.firstWhere(
          (cl) => cl.idClasse == c['idClasse'],
        );
        final caminho = c['caminho'] != null
            ? def.caminhosDisponiveis
                .where((cam) => cam.nome == c['caminho'])
                .firstOrNull
            : null;

        final List<dynamic> poderesKeysRaw = c['poderesEscolhidosKeys'] ?? [];
        final List<Poder> poderesCarregados = [];
        for (var k in poderesKeysRaw) {
          final pod = BancoDePoderes.getByKey(k.toString());
          if (pod != null) {
            poderesCarregados.add(pod);
          }
        }

        classesList.add(
          ClasseDoPersonagem(
            classeDefinicao: def,
            nivel: (c['nivel'] as num?)?.toInt() ?? 1,
            caminhoEscolhido: caminho,
            poderesEscolhidos: poderesCarregados,
          ),
        );
      }
    }

    // Reconstrói armas a partir das chaves
    final List<dynamic> armasKeysRaw = map['armasKeys'] ?? [];
    final List<Arma> armasList = [];
    for (var k in armasKeysRaw) {
      final arma = BancoDeArmas.getByKey(k.toString());
      if (arma != null) {
        armasList.add(arma);
      }
    }

    return Personagem(
      id: map['id']?.toString(),
      nome: map['nome'] ?? 'Aventureiro',
      idade: (map['idade'] as num?)?.toInt() ?? 20,
      alinhamento: map['alinhamento'] ?? 'Neutro',
      descricaoAparencia: map['descricaoAparencia'] ?? '',
      caminhoFoto: map['caminhoFoto'],
      tamanho: map['tamanho'] ?? 'Médio',
      peso: map['peso']?.toString() ?? '70 kg',
      altura: map['altura']?.toString() ?? '1.70 m',
      pvAtual: (map['pvAtual'] as num?)?.toInt(),
      pmAtual: (map['pmAtual'] as num?)?.toInt(),
      experienciaAtual: (map['experienciaAtual'] as num?)?.toInt() ?? 0,
      atributos: atribs,
      raca: raca,
      classes: classesList,
      origem: origem,
      divindade: divindade,
      poderConcedido: poderConcedido,
      itensInventario: List<String>.from(
        map['itensInventario'] ?? (origem?.itensIniciais ?? const []),
      ),
      armas: armasList,
      tibares: (map['tibares'] as num?)?.toInt() ?? 0,
      periciasTreinadas: List<String>.from(map['periciasTreinadas'] ?? []),
    );
  }
}
