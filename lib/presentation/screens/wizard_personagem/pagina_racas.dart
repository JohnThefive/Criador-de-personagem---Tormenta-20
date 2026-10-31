import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/personagem/poder.dart';
import '../../../domain/entities/personagem/raca.dart';
import '../../controllers/personagem_cubit.dart';
import '../../../domain/services/data_services/call_pericias.dart';
import '../../../domain/services/data_services/call_poderes.dart';
import '../../../domain/services/data_services/call_racas.dart';
import '../../widgets/rpg_icon.dart';

class PaginaSelecaoRaca extends StatefulWidget {
  final PersonagemState state;

  const PaginaSelecaoRaca({super.key, required this.state});

  @override
  State<PaginaSelecaoRaca> createState() => _PaginaSelecaoRacaState();
}

class _PaginaSelecaoRacaState extends State<PaginaSelecaoRaca> {
  bool _menuAberto = true;

  @override
  Widget build(BuildContext context) {
    final racaSelecionada = widget.state.personagem.raca;

    return Column(
      children: [
        // Hud de atributos (no topo)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          color: Colors.grey[200],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: widget.state.personagem.atributos.keys.map((sigla) {
              int valorFinal = widget.state.personagem.getValorFinal(
                sigla,
                bonusVariaveis: widget.state.atributosVariaveisRaca,
              );
              int valorBase =
                  widget.state.personagem.atributos[sigla]?.valor ?? 0;
              bool foiAlterado =
                  (widget.state.personagem.raca?.modificadores[sigla] ?? 0) !=
                      0 ||
                  widget.state.atributosVariaveisRaca.contains(sigla);

              Color corTexto = Colors.black;
              if (foiAlterado) {
                corTexto = valorFinal > valorBase
                    ? Colors.green[800]!
                    : Colors.red[800]!;
              }

              return Column(
                children: [
                  Text(
                    sigla,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    valorFinal >= 0 ? "+$valorFinal" : "$valorFinal",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: corTexto,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
        const Divider(height: 1),

        //  (Menu de escolha + Detalhes) ---
        Expanded(
          child: Row(
            children: [
              // MENU LATERAL ANIMADO (Mesmo que o de classes)
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
                          "Escolha Uma Raça",
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
                          itemCount: BancoDeRacas.todas.length,
                          itemBuilder: (context, index) {
                            final raca = BancoDeRacas.todas[index];
                            final isSelected =
                                racaSelecionada?.nome == raca.nome;

                            return GestureDetector(
                              onTap: () {
                                context.read<PersonagemCubit>().selecionarRaca(
                                  raca,
                                );
                                if (raca.ehFlexivel) {
                                  // Chama a função Atualizando atributos
                                  _mostrarSeletorDeAtributos(context, raca);
                                }
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.grey[400]
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor: isSelected
                                          ? Colors.brown.shade900
                                          : Colors.red.shade900,
                                      child: RpgIcon(
                                        iconName: raca.icone,
                                        size: 14,
                                        color: isSelected
                                            ? Colors.amber
                                            : Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        raca.nome,
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.black
                                              : Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
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

              // Aba para fechar e abrie seletor de reças
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

              // LOcal de detalhes
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: racaSelecionada == null
                      ? const Center(child: Text("Selecione uma raça ao lado."))
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            // Ícone da Raça
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.red.shade200,
                                    width: 2,
                                  ),
                                ),
                                child: RpgIcon(
                                  iconName: racaSelecionada.icone,
                                  size: 64,
                                  color: Colors.red[800],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // História / Lore
                            Text(
                              racaSelecionada.descricaoRaca,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                height: 1.3,
                              ),
                              textAlign: TextAlign.justify,
                            ),
                            const SizedBox(height: 16),
                            const Divider(),

                            // Modificadores de Atributo da Raça
                            const Text(
                              "Modificadores de Atributo",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (racaSelecionada.modificadores.isNotEmpty)
                              Wrap(
                                spacing: 8,
                                children: racaSelecionada.modificadores.entries
                                    .map((e) {
                                      return Chip(
                                        label: Text(
                                          "${e.key} ${e.value > 0 ? '+' : ''}${e.value}",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        backgroundColor: e.value > 0
                                            ? Colors.green[100]
                                            : Colors.red[100],
                                      );
                                    })
                                    .toList(),
                              )
                            else if (racaSelecionada.ehFlexivel)
                              ActionChip(
                                onPressed: () => _mostrarSeletorDeAtributos(
                                  context,
                                  racaSelecionada,
                                ),
                                label: const Text(
                                  "Escolha +1 em 3 atributos",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                backgroundColor: Colors.blue[100],
                                avatar: const Icon(Icons.touch_app, size: 16),
                              ),

                            if (racaSelecionada.id.toLowerCase() == 'lefou') ...[
                              const SizedBox(height: 16),
                              _buildCardDeformidadeLefou(context),
                            ],

                            const SizedBox(height: 16),

                            // Sanfona (ExpansionTile) das Habilidades da Raça
                            if (racaSelecionada.habilidadesRaca.isNotEmpty)
                              ExpansionTile(
                                title: const Text(
                                  "Habilidades da Raça",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: const Text(
                                  "Características únicas da sua espécie",
                                ),
                                iconColor: Colors.red[900],
                                collapsedIconColor: Colors.grey,
                                initiallyExpanded:
                                    true, // Já começa aberto para o usuário ver
                                children: racaSelecionada
                                    .habilidadesRaca
                                    .entries
                                    .map((entry) {
                                      return ListTile(
                                        title: Text(
                                          entry.key,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        subtitle: Text(
                                          entry.value,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 4,
                                            ),
                                      );
                                    })
                                    .toList(),
                              ),
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

  Widget _buildCardDeformidadeLefou(BuildContext context) {
    final p = widget.state.personagem;
    final pericias = p.periciasDeformidadeLefou;
    final poder = p.poderTormentaDeformidade;
    final totalEscolhido = pericias.length + (poder != null ? 1 : 0);

    return Card(
      color: Colors.red.shade50,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.coronavirus, color: Colors.red.shade900, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Deformidade (Lefou)",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.red.shade900,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: totalEscolhido == 2
                        ? Colors.green.shade700
                        : Colors.orange.shade800,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "$totalEscolhido/2",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              "Receba +2 em duas perícias (ou +2 em uma perícia e um Poder da Tormenta). Cada bônus conta como um Poder da Tormenta, sem perda de Carisma.",
              style: TextStyle(fontSize: 12, color: Colors.black87),
            ),
            if (pericias.isNotEmpty || poder != null) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  ...pericias.map((k) {
                    final label = BancoDePericias.getByKey(k).label;
                    return Chip(
                      label: Text(
                        "+2 $label",
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                    );
                  }),
                  if (poder != null)
                    Chip(
                      avatar: Icon(
                        Icons.coronavirus,
                        size: 14,
                        color: Colors.red.shade900,
                      ),
                      label: Text(
                        "Tormenta: ${poder.nome}",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade900,
                        ),
                      ),
                      backgroundColor: Colors.red.shade100,
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _mostrarModalDeformidadeLefou(context),
                icon: const Icon(Icons.tune, size: 16),
                label: const Text("Configurar Deformidade"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade900,
                  side: BorderSide(color: Colors.red.shade700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _mostrarModalDeformidadeLefou(BuildContext parentContext) {
  showModalBottomSheet(
    context: parentContext,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return BlocBuilder<PersonagemCubit, PersonagemState>(
        bloc: parentContext.read<PersonagemCubit>(),
        builder: (context, state) {
          final cubit = parentContext.read<PersonagemCubit>();
          final p = state.personagem;
          final periciasEscolhidas = p.periciasDeformidadeLefou;
          final poderTormenta = p.poderTormentaDeformidade;
          final maxPericias = poderTormenta != null ? 1 : 2;
          final todasPericias = BancoDePericias.todas;
          final poderesTormenta = BancoDePoderesGerais.poderesTormenta.where((
            pod,
          ) {
            return pod.poderesTormentaMinimos <= 1 &&
                pod.poderesExigidos.isEmpty &&
                pod.atributosExigidos.isEmpty;
          }).toList();

          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.82,
            maxChildSize: 0.92,
            minChildSize: 0.5,
            builder: (context, scrollController) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: ListView(
                  controller: scrollController,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.coronavirus, color: Colors.red.shade900),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            "Deformidade do Lefou",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Escolha até $maxPericias perícia(s) para receber +2. Você pode trocar 1 bônus de perícia por 1 Poder da Tormenta (sem perda de Carisma).",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "1. Perícias com +2 (Deformidade)",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: todasPericias.map((pericia) {
                        final selecionada = periciasEscolhidas.contains(
                          pericia.key,
                        );
                        return FilterChip(
                          label: Text(
                            pericia.label,
                            style: const TextStyle(fontSize: 12),
                          ),
                          selected: selecionada,
                          selectedColor: Colors.red.shade100,
                          checkmarkColor: Colors.red.shade900,
                          onSelected: (_) =>
                              cubit.togglePericiaDeformidadeLefou(pericia.key),
                        );
                      }).toList(),
                    ),
                    const Divider(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            "2. Opcional: Trocar 1 bônus por Poder da Tormenta",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (poderTormenta != null)
                          TextButton(
                            onPressed: () =>
                                cubit.selecionarPoderTormentaDeformidade(null),
                            child: const Text("Remover poder"),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...poderesTormenta.map((Poder pod) {
                      final isSelected = poderTormenta?.key == pod.key;
                      return Card(
                        color: isSelected ? Colors.red.shade50 : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: isSelected
                                ? Colors.red.shade700
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: ListTile(
                          dense: true,
                          title: Text(
                            pod.nome,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.red.shade900
                                  : Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            pod.descricao,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: Icon(
                            isSelected
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: isSelected
                                ? Colors.red.shade900
                                : Colors.grey,
                          ),
                          onTap: () => cubit.selecionarPoderTormentaDeformidade(
                            isSelected ? null : pod,
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade900,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: const Text(
                        "CONCLUIR DEFORMIDADE",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );
}

// Funções RElacionadas a atributos
void _mostrarSeletorDeAtributos(BuildContext parentContext, Raca raca) {
  showModalBottomSheet(
    context: parentContext,
    isDismissible: false, // O usuário é obrigado a terminar ou cancelar
    enableDrag: false, // Não deixa fechar arrastando para baixo
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      // Usamos StatefulBuilder ou BlocBuilder para atualizar SÓ o modal
      return BlocBuilder<PersonagemCubit, PersonagemState>(
        bloc: parentContext
            .read<PersonagemCubit>(), // Usa o Cubit da tela de trás
        builder: (context, state) {
          final selecoes = state.atributosVariaveisRaca;
          final faltam = 3 - selecoes.length;

          //Tela de seleção de atributos
          return Container(
            padding: const EdgeInsets.all(24),
            height: 450, // Altura do painel
            child: Column(
              children: [
                Text(
                  "Bônus de ${raca.nome}",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  faltam > 0
                      ? "Escolha mais $faltam atributos (+1)"
                      : "Seleção Completa!",
                  style: TextStyle(
                    color: faltam > 0 ? Colors.red[700] : Colors.green[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                // GRID DE BOTÕES (CHIPS)
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: state.personagem.atributos.keys.map((sigla) {
                    final estaSelecionado = selecoes.contains(sigla);
                    // Verifica se a raça proíbe este atributo (Ex: Lefou proíbe Carisma)
                    final estaBloqueado = raca.atributosBloqueados.contains(
                      sigla,
                    );

                    return FilterChip(
                      label: Text(sigla),
                      selected: estaSelecionado,
                      // Se bloqueado, onSelected é null (desabilita o botão)
                      onSelected: estaBloqueado
                          ? null
                          : (bool selected) {
                              parentContext
                                  .read<PersonagemCubit>()
                                  .toggleAtributoRacial(sigla);
                            },
                      selectedColor: Colors.green[200],
                      checkmarkColor: Colors.green[900],
                      // Visual de "Bloqueado/Proibido"
                      labelStyle: TextStyle(
                        color: estaBloqueado ? Colors.grey : Colors.black,
                        decoration: estaBloqueado
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                      backgroundColor: estaBloqueado ? Colors.grey[200] : null,
                    );
                  }).toList(),
                ),

                const Spacer(),

                // Botão de confirmar escolha
                ElevatedButton(
                  onPressed: faltam == 0
                      ? () =>
                            Navigator.pop(context) // Fecha o modal se acabou
                      : null, // Botão cinza se ainda faltam escolhas
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.red[900],
                  ),
                  child: const Text(
                    "CONFIRMAR BÔNUS",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
