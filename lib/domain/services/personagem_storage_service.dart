import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../entities/personagem.dart';
import '../entities/atributos.dart';
import 'data_services/call_racas.dart';
import '../services/data_services/call_classes.dart';
import 'data_services/call_origens.dart';
import 'data_services/call_divindades.dart';
import '../entities/divindade.dart';
import 'data_services/call_poderes.dart';
import 'data_services/call_armas.dart';
import 'data_services/call_armaduras.dart';
import '../entities/classe_do_personagem.dart';
import '../entities/poder.dart';
import '../entities/arma.dart';
import '../entities/protecao.dart';
import '../entities/forma_selvagem.dart';
import '../entities/golpe_pessoal.dart';
import '../entities/engenhoca.dart';
import '../entities/montaria_sagrada.dart';

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
    final jsonString = jsonEncode(personagemToMap(p));
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
        lista.add(mapToPersonagem(map));
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

  // MÉTODOS PÚBLICOS DE SERIALIZAÇÃO / DESSERIALIZAÇÃO
  static String personagemToJson(Personagem p) => jsonEncode(personagemToMap(p));
  static Personagem personagemFromJson(String jsonStr) =>
      mapToPersonagem(jsonDecode(jsonStr) as Map<String, dynamic>);

  // SERIALIZAÇÃO (Personagem -> Map)
  static Map<String, dynamic> personagemToMap(Personagem p) {
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
      'racaId': p.raca?.id,
      'origemId': p.origem?.id,
      'divindadeId': p.divindade?.id,
      'poderesConcedidosKeys':
          p.poderesConcedidos.map((pod) => pod.key).toList(),
      'poderConcedidoKey': p.poderConcedido?.key,
      'canalizacaoEnergia': p.canalizacaoEnergia?.name,
      'punicaoDivinaAtiva': p.punicaoDivinaAtiva,
      'itensInventario': p.itensInventario,
      'armasKeys': p.armas.map((a) => a.key).toList(),
      'armaduraKey': p.armaduraEquipada?.key,
      'escudoKey': p.escudoEquipado?.key,
      'tibares': p.tibares,
      'golpesPessoais': p.golpesPessoais.map((g) => g.toJson()).toList(),
      'engenhocas': p.engenhocas.map((e) => e.toJson()).toList(),
      'formaSelvagemAtiva': p.formaSelvagemAtiva?.toJson(),
      'tipoCompanheiroAnimal': p.tipoCompanheiroAnimal,
      'montariaSagrada': p.montariaSagrada?.toJson(),
      'periciasTreinadas': p.periciasTreinadas,
      'atributos': p.atributos.map((k, v) => MapEntry(k, v.valor)),
      'classes': p.classes
          .map(
            (c) => {
              'idClasse': c.classeDefinicao.idClasse,
              'nivel': c.nivel,
              'caminho': c.caminhoEscolhido?.nome,
              'poderesEscolhidosKeys': c.poderesEscolhidos
                  .map((pod) => pod.key)
                  .toList(),
            },
          )
          .toList(),
    };
  }

  // DESSERIALIZAÇÃO (Map -> Personagem)
  static Personagem mapToPersonagem(Map<String, dynamic> map) {
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
    final raca = map['racaId'] != null
        ? BancoDeRacas.getById(map['racaId'])
        : (map['racaNome'] != null
              ? BancoDeRacas.getByNome(map['racaNome'])
              : null);

    final origem = map['origemId'] != null
        ? BancoDeOrigens.getById(map['origemId'])
        : null;

    final divindade = map['divindadeId'] != null
        ? BancoDeDivindades.getById(map['divindadeId'])
        : null;

    final List<Poder> poderesConcedidosList = [];
    if (divindade != null) {
      if (map['poderesConcedidosKeys'] != null) {
        final List<dynamic> keysRaw = map['poderesConcedidosKeys'];
        for (var k in keysRaw) {
          final pod = divindade.poderesConcedidos
              .where((p) => p.key == k)
              .firstOrNull;
          if (pod != null &&
              !poderesConcedidosList.any((p) => p.key == pod.key)) {
            poderesConcedidosList.add(pod);
          }
        }
      } else if (map['poderConcedidoKey'] != null) {
        final pod = divindade.poderesConcedidos
            .where((p) => p.key == map['poderConcedidoKey'])
            .firstOrNull;
        if (pod != null) {
          poderesConcedidosList.add(pod);
        }
      }
    }

    TipoEnergia? canalizacao;
    if (map['canalizacaoEnergia'] != null) {
      canalizacao = TipoEnergia.values
          .where((e) => e.name == map['canalizacaoEnergia'])
          .firstOrNull;
    } else if (divindade != null) {
      canalizacao = divindade.energiaCanalizada;
    }

    final bool punicaoDivina = map['punicaoDivinaAtiva'] as bool? ?? false;

    // Reconstrói classes com caminho e poderes escolhidos
    List<ClasseDoPersonagem> classesList = [];
    if (map['classes'] != null) {
      for (var c in map['classes']) {
        final idClasse = c['idClasse'] ?? c['id'];
        final def = idClasse != null
            ? (BancoDeClasses.getById(idClasse.toString()) ??
                  BancoDeClasses.getByNome(idClasse.toString()))
            : null;
        if (def == null) continue;

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

    // Reconstrói armadura e escudo
    final String? armaduraKey = map['armaduraKey'];
    final Protecao? armadura = armaduraKey != null
        ? BancoDeArmaduras.getByKey(armaduraKey)
        : null;

    final String? escudoKey = map['escudoKey'];
    final Protecao? escudo = escudoKey != null
        ? BancoDeArmaduras.getByKey(escudoKey)
        : null;

    final formaSelvagem = map['formaSelvagemAtiva'] != null
        ? FormaSelvagemAtiva.fromJson(Map<String, dynamic>.from(map['formaSelvagemAtiva']))
        : null;

    final List<GolpePessoal> golpes = [];
    if (map['golpesPessoais'] != null) {
      for (var g in map['golpesPessoais']) {
        if (g is Map) {
          golpes.add(GolpePessoal.fromJson(Map<String, dynamic>.from(g)));
        }
      }
    }

    final List<Engenhoca> engenhocasList = [];
    if (map['engenhocas'] != null) {
      for (var e in map['engenhocas']) {
        if (e is Map) {
          engenhocasList.add(Engenhoca.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }

    final montariaSagrada = map['montariaSagrada'] != null
        ? MontariaSagrada.fromJson(Map<String, dynamic>.from(map['montariaSagrada']))
        : null;

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
      poderesConcedidos: poderesConcedidosList,
      canalizacaoEnergia: canalizacao,
      punicaoDivinaAtiva: punicaoDivina,
      itensInventario: List<String>.from(
        map['itensInventario'] ?? (origem?.itensIniciais ?? const []),
      ),
      armas: armasList,
      armaduraEquipada: armadura,
      escudoEquipado: escudo,
      tibares: (map['tibares'] as num?)?.toInt() ?? 0,
      golpesPessoais: golpes,
      engenhocas: engenhocasList,
      formaSelvagemAtiva: formaSelvagem,
      tipoCompanheiroAnimal: map['tipoCompanheiroAnimal']?.toString(),
      montariaSagrada: montariaSagrada,
      periciasTreinadas: List<String>.from(map['periciasTreinadas'] ?? []),
    );
  }
}
