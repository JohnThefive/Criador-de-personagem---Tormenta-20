import 'dart:collection';
import 'dart:convert';
import 'package:flutter/foundation.dart';
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
    try {
      final raw = await rootBundle.loadString(
        'assets/data/classes_data/especifico_classe/druida/formas_selvagens.json',
        cache: false,
      );
      _dados = _parse(raw);
      _reconstruirIndex();
    } catch (e, stack) {
      debugPrint('Erro ao carregar formas_selvagens.json: $e\n$stack');
      assert(false, 'Erro ao carregar formas_selvagens.json: $e');
    }
  }

  static List<FormaSelvagem> get todas => UnmodifiableListView(_dados);

  @visibleForTesting
  static void carregarParaTestes(List<FormaSelvagem> formas) {
    _dados = List.from(formas);
    _reconstruirIndex();
  }

  static FormaSelvagem? getByKey(String key) {
    return _indexPorChave[key.trim().toUpperCase()];
  }

  static FormaSelvagem? getPorNome(String nome) {
    return _indexPorNome[nome.trim().toLowerCase()];
  }
}
