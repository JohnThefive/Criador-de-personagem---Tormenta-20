import 'dart:convert';
import 'package:flutter/services.dart';
import '../../entities/personagem/pericias.dart';

class BancoDePericias {
  static List<Pericia> _todas = [];

  static List<Pericia> get todas => List.unmodifiable(_todas);

  /// Chame isso na inicialização do app (ex: no main() ou no splash)
  static Future<void> carregarPericias() async {
    final String response = await rootBundle.loadString(
      'assets/data/banco_pericias.json',
    );
    final List<dynamic> data = json.decode(response) as List<dynamic>;

    _todas = data
        .map((item) => Pericia.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Pericia getByKey(String key) {
    return _todas.firstWhere(
      (p) => p.key == key,
      orElse: () => const Pericia(
        key: 'UNKNOWN',
        label: 'Desconhecida',
        atributoChave: 'INT',
        somenteTreinada: false,
        penalidadeArmadura: false,
        descricao: 'Perícia não encontrada.',
        acoesExecutadas: 'Nenhuma',
      ),
    );
  }
}
