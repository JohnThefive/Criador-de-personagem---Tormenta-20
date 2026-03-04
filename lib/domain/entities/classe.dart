import 'proficiencias.dart';

// isso deve servir pra outras classes que tem caminhos (barbaro, arcanista, etc)
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
}

class Classe {
  final String nome;
  final int pvInicial;   
  final int pvPorNivel;  
  final int pmInicial; // Adicionado para a regra do Nível 1
  final int pmPorNivel;  

  final String descricaoclasse;
  
  
  final List<TipoProficiencia> proficiencias;
  final List<String> periciasFixas; 
  final List<String> periciasOpcoes; 
  final int qtdPericiasEscolha; 

  // flags para descrição e imagem 
  final String caminhoImagem;

  // Tabela de progressão (toda classe tem)
  final Map<int, List<String>> tabelaDeProgressao;
  
  // A classe pode ter caminhos para escolher no Nível 1 (Ex: Arcanista)
  final List<CaminhoDeClasse> caminhosDisponiveis;

  final Map<String, String> habilidadesFixas; // Ex: Fúria, Instinto Selvagem
  final Map<String, String> poderesDaClasse;  // Ex: Alma de Bronze, Frenesi

  const Classe({
    required this.nome,
    required this.pvInicial,
    required this.pvPorNivel,
    required this.pmInicial,
    required this.pmPorNivel,
    required this.proficiencias,
    required this.periciasFixas,
    required this.periciasOpcoes,
    required this.qtdPericiasEscolha,
    this.caminhosDisponiveis = const [],
    this.tabelaDeProgressao = const {},
    required this.caminhoImagem, 
    required this.descricaoclasse, 
    this.habilidadesFixas = const {}, 
    this.poderesDaClasse = const {},
    

  });
}