import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:t20_creator/domain/entities/magia/magia.dart';

class BancoDeMagias {
  static final List<Magia> _todas = [];

  static List<Magia> get todas => List.unmodifiable(_todas);

  static Future<void> carregarMagias() async {
    _todas.clear();

    // Lista com os arquivos de cada círculo
    const circulos = [1, 2, 3, 4, 5];

    for (var circulo in circulos) {
      try {
        final String response = await rootBundle.loadString(
          'assets/data/magias/${circulo}_circulo.json',
        );
        final List<dynamic> data = json.decode(response) as List<dynamic>;

        final magiasCirculo = data
            .map((item) => Magia.fromJson(item as Map<String, dynamic>))
            .toList();
        _todas.addAll(magiasCirculo);
      } catch (e) {
        // Caso algum círculo ainda não tenha arquivo criado, o app não quebra
      }
    }
  }

  static List<Magia> filtrarPorClasseETipo({
    required String tipo,
    required int circuloMaximo,
  }) {
    return _todas
        .where((m) => m.tipo == tipo && m.circulo <= circuloMaximo)
        .toList();
  }

  static Magia getById(String id) {
    return _todas.firstWhere(
      (m) => m.id == id,
      orElse: () => Magia(
        id: 'UNKNOWN',
        nome: 'Magia Desconhecida',
        tipo: 'arcana',
        circulo: 1,
        escola: 'desconhecida',
        execucao: const ExecucaoMagia(tipo: 'padrao'),
        alcance: const AlcanceMagia(tipo: 'pessoal'),
        efeito: const EfeitoMagia(tipo: 'alvo'),
        duracao: const DuracaoMagia(tipo: 'instantanea'),
        descricao: 'Magia não encontrada.',
        aprimoramentos: [],
      ),
    );
  }
}
