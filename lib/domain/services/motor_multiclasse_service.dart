import 'dart:math';
import '../entities/habilidades_complexas/linhagem_arcanista.dart';
import '../entities/personagem/classe.dart';
import '../entities/personagem/classe_do_personagem.dart';
import '../entities/personagem/personagem.dart';
import '../entities/personagem/poder.dart';
import '../entities/personagem/proficiencias.dart';
import 'motor_modificadores_service.dart';

/// RF10 / RN09 — Patamar de jogo determinado pelo nível total do personagem.
enum PatamarJogo {
  iniciante,
  veterano,
  campeao,
  lenda;

  String get label => switch (this) {
    PatamarJogo.iniciante => 'Iniciante',
    PatamarJogo.veterano => 'Veterano',
    PatamarJogo.campeao => 'Campeão',
    PatamarJogo.lenda => 'Lenda',
  };

  String get faixaNiveis => switch (this) {
    PatamarJogo.iniciante => '1–4',
    PatamarJogo.veterano => '5–10',
    PatamarJogo.campeao => '11–16',
    PatamarJogo.lenda => '17–20',
  };

  static PatamarJogo porNivel(int nivelTotal) {
    if (nivelTotal >= 17) return PatamarJogo.lenda;
    if (nivelTotal >= 11) return PatamarJogo.campeao;
    if (nivelTotal >= 5) return PatamarJogo.veterano;
    return PatamarJogo.iniciante;
  }
}

/// Item individual na distribuição de níveis por classe (RF02, RF04, RF11).
class ItemDistribuicaoClasse {
  final String idClasse;
  final String nomeClasse;
  final int nivel;
  final bool ehClasseInicial;
  final String? caminho;

  const ItemDistribuicaoClasse({
    required this.idClasse,
    required this.nomeClasse,
    required this.nivel,
    required this.ehClasseInicial,
    this.caminho,
  });
}

/// RF11 — Estrutura de consulta da distribuição de níveis do personagem entre classes.
class ResumoDistribuicaoMulticlasse {
  final String nomePersonagem;
  final int nivelTotal;
  final PatamarJogo patamar;
  final List<ItemDistribuicaoClasse> classes;

  const ResumoDistribuicaoMulticlasse({
    required this.nomePersonagem,
    required this.nivelTotal,
    required this.patamar,
    required this.classes,
  });

  /// Formata a visualização textual conforme especificação RF11.
  String formatarTexto() {
    final buffer = StringBuffer()
      ..writeln('Personagem: $nomePersonagem')
      ..writeln()
      ..writeln('Nível total: $nivelTotal')
      ..writeln('Patamar: ${patamar.label}')
      ..writeln()
      ..writeln('Classes:');
    for (final c in classes) {
      buffer.writeln('- ${c.nomeClasse}: ${c.nivel}');
    }
    return buffer.toString().trimRight();
  }
}

/// RF12 — Registro detalhado de cada nível adquirido, distinguindo a progressão geral
/// do personagem (nível total, patamar) da progressão individual na classe escolhida.
class RegistroProgressaoMulticlasse {
  final int nivelPersonagem;
  final PatamarJogo patamar;
  final bool novoPatamarAlcancado;
  final String idClasse;
  final String nomeClasse;
  final int nivelIndividualClasse;
  final bool ehClasseInicial;
  final bool ehAquisicaoNovaMulticlasse;
  final String? caminhoEscolhido;
  final List<String> caracteristicasClasse;
  final Poder? poderEscolhido;
  final int pvAdquiridosNoNivel;
  final int pmAdquiridosNoNivel;

  const RegistroProgressaoMulticlasse({
    required this.nivelPersonagem,
    required this.patamar,
    required this.novoPatamarAlcancado,
    required this.idClasse,
    required this.nomeClasse,
    required this.nivelIndividualClasse,
    required this.ehClasseInicial,
    required this.ehAquisicaoNovaMulticlasse,
    this.caminhoEscolhido,
    required this.caracteristicasClasse,
    this.poderEscolhido,
    required this.pvAdquiridosNoNivel,
    required this.pmAdquiridosNoNivel,
  });
}

/// Exceção de domínio lançada quando uma Regra de Validação (RV01–RV07) é violada.
class ExcecaoValidacaoMulticlasse implements Exception {
  final String codigoRegra;
  final String mensagem;

  const ExcecaoValidacaoMulticlasse(this.codigoRegra, this.mensagem);

  @override
  String toString() => '[$codigoRegra] $mensagem';
}

/// Resultado de auditoria de integridade das regras de validação RV01–RV07.
class ResultadoValidacaoMulticlasse {
  final bool valido;
  final List<ExcecaoValidacaoMulticlasse> violacoes;

  const ResultadoValidacaoMulticlasse({
    required this.valido,
    this.violacoes = const [],
  });
}

/// Motor de Domínio responsável por aplicar todas as Regras Funcionais (RF01–RF12),
/// Regras de Negócio (RN01–RN10) e Regras de Validação (RV01–RV07) de Multiclasse no Tormenta 20.
class MotorMulticlasseService {
  static const int nivelMaximoPersonagem = 20;

  /// RF03 / RN02 — Calcula automaticamente o nível total pela soma dos níveis individuais de todas as classes.
  static int calcularNivelTotal(Personagem p) {
    if (p.classes.isEmpty) return 0;
    return p.classes.fold<int>(0, (soma, c) => soma + c.nivel);
  }

  /// RF10 / RN09 — Determina o patamar de jogo considerando o nível total do personagem.
  static PatamarJogo identificarPatamar(Personagem p) {
    final nivel = calcularNivelTotal(p);
    return PatamarJogo.porNivel(nivel > 0 ? nivel : 1);
  }

  /// RF04 / RN03 — Retorna o nível individual em uma classe específica (0 se não possuir a classe),
  /// sem jamais confundi-lo com o nível total do personagem.
  static int obterNivelIndividualClasse(Personagem p, String idOuNomeClasse) {
    final alvo = _normalizar(idOuNomeClasse);
    for (final c in p.classes) {
      if (_normalizar(c.classeDefinicao.idClasse) == alvo ||
          _normalizar(c.classeDefinicao.nome) == alvo) {
        return c.nivel;
      }
    }
    return 0;
  }

  /// RF05 / RN08 / RV07 — Retorna as características de classe correspondentes estritamente
  /// ao nível individual informando naquela classe.
  static List<String> obterCaracteristicasDoNivelIndividual(
    Classe classe,
    int nivelIndividualClasse,
  ) {
    if (nivelIndividualClasse < 1 ||
        nivelIndividualClasse > nivelMaximoPersonagem) {
      return const [];
    }
    return List<String>.unmodifiable(
      classe.tabelaDeProgressao[nivelIndividualClasse] ?? const <String>[],
    );
  }

  /// RF04 / RF05 / RN08 / RV07 — Consulta todas as características de classe acumuladas pelo personagem
  /// em uma classe específica respeitando exclusivamente o nível individual naquela classe.
  static List<String> obterCaracteristicasAcumuladasDaClasse(
    Personagem p,
    String idOuNomeClasse,
  ) {
    final alvo = _normalizar(idOuNomeClasse);
    final instancia = p.classes.where((c) {
      return _normalizar(c.classeDefinicao.idClasse) == alvo ||
          _normalizar(c.classeDefinicao.nome) == alvo;
    }).firstOrNull;

    if (instancia == null) return const [];

    final resultado = <String>[];
    for (int n = 1; n <= instancia.nivel; n++) {
      resultado.addAll(
        instancia.classeDefinicao.tabelaDeProgressao[n] ?? const <String>[],
      );
    }
    return resultado;
  }

  /// RF06 / RN04 / RV05 — Calcula os Pontos de Vida totais respeitando a regra de multiclasse:
  /// - Classe inicial (`classes[0]`): recebe `pvInicial + CON` no 1º nível e `max(1, pvPorNivel + CON)` nos níveis subsequentes.
  /// - Classes secundárias (`classes[1..]`): recebem APENAS PV de nível subsequente (`max(1, pvPorNivel + CON)` por nível),
  ///   desconsiderando os PV de 1º nível (`pvInicial`).
  static int calcularPvTotal(Personagem p) {
    if (p.classes.isEmpty) return 0;

    final int con = p.getValorFinal('CON');
    int totalPV = 0;

    for (int i = 0; i < p.classes.length; i++) {
      final item = p.classes[i];
      final regras = item.classeDefinicao;
      final bool ehClasseInicial = (i == 0);

      if (ehClasseInicial) {
        int pvNivel1 = regras.pvInicial + con;
        if (pvNivel1 < 1) pvNivel1 = 1;
        totalPV += pvNivel1;

        if (item.nivel > 1) {
          final int ganhoSubsequente = max(1, regras.pvPorNivel + con);
          totalPV += ganhoSubsequente * (item.nivel - 1);
        }
      } else {
        // RN04 / RV05: Multiclasse concede exclusivamente PV de nível subsequente!
        final int ganhoSubsequente = max(1, regras.pvPorNivel + con);
        totalPV += ganhoSubsequente * item.nivel;
      }
    }

    return totalPV +
        p.bonusRacialPV +
        MotorModificadoresService.calcularBonusDeclarativoPV(p);
  }

  /// RF07 / RN05 — Calcula os Pontos de Mana totais somando os PM provenientes de todas as classes,
  /// atributos-chave de conjuração/Abençoado (sem acumular o mesmo atributo duas vezes, conforme regra T20),
  /// bônus racial e modificadores declarativos.
  static int calcularPmTotal(Personagem p) {
    if (p.classes.isEmpty) return 0;

    int totalPM = 0;
    final atributosSomadosPM = <String>{};

    for (int i = 0; i < p.classes.length; i++) {
      final item = p.classes[i];
      final def = item.classeDefinicao;

      if (i == 0) {
        totalPM += def.pmInicial;
        if (item.nivel > 1) {
          totalPM += def.pmPorNivel * (item.nivel - 1);
        }
      } else {
        totalPM += def.pmPorNivel * item.nivel;
      }

      final siglaAtributo = obterAtributoChavePmClasse(item);
      if (siglaAtributo != null && atributosSomadosPM.add(siglaAtributo)) {
        final modAtrib = p.getValorFinal(siglaAtributo);
        if (modAtrib > 0) {
          totalPM += modAtrib;
        }
      }
    }

    return totalPM +
        p.bonusRacialPM +
        MotorModificadoresService.calcularBonusDeclarativoPM(p);
  }

  /// Retorna o atributo-chave somado aos PM pelas habilidades de 1º nível da classe (Magias / Abençoado).
  static String? obterAtributoChavePmClasse(ClasseDoPersonagem c) {
    return switch (_normalizar(c.classeDefinicao.idClasse)) {
      'clerigo' || 'druida' => 'SAB',
      'bardo' || 'paladino' => 'CAR',
      'arcanista' =>
        _normalizar(c.caminhoEscolhido?.nome ?? '') == 'feiticeiro'
            ? 'CAR'
            : 'INT',
      _ => null,
    };
  }

  /// RF08 / RN06 / RV06 — Retorna as perícias treinadas fixas/exclusivas concedidas automaticamente:
  /// APENAS da classe inicial (`classes[0]`). Classes adquiridas via multiclasse NÃO concedem perícias iniciais!
  static Set<String> obterPericiasIniciaisClasseConcedidas(Personagem p) {
    if (p.classes.isEmpty) return const {};
    final inicial = p.classes.first;
    return {
      ...inicial.classeDefinicao.periciasFixas.map((s) => s.toUpperCase()),
      ...inicial.periciasExclusivasEscolhidas.values.map(
        (s) => s.toUpperCase(),
      ),
    };
  }

  /// RF09 / RN07 / RV06 — Retorna as proficiências iniciais de classe concedidas automaticamente:
  /// APENAS da classe inicial (`classes[0]`). Classes adquiridas via multiclasse NÃO concedem proficiências iniciais!
  /// Em Tormenta 20 JdA, todo personagem recebe proficiência básica em Armas Simples e
  /// (exceto se a classe inicial for Arcanista) em Armaduras Leves, além das proficiências específicas de `classes[0]`.
  static Set<TipoProficiencia> obterProficienciasIniciaisClasseConcedidas(
    Personagem p,
  ) {
    if (p.classes.isEmpty) return const {};
    final inicial = p.classes.first.classeDefinicao;
    final ehInicialArcanista = _normalizar(inicial.idClasse) == 'arcanista';
    return {
      TipoProficiencia.armasSimples,
      if (!ehInicialArcanista) TipoProficiencia.armadurasLeves,
      ...inicial.proficiencias,
    };
  }

  /// RF01, RF02, RF05, RN01, RN06, RN07, RN10, RV01, RV02, RV04, RV06 —
  /// Adquire 1 novo nível para o personagem atribuindo-o à `classeEscolhida` (existente ou nova multiclasse).
  static Personagem adquirirNivelEmClasse({
    required Personagem personagem,
    required Classe classeEscolhida,
    CaminhoDeClasse? caminhoInicial,
    Linhagem? linhagemInicial,
  }) {
    final nivelAtual = calcularNivelTotal(personagem);
    if (nivelAtual >= nivelMaximoPersonagem) {
      throw const ExcecaoValidacaoMulticlasse(
        'RV01',
        'O personagem já atingiu o nível máximo permitido (20).',
      );
    }

    final idAlvo = _normalizar(classeEscolhida.idClasse);
    final novasClasses = List<ClasseDoPersonagem>.from(personagem.classes);
    final indiceExistente = novasClasses.indexWhere(
      (c) => _normalizar(c.classeDefinicao.idClasse) == idAlvo,
    );

    if (indiceExistente >= 0) {
      // RV04 / RN10: Incrementa SOMENTE a classe selecionada, preservando todas as demais intactas
      final atual = novasClasses[indiceExistente];
      novasClasses[indiceExistente] = atual.copyWith(
        nivel: atual.nivel + 1,
        caminhoEscolhido: caminhoInicial ?? atual.caminhoEscolhido,
        linhagemEscolhida: linhagemInicial ?? atual.linhagemEscolhida,
      );
    } else {
      // Nova classe (Inicial se classes estava vazia, ou Multiclasse se já possuía classe inicial)
      final caminhoPadrao =
          caminhoInicial ??
          (classeEscolhida.caminhosNivel1.isNotEmpty
              ? classeEscolhida.caminhosNivel1.first
              : null);

      novasClasses.add(
        ClasseDoPersonagem(
          classeDefinicao: classeEscolhida,
          nivel: 1,
          // RN06 / RV06: Multiclasse não concede escolhas de perícias iniciais!
          periciasExclusivasEscolhidas: const {},
          caminhoEscolhido: caminhoPadrao,
          linhagemEscolhida: linhagemInicial,
          poderesEscolhidos: const [],
        ),
      );
    }

    final historicoBase = normalizarHistoricoClasses(personagem);
    final novoHistorico = <String>[
      ...historicoBase,
      classeEscolhida.idClasse.toLowerCase(),
    ];

    // RN06 / RN07 / RN10: Preserva periciasTreinadas, proficienciasExtras e características anteriores sem conceder iniciais da nova classe!
    final atualizado = personagem.copyWith(
      classe_do_personagem: novasClasses,
      historicoClassesPorNivel: novoHistorico,
    );

    final deltaPV = max(0, atualizado.pvTotal - personagem.pvTotal);
    final deltaPM = max(0, atualizado.pmTotal - personagem.pmTotal);

    return atualizado.copyWith(
      pvAtual: (personagem.pvAtual + deltaPV).clamp(0, atualizado.pvTotal),
      pmAtual: (personagem.pmAtual + deltaPM).clamp(0, atualizado.pmTotal),
    );
  }

  /// Reduz 1 nível de uma classe específica mantendo a integridade de RV02 e RV03.
  static Personagem removerNivelDeClasse({
    required Personagem personagem,
    required int indiceClasse,
  }) {
    if (indiceClasse < 0 || indiceClasse >= personagem.classes.length) {
      return personagem;
    }

    final cl = personagem.classes[indiceClasse];
    if (indiceClasse == 0 && cl.nivel <= 1) {
      // Classe inicial não pode cair para nível 0
      return personagem;
    }

    final novasClasses = List<ClasseDoPersonagem>.from(personagem.classes);
    final novoNivelClasse = cl.nivel - 1;

    if (novoNivelClasse <= 0) {
      // RV02: Classe secundária reduzida a 0 é removida para nunca manter classe registrada com nível <= 0
      novasClasses.removeAt(indiceClasse);
    } else {
      final maxPoderes = max(0, novoNivelClasse - 1);
      final poderesAjustados = cl.poderesEscolhidos.length > maxPoderes
          ? cl.poderesEscolhidos.sublist(0, maxPoderes)
          : cl.poderesEscolhidos;
      novasClasses[indiceClasse] = cl.copyWith(
        nivel: novoNivelClasse,
        poderesEscolhidos: poderesAjustados,
      );
    }

    final historico = List<String>.from(normalizarHistoricoClasses(personagem));
    final idRemovido = _normalizar(cl.classeDefinicao.idClasse);
    for (int i = historico.length - 1; i >= 0; i--) {
      if (_normalizar(historico[i]) == idRemovido) {
        historico.removeAt(i);
        break;
      }
    }

    final atualizado = personagem.copyWith(
      classe_do_personagem: novasClasses,
      historicoClassesPorNivel: historico,
    );

    return atualizado.copyWith(
      pvAtual: personagem.pvAtual.clamp(0, atualizado.pvTotal),
      pmAtual: personagem.pmAtual.clamp(0, atualizado.pmTotal),
    );
  }

  /// Garante que o histórico nível a nível reflita exatamente a soma e contagem das classes registradas.
  static List<String> normalizarHistoricoClasses(Personagem p) {
    if (p.classes.isEmpty) return const [];

    final contagemEsperada = <String, int>{};
    for (final c in p.classes) {
      final id = c.classeDefinicao.idClasse.toLowerCase();
      contagemEsperada[id] = (contagemEsperada[id] ?? 0) + c.nivel;
    }

    if (p.historicoClassesPorNivel.length == p.nivelPersonagem &&
        p.historicoClassesPorNivel.isNotEmpty) {
      final contagemAtual = <String, int>{};
      for (final id in p.historicoClassesPorNivel) {
        final norm = id.toLowerCase();
        contagemAtual[norm] = (contagemAtual[norm] ?? 0) + 1;
      }
      bool bate = contagemAtual.length == contagemEsperada.length;
      if (bate) {
        contagemEsperada.forEach((k, v) {
          if (contagemAtual[k] != v) bate = false;
        });
      }
      if (bate &&
          _normalizar(p.historicoClassesPorNivel.first) ==
              _normalizar(p.classes.first.classeDefinicao.idClasse)) {
        return List<String>.unmodifiable(p.historicoClassesPorNivel);
      }
    }

    // Reconstrução determinística a partir das classes registradas (preservando classes[0] no nível 1)
    final reconstruido = <String>[];
    for (final c in p.classes) {
      for (int i = 0; i < c.nivel; i++) {
        reconstruido.add(c.classeDefinicao.idClasse.toLowerCase());
      }
    }
    return List<String>.unmodifiable(reconstruido);
  }

  /// RF11 — Consulta estruturada da distribuição dos níveis do personagem entre suas classes.
  static ResumoDistribuicaoMulticlasse consultarDistribuicaoNiveis(
    Personagem p,
  ) {
    final nivelTotal = calcularNivelTotal(p);
    final patamar = identificarPatamar(p);
    final itens = <ItemDistribuicaoClasse>[];

    for (int i = 0; i < p.classes.length; i++) {
      final c = p.classes[i];
      itens.add(
        ItemDistribuicaoClasse(
          idClasse: c.classeDefinicao.idClasse,
          nomeClasse: c.classeDefinicao.nome,
          nivel: c.nivel,
          ehClasseInicial: i == 0,
          caminho: c.caminhoEscolhido?.nome,
        ),
      );
    }

    return ResumoDistribuicaoMulticlasse(
      nomePersonagem: p.nome,
      nivelTotal: nivelTotal,
      patamar: patamar,
      classes: itens,
    );
  }

  /// RF12 — Consulta a progressão passo a passo mantendo a distinção clara entre
  /// progressão geral do personagem (nível global 1..20, patamar) e progressão individual da classe.
  static List<RegistroProgressaoMulticlasse> consultarProgressaoPersonagem(
    Personagem p,
  ) {
    if (p.classes.isEmpty) return const [];

    final historico = normalizarHistoricoClasses(p);
    final mapaClasses = <String, ClasseDoPersonagem>{};
    final indiceOriginal = <String, int>{};
    for (int i = 0; i < p.classes.length; i++) {
      final key = _normalizar(p.classes[i].classeDefinicao.idClasse);
      mapaClasses[key] = p.classes[i];
      indiceOriginal[key] = i;
    }

    final contadorPorClasse = <String, int>{};
    final atributosJaSomadosPM = <String>{};
    final int con = p.getValorFinal('CON');
    final registros = <RegistroProgressaoMulticlasse>[];
    PatamarJogo? patamarAnterior;

    for (int idxGlobal = 0; idxGlobal < historico.length; idxGlobal++) {
      final nivelGlobal = idxGlobal + 1;
      final idKey = _normalizar(historico[idxGlobal]);
      final itemClasse = mapaClasses[idKey]!;
      final def = itemClasse.classeDefinicao;
      final ehClasseInicial = (indiceOriginal[idKey] == 0);

      final nivelNaClasse = (contadorPorClasse[idKey] ?? 0) + 1;
      contadorPorClasse[idKey] = nivelNaClasse;

      final patamarAtual = PatamarJogo.porNivel(nivelGlobal);
      final novoPatamar =
          patamarAnterior != null && patamarAtual != patamarAnterior;
      patamarAnterior = patamarAtual;

      // Características estritamente do nível individual daquela classe (RF05 / RN08 / RV07)
      final caracteristicas = obterCaracteristicasDoNivelIndividual(
        def,
        nivelNaClasse,
      );

      Poder? poderEscolhido;
      if (nivelNaClasse >= 2) {
        final idxPoder = nivelNaClasse - 2;
        if (idxPoder < itemClasse.poderesEscolhidos.length) {
          poderEscolhido = itemClasse.poderesEscolhidos[idxPoder];
        }
      }

      final int pvNoNivel = (ehClasseInicial && nivelNaClasse == 1)
          ? max(1, def.pvInicial + con)
          : max(1, def.pvPorNivel + con);

      int pmNoNivel = (ehClasseInicial && nivelNaClasse == 1)
          ? def.pmInicial
          : def.pmPorNivel;
      if (nivelNaClasse == 1) {
        final siglaAtrib = obterAtributoChavePmClasse(itemClasse);
        if (siglaAtrib != null && atributosJaSomadosPM.add(siglaAtrib)) {
          final mod = p.getValorFinal(siglaAtrib);
          if (mod > 0) pmNoNivel += mod;
        }
      }

      registros.add(
        RegistroProgressaoMulticlasse(
          nivelPersonagem: nivelGlobal,
          patamar: patamarAtual,
          novoPatamarAlcancado: novoPatamar,
          idClasse: def.idClasse,
          nomeClasse: def.nome,
          nivelIndividualClasse: nivelNaClasse,
          ehClasseInicial: ehClasseInicial,
          ehAquisicaoNovaMulticlasse: !ehClasseInicial && nivelNaClasse == 1,
          caminhoEscolhido: nivelNaClasse == 1
              ? itemClasse.caminhoEscolhido?.nome
              : null,
          caracteristicasClasse: caracteristicas,
          poderEscolhido: poderEscolhido,
          pvAdquiridosNoNivel: pvNoNivel,
          pmAdquiridosNoNivel: pmNoNivel,
        ),
      );
    }

    return registros;
  }

  /// Valida todas as Regras de Validação (RV01–RV07) sobre o estado de um personagem.
  static ResultadoValidacaoMulticlasse validarRegrasMulticlasse(Personagem p) {
    final violacoes = <ExcecaoValidacaoMulticlasse>[];

    // RV02: Nível individual de cada classe registrada deve ser inteiro positivo
    for (final c in p.classes) {
      if (c.nivel <= 0) {
        violacoes.add(
          ExcecaoValidacaoMulticlasse(
            'RV02',
            'A classe ${c.classeDefinicao.nome} possui nível inválido (${c.nivel}). Deve ser inteiro positivo.',
          ),
        );
      }
    }

    // RV03: Soma dos níveis individuais deve corresponder ao nível total
    final somaIndividual = p.classes.fold<int>(0, (s, c) => s + c.nivel);
    if (p.nivelPersonagem != somaIndividual) {
      violacoes.add(
        ExcecaoValidacaoMulticlasse(
          'RV03',
          'Soma dos níveis individuais ($somaIndividual) difere do nível total (${p.nivelPersonagem}).',
        ),
      );
    }

    // RV01: Nível máximo 20
    if (somaIndividual > nivelMaximoPersonagem) {
      violacoes.add(
        ExcecaoValidacaoMulticlasse(
          'RV01',
          'Nível total ($somaIndividual) ultrapassa o nível máximo de $nivelMaximoPersonagem.',
        ),
      );
    }

    // RV07: Nenhum poder de classe escolhido pode exigir nível superior ao nível individual daquela classe
    for (final c in p.classes) {
      for (final pod in c.poderesEscolhidos) {
        final ehGeral =
            pod.ehPoderTormenta ||
            pod.tipo?.toLowerCase() == 'poder_geral' ||
            (pod.categoria != null &&
                pod.categoria!.toLowerCase().startsWith('poder_'));
        if (!ehGeral && pod.nivelMinimo > c.nivel) {
          violacoes.add(
            ExcecaoValidacaoMulticlasse(
              'RV07',
              'Poder "${pod.nome}" exige nível ${pod.nivelMinimo} de ${c.classeDefinicao.nome}, mas o nível na classe é ${c.nivel}.',
            ),
          );
        }
      }
    }

    return ResultadoValidacaoMulticlasse(
      valido: violacoes.isEmpty,
      violacoes: violacoes,
    );
  }

  static String _normalizar(String s) {
    return s
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('â', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c');
  }
}
