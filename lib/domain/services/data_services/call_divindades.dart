import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../entities/personagem/divindade.dart';
import '../../entities/personagem/poder.dart';

/// Serviço responsável pelo carregamento e acesso ao catálogo de divindades do Panteão
/// e seus respectivos poderes concedidos a partir dos arquivos JSON.
class BancoDeDivindades {
  static List<Divindade> _dados = [];
  static final Map<String, Divindade> _indexPorId = {};
  static final Map<String, Divindade> _indexPorNome = {};
  static Map<String, Poder> _catalogoPoderes = {};

  static void _reconstruirIndex() {
    _indexPorId.clear();
    _indexPorNome.clear();
    for (final d in _dados) {
      _indexPorId[d.id.trim().toLowerCase()] = d;
      _indexPorNome[d.nome.trim().toLowerCase()] = d;
    }
  }

  /// Converte o JSON do catálogo de poderes concedidos em um `Map<String, Poder>`
  static Map<String, Poder> _parsearCatalogoPoderes(String raw) {
    final dynamic decoded = jsonDecode(raw);
    final Map<String, Poder> mapa = {};
    if (decoded is Map<String, dynamic>) {
      decoded.forEach((key, val) {
        if (val is Map<String, dynamic>) {
          final poder = Poder.fromJson(val);
          mapa[key.trim().toLowerCase()] = poder;
          mapa[poder.key.trim().toLowerCase()] = poder;
        }
      });
    }
    return mapa;
  }

  /// Converte a string bruta em lista de divindades, associando os poderes do catálogo
  static List<Divindade> _parsearJson(String raw, Map<String, Poder> catalogo) {
    final dynamic decoded = jsonDecode(raw);
    final List<dynamic> jsonList = decoded is List
        ? decoded
        : (decoded['divindades'] as List<dynamic>? ?? []);

    final Map<String, Divindade> mapa = {};
    for (final item in jsonList) {
      if (item is Map<String, dynamic>) {
        final div = Divindade.fromJson(item, catalogoPoderes: catalogo);
        final idNorm = div.id.trim().toLowerCase();
        // Se já existir entrada com o mesmo ID, mantém a mais completa (com mais poderes)
        if (!mapa.containsKey(idNorm) ||
            div.poderesConcedidos.length >
                mapa[idNorm]!.poderesConcedidos.length) {
          mapa[idNorm] = div;
        }
      }
    }
    return mapa.values.toList();
  }

  /// Carrega tanto o catálogo de poderes concedidos quanto as divindades dos assets
  static Future<void> carregar() async {
    try {
      String rawPoderes;
      try {
        rawPoderes = await rootBundle.loadString(
          'assets/data/deuses/poderes_divinos.json',
        );
      } catch (_) {
        rawPoderes = await rootBundle.loadString(
          'assets/data/deuses/catalogo_poderes_concedidos.json',
        );
      }
      _catalogoPoderes = _parsearCatalogoPoderes(rawPoderes);
    } catch (_) {}

    try {
      final rawDeuses = await rootBundle.loadString(
        'assets/data/deuses/deuses.json',
      );
      _dados = _parsearJson(rawDeuses, _catalogoPoderes);
      _reconstruirIndex();
    } catch (_) {}
  }

  /// Método para injetar divindades e catálogo diretamente durante testes automatizados
  @visibleForTesting
  static void carregarParaTestes(
    List<Divindade> divindades, {
    Map<String, Poder>? catalogo,
  }) {
    _dados = List.from(divindades);
    if (catalogo != null) {
      _catalogoPoderes = Map.from(catalogo);
    }
    _reconstruirIndex();
  }

  /// Fallback síncrono para execução em ambiente de testes unitários
  static List<Divindade> _obterDados() {
    if (_dados.isEmpty) {
      try {
        File filePoderes = File('assets/data/deuses/poderes_divinos.json');
        if (!filePoderes.existsSync()) {
          filePoderes = File(
            'assets/data/deuses/catalogo_poderes_concedidos.json',
          );
        }
        if (filePoderes.existsSync()) {
          final rawPoderes = filePoderes.readAsStringSync();
          _catalogoPoderes = _parsearCatalogoPoderes(rawPoderes);
        }

        final fileDeuses = File('assets/data/deuses/deuses.json');
        if (fileDeuses.existsSync()) {
          final rawDeuses = fileDeuses.readAsStringSync();
          _dados = _parsearJson(rawDeuses, _catalogoPoderes);
          _reconstruirIndex();
        }
      } catch (_) {}
    }
    return _dados;
  }

  /// Retorna a lista de todas as divindades registradas (imutável).
  static List<Divindade> get todas => List.unmodifiable(_obterDados());

  /// Indica se os dados já foram carregados
  static bool get estaCarregado => _obterDados().isNotEmpty;

  /// Busca uma divindade pelo seu ID único em O(1) (ex: "khalmyr", "valkaria")
  static Divindade? getById(String id) {
    _obterDados();
    return _indexPorId[id.trim().toLowerCase()];
  }

  /// Busca uma divindade pelo seu nome em O(1) (ex: "Khalmyr", "Valkaria")
  static Divindade? getByNome(String nome) {
    _obterDados();
    return _indexPorNome[nome.trim().toLowerCase()];
  }

  /// Busca um poder concedido específico no catálogo pelo seu ID/Key em O(1)
  static Poder? getPoderConcedido(String key) {
    _obterDados();
    final clean = key.trim().toLowerCase();
    return _catalogoPoderes[clean] ??
        _catalogoPoderes[clean.replaceAll('-', '_')] ??
        _catalogoPoderes[clean.replaceAll('_', '-')];
  }

  /// Retorna todos os poderes únicos do catálogo de poderes concedidos
  static List<Poder> get todosPoderesConcedidos {
    _obterDados();
    final Set<String> chavesVistas = {};
    final List<Poder> unicos = [];
    for (final p in _catalogoPoderes.values) {
      if (chavesVistas.add(p.key.toLowerCase())) {
        unicos.add(p);
      }
    }
    return List.unmodifiable(unicos);
  }

  /// Retorna todos os poderes concedidos de uma divindade
  static List<Poder> obterTodosPoderesPorDivindade(String idDivindade) {
    final div = getById(idDivindade);
    if (div == null) return const [];
    return div.poderesConcedidos;
  }
}
