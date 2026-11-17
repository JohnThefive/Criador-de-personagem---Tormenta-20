import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/mestre/modelos_mestre.dart';
import '../../../domain/services/sessao_lan/sessao_host_lan_service.dart';
import '../../controllers/mestre_controller/mestre_cubit.dart';
import '../../controllers/mestre_controller/mestre_state.dart';
import '../home/widgets/breakpoints.dart';
import 'campanha_detalhe_screen.dart';
import 'criar_campanha_screen.dart';
import 'mesa_sessao_screen.dart';
import 'theme/mestre_theme.dart';
import 'widgets/campanha_card.dart';
import 'widgets/mestre_drawer.dart';
import 'widgets/mestre_empty_state.dart';
import 'widgets/tela_bestiario_mestre.dart';
import 'widgets/tela_biblioteca_mapas.dart';
import 'widgets/tela_editor_mapa.dart';
import 'widgets/tela_escudo_notas.dart';

/// Painel do Mestre mobile-first com navegação por Drawer lateral.
///
/// Integra a lista de campanhas (com fluxo Campanha > Aventura > Sessão),
/// a Biblioteca de Mapas e o Escudo e Notas sem alterar o comportamento
/// interno das telas já existentes.
class MestrePainelScreen extends StatefulWidget {
  final MestreCubit? cubit;

  const MestrePainelScreen({super.key, this.cubit});

  @override
  State<MestrePainelScreen> createState() => _MestrePainelScreenState();
}

class _MestrePainelScreenState extends State<MestrePainelScreen> {
  late final MestreCubit _cubit;
  late final bool _cubitProprio;
  SessaoHostLanService? _hostLan;
  int _destinoSelecionado = 0;

  @override
  void initState() {
    super.initState();
    _cubitProprio = widget.cubit == null;
    if (_cubitProprio) {
      _hostLan = SessaoHostLanService();
      _cubit = MestreCubit(sessaoHostService: _hostLan);
    } else {
      _cubit = widget.cubit!;
    }
  }

  @override
  void dispose() {
    if (_cubitProprio) {
      _cubit.close();
      unawaited(_hostLan?.dispose());
    }
    super.dispose();
  }

  void _abrirCriarCampanha(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<String?>(
        builder: (_) => CriarCampanhaScreen(cubit: _cubit),
      ),
    );
  }

  void _abrirDetalheCampanha(BuildContext context, CampanhaMestre campanha) {
    _cubit.selecionarCampanha(campanha.id);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            CampanhaDetalheScreen(cubit: _cubit, campanhaId: campanha.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final destinoAtual = MestreDestinoDrawer.values[_destinoSelecionado];

    return Theme(
      data: MestreCores.homeStyleTheme,
      child: Builder(
        builder: (themedContext) {
          final colorScheme = Theme.of(themedContext).colorScheme;
          final textTheme = Theme.of(themedContext).textTheme;

          return BlocProvider.value(
            value: _cubit,
            child: BlocSelector<MestreCubit, MestreState, List<CampanhaMestre>>(
              bloc: _cubit,
              selector: (s) => s.campanhas,
              builder: (context, campanhas) {
                final mostrarFabCampanha =
                    _destinoSelecionado == 0 && campanhas.isNotEmpty;

                return Scaffold(
                  drawer: MestreDrawer(
                    destinoSelecionado: _destinoSelecionado,
                    onSelecionarDestino: (index) {
                      setState(() => _destinoSelecionado = index);
                    },
                    onVoltarHome: () => Navigator.of(context).pop(),
                  ),
                  appBar: AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    title: Text(
                      destinoAtual.titulo,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.home_outlined),
                        tooltip: 'Voltar para Heróis',
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  body: SafeArea(
                    child: IndexedStack(
                      index: _destinoSelecionado,
                      children: [
                        _ListaCampanhasView(
                          cubit: _cubit,
                          onCriarCampanha: () => _abrirCriarCampanha(context),
                          onAbrirCampanha: (camp) =>
                              _abrirDetalheCampanha(context, camp),
                        ),
                        TelaBibliotecaMapas(
                          key: const ValueKey('tela_biblioteca_mapas'),
                          cubit: _cubit,
                          onAbrirMesaJogo: (mapa) {
                            _cubit.selecionarMapa(mapa.id);
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => MesaSessaoScreen(cubit: _cubit),
                              ),
                            );
                          },
                          onAbrirEditorMapa: ({mapaParaEditar}) {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (ctx) => TelaEditorMapa(
                                  mapaOriginal: mapaParaEditar,
                                  cubit: _cubit,
                                  onSalvo: () => Navigator.of(ctx).pop(),
                                ),
                              ),
                            );
                          },
                        ),
                        TelaBestiarioMestre(
                          key: const ValueKey('tela_bestiario_mestre'),
                          cubit: _cubit,
                          autoCarregar:
                              _destinoSelecionado ==
                              MestreDestinoDrawer.bestiario.index,
                        ),
                        TelaEscudoNotas(
                          key: const ValueKey('tela_escudo_notas'),
                          cubit: _cubit,
                        ),
                      ],
                    ),
                  ),
                  bottomNavigationBar: NavigationBar(
                    selectedIndex: _destinoSelecionado,
                    onDestinationSelected: (index) =>
                        setState(() => _destinoSelecionado = index),
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.campaign_outlined),
                        selectedIcon: Icon(Icons.campaign),
                        label: 'Campanhas',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.map_outlined),
                        selectedIcon: Icon(Icons.map),
                        label: 'Mapas',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.pets_outlined),
                        selectedIcon: Icon(Icons.pets),
                        label: 'Bestiário',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.shield_outlined),
                        selectedIcon: Icon(Icons.shield),
                        label: 'Escudo',
                      ),
                    ],
                  ),
                  floatingActionButton: mostrarFabCampanha
                      ? FloatingActionButton.extended(
                          heroTag: 'mestre_campanhas_fab',
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          icon: const Icon(Icons.add),
                          label: const Text(
                            'Nova campanha',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: () => _abrirCriarCampanha(context),
                        )
                      : null,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ListaCampanhasView extends StatelessWidget {
  final MestreCubit cubit;
  final VoidCallback onCriarCampanha;
  final ValueChanged<CampanhaMestre> onAbrirCampanha;

  const _ListaCampanhasView({
    required this.cubit,
    required this.onCriarCampanha,
    required this.onAbrirCampanha,
  });

  @override
  Widget build(BuildContext context) {
    final windowSize = WindowSizeClass.of(context);
    final double maxWidth = windowSize.isCompact
        ? double.infinity
        : (windowSize.isMedium ? 720 : 920);

    return BlocSelector<
      MestreCubit,
      MestreState,
      ({List<CampanhaMestre> campanhas, String? ativaId})
    >(
      bloc: cubit,
      selector: (s) => (campanhas: s.campanhas, ativaId: s.campanhaAtual?.id),
      builder: (context, data) {
        if (data.campanhas.isEmpty) {
          return MestreEmptyState(
            icon: Icons.campaign_outlined,
            titulo: 'Nenhuma campanha ainda',
            subtitulo:
                'Crie sua primeira campanha para organizar aventuras, sessões e mapas.',
            textoBotao: 'Nova campanha',
            onAcaoPrincipal: onCriarCampanha,
          );
        }

        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: data.campanhas.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      'Suas campanhas',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  );
                }

                final camp = data.campanhas[index - 1];
                return CampanhaCard(
                  campanha: camp,
                  selecionada: camp.id == data.ativaId,
                  onTap: () => onAbrirCampanha(camp),
                  onExcluir: () => cubit.excluirCampanha(camp.id),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
