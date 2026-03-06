class Raca {
  final String nome;
  
  // Campos visuais e lore
  final String descricaoRaca;
  final String imagemRaca;
  
  // Mapa de modificadores fixos. Ex: {'CON': 2, 'SAB': 1, 'DES': -1} para Anão
  final Map<String, int> modificadores; 
  
  // map de habilidades - "Nome: descrição" ---
  // Ex: {"Visão no Escuro": "Você enxerga no escuro a até 15m..."}
  final Map<String, String> habilidadesRaca;

  // Flags para raças que modificam muitos atributos e habilidades complexas 
  final bool ehFlexivel; 

  // raças que possuem penalidades complexas 
  final List<String> atributosBloqueados;

  const Raca({
    required this.nome,
    required this.descricaoRaca, 
    required this.imagemRaca,    
    required this.modificadores,
    this.habilidadesRaca = const {}, 
    this.ehFlexivel = false,
    this.atributosBloqueados = const [],
  });
}