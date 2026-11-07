import 'dart:math';

import 'package:t20_creator/domain/entities/habilidades/modelos_habilidade_duracao.dart';
import 'package:t20_creator/domain/entities/testes/configuracoes_mesa_t20.dart';
import 'package:t20_creator/domain/entities/testes/modelos_teste_t20.dart';

/// R25–R28 e R31: Serviço puro de gerenciamento de Pontos de Mana (PM),
/// limites de nível, reduções de custo, componentes materiais, penalidades e sacrifícios.
class PMService {
  final ConfiguracoesMesaT20 configuracoes;

  const PMService({
    this.configuracoes = const ConfiguracoesMesaT20(),
  });

  /// R26 e R31 (Caso de Borda 4): Calcula o limite de nível da habilidade para o personagem.
  /// Habilidades de CLASSE usam o nível na classe que a concede;
  /// habilidades de raça, origem ou poder geral usam o nível total.
  int limiteNivel(
    Habilidade habilidade,
    EstadoPersonagemHabilidade personagem,
  ) {
    if (habilidade.origem == OrigemHabilidade.classe) {
      if (habilidade.classeId != null &&
          personagem.niveisPorClasse.containsKey(habilidade.classeId)) {
        return max(1, personagem.niveisPorClasse[habilidade.classeId]!);
      }
      if (personagem.niveisPorClasse.isNotEmpty) {
        return max(1, personagem.niveisPorClasse.values.first);
      }
    }
    return max(1, personagem.nivelTotal);
  }

  /// R26 (Caso de Borda 4): Calcula o limite efetivo de custo variável.
  /// O personagem SEMPRE pode usar o custo mínimo, mesmo que o limite de nível seja menor:
  /// `limiteEfetivo = max(min, min(limiteNivel, maxDefinido))`.
  int limiteEfetivoCustoVariavel(
    Habilidade habilidade,
    EstadoPersonagemHabilidade personagem,
  ) {
    final varSpec = habilidade.custo.variavel;
    if (varSpec == null) {
      return habilidade.custo.fixo ?? 0;
    }
    final limNivel = limiteNivel(habilidade, personagem);
    final teto = varSpec.max != null ? min(varSpec.max!, limNivel) : limNivel;
    return max(varSpec.min, teto);
  }

  /// R27 (Caso de Borda 11): Calcula o custo final em PM aplicando reduções.
  /// Reduções NÃO acumulam por padrão (vale apenas a maior).
  /// O piso é 1 PM apenas quando o custo base >= 1 (custo base 0 continua 0).
  int calcularCustoFinalPM({
    required int custoBase,
    List<ReducaoCusto> reducoes = const [],
  }) {
    if (custoBase <= 0) return 0;
    if (reducoes.isEmpty) return custoBase;

    final int reducaoAplicada;
    if (configuracoes.reducoesCustoPmAcumulam) {
      reducaoAplicada =
          reducoes.fold<int>(0, (soma, r) => soma + max(0, r.valor));
    } else {
      reducaoAplicada = reducoes.map((r) => max(0, r.valor)).reduce(max);
    }

    return max(1, custoBase - reducaoAplicada);
  }

  /// Valida todos os custos de PM, limite variável, componentes materiais, penalidades e sacrifício
  /// sem alterar nenhum estado (Passo 1 do pipeline R37).
  ({bool valido, String? motivo, int custoBase, int custoFinal})
      validarCustosPreAtivacao({
    required Habilidade habilidade,
    required EstadoPersonagemHabilidade personagem,
    int? custoVariavelEscolhido,
    List<ReducaoCusto> reducoesExtras = const [],
  }) {
    final int custoBase;
    if (habilidade.custo.variavel != null) {
      final minCusto = habilidade.custo.variavel!.min;
      final limEfetivo = limiteEfetivoCustoVariavel(habilidade, personagem);
      final escolhido = custoVariavelEscolhido ?? minCusto;
      if (escolhido < minCusto || escolhido > limEfetivo) {
        return (
          valido: false,
          motivo:
              'Custo variável ($escolhido PM) fora da faixa permitida [$minCusto..$limEfetivo PM].',
          custoBase: escolhido,
          custoFinal: escolhido,
        );
      }
      custoBase = escolhido;
    } else {
      custoBase = habilidade.custo.fixo ?? 0;
    }

    final todasReducoes = <ReducaoCusto>[
      ...habilidade.custo.reducoes,
      ...reducoesExtras,
    ];
    final custoFinal = calcularCustoFinalPM(
      custoBase: custoBase,
      reducoes: todasReducoes,
    );

    // R27: Validar PM atual >= custo final antes de ativar
    if (personagem.pmState.pmAtual < custoFinal) {
      return (
        valido: false,
        motivo:
            'PM insuficiente (${personagem.pmState.pmAtual} PM atual < $custoFinal PM exigido).',
        custoBase: custoBase,
        custoFinal: custoFinal,
      );
    }

    // R28: Validar sacrifício de PM (reduz pmMaxBase permanentemente)
    final sacrificio = habilidade.custo.sacrificioPM;
    if (sacrificio > 0 && personagem.pmState.pmMaxBase < sacrificio) {
      return (
        valido: false,
        motivo:
            'PM máximo base (${personagem.pmState.pmMaxBase}) insuficiente para sacrifício de $sacrificio PM.',
        custoBase: custoBase,
        custoFinal: custoFinal,
      );
    }

    // R28: Validar penalidade de PM (bloquear se pmMaxEfetivo ficaria < 0)
    final penalidade = habilidade.custo.penalidadePM;
    final novoPmMaxEfetivo =
        personagem.pmState.pmMaxEfetivo - sacrificio - penalidade;
    if (novoPmMaxEfetivo < 0) {
      return (
        valido: false,
        motivo:
            'Penalidade/sacrifício deixaria o PM máximo efetivo negativo ($novoPmMaxEfetivo).',
        custoBase: custoBase,
        custoFinal: custoFinal,
      );
    }

    // R28 (Caso de Borda 20): Validar componentes materiais em mãos (`emMaos == true`)
    for (final matReq in habilidade.custo.material) {
      final normReq = matReq.trim().toLowerCase();
      final temEmMaos = personagem.inventario.any(
        (item) =>
            item.emMaos &&
            item.quantidade > 0 &&
            (item.id.trim().toLowerCase() == normReq ||
                item.nome.trim().toLowerCase() == normReq),
      );
      if (!temEmMaos) {
        return (
          valido: false,
          motivo:
              'Componente material "$matReq" não está nas mãos do personagem.',
          custoBase: custoBase,
          custoFinal: custoFinal,
        );
      }
    }

    return (
      valido: true,
      motivo: null,
      custoBase: custoBase,
      custoFinal: custoFinal,
    );
  }

  /// R25 e R28: Aplica o gasto de PM, consome os componentes materiais das mãos,
  /// aplica o sacrifício de PM em `pmMaxBase` e vincula eventual `penalidadePM` ao `efeitoId`
  /// (apenas quando `vincularPenalidadeAoEfeito == true` e `efeitoId != null`).
  EstadoPersonagemHabilidade gastarCustos({
    required EstadoPersonagemHabilidade personagem,
    required Habilidade habilidade,
    required int custoFinalPM,
    String? efeitoIdParaPenalidade,
    bool vincularPenalidadeAoEfeito = true,
  }) {
    final novoPmMaxBase =
        personagem.pmState.pmMaxBase - habilidade.custo.sacrificioPM;
    final novasPenalidades = List<PenalidadePMAtiva>.from(
      personagem.pmState.penalidadesAtivas,
    );

    if (vincularPenalidadeAoEfeito &&
        habilidade.custo.penalidadePM > 0 &&
        efeitoIdParaPenalidade != null) {
      novasPenalidades.add(
        PenalidadePMAtiva(
          efeitoId: efeitoIdParaPenalidade,
          valor: habilidade.custo.penalidadePM,
        ),
      );
    }

    final totalPenalidades =
        novasPenalidades.fold<int>(0, (s, p) => s + p.valor);
    final novoPmMaxEfetivo = novoPmMaxBase - totalPenalidades;

    // Debita o custo final e limita pmAtual ao novo pmMaxEfetivo (R28 / Caso de Borda 6)
    final pmAposGasto = max(0, personagem.pmState.pmAtual - custoFinalPM);
    final novoPmAtual = min(pmAposGasto, novoPmMaxEfetivo);

    // Consome componentes materiais das mãos (R28: consumidos mesmo na falha)
    final novoInventario = List<ItemComponenteInventario>.from(
      personagem.inventario,
    );
    for (final matReq in habilidade.custo.material) {
      final normReq = matReq.trim().toLowerCase();
      final idx = novoInventario.indexWhere(
        (item) =>
            item.emMaos &&
            item.quantidade > 0 &&
            (item.id.trim().toLowerCase() == normReq ||
                item.nome.trim().toLowerCase() == normReq),
      );
      if (idx != -1) {
        final item = novoInventario[idx];
        if (item.quantidade <= 1) {
          novoInventario.removeAt(idx);
        } else {
          novoInventario[idx] = item.copyWith(quantidade: item.quantidade - 1);
        }
      }
    }

    return personagem.copyWith(
      pmState: PMState(
        pmMaxBase: novoPmMaxBase,
        penalidadesAtivas: List.unmodifiable(novasPenalidades),
        pmAtual: novoPmAtual,
      ),
      inventario: List.unmodifiable(novoInventario),
    );
  }

  /// R28 e R46 (Casos de Borda 6 e 31): Libera a penalidade de PM vinculada a `efeitoId`.
  /// O `pmMaxEfetivo` volta ao normal, mas o `pmAtual` NÃO sobe sozinho!
  PMState liberarPenalidadePM(PMState state, String efeitoId) {
    final filtradas = state.penalidadesAtivas
        .where((p) => p.efeitoId != efeitoId)
        .toList();
    return state.copyWith(
      penalidadesAtivas: List.unmodifiable(filtradas),
    );
  }

  /// R28 (Caso de Borda 7): Apenas o mestre pode restaurar PM sacrificado permanentemente.
  (PMState, String) restaurarPmSacrificadoPeloMestre({
    required PMState state,
    required int quantidade,
    required String personagemId,
  }) {
    if (quantidade <= 0) {
      throw const RegraTesteException(
        codigo: 'QUANTIDADE_INVALIDA',
        mensagem: 'A quantidade de PM a restaurar deve ser maior que zero.',
      );
    }
    final novoEstado = state.copyWith(
      pmMaxBase: state.pmMaxBase + quantidade,
    );
    final log =
        '[MESTRE] Restaurou $quantidade PM sacrificado(s) de $personagemId (pmMaxBase: ${state.pmMaxBase} -> ${novoEstado.pmMaxBase}).';
    return (novoEstado, log);
  }
}
