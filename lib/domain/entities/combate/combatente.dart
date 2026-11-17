import 'dart:math';
import '../../services/habilidades_services/imunidade_service.dart';
import '../equipamento/arma.dart';
import '../habilidades/modelos_resistencia_efeito.dart';
import '../personagem/personagem.dart';
import 'estado_vida_combatente.dart';
import 'monstro.dart';
import 'tipo_dano.dart';

enum CondicaoCombatente { surpreendido, caido, indefeso, cego, desprevenido, invisivel }

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
  bool get imuneACritico;
  bool get imuneASurpresa;

  int get tamanhoQuadrados => 1;
  int get modFortitude => modConstituicao;
  int get modReflexos => modDestreza;
  int get modVontade => 0;
  bool get temForcaNula => false;
  bool get temDestrezaNula => false;
  bool get temConstituicaoNula => false;
  bool get temInteligenciaNula => false;
  TipoCriatura get tipoCriatura => TipoCriatura.humanoide;
  bool get ehConstruto => tipoCriatura == TipoCriatura.construto;
  bool get ehMortoVivo => tipoCriatura == TipoCriatura.mortoVivo;
  bool get possuiVisaoNoEscuro => ehConstruto || ehMortoVivo;
  Set<TipoEfeito> get imunidadesEfeitosSet => const {};

  int rdParaTipo(
    TipoDano? tipo, {
    bool armaAdamante = false,
    bool armaMagica = false,
  }) => 0;

  bool imuneADano(TipoDano? tipo) => false;
  bool vulneravelADano(TipoDano? tipo) => false;

  /// Converte para [Criatura] para avaliação por [ImunidadeService] e [ResistenciaService].
  Criatura toCriatura() {
    return Criatura(
      id: id,
      nome: nome,
      tipoCriatura: tipoCriatura,
      inteligencia: temInteligenciaNula ? null : 0,
      imunidades: imunidadesEfeitosSet,
      bonusResistencia: BonusResistencia(
        fortitude: modFortitude,
        reflexos: modReflexos,
        vontade: modVontade,
      ),
    );
  }

  /// Verifica se o combatente é imune aos efeitos informados (via [ImunidadeService]).
  bool isImuneAEfeitos(Set<TipoEfeito> tiposEfeito) {
    if (tiposEfeito.isEmpty) return false;
    return ImunidadeService().checarImunidade(
      criatura: toCriatura(),
      tiposEfeito: tiposEfeito,
    ).imune;
  }

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
    bool imuneACritico,
    bool imuneASurpresa,
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

  /// Limite de morte no T20: PV <= min(-10, -(pvMaximo / 2)) (R71 / A2)
  int get limiteMorte => min(-10, -(pvMax / 2).floor());

  bool get estaInconsciente =>
      estadoVida.estaInconsciente ||
      pvAtual <= 0 ||
      (pvAtual > 0 && danoNaoLetal >= pvAtual);
  bool get estaMorto => estadoVida == EstadoVidaCombatente.morto;
  bool get estaIncapacitado => estaInconsciente || estaMorto;
  bool get podeAgir =>
      estadoVida == EstadoVidaCombatente.ativo &&
      pvAtual > 0 &&
      danoNaoLetal < pvAtual;
  bool get ehSurpreendido =>
      condicoesAtivas.contains(CondicaoCombatente.surpreendido);
  bool get estaCaido => condicoesAtivas.contains(CondicaoCombatente.caido);
  bool get estaIndefeso => condicoesAtivas.contains(CondicaoCombatente.indefeso);
  bool get estaCego => condicoesAtivas.contains(CondicaoCombatente.cego);
  bool get estaDesprevenido =>
      condicoesAtivas.contains(CondicaoCombatente.desprevenido) ||
      ehSurpreendido ||
      estaIndefeso;
  bool get estaInvisivel =>
      condicoesAtivas.contains(CondicaoCombatente.invisivel);

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

  /// Aplica dano letal ou não letal conforme regras do T20 (R66, R71, R72)
  Combatente aplicarDano(
    int valor, {
    bool naoLetal = false,
    TipoDano? tipo,
    int rd = 0,
    bool ignoraReducaoDano = false,
    bool armaAdamante = false,
    bool armaMagica = false,
  }) {
    if (valor <= 0) return this;

    // Mortos-vivos recuperam PV com dano de trevas (antes de checar imunidade a trevas)
    if (ehMortoVivo && tipo == TipoDano.trevas && !naoLetal) {
      return _aplicarRecuperacaoPv(valor);
    }

    // Imunidade ao tipo de dano
    if (imuneADano(tipo)) return this;

    // Vulnerabilidade ao tipo de dano (+50% no dano antes da RD)
    int danoModificado =
        vulneravelADano(tipo) ? (valor * 1.5).floor() : valor;

    // Redução de dano (RD), combinando parâmetro explícito e RD da criatura
    int danoEfetivo = danoModificado;
    final int rdTotal = max(
      rd,
      rdParaTipo(tipo, armaAdamante: armaAdamante, armaMagica: armaMagica),
    );
    if (!ignoraReducaoDano && rdTotal > 0) {
      danoEfetivo = max(0, danoEfetivo - rdTotal);
    }
    if (danoEfetivo <= 0) return this;

    if (naoLetal) {
      final novoDanoNaoLetal = danoNaoLetal + danoEfetivo;
      // Dano não-letal faz desmaiar quando soma >= PV atual, mas não sangra nem mata (R72)
      final novoEstado =
          (novoDanoNaoLetal >= pvAtual &&
              estadoVida == EstadoVidaCombatente.ativo)
          ? EstadoVidaCombatente.estabilizado
          : estadoVida;

      return copyWith(danoNaoLetal: novoDanoNaoLetal, estadoVida: novoEstado);
    }

    // Dano Letal (R71)
    final novoPv = pvAtual - danoEfetivo;
    EstadoVidaCombatente novoEstado = estadoVida;

    if (novoPv <= limiteMorte) {
      novoEstado = EstadoVidaCombatente.morto;
    } else if (novoPv <= 0) {
      // Se já estava estabilizado e tomou dano letal novo, volta a sangrar (R71)
      novoEstado = EstadoVidaCombatente.inconscienteSangrando;
    }

    return copyWith(pvAtual: novoPv, estadoVida: novoEstado);
  }

  /// Aplica cura: primeiro remove dano não-letal, sobra vai para PV (R71, R72).
  /// Construtos não recuperam PV por efeitos de cura comuns (apenas reparo via Ofício artesão).
  /// Mortos-vivos sofrem dano por efeitos mágicos de cura de luz (Vontade CD reduz à metade).
  Combatente aplicarCura(
    int valor, {
    bool magica = true,
    bool ehLuz = false,
    bool ehReparoConstruto = false,
    bool passouVontade = false,
  }) {
    if (valor <= 0) return this;
    if (estadoVida == EstadoVidaCombatente.morto) return this;

    if (ehConstruto && !ehReparoConstruto) {
      return this;
    }

    if (ehMortoVivo && magica && ehLuz) {
      final danoLuz = passouVontade ? (valor / 2).floor() : valor;
      return aplicarDano(danoLuz, tipo: TipoDano.luz);
    }

    return _aplicarRecuperacaoPv(valor);
  }

  Combatente _aplicarRecuperacaoPv(int valor) {
    if (valor <= 0) return this;
    if (estadoVida == EstadoVidaCombatente.morto) return this;

    int novoDanoNaoLetal = danoNaoLetal;
    int sobraCura = valor;

    if (novoDanoNaoLetal > 0) {
      final curaNaoLetal = min(sobraCura, novoDanoNaoLetal);
      novoDanoNaoLetal -= curaNaoLetal;
      sobraCura -= curaNaoLetal;
    }

    final novoPv = min(pvMax, pvAtual + sobraCura);
    EstadoVidaCombatente novoEstado = estadoVida;

    if (novoPv <= 0) {
      // Qualquer cura estabiliza o personagem (R71)
      novoEstado = EstadoVidaCombatente.estabilizado;
    } else if (novoDanoNaoLetal >= novoPv) {
      // Ainda inconsciente devido a dano não letal acumulado (R72)
      novoEstado = EstadoVidaCombatente.estabilizado;
    } else {
      // PV positivo e dano não-letal < PV -> acorda e volta a ficar ativo (R71)
      novoEstado = EstadoVidaCombatente.ativo;
    }

    return copyWith(
      pvAtual: novoPv,
      danoNaoLetal: novoDanoNaoLetal,
      estadoVida: novoEstado,
    );
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
  int get modFortitude => ficha.getValorPericia('FORTITUDE');

  @override
  int get modReflexos => ficha.getValorPericia('REFLEXOS');

  @override
  int get modVontade => ficha.getValorPericia('VONTADE');

  @override
  bool get imuneACritico => ficha.raca?.id.toLowerCase() == 'golem';

  @override
  bool get imuneASurpresa =>
      ficha.chavesPoderesAtivos.contains('esquiva_sobrenatural');

  @override
  Criatura toCriatura() {
    return Criatura(
      id: id,
      nome: nome,
      tipoCriatura: tipoCriatura,
      inteligencia: ficha.getValorFinal('INT'),
      bonusResistencia: BonusResistencia(
        fortitude: modFortitude,
        reflexos: modReflexos,
        vontade: modVontade,
      ),
    );
  }

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
  final Set<String> habilidadesEmRecarga;

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
    this.habilidadesEmRecarga = const {},
  }) : super._();

  factory CombatenteMonstro.doMonstro(
    Monstro monstro, {
    String? idInstancia,
    TimeCombatente time = TimeCombatente.inimigo,
    int? pvAtual,
    int? pmAtual,
  }) {
    final double deslocamentoEfetivo;
    if (monstro.destrezaNula) {
      deslocamentoEfetivo = 0.0;
    } else if (monstro.deslocamentoMetros > 0) {
      deslocamentoEfetivo = monstro.deslocamentoMetros;
    } else if (monstro.deslocamentos.isNotEmpty) {
      deslocamentoEfetivo = monstro.deslocamentos.values.reduce(max);
    } else {
      deslocamentoEfetivo = 0.0;
    }

    return CombatenteMonstro(
      id: idInstancia ?? monstro.id,
      fichaMonstro: monstro,
      time: time,
      estadoVida: (pvAtual != null && pvAtual <= 0)
          ? EstadoVidaCombatente.inconscienteSangrando
          : EstadoVidaCombatente.ativo,
      pvAtual: pvAtual ?? monstro.pvMax,
      pmAtual: pmAtual ?? monstro.pmMax,
      deslocamentoMetros: deslocamentoEfetivo,
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
  int get modForca => fichaMonstro.forcaNula ? 0 : fichaMonstro.modForca;

  @override
  int get modDestreza => fichaMonstro.destrezaNula ? 0 : fichaMonstro.modDestreza;

  @override
  int get modConstituicao =>
      fichaMonstro.constituicaoNula ? 0 : fichaMonstro.modConstituicao;

  @override
  int get tamanhoQuadrados => fichaMonstro.tamanhoQuadrados;

  @override
  int get modFortitude => fichaMonstro.fortitude;

  @override
  int get modReflexos => fichaMonstro.reflexos;

  @override
  int get modVontade => fichaMonstro.vontade;

  @override
  bool get temForcaNula => fichaMonstro.forcaNula;

  @override
  bool get temDestrezaNula => fichaMonstro.destrezaNula;

  @override
  bool get temConstituicaoNula => fichaMonstro.constituicaoNula;

  @override
  bool get temInteligenciaNula => fichaMonstro.modInteligencia == null;

  @override
  TipoCriatura get tipoCriatura => _parseTipoCriatura(fichaMonstro.tipoCriatura);

  @override
  bool get possuiVisaoNoEscuro =>
      ehConstruto ||
      ehMortoVivo ||
      fichaMonstro.sentidos.any((s) {
        final n = _normalizarToken(s);
        return n.contains('visao_no_escuro') || n.contains('visao no escuro');
      });

  @override
  Set<TipoEfeito> get imunidadesEfeitosSet => {
    ..._parseImunidadesEfeitos(fichaMonstro.imunidadesEfeitos),
    if (ehMortoVivo) TipoEfeito.trevas,
  };

  @override
  List<Arma> get armas =>
      fichaMonstro.ataques.map((a) => a.toArma(id)).toList();

  @override
  int rdParaTipo(
    TipoDano? tipo, {
    bool armaAdamante = false,
    bool armaMagica = false,
  }) {
    final rdMap = fichaMonstro.rd;
    if (rdMap.isEmpty) return 0;

    int total = rdMap['geral'] ?? 0;
    if (tipo != null) {
      total += rdMap[tipo.name] ?? 0;
    }

    final bool ehFisicoOuIndefinido =
        tipo == null ||
        tipo == TipoDano.corte ||
        tipo == TipoDano.impacto ||
        tipo == TipoDano.perfuracao;

    if (ehFisicoOuIndefinido) {
      if (!armaAdamante) {
        total += rdMap['adamante'] ?? 0;
      }
      if (!armaMagica) {
        total += rdMap['magico'] ?? 0;
      }
    }
    return total;
  }

  @override
  bool imuneADano(TipoDano? tipo) {
    if (fichaMonstro.imunidadesEfeitos.any((e) => _normalizarToken(e) == 'dano')) {
      return true;
    }
    if (tipo == null) return false;
    final alvo = tipo.name;
    if (fichaMonstro.imunidadesDano.any((d) => _normalizarToken(d) == alvo)) {
      return true;
    }
    return fichaMonstro.imunidadesEfeitos
        .any((e) => _normalizarToken(e) == 'dano_de_$alvo');
  }

  @override
  bool vulneravelADano(TipoDano? tipo) {
    if (tipo == null) return false;
    final alvo = tipo.name;
    return fichaMonstro.vulnerabilidadesDano.any((d) {
      final n = _normalizarToken(d);
      return n == alvo || (tipo == TipoDano.luz && n == 'luz_solar');
    });
  }

  @override
  Criatura toCriatura() {
    return Criatura(
      id: id,
      nome: nome,
      tipoCriatura: tipoCriatura,
      inteligencia: fichaMonstro.modInteligencia,
      imunidades: imunidadesEfeitosSet,
      bonusResistencia: BonusResistencia(
        fortitude: modFortitude,
        reflexos: modReflexos,
        vontade: modVontade,
      ),
    );
  }

  /// Indica se a habilidade está aguardando ação de recarga antes de poder ser usada novamente.
  bool habilidadeEmRecarga(String nomeHabilidade) =>
      habilidadesEmRecarga.contains(_normalizarToken(nomeHabilidade));

  CombatenteMonstro marcarHabilidadeEmRecarga(String nomeHabilidade) {
    final key = _normalizarToken(nomeHabilidade);
    if (habilidadesEmRecarga.contains(key)) return this;
    return copyWith(habilidadesEmRecarga: {...habilidadesEmRecarga, key});
  }

  CombatenteMonstro recarregarHabilidade(String nomeHabilidade) {
    final key = _normalizarToken(nomeHabilidade);
    if (!habilidadesEmRecarga.contains(key)) return this;
    final nova = Set<String>.from(habilidadesEmRecarga)..remove(key);
    return copyWith(habilidadesEmRecarga: nova);
  }

  CombatenteMonstro recarregarTodasHabilidades() {
    if (habilidadesEmRecarga.isEmpty) return this;
    return copyWith(habilidadesEmRecarga: const {});
  }

  @override
  bool get imuneACritico {
    return ehConstruto ||
        ehMortoVivo ||
        fichaMonstro.imunidadesEfeitos.any((e) => e.toLowerCase().contains('critico')) ||
        fichaMonstro.habilidadesDefensivas.any((h) =>
            h.toLowerCase().contains('imunidade a crítico') ||
            h.toLowerCase().contains('imunidade a acertos críticos')) ||
        fichaMonstro.habilidades.any((h) {
          final txt = '${h.nome} ${h.descricao}'.toLowerCase();
          return txt.contains('imunidade a crítico') ||
              txt.contains('imunidade a acertos críticos');
        });
  }

  @override
  bool get imuneASurpresa =>
      fichaMonstro.sentidos.any((s) =>
          s.toLowerCase().contains('percepcao_as_cegas') ||
          s.toLowerCase().contains('percepção às cegas')) ||
      fichaMonstro.imunidadesEfeitos.any((e) => _normalizarToken(e) == 'surpreendido') ||
      fichaMonstro.habilidades.any((h) {
        final txt = '${h.nome} ${h.descricao}'.toLowerCase();
        return txt.contains('percepção às cegas') ||
            txt.contains('esquiva sobrenatural');
      });

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
    Set<String>? habilidadesEmRecarga,
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
      habilidadesEmRecarga: habilidadesEmRecarga ?? this.habilidadesEmRecarga,
    );
  }

  static String _normalizarToken(String raw) {
    return raw
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c')
        .replaceAll(' ', '_');
  }

  static TipoCriatura _parseTipoCriatura(String raw) {
    final n = _normalizarToken(raw);
    if (n.contains('construto')) return TipoCriatura.construto;
    if (n.contains('morto')) return TipoCriatura.mortoVivo;
    if (n.contains('animal')) return TipoCriatura.animal;
    if (n.contains('espirito')) return TipoCriatura.espirito;
    if (n.contains('humanoide')) return TipoCriatura.humanoide;
    return TipoCriatura.monstro;
  }

  static Set<TipoEfeito> _parseImunidadesEfeitos(List<String> lista) {
    final resultado = <TipoEfeito>{};
    for (final raw in lista) {
      final n = _normalizarToken(raw);
      if (n.contains('medo')) resultado.add(TipoEfeito.medo);
      if (n.contains('mental') ||
          n.contains('mente') ||
          n.contains('encantamento') ||
          n.contains('confus')) {
        resultado.add(TipoEfeito.mental);
      }
      if (n.contains('metabol')) resultado.add(TipoEfeito.metabolismo);
      if (n.contains('cansaco') || n.contains('fadiga') || n.contains('exaustao')) {
        resultado.add(TipoEfeito.cansaco);
      }
      if (n.contains('veneno')) resultado.add(TipoEfeito.veneno);
      if (n.contains('trevas') || n.contains('escuridao')) resultado.add(TipoEfeito.trevas);
      if (n.contains('luz')) resultado.add(TipoEfeito.luz);
      if (n.contains('paralisia')) resultado.add(TipoEfeito.movimento);
      if (n.contains('atordoa')) resultado.add(TipoEfeito.atordoamento);
      if (n.contains('clima') || n.contains('precipitac')) {
        resultado.add(TipoEfeito.climatico);
      }
      if (n.contains('sentido') || n.contains('ofuscado')) {
        resultado.add(TipoEfeito.sentidos);
      }
      if (n.contains('movimento')) resultado.add(TipoEfeito.movimento);
      if (n.contains('magia') || n.contains('magico')) {
        resultado.add(TipoEfeito.magico);
      }
      if (n.contains('metamorfose')) resultado.add(TipoEfeito.metamorfose);
      if (n.contains('cura')) resultado.add(TipoEfeito.cura);
      if (n.contains('perda_de_vida')) resultado.add(TipoEfeito.perdaDeVida);
    }
    return resultado;
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
  @override
  final bool imuneACritico;
  @override
  final bool imuneASurpresa;

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
    this.imuneACritico = false,
    this.imuneASurpresa = false,
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
    bool? imuneACritico,
    bool? imuneASurpresa,
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
      imuneACritico: imuneACritico ?? this.imuneACritico,
      imuneASurpresa: imuneASurpresa ?? this.imuneASurpresa,
    );
  }
}
