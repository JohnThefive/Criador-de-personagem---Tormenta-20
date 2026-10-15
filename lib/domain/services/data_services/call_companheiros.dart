import 'dart:convert';
import 'dart:io';
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
    final raw = await rootBundle.loadString(
      'assets/data/classes_data/especifico_classe/druida/tipos_companheiro_animal.json',
    );
    _dados = _parse(raw);
    _reconstruirIndex();
  }

  static List<TipoCompanheiroAnimal> get todos {
    if (_dados.isEmpty) {
      try {
        final file = File(
          'assets/data/classes_data/especifico_classe/druida/tipos_companheiro_animal.json',
        );
        if (file.existsSync()) {
          _dados = _parse(file.readAsStringSync());
          _reconstruirIndex();
        }
      } catch (_) {}
    }
    return List.unmodifiable(_dados);
  }

  static void carregarParaTestes(List<TipoCompanheiroAnimal> tipos) {
    _dados = List.from(tipos);
    _reconstruirIndex();
  }

  static TipoCompanheiroAnimal? getByKey(String key) {
    if (_dados.isEmpty) {
      final _ = todos;
    }
    return _indexPorChave[key.trim().toUpperCase()];
  }
}
