import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../entities/equipamento/arma.dart';

class BancoDeArmas {
  static List<Arma> _dados = [];
  static final Map<String, Arma> _indexPorChave = {};

  static void _reconstruirIndex() {
    _indexPorChave.clear();
    for (final a in _dados) {
      _indexPorChave[a.key.trim().toUpperCase()] = a;
    }
  }

  static void _garantirCarregamento() {
    if (_dados.isEmpty) {
      try {
        final file = File('assets/data/equipment/banco_armas.json');
        if (file.existsSync()) {
          final raw = file.readAsStringSync();
          final List<dynamic> jsonList = jsonDecode(raw);
          _dados = jsonList
              .map((item) => Arma.fromJson(item as Map<String, dynamic>))
              .toList();
          _reconstruirIndex();
        }
      } catch (_) {}
    }
  }

  static Future<void> carregar() async {
    final raw = await rootBundle.loadString(
      'assets/data/equipment/banco_armas.json',
    );
    final List<dynamic> jsonList = jsonDecode(raw);

    _dados = jsonList
        .map((item) => Arma.fromJson(item as Map<String, dynamic>))
        .toList();
    _reconstruirIndex();
  }

  /// Método para injetar armas durante a execução de testes automatizados
  @visibleForTesting
  static void carregarParaTestes(List<Arma> armas) {
    _dados = List.from(armas);
    _reconstruirIndex();
  }

  /// Retorna todas as armas cadastradas
  static List<Arma> get todas {
    _garantirCarregamento();
    return List.unmodifiable(_dados);
  }

  /// Retorna as armas filtradas por proficiência (Simples, Marcial, Exótica, Fogo)
  static List<Arma> armasPorProficiencia(ProficienciaArma prof) {
    _garantirCarregamento();
    return _dados.where((a) => a.proficiencia == prof).toList();
  }

  /// Atalho para armas simples
  static List<Arma> armasSimples() {
    return armasPorProficiencia(ProficienciaArma.simples);
  }

  /// Atalho para armas marciais
  static List<Arma> armasMarciais() {
    return armasPorProficiencia(ProficienciaArma.marcial);
  }

  /// Busca uma arma específica pela chave em O(1) (ex: 'ADAGA', 'ESPADA_LONGA')
  static Arma? getByKey(String key) {
    _garantirCarregamento();
    return _indexPorChave[key.trim().toUpperCase()];
  }
}
