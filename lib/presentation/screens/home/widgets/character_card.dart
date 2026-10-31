import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../domain/entities/personagem/personagem.dart';
import '../../../widgets/rpg_icon.dart';

/// Diálogo de confirmação para exclusão de um personagem.
Future<void> confirmarExclusaoPersonagem({
  required BuildContext context,
  required Personagem personagem,
  required VoidCallback onConfirmar,
}) async {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final textTheme = theme.textTheme;

  final confirmar = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: Icon(
        Icons.warning_amber_rounded,
        color: colorScheme.error,
        size: 32,
      ),
      title: Text(
        'Excluir Personagem',
        style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      content: Text(
        'Tem certeza de que deseja excluir "${personagem.nome}"?\nEsta ação apagará a ficha permanentemente e não pode ser desfeita.',
        style: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
          height: 1.4,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('CANCELAR'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
          ),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('EXCLUIR'),
        ),
      ],
    ),
  );

  if (confirmar == true) {
    onConfirmar();
  }
}

/// Fallback para avatar do personagem caso não haja foto.
Widget _buildAvatarFallback(Personagem personagem, ColorScheme colorScheme) {
  if (personagem.raca != null && personagem.raca!.icone.isNotEmpty) {
    return Center(
      child: RpgIcon(
        iconName: personagem.raca!.icone,
        size: 32,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
  return Icon(Icons.person, color: colorScheme.onSurfaceVariant, size: 34);
}

/// Avatar com suporte a imagem local em arquivo e fallback estilizado.
Widget _buildAvatar(
  Personagem personagem,
  ColorScheme colorScheme, {
  double size = 56,
}) {
  final temFoto =
      personagem.caminhoFoto != null && personagem.caminhoFoto!.isNotEmpty;

  return ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: Container(
      width: size,
      height: size,
      color: colorScheme.surfaceContainerHighest,
      child: temFoto
          ? Image.file(
              File(personagem.caminhoFoto!),
              width: size,
              height: size,
              cacheWidth: 160,
              cacheHeight: 160,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  _buildAvatarFallback(personagem, colorScheme),
            )
          : _buildAvatarFallback(personagem, colorScheme),
    ),
  );
}

/// Card de destaque para continuar a jogar com o último personagem ativo.
class ContinueCharacterCard extends StatelessWidget {
  final Personagem personagem;
  final VoidCallback onTap;
  final VoidCallback onExcluir;

  const ContinueCharacterCard({
    super.key,
    required this.personagem,
    required this.onTap,
    required this.onExcluir,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final classeNome = personagem.classes.isEmpty
        ? 'Sem Classe'
        : (personagem.classes.length == 1
              ? personagem.classes.first.classeDefinicao.nome
              : personagem.classes
                    .map((c) => '${c.classeDefinicao.nome} ${c.nivel}')
                    .join(' / '));
    final racaNome = personagem.raca?.nome ?? 'Sem Raça';
    final nivel = personagem.nivelPersonagem > 0
        ? personagem.nivelPersonagem
        : 1;

    return Card(
      elevation: 2,
      color: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.primary.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        onLongPress: () => confirmarExclusaoPersonagem(
          context: context,
          personagem: personagem,
          onConfirmar: onExcluir,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge "Continuar: <nome>"
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_arrow_rounded,
                          size: 16,
                          color: colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Interpretar',
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: colorScheme.outline,
                      size: 20,
                    ),
                    tooltip: 'Excluir personagem',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => confirmarExclusaoPersonagem(
                      context: context,
                      personagem: personagem,
                      onConfirmar: onExcluir,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildAvatar(personagem, colorScheme, size: 64),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          personagem.nome,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$classeNome • $racaNome',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
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
                                'Nível $nivel • ${personagem.nomePatamar}',
                                style: textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            Text(
                              'PV: ${personagem.pvTotal} • PM: ${personagem.pmTotal}',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card de listagem padrão para os demais personagens.
class CharacterCard extends StatelessWidget {
  final Personagem personagem;
  final VoidCallback onTap;
  final VoidCallback onExcluir;

  const CharacterCard({
    super.key,
    required this.personagem,
    required this.onTap,
    required this.onExcluir,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final classeNome = personagem.classes.isEmpty
        ? 'Sem Classe'
        : (personagem.classes.length == 1
              ? personagem.classes.first.classeDefinicao.nome
              : personagem.classes
                    .map((c) => '${c.classeDefinicao.nome} ${c.nivel}')
                    .join(' / '));
    final racaNome = personagem.raca?.nome ?? 'Sem Raça';
    final nivel = personagem.nivelPersonagem > 0
        ? personagem.nivelPersonagem
        : 1;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        onLongPress: () => confirmarExclusaoPersonagem(
          context: context,
          personagem: personagem,
          onConfirmar: onExcluir,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              _buildAvatar(personagem, colorScheme, size: 54),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      personagem.nome,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$classeNome • $racaNome',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            'Nvl $nivel • ${personagem.nomePatamar}',
                            style: textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Text(
                          'PV: ${personagem.pvTotal} • PM: ${personagem.pmTotal}',
                          style: textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: colorScheme.outline,
                  size: 20,
                ),
                tooltip: 'Excluir personagem',
                visualDensity: VisualDensity.compact,
                onPressed: () => confirmarExclusaoPersonagem(
                  context: context,
                  personagem: personagem,
                  onConfirmar: onExcluir,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
