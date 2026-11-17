import 'package:flutter/material.dart';
import '../../home/widgets/home_action_card.dart';

/// Estado vazio amigável no padrão visual da HomeScreen.
class MestreEmptyState extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String subtitulo;
  final String textoBotao;
  final VoidCallback onAcaoPrincipal;

  const MestreEmptyState({
    super.key,
    required this.icon,
    required this.titulo,
    required this.subtitulo,
    required this.textoBotao,
    required this.onAcaoPrincipal,
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
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 48,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                titulo,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                subtitulo,
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: HomeActionCard(
                  title: textoBotao,
                  icon: Icons.add,
                  onPressed: onAcaoPrincipal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
