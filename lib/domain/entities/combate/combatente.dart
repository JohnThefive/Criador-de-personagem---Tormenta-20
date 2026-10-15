import 'dart:math';
import '../equipamento/arma.dart';
import '../personagem/personagem.dart';
import 'estado_vida_combatente.dart';
import 'monstro.dart';

enum CondicaoCombatente { surpreendido, caido, indefeso }

enum TimeCombatente { heroi, inimigo }

/// Abstração polimórfica para combatentes no T20 (Jogadores, Monstros/Ameaças e NPCs)
sealed class Combatente {
  String get id;
  String get nome;
  TimeCombatente get time;
  EstadoVidaCombatente get estadoVida;
  int get pvMax;
  int get pvAtual;
  int get danoNaoLetal;
  int get pmMax;
  int get pmAtual;
  int get defesa;
  int get iniciativaValor;
  double get deslocamentoMetros;
  int get modIniciativa;
  int get modLuta;
  int get modPontaria;
  int get modPercepcao;
  int get modForca;
  int get modDestreza;
  int get modConstituicao;
  List<Arma> get armas;
  List<CondicaoCombatente> get condicoesAtivas;

  const Combatente._();

  /// Construtor concreto padrão para manter compatibilidade com testes e instâncias manuais
  const factory Combatente({
    required String id,
    required String nome,
    TimeCombatente time,
    EstadoVidaCombatente estadoVida,
    required int pvMax,
    required int pvAtual,
    int danoNaoLetal,
    required int pmMax,
    required int pmAtual,
    required int defesa,
    int iniciativaValor,
    double deslocamentoMetros,
    required int modIniciativa,
    required int modLuta,
    required int modPontaria,
    required int modPercepcao,
    required int modForca,
    required int modDestreza,
    required int modConstituicao,
    List<Arma> armas,
    List<CondicaoCombatente> condicoesAtivas,
  }) = CombatenteGenerico;

  /// Constrói um CombatenteJogador a partir da ficha do Personagem
  factory Combatente.doPersonagem(Personagem p) = CombatenteJogador.doPersonagem;

  /// Constrói um CombatenteMonstro a partir da ficha do Monstro
  factory Combatente.doMonstro(
    Monstro monstro, {
    String? idInstancia,
    TimeCombatente time,
    int? pvAtual,
    int? pmAtual,
  }) = CombatenteMonstro.doMonstro;

  /// Limite de morte no T20: PV <= min(-10, -(pvMaximo / 2))
  int get limiteMorte => min(-10, -(pvMax / 2).floor());

  bool get estaInconsciente => estadoVida.estaInconsciente || pvAtual <= 0;
  bool get estaMorto => estadoVida == EstadoVidaCombatente.morto;
  bool get estaIncapacitado => estaInconsciente || estaMorto;
  bool get podeAgir => estadoVida == EstadoVidaCombatente.ativo && pvAtual > 0;
  bool get ehSurpreendido =>
      condicoesAtivas.contains(CondicaoCombatente.surpreendido);
  bool get estaCaido => condicoesAtivas.contains(CondicaoCombatente.caido);

  Combatente copyWith({
    TimeCombatente? time,
    EstadoVidaCombatente? estadoVida,
    int? pvAtual,
    int? danoNaoLetal,
    int? pmAtual,
    int? iniciativaValor,
    double? deslocamentoMetros,
    List<CondicaoCombatente>? condicoesAtivas,
  });

  /// Aplica dano letal ou não letal conforme regras do T20
  Combatente aplicarDano(int valor, {bool naoLetal = false}) {
    if (valor <= 0) return this;

    if (naoLetal) {
      final novoDanoNaoLetal = danoNaoLetal + valor;
      // Dano não-letal faz desmaiar quando soma >= PV atual, mas não sangra
      final novoEstado =
          (novoDanoNaoLetal >= pvAtual &&
              estadoVida == EstadoVidaCombatente.ativo)
          ? EstadoVidaCombatente.estabilizado
          : estadoVida;

      return copyWith(danoNaoLetal: novoDanoNaoLetal, estadoVida: novoEstado);
    }

    // Dano Letal
    final novoPv = pvAtual - valor;
    EstadoVidaCombatente novoEstado = estadoVida;

    if (novoPv <= limiteMorte) {
      novoEstado = EstadoVidaCombatente.morto;
    } else if (novoPv <= 0) {
      // Se já estava estabilizado e tomou dano letal novo, volta a sangrar
      novoEstado = EstadoVidaCombatente.inconscienteSangrando;
    }

    return copyWith(pvAtual: novoPv, estadoVida: novoEstado);
  }

  /// Aplica cura: se PV voltar a ser > 0, acorda e volta a ficar ativo
  Combatente aplicarCura(int valor) {
    if (valor <= 0) return this;
    if (estadoVida == EstadoVidaCombatente.morto) return this;

    final novoPv = min(pvMax, pvAtual + valor);
    EstadoVidaCombatente novoEstado = estadoVida;

    if (novoPv > 0) {
      novoEstado = EstadoVidaCombatente.ativo;
    } else {
      // Qualquer cura estabiliza o personagem
      novoEstado = EstadoVidaCombatente.estabilizado;
    }

    return copyWith(pvAtual: novoPv, estadoVida: novoEstado);
  }

  /// Realiza o teste de Constituição (CD 15) no início do turno se estiver sangrando
  (Combatente, String) testeEstabilizacaoCon(
    int dadoD20,
    int danoSangramentoD6,
  ) {
    if (estadoVida != EstadoVidaCombatente.inconscienteSangrando) {
      return (this, "");
    }

    final totalCon = dadoD20 + modConstituicao;
    if (totalCon >= 15) {
      final estavel = copyWith(estadoVida: EstadoVidaCombatente.estabilizado);
      return (
        estavel,
        "🩺 $nome passou no Teste de Constituição (d20: $dadoD20 + $modConstituicao = $totalCon >= 15) e ESTABILIZOU!",
      );
    } else {
      final aposDano = aplicarDano(danoSangramentoD6, naoLetal: false);
      if (aposDano.estadoVida == EstadoVidaCombatente.morto) {
        return (
          aposDano,
          "💀 $nome falhou no Teste de Constituição ($totalCon < 15), sofreu $danoSangramentoD6 de sangramento e MORREU!",
        );
      }
      return (
        aposDano,
        "🩸 $nome falhou no Teste de Constituição ($totalCon < 15) e sofreu $danoSangramentoD6 de sangramento (PV: ${aposDano.pvAtual}/$pvMax).",
      );
    }
  }
}

/// Implementação para Personagens de Jogadores (acoplada à ficha do Personagem)
class CombatenteJogador extends Combatente {
  final Personagem ficha;
  @override
  final TimeCombatente time;
  @override
  final EstadoVidaCombatente estadoVida;
  @override
  final int pvAtual;
  @override
  final int danoNaoLetal;
  @override
  final int pmAtual;
  @override
  final int iniciativaValor;
  @override
  final double deslocamentoMetros;
  @override
  final List<CondicaoCombatente> condicoesAtivas;

  const CombatenteJogador({
    required this.ficha,
    this.time = TimeCombatente.heroi,
    this.estadoVida = EstadoVidaCombatente.ativo,
    required this.pvAtual,
    this.danoNaoLetal = 0,
    required this.pmAtual,
    this.iniciativaValor = 0,
    this.deslocamentoMetros = 9.0,
    this.condicoesAtivas = const [],
  }) : super._();

  factory CombatenteJogador.doPersonagem(Personagem p) {
    final double deslocamento = p.estaSobrecarregado ? 6.0 : 9.0;
    return CombatenteJogador(
      ficha: p,
      time: TimeCombatente.heroi,
      estadoVida: p.pvAtual <= 0
          ? EstadoVidaCombatente.inconscienteSangrando
          : EstadoVidaCombatente.ativo,
      pvAtual: p.pvAtual,
      pmAtual: p.pmAtual,
      deslocamentoMetros: deslocamento,
    );
  }

  @override
  String get id => ficha.id;

  @override
  String get nome => ficha.nome;

  @override
  int get pvMax => ficha.pvTotal;

  @override
  int get pmMax => ficha.pmTotal;

  @override
  int get defesa => ficha.defesaFinal;

  @override
  int get modIniciativa => ficha.getValorPericia('INICIATIVA');

  @override
  int get modLuta => ficha.getValorPericia('LUTA');

  @override
  int get modPontaria => ficha.getValorPericia('PONTARIA');

  @override
  int get modPercepcao => ficha.getValorPericia('PERCEPCAO');

  @override
  int get modForca => ficha.getValorFinal('FOR');

  @override
  int get modDestreza => ficha.getValorFinal('DES');

  @override
  int get modConstituicao => ficha.getValorFinal('CON');

  @override
  List<Arma> get armas => List.unmodifiable(ficha.armasEfetivas);

  @override
  CombatenteJogador copyWith({
    TimeCombatente? time,
    EstadoVidaCombatente? estadoVida,
    int? pvAtual,
    int? danoNaoLetal,
    int? pmAtual,
    int? iniciativaValor,
    double? deslocamentoMetros,
    List<CondicaoCombatente>? condicoesAtivas,
    Personagem? ficha,
  }) {
    return CombatenteJogador(
      ficha: ficha ?? this.ficha,
      time: time ?? this.time,
      estadoVida: estadoVida ?? this.estadoVida,
      pvAtual: pvAtual ?? this.pvAtual,
      danoNaoLetal: danoNaoLetal ?? this.danoNaoLetal,
      pmAtual: pmAtual ?? this.pmAtual,
      iniciativaValor: iniciativaValor ?? this.iniciativaValor,
      deslocamentoMetros: deslocamentoMetros ?? this.deslocamentoMetros,
      condicoesAtivas: condicoesAtivas ?? this.condicoesAtivas,
    );
  }
}

/// Implementação para Monstros e Ameaças de Tormenta 20 (baseada em ND e bloco de ataques)
class CombatenteMonstro extends Combatente {
  final Monstro fichaMonstro;
  @override
  final String id;
  @override
  final TimeCombatente time;
  @override
  final EstadoVidaCombatente estadoVida;
  @override
  final int pvAtual;
  @override
  final int danoNaoLetal;
  @override
  final int pmAtual;
  @override
  final int iniciativaValor;
  @override
  final double deslocamentoMetros;
  @override
  final List<CondicaoCombatente> condicoesAtivas;

  const CombatenteMonstro({
    required this.id,
    required this.fichaMonstro,
    this.time = TimeCombatente.inimigo,
    this.estadoVida = EstadoVidaCombatente.ativo,
    required this.pvAtual,
    this.danoNaoLetal = 0,
    required this.pmAtual,
    this.iniciativaValor = 0,
    required this.deslocamentoMetros,
    this.condicoesAtivas = const [],
  }) : super._();

  factory CombatenteMonstro.doMonstro(
    Monstro monstro, {
    String? idInstancia,
    TimeCombatente time = TimeCombatente.inimigo,
    int? pvAtual,
    int? pmAtual,
  }) {
    return CombatenteMonstro(
      id: idInstancia ?? monstro.id,
      fichaMonstro: monstro,
      time: time,
      estadoVida: (pvAtual != null && pvAtual <= 0)
          ? EstadoVidaCombatente.inconscienteSangrando
          : EstadoVidaCombatente.ativo,
      pvAtual: pvAtual ?? monstro.pvMax,
      pmAtual: pmAtual ?? monstro.pmMax,
      deslocamentoMetros: monstro.deslocamentoMetros,
    );
  }

  @override
  String get nome => fichaMonstro.nome;

  @override
  int get pvMax => fichaMonstro.pvMax;

  @override
  int get pmMax => fichaMonstro.pmMax;

  @override
  int get defesa => fichaMonstro.defesa;

  @override
  int get modIniciativa => fichaMonstro.iniciativa;

  @override
  int get modLuta => fichaMonstro.ataques.isNotEmpty
      ? fichaMonstro.ataques.first.bonusAtaque
      : fichaMonstro.modForca;

  @override
  int get modPontaria => fichaMonstro.ataques.any((a) => !a.alcance.toLowerCase().contains('corpo'))
      ? fichaMonstro.ataques.firstWhere((a) => !a.alcance.toLowerCase().contains('corpo')).bonusAtaque
      : fichaMonstro.modDestreza;

  @override
  int get modPercepcao => fichaMonstro.percepcao;

  @override
  int get modForca => fichaMonstro.modForca;

  @override
  int get modDestreza => fichaMonstro.modDestreza;

  @override
  int get modConstituicao => fichaMonstro.modConstituicao;

  @override
  List<Arma> get armas =>
      fichaMonstro.ataques.map((a) => a.toArma(id)).toList();

  @override
  CombatenteMonstro copyWith({
    TimeCombatente? time,
    EstadoVidaCombatente? estadoVida,
    int? pvAtual,
    int? danoNaoLetal,
    int? pmAtual,
    int? iniciativaValor,
    double? deslocamentoMetros,
    List<CondicaoCombatente>? condicoesAtivas,
    Monstro? fichaMonstro,
  }) {
    return CombatenteMonstro(
      id: id,
      fichaMonstro: fichaMonstro ?? this.fichaMonstro,
      time: time ?? this.time,
      estadoVida: estadoVida ?? this.estadoVida,
      pvAtual: pvAtual ?? this.pvAtual,
      danoNaoLetal: danoNaoLetal ?? this.danoNaoLetal,
      pmAtual: pmAtual ?? this.pmAtual,
      iniciativaValor: iniciativaValor ?? this.iniciativaValor,
      deslocamentoMetros: deslocamentoMetros ?? this.deslocamentoMetros,
      condicoesAtivas: condicoesAtivas ?? this.condicoesAtivas,
    );
  }
}

/// Implementação genérica e independente com valores brutos (retrocompatibilidade)
class CombatenteGenerico extends Combatente {
  @override
  final String id;
  @override
  final String nome;
  @override
  final TimeCombatente time;
  @override
  final EstadoVidaCombatente estadoVida;
  @override
  final int pvMax;
  @override
  final int pvAtual;
  @override
  final int danoNaoLetal;
  @override
  final int pmMax;
  @override
  final int pmAtual;
  @override
  final int defesa;
  @override
  final int iniciativaValor;
  @override
  final double deslocamentoMetros;
  @override
  final int modIniciativa;
  @override
  final int modLuta;
  @override
  final int modPontaria;
  @override
  final int modPercepcao;
  @override
  final int modForca;
  @override
  final int modDestreza;
  @override
  final int modConstituicao;
  @override
  final List<Arma> armas;
  @override
  final List<CondicaoCombatente> condicoesAtivas;

  const CombatenteGenerico({
    required this.id,
    required this.nome,
    this.time = TimeCombatente.heroi,
    this.estadoVida = EstadoVidaCombatente.ativo,
    required this.pvMax,
    required this.pvAtual,
    this.danoNaoLetal = 0,
    required this.pmMax,
    required this.pmAtual,
    required this.defesa,
    this.iniciativaValor = 0,
    this.deslocamentoMetros = 9.0,
    required this.modIniciativa,
    required this.modLuta,
    required this.modPontaria,
    required this.modPercepcao,
    required this.modForca,
    required this.modDestreza,
    required this.modConstituicao,
    this.armas = const [],
    this.condicoesAtivas = const [],
  }) : super._();

  @override
  CombatenteGenerico copyWith({
    TimeCombatente? time,
    EstadoVidaCombatente? estadoVida,
    int? pvAtual,
    int? danoNaoLetal,
    int? pmAtual,
    int? iniciativaValor,
    double? deslocamentoMetros,
    List<CondicaoCombatente>? condicoesAtivas,
  }) {
    return CombatenteGenerico(
      id: id,
      nome: nome,
      time: time ?? this.time,
      estadoVida: estadoVida ?? this.estadoVida,
      pvMax: pvMax,
      pvAtual: pvAtual ?? this.pvAtual,
      danoNaoLetal: danoNaoLetal ?? this.danoNaoLetal,
      pmMax: pmMax,
      pmAtual: pmAtual ?? this.pmAtual,
      defesa: defesa,
      iniciativaValor: iniciativaValor ?? this.iniciativaValor,
      deslocamentoMetros: deslocamentoMetros ?? this.deslocamentoMetros,
      modIniciativa: modIniciativa,
      modLuta: modLuta,
      modPontaria: modPontaria,
      modPercepcao: modPercepcao,
      modForca: modForca,
      modDestreza: modDestreza,
      modConstituicao: modConstituicao,
      armas: armas,
      condicoesAtivas: condicoesAtivas ?? this.condicoesAtivas,
    );
  }
}
