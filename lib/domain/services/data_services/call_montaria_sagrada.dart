import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';

class BancoDeRegrasMontariaSagrada {
  static Map<String, dynamic>? _dados;

  static Map<String, dynamic> _parse(String raw) {
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<void> carregar() async {
    final raw = await rootBundle.loadString('assets/data/regras_montaria_sagrada.json');
    _dados = _parse(raw);
  }

  static Map<String, dynamic> get regras {
    if (_dados == null) {
      try {
        final file = File('assets/data/regras_montaria_sagrada.json');
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

  static int get nivelDisponivel => (regras['nivelDisponivel'] as num?)?.toInt() ?? 5;

  static int get custoPmInvocacao {
    final custo = regras['custoInvocacao'] as Map?;
    return (custo?['pm'] as num?)?.toInt() ?? 2;
  }

  static String get acaoInvocacao {
    final custo = regras['custoInvocacao'] as Map?;
    return (custo?['acao'] as String?) ?? 'MOVIMENTO';
  }

  static String get duracaoInvocacao {
    final custo = regras['custoInvocacao'] as Map?;
    return (custo?['duracao'] as String?) ?? 'FIM_DA_CENA';
  }

  static String tierParaNivel(int nivelPaladino) {
    if (nivelPaladino >= 11) return 'MESTRE';
    if (nivelPaladino >= 5) return 'VETERANO';
    return 'INICIANTE';
  }

  static int deslocamentoParaNivel(int nivelPaladino) {
    final tier = tierParaNivel(nivelPaladino);
    if (tier == 'MESTRE') return 21;
    if (tier == 'VETERANO') return 18;
    return 15;
  }

  static String beneficiosParaTier(String tier) {
    switch (tier.toUpperCase()) {
      case 'MESTRE':
        return 'Deslocamento 21m e concede uma ação de movimento extra por rodada.';
      case 'VETERANO':
        return 'Deslocamento 18m e pode realizar uma investida sem linha reta obrigatória.';
      default:
        return 'Deslocamento 15m (ou +3m se já superior).';
    }
  }

  static String animalPadraoParaTamanho(String? tamanho) {
    if (tamanho?.trim().toUpperCase() == 'PEQUENO') {
      return (regras['animaisPadrao'] as Map?)?['PEQUENO']?.toString() ?? 'Pônei';
    }
    return (regras['animaisPadrao'] as Map?)?['MEDIO']?.toString() ?? 'Cavalo de Guerra';
  }

  static List<String> get propriedades {
    final props = regras['propriedades'] as List?;
    if (props != null) {
      return props.map((p) => p.toString()).toList();
    }
    return const [
      'Vínculo mental com o cavaleiro (dispensa testes de Adestramento).',
      'Cumpre qualquer ordem incondicionalmente, mesmo arriscando a vida.',
      'Se a montaria morrer, o paladino fica atordoado por 1 rodada.',
      'Uma nova montaria pode ser invocada após um dia inteiro de prece e meditação.',
    ];
  }

  static String get descricaoVarianteMundana {
    final vm = regras['varianteMundana'] as Map?;
    return vm?['descricao']?.toString() ??
        'O animal é mundano em vez de invocado (sem custo de PM ou ação para invocar, mas restrito a terrenos acessíveis).';
  }
}
