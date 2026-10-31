import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:t20_creator/domain/entities/personagem/classe.dart';
import 'package:t20_creator/domain/entities/personagem/classe_do_personagem.dart';
import 'package:t20_creator/domain/entities/personagem/proficiencias.dart';
import 'package:t20_creator/domain/entities/habilidades_complexas/linhagem_arcanista.dart';
import 'package:t20_creator/domain/entities/equipamento/arma.dart';
import 'package:t20_creator/domain/entities/equipamento/protecao.dart';
import 'package:t20_creator/domain/services/regras_carga_service.dart';
import 'package:t20_creator/domain/services/personagem_storage_service.dart';
import '../../domain/repositories/i_personagem_repository.dart';
import '../../domain/entities/personagem/personagem.dart';
import '../../domain/services/regras_atributos.dart';
import '../../domain/entities/personagem/raca.dart';
import '../../domain/entities/personagem/origem.dart';
import '../../domain/entities/personagem/poder.dart';
import '../../domain/entities/personagem/divindade.dart';
import '../../domain/validators/validador_divindade.dart';
import '../../domain/services/poderes_e_magias/aprendizado_magia_service.dart';

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

  // metodos relacionados a divindade e devocao
  final Divindade? divindadeSelecionada;
  final List<Poder> poderesConcedidosSelecionados;
  final TipoEnergia? canalizacaoSelecionada;
  final bool modoEstritoDevocao;

  Poder? get poderConcedidoSelecionado =>
      poderesConcedidosSelecionados.isNotEmpty
      ? poderesConcedidosSelecionados.first
      : null;

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

  // Magias aprendidas na etapa de magias
  final List<String> magiasSelecionadas;

  // Equipamento inicial (Nível 1)
  final Arma? armaSimplesInicial;
  final Arma? armaMarcialInicial;
  final Protecao? armaduraInicial;
  final Protecao? escudoInicial;
  final int? tibaresIniciais;

  PersonagemState({
    required this.personagem,
    this.etapaAtual = 0,
    this.metodoAtributos = MetodoAtributos.nenhum,
    this.origemSelecionada,
    this.periciasEscolhidasOrigem = const [],
    this.poderesEscolhidosOrigem = const [],
    this.divindadeSelecionada,
    List<Poder>? poderesConcedidosSelecionados,
    Poder? poderConcedidoSelecionado,
    this.canalizacaoSelecionada,
    this.modoEstritoDevocao = true,
    this.valoresRolados = const [],
    this.alocacaoIndices = const {},
    this.pontosRestantesCompra = 10,
    this.atributosVariaveisRaca = const [],
    this.selecoesPericiaClasse = const [],
    this.selecoesPericiaInteligencia = const [],
    this.magiasSelecionadas = const [],
    this.armaSimplesInicial,
    this.armaMarcialInicial,
    this.armaduraInicial,
    this.escudoInicial,
    this.tibaresIniciais,
  }) : poderesConcedidosSelecionados =
           poderesConcedidosSelecionados ??
           (poderConcedidoSelecionado != null
               ? [poderConcedidoSelecionado]
               : const []);

  int get metaBeneficiosOrigem {
    if (origemSelecionada == null) return 2;
    final opcoesDisponiveis =
        origemSelecionada!.periciasOpcoes.length +
        origemSelecionada!.poderesGeraisOpcoes.length +
        (origemSelecionada!.poderUnico.key.isNotEmpty ? 1 : 0);
    return opcoesDisponiveis < 2 ? opcoesDisponiveis : 2;
  }

  int get totalBeneficiosOrigem =>
      periciasEscolhidasOrigem.length + poderesEscolhidosOrigem.length;

  bool get concluiuOrigem =>
      origemSelecionada != null &&
      totalBeneficiosOrigem == metaBeneficiosOrigem;

  Set<String> get todasPericiasTreinadasAteOrigem {
    final fixas = personagem.classes.isNotEmpty
        ? personagem.classes[0].classeDefinicao.periciasFixas
        : const <String>[];
    final exclusivas = personagem.classes.isNotEmpty
        ? personagem.classes[0].periciasExclusivasEscolhidas.values
        : const <String>[];
    return {
      ...personagem.periciasTreinadas,
      ...selecoesPericiaClasse,
      ...selecoesPericiaInteligencia,
      ...fixas,
      ...exclusivas,
    };
  }

  bool periciaJaTreinada(String sigla) =>
      todasPericiasTreinadasAteOrigem.contains(sigla);

  int get cotaPoderesConcedidos =>
      ValidadorDivindade.ehDevotoFiel(personagem) ? 2 : 1;

  bool get etapaDivindadeConcluida {
    final precisaDevocao = ValidadorDivindade.exigeDevocao(
      personagem,
      modoEstrito: modoEstritoDevocao,
    );

    // Se não escolheu divindade (Não Devoto)
    if (divindadeSelecionada == null) {
      return !precisaDevocao;
    }

    // Valida elegibilidade com base na classe/regras
    final elegibilidade = ValidadorDivindade.validarElegibilidade(
      personagem: personagem,
      divindade: divindadeSelecionada,
      modoEstrito: modoEstritoDevocao,
    );
    if (!elegibilidade.ehElegivel) return false;

    // Se a divindade permite qualquer canalização, exige escolha expressa
    if (divindadeSelecionada!.canalizacaoPermitida ==
        CanalizacaoOpcao.qualquer) {
      if (canalizacaoSelecionada == null) return false;
    }

    // Devoto Fiel (Clérigo, Druida, Paladino) escolhe 2 poderes; Devoto Comum escolhe 1
    return poderesConcedidosSelecionados.length == cotaPoderesConcedidos;
  }

  // --- REGRAS E CONCLUSÃO DE MAGIAS INICIAIS ---
  RegrasConjuracaoClasse get regrasConjuracao {
    if (personagem.classes.isEmpty) {
      return const RegrasConjuracaoClasse(isConjurador: false);
    }
    final classeAtual = personagem.classes[0];
    return AprendizadoMagiaService.obterRegrasIniciais(
      classeAtual.classeDefinicao.idClasse,
      caminhoId: classeAtual.caminhoEscolhido?.nome,
    );
  }

  bool get concluiuMagias {
    final regras = regrasConjuracao;
    if (!regras.isConjurador) return true;
    return magiasSelecionadas.length == regras.qtdMagiasIniciais;
  }

  // Getters para Equipamento Inicial e Carga
  OpcoesArmasIniciais get opcoesArmasIniciais =>
      RegrasCargaService.obterArmasIniciaisDisponiveis(personagem);

  OpcoesProtecoesIniciais get opcoesProtecoesIniciais =>
      RegrasCargaService.obterProtecoesIniciaisDisponiveis(personagem);

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

    final armaduraAtual = armaduraInicial ?? personagem.armaduraEquipada;
    final escudoAtual = escudoInicial ?? personagem.escudoEquipado;

    final modForca = personagem.getValorFinal('FOR');
    final limite = RegrasCargaService.calcularLimiteCarga(modForca);
    final atual = RegrasCargaService.calcularEspacosOcupados(
      armas: armasAtuais,
      itensInventario: itensAtuais,
      armadura: armaduraAtual,
      escudo: escudoAtual,
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
    // Arcanistas começam sem armadura por regra. Outras classes devem escolher 1 armadura.
    if (!personagem.ehArcanista && armaduraInicial == null) {
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
    List<Poder>? poderesConcedidosSelecionados,
    Poder? poderConcedidoSelecionado,
    TipoEnergia? canalizacaoSelecionada,
    bool anularCanalizacao = false,
    bool? modoEstritoDevocao,
    bool anularDivindade = false,
    List<int>? valoresRolados,
    Map<String, int>? alocacaoIndices,
    int? pontosRestantesCompra,
    List<String>? atributosVariaveisRaca,
    List<String>? selecoesPericiaClasse,
    List<String>? selecoesPericiaInteligencia,
    List<String>? magiasSelecionadas,
    Arma? armaSimplesInicial,
    bool anularArmaSimples = false,
    Arma? armaMarcialInicial,
    bool anularArmaMarcial = false,
    Protecao? armaduraInicial,
    bool anularArmadura = false,
    Protecao? escudoInicial,
    bool anularEscudo = false,
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
      poderesConcedidosSelecionados: anularDivindade
          ? const []
          : (poderesConcedidosSelecionados ??
                (poderConcedidoSelecionado != null
                    ? [poderConcedidoSelecionado]
                    : this.poderesConcedidosSelecionados)),
      canalizacaoSelecionada: (anularDivindade || anularCanalizacao)
          ? null
          : (canalizacaoSelecionada ?? this.canalizacaoSelecionada),
      modoEstritoDevocao: modoEstritoDevocao ?? this.modoEstritoDevocao,
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
      magiasSelecionadas: magiasSelecionadas ?? this.magiasSelecionadas,
      armaSimplesInicial: anularArmaSimples
          ? null
          : (armaSimplesInicial ?? this.armaSimplesInicial),
      armaMarcialInicial: anularArmaMarcial
          ? null
          : (armaMarcialInicial ?? this.armaMarcialInicial),
      armaduraInicial: anularArmadura
          ? null
          : (armaduraInicial ?? this.armaduraInicial),
      escudoInicial: anularEscudo
          ? null
          : (escudoInicial ?? this.escudoInicial),
      tibaresIniciais: tibaresIniciais ?? this.tibaresIniciais,
    );
  }
}

class PersonagemCubit extends Cubit<PersonagemState> {
  final IPersonagemRepository _repository;

  PersonagemCubit({IPersonagemRepository? repository})
      : _repository = repository ?? const PersonagemStorageService(),
        super(PersonagemState(personagem: Personagem.inicial()));

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
    } else if (state.etapaAtual == 7) {
      consolidarMagias();
    }
    emit(state.copyWith(etapaAtual: state.etapaAtual + 1));
  }

  void voltarEtapa() {
    // Se estiver na Raça (1) ou qualquer etapa posterior, volta uma etapa preservando o progresso
    if (state.etapaAtual >= 1) {
      emit(state.copyWith(etapaAtual: state.etapaAtual - 1));
    }
    // Se estiver nos Atributos (0) e quiser sair da seleção de método
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
  // Quando o usuário seleciona a raça e confirma os atributos flexíveis no modal:
  void selecionarRaca(
    Raca novaRaca, {
    List<String> atributosVariaveis = const [],
  }) {
    final ehLefou = novaRaca.id.toLowerCase() == 'lefou';
    final personagemAtualizado = state.personagem.copyWith(
      raca: novaRaca,
      atributosVariaveisRaca: atributosVariaveis,
      periciasDeformidadeLefou:
          ehLefou ? state.personagem.periciasDeformidadeLefou : const [],
      anularPoderTormentaDeformidade: !ehLefou,
    );

    emit(
      state.copyWith(
        personagem: personagemAtualizado,
        atributosVariaveisRaca:
            atributosVariaveis, // se ainda mantiver no state da UI
      ),
    );
  }

  // Ou caso exista um método separado apenas para atualizar os bônus variáveis:
  void atualizarAtributosVariaveisRaca(List<String> selecionados) {
    final personagemAtualizado = state.personagem.copyWith(
      atributosVariaveisRaca: selecionados,
    );

    emit(
      state.copyWith(
        personagem: personagemAtualizado,
        atributosVariaveisRaca: selecionados,
      ),
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
      if (listaAtual.length < 3) {
        listaAtual.add(sigla);
      }
    }

    final personagemAtualizado = state.personagem.copyWith(
      atributosVariaveisRaca: listaAtual,
    );

    emit(
      state.copyWith(
        personagem: personagemAtualizado,
        atributosVariaveisRaca: listaAtual,
      ),
    );
  }

  // --- DEFORMIDADE DO LEFOU ---
  void togglePericiaDeformidadeLefou(String nomePericia) {
    final raca = state.personagem.raca;
    if (raca == null || raca.id.toLowerCase() != 'lefou') return;

    final maxPericias =
        state.personagem.poderTormentaDeformidade != null ? 1 : 2;
    final atuais = List<String>.from(state.personagem.periciasDeformidadeLefou);

    if (atuais.contains(nomePericia)) {
      atuais.remove(nomePericia);
    } else {
      if (atuais.length < maxPericias) {
        atuais.add(nomePericia);
      } else if (maxPericias == 1) {
        atuais
          ..clear()
          ..add(nomePericia);
      }
    }

    emit(
      state.copyWith(
        personagem: state.personagem.copyWith(
          periciasDeformidadeLefou: atuais,
        ),
      ),
    );
  }

  void selecionarPoderTormentaDeformidade(Poder? poder) {
    final raca = state.personagem.raca;
    if (raca == null || raca.id.toLowerCase() != 'lefou') return;

    final periciasAtuais =
        List<String>.from(state.personagem.periciasDeformidadeLefou);
    if (poder != null && periciasAtuais.length > 1) {
      periciasAtuais.removeRange(1, periciasAtuais.length);
    }

    emit(
      state.copyWith(
        personagem: state.personagem.copyWith(
          periciasDeformidadeLefou: periciasAtuais,
          poderTormentaDeformidade: poder,
          anularPoderTormentaDeformidade: poder == null,
        ),
      ),
    );
  }

  // Vamos começar a logica de seleção de classe

  void selecionarClasse(Classe classeDefinicao) {
    final classeAnterior = state.personagem.classes.isNotEmpty
        ? state.personagem.classes[0].classeDefinicao
        : null;
    final mudouDeClasse =
        classeAnterior != null && classeAnterior.idClasse != classeDefinicao.idClasse;

    // Cria a instância da classe no Nível 1
    final novaClasse = ClasseDoPersonagem(
      classeDefinicao: classeDefinicao,
      nivel: 1,
    );

    if (mudouDeClasse) {
      final temProfMarcial = classeDefinicao.proficiencias.contains(
        TipoProficiencia.armasMarciais,
      );
      final ehArcanista =
          classeDefinicao.idClasse.toLowerCase() == 'arcanista';
      final temProfEscudo = classeDefinicao.proficiencias.contains(
        TipoProficiencia.escudos,
      );

      final novasArmas = List<Arma>.from(state.personagem.armas);
      if (!temProfMarcial) {
        novasArmas.removeWhere(
          (a) => a.proficiencia == ProficienciaArma.marcial,
        );
      }

      final periciasPreservadas =
          List<String>.from(state.periciasEscolhidasOrigem);

      final novoPersonagem = state.personagem.copyWith(
        classe_do_personagem: [novaClasse],
        periciasTreinadas: periciasPreservadas,
        magiasConhecidas: const [],
        armas: novasArmas,
        anularArmadura: ehArcanista,
        anularEscudo: !temProfEscudo,
      );

      emit(
        state.copyWith(
          personagem: novoPersonagem,
          selecoesPericiaClasse: const [],
          selecoesPericiaInteligencia: const [],
          magiasSelecionadas: const [],
          anularArmaMarcial: !temProfMarcial,
          anularArmadura: ehArcanista,
          anularEscudo: !temProfEscudo,
        ),
      );
    } else {
      // Como estamos na criação do personagem, esta será a classe principal (índice 0)
      final novoPersonagem = state.personagem.copyWith(
        classe_do_personagem: [novaClasse],
      );
      emit(state.copyWith(personagem: novoPersonagem));
    }
  }

  // para classes com subclasses/caminhos
  void selecionarCaminhoDaClasse(CaminhoDeClasse caminho) {
    if (state.personagem.classes.isEmpty) return;

    // Pega a classe atual e atualiza com o caminho escolhido
    final classeAtual = state.personagem.classes[0];
    final mudouCaminho = classeAtual.caminhoEscolhido?.nome != caminho.nome;
    final classeAtualizada = classeAtual.copyWith(
      caminhoEscolhido: caminho,
      anularLinhagem: mudouCaminho,
    );

    final novoPersonagem = state.personagem.copyWith(
      classe_do_personagem: [classeAtualizada],
      magiasConhecidas:
          mudouCaminho ? const [] : state.personagem.magiasConhecidas,
    );
    emit(
      state.copyWith(
        personagem: novoPersonagem,
        magiasSelecionadas:
            mudouCaminho ? const [] : state.magiasSelecionadas,
      ),
    );
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
    if (state.periciaJaTreinada(siglaPericia) &&
        !state.periciasEscolhidasOrigem.contains(siglaPericia)) {
      return;
    }
    final pericias = List<String>.from(state.periciasEscolhidasOrigem);
    if (pericias.contains(siglaPericia)) {
      pericias.remove(siglaPericia);
    } else {
      if (state.totalBeneficiosOrigem < state.metaBeneficiosOrigem) {
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
      if (state.totalBeneficiosOrigem < state.metaBeneficiosOrigem) {
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

  void alternarModoEstritoDevocao(bool estrito) {
    emit(state.copyWith(modoEstritoDevocao: estrito));
  }

  void selecionarDivindade(Divindade? divindade) {
    if (divindade == null) {
      // Optou por não ser devoto / desmarcou
      emit(
        state.copyWith(
          anularDivindade: true,
          poderesConcedidosSelecionados: const [],
          anularCanalizacao: true,
        ),
      );
      return;
    }

    // Define canalização inicial se a divindade for de canalização exclusiva
    TipoEnergia? canalizacao;
    if (divindade.canalizacaoPermitida == CanalizacaoOpcao.apenasPositiva) {
      canalizacao = TipoEnergia.positiva;
    } else if (divindade.canalizacaoPermitida ==
        CanalizacaoOpcao.apenasNegativa) {
      canalizacao = TipoEnergia.negativa;
    }

    emit(
      state.copyWith(
        divindadeSelecionada: divindade,
        poderesConcedidosSelecionados: const [],
        canalizacaoSelecionada: canalizacao,
        anularCanalizacao: canalizacao == null,
      ),
    );
  }

  void selecionarCanalizacao(TipoEnergia energia) {
    emit(state.copyWith(canalizacaoSelecionada: energia));
  }

  void selecionarPoderConcedido(Poder poder) {
    final cota = state.cotaPoderesConcedidos;
    final atuais = List<Poder>.from(state.poderesConcedidosSelecionados);
    final index = atuais.indexWhere((p) => p.key == poder.key);

    if (index >= 0) {
      // Desmarca o poder caso já esteja selecionado
      atuais.removeAt(index);
    } else {
      if (cota == 1) {
        // Devoto comum: seleciona 1
        atuais.clear();
        atuais.add(poder);
      } else {
        // Devoto fiel: escolhe até 2 poderes
        if (atuais.length < cota) {
          atuais.add(poder);
        } else {
          // Já tem 2 poderes: substitui o mais antigo
          atuais.removeAt(0);
          atuais.add(poder);
        }
      }
    }

    emit(state.copyWith(poderesConcedidosSelecionados: atuais));
  }

  void consolidarDivindade() {
    if (!state.etapaDivindadeConcluida) return;

    if (state.divindadeSelecionada == null) {
      final novoPersonagem = state.personagem.copyWith(
        anularDivindade: true,
        anularCanalizacao: true,
      );
      emit(state.copyWith(personagem: novoPersonagem));
    } else {
      final energiaFinal =
          state.canalizacaoSelecionada ??
          state.divindadeSelecionada!.energiaCanalizada;

      final novoPersonagem = state.personagem.copyWith(
        divindade: state.divindadeSelecionada,
        poderesConcedidos: state.poderesConcedidosSelecionados,
        canalizacaoEnergia: energiaFinal,
      );
      emit(state.copyWith(personagem: novoPersonagem));
    }
  }

  // --- MÉTODOS DE MAGIAS INICIAIS ---

  void alternarMagia(String magiaId) {
    final regras = state.regrasConjuracao;
    if (!regras.isConjurador) return;

    final selecionadas = List<String>.from(state.magiasSelecionadas);
    if (selecionadas.contains(magiaId)) {
      selecionadas.remove(magiaId);
    } else {
      if (selecionadas.length < regras.qtdMagiasIniciais) {
        selecionadas.add(magiaId);
      }
    }
    emit(state.copyWith(magiasSelecionadas: selecionadas));
  }

  void definirMagias(List<String> magias) {
    emit(state.copyWith(magiasSelecionadas: List<String>.from(magias)));
  }

  void consolidarMagias() {
    emit(
      state.copyWith(
        personagem: state.personagem.copyWith(
          magiasConhecidas: List<String>.from(state.magiasSelecionadas),
        ),
      ),
    );
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
    emit(state.copyWith(personagem: state.personagem.copyWith(peso: novoPeso)));
  }

  void atualizarAltura(String novaAltura) {
    emit(
      state.copyWith(personagem: state.personagem.copyWith(altura: novaAltura)),
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
      state.copyWith(personagem: state.personagem.copyWith(anularFoto: true)),
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

  /// Retorna as opções de armaduras e escudos iniciais disponíveis para a classe do personagem
  OpcoesProtecoesIniciais obterProtecoesIniciaisDisponiveis(Personagem p) {
    return RegrasCargaService.obterProtecoesIniciaisDisponiveis(p);
  }

  void selecionarArmaduraInicial(Protecao armadura) {
    emit(state.copyWith(armaduraInicial: armadura));
  }

  void removerArmaduraInicial() {
    emit(state.copyWith(anularArmadura: true));
  }

  void selecionarEscudoInicial(Protecao escudo) {
    emit(state.copyWith(escudoInicial: escudo));
  }

  void removerEscudoInicial() {
    emit(state.copyWith(anularEscudo: true));
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
      armaduraEquipada: state.armaduraInicial,
      escudoEquipado: state.escudoInicial,
    );

    emit(state.copyWith(personagem: novoPersonagem));
  }

  // MÉTODO PARA SALVAR A FICHA NO DISCO DO ANDROID
  Future<void> salvarPersonagemNoAparelho() async {
    await _repository.salvar(state.personagem);
  }

  @visibleForTesting
  void emitirEstadoParaTeste(PersonagemState novoEstado) {
    emit(novoEstado);
  }
}
