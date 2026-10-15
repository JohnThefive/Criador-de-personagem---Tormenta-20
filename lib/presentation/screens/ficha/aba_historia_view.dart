import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../controllers/ficha_cubit.dart';

class AbaHistoriaView extends StatelessWidget {
  const AbaHistoriaView({super.key});

  @override
  Widget build(BuildContext context) {
    final personagem = context.watch<FichaCubit>().state.personagem;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'História & Personalidade',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 16),
        ListTile(
          dense: true,
          title: const Text(
            'Alinhamento',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(personagem.alinhamento),
        ),
        ListTile(
          dense: true,
          title: const Text(
            'Tamanho',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(personagem.tamanho),
        ),
        ListTile(
          dense: true,
          title: const Text(
            'Idade',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text('${personagem.idade} anos'),
        ),
        ListTile(
          dense: true,
          title: const Text(
            'Peso e Altura',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text('${personagem.peso} • ${personagem.altura}'),
        ),
        const Divider(height: 24),
        const Text(
          'Aparência e Biografia:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            personagem.descricaoAparencia.isNotEmpty
                ? personagem.descricaoAparencia
                : 'Nenhuma descrição fornecida para este aventureiro.',
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
        ),
      ],
    );
  }
}
