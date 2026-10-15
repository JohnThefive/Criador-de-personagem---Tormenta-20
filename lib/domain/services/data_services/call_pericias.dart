import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import '../../entities/personagem/pericias.dart';

class BancoDePericias {
  static List<Pericia> _todas = [];
  static final Map<String, Pericia> _indexPorKey = {};

  static List<Pericia> get todas {
    _garantirCarregamento();
    return List.unmodifiable(_todas);
  }

  static void _reconstruirIndex() {
    _indexPorKey.clear();
    for (final p in _todas) {
      _indexPorKey[p.key] = p;
      _indexPorKey[p.key.toUpperCase()] = p;
      _indexPorKey[p.key.toLowerCase()] = p;
    }
  }

  static void _garantirCarregamento() {
    if (_todas.isEmpty) {
      try {
        final file = File('assets/data/banco_pericias.json');
        if (file.existsSync()) {
          final raw = file.readAsStringSync();
          final List<dynamic> data = json.decode(raw) as List<dynamic>;
          _todas = data
              .map((item) => Pericia.fromJson(item as Map<String, dynamic>))
              .toList();
          _reconstruirIndex();
        }
      } catch (_) {}
    }
  }

  /// Injeção de dados em testes unitários
  static void carregarParaTestes(List<Pericia> pericias) {
    _todas = List.from(pericias);
    _reconstruirIndex();
  }

  /// Chame isso na inicialização do app (ex: no main() ou no splash)
  static Future<void> carregarPericias() async {
    final String response = await rootBundle.loadString(
      'assets/data/banco_pericias.json',
    );
    final List<dynamic> data = json.decode(response) as List<dynamic>;

    _todas = data
        .map((item) => Pericia.fromJson(item as Map<String, dynamic>))
        .toList();
    _reconstruirIndex();
  }

  static Pericia getByKey(String key) {
    _garantirCarregamento();
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
