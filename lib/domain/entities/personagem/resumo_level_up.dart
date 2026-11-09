import 'dart:math';
import 'personagem.dart';
import '../../services/ficha_services/motor_multiclasse_service.dart';
import '../../services/powers_service/aprendizado_magia_service.dart';

/// Entidade de domínio que resume todos os ganhos e desbloqueios ocorridos ao subir de nível
/// (PV, PM, novo patamar, novo círculo de magia desbloqueado, magias ganhas e poderes pendentes).
class ResumoLevelUp {
  final Personagem personagemAnterior;
  final Personagem personagemAtualizado;
  final int indiceClasse;
  final String idClasse;
  final String nomeClasse;
  final int nivelIndividualClasse;
  final int nivelTotalPersonagem;
  final PatamarJogo patamar;
  final bool novoPatamarAlcancado;
  final int deltaPV;
  final int deltaPM;
  final int? novoCirculoDesbloqueado;
  final String? tipoMagiaDesbloqueada;
  final int magiasNovasNoNivel;
  final int totalMagiasPendentes;
  final int poderesPendentesNaClasse;
  final List<String> caracteristicasNovas;

  const ResumoLevelUp({
    required this.personagemAnterior,
    required this.personagemAtualizado,
    required this.indiceClasse,
    required this.idClasse,
    required this.nomeClasse,
    required this.nivelIndividualClasse,
    required this.nivelTotalPersonagem,
    required this.patamar,
    required this.novoPatamarAlcancado,
    required this.deltaPV,
    required this.deltaPM,
    this.novoCirculoDesbloqueado,
    this.tipoMagiaDesbloqueada,
    required this.magiasNovasNoNivel,
    required this.totalMagiasPendentes,
    required this.poderesPendentesNaClasse,
    required this.caracteristicasNovas,
  });

  bool get temPoderPendente => poderesPendentesNaClasse > 0;
  bool get temMagiaPendente => totalMagiasPendentes > 0;
  bool get desbloqueouNovoCirculo => novoCirculoDesbloqueado != null;

  /// Calcula o resumo comparando o estado do personagem antes e depois do level up
  factory ResumoLevelUp.calcular({
    required Personagem anterior,
    required Personagem atualizado,
    required int indiceClasse,
  }) {
    final cl = atualizado.classes[indiceClasse];
    final def = cl.classeDefinicao;
    final nvIndividual = cl.nivel;
    final nvTotal = atualizado.nivelPersonagem;
    final patamar = PatamarJogo.porNivel(nvTotal);
    final patamarAnterior = PatamarJogo.porNivel(anterior.nivelPersonagem);
    final novoPatamar = patamar != patamarAnterior && nvTotal > 1;

    final deltaPV = max(0, atualizado.pvTotal - anterior.pvTotal);
    final deltaPM = max(0, atualizado.pmTotal - anterior.pmTotal);

    final novoCirculo = AprendizadoMagiaService.circuloDesbloqueadoNoNivel(
      def.idClasse,
      nvIndividual,
    );

    final regras = AprendizadoMagiaService.obterRegrasIniciais(
      def.idClasse,
      caminhoId: cl.caminhoEscolhido?.nome,
    );

    final magiasNovas = AprendizadoMagiaService.magiasGanhasNoNivel(
      def.idClasse,
      nvIndividual,
      caminhoId: cl.caminhoEscolhido?.nome,
    );

    final totalMagiasPendentes =
        AprendizadoMagiaService.calcularMagiasPendentesPersonagem(atualizado);

    final caracteristicasNovas =
        def.tabelaDeProgressao[nvIndividual] ?? const <String>[];

    return ResumoLevelUp(
      personagemAnterior: anterior,
      personagemAtualizado: atualizado,
      indiceClasse: indiceClasse,
      idClasse: def.idClasse,
      nomeClasse: def.nome,
      nivelIndividualClasse: nvIndividual,
      nivelTotalPersonagem: nvTotal,
      patamar: patamar,
      novoPatamarAlcancado: novoPatamar,
      deltaPV: deltaPV,
      deltaPM: deltaPM,
      novoCirculoDesbloqueado: novoCirculo,
      tipoMagiaDesbloqueada: regras.tipoMagia,
      magiasNovasNoNivel: magiasNovas,
      totalMagiasPendentes: totalMagiasPendentes,
      poderesPendentesNaClasse: cl.poderesPendentes,
      caracteristicasNovas: caracteristicasNovas,
    );
  }
}
