import 'package:flutter/material.dart';
import 'package:t20_creator/domain/entities/habilidades/modelos_resistencia_efeito.dart';
import 'package:t20_creator/domain/entities/testes/eventos_rede_testes.dart';

/// Diálogo para a ação LIVRE de "Avisar Aliados" ao desacreditar uma ilusão (R53 / Caso 10).
///
/// Quem percebeu a ilusão pode gastar uma Ação Livre para avisar seus aliados na mesa.
/// O Mestre confirma quais aliados conseguem ouvir/ver o aviso e eles realizam o teste.
class AvisarAliadosIlusaoDialog extends StatefulWidget {
  final String avisadorId;
  final String avisadorNome;
  final String efeitoIlusaoId;
  final String nomeIlusao;
  final List<Criatura> aliadosDisponiveis;
  final void Function(AvisarAliadosIntentPayload intent)? onEnviarIntent;

  const AvisarAliadosIlusaoDialog({
    super.key,
    required this.avisadorId,
    required this.avisadorNome,
    required this.efeitoIlusaoId,
    required this.nomeIlusao,
    required this.aliadosDisponiveis,
    this.onEnviarIntent,
  });

  @override
  State<AvisarAliadosIlusaoDialog> createState() =>
      _AvisarAliadosIlusaoDialogState();
}

class _AvisarAliadosIlusaoDialogState extends State<AvisarAliadosIlusaoDialog> {
  final Set<String> _selecionados = {};

  @override
  void initState() {
    super.initState();
    // Por padrão, sugere todos os aliados disponíveis
    _selecionados.addAll(widget.aliadosDisponiveis.map((a) => a.id));
  }

  void _enviar() {
    final intent = AvisarAliadosIntentPayload(
      avisadorId: widget.avisadorId,
      efeitoIlusaoId: widget.efeitoIlusaoId,
      aliadosAlvoIds: _selecionados.toList(),
    );

    widget.onEnviarIntent?.call(intent);
    Navigator.of(context).pop(intent);
  }

  @override
  Widget build(BuildContext context) {
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
                const Icon(Icons.record_voice_over, color: Colors.cyanAccent),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Avisar Aliados (Ação Livre)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 20),
            Text(
              '${widget.avisadorNome} percebeu que "${widget.nomeIlusao}" é uma ILUSÃO!\n'
              'Você pode gritar ou sinalizar para seus aliados como uma AÇÃO LIVRE. Quem for avisado poderá fazer um teste de Vontade para desacreditar também.',
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            const Text(
              'Selecione os aliados para alertar:',
              style: TextStyle(color: Colors.amberAccent, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: widget.aliadosDisponiveis.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Nenhum aliado no mapa.',
                          style: TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: widget.aliadosDisponiveis.length,
                      itemBuilder: (context, index) {
                        final aliado = widget.aliadosDisponiveis[index];
                        final marcado = _selecionados.contains(aliado.id);
                        return CheckboxListTile(
                          value: marcado,
                          activeColor: Colors.cyanAccent,
                          checkColor: Colors.black,
                          dense: true,
                          title: Text(
                            aliado.nome,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          subtitle: Text(
                            'Vontade +${aliado.bonusResistencia.vontade}',
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selecionados.add(aliado.id);
                              } else {
                                _selecionados.remove(aliado.id);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Nota: O Mestre confirmará quem estava em distância/condição de ouvir o aviso.',
              style: TextStyle(color: Colors.white38, fontSize: 11, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.white60)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.campaign, color: Colors.black, size: 18),
                  label: const Text('Avisar Aliados', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
                  onPressed: _selecionados.isEmpty ? null : _enviar,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
