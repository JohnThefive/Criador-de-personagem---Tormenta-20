import 'package:t20_creator/domain/entities/combate/tipo_acao.dart';
import 'package:t20_creator/domain/entities/habilidades/modelos_habilidade_duracao.dart';
import 'package:t20_creator/domain/entities/testes/configuracoes_mesa_t20.dart';
import 'package:t20_creator/domain/entities/testes/modelos_teste_t20.dart';
import 'package:t20_creator/domain/services/habilidades_services/pm_service.dart';
import 'package:t20_creator/domain/services/habilidades_services/relogio_e_cena_service.dart';

/// Resultado de operações de ciclo de vida processadas pela [DuracaoEngine].
class ResultadoCicloDuracao {
  final List<EfeitoAtivo> efeitos;
  final Map<String, AreaPersistente> areasPersistentes;
  final Map<String, EstadoPersonagemHabilidade> personagens;
  final RelogioDeJogo relogio;
  final Cena cenaAtual;
  final Map<String, SustentacaoPendente> sustentacoesPendentesPorUsuario;
  final Set<String> paresHabilidadeEventoConsumidos;
  final List<Map<String, dynamic>> eventosGerados;
  final List<String> logs;

  const ResultadoCicloDuracao({
    required this.efeitos,
    required this.areasPersistentes,
    required this.personagens,
    required this.relogio,
    required this.cenaAtual,
    required this.sustentacoesPendentesPorUsuario,
    required this.paresHabilidadeEventoConsumidos,
    this.eventosGerados = const [],
    this.logs = const [],
  });
}

/// R38–R48: Motor puro de ciclo de vida das durações (`INSTANTANEA`, `CENA`,
/// `SUSTENTADA`, `DEFINIDA`, `PERMANENTE` e modificador `descarregar`).
class DuracaoEngine {
  final ConfiguracoesMesaT20 configuracoes;
  final PMService _pmService;
  final CenaService _cenaService;

  const DuracaoEngine({
    this.configuracoes = const ConfiguracoesMesaT20(),
    PMService? pmService,
    CenaService? cenaService,
  })  : _pmService = pmService ?? const PMService(),
        _cenaService = cenaService ?? const CenaService();

  /// Cria um novo [EfeitoAtivo] (para durações não-instantâneas), tratando a regra R48
  /// de substituição caso a mesma habilidade seja reativada pelo mesmo usuário sobre o mesmo alvo.
  ({
    List<EfeitoAtivo> efeitosAtualizados,
    EfeitoAtivo novoEfeito,
    List<EfeitoAtivo> substituidos,
    Map<String, EstadoPersonagemHabilidade> personagensAtualizados,
    Map<String, AreaPersistente> areasAtualizadas,
    List<Map<String, dynamic>> eventos,
    List<String> logs,
  }) registrarNovoEfeito({
    required String novoEfeitoId,
    required Habilidade habilidade,
    required String usuarioId,
    required List<String> alvosAfetados,
    String? areaPersistenteId,
    required RelogioDeJogo relogio,
    required Cena cenaAtual,
    required List<EfeitoAtivo> efeitosExistentes,
    required Map<String, EstadoPersonagemHabilidade> personagens,
    required Map<String, AreaPersistente> areasPersistentes,
    Map<String, ResultadoResistencia>? historicoResistencia,
    Set<String>? desacreditadoPor,
  }) {
    final listaEfeitos = List<EfeitoAtivo>.from(efeitosExistentes);
    final mapaPersonagens =
        Map<String, EstadoPersonagemHabilidade>.from(personagens);
    final mapaAreas = Map<String, AreaPersistente>.from(areasPersistentes);
    final substituidos = <EfeitoAtivo>[];
    final eventos = <Map<String, dynamic>>[];
    final logs = <String>[];

    // R48 (Caso de Borda 33): Reativação pelo mesmo usuário sobre o MESMO alvo substitui a anterior
    if (configuracoes.reativarMesmoAlvoSubstituiAnterior &&
        alvosAfetados.isNotEmpty) {
      final conjuntoAlvosNovo = alvosAfetados.toSet();
      for (int i = 0; i < listaEfeitos.length; i++) {
        final ef = listaEfeitos[i];
        if (!ef.estaEmJogo) continue;
        if (ef.habilidadeId == habilidade.id && ef.usuarioId == usuarioId) {
          final conjuntoAntigo = ef.alvos.toSet();
          if (conjuntoAntigo.length == conjuntoAlvosNovo.length &&
              conjuntoAntigo.containsAll(conjuntoAlvosNovo)) {
            final encerrado = _finalizarEfeitoInterno(
              efeito: ef,
              novoEstado: EstadoEfeito.encerrado,
              motivo: MotivoFimEfeito.substituido,
              personagens: mapaPersonagens,
              areasPersistentes: mapaAreas,
              eventos: eventos,
              logs: logs,
            );
            listaEfeitos[i] = encerrado;
            substituidos.add(encerrado);
          }
        }
      }
    }

    // Calcula tempos de expiração para DEFINIDA (R42)
    int? expiraEmSegundos;
    int? expiraNaRodada;
    if (habilidade.duracao.tipo == TipoDuracao.definida &&
        habilidade.duracao.definida != null) {
      final def = habilidade.duracao.definida!;
      expiraEmSegundos = relogio.tempoSegundos +
          def.paraSegundos(segundosPorRodada: configuracoes.segundosPorRodada);
      if (def.unidade == UnidadeDuracao.rodada) {
        expiraNaRodada = relogio.rodadaAtual + def.quantidade;
      }
    }

    // R45 (Caso de Borda 30): Se possui `descarregar`, nasce DORMENTE sem aplicar modificadores ainda
    final nasceDormente = habilidade.duracao.descarregar != null;
    final estadoInicial =
        nasceDormente ? EstadoEfeito.dormente : EstadoEfeito.ativo;

    final modsInstanciados = <ModificadorAplicado>[];
    for (final alvoId in alvosAfetados) {
      for (final molde in habilidade.modificadoresGerados) {
        modsInstanciados.add(
          molde.copyWith(
            efeitoId: novoEfeitoId,
            alvoId: alvoId,
            aplicado: true,
          ),
        );
      }
    }

    final novoEfeito = EfeitoAtivo(
      id: novoEfeitoId,
      habilidadeId: habilidade.id,
      nomeHabilidade: habilidade.nome,
      usuarioId: usuarioId,
      ehMagia: habilidade.ehMagia,
      alcance: habilidade.alcance,
      permiteRedirecionar: habilidade.permiteRedirecionar,
      alvosPermitidos: habilidade.alvosPermitidos,
      alvos: List.unmodifiable(alvosAfetados),
      areaPersistenteId: areaPersistenteId,
      duracao: habilidade.duracao,
      estado: estadoInicial,
      inicio: InicioEfeito(
        tempoSegundos: relogio.tempoSegundos,
        rodada: relogio.rodadaAtual,
        cenaId: cenaAtual.id,
      ),
      expiraEmSegundos: expiraEmSegundos,
      expiraNaRodada: expiraNaRodada,
      modificadores: List.unmodifiable(modsInstanciados),
      penalidadePMId:
          habilidade.custo.penalidadePM > 0 ? novoEfeitoId : null,
      sustentacao: habilidade.duracao.tipo == TipoDuracao.sustentada
          ? SustentacaoEfeito(
              custoPM: 1,
              pendente: false,
              rodadaAtivacao: relogio.rodadaAtual,
              turnosAtivos: 0,
            )
          : null,
      descarga: habilidade.duracao.descarregar != null
          ? DescargaEfeito(gatilho: habilidade.duracao.descarregar!.gatilho)
          : null,
      historico: [
        'Criado em t=${relogio.tempoSegundos}s (rodada ${relogio.rodadaAtual}, cena ${cenaAtual.id}) como ${estadoInicial.name}.',
      ],
      tipos: {
        ...habilidade.tiposEfeito,
        if (habilidade.tiposEfeito.contains(TipoEfeito.arcano) ||
            habilidade.tiposEfeito.contains(TipoEfeito.divino))
          TipoEfeito.magico,
      },
      ignoraReducaoDano:
          habilidade.tiposEfeito.contains(TipoEfeito.perdaDeVida),
      historicoResistencia: historicoResistencia ?? const {},
      desacreditadoPor: desacreditadoPor ?? const {},
    );

    listaEfeitos.add(novoEfeito);
    eventos.add({
      'tipo': 'EfeitoAtivado',
      'efeito': novoEfeito.toJson(),
    });
    logs.add(
      '[EFEITO] ${habilidade.nome} ($novoEfeitoId) iniciado em estado ${estadoInicial.name} (duração: ${habilidade.duracao.tipo.name}).',
    );

    return (
      efeitosAtualizados: List.unmodifiable(listaEfeitos),
      novoEfeito: novoEfeito,
      substituidos: List.unmodifiable(substituidos),
      personagensAtualizados: mapaPersonagens,
      areasAtualizadas: mapaAreas,
      eventos: eventos,
      logs: logs,
    );
  }

  /// R40 (Caso de Borda 22): Encerra a cena atual, expirando todos os efeitos de duração `CENA`,
  /// e inicia uma nova cena sem afetar efeitos de outras durações.
  ResultadoCicloDuracao encerrarCenaEIniciarNova({
    required List<EfeitoAtivo> efeitos,
    required Map<String, AreaPersistente> areasPersistentes,
    required Map<String, EstadoPersonagemHabilidade> personagens,
    required RelogioDeJogo relogio,
    required Cena cenaAtual,
    required Map<String, SustentacaoPendente> sustentacoesPendentes,
    required Set<String> paresConsumidos,
    required String novaCenaId,
    required String novaCenaNome,
  }) {
    final (:cenaEncerrada, :novaCena) = _cenaService.iniciarNovaCena(
      cenaAtual: cenaAtual,
      novoId: novaCenaId,
      novoNome: novaCenaNome,
      tempoAtualSegundos: relogio.tempoSegundos,
    );

    final listaEfeitos = List<EfeitoAtivo>.from(efeitos);
    final mapaPersonagens =
        Map<String, EstadoPersonagemHabilidade>.from(personagens);
    final mapaAreas = Map<String, AreaPersistente>.from(areasPersistentes);
    final eventos = <Map<String, dynamic>>[
      {'tipo': 'CenaEncerrada', 'cenaId': cenaEncerrada.id},
      {'tipo': 'CenaIniciada', 'cena': novaCena.toJson()},
    ];
    final logs = <String>[
      '[CENA] Cena "${cenaEncerrada.nome}" encerrada. Nova cena "${novaCena.nome}" iniciada.',
    ];

    for (int i = 0; i < listaEfeitos.length; i++) {
      final ef = listaEfeitos[i];
      if (!ef.estaEmJogo) continue;
      if (ef.duracao.tipo == TipoDuracao.cena) {
        listaEfeitos[i] = _finalizarEfeitoInterno(
          efeito: ef,
          novoEstado: EstadoEfeito.expirado,
          motivo: MotivoFimEfeito.cenaEncerrada,
          personagens: mapaPersonagens,
          areasPersistentes: mapaAreas,
          eventos: eventos,
          logs: logs,
        );
      }
    }

    return ResultadoCicloDuracao(
      efeitos: List.unmodifiable(listaEfeitos),
      areasPersistentes: Map.unmodifiable(mapaAreas),
      personagens: Map.unmodifiable(mapaPersonagens),
      relogio: relogio,
      cenaAtual: novaCena,
      sustentacoesPendentesPorUsuario: sustentacoesPendentes,
      paresHabilidadeEventoConsumidos: paresConsumidos,
      eventosGerados: List.unmodifiable(eventos),
      logs: List.unmodifiable(logs),
    );
  }

  /// R41 e R42 (Casos de Borda 23, 24, 25, 26): Processa o início do turno de `personagemId`.
  /// - Expira efeitos `DEFINIDA` em rodadas se `expiracaoRodadas == inicioTurnoDoUsuario`.
  /// - Processa cobrança/pendência de `SUSTENTADA` (1 PM fixo como ação livre).
  ResultadoCicloDuracao processarInicioTurno({
    required String personagemId,
    required int rodada,
    required List<EfeitoAtivo> efeitos,
    required Map<String, AreaPersistente> areasPersistentes,
    required Map<String, EstadoPersonagemHabilidade> personagens,
    required RelogioDeJogo relogio,
    required Cena cenaAtual,
    required Map<String, SustentacaoPendente> sustentacoesPendentes,
    required Set<String> paresConsumidos,
    required IControleDeAcoes controleDeAcoes,
    int? iniciativaTurno,
  }) {
    final listaEfeitos = List<EfeitoAtivo>.from(efeitos);
    final mapaPersonagens =
        Map<String, EstadoPersonagemHabilidade>.from(personagens);
    final mapaAreas = Map<String, AreaPersistente>.from(areasPersistentes);
    final mapaPendentes =
        Map<String, SustentacaoPendente>.from(sustentacoesPendentes);
    final eventos = <Map<String, dynamic>>[];
    final logs = <String>[];

    // 1. Expiração de DEFINIDA em rodadas (R42, R59, I2)
    if (configuracoes.expiracaoRodadas ==
        ModoExpiracaoRodadas.inicioTurnoDoUsuario) {
      for (int i = 0; i < listaEfeitos.length; i++) {
        final ef = listaEfeitos[i];
        if (!ef.estaEmJogo) continue;
        if (ef.usuarioId == personagemId &&
            ef.duracao.tipo == TipoDuracao.definida &&
            ef.duracao.definida?.unidade == UnidadeDuracao.rodada &&
            ef.expiraNaRodada != null &&
            rodada >= ef.expiraNaRodada!) {
          listaEfeitos[i] = _finalizarEfeitoInterno(
            efeito: ef,
            novoEstado: EstadoEfeito.expirado,
            motivo: MotivoFimEfeito.duracao,
            personagens: mapaPersonagens,
            areasPersistentes: mapaAreas,
            eventos: eventos,
            logs: logs,
          );
        }
      }
    } else if (configuracoes.expiracaoRodadas ==
        ModoExpiracaoRodadas.antesDaMesmaIniciativa) {
      for (int i = 0; i < listaEfeitos.length; i++) {
        final ef = listaEfeitos[i];
        if (!ef.estaEmJogo) continue;
        if (ef.duracao.tipo == TipoDuracao.definida &&
            ef.duracao.definida?.unidade == UnidadeDuracao.rodada &&
            ef.expiraNaRodada != null &&
            rodada >= ef.expiraNaRodada!) {
          final mesmaIniciativaOuTurnoUsuario =
              (ef.inicio.iniciativa != null && iniciativaTurno != null)
                  ? iniciativaTurno <= ef.inicio.iniciativa!
                  : ef.usuarioId == personagemId;
          if (mesmaIniciativaOuTurnoUsuario) {
            listaEfeitos[i] = _finalizarEfeitoInterno(
              efeito: ef,
              novoEstado: EstadoEfeito.expirado,
              motivo: MotivoFimEfeito.duracao,
              personagens: mapaPersonagens,
              areasPersistentes: mapaAreas,
              eventos: eventos,
              logs: logs,
            );
          }
        }
      }
    }

    // 2. Sustentação no início do turno do usuário (R41 / Casos 23, 24, 25)
    final idsPendentesUsuario = <String>[];
    for (int i = 0; i < listaEfeitos.length; i++) {
      final ef = listaEfeitos[i];
      if (!ef.estaEmJogo) continue;
      if (ef.usuarioId != personagemId ||
          ef.duracao.tipo != TipoDuracao.sustentada ||
          ef.sustentacao == null ||
          rodada <= ef.sustentacao!.rodadaAtivacao) {
        continue;
      }

      final personagem = mapaPersonagens[personagemId];
      if (personagem == null ||
          personagem.pmState.pmAtual < 1 ||
          !controleDeAcoes.temAcaoDisponivel(personagemId, TipoAcao.livre)) {
        // Sem PM ou sem ação livre -> encerra imediatamente por SUSTENTACAO_NAO_PAGA
        listaEfeitos[i] = _finalizarEfeitoInterno(
          efeito: ef,
          novoEstado: EstadoEfeito.encerrado,
          motivo: MotivoFimEfeito.sustentacaoNaoPaga,
          personagens: mapaPersonagens,
          areasPersistentes: mapaAreas,
          eventos: eventos,
          logs: logs,
        );
        continue;
      }

      if (configuracoes.sustentacaoModo == ModoSustentacao.automatico) {
        // Debita 1 PM fixo (R27 não se aplica)
        controleDeAcoes.consumirAcao(personagemId, TipoAcao.livre);
        final novoPm = personagem.pmState.copyWith(
          pmAtual: personagem.pmState.pmAtual - 1,
        );
        mapaPersonagens[personagemId] = personagem.copyWith(pmState: novoPm);
        listaEfeitos[i] = ef.copyWith(
          sustentacao: ef.sustentacao!.copyWith(
            pendente: false,
            turnosAtivos: ef.sustentacao!.turnosAtivos + 1,
          ),
        );
        eventos.add({
          'tipo': 'SustentacaoResolvida',
          'efeitoId': ef.id,
          'usuarioId': personagemId,
          'mantida': true,
          'custoPago': 1,
        });
        logs.add(
          '[SUSTENTAÇÃO] ${ef.nomeHabilidade} (${ef.id}) mantida automaticamente por 1 PM.',
        );
      } else {
        listaEfeitos[i] = ef.copyWith(
          sustentacao: ef.sustentacao!.copyWith(pendente: true),
        );
        idsPendentesUsuario.add(ef.id);
      }
    }

    if (idsPendentesUsuario.isNotEmpty) {
      final pendencia = SustentacaoPendente(
        usuarioId: personagemId,
        efeitoIds: List.unmodifiable(idsPendentesUsuario),
      );
      mapaPendentes[personagemId] = pendencia;
      eventos.add({
        'tipo': 'SustentacaoPendente',
        'usuarioId': personagemId,
        'efeitoIds': idsPendentesUsuario,
      });
    } else {
      mapaPendentes.remove(personagemId);
    }

    return ResultadoCicloDuracao(
      efeitos: List.unmodifiable(listaEfeitos),
      areasPersistentes: Map.unmodifiable(mapaAreas),
      personagens: Map.unmodifiable(mapaPersonagens),
      relogio: relogio.copyWith(rodadaAtual: rodada),
      cenaAtual: cenaAtual,
      sustentacoesPendentesPorUsuario: Map.unmodifiable(mapaPendentes),
      paresHabilidadeEventoConsumidos: paresConsumidos,
      eventosGerados: List.unmodifiable(eventos),
      logs: List.unmodifiable(logs),
    );
  }

  /// R41 (Casos de Borda 23, 24, 25): Resolve a decisão do jogador (ou do mestre) sobre manter
  /// ou encerrar uma habilidade sustentada pendente. Custo é sempre 1 PM fixo (R27 não se aplica).
  ResultadoCicloDuracao resolverSustentacao({
    required String efeitoId,
    required bool manter,
    required List<EfeitoAtivo> efeitos,
    required Map<String, AreaPersistente> areasPersistentes,
    required Map<String, EstadoPersonagemHabilidade> personagens,
    required RelogioDeJogo relogio,
    required Cena cenaAtual,
    required Map<String, SustentacaoPendente> sustentacoesPendentes,
    required Set<String> paresConsumidos,
    required IControleDeAcoes controleDeAcoes,
  }) {
    final listaEfeitos = List<EfeitoAtivo>.from(efeitos);
    final idx = listaEfeitos.indexWhere((e) => e.id == efeitoId);
    if (idx == -1) {
      throw RegraTesteException(
        codigo: 'EFEITO_NAO_ENCONTRADO',
        mensagem: 'Efeito sustentado $efeitoId não encontrado.',
      );
    }

    final ef = listaEfeitos[idx];
    final usuarioId = ef.usuarioId;
    final mapaPersonagens =
        Map<String, EstadoPersonagemHabilidade>.from(personagens);
    final mapaAreas = Map<String, AreaPersistente>.from(areasPersistentes);
    final mapaPendentes =
        Map<String, SustentacaoPendente>.from(sustentacoesPendentes);
    final eventos = <Map<String, dynamic>>[];
    final logs = <String>[];

    final personagem = mapaPersonagens[usuarioId];
    if (!manter ||
        personagem == null ||
        personagem.pmState.pmAtual < 1 ||
        !controleDeAcoes.temAcaoDisponivel(usuarioId, TipoAcao.livre)) {
      listaEfeitos[idx] = _finalizarEfeitoInterno(
        efeito: ef,
        novoEstado: EstadoEfeito.encerrado,
        motivo: MotivoFimEfeito.sustentacaoNaoPaga,
        personagens: mapaPersonagens,
        areasPersistentes: mapaAreas,
        eventos: eventos,
        logs: logs,
      );
      eventos.add({
        'tipo': 'SustentacaoResolvida',
        'efeitoId': ef.id,
        'usuarioId': usuarioId,
        'mantida': false,
        'custoPago': 0,
      });
    } else {
      // Paga exatamente 1 PM como ação livre (sem reduções de R27)
      controleDeAcoes.consumirAcao(usuarioId, TipoAcao.livre);
      final novoPmState = personagem.pmState.copyWith(
        pmAtual: personagem.pmState.pmAtual - 1,
      );
      mapaPersonagens[usuarioId] = personagem.copyWith(pmState: novoPmState);
      listaEfeitos[idx] = ef.copyWith(
        sustentacao: ef.sustentacao!.copyWith(
          pendente: false,
          turnosAtivos: ef.sustentacao!.turnosAtivos + 1,
        ),
      );
      eventos.add({
        'tipo': 'SustentacaoResolvida',
        'efeitoId': ef.id,
        'usuarioId': usuarioId,
        'mantida': true,
        'custoPago': 1,
      });
      eventos.add({
        'tipo': 'PMAtualizado',
        'personagemId': usuarioId,
        'pmState': novoPmState.toJson(),
      });
      logs.add('[SUSTENTAÇÃO] ${ef.nomeHabilidade} (${ef.id}) mantida por 1 PM.');
    }

    // Atualiza a lista de pendências do usuário; se o PM acabou (== 0), encerra as restantes!
    final pendenciaAtual = mapaPendentes[usuarioId];
    if (pendenciaAtual != null) {
      final restantes =
          pendenciaAtual.efeitoIds.where((id) => id != efeitoId).toList();
      final pmRestante = mapaPersonagens[usuarioId]?.pmState.pmAtual ?? 0;

      if (pmRestante < 1 && restantes.isNotEmpty) {
        for (final idRest in restantes) {
          final iRest = listaEfeitos.indexWhere((e) => e.id == idRest);
          if (iRest != -1 && listaEfeitos[iRest].estaEmJogo) {
            listaEfeitos[iRest] = _finalizarEfeitoInterno(
              efeito: listaEfeitos[iRest],
              novoEstado: EstadoEfeito.encerrado,
              motivo: MotivoFimEfeito.sustentacaoNaoPaga,
              personagens: mapaPersonagens,
              areasPersistentes: mapaAreas,
              eventos: eventos,
              logs: logs,
            );
          }
        }
        mapaPendentes.remove(usuarioId);
      } else if (restantes.isEmpty) {
        mapaPendentes.remove(usuarioId);
      } else {
        mapaPendentes[usuarioId] = SustentacaoPendente(
          usuarioId: usuarioId,
          efeitoIds: List.unmodifiable(restantes),
        );
      }
    }

    return ResultadoCicloDuracao(
      efeitos: List.unmodifiable(listaEfeitos),
      areasPersistentes: Map.unmodifiable(mapaAreas),
      personagens: Map.unmodifiable(mapaPersonagens),
      relogio: relogio,
      cenaAtual: cenaAtual,
      sustentacoesPendentesPorUsuario: Map.unmodifiable(mapaPendentes),
      paresHabilidadeEventoConsumidos: paresConsumidos,
      eventosGerados: List.unmodifiable(eventos),
      logs: List.unmodifiable(logs),
    );
  }

  /// R42 (Caso de Borda 26): Avança a rodada do combate (`RodadaAvancada`),
  /// avançando 6s no relógio e expirando efeitos `DEFINIDA` em rodadas se `VIRADA_DE_RODADA`.
  ResultadoCicloDuracao processarAvancoDeRodada({
    required int novaRodada,
    required List<EfeitoAtivo> efeitos,
    required Map<String, AreaPersistente> areasPersistentes,
    required Map<String, EstadoPersonagemHabilidade> personagens,
    required RelogioDeJogo relogio,
    required Cena cenaAtual,
    required Map<String, SustentacaoPendente> sustentacoesPendentes,
    required Set<String> paresConsumidos,
  }) {
    final novoTempo = relogio.tempoSegundos + configuracoes.segundosPorRodada;
    final novoRelogio = relogio.copyWith(
      tempoSegundos: novoTempo,
      rodadaAtual: novaRodada,
    );

    final listaEfeitos = List<EfeitoAtivo>.from(efeitos);
    final mapaPersonagens =
        Map<String, EstadoPersonagemHabilidade>.from(personagens);
    final mapaAreas = Map<String, AreaPersistente>.from(areasPersistentes);
    final eventos = <Map<String, dynamic>>[
      {
        'tipo': 'TempoAvancado',
        'tempoSegundos': novoTempo,
        'rodadaAtual': novaRodada,
      },
    ];
    final logs = <String>[];

    if (configuracoes.expiracaoRodadas == ModoExpiracaoRodadas.viradaDeRodada) {
      for (int i = 0; i < listaEfeitos.length; i++) {
        final ef = listaEfeitos[i];
        if (!ef.estaEmJogo) continue;
        if (ef.duracao.tipo == TipoDuracao.definida &&
            ef.duracao.definida?.unidade == UnidadeDuracao.rodada &&
            ef.expiraNaRodada != null &&
            novaRodada >= ef.expiraNaRodada!) {
          listaEfeitos[i] = _finalizarEfeitoInterno(
            efeito: ef,
            novoEstado: EstadoEfeito.expirado,
            motivo: MotivoFimEfeito.duracao,
            personagens: mapaPersonagens,
            areasPersistentes: mapaAreas,
            eventos: eventos,
            logs: logs,
          );
        }
      }
    }

    return ResultadoCicloDuracao(
      efeitos: List.unmodifiable(listaEfeitos),
      areasPersistentes: Map.unmodifiable(mapaAreas),
      personagens: Map.unmodifiable(mapaPersonagens),
      relogio: novoRelogio,
      cenaAtual: cenaAtual,
      sustentacoesPendentesPorUsuario: sustentacoesPendentes,
      paresHabilidadeEventoConsumidos: paresConsumidos,
      eventosGerados: List.unmodifiable(eventos),
      logs: List.unmodifiable(logs),
    );
  }

  /// R42 e R43 (Casos de Borda 27 e 28): Avança o relógio de jogo em `segundos`
  /// e processa todas as expirações de durações `DEFINIDA` em ordem cronológica estrita!
  /// Efeitos `PERMANENTE` nunca expiram por avanço de tempo.
  ResultadoCicloDuracao avancarTempoSegundos({
    required int deltaSegundos,
    required List<EfeitoAtivo> efeitos,
    required Map<String, AreaPersistente> areasPersistentes,
    required Map<String, EstadoPersonagemHabilidade> personagens,
    required RelogioDeJogo relogio,
    required Cena cenaAtual,
    required Map<String, SustentacaoPendente> sustentacoesPendentes,
    required Set<String> paresConsumidos,
  }) {
    if (deltaSegundos <= 0) {
      return ResultadoCicloDuracao(
        efeitos: efeitos,
        areasPersistentes: areasPersistentes,
        personagens: personagens,
        relogio: relogio,
        cenaAtual: cenaAtual,
        sustentacoesPendentesPorUsuario: sustentacoesPendentes,
        paresHabilidadeEventoConsumidos: paresConsumidos,
      );
    }

    final novoTempo = relogio.tempoSegundos + deltaSegundos;
    final rodadasAvancadas = deltaSegundos ~/ configuracoes.segundosPorRodada;
    final novoRelogio = relogio.copyWith(
      tempoSegundos: novoTempo,
      rodadaAtual: relogio.rodadaAtual + rodadasAvancadas,
    );

    final listaEfeitos = List<EfeitoAtivo>.from(efeitos);
    final mapaPersonagens =
        Map<String, EstadoPersonagemHabilidade>.from(personagens);
    final mapaAreas = Map<String, AreaPersistente>.from(areasPersistentes);
    final eventos = <Map<String, dynamic>>[
      {
        'tipo': 'TempoAvancado',
        'tempoSegundos': novoTempo,
        'rodadaAtual': novoRelogio.rodadaAtual,
      },
    ];
    final logs = <String>[];

    // Coleta índices dos efeitos que devem expirar até `novoTempo` e ordena cronologicamente
    final indicesParaExpirar = <int>[];
    for (int i = 0; i < listaEfeitos.length; i++) {
      final ef = listaEfeitos[i];
      if (!ef.estaEmJogo) continue;
      if (ef.duracao.tipo == TipoDuracao.definida &&
          ef.expiraEmSegundos != null &&
          ef.expiraEmSegundos! <= novoTempo) {
        indicesParaExpirar.add(i);
      }
    }

    indicesParaExpirar.sort(
      (a, b) => listaEfeitos[a]
          .expiraEmSegundos!
          .compareTo(listaEfeitos[b].expiraEmSegundos!),
    );

    for (final idx in indicesParaExpirar) {
      listaEfeitos[idx] = _finalizarEfeitoInterno(
        efeito: listaEfeitos[idx],
        novoEstado: EstadoEfeito.expirado,
        motivo: MotivoFimEfeito.duracao,
        personagens: mapaPersonagens,
        areasPersistentes: mapaAreas,
        eventos: eventos,
        logs: logs,
      );
    }

    return ResultadoCicloDuracao(
      efeitos: List.unmodifiable(listaEfeitos),
      areasPersistentes: Map.unmodifiable(mapaAreas),
      personagens: Map.unmodifiable(mapaPersonagens),
      relogio: novoRelogio,
      cenaAtual: cenaAtual,
      sustentacoesPendentesPorUsuario: sustentacoesPendentes,
      paresHabilidadeEventoConsumidos: paresConsumidos,
      eventosGerados: List.unmodifiable(eventos),
      logs: List.unmodifiable(logs),
    );
  }

  /// R45 (Caso de Borda 30): Processa um [EventoDeJogo] para descarregar efeitos dormentes compatíveis.
  /// Garante que o mesmo par `(habilidadeId, evento.id)` não descarregue duas vezes.
  ResultadoCicloDuracao dispararGatilhoDescarga({
    required EventoDeJogo evento,
    required List<EfeitoAtivo> efeitos,
    required Map<String, AreaPersistente> areasPersistentes,
    required Map<String, EstadoPersonagemHabilidade> personagens,
    required RelogioDeJogo relogio,
    required Cena cenaAtual,
    required Map<String, SustentacaoPendente> sustentacoesPendentes,
    required Set<String> paresConsumidos,
  }) {
    final listaEfeitos = List<EfeitoAtivo>.from(efeitos);
    final mapaPersonagens =
        Map<String, EstadoPersonagemHabilidade>.from(personagens);
    final mapaAreas = Map<String, AreaPersistente>.from(areasPersistentes);
    final novosPares = Set<String>.from(paresConsumidos);
    final eventos = <Map<String, dynamic>>[];
    final logs = <String>[];

    for (int i = 0; i < listaEfeitos.length; i++) {
      final ef = listaEfeitos[i];
      if (ef.estado != EstadoEfeito.dormente || ef.descarga == null) continue;
      if (ef.descarga!.gatilho.trim().toLowerCase() !=
          evento.tipo.trim().toLowerCase()) {
        continue;
      }

      final chavePar = '${ef.habilidadeId}::${evento.id}';
      if (novosPares.contains(chavePar)) {
        logs.add(
          '[DESCARGA IGNORADA] Evento ${evento.id} já foi consumido pela habilidade ${ef.habilidadeId}.',
        );
        continue;
      }

      novosPares.add(chavePar);
      final efComEvento = ef.copyWith(
        descarga: ef.descarga!.copyWith(eventoConsumidoId: evento.id),
      );
      listaEfeitos[i] = _finalizarEfeitoInterno(
        efeito: efComEvento,
        novoEstado: EstadoEfeito.descarregado,
        motivo: MotivoFimEfeito.descarga,
        personagens: mapaPersonagens,
        areasPersistentes: mapaAreas,
        eventos: eventos,
        logs: logs,
      );
      eventos.add({
        'tipo': 'DescargaDisparada',
        'efeitoId': ef.id,
        'habilidadeId': ef.habilidadeId,
        'eventoId': evento.id,
        'alvos': ef.alvos,
      });
    }

    return ResultadoCicloDuracao(
      efeitos: List.unmodifiable(listaEfeitos),
      areasPersistentes: Map.unmodifiable(mapaAreas),
      personagens: Map.unmodifiable(mapaPersonagens),
      relogio: relogio,
      cenaAtual: cenaAtual,
      sustentacoesPendentesPorUsuario: sustentacoesPendentes,
      paresHabilidadeEventoConsumidos: Set.unmodifiable(novosPares),
      eventosGerados: List.unmodifiable(eventos),
      logs: List.unmodifiable(logs),
    );
  }

  /// R43 e R46 (Casos de Borda 28 e 31): Encerra um efeito ativo por solicitação do usuário (dono) ou do mestre.
  /// O alvo NÃO pode encerrar o efeito. Libera a penalidade de PM sem aumentar `pmAtual`.
  ResultadoCicloDuracao encerrarEfeito({
    required String efeitoId,
    required String solicitanteId,
    bool ehMestre = false,
    MotivoFimEfeito? motivoCustom,
    required List<EfeitoAtivo> efeitos,
    required Map<String, AreaPersistente> areasPersistentes,
    required Map<String, EstadoPersonagemHabilidade> personagens,
    required RelogioDeJogo relogio,
    required Cena cenaAtual,
    required Map<String, SustentacaoPendente> sustentacoesPendentes,
    required Set<String> paresConsumidos,
    required IControleDeAcoes controleDeAcoes,
  }) {
    final listaEfeitos = List<EfeitoAtivo>.from(efeitos);
    final idx = listaEfeitos.indexWhere((e) => e.id == efeitoId);
    if (idx == -1) {
      throw RegraTesteException(
        codigo: 'EFEITO_NAO_ENCONTRADO',
        mensagem: 'Efeito $efeitoId não encontrado.',
      );
    }

    final ef = listaEfeitos[idx];
    if (!ehMestre && ef.usuarioId != solicitanteId) {
      throw RegraTesteException(
        codigo: 'PERMISSAO_NEGADA_ENCERRAR_EFEITO',
        mensagem:
            'Apenas o usuário dono (${ef.usuarioId}) ou o Mestre podem encerrar este efeito (solicitante: $solicitanteId).',
      );
    }

    if (!ehMestre) {
      if (!controleDeAcoes.temAcaoDisponivel(solicitanteId, TipoAcao.livre)) {
        throw const RegraTesteException(
          codigo: 'ACAO_LIVRE_INDISPONIVEL',
          mensagem: 'Encerrar uma habilidade exige uma Ação Livre.',
        );
      }
      controleDeAcoes.consumirAcao(solicitanteId, TipoAcao.livre);
    }

    final mapaPersonagens =
        Map<String, EstadoPersonagemHabilidade>.from(personagens);
    final mapaAreas = Map<String, AreaPersistente>.from(areasPersistentes);
    final eventos = <Map<String, dynamic>>[];
    final logs = <String>[];

    final motivo = motivoCustom ??
        (ehMestre ? MotivoFimEfeito.mestre : MotivoFimEfeito.usuario);

    listaEfeitos[idx] = _finalizarEfeitoInterno(
      efeito: ef,
      novoEstado: EstadoEfeito.encerrado,
      motivo: motivo,
      personagens: mapaPersonagens,
      areasPersistentes: mapaAreas,
      eventos: eventos,
      logs: logs,
    );

    return ResultadoCicloDuracao(
      efeitos: List.unmodifiable(listaEfeitos),
      areasPersistentes: Map.unmodifiable(mapaAreas),
      personagens: Map.unmodifiable(mapaPersonagens),
      relogio: relogio,
      cenaAtual: cenaAtual,
      sustentacoesPendentesPorUsuario: sustentacoesPendentes,
      paresHabilidadeEventoConsumidos: paresConsumidos,
      eventosGerados: List.unmodifiable(eventos),
      logs: List.unmodifiable(logs),
    );
  }

  /// R47 (Caso de Borda 32): A morte de um personagem encerra APENAS suas habilidades `SUSTENTADA`
  /// (`motivoFim = MORTE_DO_USUARIO`). Efeitos de `CENA`, `DEFINIDA` e `PERMANENTE` continuam!
  ResultadoCicloDuracao processarMortePersonagem({
    required String personagemId,
    required List<EfeitoAtivo> efeitos,
    required Map<String, AreaPersistente> areasPersistentes,
    required Map<String, EstadoPersonagemHabilidade> personagens,
    required RelogioDeJogo relogio,
    required Cena cenaAtual,
    required Map<String, SustentacaoPendente> sustentacoesPendentes,
    required Set<String> paresConsumidos,
  }) {
    final listaEfeitos = List<EfeitoAtivo>.from(efeitos);
    final mapaPersonagens =
        Map<String, EstadoPersonagemHabilidade>.from(personagens);
    final mapaAreas = Map<String, AreaPersistente>.from(areasPersistentes);
    final mapaPendentes =
        Map<String, SustentacaoPendente>.from(sustentacoesPendentes);
    final eventos = <Map<String, dynamic>>[];
    final logs = <String>[];

    if (mapaPersonagens.containsKey(personagemId)) {
      mapaPersonagens[personagemId] =
          mapaPersonagens[personagemId]!.copyWith(vivo: false);
    }
    mapaPendentes.remove(personagemId);

    for (int i = 0; i < listaEfeitos.length; i++) {
      final ef = listaEfeitos[i];
      if (!ef.estaEmJogo) continue;
      if (ef.usuarioId == personagemId &&
          ef.duracao.tipo == TipoDuracao.sustentada) {
        listaEfeitos[i] = _finalizarEfeitoInterno(
          efeito: ef,
          novoEstado: EstadoEfeito.encerrado,
          motivo: MotivoFimEfeito.morteDoUsuario,
          personagens: mapaPersonagens,
          areasPersistentes: mapaAreas,
          eventos: eventos,
          logs: logs,
        );
      }
    }

    return ResultadoCicloDuracao(
      efeitos: List.unmodifiable(listaEfeitos),
      areasPersistentes: Map.unmodifiable(mapaAreas),
      personagens: Map.unmodifiable(mapaPersonagens),
      relogio: relogio,
      cenaAtual: cenaAtual,
      sustentacoesPendentesPorUsuario: Map.unmodifiable(mapaPendentes),
      paresHabilidadeEventoConsumidos: paresConsumidos,
      eventosGerados: List.unmodifiable(eventos),
      logs: List.unmodifiable(logs),
    );
  }

  // ===========================================================================
  // AUXILIAR PRIVADO DE ENCERRAMENTO / EXPIRAÇÃO / DESCARGA
  // ===========================================================================

  EfeitoAtivo _finalizarEfeitoInterno({
    required EfeitoAtivo efeito,
    required EstadoEfeito novoEstado,
    required MotivoFimEfeito motivo,
    required Map<String, EstadoPersonagemHabilidade> personagens,
    required Map<String, AreaPersistente> areasPersistentes,
    required List<Map<String, dynamic>> eventos,
    required List<String> logs,
  }) {
    // 1. Libera penalidade de PM associada (R28 e R46: pmMax volta, pmAtual não sobe)
    if (efeito.penalidadePMId != null &&
        personagens.containsKey(efeito.usuarioId)) {
      final dono = personagens[efeito.usuarioId]!;
      final novoPm = _pmService.liberarPenalidadePM(
        dono.pmState,
        efeito.penalidadePMId!,
      );
      personagens[efeito.usuarioId] = dono.copyWith(pmState: novoPm);
      eventos.add({
        'tipo': 'PMAtualizado',
        'personagemId': efeito.usuarioId,
        'pmState': novoPm.toJson(),
      });
    }

    // 2. Remove área persistente e emite AlvoSaiuDaArea para todos que estavam dentro (R44)
    if (efeito.areaPersistenteId != null &&
        areasPersistentes.containsKey(efeito.areaPersistenteId)) {
      final areaRemovida = areasPersistentes.remove(efeito.areaPersistenteId)!;
      for (final alvoId in areaRemovida.alvosDentro) {
        eventos.add({
          'tipo': 'AlvoSaiuDaArea',
          'areaId': areaRemovida.id,
          'efeitoId': efeito.id,
          'alvoId': alvoId,
        });
      }
    }

    final atualizado = efeito.copyWith(
      estado: novoEstado,
      motivoFim: motivo,
      historico: List.unmodifiable([
        ...efeito.historico,
        'Finalizado como ${novoEstado.name} (motivo: ${motivo.name}).',
      ]),
    );

    eventos.add({
      'tipo': 'EfeitoEncerrado',
      'efeitoId': efeito.id,
      'estado': novoEstado.name,
      'motivo': motivo.name,
    });
    logs.add(
      '[FIM DE EFEITO] ${efeito.nomeHabilidade} (${efeito.id}) -> ${novoEstado.name} (motivo: ${motivo.name}).',
    );

    return atualizado;
  }
}
