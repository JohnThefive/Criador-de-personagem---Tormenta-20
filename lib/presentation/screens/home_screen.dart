import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Imports necessários (ajuste os caminhos se suas pastas forem diferentes)
import '../controllers/home_cubit.dart';
import 'char_creation_screen.dart'; // Importe a tela de criação aqui
import 'painel_jogador_screen.dart';
import '../../domain/entities/personagem.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Cor Principal baseada no seu design (Vermelho T20)
    final t20Red = const Color.fromARGB(255, 255, 0, 0); 

    return Scaffold(
      backgroundColor: t20Red, // Fundo Vermelho
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("T20 - Criador de herois", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      
      // O MENU DE BAIXO 
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(), // Recorte para o dado
        color: Colors.black,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(icon: const Icon(Icons.settings, color: Colors.white), onPressed: () {}),
              IconButton(icon: const Icon(Icons.person, color: Colors.white), onPressed: () {}),
              const SizedBox(width: 40), // Espaço para o botão do meio
              IconButton(icon: const Icon(Icons.description, color: Colors.white), onPressed: () {}), 
              IconButton(icon: const Icon(Icons.language, color: Colors.white), onPressed: () {}), 
            ],
          ),
        ),
      ),
      
      // O DADO D20 NO MEIO (Floating Action Button) // colocar d20 futuramente
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
            // Ação rápida (rolar dado avulso futuramente)
        },
        backgroundColor: Colors.white,
        child: const Icon(Icons.casino, color: Colors.red, size: 30),
      ),

      // O CORPO DA TELA
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          return Column(
            children: [
              // Banner de Boas Vindas
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: const [
                    Text("Bem Vindo ao criador de herois !!", 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18), textAlign: TextAlign.center),
                    SizedBox(height: 8),
                    Text("Crie Personagens complexos e suba de nível com eles.", 
                      style: TextStyle(fontSize: 12), textAlign: TextAlign.center),
                  ],
                ),
              ),

              // Lista de Personagens
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  // Soma +1 ao tamanho da lista para incluir o botão de criar
                  itemCount: state.personagens.length + 1, 
                  itemBuilder: (context, index) {
                    
                    // O PRIMEIRO ITEM É O BOTÃO DE CRIAR
                    if (index == 0) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CharacterCreatorScreen(),
                            ),
                          ).then((_) {
                            if (context.mounted) {
                              context.read<HomeCubit>().carregarPersonagensReais();
                            }
                          });
                        },
                        child: Container(
                          height: 100,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.add, size: 40, color: Colors.black),
                              SizedBox(width: 10),
                              Text(
                                "Criar Personagem",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // OS DEMAIS ITENS SÃO OS PERSONAGENS DA LISTA
                    final personagem = state.personagens[index - 1];
                    return _CharacterCard(personagem: personagem);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Widget Separado para o Card do Personagem (Privado neste arquivo)
class _CharacterCard extends StatelessWidget {
  final Personagem personagem;

  const _CharacterCard({required this.personagem});

  void _confirmarExclusao(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFB71C1C), size: 28),
            SizedBox(width: 8),
            Text(
              "Excluir Personagem",
              style: TextStyle(
                color: Color(0xFF1F2937),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          'Tem certeza de que deseja excluir "${personagem.nome}"?\nEsta ação apagará a ficha permanentemente e não pode ser desfeita.',
          style: const TextStyle(color: Color(0xFF374151), fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("CANCELAR", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB71C1C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<HomeCubit>().excluirPersonagem(personagem.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Personagem "${personagem.nome}" excluído.'),
                  backgroundColor: Colors.black87,
                ),
              );
            },
            child: const Text(
              "EXCLUIR",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final temFoto = personagem.caminhoFoto != null &&
        personagem.caminhoFoto!.isNotEmpty &&
        File(personagem.caminhoFoto!).existsSync();

    final classeNome = personagem.classes.isNotEmpty
        ? personagem.classes[0].classeDefinicao.nome
        : "Sem Classe";
    final racaNome = personagem.raca?.nome ?? "Sem Raça";
    final nivel = personagem.nivelPersonagem > 0 ? personagem.nivelPersonagem : 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF8B0000), // Carmesim profundo para contraste e elegância
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PainelJogadorScreen(personagemInicial: personagem),
              ),
            ).then((_) {
              if (context.mounted) {
                context.read<HomeCubit>().carregarPersonagensReais();
              }
            });
          },
          onLongPress: () => _confirmarExclusao(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Avatar / Foto
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 62,
                    height: 62,
                    color: Colors.black38,
                    child: temFoto
                        ? Image.file(
                            File(personagem.caminhoFoto!),
                            width: 62,
                            height: 62,
                            fit: BoxFit.cover,
                          )
                        : const Icon(
                            Icons.person,
                            color: Colors.white70,
                            size: 38,
                          ),
                  ),
                ),
                const SizedBox(width: 14),

                // Textos descritivos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        personagem.nome,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "$classeNome • $racaNome",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "Nvl $nivel",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "PV: ${personagem.pvTotal}  •  PM: ${personagem.pmTotal}",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Ícone de opções / menu de deleção rápida
                IconButton(
                  tooltip: "Opções (segure para excluir)",
                  icon: const Icon(Icons.delete_outline, color: Colors.white70),
                  onPressed: () => _confirmarExclusao(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}