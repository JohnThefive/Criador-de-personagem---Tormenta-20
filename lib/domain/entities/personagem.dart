import 'atributos.dart';
import 'raca.dart'; 
import 'classe_do_personagem.dart';

// imports pras pericias 
import '../services/banco_pericias.dart';


class Personagem {
  final String nome;
  final Map<String, Atributo> atributos; // Estes são os atributos BASE (Rolados/Comprados)
  final Raca? raca; // Agora ele pode ter uma raça (
  final List<ClasseDoPersonagem> classes; // o item no índice [0] é a classe inicial.
  final List<String> periciasTreinadas;   // lista string de pericias treinadas do personagem 


  Personagem({
    required this.nome, 
    required this.atributos, 
    this.raca,
    this.classes = const [],
    this.periciasTreinadas = const [],
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
    // ignore: non_constant_identifier_names
    List<ClasseDoPersonagem>? classe_do_personagem,
    List<String>? periciasTreinadas
  }) {
    return Personagem(
      nome: nome ?? this.nome,
      atributos: atributos ?? this.atributos,
      raca: raca ?? this.raca,
      classes: classe_do_personagem ?? classes,
      periciasTreinadas: periciasTreinadas ?? this.periciasTreinadas,
    );
  }

  // Este método calcula o valor final para exibir na tela (Base + Raça Fixa + Raça Variável)
  int getValorFinal(String sigla, {List<String> bonusVariaveis = const []}) {
    int base = atributos[sigla]?.valor ?? 0;

    // Bônus Fixo da Raça (Ex: Anão +2 CON)
    int bonusFixo = raca?.modificadores[sigla] ?? 0;

    // Bônus Variável (Se a sigla estiver na lista de escolhidos, ganha +1)
    int bonusVariavel = bonusVariaveis.contains(sigla) ? 1 : 0;
    
    return base + bonusFixo + bonusVariavel;
  }

  //Funções que Afetam a CLASSE e o nivel do personagem. 

  // Nível de Personagem (Soma dos níveis de todas as classes)
  int get nivelPersonagem {
    if (classes.isEmpty) return 0; // Ainda não escolheu classe
    return classes.fold(0, (soma, c) => soma + c.nivel);
  }

  // Pontos de Vida Totais (PV)
  int get pvTotal {
    if (classes.isEmpty) return 0;

    // Pega o valor FINAL da Constituição 
    int con = getValorFinal('CON'); 
    
    int totalPV = 0;

    for (int i = 0; i < classes.length; i++) {
      final item = classes[i];
      final regras = item.classeDefinicao;
      final bool ehClasseInicial = (i == 0); // O índice 0 define a regra inicial

      if (ehClasseInicial) {
        // Nível 1 da PRIMEIRA classe: PV Cheio + CON
        totalPV += regras.pvInicial + con;
        
        // Níveis subsequentes da MESMA classe inicial
        if (item.nivel > 1) {
           // Regra: Ganha PV por nível + CON (mínimo 1)
           int ganhoPorNivel = regras.pvPorNivel + con;
           if (ganhoPorNivel < 1) ganhoPorNivel = 1;
           
           totalPV += ganhoPorNivel * (item.nivel - 1);
        }
      } else {
        // MULTICLASSE (Classes adicionadas depois)
        // ganha os PV de um nível subsequente, não do primeiro
        int ganhoPorNivel = regras.pvPorNivel + con;
        if (ganhoPorNivel < 1) ganhoPorNivel = 1;

        totalPV += ganhoPorNivel * item.nivel;
      }
    }
    return totalPV;
  }

  // Pontos de Mana Totais (PM)
  int get pmTotal {
    if (classes.isEmpty) return 0;
    
    int totalPM = 0;

    for (int i = 0; i < classes.length; i++) {
      final item = classes[i];
      final regras = item.classeDefinicao;
      
      // 1. PM da Classe (Ex: Arcanista ganha 6 no Nível 1, e +6 a cada nível extra)
      if (i == 0) {
         totalPM += regras.pmInicial; // Nível 1 da classe principal
         if (item.nivel > 1) {
           totalPM += regras.pmPorNivel * (item.nivel - 1);
         }
      } else {
         // Multiclasse ganha apenas o PM por nível, não o inicial (geralmente é o mesmo, mas garante a regra)
         totalPM += regras.pmPorNivel * item.nivel; 
      }

      // 2. Bônus do Atributo-Chave (Específico para Arcanistas ou Caminhos)
      if (item.caminhoEscolhido != null) {
        // Ex: Pega 'INT' (Mago/Bruxo) ou 'CAR' (Feiticeiro)
        String siglaChave = item.caminhoEscolhido!.atributoChave;
        
        // Pega o valor total do atributo com os bônus
        int valorAtributoChave = getValorFinal(siglaChave);
        
        // Soma os PMs extras fornecidos pelo atributo-chave
        totalPM += valorAtributoChave;
      }
    }
    return totalPM;
  }

  // --- REGRAS ESPECÍFICAS DE CLASSE/CAMINHO ---
  
  // PV do Foco Mágico (Regra Específica do Arcanista Bruxo)
  int get pvDoFocoMagico {
    // Procura na lista de classes se o personagem tem o caminho "Bruxo"
    for (var item in classes) {
      if (item.caminhoEscolhido?.temFocoMagico == true) {
        // PV do Foco é a metade do PV total do personagem (arredondado para baixo)
        return (pvTotal / 2).floor();
      }
    }
    return 0; // Não possui foco mágico
  }


  // REgras de pericia 

  // bonus baseado no nivel do personagem (quando o personagem subir de nivel (futuro))
  int get bonusTreinamento {
  if (nivelPersonagem >= 15) return 6;
  if (nivelPersonagem >= 7) return 4;
  return 2;
 }

  //calculo final da pericia 
  int getValorPericia(String periciaKey, {int penalidadeArmaduraAtual = 0}) {
    final pericia = BancoDePericias.getByKey(periciaKey);

    // a. Metade do nível (arredondado para baixo)
    int metadeNivel = (nivelPersonagem / 2).floor();

    int modAtributo = getValorFinal(pericia.atributoChave);

    // Bônus de Treinamento
    bool ehTreinada = periciasTreinadas.contains(periciaKey);
    int bonusTreino = ehTreinada ? bonusTreinamento : 0;

    // d. Penalidade de Armadura (se a perícia sofrer e se o personagem usar armadura)
    int penalidade = 0;
    if (pericia.penalidadeArmadura) {
      penalidade = penalidadeArmaduraAtual; // Valor que virá do equipamento no futuro
    }

    return metadeNivel + modAtributo + bonusTreino - penalidade;
  }
}