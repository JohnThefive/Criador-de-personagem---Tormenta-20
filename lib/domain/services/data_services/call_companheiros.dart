import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import '../../entities/companheiro_animal.dart';

class BancoDeCompanheiros {
  static List<TipoCompanheiroAnimal> _dados = [];

  static Future<void> carregar() async {
    final raw = await rootBundle.loadString(
      'assets/data/tipos_companheiro_animal.json',
    );
    final Map<String, dynamic> jsonMap = jsonDecode(raw);
    final List<dynamic> tipos = jsonMap['tipos'] ?? [];
    _dados = tipos
        .map(
          (item) => TipoCompanheiroAnimal.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  static List<TipoCompanheiroAnimal> get todos {
    if (_dados.isEmpty) {
      try {
        final file = File('assets/data/tipos_companheiro_animal.json');
        if (file.existsSync()) {
          final raw = file.readAsStringSync();
          final Map<String, dynamic> jsonMap = jsonDecode(raw);
          final List<dynamic> tipos = jsonMap['tipos'] ?? [];
          _dados = tipos
              .map(
                (item) => TipoCompanheiroAnimal.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList();
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

  static TipoCompanheiroAnimal? getPorNome(String nome) {
    final n = nome.trim().toLowerCase();
    return todos.where((c) => c.nome.trim().toLowerCase() == n).firstOrNull;
  }
}
