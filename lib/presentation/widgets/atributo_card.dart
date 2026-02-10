import 'package:flutter/material.dart';
import '../../domain/entities/atributos.dart';

class AtributoCard extends StatelessWidget {
  final String sigla;
  final Atributo atributo;
  final Function(int) onUpdate;

  const AtributoCard({
    super.key,
    required this.sigla,
    required this.atributo,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    // Cor condicional: Modificador positivo verde, negativo vermelho
    final modColor = atributo.modificador >= 0 ? Colors.green[700] : Colors.red[700];

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Sigla e Nome
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sigla, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text(atributo.nome, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            
            // Controle de Valor ( - Valor + )
            Expanded(
              flex: 3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => onUpdate(atributo.valor - 1),
                  ),
                  Text(
                    '${atributo.valor}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => onUpdate(atributo.valor + 1),
                  ),
                ],
              ),
            ),

            // O Modificador (Resultado Calculado)
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: modColor!, width: 2),
              ),
              child: Center(
                child: Text(
                  atributo.modificador >= 0 ? '+${atributo.modificador}' : '${atributo.modificador}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: modColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}