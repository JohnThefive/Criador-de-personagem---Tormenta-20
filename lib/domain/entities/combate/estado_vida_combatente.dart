enum EstadoVidaCombatente {
  ativo,
  inconscienteSangrando,
  estabilizado,
  morto;

  String get label {
    switch (this) {
      case EstadoVidaCombatente.ativo:
        return 'Ativo';
      case EstadoVidaCombatente.inconscienteSangrando:
        return 'Inconsciente (Sangrando)';
      case EstadoVidaCombatente.estabilizado:
        return 'Estabilizado';
      case EstadoVidaCombatente.morto:
        return 'Morto';
    }
  }

  bool get podeAgir => this == EstadoVidaCombatente.ativo;
  bool get estaInconsciente =>
      this == EstadoVidaCombatente.inconscienteSangrando ||
      this == EstadoVidaCombatente.estabilizado;
  bool get estaDerrotado => this != EstadoVidaCombatente.ativo;
}
