class Raca {
  final String nome;
  
  // Mapa de modificadores fixos. Ex: {'CON': 2, 'SAB': 1, 'DES': -1} para Anão
  final Map<String, int> modificadores; 
  
  // Lista de nomes das habilidades (Ex: "Visão no Escuro", "Conhecimento das Rochas")
  // temos que mudar isso depois para adicionar as pericias
  final List<String> habilidades;

  // Flags para raças que midufucam muitos atributos e habilidades compleas 
  final bool ehFlexivel; 

  const Raca({
    required this.nome,
    required this.modificadores,
    required this.habilidades,
    this.ehFlexivel = false,
  });
}