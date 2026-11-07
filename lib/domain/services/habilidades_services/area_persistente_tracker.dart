import 'package:t20_creator/domain/entities/combate/grid_tatico.dart';
import 'package:t20_creator/domain/entities/habilidades/modelos_habilidade_duracao.dart';
import 'package:t20_creator/domain/entities/testes/modelos_teste_t20.dart';
import 'package:t20_creator/domain/services/habilidades_services/geometria_grid.dart';

/// Resultado de uma reavaliação de [AreaPersistente] no mapa (R44).
class ResultadoReavaliacaoArea {
  final AreaPersistente areaAtualizada;
  final EfeitoAtivo efeitoAtualizado;
  final List<String> alvosQueEntraram;
  final List<String> alvosQueSairam;
  final List<Map<String, dynamic>> eventosGerados;

  const ResultadoReavaliacaoArea({
    required this.areaAtualizada,
    required this.efeitoAtualizado,
    required this.alvosQueEntraram,
    required this.alvosQueSairam,
    required this.eventosGerados,
  });
}

/// R44 (Caso de Borda 29): Rastreador de pertinência de criaturas/objetos em áreas persistentes.
class AreaPersistenteTracker {
  final GeometriaGrid _geometria;

  const AreaPersistenteTracker({
    required GeometriaGrid geometria,
  }) : _geometria = geometria;

  /// Reavalia quais alvos válidos estão dentro da área persistente quando tokens se movem,
  /// são criados/removidos, barreiras mudam ou a área é redirecionada.
  ResultadoReavaliacaoArea reavaliarArea({
    required AreaPersistente areaPersistente,
    required EfeitoAtivo efeito,
    required List<ModificadorAplicado> modificadoresMoldeHabilidade,
    required Posicao2D posicaoUsuario,
    required List<AlvoMapa> alvosNoMapa,
    List<Barreira> barreiras = const [],
  }) {
    if (!efeito.estaEmJogo || efeito.estado == EstadoEfeito.dormente) {
      return ResultadoReavaliacaoArea(
        areaAtualizada: areaPersistente.copyWith(alvosDentro: const {}),
        efeitoAtualizado: efeito.copyWith(alvos: const [], modificadores: const []),
        alvosQueEntraram: const [],
        alvosQueSairam: areaPersistente.alvosDentro.toList(),
        eventosGerados: [
          for (final id in areaPersistente.alvosDentro)
            {
              'tipo': 'AlvoSaiuDaArea',
              'areaId': areaPersistente.id,
              'efeitoId': efeito.id,
              'alvoId': id,
            },
        ],
      );
    }

    final preview = _geometria.calcularPreviewArea(
      posicaoUsuario: posicaoUsuario,
      usuarioId: areaPersistente.usuarioId,
      alcanceHabilidade: areaPersistente.alcanceHabilidade,
      alvosPermitidos: areaPersistente.alvosPermitidos,
      area: areaPersistente.area,
      alvosNoMapa: alvosNoMapa,
      barreiras: barreiras,
    );

    final novosDentro = preview.alvosAfetadosIds.toSet();
    final antigosDentro = areaPersistente.alvosDentro;

    final entraram = novosDentro.difference(antigosDentro).toList();
    final sairam = antigosDentro.difference(novosDentro).toList();

    final eventos = <Map<String, dynamic>>[
      for (final id in entraram)
        {
          'tipo': 'AlvoEntrouNaArea',
          'areaId': areaPersistente.id,
          'efeitoId': efeito.id,
          'alvoId': id,
        },
      for (final id in sairam)
        {
          'tipo': 'AlvoSaiuDaArea',
          'areaId': areaPersistente.id,
          'efeitoId': efeito.id,
          'alvoId': id,
        },
    ];

    // Recalcula modificadores ativos apenas para os alvos que estão dentro da área agora
    final novosMods = <ModificadorAplicado>[];
    for (final alvoId in novosDentro) {
      for (final molde in modificadoresMoldeHabilidade) {
        novosMods.add(
          molde.copyWith(
            efeitoId: efeito.id,
            alvoId: alvoId,
            aplicado: true,
          ),
        );
      }
    }

    final areaAtualizada = areaPersistente.copyWith(
      alvosDentro: Set.unmodifiable(novosDentro),
    );
    final efeitoAtualizado = efeito.copyWith(
      alvos: List.unmodifiable(novosDentro),
      modificadores: List.unmodifiable(novosMods),
    );

    return ResultadoReavaliacaoArea(
      areaAtualizada: areaAtualizada,
      efeitoAtualizado: efeitoAtualizado,
      alvosQueEntraram: List.unmodifiable(entraram),
      alvosQueSairam: List.unmodifiable(sairam),
      eventosGerados: List.unmodifiable(eventos),
    );
  }
}
