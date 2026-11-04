import 'dart:io';
import 'package:flutter/material.dart';
import '../../../domain/entities/personagem/personagem.dart';
import 'rpg_icon.dart';

/// Componente centralizado e unificado para exibição do Avatar do Personagem.
///
/// Garante que qualquer tela do aplicativo (Home, Modo Arena, Ficha, Diálogos)
/// exiba a mesma representação visual:
/// 1. A foto customizada escolhida pelo jogador (`caminhoFoto`).
/// 2. Se não houver foto, o ícone oficial da Raça (`personagem.raca.icone`).
/// 3. Fallback genérico de silhueta de herói com tratamento seguro de erros.
class CharacterAvatarWidget extends StatelessWidget {
  final Personagem personagem;
  final double size;
  final double borderRadius;
  final bool useHero;
  final String? heroTag;
  final Color? backgroundColor;

  const CharacterAvatarWidget({
    super.key,
    required this.personagem,
    this.size = 56,
    this.borderRadius = 12,
    this.useHero = false,
    this.heroTag,
    this.backgroundColor,
  });

  Widget _buildFallback(BuildContext context, ColorScheme colorScheme) {
    if (personagem.raca != null && personagem.raca!.icone.isNotEmpty) {
      return Center(
        child: RpgIcon(
          iconName: personagem.raca!.icone,
          size: size * 0.58,
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }
    return Icon(
      Icons.person,
      color: colorScheme.onSurfaceVariant,
      size: size * 0.6,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final temFoto =
        personagem.caminhoFoto != null && personagem.caminhoFoto!.isNotEmpty;

    Widget avatarContent = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: size,
        height: size,
        color: backgroundColor ?? colorScheme.surfaceContainerHighest,
        child: temFoto
            ? Image.file(
                File(personagem.caminhoFoto!),
                width: size,
                height: size,
                cacheWidth: (size * 2.5).round(),
                cacheHeight: (size * 2.5).round(),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildFallback(context, colorScheme),
              )
            : _buildFallback(context, colorScheme),
      ),
    );

    if (useHero) {
      return Hero(
        tag: heroTag ?? 'character-avatar-${personagem.id}',
        child: avatarContent,
      );
    }

    return avatarContent;
  }
}
