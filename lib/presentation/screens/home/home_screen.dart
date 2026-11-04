import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/personagem/personagem.dart';
import '../../controllers/home_controller/home_cubit.dart';
import '../ficha/painel_jogador_screen.dart';
import '../wizard_personagem/char_creation_screen.dart';
import 'breakpoints.dart';
import 'widgets/app_drawer.dart';
import 'widgets/character_list_section.dart';
import 'widgets/empty_home_state.dart';
import '../arena/arena_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Tema da Home: Material 3 com superfícies neutras e o Vermelho Tormenta original como destaque.
  // Aplicado como static final para isolar o design da Home sem reconstruir ThemeData e ColorScheme a cada frame.
  static final ThemeData _homeTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFD32F2F), // Vermelho Tormenta anterior
      brightness: Brightness.dark,
    ),
  );

  void _navegarCriarPersonagem(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CharacterCreatorScreen()),
    ).then((_) {
      if (context.mounted) {
        context.read<HomeCubit>().carregarPersonagensReais();
      }
    });
  }

  void _navegarAbrirPersonagem(BuildContext context, Personagem personagem) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PainelJogadorScreen(personagemInicial: personagem),
      ),
    ).then((_) {
      if (context.mounted) {
        context.read<HomeCubit>().carregarPersonagensReais();
      }
    });
  }

  void _excluirPersonagem(BuildContext context, Personagem personagem) {
    context.read<HomeCubit>().excluirPersonagem(personagem.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Personagem "${personagem.nome}" excluído.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _abrirSeletorArena(BuildContext context, List<Personagem> personagens) {
    if (personagens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Crie ao menos um personagem antes de entrar na Arena!',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFFC62828),
        ),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.sports_kabaddi,
                        color: Colors.amberAccent,
                        size: 26,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Escolha seu Herói para a Arena',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    'Uma cópia descartável será criada. Nada na sua ficha real será modificado.',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ),
                const Divider(color: Colors.white24, height: 20),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: personagens.length,
                    separatorBuilder: (_, _) =>
                        const Divider(color: Colors.white12, height: 1),
                    itemBuilder: (ctx, index) {
                      final p = personagens[index];
                      final classeNivel = p.classes.isNotEmpty
                          ? '${p.classes.first.classeDefinicao.nome} Nv ${p.nivelPersonagem}'
                          : 'Nível ${p.nivelPersonagem}';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFD32F2F),
                          child: Text(
                            p.nome.isNotEmpty ? p.nome[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          p.nome,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '$classeNivel • ${p.raca?.nome ?? "Sem Raça"} • ${p.pvTotal} PV',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.amberAccent,
                          size: 28,
                        ),
                        onTap: () {
                          Navigator.pop(modalContext); // Fecha o modal seletor
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ArenaScreen(personagemOriginal: p),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final windowSize = WindowSizeClass.of(context);

    return Theme(
      data: _homeTheme,
      child: Builder(
        builder: (context) {
          final colorScheme = Theme.of(context).colorScheme;

          return BlocBuilder<HomeCubit, HomeState>(
            builder: (context, state) {
              final temPersonagens = state.personagens.isNotEmpty;

              // Conteúdo central adaptativo da tela
              Widget buildConteudo() {
                if (state.carregando) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!temPersonagens) {
                  return EmptyHomeState(
                    onCriarPersonagem: () => _navegarCriarPersonagem(context),
                  );
                }

                return CharacterListSection(
                  personagens: state.personagens,
                  onCriarPersonagem: () => _navegarCriarPersonagem(context),
                  onAbrirPersonagem: (p) => _navegarAbrirPersonagem(context, p),
                  onExcluirPersonagem: (p) => _excluirPersonagem(context, p),
                );
              }

              // Conteúdo com limites de largura para telas médias e expandidas
              Widget buildConteudoAdaptativo() {
                final conteudo = buildConteudo();

                if (windowSize.isCompact) {
                  return SafeArea(child: conteudo);
                }

                final double maxContentWidth = windowSize.isMedium ? 720 : 1000;

                return SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxContentWidth),
                      child: conteudo,
                    ),
                  ),
                );
              }

              return Scaffold(
                drawer: const AppDrawer(isPermanent: false),
                appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: Builder(
                    builder: (ctx) => IconButton(
                      icon: Icon(Icons.menu, color: colorScheme.onSurface),
                      tooltip: 'Abrir menu de navegação',
                      onPressed: () => Scaffold.of(ctx).openDrawer(),
                    ),
                  ),
                  actions: [
                    FilledButton.tonalIcon(
                      onPressed: () =>
                          _abrirSeletorArena(context, state.personagens),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(
                          0xFFC62828,
                        ).withValues(alpha: 0.2),
                        foregroundColor: Colors.white,
                        side: const BorderSide(
                          color: Color(0xFFC62828),
                          width: 1.2,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                      ),
                      icon: const Icon(
                        Icons.sports_kabaddi,
                        color: Colors.amberAccent,
                        size: 20,
                      ),
                      label: const Text(
                        'Modo Arena',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
                body: buildConteudoAdaptativo(),
              );
            },
          );
        },
      ),
    );
  }
}
