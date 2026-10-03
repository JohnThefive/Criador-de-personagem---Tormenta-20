import '../entities/personagem.dart';
import '../entities/classe_do_personagem.dart';
import '../entities/poder.dart';
import 'data_services/call_poderes.dart';
import 'banco_pericias.dart';

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
  /// Valida se um personagem em uma classe específica é elegível para aprender um poder.
  static ResultadoElegibilidade validar({
    required Personagem personagem,
    required ClasseDoPersonagem classeDoPersonagem,
    required Poder poder,
  }) {
    // 1. Checa se o personagem já possui este poder
    final bool jaPossui = classeDoPersonagem.poderesEscolhidos.any(
      (p) => p.key == poder.key,
    );

    final List<ItemRequisito> requisitos = [];

    // 2. Validação de Nível Mínimo na Classe
    if (poder.nivelMinimo > 1) {
      final bool atendeNivel = classeDoPersonagem.nivel >= poder.nivelMinimo;
      final nomeClasse = classeDoPersonagem.classeDefinicao.nome;
      requisitos.add(
        ItemRequisito(
          descricao: '${poder.nivelMinimo}º nível de $nomeClasse',
          atendido: atendeNivel,
        ),
      );
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
      // Converte valor de atributo no formato clássico (13, 15) para modificador se necessário
      final int modNecessario = valorExigido >= 10
          ? ((valorExigido - 10) ~/ 2)
          : valorExigido;

      final int modAtual = personagem.getValorFinal(sigla.toUpperCase());
      final bool atendeAtributo = modAtual >= modNecessario;

      requisitos.add(
        ItemRequisito(
          descricao:
              '$sigla $modNecessario (${sigla.toUpperCase()} $valorExigido)',
          atendido: atendeAtributo,
        ),
      );
    });

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
    return personagem.periciasTreinadas.any((treinada) {
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

    // Checa poderes de classe
    final naClasse = classeDoPersonagem.poderesEscolhidos.any(
      (p) =>
          p.key.toUpperCase() == poderKeyOrName.toUpperCase() ||
          _normalizarTexto(p.key) == chaveNorm ||
          _normalizarTexto(p.nome) == chaveNorm,
    );
    if (naClasse) return true;

    // Checa poderes gerais
    final nosGerais = personagem.poderesGerais.any(
      (p) =>
          p.key.toUpperCase() == poderKeyOrName.toUpperCase() ||
          _normalizarTexto(p.key) == chaveNorm ||
          _normalizarTexto(p.nome) == chaveNorm,
    );
    if (nosGerais) return true;

    // Checa poder concedido
    if (personagem.poderConcedido != null) {
      final pc = personagem.poderConcedido!;
      if (pc.key.toUpperCase() == poderKeyOrName.toUpperCase() ||
          _normalizarTexto(pc.key) == chaveNorm ||
          _normalizarTexto(pc.nome) == chaveNorm) {
        return true;
      }
    }

    return false;
  }

  static String _obterNomePoder(String poderKeyOrName) {
    final p = BancoDePoderes.getByKey(poderKeyOrName);
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
