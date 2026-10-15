import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/services/data_services/call_magias.dart';
import '../../controllers/ficha_cubit.dart';

class AbaMagiasView extends StatelessWidget {
  const AbaMagiasView({super.key});

  @override
  Widget build(BuildContext context) {
    final personagem = context.watch<FichaCubit>().state.personagem;
    final magiasIds = personagem.magiasConhecidas;
    final magias = magiasIds.map((id) => BancoDeMagias.getById(id)).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Grimório / Magias',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Chip(
              backgroundColor: Colors.blue.shade100,
              label: Text(
                'PM: ${personagem.pmAtual}/${personagem.pmTotal}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Text(
            'Seu herói pode conjurar magias gastando Pontos de Mana (PM). Magias de 1º Círculo custam tipicamente 1 PM.',
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
        ),
        const SizedBox(height: 16),
        if (magias.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'Nenhuma magia conhecida.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ...magias.map((magia) {
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: ExpansionTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Color(0xFF2563EB), size: 20),
                ),
                title: Text(
                  magia.nome,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                subtitle: Text(
                  '${magia.escola.toUpperCase()} • ${magia.circulo}º Círculo • ${magia.tipo.toUpperCase()}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                childrenPadding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Execução: ${magia.execucao.detalhes ?? magia.execucao.tipo}',
                          style: const TextStyle(fontSize: 12.5),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Alcance: ${magia.alcance.detalhes ?? magia.alcance.tipo}',
                          style: const TextStyle(fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Duração: ${magia.duracao.detalhes ?? magia.duracao.tipo}',
                          style: const TextStyle(fontSize: 12.5),
                        ),
                      ),
                      if (magia.resistencia != null)
                        Expanded(
                          child: Text(
                            'Resistência: ${magia.resistencia!.tipoTeste ?? ""} (${magia.resistencia!.resultadoSucesso})',
                            style: const TextStyle(fontSize: 12.5),
                          ),
                        ),
                    ],
                  ),
                  const Divider(height: 18),
                  Text(
                    magia.descricao,
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                  if (magia.aprimoramentos.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Aprimoramentos:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    ...magia.aprimoramentos.map((ap) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          ap.custoAdicionalPM > 0
                              ? '• +${ap.custoAdicionalPM} PM: ${ap.descricao}'
                              : '• Truque: ${ap.descricao}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            );
          }),
      ],
    );
  }
}
