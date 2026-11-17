import 'package:flutter/material.dart';

/// Layout mestre-detalhe responsivo compartilhado entre as etapas de escolha
/// do wizard (Origens, Classes, Divindades).
///
/// - Em telas largas (`>= breakpoint`, padrão 600 dp): exibe a lista lateral
///   vermelha (recolhível) ao lado do painel de detalhes.
/// - Em telas estreitas (`< breakpoint`): exibe a lista em tela cheia e, ao
///   tocar em um item, alterna para o painel de detalhes em tela cheia com
///   barra superior de retorno, evitando compressão horizontal e overflows.
class SeletorMestreDetalheResponsivo extends StatefulWidget {
  final Widget Function(
    BuildContext context, {
    required bool modoCompacto,
    required VoidCallback onItemSelecionado,
  })
  listaBuilder;

  final Widget Function(
    BuildContext context, {
    required bool modoCompacto,
    required VoidCallback onVoltarLista,
  })
  detalheBuilder;

  /// Se `true` ao montar o widget, abre diretamente no detalhe em modo compacto
  /// (por exemplo, quando já existe uma escolha pré-selecionada).
  final bool temSelecaoInicial;

  /// Título exibido no botão de retorno no modo compacto (ex.: "Todas as Origens").
  final String labelVoltarLista;

  /// Subtítulo opcional à direita da barra de retorno no modo compacto
  /// (ex.: nome do item selecionado atualmente).
  final String? resumoSelecionado;

  /// Breakpoint em dp para alternar entre modo compacto e modo lado a lado.
  final double breakpoint;

  /// Cor de fundo do menu lateral no modo lado a lado.
  final Color corListaWide;

  /// Cor da alça recolhedora no modo lado a lado.
  final Color corAlcaWide;

  const SeletorMestreDetalheResponsivo({
    super.key,
    required this.listaBuilder,
    required this.detalheBuilder,
    this.temSelecaoInicial = false,
    required this.labelVoltarLista,
    this.resumoSelecionado,
    this.breakpoint = 600,
    this.corListaWide = const Color(0xFFE53935),
    this.corAlcaWide = const Color(0xFFB71C1C),
  });

  @override
  State<SeletorMestreDetalheResponsivo> createState() =>
      _SeletorMestreDetalheResponsivoState();
}

class _SeletorMestreDetalheResponsivoState
    extends State<SeletorMestreDetalheResponsivo> {
  bool _menuWideAberto = true;
  late bool _exibindoDetalheCompacto;

  @override
  void initState() {
    super.initState();
    _exibindoDetalheCompacto = widget.temSelecaoInicial;
  }

  void _abrirDetalheCompacto() {
    if (!_exibindoDetalheCompacto) {
      setState(() => _exibindoDetalheCompacto = true);
    }
  }

  void _voltarListaCompacta() {
    if (_exibindoDetalheCompacto) {
      setState(() => _exibindoDetalheCompacto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ehWide = constraints.maxWidth >= widget.breakpoint;
        if (ehWide) {
          return _buildModoWide(constraints.maxWidth);
        }
        return _buildModoCompacto();
      },
    );
  }

  Widget _buildModoCompacto() {
    if (!_exibindoDetalheCompacto) {
      return Container(
        color: Colors.white,
        width: double.infinity,
        child: widget.listaBuilder(
          context,
          modoCompacto: true,
          onItemSelecionado: _abrirDetalheCompacto,
        ),
      );
    }

    return Container(
      color: Colors.white,
      width: double.infinity,
      child: Column(
        children: [
          Material(
            color: const Color(0xFFF8FAFC),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Flexible(
                    child: TextButton.icon(
                      onPressed: _voltarListaCompacta,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFB71C1C),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        minimumSize: const Size(0, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: Text(
                        widget.labelVoltarLista,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  if (widget.resumoSelecionado != null &&
                      widget.resumoSelecionado!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.resumoSelecionado!,
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            child: widget.detalheBuilder(
              context,
              modoCompacto: true,
              onVoltarLista: _voltarListaCompacta,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModoWide(double larguraDisponivel) {
    final larguraMenu = (larguraDisponivel * 0.28).clamp(160.0, 240.0);

    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          width: _menuWideAberto ? larguraMenu : 0,
          color: widget.corListaWide,
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.topLeft,
              minWidth: larguraMenu,
              maxWidth: larguraMenu,
              child: widget.listaBuilder(
                context,
                modoCompacto: false,
                onItemSelecionado: () {},
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () => setState(() => _menuWideAberto = !_menuWideAberto),
          child: Container(
            width: 24,
            color: widget.corAlcaWide,
            child: Center(
              child: Icon(
                _menuWideAberto ? Icons.chevron_left : Icons.chevron_right,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
        Expanded(
          child: Container(
            color: Colors.white,
            child: widget.detalheBuilder(
              context,
              modoCompacto: false,
              onVoltarLista: () => setState(() => _menuWideAberto = true),
            ),
          ),
        ),
      ],
    );
  }
}
