import 'classe.dart';
import 'poder.dart'; 
import 'linhagem_arcanista.dart';

class ClasseDoPersonagem {
  final Classe classeDefinicao; // Referência à regra (Bárbaro)
  final int nivel;               // Nível atual nesta classe (ex: 5)
  final List<Poder> poderesEscolhidos;
  final CaminhoDeClasse? caminhoEscolhido;
  final Linhagem? linhagemEscolhida;


  //

  ClasseDoPersonagem({
    required this.classeDefinicao,
    required this.nivel,
    this.caminhoEscolhido,
    this.poderesEscolhidos = const [],
    this.linhagemEscolhida,
  });

  ClasseDoPersonagem copyWith({
    int? nivel, 
    CaminhoDeClasse? caminhoEscolhido,
    List<Poder>? poderesEscolhidos,
    Linhagem? linhagemEscolhida,
    
    }) {
    return ClasseDoPersonagem(
      classeDefinicao: classeDefinicao,
      nivel: nivel ?? this.nivel,
      caminhoEscolhido: caminhoEscolhido ?? this.caminhoEscolhido,
      poderesEscolhidos: poderesEscolhidos ?? this.poderesEscolhidos,
      linhagemEscolhida: linhagemEscolhida ?? this.linhagemEscolhida,
    );
  }

  bool get possuiHerancaBasica => linhagemEscolhida != null;
  bool get possuiHerancaAprimorada => poderesEscolhidos.any((p) => p.nome == "Herança Aprimorada");
  bool get possuiHerancaSuperior => poderesEscolhidos.any((p) => p.nome == "Herança Superior");



}