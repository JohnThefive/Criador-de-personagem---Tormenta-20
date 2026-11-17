import 'package:flutter/material.dart';
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
  bool _mostrarMiniMapaNaFicha = false;

  final List<Tab> _abas = const [
    Tab(icon: Icon(Icons.shield_outlined, size: 19), text: 'Geral'),
    Tab(icon: Icon(Icons.fact_check_outlined, size: 19), text: 'Perícias'),
    Tab(icon: Icon(Icons.auto_awesome_outlined, size: 19), text: 'Habilidades'),
    Tab(icon: Icon(Icons.menu_book_outlined, size: 19), text: 'Magias'),
    Tab(icon: Icon(Icons.backpack_outlined, size: 19), text: 'Inventário'),
    Tab(icon: Icon(Icons.edit_note_rounded, size: 20), text: 'Notas'),
    Tab(icon: Icon(Icons.wifi_tethering_outlined, size: 19), text: 'Sessão'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _abas.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const t20Red = Color(0xFFC62828);
    final cubit = context.read<FichaCubit>();

    return Scaffold(
      backgroundColor: t20Red,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Barra Superior enxuta com Nome e Ação de Voltar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Row(
                children: [
                  IconButton(
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
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
                                      fontSize: 19,
                                      letterSpacing: 0.3,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.edit_outlined,
                                  color: Colors.white70,
                                  size: 15,
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
            ),

            // Cabeçalho de sessão fixo
            BlocBuilder<FichaCubit, FichaState>(
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
                    p1.atributos != p2.atributos;
              },
              builder: (context, state) =>
                  FichaCabecalhoWidget(personagem: state.personagem),
            ),

            // Banner de evolução pendente (Poderes ou Magias pendentes)
            BlocSelector<FichaCubit, FichaState, bool>(
              selector: (state) =>
                  state.personagem.classes.any((c) => c.temPoderPendente) ||
                  AprendizadoMagiaService.calcularMagiasPendentesPersonagem(
                    state.personagem,
                  ) > 0,
              builder: (context, temPendente) {
                if (!temPendente) return const SizedBox.shrink();
                return const FichaBannerEvolucao();
              },
            ),

            // Mini-mapa retrátil da Mesa LAN (visível em todas as abas quando conectado)
            BlocBuilder<SessaoJogadorCubit, SessaoJogadorState>(
              builder: (context, sessaoState) {
                final snap = sessaoState.ultimoSnapshot;
                if (!sessaoState.estaConectado || snap == null) {
                  return const SizedBox.shrink();
                }
                return _buildPainelMiniMapaFicha(context, snap);
              },
            ),

            // Área principal das 7 abas da Ficha
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        border: Border(
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
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                        tabs: _abas,
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
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
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
