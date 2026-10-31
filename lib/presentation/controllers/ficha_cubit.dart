import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/equipamento/arma.dart';
import '../../domain/entities/equipamento/item_vestido.dart';
import '../../domain/entities/equipamento/protecao.dart';
import '../../domain/entities/personagem/classe_do_personagem.dart';
import '../../domain/entities/personagem/efeito_temporario.dart';
import '../../domain/entities/personagem/personagem.dart';
import '../../domain/repositories/i_personagem_repository.dart';
import '../../domain/services/calculo_ficha_service.dart';
import '../../domain/services/personagem_storage_service.dart';
import 'ficha_state.dart';

class FichaCubit extends Cubit<FichaState> {
  final IPersonagemRepository _repository;
  final Duration _debounceDuration;
  Timer? _debounceTimer;
  Personagem? _personagemPendentePersistir;
  Completer<void>? _salvarCompleter;

  FichaCubit({
    required Personagem personagemInicial,
    IPersonagemRepository? repository,
    Duration debounceDuration = const Duration(milliseconds: 250),
  }) : _repository = repository ?? const PersonagemStorageService(),
       _debounceDuration = debounceDuration,
       super(FichaState(personagem: personagemInicial));

  Personagem get personagem => state.personagem;

  /// Atualiza o personagem no estado e persiste automaticamente no repositório (com debounce)
  Future<void> atualizarPersonagem(
    Personagem novo, {
    bool salvar = true,
    String? mensagemSucesso,
  }) async {
    emit(
      state.copyWith(
        personagem: novo,
        anularErro: true,
        anularSucesso: mensagemSucesso == null,
        mensagemSucesso: mensagemSucesso,
      ),
    );
    if (salvar) {
      await _persistir(novo);
    }
  }

  Future<void> _persistir(Personagem p) async {
    _personagemPendentePersistir = p;

    if (_debounceDuration == Duration.zero) {
      await _executarPersistenciaImediata();
      return;
    }

    _debounceTimer?.cancel();
    _salvarCompleter ??= Completer<void>();
    _debounceTimer = Timer(_debounceDuration, () {
      _executarPersistenciaImediata();
    });
  }

  Future<void> _executarPersistenciaImediata() async {
    final p = _personagemPendentePersistir;
    _personagemPendentePersistir = null;
    _debounceTimer?.cancel();
    _debounceTimer = null;

    final completer = _salvarCompleter;
    _salvarCompleter = null;

    if (p == null) {
      completer?.complete();
      return;
    }

    try {
      await _repository.salvar(p);
      completer?.complete();
    } catch (e) {
      emit(state.copyWith(mensagemErro: 'Erro ao salvar alterações: $e'));
      completer?.completeError(e);
    }
  }

  /// Força a gravação imediata no repositório caso haja alguma alteração pendente de debounce
  Future<void> flush() async {
    if (_personagemPendentePersistir != null) {
      await _executarPersistenciaImediata();
    }
  }

  @override
  Future<void> close() async {
    await flush();
    return super.close();
  }

  /// Altera o nível do personagem (+1 ou -1) dentro do limite de 1 a 20
  Future<bool> alterarNivel(int delta) async {
    if (state.personagem.classes.isEmpty) return false;
    final cl = state.personagem.classes[0];
    final novoNivel = cl.nivel + delta;

    if (novoNivel < 1 || novoNivel > 20) return false;

    final novasClasses = List<ClasseDoPersonagem>.from(state.personagem.classes)
      ..[0] = cl.copyWith(nivel: novoNivel);

    var atualizado = state.personagem.copyWith(
      classe_do_personagem: novasClasses,
    );
    if (atualizado.pvAtual > atualizado.pvTotal) {
      atualizado = atualizado.copyWith(pvAtual: atualizado.pvTotal);
    }
    if (atualizado.pmAtual > atualizado.pmTotal) {
      atualizado = atualizado.copyWith(pmAtual: atualizado.pmTotal);
    }

    await atualizarPersonagem(atualizado);
    return true;
  }

  // --- PONTOS DE VIDA E MANA ---

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

  /// Consome Pontos de Mana (PM) diretamente (com trava contra valores negativos no domínio)
  Future<void> gastarPM(int gasto) async {
    if (gasto <= 0) return;
    final atualizado = state.personagem.gastarPM(gasto);
    await atualizarPersonagem(atualizado);
  }

  /// Valida e consome PM para ativar poder ou lançar magia, impedindo PM negativo
  Future<bool> tentarAtivarComPM(int custoPM, {String? nomeAcao}) async {
    final resultado = CalculoFichaService.tentarGastarPM(
      state.personagem,
      custoPM,
    );
    if (!resultado.sucesso) {
      emit(
        state.copyWith(
          mensagemErro: resultado.mensagemErro ?? 'PM insuficiente.',
          anularSucesso: true,
        ),
      );
      return false;
    }

    final feedback = nomeAcao != null
        ? (custoPM == 0
              ? '$nomeAcao lançado como Truque (0 PM)!'
              : '$nomeAcao ativado (-$custoPM PM)')
        : null;
    await atualizarPersonagem(
      resultado.personagemAtualizado,
      mensagemSucesso: feedback,
    );
    return true;
  }

  /// Recupera Pontos de Mana (PM), respeitando regras de Punição Divina
  Future<bool> recuperarPM(int recuperado) async {
    if (recuperado <= 0) return false;
    if (state.personagem.punicaoDivinaAtiva) {
      emit(
        state.copyWith(
          mensagemErro:
              'O personagem está sob Punição Divina e não pode recuperar Pontos de Mana!',
        ),
      );
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

  // --- DESCANSOS ---

  /// Realiza descanso normal (recupera Nível + CON em PV e Nível em PM)
  Future<void> descansoNormal() async {
    var atualizado = state.personagem
        .curarPV(state.personagem.curaDescansoNormalPV);
    if (!state.personagem.punicaoDivinaAtiva) {
      atualizado = atualizado
          .recuperarPM(state.personagem.curaDescansoNormalPM);
    }
    await atualizarPersonagem(atualizado);
  }

  /// Realiza descanso confortável (o dobro do descanso normal)
  Future<void> descansoConfortavel() async {
    var atualizado = state.personagem
        .curarPV(state.personagem.curaDescansoNormalPV * 2);
    if (!state.personagem.punicaoDivinaAtiva) {
      atualizado = atualizado
          .recuperarPM(state.personagem.curaDescansoNormalPM * 2);
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

  // --- PERÍCIAS (TREINO E BÔNUS "OUTROS") ---

  /// Alterna o treinamento manual em uma perícia (mantendo perícias fixas de classe protegidas)
  Future<bool> alternarTreinoPericia(String periciaKey) async {
    if (state.personagem.ehPericiaTreinadaFixaDeClasse(periciaKey)) {
      emit(
        state.copyWith(
          mensagemErro:
              'Esta perícia é concedida pela sua classe e permanece treinada.',
          anularSucesso: true,
        ),
      );
      return false;
    }

    final upper = periciaKey.toUpperCase();
    final atual = List<String>.from(state.personagem.periciasTreinadas);
    final idx = atual.indexWhere((k) => k.toUpperCase() == upper);
    if (idx >= 0) {
      atual.removeAt(idx);
    } else {
      atual.add(periciaKey);
    }

    await atualizarPersonagem(
      state.personagem.copyWith(periciasTreinadas: atual),
    );
    return true;
  }

  /// Define o valor exato do campo "Outros" (bônus diversos) de uma perícia
  Future<void> definirOutrosBonusPericia(String periciaKey, int valor) async {
    final mapa = Map<String, int>.from(state.personagem.outrosBonusPericias);
    final chaveExistente = mapa.keys.firstWhere(
      (k) => k.toUpperCase() == periciaKey.toUpperCase(),
      orElse: () => periciaKey,
    );

    if (valor == 0) {
      mapa.remove(chaveExistente);
    } else {
      mapa[chaveExistente] = valor.clamp(-50, 99);
    }

    await atualizarPersonagem(
      state.personagem.copyWith(outrosBonusPericias: mapa),
    );
  }

  // --- EFEITOS TEMPORÁRIOS (BUFFS, DEBUFFS, CONDIÇÕES E NOTAS) ---

  Future<void> adicionarEfeitoTemporario(EfeitoTemporario efeito) async {
    final lista = List<EfeitoTemporario>.from(
      state.personagem.efeitosTemporarios,
    );
    final idx = lista.indexWhere((e) => e.id == efeito.id);
    if (idx >= 0) {
      lista[idx] = efeito;
    } else {
      lista.add(efeito);
    }
    await atualizarPersonagem(
      state.personagem.copyWith(efeitosTemporarios: lista),
    );
  }

  Future<void> atualizarEfeitoTemporario(EfeitoTemporario efeito) async {
    final lista = state.personagem.efeitosTemporarios
        .map((e) => e.id == efeito.id ? efeito : e)
        .toList();
    await atualizarPersonagem(
      state.personagem.copyWith(efeitosTemporarios: lista),
    );
  }

  Future<void> alternarAtivacaoEfeitoTemporario(String efeitoId) async {
    final lista = state.personagem.efeitosTemporarios
        .map((e) => e.id == efeitoId ? e.copyWith(ativo: !e.ativo) : e)
        .toList();
    await atualizarPersonagem(
      state.personagem.copyWith(efeitosTemporarios: lista),
    );
  }

  Future<void> removerEfeitoTemporario(String efeitoId) async {
    final lista = state.personagem.efeitosTemporarios
        .where((e) => e.id != efeitoId)
        .toList();
    await atualizarPersonagem(
      state.personagem.copyWith(efeitosTemporarios: lista),
    );
  }

  Future<void> limparEfeitosTemporarios() async {
    await atualizarPersonagem(
      state.personagem.copyWith(efeitosTemporarios: const []),
    );
  }

  // --- DEFESA, RD PADRÃO, RDs DIVERSAS E PROFICIÊNCIAS EXTRAS ---

  Future<void> definirOutrosBonusDefesa(int valor) async {
    await atualizarPersonagem(
      state.personagem.copyWith(outrosBonusDefesa: valor.clamp(-50, 99)),
    );
  }

  Future<void> definirRdPadrao(int valor) async {
    await atualizarPersonagem(
      state.personagem.copyWith(rdPadrao: valor.clamp(0, 99)),
    );
  }

  Future<void> ajustarRdPadrao(int delta) async {
    await definirRdPadrao(state.personagem.rdPadrao + delta);
  }

  Future<void> adicionarRdDiversa(String descricao) async {
    final texto = descricao.trim();
    if (texto.isEmpty) return;
    final lista = [...state.personagem.rdsDiversas, texto];
    await atualizarPersonagem(state.personagem.copyWith(rdsDiversas: lista));
  }

  Future<void> removerRdDiversa(int index) async {
    final lista = List<String>.from(state.personagem.rdsDiversas);
    if (index < 0 || index >= lista.length) return;
    lista.removeAt(index);
    await atualizarPersonagem(state.personagem.copyWith(rdsDiversas: lista));
  }

  Future<void> adicionarProficienciaExtra(String descricao) async {
    final texto = descricao.trim();
    if (texto.isEmpty) return;
    final lista = [...state.personagem.proficienciasExtras, texto];
    await atualizarPersonagem(
      state.personagem.copyWith(proficienciasExtras: lista),
    );
  }

  Future<void> removerProficienciaExtra(int index) async {
    final lista = List<String>.from(state.personagem.proficienciasExtras);
    if (index < 0 || index >= lista.length) return;
    lista.removeAt(index);
    await atualizarPersonagem(
      state.personagem.copyWith(proficienciasExtras: lista),
    );
  }

  // --- MAGIAS E CD DE RESISTÊNCIA ---

  Future<void> definirOutrosBonusCDMagia(int valor) async {
    await atualizarPersonagem(
      state.personagem.copyWith(outrosBonusCDMagia: valor.clamp(-50, 99)),
    );
  }

  Future<void> adicionarMagiaConhecida(String magiaId) async {
    if (state.personagem.magiasConhecidas.contains(magiaId)) return;
    final lista = [...state.personagem.magiasConhecidas, magiaId];
    await atualizarPersonagem(
      state.personagem.copyWith(magiasConhecidas: lista),
    );
  }

  Future<void> removerMagiaConhecida(String magiaId) async {
    final lista = state.personagem.magiasConhecidas
        .where((id) => id != magiaId)
        .toList();
    await atualizarPersonagem(
      state.personagem.copyWith(magiasConhecidas: lista),
    );
  }

  // --- INVENTÁRIO, SLOTS DE ITENS VESTIDOS E TIBARES ---

  /// Slot 1 de item vestido (Armadura)
  Future<void> equiparArmadura(Protecao? armadura) async {
    final atualizado = armadura == null
        ? state.personagem.copyWith(anularArmadura: true)
        : state.personagem.copyWith(armaduraEquipada: armadura);
    await atualizarPersonagem(atualizado);
  }

  /// Escudo empunhado
  Future<void> equiparEscudo(Protecao? escudo) async {
    final atualizado = escudo == null
        ? state.personagem.copyWith(anularEscudo: true)
        : state.personagem.copyWith(escudoEquipado: escudo);
    await atualizarPersonagem(atualizado);
  }

  /// Slots 2, 3 e 4 de itens vestidos (`slotIndex` de 1 a 3)
  Future<void> salvarItemVestidoExtra(ItemVestido item) async {
    if (item.nome.trim().isEmpty) {
      await removerItemVestidoExtra(item.slotIndex);
      return;
    }
    final lista = List<ItemVestido>.from(state.personagem.itensVestidosExtras);
    final idx = lista.indexWhere((i) => i.slotIndex == item.slotIndex);
    if (idx >= 0) {
      lista[idx] = item;
    } else {
      lista.add(item);
    }
    lista.sort((a, b) => a.slotIndex.compareTo(b.slotIndex));
    await atualizarPersonagem(
      state.personagem.copyWith(itensVestidosExtras: lista),
    );
  }

  Future<void> removerItemVestidoExtra(int slotIndex) async {
    final lista = state.personagem.itensVestidosExtras
        .where((i) => i.slotIndex != slotIndex)
        .toList();
    await atualizarPersonagem(
      state.personagem.copyWith(itensVestidosExtras: lista),
    );
  }

  Future<void> adicionarItemMochila(String item) async {
    final texto = item.trim();
    if (texto.isEmpty) return;
    final lista = [...state.personagem.itensInventario, texto];
    await atualizarPersonagem(
      state.personagem.copyWith(itensInventario: lista),
    );
  }

  Future<void> editarItemMochila(int index, String novoNome) async {
    final texto = novoNome.trim();
    final lista = List<String>.from(state.personagem.itensInventario);
    if (index < 0 || index >= lista.length) return;
    if (texto.isEmpty) {
      lista.removeAt(index);
    } else {
      lista[index] = texto;
    }
    await atualizarPersonagem(
      state.personagem.copyWith(itensInventario: lista),
    );
  }

  Future<void> removerItemMochila(int index) async {
    final lista = List<String>.from(state.personagem.itensInventario);
    if (index < 0 || index >= lista.length) return;
    lista.removeAt(index);
    await atualizarPersonagem(
      state.personagem.copyWith(itensInventario: lista),
    );
  }

  Future<void> adicionarArmaInventario(Arma arma) async {
    final lista = [...state.personagem.armas, arma];
    await atualizarPersonagem(state.personagem.copyWith(armas: lista));
  }

  Future<void> removerArmaInventario(int index) async {
    final lista = List<Arma>.from(state.personagem.armas);
    if (index < 0 || index >= lista.length) return;
    lista.removeAt(index);
    await atualizarPersonagem(state.personagem.copyWith(armas: lista));
  }

  Future<void> definirTibares({int? cobre, int? prata, int? ouro}) async {
    await atualizarPersonagem(
      state.personagem.copyWith(
        tibaresCobre: cobre != null ? max(0, cobre) : null,
        tibares: prata != null ? max(0, prata) : null,
        tibaresOuro: ouro != null ? max(0, ouro) : null,
      ),
    );
  }

  Future<void> ajustarTibares({
    int deltaCobre = 0,
    int deltaPrata = 0,
    int deltaOuro = 0,
  }) async {
    await definirTibares(
      cobre: state.personagem.tibaresCobre + deltaCobre,
      prata: state.personagem.tibares + deltaPrata,
      ouro: state.personagem.tibaresOuro + deltaOuro,
    );
  }

  // --- IDENTIDADE, ANOTAÇÕES E PROGRESSÃO ---

  Future<void> atualizarCabecalhoIdentidade({
    String? nome,
    int? idade,
    String? alinhamento,
  }) async {
    await atualizarPersonagem(
      state.personagem.copyWith(
        nome: nome?.trim().isNotEmpty == true ? nome!.trim() : null,
        idade: idade != null ? max(1, idade) : null,
        alinhamento: alinhamento?.trim().isNotEmpty == true
            ? alinhamento!.trim()
            : null,
      ),
    );
  }

  Future<void> atualizarAnotacoes(String texto) async {
    if (texto == state.personagem.anotacoes) return;
    await atualizarPersonagem(state.personagem.copyWith(anotacoes: texto));
  }

  Future<void> atualizarBiografiaFisica({
    String? descricaoAparencia,
    String? tamanho,
    String? peso,
    String? altura,
  }) async {
    await atualizarPersonagem(
      state.personagem.copyWith(
        descricaoAparencia: descricaoAparencia,
        tamanho: tamanho,
        peso: peso,
        altura: altura,
      ),
    );
  }

  Future<void> salvarNotaProgressaoNivel(int nivel, String nota) async {
    final mapa = Map<int, String>.from(
      state.personagem.notasProgressaoPorNivel,
    );
    final texto = nota.trim();
    if (texto.isEmpty) {
      mapa.remove(nivel);
    } else {
      mapa[nivel] = texto;
    }
    await atualizarPersonagem(
      state.personagem.copyWith(notasProgressaoPorNivel: mapa),
    );
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
