import 'package:flutter/material.dart';
import '../../../domain/entities/personagem/personagem.dart';
import '../../../domain/services/calculo_ficha_service.dart';

/// Abre o diálogo de rolagem inteligente de perícia em 1 toque,
/// já preenchido e rolado com todas as parcelas vindas do domínio.
Future<void> mostrarDialogoRolagemPericia(
  BuildContext context, {
  required Personagem personagem,
  required String periciaKey,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _DialogoRolagemInteligente(
      gerarRolagem: (modSituacional) => CalculoFichaService.rolarPericia(
        personagem,
        periciaKey,
        modificadorSituacional: modSituacional,
      ),
    ),
  );
}

/// Abre o diálogo de rolagem em 1 toque para teste puro de Atributo (FOR, DES, etc.).
Future<void> mostrarDialogoRolagemAtributo(
  BuildContext context, {
  required Personagem personagem,
  required String siglaAtributo,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _DialogoRolagemInteligente(
      gerarRolagem: (modSituacional) => CalculoFichaService.rolarAtributo(
        personagem,
        siglaAtributo,
        modificadorSituacional: modSituacional,
      ),
    ),
  );
}

/// Mantido com assinatura compatível para rolagens livres de dados (d4..d100) e legado.
Future<void> mostrarDialogoRolagemDado(
  BuildContext context, {
  required int lados,
  required int mod,
  required String rotulo,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _DialogoRolagemInteligente(
      gerarRolagem: (modSituacional) => CalculoFichaService.rolarDadosLivres(
        quantidadeDados: 1,
        facesDado: lados,
        modificador: mod,
        tituloCustom: rotulo,
      ),
      permitirSituacional: lados == 20,
    ),
  );
}

class _DialogoRolagemInteligente extends StatefulWidget {
  final ResultadoRolagemDado Function(int modSituacional) gerarRolagem;
  final bool permitirSituacional;

  const _DialogoRolagemInteligente({
    required this.gerarRolagem,
    this.permitirSituacional = true,
  });

  @override
  State<_DialogoRolagemInteligente> createState() =>
      _DialogoRolagemInteligenteState();
}

class _DialogoRolagemInteligenteState
    extends State<_DialogoRolagemInteligente> {
  int _modSituacional = 0;
  late ResultadoRolagemDado _resultado;

  @override
  void initState() {
    super.initState();
    _resultado = widget.gerarRolagem(0);
  }

  void _rerrolar() {
    setState(() {
      _resultado = widget.gerarRolagem(_modSituacional);
    });
  }

  void _ajustarSituacional(int novoMod) {
    setState(() {
      _modSituacional = novoMod.clamp(-30, 30);
      _resultado = ResultadoRolagemDado(
        titulo: _resultado.titulo,
        subtitulo: _resultado.subtitulo,
        quantidadeDados: _resultado.quantidadeDados,
        facesDado: _resultado.facesDado,
        valoresDados: _resultado.valoresDados,
        parcelasFixas: _resultado.parcelasFixas,
        modificadorSituacional: _modSituacional,
        bloqueadaSemTreino: _resultado.bloqueadaSemTreino,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final critico = _resultado.ehCriticoNatural;
    final falha = _resultado.ehFalhaCriticaNatural;

    final corDestaque = critico
        ? const Color(0xFFB45309)
        : falha
        ? const Color(0xFFB71C1C)
        : const Color(0xFF1E293B);

    final corFundoDado = critico
        ? const Color(0xFFFEF3C7)
        : falha
        ? const Color(0xFFFEE2E2)
        : const Color(0xFFF8FAFC);

    final corBordaDado = critico
        ? const Color(0xFFF59E0B)
        : falha
        ? const Color(0xFFEF4444)
        : const Color(0xFFCBD5E1);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabeçalho da Rolagem
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD32F2F).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.casino_rounded,
                      color: Color(0xFFD32F2F),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _resultado.titulo,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        if (_resultado.subtitulo.isNotEmpty)
                          Text(
                            _resultado.subtitulo,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                  ),
                ],
              ),

              if (_resultado.bloqueadaSemTreino) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF59E0B)),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 18,
                        color: Color(0xFFB45309),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Perícia Somente Treinada: pelas regras de T20, exige treinamento para realizar testes.',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Bloco Principal: Dado Natural + Resultado Final
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: corFundoDado,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: corBordaDado, width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        Text(
                          '${_resultado.quantidadeDados}d${_resultado.facesDado}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_resultado.somaDados}',
                          key: const Key('rolagem_valor_dado'),
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: corDestaque,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 1.5,
                      height: 44,
                      color: corBordaDado,
                    ),
                    Column(
                      children: [
                        const Text(
                          'RESULTADO FINAL',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: Color(0xFFD32F2F),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_resultado.totalFinal}',
                          key: const Key('rolagem_resultado_final'),
                          style: const TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (critico)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF10B981)),
                    ),
                    child: const Text(
                      '20 NATURAL! SUCESSO AUTOMÁTICO / CRÍTICO!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF047857),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),

              if (falha)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFEF4444)),
                    ),
                    child: const Text(
                      '1 NATURAL! FALHA AUTOMÁTICA!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFB91C1C),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 14),

              // Composição do Cálculo (parcela por parcela)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'COMPOSIÇÃO DO CÁLCULO',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildChipParcela(
                          rotulo:
                              'Dado (${_resultado.quantidadeDados}d${_resultado.facesDado})',
                          valor: '${_resultado.somaDados}',
                          corFundo: Colors.white,
                          corTexto: const Color(0xFF0F172A),
                        ),
                        ..._resultado.parcelasFixas.map(
                          (p) => _buildChipParcela(
                            rotulo: p.rotulo,
                            valor: p.valorFormatado,
                            corFundo: p.ehPenalidade
                                ? const Color(0xFFFEF2F2)
                                : Colors.white,
                            corTexto: p.ehPenalidade
                                ? const Color(0xFFB91C1C)
                                : const Color(0xFF1E293B),
                          ),
                        ),
                        if (_modSituacional != 0)
                          _buildChipParcela(
                            rotulo: 'Situacional',
                            valor: _modSituacional > 0
                                ? '+$_modSituacional'
                                : '$_modSituacional',
                            corFundo: const Color(0xFFEFF6FF),
                            corTexto: const Color(0xFF1D4ED8),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              if (widget.permitirSituacional) ...[
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    const Text(
                      'Mod. Situacional:',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _BotaoAjusteSituacional(
                          rotulo: '-2',
                          onTap: () =>
                              _ajustarSituacional(_modSituacional - 2),
                        ),
                        const SizedBox(width: 4),
                        _BotaoAjusteSituacional(
                          rotulo: '-1',
                          onTap: () =>
                              _ajustarSituacional(_modSituacional - 1),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: InkWell(
                            onTap: () => _ajustarSituacional(0),
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 8,
                              ),
                              child: Text(
                                _modSituacional >= 0
                                    ? '+$_modSituacional'
                                    : '$_modSituacional',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ),
                        ),
                        _BotaoAjusteSituacional(
                          rotulo: '+1',
                          onTap: () =>
                              _ajustarSituacional(_modSituacional + 1),
                        ),
                        const SizedBox(width: 4),
                        _BotaoAjusteSituacional(
                          rotulo: '+2',
                          onTap: () =>
                              _ajustarSituacional(_modSituacional + 2),
                        ),
                      ],
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),

              // Botões de ação com alvos >= 48px
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        foregroundColor: const Color(0xFFD32F2F),
                        side: const BorderSide(color: Color(0xFFD32F2F)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _rerrolar,
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      label: const Text(
                        'Rolar de Novo',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        backgroundColor: const Color(0xFFD32F2F),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Concluir',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChipParcela({
    required String rotulo,
    required String valor,
    required Color corFundo,
    required Color corTexto,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: corFundo,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$rotulo: ',
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            valor,
            style: TextStyle(
              fontSize: 12.5,
              color: corTexto,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _BotaoAjusteSituacional extends StatelessWidget {
  final String rotulo;
  final VoidCallback onTap;

  const _BotaoAjusteSituacional({required this.rotulo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          child: Center(
            child: Text(
              rotulo,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF334155),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
