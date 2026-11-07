import 'package:flutter/material.dart';
import '../../../../domain/entities/combate/combatente.dart';
import '../../../../domain/entities/personagem/personagem.dart';
import '../../../../domain/services/combate_services/dice_roll_service.dart';
import 'd20_dice.dart';
import 'roll_result_view.dart';
import '../../../widgets/character_avatar_widget.dart';

enum EtapaIniciativa {
  aguardandoHeroi,
  rolandoHeroi,
  resultadoHeroi,
  aguardandoInimigo,
  rolandoInimigo,
  ordemFinal,
}

/// Tela de rolagem de iniciativa tática com d20 icosaédrico 3D animado.
///
/// Fluxo estrito:
/// 1. D20 icosaedro em repouso.
/// 2. Jogador toca em "Rolar Iniciativa" -> dado gira/quica com desaceleração.
/// 3. Resultado estilo Baldur's Gate 3 revelado (d20 + bônus = total).
/// 4. Jogador confirma seu resultado antes de prosseguir.
/// 5. Rolagem do inimigo com a mesma animação 3D.
/// 6. Exibição da ordem de iniciativa e botão "Iniciar combate".
class RolarIniciativaView extends StatefulWidget {
  final Personagem heroi;
  final List<Combatente> inimigos;
  final void Function(int totalHeroi, Map<String, int> totaisInimigos)
  onIniciarCombate;
  final DiceRollService? diceService;

  const RolarIniciativaView({
    super.key,
    required this.heroi,
    required this.inimigos,
    required this.onIniciarCombate,
    this.diceService,
  });

  @override
  State<RolarIniciativaView> createState() => _RolarIniciativaViewState();
}

class _RolarIniciativaViewState extends State<RolarIniciativaView> {
  late final DiceRollService _diceService;
  EtapaIniciativa _etapa = EtapaIniciativa.aguardandoHeroi;

  ResultadoD20? _resultadoHeroi;
  int _indiceInimigoAtual = 0;
  final Map<String, ResultadoD20> _resultadosInimigos = {};

  @override
  void initState() {
    super.initState();
    _diceService = widget.diceService ?? DiceRollService();
  }

  void _rolarIniciativaHeroi() {
    final modIniciativa = widget.heroi.getValorPericia('INICIATIVA');
    final resultado = _diceService.rolarD20(
      modificador: modIniciativa,
      nomeModificador: 'Iniciativa',
    );

    setState(() {
      _resultadoHeroi = resultado;
      _etapa = EtapaIniciativa.rolandoHeroi;
    });
  }

  void _aoTerminarAnimacaoHeroi() {
    if (_etapa == EtapaIniciativa.rolandoHeroi) {
      setState(() {
        _etapa = EtapaIniciativa.resultadoHeroi;
      });
    }
  }

  void _iniciarRolagemInimigo() {
    if (widget.inimigos.isEmpty) {
      setState(() => _etapa = EtapaIniciativa.ordemFinal);
      return;
    }

    final inimigoAtual = widget.inimigos[_indiceInimigoAtual];
    final resultado = _diceService.rolarD20(
      modificador: inimigoAtual.modIniciativa,
      nomeModificador: 'Iniciativa (${inimigoAtual.nome})',
    );

    setState(() {
      _resultadosInimigos[inimigoAtual.id] = resultado;
      _etapa = EtapaIniciativa.rolandoInimigo;
    });
  }

  void _aoTerminarAnimacaoInimigo() {
    if (_etapa == EtapaIniciativa.rolandoInimigo) {
      if (_indiceInimigoAtual + 1 < widget.inimigos.length) {
        setState(() {
          _indiceInimigoAtual++;
          _etapa = EtapaIniciativa.aguardandoInimigo;
        });
      } else {
        setState(() {
          _etapa = EtapaIniciativa.ordemFinal;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final modHeroi = widget.heroi.getValorPericia('INICIATIVA');
    final inimigoAtual =
        widget.inimigos.isNotEmpty &&
            _indiceInimigoAtual < widget.inimigos.length
        ? widget.inimigos[_indiceInimigoAtual]
        : null;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Cabeçalho Informativo
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.casino_outlined,
                    color: Colors.amberAccent,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Rolagem de Iniciativa',
                      style: textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Descubra quem age primeiro no combate tático.',
                style: textTheme.bodyMedium?.copyWith(color: Colors.white60),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // 2. Dado D20 Icosaédrico 3D Central
              Center(
                child: D20Dice(
                  key: ValueKey(_etapa),
                  valorFinal: _obterValorDadoAtivo(),
                  rolando:
                      _etapa == EtapaIniciativa.rolandoHeroi ||
                      _etapa == EtapaIniciativa.rolandoInimigo,
                  size: 140,
                  onRolagemConcluida:
                      _etapa == EtapaIniciativa.rolandoHeroi
                          ? _aoTerminarAnimacaoHeroi
                          : _aoTerminarAnimacaoInimigo,
                ),
              ),
              const SizedBox(height: 24),

              // 3. Resultado BG3 / Conteúdo dinâmico conforme a etapa
              _buildConteudoEtapa(context, modHeroi, inimigoAtual),
            ],
          ),
        ),
      ),
    );
  }

  int? _obterValorDadoAtivo() {
    if (_etapa == EtapaIniciativa.rolandoHeroi ||
        _etapa == EtapaIniciativa.resultadoHeroi) {
      return _resultadoHeroi?.d20;
    }
    if (_etapa == EtapaIniciativa.rolandoInimigo ||
        _etapa == EtapaIniciativa.ordemFinal) {
      final inimigo =
          widget.inimigos.isNotEmpty
              ? widget.inimigos[_indiceInimigoAtual]
              : null;
      if (inimigo != null) {
        return _resultadosInimigos[inimigo.id]?.d20;
      }
    }
    return 20;
  }

  Widget _buildConteudoEtapa(
    BuildContext context,
    int modHeroi,
    Combatente? inimigoAtual,
  ) {
    switch (_etapa) {
      case EtapaIniciativa.aguardandoHeroi:
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                children: [
                  CharacterAvatarWidget(
                    personagem: widget.heroi,
                    size: 42,
                    borderRadius: 10,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.heroi.nome,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Bônus de Iniciativa: ${modHeroi >= 0 ? "+$modHeroi" : "$modHeroi"}',
                          style: const TextStyle(
                            color: Colors.amberAccent,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amberAccent,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 28),
              label: const Text(
                '🎲 Rolar Iniciativa do Herói',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              onPressed: _rolarIniciativaHeroi,
            ),
          ],
        );

      case EtapaIniciativa.rolandoHeroi:
        return const Center(
          child: Text(
            'Rolando o d20 do Herói...',
            style: TextStyle(
              color: Colors.amberAccent,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        );

      case EtapaIniciativa.resultadoHeroi:
        return Column(
          children: [
            RollResultView(
              resultado: _resultadoHeroi!,
              titulo: 'Iniciativa de ${widget.heroi.nome}',
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(
                widget.inimigos.length > 1
                    ? 'Confirmar e Rolar Inimigos'
                    : 'Confirmar e Rolar ${inimigoAtual?.nome ?? "Inimigo"}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              onPressed: _iniciarRolagemInimigo,
            ),
          ],
        );

      case EtapaIniciativa.aguardandoInimigo:
      case EtapaIniciativa.rolandoInimigo:
        return Column(
          children: [
            Text(
              'Rolando iniciativa para ${inimigoAtual?.nome ?? "Inimigo"}...',
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const LinearProgressIndicator(color: Colors.redAccent),
          ],
        );

      case EtapaIniciativa.ordemFinal:
        final totalHeroi = _resultadoHeroi?.total ?? 10;
        final primeiroInimigo =
            widget.inimigos.isNotEmpty ? widget.inimigos.first : null;
        final totalInimigo =
            primeiroInimigo != null
                ? (_resultadosInimigos[primeiroInimigo.id]?.total ?? 10)
                : 0;

        final heroiAgePrimeiro = totalHeroi >= totalInimigo;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner de Destaque da Rodada
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color:
                    heroiAgePrimeiro
                        ? Colors.blue.withValues(alpha: 0.15)
                        : Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: heroiAgePrimeiro ? Colors.blue : Colors.redAccent,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    heroiAgePrimeiro
                        ? Icons.bolt_rounded
                        : Icons.warning_amber_rounded,
                    color:
                        heroiAgePrimeiro ? Colors.blueAccent : Colors.redAccent,
                    size: 26,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      heroiAgePrimeiro
                          ? '👉 ${widget.heroi.nome} joga primeiro!'
                          : '👉 ${primeiroInimigo?.nome ?? "O Inimigo"} joga primeiro!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Comparativo de Resultados
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '🛡️ ${widget.heroi.nome}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Iniciativa $totalHeroi',
                              style: const TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_resultadoHeroi?.decomposicao.isNotEmpty ?? false)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            _resultadoHeroi!.decomposicao,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const Divider(color: Colors.white12, height: 16),
                  ...widget.inimigos.map((inimigo) {
                    final res = _resultadosInimigos[inimigo.id];
                    final total = res?.total ?? 10;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '👹 ${inimigo.nome}',
                                  style: const TextStyle(color: Colors.white70),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Iniciativa $total',
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (res?.decomposicao.isNotEmpty ?? false)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                res!.decomposicao,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Botão Principal para Iniciar Combate
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC62828),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              icon: const Icon(Icons.sports_kabaddi, size: 24),
              label: const Text(
                '⚔️ Iniciar Combate!',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              onPressed: () {
                final mapaInimigos = <String, int>{};
                for (final e in _resultadosInimigos.entries) {
                  mapaInimigos[e.key] = e.value.total;
                }
                widget.onIniciarCombate(totalHeroi, mapaInimigos);
              },
            ),
          ],
        );
    }
  }
}
