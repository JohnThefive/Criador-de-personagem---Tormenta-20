import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../domain/entities/personagem/personagem.dart';
import '../../../../domain/services/ficha_services/personagem_storage_service.dart';
import '../../../controllers/ficha_controller/ficha_cubit.dart';
import 'dialogo_rolagem_dado.dart';
import 'dialogos_ficha.dart';
import 'modal_progressao_multiclasse.dart';

/// Exibe o diálogo de edição do cabeçalho de identidade do personagem.
Future<void> mostrarDialogoIdentidade(
  BuildContext context,
  FichaCubit cubit,
) async {
  final p = cubit.personagem;
  final resumoClasses = p.classes.isNotEmpty
      ? p.classes.map((c) => '${c.classeDefinicao.nome} ${c.nivel}').join(' / ')
      : 'Sem Classe';

  await showDialog<void>(
    context: context,
    builder: (_) => DialogoIdentidadeTopo(
      nomeInicial: p.nome,
      alinhamentoInicial: p.alinhamento,
      idadeInicial: p.idade,
      raca: p.raca?.nome ?? 'Sem Raça',
      origem: p.origem?.nome ?? 'Sem Origem',
      classes: resumoClasses,
      divindade: p.divindade?.nome ?? 'Nenhuma',
      onSalvar: (nome, alinhamento, idade) => cubit.atualizarCabecalhoIdentidade(
        nome: nome,
        alinhamento: alinhamento,
        idade: idade,
      ),
    ),
  );
}

/// Cabeçalho fixo da Ficha do Jogador no topo da tela, contendo avatar,
/// identidade, iniciativa, nível, as 4 caixas T20 e as barras de PV/PM.
class FichaCabecalhoWidget extends StatelessWidget {
  final Personagem personagem;

  const FichaCabecalhoWidget({
    super.key,
    required this.personagem,
  });

  Future<void> _abrirOpcoesFoto(BuildContext context, FichaCubit cubit) async {
    final p = cubit.personagem;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Retrato do Personagem',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: Color(0xFFD32F2F),
                ),
                title: const Text('Escolher da Galeria'),
                onTap: () {
                  Navigator.pop(ctx);
                  _processarImagem(context, cubit, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: Color(0xFFD32F2F),
                ),
                title: const Text('Tirar Nova Foto'),
                onTap: () {
                  Navigator.pop(ctx);
                  _processarImagem(context, cubit, ImageSource.camera);
                },
              ),
              if (p.caminhoFoto != null && p.caminhoFoto!.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text(
                    'Remover Foto Atual',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    PersonagemStorageService.excluirFotoPersonagem(
                      cubit.personagem.id,
                    );
                    cubit.removerFoto();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processarImagem(
    BuildContext context,
    FichaCubit cubit,
    ImageSource source,
  ) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null && context.mounted) {
        final id = cubit.personagem.id;
        final caminhoPermanente =
            await PersonagemStorageService.salvarFotoPersonagem(
              id,
              pickedFile.path,
            );
        if (context.mounted) {
          await cubit.atualizarFoto(caminhoPermanente);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível carregar a imagem: $e')),
        );
      }
    }
  }

  Future<void> _mostrarDialogoAjustePV(
    BuildContext context,
    FichaCubit cubit,
  ) async {
    final p = cubit.personagem;
    final ajuste = await showDialog<int>(
      context: context,
      builder: (_) => AjusteRecursoDialog(
        titulo: 'Ajustar Pontos de Vida (PV)',
        labelRecurso: 'Vida Atual',
        valorAtual: p.pvAtual,
        valorTotal: p.pvTotal,
        labelReducao: 'DANO (-)',
        corReducao: Colors.red.shade700,
        labelAumento: 'CURA (+)',
        corAumento: Colors.green.shade700,
      ),
    );

    if (ajuste != null && context.mounted) {
      if (ajuste < 0) {
        cubit.aplicarDano(-ajuste);
      } else if (ajuste > 0) {
        cubit.curarPV(ajuste);
      }
    }
  }

  Future<void> _mostrarDialogoAjustePM(
    BuildContext context,
    FichaCubit cubit,
  ) async {
    final p = cubit.personagem;
    final ajuste = await showDialog<int>(
      context: context,
      builder: (_) => AjusteRecursoDialog(
        titulo: 'Ajustar Pontos de Mana (PM)',
        labelRecurso: 'Mana Atual',
        valorAtual: p.pmAtual,
        valorTotal: p.pmTotal,
        labelReducao: 'GASTAR (-)',
        corReducao: Colors.orange.shade800,
        labelAumento: 'RECUPERAR (+)',
        corAumento: Colors.blue.shade700,
      ),
    );

    if (ajuste != null && context.mounted) {
      if (ajuste < 0) {
        await cubit.tentarAtivarComPM(-ajuste);
      } else if (ajuste > 0) {
        await cubit.recuperarPM(ajuste);
      }
    }
  }

  Widget _buildItemCabecalhoT20({
    required String rotulo,
    required String valor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            rotulo,
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: Colors.white.withValues(alpha: 0.72),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FichaCubit>();
    final p = personagem;
    final temFoto = p.caminhoFoto != null && p.caminhoFoto!.isNotEmpty;

    final resumoClasses = p.classes.isNotEmpty
        ? p.classes.map((c) => '${c.classeDefinicao.nome} ${c.nivel}').join(' / ')
        : 'Sem Classe';
    final racaNome = p.raca?.nome ?? 'Sem Raça';
    final origemNome = p.origem?.nome ?? 'Sem Origem';
    final divindadeNome = p.divindade?.nome ?? 'Nenhuma';
    final nivel = p.nivelPersonagem > 0 ? p.nivelPersonagem : 1;
    final modIniciativa = p.getValorPericia('INICIATIVA');

    final double progressoPV = p.pvTotal > 0
        ? (p.pvAtual / p.pvTotal).clamp(0.0, 1.0)
        : 1.0;
    final double progressoPM = p.pmTotal > 0
        ? (p.pmAtual / p.pmTotal).clamp(0.0, 1.0)
        : 1.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Retrato circular do personagem
              GestureDetector(
                onTap: () => _abrirOpcoesFoto(context, cubit),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: temFoto
                        ? Image.file(
                            File(p.caminhoFoto!),
                            fit: BoxFit.cover,
                            width: 52,
                            height: 52,
                            cacheWidth: 160,
                            cacheHeight: 160,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.account_circle,
                              size: 48,
                              color: Colors.grey,
                            ),
                          )
                        : const Icon(
                            Icons.account_circle,
                            size: 48,
                            color: Colors.grey,
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Alinhamento, Idade, Iniciativa e Nível
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Alinhamento e Idade no topo da tela (clicável para editar)
                    InkWell(
                      key: const Key('topo_alinhamento_idade'),
                      onTap: () => mostrarDialogoIdentidade(context, cubit),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.balance_rounded,
                              size: 13,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '${p.alinhamento} • ${p.idade} anos • ${p.nomePatamar}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.edit_outlined,
                              size: 12,
                              color: Colors.white70,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Gatilho 1 toque de Iniciativa
                        Semantics(
                          button: true,
                          label: 'Rolar Iniciativa',
                          child: Material(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              key: const Key('btn_rolar_iniciativa_topo'),
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => mostrarDialogoRolagemPericia(
                                context,
                                personagem: p,
                                periciaKey: 'INICIATIVA',
                              ),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: 30,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.casino_rounded,
                                        size: 14,
                                        color: Colors.amberAccent,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Iniciativa ${modIniciativa >= 0 ? "+$modIniciativa" : "$modIniciativa"}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Indicador de Nível (toque abre Gerenciador de Multiclasse/Evolução — RF01 / RF10)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: InkWell(
                            key: const Key('btn_gerenciar_multiclasse'),
                            onTap: () =>
                                mostrarModalProgressaoEMulticlasse(context, cubit),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Nív $nivel',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                  if (nivel < 20) ...[
                                    const SizedBox(width: 3),
                                    const Icon(
                                      Icons.add,
                                      size: 13,
                                      color: Colors.white,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 4 Caixas Oficiais da Ficha Tormenta 20: Raça, Origem, Classe & Nível, Divindade
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildItemCabecalhoT20(
                    rotulo: 'RAÇA',
                    valor: racaNome,
                  ),
                ),
                Container(width: 1, height: 26, color: Colors.white24),
                Expanded(
                  child: _buildItemCabecalhoT20(
                    rotulo: 'ORIGEM',
                    valor: origemNome,
                  ),
                ),
                Container(width: 1, height: 26, color: Colors.white24),
                Expanded(
                  child: InkWell(
                    onTap: () => mostrarModalProgressaoEMulticlasse(context, cubit),
                    child: _buildItemCabecalhoT20(
                      rotulo: 'CLASSE & NÍV',
                      valor: resumoClasses,
                    ),
                  ),
                ),
                Container(width: 1, height: 26, color: Colors.white24),
                Expanded(
                  child: _buildItemCabecalhoT20(
                    rotulo: 'DIVINDADE',
                    valor: divindadeNome,
                  ),
                ),
              ],
            ),
          ),

          if (p.dominadoPelaTormenta) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.redAccent),
              ),
              child: const Row(
                children: [
                  Icon(Icons.coronavirus, color: Colors.redAccent, size: 16),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'CAR < -5: Identidade perdida para a Tormenta (NPC sob controle do Mestre)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 8),

          // Barras de PV e PM
          Row(
            children: [
              Expanded(
                child: BarraRecursoTopo(
                  rotulo: 'PV ${p.pvAtual}/${p.pvTotal}',
                  progresso: progressoPV,
                  corBarra: progressoPV > 0.3
                      ? const Color(0xFF4ADE80)
                      : Colors.amberAccent,
                  onTapTexto: () => _mostrarDialogoAjustePV(context, cubit),
                  onMenosUm: () => cubit.aplicarDano(1),
                  onMaisUm: () => cubit.curarPV(1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: BarraRecursoTopo(
                  rotulo: 'PM ${p.pmAtual}/${p.pmTotal}',
                  progresso: progressoPM,
                  corBarra: const Color(0xFF38BDF8),
                  onTapTexto: () => _mostrarDialogoAjustePM(context, cubit),
                  onMenosUm: () => cubit.tentarAtivarComPM(1),
                  onMaisUm: () => cubit.recuperarPM(1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Barra visual de recurso (PV/PM) com indicador de progresso e botões rápidos -1/+1.
class BarraRecursoTopo extends StatelessWidget {
  final String rotulo;
  final double progresso;
  final Color corBarra;
  final VoidCallback onTapTexto;
  final VoidCallback onMenosUm;
  final VoidCallback onMaisUm;

  const BarraRecursoTopo({
    super.key,
    required this.rotulo,
    required this.progresso,
    required this.corBarra,
    required this.onTapTexto,
    required this.onMenosUm,
    required this.onMaisUm,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: InkWell(
                onTap: onTapTexto,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    rotulo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: onMenosUm,
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '-1',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: onMaisUm,
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '+1',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        LinearProgressIndicator(
          value: progresso,
          minHeight: 8,
          borderRadius: BorderRadius.circular(6),
          backgroundColor: Colors.black26,
          valueColor: AlwaysStoppedAnimation<Color>(corBarra),
        ),
      ],
    );
  }
}

/// Diálogo de edição dos dados de identidade do cabeçalho (Nome, Idade e Alinhamento).
class DialogoIdentidadeTopo extends StatefulWidget {
  final String nomeInicial;
  final String alinhamentoInicial;
  final int idadeInicial;
  final String raca;
  final String origem;
  final String classes;
  final String divindade;
  final void Function(String nome, String alinhamento, int idade) onSalvar;

  const DialogoIdentidadeTopo({
    super.key,
    required this.nomeInicial,
    required this.alinhamentoInicial,
    required this.idadeInicial,
    required this.raca,
    required this.origem,
    required this.classes,
    required this.divindade,
    required this.onSalvar,
  });

  @override
  State<DialogoIdentidadeTopo> createState() => _DialogoIdentidadeTopoState();
}

class _DialogoIdentidadeTopoState extends State<DialogoIdentidadeTopo> {
  late final TextEditingController _nomeCtrl;
  late final TextEditingController _alinhamentoCtrl;
  late final TextEditingController _idadeCtrl;

  static const _alinhamentosPadrao = [
    'Leal e Bondoso',
    'Neutro e Bondoso',
    'Caótico e Bondoso',
    'Leal e Neutro',
    'Neutro',
    'Caótico e Neutro',
    'Leal e Maligno',
    'Neutro e Maligno',
    'Caótico e Maligno',
  ];

  @override
  void initState() {
    super.initState();
    _nomeCtrl = TextEditingController(text: widget.nomeInicial);
    _alinhamentoCtrl = TextEditingController(text: widget.alinhamentoInicial);
    _idadeCtrl = TextEditingController(text: '${widget.idadeInicial}');
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _alinhamentoCtrl.dispose();
    _idadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Identidade do Personagem'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.raca} • ${widget.classes}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Origem: ${widget.origem} | Divindade: ${widget.divindade}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            TextField(
              controller: _nomeCtrl,
              decoration: const InputDecoration(
                labelText: 'Nome do Personagem',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _idadeCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Idade (anos)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _alinhamentoCtrl,
              decoration: const InputDecoration(
                labelText: 'Alinhamento',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _alinhamentosPadrao.map((al) {
                return ActionChip(
                  visualDensity: VisualDensity.compact,
                  label: Text(al, style: const TextStyle(fontSize: 11)),
                  onPressed: () => setState(() => _alinhamentoCtrl.text = al),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCELAR'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD32F2F),
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            widget.onSalvar(
              _nomeCtrl.text.trim(),
              _alinhamentoCtrl.text.trim(),
              int.tryParse(_idadeCtrl.text) ?? widget.idadeInicial,
            );
            Navigator.pop(context);
          },
          child: const Text('SALVAR'),
        ),
      ],
    );
  }
}
