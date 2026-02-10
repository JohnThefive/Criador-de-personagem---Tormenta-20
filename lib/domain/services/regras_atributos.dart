import 'dart:math';

class RegrasAtributos {
  // Tabela de Custo (Compra de Pontos)
  static const Map<int, int> custoPontos = {
    -1: -1, // Ganha 1 ponto
    0: 0,
    1: 1,
    2: 2,
    3: 4,
    4: 7,
  };

  static const int pontosIniciais = 10;

  // Verifica se o valor é válido para compra
  static bool valorEhValidoParaCompra(int valor) {
    return custoPontos.containsKey(valor);
  }

  // Tabela de Conversão (Rolagem de Dados -> Modificador)
  static int converterRolagemParaModificador(int somaDados) {
    if (somaDados <= 7) return -2;
    if (somaDados <= 9) return -1;
    if (somaDados <= 11) return 0;
    if (somaDados <= 13) return 1;
    if (somaDados <= 15) return 2;
    if (somaDados <= 17) return 3;
    return 4; // 18+
  }

  // Algoritmo de Rolagem: 4d6, descarta o menor
  static int rolar4d6DropMenor() {
    final random = Random();
    List<int> dados = List.generate(4, (_) => random.nextInt(6) + 1);
    dados.sort(); // Ordena [1, 3, 5, 6]
    // Remove o primeiro (o menor) e soma o resto
    return dados.skip(1).reduce((a, b) => a + b);
  }

  // Gera o array completo de 6 atributos garantindo a regra "Soma >= 6"
  static List<int> gerarKitRolagem() {
    List<int> modificadores = [];
    
    // Loop de segurança até o kit ser válido
    do {
      modificadores = List.generate(6, (_) {
        int rolagem = rolar4d6DropMenor();
        return converterRolagemParaModificador(rolagem);
      });

      // Validação: Se a soma for menor que 6, rerola o menor valor
      while (modificadores.reduce((a, b) => a + b) < 6) {
        modificadores.sort(); // O menor fica no índice 0
        int novaRolagem = rolar4d6DropMenor();
        modificadores[0] = converterRolagemParaModificador(novaRolagem);
      }
      
    } while (modificadores.reduce((a, b) => a + b) < 6); 

    return modificadores;
  }
}