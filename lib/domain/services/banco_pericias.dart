import '../entities/pericias.dart';

class BancoDePericias {
  static const List<Pericia> todas = [


    Pericia(
      key: 'ACROBACIA',
      label: 'Acrobacia',
      atributoChave: 'DES',
      somenteTreinada: false,
      penalidadeArmadura: true,
      descricao: 'Você consegue fazer proezas acrobáticas.',
      acoesExecutadas: 'Amortecer queda, equilíbrio, escapar, levantar-se, passar por inimigo',
    ),
    Pericia(
      key: 'MISTICISMO',
      label: 'Misticismo',
      atributoChave: 'INT',
      somenteTreinada: true,
      penalidadeArmadura: false,
      descricao: 'Esta perícia envolve o conhecimento de magias, itens mágicos e fenômenos sobrenaturais',
      acoesExecutadas: 'Detectar magias, Identificar criatura, identificar item, identificar magia, informação, lançar magia com armadura',
    ),
    Pericia(
      key: 'VONTADE',
      label: 'Vontade',
      atributoChave: 'SAB',
      somenteTreinada: false,
      penalidadeArmadura: false,
      descricao: 'Você usa está perícia para resistir a efeitos que exigem determinação, como intimidação e encantamentos',
      acoesExecutadas: "A CD é determinada pelo efeito. Teste de vontade são testes de resistências.",
      ),
    
     Pericia(
      key: 'NOBREZA',
      label: 'Nobreza',
      atributoChave: 'INT',
      somenteTreinada: true,
      penalidadeArmadura: false,
      descricao: 'Você recebeu a educação de um nobre.',
      acoesExecutadas: "Etiqueta, Educação",
      ),
  ];

  // Método auxiliar para buscar uma perícia pela chave
  static Pericia getByKey(String key) {
    return todas.firstWhere((p) => p.key == key);
  }
}