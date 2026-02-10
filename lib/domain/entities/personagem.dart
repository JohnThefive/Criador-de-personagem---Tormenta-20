import 'atributos.dart';

class Personagem {
  final String nome;
  final Map<String, Atributo> atributos;

  Personagem({required this.nome, required this.atributos});

  // Factory para criar um personagem "zerado" ou padrão
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
    );
  }

  Personagem copyWith({
    String? nome,
    Map<String, Atributo>? atributos,
  }) {
    return Personagem(
      nome: nome ?? this.nome,
      atributos: atributos ?? this.atributos,
    );

  // Métodos auxiliares
  
}}