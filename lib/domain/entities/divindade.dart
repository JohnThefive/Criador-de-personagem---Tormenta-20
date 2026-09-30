import 'poder.dart';

enum TipoEnergia { positiva, negativa, qualquer }

class Divindade {
  final String id;
  final String nome;
  final String titulo; // Ex: "Deus da Justiça", "Deusa da Ambição"
  final String simboloSagrado;
  final TipoEnergia energiaCanalizada;
  final String armaPreferida;
  final String descricao;
  final String obrigacoesERestricoes;
  final List<Poder> poderesConcedidos;

  const Divindade({
    required this.id,
    required this.nome,
    required this.titulo,
    required this.simboloSagrado,
    required this.energiaCanalizada,
    required this.armaPreferida,
    required this.descricao,
    required this.obrigacoesERestricoes,
    required this.poderesConcedidos,
  });
}
