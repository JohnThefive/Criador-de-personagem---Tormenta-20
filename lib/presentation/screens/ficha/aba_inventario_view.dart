import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../controllers/ficha_cubit.dart';
import 'dialogos_ficha.dart';

class AbaInventarioView extends StatelessWidget {
  const AbaInventarioView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<FichaCubit>();
    final personagem = cubit.state.personagem;
    final itens = personagem.itensInventario;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Mochila & Equipamentos',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle, color: Color(0xFFD32F2F)),
              tooltip: 'Adicionar Item',
              onPressed: () async {
                final texto = await showDialog<String>(
                  context: context,
                  builder: (ctx) => const CampoTextoDialog(
                    titulo: 'Adicionar Item',
                    label: 'Nome do item',
                    hint: 'Ex: Poção de Cura, Corda...',
                    textoBotaoConfirmar: 'ADICIONAR',
                    corBotaoConfirmar: Color(0xFFD32F2F),
                  ),
                );

                if (texto != null && texto.isNotEmpty) {
                  final novaLista = List<String>.from(itens)..add(texto);
                  cubit.atualizarPersonagem(
                    personagem.copyWith(itensInventario: novaLista),
                  );
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (itens.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text(
                'Mochila vazia.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ...itens.map(
            (item) => Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                dense: true,
                leading: const Icon(
                  Icons.inventory_2_outlined,
                  color: Colors.brown,
                ),
                title: Text(
                  item,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    final novaLista = List<String>.from(itens)..remove(item);
                    cubit.atualizarPersonagem(
                      personagem.copyWith(itensInventario: novaLista),
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}
