import 'dart:convert';
import 'dart:io';

import 'package:t20_creator/domain/entities/combate/grid_tatico.dart';
import 'package:t20_creator/domain/entities/combate/tipo_acao.dart';
import 'package:t20_creator/domain/entities/habilidades/modelos_habilidade_duracao.dart';
import 'package:t20_creator/domain/entities/testes/configuracoes_mesa_t20.dart';
import 'package:t20_creator/domain/entities/testes/modelos_teste_t20.dart';
import 'package:t20_creator/domain/services/habilidades_services/area_persistente_tracker.dart';
import 'package:t20_creator/domain/services/habilidades_services/duracao_engine.dart';
import 'package:t20_creator/domain/services/habilidades_services/geometria_grid.dart';
import 'package:t20_creator/domain/services/habilidades_services/imunidade_service.dart';
import 'package:t20_creator/domain/services/habilidades_services/modificador_engine.dart';
import 'package:t20_creator/domain/services/habilidades_services/pm_service.dart';
import 'package:t20_creator/domain/services/habilidades_services/relogio_e_cena_service.dart';
import 'package:t20_creator/domain/services/habilidades_services/resistencia_service.dart';
import 'package:t20_creator/domain/services/testes_services/i_rng.dart';
import 'package:t20_creator/domain/services/testes_services/motor_testes_service.dart';

/// Estado completo e persistível do Módulo 2 e 3 (Habilidades, Efeitos, Áreas, Relógio, Cena, PM, Criaturas e Objetos).
/// Usado pelo Host (Mestre) para salvar/restaurar em disco (Caso 36) e enviar snapshot de reconexão (Caso 35).
class EstadoMundoHabilidades {
  final ConfiguracoesMesaT20 configuracoes;
  final RelogioDeJogo relogio;
  final Cena cenaAtual;
  final Map<String, EstadoPersonagemHabilidade> personagens;
  final Map<String, AlvoMapa> alvosNoMapa;
  final List<Barreira> barreiras;
  final List<EfeitoAtivo> efeitos;
  final Map<String, AreaPersistente> areasPersistentes;
  final Map<String, SustentacaoPendente> sustentacoesPendentes;
  final Set<String> paresHabilidadeEventoConsumidos;
  final Map<String, Habilidade> catalogoHabilidades;

  // --- MÓDULO 3: CRIATURAS E OBJETOS ---
  final Map<String, Criatura> criaturas;
  final Map<String, ItemObjeto> itensNoMapa;

  const EstadoMundoHabilidades({
    this.configuracoes = const ConfiguracoesMesaT20(),
    this.relogio = const RelogioDeJogo(),
    this.cenaAtual = const Cena(id: 'cena_1', nome: 'Cena Inicial'),
    this.personagens = const {},
    this.alvosNoMapa = const {},
    this.barreiras = const [],
    this.efeitos = const [],
    this.areasPersistentes = const {},
    this.sustentacoesPendentes = const {},
    this.paresHabilidadeEventoConsumidos = const {},
    this.catalogoHabilidades = const {},
    this.criaturas = const {},
    this.itensNoMapa = const {},
  });

  /// IDs de todos os efeitos atualmente em estado `ATIVO` (para R49).
  Set<String> get efeitosAtivosIds => efeitos
      .where((e) => e.estado == EstadoEfeito.ativo)
      .map((e) => e.id)
      .toSet();

  EstadoMundoHabilidades copyWith({
    ConfiguracoesMesaT20? configuracoes,
    RelogioDeJogo? relogio,
    Cena? cenaAtual,
    Map<String, EstadoPersonagemHabilidade>? personagens,
    Map<String, AlvoMapa>? alvosNoMapa,
    List<Barreira>? barreiras,
    List<EfeitoAtivo>? efeitos,
    Map<String, AreaPersistente>? areasPersistentes,
    Map<String, SustentacaoPendente>? sustentacoesPendentes,
    Set<String>? paresHabilidadeEventoConsumidos,
    Map<String, Habilidade>? catalogoHabilidades,
    Map<String, Criatura>? criaturas,
    Map<String, ItemObjeto>? itensNoMapa,
  }) {
    return EstadoMundoHabilidades(
      configuracoes: configuracoes ?? this.configuracoes,
      relogio: relogio ?? this.relogio,
      cenaAtual: cenaAtual ?? this.cenaAtual,
      personagens: personagens ?? this.personagens,
      alvosNoMapa: alvosNoMapa ?? this.alvosNoMapa,
      barreiras: barreiras ?? this.barreiras,
      efeitos: efeitos ?? this.efeitos,
      areasPersistentes: areasPersistentes ?? this.areasPersistentes,
      sustentacoesPendentes:
          sustentacoesPendentes ?? this.sustentacoesPendentes,
      paresHabilidadeEventoConsumidos: paresHabilidadeEventoConsumidos ??
          this.paresHabilidadeEventoConsumidos,
      catalogoHabilidades: catalogoHabilidades ?? this.catalogoHabilidades,
      criaturas: criaturas ?? this.criaturas,
      itensNoMapa: itensNoMapa ?? this.itensNoMapa,
    );
  }

  Map<String, dynamic> toJson() => {
        'configuracoes': configuracoes.toJson(),
        'relogio': relogio.toJson(),
        'cenaAtual': cenaAtual.toJson(),
        'personagens': personagens.map((k, v) => MapEntry(k, v.toJson())),
        'alvosNoMapa': alvosNoMapa.map((k, v) => MapEntry(k, v.toJson())),
        'barreiras': barreiras.map((b) => b.toJson()).toList(),
        'efeitos': efeitos.map((e) => e.toJson()).toList(),
        'areasPersistentes':
            areasPersistentes.map((k, v) => MapEntry(k, v.toJson())),
        'sustentacoesPendentes':
            sustentacoesPendentes.map((k, v) => MapEntry(k, v.toJson())),
        'paresHabilidadeEventoConsumidos':
            paresHabilidadeEventoConsumidos.toList(),
        'catalogoHabilidades':
            catalogoHabilidades.map((k, v) => MapEntry(k, v.toJson())),
        'criaturas': criaturas.map((k, v) => MapEntry(k, v.toJson())),
        'itensNoMapa': itensNoMapa.map((k, v) => MapEntry(k, v.toJson())),
      };

  String toJsonString() => jsonEncode(toJson());

  factory EstadoMundoHabilidades.fromJson(Map<String, dynamic> json) {
    return EstadoMundoHabilidades(
      configuracoes: json['configuracoes'] != null
          ? ConfiguracoesMesaT20.fromJson(
              json['configuracoes'] as Map<String, dynamic>,
            )
          : const ConfiguracoesMesaT20(),
      relogio: json['relogio'] != null
          ? RelogioDeJogo.fromJson(json['relogio'] as Map<String, dynamic>)
          : const RelogioDeJogo(),
      cenaAtual: json['cenaAtual'] != null
          ? Cena.fromJson(json['cenaAtual'] as Map<String, dynamic>)
          : const Cena(id: 'cena_1', nome: 'Cena Inicial'),
      personagens: (json['personagens'] as Map<String, dynamic>? ?? {}).map(
        (k, v) => MapEntry(
          k,
          EstadoPersonagemHabilidade.fromJson(v as Map<String, dynamic>),
        ),
      ),
      alvosNoMapa: (json['alvosNoMapa'] as Map<String, dynamic>? ?? {}).map(
        (k, v) => MapEntry(k, AlvoMapa.fromJson(v as Map<String, dynamic>)),
      ),
      barreiras: (json['barreiras'] as List<dynamic>? ?? [])
          .map((e) => Barreira.fromJson(e as Map<String, dynamic>))
          .toList(),
      efeitos: (json['efeitos'] as List<dynamic>? ?? [])
          .map((e) => EfeitoAtivo.fromJson(e as Map<String, dynamic>))
          .toList(),
      areasPersistentes:
          (json['areasPersistentes'] as Map<String, dynamic>? ?? {}).map(
        (k, v) => MapEntry(
          k,
          AreaPersistente.fromJson(v as Map<String, dynamic>),
        ),
      ),
      sustentacoesPendentes:
          (json['sustentacoesPendentes'] as Map<String, dynamic>? ?? {}).map(
        (k, v) => MapEntry(
          k,
          SustentacaoPendente.fromJson(v as Map<String, dynamic>),
        ),
      ),
      paresHabilidadeEventoConsumidos:
          (json['paresHabilidadeEventoConsumidos'] as List<dynamic>? ?? [])
              .map((e) => e as String)
              .toSet(),
      catalogoHabilidades:
          (json['catalogoHabilidades'] as Map<String, dynamic>? ?? {}).map(
        (k, v) => MapEntry(k, Habilidade.fromJson(v as Map<String, dynamic>)),
      ),
      criaturas: (json['criaturas'] as Map<String, dynamic>? ?? {}).map(
        (k, v) => MapEntry(k, Criatura.fromJson(v as Map<String, dynamic>)),
      ),
      itensNoMapa: (json['itensNoMapa'] as Map<String, dynamic>? ?? {}).map(
        (k, v) => MapEntry(k, ItemObjeto.fromJson(v as Map<String, dynamic>)),
      ),
    );
  }

  factory EstadoMundoHabilidades.fromJsonString(String raw) {
    return EstadoMundoHabilidades.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  /// Caso de Borda 36: Salva o estado do host em disco.
  Future<void> salvarEmDisco(String caminhoArquivo) async {
    final file = File(caminhoArquivo);
    await file.parent.create(recursive: true);
    await file.writeAsString(toJsonString());
  }

  /// Caso de Borda 36: Restaura o estado do host a partir do disco.
  static Future<EstadoMundoHabilidades> restaurarDeDisco(
    String caminhoArquivo,
  ) async {
    final file = File(caminhoArquivo);
    final raw = await file.readAsString();
    return EstadoMundoHabilidades.fromJsonString(raw);
  }
}

/// R22–R49: Orquestrador puro do pipeline de ativação de habilidades, áreas persistentes e durações.
class HabilidadeEngine {
  final IRng _rng;
  final ConfiguracoesMesaT20 configuracoes;
  final ModificadorEngine modificadorEngine;
  final PMService pmService;
  final GeometriaGrid geometriaGrid;
  final DuracaoEngine duracaoEngine;
  final AreaPersistenteTracker areaTracker;
  final MotorTestesService motorTestes;
  final ImunidadeService imunidadeService;
  final ResistenciaService resistenciaService;
  int _contadorEfeitos = 0;

  HabilidadeEngine({
    required IRng rng,
    this.configuracoes = const ConfiguracoesMesaT20(),
  })  : _rng = rng,
        modificadorEngine = ModificadorEngine(configuracoes: configuracoes),
        pmService = PMService(configuracoes: configuracoes),
        geometriaGrid = GeometriaGrid(configuracoes: configuracoes),
        duracaoEngine = DuracaoEngine(
          configuracoes: configuracoes,
          pmService: PMService(configuracoes: configuracoes),
        ),
        areaTracker = AreaPersistenteTracker(
          geometria: GeometriaGrid(configuracoes: configuracoes),
        ),
        motorTestes = MotorTestesService(
          rng: rng,
          configuracoes: configuracoes,
        ),
        imunidadeService = ImunidadeService(configuracoes: configuracoes),
        resistenciaService = ResistenciaService(
          rng: rng,
          configuracoes: configuracoes,
          motorTestes: MotorTestesService(rng: rng, configuracoes: configuracoes),
          imunidadeService: ImunidadeService(configuracoes: configuracoes),
        );

  /// R23 (Caso de Borda 2): Emite `GatilhoDisponivel` para habilidades engatilhadas compatíveis
  /// que ainda não consumiram `evento.id`, e dispara descargas automáticas (R45).
  ({
    EstadoMundoHabilidades mundoAtualizado,
    List<Map<String, dynamic>> eventosGerados,
  }) emitirEventoDeJogo({
    required EstadoMundoHabilidades mundo,
    required EventoDeJogo evento,
    required Map<String, List<Habilidade>> habilidadesPorPersonagem,
  }) {
    final eventos = <Map<String, dynamic>>[
      {'tipo': 'EventoDeJogo', 'evento': evento.toJson()},
    ];

    // Verifica habilidades engatilhadas disponíveis para os personagens (R23)
    for (final entry in habilidadesPorPersonagem.entries) {
      final pId = entry.key;
      for (final hab in entry.value) {
        if (!hab.ehEngatilhada) continue;
        if (hab.gatilho!.trim().toLowerCase() !=
            evento.tipo.trim().toLowerCase()) {
          continue;
        }
        final chavePar = '${hab.id}::${evento.id}';
        if (!mundo.paresHabilidadeEventoConsumidos.contains(chavePar)) {
          eventos.add({
            'tipo': 'GatilhoDisponivel',
            'personagemId': pId,
            'habilidadeId': hab.id,
            'eventoId': evento.id,
          });
        }
      }
    }

    // Se descargaModo == automatica, dispara descargas dormentes compatíveis (R45)
    var mundoNovo = mundo;
    if (configuracoes.descargaModo == ModoDescarga.automatica) {
      final ciclo = duracaoEngine.dispararGatilhoDescarga(
        evento: evento,
        efeitos: mundo.efeitos,
        areasPersistentes: mundo.areasPersistentes,
        personagens: mundo.personagens,
        relogio: mundo.relogio,
        cenaAtual: mundo.cenaAtual,
        sustentacoesPendentes: mundo.sustentacoesPendentes,
        paresConsumidos: mundo.paresHabilidadeEventoConsumidos,
      );
      mundoNovo = mundo.copyWith(
        efeitos: ciclo.efeitos,
        areasPersistentes: ciclo.areasPersistentes,
        personagens: ciclo.personagens,
        paresHabilidadeEventoConsumidos: ciclo.paresHabilidadeEventoConsumidos,
      );
      eventos.addAll(ciclo.eventosGerados);
    }

    return (mundoAtualizado: mundoNovo, eventosGerados: eventos);
  }

  /// R37: Executa o Pipeline de Ativação de 5 passos em ordem fixa.
  ({
    EstadoMundoHabilidades mundoAtualizado,
    ResultadoAtivacao resultado,
  }) ativarHabilidade({
    required EstadoMundoHabilidades mundo,
    required String usuarioId,
    required Habilidade habilidade,
    IControleDeAcoes? controleDeAcoes,
    int? custoVariavelEscolhido,
    List<ReducaoCusto> reducoesExtras = const [],
    List<String> alvosEscolhidosIds = const [],
    Area? areaEscolhida,
    Posicao2D? pontoCriacao,
    String? novoTokenIdCriado,
    EventoDeJogo? eventoGatilho,
    bool confirmarMesmoComAvisos = false,
    bool confirmarSubstituirMagiaSustentada = false,
    bool aprovadoPeloMestreAlcanceIlimitado = false,
    bool areaPercebidaPeloUsuario = true,
    bool sobrescritaMestreLinhaEfeito = false,
    bool sobrescritaMestrePercepcao = false,
    Map<String, int>? d20sForcadosResistencia,
    int? modAtributoChaveSobrescrito,
  }) {
    final acoes = controleDeAcoes ?? ControleDeAcoesPermissivo();

    // =========================================================================
    // PASSO 1: VALIDAR SEM GASTAR NADA
    // =========================================================================
    try {
      habilidade.validarDefinicao();
    } on RegraTesteException catch (e) {
      return (
        mundoAtualizado: mundo,
        resultado: ResultadoAtivacao(
          habilidadeId: habilidade.id,
          bloqueada: true,
          motivo: e.codigo,
          logDetalhado: e.mensagem,
        ),
      );
    }

    if (habilidade.tipo == TipoHabilidade.passiva) {
      return (
        mundoAtualizado: mundo,
        resultado: ResultadoAtivacao(
          habilidadeId: habilidade.id,
          bloqueada: true,
          motivo: 'HABILIDADE_PASSIVA_NAO_ATIVAVEL',
          logDetalhado:
              'Habilidades passivas são aplicadas automaticamente pelo ModificadorEngine.',
        ),
      );
    }

    final usuario = mundo.personagens[usuarioId];
    if (usuario == null) {
      return (
        mundoAtualizado: mundo,
        resultado: ResultadoAtivacao(
          habilidadeId: habilidade.id,
          bloqueada: true,
          motivo: 'USUARIO_NAO_ENCONTRADO',
        ),
      );
    }

    // R23: Ação disponível no ControleDeAcoes
    final acaoNecessaria = habilidade.acaoEfetiva;
    if (!acoes.temAcaoDisponivel(usuarioId, acaoNecessaria)) {
      return (
        mundoAtualizado: mundo,
        resultado: ResultadoAtivacao(
          habilidadeId: habilidade.id,
          bloqueada: true,
          motivo: 'ACAO_INDISPONIVEL',
          logDetalhado:
              'Ação ${acaoNecessaria.label} indisponível para $usuarioId.',
        ),
      );
    }

    // R23 (Caso de Borda 2): Habilidade engatilhada exige evento-gatilho não consumido
    if (habilidade.ehEngatilhada) {
      if (eventoGatilho == null ||
          eventoGatilho.tipo.trim().toLowerCase() !=
              habilidade.gatilho!.trim().toLowerCase()) {
        return (
          mundoAtualizado: mundo,
          resultado: ResultadoAtivacao(
            habilidadeId: habilidade.id,
            bloqueada: true,
            motivo: 'GATILHO_NAO_OCORREU',
            logDetalhado:
                'A habilidade exige o gatilho "${habilidade.gatilho}".',
          ),
        );
      }
      final chavePar = '${habilidade.id}::${eventoGatilho.id}';
      if (mundo.paresHabilidadeEventoConsumidos.contains(chavePar)) {
        return (
          mundoAtualizado: mundo,
          resultado: ResultadoAtivacao(
            habilidadeId: habilidade.id,
            bloqueada: true,
            motivo: 'GATILHO_JA_CONSUMIDO_NESTE_EVENTO',
            logDetalhado:
                'A habilidade ${habilidade.nome} já foi ativada para o evento ${eventoGatilho.id}.',
          ),
        );
      }
    }

    // R25–R28: Validação de PM, limite variável, material em mãos, penalidade e sacrifício
    final validacaoCusto = pmService.validarCustosPreAtivacao(
      habilidade: habilidade,
      personagem: usuario,
      custoVariavelEscolhido: custoVariavelEscolhido,
      reducoesExtras: reducoesExtras,
    );
    if (!validacaoCusto.valido) {
      return (
        mundoAtualizado: mundo,
        resultado: ResultadoAtivacao(
          habilidadeId: habilidade.id,
          bloqueada: true,
          motivo: 'CUSTO_INVALIDO_OU_INSUFICIENTE',
          logDetalhado: validacaoCusto.motivo ?? 'Custo inválido.',
        ),
      );
    }

    // R41 (Caso de Borda 24): Limite de APENAS UMA MAGIA sustentada por vez
    EfeitoAtivo? magiaSustentadaAnterior;
    if (habilidade.ehMagia &&
        habilidade.duracao.tipo == TipoDuracao.sustentada) {
      for (final ef in mundo.efeitos) {
        if (ef.estaEmJogo &&
            ef.usuarioId == usuarioId &&
            ef.ehMagia &&
            ef.duracao.tipo == TipoDuracao.sustentada) {
          magiaSustentadaAnterior = ef;
          break;
        }
      }
      if (magiaSustentadaAnterior != null &&
          !confirmarSubstituirMagiaSustentada) {
        return (
          mundoAtualizado: mundo,
          resultado: ResultadoAtivacao(
            habilidadeId: habilidade.id,
            bloqueada: true,
            motivo: 'LIMITE_UMA_MAGIA_SUSTENTADA',
            avisosConfirmacao: [
              'Encerrar a magia sustentada anterior (${magiaSustentadaAnterior.nomeHabilidade}) e ativar esta?',
            ],
            logDetalhado:
                'Apenas uma magia sustentada pode ficar ativa por vez. Confirme a substituição.',
          ),
        );
      }
    }

    // =========================================================================
    // PASSO 2: RESOLVER ALVOS / ÁREA
    // =========================================================================
    if (habilidade.alcance == AlcanceHabilidade.ilimitado &&
        configuracoes.alcanceIlimitadoExigeAprovacaoMestre &&
        !aprovadoPeloMestreAlcanceIlimitado) {
      return (
        mundoAtualizado: mundo,
        resultado: ResultadoAtivacao(
          habilidadeId: habilidade.id,
          bloqueada: true,
          aguardandoAprovacaoMestreIlimitado: true,
          motivo: 'AGUARDANDO_APROVACAO_MESTRE_ILIMITADO',
          logDetalhado:
              'Alcance ILIMITADO exige aprovação do Mestre caso a caso.',
        ),
      );
    }

    final avisos = <String>[];
    String? motivoFalhaResolucao;
    final alvosValidosFinais = <String>[];
    final areaEfetiva = areaEscolhida ?? habilidade.area;

    if (areaEfetiva != null) {
      // Valida origem em vértice para ESFERA e CILINDRO (R34 / Caso 17)
      if (!geometriaGrid.validarOrigemGeometriaArea(areaEfetiva)) {
        return (
          mundoAtualizado: mundo,
          resultado: ResultadoAtivacao(
            habilidadeId: habilidade.id,
            bloqueada: true,
            motivo: 'ORIGEM_VERTICE_OBRIGATORIA',
            logDetalhado:
                'Áreas de ESFERA e CILINDRO exigem origem na interseção de 4 quadrados (vértice do grid).',
          ),
        );
      }

      final preview = geometriaGrid.calcularPreviewArea(
        posicaoUsuario: usuario.posicao,
        usuarioId: usuarioId,
        alcanceHabilidade: habilidade.alcance,
        alvosPermitidos: habilidade.alvosPermitidos,
        area: areaEfetiva,
        alvosNoMapa: mundo.alvosNoMapa.values.toList(),
        barreiras: mundo.barreiras,
        sobrescritaMestreLinhaEfeito: sobrescritaMestreLinhaEfeito,
      );

      if (!preview.origemDentroDoAlcance) {
        avisos.add('Origem da área está além do alcance da habilidade.');
        motivoFalhaResolucao ??= 'ORIGEM_FORA_DO_ALCANCE';
      }
      if (!preview.origemTemLinhaDeEfeito) {
        avisos.add(
          'Origem da área não possui linha de efeito (bloqueada por barreira).',
        );
        motivoFalhaResolucao ??= 'SEM_LINHA_DE_EFEITO_ORIGEM';
      }

      if (avisos.isNotEmpty && !confirmarMesmoComAvisos) {
        return (
          mundoAtualizado: mundo,
          resultado: ResultadoAtivacao(
            habilidadeId: habilidade.id,
            bloqueada: true,
            motivo: motivoFalhaResolucao,
            avisosConfirmacao: avisos,
            logDetalhado: avisos.join(' '),
          ),
        );
      }

      if (motivoFalhaResolucao == null) {
        alvosValidosFinais.addAll(preview.alvosAfetadosIds);
      }
    } else if (habilidade.criaElementoNoMapa) {
      // R35 (Caso de Borda 14): Criação/invocação exige origem no alcance e com linha de efeito
      final dest = pontoCriacao ?? usuario.posicao;
      final noAlcance = geometriaGrid.estaDentroDoAlcance(
        posicaoUsuario: usuario.posicao,
        alcance: habilidade.alcance,
        destinoCelula: dest,
      );
      final temLoE = geometriaGrid.temLinhaDeEfeito(
        origem: usuario.posicao,
        destinoCelula: dest,
        barreiras: mundo.barreiras,
        sobrescritaMestre: sobrescritaMestreLinhaEfeito,
      );

      if (!noAlcance) {
        avisos.add('Local de criação está fora do alcance.');
        motivoFalhaResolucao ??= 'CRIACAO_FORA_DO_ALCANCE';
      }
      if (!temLoE) {
        avisos.add('Local de criação está sem linha de efeito.');
        motivoFalhaResolucao ??= 'CRIACAO_SEM_LINHA_DE_EFEITO';
      }

      if (avisos.isNotEmpty && !confirmarMesmoComAvisos) {
        return (
          mundoAtualizado: mundo,
          resultado: ResultadoAtivacao(
            habilidadeId: habilidade.id,
            bloqueada: true,
            motivo: motivoFalhaResolucao,
            avisosConfirmacao: avisos,
            logDetalhado: avisos.join(' '),
          ),
        );
      }
    } else {
      // Habilidade de alvo(s) direto(s) ( ou PESSOAL sem área )
      final idsParaChecar = alvosEscolhidosIds.isEmpty &&
              habilidade.alcance == AlcanceHabilidade.pessoal
          ? <String>[usuarioId]
          : alvosEscolhidosIds;

      for (final idAlvo in idsParaChecar) {
        if (idAlvo == usuarioId &&
            habilidade.alcance == AlcanceHabilidade.pessoal) {
          alvosValidosFinais.add(usuarioId);
          continue;
        }

        final alvo = mundo.alvosNoMapa[idAlvo];
        if (alvo == null) {
          avisos.add('Alvo "$idAlvo" não existe no mapa.');
          motivoFalhaResolucao ??= 'ALVO_INEXISTENTE';
          continue;
        }

        if (!habilidade.alvosPermitidos.contains(alvo.tipo)) {
          avisos.add(
            'Alvo "${alvo.id}" (${alvo.tipo.name}) é incompatível com ${habilidade.alvosPermitidos.map((e) => e.name).join("/")}.',
          );
          motivoFalhaResolucao ??= 'ALVO_INCOMPATIVEL';
          continue;
        }

        if (!alvo.percebidoPeloUsuario && !sobrescritaMestrePercepcao) {
          avisos.add('Alvo "${alvo.id}" não é percebido pelo usuário.');
          motivoFalhaResolucao ??= 'ALVO_NAO_PERCEBIDO';
          continue;
        }

        if (!geometriaGrid.estaDentroDoAlcance(
          posicaoUsuario: usuario.posicao,
          alcance: habilidade.alcance,
          destinoCelula: alvo.posicao,
        )) {
          avisos.add('Alvo "${alvo.id}" está fora do alcance.');
          motivoFalhaResolucao ??= 'ALVO_FORA_DO_ALCANCE';
          continue;
        }

        if (!geometriaGrid.temLinhaDeEfeito(
          origem: usuario.posicao,
          destinoCelula: alvo.posicao,
          barreiras: mundo.barreiras,
          sobrescritaMestre: sobrescritaMestreLinhaEfeito,
        )) {
          avisos.add('Sem linha de efeito até o alvo "${alvo.id}".');
          motivoFalhaResolucao ??= 'SEM_LINHA_DE_EFEITO';
          continue;
        }

        alvosValidosFinais.add(alvo.id);
      }

      if (avisos.isNotEmpty && !confirmarMesmoComAvisos) {
        // Caso de Borda 5: Sem confirmação (bloqueio prévio) -> nada é gasto!
        return (
          mundoAtualizado: mundo,
          resultado: ResultadoAtivacao(
            habilidadeId: habilidade.id,
            bloqueada: true,
            motivo: motivoFalhaResolucao,
            avisosConfirmacao: avisos,
            custoPago: 0,
            logDetalhado: avisos.join(' '),
          ),
        );
      }
    }

    // =========================================================================
    // PASSO 3: GASTAR CUSTOS (PM, MATERIAL, PENALIDADE, SACRIFÍCIO)
    // =========================================================================
    acoes.consumirAcao(usuarioId, acaoNecessaria);

    final novosParesConsumidos =
        Set<String>.from(mundo.paresHabilidadeEventoConsumidos);
    if (habilidade.ehEngatilhada && eventoGatilho != null) {
      novosParesConsumidos.add('${habilidade.id}::${eventoGatilho.id}');
    }

    var mapaPersonagens =
        Map<String, EstadoPersonagemHabilidade>.from(mundo.personagens);
    var mapaAreas = Map<String, AreaPersistente>.from(mundo.areasPersistentes);
    var listaEfeitos = List<EfeitoAtivo>.from(mundo.efeitos);
    final eventosGerados = <Map<String, dynamic>>[];

    // Se confirmou substituir magia sustentada anterior (R41 / Caso 24), encerra a anterior agora
    if (magiaSustentadaAnterior != null &&
        confirmarSubstituirMagiaSustentada) {
      final cicloSub = duracaoEngine.encerrarEfeito(
        efeitoId: magiaSustentadaAnterior.id,
        solicitanteId: usuarioId,
        ehMestre: true,
        motivoCustom: MotivoFimEfeito.substituido,
        efeitos: listaEfeitos,
        areasPersistentes: mapaAreas,
        personagens: mapaPersonagens,
        relogio: mundo.relogio,
        cenaAtual: mundo.cenaAtual,
        sustentacoesPendentes: mundo.sustentacoesPendentes,
        paresConsumidos: novosParesConsumidos,
        controleDeAcoes: acoes,
      );
      listaEfeitos = List<EfeitoAtivo>.from(cicloSub.efeitos);
      mapaAreas = Map<String, AreaPersistente>.from(cicloSub.areasPersistentes);
      mapaPersonagens =
          Map<String, EstadoPersonagemHabilidade>.from(cicloSub.personagens);
      eventosGerados.addAll(cicloSub.eventosGerados);
    }

    // R34 (Caso de Borda 16): Área não percebida exige teste de Percepção (ou Misticismo se ehMagia)
    // contra CD = 20 + custo em PM
    RollResult? resultadoTesteAreaNaoPercebida;
    if (areaEfetiva != null &&
        !areaPercebidaPeloUsuario &&
        motivoFalhaResolucao == null) {
      final periciaTeste = habilidade.ehMagia ? 'MISTICISMO' : 'PERCEPCAO';
      final custoParaCd = configuracoes.testeAreaNaoPercebidaUsaCustoFinal
          ? validacaoCusto.custoFinal
          : validacaoCusto.custoBase;
      final cdArea = 20 + custoParaCd;
      final modPericia =
          mapaPersonagens[usuarioId]?.modPericias[periciaTeste] ?? 0;

      resultadoTesteAreaNaoPercebida = motorTestes.executarTeste(
        request: TesteRequest(
          id: 'teste_area_${habilidade.id}',
          tipo: TipoTeste.comum,
          cd: cdArea,
          participantes: [usuarioId],
          modo: ModoTeste.pericia,
          fonteEsperada: periciaTeste,
        ),
        personagemId: usuarioId,
        fonteMod: periciaTeste,
        modBase: modPericia,
      );

      if (resultadoTesteAreaNaoPercebida.sucessoCD != true) {
        motivoFalhaResolucao = 'FALHA_TESTE_AREA_NAO_PERCEBIDA';
      }
    }

    // R29: Chance de falha (se houver modificadores de CHANCE_FALHA ativos no usuário)
    final modsChanceFalha = listaEfeitos
        .where((e) => e.estado == EstadoEfeito.ativo && e.alvos.contains(usuarioId))
        .expand((e) => e.modificadores)
        .where(
          (m) =>
              m.alvoCaracteristica.trim().toUpperCase() == 'CHANCE_FALHA',
        )
        .toList();
    if (modsChanceFalha.isNotEmpty && motivoFalhaResolucao == null) {
      final avaliacaoChance = modificadorEngine.calcularChanceFalha(
        modsChanceFalha,
        rng: _rng,
      );
      if (avaliacaoChance.falhou) {
        motivoFalhaResolucao =
            'FALHA_CHANCE_DE_FALHA (${avaliacaoChance.d100Rolado}% <= ${avaliacaoChance.chanceEfetiva}%)';
      }
    }

    final falhou = motivoFalhaResolucao != null;
    _contadorEfeitos += 1;
    final novoEfeitoId =
        'efeito_${habilidade.id}_$_contadorEfeitos';

    final criaEfeitoDuradouro =
        !falhou && habilidade.duracao.tipo != TipoDuracao.instantanea;

    final usuarioAposGasto = pmService.gastarCustos(
      personagem: mapaPersonagens[usuarioId]!,
      habilidade: habilidade,
      custoFinalPM: validacaoCusto.custoFinal,
      efeitoIdParaPenalidade: criaEfeitoDuradouro ? novoEfeitoId : null,
      vincularPenalidadeAoEfeito: criaEfeitoDuradouro,
    );
    mapaPersonagens[usuarioId] = usuarioAposGasto;
    eventosGerados.add({
      'tipo': 'PMAtualizado',
      'personagemId': usuarioId,
      'pmState': usuarioAposGasto.pmState.toJson(),
    });

    // =========================================================================
    // PASSO 4: APLICAR (OU REGISTRAR FALHA)
    // =========================================================================
    final mapaAlvosNoMapa = Map<String, AlvoMapa>.from(mundo.alvosNoMapa);
    final novoCatalogo =
        Map<String, Habilidade>.from(mundo.catalogoHabilidades);
    novoCatalogo[habilidade.id] = habilidade;

    String? efeitoCriadoId;
    String? tokenCriadoId;

    if (falhou) {
      final logFalha =
          '[FALHA NA ATIVAÇÃO] ${habilidade.nome} falhou ($motivoFalhaResolucao). Custos gastos: ${validacaoCusto.custoFinal} PM.';
      return (
        mundoAtualizado: mundo.copyWith(
          personagens: Map.unmodifiable(mapaPersonagens),
          efeitos: List.unmodifiable(listaEfeitos),
          areasPersistentes: Map.unmodifiable(mapaAreas),
          paresHabilidadeEventoConsumidos:
              Set.unmodifiable(novosParesConsumidos),
          catalogoHabilidades: Map.unmodifiable(novoCatalogo),
        ),
        resultado: ResultadoAtivacao(
          habilidadeId: habilidade.id,
          bloqueada: false,
          custoPago: validacaoCusto.custoFinal,
          falhou: true,
          motivoFalha: motivoFalhaResolucao,
          alvosAfetados: const [],
          resultadoTestePercepcaoArea: resultadoTesteAreaNaoPercebida,
          avisosConfirmacao: avisos,
          eventosGerados: List.unmodifiable(eventosGerados),
          logDetalhado: logFalha,
        ),
      );
    }

    // R35 (Caso de Borda 14): Cria token no mapa quando aplicável
    if (habilidade.criaElementoNoMapa) {
      tokenCriadoId = novoTokenIdCriado ?? 'token_${habilidade.id}_$_contadorEfeitos';
      final posToken = pontoCriacao ?? usuario.posicao;
      mapaAlvosNoMapa[tokenCriadoId] = AlvoMapa(
        id: tokenCriadoId,
        nome: habilidade.nome,
        tipo: TipoAlvoPermitido.objeto,
        posicao: posToken,
      );
      alvosValidosFinais.add(tokenCriadoId);
    }

    // R58: Pipeline de resolução para cada alvo no passo 4:
    // (1) checar imunidade (R57)
    // (2) teste de resistência (R50–R55)
    // (3) aplicar o resultado (R53)
    // (4) log com CD, rolagem, resultado e o tipo de efeito.
    final alvosAposImunidadeEResistencia = <String>[];
    final resultadosResistencia = <ResultadoResistencia>[];
    final motivosImunidade = <String>[];
    final desacreditadosIlusao = <String>{};
    final mapaDanosPorAlvo = <String, int>{};
    final logsResistenciaEImunidade = <String>[];

    for (final idAlvo in alvosValidosFinais) {
      // 1. Checa se o alvo é um Item/Objeto no mapa (R56)
      final itemObjeto = mundo.itensNoMapa[idAlvo];
      if (itemObjeto != null) {
        final podeSofrerDano = resistenciaService.objetoPodeSofrerDano(
          item: itemObjeto,
          habilidade: habilidade,
          ehDanoEmArea: areaEfetiva != null,
        );
        if (!podeSofrerDano) {
          // Item carregado não sofre dano de área (R56 / Caso 6)
          logsResistenciaEImunidade.add(
            'Item carregado "${itemObjeto.nome}" não sofre dano de área (R56).',
          );
          continue;
        }

        if (habilidade.resistencia != null || habilidade.resistePericia != null) {
          final modAtr = resistenciaService.obterModificadorAtributoParaCd(
            habilidade: habilidade,
            modAtributoChave: modAtributoChaveSobrescrito ??
                usuario.modPericias['ATRIBUTO_CHAVE'],
            atributos: usuario.modPericias,
          );
          final cd = resistenciaService.calcularCdResistencia(
            nivelTotal: usuario.nivelTotal,
            modAtributo: modAtr,
          );
          final portador = itemObjeto.carregadoPor != null
              ? mundo.criaturas[itemObjeto.carregadoPor!]
              : null;
          final d20Forcado = d20sForcadosResistencia?[idAlvo];
          final resObj = resistenciaService.resolverResistenciaObjeto(
            item: itemObjeto,
            habilidade: habilidade,
            cdResistencia: cd,
            portador: portador,
            d20Forcado: d20Forcado,
          );
          resultadosResistencia.add(resObj);
          logsResistenciaEImunidade.add(resObj.log);

          if (resObj.sucesso &&
              resObj.resultadoAplicado == TipoResultadoResistencia.anula) {
            continue; // Anula efeito no item (R53 / Caso 2)
          }
        }
        alvosAposImunidadeEResistencia.add(idAlvo);
        mapaDanosPorAlvo[idAlvo] = habilidade.danoPvInstantaneo;
        continue;
      }

      // 2. Checa se o alvo é uma Criatura (R57)
      final criatura = mundo.criaturas[idAlvo] ??
          (mapaPersonagens.containsKey(idAlvo)
              ? Criatura(id: idAlvo, nome: idAlvo)
              : null);

      if (criatura != null) {
        // (1) Checar imunidade (R57 / Caso 7)
        final checagemImunidade = imunidadeService.checarImunidade(
          criatura: criatura,
          tiposEfeito: habilidade.tiposEfeito,
        );
        if (checagemImunidade.imune) {
          motivosImunidade.add(checagemImunidade.motivo!);
          logsResistenciaEImunidade.add('[IMUNIDADE] ${checagemImunidade.motivo!}');
          // Alvo imune é ignorado: não faz teste, não sofre efeito, custos continuam gastos (R57 / Caso 7)
          continue;
        }

        var danoAlvo = habilidade.danoPvInstantaneo;

        // (2) Teste de resistência (R50–R55)
        if (habilidade.resistencia != null || habilidade.resistePericia != null) {
          final modAtr = resistenciaService.obterModificadorAtributoParaCd(
            habilidade: habilidade,
            modAtributoChave: modAtributoChaveSobrescrito ??
                usuario.modPericias['ATRIBUTO_CHAVE'],
            atributos: usuario.modPericias,
          );
          final cd = resistenciaService.calcularCdResistencia(
            nivelTotal: usuario.nivelTotal,
            modAtributo: modAtr,
          );
          final d20Forcado = d20sForcadosResistencia?[idAlvo];
          final resCriatura = resistenciaService.resolverResistenciaCriatura(
            criatura: criatura,
            habilidade: habilidade,
            cdResistencia: cd,
            d20Forcado: d20Forcado,
          );
          resultadosResistencia.add(resCriatura);
          logsResistenciaEImunidade.add(resCriatura.log);

          // (3) Aplicar resultado (R53)
          if (resCriatura.sucesso) {
            if (resCriatura.resultadoAplicado ==
                TipoResultadoResistencia.anula) {
              // ANULA: sucesso = o efeito não afeta o alvo (R53 / Caso 2)
              continue;
            } else if (resCriatura.resultadoAplicado ==
                TipoResultadoResistencia.metade) {
              // METADE: sucesso = dano dividido por 2 (arredonda para baixo) (R53 / Caso 3)
              danoAlvo = resistenciaService
                  .aplicarReducaoMetade(habilidade.danoPvInstantaneo);
            } else if (resCriatura.resultadoAplicado ==
                TipoResultadoResistencia.desacredita) {
              // DESACREDITA: percebe que a ilusão é falsa (R53 / Caso 10)
              desacreditadosIlusao.add(idAlvo);
            }
          }
        }

        mapaDanosPorAlvo[idAlvo] = danoAlvo;
        alvosAposImunidadeEResistencia.add(idAlvo);
        continue;
      }

      // 3. Alvo genérico (ex.: token sem ficha de criatura/objeto cadastrado)
      alvosAposImunidadeEResistencia.add(idAlvo);
      mapaDanosPorAlvo[idAlvo] = habilidade.danoPvInstantaneo;
    }

    if (habilidade.duracao.tipo == TipoDuracao.instantanea) {
      // R39 (Caso de Borda 21): INSTANTANEA aplica mudanças permanentes de estado (PV, etc.)
      // e NÃO cria EfeitoAtivo!
      if (habilidade.curaPvInstantanea > 0 ||
          habilidade.danoPvInstantaneo > 0) {
        for (final idAlvo in alvosAposImunidadeEResistencia) {
          final danoAlvo =
              mapaDanosPorAlvo[idAlvo] ?? habilidade.danoPvInstantaneo;
          final deltaPv = habilidade.curaPvInstantanea - danoAlvo;
          if (mapaPersonagens.containsKey(idAlvo)) {
            final p = mapaPersonagens[idAlvo]!;
            final novoPv = (p.pvAtual + deltaPv).clamp(0, p.pvMax);
            mapaPersonagens[idAlvo] = p.copyWith(pvAtual: novoPv);
          }
          if (mapaAlvosNoMapa.containsKey(idAlvo)) {
            final a = mapaAlvosNoMapa[idAlvo]!;
            final novoPv = (a.pvAtual + deltaPv).clamp(0, a.pvMax);
            mapaAlvosNoMapa[idAlvo] = a.copyWith(pvAtual: novoPv);
          }
        }
      }
    } else {
      // Duração CENA, SUSTENTADA, DEFINIDA ou PERMANENTE -> cria EfeitoAtivo (e AreaPersistente se tiver área)
      efeitoCriadoId = novoEfeitoId;
      String? areaPersistenteId;
      if (areaEfetiva != null) {
        areaPersistenteId = 'area_$novoEfeitoId';
        mapaAreas[areaPersistenteId] = AreaPersistente(
          id: areaPersistenteId,
          efeitoId: novoEfeitoId,
          usuarioId: usuarioId,
          alcanceHabilidade: habilidade.alcance,
          alvosPermitidos: habilidade.alvosPermitidos,
          area: areaEfetiva,
          alvosDentro:
              Set.unmodifiable(alvosAposImunidadeEResistencia.toSet()),
        );
      }

      final historicoResPorAlvo = {
        for (final r in resultadosResistencia) r.alvoId: r,
      };

      final reg = duracaoEngine.registrarNovoEfeito(
        novoEfeitoId: novoEfeitoId,
        habilidade: habilidade,
        usuarioId: usuarioId,
        alvosAfetados: alvosAposImunidadeEResistencia,
        areaPersistenteId: areaPersistenteId,
        relogio: mundo.relogio,
        cenaAtual: mundo.cenaAtual,
        efeitosExistentes: listaEfeitos,
        personagens: mapaPersonagens,
        areasPersistentes: mapaAreas,
        historicoResistencia: historicoResPorAlvo,
        desacreditadoPor: desacreditadosIlusao,
      );
      listaEfeitos = List<EfeitoAtivo>.from(reg.efeitosAtualizados);
      mapaPersonagens =
          Map<String, EstadoPersonagemHabilidade>.from(reg.personagensAtualizados);
      mapaAreas = Map<String, AreaPersistente>.from(reg.areasAtualizadas);
      eventosGerados.addAll(reg.eventos);
    }

    // =========================================================================
    // PASSO 5: LOG DETALHADO (R58)
    // =========================================================================
    final descTipos = habilidade.tiposEfeito.isNotEmpty
        ? ' | Tipos: ${imunidadeService.normalizarTipos(habilidade.tiposEfeito).map((e) => e.name).join(", ")}'
        : '';
    final logRes = logsResistenciaEImunidade.isNotEmpty
        ? '\n  ${logsResistenciaEImunidade.join('\n  ')}'
        : '';
    final log =
        '[ATIVAÇÃO] ${habilidade.nome} por $usuarioId | Custo base: ${validacaoCusto.custoBase} PM, Custo final: ${validacaoCusto.custoFinal} PM | Alvos: ${alvosAposImunidadeEResistencia.join(", ")} | Duração: ${habilidade.duracao.tipo.name}${efeitoCriadoId != null ? " (id: $efeitoCriadoId)" : " (instantânea)"}$descTipos.$logRes';

    final mundoAtualizado = mundo.copyWith(
      personagens: Map.unmodifiable(mapaPersonagens),
      alvosNoMapa: Map.unmodifiable(mapaAlvosNoMapa),
      efeitos: List.unmodifiable(listaEfeitos),
      areasPersistentes: Map.unmodifiable(mapaAreas),
      paresHabilidadeEventoConsumidos: Set.unmodifiable(novosParesConsumidos),
      catalogoHabilidades: Map.unmodifiable(novoCatalogo),
    );

    final resultado = ResultadoAtivacao(
      habilidadeId: habilidade.id,
      bloqueada: false,
      custoPago: validacaoCusto.custoFinal,
      falhou: false,
      alvosAfetados: List.unmodifiable(alvosAposImunidadeEResistencia),
      efeitoId: efeitoCriadoId,
      tokenCriadoId: tokenCriadoId,
      resultadoTestePercepcaoArea: resultadoTesteAreaNaoPercebida,
      avisosConfirmacao: avisos,
      eventosGerados: List.unmodifiable(eventosGerados),
      logDetalhado: log,
      resultadosResistencia: List.unmodifiable(resultadosResistencia),
      motivosImunidade: List.unmodifiable(motivosImunidade),
    );

    return (mundoAtualizado: mundoAtualizado, resultado: resultado);
  }

  /// R36 (Caso de Borda 18): Redireciona um efeito ativo para novo(s) alvo(s) ou nova origem de área.
  /// Exige uma `AÇÃO PADRÃO` e valida alcance, percepção, linha de efeito e compatibilidade.
  EstadoMundoHabilidades redirecionarEfeito({
    required EstadoMundoHabilidades mundo,
    required String efeitoId,
    required String solicitanteId,
    required IControleDeAcoes controleDeAcoes,
    List<String> novosAlvosIds = const [],
    Area? novaArea,
  }) {
    final idx = mundo.efeitos.indexWhere((e) => e.id == efeitoId);
    if (idx == -1) {
      throw RegraTesteException(
        codigo: 'EFEITO_NAO_ENCONTRADO',
        mensagem: 'Efeito $efeitoId não encontrado para redirecionamento.',
      );
    }

    final ef = mundo.efeitos[idx];
    if (!ef.estaEmJogo) {
      throw const RegraTesteException(
        codigo: 'EFEITO_INATIVO',
        mensagem: 'Não é possível redirecionar um efeito encerrado ou expirado.',
      );
    }
    if (ef.usuarioId != solicitanteId) {
      throw const RegraTesteException(
        codigo: 'APENAS_DONO_PODE_REDIRECIONAR',
        mensagem: 'Apenas o dono do efeito pode redirecioná-lo.',
      );
    }
    if (!ef.permiteRedirecionar) {
      throw const RegraTesteException(
        codigo: 'EFEITO_NAO_REDIRECIONAVEL',
        mensagem: 'Esta habilidade não permite redirecionamento.',
      );
    }

    // R36 (Caso de Borda 18): Redirecionar exige AÇÃO PADRÃO
    if (!controleDeAcoes.temAcaoDisponivel(solicitanteId, TipoAcao.padrao)) {
      throw const RegraTesteException(
        codigo: 'ACAO_PADRAO_EXIGIDA_PARA_REDIRECIONAR',
        mensagem: 'Redirecionar um efeito exige uma Ação Padrão disponível.',
      );
    }

    final usuario = mundo.personagens[solicitanteId];
    if (usuario == null) {
      throw const RegraTesteException(
        codigo: 'USUARIO_NAO_ENCONTRADO',
        mensagem: 'Usuário não encontrado.',
      );
    }

    final listaEfeitos = List<EfeitoAtivo>.from(mundo.efeitos);
    final mapaAreas = Map<String, AreaPersistente>.from(mundo.areasPersistentes);
    final habilidadeMolde = mundo.catalogoHabilidades[ef.habilidadeId];
    final modsMolde = habilidadeMolde?.modificadoresGerados ?? const [];

    if (novaArea != null && ef.areaPersistenteId != null) {
      final preview = geometriaGrid.calcularPreviewArea(
        posicaoUsuario: usuario.posicao,
        usuarioId: solicitanteId,
        alcanceHabilidade: ef.alcance,
        alvosPermitidos: ef.alvosPermitidos,
        area: novaArea,
        alvosNoMapa: mundo.alvosNoMapa.values.toList(),
        barreiras: mundo.barreiras,
      );
      if (!preview.origemDentroDoAlcance || !preview.origemTemLinhaDeEfeito) {
        throw const RegraTesteException(
          codigo: 'REDIRECIONAMENTO_INVALIDO',
          mensagem:
              'A nova origem da área está fora do alcance ou sem linha de efeito.',
        );
      }

      controleDeAcoes.consumirAcao(solicitanteId, TipoAcao.padrao);
      final areaAntiga = mapaAreas[ef.areaPersistenteId]!;
      final reav = areaTracker.reavaliarArea(
        areaPersistente: areaAntiga.copyWith(area: novaArea),
        efeito: ef,
        modificadoresMoldeHabilidade: modsMolde,
        posicaoUsuario: usuario.posicao,
        alvosNoMapa: mundo.alvosNoMapa.values.toList(),
        barreiras: mundo.barreiras,
      );
      mapaAreas[ef.areaPersistenteId!] = reav.areaAtualizada;
      listaEfeitos[idx] = reav.efeitoAtualizado;
    } else {
      for (final idAlvo in novosAlvosIds) {
        final alvo = mundo.alvosNoMapa[idAlvo];
        if (alvo == null ||
            !ef.alvosPermitidos.contains(alvo.tipo) ||
            !alvo.percebidoPeloUsuario ||
            !geometriaGrid.estaDentroDoAlcance(
              posicaoUsuario: usuario.posicao,
              alcance: ef.alcance,
              destinoCelula: alvo.posicao,
            ) ||
            !geometriaGrid.temLinhaDeEfeito(
              origem: usuario.posicao,
              destinoCelula: alvo.posicao,
              barreiras: mundo.barreiras,
            )) {
          throw RegraTesteException(
            codigo: 'REDIRECIONAMENTO_ALVO_INVALIDO',
            mensagem:
                'Novo alvo "$idAlvo" é inválido (fora de alcance, sem linha de efeito, não percebido ou incompatível).',
          );
        }
      }

      controleDeAcoes.consumirAcao(solicitanteId, TipoAcao.padrao);
      final novosMods = <ModificadorAplicado>[
        for (final idAlvo in novosAlvosIds)
          for (final molde in modsMolde)
            molde.copyWith(efeitoId: ef.id, alvoId: idAlvo, aplicado: true),
      ];
      listaEfeitos[idx] = ef.copyWith(
        alvos: List.unmodifiable(novosAlvosIds),
        modificadores: List.unmodifiable(novosMods),
      );
    }

    return mundo.copyWith(
      efeitos: List.unmodifiable(listaEfeitos),
      areasPersistentes: Map.unmodifiable(mapaAreas),
    );
  }

  /// R35 e R44 (Casos de Borda 14 e 29): Move um token no mapa e reavalia todas as áreas persistentes.
  /// Elementos criados/invocados podem se mover para fora da linha de efeito sem encerrar!
  ({
    EstadoMundoHabilidades mundoAtualizado,
    List<Map<String, dynamic>> eventosArea,
  }) moverTokenNoMapa({
    required EstadoMundoHabilidades mundo,
    required String tokenId,
    required Posicao2D novaPosicao,
  }) {
    final mapaAlvos = Map<String, AlvoMapa>.from(mundo.alvosNoMapa);
    final mapaPersonagens =
        Map<String, EstadoPersonagemHabilidade>.from(mundo.personagens);

    if (mapaAlvos.containsKey(tokenId)) {
      mapaAlvos[tokenId] = mapaAlvos[tokenId]!.copyWith(posicao: novaPosicao);
    }
    if (mapaPersonagens.containsKey(tokenId)) {
      mapaPersonagens[tokenId] =
          mapaPersonagens[tokenId]!.copyWith(posicao: novaPosicao);
    }

    final listaEfeitos = List<EfeitoAtivo>.from(mundo.efeitos);
    final mapaAreas = Map<String, AreaPersistente>.from(mundo.areasPersistentes);
    final eventos = <Map<String, dynamic>>[];

    for (final entry in mapaAreas.entries.toList()) {
      final areaId = entry.key;
      final areaP = entry.value;
      final idxEf = listaEfeitos.indexWhere((e) => e.id == areaP.efeitoId);
      if (idxEf == -1) continue;
      final ef = listaEfeitos[idxEf];
      final posUsuario =
          mapaPersonagens[ef.usuarioId]?.posicao ?? const Posicao2D(0, 0);
      final modsMolde =
          mundo.catalogoHabilidades[ef.habilidadeId]?.modificadoresGerados ??
              const [];

      final reav = areaTracker.reavaliarArea(
        areaPersistente: areaP,
        efeito: ef,
        modificadoresMoldeHabilidade: modsMolde,
        posicaoUsuario: posUsuario,
        alvosNoMapa: mapaAlvos.values.toList(),
        barreiras: mundo.barreiras,
      );
      mapaAreas[areaId] = reav.areaAtualizada;
      listaEfeitos[idxEf] = reav.efeitoAtualizado;
      eventos.addAll(reav.eventosGerados);
    }

    return (
      mundoAtualizado: mundo.copyWith(
        alvosNoMapa: Map.unmodifiable(mapaAlvos),
        personagens: Map.unmodifiable(mapaPersonagens),
        efeitos: List.unmodifiable(listaEfeitos),
        areasPersistentes: Map.unmodifiable(mapaAreas),
      ),
      eventosArea: List.unmodifiable(eventos),
    );
  }

  /// R47 (Caso de Borda 32): Remove um token do mapa SEM encerrar os efeitos que pertencem ao personagem.
  EstadoMundoHabilidades removerTokenDoMapa({
    required EstadoMundoHabilidades mundo,
    required String tokenId,
  }) {
    final mapaAlvos = Map<String, AlvoMapa>.from(mundo.alvosNoMapa)
      ..remove(tokenId);
    return mundo.copyWith(alvosNoMapa: Map.unmodifiable(mapaAlvos));
  }

  /// R22, R29, R45 e R49: Coleta todos os modificadores ativos (de habilidades passivas + efeitos em estado `ATIVO`,
  /// ignorando efeitos `DORMENTE` ou finalizados) para `alvoId` e aplica as regras de acúmulo do [ModificadorEngine].
  List<ModificadorAplicado> obterModificadoresResolvidosParaAlvo({
    required EstadoMundoHabilidades mundo,
    required String alvoId,
    String? caracteristica,
    List<Habilidade> habilidadesPassivas = const [],
    List<ModificadorAplicado> modificadoresExtras = const [],
  }) {
    final candidatos = <ModificadorAplicado>[];

    // 1. Habilidades PASSIVAS (R22)
    for (final hab in habilidadesPassivas) {
      if (hab.tipo != TipoHabilidade.passiva) continue;
      for (final m in hab.modificadoresGerados) {
        candidatos.add(m.copyWith(alvoId: alvoId));
      }
    }

    // 2. Efeitos ATIVOS (R45: efeitos DORMENTE não aplicam modificadores!)
    for (final ef in mundo.efeitos) {
      if (ef.estado != EstadoEfeito.ativo) continue;
      if (!ef.alvos.contains(alvoId)) continue;
      for (final m in ef.modificadores) {
        if (m.alvoId == null || m.alvoId == alvoId) {
          candidatos.add(m.copyWith(efeitoId: ef.id, alvoId: alvoId));
        }
      }
    }

    // 3. Modificadores extras avulsos (armadura, escudo, itens, atributos)
    for (final m in modificadoresExtras) {
      candidatos.add(m.copyWith(alvoId: m.alvoId ?? alvoId));
    }

    final filtradosCaract = caracteristica == null
        ? candidatos
        : candidatos
            .where(
              (m) =>
                  m.alvoCaracteristica.trim().toUpperCase() ==
                  caracteristica.trim().toUpperCase(),
            )
            .toList();

    return modificadorEngine.resolverModificadores(
      filtradosCaract,
      efeitosAtivosIds: mundo.efeitosAtivosIds,
    );
  }
}
