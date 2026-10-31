import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../entities/personagem/personagem.dart';
import '../entities/personagem/atributos.dart';
import 'data_services/call_racas.dart';
import '../services/data_services/call_classes.dart';
import 'data_services/call_origens.dart';
import 'data_services/call_divindades.dart';
import '../entities/personagem/divindade.dart';
import 'data_services/call_poderes.dart';
import 'data_services/call_armas.dart';
import 'data_services/call_armaduras.dart';
import '../entities/personagem/classe_do_personagem.dart';
import '../entities/personagem/poder.dart';
import '../entities/equipamento/arma.dart';
import '../entities/equipamento/protecao.dart';
import '../entities/equipamento/item_vestido.dart';
import '../entities/personagem/efeito_temporario.dart';
import '../entities/habilidades_complexas/forma_selvagem.dart';
import '../entities/habilidades_complexas/golpe_pessoal.dart';
import '../entities/habilidades_complexas/engenhoca.dart';
import '../entities/habilidades_complexas/montaria_sagrada.dart';
import '../repositories/i_personagem_repository.dart';

class PersonagemStorageService implements IPersonagemRepository {
  const PersonagemStorageService();

  @override
  Future<void> salvar(Personagem p) => salvarPersonagem(p);

  @override
  Future<List<Personagem>> obterTodos() => carregarTodos();

  @override
  Future<Personagem?> obterPorId(String id) async {
    final todos = await carregarTodos();
    try {
      return todos.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> excluir(String id) => excluirPersonagem(id);

  static Directory? _cachedDiretorioPersonagens;

  @visibleForTesting
  static void limparCacheDiretorio() {
    _cachedDiretorioPersonagens = null;
  }

  // Retorna a pasta interna onde o app tem permissão de escrita no Android
  static Future<Directory> _getDiretorioPersonagens() async {
    if (_cachedDiretorioPersonagens != null) {
      return _cachedDiretorioPersonagens!;
    }
    final appDir = await getApplicationDocumentsDirectory();
    final pasta = Directory('${appDir.path}/personagens');
    if (!await pasta.exists()) {
      await pasta.create(recursive: true);
    }
    _cachedDiretorioPersonagens = pasta;
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
    final entidades = await pasta.list().toList();
    final arquivos = entidades.whereType<File>().where(
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
  static String personagemToJson(Personagem p) =>
      jsonEncode(personagemToMap(p));
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
      'anotacoes': p.anotacoes,
      'notasProgressaoPorNivel': p.notasProgressaoPorNivel.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
      'caminhoFoto': p.caminhoFoto,
      'tamanho': p.tamanho,
      'peso': p.peso,
      'altura': p.altura,
      'pvAtual': p.pvAtual,
      'pmAtual': p.pmAtual,
      'experienciaAtual': p.experienciaAtual,
      'racaNome': p.raca?.nome,
      'racaId': p.raca?.id,
      'atributosVariaveisRaca': p.atributosVariaveisRaca,
      'origemId': p.origem?.id,
      'poderesGeraisKeys': p.poderesGerais.map((pod) => pod.key).toList(),
      'divindadeId': p.divindade?.id,
      'poderesConcedidosKeys': p.poderesConcedidos
          .map((pod) => pod.key)
          .toList(),
      'poderConcedidoKey': p.poderConcedido?.key,
      'canalizacaoEnergia': p.canalizacaoEnergia?.name,
      'punicaoDivinaAtiva': p.punicaoDivinaAtiva,
      'magiasConhecidas': p.magiasConhecidas,
      'outrosBonusCDMagia': p.outrosBonusCDMagia,
      'itensInventario': p.itensInventario,
      'itensVestidosExtras': p.itensVestidosExtras
          .map((item) => item.toJson())
          .toList(),
      'armasKeys': p.armas.map((a) => a.key).toList(),
      'armaduraKey': p.armaduraEquipada?.key,
      'escudoKey': p.escudoEquipado?.key,
      'tibaresCobre': p.tibaresCobre,
      'tibares': p.tibares,
      'tibaresOuro': p.tibaresOuro,
      'outrosBonusDefesa': p.outrosBonusDefesa,
      'rdPadrao': p.rdPadrao,
      'rdsDiversas': p.rdsDiversas,
      'proficienciasExtras': p.proficienciasExtras,
      'efeitosTemporarios': p.efeitosTemporarios
          .map((e) => e.toJson())
          .toList(),
      'golpesPessoais': p.golpesPessoais.map((g) => g.toJson()).toList(),
      'engenhocas': p.engenhocas.map((e) => e.toJson()).toList(),
      'formaSelvagemAtiva': p.formaSelvagemAtiva?.toJson(),
      'tipoCompanheiroAnimal': p.tipoCompanheiroAnimal,
      'montariaSagrada': p.montariaSagrada?.toJson(),
      'periciasTreinadas': p.periciasTreinadas,
      'outrosBonusPericias': p.outrosBonusPericias,
      'atributos': p.atributos.map((k, v) => MapEntry(k, v.valor)),
      'classes': p.classes
          .map(
            (c) => {
              'idClasse': c.classeDefinicao.idClasse,
              'nivel': c.nivel,
              'caminho': c.caminhoEscolhido?.nome,
              'periciasExclusivasEscolhidas': c.periciasExclusivasEscolhidas,
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

    final List<Poder> poderesGeraisList = [];
    if (map['poderesGeraisKeys'] != null && map['poderesGeraisKeys'] is List) {
      for (final k in map['poderesGeraisKeys']) {
        final keyStr = k.toString();
        Poder? pod;
        if (origem != null && origem.poderUnico.key == keyStr) {
          pod = origem.poderUnico;
        } else if (origem != null) {
          pod = origem.poderesGeraisOpcoes
              .where((p) => p.key == keyStr)
              .firstOrNull;
        }
        pod ??=
            BancoDeOrigens.getHabilidadeUnica(keyStr) ??
            BancoDePoderes.getByKey(keyStr);
        if (pod != null && !poderesGeraisList.any((p) => p.key == pod!.key)) {
          poderesGeraisList.add(pod);
        }
      }
    }

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

        final Map<String, String> periciasExclusivas = {};
        if (c['periciasExclusivasEscolhidas'] != null &&
            c['periciasExclusivasEscolhidas'] is Map) {
          (c['periciasExclusivasEscolhidas'] as Map).forEach((k, v) {
            periciasExclusivas[k.toString()] = v.toString();
          });
        }

        classesList.add(
          ClasseDoPersonagem(
            classeDefinicao: def,
            nivel: (c['nivel'] as num?)?.toInt() ?? 1,
            caminhoEscolhido: caminho,
            periciasExclusivasEscolhidas: periciasExclusivas,
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

    final List<ItemVestido> itensVestidosList = [];
    if (map['itensVestidosExtras'] is List) {
      for (final rawItem in map['itensVestidosExtras']) {
        if (rawItem is Map) {
          itensVestidosList.add(
            ItemVestido.fromJson(Map<String, dynamic>.from(rawItem)),
          );
        }
      }
    }

    final List<EfeitoTemporario> efeitosTempList = [];
    if (map['efeitosTemporarios'] is List) {
      for (final rawEf in map['efeitosTemporarios']) {
        if (rawEf is Map) {
          efeitosTempList.add(
            EfeitoTemporario.fromJson(Map<String, dynamic>.from(rawEf)),
          );
        }
      }
    }

    final Map<String, int> outrosBonusPericiasMap = {};
    if (map['outrosBonusPericias'] is Map) {
      (map['outrosBonusPericias'] as Map).forEach((k, v) {
        final parsed = (v as num?)?.toInt() ?? int.tryParse(v.toString()) ?? 0;
        if (parsed != 0) {
          outrosBonusPericiasMap[k.toString()] = parsed;
        }
      });
    }

    final Map<int, String> notasProgressaoMap = {};
    if (map['notasProgressaoPorNivel'] is Map) {
      (map['notasProgressaoPorNivel'] as Map).forEach((k, v) {
        final nivel = int.tryParse(k.toString());
        final texto = v?.toString() ?? '';
        if (nivel != null && texto.trim().isNotEmpty) {
          notasProgressaoMap[nivel] = texto;
        }
      });
    }

    final formaSelvagem = map['formaSelvagemAtiva'] != null
        ? FormaSelvagemAtiva.fromJson(
            Map<String, dynamic>.from(map['formaSelvagemAtiva']),
          )
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
        ? MontariaSagrada.fromJson(
            Map<String, dynamic>.from(map['montariaSagrada']),
          )
        : null;

    return Personagem(
      id: map['id']?.toString(),
      nome: map['nome'] ?? 'Aventureiro',
      idade: (map['idade'] as num?)?.toInt() ?? 20,
      alinhamento: map['alinhamento'] ?? 'Neutro',
      descricaoAparencia: map['descricaoAparencia'] ?? '',
      anotacoes: map['anotacoes']?.toString() ?? '',
      notasProgressaoPorNivel: notasProgressaoMap,
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
      poderesGerais: poderesGeraisList,
      divindade: divindade,
      poderesConcedidos: poderesConcedidosList,
      canalizacaoEnergia: canalizacao,
      punicaoDivinaAtiva: punicaoDivina,
      magiasConhecidas: List<String>.from(map['magiasConhecidas'] ?? []),
      outrosBonusCDMagia: (map['outrosBonusCDMagia'] as num?)?.toInt() ?? 0,
      itensInventario: List<String>.from(
        map['itensInventario'] ?? (origem?.itensIniciais ?? const []),
      ),
      itensVestidosExtras: itensVestidosList,
      armas: armasList,
      armaduraEquipada: armadura,
      escudoEquipado: escudo,
      tibaresCobre: (map['tibaresCobre'] as num?)?.toInt() ?? 0,
      tibares: (map['tibares'] as num?)?.toInt() ?? 0,
      tibaresOuro: (map['tibaresOuro'] as num?)?.toInt() ?? 0,
      outrosBonusDefesa: (map['outrosBonusDefesa'] as num?)?.toInt() ?? 0,
      rdPadrao: (map['rdPadrao'] as num?)?.toInt() ?? 0,
      rdsDiversas: List<String>.from(map['rdsDiversas'] ?? const []),
      proficienciasExtras: List<String>.from(
        map['proficienciasExtras'] ?? const [],
      ),
      efeitosTemporarios: efeitosTempList,
      golpesPessoais: golpes,
      engenhocas: engenhocasList,
      formaSelvagemAtiva: formaSelvagem,
      tipoCompanheiroAnimal: map['tipoCompanheiroAnimal']?.toString(),
      montariaSagrada: montariaSagrada,
      periciasTreinadas: List<String>.from(map['periciasTreinadas'] ?? []),
      outrosBonusPericias: outrosBonusPericiasMap,
      atributosVariaveisRaca: List<String>.from(
        map['atributosVariaveisRaca'] ?? [],
      ),
    );
  }
}
