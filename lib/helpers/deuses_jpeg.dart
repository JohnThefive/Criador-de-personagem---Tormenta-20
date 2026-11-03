import 'package:flutter/material.dart';

// REsolver pra não precisar chamar Todo o caminho para chamar os JPEGs

String? resolverIconeDeus(String id) {
  final clean = id.toLowerCase().trim();
  final mapa = {
    'aharadak': 'assets/icons/deuses/aharadak.webp',
    'allihanna': 'assets/icons/deuses/allihanna.webp',
    'arsenal': 'assets/icons/deuses/arsenal.webp',
    'azgher': 'assets/icons/deuses/azgher.webp',
    'asgher': 'assets/icons/deuses/azgher.webp',
    'hyninn': 'assets/icons/deuses/hyninn.webp',
    'kallyadranoch': 'assets/icons/deuses/kallyadranoch.webp',
    'khalmyr': 'assets/icons/deuses/khalmyr.webp',
    'lena': 'assets/icons/deuses/lena.webp',
    'lin-wu': 'assets/icons/deuses/lin-wu.webp',
    'wynna': 'assets/icons/deuses/wynna.webp',
    'lynna': 'assets/icons/deuses/wynna.webp',
    'marah': 'assets/icons/deuses/marah.webp',
    'megalokk': 'assets/icons/deuses/megalokk.webp',
    'nimb': 'assets/icons/deuses/nimb.webp',
    'oceano': 'assets/icons/deuses/oceano.webp',
    'sszzaas': 'assets/icons/deuses/sszzaas.webp',
    'tanna-toh': 'assets/icons/deuses/tanna-toh.webp',
    'tannatoh': 'assets/icons/deuses/tanna-toh.webp',
    'tenebra': 'assets/icons/deuses/tenebra.webp',
    'thwor': 'assets/icons/deuses/thwor.webp',
    'thyatis': 'assets/icons/deuses/thyatis.webp',
    'valkaria': 'assets/icons/deuses/valkaria.webp',
  };
  return mapa[clean] ?? 'assets/icons/deuses/$clean.webp';
}

// Widget de simbolo de divindade
class SimboloDivindade extends StatelessWidget {
  final String idDivindade;
  final double tamanho;

  const SimboloDivindade({
    super.key,
    required this.idDivindade,
    this.tamanho = 56,
  });

  @override
  Widget build(BuildContext context) {
    final assetPath = resolverIconeDeus(idDivindade);

    return Container(
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber[700]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.5),
        child: assetPath != null
            ? Image.asset(
                assetPath,
                fit: BoxFit.cover,
                cacheWidth: (tamanho * 3).round(),
                errorBuilder: (_, _, _) => Icon(
                  Icons.auto_awesome,
                  size: tamanho * 0.5,
                  color: Colors.amber[800],
                ),
              )
            : Icon(
                Icons.auto_awesome,
                size: tamanho * 0.5,
                color: Colors.amber[800],
              ),
      ),
    );
  }
}
