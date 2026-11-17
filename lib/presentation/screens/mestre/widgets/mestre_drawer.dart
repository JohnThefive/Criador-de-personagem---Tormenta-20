import 'package:flutter/material.dart';

/// Destinos disponíveis no Drawer do Painel do Mestre.
enum MestreDestinoDrawer {
  campanhas('Campanhas'),
  mapas('Mapas'),
  bestiario('Bestiário'),
  escudoNotas('Escudo e Notas');

  final String titulo;
  const MestreDestinoDrawer(this.titulo);
}

/// Barra lateral de navegação do Painel do Mestre no padrão Material 3 da Home.
class MestreDrawer extends StatelessWidget {
  final int destinoSelecionado;
  final ValueChanged<int> onSelecionarDestino;
  final VoidCallback onVoltarHome;

  const MestreDrawer({
    super.key,
    required this.destinoSelecionado,
    required this.onSelecionarDestino,
    required this.onVoltarHome,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return NavigationDrawer(
      selectedIndex: destinoSelecionado,
      onDestinationSelected: (index) {
        Navigator.of(context).pop();
        onSelecionarDestino(index);
      },
      children: [
        Padding(
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
                      Icons.shield_moon_outlined,
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
                          'Painel do Mestre',
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
                    icon: const Icon(Icons.close),
                    tooltip: 'Fechar menu',
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
            ],
          ),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.campaign_outlined),
          selectedIcon: Icon(Icons.campaign),
          label: Text('Campanhas'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.map_outlined),
          selectedIcon: Icon(Icons.map),
          label: Text('Mapas'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.pets_outlined),
          selectedIcon: Icon(Icons.pets),
          label: Text('Bestiário'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.shield_outlined),
          selectedIcon: Icon(Icons.shield),
          label: Text('Escudo e Notas'),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Divider(height: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: ListTile(
            minTileHeight: 48,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            leading: Icon(
              Icons.home_outlined,
              color: colorScheme.onSurfaceVariant,
            ),
            title: Text(
              'Voltar para Heróis',
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            onTap: () {
              Navigator.of(context).pop();
              onVoltarHome();
            },
          ),
        ),
      ],
    );
  }
}
