import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/personagem.dart';

// Estado da Home
class HomeState {
  final List<Personagem> personagens;
  
  // ignore: prefer_typing_uninitialized_variables, strict_top_level_inference
  var personagem;
  HomeState(this.personagem, {required this.personagens});
}

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeState([], personagens: [])) {
    _carregarDadosIniciais();
  }

  void _carregarDadosIniciais() {
    // MOCK: Fingindo que buscamos do banco de dados para popular a tela
    final listaFicticia = [
      Personagem.inicial().copyWith(nome: "Satoru Gojo (T20 Version)"), // Precisa ajustar seu copyWith para aceitar nome
      Personagem.inicial().copyWith(nome: "Machado de Assis"),
    ];
    emit(HomeState(listaFicticia, personagens: []));
  }

  void adicionarPersonagem(Personagem p) {
    final novaLista = List<Personagem>.from(state.personagens)..add(p);
    emit(HomeState(novaLista, personagens: []));
  }
}