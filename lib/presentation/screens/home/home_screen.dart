import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/personagem/personagem.dart';
import '../../controllers/home_cubit.dart';
import '../ficha/painel_jogador_screen.dart';
import '../wizard_personagem/char_creation_screen.dart';
import 'breakpoints.dart';
import 'widgets/app_drawer.dart';
import 'widgets/character_list_section.dart';
import 'widgets/empty_home_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    final windowSize = WindowSizeClass.of(context);

    // Tema da Home: Material 3 com superfícies neutras e o Vermelho Tormenta original como destaque.
    // Aplicado localmente para isolar e não interferir no design das outras telas do app.
    final homeTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFD32F2F), // Vermelho Tormenta anterior
        brightness: Brightness.dark,
      ),
    );

    return Theme(
      data: homeTheme,
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
