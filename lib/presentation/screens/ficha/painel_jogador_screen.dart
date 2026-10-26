import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../domain/entities/personagem/personagem.dart';
import '../../controllers/ficha_cubit.dart';
import 'comabte/aba_combate_view.dart';
import 'aba_geral_view.dart';
import 'aba_habilidades_view.dart';
import 'aba_historia_view.dart';
import 'aba_inventario_view.dart';
import 'aba_magias_view.dart';
import 'dialogo_rolagem_dado.dart';
import 'dialogos_ficha.dart';
import '../wizard_personagem/selecao_poderes_screen.dart';

class PainelJogadorScreen extends StatelessWidget {
  final Personagem personagemInicial;

  const PainelJogadorScreen({super.key, required this.personagemInicial});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FichaCubit(personagemInicial: personagemInicial),
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
    Tab(icon: Icon(Icons.dashboard_outlined, size: 20), text: 'Geral'),
    Tab(icon: Icon(Icons.sports_kabaddi_rounded, size: 20), text: 'Combate'),
    Tab(icon: Icon(Icons.auto_awesome_outlined, size: 20), text: 'Habilidades'),
    Tab(icon: Icon(Icons.menu_book_outlined, size: 20), text: 'Magias'),
    Tab(icon: Icon(Icons.backpack_outlined, size: 20), text: 'Inventário'),
    Tab(icon: Icon(Icons.history_edu_outlined, size: 20), text: 'História'),
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

  void _abrirRoladorGeral() {
    final dados = [4, 6, 8, 10, 12, 20, 100];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Rolador de Dados (T20)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: dados.map((d) {
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: d == 20
                          ? const Color(0xFFD32F2F)
                          : Colors.grey.shade900,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: d == 20 ? Colors.redAccent : Colors.white24,
                        ),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      mostrarDialogoRolagemDado(
                        context,
                        lados: d,
                        mod: 0,
                        rotulo: 'Rolagem d$d',
                      );
                    },
                    child: Text(
                      'd$d',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _abrirOpcoesFoto(FichaCubit cubit) async {
    final p = cubit.personagem;
    showModalBottomSheet(
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto do herói atualizada com sucesso!'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Não foi possível carregar a imagem: $e'),
            backgroundColor: Colors.black87,
          ),
        );
      }
    }
  }

  Future<void> _mostrarDialogoAjustePV(FichaCubit cubit) async {
    final p = cubit.personagem;
    final ajuste = await showDialog<int>(
      context: context,
      builder: (ctx) => AjusteRecursoDialog(
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
      builder: (ctx) => AjusteRecursoDialog(
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
      if (p.punicaoDivinaAtiva && ajuste > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'O personagem está sob Punição Divina e não pode recuperar Pontos de Mana!',
            ),
            backgroundColor: Color(0xFFB71C1C),
          ),
        );
        return;
      }
      if (ajuste < 0) {
        cubit.gastarPM(-ajuste);
      } else if (ajuste > 0) {
        cubit.recuperarPM(ajuste);
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(12),
        elevation: 3,
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.stars_rounded, color: Colors.amber, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Evolução Disponível!',
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Você pode escolher $pendentes ${pendentes == 1 ? "poder" : "poderes"} em ${cl.classeDefinicao.nome}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Escolher',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
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

    final classeNome = p.classes.isNotEmpty
        ? p.classes[0].classeDefinicao.nome
        : 'Sem Classe';
    final racaNome = p.raca?.nome ?? 'Sem Raça';
    final nivel = p.nivelPersonagem > 0 ? p.nivelPersonagem : 1;
    final modIniciativa = p.getValorPericia('INICIATIVA');
    final bonusTreino = p.bonusTreinamento;

    final double progressoPV = p.pvTotal > 0
        ? (p.pvAtual / p.pvTotal).clamp(0.0, 1.0)
        : 1.0;
    final double progressoPM = p.pmTotal > 0
        ? (p.pmAtual / p.pmTotal).clamp(0.0, 1.0)
        : 1.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar com edição segura
              Stack(
                children: [
                  GestureDetector(
                    onTap: () => _abrirOpcoesFoto(cubit),
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 4),
                        ],
                      ),
                      child: ClipOval(
                        child: temFoto
                            ? Image.file(
                                File(p.caminhoFoto!),
                                fit: BoxFit.cover,
                                width: 68,
                                height: 68,
                                cacheWidth: 200,
                                cacheHeight: 200,
                                errorBuilder: (ctx, err, stack) => const Icon(
                                  Icons.account_circle,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                              )
                            : const Icon(
                                Icons.account_circle,
                                size: 64,
                                color: Colors.grey,
                              ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: () => _abrirOpcoesFoto(cubit),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black38, blurRadius: 3),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 13,
                          color: Color(0xFFD32F2F),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),

              // Identidade e Estatísticas Principais
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Nível: ',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            InkWell(
                              onTap: () => cubit.alterarNivel(-1),
                              child: const Icon(
                                Icons.arrow_drop_down,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            Text(
                              '$nivel',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            InkWell(
                              onTap: () => cubit.alterarNivel(1),
                              child: const Icon(
                                Icons.arrow_drop_up,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ],
                        ),
                        Flexible(
                          child: Text(
                            'PV Máx: ${p.pvTotal}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Def: ${p.defesaBase}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$racaNome • $classeNome',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        InkWell(
                          onTap: () => mostrarDialogoRolagemDado(
                            context,
                            lados: 20,
                            mod: modIniciativa,
                            rotulo: 'Iniciativa',
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.casino,
                                  size: 14,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Iniciativa ${modIniciativa >= 0 ? "+$modIniciativa" : "$modIniciativa"}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.shield,
                                size: 14,
                                color: Colors.lightBlueAccent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Treino +$bonusTreino',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
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

          const SizedBox(height: 10),

          // Barras de PV e PM
          Row(
            children: [
              // Barra de Vida (PV)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: GestureDetector(
                            onTap: () => _mostrarDialogoAjustePV(cubit),
                            child: Text(
                              'PV ${p.pvAtual}/${p.pvTotal}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () => cubit.aplicarDano(1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black38,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: const Text(
                                  '-1',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 3),
                            InkWell(
                              onTap: () => cubit.curarPV(1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black38,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: const Text(
                                  '+1',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progressoPV,
                        minHeight: 8,
                        backgroundColor: Colors.black26,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progressoPV > 0.3
                              ? const Color(0xFF4CAF50)
                              : Colors.amberAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 14),

              // Barra de Mana (PM)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: GestureDetector(
                            onTap: () => _mostrarDialogoAjustePM(cubit),
                            child: Text(
                              'PM ${p.pmAtual}/${p.pmTotal}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () => cubit.gastarPM(1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black38,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: const Text(
                                  '-1',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 3),
                            InkWell(
                              onTap: () => cubit.recuperarPM(1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black38,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: const Text(
                                  '+1',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progressoPM,
                        minHeight: 8,
                        backgroundColor: Colors.black26,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF29B6F6),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    const t20Red = Color.fromARGB(255, 220, 20, 20);
    final cubit = context.watch<FichaCubit>();
    final p = cubit.state.personagem;

    return Scaffold(
      backgroundColor: t20Red,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      p.nome,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.casino_outlined,
                      color: Colors.white,
                    ),
                    tooltip: 'Rolador de Dados',
                    onPressed: _abrirRoladorGeral,
                  ),
                ],
              ),
            ),

            // Cabeçalho fixo no topo
            _buildCabecalhoFixo(context, cubit),

            // Banner de evolução pendente
            if (p.classes.any((c) => c.temPoderPendente))
              _buildBannerEvolucaoPendente(cubit),

            // Abas deslizando
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                ),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(26),
                        ),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        tabAlignment: TabAlignment.center,
                        indicatorColor: const Color(0xFFD32F2F),
                        indicatorWeight: 3,
                        labelColor: const Color(0xFFD32F2F),
                        unselectedLabelColor: Colors.black54,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        tabs: _abas,
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          const AbaGeralView(),
                          AbaCombateView(
                            personagem: p,
                            onPersonagemAtualizado: (novo) =>
                                cubit.atualizarPersonagem(novo),
                          ),
                          const AbaHabilidadesView(),
                          const AbaMagiasView(),
                          const AbaInventarioView(),
                          const AbaHistoriaView(),
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
      bottomNavigationBar: BottomAppBar(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        shape: const CircularNotchedRectangle(),
        color: Colors.black,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              tooltip: 'Configurações',
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.person, color: Colors.white),
              tooltip: 'Perfil',
              onPressed: () => _tabController.animateTo(0),
            ),
            const SizedBox(width: 44),
            IconButton(
              icon: const Icon(Icons.history_edu, color: Colors.white),
              tooltip: 'História / Notas',
              onPressed: () => _tabController.animateTo(5),
            ),
            IconButton(
              icon: const Icon(Icons.backpack, color: Colors.white),
              tooltip: 'Inventário',
              onPressed: () => _tabController.animateTo(4),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: _abrirRoladorGeral,
        child: const Icon(Icons.casino, color: Color(0xFFD32F2F), size: 30),
      ),
    );
  }
}
