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

  static const Set<String> _classesConhecidas = {
    'arcanista',
    'barbaro',
    'bardo',
    'bucaneiro',
    'cacador',
    'cavaleiro',
    'clerigo',
    'druida',
    'guerreiro',
    'inventor',
    'ladino',
    'lutador',
    'nobre',
    'paladino',
  };

  static String resolverCaminhoAsset(String iconName) {
    String clean = iconName.trim();
    if (clean.endsWith('.svg')) {
      clean = clean.substring(0, clean.length - 4);
    }
    // Padroniza em minúsculas para garantir consistência e evitar duplicatas
    clean = clean.toLowerCase();

    // Aliases para manter compatibilidade com nomes antigos/alternativos
    if (clean == 'sereia' || clean == 'racas/sereia') {
      clean = 'racas/sereia_tritao';
    } else if (clean == 'suraggel(luz)' ||
        clean == 'suraggel_luz' ||
        clean == 'racas/suraggel(luz)' ||
        clean == 'racas/suraggel_luz') {
      clean = 'racas/suraggel_aggelus';
    } else if (clean == 'suraggel(escuro)' ||
        clean == 'suraggel_escuro' ||
        clean == 'racas/suraggel(escuro)' ||
        clean == 'racas/suraggel_escuro') {
      clean = 'racas/suraggel_sulfure';
    }

    // Se for um identificador direto de classe sem barra, redireciona para a pasta de classes
    if (!clean.contains('/') && _classesConhecidas.contains(clean)) {
      clean = 'classes/$clean';
    }

    final prefix = clean.startsWith('assets/')
        ? ''
        : (clean.contains('/') ? 'assets/icons/' : 'assets/icons/racas/');
    return '$prefix$clean.svg';
  }

  String _resolverCaminhoAsset() => resolverCaminhoAsset(iconName);

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
