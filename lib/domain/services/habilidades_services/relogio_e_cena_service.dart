import 'package:t20_creator/domain/entities/combate/tipo_acao.dart';
import 'package:t20_creator/domain/entities/habilidades/modelos_habilidade_duracao.dart';

/// Ponto de extensão `ControleDeAcoes`: modela a economia de ações
/// (`LIVRE`, `PADRAO`, `MOVIMENTO`, `COMPLETA`, `REACAO`).
abstract interface class IControleDeAcoes {
  bool temAcaoDisponivel(String personagemId, TipoAcao acao);
  void consumirAcao(String personagemId, TipoAcao acao);
}

/// Implementação PERMISSIVA padrão de [IControleDeAcoes] (não bloqueia, registra histórico se necessário).
class ControleDeAcoesPermissivo implements IControleDeAcoes {
  final Set<TipoAcao> acoesBloqueadasParaTeste;

  ControleDeAcoesPermissivo({
    this.acoesBloqueadasParaTeste = const {},
  });

  @override
  bool temAcaoDisponivel(String personagemId, TipoAcao acao) {
    return !acoesBloqueadasParaTeste.contains(acao);
  }

  @override
  void consumirAcao(String personagemId, TipoAcao acao) {
    // Permissivo por padrão até o módulo de economia de turno de combate.
  }
}

/// R60: Implementação REAL da Economia de Ações por Turno do Tormenta 20:
/// (1 padrão + 1 movimento) OU 2 movimentos OU 1 completa (consome padrão + movimento).
/// Ações livres e reações não são limitadas programaticamente (ficam a cargo de roleplay e arbítrio do mestre - A4).
class ControleDeAcoesCombate implements IControleDeAcoes {
  final Map<String, int> _acoesPadraoPorCombatente = {};
  final Map<String, int> _acoesMovimentoPorCombatente = {};

  void iniciarTurno(String combatenteId) {
    _acoesPadraoPorCombatente[combatenteId] = 1;
    _acoesMovimentoPorCombatente[combatenteId] = 1;
  }

  int acoesPadraoRestantes(String combatenteId) =>
      _acoesPadraoPorCombatente[combatenteId] ?? 1;

  int acoesMovimentoRestantes(String combatenteId) =>
      _acoesMovimentoPorCombatente[combatenteId] ?? 1;

  @override
  bool temAcaoDisponivel(String personagemId, TipoAcao acao) {
    final padrao = _acoesPadraoPorCombatente[personagemId] ?? 1;
    final movimento = _acoesMovimentoPorCombatente[personagemId] ?? 1;

    switch (acao) {
      case TipoAcao.padrao:
        return padrao > 0;
      case TipoAcao.movimento:
        return movimento > 0 || padrao > 0; // Padrão pode ser convertida em movimento
      case TipoAcao.completa:
        return padrao > 0 && movimento > 0; // Consome ambas
      case TipoAcao.livre:
      case TipoAcao.reacao:
        return true; // A4: livres e reações o mais livre possível
    }
  }

  @override
  void consumirAcao(String personagemId, TipoAcao acao) {
    final padrao = _acoesPadraoPorCombatente[personagemId] ?? 1;
    final movimento = _acoesMovimentoPorCombatente[personagemId] ?? 1;

    switch (acao) {
      case TipoAcao.padrao:
        if (padrao > 0) {
          _acoesPadraoPorCombatente[personagemId] = padrao - 1;
        }
        break;
      case TipoAcao.movimento:
        if (movimento > 0) {
          _acoesMovimentoPorCombatente[personagemId] = movimento - 1;
        } else if (padrao > 0) {
          _acoesPadraoPorCombatente[personagemId] = padrao - 1;
        }
        break;
      case TipoAcao.completa:
        _acoesPadraoPorCombatente[personagemId] = 0;
        _acoesMovimentoPorCombatente[personagemId] = 0;
        break;
      case TipoAcao.livre:
      case TipoAcao.reacao:
        break;
    }
  }
}

/// Eventos emitidos pelo [ITurnClock].
sealed class EventoTurnClock {
  const EventoTurnClock();
}

class TurnoIniciado extends EventoTurnClock {
  final String personagemId;
  final int rodada;

  const TurnoIniciado({
    required this.personagemId,
    required this.rodada,
  });
}

class RodadaAvancada extends EventoTurnClock {
  final int novaRodada;

  const RodadaAvancada(this.novaRodada);
}

class PersonagemMorreu extends EventoTurnClock {
  final String personagemId;

  const PersonagemMorreu(this.personagemId);
}

/// Ponto de extensão `TurnClock`: emite `TurnoIniciado`, `RodadaAvancada` e `PersonagemMorreu`.
abstract interface class ITurnClock {
  int get rodadaAtual;
  String? get personagemTurnoAtual;
  List<String> get participantes;

  List<EventoTurnClock> proximoTurno();
  List<EventoTurnClock> novaRodada();
  PersonagemMorreu marcarPersonagemComoMorto(String personagemId);
}

/// Implementação MANUAL de [ITurnClock] controlada pelo mestre ("Próximo turno", "Nova rodada", "Marcar morto").
class TurnClockManual implements ITurnClock {
  final List<String> _participantes;
  int _indiceTurnoAtual;
  int _rodadaAtual;

  TurnClockManual({
    required List<String> participantes,
    int rodadaInicial = 1,
    int indiceInicial = 0,
  })  : _participantes = List<String>.from(participantes),
        _rodadaAtual = rodadaInicial,
        _indiceTurnoAtual = indiceInicial;

  @override
  int get rodadaAtual => _rodadaAtual;

  @override
  List<String> get participantes => List.unmodifiable(_participantes);

  @override
  String? get personagemTurnoAtual {
    if (_participantes.isEmpty) return null;
    return _participantes[_indiceTurnoAtual % _participantes.length];
  }

  @override
  List<EventoTurnClock> proximoTurno() {
    if (_participantes.isEmpty) return const [];
    final eventos = <EventoTurnClock>[];
    _indiceTurnoAtual += 1;
    if (_indiceTurnoAtual >= _participantes.length) {
      _indiceTurnoAtual = 0;
      _rodadaAtual += 1;
      eventos.add(RodadaAvancada(_rodadaAtual));
    }
    eventos.add(
      TurnoIniciado(
        personagemId: _participantes[_indiceTurnoAtual],
        rodada: _rodadaAtual,
      ),
    );
    return eventos;
  }

  @override
  List<EventoTurnClock> novaRodada() {
    _rodadaAtual += 1;
    _indiceTurnoAtual = 0;
    final eventos = <EventoTurnClock>[RodadaAvancada(_rodadaAtual)];
    if (_participantes.isNotEmpty) {
      eventos.add(
        TurnoIniciado(
          personagemId: _participantes.first,
          rodada: _rodadaAtual,
        ),
      );
    }
    return eventos;
  }

  @override
  PersonagemMorreu marcarPersonagemComoMorto(String personagemId) {
    return PersonagemMorreu(personagemId);
  }
}

/// R40 (Caso de Borda 22): Gerenciador puro de Cenas.
/// Sempre existe uma cena ativa; iniciar uma nova cena encerra a anterior.
class CenaService {
  const CenaService();

  /// Encerra a cena atual e inicia uma nova cena imediatamente.
  ({Cena cenaEncerrada, Cena novaCena}) iniciarNovaCena({
    required Cena cenaAtual,
    required String novoId,
    required String novoNome,
    required int tempoAtualSegundos,
  }) {
    final encerrada = cenaAtual.copyWith(ativa: false);
    final nova = Cena(
      id: novoId,
      nome: novoNome,
      ativa: true,
      inicioSegundos: tempoAtualSegundos,
    );
    return (cenaEncerrada: encerrada, novaCena: nova);
  }
}
