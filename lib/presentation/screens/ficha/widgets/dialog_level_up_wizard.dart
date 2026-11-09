import 'package:flutter/material.dart';
import '../../../../domain/entities/personagem/personagem.dart';
import '../../../../domain/entities/personagem/resumo_level_up.dart';
import '../../../../domain/services/powers_service/aprendizado_magia_service.dart';
import '../../../controllers/ficha_controller/ficha_cubit.dart';
import '../../wizard_personagem/selecao_poderes_screen.dart';
import 'modal_catalogo_magias.dart';

/// Modal interativo guiado de Level Up para Tormenta 20.
/// Apresenta o resumo do nível alcançado, PV/PM ganhos, novo círculo de magia desbloqueado
/// e guia o jogador passo a passo para escolher seus poderes e magias pendentes.
class DialogLevelUpWizard extends StatefulWidget {
  final ResumoLevelUp resumoInicial;
  final FichaCubit cubit;

  const DialogLevelUpWizard({
    super.key,
    required this.resumoInicial,
    required this.cubit,
  });

  @override
  State<DialogLevelUpWizard> createState() => _DialogLevelUpWizardState();
}

class _DialogLevelUpWizardState extends State<DialogLevelUpWizard> {
  late ResumoLevelUp _resumo;

  @override
  void initState() {
    super.initState();
    _resumo = widget.resumoInicial;
  }

  void _recalcularResumo(Personagem personagemAtualizado) {
    setState(() {
      _resumo = ResumoLevelUp.calcular(
        anterior: _resumo.personagemAnterior,
        atualizado: personagemAtualizado,
        indiceClasse: _resumo.indiceClasse < personagemAtualizado.classes.length
            ? _resumo.indiceClasse
            : 0,
      );
    });
  }

  Future<void> _abrirEscolhaPoder() async {
    final pAtual = widget.cubit.personagem;
    final atualizado = await Navigator.push<Personagem>(
      context,
      MaterialPageRoute(
        builder: (_) => SelecaoPoderesScreen(
          personagem: pAtual,
          indiceClasse: _resumo.indiceClasse,
        ),
      ),
    );

    if (atualizado != null && mounted) {
      await widget.cubit.atualizarPersonagem(atualizado);
      _recalcularResumo(widget.cubit.personagem);
    }
  }

  Future<void> _abrirEscolhaMagia() async {
    final pAtual = widget.cubit.personagem;
    final magiaAprendida = await abrirModalCatalogoMagias(
      context: context,
      personagem: pAtual,
      cubit: widget.cubit,
      circuloInicial: _resumo.novoCirculoDesbloqueado ?? 0,
      filtroTipoInicial: _resumo.tipoMagiaDesbloqueada,
    );

    if (magiaAprendida != null && mounted) {
      _recalcularResumo(widget.cubit.personagem);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✨ Magia "${magiaAprendida.nome}" aprendida com sucesso!'),
          backgroundColor: const Color(0xFF1D4ED8),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cl = widget.cubit.personagem.classes.isNotEmpty &&
            _resumo.indiceClasse < widget.cubit.personagem.classes.length
        ? widget.cubit.personagem.classes[_resumo.indiceClasse]
        : null;

    final poderesPendentes = cl?.poderesPendentes ?? 0;
    final magiasPendentes = AprendizadoMagiaService.calcularMagiasPendentesPersonagem(
      widget.cubit.personagem,
    );
    final ehConjurador = _resumo.tipoMagiaDesbloqueada != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A), // Fundo Dark Fantasy
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.amber.shade700, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Cabeçalho de Destaque
            _buildCabecalho(context),

            // Conteúdo Rolável
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Ganhos Básicos (PV, PM, Patamar)
                    _buildCardsGanhosBasicos(),

                    const SizedBox(height: 12),

                    // Destaque de Novo Círculo de Magia (se houver)
                    if (_resumo.desbloqueouNovoCirculo) ...[
                      _buildCardNovoCirculoMagico(),
                      const SizedBox(height: 12),
                    ],

                    // Características ganhas da classe
                    if (_resumo.caracteristicasNovas.isNotEmpty) ...[
                      _buildSecaoCaracteristicas(),
                      const SizedBox(height: 12),
                    ],

                    // Etapas de Ação Guiada
                    const Text(
                      'AÇÕES DA EVOLUÇÃO',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 1. Escolha de Poder
                    _buildCardAcaoPoder(poderesPendentes),

                    const SizedBox(height: 8),

                    // 2. Escolha de Magia (se conjurador)
                    if (ehConjurador)
                      _buildCardAcaoMagia(magiasPendentes),
                  ],
                ),
              ),
            ),

            // Rodapé com Botão Concluir
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text(
                    'CONCLUIR EVOLUÇÃO',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCabecalho(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
        border: Border(
          bottom: BorderSide(color: Colors.amber.shade700.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.amber.shade900.withValues(alpha: 0.3),
              border: Border.all(color: Colors.amber, width: 1.5),
            ),
            child: const Icon(Icons.stars_rounded, color: Colors.amber, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SUBIU DE NÍVEL! 🎉',
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  '${_resumo.nomeClasse} Nível ${_resumo.nivelIndividualClasse} • Nível Total ${_resumo.nivelTotalPersonagem}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildCardsGanhosBasicos() {
    return Row(
      children: [
        // PV
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.shade900.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.favorite, color: Color(0xFFEF4444), size: 20),
                const SizedBox(width: 6),
                Text(
                  '+${_resumo.deltaPV} PV Máx',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // PM
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.shade900.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.water_drop, color: Color(0xFF3B82F6), size: 20),
                const SizedBox(width: 6),
                Text(
                  '+${_resumo.deltaPM} PM Máx',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_resumo.novoPatamarAlcancado) ...[
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.amber.shade900.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.workspace_premium, color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      _resumo.patamar.label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCardNovoCirculoMagico() {
    final circ = _resumo.novoCirculoDesbloqueado!;
    final tipo = _resumo.tipoMagiaDesbloqueada?.toUpperCase() ?? 'MÁGICO';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4C1D95), // Roxo místico
            const Color(0xFF1E1B4B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.purpleAccent, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.purple.shade900.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.amber, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'NOVO CÍRCULO DESBLOQUEADO!',
                      style: TextStyle(
                        color: Colors.amber.shade300,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Magias de $circº Círculo ($tipo) já estão liberadas no grimório!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Acesse magias mais poderosas com novos aprimoramentos e efeitos devastadores.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecaoCaracteristicas() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Habilidades de Classe Adquiridas:',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: _resumo.caracteristicasNovas.map((hab) {
              return Chip(
                backgroundColor: const Color(0xFF0F172A),
                side: const BorderSide(color: Colors.amber, width: 0.8),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                label: Text(
                  hab,
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCardAcaoPoder(int poderesPendentes) {
    final temPendente = poderesPendentes > 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: temPendente ? Colors.amber.shade700 : Colors.green.shade800,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            temPendente ? Icons.military_tech : Icons.check_circle,
            color: temPendente ? Colors.amber : Colors.greenAccent,
            size: 26,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Poder de Classe / Geral',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  temPendente
                      ? '$poderesPendentes ${poderesPendentes == 1 ? "vaga pendente" : "vagas pendentes"}'
                      : 'Poderes em dia',
                  style: TextStyle(
                    color: temPendente ? Colors.amber.shade200 : Colors.greenAccent,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: temPendente ? Colors.amber.shade700 : const Color(0xFF334155),
                foregroundColor: temPendente ? Colors.black : Colors.white70,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _abrirEscolhaPoder,
              child: Text(
                temPendente ? 'Escolher' : 'Gerenciar',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardAcaoMagia(int magiasPendentes) {
    final temPendente = magiasPendentes > 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: temPendente ? const Color(0xFF60A5FA) : Colors.green.shade800,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            temPendente ? Icons.auto_stories : Icons.check_circle,
            color: temPendente ? const Color(0xFF60A5FA) : Colors.greenAccent,
            size: 26,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Grimório de Magias',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  temPendente
                      ? '$magiasPendentes ${magiasPendentes == 1 ? "magia para aprender" : "magias para aprender"}'
                      : 'Grimório em dia',
                  style: TextStyle(
                    color: temPendente ? const Color(0xFF93C5FD) : Colors.greenAccent,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: temPendente ? const Color(0xFF2563EB) : const Color(0xFF334155),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _abrirEscolhaMagia,
              child: Text(
                temPendente ? 'Aprender' : 'Catálogo',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper para abrir o modal guiado de Level Up
Future<void> mostrarDialogLevelUpWizard({
  required BuildContext context,
  required ResumoLevelUp resumo,
  required FichaCubit cubit,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => DialogLevelUpWizard(
      resumoInicial: resumo,
      cubit: cubit,
    ),
  );
}
