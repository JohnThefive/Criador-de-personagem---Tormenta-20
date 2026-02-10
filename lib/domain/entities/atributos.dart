class Atributo {
  final String nome; 
  final int valor;   

  const Atributo({required this.nome, required this.valor});

  // CORREÇÃO T20: O modificador é o próprio valor!
  int get modificador => valor; 

  Atributo copyWith({int? valor}) {
    return Atributo(
      nome: nome,
      valor: valor ?? this.valor,
    );
  }
}