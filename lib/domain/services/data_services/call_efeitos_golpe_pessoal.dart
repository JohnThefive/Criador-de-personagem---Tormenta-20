import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import '../../entities/habilidades_complexas/golpe_pessoal.dart';

class BancoDeEfeitosGolpePessoal {
  static List<EfeitoGolpePessoal> _dados = [];
  static final Map<String, EfeitoGolpePessoal> _indexPorChave = {};

  static void _reconstruirIndex() {
    _indexPorChave.clear();
    for (final e in _dados) {
      _indexPorChave[e.key.trim().toUpperCase()] = e;
    }
  }

  static List<EfeitoGolpePessoal> _parse(String raw) {
    final List<dynamic> jsonList = jsonDecode(raw);
    return jsonList
        .map(
          (item) => EfeitoGolpePessoal.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  static Future<void> carregar() async {
    final raw = await rootBundle.loadString(
      'assets/data/classes_data/especifico_classe/guerreiro/efeitos_golpe_pessoal.json',
    );
    _dados = _parse(raw);
    _reconstruirIndex();
  }

  static List<EfeitoGolpePessoal> get todos {
    if (_dados.isEmpty) {
      try {
        final file = File(
          'assets/data/classes_data/especifico_classe/guerreiro/efeitos_golpe_pessoal.json',
        );
        if (file.existsSync()) {
          _dados = _parse(file.readAsStringSync());
          _reconstruirIndex();
        }
      } catch (_) {}
    }
    return List.unmodifiable(_dados);
  }

  static void carregarParaTestes(List<EfeitoGolpePessoal> efeitos) {
    _dados = List.from(efeitos);
    _reconstruirIndex();
  }

  static EfeitoGolpePessoal? getByKey(String key) {
    if (_dados.isEmpty) {
      final _ = todos;
    }
    return _indexPorChave[key.trim().toUpperCase()];
  }

  static List<EfeitoGolpePessoal> get vantagens =>
      todos.where((e) => e.ehVantagem).toList();

  static List<EfeitoGolpePessoal> get desvantagens =>
      todos.where((e) => e.ehDesvantagem).toList();
}
