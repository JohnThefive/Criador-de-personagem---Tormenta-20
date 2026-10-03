import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../entities/protecao.dart';

class BancoDeArmaduras {
  static List<Protecao> _dados = [];

  static Future<void> carregar() async {
    final raw =
        await rootBundle.loadString('assets/data/banco_armaduras.json');
    final List<dynamic> jsonList = jsonDecode(raw);

    _dados = jsonList
        .map((item) => Protecao.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @visibleForTesting
  static void carregarParaTestes(List<Protecao> protecoes) {
    _dados = List.from(protecoes);
  }

  /// Retorna todas as proteções (armaduras e escudos) cadastradas
  static List<Protecao> get todas => List.unmodifiable(_dados);

  /// Retorna proteções filtradas por tipo específico
  static List<Protecao> armadurasPorTipo(TipoProtecao tipo) {
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
    return _dados.where((p) => p.ehEscudo).toList();
  }

  /// Busca uma proteção pela chave (ex: 'ARMADURA_COURO', 'BRUNEA', 'ESCUDO_LEVE')
  static Protecao? getByKey(String key) {
    final keyNorm = key.trim().toUpperCase();
    return _dados
        .where((p) => p.key.trim().toUpperCase() == keyNorm)
        .firstOrNull;
  }
}
