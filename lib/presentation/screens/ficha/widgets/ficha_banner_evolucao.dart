import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/entities/personagem/resumo_level_up.dart';
import '../../../../domain/services/powers_service/aprendizado_magia_service.dart';
import '../../../controllers/ficha_controller/ficha_cubit.dart';
import 'dialog_level_up_wizard.dart';

/// Banner exibido no topo da Ficha quando há evolução, poderes ou magias pendentes de escolha.
class FichaBannerEvolucao extends StatelessWidget {
  const FichaBannerEvolucao({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FichaCubit>();
    final p = cubit.personagem;
    if (p.classes.isEmpty) return const SizedBox.shrink();

    final idxPendente = p.classes.indexWhere((c) => c.temPoderPendente);
    final indiceEfetivo = idxPendente >= 0 ? idxPendente : 0;
    final cl = p.classes[indiceEfetivo];

    final pendentesPoderes = cl.poderesPendentes;
    final pendentesMagias =
        AprendizadoMagiaService.calcularMagiasPendentesPersonagem(p);

    if (pendentesPoderes <= 0 && pendentesMagias <= 0) {
      return const SizedBox.shrink();
    }

    String texto;
    if (pendentesPoderes > 0 && pendentesMagias > 0) {
      texto =
          'Evolução disponível: $pendentesPoderes ${pendentesPoderes == 1 ? "poder" : "poderes"} e $pendentesMagias ${pendentesMagias == 1 ? "magia" : "magias"} para escolher!';
    } else if (pendentesPoderes > 0) {
      texto =
          'Evolução disponível: escolher $pendentesPoderes ${pendentesPoderes == 1 ? "poder" : "poderes"} em ${cl.classeDefinicao.nome}';
    } else {
      texto =
          'Evolução disponível: escolher $pendentesMagias ${pendentesMagias == 1 ? "nova magia" : "novas magias"} para o grimório!';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Material(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        elevation: 3,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            final resumo = ResumoLevelUp.calcular(
              anterior: p,
              atualizado: p,
              indiceClasse: indiceEfetivo,
            );
            mostrarDialogLevelUpWizard(
              context: context,
              resumo: resumo,
              cubit: cubit,
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.stars_rounded, color: Colors.amber, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    texto,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.amber),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
