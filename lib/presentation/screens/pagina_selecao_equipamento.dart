import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/arma.dart';
import '../../domain/services/banco_armas.dart';
import '../controllers/personagem_cubit.dart';

class PaginaSelecaoEquipamento extends StatefulWidget {
  final PersonagemState state;

  const PaginaSelecaoEquipamento({super.key, required this.state});

  @override
  State<PaginaSelecaoEquipamento> createState() =>
      _PaginaSelecaoEquipamentoState();
}

class _PaginaSelecaoEquipamentoState extends State<PaginaSelecaoEquipamento> {
  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final cubit = context.read<PersonagemCubit>();
    final p = state.personagem;
    final statusCarga = state.statusCarga;
    final temProfMarcial = p.temProficienciaMarcial;

    final totalArmasNecessarias = temProfMarcial ? 2 : 1;
    int armasEscolhidas = 0;
    if (state.armaSimplesInicial != null) armasEscolhidas++;
    if (temProfMarcial && state.armaMarcialInicial != null) armasEscolhidas++;

    final bool selecaoCompleta = state.concluiuEquipamentoInicial;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ----------------------------------------------------
          // 1. HUD SUPERIOR INFORMATIVO (STATUS, CARGA, TIBARES)
          // ----------------------------------------------------
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Progresso de Escolha de Armas
                Row(
                  children: [
                    Icon(
                      selecaoCompleta
                          ? Icons.check_circle_rounded
                          : Icons.pending_actions_rounded,
                      size: 20,
                      color: selecaoCompleta
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFEA580C),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Armas: $armasEscolhidas / $totalArmasNecessarias",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),

                // Indicador de Carga
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusCarga.sobrecarregado
                        ? const Color(0xFFFEE2E2)
                        : const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: statusCarga.sobrecarregado
                          ? const Color(0xFFF87171)
                          : const Color(0xFF93C5FD),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusCarga.sobrecarregado
                            ? Icons.warning_amber_rounded
                            : Icons.inventory_2_outlined,
                        size: 15,
                        color: statusCarga.sobrecarregado
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF0284C7),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        "Carga: ${statusCarga.cargaAtual}/${statusCarga.limiteCarga}",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusCarga.sobrecarregado
                              ? const Color(0xFFB91C1C)
                              : const Color(0xFF0369A1),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Alerta visual de sobrecarga se ultrapassou o limite
          if (statusCarga.sobrecarregado)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Atenção: O peso dos itens excede seu limite de carga! Quando sobrecarregado, você sofre -2 de penalidade de armadura e tem o deslocamento reduzido.",
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF991B1B),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ----------------------------------------------------
                // 2. BANNER INFORMATIVO DE EQUIPAMENTO DE 1º NÍVEL
                // ----------------------------------------------------
                Card(
                  elevation: 0,
                  color: const Color(0xFFFFF7ED),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: Color(0xFFFED7AA)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.military_tech_rounded,
                          color: Color(0xFFC2410C),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Equipamento Inicial de 1º Nível",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xFF9A3412),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                temProfMarcial
                                    ? "Sua classe concede treino em Armas Marciais! Escolha 1 Arma Simples e 1 Arma Marcial gratuitas para iniciar suas aventuras."
                                    : "Personagens de 1º nível começam com 1 Arma Simples gratuita a sua escolha, além do kit básico de aventureiro.",
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF7C2D12),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ----------------------------------------------------
                // 3. SLOT: ARMA SIMPLES GRATUITA (OBRIGATÓRIO)
                // ----------------------------------------------------
                _buildSecaoTitulo(
                  titulo: "1. Arma Simples",
                  subtitulo: "Gratuita para todas as classes",
                  obrigatoria: true,
                  concluida: state.armaSimplesInicial != null,
                ),
                const SizedBox(height: 8),

                if (state.armaSimplesInicial == null)
                  _buildSlotVazioCard(
                    icone: Icons.colorize_rounded,
                    titulo: "Selecionar Arma Simples",
                    descricao:
                        "Toque para escolher entre adagas, lanças, arcos curtos, clavas...",
                    corDestaque: const Color(0xFFB71C1C),
                    onTap: () => _abrirSeletorArmas(
                      context: context,
                      titulo: "Escolha sua Arma Simples",
                      armas: BancoDeArmas.armasSimples(),
                      onSelecionar: (arma) {
                        cubit.selecionarArmaSimplesInicial(arma);
                      },
                    ),
                  )
                else
                  _buildCardArmaSelecionada(
                    arma: state.armaSimplesInicial!,
                    tipoSlot: "Arma Simples Gratuita",
                    onTrocar: () => _abrirSeletorArmas(
                      context: context,
                      titulo: "Trocar Arma Simples",
                      armas: BancoDeArmas.armasSimples(),
                      armaAtual: state.armaSimplesInicial,
                      onSelecionar: (arma) {
                        cubit.selecionarArmaSimplesInicial(arma);
                      },
                    ),
                    onRemover: () => cubit.removerArmaInicial(ehMarcial: false),
                  ),

                const SizedBox(height: 24),

                // ----------------------------------------------------
                // 4. SLOT: ARMA MARCIAL (CONDICIONAL À PROFICIÊNCIA)
                // ----------------------------------------------------
                _buildSecaoTitulo(
                  titulo: "2. Arma Marcial",
                  subtitulo: temProfMarcial
                      ? "Concedida pelo treino marcial da classe"
                      : "Sua classe não possui treino marcial",
                  obrigatoria: temProfMarcial,
                  concluida: !temProfMarcial || state.armaMarcialInicial != null,
                ),
                const SizedBox(height: 8),

                if (temProfMarcial) ...[
                  if (state.armaMarcialInicial == null)
                    _buildSlotVazioCard(
                      icone: Icons.shield_rounded,
                      titulo: "Selecionar Arma Marcial",
                      descricao:
                          "Toque para escolher entre espada longa, machado de batalha, montante, arco longo...",
                      corDestaque: const Color(0xFFB71C1C),
                      onTap: () => _abrirSeletorArmas(
                        context: context,
                        titulo: "Escolha sua Arma Marcial",
                        armas: BancoDeArmas.armasMarciais(),
                        onSelecionar: (arma) {
                          cubit.selecionarArmaMarcialInicial(arma);
                        },
                      ),
                    )
                  else
                    _buildCardArmaSelecionada(
                      arma: state.armaMarcialInicial!,
                      tipoSlot: "Arma Marcial Gratuita",
                      onTrocar: () => _abrirSeletorArmas(
                        context: context,
                        titulo: "Trocar Arma Marcial",
                        armas: BancoDeArmas.armasMarciais(),
                        armaAtual: state.armaMarcialInicial,
                        onSelecionar: (arma) {
                          cubit.selecionarArmaMarcialInicial(arma);
                        },
                      ),
                      onRemover: () =>
                          cubit.removerArmaInicial(ehMarcial: true),
                    ),
                ] else ...[
                  // Card explicativo elegante para não marciais
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.block_rounded,
                            size: 20,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Slot Bloqueado (${p.classes.isNotEmpty ? p.classes[0].classeDefinicao.nome : 'Classe'})",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                  color: Color(0xFF374151),
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                "Esta classe não confere proficiência com armas marciais. Você não precisa escolher este slot.",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                // ----------------------------------------------------
                // 5. SEÇÃO: DINHEIRO INICIAL (TIBARES - 4d6 T$)
                // ----------------------------------------------------
                _buildCardDinheiroInicial(
                  state: state,
                  cubit: cubit,
                ),

                const SizedBox(height: 20),

                // ----------------------------------------------------
                // 6. SEÇÃO: KIT BÁSICO DE AVENTUREIRO & ITENS
                // ----------------------------------------------------
                _buildCardKitAventureiro(state: state),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // WIDGETS AUXILIARES
  // ----------------------------------------------------

  Widget _buildSecaoTitulo({
    required String titulo,
    required String subtitulo,
    required bool obrigatoria,
    required bool concluida,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitulo,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
        if (obrigatoria)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: concluida
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: concluida
                    ? const Color(0xFF86EFAC)
                    : const Color(0xFFFCA5A5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  concluida ? Icons.check_circle : Icons.error_outline,
                  size: 13,
                  color: concluida
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFDC2626),
                ),
                const SizedBox(width: 4),
                Text(
                  concluida ? "Escolhido" : "Obrigatório",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: concluida
                        ? const Color(0xFF15803D)
                        : const Color(0xFFB91C1C),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSlotVazioCard({
    required IconData icone,
    required String titulo,
    required String descricao,
    required Color corDestaque,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD1D5DB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: corDestaque.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icone, color: corDestaque, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: corDestaque,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    descricao,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }

  Widget _buildCardArmaSelecionada({
    required Arma arma,
    required String tipoSlot,
    required VoidCallback onTrocar,
    required VoidCallback onRemover,
  }) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho da Arma
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.colorize_rounded,
                    color: Color(0xFFB71C1C),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        arma.nome,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tipoSlot,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFB71C1C),
                        ),
                      ),
                    ],
                  ),
                ),
                // Botão de Trocar
                OutlinedButton.icon(
                  onPressed: onTrocar,
                  icon: const Icon(Icons.swap_horiz, size: 16),
                  label: const Text("Trocar"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4B5563),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    visualDensity: VisualDensity.compact,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Chips com Estatísticas da Arma
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildChipInfo("Dano: ${arma.dano}", const Color(0xFFDC2626)),
                _buildChipInfo(
                  "Crítico: ${arma.criticoFormatado}",
                  const Color(0xFFB45309),
                ),
                _buildChipInfo(arma.tipoDano.label, const Color(0xFF4B5563)),
                _buildChipInfo(
                  arma.empunhadura.label,
                  const Color(0xFF2563EB),
                ),
                _buildChipInfo(arma.alcance, const Color(0xFF059669)),
                _buildChipInfo(
                  "${arma.espacos} ${arma.espacos == 1 ? 'espaço' : 'espaços'}",
                  const Color(0xFF7C3AED),
                ),
              ],
            ),

            // Propriedades Especiais (se houver)
            if (arma.propriedades.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: arma.propriedades.map((prop) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFD8B4FE)),
                    ),
                    child: Text(
                      prop[0].toUpperCase() + prop.substring(1),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6B21A8),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 10),
            Text(
              arma.descricao,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF4B5563),
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChipInfo(String texto, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: cor.withValues(alpha: 0.25)),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: cor,
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // CARD DE DINHEIRO INICIAL (TIBARES)
  // ----------------------------------------------------
  Widget _buildCardDinheiroInicial({
    required PersonagemState state,
    required PersonagemCubit cubit,
  }) {
    final tibares = state.tibaresIniciais;

    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.monetization_on_rounded,
                color: Color(0xFFD97706),
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Dinheiro Inicial (4d6 T\$)",
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    tibares == null
                      ? "Rolar 4 dados de 6 faces para determinar suas moedas iniciais."
                      : "Total rolado: T\$ $tibares (Tibares guardados para a aventura)",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                final valor = cubit.rolarDinheiroInicial();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Você rolou 4d6 e obteve T\$ $valor!"),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: Icon(
                tibares == null ? Icons.casino_outlined : Icons.refresh,
                size: 16,
              ),
              label: Text(
                tibares == null ? "Rolar" : "T\$ $tibares",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                foregroundColor: Colors.white,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // CARD DO KIT BÁSICO DE AVENTUREIRO
  // ----------------------------------------------------
  Widget _buildCardKitAventureiro({required PersonagemState state}) {
    final itensOrigem = state.personagem.origem?.itensIniciais ?? [];

    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.backpack_rounded,
                  color: Color(0xFF4B5563),
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  "Kit Padrão de Aventureiro",
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              "Todos os personagens de 1º nível recebem os seguintes itens básicos de sobrevivência:",
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildBadgeItemKit("🎒 Mochila", "0 esp."),
                _buildBadgeItemKit("⛺ Saco de Dormir", "1 esp."),
                _buildBadgeItemKit("🧳 Traje de Viajante", "0 esp."),
              ],
            ),

            if (itensOrigem.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                "Itens da Origem (${state.personagem.origem?.nome ?? ''}):",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: itensOrigem.map((item) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF374151),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeItemKit(String nome, String peso) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            nome,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              peso,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // MODAL / BOTTOM SHEET DE SELEÇÃO DE ARMAS
  // ----------------------------------------------------
  void _abrirSeletorArmas({
    required BuildContext context,
    required String titulo,
    required List<Arma> armas,
    Arma? armaAtual,
    required ValueChanged<Arma> onSelecionar,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return _ModalSeletorArmas(
          titulo: titulo,
          armas: armas,
          armaAtual: armaAtual,
          onSelecionar: (arma) {
            onSelecionar(arma);
            Navigator.pop(modalContext);
          },
        );
      },
    );
  }
}

class _ModalSeletorArmas extends StatefulWidget {
  final String titulo;
  final List<Arma> armas;
  final Arma? armaAtual;
  final ValueChanged<Arma> onSelecionar;

  const _ModalSeletorArmas({
    required this.titulo,
    required this.armas,
    this.armaAtual,
    required this.onSelecionar,
  });

  @override
  State<_ModalSeletorArmas> createState() => _ModalSeletorArmasState();
}

class _ModalSeletorArmasState extends State<_ModalSeletorArmas> {
  String _busca = '';
  PropositoArma? _filtroProposito;

  @override
  Widget build(BuildContext context) {
    final armasFiltradas = widget.armas.where((a) {
      if (_busca.isNotEmpty) {
        final matchNome =
            a.nome.toLowerCase().contains(_busca.toLowerCase().trim());
        final matchDesc =
            a.descricao.toLowerCase().contains(_busca.toLowerCase().trim());
        if (!matchNome && !matchDesc) return false;
      }
      if (_filtroProposito != null && a.proposito != _filtroProposito) {
        return false;
      }
      return true;
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Puxador Superior
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Título do Modal
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.titulo,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Barra de Pesquisa
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Buscar arma por nome...",
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
              onChanged: (val) {
                setState(() => _busca = val);
              },
            ),
          ),

          // Filtros Rápidos (Todos, Corpo a Corpo, Disparo, Arremesso)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildFiltroChip("Todas", null),
                const SizedBox(width: 6),
                _buildFiltroChip(
                  "Corpo a Corpo",
                  PropositoArma.corpoACorpo,
                ),
                const SizedBox(width: 6),
                _buildFiltroChip("Disparo", PropositoArma.disparo),
                const SizedBox(width: 6),
                _buildFiltroChip("Arremesso", PropositoArma.arremesso),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Divider(height: 1),

          // Lista de Armas Disponíveis
          Expanded(
            child: armasFiltradas.isEmpty
                ? const Center(
                    child: Text(
                      "Nenhuma arma encontrada com estes filtros.",
                      style: TextStyle(color: Color(0xFF6B7280)),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: armasFiltradas.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final arma = armasFiltradas[index];
                      final selecionada = widget.armaAtual?.key == arma.key;

                      return _buildItemModalArma(
                        arma: arma,
                        selecionada: selecionada,
                        onTap: () => widget.onSelecionar(arma),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltroChip(String label, PropositoArma? proposito) {
    final ativo = _filtroProposito == proposito;
    return ChoiceChip(
      label: Text(label),
      selected: ativo,
      onSelected: (_) {
        setState(() => _filtroProposito = proposito);
      },
      selectedColor: const Color(0xFFB71C1C),
      labelStyle: TextStyle(
        color: ativo ? Colors.white : const Color(0xFF4B5563),
        fontWeight: ativo ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      backgroundColor: const Color(0xFFF3F4F6),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildItemModalArma({
    required Arma arma,
    required bool selecionada,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: selecionada ? const Color(0xFFFEF2F2) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selecionada ? const Color(0xFFB71C1C) : const Color(0xFFE5E7EB),
          width: selecionada ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        arma.nome,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: selecionada
                              ? const Color(0xFFB71C1C)
                              : const Color(0xFF111827),
                        ),
                      ),
                    ),
                    if (arma.precoTibar > 0)
                      Text(
                        "Valor: T\$ ${arma.precoTibar}",
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF6B7280),
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: selecionada
                            ? const Color(0xFFB71C1C)
                            : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        selecionada ? "Selecionada" : "Grátis",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: selecionada
                              ? Colors.white
                              : const Color(0xFFB71C1C),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Tags de atributos
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _buildPill("Dano: ${arma.dano}", const Color(0xFFDC2626)),
                    _buildPill("Crítico: ${arma.criticoFormatado}", const Color(0xFFD97706)),
                    _buildPill(arma.tipoDano.label, const Color(0xFF4B5563)),
                    _buildPill(arma.empunhadura.label, const Color(0xFF2563EB)),
                    _buildPill(arma.alcance, const Color(0xFF059669)),
                    _buildPill("${arma.espacos} esp.", const Color(0xFF7C3AED)),
                  ],
                ),

                // Propriedades
                if (arma.propriedades.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: arma.propriedades.map((prop) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E8FF),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          prop[0].toUpperCase() + prop.substring(1),
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF7E22CE),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 8),
                Text(
                  arma.descricao,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4B5563),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPill(String texto, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: cor.withValues(alpha: 0.2)),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: cor,
        ),
      ),
    );
  }
}
