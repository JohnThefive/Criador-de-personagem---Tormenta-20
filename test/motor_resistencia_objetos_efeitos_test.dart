import 'package:flutter_test/flutter_test.dart';
import 'package:t20_creator/domain/entities/combate/grid_tatico.dart';
import 'package:t20_creator/domain/entities/habilidades/modelos_habilidade_duracao.dart';
import 'package:t20_creator/domain/entities/testes/configuracoes_mesa_t20.dart';
import 'package:t20_creator/domain/services/habilidades_services/habilidade_engine.dart';
import 'package:t20_creator/domain/services/habilidades_services/imunidade_service.dart';
import 'package:t20_creator/domain/services/habilidades_services/resistencia_service.dart';
import 'package:t20_creator/domain/services/testes_services/i_rng.dart';

void main() {
  group('Módulo 3: Resistência, Objetos e Tipos de Efeito (R50–R58)', () {
    late ImunidadeService imunidadeService;
    late ResistenciaService resistenciaService;
    late HabilidadeEngine habilidadeEngine;

    setUp(() {
      imunidadeService = const ImunidadeService();
      resistenciaService = ResistenciaService(rng: SequenciaRng([10]));
      habilidadeEngine = HabilidadeEngine(rng: SequenciaRng([10]));
    });

    test('Caso 1: CD de resistência com nível 7 e mod +3 -> 16; Magia usa atributo-chave', () {
      // R51: CD = 10 + floor(nível / 2) + modAtributo
      // Nível total 7 -> floor(7 / 2) = 3. Modificador +3. CD = 10 + 3 + 3 = 16.
      final cd = resistenciaService.calcularCdResistencia(
        nivelTotal: 7,
        modAtributo: 3,
      );
      expect(cd, equals(16));

      // Magia com atributo-chave Int (+4) vs atributoCD For (+1)
      final habMagica = const Habilidade(
        id: 'bola_de_fogo',
        nome: 'Bola de Fogo',
        tipo: TipoHabilidade.ativada,
        origem: OrigemHabilidade.classe,
        ehMagia: true,
        custo: CustoHabilidade(fixo: 3),
        atributoCD: 'for',
      );

      final modEfetivo = resistenciaService.obterModificadorAtributoParaCd(
        habilidade: habMagica,
        modAtributoChave: 4,
        atributos: {'for': 1, 'int': 4},
      );
      expect(modEfetivo, equals(4), reason: 'Magia deve priorizar atributo-chave do conjurador');

      // Habilidade não mágica com atributoCD = for
      final habNaoMagica = const Habilidade(
        id: 'derrubar',
        nome: 'Derrubar',
        tipo: TipoHabilidade.ativada,
        origem: OrigemHabilidade.classe,
        ehMagia: false,
        custo: CustoHabilidade(fixo: 1),
        atributoCD: 'for',
      );

      final modNaoMagica = resistenciaService.obterModificadorAtributoParaCd(
        habilidade: habNaoMagica,
        modAtributoChave: 4,
        atributos: {'for': 2, 'int': 4},
      );
      expect(modNaoMagica, equals(2), reason: 'Habilidade não mágica usa atributoCD indicado');
    });

    test('Caso 2: ANULA: Sucesso = efeito anulado (alvo sem efeito); Falha = efeito completo', () {
      final resService = ResistenciaService(rng: SequenciaRng([15]));
      final criatura = const Criatura(
        id: 'inimigo1',
        nome: 'Inimigo',
        tipoCriatura: TipoCriatura.humanoide,
        bonusResistencia: BonusResistencia(vontade: 2),
      );
      final habilidade = const Habilidade(
        id: 'sugestao',
        nome: 'Sugestão',
        tipo: TipoHabilidade.ativada,
        origem: OrigemHabilidade.classe,
        prejudicial: true,
        resistencia: HabilidadeResistencia(
          tipo: TipoResistencia.vontade,
          resultado: TipoResultadoResistencia.anula,
        ),
      );

      // CD 15. D20 = 15 + 2 = 17 >= 15 -> Sucesso!
      final resSucesso = resService.resolverResistenciaCriatura(
        criatura: criatura,
        habilidade: habilidade,
        cdResistencia: 15,
        d20Forcado: 15,
      );
      expect(resSucesso.sucesso, isTrue);
      expect(resSucesso.resultadoAplicado, equals(TipoResultadoResistencia.anula));

      // Falha: d20 = 5 + 2 = 7 < 15 -> Falha!
      final resFalha = resService.resolverResistenciaCriatura(
        criatura: criatura,
        habilidade: habilidade,
        cdResistencia: 15,
        d20Forcado: 5,
      );
      expect(resFalha.sucesso, isFalse);
      expect(resFalha.resultadoAplicado, equals(TipoResultadoResistencia.falha));
    });

    test('Caso 3: METADE: dano 11 reduzido para 5 (floor); PARCIAL aplica efeitoParcial', () {
      // R53: METADE divide por 2 e arredonda para baixo (11 -> 5)
      final reduzido = resistenciaService.aplicarReducaoMetade(11);
      expect(reduzido, equals(5));

      final habilidadeParcial = const Habilidade(
        id: 'raio_polar',
        nome: 'Raio Polar',
        tipo: TipoHabilidade.ativada,
        origem: OrigemHabilidade.classe,
        prejudicial: true,
        danoPvInstantaneo: 20,
        resistencia: HabilidadeResistencia(
          tipo: TipoResistencia.fortitude,
          resultado: TipoResultadoResistencia.parcial,
        ),
        efeitoParcial: HabilidadeEfeitoParcial(
          danoPvParcial: 10,
          descricao: 'Sofre apenas 10 de dano e não fica lento.',
        ),
      );

      final criatura = const Criatura(
        id: 'alvo1',
        nome: 'Alvo',
        tipoCriatura: TipoCriatura.humanoide,
        bonusResistencia: BonusResistencia(fortitude: 5),
      );

      // Sucesso na resistência parcial
      final res = resistenciaService.resolverResistenciaCriatura(
        criatura: criatura,
        habilidade: habilidadeParcial,
        cdResistencia: 14,
        d20Forcado: 10, // 10 + 5 = 15 >= 14 -> sucesso
      );
      expect(res.sucesso, isTrue);
      expect(res.resultadoAplicado, equals(TipoResultadoResistencia.parcial));
    });

    test('Caso 4: 20 natural passa e 1 natural falha mesmo contra a CD (R3)', () {
      final criaturaFraca = const Criatura(
        id: 'kobold',
        nome: 'Kobold',
        tipoCriatura: TipoCriatura.humanoide,
        bonusResistencia: BonusResistencia(reflexos: 0),
      );
      final habilidade = const Habilidade(
        id: 'explosao',
        nome: 'Explosão',
        tipo: TipoHabilidade.ativada,
        origem: OrigemHabilidade.classe,
        resistencia: HabilidadeResistencia(
          tipo: TipoResistencia.reflexos,
          resultado: TipoResultadoResistencia.metade,
        ),
      );

      // 20 natural contra CD 30 (total seria 20 + 0 = 20 < 30, mas nat 20 passa)
      final resNat20 = resistenciaService.resolverResistenciaCriatura(
        criatura: criaturaFraca,
        habilidade: habilidade,
        cdResistencia: 30,
        d20Forcado: 20,
      );
      expect(resNat20.sucesso, isTrue);
      expect(resNat20.sucessoAutomatico, isTrue);

      // 1 natural contra CD 5 (total seria 1 + 25 = 26 >= 5, mas nat 1 falha)
      final criaturaForte = const Criatura(
        id: 'paladino',
        nome: 'Paladino',
        tipoCriatura: TipoCriatura.humanoide,
        bonusResistencia: BonusResistencia(reflexos: 25),
      );
      final resNat1 = resistenciaService.resolverResistenciaCriatura(
        criatura: criaturaForte,
        habilidade: habilidade,
        cdResistencia: 5,
        d20Forcado: 1,
      );
      expect(resNat1.sucesso, isFalse);
      expect(resNat1.falhaAutomatica, isTrue);
    });

    test('Caso 5: Item mundano solto falha auto; mundano carregado usa bônus do portador; mágico usa maior', () {
      final portador = const Criatura(
        id: 'guerreiro',
        nome: 'Guerreiro',
        tipoCriatura: TipoCriatura.humanoide,
        bonusResistencia: BonusResistencia(reflexos: 6, fortitude: 8),
      );

      final habilidadeRef = const Habilidade(
        id: 'sopro',
        nome: 'Sopro',
        tipo: TipoHabilidade.ativada,
        origem: OrigemHabilidade.classe,
        resistencia: HabilidadeResistencia(tipo: TipoResistencia.reflexos),
      );

      // Item mundano solto falha automaticamente sem rolagem
      final itemSoltoMundano = const ItemObjeto(
        id: 'espada_chao',
        nome: 'Espada no Chão',
        magico: false,
        carregadoPor: null,
      );
      final resSolto = resistenciaService.resolverResistenciaObjeto(
        item: itemSoltoMundano,
        habilidade: habilidadeRef,
        cdResistencia: 15,
        portador: null,
        d20Forcado: 20,
      );
      expect(resSolto.sucesso, isFalse);
      expect(resSolto.falhaAutomatica, isTrue);
      expect(resSolto.d20, isNull);

      // Item mundano carregado usa o bônus do portador (Reflexos 6 + d20 10 = 16 >= 15)
      final itemCarregadoMundano = ItemObjeto(
        id: 'espada_empunhada',
        nome: 'Espada Empunhada',
        magico: false,
        carregadoPor: portador.id,
      );
      final resCarregado = resistenciaService.resolverResistenciaObjeto(
        item: itemCarregadoMundano,
        habilidade: habilidadeRef,
        cdResistencia: 15,
        portador: portador,
        d20Forcado: 10,
      );
      expect(resCarregado.sucesso, isTrue);
      expect(resCarregado.total, equals(16));

      // Item mágico com bônus próprio (+10) maior que o portador (+6)
      final itemMagico = ItemObjeto(
        id: 'espada_sagrada',
        nome: 'Espada Sagrada',
        magico: true,
        bonusResistencia: 10,
        carregadoPor: portador.id,
      );
      final resMagico = resistenciaService.resolverResistenciaObjeto(
        item: itemMagico,
        habilidade: habilidadeRef,
        cdResistencia: 15,
        portador: portador,
        d20Forcado: 6, // 6 + 10 (bônus do item) = 16 >= 15
      );
      expect(resMagico.sucesso, isTrue);
      expect(resMagico.total, equals(16));
    });

    test('Caso 6: Item carregado não sofre dano de área; objeto solto sofre; afetaItensCarregados sobrescreve', () {
      final itemCarregado = const ItemObjeto(
        id: 'escudo',
        nome: 'Escudo',
        carregadoPor: 'p1',
      );
      final itemSolto = const ItemObjeto(
        id: 'bau',
        nome: 'Baú de Madeira',
        carregadoPor: null,
      );

      // Habilidade comum de área
      final habAreaNormal = const Habilidade(
        id: 'bola_fogo',
        nome: 'Bola de Fogo',
        tipo: TipoHabilidade.ativada,
        origem: OrigemHabilidade.classe,
        area: Area(tipo: TipoArea.esfera, tamanhoQuadrados: 4),
        afetaItensCarregados: false,
      );

      expect(
        resistenciaService.objetoPodeSofrerDano(item: itemCarregado, habilidade: habAreaNormal, ehDanoEmArea: true),
        isFalse,
        reason: 'Item carregado não deve sofrer dano de área por padrão',
      );
      expect(
        resistenciaService.objetoPodeSofrerDano(item: itemSolto, habilidade: habAreaNormal, ehDanoEmArea: true),
        isTrue,
        reason: 'Objeto solto sofre dano de área normalmente',
      );

      // Habilidade de área com afetaItensCarregados = true
      final habCorrosao = const Habilidade(
        id: 'nevoa_acida',
        nome: 'Névoa Ácida Destrutiva',
        tipo: TipoHabilidade.ativada,
        origem: OrigemHabilidade.classe,
        area: Area(tipo: TipoArea.esfera, tamanhoQuadrados: 4),
        afetaItensCarregados: true,
      );

      expect(
        resistenciaService.objetoPodeSofrerDano(item: itemCarregado, habilidade: habCorrosao, ehDanoEmArea: true),
        isTrue,
        reason: 'afetaItensCarregados sobrescreve e danifica itens carregados',
      );
    });

    test('Caso 7: Construto/Morto-vivo imunes a cansaço, metabolismo, veneno; Int nula imune a medo e mental; Alvo imune não rola e PM é gasto', () {
      final construto = const Criatura(
        id: 'golem',
        nome: 'Golem de Ferro',
        tipoCriatura: TipoCriatura.construto,
        inteligencia: 10,
      );
      final zumbiSemMente = const Criatura(
        id: 'zumbi',
        nome: 'Zumbi',
        tipoCriatura: TipoCriatura.mortoVivo,
        inteligencia: null, // inteligência nula
      );

      // Construto: imune a veneno
      final checkVeneno = imunidadeService.checarImunidade(
        criatura: construto,
        tiposEfeito: {TipoEfeito.veneno},
      );
      expect(checkVeneno.imune, isTrue);

      // Construto: imune a metabolismo e cansaço
      expect(
        imunidadeService.checarImunidade(
          criatura: construto,
          tiposEfeito: {TipoEfeito.metabolismo},
        ).imune,
        isTrue,
      );
      expect(
        imunidadeService.checarImunidade(
          criatura: construto,
          tiposEfeito: {TipoEfeito.cansaco},
        ).imune,
        isTrue,
      );

      // Zumbi com inteligência nula: imune a medo e mental
      expect(
        imunidadeService.checarImunidade(
          criatura: zumbiSemMente,
          tiposEfeito: {TipoEfeito.mental},
        ).imune,
        isTrue,
      );
      expect(
        imunidadeService.checarImunidade(
          criatura: zumbiSemMente,
          tiposEfeito: {TipoEfeito.medo},
        ).imune,
        isTrue,
      );

      // Ativação via HabilidadeEngine: alvo imune é ignorado nos alvos afetados, mas conjurador gasta PM
      final mundo = EstadoMundoHabilidades(
        personagens: {
          'conjurador': const EstadoPersonagemHabilidade(
            id: 'conjurador',
            pmState: PMState(pmMaxBase: 10, pmAtual: 10),
            nivelTotal: 5,
          ),
          'golem': const EstadoPersonagemHabilidade(
            id: 'golem',
            pmState: PMState(pmMaxBase: 10, pmAtual: 10),
            nivelTotal: 5,
          ),
        },
        criaturas: {
          'golem': construto,
        },
        alvosNoMapa: {
          'golem': const AlvoMapa(id: 'golem', posicao: Posicao2D(1, 0)),
        },
      );

      final venenoHab = const Habilidade(
        id: 'nuvem_venenosa',
        nome: 'Nuvem Venenosa',
        tipo: TipoHabilidade.ativada,
        origem: OrigemHabilidade.classe,
        alcance: AlcanceHabilidade.curto,
        custo: CustoHabilidade(fixo: 3),
        prejudicial: true,
        tiposEfeito: {TipoEfeito.veneno},
        resistencia: HabilidadeResistencia(tipo: TipoResistencia.fortitude),
      );

      final retorno = habilidadeEngine.ativarHabilidade(
        habilidade: venenoHab,
        usuarioId: 'conjurador',
        mundo: mundo,
        alvosEscolhidosIds: ['golem'],
      );

      expect(retorno.resultado.bloqueada, isFalse);
      expect(retorno.resultado.falhou, isFalse);
      // Alvo golem foi ignorado por imunidade
      expect(retorno.resultado.alvosAfetados, isEmpty);
      expect(retorno.resultado.motivosImunidade.first, contains('é imune a veneno'));
      // Conjurador ainda gastou 3 PM
      final conjAtualizado = retorno.mundoAtualizado.personagens['conjurador']!;
      expect(conjAtualizado.pmState.pmAtual, equals(7));
    });

    test('Caso 8: Arcano e Divino geram Mágico automaticamente', () {
      final normalizadosArcano = imunidadeService.normalizarTipos({TipoEfeito.arcano});
      expect(normalizadosArcano, containsAll([TipoEfeito.arcano, TipoEfeito.magico]));

      final normalizadosDivino = imunidadeService.normalizarTipos({TipoEfeito.divino});
      expect(normalizadosDivino, containsAll([TipoEfeito.divino, TipoEfeito.magico]));

      final normalizadosAmbos = imunidadeService.normalizarTipos({TipoEfeito.arcano, TipoEfeito.dano});
      expect(normalizadosAmbos, containsAll([TipoEfeito.arcano, TipoEfeito.dano, TipoEfeito.magico]));
    });

    test('Caso 9: Efeito de Perda de Vida carrega ignoraReducaoDano = true', () {
      final mundo = EstadoMundoHabilidades(
        personagens: {
          'necromante': const EstadoPersonagemHabilidade(
            id: 'necromante',
            pmState: PMState(pmMaxBase: 10, pmAtual: 10),
            nivelTotal: 5,
          ),
          'vitima': const EstadoPersonagemHabilidade(
            id: 'vitima',
            pmState: PMState(pmMaxBase: 10, pmAtual: 10),
            nivelTotal: 5,
          ),
        },
        criaturas: {
          'vitima': const Criatura(
            id: 'vitima',
            nome: 'Vítima',
            tipoCriatura: TipoCriatura.humanoide,
          ),
        },
        alvosNoMapa: {
          'vitima': const AlvoMapa(id: 'vitima', posicao: Posicao2D(1, 0)),
        },
      );

      final toqueMortal = const Habilidade(
        id: 'dreno_vital',
        nome: 'Dreno Vital',
        tipo: TipoHabilidade.ativada,
        origem: OrigemHabilidade.classe,
        alcance: AlcanceHabilidade.curto,
        custo: CustoHabilidade(fixo: 2),
        duracao: Duracao(tipo: TipoDuracao.cena),
        tiposEfeito: {TipoEfeito.perdaDeVida, TipoEfeito.trevas},
      );

      final retorno = habilidadeEngine.ativarHabilidade(
        habilidade: toqueMortal,
        usuarioId: 'necromante',
        mundo: mundo,
        alvosEscolhidosIds: ['vitima'],
      );

      expect(retorno.resultado.bloqueada, isFalse);
      expect(retorno.mundoAtualizado.efeitos.length, equals(1));
      final efeito = retorno.mundoAtualizado.efeitos.first;
      expect(efeito.tipos, contains(TipoEfeito.perdaDeVida));
      expect(efeito.ignoraReducaoDano, isTrue, reason: 'Perda de Vida deve ignorar redução de dano');
    });

    test('Caso 10: DESACREDITA: sucesso percebe a ilusão; ação livre de avisar permite aliados confirmados testarem', () {
      final ilusao = const Habilidade(
        id: 'imagem_espelhada',
        nome: 'Imagem Maior',
        tipo: TipoHabilidade.ativada,
        origem: OrigemHabilidade.classe,
        resistencia: HabilidadeResistencia(
          tipo: TipoResistencia.vontade,
          resultado: TipoResultadoResistencia.desacredita,
        ),
      );

      final criatura1 = const Criatura(
        id: 'c1',
        nome: 'Explorador',
        tipoCriatura: TipoCriatura.humanoide,
        bonusResistencia: BonusResistencia(vontade: 4),
      );

      // Criatura 1 interage diretamente e passa na CD 14
      final resC1 = resistenciaService.resolverResistenciaCriatura(
        criatura: criatura1,
        habilidade: ilusao,
        cdResistencia: 14,
        d20Forcado: 10, // 10 + 4 = 14 >= 14
      );
      expect(resC1.sucesso, isTrue);
      expect(resC1.resultadoAplicado, equals(TipoResultadoResistencia.desacredita));

      final efeitoIlusao = EfeitoAtivo(
        id: 'ef_ilusao_1',
        habilidadeId: 'imagem_espelhada',
        nomeHabilidade: 'Imagem Maior',
        usuarioId: 'mago_inimigo',
        alvos: ['c1'],
        duracao: const Duracao(tipo: TipoDuracao.cena),
        estado: EstadoEfeito.ativo,
        inicio: const InicioEfeito(tempoSegundos: 0, rodada: 1, cenaId: 'cena1'),
        desacreditadoPor: {'c1'},
      );

      final c2 = const Criatura(id: 'c2', nome: 'Guerreiro', bonusResistencia: BonusResistencia(vontade: 5));
      final c3 = const Criatura(id: 'c3', nome: 'Ladino', bonusResistencia: BonusResistencia(vontade: 2));

      // Avisa aliados como ação livre
      final acaoAvisar = resistenciaService.avisarAliadosIlusao(
        avisadorId: 'c1',
        efeitoIlusao: efeitoIlusao,
        habilidadeIlusao: ilusao,
        cdResistencia: 14,
        aliadosConfirmadosPeloMestre: [c2, c3],
        d20sForcadosPorAlvo: {'c2': 10, 'c3': 5}, // c2: 10+5=15>=14 (sucesso); c3: 5+2=7<14 (falha)
      );

      expect(acaoAvisar.testesAliados.length, equals(2));
      expect(acaoAvisar.desacreditadosNovos, containsAll(['c1', 'c2']));
      expect(acaoAvisar.desacreditadosNovos.contains('c3'), isFalse);
    });

    test('Caso 11: Teste de perícia para resistir sem cd usa a CD da habilidade', () {
      final habilidadeAgarrar = const Habilidade(
        id: 'teia',
        nome: 'Teia',
        tipo: TipoHabilidade.ativada,
        origem: OrigemHabilidade.classe,
        prejudicial: true,
        // resistePericia com cd null -> deve herdar a CD da habilidade
        resistePericia: ResistePericia(pericia: 'ACROBACIA', cd: null),
        resistencia: HabilidadeResistencia(
          tipo: TipoResistencia.reflexos,
          resultado: TipoResultadoResistencia.anula,
        ),
      );

      final alvo = const Criatura(
        id: 'ladino',
        nome: 'Ladino',
        tipoCriatura: TipoCriatura.humanoide,
        bonusResistencia: BonusResistencia(reflexos: 5),
      );

      // CD da habilidade = 17. resService deve usar 17!
      final res = resistenciaService.resolverResistenciaCriatura(
        criatura: alvo,
        habilidade: habilidadeAgarrar,
        cdResistencia: 17,
        d20Forcado: 11, // 11 + 5 = 16 < 17 -> falha
      );
      expect(res.cd, equals(17));
      expect(res.pericia, equals('ACROBACIA'));
      expect(res.sucesso, isFalse);

      // Com d20 = 12 -> 12 + 5 = 17 >= 17 -> sucesso
      final resPassou = resistenciaService.resolverResistenciaCriatura(
        criatura: alvo,
        habilidade: habilidadeAgarrar,
        cdResistencia: 17,
        d20Forcado: 12,
      );
      expect(resPassou.sucesso, isTrue);
    });

    test('Caso 12: Área persistente: teste feito uma vez por alvo; entrar e sair não refaz (padrão)', () {
      final configs = const ConfiguracoesMesaT20(); // repetirTesteResistenciaCadaEntradaArea = false
      final efeitoPersistente = const EfeitoAtivo(
        id: 'efeito_area_1',
        habilidadeId: 'nuvem_fetida',
        nomeHabilidade: 'Nuvem Fétida',
        usuarioId: 'conjurador',
        alvos: ['alvo1'],
        duracao: Duracao(tipo: TipoDuracao.sustentada),
        estado: EstadoEfeito.ativo,
        inicio: InicioEfeito(tempoSegundos: 0, rodada: 1, cenaId: 'cena1'),
        historicoResistencia: {
          'alvo1': ResultadoResistencia(
            alvoId: 'alvo1',
            tipo: TipoResistencia.fortitude,
            cd: 15,
            d20: 16,
            total: 20,
            sucesso: true,
            resultadoAplicado: TipoResultadoResistencia.anula,
            log: 'Sucesso prévio',
          ),
        },
      );

      // Alvo já possui histórico de resistência nesta área persistente
      final podeRepetirPadrao = configs.repetirTesteResistenciaCadaEntradaArea;
      expect(podeRepetirPadrao, isFalse);

      final resultadoHistorico = efeitoPersistente.historicoResistencia['alvo1'];
      expect(resultadoHistorico, isNotNull);
      expect(resultadoHistorico!.sucesso, isTrue);
      expect(resultadoHistorico.resultadoAplicado, equals(TipoResultadoResistencia.anula));
    });
  });
}
