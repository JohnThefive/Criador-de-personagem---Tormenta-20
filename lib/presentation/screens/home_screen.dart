import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Imports necessários (ajuste os caminhos se suas pastas forem diferentes)
import '../controllers/home_cubit.dart';
import 'char_creation_screen.dart'; // Importe a tela de criação aqui
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
                          // NAVEGAÇÃO: Vai para a tela de Atributos
                          // da tela de atributos pra outras telas 
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => CharacterCreatorScreen()),
                          );
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
                              Text("Criar Personagem", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFB71C1C), // Vermelho escuro para o card
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white24)
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        // Avatar
        leading: Container(
          width: 60, 
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[400],
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.person, color: Colors.white70, size: 40),
        ),
        // Textos
        title: Text(personagem.nome, 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Classe: Indefinida", style: TextStyle(color: Colors.white70)),
            Text("Nível: 1", style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.star_border, color: Colors.amber),
          onPressed: () {},
        ),
      ),
    );
  }
}

// fazer um card de personagem onde tenha nome/ foto, atributos, nivel e configuraões (deletar, colocar em pdf, etc)