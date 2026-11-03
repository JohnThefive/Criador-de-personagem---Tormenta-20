import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/personagem/personagem.dart';
import '../../../domain/repositories/i_personagem_repository.dart';
import '../../../domain/services/data_services/catalogo_service.dart';
import '../../../domain/services/ficha_services/personagem_storage_service.dart';
import '../../../helpers/debug_mock_character.dart';

// Estado da Home (apenas o necessário)
class HomeState {
  final List<Personagem> personagens;
  final bool carregando;

  const HomeState({required this.personagens, this.carregando = false});

  HomeState copyWith({List<Personagem>? personagens, bool? carregando}) {
    return HomeState(
      personagens: personagens ?? this.personagens,
      carregando: carregando ?? this.carregando,
    );
  }
}

// Cubit da Home com injeção de IPersonagemRepository e Future de catálogos
class HomeCubit extends Cubit<HomeState> {
  final IPersonagemRepository _repository;
  final Future<void>? _catalogosFuture;
  final bool _autoSeedDebug;

  HomeCubit({
    IPersonagemRepository? repository,
    Future<void>? catalogosFuture,
    bool? autoSeedDebug,
  }) : _repository = repository ?? const PersonagemStorageService(),
       _catalogosFuture = catalogosFuture ?? CatalogoService.future,
       _autoSeedDebug = autoSeedDebug ?? (kDebugMode && repository == null),
       super(const HomeState(personagens: [], carregando: true)) {
    carregarPersonagensReais();
  }

  Future<void> carregarPersonagensReais() async {
    emit(state.copyWith(carregando: true));
    try {
      if (_catalogosFuture != null) {
        await _catalogosFuture;
      }
      var fichas = await _repository.obterTodos();

      if (_autoSeedDebug && fichas.isEmpty) {
        final mockHero = DebugMockCharacter.criarPersonagemTeste();
        await _repository.salvar(mockHero);
        fichas = await _repository.obterTodos();
      }

      emit(state.copyWith(personagens: fichas, carregando: false));
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('Erro ao carregar personagens no HomeCubit: $e\n$stack');
      }
      emit(state.copyWith(personagens: [], carregando: false));
    }
  }

  void adicionarPersonagem(Personagem p) {
    final novaLista = List<Personagem>.from(state.personagens)..add(p);
    emit(state.copyWith(personagens: novaLista));
  }

  void removerPersonagem(String id) {
    final novaLista = state.personagens.where((p) => p.id != id).toList();
    emit(state.copyWith(personagens: novaLista));
  }

  Future<void> excluirPersonagem(String id) async {
    try {
      await _repository.excluir(id);
      final novaLista = state.personagens.where((p) => p.id != id).toList();
      emit(state.copyWith(personagens: novaLista));
    } catch (e) {
      // Se houver erro, recarrega a lista para manter coerência
      await carregarPersonagensReais();
    }
  }
}
