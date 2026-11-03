import 'dart:collection';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../entities/personagem/pericias.dart';

class BancoDePericias {
  static List<Pericia> _todas = [];
  static final Map<String, Pericia> _indexPorKey = {};

  static List<Pericia> get todas => UnmodifiableListView(_todas);

  static void _reconstruirIndex() {
    _indexPorKey.clear();
    for (final p in _todas) {
      _indexPorKey[p.key] = p;
      _indexPorKey[p.key.toUpperCase()] = p;
      _indexPorKey[p.key.toLowerCase()] = p;
    }
  }

  /// Injeção de dados em testes unitários
  @visibleForTesting
  static void carregarParaTestes(List<Pericia> pericias) {
    _todas = List.from(pericias);
    _reconstruirIndex();
  }

  /// Chame isso na inicialização do app (ex: no main() ou no splash)
  static Future<void> carregarPericias() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/data/banco_pericias.json',
        cache: false,
      );
      final List<dynamic> data = json.decode(response) as List<dynamic>;

      _todas = data
          .map((item) => Pericia.fromJson(item as Map<String, dynamic>))
          .toList();
      _reconstruirIndex();
    } catch (e, stack) {
      debugPrint('Erro ao carregar banco_pericias.json: $e\n$stack');
      assert(false, 'Erro ao carregar banco_pericias.json: $e');
    }
  }

  static Pericia getByKey(String key) {
    final p = _indexPorKey[key] ??
        _indexPorKey[key.toUpperCase()] ??
        _indexPorKey[key.toLowerCase()];
    if (p != null) return p;

    return const Pericia(
      key: 'UNKNOWN',
      label: 'Desconhecida',
      atributoChave: 'INT',
      somenteTreinada: false,
      penalidadeArmadura: false,
      descricao: 'Perícia não encontrada.',
      acoesExecutadas: 'Nenhuma',
    );
  }
}
