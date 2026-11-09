import 'package:flutter/material.dart';
import 'home_action_card.dart';

/// Exibido na HomeScreen quando ainda não existem personagens salvos.
class EmptyHomeState extends StatelessWidget {
  final VoidCallback onCriarPersonagem;
  final VoidCallback? onModoArena;
  final VoidCallback? onPainelMestre;

  const EmptyHomeState({
    super.key,
    required this.onCriarPersonagem,
    this.onModoArena,
    this.onPainelMestre,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Ícone ilustrativo
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shield_outlined,
                  size: 48,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),

              // Título com texto corrigido
              Text(
                'Bem-vindo ao criador de heróis!',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Subtítulo legível usando TextTheme
              Text(
                'Crie personagens complexos e suba de nível com eles.',
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Botões de Ação usando HomeActionCard
              SizedBox(
                width: double.infinity,
                child: HomeActionCard(
                  title: 'Criar Personagem',
                  icon: Icons.add,
                  onPressed: onCriarPersonagem,
                ),
              ),
              if (onModoArena != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: HomeActionCard(
                    title: 'Modo Arena',
                    icon: Icons.stadium_outlined,
                    isSecondary: true,
                    tooltip: 'Testar personagem em combate tático',
                    onPressed: onModoArena,
                  ),
                ),
              ],
              if (onPainelMestre != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: HomeActionCard(
                    title: 'Painel do Mestre',
                    icon: Icons.shield_moon_outlined,
                    isSecondary: true,
                    tooltip: 'Campanhas, Aventuras, Sessões LAN e Mapas',
                    onPressed: onPainelMestre,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
