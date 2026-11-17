import 'package:flutter/material.dart';
import '../../../widgets/app_safe_scaffold.dart';
import '../../home/widgets/home_action_card.dart';

/// Estrutura base mobile-first para as subtelas de criação do Mestre.
///
/// Mantém os campos roláveis acima do teclado e o botão principal sempre
/// visível e acessível com uma mão na base da tela.
class MestreFormScaffold extends StatelessWidget {
  final String titulo;
  final String? subtituloEtapa;
  final GlobalKey<FormState> formKey;
  final List<Widget> campos;
  final String textoBotaoConfirmar;
  final IconData iconeBotaoConfirmar;
  final VoidCallback onConfirmar;

  const MestreFormScaffold({
    super.key,
    required this.titulo,
    this.subtituloEtapa,
    required this.formKey,
    required this.campos,
    required this.textoBotaoConfirmar,
    this.iconeBotaoConfirmar = Icons.check,
    required this.onConfirmar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        systemOverlayStyle: T20SystemUi.estiloEscuro,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subtituloEtapa != null)
              Text(
                subtituloEtapa!,
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: campos,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: SizedBox(
                    width: double.infinity,
                    child: HomeActionCard(
                      title: textoBotaoConfirmar,
                      icon: iconeBotaoConfirmar,
                      onPressed: onConfirmar,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
