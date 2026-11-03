import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/personagem/personagem.dart';
import '../../domain/entities/personagem/classe_do_personagem.dart';
import '../../domain/entities/personagem/poder.dart';
import '../../domain/services/data_services/call_poderes.dart';
import '../../domain/services/poderes_e_magias/poder_validador_service.dart';
import '../../domain/repositories/i_personagem_repository.dart';
import '../../domain/services/personagem_storage_service.dart';

enum FiltroPoderes { todos, disponiveis, adquiridos, bloqueados }

enum CategoriaEvolucaoPoder {
  classe,
  combate,
  destino,
  magia,
  tormenta;

  String get label => switch (this) {
    CategoriaEvolucaoPoder.classe => 'Poderes de Classe',
    CategoriaEvolucaoPoder.combate => 'Combate',
    CategoriaEvolucaoPoder.destino => 'Destino',
    CategoriaEvolucaoPoder.magia => 'Magia',
    CategoriaEvolucaoPoder.tormenta => 'Tormenta',
  };
}

class ItemPoderEvolucao {
  final Poder poder;
  final ResultadoElegibilidade elegibilidade;

  const ItemPoderEvolucao({required this.poder, required this.elegibilidade});

  bool get podeAprender => elegibilidade.ehElegivel;
  bool get jaAdquirido => elegibilidade.jaPossui;
  bool get bloqueado => !podeAprender && !jaAdquirido;
}

class EvolucaoState {
  final Personagem personagem;
  final int indiceClasse;
  final CategoriaEvolucaoPoder categoria;
  final FiltroPoderes filtro;
  final String busca;
  final List<ItemPoderEvolucao> todosItens;
  final bool salvando;
  final String? mensagemErro;
  final String? mensagemSucesso;

  const EvolucaoState({
    required this.personagem,
    this.indiceClasse = 0,
    this.categoria = CategoriaEvolucaoPoder.classe,
    this.filtro = FiltroPoderes.todos,
    this.busca = '',
    this.todosItens = const [],
    this.salvando = false,
    this.mensagemErro,
    this.mensagemSucesso,
  });

  ClasseDoPersonagem get classeAtual =>
      personagem.classes.isNotEmpty && indiceClasse < personagem.classes.length
      ? personagem.classes[indiceClasse]
      : ClasseDoPersonagem(
          classeDefinicao: personagem.classes.first.classeDefinicao,
          nivel: 1,
        );

  int get poderesPendentes => classeAtual.poderesPendentes;
  int get poderesPermitidos => classeAtual.poderesPermitidos;
  bool get temPoderPendente => classeAtual.temPoderPendente;

  List<ItemPoderEvolucao> get itensFiltrados {
    final query = busca.trim().toLowerCase();

    return todosItens.where((item) {
      // 1. Filtro por status
      switch (filtro) {
        case FiltroPoderes.disponiveis:
          if (!item.podeAprender) return false;
          break;
        case FiltroPoderes.adquiridos:
          if (!item.jaAdquirido) return false;
          break;
        case FiltroPoderes.bloqueados:
          if (!item.bloqueado) return false;
          break;
        case FiltroPoderes.todos:
          break;
      }

      // 2. Filtro de busca por texto
      if (query.isNotEmpty) {
        final matchNome = item.poder.nome.toLowerCase().contains(query);
        final matchDesc = item.poder.descricao.toLowerCase().contains(query);
        return matchNome || matchDesc;
      }

      return true;
    }).toList();
  }

  EvolucaoState copyWith({
    Personagem? personagem,
    int? indiceClasse,
    CategoriaEvolucaoPoder? categoria,
    FiltroPoderes? filtro,
    String? busca,
    List<ItemPoderEvolucao>? todosItens,
    bool? salvando,
    String? mensagemErro,
    bool anularErro = false,
    String? mensagemSucesso,
    bool anularSucesso = false,
  }) {
    return EvolucaoState(
      personagem: personagem ?? this.personagem,
      indiceClasse: indiceClasse ?? this.indiceClasse,
      categoria: categoria ?? this.categoria,
      filtro: filtro ?? this.filtro,
      busca: busca ?? this.busca,
      todosItens: todosItens ?? this.todosItens,
      salvando: salvando ?? this.salvando,
      mensagemErro: anularErro ? null : (mensagemErro ?? this.mensagemErro),
      mensagemSucesso: anularSucesso
          ? null
          : (mensagemSucesso ?? this.mensagemSucesso),
    );
  }
}

class EvolucaoCubit extends Cubit<EvolucaoState> {
  final IPersonagemRepository _repository;

  EvolucaoCubit({
    required Personagem personagem,
    int indiceClasse = 0,
    CategoriaEvolucaoPoder categoriaInicial = CategoriaEvolucaoPoder.classe,
    IPersonagemRepository? repository,
  }) : _repository = repository ?? const PersonagemStorageService(),
       super(
         EvolucaoState(
           personagem: personagem,
           indiceClasse: indiceClasse,
           categoria: categoriaInicial,
         ),
       ) {
    _recalcularItens();
  }

  void atualizarBusca(String novaBusca) {
    emit(state.copyWith(busca: novaBusca));
  }

  void alterarFiltro(FiltroPoderes novoFiltro) {
    emit(state.copyWith(filtro: novoFiltro));
  }

  void alterarCategoria(CategoriaEvolucaoPoder novaCategoria) {
    if (state.categoria == novaCategoria) return;
    emit(state.copyWith(categoria: novaCategoria));
    _recalcularItens();
  }

  void selecionarClasse(int indice) {
    if (indice >= 0 && indice < state.personagem.classes.length) {
      emit(state.copyWith(indiceClasse: indice));
      _recalcularItens();
    }
  }

  void limparMensagens() {
    emit(state.copyWith(anularErro: true, anularSucesso: true));
  }

  /// Recalcula os poderes da categoria selecionada com suas respectivas regras de elegibilidade
  void _recalcularItens([Personagem? personagemAtualizado]) {
    final p = personagemAtualizado ?? state.personagem;
    if (p.classes.isEmpty || state.indiceClasse >= p.classes.length) {
      emit(state.copyWith(personagem: p, todosItens: []));
      return;
    }

    final classeAtual = p.classes[state.indiceClasse];
    final List<Poder> todosPoderes = switch (state.categoria) {
      CategoriaEvolucaoPoder.classe => BancoDePoderes.poderesDaClasse(
        classeAtual.classeDefinicao.idClasse,
      ),
      CategoriaEvolucaoPoder.combate => BancoDePoderesGerais.poderesCombate,
      CategoriaEvolucaoPoder.destino => BancoDePoderesGerais.poderesDestino,
      CategoriaEvolucaoPoder.magia => BancoDePoderesGerais.poderesMagia,
      CategoriaEvolucaoPoder.tormenta => BancoDePoderesGerais.poderesTormenta,
    };

    final listaItens = todosPoderes.map((poder) {
      final resultado = PoderValidadorService.validar(
        personagem: p,
        classeDoPersonagem: classeAtual,
        poder: poder,
      );
      return ItemPoderEvolucao(poder: poder, elegibilidade: resultado);
    }).toList();

    // Ordenação amigável:
    // 1º Já adquiridos
    // 2º Elegíveis (disponíveis para escolher)
    // 3º Bloqueados
    listaItens.sort((a, b) {
      if (a.jaAdquirido && !b.jaAdquirido) return -1;
      if (!a.jaAdquirido && b.jaAdquirido) return 1;
      if (a.podeAprender && !b.podeAprender) return -1;
      if (!a.podeAprender && b.podeAprender) return 1;
      return a.poder.nome.compareTo(b.poder.nome);
    });

    emit(state.copyWith(personagem: p, todosItens: listaItens));
  }

  /// Aprende o poder selecionado
  Future<void> aprenderPoder(Poder poder, {String? tipoCompanheiro}) async {
    final classe = state.classeAtual;

    if (!classe.temPoderPendente) {
      emit(
        state.copyWith(
          mensagemErro:
              'Você já escolheu todos os poderes disponíveis para o nível atual (${classe.nivel}). Aumente o nível para poder escolher mais.',
          anularSucesso: true,
        ),
      );
      return;
    }

    final validacao = PoderValidadorService.validar(
      personagem: state.personagem,
      classeDoPersonagem: classe,
      poder: poder,
    );

    if (validacao.jaPossui) {
      emit(
        state.copyWith(
          mensagemErro: 'Você já possui o poder ${poder.nome}.',
          anularSucesso: true,
        ),
      );
      return;
    }

    if (!validacao.ehElegivel) {
      final pendenciasTexto = validacao.pendencias
          .map((req) => req.descricao)
          .join(', ');
      emit(
        state.copyWith(
          mensagemErro:
              'Pré-requisitos não atendidos para ${poder.nome}: $pendenciasTexto',
          anularSucesso: true,
        ),
      );
      return;
    }

    emit(state.copyWith(salvando: true, anularErro: true, anularSucesso: true));

    try {
      final novaClasse = classe.adicionarPoder(poder);
      final novasClasses = List<ClasseDoPersonagem>.from(
        state.personagem.classes,
      );
      novasClasses[state.indiceClasse] = novaClasse;

      final novoPersonagem = state.personagem.copyWith(
        classe_do_personagem: novasClasses,
        tipoCompanheiroAnimal:
            tipoCompanheiro ?? state.personagem.tipoCompanheiroAnimal,
      );

      // Salva no repositório
      await _repository.salvar(novoPersonagem);

      emit(
        state.copyWith(
          salvando: false,
          mensagemSucesso: 'Poder "${poder.nome}" aprendido com sucesso!',
        ),
      );

      _recalcularItens(novoPersonagem);
    } catch (e) {
      emit(
        state.copyWith(
          salvando: false,
          mensagemErro: 'Erro ao salvar poder: $e',
        ),
      );
    }
  }

  /// Remove um poder previamente adquirido
  Future<void> removerPoder(String poderKey) async {
    final classe = state.classeAtual;
    final poder = classe.poderesEscolhidos.firstWhere(
      (p) => p.key == poderKey,
      orElse: () => Poder(key: '', nome: '', descricao: ''),
    );

    if (poder.key.isEmpty) return;

    emit(state.copyWith(salvando: true, anularErro: true, anularSucesso: true));

    try {
      final novaClasse = classe.removerPoder(poderKey);
      final novasClasses = List<ClasseDoPersonagem>.from(
        state.personagem.classes,
      );
      novasClasses[state.indiceClasse] = novaClasse;

      final novoPersonagem = state.personagem.copyWith(
        classe_do_personagem: novasClasses,
        anularCompanheiro: poderKey == 'COMPANHEIRO_ANIMAL',
        anularFormaSelvagem: poderKey == 'FORMA_SELVAGEM',
      );

      await _repository.salvar(novoPersonagem);

      emit(
        state.copyWith(
          salvando: false,
          mensagemSucesso: 'Poder "${poder.nome}" removido.',
        ),
      );

      _recalcularItens(novoPersonagem);
    } catch (e) {
      emit(
        state.copyWith(
          salvando: false,
          mensagemErro: 'Erro ao remover poder: $e',
        ),
      );
    }
  }
}
