import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/entities/combate/grid_tatico.dart';
import '../../../../domain/entities/mestre/modelos_mestre.dart';
import '../../../controllers/mestre_controller/mestre_cubit.dart';
import '../../../controllers/mestre_controller/mestre_state.dart';
import '../../../widgets/app_safe_scaffold.dart';
import '../theme/mestre_theme.dart';
import 'mestre_battlemap_widget.dart';
import 'tela_bestiario_mestre.dart';

/// Ferramenta ativa na Mesa de Jogo (Parte 4)
enum FerramentaMesa {
  selecionarMover('Selecionar / Mover', Icons.near_me_outlined),
  adicionarToken('Adicionar Token', Icons.person_add_alt_1_outlined),
  bestiario('Bestiário', Icons.menu_book_outlined),
  fogOfWar('Fog of War', Icons.cloud_outlined),
  medirDistancia('Medir Distância', Icons.straighten_outlined),
  pings('Pings e Marcadores', Icons.place_outlined),
  visao('Mestre ⇄ Jogador', Icons.visibility_outlined);

  final String rotulo;
  final IconData icone;
  const FerramentaMesa(this.rotulo, this.icone);
}

/// PARTE 4 — Tela "Mesa de jogo" (mapa selecionado) (Tormenta 20 - Android/Flutter)
/// Canvas ocupa quase toda a tela com UI mínima e translúcida.
class TelaMesaJogo extends StatefulWidget {
  final MestreCubit cubit;
  final VoidCallback onVoltarBiblioteca;

  const TelaMesaJogo({
    super.key,
    required this.cubit,
    required this.onVoltarBiblioteca,
  });

  @override
  State<TelaMesaJogo> createState() => _TelaMesaJogoState();
}

class _TelaMesaJogoState extends State<TelaMesaJogo> {
  FerramentaMesa _ferramentaAtiva = FerramentaMesa.selecionarMover;
  bool _barraMobileExpandida = false;
  bool _fogModoRevelar = true; // true: revelar, false: ocultar
  bool _painelIniciativaAberto = false;
  Offset? _posicaoMiniFicha;
  bool? _miniFichaMinimizada;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<MestreCubit, MestreState, bool>(
      bloc: widget.cubit,
      selector: (s) => s.mapaAtual == null,
      builder: (context, semMapa) {
        if (semMapa) {
          return Scaffold(
            backgroundColor: MestreCores.escuroBackground,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Nenhum mapa selecionado.',
                    style: TextStyle(color: MestreCores.escuroOnSurface),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: widget.onVoltarBiblioteca,
                    child: const Text('Voltar à Biblioteca de Mapas'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxW = constraints.maxWidth;
                final maxH = constraints.maxHeight;

                return Stack(
                  children: [
                    // 1. O CANVAS DO MAPA OCUPA QUASE TODA A TELA
                    Positioned.fill(
                      child: MestreBattlemapWidget(
                        cubit: widget.cubit,
                        modoMedicao:
                            _ferramentaAtiva == FerramentaMesa.medirDistancia,
                        modoPing: _ferramentaAtiva == FerramentaMesa.pings,
                        fogModoRevelar: _fogModoRevelar,
                      ),
                    ),

                    // Medição de Distância (só reconstrói quando origem/destino mudarem)
                    Positioned(
                      bottom: 24,
                      left: 20,
                      right: 20,
                      child: BlocSelector<MestreCubit, MestreState,
                          ({Posicao2D? orig, Posicao2D? dest})>(
                        bloc: widget.cubit,
                        selector: (s) => (
                          orig: s.pontoOrigemMedicao,
                          dest: s.pontoDestinoMedicao,
                        ),
                        builder: (context, medicao) {
                          if (_ferramentaAtiva !=
                                  FerramentaMesa.medirDistancia ||
                              medicao.orig == null) {
                            return const SizedBox.shrink();
                          }
                          return _buildOverlayMedicaoDistancia(
                            context,
                            medicao.orig!,
                            medicao.dest,
                          );
                        },
                      ),
                    ),

                    // 2. TOPO TRANSLÚCIDO MÍNIMO
                    Positioned(
                      top: 8,
                      left: 8,
                      right: 8,
                      child: _buildBarraSuperiorTranslucida(context),
                    ),

                    // 2b. RASTREADOR DE INICIATIVA / TURNOS
                    Positioned(
                      top: 66,
                      left: maxW >= 600 ? 76 : 8,
                      right: 8,
                      child: _buildBarraIniciativa(context),
                    ),

                    // 3. BARRA DE FERRAMENTAS RESPONSIVA
                    if (maxW >= 600)
                      Positioned(
                        left: 12,
                        top: 80,
                        bottom: 80,
                        child: _buildBarraVerticalTablet(context),
                      )
                    else
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: _buildBarraFlutuanteMobile(context),
                      ),

                    // Sub-barra contextual do Fog of War
                    if (_ferramentaAtiva == FerramentaMesa.fogOfWar)
                      Positioned(
                        bottom: 20,
                        left: 20,
                        child: _buildSubBarraFogOfWar(context),
                      ),

                    // 4. MINI FICHA FLUTUANTE ARRASTÁVEL DO TOKEN SELECIONADO
                    BlocSelector<MestreCubit, MestreState, TokenNoMapa?>(
                      bloc: widget.cubit,
                      selector: (s) {
                        final id = s.tokenSelecionadoParaMoverId;
                        final mapa = s.mapaAtual;
                        if (id == null || mapa == null) return null;
                        return mapa.tokens.where((t) => t.id == id).firstOrNull;
                      },
                      builder: (context, token) {
                        if (token == null) {
                          return const Positioned(
                            left: 0,
                            top: 0,
                            width: 0,
                            height: 0,
                            child: SizedBox.shrink(),
                          );
                        }
                        return _buildMiniFichaFlutuante(
                          context,
                          token,
                          maxW,
                          maxH,
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // BARRA SUPERIOR TRANSLÚCIDA
  // ---------------------------------------------------------------------------

  Widget _buildBarraSuperiorTranslucida(BuildContext context) {
    return BlocSelector<
        MestreCubit,
        MestreState,
        ({
          String nomeMapa,
          bool salaAberta,
          int conectados,
          int total,
          bool enviando,
          bool enviado,
          bool emCombate,
          int rodada,
        })>(
      bloc: widget.cubit,
      selector: (s) {
        final sessao = s.sessaoAtual;
        final mapa = s.mapaAtual;
        return (
          nomeMapa: mapa?.nome ?? 'Mapa',
          salaAberta: s.statusLan != StatusConexaoLan.desligado,
          conectados:
              sessao?.elenco.where((e) => e.conectadoViaLan).length ?? 0,
          total: sessao?.elenco.length ?? 0,
          enviando: s.enviandoMapaAosJogadores,
          enviado: s.ultimoEnvioMapa != null,
          emCombate: mapa?.tokenTurnoAtualId != null,
          rodada: mapa?.rodadaCombate ?? 1,
        );
      },
      builder: (context, info) {
        final corPonto = info.salaAberta
            ? MestreCores.statusOnlineEscuro
            : MestreCores.statusOffline;
        final iniciativaVisivel = _painelIniciativaAberto || info.emCombate;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: MestreCores.escuroSurface.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8)],
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: MestreCores.escuroOnSurface,
                  size: 20,
                ),
                tooltip: 'Biblioteca de Mapas',
                onPressed: widget.onVoltarBiblioteca,
              ),
              const SizedBox(width: 4),
              // Seletor de Mapa
              Expanded(
                child: InkWell(
                  onTap: () => _exibirSheetTrocarMapa(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            info.nomeMapa,
                            style: const TextStyle(
                              fontFamily: 'serif',
                              color: MestreCores.escuroOnSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          Icons.arrow_drop_down,
                          color: MestreCores.escuroOuro,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Botão do Rastreador de Iniciativa
              Tooltip(
                message: 'Rastreador de Iniciativa',
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => setState(
                    () => _painelIniciativaAberto = !_painelIniciativaAberto,
                  ),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: iniciativaVisivel
                          ? MestreCores.escuroVinho
                          : MestreCores.escuroSurfaceContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: iniciativaVisivel
                            ? MestreCores.escuroOuro
                            : MestreCores.escuroOutline,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.sports_kabaddi_outlined,
                          size: 14,
                          color: iniciativaVisivel
                              ? MestreCores.escuroOuro
                              : MestreCores.escuroOnSurface,
                        ),
                        if (info.emCombate) ...[
                          const SizedBox(width: 4),
                          Text(
                            'Rd ${info.rodada}',
                            style: const TextStyle(
                              color: MestreCores.escuroOuro,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Indicador interativo da LAN (toque abre/encerra a sala LAN)
              Tooltip(
                message: info.salaAberta
                    ? 'Sala LAN aberta (toque para encerrar)'
                    : 'Sala LAN fechada (toque para abrir)',
                child: InkWell(
                  key: const Key('badge_lan_mesa_jogo'),
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => widget.cubit.alternarServidorLan(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: MestreCores.escuroSurfaceContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: info.salaAberta
                            ? MestreCores.statusOnlineEscuro
                            : MestreCores.escuroOutline,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 7, color: corPonto),
                        const SizedBox(width: 5),
                        Text(
                          '${info.conectados}/${info.total}',
                          style: MestreCores.estiloMono.copyWith(
                            color: MestreCores.escuroOnSurface,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Botão [Enviar mapa aos jogadores]
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: info.enviando
                      ? MestreCores.escuroVinho
                      : MestreCores.escuroOuro,
                  foregroundColor: info.enviando
                      ? Colors.white
                      : MestreCores.escuroOuroTexto,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: info.enviando
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 14),
                label: Text(
                  info.enviando
                      ? 'Enviando…'
                      : (info.enviado ? 'Enviado!' : 'Enviar aos jogadores'),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () => widget.cubit.enviarMapaAosJogadores(),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // RASTREADOR DE INICIATIVA E TURNOS
  // ---------------------------------------------------------------------------

  Widget _buildBarraIniciativa(BuildContext context) {
    return BlocSelector<MestreCubit, MestreState, MapaBatalhaMestre?>(
      bloc: widget.cubit,
      selector: (s) => s.mapaAtual,
      builder: (context, mapa) {
        if (mapa == null) return const SizedBox.shrink();
        final emCombate = mapa.tokenTurnoAtualId != null;
        if (!_painelIniciativaAberto && !emCombate) {
          return const SizedBox.shrink();
        }
        final ordenados = MestreCubit.ordenarTokensPorIniciativa(mapa.tokens);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: MestreCores.escuroSurface.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: emCombate
                  ? MestreCores.escuroOuro.withValues(alpha: 0.65)
                  : Colors.white12,
            ),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8)],
          ),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: MestreCores.escuroVinho,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Rd ${mapa.rodadaCombate}',
                  style: const TextStyle(
                    color: MestreCores.escuroOuro,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: MestreCores.escuroOuro,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                icon: const Icon(Icons.casino_outlined, size: 15),
                label: const Text(
                  'Rolar',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                onPressed: ordenados.isEmpty
                    ? null
                    : () {
                        setState(() => _painelIniciativaAberto = true);
                        widget.cubit.rolarIniciativaCena();
                      },
              ),
              const SizedBox(width: 4),
              Expanded(
                child: ordenados.isEmpty
                    ? const Text(
                        'Adicione combatentes ao mapa para iniciar a fila.',
                        style: TextStyle(
                          color: MestreCores.escuroOnSurfaceVariant,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ordenados.map((t) {
                            final ativo = t.id == mapa.tokenTurnoAtualId;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () {
                                  if (widget.cubit.state
                                          .tokenSelecionadoParaMoverId !=
                                      t.id) {
                                    widget.cubit.aoClicarTokenNoMapa(t);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: ativo
                                        ? MestreCores.escuroVinho
                                        : MestreCores.escuroSurfaceContainer,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: ativo
                                          ? MestreCores.escuroOuro
                                          : MestreCores.escuroOutline,
                                      width: ativo ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      InkWell(
                                        onTap: () =>
                                            _editarIniciativaDialog(context, t),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black38,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '${t.iniciativa ?? '–'}',
                                            style: MestreCores.estiloMono
                                                .copyWith(
                                              color: ativo
                                                  ? MestreCores.escuroOuro
                                                  : MestreCores
                                                      .escuroOnSurface,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        t.nome,
                                        style: TextStyle(
                                          color: ativo
                                              ? Colors.white
                                              : MestreCores.escuroOnSurface,
                                          fontSize: 11,
                                          fontWeight: ativo
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          decoration: t.pvAtual <= 0
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
              ),
              const SizedBox(width: 4),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: MestreCores.escuroOuro,
                  foregroundColor: MestreCores.escuroOuroTexto,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                icon: const Icon(Icons.skip_next, size: 15),
                label: const Text(
                  'Próx.',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                onPressed:
                    ordenados.isEmpty ? null : () => widget.cubit.avancarTurno(),
              ),
              if (emCombate)
                IconButton(
                  icon: const Icon(
                    Icons.stop_circle_outlined,
                    size: 18,
                    color: MestreCores.escuroOnSurfaceVariant,
                  ),
                  tooltip: 'Encerrar combate',
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    widget.cubit.encerrarCombate();
                    setState(() => _painelIniciativaAberto = false);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editarIniciativaDialog(
    BuildContext context,
    TokenNoMapa token,
  ) async {
    final novoValor = await showDialog<int>(
      context: context,
      builder: (_) => _DialogEditarIniciativa(token: token),
    );
    if (novoValor != null) {
      widget.cubit.definirIniciativaToken(token.id, novoValor);
    }
  }

  // ---------------------------------------------------------------------------
  // BARRA DE FERRAMENTAS: TABLET (VERTICAL 56 DP)
  // ---------------------------------------------------------------------------

  Widget _buildBarraVerticalTablet(BuildContext context) {
    return BlocSelector<MestreCubit, MestreState, bool>(
      bloc: widget.cubit,
      selector: (s) => s.estaEmPreviewJogador,
      builder: (context, emPreviewJogador) {
        return Container(
          width: 56,
          decoration: BoxDecoration(
            color: MestreCores.escuroSurface.withValues(alpha: 0.90),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white12),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10)],
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: FerramentaMesa.values.map((f) {
                  final sel = f == FerramentaMesa.visao
                      ? emPreviewJogador
                      : _ferramentaAtiva == f;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: IconButton(
                      icon: Icon(f.icone, size: 22),
                      color: sel
                          ? MestreCores.escuroOuro
                          : MestreCores.escuroOnSurfaceVariant,
                      style: IconButton.styleFrom(
                        backgroundColor:
                            sel ? MestreCores.escuroVinho : Colors.transparent,
                      ),
                      tooltip: f.rotulo,
                      onPressed: () => _selecionarFerramenta(f),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // BARRA DE FERRAMENTAS: CELULAR (BOTÃO FLUTUANTE EXPANSÍVEL)
  // ---------------------------------------------------------------------------

  Widget _buildBarraFlutuanteMobile(BuildContext context) {
    return BlocSelector<MestreCubit, MestreState, bool>(
      bloc: widget.cubit,
      selector: (s) => s.estaEmPreviewJogador,
      builder: (context, emPreviewJogador) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (_barraMobileExpandida) ...[
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: MestreCores.escuroSurface.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: FerramentaMesa.values.map((f) {
                    final sel = f == FerramentaMesa.visao
                        ? emPreviewJogador
                        : _ferramentaAtiva == f;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: IconButton(
                        icon: Icon(f.icone, size: 20),
                        color: sel
                            ? MestreCores.escuroOuro
                            : MestreCores.escuroOnSurfaceVariant,
                        style: IconButton.styleFrom(
                          backgroundColor: sel
                              ? MestreCores.escuroVinho
                              : Colors.transparent,
                        ),
                        tooltip: f.rotulo,
                        onPressed: () {
                          _selecionarFerramenta(f);
                          setState(() => _barraMobileExpandida = false);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
            ],
            FloatingActionButton.small(
              backgroundColor: MestreCores.escuroOuro,
              foregroundColor: MestreCores.escuroOuroTexto,
              child: Icon(
                _barraMobileExpandida ? Icons.close : _ferramentaAtiva.icone,
              ),
              onPressed: () =>
                  setState(() => _barraMobileExpandida = !_barraMobileExpandida),
            ),
          ],
        );
      },
    );
  }

  void _selecionarFerramenta(FerramentaMesa f) {
    if (f == FerramentaMesa.visao) {
      widget.cubit.alternarVisaoMestreJogador();
      return;
    }

    if (f == FerramentaMesa.adicionarToken) {
      _exibirSheetCriarTokenCombatente(context, abaInicial: 0);
      return;
    }

    if (f == FerramentaMesa.bestiario) {
      _exibirSheetCriarTokenCombatente(context, abaInicial: 1);
      return;
    }

    if (_ferramentaAtiva == FerramentaMesa.medirDistancia &&
        f != FerramentaMesa.medirDistancia) {
      widget.cubit.limparMedicao();
    }

    setState(() => _ferramentaAtiva = f);

    if (f == FerramentaMesa.selecionarMover) {
      widget.cubit.selecionarFerramentaMapa(
        FerramentaMapaMestre.moverPersonagens,
      );
    } else if (f == FerramentaMesa.fogOfWar) {
      widget.cubit.selecionarFerramentaMapa(FerramentaMapaMestre.nevoaDeGuerra);
    } else if (f == FerramentaMesa.medirDistancia ||
        f == FerramentaMesa.pings) {
      widget.cubit.selecionarFerramentaMapa(
        FerramentaMapaMestre.moverPersonagens,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // SUB-BARRA FOG OF WAR (REVELAR / OCULTAR / REVELAR TUDO / OCULTAR TUDO)
  // ---------------------------------------------------------------------------

  Widget _buildSubBarraFogOfWar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: MestreCores.escuroSurface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ChoiceChip(
            label: const Text('Revelar', style: TextStyle(fontSize: 11)),
            selected: _fogModoRevelar,
            selectedColor: MestreCores.escuroOuro,
            onSelected: (_) => setState(() => _fogModoRevelar = true),
          ),
          const SizedBox(width: 6),
          ChoiceChip(
            label: const Text('Ocultar', style: TextStyle(fontSize: 11)),
            selected: !_fogModoRevelar,
            selectedColor: MestreCores.statusAlertaEscuro,
            onSelected: (_) => setState(() => _fogModoRevelar = false),
          ),
          const SizedBox(width: 10),
          TextButton.icon(
            icon: const Icon(Icons.wb_sunny_outlined, size: 14),
            label: const Text('Revelar tudo', style: TextStyle(fontSize: 11)),
            style: TextButton.styleFrom(foregroundColor: MestreCores.escuroOuro),
            onPressed: () => widget.cubit.revelarTodoMapa(),
          ),
          TextButton.icon(
            icon: const Icon(Icons.nights_stay_outlined, size: 14),
            label: const Text('Ocultar tudo', style: TextStyle(fontSize: 11)),
            style: TextButton.styleFrom(
              foregroundColor: MestreCores.escuroOnSurfaceVariant,
            ),
            onPressed: () => widget.cubit.ocultarTodoMapa(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // OVERLAY MEDIÇÃO DE DISTÂNCIA
  // ---------------------------------------------------------------------------

  Widget _buildOverlayMedicaoDistancia(
    BuildContext context,
    Posicao2D orig,
    Posicao2D? dest,
  ) {
    final String textoMedicao;
    if (dest == null) {
      textoMedicao =
          'Origem (${orig.x}, ${orig.y}) — toque no destino para medir';
    } else {
      final dx = (dest.x - orig.x).abs();
      final dy = (dest.y - orig.y).abs();
      final diagonais = min(dx, dy);
      final retas = (dx - dy).abs();
      final metros = (retas * 1.5) + (diagonais * 3.0); // Regra diagonal 3m T20
      textoMedicao =
          'Distância: ${metros.toStringAsFixed(1)} metros ($retas retas + $diagonais diag)';
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: MestreCores.escuroSurface.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: MestreCores.escuroOuro),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.straighten,
              color: MestreCores.escuroOuro,
              size: 20,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                textoMedicao,
                style: const TextStyle(
                  color: MestreCores.escuroOnSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(
                Icons.close,
                size: 16,
                color: MestreCores.escuroOnSurfaceVariant,
              ),
              onPressed: () => widget.cubit.limparMedicao(),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MINI FICHA FLUTUANTE DO TOKEN SELECIONADO (ARRASTÁVEL E MINIMIZÁVEL)
  // ---------------------------------------------------------------------------

  Widget _buildMiniFichaFlutuante(
    BuildContext context,
    TokenNoMapa token,
    double maxW,
    double maxH,
  ) {
    final nomeTrim = token.nome.trim();
    final inicial =
        nomeTrim.isEmpty ? '?' : nomeTrim.substring(0, 1).toUpperCase();
    final monstro = token.monstro;
    final minimizada = _miniFichaMinimizada ?? token.ehHeroi;

    final ehTablet = maxW >= 600;
    final larguraCard = ehTablet ? 344.0 : (maxW - 16).clamp(240.0, 380.0);
    final maxLeft = (maxW - larguraCard - 8.0).clamp(8.0, maxW);
    final maxTop = (maxH - 68.0).clamp(68.0, maxH);

    final defaultLeft =
        ehTablet ? (maxW - larguraCard - 12.0).clamp(8.0, maxLeft) : (maxW - larguraCard) / 2;
    final defaultTop =
        ehTablet ? 68.0 : (maxH - 270.0).clamp(68.0, maxTop);

    final posAtual = _posicaoMiniFicha ?? Offset(defaultLeft, defaultTop);
    final left = posAtual.dx.clamp(8.0, maxLeft);
    final top = posAtual.dy.clamp(64.0, maxTop);
    final maxHeightDisponivel = (maxH - top - 8.0).clamp(110.0, maxH * 0.62);

    return Positioned(
      left: left,
      top: top,
      width: larguraCard,
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(maxHeight: maxHeightDisponivel),
          padding: const EdgeInsets.fromLTRB(10, 8, 8, 10),
          decoration: BoxDecoration(
            color: MestreCores.escuroSurface.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: MestreCores.escuroOutline),
            boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 14)],
          ),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Cabeçalho arrastável (handle livre no mapa)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanUpdate: (details) {
                      setState(() {
                        final base =
                            _posicaoMiniFicha ?? Offset(defaultLeft, defaultTop);
                        _posicaoMiniFicha = Offset(
                          (base.dx + details.delta.dx).clamp(8.0, maxLeft),
                          (base.dy + details.delta.dy).clamp(64.0, maxTop),
                        );
                      });
                    },
                    child: Row(
                      children: [
                        const Tooltip(
                          message: 'Arrastar mini ficha',
                          child: Icon(
                            Icons.drag_indicator,
                            size: 18,
                            color: MestreCores.escuroOnSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 4),
                        CircleAvatar(
                          backgroundColor: token.ehHeroi
                              ? MestreCores.escuroVinho
                              : MestreCores.statusAlertaEscuro,
                          radius: 15,
                          child: Text(
                            inicial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                token.nome.isEmpty ? 'Combatente' : token.nome,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: MestreCores.escuroOnSurface,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                minimizada
                                    ? 'PV ${token.pvAtual}/${token.pvMax} • Def ${token.defesa} • ${token.deslocamentoMetros}m'
                                    : [
                                        if (monstro != null)
                                          'ND ${monstro.nd} (${monstro.papel.label})',
                                        'Def: ${token.defesa}',
                                        'Desl: ${token.deslocamentoMetros}m',
                                        if (token.tamanhoQuadrados > 1)
                                          '${token.tamanhoQuadrados}×${token.tamanhoQuadrados}',
                                        token.visivelParaJogadores
                                            ? 'Visível'
                                            : 'Oculto',
                                      ].join(' • '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: MestreCores.escuroOnSurfaceVariant,
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!minimizada) ...[
                          IconButton(
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              token.visivelParaJogadores
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              size: 18,
                              color: token.visivelParaJogadores
                                  ? MestreCores.statusOnlineEscuro
                                  : MestreCores.statusAlertaEscuro,
                            ),
                            tooltip: 'Mostrar/Ocultar para jogadores',
                            onPressed: () =>
                                widget.cubit.alternarVisibilidadeToken(token.id),
                          ),
                          IconButton(
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: MestreCores.statusAlertaEscuro,
                            ),
                            tooltip: 'Remover do mapa',
                            onPressed: () =>
                                widget.cubit.removerTokenDoMapa(token.id),
                          ),
                        ],
                        IconButton(
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            minimizada
                                ? Icons.expand_more
                                : Icons.expand_less,
                            size: 20,
                            color: MestreCores.escuroOuro,
                          ),
                          tooltip: minimizada
                              ? 'Expandir ficha'
                              : 'Minimizar ficha',
                          onPressed: () => setState(
                            () => _miniFichaMinimizada = !minimizada,
                          ),
                        ),
                        IconButton(
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.close,
                            size: 18,
                            color: MestreCores.escuroOnSurfaceVariant,
                          ),
                          tooltip: 'Desselecionar token',
                          onPressed: () =>
                              widget.cubit.aoClicarTokenNoMapa(token),
                        ),
                      ],
                    ),
                  ),

                  if (!minimizada) ...[
                    const SizedBox(height: 8),

                    // PV e PM com botões rápidos (+/-) e toque para lote/RD
                    Row(
                      children: [
                        Expanded(
                          child: _buildAjustePontos(
                            'PV',
                            token.pvAtual,
                            token.pvMax,
                            Colors.redAccent,
                            (delta) {
                              widget.cubit.ajustarPvToken(token.id, delta);
                            },
                            onEditarEmLote: () => _exibirSheetAjustePontosEmLote(
                              context,
                              token: token,
                              rotulo: 'PV',
                              atual: token.pvAtual,
                              maxValor: token.pvMax,
                              cor: Colors.redAccent,
                              rd: token.monstro?.rd ?? const {},
                              onDelta: (d) =>
                                  widget.cubit.ajustarPvToken(token.id, d),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildAjustePontos(
                            'PM',
                            token.pmAtual,
                            token.pmMax,
                            Colors.blueAccent,
                            (delta) {
                              widget.cubit.ajustarPmToken(token.id, delta);
                            },
                            onEditarEmLote: () => _exibirSheetAjustePontosEmLote(
                              context,
                              token: token,
                              rotulo: 'PM',
                              atual: token.pmAtual,
                              maxValor: token.pmMax,
                              cor: Colors.blueAccent,
                              rd: const {},
                              onDelta: (d) =>
                                  widget.cubit.ajustarPmToken(token.id, d),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Condições Ativas (chips)
                    Row(
                      children: [
                        const Text(
                          'Condições: ',
                          style: TextStyle(
                            color: MestreCores.escuroOnSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                        Expanded(
                          child: Wrap(
                            spacing: 4,
                            children: [
                              ...token.condicoes.map(
                                (c) => Chip(
                                  label: Text(
                                    c,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  onDeleted: () => widget.cubit
                                      .removerCondicaoToken(token.id, c),
                                ),
                              ),
                              ActionChip(
                                label: const Text(
                                  '+ Condição',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: MestreCores.escuroOuro,
                                  ),
                                ),
                                visualDensity: VisualDensity.compact,
                                onPressed: () =>
                                    _exibirDialogAdicionarCondicao(
                                      context,
                                      token,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    if (monstro != null) ...[
                      const SizedBox(height: 4),
                      Theme(
                        data: ThemeData.dark(useMaterial3: true),
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          childrenPadding: const EdgeInsets.only(top: 4),
                          dense: true,
                          iconColor: MestreCores.escuroOuro,
                          collapsedIconColor: MestreCores.escuroOuro,
                          title: const Text(
                            'Ficha Rápida de Combate',
                            style: TextStyle(
                              color: MestreCores.escuroOuro,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          children: [
                            FichaRapidaMonstroCard(
                              monstro: monstro,
                              habilidadesRecargaGastas: token.habilidadesGastas,
                              onAlternarRecarga: (nomeHab) => widget.cubit
                                  .alternarRecargaHabilidadeToken(
                                    token.id,
                                    nomeHab,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAjustePontos(
    String rotulo,
    int atual,
    int maxValor,
    Color cor,
    ValueChanged<int> onDelta, {
    VoidCallback? onEditarEmLote,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: MestreCores.escuroSurfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: onEditarEmLote,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '$rotulo: $atual/$maxValor',
                  maxLines: 1,
                  style: TextStyle(
                    color: cor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    decoration: onEditarEmLote != null
                        ? TextDecoration.underline
                        : null,
                    decorationStyle: TextDecorationStyle.dotted,
                    decorationColor: cor.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () => onDelta(-1),
                child: const Padding(
                  padding: EdgeInsets.all(3),
                  child: Icon(Icons.remove, size: 16, color: Colors.white70),
                ),
              ),
              InkWell(
                onTap: () => onDelta(1),
                child: const Padding(
                  padding: EdgeInsets.all(3),
                  child: Icon(Icons.add, size: 16, color: Colors.white70),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _exibirSheetAjustePontosEmLote(
    BuildContext context, {
    required TokenNoMapa token,
    required String rotulo,
    required int atual,
    required int maxValor,
    required Color cor,
    required Map<String, int> rd,
    required ValueChanged<int> onDelta,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: MestreCores.escuroSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _SheetAjustePontosEmLote(
        tokenNome: token.nome,
        rotulo: rotulo,
        atual: atual,
        maxValor: maxValor,
        cor: cor,
        rd: rd,
        onDelta: onDelta,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SHEET: CRIAR INIMIGO / NPC OU ESCOLHER DO BESTIÁRIO (PARTE 4)
  // ---------------------------------------------------------------------------

  void _exibirSheetCriarTokenCombatente(
    BuildContext context, {
    int abaInicial = 0,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: MestreCores.escuroSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _SheetCriarTokenCombatente(
        cubit: widget.cubit,
        abaInicial: abaInicial,
      ),
    );
  }

  void _exibirDialogAdicionarCondicao(BuildContext context, TokenNoMapa token) {
    const condicoesComuns = [
      'Abalado',
      'Caído',
      'Cego',
      'Desprevenido',
      'Enfeitiçado',
      'Fatigado',
      'Furtivo',
      'Imobilizado',
      'Inconsciente',
      'Lento',
      'Sangrando',
      'Surpreendido',
      'Vulnerável',
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: MestreCores.escuroSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => AppBottomSheetContainer(
        scrollable: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Aplicar Condição T20',
              style: TextStyle(
                fontFamily: 'serif',
                color: MestreCores.escuroOnSurface,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: condicoesComuns.map((c) {
                return ActionChip(
                  label: Text(c, style: const TextStyle(fontSize: 11)),
                  onPressed: () {
                    widget.cubit.adicionarCondicaoToken(token.id, c);
                    Navigator.pop(ctx);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _exibirSheetTrocarMapa(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: MestreCores.escuroSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => BlocBuilder<MestreCubit, MestreState>(
        bloc: widget.cubit,
        builder: (ctx, currentState) {
          final aventura = currentState.aventuraAtual;
          final mapaAtivoId = currentState.mapaAtual?.id;
          return AppBottomSheetContainer(
            scrollable: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Trocar Mapa Ativo',
                  style: TextStyle(
                    fontFamily: 'serif',
                    color: MestreCores.escuroOnSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                ...(aventura?.mapas ?? []).map(
                  (m) => ListTile(
                    title: Text(
                      m.nome,
                      style: const TextStyle(color: MestreCores.escuroOnSurface),
                    ),
                    subtitle: Text(
                      '${m.largura}×${m.altura} • ${m.tokens.length} combatentes',
                      style: const TextStyle(
                        color: MestreCores.escuroOnSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                    trailing: m.id == mapaAtivoId
                        ? const Icon(Icons.check, color: MestreCores.escuroOuro)
                        : null,
                    onTap: () {
                      widget.cubit.selecionarMapa(m.id);
                      Navigator.pop(ctx);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SheetCriarTokenCombatente extends StatefulWidget {
  final MestreCubit cubit;
  final int abaInicial;

  const _SheetCriarTokenCombatente({
    required this.cubit,
    this.abaInicial = 0,
  });

  @override
  State<_SheetCriarTokenCombatente> createState() =>
      _SheetCriarTokenCombatenteState();
}

class _SheetCriarTokenCombatenteState
    extends State<_SheetCriarTokenCombatente> {
  late final TextEditingController _nomeController;
  late final TextEditingController _pvController;
  late final TextEditingController _pmController;
  late final TextEditingController _defController;
  late final TextEditingController _iniController;

  TipoCombatenteMapa _tipo = TipoCombatenteMapa.inimigo;
  int _tamanho = 1;
  bool _visivelAosJogadores = false;
  int _duplicarN = 1;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: 'Ameaça de Arton');
    _pvController = TextEditingController(text: '20');
    _pmController = TextEditingController(text: '10');
    _defController = TextEditingController(text: '15');
    _iniController = TextEditingController(text: '10');
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _pvController.dispose();
    _pmController.dispose();
    _defController.dispose();
    _iniController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alturaModal = MediaQuery.sizeOf(context).height * 0.82;
    return DefaultTabController(
      length: 2,
      initialIndex: widget.abaInicial.clamp(0, 1),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: alturaModal,
          child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Adicionar Combatente ao Mapa',
                    style: TextStyle(
                      fontFamily: 'serif',
                      color: MestreCores.escuroOnSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: MestreCores.escuroOnSurfaceVariant,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const TabBar(
              indicatorColor: MestreCores.escuroOuro,
              labelColor: MestreCores.escuroOuro,
              unselectedLabelColor: MestreCores.escuroOnSurfaceVariant,
              tabs: [
                Tab(
                  icon: Icon(Icons.edit_outlined, size: 16),
                  text: 'Customizado',
                ),
                Tab(
                  icon: Icon(Icons.pets_outlined, size: 16),
                  text: 'Escolher do Bestiário',
                ),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 12,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Segmented Button: Inimigo / NPC / Aliado
          SegmentedButton<TipoCombatenteMapa>(
            segments: const [
              ButtonSegment(
                value: TipoCombatenteMapa.inimigo,
                label: Text('Inimigo'),
              ),
              ButtonSegment(
                value: TipoCombatenteMapa.npc,
                label: Text('NPC'),
              ),
              ButtonSegment(
                value: TipoCombatenteMapa.aliado,
                label: Text('Aliado'),
              ),
            ],
            selected: {_tipo},
            onSelectionChanged: (val) => setState(() => _tipo = val.first),
          ),
          const SizedBox(height: 10),

          TextField(
            controller: _nomeController,
            style: const TextStyle(
              color: MestreCores.escuroOnSurface,
              fontSize: 13,
            ),
            decoration: const InputDecoration(
              labelText: 'Nome da Criatura/NPC',
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: MestreCores.escuroOutline),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: MestreCores.escuroOuro),
              ),
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _pvController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    color: MestreCores.escuroOnSurface,
                    fontSize: 12,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'PV',
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: MestreCores.escuroOutline),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _pmController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    color: MestreCores.escuroOnSurface,
                    fontSize: 12,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'PM',
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: MestreCores.escuroOutline),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _defController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    color: MestreCores.escuroOnSurface,
                    fontSize: 12,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Defesa',
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: MestreCores.escuroOutline),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _iniController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    color: MestreCores.escuroOnSurface,
                    fontSize: 12,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Iniciativa',
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: MestreCores.escuroOutline),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Tamanho em Quadrados
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tamanho do Token:',
                style: TextStyle(
                  color: MestreCores.escuroOnSurface,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ChoiceChip(
                    label: const Text('1×1 Médio'),
                    selected: _tamanho == 1,
                    onSelected: (_) => setState(() => _tamanho = 1),
                  ),
                  ChoiceChip(
                    label: const Text('2×2 Grande'),
                    selected: _tamanho == 2,
                    onSelected: (_) => setState(() => _tamanho = 2),
                  ),
                  ChoiceChip(
                    label: const Text('3×3 Enorme'),
                    selected: _tamanho == 3,
                    onSelected: (_) => setState(() => _tamanho = 3),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Visível aos Jogadores',
              style: TextStyle(
                color: MestreCores.escuroOnSurface,
                fontSize: 12,
              ),
            ),
            value: _visivelAosJogadores,
            activeThumbColor: MestreCores.escuroOuro,
            onChanged: (val) => setState(() => _visivelAosJogadores = val),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Duplicar × N para grupos:',
                style: TextStyle(
                  color: MestreCores.escuroOnSurface,
                  fontSize: 12,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.remove,
                      size: 16,
                      color: MestreCores.escuroOuro,
                    ),
                    onPressed: _duplicarN > 1
                        ? () => setState(() => _duplicarN--)
                        : null,
                  ),
                  Text(
                    '$_duplicarN',
                    style: const TextStyle(
                      color: MestreCores.escuroOnSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.add,
                      size: 16,
                      color: MestreCores.escuroOuro,
                    ),
                    onPressed: _duplicarN < 8
                        ? () => setState(() => _duplicarN++)
                        : null,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: MestreCores.escuroOuro,
              foregroundColor: MestreCores.escuroOuroTexto,
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: () {
              final pv = int.tryParse(_pvController.text) ?? 20;
              final pm = int.tryParse(_pmController.text) ?? 10;
              final def = int.tryParse(_defController.text) ?? 15;
              final ini = int.tryParse(_iniController.text);
              final nomeBase = _nomeController.text.trim().isEmpty
                  ? 'Ameaça'
                  : _nomeController.text.trim();

              final mapa = widget.cubit.state.mapaAtual;
              final posInicial = mapa != null
                  ? Posicao2D(
                      (_tipo == TipoCombatenteMapa.aliado
                              ? 2
                              : mapa.largura - 2)
                          .clamp(0, mapa.largura - 1),
                      1.clamp(0, mapa.altura - 1),
                    )
                  : null;

              widget.cubit.adicionarTokenCustomizadoNoMapa(
                nome: nomeBase,
                ehHeroi: _tipo == TipoCombatenteMapa.heroi ||
                    _tipo == TipoCombatenteMapa.aliado,
                tipo: _tipo,
                pvMax: pv,
                pmMax: pm,
                defesa: def,
                iniciativa: ini,
                tamanhoQuadrados: _tamanho,
                ocultoParaJogadores: !_visivelAosJogadores,
                posicao: posInicial,
                quantidade: _duplicarN,
              );
              Navigator.pop(context);
            },
            child: Text(
              'Adicionar ($_duplicarN)',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
                      ],
                    ),
                  ),
                  Theme(
                    data: MestreCores.homeStyleTheme,
                    child: TelaBestiarioMestre(
                      cubit: widget.cubit,
                      onAmeacaAdicionada: (_) => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

class _DialogEditarIniciativa extends StatefulWidget {
  final TokenNoMapa token;

  const _DialogEditarIniciativa({required this.token});

  @override
  State<_DialogEditarIniciativa> createState() =>
      _DialogEditarIniciativaState();
}

class _DialogEditarIniciativaState extends State<_DialogEditarIniciativa> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.token.iniciativa?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: MestreCores.escuroSurface,
      title: Text(
        'Iniciativa de ${widget.token.nome}',
        style: const TextStyle(
          color: MestreCores.escuroOnSurface,
          fontSize: 15,
        ),
      ),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(signed: true),
        style: const TextStyle(color: MestreCores.escuroOnSurface),
        decoration: const InputDecoration(
          labelText: 'Valor da iniciativa',
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: MestreCores.escuroOutline),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: MestreCores.escuroOuro),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: MestreCores.escuroOuro,
            foregroundColor: MestreCores.escuroOuroTexto,
          ),
          onPressed: () {
            final parsed = int.tryParse(_ctrl.text.trim());
            if (parsed != null) Navigator.pop(context, parsed);
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _SheetAjustePontosEmLote extends StatefulWidget {
  final String tokenNome;
  final String rotulo;
  final int atual;
  final int maxValor;
  final Color cor;
  final Map<String, int> rd;
  final ValueChanged<int> onDelta;

  const _SheetAjustePontosEmLote({
    required this.tokenNome,
    required this.rotulo,
    required this.atual,
    required this.maxValor,
    required this.cor,
    required this.rd,
    required this.onDelta,
  });

  @override
  State<_SheetAjustePontosEmLote> createState() =>
      _SheetAjustePontosEmLoteState();
}

class _SheetAjustePontosEmLoteState extends State<_SheetAjustePontosEmLote> {
  late final TextEditingController _valorCtrl;
  String? _rdSelecionadaKey;

  @override
  void initState() {
    super.initState();
    _valorCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _valorCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rdValor = _rdSelecionadaKey != null
        ? (widget.rd[_rdSelecionadaKey] ?? 0)
        : 0;
    final valorDigitado = int.tryParse(_valorCtrl.text.trim()) ?? 0;
    final danoLiquido = max(0, valorDigitado - rdValor);

    return Theme(
      data: ThemeData.dark(useMaterial3: true),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${widget.rotulo} em lote • ${widget.tokenNome} (${widget.atual}/${widget.maxValor})',
              style: TextStyle(
                fontFamily: 'serif',
                color: widget.cor,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [-10, -5, 5, 10].map((atalho) {
                return OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        atalho < 0 ? Colors.redAccent : Colors.greenAccent,
                    side: BorderSide(
                      color: atalho < 0
                          ? Colors.redAccent.withValues(alpha: 0.6)
                          : Colors.greenAccent.withValues(alpha: 0.6),
                    ),
                  ),
                  onPressed: () {
                    widget.onDelta(atalho);
                    Navigator.pop(context);
                  },
                  child: Text(atalho > 0 ? '+$atalho' : '$atalho'),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _valorCtrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: MestreCores.escuroOnSurface),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: widget.rotulo == 'PV'
                    ? 'Valor de dano ou cura'
                    : 'Valor de gasto ou recuperação',
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: MestreCores.escuroOutline),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: MestreCores.escuroOuro),
                ),
              ),
            ),
            if (widget.rotulo == 'PV' && widget.rd.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text(
                'Aplicar RD ao dano:',
                style: TextStyle(
                  color: MestreCores.escuroOnSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ChoiceChip(
                    label: const Text('Sem RD'),
                    selected: _rdSelecionadaKey == null,
                    onSelected: (_) =>
                        setState(() => _rdSelecionadaKey = null),
                  ),
                  ...widget.rd.entries.map(
                    (e) => ChoiceChip(
                      label: Text('${e.key} ${e.value}'),
                      selected: _rdSelecionadaKey == e.key,
                      onSelected: (_) => setState(
                        () => _rdSelecionadaKey =
                            _rdSelecionadaKey == e.key ? null : e.key,
                      ),
                    ),
                  ),
                ],
              ),
              if (valorDigitado > 0 && rdValor > 0) ...[
                const SizedBox(height: 6),
                Text(
                  'Dano final com RD ($_rdSelecionadaKey $rdValor): $danoLiquido',
                  style: const TextStyle(
                    color: MestreCores.escuroOuro,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: valorDigitado <= 0
                        ? null
                        : () {
                            final perda = widget.rotulo == 'PV'
                                ? danoLiquido
                                : valorDigitado;
                            widget.onDelta(-perda);
                            Navigator.pop(context);
                          },
                    child: Text(
                      widget.rotulo == 'PV' ? 'Aplicar Dano' : 'Gastar PM',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: MestreCores.escuroOuro,
                      foregroundColor: MestreCores.escuroOuroTexto,
                    ),
                    onPressed: valorDigitado <= 0
                        ? null
                        : () {
                            widget.onDelta(valorDigitado);
                            Navigator.pop(context);
                          },
                    child: Text(
                      widget.rotulo == 'PV' ? 'Curar' : 'Recuperar',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
