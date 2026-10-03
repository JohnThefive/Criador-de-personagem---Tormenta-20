import 'dart:convert';
import 'package:flutter/services.dart';
import '../../entities/arma.dart';

class BancoDeArmas {
  static List<Arma> _dados = [];

  static Future<void> carregar() async {
    final raw = await rootBundle.loadString('assets/data/banco_armas.json');
    final List<dynamic> jsonList = jsonDecode(raw);

    _dados = jsonList
        .map((item) => Arma.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Retorna todas as armas cadastradas
  static List<Arma> get todas => List.unmodifiable(_dados);

  /// Retorna as armas filtradas por proficiência (Simples, Marcial, Exótica, Fogo)
  static List<Arma> armasPorProficiencia(ProficienciaArma prof) {
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

  /// Busca uma arma específica pela chave (ex: 'ADAGA', 'ESPADA_LONGA')
  static Arma? getByKey(String key) {
    final keyNorm = key.trim().toUpperCase();
    return _dados
        .where((a) => a.key.trim().toUpperCase() == keyNorm)
        .firstOrNull;
  }
}
