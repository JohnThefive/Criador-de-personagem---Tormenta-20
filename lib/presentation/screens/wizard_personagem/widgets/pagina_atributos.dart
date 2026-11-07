import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../controllers/ficha_controller/personagem_cubit.dart';
import 'atributo_card_compra.dart';

/// Etapa 0 do Wizard: Definição dos atributos do personagem por Compra de Pontos ou Rolagem 4d6.
class PaginaAtributos extends StatelessWidget {
  final PersonagemState state;

  const PaginaAtributos({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    // Escolha dos métodos de compra de pontos (2 botões grandes)
    if (state.metodoAtributos == MetodoAtributos.nenhum) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Como você quer definir seus atributos?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            BotaoSelecaoMetodo(
              icon: Icons.shopping_cart,
              titulo: "Compra de Pontos",
              descricao: "Comece com 10 e distribua estrategicamente.",
              onTap: () => context
                  .read<PersonagemCubit>()
                  .escolherMetodoAtributos(MetodoAtributos.compra),
            ),
            const SizedBox(height: 16),
            BotaoSelecaoMetodo(
              icon: Icons.casino,
              titulo: "Rolagem de Dados",
              descricao: "A sorte define seu destino (4d6 drop menor).",
              onTap: () => context
                  .read<PersonagemCubit>()
                  .escolherMetodoAtributos(MetodoAtributos.rolagem),
            ),
          ],
        ),
      );
    }

    // Escolheu comprar pontos
    if (state.metodoAtributos == MetodoAtributos.compra) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blueGrey[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Pontos Restantes:", style: TextStyle(fontSize: 18)),
                Text(
                  "${state.pontosRestantesCompra}",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: state.personagem.atributos.entries.map((entry) {
                return AtributoCardCompra(
                  sigla: entry.key,
                  atributo: entry.value,
                  onIncrement: () => context
                      .read<PersonagemCubit>()
                      .alterarAtributoCompra(entry.key, 1),
                  onDecrement: () => context
                      .read<PersonagemCubit>()
                      .alterarAtributoCompra(entry.key, -1),
                );
              }).toList(),
            ),
          ),
        ],
      );
    }

    // Usuário escolheu rodar os dados
    if (state.metodoAtributos == MetodoAtributos.rolagem) {
      return TelaRolagemAtributos(state: state);
    }

    return Container();
  }
}

class BotaoSelecaoMetodo extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String descricao;
  final VoidCallback onTap;

  const BotaoSelecaoMetodo({
    super.key,
    required this.icon,
    required this.titulo,
    required this.descricao,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.red[900]!),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Colors.red[900]),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    descricao,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TelaRolagemAtributos extends StatelessWidget {
  final PersonagemState state;

  const TelaRolagemAtributos({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    // Se a lista de dados estiver vazia, mostra o botão gigante de rolar
    if (state.valoresRolados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.casino, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              "Role 4d6, descarte o menor.\nSoma >= 6 garantida.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text("ROLAR DADOS"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              onPressed: () => context.read<PersonagemCubit>().rolarDados(),
            ),
          ],
        ),
      );
    }

    // Se já rolou, mostra a interface de alocação
    return Column(
      children: [
        // --- Cabeçalho: Resultados e Botão de Reroll ---
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.amber[50],
          child: Column(
            children: [
              const Text(
                "Valores Disponíveis:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: state.valoresRolados
                    .map(
                      (val) => Chip(
                        label: Text(
                          val >= 0 ? "+$val" : "$val",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: Colors.white,
                        elevation: 1,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),

              // Botão Rolar Novamente
              TextButton.icon(
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text("Não gostou? Rolar Novamente"),
                style: TextButton.styleFrom(foregroundColor: Colors.red[700]),
                onPressed: () {
                  context.read<PersonagemCubit>().rolarDados();
                },
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // --- Lista de Atributos com Dropdown Inteligente ---
        Expanded(
          child: ListView(
            children: state.personagem.atributos.entries.map((entry) {
              // Verifica se este atributo já tem um dado alocado
              final indiceAlocadoParaMim = state.alocacaoIndices[entry.key];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  title: Text(
                    entry.key,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(entry.value.nome),

                  // Feedback Visual (Cinza = Vazio, Azul = Preenchido)
                  leading: CircleAvatar(
                    backgroundColor: indiceAlocadoParaMim != null
                        ? Colors.indigo
                        : Colors.grey[300],
                    child: Text(
                      entry.value.valor >= 0
                          ? "+${entry.value.valor}"
                          : "${entry.value.valor}",
                      style: TextStyle(
                        color: indiceAlocadoParaMim != null
                            ? Colors.white
                            : Colors.black38,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // O Dropdown com Travamento
                  trailing: DropdownButton<int>(
                    hint: const Text("Escolher"),
                    value: indiceAlocadoParaMim,
                    underline: Container(),

                    items: state.valoresRolados
                        .asMap()
                        .entries
                        .map((mapEntry) {
                          int index = mapEntry.key;
                          int valor = mapEntry.value;

                          // Lógica de Bloqueio:
                          // Livre se ninguém usa, OU se quem usa sou eu mesmo
                          bool estaLivre = !state.alocacaoIndices.containsValue(
                            index,
                          );
                          bool ehMeu =
                              state.alocacaoIndices[entry.key] == index;

                          if (!estaLivre && !ehMeu) {
                            return null; // Oculta da lista
                          }

                          return DropdownMenuItem<int>(
                            value: index,
                            child: Text(
                              valor >= 0 ? "+$valor" : "$valor",
                              style: TextStyle(
                                fontWeight: ehMeu
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: valor >= 2
                                    ? Colors.green[700]
                                    : Colors.black,
                              ),
                            ),
                          );
                        })
                        .where((item) => item != null)
                        .cast<DropdownMenuItem<int>>()
                        .toList(),

                    onChanged: (indexSelecionado) {
                      if (indexSelecionado != null) {
                        context.read<PersonagemCubit>().alocarDado(
                          entry.key,
                          indexSelecionado,
                        );
                      }
                    },
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
