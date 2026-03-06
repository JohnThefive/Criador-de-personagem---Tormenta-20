import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:t20_creator/domain/entities/linhagem_arcanista.dart';
import '../../domain/services/banco_classes.dart';
import '../controllers/personagem_cubit.dart';

class PaginaSelecaoClasse extends StatefulWidget {
  final PersonagemState state;

  const PaginaSelecaoClasse({super.key, required this.state});

  @override
  State<PaginaSelecaoClasse> createState() => _PaginaSelecaoClasseState();
}

class _PaginaSelecaoClasseState extends State<PaginaSelecaoClasse> {
  bool _menuAberto = true;

  @override
  Widget build(BuildContext context) {
    final classeSelecionada = widget.state.personagem.classes.isNotEmpty
        ? widget.state.personagem.classes[0].classeDefinicao
        : null;

    final caminhoSelecionado = widget.state.personagem.classes.isNotEmpty
        ? widget.state.personagem.classes[0].caminhoEscolhido
        : null;

    return Row(
      children: [
        // MENU LATERAL
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
                  child: Text(
                    "Escolha Uma Classe",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
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
                        onTap: () {
                          context.read<PersonagemCubit>().selecionarClasse(classe);
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.grey[400]
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            classe.nome,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
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

        // BOTÃO DE TOGGLE
        GestureDetector(
          onTap: () {
            setState(() {
              _menuAberto = !_menuAberto;
            });
          },
          child: Container(
            width: 24,
            height: double.infinity,
            color: Colors.red[800],
            child: Icon(
              _menuAberto ? Icons.chevron_left : Icons.chevron_right,
              color: Colors.white,
            ),
          ),
        ),

        // CONTEÚDO PRINCIPAL
        Expanded(
          child: Container(
            color: Colors.white,
            child: classeSelecionada == null
                ? const Center(child: Text("Selecione uma classe ao lado."))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Fonte
                      Row(
                        children: [
                          Icon(Icons.circle, color: Colors.red[700], size: 12),
                          const SizedBox(width: 4),
                          const Text(
                            "Fonte: Tormenta 20",
                            style: TextStyle(
                                fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Imagem da Classe
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          classeSelecionada.caminhoImagem,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            height: 150,
                            color: Colors.grey[300],
                            child: const Icon(Icons.broken_image,
                                size: 50, color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Descrição da Classe
                      Text(
                        classeSelecionada.descricaoclasse,
                        style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            height: 1.3),
                        textAlign: TextAlign.justify,
                      ),
                      const SizedBox(height: 16),

                      // Equipamento Inicial
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[400]),
                        child: const Text("Equipamento inicial",
                            style: TextStyle(color: Colors.black)),
                      ),
                      const SizedBox(height: 16),

                      // Atributos Mecânicos
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(
                              text: "Pontos de Vida (Nvl 1): ",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text:
                                  "${classeSelecionada.pvInicial} + Modificador de Constituição\n",
                            ),
                            const TextSpan(
                              text: "Pontos de Mana (Nvl 1): ",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: "${classeSelecionada.pmInicial}\n",
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),

                      // 1. CAMINHOS DE CLASSE
                      if (classeSelecionada.caminhosDisponiveis.isNotEmpty) ...[
                        Row(
                          children: [
                            const Text(
                              "Caminhos Arcanos",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.circle,
                                color: Colors.red[700], size: 12),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Você deve escolher seu caminho no 1º Nível:",
                          style: TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        ...classeSelecionada.caminhosDisponiveis.map((caminho) {
                          final isCaminhoSelecionado =
                              caminhoSelecionado?.nome == caminho.nome;
                          return GestureDetector(
                            onTap: () => context
                                .read<PersonagemCubit>()
                                .selecionarCaminhoDaClasse(caminho),
                            child: Card(
                              color: isCaminhoSelecionado
                                  ? Colors.red[50]
                                  : Colors.white,
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  color: isCaminhoSelecionado
                                      ? Colors.red
                                      : Colors.grey[300]!,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      caminho.nome,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isCaminhoSelecionado
                                            ? Colors.red[900]
                                            : Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      caminho.descricao,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],

                      // 2. LINHAGEM (FEITICEIRO)
                      if (caminhoSelecionado?.nome == "Feiticeiro") ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        Row(
                          children: [
                            Icon(Icons.bloodtype, color: Colors.red[700]),
                            const SizedBox(width: 8),
                            const Text(
                              "Linhagem Sobrenatural",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Sua magia provém de uma herança ancestral. Escolha sua linhagem:",
                          style: TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        _LinhagemCard(
                          nome: "Dracônica",
                          descricao:
                              "Descende de dragões. Concede bônus de PV e poderes elementais.",
                          isSelected: widget.state.personagem.classes[0]
                              .linhagemEscolhida is LinhagemDraconica,
                          onTap: () => _mostrarModalDraconico(context),
                        ),
                        _LinhagemCard(
                          nome: "Feérica",
                          descricao:
                              "Ancestralidade das fadas. Aprende uma magia extra de Encantamento ou Ilusão.",
                          isSelected: widget.state.personagem.classes[0]
                              .linhagemEscolhida is LinhagemFeerica,
                          onTap: () {
                            context.read<PersonagemCubit>().selecionarLinhagem(
                                LinhagemFeerica(
                                    magiaBonusEncantamentoOuIlusao:
                                        "A Escolher"));
                          },
                        ),
                        _LinhagemCard(
                          nome: "Rubra",
                          descricao:
                              "A mácula da Tormenta corre nas suas veias. Interage com Poderes da Tormenta.",
                          isSelected: widget.state.personagem.classes[0]
                              .linhagemEscolhida is LinhagemRubra,
                          onTap: () {
                            context
                                .read<PersonagemCubit>()
                                .selecionarLinhagem(LinhagemRubra());
                          },
                        ),
                      ],

                      // 3. HABILIDADES FIXAS
                      if (classeSelecionada.habilidadesFixas.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        ExpansionTile(
                          title: const Text(
                            "Habilidades de Classe",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: const Text(
                              "Ganha automaticamente ao subir de nível"),
                          iconColor: Colors.red[900],
                          collapsedIconColor: Colors.grey,
                          children: classeSelecionada.habilidadesFixas.entries
                              .map((entry) {
                            return ListTile(
                              title: Text(
                                entry.key,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              subtitle: Text(
                                entry.value,
                                style: const TextStyle(fontSize: 12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                            );
                          }).toList(),
                        ),
                      ],

                      // 4. PODERES DA CLASSE
                      if (classeSelecionada.poderesDaClasse.isNotEmpty) ...[
                        ExpansionTile(
                          title: const Text(
                            "Poderes da Classe",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: const Text(
                              "Pode escolher 1 a cada nível a partir do nível 2"),
                          iconColor: Colors.red[900],
                          collapsedIconColor: Colors.grey,
                          children: classeSelecionada.poderesDaClasse.entries
                              .map((entry) {
                            return Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.bolt,
                                          size: 16, color: Colors.orange[700]),
                                      const SizedBox(width: 4),
                                      Text(
                                        entry.key,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    entry.value,
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black87),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  // Modal para seleção do tipo de dragão da linhagem dracônica
  // Modal para seleção do tipo de dragão da linhagem dracônica
  void _mostrarModalDraconico(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Tipo de Dragão"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Escolha o tipo de dragão da sua ancestralidade:"),
            const SizedBox(height: 12),
            // Itera diretamente sobre o Enum que criamos
            ...TipoDanoDraconico.values.map(
              (tipo) => ListTile(
                title: Text(tipo.name.toUpperCase()), // Mostra ACIDO, FOGO, etc.
                onTap: () {
                  context.read<PersonagemCubit>().selecionarLinhagem(
                        // Usa o nome correto do parâmetro e passa o valor do enum
                        LinhagemDraconica(tipoDanoEscolhido: tipo),
                      );
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancelar"),
          ),
        ],
      ),
    );
  }
}

// Widget auxiliar para os cards de linhagem
class _LinhagemCard extends StatelessWidget {
  final String nome;
  final String descricao;
  final bool isSelected;
  final VoidCallback onTap;

  const _LinhagemCard({
    required this.nome,
    required this.descricao,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: isSelected ? Colors.red[50] : Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: isSelected ? Colors.red : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nome,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.red[900] : Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(descricao, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}