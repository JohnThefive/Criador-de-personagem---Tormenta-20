import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../entities/raca.dart';

class BancoDeRacas {
  static List<Raca> _dados = [];

  /// Carrega o catálogo de raças a partir do arquivo JSON nos assets
  static Future<void> carregar() async {
    final raw = await rootBundle.loadString('assets/data/banco_racas.json');
    final List<dynamic> jsonList = jsonDecode(raw);

    _dados = jsonList
        .map((item) => Raca.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Método para injetar dados durante a execução de testes automatizados
  @visibleForTesting
  static void carregarParaTestes(List<Raca> racas) {
    _dados = List.from(racas);
  }

  /// Retorna todas as raças disponíveis (imutável)
  static List<Raca> get todas => List.unmodifiable(_dados);

  /// Retorna se os dados já foram carregados
  static bool get estaCarregado => _dados.isNotEmpty;

  /// Busca uma raça pelo ID único (ex: "anao", "humano", "lefou")
  static Raca? getById(String id) {
    final idNorm = id.trim().toLowerCase();
    return _dados.where((r) => r.id.trim().toLowerCase() == idNorm).firstOrNull;
  }

  /// Busca uma raça pelo nome (ex: "Anão", "Humano", "Lefou")
  static Raca? getByNome(String nome) {
    final nomeNorm = nome.trim().toLowerCase();
    return _dados
        .where((r) => r.nome.trim().toLowerCase() == nomeNorm)
        .firstOrNull;
  }
}
