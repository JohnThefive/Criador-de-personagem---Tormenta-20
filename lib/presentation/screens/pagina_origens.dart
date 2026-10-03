import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/poder.dart';
import '../../domain/services/banco_origens.dart';
import '../../domain/services/banco_pericias.dart';
import '../controllers/personagem_cubit.dart';

class PaginaSelecaoOrigem extends StatefulWidget {
  final PersonagemState state;

  const PaginaSelecaoOrigem({super.key, required this.state});

  @override
  State<PaginaSelecaoOrigem> createState() => _PaginaSelecaoOrigemState();
}

class _PaginaSelecaoOrigemState extends State<PaginaSelecaoOrigem> {
  bool _menuAberto = true;

  @override
  Widget build(BuildContext context) {
    final origemSelecionada = widget.state.origemSelecionada;
    final cubit = context.read<PersonagemCubit>();

    return Column(
      children: [
        // HUD Superior com contador de benefícios
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Colors.grey[200],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                origemSelecionada != null
                    ? "Origem: ${origemSelecionada.nome}"
                    : "Nenhuma origem selecionada",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: widget.state.totalBeneficiosOrigem == 2
                      ? Colors.green[700]
                      : Colors.orange[800],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  "Benefícios: ${widget.state.totalBeneficiosOrigem} / 2",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Área principal (Menu Lateral + Painel de Detalhes)
        Expanded(
          child: Row(
            children: [
              // Menu Lateral Animado
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: _menuAberto ? 130 : 0,
                color: Colors.red[600],
                child: ClipRect(
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          "Escolha uma Origem",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const Divider(color: Colors.white54),
                      Expanded(
                        child: ListView.builder(
                          itemCount: BancoDeOrigens.todas.length,
                          itemBuilder: (context, index) {
                            final origem = BancoDeOrigens.todas[index];
                            final isSelected =
                                origemSelecionada?.id == origem.id;

                            return GestureDetector(
                              onTap: () {
                                cubit.selecionarOrigem(origem);
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.grey[400]
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  origem.nome,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.black
                                        : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Botão Retrátil
              GestureDetector(
                onTap: () => setState(() => _menuAberto = !_menuAberto),
                child: Container(
                  width: 24,
                  height: double.infinity,
                  color: Colors.red[800],
                  child: Icon(
                    _menuAberto ? Icons.chevron_left : Icons.chevron_right,
                    color: Colors.white,
                  ),
                ),
              ),

              // Painel de Detalhes da Origem
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: origemSelecionada == null
                      ? const Center(
                          child: Text(
                            "Selecione uma origem no menu ao lado.",
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            // Título da Origem
                            Text(
                              origemSelecionada.nome,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Lore / Descrição
                            Text(
                              origemSelecionada.descricao,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                height: 1.3,
                              ),
                              textAlign: TextAlign.justify,
                            ),
                            const SizedBox(height: 16),
                            const Divider(),

                            // 1. Itens Iniciais (Grátis)
                            Row(
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  color: Colors.red[800],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  "Itens Iniciais (Recebidos Gratuitamente)",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: origemSelecionada.itensIniciais.map((
                                item,
                              ) {
                                return Chip(
                                  backgroundColor: Colors.grey[100],
                                  side: BorderSide(color: Colors.grey[350]!),
                                  avatar: const Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Colors.green,
                                  ),
                                  label: Text(
                                    item,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                            const Divider(),

                            // 2. Benefícios (Escolha 2)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Benefícios da Origem",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  "Escolha exatamente 2",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Você pode escolher 2 perícias, 2 poderes ou 1 perícia e 1 poder.",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // A. Poder Único (Destaque Especial)
                            _buildCardPoderUnico(
                              context,
                              origemSelecionada.poderUnico,
                              cubit,
                            ),
                            const SizedBox(height: 12),

                            // B. Perícias Disponíveis
                            const Text(
                              "Perícias Disponíveis:",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: origemSelecionada.periciasOpcoes.map((
                                sigla,
                              ) {
                                final isSelected = widget
                                    .state
                                    .periciasEscolhidasOrigem
                                    .contains(sigla);
                                final pericia = BancoDePericias.getByKey(sigla);
                                final jaTreinadaNaClasse =
                                    widget.state.personagem.periciasTreinadas
                                        .contains(sigla) ||
                                    widget.state.selecoesPericiaClasse.contains(
                                      sigla,
                                    );

                                return ChoiceChip(
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(pericia.label),
                                      if (jaTreinadaNaClasse)
                                        const Text(
                                          " (Já treinada)",
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                    ],
                                  ),
                                  selected: isSelected,
                                  selectedColor: Colors.red[100],
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: isSelected
                                          ? Colors.red[800]!
                                          : Colors.grey[350]!,
                                      width: isSelected ? 1.8 : 1,
                                    ),
                                  ),
                                  onSelected: (_) {
                                    cubit.togglePericiaOrigem(sigla);
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),

                            // C. Poderes Gerais Disponíveis
                            if (origemSelecionada
                                .poderesGeraisOpcoes
                                .isNotEmpty) ...[
                              const Text(
                                "Poderes Gerais Disponíveis:",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...origemSelecionada.poderesGeraisOpcoes.map((
                                poder,
                              ) {
                                return _buildCardPoderGeral(
                                  context,
                                  poder,
                                  cubit,
                                );
                              }),
                            ],
                            const SizedBox(height: 24),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardPoderUnico(
    BuildContext context,
    Poder poder,
    PersonagemCubit cubit,
  ) {
    final isSelected = widget.state.poderesEscolhidosOrigem.any(
      (p) => p.key == poder.key,
    );

    return InkWell(
      onTap: () => cubit.togglePoderOrigem(poder),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber[50] : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.amber[800]! : Colors.amber[400]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber[800], size: 20),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "PODER ÚNICO",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Checkbox(
                  value: isSelected,
                  activeColor: Colors.amber[800],
                  onChanged: (_) => cubit.togglePoderOrigem(poder),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              poder.nome,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              poder.descricao,
              style: TextStyle(fontSize: 13, color: Colors.grey[800]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardPoderGeral(
    BuildContext context,
    Poder poder,
    PersonagemCubit cubit,
  ) {
    final isSelected = widget.state.poderesEscolhidosOrigem.any(
      (p) => p.key == poder.key,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => cubit.togglePoderOrigem(poder),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.red[50] : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? Colors.red[700]! : Colors.grey[300]!,
              width: isSelected ? 1.8 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: isSelected,
                activeColor: Colors.red[800],
                onChanged: (_) => cubit.togglePoderOrigem(poder),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      poder.nome,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      poder.descricao,
                      style: TextStyle(fontSize: 13, color: Colors.grey[750]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
