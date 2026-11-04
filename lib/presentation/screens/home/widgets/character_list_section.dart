import 'package:flutter/material.dart';
import '../../../../domain/entities/personagem/personagem.dart';
import 'character_card.dart';

import 'home_action_card.dart';

/// Seção principal exibida quando existem personagens salvos.
///
/// Apresenta:
/// 1. Ações principais (Criar Personagem & Modo Arena)
/// 2. Card de destaque "Continuar: <último personagem>"
/// 3. Lista ou grade adaptativa com os demais personagens
class CharacterListSection extends StatelessWidget {
  final List<Personagem> personagens;
  final VoidCallback onCriarPersonagem;
  final VoidCallback onModoArena;
  final void Function(Personagem personagem) onAbrirPersonagem;
  final void Function(Personagem personagem) onExcluirPersonagem;

  const CharacterListSection({
    super.key,
    required this.personagens,
    required this.onCriarPersonagem,
    required this.onModoArena,
    required this.onAbrirPersonagem,
    required this.onExcluirPersonagem,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final ultimoPersonagem = personagens.first;
    final outrosPersonagens = personagens.length > 1
        ? personagens.sublist(1)
        : <Personagem>[];

    final cardExtent = MediaQuery.textScalerOf(
      context,
    ).scale(116).clamp(112.0, 220.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final useGrid = constraints.maxWidth >= 600;

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Ações Principais no topo (Criar Personagem & Modo Arena)
              constraints.maxWidth >= 460
                  ? Row(
                      children: [
                        Expanded(
                          child: HomeActionCard(
                            title: 'Criar Personagem',
                            icon: Icons.add,
                            onPressed: onCriarPersonagem,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: HomeActionCard(
                            title: 'Modo Arena',
                            icon: Icons.stadium_outlined,
                            isSecondary: true,
                            tooltip: 'Testar personagem em combate tático',
                            onPressed: onModoArena,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        HomeActionCard(
                          title: 'Criar Personagem',
                          icon: Icons.add,
                          onPressed: onCriarPersonagem,
                        ),
                        const SizedBox(height: 10),
                        HomeActionCard(
                          title: 'Modo Arena',
                          icon: Icons.stadium_outlined,
                          isSecondary: true,
                          tooltip: 'Testar personagem em combate tático',
                          onPressed: onModoArena,
                        ),
                      ],
                    ),
              const SizedBox(height: 20),

              // 2. Card "Continuar: <último personagem>"
              ContinueCharacterCard(
                personagem: ultimoPersonagem,
                onTap: () => onAbrirPersonagem(ultimoPersonagem),
                onExcluir: () => onExcluirPersonagem(ultimoPersonagem),
              ),

              // 3. Lista / Grade com os demais heróis
              if (outrosPersonagens.isNotEmpty) ...[
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 12),
                  child: Text(
                    'Outros heróis',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                if (useGrid)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: outrosPersonagens.length,
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 420,
                      mainAxisExtent: cardExtent,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemBuilder: (context, index) {
                      final p = outrosPersonagens[index];
                      return CharacterCard(
                        personagem: p,
                        onTap: () => onAbrirPersonagem(p),
                        onExcluir: () => onExcluirPersonagem(p),
                      );
                    },
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: outrosPersonagens.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final p = outrosPersonagens[index];
                      return CharacterCard(
                        personagem: p,
                        onTap: () => onAbrirPersonagem(p),
                        onExcluir: () => onExcluirPersonagem(p),
                      );
                    },
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}
