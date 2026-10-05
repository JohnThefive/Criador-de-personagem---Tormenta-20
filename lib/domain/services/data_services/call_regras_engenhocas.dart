import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';

class BancoDeRegrasEngenhocas {
  static Map<String, dynamic>? _dados;

  static Map<String, dynamic> _parse(String raw) {
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<void> carregar() async {
    final raw = await rootBundle.loadString('assets/data/regras_engenhocas.json');
    _dados = _parse(raw);
  }

  static Map<String, dynamic> get regras {
    if (_dados == null) {
      try {
        final file = File('assets/data/regras_engenhocas.json');
        if (file.existsSync()) {
          _dados = _parse(file.readAsStringSync());
        }
      } catch (_) {}
    }
    return _dados ?? const {};
  }

  static void carregarParaTestes(Map<String, dynamic> dados) {
    _dados = Map.from(dados);
  }

  /// Retorna o círculo máximo de magia permitido para o nível de inventor
  /// 1º a 5º nível -> 1º círculo
  /// 6º a 9º nível -> 2º círculo
  /// 10º a 13º nível -> 3º círculo
  /// 14º a 17º nível -> 4º círculo
  /// 18º+ nível -> 5º círculo
  static int circuloMaximoParaNivel(int nivelInventor) {
    if (nivelInventor >= 18) return 5;
    if (nivelInventor >= 14) return 4;
    if (nivelInventor >= 10) return 3;
    if (nivelInventor >= 6) return 2;
    if (nivelInventor >= 1) return 1;
    return 0;
  }

  /// Custo de PM base por círculo segundo Tormenta 20:
  /// 1º: 1 PM, 2º: 3 PM, 3º: 6 PM, 4º: 10 PM, 5º: 15 PM
  static int custoPmBaseParaCirculo(int circulo) {
    switch (circulo) {
      case 1:
        return 1;
      case 2:
        return 3;
      case 3:
        return 6;
      case 4:
        return 10;
      case 5:
        return 15;
      default:
        return 1;
    }
  }

  /// CD base de ativação de engenhoca: 15 + CUSTO_PM_MAGIA
  static int calcularCdAtivacaoBase(int custoPm) {
    return 15 + custoPm;
  }

  /// CD do teste de Ofício (engenhoqueiro) para fabricação: 20 + CUSTO_PM_MAGIA
  static int calcularCdFabricacao(int custoPm) {
    return 20 + custoPm;
  }

  /// Custo monetário de fabricação em T$: 100 * CUSTO_PM_MAGIA
  static int calcularCustoFabricacaoTibares(int custoPm) {
    return 100 * custoPm;
  }

  /// Limite máximo de engenhocas que o inventor consegue manter ativas.
  /// Base = Inteligência (+3 se tiver Manutenção Eficiente). Mínimo 0.
  static int calcularLimiteEngenhocas({
    required int inteligencia,
    bool temManutencaoEficiente = false,
  }) {
    final int extra = temManutencaoEficiente ? 3 : 0;
    final int total = inteligencia + extra;
    return total < 0 ? 0 : total;
  }

  /// Espaços ocupados por uma engenhoca no inventário:
  /// 1 espaço por padrão; 0.5 se possuir Manutenção Eficiente.
  static num espacoOcupadoPorEngenhoca({bool temManutencaoEficiente = false}) {
    return temManutencaoEficiente ? 0.5 : 1.0;
  }
}
