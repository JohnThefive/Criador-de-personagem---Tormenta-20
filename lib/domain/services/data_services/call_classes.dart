import 'dart:collection';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../entities/personagem/classe.dart';

class BancoDeClasses {
  static List<Classe> _dados = [];
  static final Map<String, Classe> _indexPorId = {};
  static final Map<String, Classe> _indexPorNome = {};

  static void _reconstruirIndex() {
    _indexPorId.clear();
    _indexPorNome.clear();
    for (final c in _dados) {
      _indexPorId[c.idClasse.trim().toLowerCase()] = c;
      _indexPorNome[c.nome.trim().toLowerCase()] = c;
    }
  }

  /// Carrega as classes a partir do arquivo JSON nos assets
  static Future<void> carregar() async {
    try {
      final raw = await rootBundle.loadString(
        'assets/data/classes_data/banco_classe.json',
        cache: false,
      );
      final List<dynamic> jsonList = jsonDecode(raw);

      _dados = jsonList
          .map((item) => Classe.fromJson(item as Map<String, dynamic>))
          .toList();
      _reconstruirIndex();
    } catch (e, stack) {
      debugPrint('Erro ao carregar banco_classe.json: $e\n$stack');
      assert(false, 'Erro ao carregar banco_classe.json: $e');
    }
  }

  /// Método para injetar classes diretamente durante testes automatizados
  @visibleForTesting
  static void carregarParaTestes(List<Classe> classes) {
    _dados = List.from(classes);
    _reconstruirIndex();
  }

  /// Retorna a lista de todas as classes registradas.
  static List<Classe> get todas => UnmodifiableListView(_dados);

  /// Indica se os dados já foram carregados
  static bool get estaCarregado => _dados.isNotEmpty;

  /// Busca uma classe pelo seu identificador único em O(1) (ex: "arcanista", "barbaro")
  static Classe? getById(String idClasse) {
    return _indexPorId[idClasse.trim().toLowerCase()];
  }

  /// Busca uma classe pelo seu nome de exibição em O(1) (ex: "Arcanista", "Bárbaro")
  static Classe? getByNome(String nome) {
    return _indexPorNome[nome.trim().toLowerCase()];
  }
}
