import 'package:flutter/material.dart';
import '../../../../domain/entities/magia/magia.dart';
import '../../../../domain/entities/personagem/personagem.dart';
import '../../../../domain/services/data_services/call_magias.dart';
import '../../../../domain/services/powers_service/aprendizado_magia_service.dart';
import '../../../controllers/ficha_controller/ficha_cubit.dart';

/// Modal para consulta e aprendizado de magias de Tormenta 20.
/// Valida círculos liberados por classe/tradição e permite desbloquear magias extras.
class ModalCatalogoMagias extends StatefulWidget {
  final Personagem personagem;
  final List<Magia> todasMagias;
  final List<String> conhecidasIds;
  final int circuloMaximoDesbloqueado;
  final int circuloInicial;
  final String? filtroTipoInicial;
  final void Function(String magiaId, bool validarClasse) onAdicionar;

  const ModalCatalogoMagias({
    super.key,
    required this.personagem,
    required this.todasMagias,
    required this.conhecidasIds,
    this.circuloMaximoDesbloqueado = 1,
    this.circuloInicial = 0,
    this.filtroTipoInicial,
    required this.onAdicionar,
  });

  @override
  State<ModalCatalogoMagias> createState() => _ModalCatalogoMagiasState();
}

class _ModalCatalogoMagiasState extends State<ModalCatalogoMagias> {
  String _busca = '';
  late int _circulo;
  String? _filtroTipo;
  bool _liberarExtraOuRacial = false;

  @override
  void initState() {
    super.initState();
    _circulo = widget.circuloInicial;
    _filtroTipo = widget.filtroTipoInicial;
  }

  @override
  Widget build(BuildContext context) {
    final circArcano = AprendizadoMagiaService.obterCirculoMaximoPorTipoMagia(
      widget.personagem,
      'arcana',
    );
    final circDivino = AprendizadoMagiaService.obterCirculoMaximoPorTipoMagia(
      widget.personagem,
      'divina',
    );

    final filtradas = widget.todasMagias.where((m) {
      if (_circulo > 0 && m.circulo != _circulo) return false;
      if (_filtroTipo != null && _filtroTipo!.isNotEmpty) {
        if (m.tipo.toLowerCase() != _filtroTipo!.toLowerCase() &&
            m.tipo.toLowerCase() != 'universal') {
          return false;
        }
      }
      if (_busca.isNotEmpty &&
          !m.nome.toLowerCase().contains(_busca.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.auto_stories, color: Color(0xFFD32F2F)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Catálogo de Magias (T20)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Círculos por classe: Arcana ${circArcano > 0 ? "$circArcanoº" : "—"} • Divina ${circDivino > 0 ? "$circDivinoº" : "—"}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            TextField(
              onChanged: (v) => setState(() => _busca = v),
              decoration: const InputDecoration(
                hintText: 'Buscar magia por nome...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [0, 1, 2, 3, 4, 5].map((c) {
                        final acimaDoLimite =
                            c > 0 && c > widget.circuloMaximoDesbloqueado;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            selected: _circulo == c,
                            label: Text(
                              c == 0
                                  ? 'Todos'
                                  : (acimaDoLimite ? '$cº 🔒' : '$cº'),
                            ),
                            onSelected: (_) => setState(() => _circulo = c),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                FilterChip(
                  selected: _liberarExtraOuRacial,
                  visualDensity: VisualDensity.compact,
                  label: const Text(
                    'Extra/Poder',
                    style: TextStyle(fontSize: 11),
                  ),
                  onSelected: (v) => setState(() => _liberarExtraOuRacial = v),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                itemCount: filtradas.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, idx) {
                  final m = filtradas[idx];
                  final jaConhece = widget.conhecidasIds.contains(m.id);
                  final liberadaNaClasse =
                      AprendizadoMagiaService.podeAprenderMagiaNoPersonagem(
                        widget.personagem,
                        m,
                      );
                  final podeSelecionar =
                      !jaConhece && (liberadaNaClasse || _liberarExtraOuRacial);

                  return ListTile(
                    dense: true,
                    enabled: podeSelecionar || jaConhece,
                    title: Text(
                      m.nome,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      liberadaNaClasse
                          ? '${m.circulo}º Círculo • ${m.tipo.toUpperCase()} • ${m.escola}'
                          : '${m.circulo}º Círculo • ${m.tipo.toUpperCase()} • 🔒 Requer nível na classe conjuradora',
                    ),
                    trailing: jaConhece
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : (podeSelecionar
                              ? const Icon(
                                  Icons.add_circle_outline,
                                  color: Color(0xFFD32F2F),
                                )
                              : const Icon(
                                  Icons.lock_outline,
                                  color: Colors.grey,
                                  size: 18,
                                )),
                    onTap: !podeSelecionar
                        ? null
                        : () {
                            widget.onAdicionar(m.id, !_liberarExtraOuRacial);
                            Navigator.pop(context, m);
                          },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Função de conveniência para abrir o modal de catálogo de magias
Future<Magia?> abrirModalCatalogoMagias({
  required BuildContext context,
  required Personagem personagem,
  required FichaCubit cubit,
  int circuloInicial = 0,
  String? filtroTipoInicial,
}) async {
  final todas = BancoDeMagias.todas;
  final circuloMax = AprendizadoMagiaService.obterCirculoMaximoPersonagem(
    personagem,
  );

  return showModalBottomSheet<Magia>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => ModalCatalogoMagias(
      personagem: personagem,
      todasMagias: todas,
      conhecidasIds: personagem.magiasConhecidas,
      circuloMaximoDesbloqueado: circuloMax,
      circuloInicial: circuloInicial,
      filtroTipoInicial: filtroTipoInicial,
      onAdicionar: (id, validarClasse) => cubit.adicionarMagiaConhecida(
        id,
        validarCirculoClasse: validarClasse,
      ),
    ),
  );
}
