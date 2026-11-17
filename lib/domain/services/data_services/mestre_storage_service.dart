import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../entities/combate/monstro.dart';
import '../../entities/mestre/modelos_mestre.dart';

/// Snapshot serializável do Painel do Mestre e das ameaças customizadas.
class MestreEstadoPersistido {
  final List<CampanhaMestre> campanhas;
  final String? campanhaSelecionadaId;
  final String? aventuraSelecionadaId;
  final String? sessaoSelecionadaId;
  final String? mapaSelecionadoId;
  final List<PerigoMestre>? perigos;
  final List<String> historicoNomes;
  final String? nomeGeradoAtual;
  final List<String> nomesFavoritos;
  final List<Monstro> ameacasCustomizadas;

  const MestreEstadoPersistido({
    required this.campanhas,
    this.campanhaSelecionadaId,
    this.aventuraSelecionadaId,
    this.sessaoSelecionadaId,
    this.mapaSelecionadoId,
    this.perigos,
    this.historicoNomes = const [],
    this.nomeGeradoAtual,
    this.nomesFavoritos = const [],
    this.ameacasCustomizadas = const [],
  });

  Map<String, dynamic> toJson() => {
        'versao': 1,
        'campanhas': campanhas.map((c) => c.toJson()).toList(),
        if (campanhaSelecionadaId != null)
          'campanhaSelecionadaId': campanhaSelecionadaId,
        if (aventuraSelecionadaId != null)
          'aventuraSelecionadaId': aventuraSelecionadaId,
        if (sessaoSelecionadaId != null)
          'sessaoSelecionadaId': sessaoSelecionadaId,
        if (mapaSelecionadoId != null) 'mapaSelecionadoId': mapaSelecionadoId,
        if (perigos != null) 'perigos': perigos!.map((p) => p.toJson()).toList(),
        'historicoNomes': historicoNomes,
        if (nomeGeradoAtual != null) 'nomeGeradoAtual': nomeGeradoAtual,
        'nomesFavoritos': nomesFavoritos,
        'ameacasCustomizadas':
            ameacasCustomizadas.map((m) => m.toJson()).toList(),
      };

  factory MestreEstadoPersistido.fromJson(Map<String, dynamic> json) {
    final campanhasList = (json['campanhas'] as List?)
            ?.whereType<Map>()
            .map((e) => CampanhaMestre.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        const <CampanhaMestre>[];
    final rawPerigos = json['perigos'];
    final perigosList = rawPerigos is List
        ? rawPerigos
            .whereType<Map>()
            .map((e) => PerigoMestre.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : null;
    final ameacasList = (json['ameacasCustomizadas'] as List?)
            ?.whereType<Map>()
            .map((e) => Monstro.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        const <Monstro>[];

    return MestreEstadoPersistido(
      campanhas: campanhasList,
      campanhaSelecionadaId: json['campanhaSelecionadaId']?.toString(),
      aventuraSelecionadaId: json['aventuraSelecionadaId']?.toString(),
      sessaoSelecionadaId: json['sessaoSelecionadaId']?.toString(),
      mapaSelecionadoId: json['mapaSelecionadoId']?.toString(),
      perigos: perigosList,
      historicoNomes: (json['historicoNomes'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      nomeGeradoAtual: json['nomeGeradoAtual']?.toString(),
      nomesFavoritos: (json['nomesFavoritos'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      ameacasCustomizadas: ameacasList,
    );
  }
}

/// Serviço de persistência local em JSON para o Painel do Mestre.
/// Espelha a estratégia de escrita atômica (.tmp + rename) de PersonagemStorageService.
class MestreStorageService {
  static const String _nomeArquivo = 'mestre_estado.json';
  static Directory? _diretorioTeste;
  static bool? _canalDisponivel;
  static String? _webCache;

  /// Indica se há backend de armazenamento disponível (evita timers órfãos em testes sem plugin).
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
      // Testes de widget sem channel path_provider falham aqui com segurança.
      _canalDisponivel = false;
      return null;
    }
  }

  static Future<MestreEstadoPersistido?> carregar() async {
    try {
      String? bruto;
      if (kIsWeb) {
        bruto = _webCache;
      } else {
        final arquivo = await _obterArquivo();
        if (arquivo == null || !await arquivo.exists()) return null;
        bruto = await arquivo.readAsString();
      }
      if (bruto == null || bruto.trim().isEmpty) return null;
      final decoded = jsonDecode(bruto);
      if (decoded is! Map) return null;
      return MestreEstadoPersistido.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> salvar(MestreEstadoPersistido estado) async {
    try {
      final jsonStr = jsonEncode(estado.toJson());
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
      // Ignora graciosamente falhas de IO em ambiente sem storage configurado.
    }
  }

  @visibleForTesting
  static Future<void> limpar() async {
    _webCache = null;
    if (kIsWeb) return;
    final arquivo = await _obterArquivo();
    if (arquivo != null && await arquivo.exists()) {
      await arquivo.delete();
    }
  }
}
