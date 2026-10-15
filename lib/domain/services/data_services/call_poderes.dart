import 'dart:convert';
import 'package:flutter/services.dart';
import '../../entities/personagem/poder.dart';

class BancoDePoderes {
  // O mapa guarda as listas usando o idClasse (ex: "arcanista") como chave
  static Map<String, List<Poder>> _dados = {};
  static final Map<String, Poder> _indexPorChave = {};

  static Future<void> carregar() async {
    final raw = await rootBundle.loadString(
      'assets/data/classes_data/banco_poderes_classe.json',
    );

    final Map<String, dynamic> jsonMap = jsonDecode(raw);

    _dados = {};
    _indexPorChave.clear();

    // Aqui a 'chaveJson' será convertida para maiúsculo para evitar erros de case sensitivity
    jsonMap.forEach((chaveJson, lista) {
      final poderes = (lista as List)
          .map((p) => Poder.fromJson(p as Map<String, dynamic>))
          .toList();
      _dados[chaveJson.toUpperCase()] = poderes;
      for (final poder in poderes) {
        _indexPorChave[poder.key] = poder;
        _indexPorChave[poder.key.toUpperCase()] = poder;
      }
    });
  }

  /// Método para injetar poderes em testes automatizados
  static void carregarParaTestes(Map<String, List<Poder>> dados) {
    _dados = Map.from(dados);
    _indexPorChave.clear();
    for (final poderes in _dados.values) {
      for (final poder in poderes) {
        _indexPorChave[poder.key] = poder;
        _indexPorChave[poder.key.toUpperCase()] = poder;
      }
    }
  }

  // Busca os poderes passando diretamente o idClasse da entidade Classe
  static List<Poder> poderesDaClasse(String idClasse) {
    return _dados[idClasse.toUpperCase()] ?? [];
  }

  /// Busca um poder específico em O(1) pela chave
  static Poder? getByKey(String key) {
    return _indexPorChave[key] ?? _indexPorChave[key.toUpperCase()];
  }
}
