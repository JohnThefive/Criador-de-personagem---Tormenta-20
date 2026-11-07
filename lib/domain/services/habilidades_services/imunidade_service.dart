import 'package:t20_creator/domain/entities/habilidades/modelos_habilidade_duracao.dart';
import 'package:t20_creator/domain/entities/testes/configuracoes_mesa_t20.dart';

/// Resultado detalhado da avaliação de imunidade de uma criatura contra os tipos de um efeito.
class ResultadoChecagemImunidade {
  final bool imune;
  final Set<TipoEfeito> tiposEfeitoEfetivos;
  final Set<TipoEfeito> tiposImunes;
  final String? motivo;

  const ResultadoChecagemImunidade({
    required this.imune,
    required this.tiposEfeitoEfetivos,
    this.tiposImunes = const {},
    this.motivo,
  });
}

/// R57: Serviço puro de avaliação de tipos de efeito e imunidades do Tormenta 20.
class ImunidadeService {
  final ConfiguracoesMesaT20 configuracoes;

  const ImunidadeService({
    this.configuracoes = const ConfiguracoesMesaT20(),
  });

  /// R57 (Caso de Borda 8): ARCANO e DIVINO implicam MÁGICO automaticamente.
  Set<TipoEfeito> normalizarTipos(Set<TipoEfeito> tipos) {
    final set = Set<TipoEfeito>.from(tipos);
    if (set.contains(TipoEfeito.arcano) || set.contains(TipoEfeito.divino)) {
      set.add(TipoEfeito.magico);
    }
    return Set.unmodifiable(set);
  }

  /// R57 (Caso de Borda 7): Imunidades inatas por tipo de criatura e inteligência nula.
  /// - CONSTRUTO e MORTO_VIVO: imunes a CANSACO, METABOLISMO e VENENO.
  /// - Inteligência nula (`inteligencia == null`): imune a MEDO e MENTAL.
  Set<TipoEfeito> calcularImunidadesInatas(
    TipoCriatura tipoCriatura, {
    int? inteligencia,
  }) {
    final imunidades = <TipoEfeito>{};

    if (tipoCriatura == TipoCriatura.construto ||
        tipoCriatura == TipoCriatura.mortoVivo) {
      imunidades.add(TipoEfeito.cansaco);
      imunidades.add(TipoEfeito.metabolismo);
      imunidades.add(TipoEfeito.veneno);
    }

    if (inteligencia == null) {
      imunidades.add(TipoEfeito.medo);
      imunidades.add(TipoEfeito.mental);
    }

    return Set.unmodifiable(imunidades);
  }

  /// Retorna o conjunto total de imunidades de uma criatura (inatas + adicionais).
  Set<TipoEfeito> obterImunidadesTotais(Criatura criatura) {
    final inatas = calcularImunidadesInatas(
      criatura.tipoCriatura,
      inteligencia: criatura.inteligencia,
    );
    return Set.unmodifiable({...inatas, ...criatura.imunidades});
  }

  /// R57: Avalia se a criatura é imune ao efeito.
  /// Se o efeito possuir qualquer tipo imune, o alvo é considerado imune.
  ResultadoChecagemImunidade checarImunidade({
    required Criatura criatura,
    required Set<TipoEfeito> tiposEfeito,
  }) {
    final tiposEfetivos = normalizarTipos(tiposEfeito);
    if (tiposEfetivos.isEmpty) {
      return ResultadoChecagemImunidade(
        imune: false,
        tiposEfeitoEfetivos: tiposEfetivos,
      );
    }

    final imunidadesTotais = obterImunidadesTotais(criatura);
    final tiposImunes = tiposEfetivos.intersection(imunidadesTotais);

    if (tiposImunes.isEmpty) {
      return ResultadoChecagemImunidade(
        imune: false,
        tiposEfeitoEfetivos: tiposEfetivos,
      );
    }

    // Identifica motivos específicos para o log
    final motivos = <String>[];
    if (criatura.tipoCriatura == TipoCriatura.construto ||
        criatura.tipoCriatura == TipoCriatura.mortoVivo) {
      final inatasTipo = tiposImunes.where((t) =>
          t == TipoEfeito.cansaco ||
          t == TipoEfeito.metabolismo ||
          t == TipoEfeito.veneno);
      if (inatasTipo.isNotEmpty) {
        motivos.add(
            'tipo de criatura ${criatura.tipoCriatura.name} é imune a ${inatasTipo.map((e) => e.name).join(", ")}');
      }
    }

    if (criatura.temInteligenciaNula) {
      final inatasMente = tiposImunes
          .where((t) => t == TipoEfeito.medo || t == TipoEfeito.mental);
      if (inatasMente.isNotEmpty) {
        motivos.add(
            'inteligência nula é imune a ${inatasMente.map((e) => e.name).join(", ")}');
      }
    }

    final individuais = tiposImunes.difference(calcularImunidadesInatas(
      criatura.tipoCriatura,
      inteligencia: criatura.inteligencia,
    ));
    if (individuais.isNotEmpty) {
      motivos.add(
          'imunidade específica a ${individuais.map((e) => e.name).join(", ")}');
    }

    final motivoTexto =
        'Alvo "${criatura.nome}" é imune ao efeito (${motivos.join("; ")}).';

    return ResultadoChecagemImunidade(
      imune: true,
      tiposEfeitoEfetivos: tiposEfetivos,
      tiposImunes: tiposImunes,
      motivo: motivoTexto,
    );
  }
}
