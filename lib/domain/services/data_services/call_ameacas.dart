import 'dart:collection';
import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:t20_creator/domain/entities/combate/monstro.dart';

/// Banco de dados de ameaças de Tormenta 20 com suporte a índice leve (`index.json`),
/// lazy-loading por região (`criaturas/<regiao>.json`) e mesclagem de ameaças customizadas.
class BancoDeAmeacas {
  static const String _indexAssetPath = 'assets/data/ameacas/index.json';

  static final List<AmeacaResumo> _resumosBase = [];
  static final List<Monstro> _criaturasBase = [];
  static final Map<String, Monstro> _customizadasPorId = {};

  static final Map<String, AmeacaResumo> _resumoIndexPorId = {};
  static final Map<String, Monstro> _indexPorId = {};
  static final Set<String> _regioesCarregadas = {};
  static final Map<String, Future<void>> _carregandoRegioes = {};
  static final Set<String> _regioesDisponiveis = {};

  /// Indica se o índice embutido (`index.json`) já foi carregado.
  static bool get indiceCarregado => _resumosBase.isNotEmpty;

  /// Lista imutável das ameaças customizadas atualmente registradas pelo Mestre.
  static List<Monstro> get customizadas =>
      UnmodifiableListView(_customizadasPorId.values.toList(growable: false));

  /// Lista imutável de todos os resumos (índice embutido + customizadas do Mestre).
  static List<AmeacaResumo> get resumos {
    if (_customizadasPorId.isEmpty) {
      return UnmodifiableListView(_resumosBase);
    }
    final combinados = <String, AmeacaResumo>{
      for (final r in _resumosBase) r.id.toLowerCase(): r,
    };
    for (final c in _customizadasPorId.values) {
      combinados[c.id.toLowerCase()] = AmeacaResumo.fromMonstro(c);
    }
    return UnmodifiableListView(combinados.values.toList(growable: false));
  }

  /// Lista imutável das fichas completas já carregadas em memória (embutidas + customizadas).
  static List<Monstro> get carregadas {
    if (_customizadasPorId.isEmpty) {
      return UnmodifiableListView(_criaturasBase);
    }
    final combinadas = <String, Monstro>{
      for (final m in _criaturasBase) m.id.toLowerCase(): m,
    };
    for (final c in _customizadasPorId.values) {
      combinadas[c.id.toLowerCase()] = c;
    }
    return UnmodifiableListView(combinadas.values.toList(growable: false));
  }

  /// Lista imutável das regiões conhecidas (embutidas + customizadas).
  static List<String> get regioes {
    final todas = <String>{
      ..._regioesDisponiveis,
      for (final c in _customizadasPorId.values)
        if (c.regiao.trim().isNotEmpty) c.regiao.trim(),
    }.toList()
      ..sort();
    return UnmodifiableListView(todas);
  }

  /// Verifica se uma região já teve seu JSON completo carregado.
  static bool regiaoCarregada(String regiao) =>
      _regioesCarregadas.contains(regiao.trim().toLowerCase());

  static List<AmeacaResumo> _parsearResumos(String raw) {
    final limpo = raw.trim();
    if (limpo.isEmpty) return const [];
    final decoded = json.decode(limpo);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(AmeacaResumo.fromJson)
        .toList();
  }

  static List<Monstro> _parsearMonstros(String raw) {
    final limpo = raw.trim();
    if (limpo.isEmpty) return const [];
    final decoded = json.decode(limpo);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(Monstro.fromJson)
        .toList();
  }

  static void _indexarResumo(AmeacaResumo resumo) {
    _resumoIndexPorId[resumo.id] = resumo;
    _resumoIndexPorId[resumo.id.toLowerCase()] = resumo;
    _resumoIndexPorId[resumo.id.toUpperCase()] = resumo;
  }

  static void _indexarMonstro(Monstro monstro) {
    _indexPorId[monstro.id] = monstro;
    _indexPorId[monstro.id.toLowerCase()] = monstro;
    _indexPorId[monstro.id.toUpperCase()] = monstro;
  }

  static void _reconstruirIndices() {
    _resumoIndexPorId.clear();
    _indexPorId.clear();

    for (final r in _resumosBase) {
      _indexarResumo(r);
    }
    for (final m in _criaturasBase) {
      _indexarMonstro(m);
    }
    // Ameaças customizadas do Mestre têm precedência sobre entradas com mesmo ID.
    for (final c in _customizadasPorId.values) {
      _indexarMonstro(c);
      _indexarResumo(AmeacaResumo.fromMonstro(c));
    }
  }

  static Future<String> _lerAssetTolerante(List<String> caminhos) async {
    for (final caminho in caminhos) {
      try {
        return await rootBundle.loadString(caminho, cache: false);
      } catch (_) {}
    }
    return '';
  }

  /// Carrega o índice leve de ameaças (`index.json`) para busca rápida e lazy-loading.
  static Future<void> carregar() async {
    _resumosBase.clear();
    _criaturasBase.clear();
    _regioesCarregadas.clear();
    _carregandoRegioes.clear();
    _regioesDisponiveis.clear();

    try {
      final raw = await _lerAssetTolerante([_indexAssetPath]);
      final lista = raw.trim().isEmpty
          ? const <AmeacaResumo>[]
          : await Isolate.run(() => _parsearResumos(raw));
      _resumosBase.addAll(lista);
      for (final r in _resumosBase) {
        if (r.regiao.trim().isNotEmpty) {
          _regioesDisponiveis.add(r.regiao.trim());
        }
      }
    } catch (e, stack) {
      debugPrint('Erro ao carregar $_indexAssetPath: $e\n$stack');
      assert(false, 'Erro ao carregar $_indexAssetPath: $e');
    }

    _reconstruirIndices();
  }

  /// Carrega sob demanda (lazy-loading) todas as fichas completas de uma [regiao].
  static Future<void> carregarRegiao(String regiao) {
    final key = regiao.trim().toLowerCase();
    if (key.isEmpty || _regioesCarregadas.contains(key)) {
      return Future.value();
    }
    return _carregandoRegioes.putIfAbsent(key, () async {
      try {
        final raw = await _lerAssetTolerante([
          'assets/data/ameacas/criaturas/$key.json',
          'assets/data/ameacas/$key.json',
        ]);
        final monstros = raw.trim().isEmpty
            ? const <Monstro>[]
            : await Isolate.run(() => _parsearMonstros(raw));
        final idsExistentes = _criaturasBase.map((m) => m.id).toSet();
        for (final m in monstros) {
          if (!idsExistentes.contains(m.id)) {
            _criaturasBase.add(m);
            idsExistentes.add(m.id);
          }
        }
        _regioesCarregadas.add(key);
        _regioesDisponiveis.add(key);
        _reconstruirIndices();
      } catch (e, stack) {
        debugPrint('Erro ao carregar região de ameaças "$key": $e\n$stack');
      } finally {
        _carregandoRegioes.remove(key);
      }
    });
  }

  /// Carrega em paralelo todas as regiões presentes no índice.
  static Future<void> carregarTodasRegioes() async {
    final pendentes = _regioesDisponiveis
        .where((r) => !_regioesCarregadas.contains(r.toLowerCase()))
        .toList();
    if (pendentes.isEmpty) return;
    await Future.wait(pendentes.map(carregarRegiao));
  }

  /// Recupera em O(1) o resumo leve pelo [id].
  static AmeacaResumo? getResumoById(String id) {
    return _resumoIndexPorId[id] ??
        _resumoIndexPorId[id.toLowerCase()] ??
        _resumoIndexPorId[id.toUpperCase()];
  }

  /// Recupera em O(1) uma criatura já carregada (ou customizada) pelo [id].
  static Monstro? getById(String id) {
    return _indexPorId[id] ??
        _indexPorId[id.toLowerCase()] ??
        _indexPorId[id.toUpperCase()];
  }

  /// Recupera uma criatura pelo [id], carregando sua região sob demanda se necessário.
  static Future<Monstro?> getByIdAsync(String id) async {
    final jaCarregada = getById(id);
    if (jaCarregada != null) return jaCarregada;

    final resumo = getResumoById(id);
    if (resumo == null || resumo.regiao.trim().isEmpty) return null;

    await carregarRegiao(resumo.regiao);
    return getById(id);
  }

  /// Filtra as entradas do índice leve por região, ND, papel, tipo e busca textual.
  static List<AmeacaResumo> filtrarResumos({
    String? regiao,
    String? nd,
    PapelMonstro? papel,
    String? tipo,
    String? busca,
  }) {
    final regiaoNorm = regiao?.trim().toLowerCase();
    final ndNorm = nd?.trim().toLowerCase();
    final tipoNorm = tipo?.trim().toLowerCase();
    final buscaNorm = busca?.trim().toLowerCase();

    return resumos.where((r) {
      if (regiaoNorm != null &&
          regiaoNorm.isNotEmpty &&
          r.regiao.toLowerCase() != regiaoNorm) {
        return false;
      }
      if (ndNorm != null &&
          ndNorm.isNotEmpty &&
          AmeacaResumo.parseNdNumerico(r.nd) !=
              AmeacaResumo.parseNdNumerico(ndNorm) &&
          r.nd.toLowerCase() != ndNorm) {
        return false;
      }
      if (papel != null && r.papel != papel) {
        return false;
      }
      if (tipoNorm != null &&
          tipoNorm.isNotEmpty &&
          r.tipoCriatura.toLowerCase() != tipoNorm) {
        return false;
      }
      if (buscaNorm != null &&
          buscaNorm.isNotEmpty &&
          !r.nome.toLowerCase().contains(buscaNorm) &&
          !r.id.toLowerCase().contains(buscaNorm)) {
        return false;
      }
      return true;
    }).toList(growable: false);
  }

  /// Filtra as fichas completas já carregadas por região, ND, papel, tipo e busca.
  static List<Monstro> filtrarCarregadas({
    String? regiao,
    String? nd,
    PapelMonstro? papel,
    String? tipo,
    String? busca,
  }) {
    final regiaoNorm = regiao?.trim().toLowerCase();
    final ndNorm = nd?.trim().toLowerCase();
    final tipoNorm = tipo?.trim().toLowerCase();
    final buscaNorm = busca?.trim().toLowerCase();

    return carregadas.where((m) {
      if (regiaoNorm != null &&
          regiaoNorm.isNotEmpty &&
          m.regiao.toLowerCase() != regiaoNorm) {
        return false;
      }
      if (ndNorm != null &&
          ndNorm.isNotEmpty &&
          AmeacaResumo.parseNdNumerico(m.nd) !=
              AmeacaResumo.parseNdNumerico(ndNorm) &&
          m.nd.toLowerCase() != ndNorm) {
        return false;
      }
      if (papel != null && m.papel != papel) {
        return false;
      }
      if (tipoNorm != null &&
          tipoNorm.isNotEmpty &&
          m.tipoCriatura.toLowerCase() != tipoNorm) {
        return false;
      }
      if (buscaNorm != null &&
          buscaNorm.isNotEmpty &&
          !m.nome.toLowerCase().contains(buscaNorm) &&
          !m.id.toLowerCase().contains(buscaNorm)) {
        return false;
      }
      return true;
    }).toList(growable: false);
  }

  /// Substitui a camada de ameaças customizadas do Mestre, mesclando aos índices ativos.
  static void mesclarCustomizadas(List<Monstro> customizadas) {
    _customizadasPorId.clear();
    for (final c in customizadas) {
      final marcada = c.customizado ? c : _marcarCustomizada(c);
      _customizadasPorId[marcada.id.toLowerCase()] = marcada;
    }
    _reconstruirIndices();
  }

  /// Adiciona ou atualiza uma única ameaça customizada criada pelo Mestre.
  static void adicionarOuAtualizarCustomizada(Monstro monstro) {
    final marcada = monstro.customizado ? monstro : _marcarCustomizada(monstro);
    _customizadasPorId[marcada.id.toLowerCase()] = marcada;
    _reconstruirIndices();
  }

  /// Remove uma ameaça customizada pelo [id] e restaura a original (se houver).
  static void removerCustomizada(String id) {
    _customizadasPorId.remove(id.toLowerCase());
    _reconstruirIndices();
  }

  static Monstro _marcarCustomizada(Monstro m) {
    return Monstro(
      id: m.id,
      nome: m.nome,
      nd: m.nd,
      regiao: m.regiao,
      papel: m.papel,
      tipoCriatura: m.tipoCriatura,
      subtipo: m.subtipo,
      tamanho: m.tamanho,
      pvMax: m.pvMax,
      pmMax: m.pmMax,
      defesa: m.defesa,
      deslocamentoMetros: m.deslocamentoMetros,
      deslocamentos: m.deslocamentos,
      iniciativa: m.iniciativa,
      percepcao: m.percepcao,
      sentidos: m.sentidos,
      fortitude: m.fortitude,
      reflexos: m.reflexos,
      vontade: m.vontade,
      rd: m.rd,
      imunidadesEfeitos: m.imunidadesEfeitos,
      imunidadesDano: m.imunidadesDano,
      vulnerabilidadesDano: m.vulnerabilidadesDano,
      habilidadesDefensivas: m.habilidadesDefensivas,
      modForca: m.modForca,
      modDestreza: m.modDestreza,
      modConstituicao: m.modConstituicao,
      modInteligencia: m.modInteligencia,
      modSabedoria: m.modSabedoria,
      modCarisma: m.modCarisma,
      forcaNula: m.forcaNula,
      destrezaNula: m.destrezaNula,
      constituicaoNula: m.constituicaoNula,
      pericias: m.pericias,
      ataques: m.ataques,
      habilidades: m.habilidades,
      equipamento: m.equipamento,
      tesouro: m.tesouro,
      recursoExtraivel: m.recursoExtraivel,
      customizado: true,
    );
  }

  @visibleForTesting
  static void carregarParaTestes({
    List<AmeacaResumo> resumos = const [],
    List<Monstro> monstros = const [],
    List<Monstro> customizadas = const [],
  }) {
    resetar();
    _criaturasBase.addAll(monstros);
    if (resumos.isNotEmpty) {
      _resumosBase.addAll(resumos);
    } else {
      _resumosBase.addAll(monstros.map(AmeacaResumo.fromMonstro));
    }
    for (final r in _resumosBase) {
      if (r.regiao.trim().isNotEmpty) {
        _regioesDisponiveis.add(r.regiao.trim());
      }
    }
    for (final m in monstros) {
      if (m.regiao.trim().isNotEmpty) {
        _regioesCarregadas.add(m.regiao.trim().toLowerCase());
        _regioesDisponiveis.add(m.regiao.trim());
      }
    }
    mesclarCustomizadas(customizadas);
  }

  @visibleForTesting
  static void resetar() {
    _resumosBase.clear();
    _criaturasBase.clear();
    _customizadasPorId.clear();
    _resumoIndexPorId.clear();
    _indexPorId.clear();
    _regioesCarregadas.clear();
    _carregandoRegioes.clear();
    _regioesDisponiveis.clear();
  }
}
