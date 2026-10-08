import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../entities/divindade.dart';

/// Serviço responsável pelo carregamento e acesso ao catálogo de divindades do Panteão (JSON).
class BancoDeDivindades {
  static List<Divindade> _dados = [];

  /// Carrega as divindades a partir do arquivo JSON nos assets
  static Future<void> carregar() async {
    final raw = await rootBundle.loadString('assets/data/deuses/banco_deuses.json');
    _dados = _parsearJson(raw);
  }

  /// Método para injetar divindades diretamente durante testes automatizados
  @visibleForTesting
  static void carregarParaTestes(List<Divindade> divindades) {
    _dados = List.from(divindades);
  }

  /// Converte a string bruta em lista de divindades, desduplicando IDs se necessário
  static List<Divindade> _parsearJson(String raw) {
    final dynamic decoded = jsonDecode(raw);
    final List<dynamic> jsonList = decoded is List
        ? decoded
        : (decoded['divindades'] as List<dynamic>? ?? []);

    final Map<String, Divindade> mapa = {};
    for (final item in jsonList) {
      if (item is Map<String, dynamic>) {
        final div = Divindade.fromJson(item);
        final idNorm = div.id.trim().toLowerCase();
        // Se já existir entrada com o mesmo ID, mantém a mais completa (com mais poderes)
        if (!mapa.containsKey(idNorm) ||
            div.poderesConcedidos.length > mapa[idNorm]!.poderesConcedidos.length) {
          mapa[idNorm] = div;
        }
      }
    }
    return mapa.values.toList();
  }

  static List<Divindade> _obterDados() {
    if (_dados.isEmpty) {
      try {
        final file = File('assets/data/deuses/banco_deuses.json');
        if (file.existsSync()) {
          final raw = file.readAsStringSync();
          _dados = _parsearJson(raw);
        }
      } catch (_) {}
    }
    return _dados;
  }

  /// Retorna a lista de todas as divindades registradas (imutável).
  /// Inclui fallback resiliente síncrono para execução em testes unitários.
  static List<Divindade> get todas => List.unmodifiable(_obterDados());

  /// Indica se os dados já foram carregados
  static bool get estaCarregado => _obterDados().isNotEmpty;

  /// Busca uma divindade pelo seu ID único (ex: "khalmyr", "valkaria")
  static Divindade? getById(String id) {
    final idNorm = id.trim().toLowerCase();
    return todas.where((d) => d.id.trim().toLowerCase() == idNorm).firstOrNull;
  }

  /// Busca uma divindade pelo seu nome (ex: "Khalmyr", "Valkaria")
  static Divindade? getByNome(String nome) {
    final nomeNorm = nome.trim().toLowerCase();
    return todas.where((d) => d.nome.trim().toLowerCase() == nomeNorm).firstOrNull;
  }
}
