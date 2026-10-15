import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../controllers/ficha_cubit.dart';
import 'dialogo_rolagem_dado.dart';
import 'dialogos_ficha.dart';

class AbaGeralView extends StatelessWidget {
  const AbaGeralView({super.key});

  void _mostrarDialogoAdicionarXP(BuildContext context, FichaCubit cubit) async {
    final res = await showDialog<String>(
      context: context,
      builder: (ctx) => const CampoTextoDialog(
        titulo: 'Adicionar Experiência (XP)',
        label: 'Pontos de XP a somar',
        hint: 'Ex: 50',
        keyboardType: TextInputType.number,
        textoBotaoConfirmar: 'ADICIONAR',
        corBotaoConfirmar: Color(0xFFD32F2F),
      ),
    );

    if (res != null) {
      final valor = int.tryParse(res) ?? 0;
      if (valor > 0) {
        cubit.adicionarXP(valor);
      }
    }
  }

  void _mostrarDialogoPunicaoDivina(BuildContext context, FichaCubit cubit) async {
    final p = cubit.personagem;
    final sobPunicao = p.punicaoDivinaAtiva;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              sobPunicao ? Icons.verified : Icons.warning_amber_rounded,
              color: sobPunicao ? Colors.green[700] : const Color(0xFFD32F2F),
            ),
            const SizedBox(width: 8),
            Text(
              sobPunicao ? 'Remover Punição Divina' : 'Aplicar Punição Divina',
            ),
          ],
        ),
        content: Text(
          sobPunicao
              ? 'O personagem cumpriu a penitência exigida pela divindade ${p.divindade?.nome ?? ""}?\n\n'
                    'Ao confirmar, a punição será revogada, permitindo que o herói volte a recuperar Pontos de Mana normalmente e reative seus poderes concedidos.'
              : 'ATENÇÃO (Ação do Mestre):\n\n'
                    'O personagem cometeu uma violação grave de suas Obrigações e Restrições perante ${p.divindade?.nome ?? "sua divindade"}.\n\n'
                    'Efeitos mecânicos oficiais (T20 JDA):\n'
                    '• Todos os Pontos de Mana (PM) atuais são reduzidos a 0 imediatamente.\n'
                    '• A recuperação de PM fica bloqueada (descanso ou itens não recuperam PM).\n'
                    '• Todos os poderes concedidos são desativados até que a penitência seja cumprida.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: sobPunicao
                  ? Colors.green[700]
                  : const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(sobPunicao ? 'REVOGAR PUNIÇÃO' : 'APLICAR PUNIÇÃO'),
          ),
        ],
      ),
    );

    if (confirmar == true && context.mounted) {
      if (sobPunicao) {
        await cubit.removerPunicaoDivina();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Penitência aceita! Punição divina revogada.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await cubit.aplicarPunicaoDivina();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Punição divina aplicada! PM zerado e poderes concedidos inativos.',
            ),
            backgroundColor: Color(0xFFD32F2F),
          ),
        );
      }
    }
  }

  void _mostrarModalDescanso(BuildContext context, FichaCubit cubit) {
    final p = cubit.personagem;
    final con = p.getValorFinal('CON');
    final nivel = p.nivelPersonagem > 0 ? p.nivelPersonagem : 1;
    final curaNormalPV = max(1, nivel + con);
    final curaNormalPM = max(1, nivel);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: const [
                Icon(
                  Icons.nightlight_round,
                  color: Color(0xFF00ACC1),
                  size: 28,
                ),
                SizedBox(width: 10),
                Text(
                  'Descanso (Regras Tormenta 20)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.hotel, color: Colors.blueGrey),
              title: const Text('Descanso Normal'),
              subtitle: Text(
                'Recupera $curaNormalPV PV e $curaNormalPM PM (Nível + CON).',
              ),
              onTap: () {
                Navigator.pop(ctx);
                cubit.descansoNormal();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Descanso Normal! +$curaNormalPV PV, +$curaNormalPM PM.',
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.star, color: Colors.amber),
              title: const Text('Descanso Confortável'),
              subtitle: Text(
                'Recupera o dobro: ${curaNormalPV * 2} PV e ${curaNormalPM * 2} PM.',
              ),
              onTap: () {
                Navigator.pop(ctx);
                cubit.descansoConfortavel();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Descanso Confortável! +${curaNormalPV * 2} PV, +${curaNormalPM * 2} PM.',
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.healing, color: Colors.green),
              title: const Text('Descanso Completo / Restaurar Tudo'),
              subtitle: const Text('Restaura 100% dos Pontos de Vida e Mana.'),
              onTap: () {
                Navigator.pop(ctx);
                cubit.descansoCompleto();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Recursos totalmente restaurados!'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarModalAtributos(BuildContext context, FichaCubit cubit) {
    final p = cubit.personagem;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final atribs = [
          {'sigla': 'FOR', 'nome': 'Força'},
          {'sigla': 'DES', 'nome': 'Destreza'},
          {'sigla': 'CON', 'nome': 'Constituição'},
          {'sigla': 'INT', 'nome': 'Inteligência'},
          {'sigla': 'SAB', 'nome': 'Sabedoria'},
          {'sigla': 'CAR', 'nome': 'Carisma'},
        ];

        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.85,
          minChildSize: 0.4,
          expand: false,
          builder: (_, scrollController) => Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Atributos e Modificadores',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: atribs.length,
                  itemBuilder: (_, index) {
                    final a = atribs[index];
                    final sigla = a['sigla']!;
                    final mod = p.getValorFinal(sigla);
                    final sinal = mod >= 0 ? '+$mod' : '$mod';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFD32F2F),
                        child: Text(
                          sigla,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      title: Text(
                        a['nome']!,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              sinal,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(
                              Icons.casino,
                              color: Color(0xFFD32F2F),
                            ),
                            tooltip: 'Rolar Teste de ${a['nome']}',
                            onPressed: () {
                              mostrarDialogoRolagemDado(
                                context,
                                lados: 20,
                                mod: mod,
                                rotulo: 'Teste de ${a['nome']}',
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _mostrarModalRaca(BuildContext context, FichaCubit cubit) {
    final raca = cubit.personagem.raca;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.85,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Text(
                raca?.nome ?? 'Sem Raça Selecionada',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                raca?.descricaoRaca ?? 'Nenhuma informação disponível.',
                style: const TextStyle(color: Colors.black87),
              ),
              const Divider(height: 24),
              const Text(
                'Habilidades Raciais:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              if (raca != null && raca.habilidadesRaca.isNotEmpty)
                ...raca.habilidadesRaca.entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• ${e.key}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD32F2F),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          e.value,
                          style: const TextStyle(color: Colors.black87, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              else
                const Text(
                  'Nenhuma habilidade racial específica encontrada.',
                  style: TextStyle(color: Colors.grey),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarModalClasse(BuildContext context, FichaCubit cubit) {
    final p = cubit.personagem;
    if (p.classes.isEmpty) return;
    final cl = p.classes.first;
    final def = cl.classeDefinicao;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.85,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Text(
                '${def.nome} (Nível ${cl.nivel})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              if (cl.caminhoEscolhido != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Caminho: ${cl.caminhoEscolhido}',
                  style: const TextStyle(
                    color: Color(0xFFD32F2F),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                def.descricaoclasse,
                style: const TextStyle(color: Colors.black87),
              ),
              const Divider(height: 24),
              const Text(
                'Características de Classe:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text('• PV Inicial: ${def.pvInicial} + CON'),
              Text('• PV por Nível: ${def.pvPorNivel} + CON'),
              Text('• PM Inicial: ${def.pmInicial}'),
              Text('• PM por Nível: ${def.pmPorNivel}'),
            ],
          ),
        ),
      ),
    );
  }

  void _editarFisico(
    BuildContext context,
    FichaCubit cubit,
    String campo,
    String valorAtual,
    Function(String) onSalvar,
  ) async {
    final novo = await showDialog<String>(
      context: context,
      builder: (ctx) => CampoTextoDialog(
        titulo: 'Editar $campo',
        valorInicial: valorAtual,
        label: campo,
        hint: campo == 'Idade'
            ? 'Ex: 25'
            : campo == 'Peso'
            ? 'Ex: 75 kg'
            : 'Ex: 1.80 m',
        keyboardType: campo == 'Idade'
            ? TextInputType.number
            : TextInputType.text,
      ),
    );

    if (novo != null && novo.isNotEmpty) {
      onSalvar(novo);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<FichaCubit>();
    final p = cubit.state.personagem;
    const double xpMaximoNivel = 1000.0;
    final double progressoXP = (p.experienciaAtual / xpMaximoNivel).clamp(0.0, 1.0);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        // ALERTA DE PUNIÇÃO DIVINA ATIVA
        if (p.punicaoDivinaAtiva)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.shade400, width: 1.5),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_rounded,
                  color: Colors.red.shade900,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sob Punição Divina (${p.divindade?.nome ?? "Divindade"})',
                        style: TextStyle(
                          color: Colors.red.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'PM zerado e bloqueado. Poderes concedidos inativos até penitência.',
                        style: TextStyle(
                          color: Color(0xFFB71C1C),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _mostrarDialogoPunicaoDivina(context, cubit),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade900,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                  child: const Text(
                    'DETALHES',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

        // BARRA DE EXPERIÊNCIA ATUAL
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => _mostrarDialogoAdicionarXP(context, cubit),
              child: Text(
                'Experiência Atual ${p.experienciaAtual}/1000',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            InkWell(
              onTap: () => _mostrarDialogoAdicionarXP(context, cubit),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '+XP',
                  style: TextStyle(
                    color: Colors.brown,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progressoXP,
            minHeight: 10,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFB300)),
          ),
        ),

        const SizedBox(height: 18),

        // 3 CARDS RÁPIDOS (Atributos, Raça, Classe)
        Row(
          children: [
            Expanded(
              child: _buildCardAcaoRapida(
                icone: Icons.sports_kabaddi,
                titulo: 'Atributos e\nModificadores',
                onTap: () => _mostrarModalAtributos(context, cubit),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildCardAcaoRapida(
                icone: Icons.person_pin,
                titulo: 'Raça\n',
                onTap: () => _mostrarModalRaca(context, cubit),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildCardAcaoRapida(
                icone: Icons.shield_outlined,
                titulo: 'Classe\n',
                onTap: () => _mostrarModalClasse(context, cubit),
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // BOTÃO DESCANSAR
        Center(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF80DEEA),
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              elevation: 0,
            ),
            onPressed: () => _mostrarModalDescanso(context, cubit),
            icon: const Icon(Icons.nightlight_round, size: 20),
            label: const Text(
              'Descansar ?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ),

        const SizedBox(height: 22),

        // CARDS INFORMATIVOS FÍSICOS REAIS (Peso, Altura, Idade)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoFisica(
                icone: Icons.fitness_center_outlined,
                rotulo: 'Peso',
                valor: p.peso,
                onTap: () => _editarFisico(
                  context,
                  cubit,
                  'Peso',
                  p.peso,
                  (v) => cubit.atualizarPersonagem(p.copyWith(peso: v)),
                ),
              ),
              _buildInfoFisica(
                icone: Icons.straighten_outlined,
                rotulo: 'Altura',
                valor: p.altura,
                onTap: () => _editarFisico(
                  context,
                  cubit,
                  'Altura',
                  p.altura,
                  (v) => cubit.atualizarPersonagem(p.copyWith(altura: v)),
                ),
              ),
              _buildInfoFisica(
                icone: Icons.cake_outlined,
                rotulo: 'Idade',
                valor: '${p.idade} anos',
                onTap: () => _editarFisico(
                  context,
                  cubit,
                  'Idade',
                  p.idade.toString(),
                  (v) => cubit.atualizarPersonagem(
                    p.copyWith(idade: int.tryParse(v) ?? p.idade),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // CARD PREVIEW DO MODO DE COMBATE
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => mostrarDialogoRolagemDado(
            context,
            lados: 20,
            mod: p.getValorPericia('INICIATIVA'),
            rotulo: 'Rolagem de Iniciativa para Combate',
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFFB71C1C), Colors.red.shade900],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.grid_4x4_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Modo de Combate',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Toque para rolar iniciativa e preparar seu herói para o combate!',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white70,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardAcaoRapida({
    required IconData icone,
    required String titulo,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF80DEEA),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(child: Icon(icone, size: 30, color: Colors.black87)),
          ),
          const SizedBox(height: 6),
          Text(
            titulo,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoFisica({
    required IconData icone,
    required String rotulo,
    required String valor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            Icon(icone, size: 30, color: Colors.black87),
            const SizedBox(height: 4),
            Text(
              rotulo,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  valor,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
                const SizedBox(width: 3),
                const Icon(Icons.edit, size: 10, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
