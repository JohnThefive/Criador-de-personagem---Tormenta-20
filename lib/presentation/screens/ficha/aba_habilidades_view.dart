import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/personagem/classe.dart';
import '../../../domain/entities/personagem/classe_do_personagem.dart';
import '../../../domain/entities/personagem/divindade.dart';
import '../../../domain/entities/habilidades_complexas/companheiro_animal.dart';
import '../../../domain/entities/habilidades_complexas/montaria_sagrada.dart';
import '../../../domain/services/data_services/call_formas_selvagens.dart';
import '../../../domain/services/data_services/call_companheiros.dart';
import '../../../domain/services/data_services/call_montaria_sagrada.dart';
import '../../widgets/modal_escolha_companheiro.dart';
import '../../controllers/ficha_cubit.dart';
import '../selecao_poderes_screen.dart';

class AbaHabilidadesView extends StatelessWidget {
  const AbaHabilidadesView({super.key});

  Future<void> _abrirSelecaoPoderes(BuildContext context, FichaCubit cubit, {int indiceClasse = 0}) async {
    final p = cubit.personagem;
    if (p.classes.isEmpty) return;
    final atualizado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SelecaoPoderesScreen(
          personagem: p,
          indiceClasse: indiceClasse,
        ),
      ),
    );
    if (!context.mounted) return;
    if (atualizado != null) {
      cubit.atualizarPersonagem(atualizado);
    }
  }

  void _mostrarModalEscolhaCaminho(
    BuildContext context,
    FichaCubit cubit,
    ClasseDoPersonagem classeDoPersonagem,
    List<CaminhoDeClasse> caminhos,
  ) {
    final p = cubit.personagem;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                classeDoPersonagem.classeDefinicao.idClasse == 'cavaleiro'
                    ? 'Caminho do Cavaleiro (5º Nível)'
                    : 'Escolha de Caminho / Especialização',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFFD32F2F),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                classeDoPersonagem.classeDefinicao.idClasse == 'cavaleiro'
                    ? 'No 5º nível, o cavaleiro deve escolher entre Bastião ou Montaria:'
                    : 'Selecione o caminho para a sua classe:',
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              ...caminhos.map((cam) {
                final selecionado = classeDoPersonagem.caminhoEscolhido?.nome == cam.nome;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: selecionado ? Colors.red.shade50 : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: selecionado ? const Color(0xFFD32F2F) : Colors.grey.shade300,
                      width: selecionado ? 2 : 1,
                    ),
                  ),
                  child: ListTile(
                    leading: Icon(
                      selecionado ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: selecionado ? const Color(0xFFD32F2F) : Colors.grey,
                    ),
                    title: Text(
                      cam.nome,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(cam.descricao),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final clAtualizada = classeDoPersonagem.copyWith(
                        caminhoEscolhido: cam,
                      );
                      final novasClasses = List<ClasseDoPersonagem>.from(p.classes);
                      final idx = p.classes.indexOf(classeDoPersonagem);
                      if (idx >= 0) {
                        novasClasses[idx] = clAtualizada;
                      } else {
                        novasClasses[0] = clAtualizada;
                      }
                      final novoP = p.copyWith(classe_do_personagem: novasClasses);
                      await cubit.atualizarPersonagem(novoP);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Caminho "${cam.nome}" escolhido com sucesso!'),
                          backgroundColor: const Color(0xFFD32F2F),
                        ),
                      );
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarModalAssumirFormaSelvagem(BuildContext context, FichaCubit cubit) {
    final p = cubit.personagem;
    final nivelDruida = p.nivelDruida;
    final formas = BancoDeFormasSelvagens.todas;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Assumir Forma Selvagem',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF33691E),
                      ),
                    ),
                    Text(
                      'Seu PM: ${p.pmAtual}/${p.pmTotal}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Escolha a forma que deseja assumir nesta cena:',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: formas.length,
                    itemBuilder: (_, index) {
                      final forma = formas[index];
                      final tier = forma.tierParaNivel(nivelDruida);
                      final nivelForma = forma.getNivelParaDruida(nivelDruida);
                      final temPm = p.pmAtual >= nivelForma.custoPm;
                      final modsTexto = nivelForma.modificadores.entries
                          .map((e) => '+${e.value} ${e.key}')
                          .join(', ');

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.pets, color: Color(0xFF33691E), size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      forma.nome,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      tier.toUpperCase(),
                                      style: const TextStyle(
                                        color: Color(0xFF2E7D32),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                forma.descricaoGeral,
                                style: const TextStyle(fontSize: 12, color: Colors.black87),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (modsTexto.isNotEmpty)
                                      Text(
                                        'Bônus: $modsTexto',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                          color: Color(0xFF1B5E20),
                                        ),
                                      ),
                                    if (nivelForma.armasNaturais.isNotEmpty)
                                      Text(
                                        'Armas Naturais: ${nivelForma.armasNaturais.map((a) => "${a.tipo == 'duas_armas' ? '2x ' : ''}${a.dano} (${a.critico})").join(", ")}',
                                        style: const TextStyle(fontSize: 11, color: Colors.black87),
                                      ),
                                    if (nivelForma.tamanho != null)
                                      Text(
                                        'Tamanho: ${nivelForma.tamanho}${nivelForma.deslocamento != null ? ' | Deslocamento: ${nivelForma.deslocamento}' : ''}',
                                        style: const TextStyle(fontSize: 11, color: Colors.black54),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: temPm ? const Color(0xFF2E7D32) : Colors.grey.shade400,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: temPm
                                      ? () {
                                          Navigator.pop(ctx);
                                          cubit.atualizarPersonagem(p.assumirFormaSelvagem(forma));
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Você assumiu a ${forma.nome}!'),
                                              backgroundColor: const Color(0xFF2E7D32),
                                            ),
                                          );
                                        }
                                      : null,
                                  child: Text(
                                    temPm
                                        ? 'Assumir esta Forma (${nivelForma.custoPm} PM)'
                                        : 'PM Insuficiente (${nivelForma.custoPm} PM)',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _mostrarModalEscolhaCompanheiroPainel(BuildContext context, FichaCubit cubit) {
    final p = cubit.personagem;
    mostrarModalEscolhaCompanheiro(
      context: context,
      nivelDruida: p.nivelDruida,
      onSelecionado: (comp) {
        cubit.atualizarPersonagem(p.copyWith(tipoCompanheiroAnimal: comp.key));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Companheiro "${comp.nome}" selecionado!')),
        );
      },
    );
  }

  void _mostrarDialogoEditarMontaria(BuildContext context, FichaCubit cubit, MontariaSagrada montariaAtual) {
    final p = cubit.personagem;
    final nomeController = TextEditingController(text: montariaAtual.nomeCustomizado);
    final especieController = TextEditingController(text: montariaAtual.especie);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Personalizar Montaria Sagrada'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome da Montaria',
                hintText: 'Ex: Brioso, Relâmpago',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: especieController,
              decoration: const InputDecoration(
                labelText: 'Espécie / Tipo de Animal',
                hintText: 'Ex: Cavalo de Guerra, Pônei, Grifo',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final novoNome = nomeController.text.trim().isEmpty ? 'Cavalo de Guerra' : nomeController.text.trim();
              final novaEspecie = especieController.text.trim().isEmpty ? 'Cavalo de Guerra' : especieController.text.trim();
              cubit.atualizarPersonagem(
                p.atualizarMontariaSagrada(
                  montariaAtual.copyWith(
                    nomeCustomizado: novoNome,
                    especie: novaEspecie,
                  ),
                ),
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Montaria sagrada atualizada!')),
              );
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    ).whenComplete(() {
      nomeController.dispose();
      especieController.dispose();
    });
  }

  Widget _buildBannerFormaSelvagemAtiva(BuildContext context, FichaCubit cubit) {
    final p = cubit.personagem;
    final forma = p.formaSelvagemAtiva!;
    final modsTexto = forma.modificadores.entries.map((e) => '+${e.value} ${e.key}').join(', ');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1B4332),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF52B788), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pets, color: Color(0xFF95D5B2), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Transfigurado: ${forma.nome}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D6A4F),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  forma.tier.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFFD8F3DC),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Bônus ativos: $modsTexto${forma.rd > 0 ? " | RD ${forma.rd}" : ""}${forma.tamanho != null ? " | Tamanho ${forma.tamanho}" : ""}',
            style: const TextStyle(color: Color(0xFFD8F3DC), fontSize: 12),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                cubit.atualizarPersonagem(p.reverterFormaSelvagem());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Você reverteu à sua forma normal.')),
                );
              },
              icon: const Icon(Icons.undo, size: 16),
              label: const Text(
                'Reverter Forma (Ação Livre)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardFormaSelvagem(BuildContext context, FichaCubit cubit) {
    final p = cubit.personagem;
    if (p.estaEmFormaSelvagem) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _buildBannerFormaSelvagemAtiva(context, cubit),
      );
    }

    return Card(
      color: const Color(0xFFF1F8E9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFAED581)),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pets, color: Color(0xFF33691E), size: 22),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Poder: Forma Selvagem',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF33691E),
                    ),
                  ),
                ),
                Text(
                  'Druida Nv. ${p.nivelDruida}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF558B2F),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Gaste uma ação completa e PM para transformar-se em uma fera que você conhece, alterando estatísticas e ganhando armas naturais.',
              style: TextStyle(fontSize: 12, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF33691E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => _mostrarModalAssumirFormaSelvagem(context, cubit),
                icon: const Icon(Icons.flash_on, size: 16),
                label: const Text(
                  'Assumir Forma Selvagem',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardCompanheiroAnimal(BuildContext context, FichaCubit cubit) {
    final p = cubit.personagem;
    final tipoKey = p.tipoCompanheiroAnimal;
    final comp = tipoKey != null ? BancoDeCompanheiros.getByKey(tipoKey) : null;
    final nivelDruida = p.nivelDruida;

    return Card(
      color: Colors.amber.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.amber.shade300),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pets, color: Colors.brown, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    comp != null ? 'Companheiro Animal: ${comp.nome}' : 'Companheiro Animal',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.brown,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    TipoCompanheiroAnimal.tierParaNivel(nivelDruida).toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      color: Colors.brown,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (comp != null) ...[
              Text(comp.descricao, style: const TextStyle(fontSize: 12, color: Colors.black87)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Text(
                  'Benefício: ${comp.getBeneficioParaNivel(nivelDruida)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Colors.brown.shade800,
                  ),
                ),
              ),
            ] else ...[
              const Text(
                'Você possui o poder Companheiro Animal, mas ainda não selecionou o tipo de animal parceiro.',
                style: TextStyle(fontSize: 12, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _mostrarModalEscolhaCompanheiroPainel(context, cubit),
                  child: const Text('Escolher Tipo de Companheiro'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCardMontariaSagrada(BuildContext context, FichaCubit cubit) {
    final p = cubit.personagem;
    final montaria = p.montariaSagrada ??
        MontariaSagrada(
          nomeCustomizado: BancoDeRegrasMontariaSagrada.animalPadraoParaTamanho(p.tamanho),
          especie: BancoDeRegrasMontariaSagrada.animalPadraoParaTamanho(p.tamanho),
        );
    final tier = p.tierMontariaSagrada;
    final deslocamento = p.deslocamentoMontadoMetros;
    final beneficios = BancoDeRegrasMontariaSagrada.beneficiosParaTier(tier);

    return Card(
      color: Colors.amber.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.amber.shade400),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pets, color: Colors.brown, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Montaria Sagrada: ${montaria.nomeCustomizado}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.brown,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18, color: Colors.brown),
                  tooltip: 'Personalizar Montaria',
                  onPressed: () => _mostrarDialogoEditarMontaria(context, cubit, montaria),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    tier.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      color: Colors.brown,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Espécie: ${montaria.especie} • Deslocamento: ${deslocamento}m',
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Text(
                'Benefício ($tier): $beneficios',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Colors.brown.shade800,
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (montaria.isVarianteMundana) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Variante Mundana Ativa: Animal físico permanente (sem custo de PM).',
                        style: TextStyle(fontSize: 11, color: Colors.green.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      montaria.invocada ? 'Status: Invocada na Cena (Ativa)' : 'Status: Em Repouso / Dispensada',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: montaria.invocada ? Colors.green.shade800 : Colors.grey.shade700,
                      ),
                    ),
                  ),
                  if (montaria.invocada)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      onPressed: () {
                        cubit.atualizarPersonagem(p.dispensarMontariaSagrada());
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Montaria sagrada dispensada.')),
                        );
                      },
                      icon: const Icon(Icons.close, size: 14),
                      label: const Text('Dispensar', style: TextStyle(fontSize: 11)),
                    )
                  else
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      onPressed: () {
                        const custo = 2;
                        if (p.pmAtual < custo) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('PM insuficiente para invocar a montaria sagrada (custa 2 PM).'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        cubit.atualizarPersonagem(p.invocarMontariaSagrada());
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${montaria.nomeCustomizado} invocada! (-2 PM)'),
                            backgroundColor: Colors.green.shade700,
                          ),
                        );
                      },
                      icon: const Icon(Icons.auto_awesome, size: 14),
                      label: const Text('Invocar (2 PM)', style: TextStyle(fontSize: 11)),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text(
                'Variante Mundana (animal físico)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                montaria.isVarianteMundana
                    ? 'Animal permanente físico (sujeito a terreno e passagens).'
                    : 'Animal sagrado/espiritual invocado por 2 PM até o fim da cena.',
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
              value: montaria.isVarianteMundana,
              onChanged: (val) {
                cubit.atualizarPersonagem(p.alternarVarianteMundanaMontaria(val));
              },
            ),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: const Text(
                  'Propriedades Sagradas',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.brown),
                ),
                children: BancoDeRegrasMontariaSagrada.propriedades.map((prop) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '• ',
                          style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold),
                        ),
                        Expanded(
                          child: Text(prop, style: const TextStyle(fontSize: 11, color: Colors.black87)),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<FichaCubit>();
    final p = cubit.state.personagem;
    final classeDoPersonagem = p.classes.isNotEmpty ? p.classes[0] : null;
    final classe = classeDoPersonagem?.classeDefinicao;
    final nivel = classeDoPersonagem?.nivel ?? 1;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (classe != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Classe: ${classe.nome}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFFD32F2F),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFD32F2F),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Nível $nivel',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (classeDoPersonagem?.caminhoEscolhido != null) ...[
            Card(
              color: Colors.amber.shade50,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.star, color: Colors.amber),
                title: Text(
                  'Caminho: ${classeDoPersonagem!.caminhoEscolhido!.nome}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(classeDoPersonagem.caminhoEscolhido!.descricao),
                trailing: classe.caminhosParaNivel(nivel).length > 1
                    ? IconButton(
                        icon: const Icon(Icons.edit, size: 18, color: Colors.brown),
                        tooltip: 'Alterar caminho',
                        onPressed: () => _mostrarModalEscolhaCaminho(
                          context,
                          cubit,
                          classeDoPersonagem,
                          classe.caminhosParaNivel(nivel),
                        ),
                      )
                    : null,
              ),
            ),
          ] else if (classeDoPersonagem != null && classe.caminhosParaNivel(nivel).isNotEmpty) ...[
            Card(
              color: Colors.red.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.red.shade300),
              ),
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.stars, color: Color(0xFFD32F2F)),
                title: Text(
                  classe.idClasse == 'cavaleiro'
                      ? 'Caminho do Cavaleiro (5º Nível)'
                      : 'Especialização / Caminho Disponível',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD32F2F)),
                ),
                subtitle: const Text('Toque para escolher seu caminho!'),
                trailing: const Icon(Icons.chevron_right, color: Color(0xFFD32F2F)),
                onTap: () => _mostrarModalEscolhaCaminho(
                  context,
                  cubit,
                  classeDoPersonagem,
                  classe.caminhosParaNivel(nivel),
                ),
              ),
            ),
          ],
          ...classe.habilidadesFixas.entries.map(
            (e) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.key,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD32F2F)),
                    ),
                    const SizedBox(height: 4),
                    Text(e.value, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
          if (p.temPoderFormaSelvagem) ...[_buildCardFormaSelvagem(context, cubit)],
          if (p.temPoderCompanheiroAnimal) ...[_buildCardCompanheiroAnimal(context, cubit)],
          if (p.temMontariaSagrada) ...[_buildCardMontariaSagrada(context, cubit)],
          if (classeDoPersonagem != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Poderes de Classe:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _abrirSelecaoPoderes(context, cubit),
                  icon: Icon(
                    classeDoPersonagem.temPoderPendente ? Icons.add_circle : Icons.tune,
                    size: 18,
                  ),
                  label: Text(
                    classeDoPersonagem.temPoderPendente
                        ? 'Escolher (${classeDoPersonagem.poderesPendentes})'
                        : 'Gerenciar',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: classeDoPersonagem.temPoderPendente
                        ? const Color(0xFFD32F2F)
                        : Colors.blueGrey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (classeDoPersonagem.poderesEscolhidos.isEmpty)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: Colors.amber.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.amber.shade300),
                ),
                child: ListTile(
                  leading: const Icon(Icons.info_outline, color: Colors.amber),
                  title: Text(
                    classeDoPersonagem.nivel >= 2
                        ? 'Nenhum poder de classe escolhido ainda.'
                        : 'Poderes de classe começam a ser escolhidos no 2º nível.',
                    style: const TextStyle(fontSize: 13),
                  ),
                  subtitle: classeDoPersonagem.temPoderPendente
                      ? const Text(
                          'Toque para aprender um novo poder de classe!',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD32F2F),
                          ),
                        )
                      : null,
                  trailing: classeDoPersonagem.temPoderPendente
                      ? const Icon(Icons.chevron_right, color: Color(0xFFD32F2F))
                      : null,
                  onTap: () => _abrirSelecaoPoderes(context, cubit),
                ),
              )
            else
              ...classeDoPersonagem.poderesEscolhidos.map(
                (poder) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.bolt, color: Color(0xFFD32F2F)),
                    title: Text(
                      poder.nome,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(poder.descricao),
                    trailing: IconButton(
                      icon: const Icon(Icons.settings, color: Colors.grey, size: 20),
                      tooltip: 'Gerenciar poderes',
                      onPressed: () => _abrirSelecaoPoderes(context, cubit),
                    ),
                  ),
                ),
              ),
            const Divider(height: 24),
          ],
        ],
        if (p.raca != null) ...[
          Text(
            'Raça: ${p.raca!.nome}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFFD32F2F),
            ),
          ),
          const SizedBox(height: 6),
          ...p.raca!.habilidadesRaca.entries.map(
            (e) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(e.value, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 24),
        ],
        if (p.divindade != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: p.punicaoDivinaAtiva ? Colors.red.shade700 : Colors.red.shade200,
                width: p.punicaoDivinaAtiva ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.divindade!.nome,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Color(0xFFD32F2F),
                            ),
                          ),
                          Text(
                            p.divindade!.titulo,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (p.ehDevotoFiel)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade700),
                        ),
                        child: Text(
                          'Devoto Fiel',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    Chip(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: EdgeInsets.zero,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                      backgroundColor: Colors.grey.shade100,
                      avatar: const Icon(Icons.colorize, size: 14, color: Colors.brown),
                      label: Text('Arma: ${p.divindade!.armaPreferida}', style: const TextStyle(fontSize: 11)),
                    ),
                    if (p.canalizacaoEnergia != null)
                      Chip(
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                        backgroundColor: p.canalizacaoEnergia == TipoEnergia.positiva
                            ? Colors.green.shade50
                            : Colors.purple.shade50,
                        avatar: Icon(
                          p.canalizacaoEnergia == TipoEnergia.positiva ? Icons.favorite : Icons.dark_mode,
                          size: 14,
                          color: p.canalizacaoEnergia == TipoEnergia.positiva
                              ? Colors.green.shade700
                              : Colors.purple.shade700,
                        ),
                        label: Text(
                          'Energia ${p.canalizacaoEnergia == TipoEnergia.positiva ? "Positiva" : "Negativa"}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: p.canalizacaoEnergia == TipoEnergia.positiva
                                ? Colors.green.shade900
                                : Colors.purple.shade900,
                          ),
                        ),
                      ),
                  ],
                ),
                const Divider(height: 20),
                const Text(
                  'Obrigações & Restrições:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                ...p.divindade!.obrigacoesERestricoes.map(
                  (regra) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• $regra',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade800, height: 1.25),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Poderes Concedidos:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
          ),
          const SizedBox(height: 6),
          if (p.poderesConcedidos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'Nenhum poder concedido associado.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            )
          else
            ...p.poderesConcedidos.map(
              (poderConcedido) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: p.punicaoDivinaAtiva ? Colors.red.shade300 : Colors.grey.shade300,
                  ),
                ),
                color: p.punicaoDivinaAtiva ? Colors.red.shade50.withValues(alpha: 0.5) : Colors.white,
                child: ListTile(
                  dense: true,
                  leading: Icon(
                    p.punicaoDivinaAtiva ? Icons.block : Icons.auto_awesome,
                    color: p.punicaoDivinaAtiva ? Colors.red.shade800 : Colors.amber.shade800,
                    size: 22,
                  ),
                  title: Row(
                    children: [
                      Text(
                        poderConcedido.nome,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: p.punicaoDivinaAtiva ? Colors.red.shade900 : Colors.black87,
                          decoration: p.punicaoDivinaAtiva ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (p.punicaoDivinaAtiva) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'INATIVO',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade900,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    poderConcedido.descricao,
                    style: TextStyle(
                      fontSize: 12,
                      color: p.punicaoDivinaAtiva ? Colors.grey.shade600 : Colors.grey.shade800,
                    ),
                  ),
                ),
              ),
            ),
          const Divider(height: 24),
        ],
        if (p.origem != null) ...[
          Text(
            'Origem: ${p.origem!.nome}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFFD32F2F),
            ),
          ),
          const SizedBox(height: 6),
          Text(p.origem!.descricao, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 8),
          if (p.poderesGerais.isNotEmpty)
            ...p.poderesGerais.map(
              (pg) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(pg.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(pg.descricao),
                ),
              ),
            ),
        ],
      ],
    );
  }
}
