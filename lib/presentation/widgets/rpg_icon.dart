import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class RpgIcon extends StatelessWidget {
  final String iconName;
  final double size;
  final Color? color;

  const RpgIcon({
    super.key,
    required this.iconName,
    this.size = 24.0,
    this.color,
  });

  String _resolverCaminhoAsset() {
    if (iconName.startsWith('assets/')) {
      return iconName.endsWith('.svg') ? iconName : '$iconName.svg';
    }

    // Se já contém subpasta (ex: "racas/anao")
    if (iconName.contains('/')) {
      final semExt = iconName.endsWith('.svg')
          ? iconName.substring(0, iconName.length - 4)
          : iconName;
      return 'assets/icons/$semExt.svg';
    }

    // Fallback padrão se passado apenas o nome direto da raça (ex: "anao")
    final semExt = iconName.endsWith('.svg')
        ? iconName.substring(0, iconName.length - 4)
        : iconName;
    return 'assets/icons/racas/$semExt.svg';
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        color ?? Theme.of(context).iconTheme.color ?? Colors.white;

    return SvgPicture.asset(
      _resolverCaminhoAsset(),
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(effectiveColor, BlendMode.srcIn),
      placeholderBuilder: (context) => SizedBox(
        width: size,
        height: size,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
    );
  }
}
