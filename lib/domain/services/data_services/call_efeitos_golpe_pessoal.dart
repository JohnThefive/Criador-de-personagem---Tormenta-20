import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import '../../entities/golpe_pessoal.dart';

class BancoDeEfeitosGolpePessoal {
  static List<EfeitoGolpePessoal> _dados = [];

  static List<EfeitoGolpePessoal> _parse(String raw) {
    final List<dynamic> jsonList = jsonDecode(raw);
    return jsonList
        .map((item) => EfeitoGolpePessoal.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  static Future<void> carregar() async {
    final raw = await rootBundle.loadString('assets/data/efeitos_golpe_pessoal.json');
    _dados = _parse(raw);
  }

  static List<EfeitoGolpePessoal> get todos {
    if (_dados.isEmpty) {
      try {
        final file = File('assets/data/efeitos_golpe_pessoal.json');
        if (file.existsSync()) {
          _dados = _parse(file.readAsStringSync());
        }
      } catch (_) {}
    }
    return List.unmodifiable(_dados);
  }

  static void carregarParaTestes(List<EfeitoGolpePessoal> efeitos) {
    _dados = List.from(efeitos);
  }

  static EfeitoGolpePessoal? getByKey(String key) {
    final keyNorm = key.trim().toUpperCase();
    return todos.where((e) => e.key.trim().toUpperCase() == keyNorm).firstOrNull;
  }

  static List<EfeitoGolpePessoal> get vantagens =>
      todos.where((e) => e.ehVantagem).toList();

  static List<EfeitoGolpePessoal> get desvantagens =>
      todos.where((e) => e.ehDesvantagem).toList();
}
