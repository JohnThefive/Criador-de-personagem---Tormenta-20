import 'package:flutter/material.dart';

/// Modelo de dados para um destino no Drawer de navegação.
class DrawerDestinationItem {
  final String label;
  final IconData icon;
  final IconData? selectedIcon;
  final void Function(BuildContext context)? onSelect;
  final bool emBreve;

  const DrawerDestinationItem({
    required this.label,
    required this.icon,
    this.selectedIcon,
    this.onSelect,
    this.emBreve = false,
  });

  bool get habilitado => !emBreve && onSelect != null;
}

class AppDrawer extends StatelessWidget {
  /// Se verdadeiro, renderiza como um painel permanente.
  final bool isPermanent;

  /// Callback opcional para fechar/recolher o drawer.
  final VoidCallback? onClose;

  const AppDrawer({super.key, this.isPermanent = false, this.onClose});

  /// Lista centralizada de destinos de navegação.
  /// Novos itens podem ser adicionados aqui sem alterar o layout do Drawer.
  static final List<DrawerDestinationItem> destinos = [
    DrawerDestinationItem(
      label: 'Configurações',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      onSelect: (context) => abrirConfiguracoes(context),
    ),
    const DrawerDestinationItem(
      label: 'Perfil',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      emBreve: true,
    ),
    const DrawerDestinationItem(
      label: 'Gerar PDF',
      icon: Icons.picture_as_pdf_outlined,
      selectedIcon: Icons.picture_as_pdf,
      emBreve: true,
    ),
    const DrawerDestinationItem(
      label: 'Comunidade Homebrew',
      icon: Icons.public_outlined,
      selectedIcon: Icons.public,
      emBreve: true,
    ),
    const DrawerDestinationItem(
      label: 'Criar Homebrew',
      icon: Icons.auto_fix_high_outlined,
      selectedIcon: Icons.auto_fix_high,
      emBreve: true,
    ),
  ];

  static void abrirConfiguracoes(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'T20 - Criador de heróis',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.shield,
        size: 40,
        color: Color(0xFFD32F2F), // Vermelho Tormenta
      ),
      children: const [
        SizedBox(height: 12),
        Text(
          'Ícones fornecidos por Game-Icons.net sob licença CC BY 3.0.',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 6),
        Text('Autores: Delapouite, Lorc e colaboradores.'),
        SizedBox(height: 6),
        Text('Disponível em: https://game-icons.net'),
      ],
    );
  }

  void _fecharGaveta(BuildContext context) {
    if (onClose != null) {
      onClose!();
      return;
    }
    final scaffoldState = Scaffold.maybeOf(context);
    if (scaffoldState != null && scaffoldState.isDrawerOpen) {
      scaffoldState.closeDrawer();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.shield,
                  color: colorScheme.onPrimaryContainer,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'T20',
                      style: textTheme.titleSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      'Criador de heróis',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Fechar menu',
                onPressed: () => _fecharGaveta(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
        ],
      ),
    );

    final drawerWidget = NavigationDrawer(
      selectedIndex: -1,
      onDestinationSelected: (index) {
        final destino = destinos[index];
        if (destino.habilitado) {
          if (!isPermanent) {
            _fecharGaveta(context);
          }
          destino.onSelect!(context);
        }
      },
      children: [
        header,
        ...destinos.map((destino) {
          final habilitado = destino.habilitado;

          final iconWidget = Icon(
            destino.icon,
            color: habilitado
                ? colorScheme.onSurfaceVariant
                : colorScheme.onSurface.withValues(alpha: 0.38),
          );

          final selectedIconWidget = Icon(
            destino.selectedIcon ?? destino.icon,
            color: colorScheme.primary,
          );

          // NavigationDrawerDestination usa uma Row interna de 280px (304 - 24 de margem)
          // onde 76px são usados por paddings (16+24) e ícone+gap (24+12), restando 204px
          // sem restrição (unbounded width) para o label.
          // Envolver em SizedBox(width: 200) fornece constraint finita (evitando crash de Expanded)
          // e garante que nunca ultrapasse os 204px disponíveis (evitando overflow de 14px).
          final labelWidget = SizedBox(
            width: 200,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    destino.label,
                    style: TextStyle(
                      color: habilitado
                          ? colorScheme.onSurface
                          : colorScheme.onSurface.withValues(alpha: 0.38),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (destino.emBreve) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Em breve',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.8,
                        ),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );

          return NavigationDrawerDestination(
            enabled: habilitado,
            icon: iconWidget,
            selectedIcon: selectedIconWidget,
            label: labelWidget,
          );
        }),
      ],
    );

    if (isPermanent) {
      return SizedBox(width: 304, child: drawerWidget);
    }

    return drawerWidget;
  }
}
