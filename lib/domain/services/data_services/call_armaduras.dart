import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../entities/equipamento/protecao.dart';

class BancoDeArmaduras {
  static List<Protecao> _dados = [];
  static final Map<String, Protecao> _indexPorChave = {};

  static void _reconstruirIndex() {
    _indexPorChave.clear();
    for (final p in _dados) {
      _indexPorChave[p.key.trim().toUpperCase()] = p;
    }
  }

  static void _garantirCarregamento() {
    if (_dados.isEmpty) {
      try {
        final file = File('assets/data/equipment/banco_armaduras.json');
        if (file.existsSync()) {
          final raw = file.readAsStringSync();
          final List<dynamic> jsonList = jsonDecode(raw);
          _dados = jsonList
              .map((item) => Protecao.fromJson(item as Map<String, dynamic>))
              .toList();
          _reconstruirIndex();
        }
      } catch (_) {}
    }
  }

  static Future<void> carregar() async {
    final raw = await rootBundle.loadString(
      'assets/data/equipment/banco_armaduras.json',
    );
    final List<dynamic> jsonList = jsonDecode(raw);

    _dados = jsonList
        .map((item) => Protecao.fromJson(item as Map<String, dynamic>))
        .toList();
    _reconstruirIndex();
  }

  @visibleForTesting
  static void carregarParaTestes(List<Protecao> protecoes) {
    _dados = List.from(protecoes);
    _reconstruirIndex();
  }

  /// Retorna todas as proteções (armaduras e escudos) cadastradas
  static List<Protecao> get todas {
    _garantirCarregamento();
    return List.unmodifiable(_dados);
  }

  /// Retorna proteções filtradas por tipo específico
  static List<Protecao> armadurasPorTipo(TipoProtecao tipo) {
    _garantirCarregamento();
    return _dados.where((p) => p.tipo == tipo).toList();
  }

  /// Retorna apenas armaduras leves
  static List<Protecao> armadurasLeves() {
    return armadurasPorTipo(TipoProtecao.armaduraLeve);
  }

  /// Retorna apenas armaduras pesadas
  static List<Protecao> armadurasPesadas() {
    return armadurasPorTipo(TipoProtecao.armaduraPesada);
  }

  /// Retorna apenas escudos (leves e pesados)
  static List<Protecao> escudos() {
    _garantirCarregamento();
    return _dados.where((p) => p.ehEscudo).toList();
  }

  /// Busca uma proteção pela chave em O(1) (ex: 'ARMADURA_COURO', 'BRUNEA', 'ESCUDO_LEVE')
  static Protecao? getByKey(String key) {
    _garantirCarregamento();
    return _indexPorChave[key.trim().toUpperCase()];
  }
}
