import 'poder.dart';

class Origem {
  final String id;
  final String nome;
  final String descricao;
  final List<String> itensIniciais;
  final List<String> periciasOpcoes;
  final List<String> poderesGeraisOpcoesIds;
  final String poderUnicoId;
  final bool escolhaLivrePoderCombate;
  final bool escolhaLivrePoderTormenta;
  final int qtdBeneficiosEscolha;
  final String? beneficiosEspeciais;
  final List<Poder> poderesGeraisOpcoes;
  final Poder poderUnico; // Poder exclusivo desta origem

  const Origem({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.itensIniciais,
    required this.periciasOpcoes,
    required this.poderesGeraisOpcoes,
    required this.poderUnico,
    this.poderesGeraisOpcoesIds = const [],
    this.poderUnicoId = '',
    this.escolhaLivrePoderCombate = false,
    this.escolhaLivrePoderTormenta = false,
    this.qtdBeneficiosEscolha = 2,
    this.beneficiosEspeciais,
  });

  static String _formatarIdParaNome(String id) {
    return id
        .split('_')
        .map(
          (w) =>
              w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '',
        )
        .join(' ');
  }

  factory Origem.fromJson(
    Map<String, dynamic> json, {
    Map<String, Poder>? catalogoHabilidadesUnicas,
    Poder? Function(String id)? buscarPoderGeral,
    List<Poder>? poderesCombate,
  }) {
    final bool livreCombate = json['escolhaLivrePoderCombate'] as bool? ?? false;
    final bool livreTormenta =
        json['escolhaLivrePoderTormenta'] as bool? ?? false;
    final int qtdBeneficios =
        (json['qtdBeneficiosEscolha'] as num?)?.toInt() ?? 2;

    // 1. Resolução da Habilidade Única (poderUnicoId)
    final String unicoIdRaw =
        json['poderUnicoId']?.toString().trim() ??
        (json['poderUnico'] is Map
            ? (json['poderUnico']['key']?.toString().trim() ?? '')
            : '');

    Poder poderUnicoResolvido;
    if (json['poderUnico'] is Map) {
      poderUnicoResolvido = Poder.fromJson(
        Map<String, dynamic>.from(json['poderUnico'] as Map),
      );
    } else if (unicoIdRaw.isNotEmpty && catalogoHabilidadesUnicas != null) {
      final norm = unicoIdRaw.toLowerCase();
      poderUnicoResolvido =
          catalogoHabilidadesUnicas[norm] ??
          catalogoHabilidadesUnicas[norm.replaceAll('-', '_')] ??
          Poder(
            key: unicoIdRaw,
            nome: _formatarIdParaNome(unicoIdRaw),
            descricao: 'Habilidade única de origem.',
          );
    } else if (unicoIdRaw.isNotEmpty) {
      poderUnicoResolvido = Poder(
        key: unicoIdRaw,
        nome: _formatarIdParaNome(unicoIdRaw),
        descricao: 'Habilidade única de origem.',
      );
    } else {
      poderUnicoResolvido = const Poder(key: '', nome: '', descricao: '');
    }

    // 2. Resolução dos Poderes Gerais (poderesGeraisOpcoesIds + escolhaLivrePoderCombate)
    final List<String> geraisIds = List<String>.from(
      json['poderesGeraisOpcoesIds'] ?? const [],
    );

    final List<Poder> geraisResolvidos = [];
    final Set<String> chavesAdicionadas = {};

    void adicionarPoderSeNovo(Poder poder) {
      final k = poder.key.trim().toLowerCase();
      if (k.isNotEmpty && chavesAdicionadas.add(k)) {
        geraisResolvidos.add(poder);
      }
    }

    // Compatibilidade com formato embutido legado
    if (json['poderesGeraisOpcoes'] is List) {
      for (final p in json['poderesGeraisOpcoes'] as List) {
        if (p is Map) {
          final pod = Poder.fromJson(Map<String, dynamic>.from(p));
          adicionarPoderSeNovo(pod);
          if (!geraisIds.contains(pod.key) && pod.key.isNotEmpty) {
            geraisIds.add(pod.key);
          }
        }
      }
    }

    // Busca poderes específicos de poderesGeraisOpcoesIds no serviço centralizado
    for (final idPoder in geraisIds) {
      final idClean = idPoder.trim();
      if (idClean.isEmpty) continue;
      final Poder? encontrado = buscarPoderGeral?.call(idClean);
      if (encontrado != null) {
        adicionarPoderSeNovo(encontrado);
      } else if (!chavesAdicionadas.contains(idClean.toLowerCase())) {
        adicionarPoderSeNovo(
          Poder(
            key: idClean,
            nome: _formatarIdParaNome(idClean),
            descricao: 'Poder geral de Tormenta 20.',
          ),
        );
      }
    }

    // Se escolhaLivrePoderCombate for verdadeiro, disponibiliza a lista completa de poderes_combate.json
    if (livreCombate && poderesCombate != null) {
      for (final poderCombate in poderesCombate) {
        adicionarPoderSeNovo(poderCombate);
      }
    }

    return Origem(
      id: json['id'] as String? ?? '',
      nome: json['nome'] as String? ?? '',
      descricao: json['descricao'] as String? ?? '',
      itensIniciais: List<String>.from(json['itensIniciais'] ?? []),
      periciasOpcoes: List<String>.from(json['periciasOpcoes'] ?? []),
      poderesGeraisOpcoesIds: geraisIds,
      poderUnicoId: unicoIdRaw,
      escolhaLivrePoderCombate: livreCombate,
      escolhaLivrePoderTormenta: livreTormenta,
      qtdBeneficiosEscolha: qtdBeneficios,
      beneficiosEspeciais: json['beneficiosEspeciais'] as String?,
      poderesGeraisOpcoes: geraisResolvidos,
      poderUnico: poderUnicoResolvido,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nome': nome,
    'descricao': descricao,
    'itensIniciais': itensIniciais,
    'periciasOpcoes': periciasOpcoes,
    'poderesGeraisOpcoesIds': poderesGeraisOpcoesIds,
    'poderUnicoId': poderUnicoId,
    if (escolhaLivrePoderCombate)
      'escolhaLivrePoderCombate': escolhaLivrePoderCombate,
    if (escolhaLivrePoderTormenta)
      'escolhaLivrePoderTormenta': escolhaLivrePoderTormenta,
    if (qtdBeneficiosEscolha != 2)
      'qtdBeneficiosEscolha': qtdBeneficiosEscolha,
    if (beneficiosEspeciais != null)
      'beneficiosEspeciais': beneficiosEspeciais,
  };
}
