import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/services/banco_pericias.dart';
import '../../domain/entities/pericias.dart'; // Importe a entidade Pericia
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
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12, // Espaço vertical entre as linhas do Wrap
          children: classeDef.periciasFixas.map((key) {
            final pericia = _safeGetPericia(key); 
            if (pericia == null) return const SizedBox.shrink();

            return _PericiaCard(
              pericia: pericia,
              isFixed: true,
              isSelected: true,
              activeColor: const Color.fromARGB(255, 238, 255, 1),
            );
          }).toList(),
        ),
        
        const Divider(height: 40),

        // --- 2. ESCOLHAS DA CLASSE ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Escolhas da Classe", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(
              "${state.selecoesPericiaClasse.length} / ${classeDef.qtdPericiasEscolha}",
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                color: state.selecoesPericiaClasse.length == classeDef.qtdPericiasEscolha ? Colors.green : const Color.fromARGB(255, 255, 230, 0)
              ),
            ),
          ],
        ),
        const Text("Escolha entre as opções fornecidas pela sua classe:", style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: classeDef.periciasOpcoes.map((key) {
            final pericia = _safeGetPericia(key);
            if (pericia == null) return const SizedBox.shrink(); 

            final isSelected = state.selecoesPericiaClasse.contains(key);
            final isBlocked = state.selecoesPericiaInteligencia.contains(key);

            return _PericiaCard(
              pericia: pericia,
              isSelected: isSelected,
              isBlocked: isBlocked,
              activeColor: const Color.fromARGB(255, 255, 251, 0),
              onTap: isBlocked ? null : () => context.read<PersonagemCubit>().togglePericiaClasse(key),
            );
          }).toList(),
        ),
        
        // --- 3. ESCOLHAS DE INTELIGÊNCIA ---
        if (limiteInteligencia > 0) ...[
          const Divider(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Perícias Extras (Inteligência)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text(
                "${state.selecoesPericiaInteligencia.length} / $limiteInteligencia",
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  color: state.selecoesPericiaInteligencia.length == limiteInteligencia ? Colors.green : const Color.fromARGB(255, 255, 230, 0)
                ),
              ),
            ],
          ),
          const Text("Graças a sua Inteligência, escolha perícias adicionais livres:", style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: BancoDePericias.todas.map((pericia) {
              final key = pericia.key;
              
              if (classeDef.periciasFixas.contains(key)) return const SizedBox.shrink();

              final isSelected = state.selecoesPericiaInteligencia.contains(key);
              final isBlocked = state.selecoesPericiaClasse.contains(key);

              return _PericiaCard(
                pericia: pericia,
                isSelected: isSelected,
                isBlocked: isBlocked,
                activeColor: const Color.fromARGB(255, 255, 255, 0),
                onTap: isBlocked ? null : () => context.read<PersonagemCubit>().togglePericiaInteligencia(key),
              );
            }).toList(),
          ),
        ]
      ],
    );
  }

  Pericia? _safeGetPericia(String key) {
    try {
      return BancoDePericias.getByKey(key);
    } catch (e) {
      return null;
    }
  }
}

// --- NOVO WIDGET: O Card da Perícia ---
class _PericiaCard extends StatelessWidget {
  final Pericia pericia;
  final bool isSelected;
  final bool isBlocked;
  final bool isFixed;
  final Color activeColor;
  final VoidCallback? onTap;

  const _PericiaCard({
    required this.pericia,
    this.isSelected = false,
    this.isBlocked = false,
    this.isFixed = false,
    required this.activeColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Define o fundo do card com base no estado
    final bgColor = isFixed 
        ? activeColor.withValues(alpha: 0.05) 
        : isSelected 
            ? activeColor.withValues(alpha: 0.1) 
            : isBlocked 
                ? Colors.grey[200] 
                : Colors.white;

    final borderColor = (isFixed || isSelected) ? activeColor : Colors.grey[300]!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160, // Largura fixa cria um visual de "Grid" organizado dentro do Wrap
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: isSelected || isFixed ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Ocupa apenas o espaço necessário
          children: [
            // Linha do Título e Ícone
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    pericia.label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isBlocked ? Colors.grey : Colors.black,
                      decoration: isBlocked ? TextDecoration.lineThrough : null, // Risca se bloqueado
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isFixed)
                  Icon(Icons.lock, size: 16, color: activeColor)
                else if (isSelected)
                  Icon(Icons.check_circle, size: 18, color: activeColor),
              ],
            ),
            
            const SizedBox(height: 6),
            
            // Badge do Atributo Chave (ex: INT, DES)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isBlocked ? Colors.grey[300] : Colors.grey[800],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                pericia.atributoChave,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Descrição (Limitada a 3 linhas para o card não esticar muito)
            Text(
              pericia.descricao,
              style: TextStyle(
                fontSize: 11, 
                color: isBlocked ? Colors.grey : Colors.black87,
                height: 1.2,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}