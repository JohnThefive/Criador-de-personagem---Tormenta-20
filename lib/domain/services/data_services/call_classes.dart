import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../entities/classe.dart';

class BancoDeClasses {
  static List<Classe> _dados = [];

  /// Carrega as classes a partir do arquivo JSON nos assets
  static Future<void> carregar() async {
    final raw = await rootBundle.loadString('assets/data/banco_classe.json');
    final List<dynamic> jsonList = jsonDecode(raw);

    _dados = jsonList
        .map((item) => Classe.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Método para injetar classes diretamente durante testes automatizados
  @visibleForTesting
  static void carregarParaTestes(List<Classe> classes) {
    _dados = List.from(classes);
  }

  /// Retorna a lista de todas as classes registradas.
  /// Inclui fallback resiliente caso acessado antes do boot assíncrono (ex: testes unitários isolados).
  static List<Classe> get todas {
    if (_dados.isEmpty) {
      try {
        final file = File('assets/data/banco_classe.json');
        if (file.existsSync()) {
          final raw = file.readAsStringSync();
          final List<dynamic> jsonList = jsonDecode(raw);
          _dados = jsonList
              .map((item) => Classe.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      } catch (_) {}
    }
    return List.unmodifiable(_dados);
  }

  /// Indica se os dados já foram carregados
  static bool get estaCarregado => _dados.isNotEmpty;

  /// Busca uma classe pelo seu identificador único (ex: "arcanista", "barbaro")
  static Classe? getById(String idClasse) {
    final idNorm = idClasse.trim().toLowerCase();
    return todas
        .where((c) => c.idClasse.trim().toLowerCase() == idNorm)
        .firstOrNull;
  }

  /// Busca uma classe pelo seu nome de exibição (ex: "Arcanista", "Bárbaro")
  static Classe? getByNome(String nome) {
    final nomeNorm = nome.trim().toLowerCase();
    return todas
        .where((c) => c.nome.trim().toLowerCase() == nomeNorm)
        .firstOrNull;
  }
}
