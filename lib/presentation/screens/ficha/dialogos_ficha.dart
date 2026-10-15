import 'package:flutter/material.dart';

/// Diálogo com ciclo de vida seguro para entrada de texto
class CampoTextoDialog extends StatefulWidget {
  final String titulo;
  final String valorInicial;
  final String? label;
  final String? hint;
  final TextInputType keyboardType;
  final String textoBotaoConfirmar;
  final Color corBotaoConfirmar;

  const CampoTextoDialog({
    super.key,
    required this.titulo,
    this.valorInicial = '',
    this.label,
    this.hint,
    this.keyboardType = TextInputType.text,
    this.textoBotaoConfirmar = 'SALVAR',
    this.corBotaoConfirmar = const Color(0xFFD32F2F),
  });

  @override
  State<CampoTextoDialog> createState() => _CampoTextoDialogState();
}

class _CampoTextoDialogState extends State<CampoTextoDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.valorInicial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirmar() {
    final texto = _controller.text.trim();
    Navigator.of(context).pop(texto.isNotEmpty ? texto : null);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titulo),
      content: TextField(
        controller: _controller,
        keyboardType: widget.keyboardType,
        autofocus: true,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (_) => _confirmar(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('CANCELAR'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.corBotaoConfirmar,
          ),
          onPressed: _confirmar,
          child: Text(
            widget.textoBotaoConfirmar,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

/// Diálogo com ciclo de vida seguro para ajuste de recursos (PV / PM)
class AjusteRecursoDialog extends StatefulWidget {
  final String titulo;
  final String labelRecurso;
  final int valorAtual;
  final int valorTotal;
  final String labelReducao;
  final Color corReducao;
  final String labelAumento;
  final Color corAumento;

  const AjusteRecursoDialog({
    super.key,
    required this.titulo,
    required this.labelRecurso,
    required this.valorAtual,
    required this.valorTotal,
    required this.labelReducao,
    required this.corReducao,
    required this.labelAumento,
    required this.corAumento,
  });

  @override
  State<AjusteRecursoDialog> createState() => _AjusteRecursoDialogState();
}

class _AjusteRecursoDialogState extends State<AjusteRecursoDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _aplicar(bool ehAumento) {
    final valor = int.tryParse(_controller.text) ?? 0;
    if (valor <= 0) {
      Navigator.of(context).pop(null);
      return;
    }
    Navigator.of(context).pop(ehAumento ? valor : -valor);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titulo),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${widget.labelRecurso}: ${widget.valorAtual} / ${widget.valorTotal}',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Quantidade',
              hintText: 'Ex: 5',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _aplicar(true),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('CANCELAR'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: widget.corReducao),
          onPressed: () => _aplicar(false),
          child: Text(
            widget.labelReducao,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: widget.corAumento),
          onPressed: () => _aplicar(true),
          child: Text(
            widget.labelAumento,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
