import 'tipo_dano.dart';

class ResultadoAtaque {
  final String atacanteNome;
  final String defensorNome;
  final String armaNome;
  final bool acerto;
  final bool ehCritico;
  final int valorDadoNatural; // 1 a 20
  final int totalAtaque; // Dado + Modificadores
  final int defesaAlvo;
  final int danoTotal; // 0 se errou
  final TipoDano tipoDano;
  final String detalheDano; // Ex: "Rolagem: [5, 4] + 3 (FOR) = 12 de Corte"
  final String logResumo;

  const ResultadoAtaque({
    required this.atacanteNome,
    required this.defensorNome,
    required this.armaNome,
    required this.acerto,
    required this.ehCritico,
    required this.valorDadoNatural,
    required this.totalAtaque,
    required this.defesaAlvo,
    required this.danoTotal,
    required this.tipoDano,
    required this.detalheDano,
    required this.logResumo,
  });
}
