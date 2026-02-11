import 'atributos.dart';
import 'raca.dart'; // Importe a raça

class Personagem {
  final String nome;
  final Map<String, Atributo> atributos; // Estes são os atributos BASE (Rolados/Comprados)
  final Raca? raca; // Agora ele pode ter uma raça (ou null no começo)

  Personagem({
    required this.nome, 
    required this.atributos, 
    this.raca
  });

  factory Personagem.inicial() {
    return Personagem(
      nome: 'Novo Aventureiro',
      atributos: {
        'FOR': const Atributo(nome: 'Força', valor: 0),
        'DES': const Atributo(nome: 'Destreza', valor: 0),
        'CON': const Atributo(nome: 'Constituição', valor: 0),
        'INT': const Atributo(nome: 'Inteligência', valor: 0),
        'SAB': const Atributo(nome: 'Sabedoria', valor: 0),
        'CAR': const Atributo(nome: 'Carisma', valor: 0),
      },
      raca: null,
    );
  }

  Personagem copyWith({
    String? nome,
    Map<String, Atributo>? atributos,
    Raca? raca,
  }) {
    return Personagem(
      nome: nome ?? this.nome,
      atributos: atributos ?? this.atributos,
      raca: raca ?? this.raca,
    );
  }

  // Este método calcula o valor final para exibir na tela
  int getValorFinal(String sigla) {
    int base = atributos[sigla]?.valor ?? 0;
    
    // Se tiver raça e ela tiver modificador para esse atributo, soma.
    int bonusRaca = raca?.modificadores[sigla] ?? 0;
    
    return base + bonusRaca;
  }
}