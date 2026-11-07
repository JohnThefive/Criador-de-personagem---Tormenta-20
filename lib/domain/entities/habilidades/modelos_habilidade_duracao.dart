import 'package:t20_creator/domain/entities/combate/grid_tatico.dart';
import 'package:t20_creator/domain/entities/combate/tipo_acao.dart';
import 'package:t20_creator/domain/entities/testes/modelos_teste_t20.dart';
import 'package:t20_creator/domain/entities/habilidades/modelos_resistencia_efeito.dart';

export 'package:t20_creator/domain/entities/habilidades/modelos_resistencia_efeito.dart';

/// Constante oficial do grid T20: 1 quadrado = 1,5 metro.
const double kMetrosPorQuadradoT20 = 1.5;

/// R22: Classificação da habilidade quanto à forma de ativação.
enum TipoHabilidade {
  passiva,
  ativada,
}

/// R22 e R26: Origem da habilidade para cálculo de limite de nível.
enum OrigemHabilidade {
  raca,
  origem,
  classe,
  item,
  poderGeral,
  outra,
}

/// R24 (Caso de Borda 3): Alcances oficiais em quadrados e metros (1q = 1,5m).
enum AlcanceHabilidade {
  pessoal,
  toque,
  curto,
  medio,
  longo,
  ilimitado;

  /// Distância máxima em quadrados (`null` para ilimitado).
  int? get quadrados => switch (this) {
        AlcanceHabilidade.pessoal => 0,
        AlcanceHabilidade.toque => 1,
        AlcanceHabilidade.curto => 6,
        AlcanceHabilidade.medio => 20,
        AlcanceHabilidade.longo => 60,
        AlcanceHabilidade.ilimitado => null,
      };

  /// Distância máxima em metros (`null` para ilimitado).
  double? get metros =>
      quadrados != null ? quadrados! * kMetrosPorQuadradoT20 : null;
}

/// R32: Tipos de alvo compatíveis com uma habilidade.
enum TipoAlvoPermitido {
  criatura,
  objeto,
  ponto,
}

/// R32: Categorias de tamanho de criaturas e objetos.
enum CategoriaTamanho {
  minusculo,
  pequeno,
  medio,
  grande,
  enorme,
  colossal,
}

/// R34: Formatos de área de efeito no grid.
enum TipoArea {
  cone,
  esfera,
  cilindro,
  linha,
  quadrado,
  cubo,
  outro,
}

/// R44: Frequência/momento de aplicação dos efeitos de uma área persistente.
enum ModoAplicacaoArea {
  continuo,
  aoEntrar,
  inicioDoTurno,
}

/// R38: Tipos base de duração de uma habilidade ou efeito.
enum TipoDuracao {
  instantanea,
  cena,
  sustentada,
  definida,
  permanente,
}

/// R38: Unidades de tempo para durações do tipo `DEFINIDA`.
enum UnidadeDuracao {
  rodada,
  minuto,
  hora,
  dia,
  outra,
}

/// R38: Estados do ciclo de vida de um [EfeitoAtivo].
enum EstadoEfeito {
  ativo,
  dormente,
  expirado,
  descarregado,
  encerrado,
}

/// R38: Motivos de término registrados no histórico do efeito.
enum MotivoFimEfeito {
  duracao,
  usuario,
  mestre,
  morteDoUsuario,
  sustentacaoNaoPaga,
  cenaEncerrada,
  descarga,
  substituido,
  outro,
}

/// R25: Faixa de custo variável de PM.
class CustoVariavel {
  final int min;
  final int? max;

  const CustoVariavel({
    required this.min,
    this.max,
  });

  Map<String, dynamic> toJson() => {
        'min': min,
        'max': max,
      };

  factory CustoVariavel.fromJson(Map<String, dynamic> json) {
    return CustoVariavel(
      min: json['min'] as int,
      max: json['max'] as int?,
    );
  }
}

/// R27: Redução de custo em PM concedida por habilidade, item ou efeito.
class ReducaoCusto {
  final String fonteId;
  final int valor;

  const ReducaoCusto({
    required this.fonteId,
    required this.valor,
  });

  Map<String, dynamic> toJson() => {
        'fonteId': fonteId,
        'valor': valor,
      };

  factory ReducaoCusto.fromJson(Map<String, dynamic> json) {
    return ReducaoCusto(
      fonteId: json['fonteId'] as String? ?? 'REDUCAO',
      valor: json['valor'] as int? ?? 0,
    );
  }
}

/// R25–R28: Estrutura de custos de uma habilidade.
class CustoHabilidade {
  final int? fixo;
  final CustoVariavel? variavel;
  final List<ReducaoCusto> reducoes;
  final List<String> material;
  final int penalidadePM;
  final int sacrificioPM;

  const CustoHabilidade({
    this.fixo,
    this.variavel,
    this.reducoes = const [],
    this.material = const [],
    this.penalidadePM = 0,
    this.sacrificioPM = 0,
  });

  Map<String, dynamic> toJson() => {
        'fixo': fixo,
        'variavel': variavel?.toJson(),
        'reducoes': reducoes.map((r) => r.toJson()).toList(),
        'material': material,
        'penalidadePM': penalidadePM,
        'sacrificioPM': sacrificioPM,
      };

  factory CustoHabilidade.fromJson(Map<String, dynamic> json) {
    return CustoHabilidade(
      fixo: json['fixo'] as int?,
      variavel: json['variavel'] != null
          ? CustoVariavel.fromJson(json['variavel'] as Map<String, dynamic>)
          : null,
      reducoes: (json['reducoes'] as List<dynamic>? ?? [])
          .map((e) => ReducaoCusto.fromJson(e as Map<String, dynamic>))
          .toList(),
      material: (json['material'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      penalidadePM: json['penalidadePM'] as int? ?? 0,
      sacrificioPM: json['sacrificioPM'] as int? ?? 0,
    );
  }
}

/// R38 e R42: Especificação de tempo para duração `DEFINIDA`.
class DuracaoDefinida {
  final int quantidade;
  final UnidadeDuracao unidade;
  final String? rotulo;
  final int? segundosPorUnidade;

  const DuracaoDefinida({
    required this.quantidade,
    required this.unidade,
    this.rotulo,
    this.segundosPorUnidade,
  });

  /// Converte a duração definida para segundos de jogo (usado para MINUTO, HORA, DIA, OUTRA e RODADA fora de combate).
  int paraSegundos({int segundosPorRodada = 6}) {
    final base = switch (unidade) {
      UnidadeDuracao.rodada => segundosPorRodada,
      UnidadeDuracao.minuto => 60,
      UnidadeDuracao.hora => 3600,
      UnidadeDuracao.dia => 86400,
      UnidadeDuracao.outra => segundosPorUnidade ?? 6,
    };
    return quantidade * base;
  }

  Map<String, dynamic> toJson() => {
        'quantidade': quantidade,
        'unidade': unidade.name,
        'rotulo': rotulo,
        'segundosPorUnidade': segundosPorUnidade,
      };

  factory DuracaoDefinida.fromJson(Map<String, dynamic> json) {
    return DuracaoDefinida(
      quantidade: json['quantidade'] as int,
      unidade: UnidadeDuracao.values.firstWhere(
        (e) => e.name == json['unidade'],
        orElse: () => UnidadeDuracao.rodada,
      ),
      rotulo: json['rotulo'] as String?,
      segundosPorUnidade: json['segundosPorUnidade'] as int?,
    );
  }
}

/// R38 e R45: Modificador de descarga acoplado a uma duração base (CENA, DEFINIDA ou PERMANENTE).
class ConfigDescarga {
  final String gatilho;

  const ConfigDescarga({required this.gatilho});

  Map<String, dynamic> toJson() => {'gatilho': gatilho};

  factory ConfigDescarga.fromJson(Map<String, dynamic> json) {
    return ConfigDescarga(gatilho: json['gatilho'] as String? ?? '');
  }
}

/// R38: Definição completa da duração de uma habilidade.
class Duracao {
  final TipoDuracao tipo;
  final DuracaoDefinida? definida;
  final ConfigDescarga? descarregar;

  const Duracao({
    required this.tipo,
    this.definida,
    this.descarregar,
  });

  /// R38 e Caso de Borda 37: Valida a consistência estrutural da duração e penalidade de PM.
  void validar({int penalidadePM = 0}) {
    if (tipo == TipoDuracao.instantanea && penalidadePM > 0) {
      throw const RegraTesteException(
        codigo: 'DURACAO_INSTANTANEA_COM_PENALIDADE_PM',
        mensagem:
            'Duração INSTANTANEA com penalidadePM é inválida (não há duração ativa para manter a penalidade).',
      );
    }
    if (tipo == TipoDuracao.definida &&
        (definida == null || definida!.quantidade <= 0)) {
      throw const RegraTesteException(
        codigo: 'DURACAO_DEFINIDA_SEM_ESPECIFICACAO',
        mensagem:
            'Duração do tipo DEFINIDA exige o objeto `definida` com quantidade > 0.',
      );
    }
    if (descarregar != null) {
      if (descarregar!.gatilho.trim().isEmpty) {
        throw const RegraTesteException(
          codigo: 'DESCARREGAR_SEM_GATILHO',
          mensagem:
              'O modificador `descarregar` exige um `gatilho` não vazio.',
        );
      }
      if (tipo == TipoDuracao.instantanea || tipo == TipoDuracao.sustentada) {
        throw RegraTesteException(
          codigo: 'DESCARREGAR_TIPO_INCOMPATIVEL',
          mensagem:
              'O modificador `descarregar` só pode ser combinado com CENA, DEFINIDA ou PERMANENTE (recebido: ${tipo.name}).',
        );
      }
    }
  }

  Map<String, dynamic> toJson() => {
        'tipo': tipo.name,
        'definida': definida?.toJson(),
        'descarregar': descarregar?.toJson(),
      };

  factory Duracao.fromJson(Map<String, dynamic> json) {
    return Duracao(
      tipo: TipoDuracao.values.firstWhere(
        (e) => e.name == json['tipo'],
        orElse: () => TipoDuracao.instantanea,
      ),
      definida: json['definida'] != null
          ? DuracaoDefinida.fromJson(json['definida'] as Map<String, dynamic>)
          : null,
      descarregar: json['descarregar'] != null
          ? ConfigDescarga.fromJson(json['descarregar'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// R34 (Caso de Borda 17): Interseção de 4 quadrados (vértice do grid) para origem de ESFERA e CILINDRO.
/// O vértice `(vx, vy)` fica na interseção dos quadrados `(vx-1, vy-1)`, `(vx, vy-1)`, `(vx-1, vy)` e `(vx, vy)`.
class VerticeGrid {
  final int vx;
  final int vy;

  const VerticeGrid(this.vx, this.vy);

  /// Coordenada real X no plano cartesiano onde o quadrado `(x, y)` tem centro em `(x + 0.5, y + 0.5)`.
  double get coordX => vx.toDouble();
  double get coordY => vy.toDouble();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VerticeGrid && other.vx == vx && other.vy == vy);

  @override
  int get hashCode => Object.hash(vx, vy);

  Map<String, dynamic> toJson() => {'vx': vx, 'vy': vy};

  factory VerticeGrid.fromJson(Map<String, dynamic> json) =>
      VerticeGrid(json['vx'] as int, json['vy'] as int);
}

/// R34: Definição geométrica de uma área de efeito.
class Area {
  final TipoArea tipo;

  /// Raio (esfera/cilindro), comprimento (cone/linha) ou lado (quadrado/cubo) em quadrados.
  final int tamanhoQuadrados;

  /// Largura em quadrados para LINHA (padrão = 1 quadrado = 1,5 m, R34/Caso 17).
  final int larguraQuadrados;

  /// Altura vertical em quadrados para CILINDRO ou CUBO (R34).
  final int alturaQuadrados;

  /// Origem em quadrado do grid (para CONE, LINHA, QUADRADO, CUBO, OUTRO).
  final Posicao2D? origemCelula;

  /// Origem em interseção de 4 quadrados (obrigatório/padrão para ESFERA e CILINDRO, R34/Caso 17).
  final VerticeGrid? origemVertice;

  /// Ponto ou direção para orientar CONE ou LINHA.
  final Posicao2D? direcaoDestino;

  /// Elevação base da área (em quadrados).
  final int elevacaoBaseQuadrados;

  /// Sobrescreve se a área afeta o próprio usuário (`null` = usa a regra padrão de R34:
  /// alcance PESSOAL não afeta o usuário, demais alcances afetam).
  final bool? afetaUsuario;

  /// R44: Modo de aplicação para áreas persistentes.
  final ModoAplicacaoArea aplicacao;

  /// R34: Máscara de deslocamentos customizados para `TipoArea.outro`.
  final List<Posicao2D> mascaraCustomizada;

  const Area({
    required this.tipo,
    required this.tamanhoQuadrados,
    this.larguraQuadrados = 1,
    this.alturaQuadrados = 1,
    this.origemCelula,
    this.origemVertice,
    this.direcaoDestino,
    this.elevacaoBaseQuadrados = 0,
    this.afetaUsuario,
    this.aplicacao = ModoAplicacaoArea.continuo,
    this.mascaraCustomizada = const [],
  });

  double get larguraMetros => larguraQuadrados * kMetrosPorQuadradoT20;
  double get tamanhoMetros => tamanhoQuadrados * kMetrosPorQuadradoT20;

  /// Retorna a célula de referência da origem para checagem de alcance e linha de efeito.
  Posicao2D get celulaReferenciaOrigem {
    if (origemCelula != null) return origemCelula!;
    if (origemVertice != null) {
      return Posicao2D(origemVertice!.vx, origemVertice!.vy);
    }
    return const Posicao2D(0, 0);
  }

  Area copyWith({
    TipoArea? tipo,
    int? tamanhoQuadrados,
    int? larguraQuadrados,
    int? alturaQuadrados,
    Posicao2D? origemCelula,
    VerticeGrid? origemVertice,
    Posicao2D? direcaoDestino,
    int? elevacaoBaseQuadrados,
    bool? afetaUsuario,
    ModoAplicacaoArea? aplicacao,
    List<Posicao2D>? mascaraCustomizada,
  }) {
    return Area(
      tipo: tipo ?? this.tipo,
      tamanhoQuadrados: tamanhoQuadrados ?? this.tamanhoQuadrados,
      larguraQuadrados: larguraQuadrados ?? this.larguraQuadrados,
      alturaQuadrados: alturaQuadrados ?? this.alturaQuadrados,
      origemCelula: origemCelula ?? this.origemCelula,
      origemVertice: origemVertice ?? this.origemVertice,
      direcaoDestino: direcaoDestino ?? this.direcaoDestino,
      elevacaoBaseQuadrados:
          elevacaoBaseQuadrados ?? this.elevacaoBaseQuadrados,
      afetaUsuario: afetaUsuario ?? this.afetaUsuario,
      aplicacao: aplicacao ?? this.aplicacao,
      mascaraCustomizada: mascaraCustomizada ?? this.mascaraCustomizada,
    );
  }

  Map<String, dynamic> toJson() => {
        'tipo': tipo.name,
        'tamanhoQuadrados': tamanhoQuadrados,
        'larguraQuadrados': larguraQuadrados,
        'alturaQuadrados': alturaQuadrados,
        'origemCelula': origemCelula != null
            ? {'x': origemCelula!.x, 'y': origemCelula!.y}
            : null,
        'origemVertice': origemVertice?.toJson(),
        'direcaoDestino': direcaoDestino != null
            ? {'x': direcaoDestino!.x, 'y': direcaoDestino!.y}
            : null,
        'elevacaoBaseQuadrados': elevacaoBaseQuadrados,
        'afetaUsuario': afetaUsuario,
        'aplicacao': aplicacao.name,
        'mascaraCustomizada': mascaraCustomizada
            .map((p) => {'x': p.x, 'y': p.y})
            .toList(),
      };

  factory Area.fromJson(Map<String, dynamic> json) {
    final origCel = json['origemCelula'] as Map<String, dynamic>?;
    final dirDest = json['direcaoDestino'] as Map<String, dynamic>?;
    return Area(
      tipo: TipoArea.values.firstWhere(
        (e) => e.name == json['tipo'],
        orElse: () => TipoArea.esfera,
      ),
      tamanhoQuadrados: json['tamanhoQuadrados'] as int? ?? 1,
      larguraQuadrados: json['larguraQuadrados'] as int? ?? 1,
      alturaQuadrados: json['alturaQuadrados'] as int? ?? 1,
      origemCelula: origCel != null
          ? Posicao2D(origCel['x'] as int, origCel['y'] as int)
          : null,
      origemVertice: json['origemVertice'] != null
          ? VerticeGrid.fromJson(
              json['origemVertice'] as Map<String, dynamic>,
            )
          : null,
      direcaoDestino: dirDest != null
          ? Posicao2D(dirDest['x'] as int, dirDest['y'] as int)
          : null,
      elevacaoBaseQuadrados: json['elevacaoBaseQuadrados'] as int? ?? 0,
      afetaUsuario: json['afetaUsuario'] as bool?,
      aplicacao: ModoAplicacaoArea.values.firstWhere(
        (e) => e.name == json['aplicacao'],
        orElse: () => ModoAplicacaoArea.continuo,
      ),
      mascaraCustomizada: (json['mascaraCustomizada'] as List<dynamic>? ?? [])
          .map((e) {
            final m = e as Map<String, dynamic>;
            return Posicao2D(m['x'] as int, m['y'] as int);
          })
          .toList(),
    );
  }
}

/// R22–R38: Entidade completa de Habilidade (Magia, Poder, Habilidade de Raça/Classe/Origem/Item).
class Habilidade {
  final String id;
  final String nome;
  final TipoHabilidade tipo;
  final OrigemHabilidade origem;
  final String? classeId;
  final TipoAcao? acao;
  final String? gatilho;
  final AlcanceHabilidade alcance;
  final CustoHabilidade custo;
  final List<TipoAlvoPermitido> alvosPermitidos;
  final Area? area;
  final bool ehMagia;
  final bool permiteRedirecionar;
  final bool criaElementoNoMapa;
  final Duracao duracao;
  final List<ModificadorAplicado> modificadoresGerados;
  final int curaPvInstantanea;
  final int danoPvInstantaneo;

  // --- MÓDULO 3: RESISTÊNCIA, OBJETOS E TIPOS DE EFEITO (R50–R58) ---
  final bool prejudicial;
  final String? atributoCD;
  final HabilidadeResistencia? resistencia;
  final HabilidadeEfeitoParcial? efeitoParcial;
  final ResistePericia? resistePericia;
  final bool afetaItensCarregados;
  final Set<TipoEfeito> tiposEfeito;

  const Habilidade({
    required this.id,
    required this.nome,
    this.tipo = TipoHabilidade.ativada,
    this.origem = OrigemHabilidade.poderGeral,
    this.classeId,
    this.acao,
    this.gatilho,
    this.alcance = AlcanceHabilidade.pessoal,
    this.custo = const CustoHabilidade(),
    this.alvosPermitidos = const [TipoAlvoPermitido.criatura],
    this.area,
    this.ehMagia = false,
    this.permiteRedirecionar = false,
    this.criaElementoNoMapa = false,
    this.duracao = const Duracao(tipo: TipoDuracao.instantanea),
    this.modificadoresGerados = const [],
    this.curaPvInstantanea = 0,
    this.danoPvInstantaneo = 0,
    this.prejudicial = false,
    this.atributoCD,
    this.resistencia,
    this.efeitoParcial,
    this.resistePericia,
    this.afetaItensCarregados = false,
    this.tiposEfeito = const {},
  });

  /// R23 (Caso de Borda 1): Se `acao` for omitida, a ativação é `LIVRE`.
  /// Se possuir `gatilho` (habilidade engatilhada), é ativada como `REACAO`.
  TipoAcao get acaoEfetiva {
    if (gatilho != null && gatilho!.trim().isNotEmpty) {
      return acao ?? TipoAcao.reacao;
    }
    return acao ?? TipoAcao.livre;
  }

  bool get ehEngatilhada => gatilho != null && gatilho!.trim().isNotEmpty;

  /// R38 (Caso de Borda 37): Valida os dados da habilidade e sua duração.
  void validarDefinicao() {
    duracao.validar(penalidadePM: custo.penalidadePM);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'tipo': tipo.name,
        'origem': origem.name,
        'classeId': classeId,
        'acao': acao?.name,
        'gatilho': gatilho,
        'alcance': alcance.name,
        'custo': custo.toJson(),
        'alvosPermitidos': alvosPermitidos.map((a) => a.name).toList(),
        'area': area?.toJson(),
        'ehMagia': ehMagia,
        'permiteRedirecionar': permiteRedirecionar,
        'criaElementoNoMapa': criaElementoNoMapa,
        'duracao': duracao.toJson(),
        'modificadoresGerados':
            modificadoresGerados.map((m) => m.toJson()).toList(),
        'curaPvInstantanea': curaPvInstantanea,
        'danoPvInstantaneo': danoPvInstantaneo,
        'prejudicial': prejudicial,
        'atributoCD': atributoCD,
        'resistencia': resistencia?.toJson(),
        'efeitoParcial': efeitoParcial?.toJson(),
        'resistePericia': resistePericia?.toJson(),
        'afetaItensCarregados': afetaItensCarregados,
        'tiposEfeito': tiposEfeito.map((e) => e.name).toList(),
      };

  factory Habilidade.fromJson(Map<String, dynamic> json) {
    final hab = Habilidade(
      id: json['id'] as String,
      nome: json['nome'] as String,
      tipo: TipoHabilidade.values.firstWhere(
        (e) => e.name == json['tipo'],
        orElse: () => TipoHabilidade.ativada,
      ),
      origem: OrigemHabilidade.values.firstWhere(
        (e) => e.name == json['origem'],
        orElse: () => OrigemHabilidade.poderGeral,
      ),
      classeId: json['classeId'] as String?,
      acao: json['acao'] != null
          ? TipoAcao.values.firstWhere(
              (e) => e.name == json['acao'],
              orElse: () => TipoAcao.livre,
            )
          : null,
      gatilho: json['gatilho'] as String?,
      alcance: AlcanceHabilidade.values.firstWhere(
        (e) => e.name == json['alcance'],
        orElse: () => AlcanceHabilidade.pessoal,
      ),
      custo: json['custo'] != null
          ? CustoHabilidade.fromJson(json['custo'] as Map<String, dynamic>)
          : const CustoHabilidade(),
      alvosPermitidos: (json['alvosPermitidos'] as List<dynamic>? ?? [])
          .map(
            (e) => TipoAlvoPermitido.values.firstWhere(
              (t) => t.name == e,
              orElse: () => TipoAlvoPermitido.criatura,
            ),
          )
          .toList(),
      area: json['area'] != null
          ? Area.fromJson(json['area'] as Map<String, dynamic>)
          : null,
      ehMagia: json['ehMagia'] as bool? ?? false,
      permiteRedirecionar: json['permiteRedirecionar'] as bool? ?? false,
      criaElementoNoMapa: json['criaElementoNoMapa'] as bool? ?? false,
      duracao: json['duracao'] != null
          ? Duracao.fromJson(json['duracao'] as Map<String, dynamic>)
          : const Duracao(tipo: TipoDuracao.instantanea),
      modificadoresGerados:
          (json['modificadoresGerados'] as List<dynamic>? ?? [])
              .map(
                (e) => ModificadorAplicado.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
      curaPvInstantanea: json['curaPvInstantanea'] as int? ?? 0,
      danoPvInstantaneo: json['danoPvInstantaneo'] as int? ?? 0,
      prejudicial: json['prejudicial'] as bool? ?? false,
      atributoCD: json['atributoCD'] as String?,
      resistencia: json['resistencia'] != null
          ? HabilidadeResistencia.fromJson(
              json['resistencia'] as Map<String, dynamic>)
          : null,
      efeitoParcial: json['efeitoParcial'] != null
          ? HabilidadeEfeitoParcial.fromJson(
              json['efeitoParcial'] as Map<String, dynamic>)
          : null,
      resistePericia: json['resistePericia'] != null
          ? ResistePericia.fromJson(
              json['resistePericia'] as Map<String, dynamic>)
          : null,
      afetaItensCarregados: json['afetaItensCarregados'] as bool? ?? false,
      tiposEfeito: (json['tiposEfeito'] as List<dynamic>? ?? [])
          .map(
            (e) => TipoEfeito.values.firstWhere(
              (t) => t.name == e,
              orElse: () => TipoEfeito.dano,
            ),
          )
          .toSet(),
    );
    hab.validarDefinicao();
    return hab;
  }
}

/// R28: Penalidade de PM máxima vinculada a um [EfeitoAtivo].
class PenalidadePMAtiva {
  final String efeitoId;
  final int valor;

  const PenalidadePMAtiva({
    required this.efeitoId,
    required this.valor,
  });

  Map<String, dynamic> toJson() => {
        'efeitoId': efeitoId,
        'valor': valor,
      };

  factory PenalidadePMAtiva.fromJson(Map<String, dynamic> json) {
    return PenalidadePMAtiva(
      efeitoId: json['efeitoId'] as String,
      valor: json['valor'] as int,
    );
  }
}

/// R28: Estado de Pontos de Mana (PM) de um personagem.
class PMState {
  final int pmMaxBase;
  final List<PenalidadePMAtiva> penalidadesAtivas;
  final int pmAtual;

  const PMState({
    required this.pmMaxBase,
    this.penalidadesAtivas = const [],
    required this.pmAtual,
  });

  int get totalPenalidadesAtivas =>
      penalidadesAtivas.fold<int>(0, (s, p) => s + p.valor);

  /// R28: `pmMaxEfetivo = pmMaxBase - Σ penalidades ativas` (sacrifícios já reduzem `pmMaxBase`).
  int get pmMaxEfetivo => pmMaxBase - totalPenalidadesAtivas;

  PMState copyWith({
    int? pmMaxBase,
    List<PenalidadePMAtiva>? penalidadesAtivas,
    int? pmAtual,
  }) {
    return PMState(
      pmMaxBase: pmMaxBase ?? this.pmMaxBase,
      penalidadesAtivas: penalidadesAtivas ?? this.penalidadesAtivas,
      pmAtual: pmAtual ?? this.pmAtual,
    );
  }

  Map<String, dynamic> toJson() => {
        'pmMaxBase': pmMaxBase,
        'penalidadesAtivas': penalidadesAtivas.map((p) => p.toJson()).toList(),
        'pmAtual': pmAtual,
      };

  factory PMState.fromJson(Map<String, dynamic> json) {
    return PMState(
      pmMaxBase: json['pmMaxBase'] as int,
      penalidadesAtivas: (json['penalidadesAtivas'] as List<dynamic>? ?? [])
          .map((e) => PenalidadePMAtiva.fromJson(e as Map<String, dynamic>))
          .toList(),
      pmAtual: json['pmAtual'] as int,
    );
  }
}

/// R38 e R59: Metadados do instante de criação de um [EfeitoAtivo], incluindo a iniciativa de início.
class InicioEfeito {
  final int tempoSegundos;
  final int rodada;
  final String cenaId;
  final int? iniciativa;

  const InicioEfeito({
    required this.tempoSegundos,
    required this.rodada,
    required this.cenaId,
    this.iniciativa,
  });

  Map<String, dynamic> toJson() => {
        'tempoSegundos': tempoSegundos,
        'rodada': rodada,
        'cenaId': cenaId,
        'iniciativa': iniciativa,
      };

  factory InicioEfeito.fromJson(Map<String, dynamic> json) {
    return InicioEfeito(
      tempoSegundos: json['tempoSegundos'] as int? ?? 0,
      rodada: json['rodada'] as int? ?? 1,
      cenaId: json['cenaId'] as String? ?? 'cena_1',
      iniciativa: json['iniciativa'] as int?,
    );
  }
}

/// R41: Estado de manutenção de um efeito `SUSTENTADA`.
class SustentacaoEfeito {
  final int custoPM;
  final bool pendente;
  final int rodadaAtivacao;
  final int turnosAtivos;

  const SustentacaoEfeito({
    this.custoPM = 1,
    this.pendente = false,
    required this.rodadaAtivacao,
    this.turnosAtivos = 0,
  });

  SustentacaoEfeito copyWith({
    int? custoPM,
    bool? pendente,
    int? rodadaAtivacao,
    int? turnosAtivos,
  }) {
    return SustentacaoEfeito(
      custoPM: custoPM ?? this.custoPM,
      pendente: pendente ?? this.pendente,
      rodadaAtivacao: rodadaAtivacao ?? this.rodadaAtivacao,
      turnosAtivos: turnosAtivos ?? this.turnosAtivos,
    );
  }

  Map<String, dynamic> toJson() => {
        'custoPM': custoPM,
        'pendente': pendente,
        'rodadaAtivacao': rodadaAtivacao,
        'turnosAtivos': turnosAtivos,
      };

  factory SustentacaoEfeito.fromJson(Map<String, dynamic> json) {
    return SustentacaoEfeito(
      custoPM: json['custoPM'] as int? ?? 1,
      pendente: json['pendente'] as bool? ?? false,
      rodadaAtivacao: json['rodadaAtivacao'] as int? ?? 1,
      turnosAtivos: json['turnosAtivos'] as int? ?? 0,
    );
  }
}

/// R45: Estado de descarga de um efeito `DORMENTE`.
class DescargaEfeito {
  final String gatilho;
  final String? eventoConsumidoId;

  const DescargaEfeito({
    required this.gatilho,
    this.eventoConsumidoId,
  });

  DescargaEfeito copyWith({
    String? gatilho,
    String? eventoConsumidoId,
  }) {
    return DescargaEfeito(
      gatilho: gatilho ?? this.gatilho,
      eventoConsumidoId: eventoConsumidoId ?? this.eventoConsumidoId,
    );
  }

  Map<String, dynamic> toJson() => {
        'gatilho': gatilho,
        'eventoConsumidoId': eventoConsumidoId,
      };

  factory DescargaEfeito.fromJson(Map<String, dynamic> json) {
    return DescargaEfeito(
      gatilho: json['gatilho'] as String,
      eventoConsumidoId: json['eventoConsumidoId'] as String?,
    );
  }
}

/// R38–R49: Instância de um efeito com duração ativa ou dormente em jogo.
class EfeitoAtivo {
  final String id;
  final String habilidadeId;
  final String nomeHabilidade;
  final String usuarioId;
  final bool ehMagia;
  final AlcanceHabilidade alcance;
  final bool permiteRedirecionar;
  final List<TipoAlvoPermitido> alvosPermitidos;
  final List<String> alvos;
  final String? areaPersistenteId;
  final Duracao duracao;
  final EstadoEfeito estado;
  final InicioEfeito inicio;
  final int? expiraEmSegundos;
  final int? expiraNaRodada;
  final List<ModificadorAplicado> modificadores;
  final String? penalidadePMId;
  final SustentacaoEfeito? sustentacao;
  final DescargaEfeito? descarga;
  final MotivoFimEfeito? motivoFim;
  final List<String> historico;

  // --- MÓDULO 3: RESISTÊNCIA, OBJETOS E TIPOS DE EFEITO (R50–R58) ---
  final Set<TipoEfeito> tipos;
  final bool ignoraReducaoDano;
  final Map<String, ResultadoResistencia> historicoResistencia;
  final Set<String> desacreditadoPor;

  const EfeitoAtivo({
    required this.id,
    required this.habilidadeId,
    this.nomeHabilidade = '',
    required this.usuarioId,
    this.ehMagia = false,
    this.alcance = AlcanceHabilidade.pessoal,
    this.permiteRedirecionar = false,
    this.alvosPermitidos = const [TipoAlvoPermitido.criatura],
    required this.alvos,
    this.areaPersistenteId,
    required this.duracao,
    required this.estado,
    required this.inicio,
    this.expiraEmSegundos,
    this.expiraNaRodada,
    this.modificadores = const [],
    this.penalidadePMId,
    this.sustentacao,
    this.descarga,
    this.motivoFim,
    this.historico = const [],
    this.tipos = const {},
    this.ignoraReducaoDano = false,
    this.historicoResistencia = const {},
    this.desacreditadoPor = const {},
  });

  bool get estaEmJogo =>
      estado == EstadoEfeito.ativo || estado == EstadoEfeito.dormente;

  EfeitoAtivo copyWith({
    String? id,
    String? habilidadeId,
    String? nomeHabilidade,
    String? usuarioId,
    bool? ehMagia,
    AlcanceHabilidade? alcance,
    bool? permiteRedirecionar,
    List<TipoAlvoPermitido>? alvosPermitidos,
    List<String>? alvos,
    String? areaPersistenteId,
    Duracao? duracao,
    EstadoEfeito? estado,
    InicioEfeito? inicio,
    int? expiraEmSegundos,
    int? expiraNaRodada,
    List<ModificadorAplicado>? modificadores,
    String? penalidadePMId,
    SustentacaoEfeito? sustentacao,
    DescargaEfeito? descarga,
    MotivoFimEfeito? motivoFim,
    List<String>? historico,
    Set<TipoEfeito>? tipos,
    bool? ignoraReducaoDano,
    Map<String, ResultadoResistencia>? historicoResistencia,
    Set<String>? desacreditadoPor,
  }) {
    return EfeitoAtivo(
      id: id ?? this.id,
      habilidadeId: habilidadeId ?? this.habilidadeId,
      nomeHabilidade: nomeHabilidade ?? this.nomeHabilidade,
      usuarioId: usuarioId ?? this.usuarioId,
      ehMagia: ehMagia ?? this.ehMagia,
      alcance: alcance ?? this.alcance,
      permiteRedirecionar: permiteRedirecionar ?? this.permiteRedirecionar,
      alvosPermitidos: alvosPermitidos ?? this.alvosPermitidos,
      alvos: alvos ?? this.alvos,
      areaPersistenteId: areaPersistenteId ?? this.areaPersistenteId,
      duracao: duracao ?? this.duracao,
      estado: estado ?? this.estado,
      inicio: inicio ?? this.inicio,
      expiraEmSegundos: expiraEmSegundos ?? this.expiraEmSegundos,
      expiraNaRodada: expiraNaRodada ?? this.expiraNaRodada,
      modificadores: modificadores ?? this.modificadores,
      penalidadePMId: penalidadePMId ?? this.penalidadePMId,
      sustentacao: sustentacao ?? this.sustentacao,
      descarga: descarga ?? this.descarga,
      motivoFim: motivoFim ?? this.motivoFim,
      historico: historico ?? this.historico,
      tipos: tipos ?? this.tipos,
      ignoraReducaoDano: ignoraReducaoDano ?? this.ignoraReducaoDano,
      historicoResistencia: historicoResistencia ?? this.historicoResistencia,
      desacreditadoPor: desacreditadoPor ?? this.desacreditadoPor,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'habilidadeId': habilidadeId,
        'nomeHabilidade': nomeHabilidade,
        'usuarioId': usuarioId,
        'ehMagia': ehMagia,
        'alcance': alcance.name,
        'permiteRedirecionar': permiteRedirecionar,
        'alvosPermitidos': alvosPermitidos.map((e) => e.name).toList(),
        'alvos': alvos,
        'areaPersistenteId': areaPersistenteId,
        'duracao': duracao.toJson(),
        'estado': estado.name,
        'inicio': inicio.toJson(),
        'expiraEmSegundos': expiraEmSegundos,
        'expiraNaRodada': expiraNaRodada,
        'modificadores': modificadores.map((m) => m.toJson()).toList(),
        'penalidadePMId': penalidadePMId,
        'sustentacao': sustentacao?.toJson(),
        'descarga': descarga?.toJson(),
        'motivoFim': motivoFim?.name,
        'historico': historico,
        'tipos': tipos.map((e) => e.name).toList(),
        'ignoraReducaoDano': ignoraReducaoDano,
        'historicoResistencia': historicoResistencia.map(
          (k, v) => MapEntry(k, v.toJson()),
        ),
        'desacreditadoPor': desacreditadoPor.toList(),
      };

  factory EfeitoAtivo.fromJson(Map<String, dynamic> json) {
    return EfeitoAtivo(
      id: json['id'] as String,
      habilidadeId: json['habilidadeId'] as String,
      nomeHabilidade: json['nomeHabilidade'] as String? ?? '',
      usuarioId: json['usuarioId'] as String,
      ehMagia: json['ehMagia'] as bool? ?? false,
      alcance: AlcanceHabilidade.values.firstWhere(
        (e) => e.name == json['alcance'],
        orElse: () => AlcanceHabilidade.pessoal,
      ),
      permiteRedirecionar: json['permiteRedirecionar'] as bool? ?? false,
      alvosPermitidos: (json['alvosPermitidos'] as List<dynamic>? ?? [])
          .map(
            (e) => TipoAlvoPermitido.values.firstWhere(
              (t) => t.name == e,
              orElse: () => TipoAlvoPermitido.criatura,
            ),
          )
          .toList(),
      alvos: (json['alvos'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      areaPersistenteId: json['areaPersistenteId'] as String?,
      duracao: Duracao.fromJson(json['duracao'] as Map<String, dynamic>),
      estado: EstadoEfeito.values.firstWhere(
        (e) => e.name == json['estado'],
        orElse: () => EstadoEfeito.ativo,
      ),
      inicio: InicioEfeito.fromJson(json['inicio'] as Map<String, dynamic>),
      expiraEmSegundos: json['expiraEmSegundos'] as int?,
      expiraNaRodada: json['expiraNaRodada'] as int?,
      modificadores: (json['modificadores'] as List<dynamic>? ?? [])
          .map(
            (e) => ModificadorAplicado.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      penalidadePMId: json['penalidadePMId'] as String?,
      sustentacao: json['sustentacao'] != null
          ? SustentacaoEfeito.fromJson(
              json['sustentacao'] as Map<String, dynamic>,
            )
          : null,
      descarga: json['descarga'] != null
          ? DescargaEfeito.fromJson(json['descarga'] as Map<String, dynamic>)
          : null,
      motivoFim: json['motivoFim'] != null
          ? MotivoFimEfeito.values.firstWhere(
              (e) => e.name == json['motivoFim'],
              orElse: () => MotivoFimEfeito.outro,
            )
          : null,
      historico: (json['historico'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      tipos: (json['tipos'] as List<dynamic>? ?? [])
          .map((e) => TipoEfeito.values.firstWhere(
                (t) => t.name == e,
                orElse: () => TipoEfeito.dano,
              ))
          .toSet(),
      ignoraReducaoDano: json['ignoraReducaoDano'] as bool? ?? false,
      historicoResistencia: (json['historicoResistencia']
                  as Map<String, dynamic>? ??
              {})
          .map((k, v) => MapEntry(
              k, ResultadoResistencia.fromJson(v as Map<String, dynamic>))),
      desacreditadoPor: (json['desacreditadoPor'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toSet(),
    );
  }
}

/// R44: Área persistente no mapa vinculada a um [EfeitoAtivo].
class AreaPersistente {
  final String id;
  final String efeitoId;
  final String usuarioId;
  final AlcanceHabilidade alcanceHabilidade;
  final List<TipoAlvoPermitido> alvosPermitidos;
  final Area area;
  final Set<String> alvosDentro;

  const AreaPersistente({
    required this.id,
    required this.efeitoId,
    required this.usuarioId,
    this.alcanceHabilidade = AlcanceHabilidade.curto,
    this.alvosPermitidos = const [TipoAlvoPermitido.criatura],
    required this.area,
    this.alvosDentro = const {},
  });

  AreaPersistente copyWith({
    String? id,
    String? efeitoId,
    String? usuarioId,
    AlcanceHabilidade? alcanceHabilidade,
    List<TipoAlvoPermitido>? alvosPermitidos,
    Area? area,
    Set<String>? alvosDentro,
  }) {
    return AreaPersistente(
      id: id ?? this.id,
      efeitoId: efeitoId ?? this.efeitoId,
      usuarioId: usuarioId ?? this.usuarioId,
      alcanceHabilidade: alcanceHabilidade ?? this.alcanceHabilidade,
      alvosPermitidos: alvosPermitidos ?? this.alvosPermitidos,
      area: area ?? this.area,
      alvosDentro: alvosDentro ?? this.alvosDentro,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'efeitoId': efeitoId,
        'usuarioId': usuarioId,
        'alcanceHabilidade': alcanceHabilidade.name,
        'alvosPermitidos': alvosPermitidos.map((e) => e.name).toList(),
        'area': area.toJson(),
        'alvosDentro': alvosDentro.toList(),
      };

  factory AreaPersistente.fromJson(Map<String, dynamic> json) {
    return AreaPersistente(
      id: json['id'] as String,
      efeitoId: json['efeitoId'] as String,
      usuarioId: json['usuarioId'] as String? ?? '',
      alcanceHabilidade: AlcanceHabilidade.values.firstWhere(
        (e) => e.name == json['alcanceHabilidade'],
        orElse: () => AlcanceHabilidade.curto,
      ),
      alvosPermitidos: (json['alvosPermitidos'] as List<dynamic>? ?? [])
          .map(
            (e) => TipoAlvoPermitido.values.firstWhere(
              (t) => t.name == e,
              orElse: () => TipoAlvoPermitido.criatura,
            ),
          )
          .toList(),
      area: Area.fromJson(json['area'] as Map<String, dynamic>),
      alvosDentro: (json['alvosDentro'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toSet(),
    );
  }
}

/// R33: Segmento geométrico `(x1, y1) -> (x2, y2)` em coordenadas de grid para raycast.
class SegmentoBarreira {
  final double x1;
  final double y1;
  final double x2;
  final double y2;

  const SegmentoBarreira({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
  });

  Map<String, dynamic> toJson() => {
        'x1': x1,
        'y1': y1,
        'x2': x2,
        'y2': y2,
      };

  factory SegmentoBarreira.fromJson(Map<String, dynamic> json) {
    return SegmentoBarreira(
      x1: (json['x1'] as num).toDouble(),
      y1: (json['y1'] as num).toDouble(),
      x2: (json['x2'] as num).toDouble(),
      y2: (json['y2'] as num).toDouble(),
    );
  }
}

/// R33 (Caso de Borda 14): Barreira ou parede no mapa.
/// Qualquer barreira com `bloqueiaLinhaEfeito == true` (visível ou invisível) bloqueia a linha de efeito.
class Barreira {
  final String id;
  final List<SegmentoBarreira> segmentos;
  final bool bloqueiaLinhaEfeito;
  final bool visivel;
  final bool mestreSobrescreveuDesbloqueio;

  const Barreira({
    required this.id,
    required this.segmentos,
    this.bloqueiaLinhaEfeito = true,
    this.visivel = true,
    this.mestreSobrescreveuDesbloqueio = false,
  });

  bool get bloqueiaEfetivamente =>
      bloqueiaLinhaEfeito && !mestreSobrescreveuDesbloqueio;

  Barreira copyWith({
    String? id,
    List<SegmentoBarreira>? segmentos,
    bool? bloqueiaLinhaEfeito,
    bool? visivel,
    bool? mestreSobrescreveuDesbloqueio,
  }) {
    return Barreira(
      id: id ?? this.id,
      segmentos: segmentos ?? this.segmentos,
      bloqueiaLinhaEfeito: bloqueiaLinhaEfeito ?? this.bloqueiaLinhaEfeito,
      visivel: visivel ?? this.visivel,
      mestreSobrescreveuDesbloqueio:
          mestreSobrescreveuDesbloqueio ?? this.mestreSobrescreveuDesbloqueio,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'segmentos': segmentos.map((s) => s.toJson()).toList(),
        'bloqueiaLinhaEfeito': bloqueiaLinhaEfeito,
        'visivel': visivel,
        'mestreSobrescreveuDesbloqueio': mestreSobrescreveuDesbloqueio,
      };

  factory Barreira.fromJson(Map<String, dynamic> json) {
    return Barreira(
      id: json['id'] as String,
      segmentos: (json['segmentos'] as List<dynamic>? ?? [])
          .map((e) => SegmentoBarreira.fromJson(e as Map<String, dynamic>))
          .toList(),
      bloqueiaLinhaEfeito: json['bloqueiaLinhaEfeito'] as bool? ?? true,
      visivel: json['visivel'] as bool? ?? true,
      mestreSobrescreveuDesbloqueio:
          json['mestreSobrescreveuDesbloqueio'] as bool? ?? false,
    );
  }
}

/// R32: Representação de um token (criatura ou objeto) posicionado no grid.
class AlvoMapa {
  final String id;
  final String nome;
  final TipoAlvoPermitido tipo;
  final Posicao2D posicao;
  final int elevacaoQuadrados;
  final CategoriaTamanho tamanho;
  final int espacosObjeto;
  final bool percebidoPeloUsuario;
  final int pvAtual;
  final int pvMax;

  const AlvoMapa({
    required this.id,
    this.nome = '',
    this.tipo = TipoAlvoPermitido.criatura,
    required this.posicao,
    this.elevacaoQuadrados = 0,
    this.tamanho = CategoriaTamanho.medio,
    this.espacosObjeto = 1,
    this.percebidoPeloUsuario = true,
    this.pvAtual = 20,
    this.pvMax = 20,
  });

  AlvoMapa copyWith({
    String? id,
    String? nome,
    TipoAlvoPermitido? tipo,
    Posicao2D? posicao,
    int? elevacaoQuadrados,
    CategoriaTamanho? tamanho,
    int? espacosObjeto,
    bool? percebidoPeloUsuario,
    int? pvAtual,
    int? pvMax,
  }) {
    return AlvoMapa(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      tipo: tipo ?? this.tipo,
      posicao: posicao ?? this.posicao,
      elevacaoQuadrados: elevacaoQuadrados ?? this.elevacaoQuadrados,
      tamanho: tamanho ?? this.tamanho,
      espacosObjeto: espacosObjeto ?? this.espacosObjeto,
      percebidoPeloUsuario: percebidoPeloUsuario ?? this.percebidoPeloUsuario,
      pvAtual: pvAtual ?? this.pvAtual,
      pvMax: pvMax ?? this.pvMax,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'tipo': tipo.name,
        'posicao': {'x': posicao.x, 'y': posicao.y},
        'elevacaoQuadrados': elevacaoQuadrados,
        'tamanho': tamanho.name,
        'espacosObjeto': espacosObjeto,
        'percebidoPeloUsuario': percebidoPeloUsuario,
        'pvAtual': pvAtual,
        'pvMax': pvMax,
      };

  factory AlvoMapa.fromJson(Map<String, dynamic> json) {
    final pos = json['posicao'] as Map<String, dynamic>;
    return AlvoMapa(
      id: json['id'] as String,
      nome: json['nome'] as String? ?? '',
      tipo: TipoAlvoPermitido.values.firstWhere(
        (e) => e.name == json['tipo'],
        orElse: () => TipoAlvoPermitido.criatura,
      ),
      posicao: Posicao2D(pos['x'] as int, pos['y'] as int),
      elevacaoQuadrados: json['elevacaoQuadrados'] as int? ?? 0,
      tamanho: CategoriaTamanho.values.firstWhere(
        (e) => e.name == json['tamanho'],
        orElse: () => CategoriaTamanho.medio,
      ),
      espacosObjeto: json['espacosObjeto'] as int? ?? 1,
      percebidoPeloUsuario: json['percebidoPeloUsuario'] as bool? ?? true,
      pvAtual: json['pvAtual'] as int? ?? 20,
      pvMax: json['pvMax'] as int? ?? 20,
    );
  }
}

/// R28 (Caso de Borda 20): Item no inventário com flag `emMaos` para componentes materiais.
class ItemComponenteInventario {
  final String id;
  final String nome;
  final bool emMaos;
  final int quantidade;

  const ItemComponenteInventario({
    required this.id,
    required this.nome,
    this.emMaos = false,
    this.quantidade = 1,
  });

  ItemComponenteInventario copyWith({
    String? id,
    String? nome,
    bool? emMaos,
    int? quantidade,
  }) {
    return ItemComponenteInventario(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      emMaos: emMaos ?? this.emMaos,
      quantidade: quantidade ?? this.quantidade,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'emMaos': emMaos,
        'quantidade': quantidade,
      };

  factory ItemComponenteInventario.fromJson(Map<String, dynamic> json) {
    return ItemComponenteInventario(
      id: json['id'] as String,
      nome: json['nome'] as String? ?? '',
      emMaos: json['emMaos'] as bool? ?? false,
      quantidade: json['quantidade'] as int? ?? 1,
    );
  }
}

/// Estado do personagem relevante para o pipeline de habilidades e duração.
class EstadoPersonagemHabilidade {
  final String id;
  final int nivelTotal;
  final Map<String, int> niveisPorClasse;
  final PMState pmState;
  final List<ItemComponenteInventario> inventario;
  final Posicao2D posicao;
  final int elevacaoQuadrados;
  final int pvAtual;
  final int pvMax;
  final Map<String, int> modPericias;
  final bool vivo;

  const EstadoPersonagemHabilidade({
    required this.id,
    this.nivelTotal = 1,
    this.niveisPorClasse = const {},
    required this.pmState,
    this.inventario = const [],
    this.posicao = const Posicao2D(0, 0),
    this.elevacaoQuadrados = 0,
    this.pvAtual = 20,
    this.pvMax = 20,
    this.modPericias = const {},
    this.vivo = true,
  });

  EstadoPersonagemHabilidade copyWith({
    String? id,
    int? nivelTotal,
    Map<String, int>? niveisPorClasse,
    PMState? pmState,
    List<ItemComponenteInventario>? inventario,
    Posicao2D? posicao,
    int? elevacaoQuadrados,
    int? pvAtual,
    int? pvMax,
    Map<String, int>? modPericias,
    bool? vivo,
  }) {
    return EstadoPersonagemHabilidade(
      id: id ?? this.id,
      nivelTotal: nivelTotal ?? this.nivelTotal,
      niveisPorClasse: niveisPorClasse ?? this.niveisPorClasse,
      pmState: pmState ?? this.pmState,
      inventario: inventario ?? this.inventario,
      posicao: posicao ?? this.posicao,
      elevacaoQuadrados: elevacaoQuadrados ?? this.elevacaoQuadrados,
      pvAtual: pvAtual ?? this.pvAtual,
      pvMax: pvMax ?? this.pvMax,
      modPericias: modPericias ?? this.modPericias,
      vivo: vivo ?? this.vivo,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nivelTotal': nivelTotal,
        'niveisPorClasse': niveisPorClasse,
        'pmState': pmState.toJson(),
        'inventario': inventario.map((i) => i.toJson()).toList(),
        'posicao': {'x': posicao.x, 'y': posicao.y},
        'elevacaoQuadrados': elevacaoQuadrados,
        'pvAtual': pvAtual,
        'pvMax': pvMax,
        'modPericias': modPericias,
        'vivo': vivo,
      };

  factory EstadoPersonagemHabilidade.fromJson(Map<String, dynamic> json) {
    final pos = json['posicao'] as Map<String, dynamic>?;
    return EstadoPersonagemHabilidade(
      id: json['id'] as String,
      nivelTotal: json['nivelTotal'] as int? ?? 1,
      niveisPorClasse:
          (json['niveisPorClasse'] as Map<String, dynamic>? ?? {}).map(
        (k, v) => MapEntry(k, v as int),
      ),
      pmState: PMState.fromJson(json['pmState'] as Map<String, dynamic>),
      inventario: (json['inventario'] as List<dynamic>? ?? [])
          .map(
            (e) => ItemComponenteInventario.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
      posicao: pos != null
          ? Posicao2D(pos['x'] as int, pos['y'] as int)
          : const Posicao2D(0, 0),
      elevacaoQuadrados: json['elevacaoQuadrados'] as int? ?? 0,
      pvAtual: json['pvAtual'] as int? ?? 20,
      pvMax: json['pvMax'] as int? ?? 20,
      modPericias: (json['modPericias'] as Map<String, dynamic>? ?? {}).map(
        (k, v) => MapEntry(k, v as int),
      ),
      vivo: json['vivo'] as bool? ?? true,
    );
  }
}

/// R40: Cena ativa na mesa.
class Cena {
  final String id;
  final String nome;
  final bool ativa;
  final int inicioSegundos;

  const Cena({
    required this.id,
    required this.nome,
    this.ativa = true,
    this.inicioSegundos = 0,
  });

  Cena copyWith({
    String? id,
    String? nome,
    bool? ativa,
    int? inicioSegundos,
  }) {
    return Cena(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      ativa: ativa ?? this.ativa,
      inicioSegundos: inicioSegundos ?? this.inicioSegundos,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'ativa': ativa,
        'inicioSegundos': inicioSegundos,
      };

  factory Cena.fromJson(Map<String, dynamic> json) {
    return Cena(
      id: json['id'] as String,
      nome: json['nome'] as String? ?? 'Cena',
      ativa: json['ativa'] as bool? ?? true,
      inicioSegundos: json['inicioSegundos'] as int? ?? 0,
    );
  }
}

/// R42: Relógio único de tempo em segundos de jogo e rodada atual.
class RelogioDeJogo {
  final int tempoSegundos;
  final int rodadaAtual;
  final int segundosPorRodada;

  const RelogioDeJogo({
    this.tempoSegundos = 0,
    this.rodadaAtual = 1,
    this.segundosPorRodada = 6,
  });

  RelogioDeJogo copyWith({
    int? tempoSegundos,
    int? rodadaAtual,
    int? segundosPorRodada,
  }) {
    return RelogioDeJogo(
      tempoSegundos: tempoSegundos ?? this.tempoSegundos,
      rodadaAtual: rodadaAtual ?? this.rodadaAtual,
      segundosPorRodada: segundosPorRodada ?? this.segundosPorRodada,
    );
  }

  Map<String, dynamic> toJson() => {
        'tempoSegundos': tempoSegundos,
        'rodadaAtual': rodadaAtual,
        'segundosPorRodada': segundosPorRodada,
      };

  factory RelogioDeJogo.fromJson(Map<String, dynamic> json) {
    return RelogioDeJogo(
      tempoSegundos: json['tempoSegundos'] as int? ?? 0,
      rodadaAtual: json['rodadaAtual'] as int? ?? 1,
      segundosPorRodada: json['segundosPorRodada'] as int? ?? 6,
    );
  }
}

/// R23 e R45: Evento genérico de jogo usado para engatilhar reações e descargas.
class EventoDeJogo {
  final String id;
  final String tipo;
  final Map<String, dynamic> dados;

  const EventoDeJogo({
    required this.id,
    required this.tipo,
    this.dados = const {},
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'tipo': tipo,
        'dados': dados,
      };

  factory EventoDeJogo.fromJson(Map<String, dynamic> json) {
    return EventoDeJogo(
      id: json['id'] as String,
      tipo: json['tipo'] as String,
      dados: Map<String, dynamic>.from(json['dados'] as Map? ?? const {}),
    );
  }
}

/// R41: Pendência emitida no início do turno do usuário para manutenção de habilidades sustentadas.
class SustentacaoPendente {
  final String usuarioId;
  final List<String> efeitoIds;

  const SustentacaoPendente({
    required this.usuarioId,
    required this.efeitoIds,
  });

  Map<String, dynamic> toJson() => {
        'usuarioId': usuarioId,
        'efeitoIds': efeitoIds,
      };

  factory SustentacaoPendente.fromJson(Map<String, dynamic> json) {
    return SustentacaoPendente(
      usuarioId: json['usuarioId'] as String,
      efeitoIds: (json['efeitoIds'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
    );
  }
}

/// R37: Resultado retornado pelo pipeline de ativação ([HabilidadeEngine]).
class ResultadoAtivacao {
  final String habilidadeId;
  final bool bloqueada;
  final String? motivo;
  final int custoPago;
  final bool falhou;
  final String? motivoFalha;
  final List<String> alvosAfetados;
  final String? efeitoId;
  final String? tokenCriadoId;
  final bool aguardandoAprovacaoMestreIlimitado;
  final RollResult? resultadoTestePercepcaoArea;
  final List<String> avisosConfirmacao;
  final List<Map<String, dynamic>> eventosGerados;
  final String logDetalhado;

  // --- MÓDULO 3: RESISTÊNCIA E IMUNIDADE (R50–R58) ---
  final List<ResultadoResistencia> resultadosResistencia;
  final List<String> motivosImunidade;

  const ResultadoAtivacao({
    required this.habilidadeId,
    this.bloqueada = false,
    this.motivo,
    this.custoPago = 0,
    this.falhou = false,
    this.motivoFalha,
    this.alvosAfetados = const [],
    this.efeitoId,
    this.tokenCriadoId,
    this.aguardandoAprovacaoMestreIlimitado = false,
    this.resultadoTestePercepcaoArea,
    this.avisosConfirmacao = const [],
    this.eventosGerados = const [],
    this.logDetalhado = '',
    this.resultadosResistencia = const [],
    this.motivosImunidade = const [],
  });

  Map<String, dynamic> toJson() => {
        'habilidadeId': habilidadeId,
        'bloqueada': bloqueada,
        'motivo': motivo,
        'custoPago': custoPago,
        'falhou': falhou,
        'motivoFalha': motivoFalha,
        'alvosAfetados': alvosAfetados,
        'efeitoId': efeitoId,
        'tokenCriadoId': tokenCriadoId,
        'aguardandoAprovacaoMestreIlimitado':
            aguardandoAprovacaoMestreIlimitado,
        'resultadoTestePercepcaoArea':
            resultadoTestePercepcaoArea?.toJson(),
        'avisosConfirmacao': avisosConfirmacao,
        'eventosGerados': eventosGerados,
        'logDetalhado': logDetalhado,
        'resultadosResistencia':
            resultadosResistencia.map((r) => r.toJson()).toList(),
        'motivosImunidade': motivosImunidade,
      };
}
