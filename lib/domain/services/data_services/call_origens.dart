import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../entities/personagem/origem.dart';

class BancoDeOrigens {
  static List<Origem> _dados = [];
  static final Map<String, Origem> _indexPorId = {};
  static final Map<String, Origem> _indexPorNome = {};

  static void _reconstruirIndex() {
    _indexPorId.clear();
    _indexPorNome.clear();
    for (final o in _dados) {
      _indexPorId[o.id.trim().toLowerCase()] = o;
      _indexPorNome[o.nome.trim().toLowerCase()] = o;
    }
  }

  /// Carrega o catálogo de origens a partir do arquivo JSON nos assets
  static Future<void> carregar() async {
    final raw = await rootBundle.loadString('assets/data/banco_origens.json');
    final List<dynamic> jsonList = jsonDecode(raw);

    _dados = jsonList
        .map((item) => Origem.fromJson(item as Map<String, dynamic>))
        .toList();
    _reconstruirIndex();
  }

  /// Método para injetar dados durante a execução de testes automatizados
  @visibleForTesting
  static void carregarParaTestes(List<Origem> origens) {
    _dados = List.from(origens);
    _reconstruirIndex();
  }

  /// Retorna todas as origens disponíveis (imutável)
  /// Inclui fallback resiliente lendo o arquivo caso acessado antes do boot assíncrono (ex: testes).
  static List<Origem> get todas {
    if (_dados.isEmpty) {
      try {
        final file = File('assets/data/banco_origens.json');
        if (file.existsSync()) {
          final raw = file.readAsStringSync();
          final List<dynamic> jsonList = jsonDecode(raw);
          _dados = jsonList
              .map((item) => Origem.fromJson(item as Map<String, dynamic>))
              .toList();
          _reconstruirIndex();
        }
      } catch (_) {}
    }
    return List.unmodifiable(_dados);
  }

  /// Retorna se os dados já foram carregados
  static bool get estaCarregado => _dados.isNotEmpty;

  /// Busca uma origem pelo ID único em O(1) (ex: "acolito", "soldado")
  static Origem? getById(String id) {
    if (_dados.isEmpty) {
      final _ = todas;
    }
    return _indexPorId[id.trim().toLowerCase()];
  }

  /// Busca uma origem pelo nome em O(1) (ex: "Acólito", "Soldado")
  static Origem? getByNome(String nome) {
    if (_dados.isEmpty) {
      final _ = todas;
    }
    return _indexPorNome[nome.trim().toLowerCase()];
  }
}
