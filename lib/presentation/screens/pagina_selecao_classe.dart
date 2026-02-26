import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/services/banco_classes.dart';
import '../controllers/personagem_cubit.dart';

class PaginaSelecaoClasse extends StatelessWidget {
  final PersonagemState state;

  const PaginaSelecaoClasse({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    // Identifica qual classe está selecionada (se houver)
    final classeSelecionada = state.personagem.classes.isNotEmpty 
        ? state.personagem.classes[0].classeDefinicao 
        : null;

    final caminhoSelecionado = state.personagem.classes.isNotEmpty 
        ? state.personagem.classes[0].caminhoEscolhido 
        : null;

    return Row(
      children: [
        // --- MENU LATERAL ESQUERDO (VERMELHO) ---
        Container(
          width: 120, // Largura fixa para o menu
          color: Colors.red[600],
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  "Escolha Uma Classe",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
              const Divider(color: Colors.white54),
              Expanded(
                child: ListView.builder(
                  itemCount: BancoDeClasses.todas.length,
                  itemBuilder: (context, index) {
                    final classe = BancoDeClasses.todas[index];
                    final isSelected = classeSelecionada?.nome == classe.nome;

                    return GestureDetector(
                      onTap: () => context.read<PersonagemCubit>().selecionarClasse(classe),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.grey[400] : Colors.transparent,
                          borderRadius: BorderRadius.circular(20), // Estilo "Pílula"
                        ),
                        child: Text(
                          classe.nome,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // --- CONTEÚDO À DIREITA (BRANCO) ---
        Expanded(
          child: Container(
            color: Colors.white,
            child: classeSelecionada == null
                ? const Center(child: Text("Selecione uma classe ao lado."))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Fonte do Livro
                      Row(
                        children: [
                          Icon(Icons.circle, color: Colors.red[700], size: 12),
                          const SizedBox(width: 4),
                          const Text("Fonte: Tormenta 20", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 1. A Imagem da Classe
      ClipRRect(
        borderRadius: BorderRadius.circular(12), // Arredonda as pontas da imagem
        child: Image.asset(
          classeSelecionada.caminhoImagem,
          width: double.infinity, // Faz a imagem preencher a largura toda
          fit: BoxFit.cover, // Preenche o espaço sem achatar a imagem
          // Caso a imagem não seja encontrada, mostra um ícone de erro para o app não "quebrar"
          errorBuilder: (context, error, stackTrace) => Container(
            height: 150,
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
          ),
        ),
      ),
      
      const SizedBox(height: 16),

      // 2. A Descrição da Classe
      Text(
        classeSelecionada.descricaoclasse, // Certifique-se de que a variável chama descricaoclasse no seu banco
        style: const TextStyle(
          fontSize: 14, 
          color: Colors.black87,
          height: 1.3, // Dá um pequeno respiro entre as linhas do texto
        ),
        textAlign: TextAlign.justify, // Deixa o texto alinhado retinho nas bordas (como num livro)
      ),
      
      const SizedBox(height: 16),

                      

                      // Botão de Equipamento Inicial
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[400]),
                        child: const Text("Equipamento inicial", style: TextStyle(color: Colors.black)),
                      ),
                      const SizedBox(height: 16),

                      // Atributos Mecânicos
                      Text.rich(TextSpan(children: [
                        const TextSpan(text: "Pontos de Vida (Nvl 1): ", style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: "${classeSelecionada.pvInicial} + Modificador de Constituição\n"),
                        const TextSpan(text: "Pontos de Mana (Nvl 1): ", style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: "${classeSelecionada.pmInicial}\n"),
                      ])),
                      
                      const SizedBox(height: 16),
                      const Divider(),

                      // --- SEÇÃO DE CAMINHOS/SUBCLASSES ---
                      if (classeSelecionada.caminhosDisponiveis.isNotEmpty) ...[
                        Row(
                          children: [
                            const Text("Caminhos Arcanos", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            const SizedBox(width: 8),
                            Icon(Icons.circle, color: Colors.red[700], size: 12),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text("Você deve escolher seu caminho no 1º Nível:", style: TextStyle(fontSize: 12)),
                        const SizedBox(height: 12),

                        // Lista de Botões para os Caminhos
                        ...classeSelecionada.caminhosDisponiveis.map((caminho) {
                          final isCaminhoSelecionado = caminhoSelecionado?.nome == caminho.nome;
                          return GestureDetector(
                            onTap: () => context.read<PersonagemCubit>().selecionarCaminhoDaClasse(caminho),
                            child: Card(
                              color: isCaminhoSelecionado ? Colors.red[50] : Colors.white,
                              shape: RoundedRectangleBorder(
                                side: BorderSide(color: isCaminhoSelecionado ? Colors.red : Colors.grey[300]!, width: 2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(caminho.nome, style: TextStyle(fontWeight: FontWeight.bold, color: isCaminhoSelecionado ? Colors.red[900] : Colors.black)),
                                    const SizedBox(height: 4),
                                    Text(caminho.descricao, style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ]
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}