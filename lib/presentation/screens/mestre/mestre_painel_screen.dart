import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/mestre/modelos_mestre.dart';
import '../../controllers/mestre_controller/mestre_cubit.dart';
import '../../controllers/mestre_controller/mestre_state.dart';
import 'theme/mestre_theme.dart';
import 'widgets/drawer_sessao_lan.dart';
import 'widgets/tela_biblioteca_mapas.dart';
import 'widgets/tela_editor_mapa.dart';
import 'widgets/tela_escudo_notas.dart';
import 'widgets/tela_mesa_jogo.dart';

/// Painel do Mestre (Tormenta 20 - Android/Flutter)
/// Baseado no PROMPT DE DESIGN:
/// - PARTE 0: Fundação (Vinho e Ouro, Máximo espaço livre, alvos >= 48dp)
/// - PARTE 1: Gaveta "Sessão e LAN" (Árvore acordeão, menus, 5 sheets)
/// - PARTE 2: Tela "Mapas" (Biblioteca + Seleção)
/// - PARTE 3: Tela "Criar/Editar mapa" (Canvas com pinch-zoom/pan + abas de ajuste)
/// - PARTE 4: Tela "Mesa de jogo" (Canvas quase total, UI mínima e translúcida)
/// - PARTE 5: Tela "Escudo e Notas" (5 abas, busca global, consulta em 2 toques)
class MestrePainelScreen extends StatefulWidget {
  const MestrePainelScreen({super.key});

  @override
  State<MestrePainelScreen> createState() => _MestrePainelScreenState();
}

class _MestrePainelScreenState extends State<MestrePainelScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _destinoSelecionado = 0; // 0: Mapas, 1: Escudo e Notas
  bool _painelLateralTabletAberto = false; // Tablet paisagem: gaveta recolhida por padrão

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MestreCubit(),
      child: BlocBuilder<MestreCubit, MestreState>(
        builder: (context, state) {
          final cubit = context.read<MestreCubit>();

          return LayoutBuilder(
            builder: (context, constraints) {
              final isTabletLandscape = constraints.maxWidth >= 840;

              return Scaffold(
                key: _scaffoldKey,
                backgroundColor: MestreCores.escuroBackground,
                drawer: isTabletLandscape
                    ? null
                    : DrawerSessaoLan(
                        state: state,
                        cubit: cubit,
                        onFechar: () => _scaffoldKey.currentState?.closeDrawer(),
                      ),
                appBar: _buildAppBarComChipContexto(context, state, cubit, isTabletLandscape),
                body: SafeArea(
                  child: Row(
                    children: [
                      // Tablet Paisagem: NavigationRail de 56 dp
                      if (isTabletLandscape) ...[
                        _buildNavigationRailTablet(context, cubit),
                        if (_painelLateralTabletAberto) ...[
                          const VerticalDivider(color: MestreCores.escuroOutline, width: 1),
                          SizedBox(
                            width: 320,
                            child: DrawerSessaoLan(
                              state: state,
                              cubit: cubit,
                              onFechar: () => setState(() => _painelLateralTabletAberto = false),
                            ),
                          ),
                        ],
                        const VerticalDivider(color: MestreCores.escuroOutline, width: 1),
                      ],

                      // Conteúdo Principal: Máximo de Espaço Livre
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _buildDestinoPrincipal(context, state, cubit),
                        ),
                      ),
                    ],
                  ),
                ),
                bottomNavigationBar: isTabletLandscape
                    ? null
                    : _buildBottomNavigationBarCelular(context),
              );
            },
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // APP BAR COM CHIP DE CONTEXTO (40 DP) NO TOPO
  // "Campanha › Aventura › Sessão 3 · ● 4/6"
  // ---------------------------------------------------------------------------

  PreferredSizeWidget _buildAppBarComChipContexto(
    BuildContext context,
    MestreState state,
    MestreCubit cubit,
    bool isTabletLandscape,
  ) {
    final salaAberta = state.statusLan != StatusConexaoLan.desligado;
    final conectados = state.sessaoAtual?.elenco.where((e) => e.conectadoViaLan).length ?? 0;
    final total = state.sessaoAtual?.elenco.length ?? 0;
    final corPonto = salaAberta ? MestreCores.statusOnlineEscuro : MestreCores.statusOffline;

    final textoContexto = '${state.campanhaAtual?.nome ?? "Campanha"} › '
        '${state.aventuraAtual?.nome ?? "Aventura"} › '
        '${state.sessaoAtual?.titulo ?? "Sessão"}';

    return AppBar(
      backgroundColor: MestreCores.escuroSurface,
      foregroundColor: MestreCores.escuroOnSurface,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Voltar ao Menu Principal',
        onPressed: () => Navigator.pop(context),
      ),
      title: InkWell(
        onTap: () {
          if (isTabletLandscape) {
            setState(() => _painelLateralTabletAberto = !_painelLateralTabletAberto);
          } else {
            _scaffoldKey.currentState?.openDrawer();
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: MestreCores.escuroSurfaceContainer,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: MestreCores.escuroOutline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.hub_outlined, size: 16, color: MestreCores.escuroOuro),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  textoContexto,
                  style: const TextStyle(
                    color: MestreCores.escuroOnSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.circle, size: 7, color: corPonto),
              const SizedBox(width: 4),
              Text(
                '$conectados/$total',
                style: MestreCores.estiloMono.copyWith(color: MestreCores.escuroOnSurfaceVariant, fontSize: 11),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down, size: 18, color: MestreCores.escuroOuro),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _painelLateralTabletAberto ? Icons.menu_open : Icons.menu,
            color: MestreCores.escuroOuro,
          ),
          tooltip: 'Abrir / Fechar Sessão e LAN',
          onPressed: () {
            if (isTabletLandscape) {
              setState(() => _painelLateralTabletAberto = !_painelLateralTabletAberto);
            } else {
              _scaffoldKey.currentState?.openDrawer();
            }
          },
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // NAVIGATION RAIL (TABLET PAISAGEM: 56 DP)
  // ---------------------------------------------------------------------------

  Widget _buildNavigationRailTablet(BuildContext context, MestreCubit cubit) {
    return NavigationRail(
      backgroundColor: MestreCores.escuroSurface,
      selectedIndex: _destinoSelecionado,
      onDestinationSelected: (idx) => setState(() => _destinoSelecionado = idx),
      minWidth: 56,
      labelType: NavigationRailLabelType.all,
      selectedIconTheme: const IconThemeData(color: MestreCores.escuroOuro),
      unselectedIconTheme: const IconThemeData(color: MestreCores.escuroOnSurfaceVariant),
      selectedLabelTextStyle: const TextStyle(
        color: MestreCores.escuroOuro,
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
      unselectedLabelTextStyle: const TextStyle(
        color: MestreCores.escuroOnSurfaceVariant,
        fontSize: 10,
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.map_outlined),
          selectedIcon: Icon(Icons.map),
          label: Text('Mapas'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.shield_outlined),
          selectedIcon: Icon(Icons.shield),
          label: Text('Escudo e Notas'),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // BARRA INFERIOR (CELULAR & TABLET RETRATO: 56 DP)
  // ---------------------------------------------------------------------------

  Widget _buildBottomNavigationBarCelular(BuildContext context) {
    return NavigationBar(
      height: 56,
      backgroundColor: MestreCores.escuroSurface,
      indicatorColor: MestreCores.escuroVinho,
      selectedIndex: _destinoSelecionado,
      onDestinationSelected: (idx) => setState(() => _destinoSelecionado = idx),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.map_outlined, color: MestreCores.escuroOnSurfaceVariant),
          selectedIcon: Icon(Icons.map, color: MestreCores.escuroOuro),
          label: 'Mapas',
        ),
        NavigationDestination(
          icon: Icon(Icons.shield_outlined, color: MestreCores.escuroOnSurfaceVariant),
          selectedIcon: Icon(Icons.shield, color: MestreCores.escuroOuro),
          label: 'Escudo e Notas',
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // CONTEÚDO PRINCIPAL (DESTINO SELECIONADO)
  // ---------------------------------------------------------------------------

  Widget _buildDestinoPrincipal(BuildContext context, MestreState state, MestreCubit cubit) {
    if (_destinoSelecionado == 0) {
      // Destino 0: Biblioteca de Mapas (Parte 2)
      return TelaBibliotecaMapas(
        key: const ValueKey('tela_biblioteca_mapas'),
        state: state,
        cubit: cubit,
        onAbrirMesaJogo: (mapa) {
          cubit.selecionarMapa(mapa.id);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => BlocProvider.value(
                value: cubit,
                child: BlocBuilder<MestreCubit, MestreState>(
                  builder: (ctx, s) => TelaMesaJogo(
                    state: s,
                    cubit: cubit,
                    onVoltarBiblioteca: () => Navigator.pop(ctx),
                  ),
                ),
              ),
            ),
          );
        },
        onAbrirEditorMapa: ({mapaParaEditar}) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => TelaEditorMapa(
                mapaOriginal: mapaParaEditar,
                cubit: cubit,
                onSalvo: () => Navigator.pop(ctx),
              ),
            ),
          );
        },
      );
    } else {
      // Destino 1: Escudo e Notas (Parte 5)
      return TelaEscudoNotas(
        key: const ValueKey('tela_escudo_notas'),
        state: state,
        cubit: cubit,
      );
    }
  }
}
