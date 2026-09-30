import '../entities/personagem.dart';
import '../entities/arma.dart';
import 'banco_armas.dart';

class OpcoesArmasIniciais {
  final bool podeEscolherSimples;
  final bool podeEscolherMarcial;
  final List<Arma> armasSimples;
  final List<Arma> armasMarciais;

  const OpcoesArmasIniciais({
    required this.podeEscolherSimples,
    required this.podeEscolherMarcial,
    required this.armasSimples,
    required this.armasMarciais,
  });

  int get totalArmasPermitidas =>
      (podeEscolherSimples ? 1 : 0) + (podeEscolherMarcial ? 1 : 0);
}

class StatusCarga {
  final int cargaAtual;
  final int limiteCarga;
  final bool sobrecarregado;
  final int espacosRestantes;

  const StatusCarga({
    required this.cargaAtual,
    required this.limiteCarga,
    required this.sobrecarregado,
    required this.espacosRestantes,
  });
}

class RegrasCargaService {
  /// Calcula o limite de espaços de carga do personagem no Tormenta 20:
  /// Limite = 10 + (2 * modForca). Se modForca for negativo, subtrai 2 por ponto.
  static int calcularLimiteCarga(int modForca) {
    return 10 + (2 * modForca);
  }

  /// Calcula o total de espaços ocupados pelo inventário do personagem
  static int calcularEspacosOcupados({
    required List<Arma> armas,
    required List<String> itensInventario,
  }) {
    // Espaço ocupado pelas armas
    int espacosArmas = armas.fold(0, (soma, a) => soma + a.espacos);

    // Espaço ocupado pelos demais itens
    int espacosItens = 0;
    for (final item in itensInventario) {
      espacosItens += _obterEspacoItem(item);
    }

    return espacosArmas + espacosItens;
  }

  /// Determina o espaço ocupado por itens gerais (padrão T20)
  static int _obterEspacoItem(String nomeItem) {
    final nomeLower = nomeItem.toLowerCase().trim();

    // Itens que não ocupam espaço (vestindo, moeda ou mochilas)
    if (nomeLower.contains('mochila') ||
        nomeLower.contains('traje de viajante') ||
        nomeLower.contains('vestid') ||
        nomeLower.contains('tibar')) {
      return 0;
    }

    // Itens volumosos conhecidos
    if (nomeLower.contains('saco de dormir') ||
        nomeLower.contains('tenda') ||
        nomeLower.contains('corda')) {
      return 1;
    }

    // Padrão geral: 1 espaço por item comum
    return 1;
  }

  /// Verifica o status detalhado de carga do personagem
  static StatusCarga avaliarCarga(Personagem personagem) {
    final modForca = personagem.getValorFinal('FOR');
    final limite = calcularLimiteCarga(modForca);
    final atual = calcularEspacosOcupados(
      armas: personagem.armas,
      itensInventario: personagem.itensInventario,
    );

    return StatusCarga(
      cargaAtual: atual,
      limiteCarga: limite,
      sobrecarregado: atual > limite,
      espacosRestantes: limite - atual,
    );
  }

  /// Retorna as armas iniciais elegíveis para o personagem no Nível 1:
  /// - 1 arma Simples para qualquer classe.
  /// - Se tiver proficiência em armas marciais, também escolhe 1 arma Marcial.
  static OpcoesArmasIniciais obterArmasIniciaisDisponiveis(Personagem personagem) {
    final bool temMarcial = personagem.temProficienciaMarcial;

    return OpcoesArmasIniciais(
      podeEscolherSimples: true,
      podeEscolherMarcial: temMarcial,
      armasSimples: BancoDeArmas.armasSimples(),
      armasMarciais: temMarcial ? BancoDeArmas.armasMarciais() : const [],
    );
  }
}
