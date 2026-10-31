import 'dart:math';

import '../entities/equipamento/item_geral.dart';
import '../entities/personagem/personagem.dart';
import '../entities/personagem/poder.dart';

/// Motor Declarativo de Modificadores do Tormenta 20 JdA.
/// Centraliza o cálculo de bônus passivos e penalidades oriundos de:
/// - Poderes da Tormenta (incluindo escalonamento e perda de Carisma)
/// - Habilidade racial Deformidade (Lefou)
/// - Poderes Gerais (Combate, Destino, Magia)
/// - Melhorias e Encantos de Armas e Proteções (Itens Superiores e Mágicos)
/// - Itens Gerais / Vestuário / Esotéricos
class MotorModificadoresService {
  /// Retorna todos os poderes ativos do personagem (Classes + Gerais + Concedidos + Deformidade Lefou),
  /// sem duplicatas por `key`.
  static List<Poder> obterTodosPoderesAtivos(Personagem p) {
    final vistos = <String>{};
    final resultado = <Poder>[];

    void adicionar(Poder? pod) {
      if (pod == null) return;
      final k = pod.key.trim().toLowerCase();
      if (k.isEmpty) return;
      if (vistos.add(k)) {
        resultado.add(pod);
      }
    }

    for (final c in p.classes) {
      for (final pod in c.poderesEscolhidos) {
        adicionar(pod);
      }
    }
    for (final pod in p.poderesGerais) {
      adicionar(pod);
    }
    for (final pod in p.poderesConcedidosAtivos) {
      adicionar(pod);
    }
    adicionar(p.poderTormentaDeformidade);

    return resultado;
  }

  /// Verifica se o personagem possui um poder específico (por `key` ou id).
  static bool possuiPoder(Personagem p, String key) {
    final alvo = key.trim().toLowerCase();
    return obterTodosPoderesAtivos(p).any(
      (pod) => pod.key.trim().toLowerCase() == alvo,
    );
  }

  /// Conta o total de Poderes da Tormenta que o personagem possui para fins de
  /// pré-requisitos e escalonamento ("para cada dois outros poderes da Tormenta").
  ///
  /// Regra da Deformidade (Lefou):
  /// - Cada um dos 2 bônus de Deformidade (+2 em perícia ou poder da Tormenta substituto)
  ///   conta como 1 poder da Tormenta para pré-requisitos e escalonamento.
  static int contarPoderesTormentaParaEscalamento(Personagem p) {
    final poderesTormenta = obterTodosPoderesAtivos(p)
        .where((pod) => pod.ehPoderTormenta)
        .length;

    final ehLefou = p.raca?.id.toLowerCase() == 'lefou';
    int bonusDeformidadePericias = 0;
    if (ehLefou) {
      if (p.periciasDeformidadeLefou.isEmpty &&
          p.poderTormentaDeformidade == null) {
        // Lefou recém-selecionado antes de customizar as perícias da Deformidade
        // já possui 2 bônus equivalentes a poderes da Tormenta por regra racial.
        bonusDeformidadePericias = 2;
      } else {
        bonusDeformidadePericias = p.periciasDeformidadeLefou.length;
      }
    }

    return poderesTormenta + bonusDeformidadePericias;
  }

  /// Conta quantos Poderes da Tormenta o personagem possui que CONTAM para perda de Carisma.
  ///
  /// Regra do Lefou: Os bônus de Deformidade (inclusive o poder da Tormenta escolhido
  /// em troca de um dos bônus de +2 em perícia) NÃO contam para perda de Carisma.
  static int contarPoderesTormentaComPerdaCarisma(Personagem p) {
    final keyIsentaLefou = p.poderTormentaDeformidade?.key.trim().toLowerCase();
    final vistos = <String>{};
    int contagem = 0;

    final candidatos = <Poder>[
      ...p.classes.expand((c) => c.poderesEscolhidos),
      ...p.poderesGerais,
    ];

    for (final pod in candidatos) {
      if (!pod.ehPoderTormenta) continue;
      final k = pod.key.trim().toLowerCase();
      if (k.isEmpty || !vistos.add(k)) continue;
      if (keyIsentaLefou != null && k == keyIsentaLefou) continue;
      contagem++;
    }

    return contagem;
  }

  /// Calcula a perda de Carisma causada pelos Poderes da Tormenta:
  /// "Quando escolhe um poder da Tormenta, você perde 1 de Carisma.
  /// Para cada dois outros poderes da Tormenta, você perde mais 1 de Carisma."
  static int calcularPerdaCarismaTormenta(Personagem p) {
    final qtd = contarPoderesTormentaComPerdaCarisma(p);
    if (qtd <= 0) return 0;
    return 1 + ((qtd - 1) ~/ 2);
  }

  /// Verifica se o personagem perdeu a própria identidade para a Tormenta:
  /// "Um personagem reduzido a menos que Car –5 torna-se um NPC sob controle do mestre."
  static bool personagemDominadoPelaTormenta(Personagem p) {
    return p.getValorFinal('CAR') < -5;
  }

  /// Bônus de perícia concedido pela Deformidade do Lefou (+2 em até duas perícias).
  static int calcularBonusDeformidadeLefouPericia(
    Personagem p,
    String periciaKey,
  ) {
    if (p.raca?.id.toLowerCase() != 'lefou') return 0;
    final alvo = periciaKey.trim().toUpperCase();
    return p.periciasDeformidadeLefou.any((k) => k.trim().toUpperCase() == alvo)
        ? 2
        : 0;
  }

  /// Calcula o bônus passivo total concedido por Poderes (Tormenta e Gerais) e Itens
  /// (Melhorias de Proteção, Vestuário, Ferramentas) em uma perícia específica.
  static int calcularBonusDeclarativoPericia(Personagem p, String periciaKey) {
    final keyUpper = periciaKey.trim().toUpperCase();
    int bonus = 0;

    // 1. Poderes da Tormenta passivos escaláveis
    final totalTormenta = contarPoderesTormentaParaEscalamento(p);
    final outrosTormenta = max(0, totalTormenta - 1);
    final bonusEscaladoTormenta = 1 + (outrosTormenta ~/ 2);

    if (possuiPoder(p, 'antenas')) {
      if (keyUpper == 'INICIATIVA' ||
          keyUpper == 'PERCEPCAO' ||
          keyUpper == 'VONTADE') {
        bonus += bonusEscaladoTormenta;
      }
    }
    if (possuiPoder(p, 'articulacoes_flexiveis')) {
      if (keyUpper == 'ACROBACIA' ||
          keyUpper == 'FURTIVIDADE' ||
          keyUpper == 'REFLEXOS') {
        bonus += bonusEscaladoTormenta;
      }
    }
    if (possuiPoder(p, 'maos_membranosas')) {
      if (keyUpper == 'ATLETISMO' || keyUpper == 'FORTITUDE') {
        bonus += bonusEscaladoTormenta;
      }
    }
    if (possuiPoder(p, 'olhos_vermelhos')) {
      if (keyUpper == 'INTIMIDACAO') {
        bonus += bonusEscaladoTormenta;
      }
    }

    // 3. Poderes Gerais passivos (Combate e Destino)
    if (possuiPoder(p, 'esquiva') && keyUpper == 'REFLEXOS') {
      bonus += 2;
    }
    if (possuiPoder(p, 'vitalidade') && keyUpper == 'FORTITUDE') {
      bonus += 2;
    }
    if (possuiPoder(p, 'vontade_de_ferro') && keyUpper == 'VONTADE') {
      bonus += 2;
    }
    if (possuiPoder(p, 'atletico') && keyUpper == 'ATLETISMO') {
      bonus += 2;
    }
    if (possuiPoder(p, 'investigador') && keyUpper == 'INVESTIGACAO') {
      bonus += 2;
    }

    // 4. Melhoria Selada em Armadura/Escudo (+1 em Fortitude, Reflexos e Vontade)
    if (keyUpper == 'FORTITUDE' ||
        keyUpper == 'REFLEXOS' ||
        keyUpper == 'VONTADE') {
      bonus += (p.armaduraEquipada?.bonusResistenciaMelhorias ?? 0);
      bonus += (p.escudoEquipado?.bonusResistenciaMelhorias ?? 0);
    }

    // 5. Itens Vestidos Extras (Slots 2, 3 e 4)
    for (final item in p.itensVestidosExtras) {
      if (item.bonusPericias.containsKey(keyUpper)) {
        bonus += item.bonusPericias[keyUpper]!;
      } else {
        // Fallback: verifica se o nome bate com algum item geral do catálogo
        final catItem = _buscarItemGeralCatalogo(item.nome);
        if (catItem != null && catItem.bonusPericias.containsKey(keyUpper)) {
          bonus += catItem.bonusPericias[keyUpper]!;
        }
      }
    }

    return bonus;
  }

  /// Calcula o bônus passivo de Defesa vindo de Poderes (Carapaça, Esquiva, Encouraçado,
  /// Estilo de Arma e Escudo), Encantos de Arma (Defensora) e Itens Vestidos.
  static int calcularBonusDeclarativoDefesa(Personagem p) {
    int bonus = 0;

    final totalTormenta = contarPoderesTormentaParaEscalamento(p);
    final outrosTormenta = max(0, totalTormenta - 1);

    // Poder da Tormenta: Carapaça (+1 + 1 a cada 2 outros poderes da Tormenta)
    if (possuiPoder(p, 'carapaca')) {
      bonus += 1 + (outrosTormenta ~/ 2);
    }

    // Poderes de Combate
    if (possuiPoder(p, 'esquiva')) {
      bonus += 2;
    }
    if (possuiPoder(p, 'estilo_de_arma_e_escudo') && p.escudoEquipado != null) {
      bonus += 2;
    }
    if (possuiPoder(p, 'encouracado') && p.usaArmaduraPesada) {
      int bonusEncouracado = 2;
      if (possuiPoder(p, 'inexpugnavel')) bonusEncouracado += 2;
      if (possuiPoder(p, 'fanatico')) bonusEncouracado += 2;
      bonus += bonusEncouracado;
    }

    // Armas com encanto Defensora (+2)
    for (final arma in p.armas) {
      bonus += arma.bonusDefesaEncanto;
    }

    // Itens vestidos extras com bônus de Defesa
    for (final item in p.itensVestidosExtras) {
      if (item.bonusDefesa != 0) {
        bonus += item.bonusDefesa;
      } else {
        final catItem = _buscarItemGeralCatalogo(item.nome);
        if (catItem != null) bonus += catItem.bonusDefesa;
      }
    }

    return bonus;
  }

  /// Bônus de Destreza adicional permitido em armadura pesada se ela possuir a melhoria Delicada (+1).
  static int calcularBonusDestrezaDelicadaArmaduraPesada(Personagem p) {
    if (!p.usaArmaduraPesada) return 0;
    final armadura = p.armaduraEquipada;
    if (armadura == null || !armadura.possuiMelhoriaDelicada) return 0;
    final modDes = p.getValorFinal('DES');
    return modDes > 0 ? 1 : 0;
  }

  /// Calcula a Redução de Dano (RD) passiva vinda de Poderes (Carapaça Corrompida)
  /// e Melhorias/Encantos de Proteções (Adamante, Couraça de Kaiju, Invulnerável).
  static int calcularBonusDeclarativoRD(Personagem p) {
    int rd = 0;

    final totalTormenta = contarPoderesTormentaParaEscalamento(p);
    final outrosTormenta = max(0, totalTormenta - 1);

    if (possuiPoder(p, 'carapaca_corrompida')) {
      rd += 1 + (outrosTormenta ~/ 2);
    }

    rd += (p.armaduraEquipada?.rdMelhorias ?? 0);
    rd += (p.escudoEquipado?.rdMelhorias ?? 0);

    return rd;
  }

  /// Calcula o bônus passivo de Pontos de Vida (ex: Vitalidade: +1 PV por nível).
  static int calcularBonusDeclarativoPV(Personagem p) {
    int bonus = 0;
    if (possuiPoder(p, 'vitalidade')) {
      bonus += max(1, p.nivelPersonagem);
    }
    return bonus;
  }

  /// Calcula o bônus passivo de Pontos de Mana (ex: Vontade de Ferro: +1 PM para cada 2 níveis).
  static int calcularBonusDeclarativoPM(Personagem p) {
    int bonus = 0;
    if (possuiPoder(p, 'vontade_de_ferro')) {
      bonus += max(1, p.nivelPersonagem) ~/ 2;
    }
    return bonus;
  }

  /// Calcula o bônus no limite de espaços de carga (ex: Bolsões Insanos e Costas Largas).
  static int calcularBonusDeclarativoLimiteCarga(Personagem p) {
    int bonus = 0;
    if (possuiPoder(p, 'bolsoes_insanos')) {
      final totalTormenta = contarPoderesTormentaParaEscalamento(p);
      final outrosTormenta = max(0, totalTormenta - 1);
      bonus += 2 + outrosTormenta;
    }
    if (possuiPoder(p, 'costas_largas')) {
      bonus += 5;
    }
    return bonus;
  }

  /// Calcula o bônus passivo na CD de Magias vindo de Itens Esotéricos / Vestidos e Poderes.
  static int calcularBonusDeclarativoCDMagia(Personagem p) {
    int bonus = 0;

    for (final item in p.itensVestidosExtras) {
      if (item.bonusCDMagia != 0) {
        bonus += item.bonusCDMagia;
      } else {
        final catItem = _buscarItemGeralCatalogo(item.nome);
        if (catItem != null) bonus += catItem.bonusCDMagia;
      }
    }

    // Também verifica itens esotéricos carregados no inventário se não estiverem nos slots vestidos
    for (final nomeItem in p.itensInventario) {
      final catItem = _buscarItemGeralCatalogo(nomeItem);
      if (catItem != null &&
          catItem.categoria == CategoriaItemGeral.esoterico &&
          catItem.bonusCDMagia > 0) {
        bonus += catItem.bonusCDMagia;
        break; // Apenas 1 esotérico pode ser empunhado por vez para conjurar
      }
    }

    return bonus;
  }

  static ItemGeral? _buscarItemGeralCatalogo(String nomeOuKey) {
    final norm = nomeOuKey.trim().toLowerCase();
    if (norm.isEmpty) return null;
    for (final item in CatalogoItensGeraisEMelhorias.itensGerais) {
      if (item.key.toLowerCase() == norm ||
          item.nome.toLowerCase() == norm ||
          norm.startsWith(item.nome.toLowerCase())) {
        return item;
      }
    }
    return null;
  }
}
