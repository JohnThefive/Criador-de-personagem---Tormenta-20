import 'dart:collection';
import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:t20_creator/domain/entities/magia/magia.dart';

class BancoDeMagias {
  static final List<Magia> _todas = [];
  static final Map<String, Magia> _indexPorId = {};

  static List<Magia> get todas => UnmodifiableListView(_todas);

  static void _reconstruirIndex() {
    _indexPorId.clear();
    for (final m in _todas) {
      _indexPorId[m.id] = m;
      _indexPorId[m.id.toLowerCase()] = m;
      _indexPorId[m.id.toUpperCase()] = m;
    }
  }

  static List<Magia> _parsearMagias(String raw) {
    final List<dynamic> data = json.decode(raw) as List<dynamic>;
    return data
        .map((item) => Magia.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<void> carregarMagias() async {
    _todas.clear();

    // Lista com os arquivos de cada círculo
    const circulos = [1, 2, 3, 4, 5];

    for (var circulo in circulos) {
      try {
        final response = await rootBundle.loadString(
          'assets/data/magias/${circulo}_circulo.json',
          cache: false,
        );

        final List<Magia> magiasCirculo;
        if (circulo == 1) {
          magiasCirculo = await Isolate.run(() => _parsearMagias(response));
        } else {
          magiasCirculo = _parsearMagias(response);
        }
        _todas.addAll(magiasCirculo);
      } catch (e, stack) {
        debugPrint('Erro ao carregar ${circulo}_circulo.json: $e\n$stack');
        assert(false, 'Erro ao carregar ${circulo}_circulo.json: $e');
      }
    }
    _reconstruirIndex();
  }

  @visibleForTesting
  static void carregarParaTestes(List<Magia> magias) {
    _todas.clear();
    _todas.addAll(magias);
    _reconstruirIndex();
  }

  static List<Magia> filtrarPorClasseETipo({
    required String tipo,
    required int circuloMaximo,
  }) {
    return _todas
        .where(
          (m) =>
              (m.tipo == tipo || m.tipo == 'universal') &&
              m.circulo <= circuloMaximo,
        )
        .toList();
  }

  static Magia getById(String id) {
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
