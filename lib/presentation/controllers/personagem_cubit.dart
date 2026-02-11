import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/personagem.dart';
import '../../domain/services/regras_atributos.dart';
import '../../domain/entities/raca.dart';

// Enum para saber qual método o usuário escolheu nesta etapa
enum MetodoAtributos { nenhum, compra, rolagem }

// Estado expandido
class PersonagemState {
  final Personagem personagem;
  final int etapaAtual; // 0: Atributos, 1: Raça, 2: Classe...
  final MetodoAtributos metodoAtributos; // Controla a UI da etapa 0

  
  // Mantemos os dados específicos de rolagem aqui também
  final List<int> valoresRolados;
  final Map<String, int> alocacaoIndices;
  final int pontosRestantesCompra;
  final List<String> atributosVariaveisRaca; // atributos escolhidos em raças complexas 

  PersonagemState({
    required this.personagem,
    this.etapaAtual = 0,
    this.metodoAtributos = MetodoAtributos.nenhum,
    this.valoresRolados = const [],
    this.alocacaoIndices = const {},
    this.pontosRestantesCompra = 10,
    this.atributosVariaveisRaca = const [],
  });

  // CopyWith para facilitar atualizações
  PersonagemState copyWith({
    Personagem? personagem,
    int? etapaAtual,
    MetodoAtributos? metodoAtributos,
    List<int>? valoresRolados,
    Map<String, int>? alocacaoIndices,
    int? pontosRestantesCompra,
    List<String>? atributosVariaveisRaca,
  }) {
    return PersonagemState(
      personagem: personagem ?? this.personagem,
      etapaAtual: etapaAtual ?? this.etapaAtual,
      metodoAtributos: metodoAtributos ?? this.metodoAtributos,
      valoresRolados: valoresRolados ?? this.valoresRolados,
      alocacaoIndices: alocacaoIndices ?? this.alocacaoIndices,
      pontosRestantesCompra: pontosRestantesCompra ?? this.pontosRestantesCompra,
      atributosVariaveisRaca: atributosVariaveisRaca ?? this.atributosVariaveisRaca,
    );
  }
}

class PersonagemCubit extends Cubit<PersonagemState> {
  PersonagemCubit() : super(PersonagemState(personagem: Personagem.inicial()));

  // --- CONTROLE DE FLUXO (WIZARD) ---

  //  reset de criação de personagem
  void resetarCriacao() {
  emit(
    PersonagemState(
      personagem: Personagem.inicial()
      )); // Zera tudo para o estado original
}

  void escolherMetodoAtributos(MetodoAtributos metodo) {
    // Ao escolher, resetamos os valores para garantir limpeza
    emit(state.copyWith(
      metodoAtributos: metodo,
      personagem: Personagem.inicial(), // Reseta atributos para 0
      pontosRestantesCompra: 10,
      valoresRolados: [],
      alocacaoIndices: {},
    ));
  }

  void avancarEtapa() {
    // Aqui você pode colocar validações (ex: só avança se gastou todos os pontos)
    emit(state.copyWith(etapaAtual: state.etapaAtual + 1));
  }

  void voltarEtapa() {
    // Cenário 0 : Estou na Raça (1) e volto para Atributos (0)
    if (state.etapaAtual == 1) {
      emit(state.copyWith(
        etapaAtual: 0,
        // HARD RESET: O usuário pediu para perder o progresso ao voltar
        personagem: Personagem.inicial(), 
        pontosRestantesCompra: 10,
        valoresRolados: [],      // Limpa os dados rolados
        alocacaoIndices: {},     // Limpa as alocações
        metodoAtributos: MetodoAtributos.nenhum, // Volta para a escolha dos botões grandes
      ));
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
    
    emit(state.copyWith(
      personagem: novoPersonagem,
      pontosRestantesCompra: state.pontosRestantesCompra - diferenca,
    ));
  }

  void rolarDados() {
    final valores = RegrasAtributos.gerarKitRolagem();
    valores.sort((a, b) => b.compareTo(a));
    
    emit(state.copyWith(
      valoresRolados: valores,
      personagem: Personagem.inicial(), // Reseta ficha
      alocacaoIndices: {}, // Reseta alocação
    ));
  }

  void alocarDado(String atributoKey, int indexDoDado) {
    final valorReal = state.valoresRolados[indexDoDado];
    final novaAlocacao = Map<String, int>.from(state.alocacaoIndices);
    
    // Remove quem estava usando esse índice antes
    novaAlocacao.removeWhere((key, value) => value == indexDoDado);
    novaAlocacao[atributoKey] = indexDoDado;

    emit(state.copyWith(
      personagem: _atualizarPersonagem(atributoKey, valorReal),
      alocacaoIndices: novaAlocacao,
    ));
  }
  

  // metodo para auxiliar o map de atributos 
  Personagem _atualizarPersonagem(String chave, int valor) {
    final novosAtributos = Map<String, dynamic>.from(state.personagem.atributos);

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
  emit(state.copyWith(
    personagem: novoPersonagem,
    atributosVariaveisRaca: [],
    ));
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
    if (listaAtual.contains(sigla)){
      listaAtual.remove(sigla);
    } else{
      if (listaAtual.length <= 3){
        listaAtual.add(sigla);
      }
    }

    emit(state.copyWith(atributosVariaveisRaca: listaAtual));
    
    }
}