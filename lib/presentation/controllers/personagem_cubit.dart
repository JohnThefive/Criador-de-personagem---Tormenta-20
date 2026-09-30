import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:t20_creator/domain/entities/classe.dart';
import 'package:t20_creator/domain/entities/classe_do_personagem.dart';
import 'package:t20_creator/domain/entities/linhagem_arcanista.dart';
import 'package:t20_creator/domain/entities/arma.dart';
import 'package:t20_creator/domain/services/regras_carga_service.dart';
import 'package:t20_creator/domain/services/personagem_storage_service.dart';
import '../../domain/entities/personagem.dart';
import '../../domain/services/regras_atributos.dart';
import '../../domain/entities/raca.dart';
import '../../domain/entities/origem.dart';
import '../../domain/entities/poder.dart';
import '../../domain/entities/divindade.dart';

// Enum para saber qual método o usuário escolheu nesta etapa
enum MetodoAtributos { nenhum, compra, rolagem }

// Estado expandido
class PersonagemState {
  final Personagem personagem;
  final int etapaAtual; // 0: Atributos, 1: Raça, 2: Classe...
  final MetodoAtributos metodoAtributos; // Controla a UI da etapa 0

  // metodos relacionados a origem
  final Origem? origemSelecionada;
  final List<String> periciasEscolhidasOrigem; // Siglas de perícia selecionadas
  final List<Poder> poderesEscolhidosOrigem; // Poderes selecionados

  // metodos relacionados a divindade
  final Divindade? divindadeSelecionada;
  final Poder? poderConcedidoSelecionado;

  // Mantemos os dados específicos de rolagem aqui também
  final List<int> valoresRolados;
  final Map<String, int> alocacaoIndices;
  final int pontosRestantesCompra;
  final List<String>
  atributosVariaveisRaca; // atributos escolhidos em raças complexas

  // Atributos de pericias
  final List<String> selecoesPericiaClasse; // As escolhas restritas (2)
  final List<String>
  selecoesPericiaInteligencia; // As escolhas livres (Mod. INT)

  // Equipamento inicial (Nível 1)
  final Arma? armaSimplesInicial;
  final Arma? armaMarcialInicial;
  final int? tibaresIniciais;

  PersonagemState({
    required this.personagem,
    this.etapaAtual = 0,
    this.metodoAtributos = MetodoAtributos.nenhum,
    this.origemSelecionada,
    this.periciasEscolhidasOrigem = const [],
    this.poderesEscolhidosOrigem = const [],
    this.divindadeSelecionada,
    this.poderConcedidoSelecionado,
    this.valoresRolados = const [],
    this.alocacaoIndices = const {},
    this.pontosRestantesCompra = 10,
    this.atributosVariaveisRaca = const [],
    this.selecoesPericiaClasse = const [],
    this.selecoesPericiaInteligencia = const [],
    this.armaSimplesInicial,
    this.armaMarcialInicial,
    this.tibaresIniciais,
  });

  int get totalBeneficiosOrigem =>
      periciasEscolhidasOrigem.length + poderesEscolhidosOrigem.length;

  bool get concluiuOrigem =>
      origemSelecionada != null && totalBeneficiosOrigem == 2;

  bool get etapaDivindadeConcluida {
    if (personagem.exigeDevocao) {
      return divindadeSelecionada != null && poderConcedidoSelecionado != null;
    }
    if (divindadeSelecionada == null) return true;
    return poderConcedidoSelecionado != null;
  }

  // Getters para Equipamento Inicial e Carga
  OpcoesArmasIniciais get opcoesArmasIniciais =>
      RegrasCargaService.obterArmasIniciaisDisponiveis(personagem);

  StatusCarga get statusCarga {
    final armasAtuais = <Arma>[...personagem.armas];
    if (armaSimplesInicial != null &&
        !armasAtuais.any((a) => a.key == armaSimplesInicial!.key)) {
      armasAtuais.add(armaSimplesInicial!);
    }
    if (armaMarcialInicial != null &&
        !armasAtuais.any((a) => a.key == armaMarcialInicial!.key)) {
      armasAtuais.add(armaMarcialInicial!);
    }

    final itensAtuais = List<String>.from(personagem.itensInventario);
    const kitPadrao = ['Mochila', 'Saco de Dormir', 'Traje de Viajante'];
    for (final item in kitPadrao) {
      if (!itensAtuais.contains(item)) {
        itensAtuais.add(item);
      }
    }

    final modForca = personagem.getValorFinal('FOR');
    final limite = RegrasCargaService.calcularLimiteCarga(modForca);
    final atual = RegrasCargaService.calcularEspacosOcupados(
      armas: armasAtuais,
      itensInventario: itensAtuais,
    );

    return StatusCarga(
      cargaAtual: atual,
      limiteCarga: limite,
      sobrecarregado: atual > limite,
      espacosRestantes: limite - atual,
    );
  }

  bool get concluiuEquipamentoInicial {
    if (armaSimplesInicial == null) return false;
    if (personagem.temProficienciaMarcial && armaMarcialInicial == null) {
      return false;
    }
    return true;
  }

  // CopyWith para facilitar atualizações
  PersonagemState copyWith({
    Personagem? personagem,
    int? etapaAtual,
    MetodoAtributos? metodoAtributos,
    Origem? origemSelecionada,
    List<String>? periciasEscolhidasOrigem,
    List<Poder>? poderesEscolhidosOrigem,
    Divindade? divindadeSelecionada,
    Poder? poderConcedidoSelecionado,
    bool anularDivindade = false,
    List<int>? valoresRolados,
    Map<String, int>? alocacaoIndices,
    int? pontosRestantesCompra,
    List<String>? atributosVariaveisRaca,
    List<String>? selecoesPericiaClasse,
    List<String>? selecoesPericiaInteligencia,
    Arma? armaSimplesInicial,
    bool anularArmaSimples = false,
    Arma? armaMarcialInicial,
    bool anularArmaMarcial = false,
    int? tibaresIniciais,
  }) {
    return PersonagemState(
      personagem: personagem ?? this.personagem,
      etapaAtual: etapaAtual ?? this.etapaAtual,
      metodoAtributos: metodoAtributos ?? this.metodoAtributos,
      origemSelecionada: origemSelecionada ?? this.origemSelecionada,
      periciasEscolhidasOrigem:
          periciasEscolhidasOrigem ?? this.periciasEscolhidasOrigem,
      poderesEscolhidosOrigem:
          poderesEscolhidosOrigem ?? this.poderesEscolhidosOrigem,
      divindadeSelecionada: anularDivindade
          ? null
          : (divindadeSelecionada ?? this.divindadeSelecionada),
      poderConcedidoSelecionado: anularDivindade
          ? null
          : (poderConcedidoSelecionado ?? this.poderConcedidoSelecionado),
      valoresRolados: valoresRolados ?? this.valoresRolados,
      alocacaoIndices: alocacaoIndices ?? this.alocacaoIndices,
      pontosRestantesCompra:
          pontosRestantesCompra ?? this.pontosRestantesCompra,
      atributosVariaveisRaca:
          atributosVariaveisRaca ?? this.atributosVariaveisRaca,
      selecoesPericiaClasse:
          selecoesPericiaClasse ?? this.selecoesPericiaClasse,
      selecoesPericiaInteligencia:
          selecoesPericiaInteligencia ?? this.selecoesPericiaInteligencia,
      armaSimplesInicial: anularArmaSimples
          ? null
          : (armaSimplesInicial ?? this.armaSimplesInicial),
      armaMarcialInicial: anularArmaMarcial
          ? null
          : (armaMarcialInicial ?? this.armaMarcialInicial),
      tibaresIniciais: tibaresIniciais ?? this.tibaresIniciais,
    );
  }
}

class PersonagemCubit extends Cubit<PersonagemState> {
  PersonagemCubit() : super(PersonagemState(personagem: Personagem.inicial()));

  // --- CONTROLE DE FLUXO (WIZARD) ---

  //  reset de criação de personagem
  void resetarCriacao() {
    emit(
      PersonagemState(personagem: Personagem.inicial()),
    ); // Zera tudo para o estado original
  }

  void escolherMetodoAtributos(MetodoAtributos metodo) {
    // Ao escolher, resetamos os valores para garantir limpeza
    emit(
      state.copyWith(
        metodoAtributos: metodo,
        personagem: Personagem.inicial(), // Reseta atributos para 0
        pontosRestantesCompra: 10,
        valoresRolados: [],
        alocacaoIndices: {},
      ),
    );
  }

  void avancarEtapa() {
    if (state.etapaAtual == 3) {
      consolidarPericias();
    } else if (state.etapaAtual == 4) {
      consolidarOrigem();
    } else if (state.etapaAtual == 5) {
      consolidarDivindade();
    } else if (state.etapaAtual == 6) {
      consolidarEquipamentoInicial();
    }
    emit(state.copyWith(etapaAtual: state.etapaAtual + 1));
  }

  void voltarEtapa() {
    // Cenário 0 : Estou na Raça (1) e volto para Atributos (0)
    if (state.etapaAtual == 1) {
      emit(
        state.copyWith(
          etapaAtual: 0,
          // HARD RESET: O usuário pediu para perder o progresso ao voltar
          personagem: Personagem.inicial(),
          pontosRestantesCompra: 10,
          valoresRolados: [], // Limpa os dados rolados
          alocacaoIndices: {}, // Limpa as alocações
          metodoAtributos:
              MetodoAtributos.nenhum, // Volta para a escolha dos botões grandes
        ),
      );
    }
    // situação generica
    else if (state.etapaAtual > 1) {
      emit(state.copyWith(etapaAtual: state.etapaAtual - 1));
    }
    // sitação 1: Estou nos Atributos (0) e quero sair da seleção de método
    else if (state.metodoAtributos != MetodoAtributos.nenhum) {
      escolherMetodoAtributos(MetodoAtributos.nenhum);
    }
  }

  // --- LÓGICA DE ATRIBUTOS (Atualizada para o novo State) ---

  void alterarAtributoCompra(String chave, int delta) {
    final atualValor = state.personagem.atributos[chave]!.valor;
    final novoValor = atualValor + delta;

    if (!RegrasAtributos.valorEhValidoParaCompra(novoValor)) return;

    final custoAtual = RegrasAtributos.custoPontos[atualValor]!;
    final custoNovo = RegrasAtributos.custoPontos[novoValor]!;
    final diferenca = custoNovo - custoAtual;

    if (state.pontosRestantesCompra - diferenca < 0) return;

    final novoPersonagem = _atualizarPersonagem(chave, novoValor);

    emit(
      state.copyWith(
        personagem: novoPersonagem,
        pontosRestantesCompra: state.pontosRestantesCompra - diferenca,
      ),
    );
  }

  void rolarDados() {
    final valores = RegrasAtributos.gerarKitRolagem();
    valores.sort((a, b) => b.compareTo(a));

    emit(
      state.copyWith(
        valoresRolados: valores,
        personagem: Personagem.inicial(), // Reseta ficha
        alocacaoIndices: {}, // Reseta alocação
      ),
    );
  }

  void alocarDado(String atributoKey, int indexDoDado) {
    final valorReal = state.valoresRolados[indexDoDado];
    final novaAlocacao = Map<String, int>.from(state.alocacaoIndices);

    // Remove quem estava usando esse índice antes
    novaAlocacao.removeWhere((key, value) => value == indexDoDado);
    novaAlocacao[atributoKey] = indexDoDado;

    emit(
      state.copyWith(
        personagem: _atualizarPersonagem(atributoKey, valorReal),
        alocacaoIndices: novaAlocacao,
      ),
    );
  }

  // metodo para auxiliar o map de atributos
  Personagem _atualizarPersonagem(String chave, int valor) {
    final novosAtributos = Map<String, dynamic>.from(
      state.personagem.atributos,
    );

    // muda o valor dentro do map
    if (novosAtributos.containsKey(chave)) {
      novosAtributos[chave] = novosAtributos[chave]!.copyWith(valor: valor);
    }
    // retorna o personagem atualizado
    return state.personagem.copyWith(atributos: novosAtributos.cast());
  }

  // logica de selecionar raca
  void selecionarRaca(Raca raca) {
    // Atualiza o personagem com a nova raça
    final novoPersonagem = state.personagem.copyWith(raca: raca);
    emit(
      state.copyWith(personagem: novoPersonagem, atributosVariaveisRaca: []),
    );
  }

  void toggleAtributoRacial(String sigla) {
    final raca = state.personagem.raca;
    if (raca == null || !raca.ehFlexivel) {
      return;
    }

    // Verifica a penalidade de raca
    if (raca.atributosBloqueados.contains(sigla)) {
      return;
    }

    final listaAtual = List<String>.from(state.atributosVariaveisRaca);

    // se já tem, remove. se não tem, adicione.
    if (listaAtual.contains(sigla)) {
      listaAtual.remove(sigla);
    } else {
      if (listaAtual.length <= 3) {
        listaAtual.add(sigla);
      }
    }

    emit(state.copyWith(atributosVariaveisRaca: listaAtual));
  }

  // Vamos começar a logica de seleção de classe

  void selecionarClasse(Classe classeDefinicao) {
    // Cria a instância da classe no Nível 1
    final novaClasse = ClasseDoPersonagem(
      classeDefinicao: classeDefinicao,
      nivel: 1,
    );

    // Como estamos na criação do personagem, esta será a classe principal (índice 0)
    final novoPersonagem = state.personagem.copyWith(
      classe_do_personagem: [novaClasse],
    );
    emit(state.copyWith(personagem: novoPersonagem));
  }

  // para classes com subclasses/caminhos
  void selecionarCaminhoDaClasse(CaminhoDeClasse caminho) {
    if (state.personagem.classes.isEmpty) return;

    // Pega a classe atual e atualiza com o caminho escolhido
    final classeAtual = state.personagem.classes[0];
    final classeAtualizada = classeAtual.copyWith(caminhoEscolhido: caminho);

    final novoPersonagem = state.personagem.copyWith(
      classe_do_personagem: [classeAtualizada],
    );
    emit(state.copyWith(personagem: novoPersonagem));
  }

  // Seleção de linhagem de feiticeiro - classe mais complexa
  void selecionarLinhagem(Linhagem linhagem) {
    if (state.personagem.classes.isEmpty) return;

    final classeAtual = state.personagem.classes[0];
    // Atualiza a classe com a linhagem escolhida
    final classeAtualizada = classeAtual.copyWith(linhagemEscolhida: linhagem);

    final novoPersonagem = state.personagem.copyWith(
      classe_do_personagem: [classeAtualizada],
    );
    emit(state.copyWith(personagem: novoPersonagem));
  }

  // estapas de pericias
  void togglePericiaClasse(String siglaPericia) {
    if (state.personagem.classes.isEmpty) return;

    final classe = state.personagem.classes[0].classeDefinicao;

    // 1. Bloqueia se a perícia já for fixa da classe
    if (classe.periciasFixas.contains(siglaPericia)) return;

    // 2. Bloqueia se já escolheu essa perícia na lista de Inteligência
    if (state.selecoesPericiaInteligencia.contains(siglaPericia)) return;

    final listaAtual = List<String>.from(state.selecoesPericiaClasse);

    // 3. Marca/Desmarca com limite
    if (listaAtual.contains(siglaPericia)) {
      listaAtual.remove(siglaPericia);
    } else {
      if (listaAtual.length < classe.qtdPericiasEscolha) {
        listaAtual.add(siglaPericia);
      }
    }

    emit(state.copyWith(selecoesPericiaClasse: listaAtual));
  }

  void togglePericiaInteligencia(String siglaPericia) {
    if (state.personagem.classes.isEmpty) return;

    final classe = state.personagem.classes[0].classeDefinicao;

    // 1. Bloqueia se a perícia já for fixa da classe
    if (classe.periciasFixas.contains(siglaPericia)) return;

    // 2. Bloqueia se já escolheu essa perícia na lista da Classe
    if (state.selecoesPericiaClasse.contains(siglaPericia)) return;

    // 3. Calcula o limite de INT (Mínimo de 0, caso o jogador tenha INT negativa)
    final modificadorInt = state.personagem.getValorFinal('INT');
    final limiteInteligencia = modificadorInt > 0 ? modificadorInt : 0;

    final listaAtual = List<String>.from(state.selecoesPericiaInteligencia);

    // 4. Marca/Desmarca com limite
    if (listaAtual.contains(siglaPericia)) {
      listaAtual.remove(siglaPericia);
    } else {
      if (listaAtual.length < limiteInteligencia) {
        listaAtual.add(siglaPericia);
      }
    }

    emit(state.copyWith(selecoesPericiaInteligencia: listaAtual));
  }

  // Quando o jogador clicar em "Próximo" na tela de perícias, chamamos isso
  // para injetar todas as escolhas dentro da ficha definitiva do personagem.
  void consolidarPericias() {
    if (state.personagem.classes.isEmpty) return;

    final classe = state.personagem.classes[0].classeDefinicao;

    // Junta tudo: Fixas + Escolhas da Classe + Escolhas de INT
    final todasPericias = <String>[
      ...classe.periciasFixas,
      ...state.selecoesPericiaClasse,
      ...state.selecoesPericiaInteligencia,
    ];

    final novoPersonagem = state.personagem.copyWith(
      periciasTreinadas: todasPericias,
    );
    emit(state.copyWith(personagem: novoPersonagem));
  }

  // --- MÉTODOS DE ORIGEM ---

  void selecionarOrigem(Origem origem) {
    emit(
      state.copyWith(
        origemSelecionada: origem,
        periciasEscolhidasOrigem: const [],
        poderesEscolhidosOrigem: const [],
      ),
    );
  }

  void togglePericiaOrigem(String siglaPericia) {
    final pericias = List<String>.from(state.periciasEscolhidasOrigem);
    if (pericias.contains(siglaPericia)) {
      pericias.remove(siglaPericia);
    } else {
      if (state.totalBeneficiosOrigem < 2) {
        pericias.add(siglaPericia);
      }
    }
    emit(state.copyWith(periciasEscolhidasOrigem: pericias));
  }

  void togglePoderOrigem(Poder poder) {
    final poderes = List<Poder>.from(state.poderesEscolhidosOrigem);
    final index = poderes.indexWhere((p) => p.key == poder.key);
    if (index >= 0) {
      poderes.removeAt(index);
    } else {
      if (state.totalBeneficiosOrigem < 2) {
        poderes.add(poder);
      }
    }
    emit(state.copyWith(poderesEscolhidosOrigem: poderes));
  }

  void consolidarOrigem() {
    if (!state.concluiuOrigem) return;

    final novaListaPericias = List<String>.from(
      state.personagem.periciasTreinadas,
    )..addAll(state.periciasEscolhidasOrigem);

    final novoPersonagem = state.personagem.copyWith(
      origem: state.origemSelecionada,
      periciasTreinadas: novaListaPericias.toSet().toList(),
      poderesGerais: state.poderesEscolhidosOrigem,
      itensInventario: state.origemSelecionada!.itensIniciais,
    );
    emit(state.copyWith(personagem: novoPersonagem));
  }

  // --- MÉTODOS DE DIVINDADE / DEVOÇÃO ---

  void selecionarDivindade(Divindade? divindade) {
    if (divindade == null) {
      // Optou por não ser devoto / desmarcou
      emit(state.copyWith(anularDivindade: true));
    } else {
      emit(
        state.copyWith(
          divindadeSelecionada: divindade,
          poderConcedidoSelecionado:
              null, // Reseta poder concedido ao trocar de divindade
        ),
      );
    }
  }

  void selecionarPoderConcedido(Poder poder) {
    emit(state.copyWith(poderConcedidoSelecionado: poder));
  }

  void consolidarDivindade() {
    if (!state.etapaDivindadeConcluida) return;

    if (state.divindadeSelecionada == null) {
      final novoPersonagem = state.personagem.copyWith(anularDivindade: true);
      emit(state.copyWith(personagem: novoPersonagem));
    } else {
      final novoPersonagem = state.personagem.copyWith(
        divindade: state.divindadeSelecionada,
        poderConcedido: state.poderConcedidoSelecionado,
      );
      emit(state.copyWith(personagem: novoPersonagem));
    }
  }

  // metodos de atualização e personalização de personagem
  // Atualizações da etapa de finalização
  void atualizarNome(String novoNome) {
    emit(state.copyWith(personagem: state.personagem.copyWith(nome: novoNome)));
  }

  void atualizarIdade(int novaIdade) {
    emit(
      state.copyWith(personagem: state.personagem.copyWith(idade: novaIdade)),
    );
  }

  void atualizarAlinhamento(String novoAlinhamento) {
    emit(
      state.copyWith(
        personagem: state.personagem.copyWith(alinhamento: novoAlinhamento),
      ),
    );
  }

  void atualizarDescricao(String novaDescricao) {
    emit(
      state.copyWith(
        personagem: state.personagem.copyWith(
          descricaoAparencia: novaDescricao,
        ),
      ),
    );
  }

  void atualizarPeso(String novoPeso) {
    emit(
      state.copyWith(
        personagem: state.personagem.copyWith(peso: novoPeso),
      ),
    );
  }

  void atualizarAltura(String novaAltura) {
    emit(
      state.copyWith(
        personagem: state.personagem.copyWith(altura: novaAltura),
      ),
    );
  }

  void atualizarFoto(String caminhoFoto) {
    emit(
      state.copyWith(
        personagem: state.personagem.copyWith(caminhoFoto: caminhoFoto),
      ),
    );
  }

  void removerFoto() {
    emit(
      state.copyWith(
        personagem: state.personagem.copyWith(anularFoto: true),
      ),
    );
  }

  // --- MÉTODOS DE EQUIPAMENTO INICIAL E CARGA (TORMENTA 20) ---

  /// Filtra quais armas são elegíveis como escolha gratuita no Nível 1
  List<Arma> obterArmasIniciaisDisponiveis(Personagem p) {
    final opcoes = RegrasCargaService.obterArmasIniciaisDisponiveis(p);
    final List<Arma> lista = [...opcoes.armasSimples];
    if (opcoes.podeEscolherMarcial) {
      lista.addAll(opcoes.armasMarciais);
    }
    return lista;
  }

  /// Verifica se o personagem está sobrecarregado com base na Força e carga
  bool verificarSobrecarga(Personagem p) {
    return p.estaSobrecarregado;
  }

  void selecionarArmaSimplesInicial(Arma arma) {
    emit(state.copyWith(armaSimplesInicial: arma));
  }

  void selecionarArmaMarcialInicial(Arma arma) {
    emit(state.copyWith(armaMarcialInicial: arma));
  }

  void removerArmaInicial({required bool ehMarcial}) {
    if (ehMarcial) {
      emit(state.copyWith(anularArmaMarcial: true));
    } else {
      emit(state.copyWith(anularArmaSimples: true));
    }
  }

  int rolarDinheiroInicial() {
    final rand = Random();
    int total = 0;
    for (int i = 0; i < 4; i++) {
      total += rand.nextInt(6) + 1;
    }
    emit(state.copyWith(tibaresIniciais: total));
    return total;
  }

  void consolidarEquipamentoInicial() {
    final armasIniciais = <Arma>[];
    if (state.armaSimplesInicial != null) {
      armasIniciais.add(state.armaSimplesInicial!);
    }
    if (state.armaMarcialInicial != null) {
      armasIniciais.add(state.armaMarcialInicial!);
    }

    // Kit de Aventureiro Inicial padrão de T20:
    // Uma mochila, um saco de dormir e um traje de viajante.
    final itensBase = List<String>.from(state.personagem.itensInventario);
    const kitPadrao = ['Mochila', 'Saco de Dormir', 'Traje de Viajante'];
    for (final item in kitPadrao) {
      if (!itensBase.contains(item)) {
        itensBase.add(item);
      }
    }

    // Se ainda não rolou tibares (4d6), rola agora
    final tibares = state.tibaresIniciais ?? rolarDinheiroInicial();

    final novoPersonagem = state.personagem.copyWith(
      armas: armasIniciais,
      itensInventario: itensBase,
      tibares: tibares,
    );

    emit(state.copyWith(personagem: novoPersonagem));
  }

  // MÉTODO PARA SALVAR A FICHA NO DISCO DO ANDROID
  Future<void> salvarPersonagemNoAparelho() async {
    await PersonagemStorageService.salvarPersonagem(state.personagem);
  }

  @visibleForTesting
  void emitirEstadoParaTeste(PersonagemState novoEstado) {
    emit(novoEstado);
  }
}
