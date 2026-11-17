import 'package:flutter/material.dart';
import '../../../domain/entities/mestre/modelos_mestre.dart';
import '../../controllers/mestre_controller/mestre_cubit.dart';
import 'theme/mestre_theme.dart';
import 'widgets/mestre_form_scaffold.dart';

/// Subtela de criação de Sessão vinculada a uma Aventura.
class CriarSessaoScreen extends StatefulWidget {
  final MestreCubit cubit;
  final String campanhaId;
  final String? aventuraIdInicial;
  final bool emFluxoGuiado;

  const CriarSessaoScreen({
    super.key,
    required this.cubit,
    required this.campanhaId,
    this.aventuraIdInicial,
    this.emFluxoGuiado = false,
  });

  @override
  State<CriarSessaoScreen> createState() => _CriarSessaoScreenState();
}

class _CriarSessaoScreenState extends State<CriarSessaoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  String? _aventuraIdSelecionada;

  @override
  void initState() {
    super.initState();
    final camp = _obterCampanha();
    final aventuras = camp?.aventuras ?? const <AventuraMestre>[];
    if (widget.aventuraIdInicial != null &&
        aventuras.any((a) => a.id == widget.aventuraIdInicial)) {
      _aventuraIdSelecionada = widget.aventuraIdInicial;
    } else {
      _aventuraIdSelecionada = aventuras.firstOrNull?.id;
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  CampanhaMestre? _obterCampanha() {
    return widget.cubit.state.campanhas
        .where((c) => c.id == widget.campanhaId)
        .firstOrNull;
  }

  void _confirmar() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final aventuraId = _aventuraIdSelecionada;
    if (aventuraId == null) return;

    final sessao = widget.cubit.criarSessao(
      campanhaId: widget.campanhaId,
      aventuraId: aventuraId,
      titulo: _nomeController.text.trim(),
    );

    if (sessao == null || !mounted) return;
    Navigator.of(context).pop(sessao.id);
  }

  @override
  Widget build(BuildContext context) {
    final camp = _obterCampanha();
    final aventuras = camp?.aventuras ?? const <AventuraMestre>[];

    return Theme(
      data: MestreCores.homeStyleTheme,
      child: Builder(
        builder: (themedContext) {
          final colorScheme = Theme.of(themedContext).colorScheme;
          final textTheme = Theme.of(themedContext).textTheme;

          return MestreFormScaffold(
            titulo: 'Nova Sessão',
            subtituloEtapa:
                widget.emFluxoGuiado ? 'Etapa 3 de 3 • Sessão' : null,
            formKey: _formKey,
            textoBotaoConfirmar: 'Criar sessão',
            onConfirmar: _confirmar,
            campos: [
              if (camp != null) ...[
                Text(
                  'Campanha: ${camp.nome}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              DropdownButtonFormField<String>(
                initialValue: _aventuraIdSelecionada,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Aventura vinculada *',
                  prefixIcon: Icon(Icons.auto_stories_outlined),
                ),
                items: aventuras
                    .map(
                      (av) => DropdownMenuItem<String>(
                        value: av.id,
                        child: Text(
                          av.nome,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                validator: (val) => (val == null || val.isEmpty)
                    ? 'Selecione uma aventura'
                    : null,
                onChanged: (val) =>
                    setState(() => _aventuraIdSelecionada = val),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nomeController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                scrollPadding: const EdgeInsets.only(bottom: 100),
                decoration: const InputDecoration(
                  labelText: 'Nome da sessão *',
                  hintText: 'Ex: Sessão 1 — A Taverna',
                  prefixIcon: Icon(Icons.event_note_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Informe o nome da sessão';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _confirmar(),
              ),
            ],
          );
        },
      ),
    );
  }
}
