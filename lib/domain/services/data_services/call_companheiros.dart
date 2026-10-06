import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import '../../entities/companheiro_animal.dart';

class BancoDeCompanheiros {
  static List<TipoCompanheiroAnimal> _dados = [];

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
  }

  static List<TipoCompanheiroAnimal> get todos {
    if (_dados.isEmpty) {
      try {
        final file = File('assets/data/classes_data/especifico_classe/druida/tipos_companheiro_animal.json');
        if (file.existsSync()) {
          _dados = _parse(file.readAsStringSync());
        }
      } catch (_) {}
    }
    return List.unmodifiable(_dados);
  }

  static void carregarParaTestes(List<TipoCompanheiroAnimal> tipos) {
    _dados = List.from(tipos);
  }

  static TipoCompanheiroAnimal? getByKey(String key) {
    final keyNorm = key.trim().toUpperCase();
    return todos.where((c) => c.key.trim().toUpperCase() == keyNorm).firstOrNull;
  }
}
