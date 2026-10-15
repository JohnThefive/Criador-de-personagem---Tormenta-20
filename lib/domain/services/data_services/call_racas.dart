import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../entities/personagem/raca.dart';

class BancoDeRacas {
  static List<Raca> _dados = [];
  static final Map<String, Raca> _indexPorId = {};
  static final Map<String, Raca> _indexPorNome = {};

  static void _reconstruirIndex() {
    _indexPorId.clear();
    _indexPorNome.clear();
    for (final r in _dados) {
      _indexPorId[r.id.trim().toLowerCase()] = r;
      _indexPorNome[r.nome.trim().toLowerCase()] = r;
    }
  }

  static void _garantirCarregamento() {
    if (_dados.isEmpty) {
      try {
        final file = File('assets/data/banco_racas.json');
        if (file.existsSync()) {
          final raw = file.readAsStringSync();
          final List<dynamic> jsonList = jsonDecode(raw);
          _dados = jsonList
              .map((item) => Raca.fromJson(item as Map<String, dynamic>))
              .toList();
          _reconstruirIndex();
        }
      } catch (_) {}
    }
  }

  /// Carrega o catálogo de raças a partir do arquivo JSON nos assets
  static Future<void> carregar() async {
    final raw = await rootBundle.loadString('assets/data/banco_racas.json');
    final List<dynamic> jsonList = jsonDecode(raw);

    _dados = jsonList
        .map((item) => Raca.fromJson(item as Map<String, dynamic>))
        .toList();
    _reconstruirIndex();
  }

  /// Método para injetar dados durante a execução de testes automatizados
  @visibleForTesting
  static void carregarParaTestes(List<Raca> racas) {
    _dados = List.from(racas);
    _reconstruirIndex();
  }

  /// Retorna todas as raças disponíveis (imutável)
  static List<Raca> get todas {
    _garantirCarregamento();
    return List.unmodifiable(_dados);
  }

  /// Retorna se os dados já foram carregados
  static bool get estaCarregado => _dados.isNotEmpty;

  /// Busca uma raça pelo ID único em O(1) (ex: "anao", "humano", "lefou")
  static Raca? getById(String id) {
    _garantirCarregamento();
    return _indexPorId[id.trim().toLowerCase()];
  }

  /// Busca uma raça pelo nome em O(1) (ex: "Anão", "Humano", "Lefou")
  static Raca? getByNome(String nome) {
    _garantirCarregamento();
    return _indexPorNome[nome.trim().toLowerCase()];
  }
}
