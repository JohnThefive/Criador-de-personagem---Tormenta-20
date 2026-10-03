import 'package:flutter/widgets.dart';
import '../../helpers/icone_rpg_helper.dart';
import 'proficiencias.dart';

// Representa escolhas e caminhos no nível 1 (ex: Bruxo, Feiticeiro, Mago para Arcanista)
class CaminhoDeClasse {
  final String nome;
  final String atributoChave; // 'INT', 'CAR', etc.
  final String descricao;

  // Flags para a UI saber o que renderizar depois (Arcanista)
  final bool temFocoMagico;
  final bool temLinhagem;
  final bool temGrimorio;

  const CaminhoDeClasse({
    required this.nome,
    required this.atributoChave,
    required this.descricao,
    this.temFocoMagico = false,
    this.temLinhagem = false,
    this.temGrimorio = false,
  });

  factory CaminhoDeClasse.fromJson(Map<String, dynamic> json) {
    return CaminhoDeClasse(
      nome: json['nome'] as String? ?? '',
      atributoChave: json['atributoChave'] as String? ?? 'INT',
      descricao: json['descricao'] as String? ?? '',
      temFocoMagico: json['temFocoMagico'] as bool? ?? false,
      temLinhagem: json['temLinhagem'] as bool? ?? false,
      temGrimorio: json['temGrimorio'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'nome': nome,
    'atributoChave': atributoChave,
    'descricao': descricao,
    'temFocoMagico': temFocoMagico,
    'temLinhagem': temLinhagem,
    'temGrimorio': temGrimorio,
  };
}

class Classe {
  final String idClasse;
  final String nome;
  final int pvInicial;
  final int pvPorNivel;
  final int pmInicial;
  final int pmPorNivel;

  final String descricaoclasse;
  final String
  icone; // Chave do ícone serializável (ex: "crystal_ball", "axe", "harp")
  final String caminhoImagem; // Mantido para compatibilidade retroativa

  final List<TipoProficiencia> proficiencias;
  final List<String> periciasFixas;
  final List<String> periciasOpcoes;
  final int qtdPericiasEscolha;

  // Tabela de progressão (nível 1 a 20)
  final Map<int, List<String>> tabelaDeProgressao;

  // A classe pode ter caminhos para escolher no Nível 1
  final List<CaminhoDeClasse> caminhosDisponiveis;

  final Map<String, String> habilidadesFixas;

  const Classe({
    required this.idClasse,
    required this.nome,
    required this.pvInicial,
    required this.pvPorNivel,
    required this.pmInicial,
    required this.pmPorNivel,
    required this.proficiencias,
    required this.periciasFixas,
    required this.periciasOpcoes,
    required this.qtdPericiasEscolha,
    this.icone = 'player',
    this.caminhoImagem = '',
    required this.descricaoclasse,
    this.caminhosDisponiveis = const [],
    this.tabelaDeProgressao = const {},
    this.habilidadesFixas = const {},
  });

  /// Getter conveniente para obter o IconData do RpgAwesome
  IconData get iconeClasse => IconeRpgHelper.obterIcone(icone);

  /// Getter para compatibilidade de nomenclatura id
  String get id => idClasse;

  /// Getter para compatibilidade de nomenclatura descricaoClasse
  String get descricaoClasse => descricaoclasse;

  factory Classe.fromJson(Map<String, dynamic> json) {
    // Parser seguro de proficiências
    final rawProf = json['proficiencias'] as List<dynamic>? ?? [];
    final List<TipoProficiencia> profs = [];
    for (var p in rawProf) {
      final str = p.toString().trim().toLowerCase().replaceAll('_', '');
      for (var tipo in TipoProficiencia.values) {
        final tipoNorm = tipo.name.toLowerCase().replaceAll('_', '');
        if (tipoNorm == str ||
            (str == 'leves' && tipo == TipoProficiencia.armadurasLeves) ||
            (str == 'pesadas' && tipo == TipoProficiencia.armadurasPesadas) ||
            (str == 'simples' && tipo == TipoProficiencia.armasSimples) ||
            (str == 'marciais' && tipo == TipoProficiencia.armasMarciais)) {
          profs.add(tipo);
          break;
        }
      }
    }

    // Parser seguro da tabela de progressão
    final rawProg = json['tabelaDeProgressao'] as Map<String, dynamic>? ?? {};
    final Map<int, List<String>> prog = {};
    rawProg.forEach((k, v) {
      final nivel = int.tryParse(k.toString());
      if (nivel != null && v is List) {
        prog[nivel] = v.map((item) => item.toString()).toList();
      }
    });

    // Parser seguro de caminhos
    final rawCaminhos = json['caminhosDisponiveis'] as List<dynamic>? ?? [];
    final caminhos = rawCaminhos
        .map((c) => CaminhoDeClasse.fromJson(c as Map<String, dynamic>))
        .toList();

    // Parser seguro de habilidades fixas
    final rawHab = json['habilidadesFixas'] as Map<String, dynamic>? ?? {};
    final Map<String, String> habs = rawHab.map(
      (k, v) => MapEntry(k, v.toString()),
    );

    return Classe(
      idClasse: (json['id'] ?? json['idClasse'] ?? '').toString(),
      nome: (json['nome'] ?? '').toString(),
      descricaoclasse:
          (json['descricaoClasse'] ?? json['descricaoclasse'] ?? '').toString(),
      icone: (json['icone'] ?? 'player').toString(),
      caminhoImagem: (json['caminhoImagem'] ?? '').toString(),
      pvInicial: (json['pvInicial'] as num?)?.toInt() ?? 0,
      pvPorNivel: (json['pvPorNivel'] as num?)?.toInt() ?? 0,
      pmInicial: (json['pmInicial'] as num?)?.toInt() ?? 0,
      pmPorNivel: (json['pmPorNivel'] as num?)?.toInt() ?? 0,
      proficiencias: profs,
      periciasFixas:
          (json['periciasFixas'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      qtdPericiasEscolha: (json['qtdPericiasEscolha'] as num?)?.toInt() ?? 0,
      periciasOpcoes:
          (json['periciasOpcoes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      tabelaDeProgressao: prog,
      caminhosDisponiveis: caminhos,
      habilidadesFixas: habs,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': idClasse,
    'nome': nome,
    'descricaoClasse': descricaoclasse,
    'icone': icone,
    'caminhoImagem': caminhoImagem,
    'pvInicial': pvInicial,
    'pvPorNivel': pvPorNivel,
    'pmInicial': pmInicial,
    'pmPorNivel': pmPorNivel,
    'proficiencias': proficiencias.map((p) => p.name).toList(),
    'periciasFixas': periciasFixas,
    'qtdPericiasEscolha': qtdPericiasEscolha,
    'periciasOpcoes': periciasOpcoes,
    'tabelaDeProgressao': tabelaDeProgressao.map(
      (k, v) => MapEntry(k.toString(), v),
    ),
    'caminhosDisponiveis': caminhosDisponiveis.map((c) => c.toJson()).toList(),
    'habilidadesFixas': habilidadesFixas,
  };
}
