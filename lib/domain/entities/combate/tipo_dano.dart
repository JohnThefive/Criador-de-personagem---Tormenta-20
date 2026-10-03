enum TipoDano {
  corte,
  impacto,
  perfuracao,
  fogo,
  frio,
  eletricidade,
  acido,
  essencia,
  luz,
  psiquico,
  trevas;

  String get label {
    switch (this) {
      case TipoDano.corte:
        return 'Corte';
      case TipoDano.impacto:
        return 'Impacto';
      case TipoDano.perfuracao:
        return 'Perfuração';
      case TipoDano.fogo:
        return 'Fogo';
      case TipoDano.frio:
        return 'Frio';
      case TipoDano.eletricidade:
        return 'Eletricidade';
      case TipoDano.acido:
        return 'Ácido';
      case TipoDano.essencia:
        return 'Essência';
      case TipoDano.luz:
        return 'Luz';
      case TipoDano.psiquico:
        return 'Psíquico';
      case TipoDano.trevas:
        return 'Trevas';
    }
  }

  static TipoDano fromString(String val) {
    switch (val.toLowerCase().trim()) {
      case 'impacto':
        return TipoDano.impacto;
      case 'perfuracao':
      case 'perfuração':
        return TipoDano.perfuracao;
      case 'fogo':
        return TipoDano.fogo;
      case 'frio':
        return TipoDano.frio;
      case 'eletricidade':
        return TipoDano.eletricidade;
      case 'acido':
      case 'ácido':
        return TipoDano.acido;
      case 'essencia':
      case 'essência':
        return TipoDano.essencia;
      case 'luz':
        return TipoDano.luz;
      case 'psiquico':
      case 'psíquico':
        return TipoDano.psiquico;
      case 'trevas':
        return TipoDano.trevas;
      case 'corte':
      default:
        return TipoDano.corte;
    }
  }
}
