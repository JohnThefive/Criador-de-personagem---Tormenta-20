import 'package:flutter/material.dart';
import '../../../../domain/entities/combate/combatente.dart';
import '../../../../domain/entities/combate/inimigos_treino.dart';
import '../../../../domain/entities/personagem/personagem.dart';
import '../../../widgets/character_avatar_widget.dart';

class SelecaoInimigosView extends StatelessWidget {
  final Personagem heroi;
  final List<Combatente> selecionados;
  final void Function(Combatente c) onToggleInimigo;
  final VoidCallback onAvancar;
  final VoidCallback? onCriarInimigo;

  const SelecaoInimigosView({
    super.key,
    required this.heroi,
    required this.selecionados,
    required this.onToggleInimigo,
    required this.onAvancar,
    this.onCriarInimigo,
  });

  void _tratarCriarInimigo(BuildContext context) {
    if (onCriarInimigo != null) {
      onCriarInimigo!();
      return;
    }

    // Rota / Placeholder estruturado para a futura tela de criação de inimigo
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Icon(
              Icons.construction_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Em breve: O Criador de Monstros e Ameaças customizadas estará disponível!',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todosInimigos = InimigosTreino.todos;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header com Avatar unificado do Herói
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              children: [
                CharacterAvatarWidget(
                  personagem: heroi,
                  size: 48,
                  borderRadius: 12,
                  useHero: true,
                  heroTag: 'arena-selector-${heroi.id}',
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        heroi.nome,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${heroi.pvTotal} PV • Defesa ${heroi.defesaFinal} • Inic. +${heroi.getValorPericia("INICIATIVA")}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Escolha os Inimigos para o Teste:',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: todosInimigos.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                // Item 0: Card de Destaque "Criar Inimigo"
                if (index == 0) {
                  return Card(
                    color: const Color(0xFF1E293B),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: colorScheme.primary.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: colorScheme.primary.withValues(
                          alpha: 0.2,
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          color: colorScheme.primary,
                          size: 26,
                        ),
                      ),
                      title: Text(
                        'Criar Novo Inimigo',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: const Text(
                        'Monte uma ameaça customizada com atributos, armas e PV',
                        style: TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Em breve',
                          style: TextStyle(
                            color: Colors.amberAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      onTap: () => _tratarCriarInimigo(context),
                    ),
                  );
                }

                final monstro = todosInimigos[index - 1];
                final isSelected = selecionados.any((c) => c.id == monstro.id);

                return ListTile(
                  tileColor: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isSelected ? Colors.amberAccent : Colors.white12,
                    ),
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Colors.red[900],
                    child: Text(
                      '$index',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    monstro.nome,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '${monstro.pvMax} PV • Defesa ${monstro.defesa} • Desloc. ${monstro.deslocamentoMetros}m\nArmas: ${monstro.armas.map((a) => a.nome).join(", ")}',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  trailing: Checkbox(
                    value: isSelected,
                    activeColor: Colors.amberAccent,
                    checkColor: Colors.black,
                    onChanged: (_) => onToggleInimigo(monstro),
                  ),
                  onTap: () => onToggleInimigo(monstro),
                );
              },
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.arrow_forward),
            label: Text(
              'Avançar para Rolagem (${selecionados.length} ${selecionados.length == 1 ? "Inimigo" : "Inimigos"})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            onPressed: selecionados.isNotEmpty ? onAvancar : null,
          ),
        ],
      ),
    );
  }
}
