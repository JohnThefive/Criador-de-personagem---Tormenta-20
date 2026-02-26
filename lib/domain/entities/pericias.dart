class Pericia {
  final String key;  // nome da pericia 
  final String label;  
  final String atributoChave; // 'FOR', 'DES', 'CON', 'INT', 'SAB', 'CAR'
  final bool somenteTreinada; // verifica se é preciso treinar para ter a pericia
  final bool penalidadeArmadura; //  verifica se tem penalidade  de armadura
  final String descricao;  // descricao curta do que a percia faz 
  final String acoesExecutadas; // ações que voce pode fazer com bonus graças a pericia 

  const Pericia({
    required this.key,
    required this.label,
    required this.atributoChave,
    required this.somenteTreinada,
    required this.penalidadeArmadura,
    required this.descricao,
    required this.acoesExecutadas,
  });
}