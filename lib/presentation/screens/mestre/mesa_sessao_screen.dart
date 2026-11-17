import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/mestre/modelos_mestre.dart';
import '../../controllers/mestre_controller/mestre_cubit.dart';
import '../../controllers/mestre_controller/mestre_state.dart';
import 'theme/mestre_theme.dart';
import 'widgets/tela_escudo_notas.dart';
import 'widgets/tela_mesa_jogo.dart';

/// Tela unificada de Sessão Ativa ("Escudo do Mestre" no celular).
///
/// Mantém Mapa, Escudo/Notas e Jogadores em um `IndexedStack` com troca em
/// 1 toque via barra inferior — sem swipe lateral (não conflita com o pan do
/// mapa) e sem desmontar o estado visual do mapa durante consultas rápidas.
class MesaSessaoScreen extends StatefulWidget {
  final MestreCubit cubit;
  final int abaInicial;

  const MesaSessaoScreen({
    super.key,
    required this.cubit,
    this.abaInicial = 0,
  });

  @override
  State<MesaSessaoScreen> createState() => _MesaSessaoScreenState();
}

class _MesaSessaoScreenState extends State<MesaSessaoScreen> {
  late int _abaAtiva;

  @override
  void initState() {
    super.initState();
    _abaAtiva = widget.abaInicial.clamp(0, 2);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: MestreCores.homeStyleTheme,
      child: BlocProvider.value(
        value: widget.cubit,
        child: Scaffold(
          body: IndexedStack(
            index: _abaAtiva,
            children: [
              TelaMesaJogo(
                cubit: widget.cubit,
                onVoltarBiblioteca: () => Navigator.of(context).pop(),
              ),
              TelaEscudoNotas(cubit: widget.cubit),
              _AbaJogadoresSessao(
                cubit: widget.cubit,
                onIrParaMapa: () => setState(() => _abaAtiva = 0),
              ),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _abaAtiva,
            onDestinationSelected: (index) =>
                setState(() => _abaAtiva = index),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.map_outlined),
                selectedIcon: Icon(Icons.map),
                label: 'Mapa',
              ),
              NavigationDestination(
                icon: Icon(Icons.shield_outlined),
                selectedIcon: Icon(Icons.shield),
                label: 'Escudo',
              ),
              NavigationDestination(
                icon: Icon(Icons.group_outlined),
                selectedIcon: Icon(Icons.group),
                label: 'Jogadores',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AbaJogadoresSessao extends StatelessWidget {
  final MestreCubit cubit;
  final VoidCallback onIrParaMapa;

  const _AbaJogadoresSessao({
    required this.cubit,
    required this.onIrParaMapa,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocBuilder<MestreCubit, MestreState>(
      bloc: cubit,
      builder: (context, state) {
        final camp = state.campanhaAtual;
        final sessao = state.sessaoAtual;
        final mapa = state.mapaAtual;
        final elenco = sessao?.elenco ?? const <ElencoSessaoEntry>[];
        final codigoLan = (camp?.codigoConexaoLan?.isNotEmpty ?? false)
            ? camp!.codigoConexaoLan!
            : sessao?.codigoSalaLan;
        final salaAberta = state.statusLan != StatusConexaoLan.desligado;
        final ipPorta = '${state.ipHostLocal}:${state.portaHostLan}';
        final idsNoMapa = (mapa?.tokens ?? const <TokenNoMapa>[])
            .map((t) => t.id)
            .toSet();

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Sair da mesa',
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Jogadores da Sessão',
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (sessao != null)
                  Card(
                    elevation: 0,
                    color: colorScheme.surfaceContainerHigh,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            minTileHeight: 48,
                            leading: Icon(
                              salaAberta
                                  ? Icons.wifi_tethering
                                  : Icons.event_note_outlined,
                              color: salaAberta
                                  ? Colors.green.shade700
                                  : colorScheme.primary,
                            ),
                            title: Text(
                              sessao.titulo,
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              codigoLan != null
                                  ? 'Código LAN: $codigoLan'
                                  : 'Sessão local ativa',
                            ),
                            trailing: codigoLan != null
                                ? IconButton(
                                    icon: const Icon(Icons.copy, size: 20),
                                    tooltip: 'Copiar código e IP',
                                    onPressed: () {
                                      Clipboard.setData(
                                        ClipboardData(
                                          text:
                                              'Código: $codigoLan | IP: $ipPorta',
                                        ),
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Código e IP copiados!',
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                  )
                                : null,
                          ),
                          const Divider(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.lan_outlined,
                                size: 16,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'IP do Mestre: $ipPorta • ${salaAberta ? "Sala Aberta" : "Sala Fechada"}',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              FilledButton.icon(
                                key: const Key('botao_alternar_sala_lan'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: salaAberta
                                      ? colorScheme.error
                                      : colorScheme.primary,
                                  foregroundColor: salaAberta
                                      ? colorScheme.onError
                                      : colorScheme.onPrimary,
                                  minimumSize: const Size(120, 40),
                                ),
                                icon: Icon(
                                  salaAberta
                                      ? Icons.stop_circle_outlined
                                      : Icons.wifi_tethering,
                                  size: 18,
                                ),
                                label: Text(
                                  salaAberta ? 'Encerrar LAN' : 'Abrir Sala LAN',
                                ),
                                onPressed: cubit.alternarServidorLan,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                if (elenco.isEmpty)
                  Card(
                    elevation: 0,
                    color: colorScheme.surfaceContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(
                            Icons.group_off_outlined,
                            size: 40,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Nenhum jogador nesta sessão ainda.',
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Abra a Sala LAN acima para que os jogadores se conectem usando o Código LAN ou o IP do Mestre.',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...elenco.map((heroi) {
                    final jaNoMapa = idsNoMapa.contains(heroi.characterId);
                    final pendente =
                        heroi.statusRevisao == StatusRevisaoFicha.pendente ||
                        heroi.statusRevisao == StatusRevisaoFicha.desatualizada;

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 10),
                      color: colorScheme.surfaceContainer,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              minTileHeight: 52,
                              leading: CircleAvatar(
                                backgroundColor: colorScheme.primaryContainer,
                                foregroundColor: colorScheme.onPrimaryContainer,
                                child: Text(
                                  heroi.nomePersonagem.isNotEmpty
                                      ? heroi.nomePersonagem[0].toUpperCase()
                                      : '?',
                                ),
                              ),
                              title: Text(
                                heroi.nomePersonagem,
                                style: textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '${heroi.nomeJogador} • PV ${heroi.pvAtual}/${heroi.pvMax} • PM ${heroi.pmAtual}/${heroi.pmMax}',
                              ),
                              trailing: pendente
                                  ? null
                                  : (jaNoMapa
                                        ? Chip(
                                            label: const Text('No mapa'),
                                            backgroundColor:
                                                colorScheme.primaryContainer,
                                          )
                                        : FilledButton.tonal(
                                            style: FilledButton.styleFrom(
                                              minimumSize: const Size(48, 44),
                                            ),
                                            onPressed: mapa == null
                                                ? null
                                                : () {
                                                    cubit.adicionarHeroiNoMapa(
                                                      heroi,
                                                    );
                                                    onIrParaMapa();
                                                  },
                                            child: const Text('No mapa'),
                                          )),
                            ),
                            if (pendente) ...[
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Aguardando aprovação para entrar na mesa',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  OutlinedButton(
                                    key: Key(
                                      'botao_recusar_jogador_${heroi.characterId}',
                                    ),
                                    onPressed: () =>
                                        cubit.atualizarStatusRevisaoFicha(
                                          heroi.characterId,
                                          StatusRevisaoFicha.recusada,
                                        ),
                                    child: const Text('Recusar'),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton.icon(
                                    key: Key(
                                      'botao_aprovar_jogador_${heroi.characterId}',
                                    ),
                                    icon: const Icon(Icons.check, size: 16),
                                    label: const Text('Aprovar'),
                                    onPressed: () =>
                                        cubit.atualizarStatusRevisaoFicha(
                                          heroi.characterId,
                                          StatusRevisaoFicha.aprovada,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }
}
