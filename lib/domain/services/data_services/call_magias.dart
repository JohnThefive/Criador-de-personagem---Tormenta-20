import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:t20_creator/domain/entities/magia/magia.dart';

class BancoDeMagias {
  static final List<Magia> _todas = [];
  static final Map<String, Magia> _indexPorId = {};

  static List<Magia> get todas {
    _garantirCarregamento();
    return List.unmodifiable(_todas);
  }

  static void _reconstruirIndex() {
    _indexPorId.clear();
    for (final m in _todas) {
      _indexPorId[m.id] = m;
      _indexPorId[m.id.toLowerCase()] = m;
      _indexPorId[m.id.toUpperCase()] = m;
    }
  }

  static void _garantirCarregamento() {
    if (_todas.isEmpty) {
      const circulos = [1, 2, 3, 4, 5];
      for (var circulo in circulos) {
        try {
          final file = File('assets/data/magias/${circulo}_circulo.json');
          if (file.existsSync()) {
            final raw = file.readAsStringSync();
            final List<dynamic> data = json.decode(raw) as List<dynamic>;
            final magiasCirculo = data
                .map((item) => Magia.fromJson(item as Map<String, dynamic>))
                .toList();
            _todas.addAll(magiasCirculo);
          }
        } catch (_) {}
      }
      _reconstruirIndex();
    }
  }

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
    _reconstruirIndex();
  }

  static void carregarParaTestes(List<Magia> magias) {
    _todas.clear();
    _todas.addAll(magias);
    _reconstruirIndex();
  }

  static List<Magia> filtrarPorClasseETipo({
    required String tipo,
    required int circuloMaximo,
  }) {
    _garantirCarregamento();
    return _todas
        .where(
          (m) =>
              (m.tipo == tipo || m.tipo == 'universal') &&
              m.circulo <= circuloMaximo,
        )
        .toList();
  }

  static Magia getById(String id) {
    _garantirCarregamento();
    final encontrada = _indexPorId[id] ??
        _indexPorId[id.toLowerCase()] ??
        _indexPorId[id.toUpperCase()];
    if (encontrada != null) return encontrada;

    return Magia(
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
    );
  }
}
