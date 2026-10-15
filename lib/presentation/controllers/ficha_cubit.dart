import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/personagem/classe_do_personagem.dart';
import '../../domain/entities/personagem/personagem.dart';
import '../../domain/repositories/i_personagem_repository.dart';
import '../../domain/services/personagem_storage_service.dart';
import 'ficha_state.dart';

class FichaCubit extends Cubit<FichaState> {
  final IPersonagemRepository _repository;

  FichaCubit({
    required Personagem personagemInicial,
    IPersonagemRepository? repository,
  })  : _repository = repository ?? const PersonagemStorageService(),
        super(FichaState(personagem: personagemInicial));

  Personagem get personagem => state.personagem;

  void limparMensagens() {
    emit(state.copyWith(anularErro: true, anularSucesso: true));
  }

  /// Atualiza o personagem no estado e persiste no repositório
  Future<void> atualizarPersonagem(Personagem novo, {bool salvar = true}) async {
    emit(state.copyWith(personagem: novo, anularErro: true, anularSucesso: true));
    if (salvar) {
      await _persistir(novo);
    }
  }

  Future<void> _persistir(Personagem p) async {
    try {
      await _repository.salvar(p);
    } catch (e) {
      emit(state.copyWith(mensagemErro: 'Erro ao salvar alterações: $e'));
    }
  }

  /// Altera o nível do personagem (+1 ou -1) dentro do limite de 1 a 20
  Future<bool> alterarNivel(int delta) async {
    if (state.personagem.classes.isEmpty) return false;
    final cl = state.personagem.classes[0];
    final novoNivel = cl.nivel + delta;

    if (novoNivel < 1 || novoNivel > 20) return false;

    final novasClasses = List<ClasseDoPersonagem>.from(state.personagem.classes)
      ..[0] = cl.copyWith(nivel: novoNivel);

    var atualizado = state.personagem.copyWith(classe_do_personagem: novasClasses);
    if (atualizado.pvAtual > atualizado.pvTotal) {
      atualizado = atualizado.copyWith(pvAtual: atualizado.pvTotal);
    }
    if (atualizado.pmAtual > atualizado.pmTotal) {
      atualizado = atualizado.copyWith(pmAtual: atualizado.pmTotal);
    }

    await atualizarPersonagem(atualizado);
    return true;
  }

  /// Aplica dano aos Pontos de Vida (PV)
  Future<void> aplicarDano(int dano) async {
    if (dano <= 0) return;
    final atualizado = state.personagem.aplicarDano(dano);
    await atualizarPersonagem(atualizado);
  }

  /// Cura Pontos de Vida (PV)
  Future<void> curarPV(int cura) async {
    if (cura <= 0) return;
    final atualizado = state.personagem.curarPV(cura);
    await atualizarPersonagem(atualizado);
  }

  /// Consome Pontos de Mana (PM)
  Future<void> gastarPM(int gasto) async {
    if (gasto <= 0) return;
    final atualizado = state.personagem.gastarPM(gasto);
    await atualizarPersonagem(atualizado);
  }

  /// Recupera Pontos de Mana (PM), respeitando regras de Punição Divina
  Future<bool> recuperarPM(int recuperado) async {
    if (recuperado <= 0) return false;
    if (state.personagem.punicaoDivinaAtiva) {
      emit(state.copyWith(
        mensagemErro:
            'O personagem está sob Punição Divina e não pode recuperar Pontos de Mana!',
      ));
      return false;
    }
    final atualizado = state.personagem.recuperarPM(recuperado);
    await atualizarPersonagem(atualizado);
    return true;
  }

  /// Aplica punição divina (Zera PM e desativa recuperação)
  Future<void> aplicarPunicaoDivina() async {
    final atualizado = state.personagem.aplicarPunicaoDivina();
    await atualizarPersonagem(atualizado);
  }

  /// Revoga punição divina após penitência
  Future<void> removerPunicaoDivina() async {
    final atualizado = state.personagem.removerPunicaoDivina();
    await atualizarPersonagem(atualizado);
  }

  /// Adiciona Pontos de Experiência (XP)
  Future<void> adicionarXP(int valor) async {
    if (valor <= 0) return;
    final atualizado = state.personagem.adicionarXP(valor);
    await atualizarPersonagem(atualizado);
  }

  /// Realiza descanso normal (recupera Nível + CON em PV e Nível em PM)
  Future<void> descansoNormal() async {
    final con = state.personagem.getValorFinal('CON');
    final nivel =
        state.personagem.nivelPersonagem > 0 ? state.personagem.nivelPersonagem : 1;
    final curaNormalPV = max(1, nivel + con);
    final curaNormalPM = max(1, nivel);

    var atualizado = state.personagem.curarPV(curaNormalPV);
    if (!state.personagem.punicaoDivinaAtiva) {
      atualizado = atualizado.recuperarPM(curaNormalPM);
    }
    await atualizarPersonagem(atualizado);
  }

  /// Realiza descanso confortável (o dobro do descanso normal)
  Future<void> descansoConfortavel() async {
    final con = state.personagem.getValorFinal('CON');
    final nivel =
        state.personagem.nivelPersonagem > 0 ? state.personagem.nivelPersonagem : 1;
    final curaNormalPV = max(1, nivel + con) * 2;
    final curaNormalPM = max(1, nivel) * 2;

    var atualizado = state.personagem.curarPV(curaNormalPV);
    if (!state.personagem.punicaoDivinaAtiva) {
      atualizado = atualizado.recuperarPM(curaNormalPM);
    }
    await atualizarPersonagem(atualizado);
  }

  /// Realiza descanso completo (restaura 100% dos recursos)
  Future<void> descansoCompleto() async {
    var atualizado = state.personagem.restaurarRecursos();
    if (state.personagem.punicaoDivinaAtiva) {
      atualizado = atualizado.copyWith(pmAtual: 0);
    }
    await atualizarPersonagem(atualizado);
  }

  /// Atualiza o caminho da imagem de foto do herói
  Future<void> atualizarFoto(String caminho) async {
    final atualizado = state.personagem.copyWith(caminhoFoto: caminho);
    await atualizarPersonagem(atualizado);
  }

  /// Remove o retrato do herói
  Future<void> removerFoto() async {
    final atualizado = state.personagem.copyWith(anularFoto: true);
    await atualizarPersonagem(atualizado);
  }
}
