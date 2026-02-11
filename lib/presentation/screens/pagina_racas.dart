import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:t20_creator/domain/entities/raca.dart';
import 'package:t20_creator/presentation/controllers/personagem_cubit.dart';

import '../../domain/services/banco_racas.dart'; // Importe o banco

class PaginaSelecaoRaca extends StatelessWidget {
  final PersonagemState state;

  const PaginaSelecaoRaca({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Resumo dos Atributos Atuais (Como uma "Hud" no topo)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          color: Colors.grey[200],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: state.personagem.atributos.keys.map((sigla) {


              // Usa o getValorFinal para mostrar a soma (Base + Raça + seletor)
              int valorFinal = state.personagem.getValorFinal(
                sigla,
                bonusVariaveis: state.atributosVariaveisRaca
                );

              int valorBase = state.personagem.atributos[sigla]?.valor ?? 0;
              bool foiAlterado = (state.personagem.raca?.modificadores[sigla] ?? 0) != 0;

              Color corTexto = Colors.black;
              if (foiAlterado){
                corTexto = valorFinal > valorBase ? Colors.green[800]!: Colors.red[800]!;
              }


              return Column(
                children: [
                  Text(sigla, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  Text(
                    valorFinal >= 0 ? "+$valorFinal" : "$valorFinal",
                    style: TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold,
                      // Fica Verde/Vermelho se a raça alterou este atributo
                      color: corTexto,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),

        const Divider(height: 1),

        // 2. Grid de Raças
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 colunas
              childAspectRatio: 0.8, // Altura do card
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: BancoDeRacas.todas.length,
            itemBuilder: (context, index) {
              final raca = BancoDeRacas.todas[index];
              final selecionada = state.personagem.raca?.nome == raca.nome;

              return GestureDetector(
                onTap: () {

                  // selecionar raca 
                  context.read<PersonagemCubit>().selecionarRaca(raca);

                  //se flexivel 
                  if (raca.ehFlexivel) {
                    // delecionar os atributos de raca 
                    _mostrarSeletorDeAtributos(context, raca);
                  } else {
                    context.read<PersonagemCubit>().selecionarRaca(raca);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: selecionada ? Colors.red[50] : Colors.white,
                    border: Border.all(
                      color: selecionada ? Colors.red : Colors.grey[300]!,
                      width: selecionada ? 2 : 1
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nome da Raça
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: selecionada ? Colors.red : Colors.grey[100],
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                        ),
                        child: Text(
                          raca.nome,
                          style: TextStyle(
                            color: selecionada ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Modificadores (Ex: CON +2)
                            if (raca.modificadores.isNotEmpty)
                              Wrap(
                                spacing: 4,
                                children: raca.modificadores.entries.map((e) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: e.value > 0 ? Colors.green[100] : Colors.red[100],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      "${e.key} ${e.value > 0 ? '+' : ''}${e.value}",
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  );
                                }).toList(),
                              )
                            else 
                              const Text("Modificadores Variáveis", style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic)),

                            const SizedBox(height: 8),
                            
                            // Lista de Habilidades (Bullet Points)
                            ...raca.habilidades.map((habilidade) => Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("• ", style: TextStyle(fontSize: 10)),
                                  Expanded(child: Text(habilidade, style: const TextStyle(fontSize: 10))),
                                ],
                              ),
                            )),
                          ],
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
    );
  }
}

// Cole isso no final do arquivo _pagina_racas.dart (fora da classe PaginaSelecaoRaca)

void _mostrarSeletorDeAtributos(BuildContext parentContext, Raca raca) {
  showModalBottomSheet(
    context: parentContext,
    isDismissible: false, // O usuário é obrigado a terminar ou cancelar
    enableDrag: false,    // Não deixa fechar arrastando para baixo
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20))
    ),
    builder: (context) {
      // Usamos StatefulBuilder ou BlocBuilder para atualizar SÓ o modal
      return BlocBuilder<PersonagemCubit, PersonagemState>(
        bloc: parentContext.read<PersonagemCubit>(), // Usa o Cubit da tela de trás
        builder: (context, state) {
          
          final selecoes = state.atributosVariaveisRaca;
          final faltam = 3 - selecoes.length;

          return Container(
            padding: const EdgeInsets.all(24),
            height: 450, // Altura do painel
            child: Column(
              children: [
                Text("Bônus de ${raca.nome}", 
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                
                const SizedBox(height: 8),
                
                Text(
                  faltam > 0 ? "Escolha mais $faltam atributos (+1)" : "Seleção Completa!",
                  style: TextStyle(
                    color: faltam > 0 ? Colors.red[700] : Colors.green[700], 
                    fontWeight: FontWeight.bold
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
                    final estaBloqueado = raca.atributosBloqueados.contains(sigla);
                    
                    return FilterChip(
                      label: Text(sigla),
                      selected: estaSelecionado,
                      // Se bloqueado, onSelected é null (desabilita o botão)
                      onSelected: estaBloqueado ? null : (bool selected) {
                        parentContext.read<PersonagemCubit>().toggleAtributoRacial(sigla);
                      },
                      selectedColor: Colors.green[200],
                      checkmarkColor: Colors.green[900],
                      // Visual de "Bloqueado/Proibido"
                      labelStyle: TextStyle(
                        color: estaBloqueado ? Colors.grey : Colors.black,
                        decoration: estaBloqueado ? TextDecoration.lineThrough : null,
                      ),
                      backgroundColor: estaBloqueado ? Colors.grey[200] : null,
                    );
                  }).toList(),
                ),

                const Spacer(),
                
                // BOTÃO CONFIRMAR
                ElevatedButton(
                  onPressed: faltam == 0 
                    ? () => Navigator.pop(context) // Fecha o modal se acabou
                    : null, // Botão cinza se ainda faltam escolhas
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.red[900],
                  ),
                  child: const Text("CONFIRMAR BÔNUS", style: TextStyle(color: Colors.white)),
                )
              ],
            ),
          );
        },
      );
    },
  );
}