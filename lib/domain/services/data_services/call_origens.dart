import 'dart:collection';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../entities/personagem/origem.dart';
import '../../entities/personagem/poder.dart';
import 'call_poderes.dart';

class BancoDeOrigens {
  static List<Origem> _dados = [];
  static final Map<String, Origem> _indexPorId = {};
  static final Map<String, Origem> _indexPorNome = {};
  static Map<String, Poder> _catalogoHabilidadesUnicas = {};

  static void _reconstruirIndex() {
    _indexPorId.clear();
    _indexPorNome.clear();
    for (final o in _dados) {
      _indexPorId[o.id.trim().toLowerCase()] = o;
      _indexPorNome[o.nome.trim().toLowerCase()] = o;
    }
  }

  static Map<String, Poder> _parsearCatalogoHabilidades(String raw) {
    final dynamic decoded = jsonDecode(raw);
    final Map<String, Poder> mapa = {};
    if (decoded is Map<String, dynamic>) {
      decoded.forEach((key, val) {
        if (val is Map<String, dynamic>) {
          final item = Map<String, dynamic>.from(val);
          item['key'] ??= key;
          final poder = Poder.fromJson(item);
          mapa[key.trim().toLowerCase()] = poder;
          mapa[poder.key.trim().toLowerCase()] = poder;
        }
      });
    }
    return mapa;
  }

  static List<Origem> _parsearOrigens(
    String raw,
    Map<String, Poder> catalogoHabilidades,
  ) {
    final dynamic decoded = jsonDecode(raw);
    final List<dynamic> jsonList = decoded is List
        ? decoded
        : (decoded['origens'] as List<dynamic>? ?? []);

    final List<Poder> listaCombate = BancoDePoderesGerais.poderesCombate;

    return jsonList
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => Origem.fromJson(
            item,
            catalogoHabilidadesUnicas: catalogoHabilidades,
            buscarPoderGeral: BancoDePoderesGerais.getByKey,
            poderesCombate: listaCombate,
          ),
        )
        .toList();
  }

  static Future<String> _carregarAssetComFallback(List<String> caminhos) async {
    for (final path in caminhos) {
      try {
        return await rootBundle.loadString(path, cache: false);
      } catch (_) {}
    }
    return '';
  }

  /// Carrega o catálogo de habilidades únicas, poderes gerais e origens via rootBundle
  static Future<void> carregar() async {
    await BancoDePoderesGerais.carregar();

    try {
      final rawHabilidades = await _carregarAssetComFallback([
        'assets/data/origens/habilidades_origens.json',
        'assets/data/origens/catalogo_habilidades_origem_basico.json',
      ]);
      if (rawHabilidades.isNotEmpty) {
        _catalogoHabilidadesUnicas = _parsearCatalogoHabilidades(
          rawHabilidades,
        );
      } else {
        debugPrint('Aviso: Nenhum arquivo de habilidades de origem encontrado.');
        assert(false, 'Nenhum arquivo de habilidades de origem encontrado.');
      }
    } catch (e, stack) {
      debugPrint('Erro ao carregar habilidades de origem: $e\n$stack');
      assert(false, 'Erro ao carregar habilidades de origem: $e');
    }

    try {
      final rawOrigens = await _carregarAssetComFallback([
        'assets/data/origens/origens.json',
        'assets/data/banco_origens.json',
      ]);
      if (rawOrigens.isNotEmpty) {
        _dados = _parsearOrigens(rawOrigens, _catalogoHabilidadesUnicas);
        _reconstruirIndex();
      } else {
        debugPrint('Aviso: Nenhum arquivo de origens encontrado.');
        assert(false, 'Nenhum arquivo de origens encontrado.');
      }
    } catch (e, stack) {
      debugPrint('Erro ao carregar origens.json: $e\n$stack');
      assert(false, 'Erro ao carregar origens.json: $e');
    }
  }

  /// Método para injetar dados durante a execução de testes automatizados
  @visibleForTesting
  static void carregarParaTestes(
    List<Origem> origens, {
    Map<String, Poder>? catalogoHabilidades,
  }) {
    _dados = List.from(origens);
    if (catalogoHabilidades != null) {
      _catalogoHabilidadesUnicas = Map.from(catalogoHabilidades);
    }
    _reconstruirIndex();
  }

  /// Retorna todas as origens disponíveis (imutável, sem cópia)
  static List<Origem> get todas => UnmodifiableListView(_dados);

  /// Retorna se os dados já foram carregados
  static bool get estaCarregado => _dados.isNotEmpty;

  /// Busca uma origem pelo ID único em O(1) (ex: "acolito", "soldado")
  static Origem? getById(String id) {
    return _indexPorId[id.trim().toLowerCase()];
  }

  /// Busca uma origem pelo nome em O(1) (ex: "Acólito", "Soldado")
  static Origem? getByNome(String nome) {
    return _indexPorNome[nome.trim().toLowerCase()];
  }

  /// Resolve os detalhes de uma habilidade única de origem pelo seu `poderUnicoId`
  static Poder? getHabilidadeUnica(String poderUnicoId) {
    final norm = poderUnicoId.trim().toLowerCase();
    return _catalogoHabilidadesUnicas[norm] ??
        _catalogoHabilidadesUnicas[norm.replaceAll('-', '_')] ??
        _catalogoHabilidadesUnicas[norm.replaceAll('_', '-')];
  }

  /// Procura um poder geral definido em `poderesGeraisOpcoesIds` através da chave
  static Poder? buscarPoderGeral(String key) {
    return BancoDePoderesGerais.getByKey(key);
  }
}
