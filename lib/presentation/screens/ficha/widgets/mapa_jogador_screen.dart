import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/entities/combate/combatente.dart';
import '../../../../domain/entities/combate/grid_tatico.dart';
import '../../../../domain/entities/entidade_sessao_lan/sessao_lan_modelos.dart';
import '../../../../domain/entities/mestre/modelos_mestre.dart';
import '../../../../domain/services/combate_services/movimento_engine.dart';
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
  String? _tokenSelecionadoId;

  Color _corFundoMapa(PresetFundoMapa preset) => switch (preset) {
    PresetFundoMapa.masmorraPedra => const Color(0xFF1E293B),
    PresetFundoMapa.florestaArton => const Color(0xFF143321),
    PresetFundoMapa.tavernaMadeira => const Color(0xFF3E2723),
    PresetFundoMapa.desertoHalakTur => const Color(0xFF4E3B1E),
    PresetFundoMapa.areaTormenta => const Color(0xFF3B0A1E),
    PresetFundoMapa.imagemCustomizada => const Color(0xFF1E293B),
  };

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

  @override
  Widget build(BuildContext context) {
    final personagem = context.select(
      (FichaCubit c) => (
        id: c.personagem.id,
        deslocamento: c.personagem.deslocamentoEfetivoMetros.toDouble(),
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

        final movendoProprio = _tokenSelecionadoId == meuCharId;
        final alcance = _calcularAlcance(
          snap,
          meuCharId,
          personagem.deslocamento,
        );

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
              Expanded(
                child: InteractiveViewer(
                  minScale: widget.compacto ? 0.35 : 0.5,
                  maxScale: 3.0,
                  boundaryMargin: EdgeInsets.all(widget.compacto ? 24 : 64),
                  child: Center(
                    child: _buildGrid(
                      snap,
                      meuCharId,
                      alcance.destinos,
                      alcance.custos,
                    ),
                  ),
                ),
              ),
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

  Widget _buildGrid(
    SnapshotMesa snap,
    String meuCharId,
    Set<Posicao2D> alcancaveis,
    Map<Posicao2D, double> custos,
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
          // Grade, Terrenos, Alcance e Fog of War
          for (int y = 0; y < snap.altura; y++)
            for (int x = 0; x < snap.largura; x++)
              Positioned(
                left: x * cellSize,
                top: y * cellSize,
                width: cellSize,
                height: cellSize,
                child: _buildCelula(
                  snap,
                  x,
                  y,
                  meuCharId,
                  alcancaveis,
                  custos,
                ),
              ),
          // Tokens visíveis ao jogador
          for (final tok in snap.tokensVisiveis)
            if (snap.celulasReveladas.isEmpty ||
                tok.ehHeroi ||
                snap.celulasReveladas.contains(tok.posicao))
              Positioned(
                left: tok.posicao.x * cellSize,
                top: tok.posicao.y * cellSize,
                width: tok.tamanhoQuadrados * cellSize,
                height: tok.tamanhoQuadrados * cellSize,
                child: GestureDetector(
                  onTap: () => setState(() {
                    _tokenSelecionadoId =
                        _tokenSelecionadoId == tok.id ? null : tok.id;
                  }),
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

  Widget _buildCelula(
    SnapshotMesa snap,
    int x,
    int y,
    String meuCharId,
    Set<Posicao2D> alcancaveis,
    Map<Posicao2D, double> custos,
  ) {
    final pos = Posicao2D(x, y);
    final revelada =
        snap.celulasReveladas.isEmpty || snap.celulasReveladas.contains(pos);
    final terreno = revelada
        ? (snap.terrenos[pos] ?? TipoTerreno.normal)
        : TipoTerreno.normal;
    final alcancavel = revelada && alcancaveis.contains(pos);
    final custo = custos[pos];
    final podeMoverAqui =
        _tokenSelecionadoId == meuCharId &&
        revelada &&
        terreno != TipoTerreno.obstaculo &&
        (alcancaveis.isEmpty || alcancavel);

    Color corCelula;
    if (!revelada) {
      corCelula = Colors.black.withValues(alpha: 0.78);
    } else if (terreno == TipoTerreno.obstaculo) {
      corCelula = Colors.black.withValues(alpha: 0.72);
    } else if (alcancavel) {
      corCelula = const Color(0xFF38BDF8).withValues(alpha: 0.35);
    } else if (terreno == TipoTerreno.dificil) {
      corCelula = const Color(0xFFD97706).withValues(alpha: 0.35);
    } else {
      corCelula = Colors.transparent;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: podeMoverAqui
          ? () {
              context.read<SessaoJogadorCubit>().moverMeuToken(pos);
              setState(() => _tokenSelecionadoId = null);
            }
          : null,
      child: Container(
        key: revelada && terreno == TipoTerreno.obstaculo
            ? ValueKey('celula_obstaculo_${x}_$y')
            : (revelada && terreno == TipoTerreno.dificil
                  ? ValueKey('celula_dificil_${x}_$y')
                  : (alcancavel ? ValueKey('celula_alcancavel_${x}_$y') : null)),
        decoration: BoxDecoration(
          color: corCelula,
          border: alcancavel
              ? Border.all(color: Colors.cyanAccent, width: 1.4)
              : (snap.gridVisivel
                    ? Border.all(
                        color: Colors.white.withValues(
                          alpha: snap.opacidadeGrid * 0.45,
                        ),
                        width: 0.5,
                      )
                    : null),
        ),
        child: Stack(
          children: [
            if (revelada && terreno == TipoTerreno.obstaculo)
              Center(
                child: Icon(
                  Icons.close,
                  size: widget.compacto ? 13 : 18,
                  color: Colors.white38,
                ),
              ),
            if (revelada && terreno == TipoTerreno.dificil)
              Positioned(
                top: 1,
                right: 1,
                child: Icon(
                  Icons.change_history_rounded,
                  size: widget.compacto ? 9 : 12,
                  color: Colors.amberAccent,
                ),
              ),
            if (alcancavel && custo != null)
              Positioned(
                right: 1,
                bottom: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 0.5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    '${custo.toStringAsFixed(1)}m',
                    style: TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: widget.compacto ? 6.5 : 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
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
