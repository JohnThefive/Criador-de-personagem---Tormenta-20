import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:t20_creator/presentation/screens/pagina_racas.dart';
import '../controllers/personagem_cubit.dart';
import '../widgets/atributo_card_compra.dart'; 
// Importe seus widgets de AtributoCard e a lógica de Rolagem aqui

class CharacterCreatorScreen extends StatelessWidget {
  // Controlador para deslizar as páginas programaticamente
  final PageController _pageController = PageController();

  CharacterCreatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PersonagemCubit, PersonagemState>(
      listenWhen: (previous, current) => previous.etapaAtual != current.etapaAtual,
      listener: (context, state) {
        // Animação suave quando o Cubit diz que mudou de etapa
        _pageController.animateToPage(
          state.etapaAtual,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(_getTituloEtapa(state.etapaAtual)),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                // Se estiver na primeira etapa, sai da tela. Se não, volta um passo.
                if (state.etapaAtual == 0 && state.metodoAtributos == MetodoAtributos.nenhum) {
                  Navigator.pop(context);
                } else {
                  context.read<PersonagemCubit>().voltarEtapa();
                }
              },
            ),
          ),
          
          // O CORPO É UM WIZARD QUE NÃO DESLIZA COM O DEDO (Physics)
          body: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(), // Bloqueia swipe manual
            children: [
              _PaginaAtributos(state: state), // Etapa 0
              PaginaSelecaoRaca(state: state),
              const Center(child: Text("Etapa 2: Escolha da Classe (Em Breve)")),
              const Center(child: Text("Etapa 3: Origem (Em Breve)")),
              // ... adicione as outras etapas aqui (mesngaem pro joão do futuro) ...
              _PaginaFinalizacao(), // Última Etapa
            ],
          ),

          // Botão de avançar só aparece quando uma atividade é concluida (modificar visual no futuro)
          floatingActionButton: _deveMostrarBotaoAvancar(state) 
            ? FloatingActionButton.extended(
                onPressed: () => context.read<PersonagemCubit>().avancarEtapa(),
                label: const Text("Próximo"),
                icon: const Icon(Icons.arrow_forward),
                backgroundColor: Colors.red[900],
              )
            : null,
        );
      },
    );
  }

  String _getTituloEtapa(int step) {
    switch (step) {
      case 0: return "Definir Atributos";
      case 1: return "Escolher Raça";
      case 2: return "Escolher Classe";
      default: return "Criação de Personagem";
    }
  }

  bool _deveMostrarBotaoAvancar(PersonagemState state) {
    if (state.etapaAtual == 0){

      // só avança se todos os pontos forem comprado
      if (state.metodoAtributos == MetodoAtributos.compra){
        return state.pontosRestantesCompra == 0;
      }

      if (state.etapaAtual == 1){

      return state.personagem.raca != null;}

      // só avanca se colocou todos os atributos 
      if(state.metodoAtributos == MetodoAtributos.rolagem){
        return state.alocacaoIndices.length == 6; 
      }

      // se não escolher nada 
      return false; 

    }
    // passa pra ir pros mocks 
    return true;
    }
  }


// --- SUB-WIDGET DA ETAPA 0: ATRIBUTOS ---
class _PaginaAtributos extends StatelessWidget {
  final PersonagemState state;

  const _PaginaAtributos({required this.state});

  @override
  Widget build(BuildContext context) {
    // Escolha dos metodos de compra de pontos (2 botões grandes)
    if (state.metodoAtributos == MetodoAtributos.nenhum) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Como você quer definir seus atributos?", 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            _BotaoSelecaoMetodo(
              icon: Icons.shopping_cart,
              titulo: "Compra de Pontos",
              descricao: "Comece com 10 e distribua estrategicamente.",
              onTap: () => context.read<PersonagemCubit>().escolherMetodoAtributos(MetodoAtributos.compra),
            ),
            const SizedBox(height: 16),
            _BotaoSelecaoMetodo(
              icon: Icons.casino,
              titulo: "Rolagem de Dados",
              descricao: "A sorte define seu destino (4d6 drop menor).",
              onTap: () => context.read<PersonagemCubit>().escolherMetodoAtributos(MetodoAtributos.rolagem),
            ),
          ],
        ),
      );
    }

    // escolheu comprar pontos 
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
                  Text("${state.pontosRestantesCompra}", 
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: state.personagem.atributos.entries.map((entry) {
                   return AtributoCardCompra(
                    sigla: entry.key,
                    atributo: entry.value,
                    onIncrement: () => context.read<PersonagemCubit>().alterarAtributoCompra(entry.key, 1),
                    onDecrement: () => context.read<PersonagemCubit>().alterarAtributoCompra(entry.key, -1),
                  );
                }).toList(),
              ),
            )
        ],
      );
    }

    // usuario escolheu rodar os dados
    if (state.metodoAtributos == MetodoAtributos.rolagem) {
      return _TelaRolagemAtributos(state: state);
  
    }

    return Container();
  }
}



class _BotaoSelecaoMetodo extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String descricao;
  final VoidCallback onTap;

  const _BotaoSelecaoMetodo({required this.icon, required this.titulo, required this.descricao, required this.onTap});

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
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 4))],
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Colors.red[900]),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(descricao, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// modificar pagina no futuro.
class _PaginaFinalizacao extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.all(20)),
        onPressed: () {
          // Aqui sim salvamos!
          //context.read<PersonagemCubit>().salvarPersonagemFinal(context);
        },
        child: const Text("SALVAR PERSONAGEM FINAL", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

class _TelaRolagemAtributos extends StatelessWidget {
  final PersonagemState state;

  const _TelaRolagemAtributos({required this.state});

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
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
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
              const Text("Valores Disponíveis:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: state.valoresRolados.map((val) => Chip(
                  label: Text(val >= 0 ? "+$val" : "$val", style: const TextStyle(fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.white,
                  elevation: 1,
                )).toList(),
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
                  title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(entry.value.nome),
                  
                  // Feedback Visual (Cinza = Vazio, Azul = Preenchido)
                  leading: CircleAvatar(
                    backgroundColor: indiceAlocadoParaMim != null ? Colors.indigo : Colors.grey[300],
                    child: Text(
                      entry.value.valor >= 0 ? "+${entry.value.valor}" : "${entry.value.valor}",
                      style: TextStyle(
                        color: indiceAlocadoParaMim != null ? Colors.white : Colors.black38, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ),

                  // O Dropdown com Travamento
                  trailing: DropdownButton<int>(
                    hint: const Text("Escolher"),
                    value: indiceAlocadoParaMim, 
                    underline: Container(), 
                    
                    items: state.valoresRolados.asMap().entries.map((mapEntry) {
                      int index = mapEntry.key;
                      int valor = mapEntry.value;

                      // Lógica de Bloqueio:
                      // Livre se ninguem usa, OU se quem usa sou eu mesmo
                      bool estaLivre = !state.alocacaoIndices.containsValue(index);
                      bool ehMeu = state.alocacaoIndices[entry.key] == index;

                      if (!estaLivre && !ehMeu) {
                          return null; // Oculta da lista
                      }

                      return DropdownMenuItem<int>(
                        value: index,
                        child: Text(
                          valor >= 0 ? "+$valor" : "$valor",
                          style: TextStyle(
                            fontWeight: ehMeu ? FontWeight.bold : FontWeight.normal,
                            color: valor >= 2 ? Colors.green[700] : Colors.black
                          ),
                        ),
                      );
                    })
                    .where((item) => item != null).cast<DropdownMenuItem<int>>().toList(), 
                    
                    onChanged: (indexSelecionado) {
                      if (indexSelecionado != null) {
                        context.read<PersonagemCubit>().alocarDado(entry.key, indexSelecionado);
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

