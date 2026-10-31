import 'dart:math';

import '../entities/equipamento/arma.dart';
import '../entities/magia/magia.dart';
import '../entities/personagem/pericias.dart';
import '../entities/personagem/personagem.dart';
import '../entities/personagem/poder.dart';
import '../entities/personagem/proficiencias.dart';
import 'data_services/call_pericias.dart';
import 'motor_modificadores_service.dart';
import 'motor_multiclasse_service.dart';

/// Representa uma parcela nomeada de um cálculo de Tormenta 20 para exibição transparente na UI.
class ParcelaCalculo {
  final String rotulo;
  final int valor;
  final bool ehPenalidade;

  const ParcelaCalculo({
    required this.rotulo,
    required this.valor,
    this.ehPenalidade = false,
  });

  String get valorFormatado {
    if (ehPenalidade) {
      final absVal = valor.abs();
      return '-$absVal';
    }
    return valor >= 0 ? '+$valor' : '$valor';
  }
}

/// Detalhamento completo de uma perícia calculada no domínio.
class ComposicaoPericia {
  final Pericia pericia;
  final int metadeNivel;
  final int modAtributo;
  final bool ehTreinada;
  final bool ehTreinoFixoClasse;
  final int bonusTreino;
  final int bonusRacial;
  final int bonusDeclarativo;
  final int bonusOutros;
  final int bonusEfeitos;
  final int penalidadeArmaduraAplicada;
  final bool sofrePenalidadeArmadura;
  final bool bloqueadaSemTreino;
  final int total;

  const ComposicaoPericia({
    required this.pericia,
    required this.metadeNivel,
    required this.modAtributo,
    required this.ehTreinada,
    required this.ehTreinoFixoClasse,
    required this.bonusTreino,
    this.bonusRacial = 0,
    this.bonusDeclarativo = 0,
    required this.bonusOutros,
    required this.bonusEfeitos,
    required this.penalidadeArmaduraAplicada,
    required this.sofrePenalidadeArmadura,
    required this.bloqueadaSemTreino,
    required this.total,
  });

  String get totalFormatado => total >= 0 ? '+$total' : '$total';

  List<ParcelaCalculo> get parcelas {
    final lista = <ParcelaCalculo>[
      ParcelaCalculo(rotulo: '½ Nível', valor: metadeNivel),
      ParcelaCalculo(rotulo: pericia.atributoChave, valor: modAtributo),
    ];
    if (ehTreinada) {
      lista.add(ParcelaCalculo(rotulo: 'Treino', valor: bonusTreino));
    }
    if (bonusRacial != 0) {
      lista.add(ParcelaCalculo(rotulo: 'Racial', valor: bonusRacial));
    }
    if (bonusDeclarativo != 0) {
      lista.add(ParcelaCalculo(rotulo: 'Poderes/Itens', valor: bonusDeclarativo));
    }
    if (bonusOutros != 0) {
      lista.add(ParcelaCalculo(rotulo: 'Outros', valor: bonusOutros));
    }
    if (bonusEfeitos != 0) {
      lista.add(ParcelaCalculo(rotulo: 'Efeitos', valor: bonusEfeitos));
    }
    if (penalidadeArmaduraAplicada > 0) {
      lista.add(
        ParcelaCalculo(
          rotulo: 'Pen. Armadura',
          valor: penalidadeArmaduraAplicada,
          ehPenalidade: true,
        ),
      );
    }
    return lista;
  }

  /// Texto enxuto para subtítulo na linha da perícia (mostrando de onde vem cada bônus)
  String get resumoParcelas {
    return parcelas.map((p) => '${p.rotulo} ${p.valorFormatado}').join(' • ');
  }
}

/// Agrupamento de perícias por atributo-chave, ordenadas alfabeticamente.
class GrupoPericiasAtributo {
  final String siglaAtributo;
  final String nomeAtributo;
  final int valorAtributo;
  final List<ComposicaoPericia> pericias;

  const GrupoPericiasAtributo({
    required this.siglaAtributo,
    required this.nomeAtributo,
    required this.valorAtributo,
    required this.pericias,
  });

  String get valorAtributoFormatado =>
      valorAtributo >= 0 ? '+$valorAtributo' : '$valorAtributo';
}

/// Resultado imutável de uma rolagem de dados realizada no domínio.
class ResultadoRolagemDado {
  final String titulo;
  final String subtitulo;
  final int quantidadeDados;
  final int facesDado;
  final List<int> valoresDados;
  final List<ParcelaCalculo> parcelasFixas;
  final int modificadorSituacional;
  final bool bloqueadaSemTreino;

  const ResultadoRolagemDado({
    required this.titulo,
    this.subtitulo = '',
    this.quantidadeDados = 1,
    this.facesDado = 20,
    required this.valoresDados,
    this.parcelasFixas = const [],
    this.modificadorSituacional = 0,
    this.bloqueadaSemTreino = false,
  });

  int get somaDados => valoresDados.fold(0, (s, v) => s + v);

  int get somaParcelasFixas => parcelasFixas.fold(
    0,
    (soma, p) => soma + (p.ehPenalidade ? -p.valor.abs() : p.valor),
  );

  int get totalModificadores => somaParcelasFixas + modificadorSituacional;

  int get totalFinal => somaDados + totalModificadores;

  bool get ehCriticoNatural =>
      facesDado == 20 && quantidadeDados == 1 && somaDados == 20;

  bool get ehFalhaCriticaNatural =>
      facesDado == 20 && quantidadeDados == 1 && somaDados == 1;
}

/// Composição detalhada de Defesa e Redução de Dano Padrão.
class ComposicaoDefesa {
  final int base;
  final int modDestrezaOriginal;
  final int modDestrezaAplicado;
  final bool destrezaLimitadaPorArmaduraPesada;
  final int bonusArmadura;
  final String? nomeArmadura;
  final int bonusEscudo;
  final String? nomeEscudo;
  final int bonusRacialDefesa;
  final int bonusFormaSelvagem;
  final int bonusCompanheiro;
  final int bonusDeclarativoDefesa;
  final int outrosBonusDefesa;
  final int bonusEfeitos;
  final int defesaFinal;
  final int rdPadrao;
  final int rdFormaSelvagem;
  final int rdDeclarativa;
  final int rdEfeitos;
  final int rdTotal;
  final int penalidadeArmaduraTotal;
  final bool usaProtecaoSemProficiencia;

  const ComposicaoDefesa({
    this.base = 10,
    required this.modDestrezaOriginal,
    required this.modDestrezaAplicado,
    required this.destrezaLimitadaPorArmaduraPesada,
    required this.bonusArmadura,
    this.nomeArmadura,
    required this.bonusEscudo,
    this.nomeEscudo,
    this.bonusRacialDefesa = 0,
    required this.bonusFormaSelvagem,
    required this.bonusCompanheiro,
    this.bonusDeclarativoDefesa = 0,
    required this.outrosBonusDefesa,
    required this.bonusEfeitos,
    required this.defesaFinal,
    required this.rdPadrao,
    required this.rdFormaSelvagem,
    this.rdDeclarativa = 0,
    required this.rdEfeitos,
    required this.rdTotal,
    required this.penalidadeArmaduraTotal,
    required this.usaProtecaoSemProficiencia,
  });

  List<ParcelaCalculo> get parcelasDefesa {
    final lista = <ParcelaCalculo>[
      ParcelaCalculo(rotulo: 'Base', valor: base),
      ParcelaCalculo(
        rotulo: destrezaLimitadaPorArmaduraPesada ? 'DES (Pesada)' : 'DES',
        valor: modDestrezaAplicado,
      ),
    ];
    if (bonusArmadura != 0) {
      lista.add(ParcelaCalculo(rotulo: 'Armadura', valor: bonusArmadura));
    }
    if (bonusEscudo != 0) {
      lista.add(ParcelaCalculo(rotulo: 'Escudo', valor: bonusEscudo));
    }
    if (bonusRacialDefesa != 0) {
      lista.add(ParcelaCalculo(rotulo: 'Racial', valor: bonusRacialDefesa));
    }
    if (bonusFormaSelvagem != 0) {
      lista.add(
        ParcelaCalculo(rotulo: 'Forma Selvagem', valor: bonusFormaSelvagem),
      );
    }
    if (bonusCompanheiro != 0) {
      lista.add(ParcelaCalculo(rotulo: 'Parceiro', valor: bonusCompanheiro));
    }
    if (bonusDeclarativoDefesa != 0) {
      lista.add(
        ParcelaCalculo(rotulo: 'Poderes/Itens', valor: bonusDeclarativoDefesa),
      );
    }
    if (outrosBonusDefesa != 0) {
      lista.add(ParcelaCalculo(rotulo: 'Outros', valor: outrosBonusDefesa));
    }
    if (bonusEfeitos != 0) {
      lista.add(ParcelaCalculo(rotulo: 'Efeitos', valor: bonusEfeitos));
    }
    return lista;
  }
}

/// Composição do Teste de Resistência (CD) das magias do personagem.
class ComposicaoCDMagia {
  final String siglaAtributo;
  final int base;
  final int metadeNivel;
  final int modAtributo;
  final int outrosBonus;
  final int cdTotal;

  const ComposicaoCDMagia({
    required this.siglaAtributo,
    this.base = 10,
    required this.metadeNivel,
    required this.modAtributo,
    required this.outrosBonus,
    required this.cdTotal,
  });

  String get formulaFormatada {
    final modStr = modAtributo >= 0 ? '+$modAtributo' : '$modAtributo';
    final outrosStr = outrosBonus == 0
        ? ''
        : (outrosBonus > 0 ? ' + $outrosBonus (Outros)' : ' - ${outrosBonus.abs()} (Outros)');
    return '10 + ½ Nível (+$metadeNivel) + $siglaAtributo ($modStr)$outrosStr';
  }
}

/// Resultado seguro da tentativa de gasto de Pontos de Mana (PM).
class ResultadoGastoPM {
  final bool sucesso;
  final int custoAplicado;
  final String? mensagemErro;
  final Personagem personagemAtualizado;

  const ResultadoGastoPM({
    required this.sucesso,
    required this.custoAplicado,
    this.mensagemErro,
    required this.personagemAtualizado,
  });
}

/// Registro sequencial de um nível de personagem para revisão do jogador/mestre (RF12).
/// Mantém distinção explícita entre progressão geral do personagem e progressão individual da classe.
class EtapaProgressaoNivel {
  final int nivelPersonagem;
  final PatamarJogo patamar;
  final bool novoPatamarAlcancado;
  final String nomeClasse;
  final int nivelNaClasse;
  final bool ehClasseInicial;
  final bool ehAquisicaoNovaMulticlasse;
  final String? caminhoEscolhido;
  final List<String> habilidadesDeClasse;
  final Poder? poderEscolhido;
  final int pvAdquiridos;
  final int pmAdquiridos;
  final List<String> marcosIniciais;
  final String notaOuDistincao;

  const EtapaProgressaoNivel({
    required this.nivelPersonagem,
    this.patamar = PatamarJogo.iniciante,
    this.novoPatamarAlcancado = false,
    required this.nomeClasse,
    required this.nivelNaClasse,
    this.ehClasseInicial = true,
    this.ehAquisicaoNovaMulticlasse = false,
    this.caminhoEscolhido,
    this.habilidadesDeClasse = const [],
    this.poderEscolhido,
    this.pvAdquiridos = 0,
    this.pmAdquiridos = 0,
    this.marcosIniciais = const [],
    this.notaOuDistincao = '',
  });
}

/// Agrupamento de proficiências, sentidos especiais, deslocamentos e RDs diversas.
class ResumoProficienciasESentidos {
  final List<String> proficienciasClasse;
  final List<String> proficienciasExtras;
  final String deslocamentoBase;
  final List<String> sentidosEDeslocamentosEspeciais;
  final List<String> rdsDiversas;

  const ResumoProficienciasESentidos({
    required this.proficienciasClasse,
    required this.proficienciasExtras,
    required this.deslocamentoBase,
    required this.sentidosEDeslocamentosEspeciais,
    required this.rdsDiversas,
  });
}

/// Estrutura preparatória de domínio para o futuro módulo de Combate (ataque e dano em 1 toque).
class PreviewAtaqueArma {
  final Arma arma;
  final ComposicaoPericia composicaoPericiaAtaque;
  final bool temProficienciaNaArma;
  final int penalidadeNaoProficiencia;
  final int bonusAtaqueFinal;
  final int bonusDanoAtributo;
  final String formulaDanoCompleta;
  final int margemAmeaca;
  final int multiplicadorCritico;
  final String criticoFormatado;

  const PreviewAtaqueArma({
    required this.arma,
    required this.composicaoPericiaAtaque,
    required this.temProficienciaNaArma,
    required this.penalidadeNaoProficiencia,
    required this.bonusAtaqueFinal,
    required this.bonusDanoAtributo,
    required this.formulaDanoCompleta,
    required this.margemAmeaca,
    required this.multiplicadorCritico,
    required this.criticoFormatado,
  });
}

/// Serviço puro de domínio que centraliza todos os cálculos, decomposições de bônus
/// e rolagens da ficha de Tormenta 20 (sem nenhuma dependência de UI/Widgets).
class CalculoFichaService {
  static const List<String> ordemAtributos = [
    'FOR',
    'DES',
    'CON',
    'INT',
    'SAB',
    'CAR',
  ];

  static const Map<String, String> nomesAtributos = {
    'FOR': 'Força',
    'DES': 'Destreza',
    'CON': 'Constituição',
    'INT': 'Inteligência',
    'SAB': 'Sabedoria',
    'CAR': 'Carisma',
  };

  /// Decompõe todas as parcelas que formam o valor final de uma perícia.
  static ComposicaoPericia detalharPericia(
    Personagem p,
    String periciaKey, {
    Pericia? periciaObjeto,
    int? penalidadeArmaduraCustom,
  }) {
    final pericia = periciaObjeto ?? BancoDePericias.getByKey(periciaKey);
    final metadeNivel = (p.nivelPersonagem / 2).floor();
    final modAtributo = p.getValorFinal(pericia.atributoChave);
    final ehTreinoFixo = p.ehPericiaTreinadaFixaDeClasse(pericia.key);
    final ehTreinada = p.ehPericiaTreinada(pericia.key);
    final bonusTreino = ehTreinada ? p.bonusTreinamento : 0;
    final bonusRacial = p.bonusRacialPericia(pericia.key);
    final bonusDeclarativo = p.bonusDeclarativoPericia(pericia.key);
    final bonusOutros = p.obterOutrosBonusPericia(pericia.key);
    final bonusEfeitos = p.bonusEfeitosPericias;

    final sofrePenalidade = p.periciaSofrePenalidade(pericia);
    final penalidade = penalidadeArmaduraCustom ?? p.penalidadeArmaduraTotal;
    final penalidadeAplicada = sofrePenalidade ? penalidade : 0;

    final total = p.getValorPericia(
      pericia.key,
      penalidadeArmaduraCustom: penalidade,
    );
    final bloqueada = pericia.somenteTreinada && !ehTreinada;

    return ComposicaoPericia(
      pericia: pericia,
      metadeNivel: metadeNivel,
      modAtributo: modAtributo,
      ehTreinada: ehTreinada,
      ehTreinoFixoClasse: ehTreinoFixo,
      bonusTreino: bonusTreino,
      bonusRacial: bonusRacial,
      bonusDeclarativo: bonusDeclarativo,
      bonusOutros: bonusOutros,
      bonusEfeitos: bonusEfeitos,
      penalidadeArmaduraAplicada: penalidadeAplicada,
      sofrePenalidadeArmadura: pericia.penalidadeArmadura,
      bloqueadaSemTreino: bloqueada,
      total: total,
    );
  }

  /// Agrupa todas as perícias do jogo por atributo (FOR..CAR) e em ordem alfabética dentro de cada grupo.
  static List<GrupoPericiasAtributo> agruparPericiasPorAtributo(
    Personagem p, {
    List<Pericia>? catalogoCustom,
    bool apenasTreinadas = false,
    String filtroBusca = '',
    int? penalidadeArmaduraCustom,
  }) {
    final catalogo = catalogoCustom ?? BancoDePericias.todas;
    final termo = _normalizarOrdenacao(filtroBusca);
    final penalidadeArmadura =
        penalidadeArmaduraCustom ?? p.penalidadeArmaduraTotal;

    final cacheNorm = <String, String>{};
    String norm(String s) =>
        cacheNorm.putIfAbsent(s, () => _normalizarOrdenacao(s));

    final grupos = <GrupoPericiasAtributo>[];
    for (final sigla in ordemAtributos) {
      final periciasDoAtributo = catalogo
          .where((per) => per.atributoChave.toUpperCase() == sigla)
          .map((per) => detalharPericia(
                p,
                per.key,
                periciaObjeto: per,
                penalidadeArmaduraCustom: penalidadeArmadura,
              ))
          .where((comp) {
            if (apenasTreinadas && !comp.ehTreinada) return false;
            if (termo.isNotEmpty) {
              final nomeNorm = norm(comp.pericia.label);
              final keyNorm = norm(comp.pericia.key);
              return nomeNorm.contains(termo) || keyNorm.contains(termo);
            }
            return true;
          })
          .toList();

      periciasDoAtributo.sort(
        (a, b) => norm(a.pericia.label).compareTo(norm(b.pericia.label)),
      );

      if (periciasDoAtributo.isNotEmpty) {
        grupos.add(
          GrupoPericiasAtributo(
            siglaAtributo: sigla,
            nomeAtributo: nomesAtributos[sigla] ?? sigla,
            valorAtributo: p.getValorFinal(sigla),
            pericias: periciasDoAtributo,
          ),
        );
      }
    }
    return grupos;
  }

  /// Rola 1d20 para uma perícia com todas as parcelas detalhadas.
  static ResultadoRolagemDado rolarPericia(
    Personagem p,
    String periciaKey, {
    int modificadorSituacional = 0,
    Random? random,
    int? valorDadoFixoParaTeste,
  }) {
    final comp = detalharPericia(p, periciaKey);
    final rng = random ?? Random();
    final d20 = valorDadoFixoParaTeste ?? (rng.nextInt(20) + 1);

    return ResultadoRolagemDado(
      titulo: comp.pericia.label,
      subtitulo:
          'Teste de Perícia (${comp.pericia.atributoChave})${comp.ehTreinada ? " • Treinada" : ""}',
      quantidadeDados: 1,
      facesDado: 20,
      valoresDados: [d20],
      parcelasFixas: comp.parcelas,
      modificadorSituacional: modificadorSituacional,
      bloqueadaSemTreino: comp.bloqueadaSemTreino,
    );
  }

  /// Rola 1d20 puro de atributo (ex: Teste de Força, Constituição contra Sangramento).
  static ResultadoRolagemDado rolarAtributo(
    Personagem p,
    String siglaAtributo, {
    int modificadorSituacional = 0,
    Random? random,
    int? valorDadoFixoParaTeste,
  }) {
    final sigla = siglaAtributo.toUpperCase();
    final mod = p.getValorFinal(sigla);
    final rng = random ?? Random();
    final d20 = valorDadoFixoParaTeste ?? (rng.nextInt(20) + 1);

    return ResultadoRolagemDado(
      titulo: nomesAtributos[sigla] ?? sigla,
      subtitulo: 'Teste de Atributo ($sigla)',
      quantidadeDados: 1,
      facesDado: 20,
      valoresDados: [d20],
      parcelasFixas: [ParcelaCalculo(rotulo: sigla, valor: mod)],
      modificadorSituacional: modificadorSituacional,
    );
  }

  /// Decompõe a Defesa e a Redução de Dano Padrão do personagem.
  static ComposicaoDefesa detalharDefesaERd(Personagem p) {
    final modDesOrig = p.getValorFinal('DES');
    final modDesAplicado = p.usaArmaduraPesada
        ? MotorModificadoresService.calcularBonusDestrezaDelicadaArmaduraPesada(
            p,
          )
        : modDesOrig;
    final rdForma = p.estaEmFormaSelvagem ? p.formaSelvagemAtiva!.rd : 0;

    return ComposicaoDefesa(
      modDestrezaOriginal: modDesOrig,
      modDestrezaAplicado: modDesAplicado,
      destrezaLimitadaPorArmaduraPesada: p.usaArmaduraPesada,
      bonusArmadura: p.bonusArmadura,
      nomeArmadura: p.armaduraEquipada?.nome,
      bonusEscudo: p.bonusEscudo,
      nomeEscudo: p.escudoEquipado?.nome,
      bonusRacialDefesa: p.bonusRacialDefesa,
      bonusFormaSelvagem: p.bonusFormaDefesa,
      bonusCompanheiro: p.bonusCompanheiroDefesa,
      bonusDeclarativoDefesa: p.bonusDeclarativoDefesa,
      outrosBonusDefesa: p.outrosBonusDefesa,
      bonusEfeitos: p.bonusEfeitosDefesa,
      defesaFinal: p.defesaFinal,
      rdPadrao: p.rdPadrao,
      rdFormaSelvagem: rdForma,
      rdDeclarativa: p.bonusDeclarativoRd,
      rdEfeitos: p.bonusEfeitosRd,
      rdTotal: p.rdTotal,
      penalidadeArmaduraTotal: p.penalidadeArmaduraTotal,
      usaProtecaoSemProficiencia: p.usaProtecaoSemProficiencia,
    );
  }

  /// Calcula a CD de Teste de Resistência de Magias (10 + ½ nível + Atributo-chave + Outros + Itens/Poderes).
  static ComposicaoCDMagia detalharCDMagia(
    Personagem p, {
    String? atributoOverride,
  }) {
    final sigla = (atributoOverride ?? p.atributoChaveMagiaPrincipal ?? 'INT')
        .toUpperCase();
    final metadeNivel = (p.nivelPersonagem / 2).floor();
    final modAtrib = p.getValorFinal(sigla);
    final outros =
        p.outrosBonusCDMagia +
        MotorModificadoresService.calcularBonusDeclarativoCDMagia(p);
    final cd = 10 + metadeNivel + modAtrib + outros;

    return ComposicaoCDMagia(
      siglaAtributo: sigla,
      metadeNivel: metadeNivel,
      modAtributo: modAtrib,
      outrosBonus: outros,
      cdTotal: cd,
    );
  }

  /// Custo base de PM por círculo de magia em Tormenta 20 (1º=1, 2º=3, 3º=6, 4º=10, 5º=15).
  static int custoBaseMagiaPorCirculo(int circulo) {
    return switch (circulo) {
      1 => 1,
      2 => 3,
      3 => 6,
      4 => 10,
      5 => 15,
      _ => 1,
    };
  }

  /// Calcula o custo final em PM de uma magia considerando os aprimoramentos selecionados.
  static int calcularCustoMagia(
    Magia magia,
    Iterable<AprimoramentoMagia> aprimoramentosSelecionados,
  ) {
    final lista = aprimoramentosSelecionados.toList();
    if (lista.isNotEmpty && lista.every((a) => a.isTruque)) {
      return 0;
    }
    final base = custoBaseMagiaPorCirculo(magia.circulo);
    final extra = lista
        .where((a) => !a.isTruque)
        .fold(0, (soma, a) => soma + a.custoAdicionalPM);
    return base + extra;
  }

  /// Valida e deduz Pontos de Mana (PM), impedindo PM negativo ou conjuração sob punição divina.
  static ResultadoGastoPM tentarGastarPM(Personagem p, int custoPM) {
    if (custoPM < 0) {
      return ResultadoGastoPM(
        sucesso: false,
        custoAplicado: 0,
        mensagemErro: 'O custo de PM não pode ser negativo.',
        personagemAtualizado: p,
      );
    }
    if (p.punicaoDivinaAtiva && custoPM > 0) {
      return ResultadoGastoPM(
        sucesso: false,
        custoAplicado: 0,
        mensagemErro:
            'Punição Divina ativa: seus Pontos de Mana estão bloqueados até realizar penitência.',
        personagemAtualizado: p,
      );
    }
    if (custoPM == 0) {
      return ResultadoGastoPM(
        sucesso: true,
        custoAplicado: 0,
        personagemAtualizado: p,
      );
    }
    if (p.pmAtual < custoPM) {
      return ResultadoGastoPM(
        sucesso: false,
        custoAplicado: 0,
        mensagemErro:
            'PM insuficiente! Necessário $custoPM PM, disponível ${p.pmAtual} PM.',
        personagemAtualizado: p,
      );
    }

    final novoPM = (p.pmAtual - custoPM).clamp(0, p.pmTotal);
    return ResultadoGastoPM(
      sucesso: true,
      custoAplicado: custoPM,
      personagemAtualizado: p.copyWith(pmAtual: novoPM),
    );
  }

  /// Constrói a linha do tempo sequencial nível a nível para a aba de Progressão de Personagem (RF12).
  /// Distingue progressão geral do personagem (nível total, patamar) da progressão individual de cada classe.
  static List<EtapaProgressaoNivel> gerarTrilhaProgressao(Personagem p) {
    if (p.classes.isEmpty) return const [];

    final registros = MotorMulticlasseService.consultarProgressaoPersonagem(p);
    final etapas = <EtapaProgressaoNivel>[];

    for (final reg in registros) {
      final marcosIniciais = <String>[];
      if (reg.nivelPersonagem == 1) {
        if (p.raca != null) marcosIniciais.add('Raça: ${p.raca!.nome}');
        if (p.origem != null) marcosIniciais.add('Origem: ${p.origem!.nome}');
        if (p.divindade != null) {
          marcosIniciais.add('Devoção: ${p.divindade!.nome}');
        }
        for (final pg in p.poderesGerais) {
          marcosIniciais.add('Benefício Inicial: ${pg.nome}');
        }
        if (p.poderTormentaDeformidade != null) {
          marcosIniciais.add(
            'Deformidade (Tormenta): ${p.poderTormentaDeformidade!.nome}',
          );
        }
      }

      etapas.add(
        EtapaProgressaoNivel(
          nivelPersonagem: reg.nivelPersonagem,
          patamar: reg.patamar,
          novoPatamarAlcancado: reg.novoPatamarAlcancado,
          nomeClasse: reg.nomeClasse,
          nivelNaClasse: reg.nivelIndividualClasse,
          ehClasseInicial: reg.ehClasseInicial,
          ehAquisicaoNovaMulticlasse: reg.ehAquisicaoNovaMulticlasse,
          caminhoEscolhido: reg.caminhoEscolhido,
          habilidadesDeClasse: reg.caracteristicasClasse,
          poderEscolhido: reg.poderEscolhido,
          pvAdquiridos: reg.pvAdquiridosNoNivel,
          pmAdquiridos: reg.pmAdquiridosNoNivel,
          marcosIniciais: marcosIniciais,
          notaOuDistincao: p.notasProgressaoPorNivel[reg.nivelPersonagem] ?? '',
        ),
      );
    }

    return etapas;
  }

  /// Extrai proficiências de classe/extras, sentidos especiais, deslocamento e RDs diversas.
  /// RF09 / RN07 / RV06: Proficiências iniciais automáticas provêm APENAS da classe inicial (`classes[0]`)!
  static ResumoProficienciasESentidos extrairProficienciasESentidos(
    Personagem p,
  ) {
    final profsSet = <String>{};
    for (final prof
        in MotorMulticlasseService.obterProficienciasIniciaisClasseConcedidas(
          p,
        )) {
      profsSet.add(switch (prof) {
        TipoProficiencia.armasSimples => 'Armas Simples',
        TipoProficiencia.armasMarciais => 'Armas Marciais',
        TipoProficiencia.armadurasLeves => 'Armaduras Leves',
        TipoProficiencia.armadurasPesadas => 'Armaduras Pesadas',
        TipoProficiencia.escudos => 'Escudos',
      });
    }

    // Deslocamento padrão e efetivo do personagem (considerando bônus raciais e armadura/sobrecarga)
    final descMetros = p.deslocamentoEfetivoMetros;
    final descQuadrados = (descMetros / 1.5).round();
    String deslocamento = '${descMetros}m ($descQuadrados quadrados)';
    if (p.deslocamentoBaseMetros > descMetros) {
      deslocamento = '$deslocamento (-3m armadura pesada/sobrecarga)';
    }

    // Heurística de sentidos, deslocamentos especiais e resistências em habilidades raciais/poderes
    final sentidos = <String>[];
    final termosChave = [
      'visão no escuro',
      'visão na penumbra',
      'faro',
      'escalada',
      'natação',
      'voo',
      'imunidade',
      'resistência',
      'redução de dano',
      'anfíbio',
    ];

    if (p.raca != null) {
      p.raca!.habilidadesRaca.forEach((nome, desc) {
        final combinado = '${nome.toLowerCase()} ${desc.toLowerCase()}';
        if (termosChave.any((t) => combinado.contains(t))) {
          sentidos.add('$nome: $desc');
        }
      });
    }

    for (final pod in MotorModificadoresService.obterTodosPoderesAtivos(p)) {
      final combinado =
          '${pod.nome.toLowerCase()} ${pod.descricao.toLowerCase()}';
      if (termosChave.any((t) => combinado.contains(t))) {
        sentidos.add('${pod.nome}: ${pod.descricao}');
      }
    }

    return ResumoProficienciasESentidos(
      proficienciasClasse: profsSet.toList(),
      proficienciasExtras: p.proficienciasExtras,
      deslocamentoBase: deslocamento,
      sentidosEDeslocamentosEspeciais: sentidos,
      rdsDiversas: p.rdsDiversas,
    );
  }

  /// ADIANTAMENTO DE DOMÍNIO PARA COMBATE FUTURO:
  /// Prepara o cálculo de ataque, proficiência, margem de ameaça e fórmula de dano de uma arma,
  /// considerando melhorias, encantos e poderes como Acuidade com Arma.
  static PreviewAtaqueArma prepararPreviewAtaqueArma(Personagem p, Arma arma) {
    final compAtaque = detalharPericia(p, arma.periciaAtaque);
    final temProf = switch (arma.proficiencia) {
      ProficienciaArma.simples => p.temProficienciaSimples || p.classes.isEmpty,
      ProficienciaArma.marcial => p.temProficienciaMarcial,
      ProficienciaArma.exotica => p.proficienciasExtras.any(
        (x) => x.toLowerCase().contains(arma.nome.toLowerCase()),
      ),
      ProficienciaArma.fogo => p.proficienciasExtras.any(
        (x) => x.toLowerCase().contains('fogo'),
      ),
    };

    final penNaoProf = temProf ? 0 : -2;
    final usaAcuidade =
        MotorModificadoresService.possuiPoder(p, 'acuidade_com_arma') &&
        (arma.empunhadura == EmpunhaduraArma.leve ||
            arma.ehAgil ||
            arma.proposito == PropositoArma.arremesso);
    final diffAcuidadeAtaque =
        (usaAcuidade &&
                arma.ehCorpoACorpo &&
                p.getValorFinal('DES') > p.getValorFinal('FOR'))
            ? (p.getValorFinal('DES') - p.getValorFinal('FOR'))
            : 0;

    final bonusAtaque =
        compAtaque.total +
        penNaoProf +
        arma.bonusAtaqueMelhorias +
        diffAcuidadeAtaque;

    int bonusDanoAtrib = 0;
    if (arma.somaForcaAoDano) {
      bonusDanoAtrib = usaAcuidade
          ? max(p.getValorFinal('FOR'), p.getValorFinal('DES'))
          : p.getValorFinal('FOR');
    }
    final bonusDanoTotal = bonusDanoAtrib + arma.bonusDanoMelhorias;
    final sufixoDano = bonusDanoTotal == 0
        ? ''
        : (bonusDanoTotal > 0 ? '+$bonusDanoTotal' : '$bonusDanoTotal');

    return PreviewAtaqueArma(
      arma: arma,
      composicaoPericiaAtaque: compAtaque,
      temProficienciaNaArma: temProf,
      penalidadeNaoProficiencia: penNaoProf,
      bonusAtaqueFinal: bonusAtaque,
      bonusDanoAtributo: bonusDanoTotal,
      formulaDanoCompleta:
          '${arma.danoEfetivo}$sufixoDano (${arma.tipoDano.label})',
      margemAmeaca: arma.margemAmeacaEfetiva,
      multiplicadorCritico: arma.multiplicadorCriticoEfetivo,
      criticoFormatado: arma.criticoFormatado,
    );
  }

  static final _regexA = RegExp(r'[áàâãä]');
  static final _regexE = RegExp(r'[éèêë]');
  static final _regexI = RegExp(r'[íìîï]');
  static final _regexO = RegExp(r'[óòôõö]');
  static final _regexU = RegExp(r'[úùûü]');

  static String _normalizarOrdenacao(String texto) {
    return texto
        .toLowerCase()
        .trim()
        .replaceAll(_regexA, 'a')
        .replaceAll(_regexE, 'e')
        .replaceAll(_regexI, 'i')
        .replaceAll(_regexO, 'o')
        .replaceAll(_regexU, 'u')
        .replaceAll('ç', 'c');
  }
}
