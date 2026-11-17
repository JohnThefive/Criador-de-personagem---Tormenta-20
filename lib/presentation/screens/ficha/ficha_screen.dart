import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/entidade_sessao_lan/sessao_lan_modelos.dart';
import '../../../domain/entities/personagem/personagem.dart';
import '../../../domain/repositories/i_personagem_repository.dart';
import '../../../domain/services/powers_service/aprendizado_magia_service.dart';
import '../../../domain/services/sessao_lan/sessao_cliente_lan_service.dart';
import '../../../domain/services/sessao_lan/sessao_lan_transport.dart';
import '../../../domain/services/sessao_lan/sessao_loopback_transport.dart';
import '../../controllers/ficha_controller/ficha_cubit.dart';
import '../../controllers/ficha_controller/ficha_state.dart';
import '../../controllers/ficha_controller/sessao_jogador_cubit.dart';
import '../../controllers/ficha_controller/sessao_jogador_state.dart';
import '../../widgets/app_safe_scaffold.dart';

import 'widgets/aba_geral_view.dart';
import 'widgets/aba_habilidades_view.dart';
import 'widgets/aba_historia_view.dart';
import 'widgets/aba_inventario_view.dart';
import 'widgets/aba_magias_view.dart';
import 'widgets/aba_pericias_view.dart';
import 'widgets/aba_sessao_view.dart';
import 'widgets/ficha_banner_evolucao.dart';
import 'widgets/ficha_cabecalho_widget.dart';
import 'widgets/mapa_jogador_screen.dart';

/// Tela principal da Ficha do Personagem (Painel do Jogador).
///
/// Atua como coordenadora de alto nível, integrando o cabeçalho fixo,
/// banner de evolução pendente e o controlador das 7 abas de navegação.
class FichaScreen extends StatelessWidget {
  final Personagem personagemInicial;
  final IPersonagemRepository? repository;
  final SessaoClienteService? sessaoClienteService;
  final bool usarTransporteLan;
  final VoidCallback? onAbrirMapaMesa;

  const FichaScreen({
    super.key,
    required this.personagemInicial,
    this.repository,
    this.sessaoClienteService,
    this.usarTransporteLan = false,
    this.onAbrirMapaMesa,
  });

  @override
  Widget build(BuildContext context) {
    final gerenciarClienteInterno =
        sessaoClienteService == null && usarTransporteLan;
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => FichaCubit(
            personagemInicial: personagemInicial,
            repository: repository,
          ),
        ),
        BlocProvider(
          create: (ctx) => SessaoJogadorCubit(
            clienteService:
                sessaoClienteService ??
                (usarTransporteLan
                    ? SessaoClienteLanService()
                    : SessaoLoopbackTransport().cliente),
            lerFichaState: () => ctx.read<FichaCubit>().state,
            disposeClienteAoFechar: gerenciarClienteInterno,
          ),
        ),
      ],
      child: BlocListener<FichaCubit, FichaState>(
        listenWhen: (prev, curr) {
          final p1 = prev.personagem;
          final p2 = curr.personagem;
          return p1.pvAtual != p2.pvAtual ||
              p1.pvTotal != p2.pvTotal ||
              p1.pmAtual != p2.pmAtual ||
              p1.pmTotal != p2.pmTotal ||
              p1.defesaFinal != p2.defesaFinal;
        },
        listener: (ctx, state) {
          ctx.read<SessaoJogadorCubit>().sincronizarPersonagemAtual(state);
        },
        child: _FichaView(onAbrirMapaMesa: onAbrirMapaMesa),
      ),
    );
  }
}

/// Alias para manter retrocompatibilidade com código existente e testes.
typedef PainelJogadorScreen = FichaScreen;

class _FichaView extends StatefulWidget {
  final VoidCallback? onAbrirMapaMesa;

  const _FichaView({this.onAbrirMapaMesa});

  @override
  State<_FichaView> createState() => _FichaViewState();
}

class _FichaViewState extends State<_FichaView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final ScrollController _nestedScrollController = ScrollController();
  bool _mostrarMiniMapaNaFicha = false;
  bool _forcarExpandidoNoCompacto = false;

  static const List<({IconData icone, String rotulo})> _definicaoAbas = [
    (icone: Icons.shield_outlined, rotulo: 'Geral'),
    (icone: Icons.fact_check_outlined, rotulo: 'Perícias'),
    (icone: Icons.auto_awesome_outlined, rotulo: 'Habilidades'),
    (icone: Icons.menu_book_outlined, rotulo: 'Magias'),
    (icone: Icons.backpack_outlined, rotulo: 'Inventário'),
    (icone: Icons.edit_note_rounded, rotulo: 'Notas'),
    (icone: Icons.wifi_tethering_outlined, rotulo: 'Sessão'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _definicaoAbas.length, vsync: this);
  }

  @override
  void dispose() {
    _nestedScrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildBarraNomeTopo(BuildContext context, FichaCubit cubit) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Row(
        children: [
          IconButton(
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 19,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: BlocSelector<FichaCubit, FichaState, String>(
              selector: (state) => state.personagem.nome,
              builder: (context, nome) {
                return InkWell(
                  onTap: () => mostrarDialogoIdentidade(context, cubit),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            nome,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              letterSpacing: 0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.edit_outlined,
                          color: Colors.white70,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCabecalhoCompleto(BuildContext context) {
    return BlocBuilder<FichaCubit, FichaState>(
      buildWhen: (prev, curr) {
        final p1 = prev.personagem;
        final p2 = curr.personagem;
        return p1.nome != p2.nome ||
            p1.caminhoFoto != p2.caminhoFoto ||
            p1.alinhamento != p2.alinhamento ||
            p1.idade != p2.idade ||
            p1.nivelPersonagem != p2.nivelPersonagem ||
            p1.pvAtual != p2.pvAtual ||
            p1.pvTotal != p2.pvTotal ||
            p1.pmAtual != p2.pmAtual ||
            p1.pmTotal != p2.pmTotal ||
            p1.raca?.nome != p2.raca?.nome ||
            p1.origem?.nome != p2.origem?.nome ||
            p1.divindade?.nome != p2.divindade?.nome ||
            p1.classes != p2.classes ||
            p1.atributos != p2.atributos ||
            p1.dominadoPelaTormenta != p2.dominadoPelaTormenta;
      },
      builder: (context, state) =>
          FichaCabecalhoWidget(personagem: state.personagem),
    );
  }

  Widget _buildCabecalhoCompacto(
    BuildContext context, {
    VoidCallback? onExpandirDetalhes,
  }) {
    return BlocBuilder<FichaCubit, FichaState>(
      buildWhen: (prev, curr) {
        final p1 = prev.personagem;
        final p2 = curr.personagem;
        return p1.nome != p2.nome ||
            p1.caminhoFoto != p2.caminhoFoto ||
            p1.pvAtual != p2.pvAtual ||
            p1.pvTotal != p2.pvTotal ||
            p1.pmAtual != p2.pmAtual ||
            p1.pmTotal != p2.pmTotal;
      },
      builder: (context, state) => FichaCabecalhoCompactoWidget(
        personagem: state.personagem,
        onVoltar: () => Navigator.pop(context),
        onExpandirDetalhes: onExpandirDetalhes,
      ),
    );
  }

  Widget _buildBannerEMiniMapa(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BlocSelector<FichaCubit, FichaState, bool>(
          selector: (state) =>
              state.personagem.classes.any((c) => c.temPoderPendente) ||
              AprendizadoMagiaService.calcularMagiasPendentesPersonagem(
                    state.personagem,
                  ) >
                  0,
          builder: (context, temPendente) {
            if (!temPendente) return const SizedBox.shrink();
            return const FichaBannerEvolucao();
          },
        ),
        BlocBuilder<SessaoJogadorCubit, SessaoJogadorState>(
          builder: (context, sessaoState) {
            final snap = sessaoState.ultimoSnapshot;
            if (!sessaoState.estaConectado || snap == null) {
              return const SizedBox.shrink();
            }
            return _buildPainelMiniMapaFicha(context, snap);
          },
        ),
      ],
    );
  }

  Widget _buildTabBarBarra({bool arredondarTopo = true}) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: arredondarTopo
            ? const BorderRadius.vertical(top: Radius.circular(24))
            : BorderRadius.zero,
        border: const Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: const Color(0xFFD32F2F),
        indicatorWeight: 3,
        labelColor: const Color(0xFFD32F2F),
        unselectedLabelColor: const Color(0xFF64748B),
        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
        tabs: _definicaoAbas
            .map(
              (aba) => Tab(
                height: 42,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(aba.icone, size: 15),
                    const SizedBox(width: 4),
                    Text(aba.rotulo),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [
        const AbaGeralView(),
        const AbaPericiasView(),
        const AbaHabilidadesView(),
        const AbaMagiasView(),
        const AbaInventarioView(),
        const AbaHistoriaView(),
        AbaSessaoView(onAbrirMapa: widget.onAbrirMapaMesa),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const t20Red = Color(0xFFC62828);
    final cubit = context.read<FichaCubit>();
    final media = MediaQuery.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: T20SystemUi.estiloFicha,
      child: Scaffold(
        backgroundColor: t20Red,
        body: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final emPaisagem =
                  constraints.maxWidth > constraints.maxHeight ||
                  constraints.maxHeight < 520;

              // Em paisagem com largura >= 600 dp, usa coluna lateral fixa à esquerda
              // deixando ~88% da altura útil para o conteúdo das abas.
              if (emPaisagem && constraints.maxWidth >= 600) {
                final larguraLateral = (constraints.maxWidth * 0.34).clamp(
                  250.0,
                  320.0,
                );
                return Row(
                  children: [
                    SizedBox(
                      width: larguraLateral,
                      child: Column(
                        children: [
                          _buildBarraNomeTopo(context, cubit),
                          Expanded(
                            child: SingleChildScrollView(
                              padding: EdgeInsets.only(
                                bottom: MediaQuery.paddingOf(context).bottom + 12,
                              ),
                              child: Column(
                                children: [
                                  _buildCabecalhoCompleto(context),
                                  _buildBannerEMiniMapa(context),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(24),
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            _buildTabBarBarra(arredondarTopo: false),
                            Expanded(child: _buildTabBarView()),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }

              // Retrato (ou paisagem estreita < 600 dp): cabeçalho recolhível via NestedScrollView
              final textScale = media.textScaler.scale(1.0).clamp(1.0, 1.5);
              final compactHeaderHeight =
                  (78.0 + (textScale - 1.0) * 28.0).ceilToDouble();
              final tabBarHeight = 44.0;

              final temPendente = context.select<FichaCubit, bool>(
                (c) =>
                    c.state.personagem.classes.any((cl) => cl.temPoderPendente) ||
                    AprendizadoMagiaService.calcularMagiasPendentesPersonagem(
                          c.state.personagem,
                        ) >
                        0,
              );
              final dominadoTormenta = context.select<FichaCubit, bool>(
                (c) => c.state.personagem.dominadoPelaTormenta,
              );
              final temMiniMapa = context.select<SessaoJogadorCubit, bool>(
                (s) => s.state.estaConectado && s.state.ultimoSnapshot != null,
              );

              final extraEstreito = constraints.maxWidth < 350 ? 28.0 : 0.0;
              final baseExpandedTop =
                  44.0 +
                  (158.0 +
                          (dominadoTormenta ? 44.0 : 0.0) +
                          extraEstreito) *
                      (1 + (textScale - 1.0) * 0.45) +
                  (temPendente ? 54.0 * (1 + (textScale - 1.0) * 0.4) : 0.0) +
                  (temMiniMapa
                      ? (_mostrarMiniMapaNaFicha ? 236.0 : 50.0)
                      : 0.0);

              final comecarCompacto = emPaisagem && !_forcarExpandidoNoCompacto;
              final minExtent = compactHeaderHeight + tabBarHeight;
              final maxExtent = comecarCompacto
                  ? minExtent
                  : math.max(minExtent + 1.0, baseExpandedTop + tabBarHeight);

              return NestedScrollView(
                controller: _nestedScrollController,
                headerSliverBuilder: (innerContext, innerBoxIsScrolled) {
                  return [
                    SliverOverlapAbsorber(
                      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                        innerContext,
                      ),
                      sliver: SliverPersistentHeader(
                        pinned: true,
                        delegate: _FichaCabecalhoSliverDelegate(
                          minExtentValue: minExtent,
                          maxExtentValue: maxExtent,
                          tabBarHeight: tabBarHeight,
                          corFundoTopo: t20Red,
                          expandedBuilder: (context) => Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildBarraNomeTopo(context, cubit),
                              _buildCabecalhoCompleto(context),
                              _buildBannerEMiniMapa(context),
                            ],
                          ),
                          compactWidget: _buildCabecalhoCompacto(
                            context,
                            onExpandirDetalhes: () {
                              if (emPaisagem && !_forcarExpandidoNoCompacto) {
                                setState(
                                  () => _forcarExpandidoNoCompacto = true,
                                );
                                return;
                              }
                              if (_nestedScrollController.hasClients) {
                                _nestedScrollController.animateTo(
                                  0,
                                  duration: const Duration(milliseconds: 260),
                                  curve: Curves.easeOut,
                                );
                              }
                            },
                          ),
                          tabBarWidget: _buildTabBarBarra(arredondarTopo: true),
                        ),
                      ),
                    ),
                  ];
                },
                body: Builder(
                  builder: (bodyContext) {
                    return NestedOverlapScope(
                      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                        bodyContext,
                      ),
                      child: Container(
                        width: double.infinity,
                        color: const Color(0xFFF1F5F9),
                        child: _buildTabBarView(),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPainelMiniMapaFicha(BuildContext context, SnapshotMesa snap) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              key: const Key('toggle_mini_mapa_ficha'),
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(
                () => _mostrarMiniMapaNaFicha = !_mostrarMiniMapaNaFicha,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.map_outlined,
                      color: Color(0xFFFBBF24),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${snap.nomeMapa} • Rd ${snap.rodadaCombate}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_mostrarMiniMapaNaFicha)
                      IconButton(
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.open_in_full_rounded,
                          color: Colors.white70,
                          size: 16,
                        ),
                        tooltip: 'Tela cheia',
                        onPressed: () {
                          if (widget.onAbrirMapaMesa != null) {
                            widget.onAbrirMapaMesa!();
                            return;
                          }
                          final fichaCubit = context.read<FichaCubit>();
                          final sessaoCubit = context.read<SessaoJogadorCubit>();
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => MultiBlocProvider(
                                providers: [
                                  BlocProvider.value(value: fichaCubit),
                                  BlocProvider.value(value: sessaoCubit),
                                ],
                                child: const MapaJogadorScreen(),
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(width: 4),
                    Text(
                      _mostrarMiniMapaNaFicha ? 'Ocultar' : 'Ver mapa',
                      style: const TextStyle(
                        color: Color(0xFFFBBF24),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      _mostrarMiniMapaNaFicha
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: const Color(0xFFFBBF24),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
            if (_mostrarMiniMapaNaFicha)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(13),
                ),
                child: const SizedBox(
                  key: Key('mini_mapa_global_ficha'),
                  height: 185,
                  child: MapaMesaJogadorWidget(compacto: true),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FichaCabecalhoSliverDelegate extends SliverPersistentHeaderDelegate {
  final double minExtentValue;
  final double maxExtentValue;
  final double tabBarHeight;
  final Color corFundoTopo;
  final WidgetBuilder expandedBuilder;
  final Widget compactWidget;
  final Widget tabBarWidget;

  _FichaCabecalhoSliverDelegate({
    required this.minExtentValue,
    required this.maxExtentValue,
    required this.tabBarHeight,
    required this.corFundoTopo,
    required this.expandedBuilder,
    required this.compactWidget,
    required this.tabBarWidget,
  });

  @override
  double get minExtent => minExtentValue;

  @override
  double get maxExtent => maxExtentValue;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final range = math.max(0.0, maxExtent - minExtent);
    final t = range <= 1.0 ? 1.0 : (shrinkOffset / range).clamp(0.0, 1.0);
    final currentExtent = math.max(minExtent, maxExtent - shrinkOffset);
    final topHeight = math.max(0.0, currentExtent - tabBarHeight);
    final mostrarCompacto = t >= 0.65;

    return ColoredBox(
      color: corFundoTopo,
      child: Column(
        children: [
          SizedBox(
            height: topHeight,
            width: double.infinity,
            child: ClipRect(
              child: mostrarCompacto
                  ? Opacity(
                      opacity: range <= 1.0
                          ? 1.0
                          : ((t - 0.65) / 0.35).clamp(0.0, 1.0),
                      child: Align(
                        alignment: Alignment.center,
                        child: OverflowBox(
                          minHeight: 0,
                          maxHeight: double.infinity,
                          alignment: Alignment.center,
                          child: compactWidget,
                        ),
                      ),
                    )
                  : Opacity(
                      opacity: (1.0 - t / 0.65).clamp(0.0, 1.0),
                      child: OverflowBox(
                        minHeight: 0,
                        maxHeight: double.infinity,
                        alignment: Alignment.topCenter,
                        child: expandedBuilder(context),
                      ),
                    ),
            ),
          ),
          tabBarWidget,
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _FichaCabecalhoSliverDelegate oldDelegate) {
    return true;
  }
}

