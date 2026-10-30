import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../controllers/ficha_cubit.dart';
import '../../controllers/ficha_state.dart';
import 'dialogos_ficha.dart';

class AbaHistoriaView extends StatefulWidget {
  const AbaHistoriaView({super.key});

  @override
  State<AbaHistoriaView> createState() => _AbaHistoriaViewState();
}

class _AbaHistoriaViewState extends State<AbaHistoriaView> {
  late final TextEditingController _notasCtrl;
  late final TextEditingController _bioCtrl;
  Timer? _debounceTimer;
  FichaCubit? _cubitRef;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<FichaCubit>();
    _cubitRef = cubit;
    _notasCtrl = TextEditingController(text: cubit.personagem.anotacoes);
    _bioCtrl = TextEditingController(text: cubit.personagem.descricaoAparencia);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    // Garante persistência imediata ao sair da aba/tela sem botão salvar
    final cubit = _cubitRef;
    if (cubit != null && !cubit.isClosed) {
      if (_notasCtrl.text != cubit.personagem.anotacoes) {
        cubit.atualizarAnotacoes(_notasCtrl.text);
      }
      if (_bioCtrl.text != cubit.personagem.descricaoAparencia) {
        cubit.atualizarBiografiaFisica(descricaoAparencia: _bioCtrl.text);
      }
    }
    _notasCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  void _agendarAutoSaveNotas(String valor) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      context.read<FichaCubit>().atualizarAnotacoes(valor);
    });
  }

  void _agendarAutoSaveBio(String valor) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      context.read<FichaCubit>().atualizarBiografiaFisica(
        descricaoAparencia: valor,
      );
    });
  }

  Future<void> _editarCampoFisico(
    BuildContext context,
    FichaCubit cubit, {
    required String titulo,
    required String valorAtual,
    required ValueChanged<String> onSalvar,
  }) async {
    final res = await showDialog<String>(
      context: context,
      builder: (_) => CampoTextoDialog(
        titulo: titulo,
        valorInicial: valorAtual,
        textoBotaoConfirmar: 'SALVAR',
      ),
    );
    if (res != null) {
      onSalvar(res);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FichaCubit, FichaState>(
      builder: (context, state) {
        final cubit = context.read<FichaCubit>();
        final p = state.personagem;

        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
          children: [
            // 1. ANOTAÇÕES LIVRES DE SESSÃO (AUTO-SAVE)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.edit_note_rounded,
                            color: Color(0xFFD32F2F),
                            size: 22,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Anotações da Campanha',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Salvo automaticamente',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF16A34A),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    key: const Key('campo_anotacoes_livres'),
                    controller: _notasCtrl,
                    minLines: 7,
                    maxLines: 14,
                    onChanged: _agendarAutoSaveNotas,
                    style: const TextStyle(fontSize: 13.5, height: 1.45),
                    decoration: InputDecoration(
                      hintText:
                          'Escreva pistas, NPCs importantes, missões, dívidas, itens prometidos ou lembretes de sessão...',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 2. CARACTERÍSTICAS FÍSICAS E BIOGRAFIA
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Características Físicas & Biografia',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _ChipDadoFisico(
                          rotulo: 'Tamanho',
                          valor: p.tamanho,
                          onTap: () => _editarCampoFisico(
                            context,
                            cubit,
                            titulo: 'Tamanho',
                            valorAtual: p.tamanho,
                            onSalvar: (v) =>
                                cubit.atualizarBiografiaFisica(tamanho: v),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ChipDadoFisico(
                          rotulo: 'Altura',
                          valor: p.altura,
                          onTap: () => _editarCampoFisico(
                            context,
                            cubit,
                            titulo: 'Altura',
                            valorAtual: p.altura,
                            onSalvar: (v) =>
                                cubit.atualizarBiografiaFisica(altura: v),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ChipDadoFisico(
                          rotulo: 'Peso',
                          valor: p.peso,
                          onTap: () => _editarCampoFisico(
                            context,
                            cubit,
                            titulo: 'Peso',
                            valorAtual: p.peso,
                            onSalvar: (v) =>
                                cubit.atualizarBiografiaFisica(peso: v),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Aparência & História:',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _bioCtrl,
                    minLines: 4,
                    maxLines: 8,
                    onChanged: _agendarAutoSaveBio,
                    style: const TextStyle(fontSize: 13.5, height: 1.4),
                    decoration: InputDecoration(
                      hintText:
                          'Descreva a aparência, cicatrizes, personalidade e passado do aventureiro...',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ChipDadoFisico extends StatelessWidget {
  final String rotulo;
  final String valor;
  final VoidCallback onTap;

  const _ChipDadoFisico({
    required this.rotulo,
    required this.valor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Text(
                rotulo,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                valor,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
