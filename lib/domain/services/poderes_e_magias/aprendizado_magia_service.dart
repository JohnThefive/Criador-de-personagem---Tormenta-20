import 'package:t20_creator/domain/entities/magia/magia.dart';
import 'package:t20_creator/domain/services/data_services/call_magias.dart';

class RegrasConjuracaoClasse {
  final bool isConjurador;
  final String? tipoMagia; // 'arcana' ou 'divina'
  final String? atributoChave; // 'INT', 'CAR', 'SAB'
  final int qtdMagiasIniciais;

  const RegrasConjuracaoClasse({
    required this.isConjurador,
    this.tipoMagia,
    this.atributoChave,
    this.qtdMagiasIniciais = 0,
  });
}

class AprendizadoMagiaService {
  /// Retorna as regras de conjuração no 1º nível de acordo com a classe
  static RegrasConjuracaoClasse obterRegrasIniciais(String classeId) {
    switch (classeId.toUpperCase()) {
      case 'ARCANISTA':
        return const RegrasConjuracaoClasse(
          isConjurador: true,
          tipoMagia: 'arcana',
          atributoChave: 'INT', // Varia por caminho, padrão INT para mago/bruxo
          qtdMagiasIniciais: 3,
        );
      case 'BARDO':
        return const RegrasConjuracaoClasse(
          isConjurador: true,
          tipoMagia: 'arcana',
          atributoChave: 'CAR',
          qtdMagiasIniciais: 2,
        );
      case 'CLERIGO':
        return const RegrasConjuracaoClasse(
          isConjurador: true,
          tipoMagia: 'divina',
          atributoChave: 'SAB',
          qtdMagiasIniciais: 3,
        );
      case 'DRUIDA':
        return const RegrasConjuracaoClasse(
          isConjurador: true,
          tipoMagia: 'divina',
          atributoChave: 'SAB',
          qtdMagiasIniciais: 3,
        );
      default:
        return const RegrasConjuracaoClasse(isConjurador: false);
    }
  }

  /// Retorna a lista de magias elegíveis no 1º nível para a classe
  static List<Magia> obterMagiasDisponiveis(String classeId) {
    final regras = obterRegrasIniciais(classeId);
    if (!regras.isConjurador || regras.tipoMagia == null) {
      return [];
    }

    return BancoDeMagias.filtrarPorClasseETipo(
      tipo: regras.tipoMagia!,
      circuloMaximo: 1,
    );
  }
}
