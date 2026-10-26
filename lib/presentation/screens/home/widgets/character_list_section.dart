import 'package:flutter/material.dart';
import '../../../../domain/entities/personagem/personagem.dart';
import 'character_card.dart';

/// Seção principal exibida quando existem personagens salvos.
///
/// Apresenta:
/// 1. Botão "Criar personagem" no topo
/// 2. Card de destaque "Continuar: <último personagem>"
/// 3. Lista ou grade adaptativa com os demais personagens
class CharacterListSection extends StatelessWidget {
  final List<Personagem> personagens;
  final VoidCallback onCriarPersonagem;
  final void Function(Personagem personagem) onAbrirPersonagem;
  final void Function(Personagem personagem) onExcluirPersonagem;

  const CharacterListSection({
    super.key,
    required this.personagens,
    required this.onCriarPersonagem,
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
              // 1. Botão "Criar personagem" no topo
              FilledButton.icon(
                onPressed: onCriarPersonagem,
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 1,
                ),
                icon: const Icon(Icons.add, size: 24),
                label: Text(
                  'Criar Personagem',
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
