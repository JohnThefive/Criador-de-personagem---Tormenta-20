import 'package:t20_creator/domain/entities/magia/magia.dart';
import 'package:t20_creator/domain/services/data_services/call_magias.dart';

class RegrasConjuracaoClasse {
  final bool isConjurador;
  final String? tipoMagia; // 'arcana' ou 'divina'
  final String? atributoChave; // 'INT', 'CAR', 'SAB'
  final int qtdMagiasIniciais;
  final String? caminho; // 'bruxo', 'mago', 'feiticeiro'

  const RegrasConjuracaoClasse({
    required this.isConjurador,
    this.tipoMagia,
    this.atributoChave,
    this.qtdMagiasIniciais = 0,
    this.caminho,
  });
}

class AprendizadoMagiaService {
  static RegrasConjuracaoClasse obterRegrasIniciais(
    String classeId, {
    String? caminhoId,
  }) =>
      switch ((classeId.toUpperCase(), caminhoId?.toLowerCase())) {
        ('ARCANISTA', 'feiticeiro') => const RegrasConjuracaoClasse(
            isConjurador: true,
            tipoMagia: 'arcana',
            atributoChave: 'CAR',
            qtdMagiasIniciais: 3,
            caminho: 'feiticeiro',
          ),
        ('ARCANISTA', 'mago') => const RegrasConjuracaoClasse(
            isConjurador: true,
            tipoMagia: 'arcana',
            atributoChave: 'INT',
            qtdMagiasIniciais: 4,
            caminho: 'mago',
          ),
        ('ARCANISTA', _) => const RegrasConjuracaoClasse(
            isConjurador: true,
            tipoMagia: 'arcana',
            atributoChave: 'INT',
            qtdMagiasIniciais: 3,
            caminho: 'bruxo',
          ),
        ('BARDO', _) => const RegrasConjuracaoClasse(
            isConjurador: true,
            tipoMagia: 'arcana',
            atributoChave: 'CAR',
            qtdMagiasIniciais: 2,
          ),
        ('CLERIGO' || 'CLÉRIGO', _) => const RegrasConjuracaoClasse(
            isConjurador: true,
            tipoMagia: 'divina',
            atributoChave: 'SAB',
            qtdMagiasIniciais: 3,
          ),
        ('DRUIDA', _) => const RegrasConjuracaoClasse(
            isConjurador: true,
            tipoMagia: 'divina',
            atributoChave: 'SAB',
            qtdMagiasIniciais: 3,
          ),
        _ => const RegrasConjuracaoClasse(isConjurador: false),
      };

  /// Retorna a lista de magias elegíveis no 1º nível para a classe/caminho
  static List<Magia> obterMagiasDisponiveis(
    String classeId, {
    String? caminhoId,
  }) {
    final regras = obterRegrasIniciais(classeId, caminhoId: caminhoId);
    if (!regras.isConjurador || regras.tipoMagia == null) {
      return [];
    }

    return BancoDeMagias.filtrarPorClasseETipo(
      tipo: regras.tipoMagia!,
      circuloMaximo: 1,
    );
  }
}
