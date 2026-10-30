import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../domain/entities/personagem/personagem.dart';
import '../../../domain/repositories/i_personagem_repository.dart';
import '../../controllers/ficha_cubit.dart';
import 'aba_geral_view.dart';
import 'aba_pericias_view.dart';
import 'aba_habilidades_view.dart';
import 'aba_magias_view.dart';
import 'aba_inventario_view.dart';
import 'aba_historia_view.dart';
import 'dialogo_rolagem_dado.dart';
import 'dialogos_ficha.dart';
import '../wizard_personagem/selecao_poderes_screen.dart';

class PainelJogadorScreen extends StatelessWidget {
  final Personagem personagemInicial;
  final IPersonagemRepository? repository;

  const PainelJogadorScreen({
    super.key,
    required this.personagemInicial,
    this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FichaCubit(
        personagemInicial: personagemInicial,
        repository: repository,
      ),
      child: const _PainelJogadorView(),
    );
  }
}

class _PainelJogadorView extends StatefulWidget {
  const _PainelJogadorView();

  @override
  State<_PainelJogadorView> createState() => _PainelJogadorViewState();
}

class _PainelJogadorViewState extends State<_PainelJogadorView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final List<Tab> _abas = const [
    Tab(icon: Icon(Icons.shield_outlined, size: 19), text: 'Geral'),
    Tab(icon: Icon(Icons.fact_check_outlined, size: 19), text: 'Perícias'),
    Tab(icon: Icon(Icons.auto_awesome_outlined, size: 19), text: 'Habilidades'),
    Tab(icon: Icon(Icons.menu_book_outlined, size: 19), text: 'Magias'),
    Tab(icon: Icon(Icons.backpack_outlined, size: 19), text: 'Inventário'),
    Tab(icon: Icon(Icons.edit_note_rounded, size: 20), text: 'Notas'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _abas.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _editarIdentidadeCabecalho(FichaCubit cubit) async {
    final p = cubit.personagem;
    final resumoClasses = p.classes.isNotEmpty
        ? p.classes
              .map((c) => '${c.classeDefinicao.nome} ${c.nivel}')
              .join(' / ')
        : 'Sem Classe';
    await showDialog<void>(
      context: context,
      builder: (_) => _DialogoIdentidadeTopo(
        nomeInicial: p.nome,
        alinhamentoInicial: p.alinhamento,
        idadeInicial: p.idade,
        raca: p.raca?.nome ?? 'Sem Raça',
        origem: p.origem?.nome ?? 'Sem Origem',
        classes: resumoClasses,
        divindade: p.divindade?.nome ?? 'Nenhuma',
        onSalvar: (nome, alinhamento, idade) => cubit
            .atualizarCabecalhoIdentidade(
              nome: nome,
              alinhamento: alinhamento,
              idade: idade,
            ),
      ),
    );
  }

  Future<void> _abrirOpcoesFoto(FichaCubit cubit) async {
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
                  _processarImagem(cubit, ImageSource.gallery);
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
                  _processarImagem(cubit, ImageSource.camera);
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
                    cubit.removerFoto();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processarImagem(FichaCubit cubit, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null && mounted) {
        await cubit.atualizarFoto(pickedFile.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível carregar a imagem: $e')),
        );
      }
    }
  }

  Future<void> _mostrarDialogoAjustePV(FichaCubit cubit) async {
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

    if (ajuste != null && mounted) {
      if (ajuste < 0) {
        cubit.aplicarDano(-ajuste);
      } else if (ajuste > 0) {
        cubit.curarPV(ajuste);
      }
    }
  }

  Future<void> _mostrarDialogoAjustePM(FichaCubit cubit) async {
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

    if (ajuste != null && mounted) {
      if (ajuste < 0) {
        await cubit.tentarAtivarComPM(-ajuste);
      } else if (ajuste > 0) {
        await cubit.recuperarPM(ajuste);
      }
    }
  }

  Widget _buildBannerEvolucaoPendente(FichaCubit cubit) {
    final p = cubit.personagem;
    final cl = p.classes.firstWhere(
      (c) => c.temPoderPendente,
      orElse: () => p.classes.first,
    );
    final pendentes = cl.poderesPendentes;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Material(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final atualizado = await Navigator.push<Personagem>(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    SelecaoPoderesScreen(personagem: p, indiceClasse: 0),
              ),
            );
            if (mounted && atualizado != null) {
              cubit.atualizarPersonagem(atualizado);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.stars_rounded, color: Colors.amber, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Evolução disponível: escolher $pendentes ${pendentes == 1 ? "poder" : "poderes"} em ${cl.classeDefinicao.nome}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.amber),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCabecalhoFixo(BuildContext context, FichaCubit cubit) {
    final p = cubit.personagem;
    final temFoto = p.caminhoFoto != null && p.caminhoFoto!.isNotEmpty;

    final resumoClasses = p.classes.isNotEmpty
        ? p.classes
              .map((c) => '${c.classeDefinicao.nome} ${c.nivel}')
              .join(' / ')
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
                onTap: () => _abrirOpcoesFoto(cubit),
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
                      onTap: () => _editarIdentidadeCabecalho(cubit),
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
                                '${p.alinhamento} • ${p.idade} anos',
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
                        // Stepper compacto de Nível
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () => cubit.alterarNivel(-1),
                                child: const Padding(
                                  padding: EdgeInsets.all(3),
                                  child: Icon(
                                    Icons.remove,
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Text(
                                  'Nív $nivel',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () => cubit.alterarNivel(1),
                                child: const Padding(
                                  padding: EdgeInsets.all(3),
                                  child: Icon(
                                    Icons.add,
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
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
                  child: _buildItemCabecalhoT20(
                    rotulo: 'CLASSE & NÍV',
                    valor: resumoClasses,
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

          const SizedBox(height: 8),

          // Barras de PV e PM
          Row(
            children: [
              Expanded(
                child: _BarraRecursoTopo(
                  rotulo: 'PV ${p.pvAtual}/${p.pvTotal}',
                  progresso: progressoPV,
                  corBarra: progressoPV > 0.3
                      ? const Color(0xFF4ADE80)
                      : Colors.amberAccent,
                  onTapTexto: () => _mostrarDialogoAjustePV(cubit),
                  onMenosUm: () => cubit.aplicarDano(1),
                  onMaisUm: () => cubit.curarPV(1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BarraRecursoTopo(
                  rotulo: 'PM ${p.pmAtual}/${p.pmTotal}',
                  progresso: progressoPM,
                  corBarra: const Color(0xFF38BDF8),
                  onTapTexto: () => _mostrarDialogoAjustePM(cubit),
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
    const t20Red = Color(0xFFC62828);
    final cubit = context.watch<FichaCubit>();
    final p = cubit.state.personagem;

    return Scaffold(
      backgroundColor: t20Red,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Barra Superior enxuta com Nome e Ação de Voltar (Sem dado no topo direito)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Row(
                children: [
                  IconButton(
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => _editarIdentidadeCabecalho(cubit),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                p.nome,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 19,
                                  letterSpacing: 0.3,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.edit_outlined,
                              color: Colors.white70,
                              size: 15,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Cabeçalho de sessão fixo
            _buildCabecalhoFixo(context, cubit),

            // Banner de evolução pendente
            if (p.classes.any((c) => c.temPoderPendente))
              _buildBannerEvolucaoPendente(cubit),

            // Área principal das 6 abas da Ficha
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        indicatorColor: const Color(0xFFD32F2F),
                        indicatorWeight: 3,
                        labelColor: const Color(0xFFD32F2F),
                        unselectedLabelColor: const Color(0xFF64748B),
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                        tabs: _abas,
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: const [
                          AbaGeralView(),
                          AbaPericiasView(),
                          AbaHabilidadesView(),
                          AbaMagiasView(),
                          AbaInventarioView(),
                          AbaHistoriaView(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarraRecursoTopo extends StatelessWidget {
  final String rotulo;
  final double progresso;
  final Color corBarra;
  final VoidCallback onTapTexto;
  final VoidCallback onMenosUm;
  final VoidCallback onMaisUm;

  const _BarraRecursoTopo({
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
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progresso,
            minHeight: 8,
            backgroundColor: Colors.black26,
            valueColor: AlwaysStoppedAnimation<Color>(corBarra),
          ),
        ),
      ],
    );
  }
}

class _DialogoIdentidadeTopo extends StatefulWidget {
  final String nomeInicial;
  final String alinhamentoInicial;
  final int idadeInicial;
  final String raca;
  final String origem;
  final String classes;
  final String divindade;
  final void Function(String nome, String alinhamento, int idade) onSalvar;

  const _DialogoIdentidadeTopo({
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
  State<_DialogoIdentidadeTopo> createState() => _DialogoIdentidadeTopoState();
}

class _DialogoIdentidadeTopoState extends State<_DialogoIdentidadeTopo> {
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
