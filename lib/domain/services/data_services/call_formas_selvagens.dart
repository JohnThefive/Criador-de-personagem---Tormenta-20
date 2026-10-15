import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import '../../entities/habilidades_complexas/forma_selvagem.dart';

class BancoDeFormasSelvagens {
  static List<FormaSelvagem> _dados = [];
  static final Map<String, FormaSelvagem> _indexPorChave = {};
  static final Map<String, FormaSelvagem> _indexPorNome = {};

  static void _reconstruirIndex() {
    _indexPorChave.clear();
    _indexPorNome.clear();
    for (final f in _dados) {
      _indexPorChave[f.key.trim().toUpperCase()] = f;
      final fn = f.nome.trim().toLowerCase();
      _indexPorNome[fn] = f;
      _indexPorNome['forma $fn'] = f;
      _indexPorNome[fn.replaceFirst('forma ', '')] = f;
    }
  }

  static List<FormaSelvagem> _parse(String raw) {
    final List<dynamic> jsonList = jsonDecode(raw);
    return jsonList
        .map(
          (item) =>
              FormaSelvagem.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  static Future<void> carregar() async {
    final raw = await rootBundle.loadString(
      'assets/data/classes_data/especifico_classe/druida/formas_selvagens.json',
    );
    _dados = _parse(raw);
    _reconstruirIndex();
  }

  static List<FormaSelvagem> get todas {
    if (_dados.isEmpty) {
      try {
        final file = File(
          'assets/data/classes_data/especifico_classe/druida/formas_selvagens.json',
        );
        if (file.existsSync()) {
          _dados = _parse(file.readAsStringSync());
          _reconstruirIndex();
        }
      } catch (_) {}
    }
    return List.unmodifiable(_dados);
  }

  static void carregarParaTestes(List<FormaSelvagem> formas) {
    _dados = List.from(formas);
    _reconstruirIndex();
  }

  static FormaSelvagem? getByKey(String key) {
    if (_dados.isEmpty) {
      final _ = todas;
    }
    return _indexPorChave[key.trim().toUpperCase()];
  }

  static FormaSelvagem? getPorNome(String nome) {
    if (_dados.isEmpty) {
      final _ = todas;
    }
    return _indexPorNome[nome.trim().toLowerCase()];
  }
}
