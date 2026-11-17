import 'package:flutter/material.dart';
import '../../controllers/mestre_controller/mestre_cubit.dart';
import 'criar_aventura_screen.dart';
import 'theme/mestre_theme.dart';
import 'widgets/mestre_form_scaffold.dart';

/// Subtela de criação de Campanha com nome obrigatório e código LAN opcional.
class CriarCampanhaScreen extends StatefulWidget {
  final MestreCubit cubit;

  const CriarCampanhaScreen({
    super.key,
    required this.cubit,
  });

  @override
  State<CriarCampanhaScreen> createState() => _CriarCampanhaScreenState();
}

class _CriarCampanhaScreenState extends State<CriarCampanhaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _codigoLanController = TextEditingController();

  @override
  void dispose() {
    _nomeController.dispose();
    _codigoLanController.dispose();
    super.dispose();
  }

  void _gerarCodigoLan() {
    _codigoLanController.text = widget.cubit.gerarCodigoLanSugerido();
  }

  Future<void> _confirmar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final campanha = widget.cubit.criarCampanha(
      nome: _nomeController.text.trim(),
      codigoConexaoLan: _codigoLanController.text.trim(),
      criarEstruturaPadrao: false,
    );

    if (!mounted) return;

    // Aguarda o fechamento completo do diálogo antes de navegar com o
    // contexto válido desta tela pai, evitando uso de contexto descartado.
    final querCriarAventura = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Campanha criada'),
        content: Text(
          'A campanha "${campanha.nome}" foi criada. Deseja criar a primeira aventura agora?',
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
            child: const Text('Criar aventura'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (querCriarAventura == true) {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<String?>(
          builder: (_) => CriarAventuraScreen(
            cubit: widget.cubit,
            campanhaIdInicial: campanha.id,
            emFluxoGuiado: true,
          ),
        ),
      );
      return;
    }

    Navigator.of(context).pop(campanha.id);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: MestreCores.homeStyleTheme,
      child: MestreFormScaffold(
        titulo: 'Nova Campanha',
        subtituloEtapa: 'Etapa 1 de 3 • Campanha',
        formKey: _formKey,
        textoBotaoConfirmar: 'Criar campanha',
        onConfirmar: _confirmar,
        campos: [
          TextFormField(
            controller: _nomeController,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            scrollPadding: const EdgeInsets.only(bottom: 100),
            decoration: const InputDecoration(
              labelText: 'Nome da campanha *',
              hintText: 'Ex: Coração de Rubi',
              prefixIcon: Icon(Icons.campaign_outlined),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Informe o nome da campanha';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _codigoLanController,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.done,
            scrollPadding: const EdgeInsets.only(bottom: 100),
            decoration: InputDecoration(
              labelText: 'Código de conexão LAN (opcional)',
              hintText: 'Ex: T20-4829',
              helperText:
                  'Para jogadores na mesma rede Wi-Fi ou Hotspot em etapas futuras.',
              helperMaxLines: 2,
              prefixIcon: const Icon(Icons.wifi_tethering),
              suffixIcon: IconButton(
                icon: const Icon(Icons.casino_outlined),
                tooltip: 'Gerar código LAN',
                constraints: const BoxConstraints(
                  minWidth: 48,
                  minHeight: 48,
                ),
                onPressed: _gerarCodigoLan,
              ),
            ),
            validator: (val) {
              final texto = val?.trim() ?? '';
              if (texto.isEmpty) return null;
              if (texto.contains(' ')) {
                return 'O código LAN não pode conter espaços';
              }
              if (texto.length < 4) {
                return 'Use ao menos 4 caracteres ou deixe em branco';
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
