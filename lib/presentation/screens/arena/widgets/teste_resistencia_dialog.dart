import 'package:flutter/material.dart';
import 'package:t20_creator/domain/entities/habilidades/modelos_habilidade_duracao.dart';
import 'package:t20_creator/domain/services/habilidades_services/resistencia_service.dart';
import 'package:t20_creator/domain/services/testes_services/i_rng.dart';

/// Diálogo modal interativo para resolução do Teste de Resistência do Jogador (R50–R55).
///
/// Filosofia VTT (Roll20 / Foundry): Auxilia o jogador exibindo a CD, a habilidade instigadora,
/// se é magia, o tipo de resistência e permite tanto rolar automaticamente quanto inserir
/// o resultado do dado físico manualmente.
class TesteResistenciaDialog extends StatefulWidget {
  final Criatura criatura;
  final String nomeHabilidade;
  final bool ehMagia;
  final TipoResistencia? tipoResistencia;
  final String? pericia;
  final int cd;
  final TipoResultadoResistencia resultadoEsperado;
  final ResistenciaService? resistenciaService;
  final void Function(ResultadoResistencia)? onResultado;

  const TesteResistenciaDialog({
    super.key,
    required this.criatura,
    required this.nomeHabilidade,
    this.ehMagia = false,
    this.tipoResistencia,
    this.pericia,
    required this.cd,
    required this.resultadoEsperado,
    this.resistenciaService,
    this.onResultado,
  });

  @override
  State<TesteResistenciaDialog> createState() => _TesteResistenciaDialogState();
}

class _TesteResistenciaDialogState extends State<TesteResistenciaDialog> {
  late final ResistenciaService _service;
  final TextEditingController _dadoManualController = TextEditingController();
  bool _modoManual = false;
  ResultadoResistencia? _resultado;

  @override
  void initState() {
    super.initState();
    _service = widget.resistenciaService ?? ResistenciaService(rng: RandomRng());
  }

  @override
  void dispose() {
    _dadoManualController.dispose();
    super.dispose();
  }

  void _rolar({int? d20Manual}) {
    final res = _service.resolverResistenciaCriatura(
      criatura: widget.criatura,
      habilidade: Habilidade(
        id: 'resistencia_${widget.nomeHabilidade}',
        nome: widget.nomeHabilidade,
        ehMagia: widget.ehMagia,
        resistencia: HabilidadeResistencia(
          tipo: widget.tipoResistencia ?? TipoResistencia.fortitude,
          resultado: widget.resultadoEsperado,
        ),
        resistePericia: widget.pericia != null
            ? ResistePericia(pericia: widget.pericia!)
            : null,
      ),
      cdResistencia: widget.cd,
      d20Forcado: d20Manual,
    );

    setState(() {
      _resultado = res;
    });

    widget.onResultado?.call(res);
  }

  @override
  Widget build(BuildContext context) {
    final nomeTeste = widget.pericia != null
        ? 'Perícia: ${widget.pericia}'
        : (widget.tipoResistencia?.name.toUpperCase() ?? 'FORTITUDE');

    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  widget.ehMagia ? Icons.auto_awesome : Icons.shield_outlined,
                  color: Colors.amberAccent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Teste de Resistência',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.of(context).pop(_resultado),
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 24),
            Text(
              '${widget.criatura.nome} está sob efeito de "${widget.nomeHabilidade}".',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text(
                        'TESTE',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        nomeTeste,
                        style: const TextStyle(
                          color: Colors.amberAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Text(
                        'CD',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.cd}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Text(
                        'SE PASSAR',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.resultadoEsperado.name.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_resultado == null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Inserir dado físico manualmente',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  Switch(
                    value: _modoManual,
                    activeTrackColor: Colors.amberAccent,
                    onChanged: (val) => setState(() => _modoManual = val),
                  ),
                ],
              ),
              if (_modoManual) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _dadoManualController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Valor do d20 tirado na mesa (1 a 20)',
                    labelStyle: const TextStyle(color: Colors.white60),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check, color: Colors.black),
                  label: const Text('Confirmar Rolagem Manual', style: TextStyle(color: Colors.black)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent),
                  onPressed: () {
                    final d20 = int.tryParse(_dadoManualController.text.trim());
                    if (d20 == null || d20 < 1 || d20 > 20) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Insira um valor de d20 entre 1 e 20.')),
                      );
                      return;
                    }
                    _rolar(d20Manual: d20);
                  },
                ),
              ] else ...[
                ElevatedButton.icon(
                  icon: const Icon(Icons.casino, color: Colors.black),
                  label: const Text('Rolar no VTT', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent, padding: const EdgeInsets.symmetric(vertical: 12)),
                  onPressed: () => _rolar(),
                ),
              ],
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _resultado!.sucesso
                      ? Colors.green.withValues(alpha: 0.15)
                      : Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _resultado!.sucesso ? Colors.greenAccent : Colors.redAccent,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _resultado!.sucesso ? 'PASSOU NO TESTE!' : 'FALHOU NO TESTE!',
                      style: TextStyle(
                        color: _resultado!.sucesso ? Colors.greenAccent : Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _resultado!.log,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white24),
                onPressed: () => Navigator.of(context).pop(_resultado),
                child: const Text('Fechar', style: TextStyle(color: Colors.white)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
