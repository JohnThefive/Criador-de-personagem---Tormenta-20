import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/entities/personagem/personagem.dart';
import '../../../controllers/ficha_controller/ficha_cubit.dart';
import '../../wizard_personagem/selecao_poderes_screen.dart';

/// Banner exibido no topo da Ficha quando há evolução ou poderes pendentes de escolha.
class FichaBannerEvolucao extends StatelessWidget {
  const FichaBannerEvolucao({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FichaCubit>();
    final p = cubit.personagem;
    final idxPendente = p.classes.indexWhere((c) => c.temPoderPendente);
    final indiceEfetivo = idxPendente >= 0 ? idxPendente : 0;
    if (p.classes.isEmpty) return const SizedBox.shrink();

    final cl = p.classes[indiceEfetivo];
    final pendentes = cl.poderesPendentes;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Material(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final atualizado = await Navigator.push<Personagem>(
              context,
              MaterialPageRoute(
                builder: (_) => SelecaoPoderesScreen(
                  personagem: p,
                  indiceClasse: indiceEfetivo,
                ),
              ),
            );
            if (context.mounted && atualizado != null) {
              cubit.atualizarPersonagem(atualizado);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.stars_rounded, color: Colors.amber, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Evolução disponível: escolher $pendentes ${pendentes == 1 ? "poder" : "poderes"} em ${cl.classeDefinicao.nome}',
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
