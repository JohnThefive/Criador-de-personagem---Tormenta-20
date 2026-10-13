import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/magia/magia.dart';
import '../../domain/services/poderes_e_magias/aprendizado_magia_service.dart';
import '../controllers/personagem_cubit.dart';

class PaginaSelecaoMagias extends StatefulWidget {
  final PersonagemState state;

  const PaginaSelecaoMagias({super.key, required this.state});

  @override
  State<PaginaSelecaoMagias> createState() => _PaginaSelecaoMagiasState();
}

class _PaginaSelecaoMagiasState extends State<PaginaSelecaoMagias> {
  String _filtroTexto = '';
  String _filtroEscola = 'TODAS';
  Magia? _magiaSelecionadaParaDetalhe;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final cubit = context.read<PersonagemCubit>();
    final regras = state.regrasConjuracao;

    if (!regras.isConjurador) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_fix_off_rounded,
                  size: 56,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Classe Não Conjuradora',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'A classe selecionada (${state.personagem.classes.isNotEmpty ? state.personagem.classes[0].classeDefinicao.nome : "Nenhuma"}) não possui conjuração de magias no 1º nível.\nVocê pode avançar diretamente para o próximo passo.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final classeId = state.personagem.classes[0].classeDefinicao.idClasse;
    final todasDisponiveis = AprendizadoMagiaService.obterMagiasDisponiveis(classeId);
    final selecionadasIds = state.magiasSelecionadas;

    // Filtra as magias pela busca e pela escola
    final magiasFiltradas = todasDisponiveis.where((magia) {
      final matchesTexto = _filtroTexto.isEmpty ||
          magia.nome.toLowerCase().contains(_filtroTexto.toLowerCase()) ||
          magia.descricao.toLowerCase().contains(_filtroTexto.toLowerCase());
      final matchesEscola = _filtroEscola == 'TODAS' ||
          magia.escola.toLowerCase() == _filtroEscola.toLowerCase();
      return matchesTexto && matchesEscola;
    }).toList();

    final escolas = [
      'TODAS',
      ...{...todasDisponiveis.map((m) => m.escola.toUpperCase())}
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isLargeScreen = constraints.maxWidth >= 720;

        return Column(
          children: [
            // HUD Superior de Status
            _buildHeaderStatus(regras, selecionadasIds.length),

            // Filtros de busca e escola
            _buildFiltros(escolas),

            // Conteúdo responsivo
            Expanded(
              child: isLargeScreen
                  ? _buildLargeScreenLayout(
                      magias: magiasFiltradas,
                      selecionadasIds: selecionadasIds,
                      regras: regras,
                      cubit: cubit,
                    )
                  : _buildSmallScreenLayout(
                      magias: magiasFiltradas,
                      selecionadasIds: selecionadasIds,
                      regras: regras,
                      cubit: cubit,
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeaderStatus(RegrasConjuracaoClasse regras, int totalSelecionadas) {
    final bool completo = totalSelecionadas == regras.qtdMagiasIniciais;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFF2563EB),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Magias de 1º Círculo (${regras.tipoMagia?.toUpperCase() ?? ""})',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  'Atributo-Chave: ${regras.atributoChave ?? "INT"} • Escolha suas magias iniciais',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: completo
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: completo
                    ? const Color(0xFF86EFAC)
                    : const Color(0xFFFDE68A),
              ),
            ),
            child: Text(
              '$totalSelecionadas / ${regras.qtdMagiasIniciais}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: completo
                    ? const Color(0xFF166534)
                    : const Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros(List<String> escolas) {
    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Pesquisar magia pelo nome ou descrição...',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _filtroTexto.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() => _filtroTexto = ''),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            onChanged: (val) => setState(() => _filtroTexto = val),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: escolas.map((escola) {
                final bool isSelected = _filtroEscola == escola;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(escola),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _filtroEscola = escola);
                      }
                    },
                    selectedColor: const Color(0xFFB71C1C),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.grey.shade800,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallScreenLayout({
    required List<Magia> magias,
    required List<String> selecionadasIds,
    required RegrasConjuracaoClasse regras,
    required PersonagemCubit cubit,
  }) {
    if (magias.isEmpty) {
      return Center(
        child: Text(
          'Nenhuma magia encontrada.',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: magias.length,
      itemBuilder: (context, index) {
        final magia = magias[index];
        final isMarcada = selecionadasIds.contains(magia.id);

        return Card(
          elevation: isMarcada ? 2 : 1,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isMarcada ? const Color(0xFFB71C1C) : Colors.grey.shade300,
              width: isMarcada ? 1.5 : 1,
            ),
          ),
          color: isMarcada ? const Color(0xFFFEF2F2) : Colors.white,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            leading: Checkbox(
              value: isMarcada,
              activeColor: const Color(0xFFB71C1C),
              onChanged: (_) => _alternarSelecao(magia.id, selecionadasIds, regras, cubit),
            ),
            title: Text(
              magia.nome,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isMarcada ? const Color(0xFF991B1B) : const Color(0xFF111827),
              ),
            ),
            subtitle: Text(
              '${magia.escola.toUpperCase()} • ${magia.execucao.detalhes ?? magia.execucao.tipo} • Alcance: ${magia.alcance.detalhes ?? magia.alcance.tipo}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB)),
              onPressed: () => _exibirDetalhesModal(magia),
            ),
            onTap: () => _alternarSelecao(magia.id, selecionadasIds, regras, cubit),
          ),
        );
      },
    );
  }

  Widget _buildLargeScreenLayout({
    required List<Magia> magias,
    required List<String> selecionadasIds,
    required RegrasConjuracaoClasse regras,
    required PersonagemCubit cubit,
  }) {
    final magiaExibida = _magiaSelecionadaParaDetalhe ?? (magias.isNotEmpty ? magias.first : null);

    return Row(
      children: [
        // Coluna da Lista de Magias
        Expanded(
          flex: 3,
          child: magias.isEmpty
              ? Center(
                  child: Text(
                    'Nenhuma magia encontrada.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: magias.length,
                  itemBuilder: (context, index) {
                    final magia = magias[index];
                    final isMarcada = selecionadasIds.contains(magia.id);
                    final isFocada = magiaExibida?.id == magia.id;

                    return Card(
                      elevation: isFocada ? 2.5 : 1,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isFocada
                              ? const Color(0xFF2563EB)
                              : (isMarcada ? const Color(0xFFB71C1C) : Colors.grey.shade300),
                          width: isFocada ? 2 : (isMarcada ? 1.5 : 1),
                        ),
                      ),
                      color: isMarcada ? const Color(0xFFFEF2F2) : Colors.white,
                      child: ListTile(
                        leading: Checkbox(
                          value: isMarcada,
                          activeColor: const Color(0xFFB71C1C),
                          onChanged: (_) =>
                              _alternarSelecao(magia.id, selecionadasIds, regras, cubit),
                        ),
                        title: Text(
                          magia.nome,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isMarcada
                                ? const Color(0xFF991B1B)
                                : const Color(0xFF111827),
                          ),
                        ),
                        subtitle: Text(
                          '${magia.escola.toUpperCase()} • ${magia.execucao.detalhes ?? magia.execucao.tipo}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            isFocada ? Icons.visibility : Icons.visibility_outlined,
                            color: const Color(0xFF2563EB),
                          ),
                          onPressed: () => setState(() => _magiaSelecionadaParaDetalhe = magia),
                        ),
                        onTap: () {
                          setState(() => _magiaSelecionadaParaDetalhe = magia);
                          _alternarSelecao(magia.id, selecionadasIds, regras, cubit);
                        },
                      ),
                    );
                  },
                ),
        ),

        // Divisor vertical
        const VerticalDivider(width: 1, thickness: 1),

        // Coluna de Detalhes da Magia
        Expanded(
          flex: 2,
          child: magiaExibida == null
              ? const Center(
                  child: Text('Selecione uma magia para visualizar seus detalhes.'),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _buildConteudoDetalheMagia(magiaExibida),
                ),
        ),
      ],
    );
  }

  void _alternarSelecao(
    String id,
    List<String> selecionadas,
    RegrasConjuracaoClasse regras,
    PersonagemCubit cubit,
  ) {
    if (selecionadas.contains(id)) {
      cubit.alternarMagia(id);
    } else {
      if (selecionadas.length < regras.qtdMagiasIniciais) {
        cubit.alternarMagia(id);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Você já selecionou o limite de ${regras.qtdMagiasIniciais} magias para o 1º nível.',
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFFB71C1C),
          ),
        );
      }
    }
  }

  void _exibirDetalhesModal(Magia magia) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return ListView(
              controller: controller,
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildConteudoDetalheMagia(magia),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildConteudoDetalheMagia(Magia magia) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                magia.nome,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Text(
                '1º CÍRCULO',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D4ED8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${magia.escola.toUpperCase()} • ${magia.tipo.toUpperCase()}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const Divider(height: 24),
        _buildInfoRow(Icons.timer_outlined, 'Execução', magia.execucao.detalhes ?? magia.execucao.tipo),
        _buildInfoRow(Icons.radar_outlined, 'Alcance', magia.alcance.detalhes ?? magia.alcance.tipo),
        _buildInfoRow(Icons.filter_center_focus_outlined, 'Alvo/Área', magia.efeito.descricao ?? magia.efeito.tipo),
        _buildInfoRow(Icons.hourglass_bottom_outlined, 'Duração', magia.duracao.detalhes ?? magia.duracao.tipo),
        if (magia.resistencia != null)
          _buildInfoRow(
            Icons.shield_outlined,
            'Resistência',
            '${magia.resistencia!.tipoTeste ?? ""} (${magia.resistencia!.resultadoSucesso})',
          ),
        const SizedBox(height: 16),
        const Text(
          'Descrição:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 6),
        Text(
          magia.descricao,
          style: const TextStyle(fontSize: 14, height: 1.45, color: Color(0xFF374151)),
        ),
        if (magia.aprimoramentos.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text(
            'Aprimoramentos:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          ...magia.aprimoramentos.map((ap) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ap.custoAdicionalPM > 0
                        ? '+${ap.custoAdicionalPM} PM: '
                        : (ap.isTruque ? 'Truque: ' : '• '),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFFB71C1C),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      ap.descricao,
                      style: const TextStyle(fontSize: 13, height: 1.35),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
            ),
          ),
        ],
      ),
    );
  }
}
