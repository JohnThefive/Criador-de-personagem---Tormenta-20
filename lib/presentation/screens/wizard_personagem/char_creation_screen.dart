import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../controllers/ficha_controller/personagem_cubit.dart';
import 'widgets/pagina_atributos.dart';
import 'widgets/pagina_divindades.dart';
import 'widgets/pagina_finalizacao.dart';
import 'widgets/pagina_origens.dart';
import 'widgets/pagina_pericias.dart';
import 'widgets/pagina_racas.dart';
import 'widgets/pagina_selecao_classe.dart';
import 'widgets/pagina_selecao_equipamento.dart';
import 'widgets/pagina_selecao_magias.dart';
import 'widgets/wizard_dialogs.dart';

/// Tela coordenadora do Wizard de Criação de Personagem.
///
/// Gerencia a navegação unidirecional em etapas sequenciais (0 a 8) usando
/// [PageView] e [PageController], sincronizado com o [PersonagemCubit].
class CharacterCreatorScreen extends StatefulWidget {
  const CharacterCreatorScreen({super.key});

  @override
  State<CharacterCreatorScreen> createState() => _CharacterCreatorScreenState();
}

class _CharacterCreatorScreenState extends State<CharacterCreatorScreen> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    final etapaInicial = context.read<PersonagemCubit>().state.etapaAtual;
    _pageController = PageController(initialPage: etapaInicial);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PersonagemCubit, PersonagemState>(
      listenWhen: (previous, current) =>
          current.etapaAtual > previous.etapaAtual,
      listener: (context, state) {
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            state.etapaAtual,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          mostrarDialogoDesistencia(context);
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFF4F6F8),
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child:
                BlocSelector<
                  PersonagemCubit,
                  PersonagemState,
                  ({
                    int etapaAtual,
                    MetodoAtributos metodoAtributos,
                    bool podeAvancar,
                  })
                >(
                  selector: (state) => (
                    etapaAtual: state.etapaAtual,
                    metodoAtributos: state.metodoAtributos,
                    podeAvancar: _deveMostrarBotaoAvancar(state),
                  ),
                  builder: (context, dados) {
                    return AppBar(
                      backgroundColor: Colors.white,
                      elevation: 1,
                      shadowColor: Colors.black.withValues(alpha: 0.08),
                      iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
                      title: Text(
                        _getTituloEtapa(dados.etapaAtual),
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      leading: IconButton(
                        icon: Icon(
                          dados.etapaAtual >= 1
                              ? Icons.close
                              : Icons.arrow_back,
                        ),
                        tooltip: dados.etapaAtual >= 1
                            ? 'Cancelar criação'
                            : 'Voltar',
                        onPressed: () {
                          if (dados.etapaAtual >= 1) {
                            mostrarDialogoDesistencia(context);
                          } else {
                            if (dados.metodoAtributos !=
                                MetodoAtributos.nenhum) {
                              context
                                  .read<PersonagemCubit>()
                                  .escolherMetodoAtributos(
                                    MetodoAtributos.nenhum,
                                  );
                            } else {
                              mostrarDialogoDesistencia(context);
                            }
                          }
                        },
                      ),
                      actions: [
                        if (dados.podeAvancar)
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: TextButton(
                              onPressed: () => mostrarDialogoConfirmarAvanco(
                                context,
                                etapaAtual: dados.etapaAtual,
                                nomeEtapa: _getTituloEtapa(dados.etapaAtual),
                              ),
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
                    );
                  },
                ),
          ),
          body: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              BlocBuilder<PersonagemCubit, PersonagemState>(
                buildWhen: (prev, curr) =>
                    prev.metodoAtributos != curr.metodoAtributos ||
                    prev.pontosRestantesCompra != curr.pontosRestantesCompra ||
                    prev.alocacaoIndices != curr.alocacaoIndices ||
                    prev.valoresRolados != curr.valoresRolados ||
                    prev.personagem.atributos != curr.personagem.atributos,
                builder: (context, state) => PaginaAtributos(state: state),
              ),
              BlocBuilder<PersonagemCubit, PersonagemState>(
                buildWhen: (prev, curr) =>
                    prev.personagem.raca != curr.personagem.raca ||
                    prev.atributosVariaveisRaca !=
                        curr.atributosVariaveisRaca ||
                    prev.personagem.atributos != curr.personagem.atributos,
                builder: (context, state) => PaginaSelecaoRaca(state: state),
              ),
              BlocBuilder<PersonagemCubit, PersonagemState>(
                buildWhen: (prev, curr) =>
                    prev.personagem.classes != curr.personagem.classes,
                builder: (context, state) => PaginaSelecaoClasse(state: state),
              ),
              BlocBuilder<PersonagemCubit, PersonagemState>(
                buildWhen: (prev, curr) =>
                    prev.selecoesPericiaClasse != curr.selecoesPericiaClasse ||
                    prev.selecoesPericiaInteligencia !=
                        curr.selecoesPericiaInteligencia ||
                    prev.personagem.classes != curr.personagem.classes ||
                    prev.personagem.atributos != curr.personagem.atributos,
                builder: (context, state) =>
                    PaginaSelecaoPericias(state: state),
              ),
              BlocBuilder<PersonagemCubit, PersonagemState>(
                buildWhen: (prev, curr) =>
                    prev.origemSelecionada != curr.origemSelecionada ||
                    prev.periciasEscolhidasOrigem !=
                        curr.periciasEscolhidasOrigem ||
                    prev.poderesEscolhidosOrigem !=
                        curr.poderesEscolhidosOrigem ||
                    prev.personagem.classes != curr.personagem.classes,
                builder: (context, state) => PaginaSelecaoOrigem(state: state),
              ),
              BlocBuilder<PersonagemCubit, PersonagemState>(
                buildWhen: (prev, curr) =>
                    prev.divindadeSelecionada != curr.divindadeSelecionada ||
                    prev.poderesConcedidosSelecionados !=
                        curr.poderesConcedidosSelecionados ||
                    prev.canalizacaoSelecionada !=
                        curr.canalizacaoSelecionada ||
                    prev.modoEstritoDevocao != curr.modoEstritoDevocao,
                builder: (context, state) =>
                    PaginaSelecaoDivindade(state: state),
              ),
              BlocBuilder<PersonagemCubit, PersonagemState>(
                buildWhen: (prev, curr) =>
                    prev.armaSimplesInicial != curr.armaSimplesInicial ||
                    prev.armaMarcialInicial != curr.armaMarcialInicial ||
                    prev.armaduraInicial != curr.armaduraInicial ||
                    prev.escudoInicial != curr.escudoInicial ||
                    prev.tibaresIniciais != curr.tibaresIniciais ||
                    prev.personagem.armas != curr.personagem.armas ||
                    prev.personagem.itensInventario !=
                        curr.personagem.itensInventario,
                builder: (context, state) =>
                    PaginaSelecaoEquipamento(state: state),
              ),
              BlocBuilder<PersonagemCubit, PersonagemState>(
                buildWhen: (prev, curr) =>
                    prev.magiasSelecionadas != curr.magiasSelecionadas ||
                    prev.personagem.classes != curr.personagem.classes,
                builder: (context, state) => PaginaSelecaoMagias(state: state),
              ),
              const PaginaFinalizacao(),
            ],
          ),
        ),
      ),
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
        return "Equipamento Inicial";
      case 7:
        return "Escolher Magias";
      case 8:
        return "Finalização";
      default:
        return "Criação de Personagem";
    }
  }

  bool _deveMostrarBotaoAvancar(PersonagemState state) {
    // 1. LÓGICA DA ETAPA 0 (ATRIBUTOS)
    if (state.etapaAtual == 0) {
      if (state.metodoAtributos == MetodoAtributos.compra) {
        return state.pontosRestantesCompra == 0;
      }
      if (state.metodoAtributos == MetodoAtributos.rolagem) {
        return state.alocacaoIndices.length == 6;
      }
      return false;
    }

    // 2. LÓGICA DA ETAPA 1 (RAÇA)
    if (state.etapaAtual == 1) {
      return state.personagem.raca != null;
    }

    // 3. LÓGICA DA ETAPA 2 (CLASSE)
    if (state.etapaAtual == 2) {
      if (state.personagem.classes.isEmpty) {
        return false;
      }

      final classeSelecionada = state.personagem.classes[0];
      if (classeSelecionada.classeDefinicao.caminhosNivel1.isNotEmpty) {
        if (classeSelecionada.caminhoEscolhido == null) return false;

        if (classeSelecionada.caminhoEscolhido!.nome == "Feiticeiro") {
          if (classeSelecionada.linhagemEscolhida == null) return false;
        }
      }
      return true;
    }

    // 4. LÓGICA DA ETAPA 3 (PERÍCIAS)
    if (state.etapaAtual == 3) {
      if (state.personagem.classes.isEmpty) return false;

      final classeDef = state.personagem.classes[0].classeDefinicao;
      bool completouClasse =
          state.selecoesPericiaClasse.length == classeDef.qtdPericiasEscolha;

      final modInt = state.personagem.getValorFinal('INT');
      final limiteInteligencia = modInt > 0 ? modInt : 0;
      bool completouInt =
          state.selecoesPericiaInteligencia.length == limiteInteligencia;

      return completouClasse && completouInt;
    }

    // 5. LÓGICA DA ETAPA 4 (ORIGEM)
    if (state.etapaAtual == 4) {
      return state.concluiuOrigem;
    }

    // 6. LÓGICA DA ETAPA 5 (DIVINDADE)
    if (state.etapaAtual == 5) {
      return state.etapaDivindadeConcluida;
    }

    // 7. LÓGICA DA ETAPA 6 (EQUIPAMENTO INICIAL)
    if (state.etapaAtual == 6) {
      return state.concluiuEquipamentoInicial;
    }

    // 8. LÓGICA DA ETAPA 7 (MAGIAS INICIAIS)
    if (state.etapaAtual == 7) {
      return state.concluiuMagias;
    }

    // Na última etapa (Finalização), não exibe botão "Próximo"
    if (state.etapaAtual >= 8) {
      return false;
    }

    return true;
  }
}
