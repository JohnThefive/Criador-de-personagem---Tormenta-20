import 'package:flutter/material.dart';
import '../../controllers/mestre_controller/mestre_cubit.dart';
import 'criar_sessao_screen.dart';
import 'theme/mestre_theme.dart';
import 'widgets/mestre_form_scaffold.dart';

/// Subtela de criação de Aventura vinculada a uma Campanha.
class CriarAventuraScreen extends StatefulWidget {
  final MestreCubit cubit;
  final String? campanhaIdInicial;
  final bool emFluxoGuiado;

  const CriarAventuraScreen({
    super.key,
    required this.cubit,
    this.campanhaIdInicial,
    this.emFluxoGuiado = false,
  });

  @override
  State<CriarAventuraScreen> createState() => _CriarAventuraScreenState();
}

class _CriarAventuraScreenState extends State<CriarAventuraScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  String? _campanhaIdSelecionada;

  @override
  void initState() {
    super.initState();
    final campanhas = widget.cubit.state.campanhas;
    if (widget.campanhaIdInicial != null &&
        campanhas.any((c) => c.id == widget.campanhaIdInicial)) {
      _campanhaIdSelecionada = widget.campanhaIdInicial;
    } else {
      _campanhaIdSelecionada =
          widget.cubit.state.campanhaAtual?.id ?? campanhas.firstOrNull?.id;
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final campanhaId = _campanhaIdSelecionada;
    if (campanhaId == null) return;

    final aventura = widget.cubit.criarAventura(
      campanhaId: campanhaId,
      nome: _nomeController.text.trim(),
      criarSessaoPadrao: false,
    );

    if (aventura == null || !mounted) return;

    final querCriarSessao = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Aventura criada'),
        content: Text(
          'A aventura "${aventura.nome}" foi criada. Deseja criar a primeira sessão agora?',
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Agora não'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Criar sessão'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (querCriarSessao == true) {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<String?>(
          builder: (_) => CriarSessaoScreen(
            cubit: widget.cubit,
            campanhaId: campanhaId,
            aventuraIdInicial: aventura.id,
            emFluxoGuiado: widget.emFluxoGuiado,
          ),
        ),
      );
      return;
    }

    Navigator.of(context).pop(aventura.id);
  }

  @override
  Widget build(BuildContext context) {
    final campanhas = widget.cubit.state.campanhas;

    return Theme(
      data: MestreCores.homeStyleTheme,
      child: MestreFormScaffold(
        titulo: 'Nova Aventura',
        subtituloEtapa: widget.emFluxoGuiado ? 'Etapa 2 de 3 • Aventura' : null,
        formKey: _formKey,
        textoBotaoConfirmar: 'Criar aventura',
        onConfirmar: _confirmar,
        campos: [
          DropdownButtonFormField<String>(
            initialValue: _campanhaIdSelecionada,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Campanha vinculada *',
              prefixIcon: Icon(Icons.campaign_outlined),
            ),
            items: campanhas
                .map(
                  (c) => DropdownMenuItem<String>(
                    value: c.id,
                    child: Text(
                      c.nome,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            validator: (val) => (val == null || val.isEmpty)
                ? 'Selecione uma campanha'
                : null,
            onChanged: (val) => setState(() => _campanhaIdSelecionada = val),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nomeController,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            scrollPadding: const EdgeInsets.only(bottom: 100),
            decoration: const InputDecoration(
              labelText: 'Nome da aventura *',
              hintText: 'Ex: O Segredo das Minas',
              prefixIcon: Icon(Icons.auto_stories_outlined),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Informe o nome da aventura';
              }
              return null;
            },
            onFieldSubmitted: (_) => _confirmar(),
          ),
        ],
      ),
    );
  }
}
