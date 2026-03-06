import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/raca.dart';
import '../controllers/personagem_cubit.dart';
import '../../domain/services/banco_racas.dart';

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
                bonusVariaveis: widget.state.atributosVariaveisRaca
              );
              int valorBase = widget.state.personagem.atributos[sigla]?.valor ?? 0;
              bool foiAlterado = (widget.state.personagem.raca?.modificadores[sigla] ?? 0) != 0 || widget.state.atributosVariaveisRaca.contains(sigla);

              Color corTexto = Colors.black;
              if (foiAlterado) {
                corTexto = valorFinal > valorBase ? Colors.green[800]! : Colors.red[800]!;
              }

              return Column(
                children: [
                  Text(sigla, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  Text(
                    valorFinal >= 0 ? "+$valorFinal" : "$valorFinal",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: corTexto),
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
                        child: Text("Escolha Uma Raça", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center),
                      ),
                      const Divider(color: Colors.white54),
                      Expanded(
                        child: ListView.builder(
                          itemCount: BancoDeRacas.todas.length,
                          itemBuilder: (context, index) {
                            final raca = BancoDeRacas.todas[index];
                            final isSelected = racaSelecionada?.nome == raca.nome;

                            return GestureDetector(
                              onTap: () {
                                context.read<PersonagemCubit>().selecionarRaca(raca);
                                if (raca.ehFlexivel) {
                                  // Chama a função Atualizando atributos
                                  _mostrarSeletorDeAtributos(context, raca);
                                }
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.grey[400] : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  raca.nome,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
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

              // Aba para fechar e abrie seletor de reças
              GestureDetector(
                onTap: () => setState(() => _menuAberto = !_menuAberto),
                child: Container(
                  width: 24,
                  height: double.infinity,
                  color: Colors.red[800],
                  child: Icon(_menuAberto ? Icons.chevron_left : Icons.chevron_right, color: Colors.white),
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
                            // Imagem da Raça
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                racaSelecionada.imagemRaca,
                                width: double.infinity,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  height: 150, color: Colors.grey[300], child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // História / Lore
                            Text(
                              racaSelecionada.descricaoRaca,
                              style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.3),
                              textAlign: TextAlign.justify,
                            ),
                            const SizedBox(height: 16),
                            const Divider(),

                            // Modificadores de Atributo da Raça
                            const Text("Modificadores de Atributo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 8),
                            if (racaSelecionada.modificadores.isNotEmpty)
                              Wrap(
                                spacing: 8,
                                children: racaSelecionada.modificadores.entries.map((e) {
                                  return Chip(
                                    label: Text("${e.key} ${e.value > 0 ? '+' : ''}${e.value}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                    backgroundColor: e.value > 0 ? Colors.green[100] : Colors.red[100],
                                  );
                                }).toList(),
                              )
                            else if (racaSelecionada.ehFlexivel)
                              Chip(
                                label: const Text("Escolha +1 em 3 atributos", style: TextStyle(fontWeight: FontWeight.bold)),
                                backgroundColor: Colors.blue[100],
                                avatar: const Icon(Icons.touch_app, size: 16),
                              ),
                            
                            const SizedBox(height: 16),

                            // Sanfona (ExpansionTile) das Habilidades da Raça
                            if (racaSelecionada.habilidadesRaca.isNotEmpty)
                              ExpansionTile(
                                title: const Text("Habilidades da Raça", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                subtitle: const Text("Características únicas da sua espécie"),
                                iconColor: Colors.red[900],
                                collapsedIconColor: Colors.grey,
                                initiallyExpanded: true, // Já começa aberto para o usuário ver
                                children: racaSelecionada.habilidadesRaca.entries.map((entry) {
                                  return ListTile(
                                    title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    subtitle: Text(entry.value, style: const TextStyle(fontSize: 12)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  );
                                }).toList(),
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
}

// Funções RElacionadas a atributos
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

          //Tela de seleção de atributos
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
                
                // Botão de confirmar escolha
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