import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../entities/personagem/poder.dart';

/// Serviço centralizado para carregamento e busca de Poderes Gerais
/// (Combate, Destino, Magia e Tormenta) a partir dos arquivos JSON normalizados.
class BancoDePoderesGerais {
  static List<Poder> _combate = [];
  static List<Poder> _destino = [];
  static List<Poder> _magia = [];
  static List<Poder> _tormenta = [];
  static final Map<String, Poder> _indexPorChave = {};

  static List<Poder> _parsearMapaPoderes(
    String raw, {
    String? categoriaDefault,
  }) {
    final dynamic decoded = jsonDecode(raw);
    final List<Poder> lista = [];
    if (decoded is Map<String, dynamic>) {
      decoded.forEach((key, val) {
        if (val is Map<String, dynamic>) {
          final mapaItem = Map<String, dynamic>.from(val);
          mapaItem['key'] ??= key;
          if (categoriaDefault != null) {
            mapaItem['categoria'] ??= categoriaDefault;
          }
          lista.add(Poder.fromJson(mapaItem));
        }
      });
    } else if (decoded is List) {
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          final mapaItem = Map<String, dynamic>.from(item);
          if (categoriaDefault != null) {
            mapaItem['categoria'] ??= categoriaDefault;
          }
          lista.add(Poder.fromJson(mapaItem));
        }
      }
    }
    return lista;
  }

  static void _reconstruirIndex() {
    _indexPorChave.clear();
    for (final lista in [_combate, _destino, _magia, _tormenta]) {
      for (final p in lista) {
        final k = p.key.trim().toLowerCase();
        _indexPorChave[k] = p;
        _indexPorChave[k.replaceAll('-', '_')] = p;
        _indexPorChave[k.replaceAll('_', '-')] = p;
      }
    }
  }

  static Future<String> _carregarAssetComFallback(List<String> caminhos) async {
    for (final path in caminhos) {
      try {
        return await rootBundle.loadString(path);
      } catch (_) {}
    }
    return '{}';
  }

  static String _carregarArquivoSyncComFallback(List<String> caminhos) {
    for (final path in caminhos) {
      try {
        final file = File(path);
        if (file.existsSync()) {
          return file.readAsStringSync();
        }
      } catch (_) {}
    }
    return '{}';
  }

  /// Carrega os catálogos de poderes de combate, destino, magia e tormenta via rootBundle
  static Future<void> carregar() async {
    try {
      final rawCombate = await _carregarAssetComFallback([
        'assets/data/poderes/poderes_combate.json',
      ]);
      final rawDestino = await _carregarAssetComFallback([
        'assets/data/poderes/poderes_destino.json',
      ]);
      final rawMagia = await _carregarAssetComFallback([
        'assets/data/poderes/poderes_magicos.json',
        'assets/data/poderes/poderes_magia.json',
      ]);
      final rawTormenta = await _carregarAssetComFallback([
        'assets/data/poderes/poderes_da_tormenta.json',
      ]);

      _combate = _parsearMapaPoderes(
        rawCombate,
        categoriaDefault: 'poder_combate',
      );
      _destino = _parsearMapaPoderes(
        rawDestino,
        categoriaDefault: 'poder_destino',
      );
      _magia = _parsearMapaPoderes(rawMagia, categoriaDefault: 'poder_magia');
      _tormenta = _parsearMapaPoderes(
        rawTormenta,
        categoriaDefault: 'poder_tormenta',
      );
      _reconstruirIndex();
    } catch (_) {}
  }

  static void _garantirCarregadoSync() {
    if (_indexPorChave.isEmpty) {
      try {
        final rawCombate = _carregarArquivoSyncComFallback([
          'assets/data/poderes/poderes_combate.json',
        ]);
        final rawDestino = _carregarArquivoSyncComFallback([
          'assets/data/poderes/poderes_destino.json',
        ]);
        final rawMagia = _carregarArquivoSyncComFallback([
          'assets/data/poderes/poderes_magicos.json',
          'assets/data/poderes/poderes_magia.json',
        ]);
        final rawTormenta = _carregarArquivoSyncComFallback([
          'assets/data/poderes/poderes_da_tormenta.json',
        ]);

        _combate = _parsearMapaPoderes(
          rawCombate,
          categoriaDefault: 'poder_combate',
        );
        _destino = _parsearMapaPoderes(
          rawDestino,
          categoriaDefault: 'poder_destino',
        );
        _magia = _parsearMapaPoderes(rawMagia, categoriaDefault: 'poder_magia');
        _tormenta = _parsearMapaPoderes(
          rawTormenta,
          categoriaDefault: 'poder_tormenta',
        );
        _reconstruirIndex();
      } catch (_) {}
    }
  }

  @visibleForTesting
  static void carregarParaTestes({
    List<Poder>? combate,
    List<Poder>? destino,
    List<Poder>? magia,
    List<Poder>? tormenta,
  }) {
    _combate = combate != null ? List.from(combate) : [];
    _destino = destino != null ? List.from(destino) : [];
    _magia = magia != null ? List.from(magia) : [];
    _tormenta = tormenta != null ? List.from(tormenta) : [];
    _reconstruirIndex();
  }

  /// Lista completa de Poderes de Combate (`poderes_combate.json`)
  static List<Poder> get poderesCombate {
    _garantirCarregadoSync();
    return List.unmodifiable(_combate);
  }

  /// Lista completa de Poderes de Destino (`poderes_destino.json`)
  static List<Poder> get poderesDestino {
    _garantirCarregadoSync();
    return List.unmodifiable(_destino);
  }

  /// Lista completa de Poderes de Magia (`poderes_magicos.json` / `poderes_magia.json`)
  static List<Poder> get poderesMagia {
    _garantirCarregadoSync();
    return List.unmodifiable(_magia);
  }

  /// Lista completa de Poderes da Tormenta (`poderes_da_tormenta.json`)
  static List<Poder> get poderesTormenta {
    _garantirCarregadoSync();
    return List.unmodifiable(_tormenta);
  }

  /// Lista unificada com todos os Poderes Gerais (Combate, Destino, Magia e Tormenta)
  static List<Poder> get todos {
    _garantirCarregadoSync();
    return List.unmodifiable([
      ..._combate,
      ..._destino,
      ..._magia,
      ..._tormenta,
    ]);
  }

  /// Procura um poder geral pela sua chave/ID em O(1)
  static Poder? getByKey(String key) {
    _garantirCarregadoSync();
    final clean = key.trim().toLowerCase();
    return _indexPorChave[clean] ??
        _indexPorChave[clean.replaceAll('-', '_')] ??
        _indexPorChave[clean.replaceAll('_', '-')];
  }

  /// Resolve a lista de opções de poderes gerais de uma origem a partir de
  /// `poderesGeraisOpcoesIds` e da flag `escolhaLivrePoderCombate`.
  static List<Poder> resolverOpcoesOrigem({
    required List<String> poderesGeraisOpcoesIds,
    required bool escolhaLivrePoderCombate,
  }) {
    _garantirCarregadoSync();
    final List<Poder> resultado = [];
    final Set<String> vistos = {};

    for (final id in poderesGeraisOpcoesIds) {
      final p = getByKey(id);
      if (p != null && vistos.add(p.key.toLowerCase())) {
        resultado.add(p);
      }
    }

    if (escolhaLivrePoderCombate) {
      for (final p in _combate) {
        if (vistos.add(p.key.toLowerCase())) {
          resultado.add(p);
        }
      }
    }

    return resultado;
  }
}

class BancoDePoderes {
  // O mapa guarda as listas usando o idClasse (ex: "ARCANISTA") como chave
  static Map<String, List<Poder>> _dados = {};
  static final Map<String, Poder> _indexPorChave = {};
  static final Map<String, Set<String>> _classesDonasPorChave = {};

  static void _popularMapas(Map<String, dynamic> jsonMap) {
    _dados = {};
    _indexPorChave.clear();
    _classesDonasPorChave.clear();

    jsonMap.forEach((chaveJson, lista) {
      final idUpper = chaveJson.toUpperCase();
      final poderes = (lista as List)
          .map((p) => Poder.fromJson(p as Map<String, dynamic>))
          .toList();
      _dados[idUpper] = poderes;
      for (final poder in poderes) {
        _indexPorChave[poder.key] = poder;
        _indexPorChave[poder.key.toUpperCase()] = poder;
        _classesDonasPorChave
            .putIfAbsent(poder.key.toUpperCase(), () => <String>{})
            .add(idUpper);
      }
    });
  }

  static void _garantirCarregadoSync() {
    if (_dados.isEmpty) {
      try {
        final file = File('assets/data/classes_data/banco_poderes_classe.json');
        if (file.existsSync()) {
          final raw = file.readAsStringSync();
          _popularMapas(jsonDecode(raw) as Map<String, dynamic>);
        }
      } catch (_) {}
    }
  }

  static Future<void> carregar() async {
    await BancoDePoderesGerais.carregar();

    String raw;
    try {
      raw = await rootBundle.loadString(
        'assets/data/classes_data/banco_poderes_classe.json',
      );
    } catch (_) {
      final file = File('assets/data/classes_data/banco_poderes_classe.json');
      raw = file.existsSync() ? file.readAsStringSync() : '{}';
    }

    _popularMapas(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// Método para injetar poderes em testes automatizados
  static void carregarParaTestes(Map<String, List<Poder>> dados) {
    _dados = {};
    _indexPorChave.clear();
    _classesDonasPorChave.clear();
    dados.forEach((idClasse, poderes) {
      final idUpper = idClasse.toUpperCase();
      _dados[idUpper] = List.from(poderes);
      for (final poder in poderes) {
        _indexPorChave[poder.key] = poder;
        _indexPorChave[poder.key.toUpperCase()] = poder;
        _classesDonasPorChave
            .putIfAbsent(poder.key.toUpperCase(), () => <String>{})
            .add(idUpper);
      }
    });
  }

  // Busca os poderes passando diretamente o idClasse da entidade Classe
  static List<Poder> poderesDaClasse(String idClasse) {
    _garantirCarregadoSync();
    return _dados[idClasse.toUpperCase()] ?? [];
  }

  /// Retorna o conjunto de IDs de classes (em maiúsculo) que possuem este poder como poder de classe,
  /// ou vazio caso seja um poder geral / customizado fora do catálogo de classes.
  static Set<String> obterClassesDonasDoPoder(String poderKey) {
    _garantirCarregadoSync();
    return _classesDonasPorChave[poderKey.toUpperCase()] ?? const {};
  }

  /// Busca um poder específico em O(1) pela chave (classe ou poder geral)
  static Poder? getByKey(String key) {
    _garantirCarregadoSync();
    return _indexPorChave[key] ??
        _indexPorChave[key.toUpperCase()] ??
        BancoDePoderesGerais.getByKey(key);
  }
}
