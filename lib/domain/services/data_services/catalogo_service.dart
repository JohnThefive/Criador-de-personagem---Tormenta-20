import 'package:flutter/foundation.dart';
import 'call_armaduras.dart';
import 'call_armas.dart';
import 'call_classes.dart';
import 'call_companheiros.dart';
import 'call_divindades.dart';
import 'call_efeitos_golpe_pessoal.dart';
import 'call_formas_selvagens.dart';
import 'call_magias.dart';
import 'call_montaria_sagrada.dart';
import 'call_origens.dart';
import 'call_pericias.dart';
import 'call_poderes.dart';
import 'call_racas.dart';
import 'call_regras_engenhocas.dart';

/// Centraliza o carregamento concorrente dos catálogos estáticos do sistema T20
/// mantendo um único [Future] compartilhado para evitar carregamentos duplicados
/// ou desserializações prematuras.
class CatalogoService {
  static Future<void>? _loadingFuture;

  /// Inicia o carregamento de todos os catálogos em paralelo via [Future.wait].
  static Future<void> carregarTodos() {
    _loadingFuture ??= Future.wait([
      BancoDeRacas.carregar(),
      BancoDeClasses.carregar(),
      BancoDeOrigens.carregar(),
      BancoDePoderes.carregar(),
      BancoDeArmas.carregar(),
      BancoDeArmaduras.carregar(),
      BancoDeFormasSelvagens.carregar(),
      BancoDeCompanheiros.carregar(),
      BancoDeEfeitosGolpePessoal.carregar(),
      BancoDeRegrasEngenhocas.carregar(),
      BancoDeRegrasMontariaSagrada.carregar(),
      BancoDeDivindades.carregar(),
      BancoDeMagias.carregarMagias(),
      BancoDePericias.carregarPericias(),
    ]).then((_) {});
    return _loadingFuture!;
  }

  /// Retorna o [Future] de carregamento em andamento ou concluído, se houver.
  static Future<void>? get future => _loadingFuture;

  @visibleForTesting
  static void resetar([Future<void>? future]) {
    _loadingFuture = future;
  }
}
