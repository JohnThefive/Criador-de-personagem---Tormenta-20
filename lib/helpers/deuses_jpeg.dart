import 'package:flutter/material.dart';

// REsolver pra não precisar chamar Todo o caminho para chamar os JPEGs

String? resolverIconeDeus(String id) {
  final clean = id.toLowerCase().trim();
  final mapa = {
    'aharadak': 'assets/icons/deuses/aharadak.jpeg',
    'allihanna': 'assets/icons/deuses/allihanna.jpeg',
    'arsenal': 'assets/icons/deuses/arsenal.jpeg',
    'azgher': 'assets/icons/deuses/azgher.jpeg',
    'asgher': 'assets/icons/deuses/azgher.jpeg',
    'hyninn': 'assets/icons/deuses/hyninn.jpeg',
    'kallyadranoch': 'assets/icons/deuses/kallyadranoch.jpeg',
    'khalmyr': 'assets/icons/deuses/khalmyr.jpeg',
    'lena': 'assets/icons/deuses/lena.jpeg',
    'lin-wu': 'assets/icons/deuses/lin-wu.jpeg',
    'wynna': 'assets/icons/deuses/wynna.jpeg',
    'lynna': 'assets/icons/deuses/wynna.jpeg',
    'marah': 'assets/icons/deuses/marah.jpeg',
    'megalokk': 'assets/icons/deuses/megalokk.jpeg',
    'nimb': 'assets/icons/deuses/nimb.jpeg',
    'oceano': 'assets/icons/deuses/oceano.jpeg',
    'sszzaas': 'assets/icons/deuses/sszzaas.jpeg',
    'tanna-toh': 'assets/icons/deuses/tanna-toh.jpeg',
    'tannatoh': 'assets/icons/deuses/tanna-toh.jpeg',
    'tenebra': 'assets/icons/deuses/tenebra.jpeg',
    'thwor': 'assets/icons/deuses/thwor.jpeg',
    'thyatis': 'assets/icons/deuses/thyatis.jpeg',
    'valkaria': 'assets/icons/deuses/valkaria.jpeg',
  };
  return mapa[clean] ?? 'assets/icons/deuses/$clean.jpeg';
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
