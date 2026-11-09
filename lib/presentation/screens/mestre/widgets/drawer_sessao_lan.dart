import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../domain/entities/mestre/modelos_mestre.dart';
import '../../../controllers/mestre_controller/mestre_cubit.dart';
import '../../../controllers/mestre_controller/mestre_state.dart';
import '../theme/mestre_theme.dart';

/// PARTE 1 — Gaveta "Sessão e LAN" (Tormenta 20 - Android/Flutter)
/// Modal Navigation Drawer (~85% no celular, painel de 320 dp no tablet).
/// Árvore em acordeão com linha guia fina, nós com menu ⋮, rodapé fixo e sheets da LAN.
class DrawerSessaoLan extends StatelessWidget {
  final MestreState state;
  final MestreCubit cubit;
  final VoidCallback? onFechar;

  const DrawerSessaoLan({
    super.key,
    required this.state,
    required this.cubit,
    this.onFechar,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: MestreCores.escuroSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildCabecalho(context),
            const Divider(color: MestreCores.escuroOutline, height: 1),
            Expanded(
              child: state.campanhas.isEmpty
                  ? _buildEstadoVazio(context)
                  : _buildArvoreCampanhas(context),
            ),
            const Divider(color: MestreCores.escuroOutline, height: 1),
            _buildRodapeNovaCampanha(context),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CABEÇALHO & NOTIFICAÇÃO PERSISTENTE DA MESA
  // ---------------------------------------------------------------------------

  Widget _buildCabecalho(BuildContext context) {
    final salaAberta = state.statusLan != StatusConexaoLan.desligado;
    final conectados = state.sessaoAtual?.elenco.where((e) => e.conectadoViaLan).length ?? 0;
    final total = state.sessaoAtual?.elenco.length ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.hub_outlined, color: MestreCores.escuroOuro, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Sessão & LAN',
                    style: TextStyle(
                      fontFamily: 'serif',
                      color: MestreCores.escuroOnSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (onFechar != null)
                IconButton(
                  icon: const Icon(Icons.close, color: MestreCores.escuroOnSurfaceVariant, size: 20),
                  onPressed: onFechar,
                  tooltip: 'Fechar Gaveta',
                ),
            ],
          ),

          // Simulação da Notificação Persistente da Mesa
          if (salaAberta) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: MestreCores.escuroVinho.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: MestreCores.escuroVinho),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active, color: MestreCores.escuroOuro, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mesa ${state.campanhaAtual?.nome ?? "T20"}: $conectados/$total conectados',
                      style: const TextStyle(
                        color: MestreCores.escuroOnSurface,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: () => cubit.alternarServidorLan(),
                    style: TextButton.styleFrom(
                      foregroundColor: MestreCores.statusAlertaEscuro,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                    child: const Text('Encerrar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ÁRVORE DE ACORDEÃO (CAMPANHA -> AVENTURA -> SESSÃO -> SALA LAN)
  // ---------------------------------------------------------------------------

  Widget _buildArvoreCampanhas(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.campanhas.length,
      itemBuilder: (context, index) {
        final campanha = state.campanhas[index];
        final ehAtiva = campanha.id == state.campanhaAtual?.id;

        return Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: PageStorageKey('camp_${campanha.id}'),
            initiallyExpanded: ehAtiva,
            tilePadding: const EdgeInsets.symmetric(horizontal: 14),
            leading: Icon(
              Icons.shield_outlined,
              size: 20,
              color: ehAtiva ? MestreCores.escuroOuro : MestreCores.escuroOnSurfaceVariant,
            ),
            title: Text(
              campanha.nome,
              style: TextStyle(
                fontFamily: 'serif',
                color: ehAtiva ? MestreCores.escuroOnSurface : MestreCores.escuroOnSurfaceVariant,
                fontWeight: ehAtiva ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.add, size: 18, color: MestreCores.escuroOuro),
                  tooltip: 'Adicionar Aventura',
                  onPressed: () => _exibirDialogCriarItem(
                    context,
                    titulo: 'Nova Aventura',
                    onCriar: (nome, desc) {
                      cubit.selecionarCampanha(campanha.id);
                      cubit.criarAventura(nome: nome, sinopse: desc);
                      _exibirSnackCriarSessao(context);
                    },
                  ),
                ),
                _buildMenuOpcoesNo(
                  context,
                  titulo: 'Campanha: ${campanha.nome}',
                  onRenomear: () => _exibirDialogRenomear(context, 'Campanha', campanha.nome, (novo) {
                    cubit.renomearCampanha(campanha.id, novo);
                  }),
                  onDuplicar: () => cubit.duplicarCampanha(campanha.id),
                  onExcluir: () => cubit.excluirCampanha(campanha.id),
                ),
              ],
            ),
            children: [
              ...campanha.aventuras.map((av) => _buildNoAventura(context, campanha, av)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoAventura(BuildContext context, CampanhaMestre campanha, AventuraMestre aventura) {
    final ehAtiva = aventura.id == state.aventuraAtual?.id && campanha.id == state.campanhaAtual?.id;

    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: MestreCores.escuroOutline, width: 1.5)),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: PageStorageKey('av_${aventura.id}'),
            initiallyExpanded: ehAtiva,
            tilePadding: const EdgeInsets.symmetric(horizontal: 12),
            leading: Icon(
              Icons.auto_stories_outlined,
              size: 18,
              color: ehAtiva ? MestreCores.escuroOuro : MestreCores.escuroOnSurfaceVariant,
            ),
            title: Text(
              aventura.nome,
              style: TextStyle(
                color: ehAtiva ? MestreCores.escuroOnSurface : MestreCores.escuroOnSurfaceVariant,
                fontWeight: ehAtiva ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.add, size: 16, color: MestreCores.escuroOuro),
                  tooltip: 'Adicionar Sessão',
                  onPressed: () => _exibirDialogCriarItem(
                    context,
                    titulo: 'Nova Sessão',
                    onCriar: (nome, desc) {
                      cubit.selecionarCampanha(campanha.id);
                      cubit.selecionarAventura(aventura.id);
                      cubit.criarSessao(titulo: nome, objetivoResumo: desc);
                    },
                  ),
                ),
                _buildMenuOpcoesNo(
                  context,
                  titulo: 'Aventura: ${aventura.nome}',
                  onRenomear: () => _exibirDialogRenomear(context, 'Aventura', aventura.nome, (novo) {
                    cubit.renomearAventura(aventura.id, novo);
                  }),
                  onDuplicar: () => cubit.duplicarAventura(aventura.id),
                  onExcluir: () => cubit.excluirAventura(aventura.id),
                ),
              ],
            ),
            children: [
              ...aventura.sessoes.map((ses) => _buildNoSessao(context, campanha, aventura, ses)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoSessao(
    BuildContext context,
    CampanhaMestre campanha,
    AventuraMestre aventura,
    SessaoJogo sessao,
  ) {
    final ehAtiva = sessao.id == state.sessaoAtual?.id && aventura.id == state.aventuraAtual?.id;

    Color corStatus;
    switch (sessao.statusSessao) {
      case StatusSessao.emAndamento:
        corStatus = MestreCores.statusOnlineEscuro;
        break;
      case StatusSessao.planejada:
        corStatus = MestreCores.escuroOuro;
        break;
      case StatusSessao.encerrada:
        corStatus = MestreCores.statusOffline;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 8, bottom: 4),
      child: Container(
        decoration: BoxDecoration(
          color: ehAtiva ? MestreCores.escuroSurfaceContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(
              color: ehAtiva ? MestreCores.escuroOuro : MestreCores.escuroOutline,
              width: ehAtiva ? 3.0 : 1.5,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              title: Text(
                sessao.titulo,
                style: TextStyle(
                  color: ehAtiva ? MestreCores.escuroOnSurface : MestreCores.escuroOnSurfaceVariant,
                  fontWeight: ehAtiva ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              subtitle: Row(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: corStatus.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: corStatus.withValues(alpha: 0.6), width: 0.8),
                    ),
                    child: Text(
                      sessao.statusSessao.rotulo,
                      style: TextStyle(color: corStatus, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              trailing: _buildMenuOpcoesNo(
                context,
                titulo: 'Sessão: ${sessao.titulo}',
                onRenomear: () => _exibirDialogRenomear(context, 'Sessão', sessao.titulo, (novo) {
                  cubit.renomearSessao(sessao.id, novo);
                }),
                onDuplicar: () => cubit.duplicarSessao(sessao.id),
                onExcluir: () => cubit.excluirSessao(sessao.id),
              ),
              onTap: () {
                cubit.selecionarCampanha(campanha.id);
                cubit.selecionarAventura(aventura.id);
                cubit.selecionarSessao(sessao.id);
              },
            ),

            // NÓ FILHO: SALA LAN
            if (ehAtiva) _buildNoFilhoSalaLan(context, sessao),
          ],
        ),
      ),
    );
  }

  Widget _buildNoFilhoSalaLan(BuildContext context, SessaoJogo sessao) {
    final salaAberta = state.statusLan != StatusConexaoLan.desligado;
    final conectados = sessao.elenco.where((e) => e.conectadoViaLan).length;
    final total = sessao.elenco.length;
    final corPonto = salaAberta ? MestreCores.statusOnlineEscuro : MestreCores.statusOffline;

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: MestreCores.escuroSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: MestreCores.escuroOutline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.circle, size: 8, color: corPonto),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  salaAberta ? 'Sala aberta · $conectados/$total' : 'Sala fechada (offline)',
                  style: TextStyle(
                    color: salaAberta ? MestreCores.escuroOnSurface : MestreCores.escuroOnSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Botão Contextual [Abrir sala] / [Encerrar sala]
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: salaAberta ? MestreCores.statusAlertaEscuro : MestreCores.escuroOuro,
                  side: BorderSide(
                    color: salaAberta ? MestreCores.statusAlertaEscuro : MestreCores.escuroOuro,
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                onPressed: () => cubit.alternarServidorLan(),
                child: Text(
                  salaAberta ? 'Encerrar' : 'Abrir sala',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: const Icon(Icons.qr_code_2, size: 20, color: MestreCores.escuroOuro),
                tooltip: 'Convidar jogadores (QR e PIN)',
                onPressed: () => _exibirSheetConvidarJogadores(context),
              ),
              IconButton(
                icon: const Icon(Icons.people_alt_outlined, size: 20, color: MestreCores.escuroOuro),
                tooltip: 'Jogadores na sala',
                onPressed: () => _exibirSheetJogadoresNaSala(context),
              ),
              IconButton(
                icon: const Icon(Icons.network_check_outlined, size: 20, color: MestreCores.escuroOuro),
                tooltip: 'Diagnóstico de rede',
                onPressed: () => _exibirSheetDiagnosticoRede(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MENU ⋮ EM CADA NÓ (RENOMEAR, DUPLICAR, ARQUIVAR, EXCLUIR)
  // ---------------------------------------------------------------------------

  Widget _buildMenuOpcoesNo(
    BuildContext context, {
    required String titulo,
    required VoidCallback onRenomear,
    required VoidCallback onDuplicar,
    required VoidCallback onExcluir,
  }) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 16, color: MestreCores.escuroOnSurfaceVariant),
      color: MestreCores.escuroSurfaceContainer,
      onSelected: (val) {
        if (val == 'renomear') onRenomear();
        if (val == 'duplicar') onDuplicar();
        if (val == 'excluir') {
          _confirmarExclusao(context, titulo, onExcluir);
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'renomear', child: Text('Renomear', style: TextStyle(color: MestreCores.escuroOnSurface))),
        PopupMenuItem(value: 'duplicar', child: Text('Duplicar', style: TextStyle(color: MestreCores.escuroOnSurface))),
        PopupMenuItem(value: 'excluir', child: Text('Excluir', style: TextStyle(color: MestreCores.statusAlertaEscuro))),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // RODAPÉ FIXO: + NOVA CAMPANHA & ESTADO VAZIO
  // ---------------------------------------------------------------------------

  Widget _buildRodapeNovaCampanha(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: MestreCores.escuroSurface,
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: MestreCores.escuroOuro,
            foregroundColor: MestreCores.escuroOuroTexto,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.add, size: 18),
          label: const Text(
            '+ Nova campanha',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          onPressed: () => _exibirDialogCriarItem(
            context,
            titulo: 'Nova Campanha',
            onCriar: (nome, desc) {
              cubit.criarCampanha(nome: nome, descricao: desc, patamar: 'Iniciante (Nível 1 a 4)');
              _exibirSnackCriarAventura(context);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoVazio(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shield_outlined, size: 48, color: MestreCores.escuroOnSurfaceVariant),
            const SizedBox(height: 12),
            const Text(
              'Crie sua primeira campanha',
              style: TextStyle(
                fontFamily: 'serif',
                color: MestreCores.escuroOnSurface,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Organize suas aventuras, sessões e salas LAN em uma única árvore tática.',
              textAlign: TextAlign.center,
              style: TextStyle(color: MestreCores.escuroOnSurfaceVariant, fontSize: 12),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: MestreCores.escuroOuro, foregroundColor: MestreCores.escuroOuroTexto),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Criar Campanha'),
              onPressed: () => _exibirDialogCriarItem(
                context,
                titulo: 'Nova Campanha',
                onCriar: (nome, desc) {
                  cubit.criarCampanha(nome: nome, descricao: desc, patamar: 'Iniciante (Nível 1 a 4)');
                  _exibirSnackCriarAventura(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DIÁLOGOS DE CRIAÇÃO E RENOMEAÇÃO
  // ---------------------------------------------------------------------------

  void _exibirDialogCriarItem(
    BuildContext context, {
    required String titulo,
    required void Function(String nome, String descricao) onCriar,
  }) {
    final nomeController = TextEditingController();
    final descController = TextEditingController();
    bool expandirOpcoes = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: MestreCores.escuroSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  fontFamily: 'serif',
                  color: MestreCores.escuroOnSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nomeController,
                autofocus: true,
                style: const TextStyle(color: MestreCores.escuroOnSurface),
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  labelStyle: TextStyle(color: MestreCores.escuroOnSurfaceVariant),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: MestreCores.escuroOutline)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: MestreCores.escuroOuro)),
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => setSheetState(() => expandirOpcoes = !expandirOpcoes),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        expandirOpcoes ? Icons.expand_less : Icons.expand_more,
                        size: 16,
                        color: MestreCores.escuroOuro,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        expandirOpcoes ? 'Menos opções' : 'Mais opções (descrição)',
                        style: const TextStyle(color: MestreCores.escuroOuro, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              if (expandirOpcoes) ...[
                const SizedBox(height: 6),
                TextField(
                  controller: descController,
                  maxLines: 2,
                  style: const TextStyle(color: MestreCores.escuroOnSurface),
                  decoration: const InputDecoration(
                    labelText: 'Descrição ou sinopse',
                    labelStyle: TextStyle(color: MestreCores.escuroOnSurfaceVariant),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: MestreCores.escuroOutline)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: MestreCores.escuroOuro)),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: MestreCores.escuroOuro,
                  foregroundColor: MestreCores.escuroOuroTexto,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () {
                  final nome = nomeController.text.trim();
                  if (nome.isNotEmpty) {
                    onCriar(nome, descController.text.trim());
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Confirmar', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _exibirDialogRenomear(
    BuildContext context,
    String tipo,
    String valorAtual,
    void Function(String novoNome) onConfirmar,
  ) {
    final controller = TextEditingController(text: valorAtual);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MestreCores.escuroSurface,
        title: Text('Renomear $tipo', style: const TextStyle(color: MestreCores.escuroOnSurface)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: MestreCores.escuroOnSurface),
          decoration: InputDecoration(
            labelText: 'Novo nome',
            enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: MestreCores.escuroOutline)),
            focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: MestreCores.escuroOuro)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: MestreCores.escuroOnSurfaceVariant)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: MestreCores.escuroOuro, foregroundColor: MestreCores.escuroOuroTexto),
            onPressed: () {
              onConfirmar(controller.text);
              Navigator.pop(ctx);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _confirmarExclusao(BuildContext context, String nomeItem, VoidCallback onConfirmar) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MestreCores.escuroSurface,
        title: const Text('Confirmar exclusão', style: TextStyle(color: MestreCores.escuroOnSurface)),
        content: Text('Deseja realmente excluir $nomeItem?', style: const TextStyle(color: MestreCores.escuroOnSurfaceVariant)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: MestreCores.escuroOnSurfaceVariant)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: MestreCores.statusAlertaEscuro),
            onPressed: () {
              onConfirmar();
              Navigator.pop(ctx);
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _exibirSnackCriarAventura(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: MestreCores.escuroVinho,
        content: const Text('Campanha criada! Deseja criar uma aventura agora?'),
        action: SnackBarAction(
          label: 'Criar aventura agora',
          textColor: MestreCores.escuroOuro,
          onPressed: () {
            _exibirDialogCriarItem(
              context,
              titulo: 'Nova Aventura',
              onCriar: (nome, desc) {
                cubit.criarAventura(nome: nome, sinopse: desc);
                _exibirSnackCriarSessao(context);
              },
            );
          },
        ),
      ),
    );
  }

  void _exibirSnackCriarSessao(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: MestreCores.escuroVinho,
        content: const Text('Aventura criada! Deseja criar uma sessão agora?'),
        action: SnackBarAction(
          label: 'Criar sessão agora',
          textColor: MestreCores.escuroOuro,
          onPressed: () {
            _exibirDialogCriarItem(
              context,
              titulo: 'Nova Sessão',
              onCriar: (nome, desc) {
                cubit.criarSessao(titulo: nome, objetivoResumo: desc);
              },
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // AS 5 SHEETS DA LAN
  // ---------------------------------------------------------------------------

  // Sheet 1: Convidar Jogadores
  void _exibirSheetConvidarJogadores(BuildContext context) {
    bool exigirDigitarPin = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: MestreCores.escuroSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Convidar Jogadores',
                    style: TextStyle(
                      fontFamily: 'serif',
                      color: MestreCores.escuroOnSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: MestreCores.escuroOnSurfaceVariant, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // QR Code Simulado com visual tático
              Center(
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: MestreCores.escuroOuro, width: 2),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(Icons.qr_code_2, size: 140, color: Colors.black87),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: MestreCores.escuroVinho,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('T20', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // IP:Porta Copiável
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: MestreCores.escuroSurfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wifi, size: 16, color: MestreCores.escuroOuro),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'IP: ${state.ipHostLocal}:${state.portaHostLan}',
                        style: MestreCores.estiloMono.copyWith(color: MestreCores.escuroOnSurface, fontSize: 13),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 16, color: MestreCores.escuroOuro),
                      tooltip: 'Copiar IP',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: '${state.ipHostLocal}:${state.portaHostLan}'));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('IP copiado para a área de transferência!')));
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // PIN de 6 dígitos grande + [Girar PIN]
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: MestreCores.escuroSurfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: MestreCores.escuroOuro.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PIN DE ACESSO', style: TextStyle(color: MestreCores.escuroOnSurfaceVariant, fontSize: 10, letterSpacing: 1)),
                        Text(
                          state.sessaoAtual?.codigoSalaLan ?? 'T20-4829',
                          style: MestreCores.estiloMono.copyWith(color: MestreCores.escuroOuro, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Girar PIN'),
                      style: TextButton.styleFrom(foregroundColor: MestreCores.escuroOuro),
                      onPressed: () => cubit.gerarNovoCodigoSalaLan(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Toggle Exigir PIN manual
              SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text('Exigir digitar PIN (não colocar no QR)', style: TextStyle(color: MestreCores.escuroOnSurface, fontSize: 12)),
                value: exigirDigitarPin,
                activeThumbColor: MestreCores.escuroOuro,
                onChanged: (val) => setSheetState(() => exigirDigitarPin = val),
              ),
              const SizedBox(height: 8),

              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: MestreCores.escuroOuro,
                  foregroundColor: MestreCores.escuroOuroTexto,
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: const Icon(Icons.share, size: 18),
                label: const Text('Compartilhar convite', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  Clipboard.setData(ClipboardData(
                    text: 'Entre na mesa de Tormenta 20!\nIP: ${state.ipHostLocal}:${state.portaHostLan}\nPIN: ${state.sessaoAtual?.codigoSalaLan}',
                  ));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Convite copiado para compartilhar!')));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Sheet 2: Jogadores na Sala
  void _exibirSheetJogadoresNaSala(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: MestreCores.escuroSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Jogadores na Sala',
                  style: TextStyle(
                    fontFamily: 'serif',
                    color: MestreCores.escuroOnSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: MestreCores.escuroOnSurfaceVariant, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if ((state.sessaoAtual?.elenco ?? []).isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: const [
                    Icon(Icons.people_outline, size: 40, color: MestreCores.escuroOnSurfaceVariant),
                    SizedBox(height: 8),
                    Text(
                      'Nenhum jogador na sala',
                      style: TextStyle(color: MestreCores.escuroOnSurface, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Os jogadores conectam via Wi-Fi/Hotspot pelo QR Code ou IP e PIN.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: MestreCores.escuroOnSurfaceVariant, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ...(state.sessaoAtual?.elenco ?? []).map((entry) {
              Color corStatus = entry.conectadoViaLan ? MestreCores.statusOnlineEscuro : MestreCores.statusOffline;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: MestreCores.escuroSurfaceContainer,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: MestreCores.escuroOutline),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: MestreCores.escuroVinho,
                      child: Text(entry.nomePersonagem.substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(entry.nomePersonagem, style: const TextStyle(color: MestreCores.escuroOnSurface, fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(width: 6),
                              Icon(Icons.circle, size: 7, color: corStatus),
                              const SizedBox(width: 4),
                              Text(entry.conectadoViaLan ? 'Online (18ms)' : 'Offline', style: TextStyle(color: corStatus, fontSize: 10)),
                            ],
                          ),
                          Text(
                            'Jogador: ${entry.nomeJogador} • ${entry.classeResumo}',
                            style: const TextStyle(color: MestreCores.escuroOnSurfaceVariant, fontSize: 11),
                          ),
                          if (entry.statusRevisao == StatusRevisaoFicha.pendente)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: MestreCores.statusAlertaEscuro.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('Ficha aguardando revisão', style: TextStyle(color: MestreCores.statusAlertaEscuro, fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.person_remove_outlined, color: MestreCores.statusAlertaEscuro, size: 18),
                      tooltip: 'Expulsar jogador',
                      onPressed: () {
                        _confirmarExclusao(context, 'o jogador ${entry.nomeJogador}', () {
                          cubit.removerPersonagemDaSessao(entry.characterId);
                        });
                      },
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: MestreCores.escuroOuro,
                side: const BorderSide(color: MestreCores.escuroOuro),
                minimumSize: const Size.fromHeight(44),
              ),
              icon: const Icon(Icons.person_add_outlined, size: 18),
              label: const Text('Simular Pedido de Entrada LAN'),
              onPressed: () {
                cubit.simularPedidoEntradaJogadorLan(
                  nomeJogador: 'Jogador Visitante',
                  nomePersonagem: 'Kaelen',
                  classeResumo: 'Ladino Nv 2',
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Sheet 3: Diagnóstico de Rede
  void _exibirSheetDiagnosticoRede(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: MestreCores.escuroSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Diagnóstico de Rede LAN',
                  style: TextStyle(fontFamily: 'serif', color: MestreCores.escuroOnSurface, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: MestreCores.escuroOnSurfaceVariant, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildItemDiagnostico(icone: Icons.wifi, titulo: 'Wi-Fi / Hotspot Conectado', statusOk: true, mensagem: 'Conectado à rede local do aparelho.'),
            _buildItemDiagnostico(icone: Icons.lan, titulo: 'IP Local Encontrado', statusOk: true, mensagem: 'Endereço: ${state.ipHostLocal}'),
            _buildItemDiagnostico(icone: Icons.dns, titulo: 'Servidor LAN Ativo', statusOk: state.statusLan != StatusConexaoLan.desligado, mensagem: 'Porta padrão: ${state.portaHostLan}'),
            _buildItemDiagnostico(icone: Icons.lock_open, titulo: 'Porta Aberta e Acessível', statusOk: true, mensagem: 'Permissões locais liberadas no Android.'),
            _buildItemDiagnostico(
              icone: Icons.devices,
              titulo: 'Rede Local Permite Aparelhos',
              statusOk: true,
              mensagem: 'Esta rede permite comunicação peer-to-peer. Se houver problemas, use o Hotspot do celular.',
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: MestreCores.escuroOuro,
                foregroundColor: MestreCores.escuroOuroTexto,
                minimumSize: const Size.fromHeight(48),
              ),
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Copiar Relatório de Rede', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                Clipboard.setData(ClipboardData(
                  text: 'Relatório T20 LAN:\nIP: ${state.ipHostLocal}:${state.portaHostLan}\nStatus: ${state.statusLan.rotulo}\nJogadores: ${state.sessaoAtual?.elenco.length}',
                ));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Relatório copiado!')));
              },
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => _exibirDialogAjudaBateria(context),
                  child: const Text('Ajuda de Bateria (Xiaomi/Samsung)', style: TextStyle(color: MestreCores.escuroOuro, fontSize: 11)),
                ),
                TextButton(
                  onPressed: () => _exibirDialogPermissoes(context),
                  child: const Text('Permissões de Rede', style: TextStyle(color: MestreCores.escuroOuro, fontSize: 11)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemDiagnostico({
    required IconData icone,
    required String titulo,
    required bool statusOk,
    required String mensagem,
  }) {
    final cor = statusOk ? MestreCores.statusOnlineEscuro : MestreCores.statusAlertaEscuro;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 18, color: cor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: TextStyle(color: MestreCores.escuroOnSurface, fontSize: 12, fontWeight: FontWeight.bold)),
                Text(mensagem, style: const TextStyle(color: MestreCores.escuroOnSurfaceVariant, fontSize: 11)),
              ],
            ),
          ),
          Icon(statusOk ? Icons.check_circle : Icons.warning_amber, size: 16, color: cor),
        ],
      ),
    );
  }

  // Sheet 4: Ajuda de Bateria
  void _exibirDialogAjudaBateria(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MestreCores.escuroSurface,
        title: const Text('Otimização de Bateria', style: TextStyle(fontFamily: 'serif', color: MestreCores.escuroOnSurface)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Para evitar que o Android desconecte os jogadores durante a sessão:', style: TextStyle(color: MestreCores.escuroOnSurfaceVariant, fontSize: 12)),
            SizedBox(height: 10),
            Text('1. Desative a "Economia de Bateria" para o T20 Creator.', style: TextStyle(color: MestreCores.escuroOnSurface, fontSize: 12, fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text('2. Permita execução Irrestrita em segundo plano.', style: TextStyle(color: MestreCores.escuroOnSurface, fontSize: 12, fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text('3. Bloqueie o app na tela de aplicativos recentes (ícone de cadeado).', style: TextStyle(color: MestreCores.escuroOnSurface, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: MestreCores.escuroOuro, foregroundColor: MestreCores.escuroOuroTexto),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  // Sheet 5: Permissões de Rede
  void _exibirDialogPermissoes(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MestreCores.escuroSurface,
        title: const Text('Permissões Necessárias', style: TextStyle(fontFamily: 'serif', color: MestreCores.escuroOnSurface)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('O modo Host LAN utiliza apenas a rede local sem envio para a nuvem:', style: TextStyle(color: MestreCores.escuroOnSurfaceVariant, fontSize: 12)),
            SizedBox(height: 10),
            Text('• Rede Local (Sockets): para receber as fichas dos jogadores.', style: TextStyle(color: MestreCores.escuroOnSurface, fontSize: 12)),
            SizedBox(height: 6),
            Text('• Câmera: para ler QR codes de convite (quando aplicável).', style: TextStyle(color: MestreCores.escuroOnSurface, fontSize: 12)),
            SizedBox(height: 6),
            Text('• Notificações: para manter o serviço da mesa ativo em segundo plano.', style: TextStyle(color: MestreCores.escuroOnSurface, fontSize: 12)),
          ],
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: MestreCores.escuroOuro, foregroundColor: MestreCores.escuroOuroTexto),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
