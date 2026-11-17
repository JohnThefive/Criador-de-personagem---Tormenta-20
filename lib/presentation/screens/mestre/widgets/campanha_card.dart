import 'package:flutter/material.dart';
import '../../../../domain/entities/mestre/modelos_mestre.dart';

/// Diálogo padrão de confirmação para exclusão no Painel do Mestre.
Future<bool> confirmarExclusaoMestre({
  required BuildContext context,
  required String titulo,
  required String mensagem,
}) async {
  final colorScheme = Theme.of(context).colorScheme;
  final textTheme = Theme.of(context).textTheme;

  final confirmar = await showDialog<bool>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      icon: Icon(
        Icons.warning_amber_rounded,
        color: colorScheme.error,
        size: 32,
      ),
      title: Text(
        titulo,
        style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      content: Text(
        mensagem,
        style: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
          height: 1.4,
        ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: () => Navigator.of(dialogCtx).pop(false),
          child: const Text('CANCELAR'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
            minimumSize: const Size(48, 48),
          ),
          onPressed: () => Navigator.of(dialogCtx).pop(true),
          child: const Text('EXCLUIR'),
        ),
      ],
    ),
  );

  return confirmar == true;
}

/// Card de campanha no padrão visual dos cards da HomeScreen, com alvos >= 48dp.
class CampanhaCard extends StatelessWidget {
  final CampanhaMestre campanha;
  final bool selecionada;
  final VoidCallback onTap;
  final VoidCallback onExcluir;

  const CampanhaCard({
    super.key,
    required this.campanha,
    required this.selecionada,
    required this.onTap,
    required this.onExcluir,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final totalAventuras = campanha.aventuras.length;
    final totalSessoes = campanha.aventuras.fold<int>(
      0,
      (total, av) => total + av.sessoes.length,
    );

    final resumoAventuras = totalAventuras == 1
        ? '1 aventura'
        : '$totalAventuras aventuras';
    final resumoSessoes = totalSessoes == 1
        ? '1 sessão'
        : '$totalSessoes sessões';

    return Card(
      elevation: selecionada ? 2 : 0,
      color: selecionada
          ? colorScheme.surfaceContainerHigh
          : colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selecionada
              ? colorScheme.primary.withValues(alpha: 0.55)
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: selecionada ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: selecionada
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.campaign_outlined,
                    color: selecionada
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        campanha.nome,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$resumoAventuras • $resumoSessoes',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (campanha.codigoConexaoLan != null &&
                          campanha.codigoConexaoLan!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.wifi_tethering,
                                size: 14,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'LAN: ${campanha.codigoConexaoLan}',
                                style: textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: colorScheme.outline,
                  ),
                  tooltip: 'Excluir campanha',
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  onPressed: () async {
                    final confirmou = await confirmarExclusaoMestre(
                      context: context,
                      titulo: 'Excluir campanha',
                      mensagem:
                          'Deseja excluir "${campanha.nome}" e todas as suas aventuras e sessões?',
                    );
                    if (confirmou) {
                      onExcluir();
                    }
                  },
                ),
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
