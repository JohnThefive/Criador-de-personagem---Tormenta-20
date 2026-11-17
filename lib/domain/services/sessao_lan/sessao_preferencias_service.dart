import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Preferências locais do Jogador para a aba Sessão (nome e último código usado).
/// Segue o mesmo padrão atômico de [MestreStorageService].
class SessaoPreferencias {
  final String nomeJogador;
  final String ultimoCodigoSala;

  const SessaoPreferencias({
    this.nomeJogador = '',
    this.ultimoCodigoSala = '',
  });

  Map<String, dynamic> toJson() => {
        'nomeJogador': nomeJogador,
        'ultimoCodigoSala': ultimoCodigoSala,
      };

  factory SessaoPreferencias.fromJson(Map<String, dynamic> json) {
    return SessaoPreferencias(
      nomeJogador: (json['nomeJogador'] ?? '').toString(),
      ultimoCodigoSala: (json['ultimoCodigoSala'] ?? '').toString(),
    );
  }
}

class SessaoPreferenciasService {
  static const String _nomeArquivo = 'sessao_jogador_prefs.json';
  static Directory? _diretorioTeste;
  static bool? _canalDisponivel;
  static String? _webCache;

  static bool get podePersistir =>
      kIsWeb || _diretorioTeste != null || _canalDisponivel != false;

  @visibleForTesting
  static void setDiretorioTeste(Directory? dir) {
    _diretorioTeste = dir;
    _canalDisponivel = dir != null ? true : null;
  }

  static Future<File?> _obterArquivo() async {
    if (_diretorioTeste != null) {
      _canalDisponivel = true;
      return File('${_diretorioTeste!.path}/$_nomeArquivo');
    }
    try {
      final base = await getApplicationDocumentsDirectory();
      _canalDisponivel = true;
      return File('${base.path}/$_nomeArquivo');
    } catch (_) {
      _canalDisponivel = false;
      return null;
    }
  }

  static Future<SessaoPreferencias> carregar() async {
    try {
      String? bruto;
      if (kIsWeb) {
        bruto = _webCache;
      } else {
        final arquivo = await _obterArquivo();
        if (arquivo == null || !await arquivo.exists()) {
          return const SessaoPreferencias();
        }
        bruto = await arquivo.readAsString();
      }
      if (bruto == null || bruto.trim().isEmpty) {
        return const SessaoPreferencias();
      }
      final decoded = jsonDecode(bruto);
      if (decoded is! Map) return const SessaoPreferencias();
      return SessaoPreferencias.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return const SessaoPreferencias();
    }
  }

  static Future<void> salvar(SessaoPreferencias prefs) async {
    try {
      final jsonStr = jsonEncode(prefs.toJson());
      if (kIsWeb) {
        _webCache = jsonStr;
        return;
      }
      final arquivo = await _obterArquivo();
      if (arquivo == null) return;
      final dir = arquivo.parent;
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final tmp = File('${arquivo.path}.tmp');
      await tmp.writeAsString(jsonStr, flush: true);
      await tmp.rename(arquivo.path);
    } catch (_) {
      // Silencioso: falha de disco não deve impedir o uso da ficha.
    }
  }
}
