import 'dart:collection';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../entities/habilidades_complexas/companheiro_animal.dart';

class BancoDeCompanheiros {
  static List<TipoCompanheiroAnimal> _dados = [];
  static final Map<String, TipoCompanheiroAnimal> _indexPorChave = {};

  static void _reconstruirIndex() {
    _indexPorChave.clear();
    for (final c in _dados) {
      _indexPorChave[c.key.trim().toUpperCase()] = c;
    }
  }

  static List<TipoCompanheiroAnimal> _parse(String raw) {
    final Map<String, dynamic> jsonMap = jsonDecode(raw);
    final List<dynamic> tipos = jsonMap['tipos'] ?? [];
    return tipos
        .map(
          (item) => TipoCompanheiroAnimal.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  static Future<void> carregar() async {
    try {
      final raw = await rootBundle.loadString(
        'assets/data/classes_data/especifico_classe/druida/tipos_companheiro_animal.json',
        cache: false,
      );
      _dados = _parse(raw);
      _reconstruirIndex();
    } catch (e, stack) {
      debugPrint('Erro ao carregar tipos_companheiro_animal.json: $e\n$stack');
      assert(false, 'Erro ao carregar tipos_companheiro_animal.json: $e');
    }
  }

  static List<TipoCompanheiroAnimal> get todos => UnmodifiableListView(_dados);

  @visibleForTesting
  static void carregarParaTestes(List<TipoCompanheiroAnimal> tipos) {
    _dados = List.from(tipos);
    _reconstruirIndex();
  }

  static TipoCompanheiroAnimal? getByKey(String key) {
    return _indexPorChave[key.trim().toUpperCase()];
  }
}
