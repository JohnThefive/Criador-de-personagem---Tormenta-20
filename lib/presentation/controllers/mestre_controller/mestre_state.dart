import '../../../domain/entities/combate/grid_tatico.dart';
import '../../../domain/entities/mestre/modelos_mestre.dart';

/// Ferramenta ativa no Editor / Controlador de Mapa de Batalha do Mestre.
enum FerramentaMapaMestre {
  moverPersonagens('Mover Personagens', 'Toque em um herói e mova-o pelo grid tático.'),
  posicionarTokens('Posicionar Elenco', 'Toque em uma célula para posicionar o personagem selecionado.'),
  pintarTerreno('Pintar Terreno', 'Altere células entre Normal, Difícil (3m) e Obstáculo.'),
  nevoaDeGuerra('Fog of War (Revelar)', 'Toque nas células para revelar ou ocultar para os jogadores.');

  final String rotulo;
  final String dica;
  const FerramentaMapaMestre(this.rotulo, this.dica);
}

class MestreState {
  final List<CampanhaMestre> campanhas;
  final String? campanhaSelecionadaId;
  final String? aventuraSelecionadaId;
  final String? sessaoSelecionadaId;
  final String? mapaSelecionadoId;

  // Estado Frontend de Conexão LAN (ADR-004 UI)
  final StatusConexaoLan statusLan;
  final String ipHostLocal;
  final int portaHostLan;
  final List<String> logsRedeLan;

  // Estado do Editor e Controlador de Mapa de Batalha (RF-M6, RF-M7)
  final FerramentaMapaMestre ferramentaMapa;
  final TipoTerreno pincelTerreno;
  final String? tokenSelecionadoParaMoverId;
  final String? heroiSelecionadoParaPosicionarId;
  final Set<Posicao2D> celulasAlcancaveisToken;
  final Map<Posicao2D, double> custosMovimentoToken;
  final bool movimentoLivreMestre;
  final PapelView papelVisualizacao;

  // Escudo do Mestre (RF-M4)
  final List<RegraCard> regrasRapidas;
  final String buscaRegra;
  final List<PerigoMestre> perigos;
  final List<String> historicoNomes;
  final String? nomeGeradoAtual;
  final List<String> nomesFavoritos;

  // Estado da Mesa de Jogo (Parte 4)
  final bool enviandoMapaAosJogadores;
  final DateTime? ultimoEnvioMapa;
  final Posicao2D? pontoOrigemMedicao;
  final Posicao2D? pontoDestinoMedicao;
  final List<Posicao2D> pingsAtivos;

  const MestreState({
    required this.campanhas,
    this.campanhaSelecionadaId,
    this.aventuraSelecionadaId,
    this.sessaoSelecionadaId,
    this.mapaSelecionadoId,
    this.statusLan = StatusConexaoLan.desligado,
    this.ipHostLocal = '192.168.1.104',
    this.portaHostLan = 7777,
    this.logsRedeLan = const [],
    this.ferramentaMapa = FerramentaMapaMestre.moverPersonagens,
    this.pincelTerreno = TipoTerreno.obstaculo,
    this.tokenSelecionadoParaMoverId,
    this.heroiSelecionadoParaPosicionarId,
    this.celulasAlcancaveisToken = const {},
    this.custosMovimentoToken = const {},
    this.movimentoLivreMestre = false,
    this.papelVisualizacao = const VisaoMestre(),
    this.regrasRapidas = const [],
    this.buscaRegra = '',
    this.perigos = const [],
    this.historicoNomes = const [],
    this.nomeGeradoAtual,
    this.nomesFavoritos = const [],
    this.enviandoMapaAosJogadores = false,
    this.ultimoEnvioMapa,
    this.pontoOrigemMedicao,
    this.pontoDestinoMedicao,
    this.pingsAtivos = const [],
  });

  CampanhaMestre? get campanhaAtual {
    if (campanhas.isEmpty) return null;
    return campanhas
            .where((c) => c.id == campanhaSelecionadaId)
            .firstOrNull ??
        campanhas.first;
  }

  AventuraMestre? get aventuraAtual {
    final camp = campanhaAtual;
    if (camp == null || camp.aventuras.isEmpty) return null;
    return camp.aventuras
            .where((a) => a.id == aventuraSelecionadaId)
            .firstOrNull ??
        camp.aventuras.first;
  }

  SessaoJogo? get sessaoAtual {
    final av = aventuraAtual;
    if (av == null || av.sessoes.isEmpty) return null;
    return av.sessoes
            .where((s) => s.id == sessaoSelecionadaId)
            .firstOrNull ??
        av.sessoes.first;
  }

  MapaBatalhaMestre? get mapaAtual {
    final av = aventuraAtual;
    if (av == null || av.mapas.isEmpty) return null;
    final idAlvo = mapaSelecionadoId ?? sessaoAtual?.mapaAtivoId;
    return av.mapas.where((m) => m.id == idAlvo).firstOrNull ?? av.mapas.first;
  }

  /// Retorna o mapa projetado conforme o papel atual (Visão do Mestre vs Ver como Jogador).
  MapaBatalhaMestre? get mapaProjetado {
    final m = mapaAtual;
    if (m == null) return null;
    return projectMapaFor(papelVisualizacao, m);
  }

  bool get estaEmPreviewJogador => papelVisualizacao is! VisaoMestre;

  MestreState copyWith({
    List<CampanhaMestre>? campanhas,
    String? campanhaSelecionadaId,
    String? aventuraSelecionadaId,
    String? sessaoSelecionadaId,
    String? mapaSelecionadoId,
    StatusConexaoLan? statusLan,
    String? ipHostLocal,
    int? portaHostLan,
    List<String>? logsRedeLan,
    FerramentaMapaMestre? ferramentaMapa,
    TipoTerreno? pincelTerreno,
    String? tokenSelecionadoParaMoverId,
    bool limparTokenSelecionado = false,
    String? heroiSelecionadoParaPosicionarId,
    Set<Posicao2D>? celulasAlcancaveisToken,
    Map<Posicao2D, double>? custosMovimentoToken,
    bool? movimentoLivreMestre,
    PapelView? papelVisualizacao,
    List<RegraCard>? regrasRapidas,
    String? buscaRegra,
    List<PerigoMestre>? perigos,
    List<String>? historicoNomes,
    String? nomeGeradoAtual,
    List<String>? nomesFavoritos,
    bool? enviandoMapaAosJogadores,
    DateTime? ultimoEnvioMapa,
    Posicao2D? pontoOrigemMedicao,
    bool limparMedicao = false,
    Posicao2D? pontoDestinoMedicao,
    List<Posicao2D>? pingsAtivos,
  }) {
    return MestreState(
      campanhas: campanhas ?? this.campanhas,
      campanhaSelecionadaId:
          campanhaSelecionadaId ?? this.campanhaSelecionadaId,
      aventuraSelecionadaId:
          aventuraSelecionadaId ?? this.aventuraSelecionadaId,
      sessaoSelecionadaId: sessaoSelecionadaId ?? this.sessaoSelecionadaId,
      mapaSelecionadoId: mapaSelecionadoId ?? this.mapaSelecionadoId,
      statusLan: statusLan ?? this.statusLan,
      ipHostLocal: ipHostLocal ?? this.ipHostLocal,
      portaHostLan: portaHostLan ?? this.portaHostLan,
      logsRedeLan: logsRedeLan ?? this.logsRedeLan,
      ferramentaMapa: ferramentaMapa ?? this.ferramentaMapa,
      pincelTerreno: pincelTerreno ?? this.pincelTerreno,
      tokenSelecionadoParaMoverId: limparTokenSelecionado
          ? null
          : (tokenSelecionadoParaMoverId ?? this.tokenSelecionadoParaMoverId),
      heroiSelecionadoParaPosicionarId: heroiSelecionadoParaPosicionarId ??
          this.heroiSelecionadoParaPosicionarId,
      celulasAlcancaveisToken:
          celulasAlcancaveisToken ?? this.celulasAlcancaveisToken,
      custosMovimentoToken: custosMovimentoToken ?? this.custosMovimentoToken,
      movimentoLivreMestre: movimentoLivreMestre ?? this.movimentoLivreMestre,
      papelVisualizacao: papelVisualizacao ?? this.papelVisualizacao,
      regrasRapidas: regrasRapidas ?? this.regrasRapidas,
      buscaRegra: buscaRegra ?? this.buscaRegra,
      perigos: perigos ?? this.perigos,
      historicoNomes: historicoNomes ?? this.historicoNomes,
      nomeGeradoAtual: nomeGeradoAtual ?? this.nomeGeradoAtual,
      nomesFavoritos: nomesFavoritos ?? this.nomesFavoritos,
      enviandoMapaAosJogadores:
          enviandoMapaAosJogadores ?? this.enviandoMapaAosJogadores,
      ultimoEnvioMapa: ultimoEnvioMapa ?? this.ultimoEnvioMapa,
      pontoOrigemMedicao:
          limparMedicao ? null : (pontoOrigemMedicao ?? this.pontoOrigemMedicao),
      pontoDestinoMedicao:
          limparMedicao ? null : (pontoDestinoMedicao ?? this.pontoDestinoMedicao),
      pingsAtivos: pingsAtivos ?? this.pingsAtivos,
    );
  }
}
