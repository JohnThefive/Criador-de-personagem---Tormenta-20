import 'dart:math';
import '../arma.dart';
import '../personagem.dart';
import 'estado_vida_combatente.dart';

enum CondicaoCombatente { surpreendido, caido, indefeso }

enum TimeCombatente { heroi, inimigo }

class Combatente {
  final String id;
  final String nome;
  final TimeCombatente time;
  final EstadoVidaCombatente estadoVida;
  final int pvMax;
  final int pvAtual;
  final int danoNaoLetal;
  final int pmMax;
  final int pmAtual;
  final int defesa;
  final int iniciativaValor;
  final double deslocamentoMetros; // Padrão 9.0m (6 quadrados)
  final int modIniciativa;
  final int modLuta;
  final int modPontaria;
  final int modPercepcao;
  final int modForca;
  final int modDestreza;
  final int modConstituicao;
  final List<Arma> armas;
  final List<CondicaoCombatente> condicoesAtivas;

  const Combatente({
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
  });

  /// Limite de morte no T20: PV <= min(-10, -(pvMaximo / 2))
  int get limiteMorte => min(-10, -(pvMax / 2).floor());

  bool get estaInconsciente => estadoVida.estaInconsciente || pvAtual <= 0;
  bool get estaMorto => estadoVida == EstadoVidaCombatente.morto;
  bool get estaIncapacitado => estaInconsciente || estaMorto;
  bool get podeAgir => estadoVida == EstadoVidaCombatente.ativo && pvAtual > 0;
  bool get ehSurpreendido =>
      condicoesAtivas.contains(CondicaoCombatente.surpreendido);
  bool get estaCaido => condicoesAtivas.contains(CondicaoCombatente.caido);

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
  /// Retorna o novo Combatente e o resultado textual
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

  /// Constrói um Combatente a partir da ficha do Personagem
  factory Combatente.fromPersonagem(Personagem p) => Combatente.doPersonagem(p);

  factory Combatente.doPersonagem(Personagem p) {
    // Se estiver sobrecarregado, deslocamento reduz em 3m
    final double deslocamento = p.estaSobrecarregado ? 6.0 : 9.0;

    return Combatente(
      id: p.id,
      nome: p.nome,
      time: TimeCombatente.heroi,
      estadoVida: p.pvAtual <= 0
          ? EstadoVidaCombatente.inconscienteSangrando
          : EstadoVidaCombatente.ativo,
      pvMax: p.pvTotal,
      pvAtual: p.pvAtual,
      pmMax: p.pmTotal,
      pmAtual: p.pmAtual,
      defesa: p.defesaFinal,
      deslocamentoMetros: deslocamento,
      modIniciativa: p.getValorPericia('INICIATIVA'),
      modLuta: p.getValorPericia('LUTA'),
      modPontaria: p.getValorPericia('PONTARIA'),
      modPercepcao: p.getValorPericia('PERCEPCAO'),
      modForca: p.getValorFinal('FOR'),
      modDestreza: p.getValorFinal('DES'),
      modConstituicao: p.getValorFinal('CON'),
      armas: List.unmodifiable(p.armasEfetivas),
    );
  }

  Combatente copyWith({
    TimeCombatente? time,
    EstadoVidaCombatente? estadoVida,
    int? pvAtual,
    int? danoNaoLetal,
    int? pmAtual,
    int? iniciativaValor,
    double? deslocamentoMetros,
    List<CondicaoCombatente>? condicoesAtivas,
  }) {
    return Combatente(
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
