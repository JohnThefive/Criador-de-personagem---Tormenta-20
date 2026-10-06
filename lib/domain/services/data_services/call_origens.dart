import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../entities/origem.dart';

class BancoDeOrigens {
  static List<Origem> _dados = [];

  /// Carrega o catálogo de origens a partir do arquivo JSON nos assets
  static Future<void> carregar() async {
    final raw = await rootBundle.loadString('assets/data/banco_origens.json');
    final List<dynamic> jsonList = jsonDecode(raw);

    _dados = jsonList
        .map((item) => Origem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Método para injetar dados durante a execução de testes automatizados
  @visibleForTesting
  static void carregarParaTestes(List<Origem> origens) {
    _dados = List.from(origens);
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
        }
      } catch (_) {}
    }
    return List.unmodifiable(_dados);
  }

  /// Retorna se os dados já foram carregados
  static bool get estaCarregado => _dados.isNotEmpty;

  /// Busca uma origem pelo ID único (ex: "acolito", "soldado")
  static Origem? getById(String id) {
    final idNorm = id.trim().toLowerCase();
    return todas.where((o) => o.id.trim().toLowerCase() == idNorm).firstOrNull;
  }

  /// Busca uma origem pelo nome (ex: "Acólito", "Soldado")
  static Origem? getByNome(String nome) {
    final nomeNorm = nome.trim().toLowerCase();
    return todas
        .where((o) => o.nome.trim().toLowerCase() == nomeNorm)
        .firstOrNull;
  }
}
