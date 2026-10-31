import '../entities/personagem/personagem.dart';
import '../entities/equipamento/arma.dart';
import '../entities/equipamento/protecao.dart';
import '../entities/equipamento/item_vestido.dart';
import '../entities/habilidades_complexas/engenhoca.dart';
import 'data_services/call_armas.dart';
import 'data_services/call_armaduras.dart';

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

class OpcoesProtecoesIniciais {
  final bool podeEscolherArmadura;
  final bool podeEscolherEscudo;
  final List<Protecao> armadurasIniciais;
  final List<Protecao> escudosIniciais;

  const OpcoesProtecoesIniciais({
    required this.podeEscolherArmadura,
    required this.podeEscolherEscudo,
    required this.armadurasIniciais,
    required this.escudosIniciais,
  });
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

  /// Capacidade máxima antes de ficar impedido de se mover (2x o limite normal no T20)
  int get cargaMaximaAbsoluta => limiteCarga * 2;
}

class RegrasCargaService {
  /// Calcula o limite de espaços de carga do personagem no Tormenta 20:
  /// Limite = 10 + (2 * modForca). Se modForca for negativo, subtrai 2 por ponto (mínimo 1).
  static int calcularLimiteCarga(int modForca) {
    final calc = 10 + (2 * modForca);
    return calc < 1 ? 1 : calc;
  }

  /// Calcula o total de espaços ocupados pelo inventário do personagem,
  /// incluindo armas, armadura, escudo, itens vestidos extras, engenhocas e mochila.
  static int calcularEspacosOcupados({
    required List<Arma> armas,
    required List<String> itensInventario,
    Protecao? armadura,
    Protecao? escudo,
    List<Engenhoca> engenhocas = const [],
    List<ItemVestido> itensVestidosExtras = const [],
  }) {
    // Espaço ocupado pelas armas (considerando Mitral)
    int espacosArmas = armas.fold(0, (soma, a) => soma + a.espacosEfetivos);

    // Espaço ocupado por armaduras e escudos (considerando Mitral)
    int espacosProtecoes =
        (armadura?.espacosEfetivos ?? 0) + (escudo?.espacosEfetivos ?? 0);

    // Espaço ocupado pelos slots extras de itens vestidos (Slots 2, 3 e 4)
    int espacosVestidosExtras = itensVestidosExtras.fold(
      0,
      (soma, item) => soma + item.espacos,
    );

    // Espaço ocupado pelos demais itens da mochila
    int espacosItens = 0;
    for (final item in itensInventario) {
      espacosItens += obterEspacoItem(item);
    }

    // Espaço ocupado pelas engenhocas (fracionários arredondados para cima no total)
    final num somaEngenhocas = engenhocas.fold<num>(
      0,
      (soma, e) => soma + e.espacosOcupados,
    );
    final int espacosEngenhocas = somaEngenhocas.ceil();

    return espacosArmas +
        espacosProtecoes +
        espacosVestidosExtras +
        espacosItens +
        espacosEngenhocas;
  }

  static final _regexEspacoExplicito = RegExp(r'\((\d+)\s*esp');

  /// Determina o espaço ocupado por itens gerais (padrão T20)
  static int obterEspacoItem(String nomeItem) {
    final nomeLower = nomeItem.toLowerCase().trim();

    // Suporte a sufixo explícito ex: "Corda (2 esp)" ou "(0 esp)"
    final matchExplicito = _regexEspacoExplicito.firstMatch(nomeLower);
    if (matchExplicito != null) {
      return int.tryParse(matchExplicito.group(1)!) ?? 1;
    }

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
    final limite = personagem.limiteCarga;
    final atual = calcularEspacosOcupados(
      armas: personagem.armas,
      itensInventario: personagem.itensInventario,
      armadura: personagem.armaduraEquipada,
      escudo: personagem.escudoEquipado,
      engenhocas: personagem.engenhocas,
      itensVestidosExtras: personagem.itensVestidosExtras,
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
  static OpcoesArmasIniciais obterArmasIniciaisDisponiveis(
    Personagem personagem,
  ) {
    final bool temMarcial = personagem.temProficienciaMarcial;

    return OpcoesArmasIniciais(
      podeEscolherSimples: true,
      podeEscolherMarcial: temMarcial,
      armasSimples: BancoDeArmas.armasSimples(),
      armasMarciais: temMarcial ? BancoDeArmas.armasMarciais() : const [],
    );
  }

  /// Retorna as armaduras e escudos iniciais elegíveis no Nível 1 (T20):
  /// - Exceção: Arcanistas começam sem armadura inicial.
  /// - Outras classes: Armadura de Couro, Couro Batido ou Gibão de Peles (gratuitas).
  /// - Se tiver proficiência com armaduras pesadas: pode substituir por uma Brunea sem custo.
  /// - Se tiver proficiência com escudos: recebe adicionalmente um Escudo Leve sem custo.
  static OpcoesProtecoesIniciais obterProtecoesIniciaisDisponiveis(
    Personagem personagem,
  ) {
    final bool arcanista = personagem.ehArcanista;

    final List<Protecao> armaduras = [];
    if (!arcanista) {
      // Opções base de armaduras leves
      final couro = BancoDeArmaduras.getByKey('ARMADURA_COURO');
      final couroBatido = BancoDeArmaduras.getByKey('COURO_BATIDO');
      final gibao = BancoDeArmaduras.getByKey('GIBAO_DE_PELES');
      if (couro != null) armaduras.add(couro);
      if (couroBatido != null) armaduras.add(couroBatido);
      if (gibao != null) armaduras.add(gibao);

      // Se proficiente em armaduras pesadas, adiciona a Brunea
      if (personagem.temProficienciaArmadurasPesadas) {
        final brunea = BancoDeArmaduras.getByKey('BRUNEA');
        if (brunea != null) armaduras.add(brunea);
      }
    }

    // Escudos: se proficiente, recebe Escudo Leve
    final bool temEscudo = personagem.temProficienciaEscudos;
    final List<Protecao> escudos = [];
    if (temEscudo) {
      final escudoLeve = BancoDeArmaduras.getByKey('ESCUDO_LEVE');
      if (escudoLeve != null) escudos.add(escudoLeve);
    }

    return OpcoesProtecoesIniciais(
      podeEscolherArmadura: !arcanista,
      podeEscolherEscudo: temEscudo,
      armadurasIniciais: armaduras,
      escudosIniciais: escudos,
    );
  }
}
