import 'package:flutter/material.dart';

class ArenaTerminalLog extends StatelessWidget {
  final List<String> logs;

  const ArenaTerminalLog({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    final logInvertido = logs.reversed.toList();

    return Container(
      height: 80,
      width: double.infinity,
      color: Colors.black,
      padding: const EdgeInsets.all(6),
      child: ListView.builder(
        reverse: true,
        itemCount: logs.length,
        itemBuilder: (context, index) {
          return Text(
            logInvertido[index],
            style: const TextStyle(
              color: Colors.greenAccent,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          );
        },
      ),
    );
  }
}
