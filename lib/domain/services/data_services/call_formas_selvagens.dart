import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import '../../entities/forma_selvagem.dart';

class BancoDeFormasSelvagens {
  static List<FormaSelvagem> _dados = [];

  static List<FormaSelvagem> _parse(String raw) {
    final List<dynamic> jsonList = jsonDecode(raw);
    return jsonList
        .map((item) => FormaSelvagem.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  static Future<void> carregar() async {
    final raw = await rootBundle.loadString('assets/data/formas_selvagens.json');
    _dados = _parse(raw);
  }

  static List<FormaSelvagem> get todas {
    if (_dados.isEmpty) {
      try {
        final file = File('assets/data/formas_selvagens.json');
        if (file.existsSync()) {
          _dados = _parse(file.readAsStringSync());
        }
      } catch (_) {}
    }
    return List.unmodifiable(_dados);
  }

  static void carregarParaTestes(List<FormaSelvagem> formas) {
    _dados = List.from(formas);
  }

  static FormaSelvagem? getByKey(String key) {
    final keyNorm = key.trim().toUpperCase();
    return todas.where((f) => f.key.trim().toUpperCase() == keyNorm).firstOrNull;
  }

  static FormaSelvagem? getPorNome(String nome) {
    final n = nome.trim().toLowerCase();
    return todas.where((f) {
      final fn = f.nome.trim().toLowerCase();
      return fn == n ||
          fn == 'forma $n' ||
          fn.replaceFirst('forma ', '') == n;
    }).firstOrNull;
  }
}
