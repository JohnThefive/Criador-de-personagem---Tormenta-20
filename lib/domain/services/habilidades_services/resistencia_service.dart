import 'dart:math';

import 'package:t20_creator/domain/entities/combate/tipo_acao.dart';
import 'package:t20_creator/domain/entities/habilidades/modelos_habilidade_duracao.dart';
import 'package:t20_creator/domain/entities/testes/configuracoes_mesa_t20.dart';
import 'package:t20_creator/domain/entities/testes/modelos_teste_t20.dart';
import 'package:t20_creator/domain/services/habilidades_services/imunidade_service.dart';
import 'package:t20_creator/domain/services/habilidades_services/relogio_e_cena_service.dart';
import 'package:t20_creator/domain/services/testes_services/i_rng.dart';
import 'package:t20_creator/domain/services/testes_services/motor_testes_service.dart';

/// R50–R56: Serviço puro de Testes de Resistência, interação com Objetos e Desacreditar Ilusões.
class ResistenciaService {
  final IRng _rng;
  final MotorTestesService motorTestes;
  final ImunidadeService imunidadeService;
  final ConfiguracoesMesaT20 configuracoes;

  ResistenciaService({
    required IRng rng,
    MotorTestesService? motorTestes,
    ImunidadeService? imunidadeService,
    this.configuracoes = const ConfiguracoesMesaT20(),
  })  : _rng = rng,
        motorTestes = motorTestes ??
            MotorTestesService(rng: rng, configuracoes: configuracoes),
        imunidadeService = imunidadeService ??
            ImunidadeService(configuracoes: configuracoes);

  /// R51 (Caso de Borda 1): Calcula a CD oficial de resistência do Tormenta 20:
  /// `CD = 10 + floor(nivelTotal / 2) + modificador do atributo`.
  int calcularCdResistencia({
    required int nivelTotal,
    required int modAtributo,
  }) {
    final metadeNivel = (nivelTotal / 2).floor();
    return 10 + metadeNivel + modAtributo;
  }

  /// R51: Extrai o modificador de atributo para a CD de uma habilidade ou magia.
  /// Para magias (`ehMagia == true`), prioriza o atributo-chave (`modAtributoChave`) ou `atributoCD`.
  int obterModificadorAtributoParaCd({
    required Habilidade habilidade,
    int? modAtributoChave,
    Map<String, int> atributos = const {},
  }) {
    if (habilidade.ehMagia && modAtributoChave != null) {
      return modAtributoChave;
    }
    if (habilidade.atributoCD != null) {
      final key = habilidade.atributoCD!.trim().toLowerCase();
      return atributos[key] ?? modAtributoChave ?? 0;
    }
    return modAtributoChave ?? 0;
  }

  /// R53 (Caso de Borda 3): Aplica redução de METADE (arredonda para baixo, mínimo 0).
  int aplicarReducaoMetade(int valorOriginal) {
    if (valorOriginal <= 0) return 0;
    return (valorOriginal / 2).floor();
  }

  /// R50–R54: Resolve o teste de resistência para uma Criatura contra a CD.
  ResultadoResistencia resolverResistenciaCriatura({
    required Criatura criatura,
    required Habilidade habilidade,
    required int cdResistencia,
    List<ModificadorAplicado> modificadoresExtras = const [],
    int? d20Forcado, // Para testes determinísticos diretos
  }) {
    final d20 = d20Forcado ?? _rng.rolarD20();

    // R54 (Caso de Borda 11): Se a habilidade usa teste de perícia para resistir
    if (habilidade.resistePericia != null) {
      final configPericia = habilidade.resistePericia!;
      final cdEfetiva = configPericia.cd ?? cdResistencia;

      // Sucesso / Falha automática por 20 e 1 natural (R3 / Caso 4)
      final nat20 = d20 == 20 && configuracoes.nat20SucessoAutomaticoContraCd;
      final nat1 = d20 == 1 && configuracoes.nat1FalhaAutomaticaContraCd;

      final bonusPericia = criatura.bonusResistencia
          .paraTipo(TipoResistencia.reflexos); // base fallback
      final somaMods = modificadoresExtras
          .where((m) => m.aplicado)
          .fold<int>(0, (s, m) => s + m.valor);
      final total = d20 + bonusPericia + somaMods;

      final passou = nat20 ? true : (nat1 ? false : total >= cdEfetiva);
      final resultadoFinal = passou
          ? (habilidade.resistencia?.resultado ??
              TipoResultadoResistencia.anula)
          : TipoResultadoResistencia.falha;

      final log =
          '${criatura.nome} resiste com ${configPericia.pericia}: d20 ($d20)${nat20 ? " [20 NATURAL]" : (nat1 ? " [1 NATURAL]" : "")} + mod ($bonusPericia) = $total vs CD $cdEfetiva → ${passou ? "SUCESSO (${resultadoFinal.name.toUpperCase()})" : "FALHA (COMPLETO)"}.';

      return ResultadoResistencia(
        alvoId: criatura.id,
        pericia: configPericia.pericia,
        cd: cdEfetiva,
        d20: d20,
        total: total,
        sucesso: passou,
        resultadoAplicado: resultadoFinal,
        sucessoAutomatico: nat20,
        falhaAutomatica: nat1,
        log: log,
      );
    }

    // Resistência padrão (Fortitude, Reflexos, Vontade)
    final tipoRes =
        habilidade.resistencia?.tipo ?? TipoResistencia.fortitude;
    final bonusBase = criatura.bonusResistencia.paraTipo(tipoRes);
    final somaMods = modificadoresExtras
        .where((m) => m.aplicado)
        .fold<int>(0, (s, m) => s + m.valor);
    final total = d20 + bonusBase + somaMods;

    // R3 (Caso de Borda 4): 20 natural passa e 1 natural falha mesmo contra a CD
    final nat20 = d20 == 20 && configuracoes.nat20SucessoAutomaticoContraCd;
    final nat1 = d20 == 1 && configuracoes.nat1FalhaAutomaticaContraCd;

    final passou = nat20 ? true : (nat1 ? false : total >= cdResistencia);
    final resultadoFinal = passou
        ? (habilidade.resistencia?.resultado ??
            TipoResultadoResistencia.anula)
        : TipoResultadoResistencia.falha;

    final log =
        '${criatura.nome} resiste com ${tipoRes.name.toUpperCase()}: d20 ($d20)${nat20 ? " [20 NATURAL]" : (nat1 ? " [1 NATURAL]" : "")} + bônus ($bonusBase) = $total vs CD $cdResistencia → ${passou ? "SUCESSO (${resultadoFinal.name.toUpperCase()})" : "FALHA (COMPLETO)"}.';

    return ResultadoResistencia(
      alvoId: criatura.id,
      tipo: tipoRes,
      cd: cdResistencia,
      d20: d20,
      total: total,
      sucesso: passou,
      resultadoAplicado: resultadoFinal,
      sucessoAutomatico: nat20,
      falhaAutomatica: nat1,
      log: log,
    );
  }

  /// R56 (Casos de Borda 5 e 6): Resolve a resistência de um Objeto/Item.
  /// - Item mundano solto: falha automática (sem rolagem).
  /// - Item mundano carregado: usa o bônus de resistência do portador.
  /// - Item mágico: sempre pode testar, usando o MAIOR entre o bônus próprio e o do portador.
  ResultadoResistencia resolverResistenciaObjeto({
    required ItemObjeto item,
    required Habilidade habilidade,
    required int cdResistencia,
    Criatura? portador,
    int? d20Forcado,
  }) {
    final tipoRes =
        habilidade.resistencia?.tipo ?? TipoResistencia.reflexos;

    // Item mundano solto: falha automática (Caso de Borda 5)
    if (!item.magico && item.estaSolto) {
      return ResultadoResistencia(
        alvoId: item.id,
        tipo: tipoRes,
        cd: cdResistencia,
        total: 0,
        sucesso: false,
        resultadoAplicado: TipoResultadoResistencia.falha,
        falhaAutomatica: true,
        log:
            'Item mundano solto "${item.nome}" falha automaticamente no teste de resistência.',
      );
    }

    // Determina o bônus efetivo do objeto
    final bonusPortador =
        portador != null ? portador.bonusResistencia.paraTipo(tipoRes) : 0;

    final int bonusEfetivo;
    if (item.magico) {
      // Item mágico: maior entre o bônus próprio e o do portador (R56 / Caso 5)
      bonusEfetivo = item.estaCarregado
          ? max(item.bonusResistencia, bonusPortador)
          : item.bonusResistencia;
    } else {
      // Item mundano carregado: usa o bônus do portador (R56 / Caso 5)
      bonusEfetivo = bonusPortador;
    }

    final d20 = d20Forcado ?? _rng.rolarD20();
    final nat20 = d20 == 20 && configuracoes.nat20SucessoAutomaticoContraCd;
    final nat1 = d20 == 1 && configuracoes.nat1FalhaAutomaticaContraCd;

    final total = d20 + bonusEfetivo;
    final passou = nat20 ? true : (nat1 ? false : total >= cdResistencia);
    final resultadoFinal = passou
        ? (habilidade.resistencia?.resultado ??
            TipoResultadoResistencia.anula)
        : TipoResultadoResistencia.falha;

    final log =
        'Objeto "${item.nome}" (${item.magico ? "mágico" : "carregado"}) resiste: d20 ($d20) + mod ($bonusEfetivo) = $total vs CD $cdResistencia → ${passou ? "SUCESSO (${resultadoFinal.name.toUpperCase()})" : "FALHA (COMPLETO)"}.';

    return ResultadoResistencia(
      alvoId: item.id,
      tipo: tipoRes,
      cd: cdResistencia,
      d20: d20,
      total: total,
      sucesso: passou,
      resultadoAplicado: resultadoFinal,
      sucessoAutomatico: nat20,
      falhaAutomatica: nat1,
      log: log,
    );
  }

  /// R56 (Caso de Borda 6): Avalia se um item sofre dano de uma habilidade em área ou alvo.
  /// Itens carregados NÃO sofrem dano de área, salvo se `afetaItensCarregados == true`.
  /// Objetos soltos sofrem dano normalmente.
  bool objetoPodeSofrerDano({
    required ItemObjeto item,
    required Habilidade habilidade,
    required bool ehDanoEmArea,
  }) {
    if (item.estaCarregado) {
      if (ehDanoEmArea && !habilidade.afetaItensCarregados) {
        return false; // Itens carregados não sofrem dano de área por padrão
      }
      return habilidade.afetaItensCarregados;
    }
    // Objetos soltos sofrem dano de área ou direcionado
    return true;
  }

  /// R53 (Caso de Borda 10): Processa a ação LIVRE de avisar aliados quando uma criatura
  /// percebe e desacredita uma ilusão. O mestre confirma quais aliados foram avisados.
  ({
    List<ResultadoResistencia> testesAliados,
    Set<String> desacreditadosNovos,
    List<String> logs,
  }) avisarAliadosIlusao({
    required String avisadorId,
    required EfeitoAtivo efeitoIlusao,
    required Habilidade habilidadeIlusao,
    required int cdResistencia,
    required List<Criatura> aliadosConfirmadosPeloMestre,
    IControleDeAcoes? controleDeAcoes,
    Map<String, int>? d20sForcadosPorAlvo,
  }) {
    final acoes = controleDeAcoes ?? ControleDeAcoesPermissivo();
    // Ação LIVRE de avisar aliados
    acoes.consumirAcao(avisadorId, TipoAcao.livre);

    final testes = <ResultadoResistencia>[];
    final novosDesacreditados = Set<String>.from(efeitoIlusao.desacreditadoPor);
    final logs = <String>[
      'Personagem $avisadorId avisa aliados sobre a ilusão "${efeitoIlusao.nomeHabilidade}" como ação livre.',
    ];

    for (final aliado in aliadosConfirmadosPeloMestre) {
      if (novosDesacreditados.contains(aliado.id)) {
        continue; // Já desacreditou anteriormente
      }

      final d20 = d20sForcadosPorAlvo?[aliado.id];
      final res = resolverResistenciaCriatura(
        criatura: aliado,
        habilidade: habilidadeIlusao,
        cdResistencia: cdResistencia,
        d20Forcado: d20,
      );
      testes.add(res);
      logs.add(res.log);

      if (res.sucesso) {
        novosDesacreditados.add(aliado.id);
        logs.add(
            '${aliado.nome} percebeu que a ilusão é falsa após ser avisado!');
      }
    }

    return (
      testesAliados: testes,
      desacreditadosNovos: novosDesacreditados,
      logs: logs,
    );
  }
}
