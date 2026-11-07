import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/personagem/personagem.dart';
import '../../../domain/repositories/i_personagem_repository.dart';
import '../../controllers/ficha_controller/ficha_cubit.dart';
import '../../controllers/ficha_controller/ficha_state.dart';

import 'widgets/aba_geral_view.dart';
import 'widgets/aba_habilidades_view.dart';
import 'widgets/aba_historia_view.dart';
import 'widgets/aba_inventario_view.dart';
import 'widgets/aba_magias_view.dart';
import 'widgets/aba_pericias_view.dart';
import 'widgets/ficha_banner_evolucao.dart';
import 'widgets/ficha_cabecalho_widget.dart';

/// Tela principal da Ficha do Personagem (Painel do Jogador).
///
/// Atua como coordenadora de alto nível, integrando o cabeçalho fixo,
/// banner de evolução pendente e o controlador das 6 abas de navegação.
class FichaScreen extends StatelessWidget {
  final Personagem personagemInicial;
  final IPersonagemRepository? repository;

  const FichaScreen({
    super.key,
    required this.personagemInicial,
    this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FichaCubit(
        personagemInicial: personagemInicial,
        repository: repository,
      ),
      child: const _FichaView(),
    );
  }
}

/// Alias para manter retrocompatibilidade com código existente e testes.
typedef PainelJogadorScreen = FichaScreen;

class _FichaView extends StatefulWidget {
  const _FichaView();

  @override
  State<_FichaView> createState() => _FichaViewState();
}

class _FichaViewState extends State<_FichaView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final List<Tab> _abas = const [
    Tab(icon: Icon(Icons.shield_outlined, size: 19), text: 'Geral'),
    Tab(icon: Icon(Icons.fact_check_outlined, size: 19), text: 'Perícias'),
    Tab(icon: Icon(Icons.auto_awesome_outlined, size: 19), text: 'Habilidades'),
    Tab(icon: Icon(Icons.menu_book_outlined, size: 19), text: 'Magias'),
    Tab(icon: Icon(Icons.backpack_outlined, size: 19), text: 'Inventário'),
    Tab(icon: Icon(Icons.edit_note_rounded, size: 20), text: 'Notas'),
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

            // Banner de evolução pendente
            BlocSelector<FichaCubit, FichaState, bool>(
              selector: (state) =>
                  state.personagem.classes.any((c) => c.temPoderPendente),
              builder: (context, temPendente) {
                if (!temPendente) return const SizedBox.shrink();
                return const FichaBannerEvolucao();
              },
            ),

            // Área principal das 6 abas da Ficha
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
                        children: const [
                          AbaGeralView(),
                          AbaPericiasView(),
                          AbaHabilidadesView(),
                          AbaMagiasView(),
                          AbaInventarioView(),
                          AbaHistoriaView(),
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
}
