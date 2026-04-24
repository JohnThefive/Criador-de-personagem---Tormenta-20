import 'dart:convert';
import 'package:flutter/services.dart';
import '../entities/poder.dart';

class BancoDePoderes {
  // O mapa guarda as listas usando o idClasse (ex: "arcanista") como chave
  static Map<String, List<Poder>> _dados = {};

  static Future<void> carregar() async {
    final raw = await rootBundle.loadString(
      'assets/data/banco_poderes_classe.json',
    );

    final Map<String, dynamic> jsonMap = jsonDecode(raw);

    _dados = {};

    // Aqui a 'chaveJson' será convertida para maiúsculo para evitar erros de case sensitivity
    jsonMap.forEach((chaveJson, lista) {
      _dados[chaveJson.toUpperCase()] = (lista as List)
          .map((p) => Poder.fromJson(p as Map<String, dynamic>))
          .toList();
    });
  }

  // Busca os poderes passando diretamente o idClasse da entidade Classe
  static List<Poder> poderesDaClasse(String idClasse) {
    return _dados[idClasse.toUpperCase()] ?? [];
  }

  // Mantido caso você precise buscar um poder específico (ex: para validar pré-requisitos)
  static Poder? getByKey(String key) {
    for (var lista in _dados.values) {
      for (var poder in lista) {
        if (poder.key == key) return poder;
      }
    }
    return null;
  }
}