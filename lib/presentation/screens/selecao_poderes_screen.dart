import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/personagem.dart';
import '../../domain/entities/poder.dart';
import '../controllers/evolucao_cubit.dart';

class SelecaoPoderesScreen extends StatelessWidget {
  final Personagem personagem;
  final int indiceClasse;

  const SelecaoPoderesScreen({
    super.key,
    required this.personagem,
    this.indiceClasse = 0,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          EvolucaoCubit(personagem: personagem, indiceClasse: indiceClasse),
      child: const _SelecaoPoderesView(),
    );
  }
}

class _SelecaoPoderesView extends StatelessWidget {
  const _SelecaoPoderesView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EvolucaoCubit, EvolucaoState>(
      listener: (context, state) {
        if (state.mensagemErro != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.mensagemErro!),
              backgroundColor: Colors.red.shade800,
            ),
          );
          context.read<EvolucaoCubit>().limparMensagens();
        } else if (state.mensagemSucesso != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.mensagemSucesso!),
              backgroundColor: Colors.green.shade800,
            ),
          );
          context.read<EvolucaoCubit>().limparMensagens();
        }
      },
      builder: (context, state) {
        final classe = state.classeAtual;
        final cubit = context.read<EvolucaoCubit>();
        final itens = state.itensFiltrados;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            // Retorna o personagem atualizado para a tela anterior
            Navigator.pop(context, state.personagem);
          },
          child: Scaffold(
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Poderes de Classe',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF008000),
                    ),
                  ),
                  Text(
                    '${classe.classeDefinicao.nome} (Nível ${classe.nivel})',
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF1E1E2C),
              iconTheme: const IconThemeData(color: Colors.white),
              actions: [
                IconButton(
                  tooltip: 'Concluir',
                  icon: const Icon(Icons.check, color: Colors.amber),
                  onPressed: () => Navigator.pop(context, state.personagem),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF12121A),
            body: Column(
              children: [
                // 1. Painel Informativo de Evolução
                _buildCabecalhoEvolucao(context, state),

                // 2. Barra de Busca e Filtros
                _buildBarraBuscaEFiltros(context, state, cubit),

                // 3. Lista de Poderes
                Expanded(
                  child: itens.isEmpty
                      ? _buildListaVazia(state)
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          itemCount: itens.length,
                          itemBuilder: (context, index) {
                            final item = itens[index];
                            return _CardPoderEvolucao(
                              item: item,
                              temPoderPendente: state.temPoderPendente,
                              onAprender: () => _confirmarAprender(
                                context,
                                cubit,
                                item.poder,
                              ),
                              onRemover: () =>
                                  _confirmarRemover(context, cubit, item.poder),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCabecalhoEvolucao(BuildContext context, EvolucaoState state) {
    final classe = state.classeAtual;
    final pendentes = state.poderesPendentes;
    final permitidos = state.poderesPermitidos;
    final escolhidos = classe.poderesEscolhidos.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Nível de Classe',
                  '${classe.nivel}º',
                  Icons.shield_outlined,
                  Colors.white,
                ),
              ),
              Container(width: 1, height: 35, color: Colors.white24),
              Expanded(
                child: _buildInfoItem(
                  'Poderes da Classe',
                  '$escolhidos de $permitidos',
                  Icons.auto_awesome,
                  Colors.amber,
                ),
              ),
              Container(width: 1, height: 35, color: Colors.white24),
              Expanded(
                child: _buildInfoItem(
                  'Disponíveis',
                  '$pendentes',
                  Icons.add_circle_outline,
                  pendentes > 0 ? Colors.greenAccent : Colors.grey,
                ),
              ),
            ],
          ),
          if (pendentes > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Você possui $pendentes ${pendentes == 1 ? "poder" : "poderes"} de classe para escolher!',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    String label,
    String valor,
    IconData icon,
    Color corValor,
  ) {
    return Column(
      children: [
        Icon(icon, size: 18, color: Colors.white70),
        const SizedBox(height: 4),
        Text(
          valor,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: corValor,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white60),
        ),
      ],
    );
  }

  Widget _buildBarraBuscaEFiltros(
    BuildContext context,
    EvolucaoState state,
    EvolucaoCubit cubit,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      child: Column(
        children: [
          // Campo de busca
          TextField(
            onChanged: cubit.atualizarBusca,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Buscar poder pelo nome...',
              hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
              prefixIcon: const Icon(
                Icons.search,
                color: Colors.white54,
                size: 20,
              ),
              suffixIcon: state.busca.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: Colors.white54,
                        size: 18,
                      ),
                      onPressed: () => cubit.atualizarBusca(''),
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFF2A2A3C),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Chips de filtro
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFiltroChip(
                  label: 'Todos (${state.todosItens.length})',
                  filtro: FiltroPoderes.todos,
                  filtroAtual: state.filtro,
                  onSelect: () => cubit.alterarFiltro(FiltroPoderes.todos),
                ),
                const SizedBox(width: 8),
                _buildFiltroChip(
                  label:
                      'Disponíveis (${state.todosItens.where((i) => i.podeAprender).length})',
                  filtro: FiltroPoderes.disponiveis,
                  filtroAtual: state.filtro,
                  onSelect: () =>
                      cubit.alterarFiltro(FiltroPoderes.disponiveis),
                  corAtiva: Colors.greenAccent.shade700,
                ),
                const SizedBox(width: 8),
                _buildFiltroChip(
                  label:
                      'Adquiridos (${state.todosItens.where((i) => i.jaAdquirido).length})',
                  filtro: FiltroPoderes.adquiridos,
                  filtroAtual: state.filtro,
                  onSelect: () => cubit.alterarFiltro(FiltroPoderes.adquiridos),
                  corAtiva: Colors.blueAccent,
                ),
                const SizedBox(width: 8),
                _buildFiltroChip(
                  label:
                      'Bloqueados (${state.todosItens.where((i) => i.bloqueado).length})',
                  filtro: FiltroPoderes.bloqueados,
                  filtroAtual: state.filtro,
                  onSelect: () => cubit.alterarFiltro(FiltroPoderes.bloqueados),
                  corAtiva: Colors.redAccent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltroChip({
    required String label,
    required FiltroPoderes filtro,
    required FiltroPoderes filtroAtual,
    required VoidCallback onSelect,
    Color? corAtiva,
  }) {
    final bool ativo = filtro == filtroAtual;
    final cor = corAtiva ?? Colors.amber;

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: ativo ? FontWeight.bold : FontWeight.normal,
          color: ativo ? Colors.black : Colors.white70,
        ),
      ),
      selected: ativo,
      onSelected: (_) => onSelect(),
      selectedColor: cor,
      backgroundColor: const Color(0xFF2A2A3C),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: ativo ? cor : Colors.white24, width: 1),
      ),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildListaVazia(EvolucaoState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_outlined,
              size: 54,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              state.busca.isNotEmpty
                  ? 'Nenhum poder encontrado para "${state.busca}"'
                  : 'Nenhum poder nesta categoria.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarAprender(
    BuildContext context,
    EvolucaoCubit cubit,
    Poder poder,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        title: Text(
          'Aprender ${poder.nome}?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              poder.descricao,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            const Text(
              'Esta escolha gastará 1 vaga de poder de classe.',
              style: TextStyle(
                color: Colors.amber,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white60),
            ),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.black,
            ),
            child: const Text(
              'Confirmar Escolha',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              cubit.aprenderPoder(poder);
            },
          ),
        ],
      ),
    );
  }

  void _confirmarRemover(
    BuildContext context,
    EvolucaoCubit cubit,
    Poder poder,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        title: Text(
          'Remover ${poder.nome}?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Você poderá escolher outro poder no lugar deste.',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white60),
            ),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remover'),
            onPressed: () {
              Navigator.pop(ctx);
              cubit.removerPoder(poder.key);
            },
          ),
        ],
      ),
    );
  }
}

class _CardPoderEvolucao extends StatelessWidget {
  final ItemPoderEvolucao item;
  final bool temPoderPendente;
  final VoidCallback onAprender;
  final VoidCallback onRemover;

  const _CardPoderEvolucao({
    required this.item,
    required this.temPoderPendente,
    required this.onAprender,
    required this.onRemover,
  });

  @override
  Widget build(BuildContext context) {
    final poder = item.poder;
    final podeAprender = item.podeAprender;
    final jaAdquirido = item.jaAdquirido;
    final bloqueado = item.bloqueado;

    // Definição de cores e bordas por status
    Color corBorda = Colors.white12;
    Color corFundo = const Color(0xFF1A1A26);
    if (jaAdquirido) {
      corBorda = Colors.blueAccent.withValues(alpha: 0.5);
      corFundo = const Color(0xFF142033);
    } else if (podeAprender) {
      corBorda = temPoderPendente
          ? Colors.greenAccent.withValues(alpha: 0.6)
          : Colors.amber.withValues(alpha: 0.4);
      corFundo = const Color(0xFF1E2822);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: corFundo,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: corBorda, width: 1.2),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Topo do card: Nome + Status Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    poder.nome,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: jaAdquirido
                          ? Colors.blue.shade200
                          : (podeAprender ? Colors.white : Colors.white60),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildBadgeStatus(),
              ],
            ),
            const SizedBox(height: 8),

            // Descrição do Poder
            Text(
              poder.descricao,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: bloqueado ? Colors.white54 : Colors.white70,
              ),
            ),

            // Lista de Requisitos Discriminados
            if (item.elegibilidade.requisitos.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 8),
              const Text(
                'Pré-requisitos:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: item.elegibilidade.requisitos.map((req) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: req.atendido
                          ? Colors.green.withValues(alpha: 0.15)
                          : Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: req.atendido
                            ? Colors.green.withValues(alpha: 0.4)
                            : Colors.red.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          req.atendido ? Icons.check : Icons.close,
                          size: 13,
                          color: req.atendido
                              ? Colors.greenAccent
                              : Colors.redAccent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          req.descricao,
                          style: TextStyle(
                            fontSize: 11,
                            color: req.atendido
                                ? Colors.green.shade200
                                : Colors.red.shade200,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],

            // Botão de Ação
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (jaAdquirido) ...[
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text(
                      'Remover Poder',
                      style: TextStyle(fontSize: 12),
                    ),
                    onPressed: onRemover,
                  ),
                ] else if (podeAprender) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: temPoderPendente
                          ? Colors.amber.shade700
                          : Colors.grey.shade700,
                      foregroundColor: temPoderPendente
                          ? Colors.black
                          : Colors.white70,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: Icon(
                      temPoderPendente ? Icons.add : Icons.lock_clock,
                      size: 16,
                    ),
                    label: Text(
                      temPoderPendente
                          ? 'Aprender Poder'
                          : 'Sem Vagas de Poder',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: temPoderPendente ? onAprender : null,
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock, size: 14, color: Colors.white38),
                        SizedBox(width: 4),
                        Text(
                          'Requisitos Pendentes',
                          style: TextStyle(fontSize: 11, color: Colors.white38),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeStatus() {
    if (item.jaAdquirido) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.blueAccent.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.5)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 13, color: Colors.blueAccent),
            SizedBox(width: 4),
            Text(
              'Adquirido',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
          ],
        ),
      );
    }

    if (item.podeAprender) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.greenAccent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.5)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 13, color: Colors.greenAccent),
            SizedBox(width: 4),
            Text(
              'Disponível',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.greenAccent,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock, size: 13, color: Colors.redAccent),
          SizedBox(width: 4),
          Text(
            'Bloqueado',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }
}
