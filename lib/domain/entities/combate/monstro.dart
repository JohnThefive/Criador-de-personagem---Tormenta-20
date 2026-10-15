import '../equipamento/arma.dart';

enum PapelMonstro {
  lacaio('Lacaio'),
  padrao('Padrão'),
  solo('Solo'),
  chefe('Chefe');

  final String label;
  const PapelMonstro(this.label);
}

class AtaqueMonstro {
  final String nome;
  final int bonusAtaque; // ex: +8
  final String dano; // ex: "1d8+4"
  final int margemAmeaca; // ex: 20
  final int multiplicadorCritico; // ex: 2
  final TipoDanoArma tipoDano;
  final String alcance; // "Corpo a corpo", "Curto", "Médio"
  final String? descricaoEfeito; // ex: "Veneno (CD 14)"

  const AtaqueMonstro({
    required this.nome,
    required this.bonusAtaque,
    required this.dano,
    this.margemAmeaca = 20,
    this.multiplicadorCritico = 2,
    this.tipoDano = TipoDanoArma.impacto,
    this.alcance = 'Corpo a corpo',
    this.descricaoEfeito,
  });

  /// Converte para a representação de Arma do sistema para reuso transparente do motor de combate
  Arma toArma(String idAmeaca) {
    return Arma(
      key: '${idAmeaca}_${nome.toLowerCase().replaceAll(' ', '_')}',
      nome: nome,
      descricao: descricaoEfeito ?? 'Ataque de criatura',
      proficiencia: ProficienciaArma.simples,
      proposito: alcance.toLowerCase().contains('corpo')
          ? PropositoArma.corpoACorpo
          : PropositoArma.disparo,
      empunhadura: EmpunhaduraArma.umaMao,
      dano: dano,
      margemAmeaca: margemAmeaca,
      multiplicadorCritico: multiplicadorCritico,
      tipoDano: tipoDano,
      alcance: alcance,
    );
  }
}

class Monstro {
  final String id;
  final String nome;
  final String nd; // Ex: "1/4", "1/2", "1", "5", "S"
  final PapelMonstro papel;
  final String tipoCriatura; // Humanoide, Monstro, Morto-vivo, Animal, Construto
  final String tamanho; // Minúsculo, Pequeno, Médio, Grande, Enorme, Colossal
  final int pvMax;
  final int pmMax;
  final int defesa;
  final double deslocamentoMetros;
  final int iniciativa;
  final int percepcao;
  final int fortitude;
  final int reflexos;
  final int vontade;
  final int modForca;
  final int modDestreza;
  final int modConstituicao;
  final List<AtaqueMonstro> ataques;
  final List<String> habilidades;

  const Monstro({
    required this.id,
    required this.nome,
    required this.nd,
    this.papel = PapelMonstro.padrao,
    this.tipoCriatura = 'Monstro',
    this.tamanho = 'Médio',
    required this.pvMax,
    this.pmMax = 0,
    required this.defesa,
    this.deslocamentoMetros = 9.0,
    required this.iniciativa,
    this.percepcao = 0,
    this.fortitude = 0,
    this.reflexos = 0,
    this.vontade = 0,
    this.modForca = 0,
    this.modDestreza = 0,
    this.modConstituicao = 0,
    this.ataques = const [],
    this.habilidades = const [],
  });
}
