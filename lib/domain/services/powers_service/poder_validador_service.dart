import '../../entities/personagem/personagem.dart';
import '../../entities/personagem/classe_do_personagem.dart';
import '../../entities/personagem/poder.dart';
import '../data_services/call_poderes.dart';
import '../data_services/call_pericias.dart';
import '../motor_modificadores_service.dart';
import 'aprendizado_magia_service.dart';

class ItemRequisito {
  final String descricao;
  final bool atendido;

  const ItemRequisito({required this.descricao, required this.atendido});
}

class ResultadoElegibilidade {
  final bool ehElegivel;
  final bool jaPossui;
  final List<ItemRequisito> requisitos;

  const ResultadoElegibilidade({
    required this.ehElegivel,
    required this.jaPossui,
    required this.requisitos,
  });

  /// Retorna lista apenas com os requisitos não atendidos
  List<ItemRequisito> get pendencias =>
      requisitos.where((r) => !r.atendido).toList();
}

class PoderValidadorService {
  /// Valida se um personagem em uma classe específica é elegível para aprender um poder
  /// (seja poder de classe ou poder geral/Tormenta).
  static ResultadoElegibilidade validar({
    required Personagem personagem,
    required ClasseDoPersonagem classeDoPersonagem,
    required Poder poder,
  }) {
    final permiteMultiplas =
        poder.regrasCustomizacao?.permiteMultiplasInstancias == true ||
        poder.key.toUpperCase() == 'AUMENTO_DE_ATRIBUTO';

    // 1. Checa se o personagem já possui este poder (em qualquer classe, geral ou Deformidade)
    final bool jaPossui =
        !permiteMultiplas &&
        (classeDoPersonagem.poderesEscolhidos.any(
              (p) => p.key.toLowerCase() == poder.key.toLowerCase(),
            ) ||
            MotorModificadoresService.possuiPoder(personagem, poder.key));

    final List<ItemRequisito> requisitos = [];

    final bool ehPoderGeralOuTormenta =
        poder.ehPoderTormenta ||
        poder.tipo?.toLowerCase() == 'poder_geral' ||
        (poder.categoria != null &&
            poder.categoria!.toLowerCase().startsWith('poder_'));

    // RV07: Se o poder pertence exclusivamente a determinadas classes no catálogo,
    // impede que seja liberado utilizando o nível ou o slot de outra classe!
    if (!ehPoderGeralOuTormenta) {
      final classesDonas = BancoDePoderes.obterClassesDonasDoPoder(poder.key);
      final idClasseAtualUpper =
          classeDoPersonagem.classeDefinicao.idClasse.toUpperCase();
      if (classesDonas.isNotEmpty &&
          !classesDonas.contains(idClasseAtualUpper)) {
        requisitos.add(
          ItemRequisito(
            descricao: 'Exclusivo de ${classesDonas.join(" / ")}',
            atendido: false,
          ),
        );
      }
    }

    // 2. Validação de Nível Mínimo (Nível de Personagem para Poderes Gerais;
    //    Nível Individual na Classe para Poderes de Classe — RF05 / RN08 / RV07)
    if (poder.nivelMinimo > 1) {
      if (ehPoderGeralOuTormenta) {
        final nivPers = personagem.nivelPersonagem > 0
            ? personagem.nivelPersonagem
            : classeDoPersonagem.nivel;
        final bool atendeNivel = nivPers >= poder.nivelMinimo;
        requisitos.add(
          ItemRequisito(
            descricao: '${poder.nivelMinimo}º nível de personagem',
            atendido: atendeNivel,
          ),
        );
      } else {
        final bool atendeNivel = classeDoPersonagem.nivel >= poder.nivelMinimo;
        final nomeClasse = classeDoPersonagem.classeDefinicao.nome;
        requisitos.add(
          ItemRequisito(
            descricao: '${poder.nivelMinimo}º nível de $nomeClasse',
            atendido: atendeNivel,
          ),
        );
      }
    }

    // 3. Validação de Caminho / Especialização (ex: Mago, Bruxo, Feiticeiro)
    if (poder.caminhosExigidos.isNotEmpty) {
      final caminhoAtual = classeDoPersonagem.caminhoEscolhido?.nome;
      final bool atendeCaminho =
          caminhoAtual != null &&
          poder.caminhosExigidos.any(
            (c) => c.trim().toLowerCase() == caminhoAtual.trim().toLowerCase(),
          );

      requisitos.add(
        ItemRequisito(
          descricao: 'Caminho: ${poder.caminhosExigidos.join(" ou ")}',
          atendido: atendeCaminho,
        ),
      );
    }

    // 4. Validação de Atributos Exigidos (ex: FOR 13 -> Mod +1, DES 15 -> Mod +2)
    poder.atributosExigidos.forEach((sigla, valorExigido) {
      final int modNecessario = valorExigido >= 10
          ? ((valorExigido - 10) ~/ 2)
          : valorExigido;

      final int modAtual = personagem.getValorFinal(sigla.toUpperCase());
      final bool atendeAtributo = modAtual >= modNecessario;

      requisitos.add(
        ItemRequisito(
          descricao: '${sigla.toUpperCase()} +$modNecessario',
          atendido: atendeAtributo,
        ),
      );
    });

    // 4b. Validação de Atributos Máximos (ex: Repulsivo exige CAR -1 ou menor)
    poder.atributosMaximos.forEach((sigla, valorMaximo) {
      final int modAtual = personagem.getValorFinal(sigla.toUpperCase());
      final bool atendeMax = modAtual <= valorMaximo;
      requisitos.add(
        ItemRequisito(
          descricao: '${sigla.toUpperCase()} $valorMaximo ou menor',
          atendido: atendeMax,
        ),
      );
    });

    // 4c. Validação de Quantidade Mínima de Outros Poderes da Tormenta
    if (poder.poderesTormentaMinimos > 0) {
      final int totalTormenta = personagem.totalPoderesTormenta;
      final bool atendeTormenta = totalTormenta >= poder.poderesTormentaMinimos;
      final String descTormenta = poder.poderesTormentaMinimos == 1
          ? 'Outro poder da Tormenta ($totalTormenta/1)'
          : '${poder.poderesTormentaMinimos} outros poderes da Tormenta ($totalTormenta/${poder.poderesTormentaMinimos})';
      requisitos.add(
        ItemRequisito(descricao: descTormenta, atendido: atendeTormenta),
      );
    }

    // 4d. Validação de Círculo Mágico Mínimo
    if (poder.circuloMagicoMinimo != null && poder.circuloMagicoMinimo! > 0) {
      final int circMax = AprendizadoMagiaService.obterCirculoMaximoPersonagem(
        personagem,
      );
      final bool atendeCirculo = circMax >= poder.circuloMagicoMinimo!;
      requisitos.add(
        ItemRequisito(
          descricao: 'Lançar magias de ${poder.circuloMagicoMinimo}º círculo',
          atendido: atendeCirculo,
        ),
      );
    }

    // 5. Validação de Perícias Exigidas
    for (final periciaExigida in poder.periciasExigidas) {
      final bool atendePericia = _checarPericiaTreinada(
        personagem: personagem,
        periciaExigida: periciaExigida,
      );

      final labelExibicao = _obterLabelPericia(periciaExigida);
      requisitos.add(
        ItemRequisito(
          descricao: 'Treinado em $labelExibicao',
          atendido: atendePericia,
        ),
      );
    }

    // 6. Validação de Poderes Exigidos como Pré-requisito
    for (final poderExigidoKey in poder.poderesExigidos) {
      final bool possuiPoder = _checarPoderPossuido(
        personagem: personagem,
        classeDoPersonagem: classeDoPersonagem,
        poderKeyOrName: poderExigidoKey,
      );

      final nomePoderExigido = _obterNomePoder(poderExigidoKey);
      requisitos.add(
        ItemRequisito(
          descricao: 'Poder: $nomePoderExigido',
          atendido: possuiPoder,
        ),
      );
    }

    // O poder é elegível se não for possuído ainda e cumprir todos os pré-requisitos
    final bool todosAtendidos = requisitos.every((r) => r.atendido);
    final bool ehElegivel = !jaPossui && todosAtendidos;

    return ResultadoElegibilidade(
      ehElegivel: ehElegivel,
      jaPossui: jaPossui,
      requisitos: requisitos,
    );
  }

  static bool _checarPericiaTreinada({
    required Personagem personagem,
    required String periciaExigida,
  }) {
    final exigidaNorm = _normalizarTexto(periciaExigida);
    final listaExplicita = <String>[
      ...personagem.periciasTreinadas,
      ...personagem.classes.expand((c) => c.periciasExclusivasEscolhidas.values),
    ];

    if (listaExplicita.isEmpty) {
      if (personagem.ehPericiaTreinada(periciaExigida)) return true;
      for (final per in BancoDePericias.todas) {
        if (_normalizarTexto(per.key) == exigidaNorm ||
            _normalizarTexto(per.label) == exigidaNorm) {
          if (personagem.ehPericiaTreinada(per.key)) return true;
        }
      }
      return false;
    }

    return listaExplicita.any((treinada) {
      if (treinada.toUpperCase() == periciaExigida.toUpperCase()) return true;
      if (_normalizarTexto(treinada) == exigidaNorm) return true;

      final p = BancoDePericias.getByKey(treinada);
      if (_normalizarTexto(p.label) == exigidaNorm) return true;
      return false;
    });
  }

  static String _obterLabelPericia(String periciaKeyOuLabel) {
    final p = BancoDePericias.getByKey(periciaKeyOuLabel.toUpperCase());
    if (p.key != 'UNKNOWN') {
      return p.label;
    }
    return periciaKeyOuLabel;
  }

  static bool _checarPoderPossuido({
    required Personagem personagem,
    required ClasseDoPersonagem classeDoPersonagem,
    required String poderKeyOrName,
  }) {
    final chaveNorm = _normalizarTexto(poderKeyOrName);

    final todosPoderes = <Poder>[
      ...classeDoPersonagem.poderesEscolhidos,
      ...MotorModificadoresService.obterTodosPoderesAtivos(personagem),
    ];

    for (final p in todosPoderes) {
      if (p.key.toUpperCase() == poderKeyOrName.toUpperCase() ||
          _normalizarTexto(p.key) == chaveNorm ||
          _normalizarTexto(p.nome) == chaveNorm) {
        return true;
      }
    }

    // Também checa habilidades de classe adquiridas na tabela de progressão (ex: Magias, Ataque Especial)
    for (final c in personagem.classes) {
      for (int n = 1; n <= c.nivel; n++) {
        final habs = c.classeDefinicao.tabelaDeProgressao[n] ?? const [];
        for (final h in habs) {
          if (_normalizarTexto(h).contains(chaveNorm)) return true;
        }
      }
    }

    return false;
  }

  static String _obterNomePoder(String poderKeyOrName) {
    final p =
        BancoDePoderes.getByKey(poderKeyOrName) ??
        BancoDePoderesGerais.getByKey(poderKeyOrName);
    if (p != null) return p.nome;
    return poderKeyOrName;
  }

  static String _normalizarTexto(String s) {
    return s
        .trim()
        .toUpperCase()
        .replaceAll('Á', 'A')
        .replaceAll('À', 'A')
        .replaceAll('Ã', 'A')
        .replaceAll('Â', 'A')
        .replaceAll('É', 'E')
        .replaceAll('Ê', 'E')
        .replaceAll('Í', 'I')
        .replaceAll('Ó', 'O')
        .replaceAll('Õ', 'O')
        .replaceAll('Ô', 'O')
        .replaceAll('Ú', 'U')
        .replaceAll('Ç', 'C')
        .replaceAll('_', ' ');
  }
}
