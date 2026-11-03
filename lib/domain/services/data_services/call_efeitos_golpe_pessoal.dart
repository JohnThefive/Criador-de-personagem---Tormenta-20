import 'dart:collection';
import 'dart:convert';
import 'package:flutter/foundation.dart';
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
    try {
      final raw = await rootBundle.loadString(
        'assets/data/classes_data/especifico_classe/guerreiro/efeitos_golpe_pessoal.json',
        cache: false,
      );
      _dados = _parse(raw);
      _reconstruirIndex();
    } catch (e, stack) {
      debugPrint('Erro ao carregar efeitos_golpe_pessoal.json: $e\n$stack');
      assert(false, 'Erro ao carregar efeitos_golpe_pessoal.json: $e');
    }
  }

  static List<EfeitoGolpePessoal> get todos => UnmodifiableListView(_dados);

  @visibleForTesting
  static void carregarParaTestes(List<EfeitoGolpePessoal> efeitos) {
    _dados = List.from(efeitos);
    _reconstruirIndex();
  }

  static EfeitoGolpePessoal? getByKey(String key) {
    return _indexPorChave[key.trim().toUpperCase()];
  }

  static List<EfeitoGolpePessoal> get vantagens =>
      todos.where((e) => e.ehVantagem).toList();

  static List<EfeitoGolpePessoal> get desvantagens =>
      todos.where((e) => e.ehDesvantagem).toList();
}
