import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:t20_creator/domain/entities/habilidades_complexas/linhagem_arcanista.dart';
import '../../../domain/entities/personagem/classe.dart';
import '../../../domain/entities/personagem/proficiencias.dart';
import '../../../domain/services/data_services/call_classes.dart';
import '../../../domain/services/data_services/call_poderes.dart';
import '../../../domain/services/powers_service/aprendizado_magia_service.dart';
import '../../controllers/ficha_controller/personagem_cubit.dart';
import '../../widgets/rpg_icon.dart';

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

    final poderesDoBanco = classeSelecionada != null
        ? BancoDePoderes.poderesDaClasse(classeSelecionada.idClasse)
        : <dynamic>[];

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
                          context.read<PersonagemCubit>().selecionarClasse(
                            classe,
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.grey[400]
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: isSelected
                                    ? Colors.brown.shade900
                                    : Colors.red.shade900,
                                child: RpgIcon(
                                  iconName: classe.iconeSvg,
                                  size: 14,
                                  color: isSelected
                                      ? Colors.amber
                                      : Colors.white,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  classe.nome,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.black
                                        : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Ícone da Classe
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.red.shade200,
                              width: 2,
                            ),
                          ),
                          child: RpgIcon(
                            iconName: classeSelecionada.iconeSvg,
                            size: 64,
                            color: Colors.red[800],
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
                          height: 1.3,
                        ),
                        textAlign: TextAlign.justify,
                      ),
                      const SizedBox(height: 16),

                      // Painel de Proficiências e Equipamentos
                      _PainelProficienciasEquipamentos(
                        classe: classeSelecionada,
                        caminho: caminhoSelecionado,
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
                            TextSpan(text: "${classeSelecionada.pmInicial}\n"),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),

                      // 1. CAMINHOS DE CLASSE (NÍVEL 1)
                      if (classeSelecionada.caminhosNivel1.isNotEmpty) ...[
                        Row(
                          children: [
                            const Text(
                              "Caminhos Arcanos",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.circle,
                              color: Colors.red[700],
                              size: 12,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Você deve escolher seu caminho no 1º Nível:",
                          style: TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        ...classeSelecionada.caminhosNivel1.map((caminho) {
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
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
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
                          isSelected:
                              widget
                                      .state
                                      .personagem
                                      .classes[0]
                                      .linhagemEscolhida
                                  is LinhagemDraconica,
                          onTap: () => _mostrarModalDraconico(context),
                        ),
                        _LinhagemCard(
                          nome: "Feérica",
                          descricao:
                              "Ancestralidade das fadas. Aprende uma magia extra de Encantamento ou Ilusão.",
                          isSelected:
                              widget
                                      .state
                                      .personagem
                                      .classes[0]
                                      .linhagemEscolhida
                                  is LinhagemFeerica,
                          onTap: () {
                            context.read<PersonagemCubit>().selecionarLinhagem(
                              LinhagemFeerica(
                                magiaBonusEncantamentoOuIlusao: "A Escolher",
                              ),
                            );
                          },
                        ),
                        _LinhagemCard(
                          nome: "Rubra",
                          descricao:
                              "A mácula da Tormenta corre nas suas veias. Interage com Poderes da Tormenta.",
                          isSelected:
                              widget
                                      .state
                                      .personagem
                                      .classes[0]
                                      .linhagemEscolhida
                                  is LinhagemRubra,
                          onTap: () {
                            context.read<PersonagemCubit>().selecionarLinhagem(
                              LinhagemRubra(),
                            );
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
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: const Text(
                            "Ganha automaticamente ao subir de nível",
                          ),
                          iconColor: Colors.red[900],
                          collapsedIconColor: Colors.grey,
                          children: classeSelecionada.habilidadesFixas.entries
                              .map((entry) {
                                return ListTile(
                                  title: Text(
                                    entry.key,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Text(
                                    entry.value,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                );
                              })
                              .toList(),
                        ),
                      ],

                      // 4. PODERES DA CLASSE
                      if (poderesDoBanco.isNotEmpty) ...[
                        ExpansionTile(
                          title: const Text(
                            "Poderes da Classe",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: const Text(
                            "Pode escolher 1 a cada nível a partir do nível 2",
                          ),
                          iconColor: Colors.red[900],
                          collapsedIconColor: Colors.grey,
                          children: poderesDoBanco.map((poder) {
                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
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
                                      Icon(
                                        Icons.bolt,
                                        size: 16,
                                        color: Colors.orange[700],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        poder.nome,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Column(
                                    children: [
                                      Text(
                                        poder.descricao,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black87,
                                        ),
                                      ),

                                      if (poder.preRequisitoTexto.isNotEmpty)
                                        Text(
                                          poder.preRequisitoTexto,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black87,
                                          ),
                                        ),
                                    ],
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
                title: Text(
                  tipo.name.toUpperCase(),
                ), // Mostra ACIDO, FOGO, etc.
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

class _PainelProficienciasEquipamentos extends StatelessWidget {
  final Classe classe;
  final CaminhoDeClasse? caminho;

  const _PainelProficienciasEquipamentos({
    required this.classe,
    this.caminho,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Armas
    final temMarciais =
        classe.proficiencias.contains(TipoProficiencia.armasMarciais);
    final textoArmas =
        temMarciais ? 'Armas Marciais e Simples' : 'Apenas Armas Simples';

    // 2. Armaduras e Escudos
    final ehArcanista = classe.idClasse.trim().toLowerCase() == 'arcanista';
    final temPesadas =
        classe.proficiencias.contains(TipoProficiencia.armadurasPesadas);
    final temLeves =
        !ehArcanista ||
        classe.proficiencias.contains(TipoProficiencia.armadurasLeves);
    final temEscudos = classe.proficiencias.contains(TipoProficiencia.escudos);

    String textoArmaduras;
    if (!temLeves && !temPesadas && !temEscudos) {
      textoArmaduras = 'Nenhuma';
    } else if (temPesadas) {
      textoArmaduras =
          temEscudos
              ? 'Armaduras Leves, Pesadas e Escudos'
              : 'Armaduras Leves e Pesadas';
    } else if (temLeves) {
      textoArmaduras =
          temEscudos ? 'Armaduras Leves e Escudos' : 'Armaduras Leves';
    } else {
      textoArmaduras = 'Escudos';
    }

    // 3. Conjuração / Foco Mágico
    final regras = AprendizadoMagiaService.obterRegrasIniciais(
      classe.idClasse,
      caminhoId: caminho?.nome,
    );

    String textoConjuracao;
    if (regras.isConjurador) {
      final tipo = regras.tipoMagia == 'arcana' ? 'Arcana' : 'Divina';
      if (ehArcanista && caminho == null) {
        textoConjuracao = 'Conjuradora $tipo (atributo-chave: INT ou CAR)';
      } else if (caminho?.temFocoMagico == true) {
        textoConjuracao =
            'Conjuradora $tipo (atributo-chave: ${regras.atributoChave}, requer Foco Mágico)';
      } else {
        textoConjuracao =
            'Conjuradora $tipo (atributo-chave: ${regras.atributoChave})';
      }
    } else {
      textoConjuracao = 'Não-conjuradora';
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shield_outlined,
                size: 18,
                color: Colors.red[800],
              ),
              const SizedBox(width: 8),
              Text(
                'Proficiências e Equipamentos',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.red[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _itemInfo(
            icone: Icons.sports_martial_arts,
            rotulo: 'Armas',
            valor: textoArmas,
          ),
          const SizedBox(height: 6),
          _itemInfo(
            icone: Icons.shield,
            rotulo: 'Armaduras e Escudos',
            valor: textoArmaduras,
          ),
          const SizedBox(height: 6),
          _itemInfo(
            icone: Icons.auto_fix_high,
            rotulo: 'Conjuração / Foco Mágico',
            valor: textoConjuracao,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 15,
                  color: Colors.amber.shade900,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Você selecionará e equipará suas armas, armadura e escudo na Etapa 6 (Equipamento Inicial).',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.brown.shade900,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemInfo({
    required IconData icone,
    required String rotulo,
    required String valor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icone, size: 14, color: const Color(0xFF6B7280)),
        const SizedBox(width: 6),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$rotulo: ',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF374151),
                  ),
                ),
                TextSpan(
                  text: valor,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

