import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:t20_creator/presentation/controllers/home_cubit.dart';
import 'package:t20_creator/presentation/screens/pagina_pericias.dart';
import 'package:t20_creator/presentation/screens/pagina_racas.dart';
import 'package:t20_creator/presentation/screens/pagina_selecao_classe.dart';
import 'package:t20_creator/presentation/screens/pagina_origens.dart';
import 'package:t20_creator/presentation/screens/pagina_divindades.dart';
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
      listenWhen: (previous, current) =>
          previous.etapaAtual != current.etapaAtual,
      listener: (context, state) {
        // Animação suave quando o Cubit diz que mudou de etapa
        _pageController.animateToPage(
          state.etapaAtual,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      builder: (context, state) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              return;
            }
            final cubit = context.read<PersonagemCubit>();

            // Se estiver avançado no Wizard (Raça, etc), volta uma etapa
            if (state.etapaAtual > 0) {
              cubit.voltarEtapa();
            }
            // Se estiver na etapa 0 mas já escolheu um método (Rolagem/Compra), reseta pro inicio
            else if (state.metodoAtributos != MetodoAtributos.nenhum) {
              cubit.escolherMetodoAtributos(MetodoAtributos.nenhum);
            }
            // 3. Se estiver no começo de tudo, limpa a memória e fecha a tela
            else {
              cubit.resetarCriacao(); // (Limpa o estado sujo)
              Navigator.pop(context);
            }
          },
          child: Scaffold(
            backgroundColor: const Color(0xFFF4F6F8),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 1,
              shadowColor: Colors.black.withValues(alpha: 0.08),
              iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
              title: Text(
                _getTituloEtapa(state.etapaAtual),
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  // Se estiver na primeira etapa, sai da tela. Se não, volta um passo.
                  if (state.etapaAtual == 0 &&
                      state.metodoAtributos == MetodoAtributos.nenhum) {
                    Navigator.pop(context);
                  } else {
                    context.read<PersonagemCubit>().voltarEtapa();
                  }
                },
              ),
              // Botão de avançar só aparece quando uma atividade é concluida
              actions: [
                if (_deveMostrarBotaoAvancar(state))
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: TextButton(
                      onPressed: () =>
                          context.read<PersonagemCubit>().avancarEtapa(),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFB71C1C),
                      ),
                      child: const Row(
                        children: [
                          Text(
                            "Próximo",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            body: PageView(
              controller: _pageController,
              physics:
                  const NeverScrollableScrollPhysics(), // Bloqueia swipe manual
              children: [
                _PaginaAtributos(state: state), // pagina de atributos
                PaginaSelecaoRaca(state: state), // pagina de seleção de raça
                PaginaSelecaoClasse(
                  state: state,
                ), // pagina de seleçao de classe
                // fazer uma pagina de origens
                // fazer uma pagina de deuses
                PaginaSelecaoPericias(
                  state: state,
                ), // Pagina de seleção de pericias
                PaginaSelecaoOrigem(
                  state: state,
                ), // Pagina de seleção de origem
                PaginaSelecaoDivindade(
                  state: state,
                ), // Pagina de seleção de divindade
                _PaginaFinalizacao(), // Última Etapa
              ],
            ),
          ),
        );
      },
    );
  }

  String _getTituloEtapa(int step) {
    switch (step) {
      case 0:
        return "Definir Atributos";
      case 1:
        return "Escolher Raça";
      case 2:
        return "Escolher Classe";
      case 3:
        return "Escolher Perícias";
      case 4:
        return "Escolher Origem";
      case 5:
        return "Escolher Divindade";
      case 6:
        return "Finalização";
      default:
        return "Criação de Personagem";
    }
  }

  bool _deveMostrarBotaoAvancar(PersonagemState state) {
    // 1. LÓGICA DA ETAPA 0 (ATRIBUTOS)
    if (state.etapaAtual == 0) {
      // Compra de Pontos: Só avança se zerou
      if (state.metodoAtributos == MetodoAtributos.compra) {
        return state.pontosRestantesCompra == 0;
      }
      // Rolagem: Só avança se alocou os 6 dados
      if (state.metodoAtributos == MetodoAtributos.rolagem) {
        return state.alocacaoIndices.length == 6;
      }
      // Se não escolheu método, esconde o botão
      return false;
    }

    // 2. LÓGICA DA ETAPA 1 (RAÇA) - (Isso estava dentro do if anterior por engano)
    if (state.etapaAtual == 1) {
      return state.personagem.raca != null;
    }

    if (state.etapaAtual == 2) {
      if (state.personagem.classes.isEmpty) {
        return false;
      }

      final classeSelecionada = state.personagem.classes[0];

      // Se tem caminhos, precisa escolher um
      if (classeSelecionada.classeDefinicao.caminhosDisponiveis.isNotEmpty) {
        if (classeSelecionada.caminhoEscolhido == null) return false;

        // Se o caminho escolhido for Feiticeiro, OBRIGA a escolher a Linhagem
        if (classeSelecionada.caminhoEscolhido!.nome == "Feiticeiro") {
          if (classeSelecionada.linhagemEscolhida == null) return false;
        }
      }
      return true;
    }

    // Logica de pericias
    if (state.etapaAtual == 3) {
      if (state.personagem.classes.isEmpty) return false;

      final classeDef = state.personagem.classes[0].classeDefinicao;

      // Verificou se escolheu as pericias de classe
      bool completouClasse =
          state.selecoesPericiaClasse.length == classeDef.qtdPericiasEscolha;

      // Verificou se gastou as extras de INT?
      final modInt = state.personagem.getValorFinal('INT');
      final limiteInteligencia = modInt > 0 ? modInt : 0;
      bool completouInt =
          state.selecoesPericiaInteligencia.length == limiteInteligencia;

      // Só avança se completou as duas exigências
      return completouClasse && completouInt;
    }

    // 4. LÓGICA DA ETAPA 4 (ORIGEM)
    if (state.etapaAtual == 4) {
      return state.concluiuOrigem;
    }

    // 5. LÓGICA DA ETAPA 5 (DIVINDADE)
    if (state.etapaAtual == 5) {
      return state.etapaDivindadeConcluida;
    }

    // Na última etapa (Finalização), não exibe botão "Próximo"
    if (state.etapaAtual >= 6) {
      return false;
    }

    return true;
  }
}

// Widget de Atributos
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
            const Text(
              "Como você quer definir seus atributos?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            _BotaoSelecaoMetodo(
              icon: Icons.shopping_cart,
              titulo: "Compra de Pontos",
              descricao: "Comece com 10 e distribua estrategicamente.",
              onTap: () => context
                  .read<PersonagemCubit>()
                  .escolherMetodoAtributos(MetodoAtributos.compra),
            ),
            const SizedBox(height: 16),
            _BotaoSelecaoMetodo(
              icon: Icons.casino,
              titulo: "Rolagem de Dados",
              descricao: "A sorte define seu destino (4d6 drop menor).",
              onTap: () => context
                  .read<PersonagemCubit>()
                  .escolherMetodoAtributos(MetodoAtributos.rolagem),
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
                Text(
                  "${state.pontosRestantesCompra}",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: state.personagem.atributos.entries.map((entry) {
                return AtributoCardCompra(
                  sigla: entry.key,
                  atributo: entry.value,
                  onIncrement: () => context
                      .read<PersonagemCubit>()
                      .alterarAtributoCompra(entry.key, 1),
                  onDecrement: () => context
                      .read<PersonagemCubit>()
                      .alterarAtributoCompra(entry.key, -1),
                );
              }).toList(),
            ),
          ),
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

  const _BotaoSelecaoMetodo({
    required this.icon,
    required this.titulo,
    required this.descricao,
    required this.onTap,
  });

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
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Colors.red[900]),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    descricao,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
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
class _PaginaFinalizacao extends StatefulWidget {
  @override
  State<_PaginaFinalizacao> createState() => _PaginaFinalizacaoState();
}

class _PaginaFinalizacaoState extends State<_PaginaFinalizacao> {
  final List<String> alinhamentos = const [
    'Leal e Bom',
    'Neutro e Bom',
    'Caótico e Bom',
    'Leal e Neutro',
    'Neutro',
    'Caótico e Neutro',
    'Leal e Mau',
    'Neutro e Mau',
    'Caótico e Mau',
  ];

  bool _salvando = false;

  Future<void> _escolherFoto(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      if (context.mounted) {
        context.read<PersonagemCubit>().atualizarFoto(pickedFile.path);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<PersonagemCubit>();
    final p = cubit.state.personagem;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        // ==========================================
        // CARD 1: DADOS GERAIS, APARÊNCIA E HISTÓRIA
        // ==========================================
        Card(
          color: Colors.white,
          elevation: 1.5,
          shadowColor: Colors.black.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho do Card 1
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.person_pin_rounded,
                        color: Color(0xFFB71C1C),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Identidade do Herói",
                            style: TextStyle(
                              color: Color(0xFF111827),
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Defina nome, retrato e características essenciais",
                            style: TextStyle(
                              color: Color(0xFF4B5563),
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Seletor de Avatar / Foto
                Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: const Color(0xFFF3F4F6),
                              backgroundImage: (p.caminhoFoto != null &&
                                      p.caminhoFoto!.isNotEmpty &&
                                      File(p.caminhoFoto!).existsSync())
                                  ? FileImage(File(p.caminhoFoto!))
                                  : null,
                              child: (p.caminhoFoto == null ||
                                      p.caminhoFoto!.isEmpty ||
                                      !File(p.caminhoFoto!).existsSync())
                                  ? const Icon(
                                      Icons.person_outline_rounded,
                                      size: 52,
                                      color: Color(0xFF9CA3AF),
                                    )
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => _escolherFoto(context),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFB71C1C),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (p.caminhoFoto != null &&
                          p.caminhoFoto!.isNotEmpty &&
                          File(p.caminhoFoto!).existsSync())
                        TextButton.icon(
                          onPressed: () => cubit.removerFoto(),
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 16,
                            color: Color(0xFFDC2626),
                          ),
                          label: const Text(
                            "Remover foto",
                            style: TextStyle(
                              color: Color(0xFFDC2626),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            "Toque no ícone da câmera para adicionar uma foto",
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Campo Nome do Herói
                TextFormField(
                  initialValue: p.nome == 'Novo Aventureiro' ? '' : p.nome,
                  style: const TextStyle(
                    color: Color(0xFF1F2937),
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Nome do Herói',
                    labelStyle: const TextStyle(color: Color(0xFF4B5563)),
                    hintText: 'Ex: Sir Valen, Katabrok, Lisandra...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    prefixIcon: const Icon(
                      Icons.badge_outlined,
                      color: Color(0xFF6B7280),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFB71C1C),
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (val) => cubit.atualizarNome(
                    val.trim().isEmpty ? 'Novo Aventureiro' : val,
                  ),
                ),
                const SizedBox(height: 14),

                // Linha com Idade e Alinhamento
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Idade
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        initialValue: p.idade.toString(),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          color: Color(0xFF1F2937),
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Idade',
                          labelStyle:
                              const TextStyle(color: Color(0xFF4B5563)),
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                          prefixIcon: const Icon(
                            Icons.cake_outlined,
                            color: Color(0xFF6B7280),
                            size: 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFFD1D5DB)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFFD1D5DB)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFB71C1C),
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: (val) =>
                            cubit.atualizarIdade(int.tryParse(val) ?? 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Alinhamento / Tendência
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        initialValue: p.alinhamento,
                        style: const TextStyle(
                          color: Color(0xFF1F2937),
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        dropdownColor: Colors.white,
                        decoration: InputDecoration(
                          labelText: 'Alinhamento',
                          labelStyle:
                              const TextStyle(color: Color(0xFF4B5563)),
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                          prefixIcon: const Icon(
                            Icons.balance_outlined,
                            color: Color(0xFF6B7280),
                            size: 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFFD1D5DB)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFFD1D5DB)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFB71C1C),
                              width: 2,
                            ),
                          ),
                        ),
                        items: alinhamentos.map((alin) {
                          return DropdownMenuItem(
                            value: alin,
                            child: Text(alin),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) cubit.atualizarAlinhamento(val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Descrição Física e Personalidade
                TextFormField(
                  maxLines: 3,
                  initialValue: p.descricaoAparencia,
                  style: const TextStyle(
                    color: Color(0xFF1F2937),
                    height: 1.35,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Descrição Física e Personalidade',
                    labelStyle: const TextStyle(color: Color(0xFF4B5563)),
                    hintText:
                        'Descreva a aparência, cicatrizes, trejeitos ou histórico marcante...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFB71C1C),
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (val) => cubit.atualizarDescricao(val),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ==========================================
        // CARD 2: ESTATÍSTICAS DE COMBATE
        // ==========================================
        Card(
          color: Colors.white,
          elevation: 1.5,
          shadowColor: Colors.black.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho do Card 2
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.shield_rounded,
                        color: Color(0xFFB71C1C),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Estatísticas de Combate",
                            style: TextStyle(
                              color: Color(0xFF111827),
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Valores calculados com base na sua classe e atributos",
                            style: TextStyle(
                              color: Color(0xFF4B5563),
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Grid 2x2 de Estatísticas
                Row(
                  children: [
                    // PV Total
                    Expanded(
                      child: _buildCombatStatItem(
                        icon: Icons.favorite_rounded,
                        label: "Pontos de Vida",
                        sigla: "PV TOTAL",
                        valor: "${p.pvTotal}",
                        detalhe: "Inicial + CON",
                        fundoCor: const Color(0xFFFEF2F2),
                        bordaCor: const Color(0xFFFECACA),
                        iconeCor: const Color(0xFFDC2626),
                        textoCor: const Color(0xFF991B1B),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // PM Total
                    Expanded(
                      child: _buildCombatStatItem(
                        icon: Icons.auto_awesome_rounded,
                        label: "Pontos de Mana",
                        sigla: "PM TOTAL",
                        valor: "${p.pmTotal}",
                        detalhe: "Inicial + Atributo",
                        fundoCor: const Color(0xFFEFF6FF),
                        bordaCor: const Color(0xFFBFDBFE),
                        iconeCor: const Color(0xFF2563EB),
                        textoCor: const Color(0xFF1D4ED8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Defesa Base
                    Expanded(
                      child: _buildCombatStatItem(
                        icon: Icons.security_rounded,
                        label: "Defesa Base",
                        sigla: "DEFESA",
                        valor: "${p.defesaBase}",
                        detalhe: "10 + Destreza",
                        fundoCor: const Color(0xFFF0FDF4),
                        bordaCor: const Color(0xFFBBF7D0),
                        iconeCor: const Color(0xFF16A34A),
                        textoCor: const Color(0xFF15803D),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Tamanho / Porte
                    Expanded(
                      child: _buildCombatStatItem(
                        icon: Icons.accessibility_new_rounded,
                        label: "Porte Corporal",
                        sigla: "TAMANHO",
                        valor: p.tamanho,
                        detalhe: p.raca?.nome ?? "Padrão",
                        fundoCor: const Color(0xFFFAF5FF),
                        bordaCor: const Color(0xFFE9D5FF),
                        iconeCor: const Color(0xFF9333EA),
                        textoCor: const Color(0xFF7E22CE),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // ==========================================
        // BOTÃO CTA: CONCLUIR E SALVAR FICHA
        // ==========================================
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB71C1C), // Vermelho T20 Carmesim
              foregroundColor: Colors.white,
              elevation: 2.5,
              shadowColor: const Color(0xFFB71C1C).withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: _salvando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 24,
                    color: Colors.white,
                  ),
            label: Text(
              _salvando ? "SALVANDO FICHA..." : "CONCLUIR E SALVAR FICHA",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            onPressed: _salvando
                ? null
                : () async {
                    setState(() => _salvando = true);
                    try {
                      // Salva localmente no disco do celular
                      await cubit.salvarPersonagemNoAparelho();

                      if (context.mounted) {
                        // Atualiza a lista da tela inicial
                        context.read<HomeCubit>().carregarPersonagensReais();

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF1F2937),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            content: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF4ADE80),
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Personagem "${p.nome}" salvo com sucesso!',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );

                        // Limpa o wizard e fecha
                        cubit.resetarCriacao();
                        Navigator.pop(context);
                      }
                    } finally {
                      if (mounted) setState(() => _salvando = false);
                    }
                  },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCombatStatItem({
    required IconData icon,
    required String label,
    required String sigla,
    required String valor,
    required String detalhe,
    required Color fundoCor,
    required Color bordaCor,
    required Color iconeCor,
    required Color textoCor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: fundoCor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bordaCor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconeCor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  sigla,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: textoCor,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            valor,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textoCor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            detalhe,
            style: TextStyle(
              fontSize: 11,
              color: textoCor.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
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
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
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
              const Text(
                "Valores Disponíveis:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: state.valoresRolados
                    .map(
                      (val) => Chip(
                        label: Text(
                          val >= 0 ? "+$val" : "$val",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: Colors.white,
                        elevation: 1,
                      ),
                    )
                    .toList(),
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
                  title: Text(
                    entry.key,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(entry.value.nome),

                  // Feedback Visual (Cinza = Vazio, Azul = Preenchido)
                  leading: CircleAvatar(
                    backgroundColor: indiceAlocadoParaMim != null
                        ? Colors.indigo
                        : Colors.grey[300],
                    child: Text(
                      entry.value.valor >= 0
                          ? "+${entry.value.valor}"
                          : "${entry.value.valor}",
                      style: TextStyle(
                        color: indiceAlocadoParaMim != null
                            ? Colors.white
                            : Colors.black38,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // O Dropdown com Travamento
                  trailing: DropdownButton<int>(
                    hint: const Text("Escolher"),
                    value: indiceAlocadoParaMim,
                    underline: Container(),

                    items: state.valoresRolados
                        .asMap()
                        .entries
                        .map((mapEntry) {
                          int index = mapEntry.key;
                          int valor = mapEntry.value;

                          // Lógica de Bloqueio:
                          // Livre se ninguem usa, OU se quem usa sou eu mesmo
                          bool estaLivre = !state.alocacaoIndices.containsValue(
                            index,
                          );
                          bool ehMeu =
                              state.alocacaoIndices[entry.key] == index;

                          if (!estaLivre && !ehMeu) {
                            return null; // Oculta da lista
                          }

                          return DropdownMenuItem<int>(
                            value: index,
                            child: Text(
                              valor >= 0 ? "+$valor" : "$valor",
                              style: TextStyle(
                                fontWeight: ehMeu
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: valor >= 2
                                    ? Colors.green[700]
                                    : Colors.black,
                              ),
                            ),
                          );
                        })
                        .where((item) => item != null)
                        .cast<DropdownMenuItem<int>>()
                        .toList(),

                    onChanged: (indexSelecionado) {
                      if (indexSelecionado != null) {
                        context.read<PersonagemCubit>().alocarDado(
                          entry.key,
                          indexSelecionado,
                        );
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
