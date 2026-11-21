import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/entities/combate/combatente.dart';
import '../../../../domain/entities/combate/grid_tatico.dart';
import '../../../../domain/entities/entidade_sessao_lan/sessao_lan_modelos.dart';
import '../../../../domain/entities/habilidades/modelos_habilidade_duracao.dart';
import '../../../../domain/entities/magia/magia.dart';
import '../../../../domain/entities/mestre/modelos_mestre.dart';
import '../../../../domain/services/combate_services/dice_roll_service.dart';
import '../../../../domain/services/combate_services/movimento_engine.dart';
import '../../../../domain/services/data_services/call_magias.dart';
import '../../../../domain/services/habilidades_services/geometria_grid.dart';
import '../../../controllers/ficha_controller/ficha_cubit.dart';
import '../../../controllers/ficha_controller/sessao_jogador_cubit.dart';
import '../../../controllers/ficha_controller/sessao_jogador_state.dart';
import '../../../widgets/app_safe_scaffold.dart';

/// Visão em tela cheia do mapa da mesa enviada pelo Mestre para o Jogador.
class MapaJogadorScreen extends StatelessWidget {
  const MapaJogadorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SessaoJogadorCubit, SessaoJogadorState>(
      builder: (context, state) {
        final snap = state.ultimoSnapshot;

        return Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          appBar: AppBar(
            systemOverlayStyle: T20SystemUi.estiloEscuro,
            backgroundColor: const Color(0xFF1E293B),
            foregroundColor: Colors.white,
            title: Text(snap?.nomeMapa ?? 'Mapa da Mesa'),
            actions: [
              if (snap != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF334155),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Rodada ${snap.rodadaCombate}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          body: SafeArea(
            top: false,
            child: !state.estaConectado || snap == null
                ? const Center(
                    child: Text(
                      'Aguardando mapa ativo da sessão...',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : const MapaMesaJogadorWidget(),
          ),
        );
      },
    );
  }
}

/// Widget interativo do mapa tático do jogador (pode ser usado em tela cheia
/// ou em miniatura embutida dentro da Ficha).
class MapaMesaJogadorWidget extends StatefulWidget {
  final bool compacto;

  const MapaMesaJogadorWidget({super.key, this.compacto = false});

  @override
  State<MapaMesaJogadorWidget> createState() => _MapaMesaJogadorWidgetState();
}

class _MapaMesaJogadorWidgetState extends State<MapaMesaJogadorWidget> {
  static const GeometriaGrid _geometriaGrid = GeometriaGrid();
  static final RegExp _regexDadoDescricao = RegExp(
    r'(\d+)\s*d\s*(2|4|6|8|10|12|20|100)(?:\s*([+-])\s*(\d+))?\b',
    caseSensitive: false,
  );

  String? _tokenSelecionadoId;

  // Modo Magia / Área de Efeito T20 no Mapa LAN
  bool _modoMagiaAtivo = false;
  Magia? _magiaSelecionada;
  TipoArea? _tipoAreaEscolhida = TipoArea.esfera;
  double _tamanhoAreaMetros = 6.0;
  Posicao2D? _pontoAlvoArea;
  VerticeGrid? _verticeAlvoArea;
  int _pmEscolhido = 1;
  int _qtdDados = 2;
  int _tipoDado = 6;
  int _modificadorDano = 0;
  bool _ehCuraMagia = false;
  final DiceRollService _roller = DiceRollService();

  // Cache de memoização para evitar executar Dijkstra a cada frame de build().
  SnapshotMesa? _cacheSnapshot;
  String? _cacheTokenSelecionadoId;
  String? _cacheMeuCharId;
  double? _cacheMeuDeslocamento;
  ({Set<Posicao2D> destinos, Map<Posicao2D, double> custos}) _cacheAlcance = (
    destinos: const {},
    custos: const {},
  );

  Color _corFundoMapa(PresetFundoMapa preset) => switch (preset) {
    PresetFundoMapa.masmorraPedra => const Color(0xFF1E293B),
    PresetFundoMapa.florestaArton => const Color(0xFF143321),
    PresetFundoMapa.tavernaMadeira => const Color(0xFF3E2723),
    PresetFundoMapa.desertoHalakTur => const Color(0xFF4E3B1E),
    PresetFundoMapa.areaTormenta => const Color(0xFF3B0A1E),
    PresetFundoMapa.imagemCustomizada => const Color(0xFF1E293B),
  };

  ({Set<Posicao2D> destinos, Map<Posicao2D, double> custos})
  _obterAlcanceMemoizado(
    SnapshotMesa snap,
    String meuCharId,
    double meuDeslocamentoFicha,
  ) {
    if (_cacheTokenSelecionadoId == _tokenSelecionadoId &&
        _cacheMeuCharId == meuCharId &&
        _cacheMeuDeslocamento == meuDeslocamentoFicha &&
        (identical(_cacheSnapshot, snap) || _cacheSnapshot == snap)) {
      return _cacheAlcance;
    }

    final calculado = _calcularAlcance(snap, meuCharId, meuDeslocamentoFicha);
    _cacheSnapshot = snap;
    _cacheTokenSelecionadoId = _tokenSelecionadoId;
    _cacheMeuCharId = meuCharId;
    _cacheMeuDeslocamento = meuDeslocamentoFicha;
    _cacheAlcance = calculado;
    return calculado;
  }

  ({Set<Posicao2D> destinos, Map<Posicao2D, double> custos}) _calcularAlcance(
    SnapshotMesa snap,
    String meuCharId,
    double meuDeslocamentoFicha,
  ) {
    final selId = _tokenSelecionadoId;
    if (selId == null) {
      return (destinos: const {}, custos: const {});
    }
    final tok = snap.tokensVisiveis.where((t) => t.id == selId).firstOrNull;
    if (tok == null) {
      return (destinos: const {}, custos: const {});
    }

    final deslocamento = tok.id == meuCharId
        ? meuDeslocamentoFicha
        : tok.deslocamentoMetros;

    final posicoes = <String, Posicao2D>{
      for (final t in snap.tokensVisiveis) t.id: t.posicao,
    };
    final combatentes = <String, Combatente>{
      for (final t in snap.tokensVisiveis)
        t.id: Combatente(
          id: t.id,
          nome: t.nome,
          time: t.ehHeroi ? TimeCombatente.heroi : TimeCombatente.inimigo,
          pvMax: t.pvMax,
          pvAtual: t.pvAtual,
          pmMax: t.pmMax,
          pmAtual: t.pmAtual,
          defesa: t.defesa,
          deslocamentoMetros: t.id == meuCharId
              ? meuDeslocamentoFicha
              : t.deslocamentoMetros,
          modIniciativa: t.iniciativa ?? 0,
          modLuta: 0,
          modPontaria: 0,
          modPercepcao: 0,
          modForca: 0,
          modDestreza: 0,
          modConstituicao: 0,
        ),
    };

    final resultado = MovimentoEngine.calcularAlcancaveis(
      mapa: GridMapa(
        largura: snap.largura,
        altura: snap.altura,
        terrenos: snap.terrenos,
      ),
      inicio: tok.posicao,
      deslocamentoMaximoMetros: deslocamento,
      posicoesCombatentes: posicoes,
      combatentesPorId: combatentes,
      combatenteAtivoId: tok.id,
    );

    return (
      destinos: resultado.destinosValidos,
      custos: resultado.custosMetros,
    );
  }

  String get _expressaoDadosFormatada {
    final base = '${_qtdDados}d$_tipoDado';
    if (_modificadorDano > 0) return '$base+$_modificadorDano';
    if (_modificadorDano < 0) return '$base$_modificadorDano';
    return base;
  }

  int _custoBaseMagia(Magia m) => switch (m.circulo) {
    1 => 1,
    2 => 3,
    3 => 6,
    4 => 10,
    5 => 15,
    _ => m.circulo,
  };

  void _selecionarMagiaLan(Magia? magia, SnapshotMesa snap, String meuCharId) {
    if (magia == null) {
      setState(() => _magiaSelecionada = null);
      return;
    }
    final custoBase = _custoBaseMagia(magia);
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
    final ehCura =
        magia.escola.toLowerCase().contains('cura') ||
        magia.nome.toLowerCase().contains('curar');

    setState(() {
      _magiaSelecionada = magia;
      _pmEscolhido = math.max(1, custoBase);
      _qtdDados = qtdSugerida;
      _tipoDado = [2, 4, 6, 8, 10, 12, 20, 100].contains(faceSugerida)
          ? faceSugerida
          : 6;
      _modificadorDano = modSugerido;
      _ehCuraMagia = ehCura;
      _tipoAreaEscolhida = areaPadrao?.tipo;
      if (areaPadrao != null) {
        _tamanhoAreaMetros = areaPadrao.tamanhoMetros;
      }
    });
    _sincronizarAreaNaLan(snap, meuCharId);
  }

  void _sincronizarAreaNaLan(SnapshotMesa snap, String meuCharId) {
    final tipo = _tipoAreaEscolhida;
    final sessaoCubit = context.read<SessaoJogadorCubit>();
    if (!_modoMagiaAtivo || tipo == null) {
      unawaited(sessaoCubit.limparMinhaAreaNoMapa());
      return;
    }
    final meuToken = snap.tokensVisiveis
        .where((t) => t.id == meuCharId)
        .firstOrNull;
    final posAlvo = _pontoAlvoArea ?? meuToken?.posicao ?? const Posicao2D(0, 0);
    final usaVertice = tipo == TipoArea.esfera || tipo == TipoArea.cilindro;
    final vert = usaVertice
        ? (_verticeAlvoArea ??
              VerticeGrid(
                posAlvo.x.clamp(1, math.max(1, snap.largura - 1)),
                posAlvo.y.clamp(1, math.max(1, snap.altura - 1)),
              ))
        : null;
    final rotulo = _magiaSelecionada != null
        ? '${_magiaSelecionada!.nome} (${tipo.name.toUpperCase()} ${_tamanhoAreaMetros.toStringAsFixed(1)}m)'
        : '${tipo.name.toUpperCase()} ${_tamanhoAreaMetros.toStringAsFixed(1)}m';
    unawaited(
      sessaoCubit.projetarAreaNoMapa(
        tipo: tipo,
        tamanhoMetros: _tamanhoAreaMetros,
        pontoAlvo: posAlvo,
        verticeAlvo: vert,
        rotulo: rotulo,
      ),
    );
  }

  ({
    Set<Posicao2D> celulasArea,
    VerticeGrid? centroVertice,
    List<TokenNoMapa> tokensAfetados,
  }) _calcularPreviewAreaLocal(SnapshotMesa snap, String meuCharId) {
    if (!_modoMagiaAtivo) {
      return (
        celulasArea: const {},
        centroVertice: null,
        tokensAfetados: const [],
      );
    }
    final meuToken = snap.tokensVisiveis
        .where((t) => t.id == meuCharId)
        .firstOrNull;
    final posLancador = meuToken?.posicao ?? const Posicao2D(0, 0);
    final pontoAlvo = _pontoAlvoArea ?? posLancador;
    final tipo = _tipoAreaEscolhida;

    if (tipo == null) {
      final celulas = <Posicao2D>{pontoAlvo};
      final alvos = snap.tokensVisiveis.where((t) {
        return t.posicao
            .celulasOcupadas(t.tamanhoQuadrados)
            .any(celulas.contains);
      }).toList();
      return (
        celulasArea: celulas,
        centroVertice: null,
        tokensAfetados: alvos,
      );
    }

    final mapa = GridMapa(
      largura: snap.largura,
      altura: snap.altura,
      terrenos: snap.terrenos,
    );
    final usaVertice = tipo == TipoArea.esfera || tipo == TipoArea.cilindro;
    final vert = usaVertice
        ? (_verticeAlvoArea ??
              VerticeGrid(
                pontoAlvo.x.clamp(1, math.max(1, snap.largura - 1)),
                pontoAlvo.y.clamp(1, math.max(1, snap.altura - 1)),
              ))
        : null;

    final calc = _geometriaGrid.calcularAreaTaticaNoMapa(
      mapa: mapa,
      posLancador: posLancador,
      tipoArea: tipo,
      tamanhoMetros: _tamanhoAreaMetros,
      pontoAlvo: pontoAlvo,
      verticeAlvo: vert,
    );
    final celulasVisiveis = calc.celulasArea.intersection(
      snap.celulasReveladas,
    );
    final ehPessoal =
        _magiaSelecionada?.alcance.tipo.toLowerCase() == 'pessoal';

    final alvos = snap.tokensVisiveis.where((t) {
      if (ehPessoal && t.id == meuCharId) return false;
      return t.posicao
          .celulasOcupadas(t.tamanhoQuadrados)
          .any(celulasVisiveis.contains);
    }).toList();

    return (
      celulasArea: celulasVisiveis,
      centroVertice: calc.centroVertice,
      tokensAfetados: alvos,
    );
  }

  Future<void> _rolarELancarMagiaNaLan(
    SnapshotMesa snap,
    String meuCharId,
    List<TokenNoMapa> alvosAfetados,
  ) async {
    final fichaCubit = context.read<FichaCubit>();
    final sessaoCubit = context.read<SessaoJogadorCubit>();
    final nomeMagia = _magiaSelecionada?.nome ?? 'Magia em Área';
    final ok = await fichaCubit.tentarAtivarComPM(
      _pmEscolhido,
      nomeAcao: nomeMagia,
    );
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            fichaCubit.state.mensagemErro ?? 'PM insuficiente na ficha!',
          ),
          backgroundColor: const Color(0xFFB91C1C),
        ),
      );
      return;
    }

    final rolagem = _roller.rolarDano(expressaoDano: _expressaoDadosFormatada);
    final tipo = _tipoAreaEscolhida;
    final rotuloArea = tipo != null
        ? '${tipo.name.toUpperCase()} ${_tamanhoAreaMetros.toStringAsFixed(1)}m'
        : 'Alvo Único';

    await sessaoCubit.enviarLancamentoMagiaLan(
      magiaNome: nomeMagia,
      custoPm: _pmEscolhido,
      expressaoDados: _expressaoDadosFormatada,
      valorRolado: rolagem.total,
      ehCura: _ehCuraMagia,
      alvosIds: alvosAfetados.map((t) => t.id).toList(),
      rotuloArea: rotuloArea,
    );
    await sessaoCubit.sincronizarPersonagemAtual(fichaCubit.state);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '✨ $nomeMagia enviada ao Mestre (${rolagem.decomposicao} • $_pmEscolhido PM)!',
        ),
        backgroundColor: const Color(0xFF1D4ED8),
      ),
    );
  }

  void _aoTocarGrade(
    Offset localPosition,
    double cellSize,
    SnapshotMesa snap,
    String meuCharId,
    Set<Posicao2D> alcancaveis,
  ) {
    final x = (localPosition.dx / cellSize).floor();
    final y = (localPosition.dy / cellSize).floor();
    if (x < 0 || x >= snap.largura || y < 0 || y >= snap.altura) return;
    final pos = Posicao2D(x, y);

    if (_modoMagiaAtivo) {
      final usaVertice =
          _tipoAreaEscolhida == TipoArea.esfera ||
          _tipoAreaEscolhida == TipoArea.cilindro;
      setState(() {
        _pontoAlvoArea = pos;
        if (usaVertice) {
          _verticeAlvoArea = VerticeGrid(
            (localPosition.dx / cellSize)
                .round()
                .clamp(1, math.max(1, snap.largura - 1)),
            (localPosition.dy / cellSize)
                .round()
                .clamp(1, math.max(1, snap.altura - 1)),
          );
        }
      });
      _sincronizarAreaNaLan(snap, meuCharId);
      return;
    }

    if (_tokenSelecionadoId != meuCharId) return;
    if (!snap.celulasReveladas.contains(pos)) return;
    final terreno = snap.terrenos[pos] ?? TipoTerreno.normal;
    if (terreno == TipoTerreno.obstaculo) return;
    if (alcancaveis.isNotEmpty && !alcancaveis.contains(pos)) return;

    context.read<SessaoJogadorCubit>().moverMeuToken(pos);
    setState(() => _tokenSelecionadoId = null);
  }

  @override
  Widget build(BuildContext context) {
    final personagem = context.select(
      (FichaCubit c) => (
        id: c.personagem.id,
        deslocamento: c.personagem.deslocamentoEfetivoMetros.toDouble(),
        pmAtual: c.personagem.pmAtual,
        magiasIds: c.personagem.magiasConhecidas,
      ),
    );
    final meuCharId = personagem.id;

    return BlocBuilder<SessaoJogadorCubit, SessaoJogadorState>(
      builder: (context, state) {
        final snap = state.ultimoSnapshot;
        if (!state.estaConectado || snap == null) {
          return const Center(
            child: Text(
              'Aguardando mapa ativo da sessão...',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        final movendoProprio =
            !_modoMagiaAtivo && _tokenSelecionadoId == meuCharId;
        final alcance = _obterAlcanceMemoizado(
          snap,
          meuCharId,
          personagem.deslocamento,
        );
        final previewMagia = _calcularPreviewAreaLocal(snap, meuCharId);

        return Container(
          color: const Color(0xFF0F172A),
          child: Column(
            children: [
              if (movendoProprio)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: widget.compacto ? 4 : 6,
                  ),
                  color: const Color(0xFF1E3A8A),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Toque em uma célula revelada para mover seu personagem.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: widget.compacto ? 11 : 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Alcance: ${personagem.deslocamento.toStringAsFixed(1)}m (${(personagem.deslocamento / 1.5).floor()}□) • Difícil = 3m/□',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: widget.compacto ? 10 : 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              if (!widget.compacto)
                _buildBarraModoMagiaTopo(
                  snap,
                  meuCharId,
                  personagem.pmAtual,
                ),
              Expanded(
                child: InteractiveViewer(
                  minScale: widget.compacto ? 0.35 : 0.5,
                  maxScale: 3.0,
                  boundaryMargin: EdgeInsets.all(widget.compacto ? 24 : 64),
                  child: Center(
                    child: _buildGrid(
                      snap,
                      meuCharId,
                      movendoProprio ? alcance.destinos : const {},
                      movendoProprio ? alcance.custos : const {},
                      previewMagia.celulasArea,
                      previewMagia.centroVertice,
                    ),
                  ),
                ),
              ),
              if (!widget.compacto && _modoMagiaAtivo)
                _buildPainelMagiaLan(
                  snap,
                  meuCharId,
                  personagem.pmAtual,
                  personagem.magiasIds,
                  previewMagia.tokensAfetados,
                )
              else
                _buildBarraTokenSelecionado(
                  snap,
                  meuCharId,
                  personagem.deslocamento,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBarraModoMagiaTopo(
    SnapshotMesa snap,
    String meuCharId,
    int pmAtual,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: const Color(0xFF1E293B),
      child: Row(
        children: [
          Text(
            'PM Disponível: $pmAtual',
            style: const TextStyle(
              color: Colors.amberAccent,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          FilledButton.tonalIcon(
            key: const Key('btn_toggle_modo_magia_lan_jogador'),
            icon: Icon(
              _modoMagiaAtivo ? Icons.close : Icons.auto_awesome,
              size: 16,
            ),
            label: Text(
              _modoMagiaAtivo ? 'Fechar Magia/Área' : '✨ Magia / Área T20',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              setState(() {
                _modoMagiaAtivo = !_modoMagiaAtivo;
                if (_modoMagiaAtivo) {
                  _tokenSelecionadoId = null;
                }
              });
              _sincronizarAreaNaLan(snap, meuCharId);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPainelMagiaLan(
    SnapshotMesa snap,
    String meuCharId,
    int pmAtual,
    List<String> magiasIds,
    List<TokenNoMapa> alvosAfetados,
  ) {
    final magiasConhecidas = magiasIds
        .map((id) => BancoDeMagias.getById(id))
        .where((m) => m.id != 'UNKNOWN')
        .toList();
    const formas = <({TipoArea? tipo, String rotulo})>[
      (tipo: null, rotulo: 'Alvo Único'),
      (tipo: TipoArea.cone, rotulo: 'Cone'),
      (tipo: TipoArea.esfera, rotulo: 'Esfera (◎)'),
      (tipo: TipoArea.cilindro, rotulo: 'Cilindro'),
      (tipo: TipoArea.cubo, rotulo: 'Cubo/Quad.'),
      (tipo: TipoArea.linha, rotulo: 'Linha'),
    ];
    const tamanhos = <double>[1.5, 3.0, 4.5, 6.0, 9.0, 12.0, 15.0];

    return Container(
      key: const Key('painel_magia_lan_jogador'),
      constraints: const BoxConstraints(maxHeight: 270),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        border: Border(top: BorderSide(color: Colors.white24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (magiasConhecidas.isNotEmpty) ...[
              DropdownButton<Magia?>(
                isExpanded: true,
                dropdownColor: const Color(0xFF0F172A),
                value: _magiaSelecionada,
                hint: const Text(
                  'Selecionar magia conhecida da ficha (ou configurar livre)...',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                items: [
                  const DropdownMenuItem<Magia?>(
                    value: null,
                    child: Text(
                      '⚙️ Área / Rolagem Livre',
                      style: TextStyle(color: Colors.amberAccent, fontSize: 12),
                    ),
                  ),
                  ...magiasConhecidas.map((m) {
                    return DropdownMenuItem<Magia?>(
                      value: m,
                      child: Text(
                        '${m.nome} (${m.circulo}º • ${m.efeito.descricao ?? m.alcance.tipo})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }),
                ],
                onChanged: (m) => _selecionarMagiaLan(m, snap, meuCharId),
              ),
            ],
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final f in formas)
                  ChoiceChip(
                    key: Key('chip_lan_forma_${f.tipo?.name ?? "alvo"}'),
                    label: Text(
                      f.rotulo,
                      style: const TextStyle(fontSize: 11),
                    ),
                    selected: _tipoAreaEscolhida == f.tipo,
                    selectedColor: Colors.amber.shade800,
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) {
                      setState(() => _tipoAreaEscolhida = f.tipo);
                      _sincronizarAreaNaLan(snap, meuCharId);
                    },
                  ),
              ],
            ),
            if (_tipoAreaEscolhida != null) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final m in tamanhos)
                    ChoiceChip(
                      key: Key(
                        'chip_lan_tam_${m == m.roundToDouble() ? "${m.toInt()}m" : "${m}m"}',
                      ),
                      label: Text(
                        m == m.roundToDouble()
                            ? '${m.toInt()}m'
                            : '${m.toStringAsFixed(1).replaceAll('.', ',')}m',
                        style: const TextStyle(fontSize: 11),
                      ),
                      selected: (_tamanhoAreaMetros - m).abs() < 0.01,
                      selectedColor: Colors.indigo,
                      visualDensity: VisualDensity.compact,
                      onSelected: (_) {
                        setState(() => _tamanhoAreaMetros = m);
                        _sincronizarAreaNaLan(snap, meuCharId);
                      },
                    ),
                ],
              ),
            ],
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final faces in [2, 4, 6, 8, 10, 12, 20, 100])
                  ChoiceChip(
                    key: Key('chip_lan_dado_d$faces'),
                    label: Text(
                      'd$faces',
                      style: const TextStyle(fontSize: 11),
                    ),
                    selected: _tipoDado == faces,
                    selectedColor: Colors.indigo,
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) => setState(() => _tipoDado = faces),
                  ),
                ChoiceChip(
                  label: Text(
                    _ehCuraMagia ? '💚 Cura' : '💥 Dano',
                    style: const TextStyle(fontSize: 11),
                  ),
                  selected: true,
                  selectedColor: _ehCuraMagia
                      ? Colors.green.shade800
                      : Colors.red.shade900,
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) =>
                      setState(() => _ehCuraMagia = !_ehCuraMagia),
                ),
              ],
            ),
            Row(
              children: [
                const Text(
                  'Dados:',
                  style: TextStyle(color: Colors.white70, fontSize: 11.5),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    size: 18,
                    color: Colors.white70,
                  ),
                  onPressed: _qtdDados > 1
                      ? () => setState(() => _qtdDados--)
                      : null,
                ),
                Text(
                  '$_qtdDados',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add_circle_outline,
                    size: 18,
                    color: Colors.white70,
                  ),
                  onPressed: () => setState(() => _qtdDados++),
                ),
                const Text(
                  'Mod:',
                  style: TextStyle(color: Colors.white70, fontSize: 11.5),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    size: 18,
                    color: Colors.white70,
                  ),
                  onPressed: () => setState(() => _modificadorDano--),
                ),
                Text(
                  _modificadorDano >= 0
                      ? '+$_modificadorDano'
                      : '$_modificadorDano',
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add_circle_outline,
                    size: 18,
                    color: Colors.white70,
                  ),
                  onPressed: () => setState(() => _modificadorDano++),
                ),
                const Spacer(),
                const Text(
                  'PM:',
                  style: TextStyle(color: Colors.amberAccent, fontSize: 11.5),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    size: 18,
                    color: Colors.white70,
                  ),
                  onPressed: _pmEscolhido > 1
                      ? () => setState(() => _pmEscolhido--)
                      : null,
                ),
                Text(
                  '$_pmEscolhido',
                  style: const TextStyle(
                    color: Colors.amberAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add_circle_outline,
                    size: 18,
                    color: Colors.white70,
                  ),
                  onPressed: () => setState(() => _pmEscolhido++),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    alvosAfetados.isEmpty
                        ? 'Toque no mapa para mirar a área (0 alvos atingidos)'
                        : '🎯 Atingidos (${alvosAfetados.length}): ${alvosAfetados.map((t) => t.nome).join(", ")}',
                    style: const TextStyle(
                      color: Colors.amberAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  key: const Key('btn_lancar_magia_lan_jogador'),
                  icon: const Icon(Icons.auto_awesome, size: 15),
                  label: Text(
                    'Lançar ($_expressaoDadosFormatada • $_pmEscolhido PM)',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: pmAtual >= _pmEscolhido
                      ? () => _rolarELancarMagiaNaLan(
                          snap,
                          meuCharId,
                          alvosAfetados,
                        )
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(
    SnapshotMesa snap,
    String meuCharId,
    Set<Posicao2D> alcancaveis,
    Map<Posicao2D, double> custos,
    Set<Posicao2D> celulasAreaLocal,
    VerticeGrid? centroVerticeLocal,
  ) {
    final double cellSize = widget.compacto ? 26 : 40;
    final larguraPx = snap.largura * cellSize;
    final alturaPx = snap.altura * cellSize;

    return Container(
      width: larguraPx,
      height: alturaPx,
      decoration: BoxDecoration(
        color: _corFundoMapa(snap.presetFundo),
        border: Border.all(color: Colors.white24),
      ),
      child: Stack(
        children: [
          // Grade, Terrenos, Alcance, Áreas de Efeito e Fog of War em um único CustomPaint + RepaintBoundary
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) => _aoTocarGrade(
                details.localPosition,
                cellSize,
                snap,
                meuCharId,
                alcancaveis,
              ),
              child: RepaintBoundary(
                child: CustomPaint(
                  key: const ValueKey('mapa_jogador_grid_canvas'),
                  size: Size(larguraPx, alturaPx),
                  painter: MapaJogadorGridPainter(
                    snapshot: snap,
                    celulasAlcancaveis: alcancaveis,
                    custosMovimento: custos,
                    celulasAreaLocal: celulasAreaLocal,
                    centroVerticeLocal: centroVerticeLocal,
                    compacto: widget.compacto,
                  ),
                ),
              ),
            ),
          ),
          // Tokens visíveis ao jogador
          for (final tok in snap.tokensVisiveis)
            if (tok.ehHeroi || snap.celulasReveladas.contains(tok.posicao))
              Positioned(
                left: tok.posicao.x * cellSize,
                top: tok.posicao.y * cellSize,
                width: tok.tamanhoQuadrados * cellSize,
                height: tok.tamanhoQuadrados * cellSize,
                child: GestureDetector(
                  onTap: () {
                    if (_modoMagiaAtivo) {
                      setState(() {
                        _pontoAlvoArea = tok.posicao;
                        _verticeAlvoArea = VerticeGrid(
                          tok.posicao.x.clamp(1, math.max(1, snap.largura - 1)),
                          tok.posicao.y.clamp(1, math.max(1, snap.altura - 1)),
                        );
                      });
                      _sincronizarAreaNaLan(snap, meuCharId);
                    } else {
                      setState(() {
                        _tokenSelecionadoId =
                            _tokenSelecionadoId == tok.id ? null : tok.id;
                      });
                    }
                  },
                  child: _buildToken(
                    tok,
                    ehMeu: tok.id == meuCharId,
                    ehTurno: tok.id == snap.tokenTurnoAtualId,
                    selecionado: tok.id == _tokenSelecionadoId,
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildToken(
    TokenNoMapa tok, {
    required bool ehMeu,
    required bool ehTurno,
    required bool selecionado,
  }) {
    final corBorda = ehTurno
        ? Colors.greenAccent
        : (ehMeu
              ? const Color(0xFFFBBF24)
              : (tok.ehHeroi ? Colors.lightBlueAccent : Colors.redAccent));

    return Container(
      margin: EdgeInsets.all(widget.compacto ? 1.5 : 2),
      decoration: BoxDecoration(
        color: tok.ehHeroi ? const Color(0xFF1E3A8A) : const Color(0xFF7F1D1D),
        shape: BoxShape.circle,
        border: Border.all(
          color: corBorda,
          width: selecionado || ehTurno
              ? (widget.compacto ? 2.5 : 3)
              : (widget.compacto ? 1.5 : 2),
        ),
      ),
      child: Center(
        child: Text(
          tok.nome.isEmpty ? '?' : tok.nome.substring(0, 1).toUpperCase(),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: widget.compacto ? 10 : 13,
          ),
        ),
      ),
    );
  }

  Widget _buildBarraTokenSelecionado(
    SnapshotMesa snap,
    String meuCharId,
    double meuDeslocamentoFicha,
  ) {
    final tok = snap.tokensVisiveis
        .where((t) => t.id == _tokenSelecionadoId)
        .firstOrNull;
    if (tok == null) return const SizedBox.shrink();

    final mostrarPv = tok.id == meuCharId || tok.ehHeroi;
    final desl = tok.id == meuCharId
        ? meuDeslocamentoFicha
        : tok.deslocamentoMetros;
    final texto = mostrarPv
        ? '${tok.nome} • PV ${tok.pvAtual}/${tok.pvMax} • PM ${tok.pmAtual}/${tok.pmMax} • Desl ${desl.toStringAsFixed(1)}m${tok.condicoes.isNotEmpty ? ' • ${tok.condicoes.join(", ")}' : ''}'
        : '${tok.nome} • Desl ${desl.toStringAsFixed(1)}m${tok.condicoes.isNotEmpty ? ' • Condições: ${tok.condicoes.join(", ")}' : ''}';

    final conteudo = Text(
      texto,
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: widget.compacto ? 11.5 : 13,
      ),
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: widget.compacto ? 6 : 12,
      ),
      color: const Color(0xFF1E293B),
      child: widget.compacto
          ? conteudo
          : SafeArea(top: false, child: conteudo),
    );
  }
}

/// Painter de alta performance para o grid tático do Jogador.
/// Renderiza terrenos, alcance de movimento, áreas de efeito T20 (com ◎), Fog of War e linhas da grade em um único Canvas.
class MapaJogadorGridPainter extends CustomPainter {
  final SnapshotMesa snapshot;
  final Set<Posicao2D> celulasAlcancaveis;
  final Map<Posicao2D, double> custosMovimento;
  final Set<Posicao2D> celulasAreaLocal;
  final VerticeGrid? centroVerticeLocal;
  final bool compacto;

  static final Paint _obstaculoFill = Paint()
    ..color = Colors.black.withValues(alpha: 0.72)
    ..style = PaintingStyle.fill;
  static final Paint _obstaculoMark = Paint()
    ..color = Colors.white38
    ..strokeWidth = 1.4
    ..style = PaintingStyle.stroke;
  static final Paint _dificilFill = Paint()
    ..color = const Color(0xFFD97706).withValues(alpha: 0.35)
    ..style = PaintingStyle.fill;
  static final Paint _dificilMark = Paint()
    ..color = Colors.amberAccent
    ..strokeWidth = 1.3
    ..style = PaintingStyle.stroke;
  static final Paint _alcanceFill = Paint()
    ..color = const Color(0xFF38BDF8).withValues(alpha: 0.35)
    ..style = PaintingStyle.fill;
  static final Paint _alcanceBorder = Paint()
    ..color = Colors.cyanAccent
    ..strokeWidth = 1.4
    ..style = PaintingStyle.stroke;
  static final Paint _areaSincFill = Paint()
    ..color = const Color(0xFFF59E0B).withValues(alpha: 0.40)
    ..style = PaintingStyle.fill;
  static final Paint _areaSincBorder = Paint()
    ..color = Colors.amberAccent
    ..strokeWidth = 1.4
    ..style = PaintingStyle.stroke;
  static final Paint _areaLocalFill = Paint()
    ..color = const Color(0xFFEC4899).withValues(alpha: 0.44)
    ..style = PaintingStyle.fill;
  static final Paint _areaLocalBorder = Paint()
    ..color = Colors.pinkAccent
    ..strokeWidth = 1.6
    ..style = PaintingStyle.stroke;
  static final Paint _centroVerticeBg = Paint()
    ..color = const Color(0xFF0F172A)
    ..style = PaintingStyle.fill;
  static final Paint _centroVerticeOuter = Paint()
    ..color = Colors.white
    ..strokeWidth = 1.8
    ..style = PaintingStyle.stroke;
  static final Paint _centroVerticeInner = Paint()
    ..color = Colors.amberAccent
    ..strokeWidth = 1.4
    ..style = PaintingStyle.stroke;
  static final Paint _fogPaint = Paint()
    ..color = Colors.black.withValues(alpha: 0.78)
    ..style = PaintingStyle.fill;
  static final Paint _pillBgPaint = Paint()
    ..color = Colors.black87
    ..style = PaintingStyle.fill;
  static final Paint _gridPaint = Paint()
    ..strokeWidth = 0.5
    ..style = PaintingStyle.stroke;

  static final Map<String, TextPainter> _custoTextCache = {};

  const MapaJogadorGridPainter({
    required this.snapshot,
    required this.celulasAlcancaveis,
    required this.custosMovimento,
    this.celulasAreaLocal = const {},
    this.centroVerticeLocal,
    required this.compacto,
  });

  TextPainter _obterTextPainterCusto(double custo, bool compacto) {
    final label = '${custo.toStringAsFixed(1)}m';
    final cacheKey = '${compacto ? "c" : "n"}_$label';
    return _custoTextCache.putIfAbsent(cacheKey, () {
      return TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: Colors.cyanAccent,
            fontSize: compacto ? 6.5 : 8,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    });
  }

  bool _dentroLimites(Posicao2D pos, int largura, int altura) =>
      pos.x >= 0 && pos.x < largura && pos.y >= 0 && pos.y < altura;

  @override
  void paint(Canvas canvas, Size size) {
    final largura = snapshot.largura;
    final altura = snapshot.altura;
    if (largura <= 0 || altura <= 0) return;

    final cellW = size.width / largura;
    final cellH = size.height / altura;
    final reveladas = snapshot.celulasReveladas;

    // 1. Terrenos revelados
    if (snapshot.terrenos.isNotEmpty) {
      final minDim = math.min(cellW, cellH);
      for (final entry in snapshot.terrenos.entries) {
        final pos = entry.key;
        if (!_dentroLimites(pos, largura, altura) || !reveladas.contains(pos)) {
          continue;
        }
        final rect = Rect.fromLTWH(pos.x * cellW, pos.y * cellH, cellW, cellH);
        if (entry.value == TipoTerreno.obstaculo) {
          canvas.drawRect(rect, _obstaculoFill);
          final pad = minDim * 0.28;
          canvas.drawLine(
            Offset(rect.left + pad, rect.top + pad),
            Offset(rect.right - pad, rect.bottom - pad),
            _obstaculoMark,
          );
          canvas.drawLine(
            Offset(rect.right - pad, rect.top + pad),
            Offset(rect.left + pad, rect.bottom - pad),
            _obstaculoMark,
          );
        } else if (entry.value == TipoTerreno.dificil) {
          canvas.drawRect(rect, _dificilFill);
          final iconSize = minDim * 0.24;
          final topRight = Offset(rect.right - 2, rect.top + 2);
          final path = Path()
            ..moveTo(topRight.dx - iconSize, topRight.dy + iconSize)
            ..lineTo(topRight.dx - iconSize * 0.5, topRight.dy)
            ..lineTo(topRight.dx, topRight.dy + iconSize)
            ..close();
          canvas.drawPath(path, _dificilMark);
        }
      }
    }

    // 2. Preenchimento das células alcançáveis reveladas
    if (celulasAlcancaveis.isNotEmpty) {
      for (final pos in celulasAlcancaveis) {
        if (!_dentroLimites(pos, largura, altura) || !reveladas.contains(pos)) {
          continue;
        }
        canvas.drawRect(
          Rect.fromLTWH(pos.x * cellW, pos.y * cellH, cellW, cellH),
          _alcanceFill,
        );
      }
    }

    // 2b. Áreas de Efeito sincronizadas pela LAN + preview local do jogador
    if (snapshot.areasEfeitoVisiveis.isNotEmpty) {
      for (final area in snapshot.areasEfeitoVisiveis) {
        for (final pos in area.celulasAfetadas) {
          if (!_dentroLimites(pos, largura, altura) ||
              !reveladas.contains(pos)) {
            continue;
          }
          final rect = Rect.fromLTWH(
            pos.x * cellW,
            pos.y * cellH,
            cellW,
            cellH,
          );
          canvas.drawRect(rect, _areaSincFill);
          canvas.drawRect(rect, _areaSincBorder);
        }
      }
    }
    if (celulasAreaLocal.isNotEmpty) {
      for (final pos in celulasAreaLocal) {
        if (!_dentroLimites(pos, largura, altura) || !reveladas.contains(pos)) {
          continue;
        }
        final rect = Rect.fromLTWH(pos.x * cellW, pos.y * cellH, cellW, cellH);
        canvas.drawRect(rect, _areaLocalFill);
        canvas.drawRect(rect, _areaLocalBorder);
      }
    }

    // 3. Fog of War nas células não reveladas
    if (reveladas.length < largura * altura) {
      for (int y = 0; y < altura; y++) {
        for (int x = 0; x < largura; x++) {
          if (reveladas.contains(Posicao2D(x, y))) continue;
          canvas.drawRect(
            Rect.fromLTWH(x * cellW, y * cellH, cellW, cellH),
            _fogPaint,
          );
        }
      }
    }

    // 4. Linhas do grid
    if (snapshot.gridVisivel) {
      _gridPaint.color = Colors.white.withValues(
        alpha: snapshot.opacidadeGrid * 0.45,
      );
      for (int x = 0; x <= largura; x++) {
        final dx = x * cellW;
        canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), _gridPaint);
      }
      for (int y = 0; y <= altura; y++) {
        final dy = y * cellH;
        canvas.drawLine(Offset(0, dy), Offset(size.width, dy), _gridPaint);
      }
    }

    // 5. Bordas de alcance e badges de custo em metros
    if (celulasAlcancaveis.isNotEmpty) {
      for (final pos in celulasAlcancaveis) {
        if (!_dentroLimites(pos, largura, altura) || !reveladas.contains(pos)) {
          continue;
        }
        final rect = Rect.fromLTWH(pos.x * cellW, pos.y * cellH, cellW, cellH);
        canvas.drawRect(rect, _alcanceBorder);

        final custo = custosMovimento[pos];
        if (custo != null) {
          final tp = _obterTextPainterCusto(custo, compacto);
          final bgWidth = tp.width + 4;
          final bgHeight = tp.height + 1;
          if (bgWidth <= cellW && bgHeight <= cellH) {
            final bgRect = RRect.fromRectAndRadius(
              Rect.fromLTWH(
                rect.right - bgWidth - 1,
                rect.bottom - bgHeight - 1,
                bgWidth,
                bgHeight,
              ),
              const Radius.circular(3),
            );
            canvas.drawRRect(bgRect, _pillBgPaint);
            tp.paint(canvas, Offset(bgRect.left + 2, bgRect.top + 0.5));
          }
        }
      }
    }

    // 6. Círculo duplo ◎ nas interseções de 4 quadrados (Esfera/Cilindro)
    for (final area in snapshot.areasEfeitoVisiveis) {
      final v = area.centroVertice;
      if (v == null) continue;
      final center = Offset(v.vx * cellW, v.vy * cellH);
      canvas.drawCircle(center, 6.0, _centroVerticeBg);
      canvas.drawCircle(center, 6.0, _centroVerticeOuter);
      canvas.drawCircle(center, 3.5, _centroVerticeInner);
    }
    if (centroVerticeLocal != null) {
      final center = Offset(
        centroVerticeLocal!.vx * cellW,
        centroVerticeLocal!.vy * cellH,
      );
      canvas.drawCircle(center, 6.5, _centroVerticeBg);
      canvas.drawCircle(center, 6.5, _centroVerticeOuter);
      canvas.drawCircle(center, 3.8, _centroVerticeInner);
    }
  }

  @override
  bool shouldRepaint(covariant MapaJogadorGridPainter oldDelegate) {
    return oldDelegate.compacto != compacto ||
        oldDelegate.snapshot.largura != snapshot.largura ||
        oldDelegate.snapshot.altura != snapshot.altura ||
        oldDelegate.snapshot.gridVisivel != snapshot.gridVisivel ||
        oldDelegate.snapshot.opacidadeGrid != snapshot.opacidadeGrid ||
        oldDelegate.centroVerticeLocal != centroVerticeLocal ||
        (!identical(oldDelegate.celulasAreaLocal, celulasAreaLocal) &&
            !setEquals(oldDelegate.celulasAreaLocal, celulasAreaLocal)) ||
        (!identical(
              oldDelegate.snapshot.areasEfeitoVisiveis,
              snapshot.areasEfeitoVisiveis,
            ) &&
            !listEquals(
              oldDelegate.snapshot.areasEfeitoVisiveis,
              snapshot.areasEfeitoVisiveis,
            )) ||
        (!identical(oldDelegate.snapshot.terrenos, snapshot.terrenos) &&
            !mapEquals(oldDelegate.snapshot.terrenos, snapshot.terrenos)) ||
        (!identical(
              oldDelegate.snapshot.celulasReveladas,
              snapshot.celulasReveladas,
            ) &&
            !setEquals(
              oldDelegate.snapshot.celulasReveladas,
              snapshot.celulasReveladas,
            )) ||
        (!identical(oldDelegate.celulasAlcancaveis, celulasAlcancaveis) &&
            !setEquals(oldDelegate.celulasAlcancaveis, celulasAlcancaveis)) ||
        (!identical(oldDelegate.custosMovimento, custosMovimento) &&
            !mapEquals(oldDelegate.custosMovimento, custosMovimento));
  }
}
