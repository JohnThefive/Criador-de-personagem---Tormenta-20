import 'package:equatable/equatable.dart';
import '../../domain/entities/combate/combatente.dart';
import '../../domain/entities/combate/grid_tatico.dart';
import '../../domain/entities/combate/resultado_ataque.dart';
import '../../domain/services/combate_engine.dart';

class CombateState extends Equatable {
  final List<Combatente> filaIniciativa;
  final int rodadaAtual;
  final int indiceTurnoAtual;
  final int acoesPadraoRestantes;
  final int acoesMovimentoRestantes;
  final double deslocamentoRestanteMetros;
  final bool mirouNesteTurno;
  final bool ataqueNaoLetalAtivo;
  final bool modoMovimentoAtivo;
  final GridMapa mapaGrid;
  final Map<String, Posicao2D> posicoesCombatentes;
  final Set<Posicao2D> celulasAlcancaveis;
  final Map<Posicao2D, double> custosMovimento;
  final StatusCombate statusCombate;
  final List<String> logCombate;
  final ResultadoAtaque? ultimoResultadoAtaque;

  const CombateState({
    this.filaIniciativa = const [],
    this.rodadaAtual = 1,
    this.indiceTurnoAtual = 0,
    this.acoesPadraoRestantes = 1,
    this.acoesMovimentoRestantes = 1,
    this.deslocamentoRestanteMetros = 9.0,
    this.mirouNesteTurno = false,
    this.ataqueNaoLetalAtivo = false,
    this.modoMovimentoAtivo = false,
    this.mapaGrid = const GridMapa(largura: 10, altura: 8),
    this.posicoesCombatentes = const {},
    this.celulasAlcancaveis = const {},
    this.custosMovimento = const {},
    this.statusCombate = StatusCombate.emAndamento,
    this.logCombate = const [],
    this.ultimoResultadoAtaque,
  });

  Combatente? get combatenteAtual =>
      filaIniciativa.isNotEmpty && indiceTurnoAtual < filaIniciativa.length
          ? filaIniciativa[indiceTurnoAtual]
          : null;

  Posicao2D? get posicaoCombatenteAtual =>
      combatenteAtual != null ? posicoesCombatentes[combatenteAtual!.id] : null;

  bool get temAcaoPadrao => acoesPadraoRestantes > 0;
  bool get temAcaoMovimento =>
      acoesMovimentoRestantes > 0 || acoesPadraoRestantes > 0;
  bool get combateIniciado => filaIniciativa.isNotEmpty;
  bool get combateTerminado => statusCombate != StatusCombate.emAndamento;

  CombateState copyWith({
    List<Combatente>? filaIniciativa,
    int? rodadaAtual,
    int? indiceTurnoAtual,
    int? acoesPadraoRestantes,
    int? acoesMovimentoRestantes,
    double? deslocamentoRestanteMetros,
    bool? mirouNesteTurno,
    bool? ataqueNaoLetalAtivo,
    bool? modoMovimentoAtivo,
    GridMapa? mapaGrid,
    Map<String, Posicao2D>? posicoesCombatentes,
    Set<Posicao2D>? celulasAlcancaveis,
    Map<Posicao2D, double>? custosMovimento,
    StatusCombate? statusCombate,
    List<String>? logCombate,
    ResultadoAtaque? ultimoResultadoAtaque,
    bool limparUltimoAtaque = false,
  }) {
    return CombateState(
      filaIniciativa: filaIniciativa ?? this.filaIniciativa,
      rodadaAtual: rodadaAtual ?? this.rodadaAtual,
      indiceTurnoAtual: indiceTurnoAtual ?? this.indiceTurnoAtual,
      acoesPadraoRestantes: acoesPadraoRestantes ?? this.acoesPadraoRestantes,
      acoesMovimentoRestantes:
          acoesMovimentoRestantes ?? this.acoesMovimentoRestantes,
      deslocamentoRestanteMetros:
          deslocamentoRestanteMetros ?? this.deslocamentoRestanteMetros,
      mirouNesteTurno: mirouNesteTurno ?? this.mirouNesteTurno,
      ataqueNaoLetalAtivo: ataqueNaoLetalAtivo ?? this.ataqueNaoLetalAtivo,
      modoMovimentoAtivo: modoMovimentoAtivo ?? this.modoMovimentoAtivo,
      mapaGrid: mapaGrid ?? this.mapaGrid,
      posicoesCombatentes: posicoesCombatentes ?? this.posicoesCombatentes,
      celulasAlcancaveis: celulasAlcancaveis ?? this.celulasAlcancaveis,
      custosMovimento: custosMovimento ?? this.custosMovimento,
      statusCombate: statusCombate ?? this.statusCombate,
      logCombate: logCombate ?? this.logCombate,
      ultimoResultadoAtaque: limparUltimoAtaque
          ? null
          : (ultimoResultadoAtaque ?? this.ultimoResultadoAtaque),
    );
  }

  @override
  List<Object?> get props => [
        filaIniciativa,
        rodadaAtual,
        indiceTurnoAtual,
        acoesPadraoRestantes,
        acoesMovimentoRestantes,
        deslocamentoRestanteMetros,
        mirouNesteTurno,
        ataqueNaoLetalAtivo,
        modoMovimentoAtivo,
        mapaGrid,
        posicoesCombatentes,
        celulasAlcancaveis,
        custosMovimento,
        statusCombate,
        logCombate,
        ultimoResultadoAtaque,
      ];
}
