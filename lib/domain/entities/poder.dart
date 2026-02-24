import 'personagem.dart';
import 'classe_do_personagem.dart';

class Poder {
  final String nome;
  final String descricao; // O efeito mecânico

  // --- PRÉ-REQUISITOS ---
  final int nivelMinimo;
  final List<String> caminhosExigidos; // Ex: ['Bruxo', 'Mago']
  final List<String> poderesExigidos;  // Ex: ['Raio Arcano']
  final List<String> periciasExigidas; // Ex: ['Ofício (Escriba)']

  const Poder({
    required this.nome,
    required this.descricao,
    this.nivelMinimo = 1,
    this.caminhosExigidos = const [],
    this.poderesExigidos = const [],
    this.periciasExigidas = const [],
  });

  // O motor de validação: O App chama isso para saber se o botão fica cinza ou clicável
  bool isElegivel(Personagem personagem, ClasseDoPersonagem classeAtual) {
    // 1. Checa Nível
    if (classeAtual.nivel < nivelMinimo) return false;

    // 2. Checa Caminho (Se a lista não for vazia, o caminho atual DEVE estar nela)
    if (caminhosExigidos.isNotEmpty) {
      final caminhoAtual = classeAtual.caminhoEscolhido?.nome;
      if (caminhoAtual == null || !caminhosExigidos.contains(caminhoAtual)) {
        return false;
      }
    }

    // 3. Checa Poderes Anteriores
    final nomesDosPoderesQueTenho = classeAtual.poderesEscolhidos.map((p) => p.nome).toList();
    for (var exigido in poderesExigidos) {
      if (!nomesDosPoderesQueTenho.contains(exigido)) return false;
    }

    // 4. Checa Perícias (Assumindo que teremos uma lista de perícias treinadas no personagem no futuro)
    // for (var pericia in periciasExigidas) {
    //   if (!personagem.periciasTreinadas.contains(pericia)) return false;
    // }

    return true; // Passou em tudo!
  }
}