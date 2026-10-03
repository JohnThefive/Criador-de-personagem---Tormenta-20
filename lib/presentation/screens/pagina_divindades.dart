import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/divindade.dart';
import '../../domain/services/banco_divindades.dart';
import '../controllers/personagem_cubit.dart';

class PaginaSelecaoDivindade extends StatefulWidget {
  final PersonagemState state;

  const PaginaSelecaoDivindade({super.key, required this.state});

  @override
  State<PaginaSelecaoDivindade> createState() => _PaginaSelecaoDivindadeState();
}

class _PaginaSelecaoDivindadeState extends State<PaginaSelecaoDivindade> {
  bool _menuAberto = true;

  @override
  Widget build(BuildContext context) {
    final divindadeSelecionada = widget.state.divindadeSelecionada;
    final cubit = context.read<PersonagemCubit>();
    final exigeDevocao = widget.state.personagem.exigeDevocao;

    return Column(
      children: [
        // HUD Superior Informativo
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Colors.grey[200],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  divindadeSelecionada != null
                      ? "Devoto de ${divindadeSelecionada.nome}"
                      : (exigeDevocao
                            ? "Devoção Obrigatória (Escolha um Deus)"
                            : "Sem Divindade (Não Devoto)"),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _buildBadgeStatus(),
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
                width: _menuAberto ? 140 : 0,
                color: Colors.red[600],
                child: ClipRect(
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          "Panteão de Arton",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const Divider(color: Colors.white54, height: 1),

                      // Opção 0: Não ser devoto (Pular)
                      GestureDetector(
                        onTap: () {
                          if (exigeDevocao) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Sua classe exige a escolha obrigatória de uma divindade.",
                                ),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }
                          cubit.selecionarDivindade(null);
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 6,
                          ),
                          decoration: BoxDecoration(
                            color: divindadeSelecionada == null
                                ? Colors.grey[400]
                                : (exigeDevocao
                                      ? Colors.black26
                                      : Colors.transparent),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white38, width: 1),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                exigeDevocao ? Icons.lock : Icons.block,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  "Não Devoto",
                                  style: TextStyle(
                                    color: divindadeSelecionada == null
                                        ? Colors.black
                                        : (exigeDevocao
                                              ? Colors.white38
                                              : Colors.white),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(color: Colors.white54, height: 1),

                      // Lista das Divindades
                      Expanded(
                        child: ListView.builder(
                          itemCount: BancoDeDivindades.todas.length,
                          itemBuilder: (context, index) {
                            final divindade = BancoDeDivindades.todas[index];
                            final isSelected =
                                divindadeSelecionada?.id == divindade.id;

                            return GestureDetector(
                              onTap: () {
                                cubit.selecionarDivindade(divindade);
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.grey[400]
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  divindade.nome,
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

              // Painel de Conteúdo
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: divindadeSelecionada == null
                      ? _buildPainelNaoDevoto(exigeDevocao)
                      : _buildPainelDivindade(divindadeSelecionada, cubit),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeStatus() {
    final divindade = widget.state.divindadeSelecionada;
    final poder = widget.state.poderConcedidoSelecionado;
    final exigeDevocao = widget.state.personagem.exigeDevocao;

    if (divindade == null) {
      if (exigeDevocao) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red[800],
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            "Devoção Exigida",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        );
      }
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green[700],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          "Etapa Concluída",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
    }

    // Se é devoto, verifica se escolheu o poder concedido
    final completo = poder != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: completo ? Colors.green[700] : Colors.orange[800],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        completo ? "Poder Concedido: 1/1" : "Escolha 1 Poder Concedido",
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildPainelNaoDevoto(bool exigeDevocao) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              exigeDevocao
                  ? Icons.warning_amber_rounded
                  : Icons.shield_outlined,
              size: 64,
              color: exigeDevocao ? Colors.red[700] : Colors.grey[500],
            ),
            const SizedBox(height: 16),
            Text(
              exigeDevocao
                  ? "Devoção Obrigatória!"
                  : "Aventureiro Livre (Não Devoto)",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: exigeDevocao ? Colors.red[800] : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              exigeDevocao
                  ? "Sua classe (Clérigo, Druida ou Paladino) exige a escolha de um deus padroeiro no Panteão. Selecione uma divindade no menu ao lado para prosseguir."
                  : "Você optou por não seguir nenhum deus do Panteão. Seu personagem não recebe poderes concedidos, mas tem total liberdade moral e não sofre nenhuma Obrigação ou Restrição sagrada.",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[750],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (!exigeDevocao)
              Chip(
                backgroundColor: Colors.green[50],
                side: BorderSide(color: Colors.green[400]!),
                avatar: const Icon(
                  Icons.check_circle,
                  size: 18,
                  color: Colors.green,
                ),
                label: const Text(
                  "Você pode avançar sem escolher um deus",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPainelDivindade(Divindade divindade, PersonagemCubit cubit) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Título e Título Divino
        Text(
          divindade.nome,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          divindade.titulo,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.red[900],
          ),
        ),
        const SizedBox(height: 12),

        // Especificações Rápidas
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            Chip(
              backgroundColor: Colors.grey[100],
              side: BorderSide(color: Colors.grey[300]!),
              avatar: const Icon(
                Icons.auto_awesome,
                size: 16,
                color: Colors.indigo,
              ),
              label: Text(
                "Símbolo: ${divindade.simboloSagrado}",
                style: const TextStyle(fontSize: 12),
              ),
            ),
            Chip(
              backgroundColor: Colors.grey[100],
              side: BorderSide(color: Colors.grey[300]!),
              avatar: const Icon(Icons.colorize, size: 16, color: Colors.brown),
              label: Text(
                "Arma: ${divindade.armaPreferida}",
                style: const TextStyle(fontSize: 12),
              ),
            ),
            Chip(
              backgroundColor: Colors.grey[100],
              side: BorderSide(color: Colors.grey[300]!),
              avatar: const Icon(Icons.bolt, size: 16, color: Colors.amber),
              label: Text(
                "Energia: ${_nomeEnergia(divindade.energiaCanalizada)}",
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(),

        // Lore / Descrição
        Text(
          divindade.descricao,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            height: 1.3,
          ),
          textAlign: TextAlign.justify,
        ),
        const SizedBox(height: 16),

        // Card de Obrigações & Restrições (Destaque Vermelho)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red[400]!, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.gavel, color: Colors.red[900], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Obrigações & Restrições",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.red[950],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                divindade.obrigacoesERestricoes,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.red[950],
                  height: 1.3,
                ),
                textAlign: TextAlign.justify,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Divider(),

        // Seletor de Poder Concedido
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Poderes Concedidos",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              "Escolha 1 poder",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        ...divindade.poderesConcedidos.map((poder) {
          final isSelected =
              widget.state.poderConcedidoSelecionado?.key == poder.key;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => cubit.selecionarPoderConcedido(poder),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.red[50] : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? Colors.red[700]! : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2, right: 4),
                      child: Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: isSelected ? Colors.red[800] : Colors.grey[500],
                        size: 22,
                      ),
                    ),
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
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[800],
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 20),
      ],
    );
  }

  String _nomeEnergia(TipoEnergia energia) {
    switch (energia) {
      case TipoEnergia.positiva:
        return "Positiva";
      case TipoEnergia.negativa:
        return "Negativa";
      case TipoEnergia.qualquer:
        return "Qualquer";
    }
  }
}
