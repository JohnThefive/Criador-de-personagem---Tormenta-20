import 'package:flutter/material.dart';

/// Card/Botão de Ação principal reutilizável da HomeScreen.
///
/// Padroniza o visual Material 3, elevação, alvos de toque mínimos de 48dp,
/// tipografia e bordas arredondadas entre "Criar Personagem", "Modo Arena" e futuras ações.
class HomeActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String? tooltip;
  final bool isSecondary;

  const HomeActionCard({
    super.key,
    required this.title,
    required this.icon,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.tooltip,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final bg = backgroundColor ??
        (isSecondary
            ? colorScheme.secondaryContainer
            : colorScheme.primary);
    final fg = foregroundColor ??
        (isSecondary
            ? colorScheme.onSecondaryContainer
            : colorScheme.onPrimary);

    return Semantics(
      button: true,
      label: tooltip ?? title,
      enabled: onPressed != null,
      child: Tooltip(
        message: tooltip ?? title,
        child: FilledButton.icon(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: fg,
            minimumSize: const Size(48, 54),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 1,
          ),
          icon: Icon(icon, size: 24),
          label: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleMedium?.copyWith(
              color: fg,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
