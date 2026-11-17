import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/mestre/modelos_mestre.dart';
import '../../controllers/mestre_controller/mestre_cubit.dart';
import '../../controllers/mestre_controller/mestre_state.dart';
import 'criar_aventura_screen.dart';
import 'criar_sessao_screen.dart';
import 'mesa_sessao_screen.dart';
import 'theme/mestre_theme.dart';
import 'widgets/campanha_card.dart';
import 'widgets/mestre_empty_state.dart';

/// Tela de detalhes da Campanha selecionada: exibe código LAN (se houver),
/// lista de Aventuras e suas Sessões com ações grandes (>= 48dp).
class CampanhaDetalheScreen extends StatelessWidget {
  final MestreCubit cubit;
  final String campanhaId;

  const CampanhaDetalheScreen({
    super.key,
    required this.cubit,
    required this.campanhaId,
  });

  void _abrirCriarAventura(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<String?>(
        builder: (_) => CriarAventuraScreen(
          cubit: cubit,
          campanhaIdInicial: campanhaId,
        ),
      ),
    );
  }

  void _abrirCriarSessao(BuildContext context, String aventuraId) {
    Navigator.of(context).push(
      MaterialPageRoute<String?>(
        builder: (_) => CriarSessaoScreen(
          cubit: cubit,
          campanhaId: campanhaId,
          aventuraIdInicial: aventuraId,
        ),
      ),
    );
  }

  Future<void> _abrirConvidarJogador(BuildContext context) async {
    final resultado =
        await showDialog<({String jogador, String heroi})>(
      context: context,
      builder: (_) => const _DialogConvidarJogador(),
    );

    if (resultado != null && resultado.jogador.isNotEmpty) {
      cubit.convidarJogadorCampanha(
        campanhaId: campanhaId,
        nomeJogador: resultado.jogador,
        nomePersonagem: resultado.heroi,
      );
    }
  }

  Future<void> _abrirEnviarMapa(
    BuildContext context,
    CampanhaMestre campanha,
  ) async {
    final idsNaCampanha = campanha.mapas.map((m) => m.id).toSet();
    final mapasDisponiveis = <MapaBatalhaMestre>[];
    final idsVistos = <String>{};

    for (final c in cubit.state.campanhas) {
      for (final m in c.mapas) {
        if (!idsNaCampanha.contains(m.id) && idsVistos.add(m.id)) {
          mapasDisponiveis.add(m);
        }
      }
      for (final av in c.aventuras) {
        for (final m in av.mapas) {
          if (!idsNaCampanha.contains(m.id) && idsVistos.add(m.id)) {
            mapasDisponiveis.add(m);
          }
        }
      }
    }

    if (mapasDisponiveis.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Todos os mapas da biblioteca já estão nesta campanha. Crie novos mapas na aba Mapas.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final mapaEscolhido = await showModalBottomSheet<MapaBatalhaMestre>(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enviar mapa para "${campanha.nome}"',
                style: Theme.of(sheetCtx)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: mapasDisponiveis.length,
                  itemBuilder: (_, index) {
                    final mapa = mapasDisponiveis[index];
                    return ListTile(
                      minTileHeight: 52,
                      leading: const Icon(Icons.map_outlined),
                      title: Text(mapa.nome),
                      subtitle: Text('Grid ${mapa.largura}×${mapa.altura}'),
                      trailing: const Icon(Icons.add_circle_outline),
                      onTap: () => Navigator.of(sheetCtx).pop(mapa),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (mapaEscolhido != null) {
      cubit.enviarMapaParaCampanha(
        campanhaId: campanhaId,
        mapa: mapaEscolhido,
      );
    }
  }

  Future<void> _abrirSessaoComEscolhaMapa(
    BuildContext context, {
    required CampanhaMestre campanha,
    required AventuraMestre aventura,
    required SessaoJogo sessao,
  }) async {
    final mapasPorId = <String, MapaBatalhaMestre>{};
    for (final m in campanha.mapas) {
      mapasPorId[m.id] = m;
    }
    for (final m in aventura.mapas) {
      mapasPorId.putIfAbsent(m.id, () => m);
    }
    final mapasOpcoes = mapasPorId.values.toList();

    final escolha = await showModalBottomSheet<({bool abrirMesa, String? mapaId})>(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Iniciar "${sessao.titulo}"',
                style: Theme.of(sheetCtx)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                campanha.jogadoresConvidados.isEmpty
                    ? 'Escolha um mapa da campanha para abrir a Mesa de Jogo.'
                    : '${campanha.jogadoresConvidados.length} jogador(es) convidado(s) serão vinculados à sessão.',
                style: Theme.of(sheetCtx).textTheme.bodySmall?.copyWith(
                  color: Theme.of(sheetCtx).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              if (mapasOpcoes.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Nenhum mapa enviado para esta campanha ainda.',
                    style: Theme.of(sheetCtx).textTheme.bodyMedium,
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: mapasOpcoes.length,
                    itemBuilder: (_, index) {
                      final mapa = mapasOpcoes[index];
                      final ativo = mapa.id == sessao.mapaAtivoId;
                      return ListTile(
                        minTileHeight: 52,
                        leading: Icon(
                          ativo ? Icons.map : Icons.map_outlined,
                          color: ativo
                              ? Theme.of(sheetCtx).colorScheme.primary
                              : null,
                        ),
                        title: Text(mapa.nome),
                        subtitle: Text(
                          ativo
                              ? 'Mapa ativo na sessão • ${mapa.largura}×${mapa.altura}'
                              : 'Grid ${mapa.largura}×${mapa.altura}',
                        ),
                        trailing: const Icon(Icons.play_arrow_rounded),
                        onTap: () => Navigator.of(sheetCtx).pop((
                          abrirMesa: true,
                          mapaId: mapa.id,
                        )),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () => Navigator.of(sheetCtx).pop((
                  abrirMesa: false,
                  mapaId: null,
                )),
                child: const Text('Apenas marcar como sessão ativa'),
              ),
            ],
          ),
        ),
      ),
    );

    if (escolha == null || !context.mounted) return;

    cubit.abrirSessaoComMapa(
      campanhaId: campanha.id,
      aventuraId: aventura.id,
      sessaoId: sessao.id,
      mapaId: escolha.mapaId,
    );

    if (escolha.abrirMesa && escolha.mapaId != null) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MesaSessaoScreen(cubit: cubit),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sessão ativa: ${sessao.titulo}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: MestreCores.homeStyleTheme,
      child: BlocBuilder<MestreCubit, MestreState>(
        bloc: cubit,
        builder: (context, state) {
          final campanha = state.campanhas
              .where((c) => c.id == campanhaId)
              .firstOrNull;

          if (campanha == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Campanha')),
              body: const Center(
                child: Text('Campanha não encontrada.'),
              ),
            );
          }

          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;
          final textTheme = theme.textTheme;
          final temAventuras = campanha.aventuras.isNotEmpty;

          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                campanha.nome,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            body: SafeArea(
              child: !temAventuras
                  ? Column(
                      children: [
                        if (campanha.codigoConexaoLan != null &&
                            campanha.codigoConexaoLan!.isNotEmpty)
                          _BannerCodigoLan(
                            codigo: campanha.codigoConexaoLan!,
                          ),
                        Expanded(
                          child: MestreEmptyState(
                            icon: Icons.auto_stories_outlined,
                            titulo: 'Nenhuma aventura ainda',
                            subtitulo:
                                'Crie uma aventura para organizar as sessões de "${campanha.nome}".',
                            textoBotao: 'Criar aventura',
                            onAcaoPrincipal: () => _abrirCriarAventura(context),
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                      children: [
                        if (campanha.codigoConexaoLan != null &&
                            campanha.codigoConexaoLan!.isNotEmpty) ...[
                          _BannerCodigoLan(
                            codigo: campanha.codigoConexaoLan!,
                          ),
                          const SizedBox(height: 12),
                        ],
                        _SecaoJogadoresCampanha(
                          jogadores: campanha.jogadoresConvidados,
                          onConvidar: () => _abrirConvidarJogador(context),
                          onRemover: (id) => cubit.removerJogadorCampanha(
                            campanhaId: campanha.id,
                            characterId: id,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _SecaoMapasCampanha(
                          mapas: campanha.mapas,
                          onEnviarMapa: () =>
                              _abrirEnviarMapa(context, campanha),
                        ),
                        const SizedBox(height: 12),
                        ...campanha.aventuras.map((aventura) {
                          return _AventuraCard(
                            aventura: aventura,
                            sessaoAtivaId: state.sessaoSelecionadaId,
                            onSelecionarSessao: (sessao) =>
                                _abrirSessaoComEscolhaMapa(
                              context,
                              campanha: campanha,
                              aventura: aventura,
                              sessao: sessao,
                            ),
                            onNovaSessao: () =>
                                _abrirCriarSessao(context, aventura.id),
                            onExcluirAventura: () => cubit.excluirAventura(
                              aventura.id,
                              campanhaId: campanha.id,
                            ),
                            onExcluirSessao: (sessaoId) => cubit.excluirSessao(
                              sessaoId,
                              campanhaId: campanha.id,
                              aventuraId: aventura.id,
                            ),
                          );
                        }),
                      ],
                    ),
            ),
            floatingActionButton: temAventuras
                ? FloatingActionButton.extended(
                    heroTag: 'mestre_campanha_detalhe_fab',
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    icon: const Icon(Icons.add),
                    label: const Text(
                      'Nova aventura',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => _abrirCriarAventura(context),
                  )
                : null,
          );
        },
      ),
    );
  }
}

class _BannerCodigoLan extends StatelessWidget {
  final String codigo;

  const _BannerCodigoLan({required this.codigo});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      color: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.wifi_tethering, color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Código LAN da campanha',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    codigo,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: 'Copiar código LAN',
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: codigo));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Código LAN copiado!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AventuraCard extends StatelessWidget {
  final AventuraMestre aventura;
  final String? sessaoAtivaId;
  final ValueChanged<SessaoJogo> onSelecionarSessao;
  final VoidCallback onNovaSessao;
  final VoidCallback onExcluirAventura;
  final ValueChanged<String> onExcluirSessao;

  const _AventuraCard({
    required this.aventura,
    required this.sessaoAtivaId,
    required this.onSelecionarSessao,
    required this.onNovaSessao,
    required this.onExcluirAventura,
    required this.onExcluirSessao,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_stories_outlined,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    aventura.nome,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: colorScheme.outline,
                  ),
                  tooltip: 'Excluir aventura',
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  onPressed: () async {
                    final confirmou = await confirmarExclusaoMestre(
                      context: context,
                      titulo: 'Excluir aventura',
                      mensagem:
                          'Deseja excluir "${aventura.nome}" e suas sessões?',
                    );
                    if (confirmou) {
                      onExcluirAventura();
                    }
                  },
                ),
              ],
            ),
            const Divider(height: 16),
            if (aventura.sessoes.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Nenhuma sessão criada nesta aventura.',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              ...aventura.sessoes.map((sessao) {
                final ativa = sessao.id == sessaoAtivaId;
                return ListTile(
                  minTileHeight: 52,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  selected: ativa,
                  selectedTileColor:
                      colorScheme.primaryContainer.withValues(alpha: 0.35),
                  leading: Icon(
                    ativa ? Icons.play_circle_filled : Icons.event_note_outlined,
                    color: ativa
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  title: Text(
                    sessao.titulo,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: ativa ? FontWeight.bold : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    ativa ? 'Sessão ativa' : sessao.statusSessao.rotulo,
                    style: textTheme.bodySmall?.copyWith(
                      color: ativa
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: colorScheme.outline,
                      size: 20,
                    ),
                    tooltip: 'Excluir sessão',
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    onPressed: () async {
                      final confirmou = await confirmarExclusaoMestre(
                        context: context,
                        titulo: 'Excluir sessão',
                        mensagem: 'Deseja excluir "${sessao.titulo}"?',
                      );
                      if (confirmou) {
                        onExcluirSessao(sessao.id);
                      }
                    },
                  ),
                  onTap: () => onSelecionarSessao(sessao),
                );
              }),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Nova sessão'),
              onPressed: onNovaSessao,
            ),
          ],
        ),
      ),
    );
  }
}

class _SecaoJogadoresCampanha extends StatelessWidget {
  final List<ElencoSessaoEntry> jogadores;
  final VoidCallback onConvidar;
  final ValueChanged<String> onRemover;

  const _SecaoJogadoresCampanha({
    required this.jogadores,
    required this.onConvidar,
    required this.onRemover,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.group_outlined, color: colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Jogadores convidados (${jogadores.length})',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                  onPressed: onConvidar,
                  icon: const Icon(Icons.person_add_alt_1, size: 18),
                  label: const Text('Convidar'),
                ),
              ],
            ),
            if (jogadores.isEmpty)
              Text(
                'Nenhum jogador convidado ainda. Eles entram automaticamente nas sessões desta campanha.',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: jogadores
                    .map(
                      (j) => InputChip(
                        label: Text(
                          j.nomePersonagem == j.nomeJogador
                              ? j.nomeJogador
                              : '${j.nomeJogador} (${j.nomePersonagem})',
                        ),
                        onDeleted: () => onRemover(j.characterId),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _SecaoMapasCampanha extends StatelessWidget {
  final List<MapaBatalhaMestre> mapas;
  final VoidCallback onEnviarMapa;

  const _SecaoMapasCampanha({
    required this.mapas,
    required this.onEnviarMapa,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.map_outlined, color: colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Mapas da campanha (${mapas.length})',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                  onPressed: onEnviarMapa,
                  icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                  label: const Text('Enviar mapa'),
                ),
              ],
            ),
            if (mapas.isEmpty)
              Text(
                'Envie mapas para reutilizá-los em qualquer sessão desta campanha.',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: mapas
                    .map(
                      (m) => Chip(
                        avatar: const Icon(Icons.grid_on, size: 16),
                        label: Text('${m.nome} (${m.largura}×${m.altura})'),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _DialogConvidarJogador extends StatefulWidget {
  const _DialogConvidarJogador();

  @override
  State<_DialogConvidarJogador> createState() => _DialogConvidarJogadorState();
}

class _DialogConvidarJogadorState extends State<_DialogConvidarJogador> {
  final _jogadorCtrl = TextEditingController();
  final _heroiCtrl = TextEditingController();

  @override
  void dispose() {
    _jogadorCtrl.dispose();
    _heroiCtrl.dispose();
    super.dispose();
  }

  void _confirmar() {
    final jogador = _jogadorCtrl.text.trim();
    if (jogador.isEmpty) return;
    Navigator.of(context).pop((
      jogador: jogador,
      heroi: _heroiCtrl.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Convidar jogador'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _jogadorCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Nome do jogador *',
              hintText: 'Ex: Lucas',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _heroiCtrl,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Nome do personagem (opcional)',
              hintText: 'Ex: Valeros',
            ),
            onSubmitted: (_) => _confirmar(),
          ),
        ],
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: _confirmar,
          child: const Text('Convidar'),
        ),
      ],
    );
  }
}


