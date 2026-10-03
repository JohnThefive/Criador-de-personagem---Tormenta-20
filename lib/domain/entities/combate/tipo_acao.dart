enum TipoAcao {
  padrao,
  movimento,
  completa,
  livre,
  reacao;

  String get label {
    switch (this) {
      case TipoAcao.padrao:
        return 'Ação Padrão';
      case TipoAcao.movimento:
        return 'Ação de Movimento';
      case TipoAcao.completa:
        return 'Ação Completa';
      case TipoAcao.livre:
        return 'Ação Livre';
      case TipoAcao.reacao:
        return 'Reação';
    }
  }
}
