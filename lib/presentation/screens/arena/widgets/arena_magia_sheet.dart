import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../domain/entities/combate/combatente.dart';
import '../../../../domain/entities/combate/efeito_ativo_combate.dart';
import '../../../../domain/entities/combate/grid_tatico.dart';
import '../../../../domain/entities/habilidades/modelos_habilidade_duracao.dart';
import '../../../../domain/entities/magia/magia.dart';
import '../../../../domain/services/combate_services/arena_stats_collector.dart';
import '../../../../domain/services/combate_services/dice_roll_service.dart';
import '../../../../domain/services/data_services/call_magias.dart';
import '../../../controllers/combate_controller/combate_cubit.dart';
import '../../../widgets/app_safe_scaffold.dart';

/// Modal bottom sheet para gerenciamento e lançamento de magias no Modo Arena.
///
/// Implementa a filosofia do Foundry VTT / Sistema de Honestidade:
/// 1. Card completo da magia com metadados (Execução, Alcance métrico, Duração, CD).
/// 2. Seletor de PM utilizado (permitindo aprimoramentos e círculos maiores).
/// 3. Visualização interativa de Alcance e Área de Efeito (Cone, Círculo/Esfera, Cubo/Quadrado, Linha).
/// 4. Botão "Ativar Efeito" para registrar buffs ativos com duração e bônus.
/// 5. Rolagem de dano/cura configurável por tipo de dado (d2..d100), quantidade e modificador.
class ArenaMagiaSheet extends StatefulWidget {
  static const List<int> tiposDadosSuportados = [2, 4, 6, 8, 10, 12, 20, 100];
  static const List<double> tamanhosAreaMetrosSuportados = [
    1.5,
    3.0,
    4.5,
    6.0,
    9.0,
    12.0,
    15.0,
  ];

  final Combatente heroi;
  final List<Combatente> todos;
  final CombateCubit cubit;
  final ArenaStatsCollector? stats;
  final DiceRollService? diceRollService;

  const ArenaMagiaSheet({
    super.key,
    required this.heroi,
    required this.todos,
    required this.cubit,
    this.stats,
    this.diceRollService,
  });

  static Future<void> exibir(
    BuildContext context, {
    required Combatente heroi,
    required List<Combatente> todos,
    required CombateCubit cubit,
    ArenaStatsCollector? stats,
    DiceRollService? diceRollService,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => ArenaMagiaSheet(
        heroi: heroi,
        todos: todos,
        cubit: cubit,
        stats: stats,
        diceRollService: diceRollService,
      ),
    );
  }

  @override
  State<ArenaMagiaSheet> createState() => _ArenaMagiaSheetState();
}

class _ArenaMagiaSheetState extends State<ArenaMagiaSheet> {
  static final RegExp _regexDadoDescricao = RegExp(
    r'(\d+)\s*d\s*(2|4|6|8|10|12|20|100)(?:\s*([+-])\s*(\d+))?\b',
    caseSensitive: false,
  );

  late final DiceRollService _roller;
  Magia? _magiaSelecionada;
  Combatente? _alvo;

  // Configuração de Área de Efeito e Ponto de Mira no Grid
  TipoArea? _tipoAreaEscolhida; // null = Alvo Único
  double _tamanhoAreaMetros = 6.0;
  Posicao2D? _pontoAlvoGrid;
  VerticeGrid? _verticeAlvoGrid;
  PreviewMagiaCombate? _previewAtual;

  // Configuração de PM, Dados e Modificador de Dano/Cura
  int _pmEscolhido = 1;
  int _qtdDados = 2;
  int _tipoDado = 6;
  int _modificadorDano = 0;

  // Campos para Ativar Efeito
  int _bonusAtqEfeito = 0;
  int _bonusDanoEfeito = 0;
  int _duracaoRodadas = 10;

  String get _expressaoDadosFormatada {
    final base = '${_qtdDados}d$_tipoDado';
    if (_modificadorDano > 0) return '$base+$_modificadorDano';
    if (_modificadorDano < 0) return '$base$_modificadorDano';
    return base;
  }

  bool get _usaCentroVertice =>
      _tipoAreaEscolhida == TipoArea.esfera ||
      _tipoAreaEscolhida == TipoArea.cilindro;

  String _rotuloTipoArea(TipoArea? tipo) {
    return switch (tipo) {
      null => 'Alvo Único',
      TipoArea.cone => 'Cone',
      TipoArea.esfera => 'Esfera (Raio)',
      TipoArea.cilindro => 'Cilindro',
      TipoArea.cubo || TipoArea.quadrado => 'Cubo / Quadrado',
      TipoArea.linha => 'Linha',
      TipoArea.outro => 'Área',
    };
  }

  String _rotuloDirecao(({int dx, int dy}) dir) {
    return switch ((dir.dx, dir.dy)) {
      (1, 0) => '→ Reta (L)',
      (-1, 0) => '← Reta (O)',
      (0, 1) => '↓ Reta (S)',
      (0, -1) => '↑ Reta (N)',
      (1, 1) => '↘ Diagonal (SE)',
      (-1, 1) => '↙ Diagonal (SO)',
      (1, -1) => '↗ Diagonal (NE)',
      _ => '↖ Diagonal (NO)',
    };
  }

  String _formatarMetros(double metros) {
    if (metros == metros.roundToDouble()) {
      return '${metros.toInt()}m';
    }
    return '${metros.toStringAsFixed(1).replaceAll('.', ',')}m';
  }

  String get _resumoAreaFormatado {
    if (_tipoAreaEscolhida == null) return 'Alvo Único';
    final qtdQuad = (_tamanhoAreaMetros / kMetrosPorQuadradoT20).round();
    final detalheQuad =
        (_tipoAreaEscolhida == TipoArea.cubo ||
            _tipoAreaEscolhida == TipoArea.quadrado)
        ? ' (${qtdQuad}x$qtdQuad = ${qtdQuad * qtdQuad}q)'
        : ' (${qtdQuad}q)';
    return '${_rotuloTipoArea(_tipoAreaEscolhida)} ${_formatarMetros(_tamanhoAreaMetros)}$detalheQuad';
  }

  @override
  void initState() {
    super.initState();
    _roller = widget.diceRollService ?? DiceRollService();
    final inimigos = widget.todos
        .where((c) => c.time == TimeCombatente.inimigo && c.pvAtual > 0)
        .toList();
    _alvo = inimigos.isNotEmpty ? inimigos.first : widget.todos.first;
    if (_alvo != null) {
      _pontoAlvoGrid = widget.cubit.state.posicoesCombatentes[_alvo!.id];
    }
  }

  @override
  void dispose() {
    widget.cubit.limparPreviewMagia();
    super.dispose();
  }

  void _recalcularESincronizarPreview() {
    final magia = _magiaSelecionada;
    if (magia == null) {
      _previewAtual = null;
      widget.cubit.limparPreviewMagia();
      return;
    }

    final posAlvo =
        _pontoAlvoGrid ??
        (_alvo != null
            ? widget.cubit.state.posicoesCombatentes[_alvo!.id]
            : null) ??
        widget.cubit.state.posicoesCombatentes[widget.heroi.id] ??
        const Posicao2D(0, 0);

    final preview = widget.cubit.calcularPreviewMagia(
      magia: magia,
      tipoAreaOverride: _tipoAreaEscolhida,
      tamanhoMetrosOverride: _tipoAreaEscolhida != null
          ? _tamanhoAreaMetros
          : null,
      pontoAlvo: posAlvo,
      verticeAlvo: _usaCentroVertice ? _verticeAlvoGrid : null,
    );
    _previewAtual = preview;
    widget.cubit.atualizarPreviewMagia(
      celulasAlcance: preview.celulasAlcance,
      celulasArea: preview.celulasArea,
      centroVertice: preview.centroVertice,
    );
  }

  int _calcularCdMagia() {
    if (widget.heroi is CombatenteJogador) {
      final jogador = widget.heroi as CombatenteJogador;
      final modInt = jogador.ficha.getValorFinal('INT');
      final modSab = jogador.ficha.getValorFinal('SAB');
      final modCar = jogador.ficha.getValorFinal('CAR');
      final modChave = max(modInt, max(modSab, modCar));
      return 10 + (jogador.ficha.nivelPersonagem ~/ 2) + modChave;
    }
    return 12;
  }

  void _selecionarMagia(Magia magia) {
    final custoBase = widget.cubit.calcularCustoPmMagia(magia);
    final matchDado = _regexDadoDescricao.firstMatch(magia.descricao);
    final qtdSugerida = matchDado != null
        ? (int.tryParse(matchDado.group(1)!) ?? 2).clamp(1, 30)
        : 2;
    final faceSugerida = matchDado != null
        ? (int.tryParse(matchDado.group(2)!) ?? 6)
        : 6;
    int modSugerido = 0;
    if (matchDado != null &&
        matchDado.group(3) != null &&
        matchDado.group(4) != null) {
      final sinal = matchDado.group(3) == '-' ? -1 : 1;
      modSugerido = (sinal * (int.tryParse(matchDado.group(4)!) ?? 0)).clamp(
        -50,
        99,
      );
    }

    final areaPadrao = magia.efeito.extrairAreaPadrao(
      alcanceDetalhes: magia.alcance.detalhes,
    );
    final double metrosPadrao = areaPadrao != null
        ? areaPadrao.tamanhoMetros
        : 6.0;
    final double metrosNormalizado =
        ArenaMagiaSheet.tamanhosAreaMetrosSuportados.contains(metrosPadrao)
        ? metrosPadrao
        : 6.0;

    final posAlvoInicial =
        (_alvo != null
            ? widget.cubit.state.posicoesCombatentes[_alvo!.id]
            : null) ??
        widget.cubit.state.posicoesCombatentes[widget.heroi.id] ??
        const Posicao2D(0, 0);
    final mapa = widget.cubit.state.mapaGrid;

    setState(() {
      _magiaSelecionada = magia;
      _pmEscolhido = max(1, custoBase);
      _qtdDados = qtdSugerida;
      _tipoDado = ArenaMagiaSheet.tiposDadosSuportados.contains(faceSugerida)
          ? faceSugerida
          : 6;
      _modificadorDano = modSugerido;
      _tipoAreaEscolhida = areaPadrao?.tipo;
      _tamanhoAreaMetros = metrosNormalizado;
      _pontoAlvoGrid = posAlvoInicial;
      _verticeAlvoGrid = VerticeGrid(
        posAlvoInicial.x.clamp(1, max(1, mapa.largura - 1)),
        posAlvoInicial.y.clamp(1, max(1, mapa.altura - 1)),
      );

      // Heurística de sugestão de bônus para buffs comuns como Arma de Jade
      if (magia.nome.toLowerCase().contains('jade') ||
          magia.nome.toLowerCase().contains('arma')) {
        _bonusAtqEfeito = 1;
        _bonusDanoEfeito = 1;
      } else if (magia.nome.toLowerCase().contains('bênção') ||
          magia.nome.toLowerCase().contains('bencao')) {
        _bonusAtqEfeito = 1;
        _bonusDanoEfeito = 0;
      } else {
        _bonusAtqEfeito = 0;
        _bonusDanoEfeito = 0;
      }
      _recalcularESincronizarPreview();
    });
  }

  void _ativarEfeitoBuff(int custoPm) {
    final magia = _magiaSelecionada!;
    final efeito = EfeitoAtivoCombate(
      id: '${magia.id}_${DateTime.now().millisecondsSinceEpoch}',
      nome: magia.nome,
      descricaoEfeito: magia.descricao,
      bonusAtaque: _bonusAtqEfeito,
      bonusDano: _bonusDanoEfeito,
      rodadasRestantes: _duracaoRodadas,
      combatenteId: widget.heroi.id,
    );

    widget.stats?.registrarMagia(custoPm: custoPm);
    widget.cubit.adicionarEfeitoAtivo(efeito, custoPm: custoPm);
    Navigator.pop(context);
  }

  void _copiarParaOLog(int custoPm) {
    final magia = _magiaSelecionada!;
    final log =
        '📜 [Grimório] ${widget.heroi.nome} consultou/ativou ${magia.nome} (Círculo ${magia.circulo} • ${magia.escola} • Custo $custoPm PM): ${magia.descricao}';
    widget.cubit.aplicarAjusteVtt(
      combatenteId: widget.heroi.id,
      valor: 0,
      motivo: log,
    );
  }

  void _lancarMagiaDanoOuCura(
    int custoPm,
    bool ehCura, {
    bool ehMetade = false,
  }) {
    final magia = _magiaSelecionada!;
    final rolagem = _roller.rolarDano(expressaoDano: _expressaoDadosFormatada);
    final valorTotal = rolagem.total;
    final valorAplicado = ehMetade ? (valorTotal / 2).floor() : valorTotal;
    final resumoRolagem = ehMetade
        ? '${rolagem.decomposicao} (Metade: $valorAplicado)'
        : rolagem.decomposicao;

    final ehEmArea = _tipoAreaEscolhida != null;
    final alvosNaArea = ehEmArea
        ? (_previewAtual?.alvosAfetados ?? const <Combatente>[])
        : null;

    widget.stats?.registrarMagia(
      custoPm: custoPm,
      dano: ehCura ? 0 : valorAplicado * (ehEmArea ? max(1, alvosNaArea!.length) : 1),
    );
    Navigator.pop(context);
    widget.cubit.lancarMagia(
      magia: magia,
      alvo: ehEmArea ? null : _alvo,
      alvosAfetados: ehEmArea ? alvosNaArea : null,
      valorDanoOuCura: valorAplicado,
      ehCura: ehCura,
      custoPmOverride: custoPm,
      resumoRolagem: resumoRolagem,
      resumoArea: ehEmArea ? _resumoAreaFormatado : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final magiasIds = widget.heroi is CombatenteJogador
        ? (widget.heroi as CombatenteJogador).ficha.magiasConhecidas
        : <String>[];

    if (magiasIds.isEmpty) {
      return AppBottomSheetContainer(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_stories, size: 48, color: Colors.white38),
            const SizedBox(height: 12),
            Text(
              'Este personagem não conhece nenhuma magia.',
              style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final magias = magiasIds.map((id) => BancoDeMagias.getById(id)).toList();

    return AppBottomSheetContainer(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Topo: Cabeçalho com PM e CD
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: Colors.indigoAccent,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Grimório de Magias (PM: ${widget.heroi.pmAtual}/${widget.heroi.pmMax})',
                    style: textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  tooltip: 'Fechar',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 16),

            // Se nenhuma magia selecionada: exibe a lista
            if (_magiaSelecionada == null) ...[
              Text(
                'Selecione uma magia para usar ou consultar:',
                style: textTheme.bodySmall?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 10),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: magias.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (ctx, idx) {
                  final magia = magias[idx];
                  final custo = widget.cubit.calcularCustoPmMagia(magia);
                  final temPm = widget.heroi.pmAtual >= custo;

                  return ListTile(
                    tileColor: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    leading: CircleAvatar(
                      backgroundColor: temPm
                          ? Colors.indigo
                          : Colors.grey.shade800,
                      child: Text(
                        '${magia.circulo}º',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      magia.nome,
                      style: TextStyle(
                        color: temPm ? Colors.white : Colors.white38,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'Custo: $custo PM • ${magia.escola} • Alcance: ${magia.alcance.tipo}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.white38,
                    ),
                    onTap: () => _selecionarMagia(magia),
                  );
                },
              ),
            ] else ...[
              // Card da Magia Selecionada
              _buildCardMagiaDetalhado(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCardMagiaDetalhado(BuildContext context) {
    final magia = _magiaSelecionada!;
    final custoBase = widget.cubit.calcularCustoPmMagia(magia);
    final custo = _pmEscolhido;
    final temPm = widget.heroi.pmAtual >= custo;
    final alcanceMetros = widget.cubit.calcularAlcanceMetrosMagia(
      magia.alcance,
    );
    final cdMagia = _calcularCdMagia();
    final ehCura =
        magia.escola.toLowerCase().contains('cura') ||
        magia.nome.toLowerCase().contains('curar');
    final expressaoDados = _expressaoDadosFormatada;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Botão Voltar para a Lista
        TextButton.icon(
          icon: const Icon(
            Icons.arrow_back,
            size: 16,
            color: Colors.indigoAccent,
          ),
          label: const Text(
            'Voltar para a Lista de Magias',
            style: TextStyle(color: Colors.indigoAccent),
          ),
          onPressed: () {
            setState(() {
              _magiaSelecionada = null;
              _previewAtual = null;
            });
            widget.cubit.limparPreviewMagia();
          },
        ),
        const SizedBox(height: 6),

        // Cabeçalho da Magia
        Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.indigo,
              child: Text(
                '${magia.circulo}º',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    magia.nome,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${magia.escola} • Base: $custoBase PM • Usando: $custo PM (CD $cdMagia)',
                    style: const TextStyle(
                      color: Colors.amberAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Badges de Metadados
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _buildBadge('Execução', magia.execucao.tipo),
            _buildBadge(
              'Alcance',
              '${magia.alcance.tipo} (${alcanceMetros.toStringAsFixed(1)}m)',
            ),
            _buildBadge(
              'Área / Efeito',
              magia.efeito.descricao?.isNotEmpty == true
                  ? magia.efeito.descricao!
                  : _resumoAreaFormatado,
            ),
            _buildBadge('Duração', magia.duracao.tipo),
            _buildBadge(
              'Resistência',
              magia.resistencia?.tipoTeste != null
                  ? '${magia.resistencia!.tipoTeste} (${magia.resistencia!.resultadoSucesso})'
                  : 'Nenhuma',
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Descrição da Magia e Aprimoramentos (+X PM / Truque)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          constraints: BoxConstraints(
            maxHeight: magia.aprimoramentos.isNotEmpty ? 190 : 140,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white12),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  magia.descricao,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                if (magia.aprimoramentos.isNotEmpty) ...[
                  const Divider(color: Colors.white12, height: 16),
                  const Text(
                    'Aprimoramentos:',
                    style: TextStyle(
                      color: Colors.amberAccent,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...magia.aprimoramentos.map((ap) {
                    final prefixo = ap.isTruque
                        ? 'Truque (0 PM): '
                        : '+${ap.custoAdicionalPM} PM: ';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: prefixo,
                              style: const TextStyle(
                                color: Colors.amberAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 11.5,
                              ),
                            ),
                            TextSpan(
                              text: ap.descricao,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11.5,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Seletor de PM a gastar (base + aprimoramentos/círculos maiores)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: temPm
                  ? Colors.amberAccent.withValues(alpha: 0.35)
                  : Colors.redAccent.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.bolt, color: Colors.amberAccent, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PM a utilizar no lançamento',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                    Text(
                      'Base do ${magia.circulo}º círculo: $custoBase PM • Disponível: ${widget.heroi.pmAtual} PM',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: const Key('btn_diminuir_pm_magia'),
                icon: const Icon(Icons.remove_circle_outline, size: 20),
                color: Colors.white70,
                onPressed: _pmEscolhido > 1
                    ? () => setState(() => _pmEscolhido--)
                    : null,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$_pmEscolhido PM',
                  key: const Key('txt_pm_escolhido_magia'),
                  style: TextStyle(
                    color: temPm ? Colors.amberAccent : Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              IconButton(
                key: const Key('btn_aumentar_pm_magia'),
                icon: const Icon(Icons.add_circle_outline, size: 20),
                color: Colors.white70,
                onPressed: _pmEscolhido < 50
                    ? () => setState(() => _pmEscolhido++)
                    : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Seletor de Alvo + Visualizador Tático de Alcance e Área de Efeito (Cone, Círculo, Cubo, Linha)
        _buildSecaoAlcanceEArea(context, magia, alcanceMetros),
        const SizedBox(height: 12),

        // -------------------------------------------------------------
        // PILARES FOUNDRY VTT: Ativar Efeito vs Lançar Magia vs Copiar
        // -------------------------------------------------------------
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.purpleAccent.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.auto_fix_high,
                    size: 16,
                    color: Colors.purpleAccent,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Opção 1: Ativar como Efeito / Buff Ativo',
                    style: TextStyle(
                      color: Colors.purpleAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Bônus Atq: ',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.remove,
                          size: 16,
                          color: Colors.white70,
                        ),
                        onPressed: () => setState(() => _bonusAtqEfeito--),
                      ),
                      Text(
                        '+$_bonusAtqEfeito',
                        style: const TextStyle(
                          color: Colors.amberAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add,
                          size: 16,
                          color: Colors.white70,
                        ),
                        onPressed: () => setState(() => _bonusAtqEfeito++),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Bônus Dano: ',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.remove,
                          size: 16,
                          color: Colors.white70,
                        ),
                        onPressed: () => setState(() => _bonusDanoEfeito--),
                      ),
                      Text(
                        '+$_bonusDanoEfeito',
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add,
                          size: 16,
                          color: Colors.white70,
                        ),
                        onPressed: () => setState(() => _bonusDanoEfeito++),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Duração: ',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.remove,
                          size: 16,
                          color: Colors.white70,
                        ),
                        onPressed: _duracaoRodadas > 1
                            ? () => setState(() => _duracaoRodadas--)
                            : null,
                      ),
                      Text(
                        '$_duracaoRodadas r',
                        style: const TextStyle(
                          color: Colors.lightBlueAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add,
                          size: 16,
                          color: Colors.white70,
                        ),
                        onPressed: () => setState(() => _duracaoRodadas++),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: temPm
                        ? Colors.purple.shade700
                        : Colors.grey.shade800,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(
                    temPm
                        ? '✨ Ativar Efeito ($custo PM)'
                        : 'PM Insuficiente ($custo PM)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: temPm ? () => _ativarEfeitoBuff(custo) : null,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Opção 2: Dano ou Cura por Rolagem de Dados Configurável
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ehCura
                          ? '💚 Opção 2: Rolar e Aplicar Cura'
                          : '💥 Opção 2: Rolar e Aplicar Dano',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.indigoAccent),
                    ),
                    child: Text(
                      '🎲 $expressaoDados',
                      key: const Key('txt_expressao_dados_magia'),
                      style: const TextStyle(
                        color: Colors.cyanAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Tipo de Dado:',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: ArenaMagiaSheet.tiposDadosSuportados.map((faces) {
                  final selecionado = _tipoDado == faces;
                  return ChoiceChip(
                    key: Key('chip_dado_d$faces'),
                    label: Text('d$faces'),
                    selected: selecionado,
                    selectedColor: Colors.indigo,
                    backgroundColor: const Color(0xFF1E293B),
                    labelStyle: TextStyle(
                      color: selecionado ? Colors.white : Colors.white70,
                      fontWeight: selecionado
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 12,
                    ),
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) => setState(() => _tipoDado = faces),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text(
                    'Quantidade de Dados:',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    key: const Key('btn_diminuir_qtd_dados_magia'),
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    color: Colors.white70,
                    onPressed: _qtdDados > 1
                        ? () => setState(() => _qtdDados--)
                        : null,
                  ),
                  Container(
                    constraints: const BoxConstraints(minWidth: 36),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$_qtdDados',
                      key: const Key('txt_qtd_dados_magia'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('btn_aumentar_qtd_dados_magia'),
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    color: Colors.white70,
                    onPressed: _qtdDados < 30
                        ? () => setState(() => _qtdDados++)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    ehCura ? 'Modificador de Cura:' : 'Modificador de Dano:',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    key: const Key('btn_diminuir_mod_dano_magia'),
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    color: Colors.white70,
                    onPressed: _modificadorDano > -50
                        ? () => setState(() => _modificadorDano--)
                        : null,
                  ),
                  Container(
                    constraints: const BoxConstraints(minWidth: 44),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _modificadorDano >= 0
                          ? '+$_modificadorDano'
                          : '$_modificadorDano',
                      key: const Key('txt_mod_dano_magia'),
                      style: TextStyle(
                        color: _modificadorDano > 0
                            ? Colors.greenAccent
                            : (_modificadorDano < 0
                                  ? Colors.redAccent
                                  : Colors.white70),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('btn_aumentar_mod_dano_magia'),
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    color: Colors.white70,
                    onPressed: _modificadorDano < 99
                        ? () => setState(() => _modificadorDano++)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        key: const Key('btn_rolar_magia_total'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: temPm
                              ? Colors.indigo
                              : Colors.grey.shade800,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: temPm
                            ? () => _lancarMagiaDanoOuCura(custo, ehCura)
                            : null,
                        child: Text(
                          () {
                            final qtdAlvos = _tipoAreaEscolhida != null
                                ? (_previewAtual?.alvosAfetados.length ?? 0)
                                : 1;
                            final sufixoAlvos = _tipoAreaEscolhida != null
                                ? ' ($qtdAlvos alvo${qtdAlvos == 1 ? '' : 's'} • $expressaoDados • $custo PM)'
                                : ' ($expressaoDados • $custo PM)';
                            return ehCura
                                ? 'Rolar Cura$sufixoAlvos'
                                : 'Dano Total$sufixoAlvos';
                          }(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  if (!ehCura &&
                      (_alvo != null || _tipoAreaEscolhida != null)) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          key: const Key('btn_rolar_magia_metade'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orangeAccent,
                            side: const BorderSide(color: Colors.orangeAccent),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: temPm
                              ? () => _lancarMagiaDanoOuCura(
                                  custo,
                                  ehCura,
                                  ehMetade: true,
                                )
                              : null,
                          child: Text(
                            'Metade ($custo PM)',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Opção 3: Copiar para o Log
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: const BorderSide(color: Colors.white24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.content_copy, size: 16),
            label: const Text('📋 Copiar Descrição para o Log'),
            onPressed: () => _copiarParaOLog(custo),
          ),
        ),
      ],
    );
  }

  Widget _buildSecaoAlcanceEArea(
    BuildContext context,
    Magia magia,
    double alcanceMetros,
  ) {
    final opcoesForma = <TipoArea?>[
      null,
      TipoArea.cone,
      TipoArea.esfera,
      TipoArea.cilindro,
      TipoArea.cubo,
      TipoArea.linha,
    ];
    final preview = _previewAtual;
    final alvosNaArea = preview?.alvosAfetados ?? const <Combatente>[];
    final qtdQuadradosArea = preview?.celulasArea.length ?? 0;
    final qtdBloqueados = preview?.celulasBloqueadas.length ?? 0;
    final direcao = preview?.direcaoAplicada;
    final mapa = widget.cubit.state.mapaGrid;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.amberAccent.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.grid_on, size: 16, color: Colors.amberAccent),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Alcance e Área de Efeito (T20)',
                  style: TextStyle(
                    color: Colors.amberAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                _resumoAreaFormatado,
                key: const Key('txt_resumo_area_magia'),
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Seletor de Alvo / Direção Principal
          if (magia.alcance.tipo.toLowerCase() != 'pessoal' ||
              _tipoAreaEscolhida != null) ...[
            const Text(
              '🎯 Alvo / Direção de Referência:',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
                fontSize: 11.5,
              ),
            ),
            const SizedBox(height: 4),
            DropdownButton<Combatente>(
              isExpanded: true,
              dropdownColor: const Color(0xFF0F172A),
              value: _alvo,
              items: widget.todos.map((c) {
                final pos = widget.cubit.state.posicoesCombatentes[c.id];
                final coord = pos != null ? ' [${pos.x},${pos.y}]' : '';
                return DropdownMenuItem(
                  value: c,
                  child: Text(
                    '${c.nome}$coord (${c.pvAtual}/${c.pvMax} PV)',
                    style: const TextStyle(color: Colors.white, fontSize: 12.5),
                  ),
                );
              }).toList(),
              onChanged: (novo) {
                if (novo != null) {
                  setState(() {
                    _alvo = novo;
                    final posNovo =
                        widget.cubit.state.posicoesCombatentes[novo.id];
                    if (posNovo != null) {
                      _pontoAlvoGrid = posNovo;
                      _verticeAlvoGrid = VerticeGrid(
                        posNovo.x.clamp(1, max(1, mapa.largura - 1)),
                        posNovo.y.clamp(1, max(1, mapa.altura - 1)),
                      );
                    }
                    _recalcularESincronizarPreview();
                  });
                }
              },
            ),
            const SizedBox(height: 8),
          ],

          // Formato da Área (Alvo Único, Cone, Esfera, Cilindro, Cubo/Quadrado, Linha)
          const Text(
            'Formato da Área:',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: opcoesForma.map((forma) {
              final selecionado = _tipoAreaEscolhida == forma;
              final keyName = forma?.name ?? 'alvo';
              return ChoiceChip(
                key: Key('chip_forma_area_$keyName'),
                label: Text(_rotuloTipoArea(forma)),
                selected: selecionado,
                selectedColor: Colors.amber.shade800,
                backgroundColor: const Color(0xFF1E293B),
                labelStyle: TextStyle(
                  color: selecionado ? Colors.white : Colors.white70,
                  fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
                  fontSize: 11.5,
                ),
                visualDensity: VisualDensity.compact,
                onSelected: (_) {
                  setState(() {
                    _tipoAreaEscolhida = forma;
                    if (forma == TipoArea.cubo &&
                        _tamanhoAreaMetros == 6.0 &&
                        magia.efeito.extrairAreaPadrao() == null) {
                      _tamanhoAreaMetros = 3.0;
                    }
                    _recalcularESincronizarPreview();
                  });
                },
              );
            }).toList(),
          ),

          // Seletor de Tamanho em Metros (quando formato em área está ativo)
          if (_tipoAreaEscolhida != null) ...[
            const SizedBox(height: 10),
            Text(
              _usaCentroVertice
                  ? 'Raio a partir da interseção de 4 quadrados (◎):'
                  : (_tipoAreaEscolhida == TipoArea.cubo
                        ? 'Lado do Cubo/Quadrado (1,5m = 1q • 3m = 2x2 = 4q):'
                        : 'Comprimento do ${_rotuloTipoArea(_tipoAreaEscolhida)} (adjacente ao personagem):'),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: ArenaMagiaSheet.tamanhosAreaMetrosSuportados.map((m) {
                final selecionado = (_tamanhoAreaMetros - m).abs() < 0.01;
                final rotulo = _formatarMetros(m);
                return ChoiceChip(
                  key: Key('chip_tamanho_area_$rotulo'),
                  label: Text(rotulo),
                  selected: selecionado,
                  selectedColor: Colors.indigo,
                  backgroundColor: const Color(0xFF1E293B),
                  labelStyle: TextStyle(
                    color: selecionado ? Colors.white : Colors.white70,
                    fontWeight: selecionado
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 11.5,
                  ),
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) {
                    setState(() {
                      _tamanhoAreaMetros = m;
                      _recalcularESincronizarPreview();
                    });
                  },
                );
              }).toList(),
            ),
          ],

          if (direcao != null) ...[
            const SizedBox(height: 6),
            Text(
              '🧭 Direção: ${_rotuloDirecao(direcao)} (toque ao redor do herói para girar nas 8 direções)',
              key: const Key('txt_direcao_area_magia'),
              style: const TextStyle(
                color: Colors.lightBlueAccent,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],

          const SizedBox(height: 10),
          // Mini-Grid Tático Interativo de Alcance e Área
          _buildMiniGridPreview(alcanceMetros),
          const SizedBox(height: 8),

          // Alertas de Alcance / Linha de Efeito (Barreiras)
          if (preview != null && !preview.origemDentroDoAlcance)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '⚠️ Origem fora do alcance da magia (${alcanceMetros.toStringAsFixed(1)}m).',
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (preview != null && !preview.origemTemLinhaDeEfeito)
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Text(
                '🧱 Sem linha de efeito: uma barreira sólida bloqueia o caminho até a origem!',
                style: TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          // Resumo de Quadrados e Todos os Alvos Atingidos (Múltiplos Inimigos/Aliados)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alvosNaArea.isEmpty
                      ? '📐 $qtdQuadradosArea quadrado(s) afetados${qtdBloqueados > 0 ? ' • $qtdBloqueados bloqueado(s) por barreira' : ''} • Nenhum combatente na área'
                      : '🎯 $qtdQuadradosArea quadrado(s) afetados${qtdBloqueados > 0 ? ' • $qtdBloqueados bloqueado(s)' : ''} • Atingidos simultaneamente (${alvosNaArea.length}):',
                  key: const Key('txt_alvos_na_area_magia'),
                  style: TextStyle(
                    color: alvosNaArea.isEmpty
                        ? Colors.white70
                        : Colors.amberAccent,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (alvosNaArea.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: alvosNaArea.map((alvo) {
                      final ehProprioLancador = alvo.id == widget.heroi.id;
                      final ehAliado = alvo.time == TimeCombatente.heroi;
                      final corChip = ehProprioLancador
                          ? Colors.orange.shade900
                          : (ehAliado
                                ? Colors.blue.shade900
                                : Colors.red.shade900);
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: corChip,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: ehProprioLancador
                                ? Colors.amberAccent
                                : Colors.white24,
                          ),
                        ),
                        child: Text(
                          ehProprioLancador
                              ? '⚠️ ${alvo.nome} (Você!)'
                              : '${ehAliado ? '🔵' : '🔴'} ${alvo.nome}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                if (_tipoAreaEscolhida != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    magia.alcance.tipo.toLowerCase() == 'pessoal'
                        ? 'Regra T20: Alcance Pessoal não afeta você; todos os demais na área sofrem o efeito.'
                        : 'Regra T20: Tudo dentro da área é afetado simultaneamente (inclusive você, se estiver dentro).',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniGridPreview(double alcanceMetros) {
    final combateState = widget.cubit.state;
    final mapa = combateState.mapaGrid;
    final preview = _previewAtual;
    final celulasAlcance = preview?.celulasAlcance ?? const <Posicao2D>{};
    final celulasArea = preview?.celulasArea ?? const <Posicao2D>{};
    final celulasBloqueadas = preview?.celulasBloqueadas ?? const <Posicao2D>{};
    final centroVertice = preview?.centroVertice;
    final posLancador = combateState.posicoesCombatentes[widget.heroi.id];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              _usaCentroVertice
                  ? 'Toque na grade para posicionar o centro (◎) na interseção:'
                  : 'Toque na grade para mirar/posicionar a área:',
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.indigo.withValues(alpha: 0.45),
                        border: Border.all(color: Colors.indigoAccent),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Alcance (${alcanceMetros.toStringAsFixed(1)}m)',
                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.65),
                        border: Border.all(color: Colors.amberAccent),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Área',
                      style: TextStyle(color: Colors.amberAccent, fontSize: 10),
                    ),
                  ],
                ),
                if (centroVertice != null)
                  const Text(
                    '◎ Centro',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320, maxHeight: 220),
            child: AspectRatio(
              aspectRatio: mapa.largura / mapa.altura,
              child: Container(
                key: const Key('mini_grid_magia_preview'),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1120),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cellW = constraints.maxWidth / mapa.largura;
                    final cellH = constraints.maxHeight / mapa.altura;

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: _usaCentroVertice
                          ? (details) {
                              final vx = (details.localPosition.dx / cellW)
                                  .round()
                                  .clamp(1, max(1, mapa.largura - 1))
                                  .toInt();
                              final vy = (details.localPosition.dy / cellH)
                                  .round()
                                  .clamp(1, max(1, mapa.altura - 1))
                                  .toInt();
                              setState(() {
                                _verticeAlvoGrid = VerticeGrid(vx, vy);
                                _pontoAlvoGrid = Posicao2D(
                                  vx.clamp(0, mapa.largura - 1).toInt(),
                                  vy.clamp(0, mapa.altura - 1).toInt(),
                                );
                                _recalcularESincronizarPreview();
                              });
                            }
                          : null,
                      child: Stack(
                        children: [
                          for (int y = 0; y < mapa.altura; y++)
                            for (int x = 0; x < mapa.largura; x++)
                              _buildMiniGridCell(
                                Posicao2D(x, y),
                                cellW,
                                cellH,
                                mapa.obterTerreno(Posicao2D(x, y)),
                                celulasAlcance.contains(Posicao2D(x, y)),
                                celulasArea.contains(Posicao2D(x, y)),
                                celulasBloqueadas.contains(Posicao2D(x, y)),
                                posLancador == Posicao2D(x, y),
                              ),
                          for (final entry
                              in combateState.posicoesCombatentes.entries)
                            _buildMiniGridToken(
                              entry.key,
                              entry.value,
                              cellW,
                              cellH,
                              celulasArea.contains(entry.value),
                            ),
                          // Círculo duplo ◎ marcando o centro da Esfera/Cilindro na interseção de 4 quadrados
                          if (centroVertice != null)
                            Positioned(
                              key: const Key('marcador_centro_vertice_magia'),
                              left: centroVertice.vx * cellW - 7,
                              top: centroVertice.vy * cellH - 7,
                              width: 14,
                              height: 14,
                              child: IgnorePointer(
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF0F172A),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1.8,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(2),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.amberAccent,
                                        width: 1.4,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniGridCell(
    Posicao2D pos,
    double w,
    double h,
    TipoTerreno terreno,
    bool noAlcance,
    bool naArea,
    bool bloqueadoBarreira,
    bool ehOrigemHeroi,
  ) {
    Color corFundo = const Color(0xFF0F172A);
    Color corBorda = Colors.white12;
    double larguraBorda = 0.5;

    if (terreno == TipoTerreno.obstaculo) {
      corFundo = Colors.black87;
    } else if (terreno == TipoTerreno.dificil) {
      corFundo = const Color(0xFF334155);
    }

    if (naArea) {
      corFundo = const Color(0xFFF59E0B).withValues(alpha: 0.52);
      corBorda = Colors.amberAccent;
      larguraBorda = 1.4;
    } else if (bloqueadoBarreira) {
      corFundo = Colors.red.shade900.withValues(alpha: 0.25);
      corBorda = Colors.redAccent.withValues(alpha: 0.5);
      larguraBorda = 0.9;
    } else if (noAlcance) {
      corFundo = Colors.indigo.withValues(alpha: 0.25);
      corBorda = Colors.indigoAccent.withValues(alpha: 0.6);
      larguraBorda = 0.8;
    }

    if (!_usaCentroVertice && _pontoAlvoGrid == pos) {
      corBorda = Colors.cyanAccent;
      larguraBorda = 1.6;
    }

    final celulaWidget = Container(
      decoration: BoxDecoration(
        color: corFundo,
        border: Border.all(color: corBorda, width: larguraBorda),
      ),
      child: terreno == TipoTerreno.obstaculo
          ? const Center(
              child: Icon(Icons.block, color: Colors.white24, size: 10),
            )
          : null,
    );

    return Positioned(
      left: pos.x * w,
      top: pos.y * h,
      width: w,
      height: h,
      child: _usaCentroVertice
          ? celulaWidget
          : GestureDetector(
              key: Key('mini_cell_${pos.x}_${pos.y}'),
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() {
                  _pontoAlvoGrid = pos;
                  for (final c in widget.todos) {
                    if (widget.cubit.state.posicoesCombatentes[c.id] == pos) {
                      _alvo = c;
                      break;
                    }
                  }
                  _recalcularESincronizarPreview();
                });
              },
              child: celulaWidget,
            ),
    );
  }

  Widget _buildMiniGridToken(
    String id,
    Posicao2D pos,
    double w,
    double h,
    bool atingidoNaArea,
  ) {
    final combatente = widget.todos.firstWhere(
      (c) => c.id == id,
      orElse: () => widget.heroi,
    );
    if (combatente.pvAtual <= 0) return const SizedBox.shrink();
    final ehHeroi = combatente.time == TimeCombatente.heroi;
    final span = combatente.tamanhoQuadrados;

    return Positioned(
      left: pos.x * w + 2,
      top: pos.y * h + 2,
      width: w * span - 4,
      height: h * span - 4,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            shape: span > 1 ? BoxShape.rectangle : BoxShape.circle,
            borderRadius: span > 1 ? BorderRadius.circular(4) : null,
            color: ehHeroi ? const Color(0xFF1E88E5) : const Color(0xFFE53935),
            border: Border.all(
              color: atingidoNaArea ? Colors.amberAccent : Colors.white,
              width: atingidoNaArea ? 2.0 : 1.0,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            combatente.nome.isNotEmpty
                ? combatente.nome[0].toUpperCase()
                : '?',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, String valor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(color: Colors.white54, fontSize: 10)),
          Flexible(
            child: Text(
              valor,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
