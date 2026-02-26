import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/services/banco_pericias.dart';
import '../controllers/personagem_cubit.dart';

class PaginaSelecaoPericias extends StatelessWidget {
  final PersonagemState state;

  const PaginaSelecaoPericias({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.personagem.classes.isEmpty) return const Center(child: Text("Escolha uma classe primeiro"));

    final classeDef = state.personagem.classes[0].classeDefinicao;
    
    // Calcula quantas perícias de Inteligência o jogador tem direito
    final modInt = state.personagem.getValorFinal('INT');
    final limiteInteligencia = modInt > 0 ? modInt : 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // --- 1. PERÍCIAS FIXAS DA CLASSE ---
        const Text("Perícias Fixas da Classe", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const Text("Você já recebe treinamento nestas perícias automaticamente:", style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: classeDef.periciasFixas.map((key) {
            // Tenta buscar no banco, se não achar, mostra só a chave
            final pericia = _safeGetPericia(key); 
            return Chip(
              label: Text(pericia?.label ?? key, style: const TextStyle(color: Colors.white)),
              backgroundColor: Colors.red[900],
              avatar: const Icon(Icons.lock, color: Colors.white, size: 16),
            );
          }).toList(),
        ),
        const Divider(height: 32),

        // --- 2. ESCOLHAS DA CLASSE ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Escolhas da Classe", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(
              "${state.selecoesPericiaClasse.length} / ${classeDef.qtdPericiasEscolha}",
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                color: state.selecoesPericiaClasse.length == classeDef.qtdPericiasEscolha ? Colors.green : Colors.red
              ),
            ),
          ],
        ),
        const Text("Escolha entre as opções fornecidas pela sua classe:", style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: classeDef.periciasOpcoes.map((key) {
            final pericia = _safeGetPericia(key);
            if (pericia == null) return const SizedBox.shrink(); // Esconde se não estiver no banco

            final isSelected = state.selecoesPericiaClasse.contains(key);
            // Bloqueia se já escolheu na Inteligência
            final isBlocked = state.selecoesPericiaInteligencia.contains(key);

            return FilterChip(
              label: Text(pericia.label),
              selected: isSelected,
              onSelected: isBlocked ? null : (bool val) {
                context.read<PersonagemCubit>().togglePericiaClasse(key);
              },
              selectedColor: Colors.red[100],
              checkmarkColor: Colors.red[900],
            );
          }).toList(),
        ),
        
        // --- 3. ESCOLHAS DE INTELIGÊNCIA (Só aparece se tiver INT positiva) ---
        if (limiteInteligencia > 0) ...[
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Perícias Extras (Inteligência)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text(
                "${state.selecoesPericiaInteligencia.length} / $limiteInteligencia",
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  color: state.selecoesPericiaInteligencia.length == limiteInteligencia ? Colors.green : Colors.blue
                ),
              ),
            ],
          ),
          const Text("Graças a sua Inteligência, escolha perícias adicionais livres:", style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            // Lista TODAS as perícias do banco para ele escolher
            children: BancoDePericias.todas.map((pericia) {
              final key = pericia.key;
              
              // Esconde se for fixa da classe (já tem)
              if (classeDef.periciasFixas.contains(key)) return const SizedBox.shrink();

              final isSelected = state.selecoesPericiaInteligencia.contains(key);
              // Bloqueia se já escolheu na lista da Classe
              final isBlocked = state.selecoesPericiaClasse.contains(key);

              return FilterChip(
                label: Text(pericia.label),
                selected: isSelected,
                onSelected: isBlocked ? null : (bool val) {
                  context.read<PersonagemCubit>().togglePericiaInteligencia(key);
                },
                selectedColor: Colors.blue[100],
                checkmarkColor: Colors.blue[900],
              );
            }).toList(),
          ),
        ]
      ],
    );
  }

  // Função segura para evitar Crash se você esquecer de cadastrar a perícia no Banco
  dynamic _safeGetPericia(String key) {
    try {
      return BancoDePericias.getByKey(key);
    } catch (e) {
      return null;
    }
  }
}