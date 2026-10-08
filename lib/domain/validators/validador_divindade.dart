import '../entities/personagem.dart';
import '../entities/divindade.dart';
import '../entities/poder.dart';
import '../services/poder_validador_service.dart';

/// Resultado detalhado da validação de elegibilidade de devoção
class ResultadoElegibilidadeDevocao {
  final bool ehElegivel;
  final String? motivoIneligibilidade;
  final bool ehDevotoFiel;
  final bool exigeDevocao;

  const ResultadoElegibilidadeDevocao({
    required this.ehElegivel,
    this.motivoIneligibilidade,
    required this.ehDevotoFiel,
    required this.exigeDevocao,
  });
}

/// Validador de regras de domínio para Divindades e Devoções em Tormenta 20.
class ValidadorDivindade {
  /// Lista oficial de IDs de divindades permitidas para Paladinos (T20 JDA)
  static const Set<String> deusesPermitidosPaladino = {
    'arsenal',
    'khalmyr',
    'lena',
    'lin-wu',
    'marah',
    'tanna-toh',
    'thyatis',
    'valkaria',
  };

  /// Lista oficial de IDs de divindades permitidas para Druidas (T20 JDA)
  static const Set<String> deusesPermitidosDruida = {
    'aharadak',
    'allihanna',
    'megalokk',
    'oceano',
  };

  /// Identifica se a classe do personagem é considerada um "Devoto Fiel"
  /// (Clérigo, Druida ou Paladino), que pode escolher 2 poderes concedidos ao invés de 1.
  static bool ehDevotoFiel(Personagem personagem) {
    if (personagem.classes.isEmpty) return false;
    final idClasse = _normalizarId(personagem.classes[0].classeDefinicao.idClasse);
    return idClasse == 'clerigo' ||
        idClasse == 'clerigo' ||
        idClasse == 'druida' ||
        idClasse == 'paladino';
  }

  /// Verifica se a classe do personagem exige devoção obrigatória
  static bool exigeDevocao(Personagem personagem, {bool modoEstrito = true}) {
    if (!modoEstrito) return false;
    return ehDevotoFiel(personagem);
  }

  /// Valida se o personagem pode escolher a divindade especificada
  static ResultadoElegibilidadeDevocao validarElegibilidade({
    required Personagem personagem,
    required Divindade? divindade,
    bool modoEstrito = true,
  }) {
    final devotoFiel = ehDevotoFiel(personagem);
    final precisaDevocao = exigeDevocao(personagem, modoEstrito: modoEstrito);

    // Caso de Não Devoto (divindade nula)
    if (divindade == null) {
      if (precisaDevocao) {
        final nomeClasse = personagem.classes.isNotEmpty
            ? personagem.classes[0].classeDefinicao.nome
            : 'Sua classe';
        return ResultadoElegibilidadeDevocao(
          ehElegivel: false,
          motivoIneligibilidade:
              '$nomeClasse exige a escolha de um deus padroeiro no Panteão.',
          ehDevotoFiel: devotoFiel,
          exigeDevocao: precisaDevocao,
        );
      }
      return ResultadoElegibilidadeDevocao(
        ehElegivel: true,
        ehDevotoFiel: devotoFiel,
        exigeDevocao: precisaDevocao,
      );
    }

    // Se o modo estrito estiver desativado (homebrew livre), permite qualquer deus
    if (!modoEstrito) {
      return ResultadoElegibilidadeDevocao(
        ehElegivel: true,
        ehDevotoFiel: devotoFiel,
        exigeDevocao: precisaDevocao,
      );
    }

    if (personagem.classes.isNotEmpty) {
      final idClasse = _normalizarId(personagem.classes[0].classeDefinicao.idClasse);
      final idDivindade = _normalizarId(divindade.id);

      // Restrição de Paladino
      if (idClasse == 'paladino') {
        if (!deusesPermitidosPaladino.contains(idDivindade)) {
          return ResultadoElegibilidadeDevocao(
            ehElegivel: false,
            motivoIneligibilidade:
                'Paladinos só podem cultuar deuses com tendência compatível: '
                'Arsenal, Khalmyr, Lena, Lin-Wu, Marah, Tanna-Toh, Thyatis ou Valkaria.',
            ehDevotoFiel: devotoFiel,
            exigeDevocao: precisaDevocao,
          );
        }
      }

      // Restrição de Druida
      if (idClasse == 'druida') {
        if (!deusesPermitidosDruida.contains(idDivindade)) {
          return ResultadoElegibilidadeDevocao(
            ehElegivel: false,
            motivoIneligibilidade:
                'Druidas só podem cultuar deuses da natureza ou do caos natural: '
                'Aharadak, Allihanna, Megalokk ou Oceano.',
            ehDevotoFiel: devotoFiel,
            exigeDevocao: precisaDevocao,
          );
        }
      }

      // Restrição específica cadastrada na própria Divindade (Devotos Permitidos)
      if (divindade.classesPermitidas.isNotEmpty) {
        // No livro T20 JDA (p. 100), Clérigos podem ser devotos de qualquer divindade
        if (idClasse != 'clerigo') {
          final idRaca = personagem.raca != null
              ? _normalizarId(personagem.raca!.id)
              : null;

          bool aceita = false;
          for (final permitida in divindade.classesPermitidas) {
            final pNorm = _removerAcentosEPlural(permitida);
            if (pNorm == _removerAcentosEPlural(idClasse)) {
              aceita = true;
              break;
            }
            if (idRaca != null && pNorm == _removerAcentosEPlural(idRaca)) {
              aceita = true;
              break;
            }
          }

          if (!aceita) {
            return ResultadoElegibilidadeDevocao(
              ehElegivel: false,
              motivoIneligibilidade:
                  '${divindade.nome} só aceita como devotos: ${divindade.classesPermitidas.join(", ")}.',
              ehDevotoFiel: devotoFiel,
              exigeDevocao: precisaDevocao,
            );
          }
        }
      }
    }

    return ResultadoElegibilidadeDevocao(
      ehElegivel: true,
      ehDevotoFiel: devotoFiel,
      exigeDevocao: precisaDevocao,
    );
  }

  /// Valida os pré-requisitos de um poder concedido específico para o personagem
  static ResultadoElegibilidade validarPoderConcedido({
    required Personagem personagem,
    required Poder poder,
  }) {
    if (personagem.classes.isEmpty) {
      return ResultadoElegibilidade(
        ehElegivel: true,
        jaPossui: false,
        requisitos: const [],
      );
    }

    return PoderValidadorService.validar(
      personagem: personagem,
      classeDoPersonagem: personagem.classes[0],
      poder: poder,
    );
  }

  static String _normalizarId(String text) {
    return text.trim().toLowerCase().replaceAll('_', '-');
  }

  static String _removerAcentosEPlural(String text) {
    var s = text.trim().toLowerCase().replaceAll('_', '-');
    s = s
        .replaceAll('ã', 'a')
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c');

    if (s == 'anoes') return 'anao';
    if (s == 'golens') return 'golem';
    if (s == 'inventores') return 'inventor';
    if (s == 'cacadores') return 'cacador';

    if (s != 'aggelus' && s.endsWith('s')) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }
}
