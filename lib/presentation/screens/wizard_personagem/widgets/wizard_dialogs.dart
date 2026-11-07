import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/services/ficha_services/personagem_storage_service.dart';
import '../../../controllers/ficha_controller/personagem_cubit.dart';

/// Diálogo de confirmação para avançar de etapa no wizard unidirecional.
Future<void> mostrarDialogoConfirmarAvanco(
  BuildContext context, {
  required int etapaAtual,
  required String nomeEtapa,
}) async {
  final theme = Theme.of(context);

  final confirmar = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(
          'Confirmar $nomeEtapa?',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF111827),
          ),
        ),
        content: Text(
          'Ao avançar, suas escolhas nesta etapa serão consolidadas e você não poderá retornar a ela. Deseja continuar?',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF4B5563),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Revisar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB71C1C),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirmar e Avançar'),
          ),
        ],
      );
    },
  );

  if (confirmar == true && context.mounted) {
    context.read<PersonagemCubit>().avancarEtapa();
  }
}

/// Diálogo de confirmação para cancelar a criação e descartar progresso e foto temporária.
Future<void> mostrarDialogoDesistencia(BuildContext context) async {
  final theme = Theme.of(context);

  final confirmar = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(
          'Deseja cancelar a criação de personagem?',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF111827),
          ),
        ),
        content: Text(
          'Todo o progresso deste aventureiro será descartado.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF4B5563),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Continuar Criando'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB71C1C),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Descartar e Sair'),
          ),
        ],
      );
    },
  );

  if (confirmar == true && context.mounted) {
    final cubit = context.read<PersonagemCubit>();
    final p = cubit.state.personagem;
    final idPersonagem = p.id;
    final caminhoFoto = p.caminhoFoto;

    cubit.resetarCriacao();

    if (caminhoFoto != null && caminhoFoto.isNotEmpty) {
      try {
        final f = File(caminhoFoto);
        if (f.existsSync()) {
          f.deleteSync();
        }
      } catch (_) {}
    }
    await PersonagemStorageService.excluirFotoPersonagem(idPersonagem);

    if (context.mounted) {
      Navigator.pop(context);
    }
  }
}
