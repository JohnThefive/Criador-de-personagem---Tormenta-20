import 'dart:math';

import 'package:t20_creator/domain/entities/testes/configuracoes_mesa_t20.dart';
import 'package:t20_creator/domain/entities/testes/modelos_teste_t20.dart';
import 'package:t20_creator/domain/services/testes_services/i_rng.dart';

/// Resultado da avaliação de Chance de Falha (R29).
class ResultadoChanceFalha {
  final int chanceTotalBruta;
  final int chanceEfetiva;
  final int? d100Rolado;
  final bool falhou;
  final List<ModificadorAplicado> avaliados;

  const ResultadoChanceFalha({
    required this.chanceTotalBruta,
    required this.chanceEfetiva,
    this.d100Rolado,
    required this.falhou,
    required this.avaliados,
  });
}

/// R29 e R49: Motor puro de acúmulo de modificadores e chance de falha do Tormenta 20.
class ModificadorEngine {
  final ConfiguracoesMesaT20 configuracoes;

  const ModificadorEngine({
    this.configuracoes = const ConfiguracoesMesaT20(),
  });

  /// Avalia uma lista de modificadores candidatos para uma característica/alvo,
  /// retornando a lista completa com `aplicado: true/false` e `motivoIgnorado` preenchido.
  List<ModificadorAplicado> resolverModificadores(
    List<ModificadorAplicado> candidatos, {
    Set<String>? efeitosAtivosIds,
  }) {
    if (candidatos.isEmpty) return const [];

    // Cópia mutável de trabalho mantendo a ordem original
    final resultado = List<ModificadorAplicado>.generate(
      candidatos.length,
      (i) => candidatos[i].copyWith(aplicado: true, motivoIgnorado: null),
    );

    // 0. R49: Filtra modificadores cujos efeitos já expiraram antes de travar os modificadores
    if (efeitosAtivosIds != null) {
      for (int i = 0; i < resultado.length; i++) {
        final m = resultado[i];
        if (m.efeitoId != null && !efeitosAtivosIds.contains(m.efeitoId)) {
          resultado[i] = m.copyWith(
            aplicado: false,
            motivoIgnorado: 'Efeito ${m.efeitoId} não está mais ativo',
          );
        }
      }
    }

    // Agrupa índices por (alvoId, alvoCaracteristica)
    final gruposAlvoCaract = <String, List<int>>{};
    for (int i = 0; i < resultado.length; i++) {
      if (!resultado[i].aplicado) continue;
      final chave =
          '${resultado[i].alvoId ?? ""}::${resultado[i].alvoCaracteristica.trim().toUpperCase()}';
      gruposAlvoCaract.putIfAbsent(chave, () => []).add(i);
    }

    for (final entry in gruposAlvoCaract.entries) {
      final indices = entry.value;
      final caractUpper =
          resultado[indices.first].alvoCaracteristica.trim().toUpperCase();

      // 1. ATRIBUTO: troca de atributo substitui o original; mesmo atributo não soma 2x
      _resolverAtributos(resultado, indices);

      // 2. HABILIDADE e PERICIA: mesma fonteId não acumula (mantém melhor bônus / pior penalidade)
      _resolverPorChaveUnica(
        resultado,
        indices.where((i) {
          final t = resultado[i].fonteTipo;
          return t == FonteModificador.habilidade ||
              t == FonteModificador.pericia;
        }).toList(),
        gerarChave: (m) =>
            '${m.fonteTipo.name}::${m.fonteId.trim().toUpperCase()}',
        motivo: (m) =>
            'Não acumula com outra instância da mesma ${m.fonteTipo.name} (${m.fonteId})',
      );

      // 3. ARMADURA, ESCUDO e ITEM em DEFESA vs geral
      if (caractUpper == 'DEFESA') {
        _resolverDefesaArmaduraEscudoItens(resultado, indices);
      } else {
        // Fora de Defesa, ITEM não acumula com outro ITEM
        _resolverPorChaveUnica(
          resultado,
          indices
              .where((i) => resultado[i].fonteTipo == FonteModificador.item)
              .toList(),
          gerarChave: (_) => 'FONTE_ITEM',
          motivo: (_) => 'Bônus/penalidades de ITEM não acumulam entre si',
        );
      }

      // 4. MAGIA, PARCEIRO e AMBIENTE: não acumulam entre efeitos da mesma fonteTipo
      for (final tipo in const [
        FonteModificador.magia,
        FonteModificador.parceiro,
        FonteModificador.ambiente,
      ]) {
        _resolverPorChaveUnica(
          resultado,
          indices.where((i) => resultado[i].fonteTipo == tipo).toList(),
          gerarChave: (_) => tipo.name,
          motivo: (_) =>
              'Efeitos de ${tipo.name.toUpperCase()} não acumulam entre si',
        );
      }

      // 5. FERRAMENTA: aplica penalidade no máximo 1 vez
      _resolverPorChaveUnica(
        resultado,
        indices
            .where(
              (i) => resultado[i].fonteTipo == FonteModificador.ferramenta,
            )
            .toList(),
        gerarChave: (_) => 'FERRAMENTA',
        motivo: (_) => 'Penalidade por falta de ferramenta aplica-se apenas 1x',
      );
    }

    return List.unmodifiable(resultado);
  }

  /// Soma apenas os modificadores com `aplicado == true` após resolver o acúmulo.
  int somarModificadoresAplicados(
    List<ModificadorAplicado> candidatos, {
    Set<String>? efeitosAtivosIds,
  }) {
    final resolvidos = resolverModificadores(
      candidatos,
      efeitosAtivosIds: efeitosAtivosIds,
    );
    return resolvidos
        .where((m) => m.aplicado)
        .fold<int>(0, (soma, m) => soma + m.valor);
  }

  /// R29 (Caso de Borda 10): Calcula a chance de falha acumulada (mesma fonte não acumula,
  /// fontes diferentes somam, respeitando o teto de 75%).
  ResultadoChanceFalha calcularChanceFalha(
    List<ModificadorAplicado> chances, {
    IRng? rng,
  }) {
    final avaliados = List<ModificadorAplicado>.generate(
      chances.length,
      (i) => chances[i].copyWith(aplicado: true, motivoIgnorado: null),
    );

    // Mesma fonte (fonteTipo + fonteId) não acumula: mantém apenas o maior percentual
    final porFonte = <String, List<int>>{};
    for (int i = 0; i < avaliados.length; i++) {
      final m = avaliados[i];
      final chave =
          '${m.fonteTipo.name}::${m.fonteId.trim().toUpperCase()}';
      porFonte.putIfAbsent(chave, () => []).add(i);
    }

    for (final indices in porFonte.values) {
      if (indices.length <= 1) continue;
      int idxMaior = indices.first;
      for (final idx in indices.skip(1)) {
        if (avaliados[idx].valor > avaliados[idxMaior].valor) {
          idxMaior = idx;
        }
      }
      for (final idx in indices) {
        if (idx != idxMaior) {
          avaliados[idx] = avaliados[idx].copyWith(
            aplicado: false,
            motivoIgnorado:
                'Chance de falha da mesma fonte (${avaliados[idx].fonteId}) não acumula',
          );
        }
      }
    }

    final somaBruta = avaliados
        .where((m) => m.aplicado)
        .fold<int>(0, (s, m) => s + max(0, m.valor));
    final chanceEfetiva = min(
      configuracoes.tetoChanceFalhaPercentual,
      somaBruta,
    );

    int? d100;
    bool falhou = false;
    if (rng != null && chanceEfetiva > 0) {
      d100 = rng.rolarD100();
      falhou = d100 <= chanceEfetiva;
    }

    return ResultadoChanceFalha(
      chanceTotalBruta: somaBruta,
      chanceEfetiva: chanceEfetiva,
      d100Rolado: d100,
      falhou: falhou,
      avaliados: List.unmodifiable(avaliados),
    );
  }

  // ===========================================================================
  // AUXILIARES PRIVADOS DE ACÚMULO (R29)
  // ===========================================================================

  void _resolverAtributos(
    List<ModificadorAplicado> resultado,
    List<int> indices,
  ) {
    final indicesAtrib = indices
        .where((i) => resultado[i].fonteTipo == FonteModificador.atributo)
        .toList();
    if (indicesAtrib.isEmpty) return;

    // Se algum modificador de atributo troca o atributo-chave (`substituiAtributoBase`),
    // os atributos base que não têm essa flag são substituídos.
    final temSubstituto =
        indicesAtrib.any((i) => resultado[i].substituiAtributoBase);
    if (temSubstituto) {
      bool jaManteveSubstituto = false;
      for (final i in indicesAtrib) {
        if (!resultado[i].substituiAtributoBase) {
          resultado[i] = resultado[i].copyWith(
            aplicado: false,
            motivoIgnorado: 'Substituído por habilidade que troca o atributo-chave',
          );
        } else if (!jaManteveSubstituto) {
          jaManteveSubstituto = true;
        } else {
          resultado[i] = resultado[i].copyWith(
            aplicado: false,
            motivoIgnorado: 'Apenas uma substituição de atributo-chave pode vigorar',
          );
        }
      }
    }

    // O mesmo atributo nunca é somado mais de uma vez na mesma característica (Caso de Borda 9)
    final atributosVistos = <String>{};
    for (final i in indicesAtrib) {
      if (!resultado[i].aplicado) continue;
      final sigla = resultado[i].fonteId.trim().toUpperCase();
      if (!atributosVistos.add(sigla)) {
        resultado[i] = resultado[i].copyWith(
          aplicado: false,
          motivoIgnorado:
              'O atributo $sigla já foi somado nesta característica',
        );
      }
    }
  }

  void _resolverDefesaArmaduraEscudoItens(
    List<ModificadorAplicado> resultado,
    List<int> indices,
  ) {
    // 1. Armadura: no máximo 1 armadura soma na Defesa
    _resolverPorChaveUnica(
      resultado,
      indices
          .where((i) => resultado[i].fonteTipo == FonteModificador.armadura)
          .toList(),
      gerarChave: (_) => 'ARMADURA',
      motivo: (_) => 'Bônus de duas armaduras não acumulam',
    );

    // 2. Escudo: no máximo 1 escudo soma na Defesa (acumula com armadura)
    _resolverPorChaveUnica(
      resultado,
      indices
          .where((i) => resultado[i].fonteTipo == FonteModificador.escudo)
          .toList(),
      gerarChave: (_) => 'ESCUDO',
      motivo: (_) => 'Bônus de dois escudos não acumulam',
    );

    // 3. Itens adicionais na Defesa: até `limiteItensAdicionaisDefesa` (padrão 1)
    final indicesItemBonus = indices
        .where(
          (i) =>
              resultado[i].fonteTipo == FonteModificador.item &&
              resultado[i].valor > 0,
        )
        .toList();

    final limite = max(0, configuracoes.limiteItensAdicionaisDefesa);
    if (indicesItemBonus.length > limite) {
      // Ordena índices pelos maiores bônus (estável em caso de empate)
      final ordenados = List<int>.from(indicesItemBonus)
        ..sort((a, b) => resultado[b].valor.compareTo(resultado[a].valor));
      final permitidos = ordenados.take(limite).toSet();
      for (final idx in indicesItemBonus) {
        if (!permitidos.contains(idx)) {
          resultado[idx] = resultado[idx].copyWith(
            aplicado: false,
            motivoIgnorado:
                'Limite de $limite item(ns) adicional(is) na Defesa atingido (Armadura + Escudo + $limite item)',
          );
        }
      }
    }

    // Penalidades de ITEM na Defesa: mantém a pior penalidade
    final indicesItemPenal = indices
        .where(
          (i) =>
              resultado[i].fonteTipo == FonteModificador.item &&
              resultado[i].valor < 0,
        )
        .toList();
    if (indicesItemPenal.length > 1) {
      int idxPior = indicesItemPenal.first;
      for (final idx in indicesItemPenal.skip(1)) {
        if (resultado[idx].valor < resultado[idxPior].valor) {
          idxPior = idx;
        }
      }
      for (final idx in indicesItemPenal) {
        if (idx != idxPior) {
          resultado[idx] = resultado[idx].copyWith(
            aplicado: false,
            motivoIgnorado: 'Penalidades de ITEM não acumulam entre si',
          );
        }
      }
    }
  }

  void _resolverPorChaveUnica(
    List<ModificadorAplicado> resultado,
    List<int> indicesSubset, {
    required String Function(ModificadorAplicado) gerarChave,
    required String Function(ModificadorAplicado) motivo,
  }) {
    if (indicesSubset.length <= 1) return;

    final grupos = <String, List<int>>{};
    for (final idx in indicesSubset) {
      if (!resultado[idx].aplicado) continue;
      final k = gerarChave(resultado[idx]);
      grupos.putIfAbsent(k, () => []).add(idx);
    }

    for (final listaIdx in grupos.values) {
      if (listaIdx.length <= 1) continue;

      // Bônus (> 0): vale o maior bônus
      final bonusIdx =
          listaIdx.where((i) => resultado[i].valor >= 0).toList();
      if (bonusIdx.length > 1) {
        int idxMelhor = bonusIdx.first;
        if (configuracoes.mesmaFonteMantemMelhorBonusPiorPenalidade) {
          for (final i in bonusIdx.skip(1)) {
            if (resultado[i].valor > resultado[idxMelhor].valor) {
              idxMelhor = i;
            }
          }
        }
        for (final i in bonusIdx) {
          if (i != idxMelhor) {
            resultado[i] = resultado[i].copyWith(
              aplicado: false,
              motivoIgnorado: motivo(resultado[i]),
            );
          }
        }
      }

      // Penalidades (< 0): vale a pior penalidade (menor valor)
      final penalIdx =
          listaIdx.where((i) => resultado[i].valor < 0).toList();
      if (penalIdx.length > 1) {
        int idxPior = penalIdx.first;
        if (configuracoes.mesmaFonteMantemMelhorBonusPiorPenalidade) {
          for (final i in penalIdx.skip(1)) {
            if (resultado[i].valor < resultado[idxPior].valor) {
              idxPior = i;
            }
          }
        }
        for (final i in penalIdx) {
          if (i != idxPior) {
            resultado[i] = resultado[i].copyWith(
              aplicado: false,
              motivoIgnorado: motivo(resultado[i]),
            );
          }
        }
      }
    }
  }
}
