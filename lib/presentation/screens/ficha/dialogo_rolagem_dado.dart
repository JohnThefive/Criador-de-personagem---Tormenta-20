import 'dart:math';
import 'package:flutter/material.dart';

void mostrarDialogoRolagemDado(
  BuildContext context, {
  required int lados,
  required int mod,
  required String rotulo,
}) {
  final rand = Random();
  final resultadoDado = rand.nextInt(lados) + 1;
  final total = resultadoDado + mod;

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        rotulo,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: resultadoDado == 20
                  ? Colors.amber.shade100
                  : resultadoDado == 1
                  ? Colors.red.shade100
                  : Colors.grey.shade100,
              border: Border.all(
                color: resultadoDado == 20
                    ? Colors.amber
                    : resultadoDado == 1
                    ? Colors.red
                    : Colors.grey.shade300,
                width: 3,
              ),
            ),
            child: Text(
              '$resultadoDado',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: resultadoDado == 20
                    ? Colors.amber.shade900
                    : resultadoDado == 1
                    ? Colors.red.shade900
                    : Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (mod != 0)
            Text(
              'Dado: $resultadoDado   Modificador: ${mod >= 0 ? "+$mod" : "$mod"}',
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
          const SizedBox(height: 6),
          Text(
            'Resultado Final: $total',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          if (lados == 20 && resultadoDado == 20)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                '🎉 20 NATURAL! SUCESSO CRÍTICO! 🎉',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (lados == 20 && resultadoDado == 1)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                '💀 1 NATURAL! FALHA CRÍTICA! 💀',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      actions: [
        Center(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    ),
  );
}
