import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../domain/entities/combate/grid_tatico.dart';
import '../../../../domain/entities/mestre/modelos_mestre.dart';
import '../../../controllers/mestre_controller/mestre_cubit.dart';
import '../../../controllers/mestre_controller/mestre_state.dart';
import '../theme/mestre_theme.dart';
import 'mestre_battlemap_widget.dart';

/// Ferramenta ativa na Mesa de Jogo (Parte 4)
enum FerramentaMesa {
  selecionarMover('Selecionar / Mover', Icons.near_me_outlined),
  adicionarToken('Adicionar Token', Icons.person_add_alt_1_outlined),
  fogOfWar('Fog of War', Icons.cloud_outlined),
  medirDistancia('Medir Distância', Icons.straighten_outlined),
  pings('Pings e Marcadores', Icons.place_outlined),
  visao('Mestre ⇄ Jogador', Icons.visibility_outlined);

  final String rotulo;
  final IconData icone;
  const FerramentaMesa(this.rotulo, this.icone);
}

/// PARTE 4 — Tela "Mesa de jogo" (mapa selecionado) (Tormenta 20 - Android/Flutter)
/// Canvas ocupa quase toda a tela com UI mínima e translúcida.
class TelaMesaJogo extends StatefulWidget {
  final MestreState state;
  final MestreCubit cubit;
  final VoidCallback onVoltarBiblioteca;
  final void Function({String? condicaoParaToken})? onAbrirEscudoCondicoes;

  const TelaMesaJogo({
    super.key,
    required this.state,
    required this.cubit,
    required this.onVoltarBiblioteca,
    this.onAbrirEscudoCondicoes,
  });

  @override
  State<TelaMesaJogo> createState() => _TelaMesaJogoState();
}

class _TelaMesaJogoState extends State<TelaMesaJogo> {
  FerramentaMesa _ferramentaAtiva = FerramentaMesa.selecionarMover;
  bool _barraMobileExpandida = false;
  bool _fogModoRevelar = true; // true: revelar, false: ocultar

  @override
  Widget build(BuildContext context) {
    final mapaAtual = widget.state.mapaAtual;
    if (mapaAtual == null) {
      return Scaffold(
        backgroundColor: MestreCores.escuroBackground,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Nenhum mapa selecionado.', style: TextStyle(color: MestreCores.escuroOnSurface)),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: widget.onVoltarBiblioteca,
                child: const Text('Voltar à Biblioteca de Mapas'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // 1. O CANVAS DO MAPA OCUPA QUASE TODA A TELA
            Positioned.fill(
              child: GestureDetector(
                onTapUp: (details) {
                  // Se for ferramenta de medição ou pings, delega
                },
                child: MestreBattlemapWidget(
                  state: widget.state,
                  cubit: widget.cubit,
                ),
              ),
            ),

            // Medição de Distância (Overlay visual se ativo)
            if (_ferramentaAtiva == FerramentaMesa.medirDistancia &&
                widget.state.pontoOrigemMedicao != null &&
                widget.state.pontoDestinoMedicao != null)
              _buildOverlayMedicaoDistancia(context),

            // 2. TOPO TRANSLÚCIDO MÍNIMO
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: _buildBarraSuperiorTranslucida(context, mapaAtual),
            ),

            // 3. BARRA DE FERRAMENTAS RESPONSIVA
            if (MediaQuery.sizeOf(context).width >= 600)
              Positioned(
                left: 12,
                top: 80,
                bottom: 80,
                child: _buildBarraVerticalTablet(context),
              )
            else
              Positioned(
                bottom: 16,
                right: 16,
                child: _buildBarraFlutuanteMobile(context),
              ),

            // Sub-barra contextual do Fog of War
            if (_ferramentaAtiva == FerramentaMesa.fogOfWar)
              Positioned(
                bottom: 20,
                left: 20,
                child: _buildSubBarraFogOfWar(context, mapaAtual),
              ),
          ],
        ),
      ),
      bottomSheet: widget.state.tokenSelecionadoParaMoverId != null
          ? _buildSheetTokenSelecionado(context, mapaAtual)
          : null,
    );
  }

  // ---------------------------------------------------------------------------
  // BARRA SUPERIOR TRANSLÚCIDA
  // ---------------------------------------------------------------------------

  Widget _buildBarraSuperiorTranslucida(BuildContext context, MapaBatalhaMestre mapa) {
    final salaAberta = widget.state.statusLan != StatusConexaoLan.desligado;
    final conectados = widget.state.sessaoAtual?.elenco.where((e) => e.conectadoViaLan).length ?? 0;
    final total = widget.state.sessaoAtual?.elenco.length ?? 0;
    final corPonto = salaAberta ? MestreCores.statusOnlineEscuro : MestreCores.statusOffline;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: MestreCores.escuroSurface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8)],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: MestreCores.escuroOnSurface, size: 20),
            tooltip: 'Biblioteca de Mapas',
            onPressed: widget.onVoltarBiblioteca,
          ),
          const SizedBox(width: 4),
          // Seletor de Mapa
          Expanded(
            child: InkWell(
              onTap: () => _exibirSheetTrocarMapa(context),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        mapa.nome,
                        style: const TextStyle(
                          fontFamily: 'serif',
                          color: MestreCores.escuroOnSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: MestreCores.escuroOuro, size: 18),
                  ],
                ),
              ),
            ),
          ),

          // Indicador discreto da LAN (ponto + n/6)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: MestreCores.escuroSurfaceContainer,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: MestreCores.escuroOutline),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 7, color: corPonto),
                const SizedBox(width: 5),
                Text(
                  '$conectados/$total',
                  style: MestreCores.estiloMono.copyWith(color: MestreCores.escuroOnSurface, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Botão [Enviar mapa aos jogadores]
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: widget.state.enviandoMapaAosJogadores
                  ? MestreCores.escuroVinho
                  : MestreCores.escuroOuro,
              foregroundColor: widget.state.enviandoMapaAosJogadores
                  ? Colors.white
                  : MestreCores.escuroOuroTexto,
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: widget.state.enviandoMapaAosJogadores
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send_rounded, size: 14),
            label: Text(
              widget.state.enviandoMapaAosJogadores
                  ? 'Enviando…'
                  : (widget.state.ultimoEnvioMapa != null ? 'Enviado!' : 'Enviar aos jogadores'),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            onPressed: () => widget.cubit.enviarMapaAosJogadores(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BARRA DE FERRAMENTAS: TABLET (VERTICAL 56 DP)
  // ---------------------------------------------------------------------------

  Widget _buildBarraVerticalTablet(BuildContext context) {
    return Container(
      width: 56,
      decoration: BoxDecoration(
        color: MestreCores.escuroSurface.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: FerramentaMesa.values.map((f) {
          final sel = _ferramentaAtiva == f;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: IconButton(
              icon: Icon(f.icone, size: 22),
              color: sel ? MestreCores.escuroOuro : MestreCores.escuroOnSurfaceVariant,
              style: IconButton.styleFrom(
                backgroundColor: sel ? MestreCores.escuroVinho : Colors.transparent,
              ),
              tooltip: f.rotulo,
              onPressed: () => _selecionarFerramenta(f),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BARRA DE FERRAMENTAS: CELULAR (BOTÃO FLUTUANTE EXPANSÍVEL)
  // ---------------------------------------------------------------------------

  Widget _buildBarraFlutuanteMobile(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_barraMobileExpandida) ...[
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: MestreCores.escuroSurface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: FerramentaMesa.values.map((f) {
                final sel = _ferramentaAtiva == f;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: IconButton(
                    icon: Icon(f.icone, size: 20),
                    color: sel ? MestreCores.escuroOuro : MestreCores.escuroOnSurfaceVariant,
                    style: IconButton.styleFrom(
                      backgroundColor: sel ? MestreCores.escuroVinho : Colors.transparent,
                    ),
                    tooltip: f.rotulo,
                    onPressed: () {
                      _selecionarFerramenta(f);
                      setState(() => _barraMobileExpandida = false);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
        ],
        FloatingActionButton.small(
          backgroundColor: MestreCores.escuroOuro,
          foregroundColor: MestreCores.escuroOuroTexto,
          child: Icon(_barraMobileExpandida ? Icons.close : _ferramentaAtiva.icone),
          onPressed: () => setState(() => _barraMobileExpandida = !_barraMobileExpandida),
        ),
      ],
    );
  }

  void _selecionarFerramenta(FerramentaMesa f) {
    setState(() => _ferramentaAtiva = f);

    if (f == FerramentaMesa.selecionarMover) {
      widget.cubit.selecionarFerramentaMapa(FerramentaMapaMestre.moverPersonagens);
    } else if (f == FerramentaMesa.adicionarToken) {
      _exibirSheetCriarTokenCombatente(context);
    } else if (f == FerramentaMesa.fogOfWar) {
      widget.cubit.selecionarFerramentaMapa(FerramentaMapaMestre.nevoaDeGuerra);
    } else if (f == FerramentaMesa.visao) {
      widget.cubit.alternarVisaoMestreJogador();
    }
  }

  // ---------------------------------------------------------------------------
  // SUB-BARRA FOG OF WAR (REVELAR / OCULTAR / REVELAR TUDO / OCULTAR TUDO)
  // ---------------------------------------------------------------------------

  Widget _buildSubBarraFogOfWar(BuildContext context, MapaBatalhaMestre mapa) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: MestreCores.escuroSurface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ChoiceChip(
            label: const Text('Revelar', style: TextStyle(fontSize: 11)),
            selected: _fogModoRevelar,
            selectedColor: MestreCores.escuroOuro,
            onSelected: (_) => setState(() => _fogModoRevelar = true),
          ),
          const SizedBox(width: 6),
          ChoiceChip(
            label: const Text('Ocultar', style: TextStyle(fontSize: 11)),
            selected: !_fogModoRevelar,
            selectedColor: MestreCores.statusAlertaEscuro,
            onSelected: (_) => setState(() => _fogModoRevelar = false),
          ),
          const SizedBox(width: 10),
          TextButton.icon(
            icon: const Icon(Icons.wb_sunny_outlined, size: 14),
            label: const Text('Revelar tudo', style: TextStyle(fontSize: 11)),
            style: TextButton.styleFrom(foregroundColor: MestreCores.escuroOuro),
            onPressed: () => widget.cubit.revelarTodoMapa(),
          ),
          TextButton.icon(
            icon: const Icon(Icons.nights_stay_outlined, size: 14),
            label: const Text('Ocultar tudo', style: TextStyle(fontSize: 11)),
            style: TextButton.styleFrom(foregroundColor: MestreCores.escuroOnSurfaceVariant),
            onPressed: () => widget.cubit.ocultarTodoMapa(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // OVERLAY MEDIÇÃO DE DISTÂNCIA
  // ---------------------------------------------------------------------------

  Widget _buildOverlayMedicaoDistancia(BuildContext context) {
    final orig = widget.state.pontoOrigemMedicao!;
    final dest = widget.state.pontoDestinoMedicao!;
    final dx = (dest.x - orig.x).abs();
    final dy = (dest.y - orig.y).abs();
    final diagonais = min(dx, dy);
    final retas = (dx - dy).abs();
    final metros = (retas * 1.5) + (diagonais * 3.0); // Regra diagonal 3m T20

    return Positioned(
      bottom: 24,
      left: 20,
      right: 20,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: MestreCores.escuroSurface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: MestreCores.escuroOuro),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.straighten, color: MestreCores.escuroOuro, size: 20),
              const SizedBox(width: 10),
              Text(
                'Distância: ${metros.toStringAsFixed(1)} metros ($retas retas + $diagonais diag)',
                style: const TextStyle(
                  color: MestreCores.escuroOnSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.close, size: 16, color: MestreCores.escuroOnSurfaceVariant),
                onPressed: () => widget.cubit.limparMedicao(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SHEET: TOKEN SELECIONADO (PEQUENO E NÃO INVASIVO)
  // ---------------------------------------------------------------------------

  Widget _buildSheetTokenSelecionado(BuildContext context, MapaBatalhaMestre mapa) {
    final token = mapa.tokens.where((t) => t.id == widget.state.tokenSelecionadoParaMoverId).firstOrNull;
    if (token == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: MestreCores.escuroSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(color: MestreCores.escuroOutline),
        boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 14)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: token.ehHeroi ? MestreCores.escuroVinho : MestreCores.statusAlertaEscuro,
                radius: 18,
                child: Text(token.nome.substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(token.nome, style: const TextStyle(color: MestreCores.escuroOnSurface, fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(
                      'Defesa: ${token.defesa} • Desl: ${token.deslocamentoMetros}m • ${token.visivelParaJogadores ? "Visível a todos" : "Somente Mestre"}',
                      style: const TextStyle(color: MestreCores.escuroOnSurfaceVariant, fontSize: 11),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  token.visivelParaJogadores ? Icons.visibility : Icons.visibility_off,
                  size: 20,
                  color: token.visivelParaJogadores ? MestreCores.statusOnlineEscuro : MestreCores.statusAlertaEscuro,
                ),
                tooltip: 'Mostrar/Ocultar para jogadores',
                onPressed: () => widget.cubit.alternarVisibilidadeToken(token.id),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: MestreCores.statusAlertaEscuro),
                tooltip: 'Remover do mapa',
                onPressed: () => widget.cubit.removerTokenDoMapa(token.id),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // PV e PM com botões rápidos (+/-)
          Row(
            children: [
              Expanded(
                child: _buildAjustePontos('PV', token.pvAtual, token.pvMax, Colors.redAccent, (delta) {
                  widget.cubit.ajustarPvToken(token.id, delta);
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAjustePontos('PM', token.pmAtual, token.pmMax, Colors.blueAccent, (delta) {
                  widget.cubit.ajustarPmToken(token.id, delta);
                }),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Condições Ativas (chips)
          Row(
            children: [
              const Text('Condições: ', style: TextStyle(color: MestreCores.escuroOnSurfaceVariant, fontSize: 11)),
              Expanded(
                child: Wrap(
                  spacing: 4,
                  children: [
                    ...token.condicoes.map((c) => Chip(
                          label: Text(c, style: const TextStyle(fontSize: 10)),
                          visualDensity: VisualDensity.compact,
                          onDeleted: () => widget.cubit.removerCondicaoToken(token.id, c),
                        )),
                    ActionChip(
                      label: const Text('+ Condição', style: TextStyle(fontSize: 10, color: MestreCores.escuroOuro)),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _exibirDialogAdicionarCondicao(context, token),
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

  Widget _buildAjustePontos(String rotulo, int atual, int max, Color cor, ValueChanged<int> onDelta) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: MestreCores.escuroSurfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$rotulo: $atual/$max', style: TextStyle(color: cor, fontSize: 12, fontWeight: FontWeight.bold)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () => onDelta(-1),
                child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.remove, size: 16, color: Colors.white70)),
              ),
              InkWell(
                onTap: () => onDelta(1),
                child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.add, size: 16, color: Colors.white70)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SHEET: CRIAR INIMIGO / NPC (PARTE 4)
  // ---------------------------------------------------------------------------

  void _exibirSheetCriarTokenCombatente(BuildContext context) {
    final nomeController = TextEditingController(text: 'Ameaça de Arton');
    final pvController = TextEditingController(text: '20');
    final pmController = TextEditingController(text: '10');
    final defController = TextEditingController(text: '15');
    final iniController = TextEditingController(text: '10');
    TipoCombatenteMapa tipo = TipoCombatenteMapa.inimigo;
    int tamanho = 1;
    bool visivelAosJogadores = false;
    int duplicarN = 1;

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Adicionar Combatente ao Mapa', style: TextStyle(fontFamily: 'serif', color: MestreCores.escuroOnSurface, fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close, color: MestreCores.escuroOnSurfaceVariant, size: 20), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 10),

              // Segmented Button: Inimigo / NPC / Aliado
              SegmentedButton<TipoCombatenteMapa>(
                segments: const [
                  ButtonSegment(value: TipoCombatenteMapa.inimigo, label: Text('Inimigo')),
                  ButtonSegment(value: TipoCombatenteMapa.npc, label: Text('NPC')),
                  ButtonSegment(value: TipoCombatenteMapa.aliado, label: Text('Aliado')),
                ],
                selected: {tipo},
                onSelectionChanged: (val) => setSheetState(() => tipo = val.first),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: nomeController,
                style: const TextStyle(color: MestreCores.escuroOnSurface, fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Nome da Criatura/NPC',
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: MestreCores.escuroOutline)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: MestreCores.escuroOuro)),
                ),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: pvController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: MestreCores.escuroOnSurface, fontSize: 12),
                      decoration: const InputDecoration(labelText: 'PV', enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: MestreCores.escuroOutline))),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: pmController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: MestreCores.escuroOnSurface, fontSize: 12),
                      decoration: const InputDecoration(labelText: 'PM', enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: MestreCores.escuroOutline))),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: defController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: MestreCores.escuroOnSurface, fontSize: 12),
                      decoration: const InputDecoration(labelText: 'Defesa', enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: MestreCores.escuroOutline))),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: iniController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: MestreCores.escuroOnSurface, fontSize: 12),
                      decoration: const InputDecoration(labelText: 'Iniciativa', enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: MestreCores.escuroOutline))),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Tamanho em Quadrados
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tamanho do Token:', style: TextStyle(color: MestreCores.escuroOnSurface, fontSize: 12)),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('1×1 Médio'),
                        selected: tamanho == 1,
                        onSelected: (_) => setSheetState(() => tamanho = 1),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('2×2 Grande'),
                        selected: tamanho == 2,
                        onSelected: (_) => setSheetState(() => tamanho = 2),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('3×3 Enorme'),
                        selected: tamanho == 3,
                        onSelected: (_) => setSheetState(() => tamanho = 3),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text('Visível aos Jogadores', style: TextStyle(color: MestreCores.escuroOnSurface, fontSize: 12)),
                value: visivelAosJogadores,
                activeThumbColor: MestreCores.escuroOuro,
                onChanged: (val) => setSheetState(() => visivelAosJogadores = val),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Duplicar × N para grupos:', style: TextStyle(color: MestreCores.escuroOnSurface, fontSize: 12)),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 16, color: MestreCores.escuroOuro),
                        onPressed: duplicarN > 1 ? () => setSheetState(() => duplicarN--) : null,
                      ),
                      Text('$duplicarN', style: const TextStyle(color: MestreCores.escuroOnSurface, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add, size: 16, color: MestreCores.escuroOuro),
                        onPressed: duplicarN < 8 ? () => setSheetState(() => duplicarN++) : null,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: MestreCores.escuroOuro,
                  foregroundColor: MestreCores.escuroOuroTexto,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () {
                  final pv = int.tryParse(pvController.text) ?? 20;
                  final pm = int.tryParse(pmController.text) ?? 10;
                  final def = int.tryParse(defController.text) ?? 15;
                  final ini = int.tryParse(iniController.text);
                  final nomeBase = nomeController.text.trim().isEmpty ? 'Ameaça' : nomeController.text.trim();

                  for (int i = 0; i < duplicarN; i++) {
                    final nomeFinal = duplicarN > 1 ? '$nomeBase #${i + 1}' : nomeBase;
                    widget.cubit.adicionarTokenCustomizadoNoMapa(
                      nome: nomeFinal,
                      ehHeroi: tipo == TipoCombatenteMapa.heroi || tipo == TipoCombatenteMapa.aliado,
                      tipo: tipo,
                      pvMax: pv,
                      pmMax: pm,
                      defesa: def,
                      iniciativa: ini,
                      tamanhoQuadrados: tamanho,
                      ocultoParaJogadores: !visivelAosJogadores,
                      posicao: Posicao2D((i + 2) % 12, 1),
                    );
                  }
                  Navigator.pop(ctx);
                },
                child: Text('Adicionar ($duplicarN)', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _exibirDialogAdicionarCondicao(BuildContext context, TokenNoMapa token) {
    const condicoesComuns = [
      'Abalado',
      'Caído',
      'Cego',
      'Desprevenido',
      'Enfeitiçado',
      'Fatigado',
      'Furtivo',
      'Imobilizado',
      'Inconsciente',
      'Lento',
      'Sangrando',
      'Surpreendido',
      'Vulnerável',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: MestreCores.escuroSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Aplicar Condição T20', style: TextStyle(fontFamily: 'serif', color: MestreCores.escuroOnSurface, fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: condicoesComuns.map((c) {
                return ActionChip(
                  label: Text(c, style: const TextStyle(fontSize: 11)),
                  onPressed: () {
                    widget.cubit.adicionarCondicaoToken(token.id, c);
                    Navigator.pop(ctx);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _exibirSheetTrocarMapa(BuildContext context) {
    final aventura = widget.state.aventuraAtual;
    showModalBottomSheet(
      context: context,
      backgroundColor: MestreCores.escuroSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Trocar Mapa Ativo', style: TextStyle(fontFamily: 'serif', color: MestreCores.escuroOnSurface, fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...(aventura?.mapas ?? []).map((m) => ListTile(
                  title: Text(m.nome, style: const TextStyle(color: MestreCores.escuroOnSurface)),
                  subtitle: Text('${m.largura}×${m.altura} • ${m.tokens.length} combatentes', style: const TextStyle(color: MestreCores.escuroOnSurfaceVariant, fontSize: 11)),
                  trailing: m.id == widget.state.mapaAtual?.id ? const Icon(Icons.check, color: MestreCores.escuroOuro) : null,
                  onTap: () {
                    widget.cubit.selecionarMapa(m.id);
                    Navigator.pop(ctx);
                  },
                )),
          ],
        ),
      ),
    );
  }
}
