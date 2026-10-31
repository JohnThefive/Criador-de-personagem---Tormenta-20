import 'package:t20_creator/domain/entities/magia/magia.dart';
import 'package:t20_creator/domain/entities/personagem/personagem.dart';
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

  /// Retorna o círculo máximo de magia que uma classe conjuradora libera no nível informado (T20 JdA)
  static int obterCirculoMaximoClasse(String classeId, int nivelClasse) {
    if (nivelClasse < 1) return 0;
    final id = classeId.toUpperCase();
    // Conjuradores plenos (Arcanista, Clérigo): 1º(1), 2º(5), 3º(9), 4º(13), 5º(17)
    if (id == 'ARCANISTA' || id == 'CLERIGO' || id == 'CLÉRIGO') {
      if (nivelClasse >= 17) return 5;
      if (nivelClasse >= 13) return 4;
      if (nivelClasse >= 9) return 3;
      if (nivelClasse >= 5) return 2;
      return 1;
    }
    // Conjuradores parciais (Bardo, Druida): 1º(1), 2º(6), 3º(10), 4º(14)
    if (id == 'BARDO' || id == 'DRUIDA') {
      if (nivelClasse >= 14) return 4;
      if (nivelClasse >= 10) return 3;
      if (nivelClasse >= 6) return 2;
      return 1;
    }
    return 0;
  }

  /// Calcula o total de magias de classe que a classe conjuradora tem direito até o `nivelClasse`
  static int calcularTotalMagiasPermitidasClasse(
    String classeId,
    int nivelClasse, {
    String? caminhoId,
  }) {
    if (nivelClasse < 1) return 0;
    final regras = obterRegrasIniciais(classeId, caminhoId: caminhoId);
    if (!regras.isConjurador) return 0;

    final id = classeId.toUpperCase();
    int total = regras.qtdMagiasIniciais;

    if (id == 'ARCANISTA') {
      final caminho = regras.caminho ?? 'bruxo';
      if (caminho == 'feiticeiro') {
        // Feiticeiro: aprende 1 magia nos níveis ímpares (3, 5, 7, ..., 19)
        for (int n = 2; n <= nivelClasse; n++) {
          if (n.isOdd) total += 1;
        }
      } else if (caminho == 'mago') {
        // Mago: 1 magia por nível + 1 extra quando libera novo círculo (5, 9, 13, 17)
        for (int n = 2; n <= nivelClasse; n++) {
          total += 1;
          if (n == 5 || n == 9 || n == 13 || n == 17) {
            total += 1;
          }
        }
      } else {
        // Bruxo: 1 magia a cada nível subsequente
        total += (nivelClasse - 1);
      }
    } else if (id == 'CLERIGO' || id == 'CLÉRIGO') {
      // Clérigo: 1 magia por nível subsequente
      total += (nivelClasse - 1);
    } else if (id == 'BARDO' || id == 'DRUIDA') {
      // Bardo e Druida: 1 magia a cada nível par (2, 4, 6, ..., 20)
      total += (nivelClasse ~/ 2);
    }

    return total;
  }

  /// Retorna o círculo máximo de magia que o personagem pode lançar considerando todas as classes e raça
  static int obterCirculoMaximoPersonagem(Personagem p) {
    int maxCirc = 0;
    for (final c in p.classes) {
      final circ = obterCirculoMaximoClasse(
        c.classeDefinicao.idClasse,
        c.nivel,
      );
      if (circ > maxCirc) maxCirc = circ;
    }
    if (maxCirc == 0 && p.magiasConhecidas.isNotEmpty) {
      maxCirc = 1;
    }
    return maxCirc;
  }

  /// RV07 / RF05 / RN08 — Retorna o círculo máximo desbloqueado para uma tradição mágica específica
  /// ('arcana', 'divina' ou 'universal'), respeitando estritamente o nível individual de cada classe conjuradora!
  static int obterCirculoMaximoPorTipoMagia(Personagem p, String tipoMagia) {
    final tipo = tipoMagia.trim().toLowerCase();
    if (tipo == 'universal') {
      return obterCirculoMaximoPersonagem(p);
    }

    int maxCirc = 0;
    for (final c in p.classes) {
      final regras = obterRegrasIniciais(
        c.classeDefinicao.idClasse,
        caminhoId: c.caminhoEscolhido?.nome,
      );
      if (!regras.isConjurador || regras.tipoMagia == null) continue;
      if (regras.tipoMagia!.toLowerCase() == tipo) {
        final circ = obterCirculoMaximoClasse(
          c.classeDefinicao.idClasse,
          c.nivel,
        );
        if (circ > maxCirc) maxCirc = circ;
      }
    }

    // Qareen (Tatuagem Mística) / poderes que concedem magia arcana de 1º círculo
    if (maxCirc == 0 &&
        tipo == 'arcana' &&
        p.raca?.id.toLowerCase() == 'qareen') {
      return 1;
    }

    return maxCirc;
  }

  /// RV07 — Verifica se o personagem cumpre os requisitos de classe e círculo individual
  /// para aprender uma magia sem usar o nível de outra classe para destravar círculos superiores.
  static bool podeAprenderMagiaNoPersonagem(Personagem p, Magia magia) {
    final circuloLiberado = obterCirculoMaximoPorTipoMagia(p, magia.tipo);
    if (circuloLiberado <= 0) return false;
    return magia.circulo <= circuloLiberado;
  }

  /// Calcula quantas magias ao todo o personagem deveria conhecer por progressão de suas classes
  static int calcularTotalMagiasEsperadasPersonagem(Personagem p) {
    int total = 0;
    for (final c in p.classes) {
      total += calcularTotalMagiasPermitidasClasse(
        c.classeDefinicao.idClasse,
        c.nivel,
        caminhoId: c.caminhoEscolhido?.nome,
      );
    }
    return total;
  }

  /// Quantidade de magias pendentes de escolha ao subir de nível
  static int calcularMagiasPendentesPersonagem(Personagem p) {
    final esperadas = calcularTotalMagiasEsperadasPersonagem(p);
    final atuais = p.magiasConhecidas.length;
    return (esperadas - atuais).clamp(0, 99);
  }

  /// Retorna a lista de magias elegíveis no nível informado para a classe/caminho
  static List<Magia> obterMagiasDisponiveis(
    String classeId, {
    String? caminhoId,
    int nivelClasse = 1,
  }) {
    final regras = obterRegrasIniciais(classeId, caminhoId: caminhoId);
    if (!regras.isConjurador || regras.tipoMagia == null) {
      return [];
    }

    final circMax = obterCirculoMaximoClasse(classeId, nivelClasse);
    return BancoDeMagias.filtrarPorClasseETipo(
      tipo: regras.tipoMagia!,
      circuloMaximo: circMax > 0 ? circMax : 1,
    );
  }
}
