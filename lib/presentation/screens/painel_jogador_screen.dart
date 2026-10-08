import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:t20_creator/domain/entities/classe_do_personagem.dart';
import '../../domain/entities/classe.dart';
import '../../domain/entities/personagem.dart';
import '../../domain/entities/divindade.dart';
import '../../domain/entities/companheiro_animal.dart';
import '../../domain/entities/montaria_sagrada.dart';
import '../../domain/services/data_services/call_formas_selvagens.dart';
import '../../domain/services/data_services/call_companheiros.dart';
import '../../domain/services/data_services/call_montaria_sagrada.dart';
import '../../domain/services/personagem_storage_service.dart';
import 'selecao_poderes_screen.dart';
import 'aba_combate_view.dart';
import '../widgets/modal_escolha_companheiro.dart';

class PainelJogadorScreen extends StatefulWidget {
  final Personagem personagemInicial;

  const PainelJogadorScreen({super.key, required this.personagemInicial});

  @override
  State<PainelJogadorScreen> createState() => _PainelJogadorScreenState();
}

class _PainelJogadorScreenState extends State<PainelJogadorScreen>
    with SingleTickerProviderStateMixin {
  late Personagem _personagem;
  late TabController _tabController;

  final List<Tab> _abas = const [
    Tab(icon: Icon(Icons.dashboard_outlined, size: 20), text: 'Geral'),
    Tab(icon: Icon(Icons.sports_kabaddi_rounded, size: 20), text: 'Combate'),
    Tab(icon: Icon(Icons.auto_awesome_outlined, size: 20), text: 'Habilidades'),
    Tab(icon: Icon(Icons.menu_book_outlined, size: 20), text: 'Magias'),
    Tab(icon: Icon(Icons.backpack_outlined, size: 20), text: 'Inventário'),
    Tab(icon: Icon(Icons.history_edu_outlined, size: 20), text: 'História'),
  ];

  @override
  void initState() {
    super.initState();
    _personagem = widget.personagemInicial;
    _tabController = TabController(length: _abas.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _atualizarPersonagem(Personagem novo) {
    setState(() {
      _personagem = novo;
    });
    PersonagemStorageService.salvarPersonagem(novo);
  }

  // --- CONTROLE SEGURO DE NÍVEL ---
  void _alterarNivel(int delta) {
    if (_personagem.classes.isEmpty) return;
    final cl = _personagem.classes[0];
    final novoNivel = cl.nivel + delta;

    if (novoNivel < 1) return;
    if (novoNivel > 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nível máximo atingido (Nível 20)!'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    final novaLista = List<ClasseDoPersonagem>.from(_personagem.classes)
      ..[0] = cl.copyWith(nivel: novoNivel);

    var atualizado = _personagem.copyWith(classe_do_personagem: novaLista);
    if (atualizado.pvAtual > atualizado.pvTotal) {
      atualizado = atualizado.copyWith(pvAtual: atualizado.pvTotal);
    }
    if (atualizado.pmAtual > atualizado.pmTotal) {
      atualizado = atualizado.copyWith(pmAtual: atualizado.pmTotal);
    }

    _atualizarPersonagem(atualizado);

    // Feedback visual quando sobe de nível e tem poderes de classe para escolher
    if (delta > 0 && atualizado.classes[0].temPoderPendente && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Subiu para o nível $novoNivel! Você tem poder de classe disponível.',
          ),
          backgroundColor: const Color(0xFF1E1E2C),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'ESCOLHER',
            textColor: Colors.amber,
            onPressed: () => _abrirSelecaoPoderes(),
          ),
        ),
      );
    }

    // Se liberou caminhos no nível atual (ex: Cavaleiro no nível 5) e ainda não escolheu
    final clAtual = atualizado.classes[0];
    final caminhosNivel = clAtual.classeDefinicao.caminhosParaNivel(novoNivel);
    if (delta > 0 &&
        clAtual.caminhoEscolhido == null &&
        caminhosNivel.isNotEmpty &&
        mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _mostrarModalEscolhaCaminho(clAtual, caminhosNivel);
        }
      });
    }
  }

  // --- NAVEGAÇÃO PARA SELEÇÃO DE PODERES DE CLASSE ---
  Future<void> _abrirSelecaoPoderes({int indiceClasse = 0}) async {
    if (_personagem.classes.isEmpty) return;
    final atualizado = await Navigator.push<Personagem>(
      context,
      MaterialPageRoute(
        builder: (_) => SelecaoPoderesScreen(
          personagem: _personagem,
          indiceClasse: indiceClasse,
        ),
      ),
    );
    if (atualizado != null && mounted) {
      _atualizarPersonagem(atualizado);
    }
  }

  Widget _buildBannerEvolucaoPendente() {
    final cl = _personagem.classes.firstWhere(
      (c) => c.temPoderPendente,
      orElse: () => _personagem.classes.first,
    );
    final pendentes = cl.poderesPendentes;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(12),
        elevation: 3,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _abrirSelecaoPoderes(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.stars_rounded, color: Colors.amber, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Evolução Disponível!',
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Você pode escolher $pendentes ${pendentes == 1 ? "poder" : "poderes"} em ${cl.classeDefinicao.nome}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Escolher',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- CONTROLE SEGURO DE FOTO ---
  Future<void> _abrirOpcoesFoto() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Retrato do Personagem',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: Color(0xFFD32F2F),
                ),
                title: const Text('Escolher da Galeria'),
                onTap: () {
                  Navigator.pop(ctx);
                  _processarImagem(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: Color(0xFFD32F2F),
                ),
                title: const Text('Tirar Nova Foto'),
                onTap: () {
                  Navigator.pop(ctx);
                  _processarImagem(ImageSource.camera);
                },
              ),
              if (_personagem.caminhoFoto != null &&
                  _personagem.caminhoFoto!.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text(
                    'Remover Foto Atual',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _atualizarPersonagem(
                      _personagem.copyWith(anularFoto: true),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processarImagem(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null && mounted) {
        _atualizarPersonagem(
          _personagem.copyWith(caminhoFoto: pickedFile.path),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto do herói atualizada com sucesso!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Não foi possível carregar a imagem: $e'),
            backgroundColor: Colors.black87,
          ),
        );
      }
    }
  }

  // --- DIÁLOGOS DE RECURSOS E EDIÇÕES (CICLO DE VIDA 100% SEGURO) ---
  Future<void> _mostrarDialogoAjustePV() async {
    final ajuste = await showDialog<int>(
      context: context,
      builder: (ctx) => _AjusteRecursoDialog(
        titulo: 'Ajustar Pontos de Vida (PV)',
        labelRecurso: 'Vida Atual',
        valorAtual: _personagem.pvAtual,
        valorTotal: _personagem.pvTotal,
        labelReducao: 'DANO (-)',
        corReducao: Colors.red.shade700,
        labelAumento: 'CURA (+)',
        corAumento: Colors.green.shade700,
      ),
    );

    if (ajuste != null && mounted) {
      if (ajuste < 0) {
        _atualizarPersonagem(_personagem.aplicarDano(-ajuste));
      } else if (ajuste > 0) {
        _atualizarPersonagem(_personagem.curarPV(ajuste));
      }
    }
  }

  Future<void> _mostrarDialogoAjustePM() async {
    final ajuste = await showDialog<int>(
      context: context,
      builder: (ctx) => _AjusteRecursoDialog(
        titulo: 'Ajustar Pontos de Mana (PM)',
        labelRecurso: 'Mana Atual',
        valorAtual: _personagem.pmAtual,
        valorTotal: _personagem.pmTotal,
        labelReducao: 'GASTAR (-)',
        corReducao: Colors.orange.shade800,
        labelAumento: 'RECUPERAR (+)',
        corAumento: Colors.blue.shade700,
      ),
    );

    if (ajuste != null && mounted) {
      if (_personagem.punicaoDivinaAtiva && ajuste > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'O personagem está sob Punição Divina e não pode recuperar Pontos de Mana!',
            ),
            backgroundColor: Color(0xFFB71C1C),
          ),
        );
        return;
      }
      if (ajuste < 0) {
        _atualizarPersonagem(_personagem.gastarPM(-ajuste));
      } else if (ajuste > 0) {
        _atualizarPersonagem(_personagem.recuperarPM(ajuste));
      }
    }
  }

  Future<void> _mostrarDialogoPunicaoDivina() async {
    final sobPunicao = _personagem.punicaoDivinaAtiva;
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
            Text(sobPunicao ? 'Remover Punição Divina' : 'Aplicar Punição Divina'),
          ],
        ),
        content: Text(
          sobPunicao
              ? 'O personagem cumpriu a penitência exigida pela divindade ${_personagem.divindade?.nome ?? ""}?\n\n'
                  'Ao confirmar, a punição será revogada, permitindo que o herói volte a recuperar Pontos de Mana normalmente e reative seus poderes concedidos.'
              : 'ATENÇÃO (Ação do Mestre):\n\n'
                  'O personagem cometeu uma violação grave de suas Obrigações e Restrições perante ${_personagem.divindade?.nome ?? "sua divindade"}.\n\n'
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
              backgroundColor: sobPunicao ? Colors.green[700] : const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(sobPunicao ? 'REVOGAR PUNIÇÃO' : 'APLICAR PUNIÇÃO'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      if (sobPunicao) {
        _atualizarPersonagem(_personagem.removerPunicaoDivina());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Penitência aceita! Punição divina revogada.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _atualizarPersonagem(_personagem.aplicarPunicaoDivina());
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

  Future<void> _mostrarDialogoAdicionarXP() async {
    final res = await showDialog<String>(
      context: context,
      builder: (ctx) => const _CampoTextoDialog(
        titulo: 'Adicionar Experiência (XP)',
        label: 'Pontos de XP a somar',
        hint: 'Ex: 50',
        keyboardType: TextInputType.number,
        textoBotaoConfirmar: 'ADICIONAR',
        corBotaoConfirmar: Color(0xFFD32F2F),
      ),
    );

    if (res != null && mounted) {
      final valor = int.tryParse(res) ?? 0;
      if (valor > 0) {
        _atualizarPersonagem(_personagem.adicionarXP(valor));
      }
    }
  }

  Future<void> _mostrarDialogoEditarFisico(
    String campo,
    String valorAtual,
    Function(String) onSalvar,
  ) async {
    final novo = await showDialog<String>(
      context: context,
      builder: (ctx) => _CampoTextoDialog(
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

    if (novo != null && novo.isNotEmpty && mounted) {
      onSalvar(novo);
    }
  }

  void _mostrarModalDescanso() {
    final con = _personagem.getValorFinal('CON');
    final nivel = _personagem.nivelPersonagem > 0
        ? _personagem.nivelPersonagem
        : 1;
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
                _atualizarPersonagem(
                  _personagem.curarPV(curaNormalPV).recuperarPM(curaNormalPM),
                );
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
                _atualizarPersonagem(
                  _personagem
                      .curarPV(curaNormalPV * 2)
                      .recuperarPM(curaNormalPM * 2),
                );
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
                _atualizarPersonagem(_personagem.restaurarRecursos());
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

  void _mostrarModalAtributos() {
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
                    final mod = _personagem.getValorFinal(sigla);
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
                              _rolarDadoComModificador(
                                20,
                                mod,
                                'Teste de ${a['nome']}',
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

  void _mostrarModalRaca() {
    final raca = _personagem.raca;
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
                          style: const TextStyle(fontSize: 13, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                )
              else
                const Text('Nenhuma habilidade racial especial.'),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarModalClasse() {
    final classeDoPersonagem = _personagem.classes.isNotEmpty
        ? _personagem.classes[0]
        : null;
    final classe = classeDoPersonagem?.classeDefinicao;
    final nivel = classeDoPersonagem?.nivel ?? 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      classe?.nome ?? 'Sem Classe Selecionada',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Color(0xFFD32F2F),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD32F2F),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Nível $nivel / 20',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                classe?.descricaoclasse ?? 'Nenhuma informação disponível.',
                style: const TextStyle(color: Colors.black87, height: 1.3),
              ),

              // Especialização / Caminho Escolhido
              if (classeDoPersonagem?.caminhoEscolhido != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Caminho: ${classeDoPersonagem!.caminhoEscolhido!.nome}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        classeDoPersonagem.caminhoEscolhido!.descricao,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Divider(height: 24),
              const Text(
                'Habilidades de Classe:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),

              if (classe != null && classe.habilidadesFixas.isNotEmpty)
                ...classe.habilidadesFixas.entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '• ${e.key}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD32F2F),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            e.value,
                            style: const TextStyle(fontSize: 13, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                const Text('Nenhuma habilidade de classe registrada.'),

              // Poderes Escolhidos de Classe
              if (classeDoPersonagem != null &&
                  classeDoPersonagem.poderesEscolhidos.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Poderes de Classe Escolhidos:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ...classeDoPersonagem.poderesEscolhidos.map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '⚡ ${p.nome}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFB71C1C),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            p.descricao,
                            style: const TextStyle(fontSize: 13, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              // Recursos e Progressão
              if (classe != null) ...[
                const Divider(height: 24),
                const Text(
                  'Recursos de Classe:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.favorite, color: Colors.green),
                  title: const Text(
                    'Pontos de Vida (PV)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${classe.pvInicial} PV + CON no 1º nível, e +${classe.pvPorNivel} + CON a cada novo nível.',
                  ),
                ),
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.bolt, color: Colors.blue),
                  title: const Text(
                    'Pontos de Mana (PM)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${classe.pmInicial} PM no 1º nível, e +${classe.pmPorNivel} PM a cada novo nível.',
                  ),
                ),
              ],

              // Botão para Gerenciar / Escolher Poderes de Classe
              if (classeDoPersonagem != null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E1E2C),
                      foregroundColor: Colors.amber,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Colors.amber, width: 1.2),
                      ),
                    ),
                    icon: const Icon(Icons.auto_awesome, color: Colors.amber),
                    label: Text(
                      classeDoPersonagem.temPoderPendente
                          ? 'Escolher Poder (${classeDoPersonagem.poderesPendentes} disponível)'
                          : 'Gerenciar Poderes de Classe',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _abrirSelecaoPoderes();
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarModalEscolhaCaminho(
    ClasseDoPersonagem classeDoPersonagem,
    List<CaminhoDeClasse> caminhos,
  ) {
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
                final selecionado =
                    classeDoPersonagem.caminhoEscolhido?.nome == cam.nome;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: selecionado ? Colors.red.shade50 : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: selecionado
                          ? const Color(0xFFD32F2F)
                          : Colors.grey.shade300,
                      width: selecionado ? 2 : 1,
                    ),
                  ),
                  child: ListTile(
                    leading: Icon(
                      selecionado
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: selecionado
                          ? const Color(0xFFD32F2F)
                          : Colors.grey,
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
                      final novasClasses = List<ClasseDoPersonagem>.from(
                        _personagem.classes,
                      );
                      final idx = _personagem.classes.indexOf(
                        classeDoPersonagem,
                      );
                      if (idx >= 0) {
                        novasClasses[idx] = clAtualizada;
                      } else {
                        novasClasses[0] = clAtualizada;
                      }
                      final novoP = _personagem.copyWith(
                        classe_do_personagem: novasClasses,
                      );
                      await PersonagemStorageService.salvarPersonagem(novoP);
                      setState(() {
                        _personagem = novoP;
                      });
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Caminho "${cam.nome}" escolhido com sucesso!',
                            ),
                            backgroundColor: const Color(0xFFD32F2F),
                          ),
                        );
                      }
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

  // --- ROLADOR DE DADOS ---
  void _rolarDadoComModificador(int lados, int mod, String rotulo) {
    final rand = Random();
    final resultadoDado = rand.nextInt(lados) + 1;
    final total = resultadoDado + mod;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          rotulo,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: resultadoDado == 20
                    ? Colors.amber.shade100
                    : resultadoDado == 1
                    ? Colors.red.shade100
                    : Colors.grey.shade100,
                border: Border.all(
                  color: resultadoDado == 20
                      ? Colors.amber
                      : resultadoDado == 1
                      ? Colors.red
                      : Colors.grey.shade300,
                  width: 3,
                ),
              ),
              child: Text(
                '$resultadoDado',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: resultadoDado == 20
                      ? Colors.amber.shade900
                      : resultadoDado == 1
                      ? Colors.red.shade900
                      : Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (mod != 0)
              Text(
                'Dado: $resultadoDado   Modificador: ${mod >= 0 ? "+$mod" : "$mod"}',
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
            const SizedBox(height: 6),
            Text(
              'Resultado Final: $total',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (lados == 20 && resultadoDado == 20)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  '🎉 20 NATURAL! SUCESSO CRÍTICO! 🎉',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (lados == 20 && resultadoDado == 1)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  '💀 1 NATURAL! FALHA CRÍTICA! 💀',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _abrirRoladorGeral() {
    final dados = [4, 6, 8, 10, 12, 20, 100];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Rolador de Dados (T20)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: dados.map((d) {
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: d == 20
                          ? const Color(0xFFD32F2F)
                          : Colors.grey.shade900,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: d == 20 ? Colors.redAccent : Colors.white24,
                        ),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _rolarDadoComModificador(d, 0, 'Rolagem d$d');
                    },
                    child: Text(
                      'd$d',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const t20Red = Color.fromARGB(255, 220, 20, 20);

    return Scaffold(
      backgroundColor: t20Red,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      _personagem.nome,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.casino_outlined,
                      color: Colors.white,
                    ),
                    tooltip: 'Rolador de Dados',
                    onPressed: _abrirRoladorGeral,
                  ),
                ],
              ),
            ),

            // CABEÇALHO FIXO NO TOPO (Avatar, Nível, Defesa, PV, PM)
            _buildCabecalhoFixo(),

            // BANNER DE EVOLUÇÃO PENDENTE (se houver poderes de classe para escolher)
            if (_personagem.classes.any((c) => c.temPoderPendente))
              _buildBannerEvolucaoPendente(),

            // CORPO BRANCO QUE OCUPA 100% DA LARGURA COM TABBAR SUPERIOR
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                ),
                child: Column(
                  children: [
                    // TabBar superior moderna e ergonômica
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(26),
                        ),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        tabAlignment: TabAlignment.center,
                        indicatorColor: const Color(0xFFD32F2F),
                        indicatorWeight: 3,
                        labelColor: const Color(0xFFD32F2F),
                        unselectedLabelColor: Colors.black54,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        tabs: _abas,
                      ),
                    ),

                    // PageView com as telas deslizando
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildTabGeral(),
                          AbaCombateView(
                            personagem: _personagem,
                            onPersonagemAtualizado: _atualizarPersonagem,
                          ),
                          _buildTabHabilidades(),
                          _buildTabMagia(),
                          _buildTabEquipamento(),
                          _buildTabHistoria(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Bottom Bar com D20 centralizado
      bottomNavigationBar: BottomAppBar(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        shape: const CircularNotchedRectangle(),
        color: Colors.black,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              tooltip: 'Configurações',
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.person, color: Colors.white),
              tooltip: 'Perfil',
              onPressed: () {
                _tabController.animateTo(0);
              },
            ),
            const SizedBox(width: 44), // Espaço pro FAB central
            IconButton(
              icon: const Icon(Icons.history_edu, color: Colors.white),
              tooltip: 'História / Notas',
              onPressed: () {
                _tabController.animateTo(5);
              },
            ),
            IconButton(
              icon: const Icon(Icons.backpack, color: Colors.white),
              tooltip: 'Inventário',
              onPressed: () {
                _tabController.animateTo(4);
              },
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: _abrirRoladorGeral,
        child: const Icon(Icons.casino, color: Color(0xFFD32F2F), size: 30),
      ),
    );
  }

  // --- CABEÇALHO FIXO DO HERÓI (Sempre visível no topo) ---
  Widget _buildCabecalhoFixo() {
    final temFoto =
        _personagem.caminhoFoto != null &&
        _personagem.caminhoFoto!.isNotEmpty &&
        File(_personagem.caminhoFoto!).existsSync();

    final classeNome = _personagem.classes.isNotEmpty
        ? _personagem.classes[0].classeDefinicao.nome
        : 'Sem Classe';
    final racaNome = _personagem.raca?.nome ?? 'Sem Raça';
    final nivel = _personagem.nivelPersonagem > 0
        ? _personagem.nivelPersonagem
        : 1;
    final modIniciativa = _personagem.getValorPericia('INICIATIVA');
    final bonusTreino = _personagem.bonusTreinamento;

    final double progressoPV = _personagem.pvTotal > 0
        ? (_personagem.pvAtual / _personagem.pvTotal).clamp(0.0, 1.0)
        : 1.0;
    final double progressoPM = _personagem.pmTotal > 0
        ? (_personagem.pmAtual / _personagem.pmTotal).clamp(0.0, 1.0)
        : 1.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar com edição segura
              Stack(
                children: [
                  GestureDetector(
                    onTap: _abrirOpcoesFoto,
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 4),
                        ],
                      ),
                      child: ClipOval(
                        child: temFoto
                            ? Image.file(
                                File(_personagem.caminhoFoto!),
                                fit: BoxFit.cover,
                                width: 68,
                                height: 68,
                                cacheWidth: 200,
                                cacheHeight: 200,
                                errorBuilder: (ctx, err, stack) => const Icon(
                                  Icons.account_circle,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                              )
                            : const Icon(
                                Icons.account_circle,
                                size: 64,
                                color: Colors.grey,
                              ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: _abrirOpcoesFoto,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black38, blurRadius: 3),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 13,
                          color: Color(0xFFD32F2F),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),

              // Identidade e Estatísticas Principais (Flexível sem Overflows)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Nível com botões de incremento
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Nível: ',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            InkWell(
                              onTap: () => _alterarNivel(-1),
                              child: const Icon(
                                Icons.arrow_drop_down,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            Text(
                              '$nivel',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            InkWell(
                              onTap: () => _alterarNivel(1),
                              child: const Icon(
                                Icons.arrow_drop_up,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ],
                        ),
                        Flexible(
                          child: Text(
                            'PV Máx: ${_personagem.pvTotal}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Def: ${_personagem.defesaBase}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$racaNome • $classeNome',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        InkWell(
                          onTap: () => _rolarDadoComModificador(
                            20,
                            modIniciativa,
                            'Iniciativa',
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.casino,
                                  size: 14,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Iniciativa ${modIniciativa >= 0 ? "+$modIniciativa" : "$modIniciativa"}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.shield,
                                size: 14,
                                color: Colors.lightBlueAccent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Treino +$bonusTreino',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // BARRAS DE PV E PM FIXAS
          Row(
            children: [
              // Barra de Vida (PV)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: GestureDetector(
                            onTap: _mostrarDialogoAjustePV,
                            child: Text(
                              'PV ${_personagem.pvAtual}/${_personagem.pvTotal}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () => _atualizarPersonagem(
                                _personagem.aplicarDano(1),
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black38,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: const Text(
                                  '-1',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 3),
                            InkWell(
                              onTap: () =>
                                  _atualizarPersonagem(_personagem.curarPV(1)),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black38,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: const Text(
                                  '+1',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progressoPV,
                        minHeight: 8,
                        backgroundColor: Colors.black26,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progressoPV > 0.3
                              ? const Color(0xFF4CAF50)
                              : Colors.amberAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 14),

              // Barra de Mana (PM)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: GestureDetector(
                            onTap: _mostrarDialogoAjustePM,
                            child: Text(
                              'PM ${_personagem.pmAtual}/${_personagem.pmTotal}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () =>
                                  _atualizarPersonagem(_personagem.gastarPM(1)),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black38,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: const Text(
                                  '-1',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 3),
                            InkWell(
                              onTap: () => _atualizarPersonagem(
                                _personagem.recuperarPM(1),
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black38,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: const Text(
                                  '+1',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progressoPM,
                        minHeight: 8,
                        backgroundColor: Colors.black26,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF29B6F6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- ABA 1: GERAL (Miolo Principal) ---
  Widget _buildTabGeral() {
    const double xpMaximoNivel = 1000.0;
    final double progressoXP = (_personagem.experienciaAtual / xpMaximoNivel)
        .clamp(0.0, 1.0);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        // ALERTA DE PUNIÇÃO DIVINA ATIVA
        if (_personagem.punicaoDivinaAtiva)
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
                Icon(Icons.warning_rounded, color: Colors.red.shade900, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sob Punição Divina (${_personagem.divindade?.nome ?? "Divindade"})',
                        style: TextStyle(
                          color: Colors.red.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'PM zerado e bloqueado. Poderes concedidos inativos até penitência.',
                        style: TextStyle(
                          color: const Color(0xFFB71C1C),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _mostrarDialogoPunicaoDivina,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade900,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                  child: const Text('DETALHES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

        // BARRA DE EXPERIÊNCIA ATUAL
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: _mostrarDialogoAdicionarXP,
              child: Text(
                'Experiência Atual ${_personagem.experienciaAtual}/1000',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            InkWell(
              onTap: _mostrarDialogoAdicionarXP,
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

        // BANNER DA FORMA SELVAGEM SE TRANSFORMADO
        if (_personagem.estaEmFormaSelvagem) ...[
          const SizedBox(height: 12),
          _buildBannerFormaSelvagemAtiva(),
        ],

        // BANNER DA MONTARIA SAGRADA SE ATIVA
        if (_personagem.montariaSagradaAtiva) ...[
          const SizedBox(height: 12),
          _buildBannerMontariaSagradaAtiva(),
        ],

        const SizedBox(height: 18),

        // 3 CARDS RÁPIDOS 100% RESPONSIVOS (Atributos, Raça, Classe)
        Row(
          children: [
            Expanded(
              child: _buildCardAcaoRapida(
                icone: Icons.sports_kabaddi,
                titulo: 'Atributos e\nModificadores',
                onTap: _mostrarModalAtributos,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildCardAcaoRapida(
                icone: Icons.person_pin,
                titulo: 'Raça\n',
                onTap: _mostrarModalRaca,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildCardAcaoRapida(
                icone: Icons.shield_outlined,
                titulo: 'Classe\n',
                onTap: _mostrarModalClasse,
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
            onPressed: _mostrarModalDescanso,
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
                valor: _personagem.peso,
                onTap: () => _mostrarDialogoEditarFisico(
                  'Peso',
                  _personagem.peso,
                  (v) => _atualizarPersonagem(_personagem.copyWith(peso: v)),
                ),
              ),
              _buildInfoFisica(
                icone: Icons.straighten_outlined,
                rotulo: 'Altura',
                valor: _personagem.altura,
                onTap: () => _mostrarDialogoEditarFisico(
                  'Altura',
                  _personagem.altura,
                  (v) => _atualizarPersonagem(_personagem.copyWith(altura: v)),
                ),
              ),
              _buildInfoFisica(
                icone: Icons.cake_outlined,
                rotulo: 'Idade',
                valor: '${_personagem.idade} anos',
                onTap: () => _mostrarDialogoEditarFisico(
                  'Idade',
                  _personagem.idade.toString(),
                  (v) => _atualizarPersonagem(
                    _personagem.copyWith(
                      idade: int.tryParse(v) ?? _personagem.idade,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // CARD PREVIEW DO MODO DE COMBATE 2D
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _rolarDadoComModificador(
            20,
            _personagem.getValorPericia('INICIATIVA'),
            'Rolagem de Iniciativa para Combate',
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
                        'Modo de Combate (Em Breve)',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Toque para rolar iniciativa e preparar seu herói para o grid tático!',
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

  // --- DEMAIS ABAS ---
  Widget _buildTabHabilidades() {
    final classeDoPersonagem = _personagem.classes.isNotEmpty
        ? _personagem.classes[0]
        : null;
    final classe = classeDoPersonagem?.classeDefinicao;
    final nivel = classeDoPersonagem?.nivel ?? 1;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // CLASSE (Habilidades e Poderes)
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
                        icon: const Icon(
                          Icons.edit,
                          size: 18,
                          color: Colors.brown,
                        ),
                        tooltip: 'Alterar caminho',
                        onPressed: () => _mostrarModalEscolhaCaminho(
                          classeDoPersonagem,
                          classe.caminhosParaNivel(nivel),
                        ),
                      )
                    : null,
              ),
            ),
          ] else if (classeDoPersonagem != null &&
              classe.caminhosParaNivel(nivel).isNotEmpty) ...[
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD32F2F),
                  ),
                ),
                subtitle: const Text('Toque para escolher seu caminho!'),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Color(0xFFD32F2F),
                ),
                onTap: () => _mostrarModalEscolhaCaminho(
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
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD32F2F),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(e.value, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
          // SEÇÃO DE PODERES ESPECIAIS DE DRUIDA (Forma Selvagem e Companheiro Animal)
          if (_personagem.temPoderFormaSelvagem) ...[
            _buildCardFormaSelvagem(),
          ],
          if (_personagem.temPoderCompanheiroAnimal) ...[
            _buildCardCompanheiroAnimal(),
          ],
          // SEÇÃO DE MONTARIA SAGRADA (PALADINO)
          if (_personagem.temMontariaSagrada) ...[
            _buildCardMontariaSagrada(),
          ],
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
                  onPressed: () => _abrirSelecaoPoderes(),
                  icon: Icon(
                    classeDoPersonagem.temPoderPendente
                        ? Icons.add_circle
                        : Icons.tune,
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
                      ? const Icon(
                          Icons.chevron_right,
                          color: Color(0xFFD32F2F),
                        )
                      : null,
                  onTap: () => _abrirSelecaoPoderes(),
                ),
              )
            else
              ...classeDoPersonagem.poderesEscolhidos.map(
                (p) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.bolt, color: Color(0xFFD32F2F)),
                    title: Text(
                      p.nome,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(p.descricao),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.settings,
                        color: Colors.grey,
                        size: 20,
                      ),
                      tooltip: 'Gerenciar poderes',
                      onPressed: () => _abrirSelecaoPoderes(),
                    ),
                  ),
                ),
              ),
            const Divider(height: 24),
          ],
        ],

        // Raça
        if (_personagem.raca != null) ...[
          Text(
            'Raça: ${_personagem.raca!.nome}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFFD32F2F),
            ),
          ),
          const SizedBox(height: 6),
          ..._personagem.raca!.habilidadesRaca.entries.map(
            (e) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.key,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(e.value, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 24),
        ],

        // Divindade e Devoção
        if (_personagem.divindade != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _personagem.punicaoDivinaAtiva
                    ? Colors.red.shade700
                    : Colors.red.shade200,
                width: _personagem.punicaoDivinaAtiva ? 2 : 1,
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
                            _personagem.divindade!.nome,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Color(0xFFD32F2F),
                            ),
                          ),
                          Text(
                            _personagem.divindade!.titulo,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_personagem.ehDevotoFiel)
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
                      label: Text(
                        'Arma: ${_personagem.divindade!.armaPreferida}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    if (_personagem.canalizacaoEnergia != null)
                      Chip(
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                        backgroundColor: _personagem.canalizacaoEnergia == TipoEnergia.positiva
                            ? Colors.green.shade50
                            : Colors.purple.shade50,
                        avatar: Icon(
                          _personagem.canalizacaoEnergia == TipoEnergia.positiva
                              ? Icons.favorite
                              : Icons.dark_mode,
                          size: 14,
                          color: _personagem.canalizacaoEnergia == TipoEnergia.positiva
                              ? Colors.green.shade700
                              : Colors.purple.shade700,
                        ),
                        label: Text(
                          'Energia ${_personagem.canalizacaoEnergia == TipoEnergia.positiva ? "Positiva" : "Negativa"}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _personagem.canalizacaoEnergia == TipoEnergia.positiva
                                ? Colors.green.shade900
                                : Colors.purple.shade900,
                          ),
                        ),
                      ),
                  ],
                ),

                // Alerta de Punição Divina Ativa
                if (_personagem.punicaoDivinaAtiva) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade400, width: 1.5),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_rounded, color: Colors.red.shade900, size: 24),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SOB PUNIÇÃO DIVINA DO MESTRE',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade900,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'O herói violou as obrigações sagradas. Seus PM atuais foram reduzidos a 0, '
                                'a recuperação de PM está bloqueada e todos os poderes concedidos estão desativados '
                                'até que uma penitência seja cumprida.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: const Color(0xFFB71C1C),
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                // Botão de Gestão da Punição Divina (Mestre)
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _personagem.punicaoDivinaAtiva
                          ? Colors.green.shade700
                          : Colors.red.shade800,
                      side: BorderSide(
                        color: _personagem.punicaoDivinaAtiva
                            ? Colors.green.shade700
                            : Colors.red.shade300,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    onPressed: _mostrarDialogoPunicaoDivina,
                    icon: Icon(
                      _personagem.punicaoDivinaAtiva
                          ? Icons.verified
                          : Icons.gavel,
                      size: 16,
                    ),
                    label: Text(
                      _personagem.punicaoDivinaAtiva
                          ? 'Penitência Cumprida (Revogar)'
                          : 'Aplicar Punição Divina',
                    ),
                  ),
                ),

                const Divider(height: 20),
                const Text(
                  'Obrigações & Restrições:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                ..._personagem.divindade!.obrigacoesERestricoes.map(
                  (regra) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• $regra',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade800,
                        height: 1.25,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),
          const Text(
            'Poderes Concedidos:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),

          if (_personagem.poderesConcedidos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'Nenhum poder concedido associado.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            )
          else
            ..._personagem.poderesConcedidos.map(
              (p) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: _personagem.punicaoDivinaAtiva
                        ? Colors.red.shade300
                        : Colors.grey.shade300,
                  ),
                ),
                color: _personagem.punicaoDivinaAtiva
                    ? Colors.red.shade50.withValues(alpha: 0.5)
                    : Colors.white,
                child: ListTile(
                  dense: true,
                  leading: Icon(
                    _personagem.punicaoDivinaAtiva
                        ? Icons.block
                        : Icons.auto_awesome,
                    color: _personagem.punicaoDivinaAtiva
                        ? Colors.red.shade800
                        : Colors.amber.shade800,
                    size: 22,
                  ),
                  title: Row(
                    children: [
                      Text(
                        p.nome,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _personagem.punicaoDivinaAtiva
                              ? Colors.red.shade900
                              : Colors.black87,
                          decoration: _personagem.punicaoDivinaAtiva
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      if (_personagem.punicaoDivinaAtiva) ...[
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
                    p.descricao,
                    style: TextStyle(
                      fontSize: 12,
                      color: _personagem.punicaoDivinaAtiva
                          ? Colors.grey.shade600
                          : Colors.grey.shade800,
                    ),
                  ),
                ),
              ),
            ),
          const Divider(height: 24),
        ],

        // Origem
        if (_personagem.origem != null) ...[
          Text(
            'Origem: ${_personagem.origem!.nome}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFFD32F2F),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _personagem.origem!.descricao,
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 8),
          if (_personagem.poderesGerais.isNotEmpty)
            ..._personagem.poderesGerais.map(
              (p) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(
                    p.nome,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(p.descricao),
                ),
              ),
            ),
        ],
      ],
    );
  }

  // --- SEÇÃO DE FORMA SELVAGEM E COMPANHEIRO ANIMAL DO DRUIDA ---

  Widget _buildBannerFormaSelvagemAtiva() {
    final forma = _personagem.formaSelvagemAtiva!;
    final modsTexto = forma.modificadores.entries
        .map((e) => '+${e.value} ${e.key}')
        .join(', ');

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
            'Bônus ativos: $modsTexto'
            '${forma.rd > 0 ? " | RD ${forma.rd}" : ""}'
            '${forma.tamanho != null ? " | Tamanho ${forma.tamanho}" : ""}',
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
                _atualizarPersonagem(_personagem.reverterFormaSelvagem());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Você reverteu à sua forma normal.'),
                  ),
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

  Widget _buildCardFormaSelvagem() {
    final estaTransformado = _personagem.estaEmFormaSelvagem;

    if (estaTransformado) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _buildBannerFormaSelvagemAtiva(),
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
                  'Druida Nv. ${_personagem.nivelDruida}',
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
                onPressed: _mostrarModalAssumirFormaSelvagem,
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

  void _mostrarModalAssumirFormaSelvagem() {
    final nivelDruida = _personagem.nivelDruida;
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
                      'Seu PM: ${_personagem.pmAtual}/${_personagem.pmTotal}',
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
                      final temPm = _personagem.pmAtual >= nivelForma.custoPm;

                      final modsTexto = nivelForma.modificadores.entries
                          .map((e) => '+${e.value} ${e.key}')
                          .join(', ');

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.grey.shade300,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.pets,
                                    color: Color(0xFF33691E),
                                    size: 20,
                                  ),
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
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
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black87,
                                ),
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
                                        'Armas Naturais: ${nivelForma.armasNaturais.map((a) => '${a.tipo == 'duas_armas' ? '2x ' : ''}${a.dano} (${a.critico})').join(', ')}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    if (nivelForma.tamanho != null)
                                      Text(
                                        'Tamanho: ${nivelForma.tamanho}'
                                        '${nivelForma.deslocamento != null ? ' | Deslocamento: ${nivelForma.deslocamento}' : ''}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.black54,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: temPm
                                        ? const Color(0xFF2E7D32)
                                        : Colors.grey.shade400,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: temPm
                                      ? () {
                                          Navigator.pop(ctx);
                                          _atualizarPersonagem(
                                            _personagem.assumirFormaSelvagem(forma),
                                          );
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Você assumiu a ${forma.nome}!',
                                              ),
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

  Widget _buildCardCompanheiroAnimal() {
    final tipoKey = _personagem.tipoCompanheiroAnimal;
    final comp = tipoKey != null ? BancoDeCompanheiros.getByKey(tipoKey) : null;
    final nivelDruida = _personagem.nivelDruida;

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
                    comp != null
                        ? 'Companheiro Animal: ${comp.nome}'
                        : 'Companheiro Animal',
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
              Text(
                comp.descricao,
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
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
                  onPressed: _mostrarModalEscolhaCompanheiroPainel,
                  child: const Text('Escolher Tipo de Companheiro'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _mostrarModalEscolhaCompanheiroPainel() {
    mostrarModalEscolhaCompanheiro(
      context: context,
      nivelDruida: _personagem.nivelDruida,
      onSelecionado: (comp) {
        _atualizarPersonagem(
          _personagem.copyWith(tipoCompanheiroAnimal: comp.key),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Companheiro "${comp.nome}" selecionado!'),
          ),
        );
      },
    );
  }

  // --- SEÇÃO DE MONTARIA SAGRADA DO PALADINO ---

  Widget _buildBannerMontariaSagradaAtiva() {
    final montaria = _personagem.montariaSagrada ??
        MontariaSagrada(
          nomeCustomizado: BancoDeRegrasMontariaSagrada.animalPadraoParaTamanho(_personagem.tamanho),
          especie: BancoDeRegrasMontariaSagrada.animalPadraoParaTamanho(_personagem.tamanho),
        );
    final tier = _personagem.tierMontariaSagrada;
    final deslocamento = _personagem.deslocamentoMontadoMetros;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF4E342E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFB300), width: 1.5),
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
              const Icon(Icons.pets, color: Color(0xFFFFD54F), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Montaria Sagrada Ativa: ${montaria.nomeCustomizado}',
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
                  color: const Color(0xFFFFB300),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tier.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.brown,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Deslocamento: ${deslocamento}m | ${montaria.especie} (${montaria.isVarianteMundana ? "Variante Mundana" : "Invocada"})',
            style: const TextStyle(color: Color(0xFFFFF8E1), fontSize: 12),
          ),
          if (!montaria.isVarianteMundana) ...[
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
                  _atualizarPersonagem(_personagem.dispensarMontariaSagrada());
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Montaria sagrada dispensada.')),
                  );
                },
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Dispensar Montaria', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCardMontariaSagrada() {
    final montaria = _personagem.montariaSagrada ??
        MontariaSagrada(
          nomeCustomizado: BancoDeRegrasMontariaSagrada.animalPadraoParaTamanho(_personagem.tamanho),
          especie: BancoDeRegrasMontariaSagrada.animalPadraoParaTamanho(_personagem.tamanho),
        );
    final tier = _personagem.tierMontariaSagrada;
    final deslocamento = _personagem.deslocamentoMontadoMetros;
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
                  onPressed: () => _mostrarDialogoEditarMontaria(montaria),
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

            // Invocação e estado
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
                      montaria.invocada
                          ? 'Status: Invocada na Cena (Ativa)'
                          : 'Status: Em Repouso / Dispensada',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: montaria.invocada
                            ? Colors.green.shade800
                            : Colors.grey.shade700,
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
                        _atualizarPersonagem(_personagem.dispensarMontariaSagrada());
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
                        if (_personagem.pmAtual < custo) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('PM insuficiente para invocar a montaria sagrada (custa 2 PM).'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        _atualizarPersonagem(_personagem.invocarMontariaSagrada());
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

            // Switch Variante Mundana
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
                _atualizarPersonagem(
                  _personagem.alternarVarianteMundanaMontaria(val),
                );
              },
            ),

            // Propriedades e Regras
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
                        const Text('• ', style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Text(
                            prop,
                            style: const TextStyle(fontSize: 11, color: Colors.black87),
                          ),
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

  void _mostrarDialogoEditarMontaria(MontariaSagrada montariaAtual) {
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
              _atualizarPersonagem(
                _personagem.atualizarMontariaSagrada(
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
    );
  }

  Widget _buildTabMagia() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Grimório / Magias',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Chip(
              backgroundColor: Colors.blue.shade100,
              label: Text(
                'PM: ${_personagem.pmAtual}/${_personagem.pmTotal}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Text(
            'Seu herói pode conjurar magias gastando Pontos de Mana (PM). Magias de 1º Círculo custam tipicamente 1 PM.',
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
        ),
        const SizedBox(height: 24),
        const Center(
          child: Text(
            'Nenhuma magia personalizada vinculada.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildTabEquipamento() {
    final itens = _personagem.itensInventario;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Mochila & Equipamentos',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle, color: Color(0xFFD32F2F)),
              tooltip: 'Adicionar Item',
              onPressed: () async {
                final texto = await showDialog<String>(
                  context: context,
                  builder: (ctx) => const _CampoTextoDialog(
                    titulo: 'Adicionar Item',
                    label: 'Nome do item',
                    hint: 'Ex: Poção de Cura, Corda...',
                    textoBotaoConfirmar: 'ADICIONAR',
                    corBotaoConfirmar: Color(0xFFD32F2F),
                  ),
                );

                if (texto != null && texto.isNotEmpty && mounted) {
                  final novaLista = List<String>.from(itens)..add(texto);
                  _atualizarPersonagem(
                    _personagem.copyWith(itensInventario: novaLista),
                  );
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (itens.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text(
                'Mochila vazia.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ...itens.map(
            (item) => Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                dense: true,
                leading: const Icon(
                  Icons.inventory_2_outlined,
                  color: Colors.brown,
                ),
                title: Text(
                  item,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    final novaLista = List<String>.from(itens)..remove(item);
                    _atualizarPersonagem(
                      _personagem.copyWith(itensInventario: novaLista),
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTabHistoria() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'História & Personalidade',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 16),
        ListTile(
          dense: true,
          title: const Text(
            'Alinhamento',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(_personagem.alinhamento),
        ),
        ListTile(
          dense: true,
          title: const Text(
            'Tamanho',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(_personagem.tamanho),
        ),
        ListTile(
          dense: true,
          title: const Text(
            'Idade',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text('${_personagem.idade} anos'),
        ),
        ListTile(
          dense: true,
          title: const Text(
            'Peso e Altura',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text('${_personagem.peso} • ${_personagem.altura}'),
        ),
        const Divider(height: 24),
        const Text(
          'Aparência e Biografia:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            _personagem.descricaoAparencia.isNotEmpty
                ? _personagem.descricaoAparencia
                : 'Nenhuma descrição fornecida para este aventureiro.',
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
        ),
      ],
    );
  }
}

/// Diálogo com ciclo de vida seguro para entrada de texto
class _CampoTextoDialog extends StatefulWidget {
  final String titulo;
  final String valorInicial;
  final String? label;
  final String? hint;
  final TextInputType keyboardType;
  final String textoBotaoConfirmar;
  final Color corBotaoConfirmar;

  const _CampoTextoDialog({
    required this.titulo,
    this.valorInicial = '',
    this.label,
    this.hint,
    this.keyboardType = TextInputType.text,
    this.textoBotaoConfirmar = 'SALVAR',
    this.corBotaoConfirmar = const Color(0xFFD32F2F),
  });

  @override
  State<_CampoTextoDialog> createState() => _CampoTextoDialogState();
}

class _CampoTextoDialogState extends State<_CampoTextoDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.valorInicial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirmar() {
    final texto = _controller.text.trim();
    Navigator.of(context).pop(texto.isNotEmpty ? texto : null);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titulo),
      content: TextField(
        controller: _controller,
        keyboardType: widget.keyboardType,
        autofocus: true,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (_) => _confirmar(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('CANCELAR'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.corBotaoConfirmar,
          ),
          onPressed: _confirmar,
          child: Text(
            widget.textoBotaoConfirmar,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

/// Diálogo com ciclo de vida seguro para ajuste de recursos (PV / PM)
class _AjusteRecursoDialog extends StatefulWidget {
  final String titulo;
  final String labelRecurso;
  final int valorAtual;
  final int valorTotal;
  final String labelReducao;
  final Color corReducao;
  final String labelAumento;
  final Color corAumento;

  const _AjusteRecursoDialog({
    required this.titulo,
    required this.labelRecurso,
    required this.valorAtual,
    required this.valorTotal,
    required this.labelReducao,
    required this.corReducao,
    required this.labelAumento,
    required this.corAumento,
  });

  @override
  State<_AjusteRecursoDialog> createState() => _AjusteRecursoDialogState();
}

class _AjusteRecursoDialogState extends State<_AjusteRecursoDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _aplicar(bool ehAumento) {
    final valor = int.tryParse(_controller.text) ?? 0;
    if (valor <= 0) {
      Navigator.of(context).pop(null);
      return;
    }
    Navigator.of(context).pop(ehAumento ? valor : -valor);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titulo),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${widget.labelRecurso}: ${widget.valorAtual} / ${widget.valorTotal}',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Quantidade',
              hintText: 'Ex: 5',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _aplicar(true),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('CANCELAR'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: widget.corReducao),
          onPressed: () => _aplicar(false),
          child: Text(
            widget.labelReducao,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: widget.corAumento),
          onPressed: () => _aplicar(true),
          child: Text(
            widget.labelAumento,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
