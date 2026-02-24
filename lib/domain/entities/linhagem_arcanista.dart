// Enum para a Dracônica
enum TipoDanoDraconico { acido, eletricidade, fogo, frio }

// Classe Base
abstract class Linhagem {
  final String nome;
  final String descricaoBasica;
  final String descricaoAprimorada;
  final String descricaoSuperior;

  Linhagem({
    required this.nome,
    required this.descricaoBasica,
    required this.descricaoAprimorada,
    required this.descricaoSuperior,
  });
}

// Implementações Específicas
class LinhagemDraconica extends Linhagem {
  final TipoDanoDraconico tipoDanoEscolhido;

  LinhagemDraconica({required this.tipoDanoEscolhido}) 
    : super(
        nome: "Dracônica",
        descricaoBasica: "Redução de dano e bônus de dano do tipo ${tipoDanoEscolhido.name}.",
        descricaoAprimorada: "Aumento de PV e imunidade.",
        descricaoSuperior: "Transformação em meio-dragão.",
      );
}

class LinhagemFeerica extends Linhagem {
  final String magiaBonusEncantamentoOuIlusao; // Guardaremos o nome ou ID da magia

  LinhagemFeerica({required this.magiaBonusEncantamentoOuIlusao})
    : super(
        nome: "Feérica",
        descricaoBasica: "Aprende $magiaBonusEncantamentoOuIlusao (+1 magia bônus).",
        descricaoAprimorada: "Aumento de Carisma.",
        descricaoSuperior: "Magias viram ações livres.",
      );
}

class LinhagemRubra extends Linhagem {
  // Flag para a UI saber que precisa abrir a lista de Poderes da Tormenta
  final bool interageComTormenta = true; 

  LinhagemRubra()
    : super(
        nome: "Rubra",
        descricaoBasica: "Pode perder Carisma para ganhar Poderes da Tormenta.",
        descricaoAprimorada: "Redução de custo de mana.",
        descricaoSuperior: "Imunidades da Tormenta.",
      );
}