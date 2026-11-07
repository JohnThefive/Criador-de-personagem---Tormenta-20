import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../domain/services/ficha_services/personagem_storage_service.dart';
import '../../../controllers/ficha_controller/personagem_cubit.dart';
import '../../../controllers/home_controller/home_cubit.dart';

class PaginaFinalizacao extends StatefulWidget {
  const PaginaFinalizacao({super.key});

  @override
  State<PaginaFinalizacao> createState() => _PaginaFinalizacaoState();
}

class _PaginaFinalizacaoState extends State<PaginaFinalizacao> {
  final List<String> alinhamentos = const [
    'Leal e Bom',
    'Neutro e Bom',
    'Caótico e Bom',
    'Leal e Neutro',
    'Neutro',
    'Caótico e Neutro',
    'Leal e Mau',
    'Neutro e Mau',
    'Caótico e Mau',
  ];

  late final TextEditingController _nomeCtrl;
  late final TextEditingController _idadeCtrl;
  late final TextEditingController _pesoCtrl;
  late final TextEditingController _alturaCtrl;
  late final TextEditingController _descricaoCtrl;
  Timer? _debounceTimer;
  PersonagemCubit? _cubitRef;

  bool _salvando = false;
  bool _selecionandoFoto = false;
  final ImagePicker _picker = ImagePicker();
  DateTime? _ultimoCliqueFoto;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<PersonagemCubit>();
    _cubitRef = cubit;
    final p = cubit.state.personagem;
    _nomeCtrl = TextEditingController(
      text: p.nome == 'Novo Aventureiro' ? '' : p.nome,
    );
    _idadeCtrl = TextEditingController(text: p.idade.toString());
    _pesoCtrl = TextEditingController(text: p.peso);
    _alturaCtrl = TextEditingController(text: p.altura);
    _descricaoCtrl = TextEditingController(text: p.descricaoAparencia);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    final cubit = _cubitRef;
    if (cubit != null && !cubit.isClosed && cubit.state.etapaAtual == 8) {
      _salvarAlteracoesPendentes(cubit);
    }
    _nomeCtrl.dispose();
    _idadeCtrl.dispose();
    _pesoCtrl.dispose();
    _alturaCtrl.dispose();
    _descricaoCtrl.dispose();
    super.dispose();
  }

  void _salvarAlteracoesPendentes(PersonagemCubit cubit) {
    final p = cubit.state.personagem;
    final nomeTexto = _nomeCtrl.text.trim();
    final novoNome = nomeTexto.isEmpty ? 'Novo Aventureiro' : _nomeCtrl.text;
    if (novoNome != p.nome) {
      cubit.atualizarNome(novoNome);
    }
    final novaIdade = int.tryParse(_idadeCtrl.text) ?? 20;
    if (novaIdade != p.idade) {
      cubit.atualizarIdade(novaIdade);
    }
    final pesoTexto = _pesoCtrl.text.trim();
    final novoPeso = pesoTexto.isEmpty ? '70 kg' : pesoTexto;
    if (novoPeso != p.peso) {
      cubit.atualizarPeso(novoPeso);
    }
    final alturaTexto = _alturaCtrl.text.trim();
    final novoAltura = alturaTexto.isEmpty ? '1.70 m' : alturaTexto;
    if (novoAltura != p.altura) {
      cubit.atualizarAltura(novoAltura);
    }
    if (_descricaoCtrl.text != p.descricaoAparencia) {
      cubit.atualizarDescricao(_descricaoCtrl.text);
    }
  }

  void _agendarAutoSave(VoidCallback acao) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      acao();
    });
  }

  Future<void> _escolherFoto(BuildContext context) async {
    final agora = DateTime.now();
    // Bloqueia qualquer nova tentativa se já houver uma seleção pendente ou clique repetido
    if (_selecionandoFoto ||
        (_ultimoCliqueFoto != null &&
            agora.difference(_ultimoCliqueFoto!) <
                const Duration(milliseconds: 1000))) {
      return;
    }

    _ultimoCliqueFoto = agora;
    setState(() {
      _selecionandoFoto = true;
    });

    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        imageQuality: 85,
      );
      if (pickedFile != null && context.mounted) {
        final id = context.read<PersonagemCubit>().state.personagem.id;
        final caminhoPermanente =
            await PersonagemStorageService.salvarFotoPersonagem(
              id,
              pickedFile.path,
            );
        if (context.mounted) {
          context.read<PersonagemCubit>().atualizarFoto(caminhoPermanente);
        }
      }
    } catch (e) {
      debugPrint('Erro ao selecionar foto da galeria: $e');
    } finally {
      _selecionandoFoto = false;
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PersonagemCubit>();

    return BlocBuilder<PersonagemCubit, PersonagemState>(
      buildWhen: (prev, curr) {
        final p1 = prev.personagem;
        final p2 = curr.personagem;
        return p1.caminhoFoto != p2.caminhoFoto ||
            p1.alinhamento != p2.alinhamento ||
            p1.pvTotal != p2.pvTotal ||
            p1.pmTotal != p2.pmTotal ||
            p1.defesaBase != p2.defesaBase ||
            p1.tamanho != p2.tamanho ||
            p1.tibares != p2.tibares ||
            p1.cargaAtual != p2.cargaAtual ||
            p1.limiteCarga != p2.limiteCarga ||
            p1.armas != p2.armas ||
            p1.itensInventario != p2.itensInventario;
      },
      builder: (context, state) {
        final p = state.personagem;

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // ==========================================
            // CARD 1: DADOS GERAIS, APARÊNCIA E HISTÓRIA
            // ==========================================
            Card(
              color: Colors.white,
              elevation: 1.5,
              shadowColor: Colors.black.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cabeçalho do Card 1
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.person_pin_rounded,
                            color: Color(0xFFB71C1C),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Identidade do Herói",
                                style: TextStyle(
                                  color: Color(0xFF111827),
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "Defina nome, retrato e características essenciais",
                                style: TextStyle(
                                  color: Color(0xFF4B5563),
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Seletor de Avatar / Foto
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.06,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundColor: const Color(0xFFF3F4F6),
                                  child:
                                      (p.caminhoFoto != null &&
                                          p.caminhoFoto!.isNotEmpty)
                                      ? ClipOval(
                                          child: Image.file(
                                            File(p.caminhoFoto!),
                                            width: 100,
                                            height: 100,
                                            cacheWidth: 300,
                                            cacheHeight: 300,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) =>
                                                const Icon(
                                                  Icons.person_outline_rounded,
                                                  size: 52,
                                                  color: Color(0xFF9CA3AF),
                                                ),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.person_outline_rounded,
                                          size: 52,
                                          color: Color(0xFF9CA3AF),
                                        ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: _selecionandoFoto
                                        ? null
                                        : () => _escolherFoto(context),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: _selecionandoFoto
                                            ? const Color(0xFF9E9E9E)
                                            : const Color(0xFFB71C1C),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.2,
                                            ),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: _selecionandoFoto
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
                                              ),
                                            )
                                          : const Icon(
                                              Icons.camera_alt_rounded,
                                              size: 18,
                                              color: Colors.white,
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (p.caminhoFoto != null &&
                              p.caminhoFoto!.isNotEmpty)
                            TextButton.icon(
                              onPressed: _selecionandoFoto
                                  ? null
                                  : () {
                                      PersonagemStorageService.excluirFotoPersonagem(
                                        p.id,
                                      );
                                      cubit.removerFoto();
                                    },
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 16,
                                color: Color(0xFFDC2626),
                              ),
                              label: const Text(
                                "Remover foto",
                                style: TextStyle(
                                  color: Color(0xFFDC2626),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                              ),
                            )
                          else
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                "Toque no ícone da câmera para adicionar uma foto",
                                style: TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 11.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Campo Nome do Herói
                    TextFormField(
                      controller: _nomeCtrl,
                      style: const TextStyle(
                        color: Color(0xFF1F2937),
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Nome do Herói',
                        labelStyle: const TextStyle(color: Color(0xFF4B5563)),
                        hintText: 'Ex: Sir Valen, Katabrok, Lisandra...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        prefixIcon: const Icon(
                          Icons.badge_outlined,
                          color: Color(0xFF6B7280),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFD1D5DB),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFD1D5DB),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFB71C1C),
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (val) => _agendarAutoSave(() {
                        final cubit = context.read<PersonagemCubit>();
                        cubit.atualizarNome(
                          val.trim().isEmpty ? 'Novo Aventureiro' : val,
                        );
                      }),
                    ),
                    const SizedBox(height: 14),

                    // Linha com Idade e Alinhamento
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Idade
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: _idadeCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              color: Color(0xFF1F2937),
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Idade',
                              labelStyle: const TextStyle(
                                color: Color(0xFF4B5563),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              prefixIcon: const Icon(
                                Icons.cake_outlined,
                                color: Color(0xFF6B7280),
                                size: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFD1D5DB),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFD1D5DB),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFB71C1C),
                                  width: 2,
                                ),
                              ),
                            ),
                            onChanged: (val) => _agendarAutoSave(() {
                              final cubit = context.read<PersonagemCubit>();
                              cubit.atualizarIdade(int.tryParse(val) ?? 20);
                            }),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Alinhamento / Tendência
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            initialValue: p.alinhamento,
                            style: const TextStyle(
                              color: Color(0xFF1F2937),
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                            dropdownColor: Colors.white,
                            decoration: InputDecoration(
                              labelText: 'Alinhamento',
                              labelStyle: const TextStyle(
                                color: Color(0xFF4B5563),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              prefixIcon: const Icon(
                                Icons.balance_outlined,
                                color: Color(0xFF6B7280),
                                size: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFD1D5DB),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFD1D5DB),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFB71C1C),
                                  width: 2,
                                ),
                              ),
                            ),
                            items: alinhamentos.map((alin) {
                              return DropdownMenuItem(
                                value: alin,
                                child: Text(alin),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) cubit.atualizarAlinhamento(val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Linha com Peso e Altura
                    Row(
                      children: [
                        // Peso
                        Expanded(
                          child: TextFormField(
                            controller: _pesoCtrl,
                            style: const TextStyle(
                              color: Color(0xFF1F2937),
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Peso',
                              labelStyle: const TextStyle(
                                color: Color(0xFF4B5563),
                              ),
                              hintText: 'Ex: 75 kg',
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              prefixIcon: const Icon(
                                Icons.fitness_center_outlined,
                                color: Color(0xFF6B7280),
                                size: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFD1D5DB),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFD1D5DB),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFB71C1C),
                                  width: 2,
                                ),
                              ),
                            ),
                            onChanged: (val) => _agendarAutoSave(() {
                              final cubit = context.read<PersonagemCubit>();
                              cubit.atualizarPeso(
                                val.trim().isEmpty ? '70 kg' : val.trim(),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Altura
                        Expanded(
                          child: TextFormField(
                            controller: _alturaCtrl,
                            style: const TextStyle(
                              color: Color(0xFF1F2937),
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Altura',
                              labelStyle: const TextStyle(
                                color: Color(0xFF4B5563),
                              ),
                              hintText: 'Ex: 1,75 m',
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              prefixIcon: const Icon(
                                Icons.straighten_outlined,
                                color: Color(0xFF6B7280),
                                size: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFD1D5DB),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFD1D5DB),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFB71C1C),
                                  width: 2,
                                ),
                              ),
                            ),
                            onChanged: (val) => _agendarAutoSave(() {
                              final cubit = context.read<PersonagemCubit>();
                              cubit.atualizarAltura(
                                val.trim().isEmpty ? '1.70 m' : val.trim(),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Descrição Física e Personalidade
                    TextFormField(
                      controller: _descricaoCtrl,
                      maxLines: 3,
                      style: const TextStyle(
                        color: Color(0xFF1F2937),
                        height: 1.35,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Descrição Física e Personalidade',
                        labelStyle: const TextStyle(color: Color(0xFF4B5563)),
                        hintText:
                            'Descreva a aparência, cicatrizes, trejeitos ou histórico marcante...',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFD1D5DB),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFD1D5DB),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFB71C1C),
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (val) => _agendarAutoSave(() {
                        final cubit = context.read<PersonagemCubit>();
                        cubit.atualizarDescricao(val);
                      }),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ==========================================
            // CARD 2: ESTATÍSTICAS DE COMBATE
            // ==========================================
            Card(
              color: Colors.white,
              elevation: 1.5,
              shadowColor: Colors.black.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cabeçalho do Card 2
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.shield_rounded,
                            color: Color(0xFFB71C1C),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Estatísticas de Combate",
                                style: TextStyle(
                                  color: Color(0xFF111827),
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "Valores calculados com base na sua classe e atributos",
                                style: TextStyle(
                                  color: Color(0xFF4B5563),
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Grid 2x2 de Estatísticas
                    Row(
                      children: [
                        // PV Total
                        Expanded(
                          child: _buildCombatStatItem(
                            icon: Icons.favorite_rounded,
                            label: "Pontos de Vida",
                            sigla: "PV TOTAL",
                            valor: "${p.pvTotal}",
                            detalhe: "Inicial + CON",
                            fundoCor: const Color(0xFFFEF2F2),
                            bordaCor: const Color(0xFFFECACA),
                            iconeCor: const Color(0xFFDC2626),
                            textoCor: const Color(0xFF991B1B),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // PM Total
                        Expanded(
                          child: _buildCombatStatItem(
                            icon: Icons.auto_awesome_rounded,
                            label: "Pontos de Mana",
                            sigla: "PM TOTAL",
                            valor: "${p.pmTotal}",
                            detalhe: "Inicial + Atributo",
                            fundoCor: const Color(0xFFEFF6FF),
                            bordaCor: const Color(0xFFBFDBFE),
                            iconeCor: const Color(0xFF2563EB),
                            textoCor: const Color(0xFF1D4ED8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Defesa Base
                        Expanded(
                          child: _buildCombatStatItem(
                            icon: Icons.security_rounded,
                            label: "Defesa Base",
                            sigla: "DEFESA",
                            valor: "${p.defesaBase}",
                            detalhe: "10 + Destreza",
                            fundoCor: const Color(0xFFF0FDF4),
                            bordaCor: const Color(0xFFBBF7D0),
                            iconeCor: const Color(0xFF16A34A),
                            textoCor: const Color(0xFF15803D),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Tamanho / Porte
                        Expanded(
                          child: _buildCombatStatItem(
                            icon: Icons.accessibility_new_rounded,
                            label: "Porte Corporal",
                            sigla: "TAMANHO",
                            valor: p.tamanho,
                            detalhe: p.raca?.nome ?? "Padrão",
                            fundoCor: const Color(0xFFFAF5FF),
                            bordaCor: const Color(0xFFE9D5FF),
                            iconeCor: const Color(0xFF9333EA),
                            textoCor: const Color(0xFF7E22CE),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: Colors.white,
              elevation: 1.5,
              shadowColor: Colors.black.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cabeçalho do Card 3
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.colorize_rounded,
                            color: Color(0xFFD97706),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Equipamento & Riqueza",
                                style: TextStyle(
                                  color: Color(0xFF111827),
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "Armas, itens iniciais e tibares do aventureiro",
                                style: TextStyle(
                                  color: Color(0xFF4B5563),
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Resumo de Dinheiro e Carga
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFFDE68A),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.monetization_on_rounded,
                                  color: Color(0xFFD97706),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "TIBARES",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF92400E),
                                      ),
                                    ),
                                    Text(
                                      "T\$ ${p.tibares}",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFB45309),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFBBF7D0),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.inventory_2_outlined,
                                  color: Color(0xFF16A34A),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "CARGA",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF166534),
                                      ),
                                    ),
                                    Text(
                                      "${p.cargaAtual}/${p.limiteCarga} esp.",
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF15803D),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Lista de Armas Escolhidas
                    const Text(
                      "Armas Equipadas:",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (p.armas.isEmpty)
                      const Text(
                        "Nenhuma arma cadastrada.",
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      )
                    else
                      ...p.armas.map((arma) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.colorize_rounded,
                                size: 16,
                                color: Color(0xFFB71C1C),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  arma.nome,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                              ),
                              Text(
                                "${arma.dano} (${arma.criticoFormatado})",
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFB71C1C),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  arma.tipoDano.label,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: Color(0xFF4B5563),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ==========================================
            // BOTÃO CTA: CONCLUIR E SALVAR FICHA
            // ==========================================
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(
                    0xFFB71C1C,
                  ), // Vermelho T20 Carmesim
                  foregroundColor: Colors.white,
                  elevation: 2.5,
                  shadowColor: const Color(0xFFB71C1C).withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: _salvando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 24,
                        color: Colors.white,
                      ),
                label: Text(
                  _salvando ? "SALVANDO FICHA..." : "CONCLUIR E SALVAR FICHA",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                onPressed: _salvando
                    ? null
                    : () async {
                        setState(() => _salvando = true);
                        try {
                          _debounceTimer?.cancel();
                          _salvarAlteracoesPendentes(cubit);

                          // Salva localmente no disco do celular
                          await cubit.salvarPersonagemNoAparelho();

                          if (context.mounted) {
                            // Atualiza a lista da tela inicial
                            context
                                .read<HomeCubit>()
                                .carregarPersonagensReais();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: const Color(0xFF1F2937),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                content: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: Color(0xFF4ADE80),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Personagem "${cubit.state.personagem.nome}" salvo com sucesso!',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );

                            // Limpa o wizard e fecha
                            cubit.resetarCriacao();
                            Navigator.pop(context);
                          }
                        } finally {
                          if (mounted) setState(() => _salvando = false);
                        }
                      },
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _buildCombatStatItem({
    required IconData icon,
    required String label,
    required String sigla,
    required String valor,
    required String detalhe,
    required Color fundoCor,
    required Color bordaCor,
    required Color iconeCor,
    required Color textoCor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: fundoCor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bordaCor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconeCor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  sigla,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: textoCor,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            valor,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textoCor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            detalhe,
            style: TextStyle(
              fontSize: 11,
              color: textoCor.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
