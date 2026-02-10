import 'package:flutter/material.dart';
import '../../domain/entities/atributos.dart';

class AtributoCardCompra extends StatelessWidget {
  final String sigla;
  final Atributo atributo;
  final VoidCallback onIncrement; // Função sem parâmetros (apenas avisa que clicou)
  final VoidCallback onDecrement; // Função sem parâmetros

  const AtributoCardCompra({
    super.key,
    required this.sigla,
    required this.atributo,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    // Regra visual: Se o valor for menor que -1 ou maior que 4 (limites T20 compra), 
    // podemos desabilitar visualmente os botões futuramente.
    
    // Cor do modificador
    final modColor = atributo.modificador >= 0 ? Colors.green[700] : Colors.red[700];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Coluna 1: Nome do Atributo
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sigla, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(atributo.nome, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),

            // Coluna 2: Controles (- Valor +)
            Expanded(
              flex: 4,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: onDecrement,
                    color: Colors.redAccent,
                  ),
                  Text(
                    '${atributo.valor}', // Valor bruto (ex: 18)
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: onIncrement,
                    color: Colors.green,
                  ),
                ],
              ),
            ),

            // Coluna 3: Modificador Final
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                // ignore: deprecated_member_use
                border: Border.all(color: modColor!.withOpacity(0.5)),
              ),
              child: Text(
                atributo.modificador >= 0 ? '+${atributo.modificador}' : '${atributo.modificador}',
                style: TextStyle(fontWeight: FontWeight.bold, color: modColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}