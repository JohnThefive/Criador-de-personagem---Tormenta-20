import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/magia/magia.dart';
import '../../../domain/services/calculo_ficha_service.dart';
import '../../../domain/services/data_services/call_magias.dart';
import '../../controllers/ficha_cubit.dart';
import '../../controllers/ficha_state.dart';
import 'dialogos_ficha.dart';

class AbaMagiasView extends StatefulWidget {
  const AbaMagiasView({super.key});

  @override
  State<AbaMagiasView> createState() => _AbaMagiasViewState();
}

class _AbaMagiasViewState extends State<AbaMagiasView> {
  bool? _modoAmpliadoOverride;
  int _circuloFiltro = 0; // 0 = Todos, 1..5 = Círculo específico
  String _termoBusca = '';
  final TextEditingController _buscaCtrl = TextEditingController();

  @override
  void dispose() {
    _buscaCtrl.dispose();
    super.dispose();
  }

  Future<void> _editarBonusCD(
    BuildContext context,
    FichaCubit cubit,
    int atual,
  ) async {
    final res = await showDialog<String>(
      context: context,
      builder: (_) => CampoTextoDialog(
        titulo: 'Bônus "Outros" na CD de Magia',
        valorInicial: '$atual',
        label: 'Bônus de itens esotéricos, poderes ou parceiros',
        hint: 'Ex: 2',
        keyboardType: const TextInputType.numberWithOptions(signed: true),
      ),
    );
    if (res != null) {
      cubit.definirOutrosBonusCDMagia(int.tryParse(res) ?? 0);
    }
  }

  Future<void> _abrirCatalogoMagias(
    BuildContext context,
    FichaCubit cubit,
  ) async {
    final todas = BancoDeMagias.todas;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ModalCatalogoMagias(
        todasMagias: todas,
        conhecidasIds: cubit.personagem.magiasConhecidas,
        onAdicionar: (id) => cubit.adicionarMagiaConhecida(id),
      ),
    );
  }

  Future<void> _lancarMagia(
    BuildContext context,
    FichaCubit cubit,
    Magia magia,
    int custoFinal,
  ) async {
    final ok = await cubit.tentarAtivarComPM(custoFinal, nomeAcao: magia.nome);
    if (!context.mounted) return;
    final texto = ok
        ? (custoFinal == 0
              ? '✨ ${magia.nome} conjurada como Truque (0 PM)!'
              : '✨ ${magia.nome} conjurada (-$custoFinal PM)!')
        : (cubit.state.mensagemErro ?? 'PM insuficiente para conjurar!');

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: ok ? const Color(0xFF1D4ED8) : const Color(0xFFB91C1C),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FichaCubit, FichaState>(
      builder: (context, state) {
        final cubit = context.read<FichaCubit>();
        final p = state.personagem;

        final cdInfo = CalculoFichaService.detalharCDMagia(p);
        final modoAmpliado =
            _modoAmpliadoOverride ??
            (p.ehArcanista || p.magiasConhecidas.length >= 6);

        final todasConhecidas = p.magiasConhecidas
            .map((id) => BancoDeMagias.getById(id))
            .where((m) => m.id != 'UNKNOWN')
            .toList()
          ..sort((a, b) {
            final cmpCirc = a.circulo.compareTo(b.circulo);
            if (cmpCirc != 0) return cmpCirc;
            return a.nome.compareTo(b.nome);
          });

        final magiasFiltradas = todasConhecidas.where((m) {
          if (_circuloFiltro > 0 && m.circulo != _circuloFiltro) return false;
          if (_termoBusca.trim().isNotEmpty) {
            final q = _termoBusca.toLowerCase();
            return m.nome.toLowerCase().contains(q) ||
                m.escola.toLowerCase().contains(q);
          }
          return true;
        }).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
          children: [
            // 1. CONTA DE TESTE DE RESISTÊNCIA (CD) ESTILIZADA
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF312E81).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'CD MAGIA',
                              style: TextStyle(
                                color: Color(0xFFC7D2FE),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                              ),
                            ),
                            Text(
                              '${cdInfo.cdTotal}',
                              key: const Key('valor_cd_magia'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                height: 1.05,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Teste de Resistência',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              cdInfo.formulaFormatada,
                              style: const TextStyle(
                                color: Color(0xFFE0E7FF),
                                fontSize: 11.5,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Mana Atual: ${p.pmAtual} / ${p.pmTotal} PM',
                              style: const TextStyle(
                                color: Color(0xFF38BDF8),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () =>
                            _editarBonusCD(context, cubit, p.outrosBonusCDMagia),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minWidth: 44,
                            minHeight: 44,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                'Outros\n${p.outrosBonusCDMagia >= 0 ? "+${p.outrosBonusCDMagia}" : "${p.outrosBonusCDMagia}"}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 2. BARRA DE CONTROLE: VARIANTE GRIMÓRIO AMPLIADO + ADICIONAR MAGIA
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  key: const Key('toggle_grimorio_ampliado'),
                  selected: modoAmpliado,
                  selectedColor: const Color(0xFFE0E7FF),
                  checkmarkColor: const Color(0xFF3730A3),
                  label: Text(
                    p.ehArcanista ? 'Grimório Arcanista' : 'Área Ampliada',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  onSelected: (val) =>
                      setState(() => _modoAmpliadoOverride = val),
                ),
                ElevatedButton.icon(
                  key: const Key('btn_aprender_magia'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    backgroundColor: const Color(0xFFD32F2F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => _abrirCatalogoMagias(context, cubit),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text(
                    'Adicionar Magia',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),

            // Filtros rápidos de círculo e busca (sempre visíveis na variante ampliada ou se tiver >= 4 magias)
            if (modoAmpliado || todasConhecidas.length >= 4) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 44,
                child: TextField(
                  controller: _buscaCtrl,
                  onChanged: (v) => setState(() => _termoBusca = v),
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Filtrar magia ou escola...',
                    prefixIcon: const Icon(Icons.search, size: 19),
                    suffixIcon: _termoBusca.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _buscaCtrl.clear();
                              setState(() => _termoBusca = '');
                            },
                            icon: const Icon(Icons.clear, size: 18),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [0, 1, 2, 3, 4, 5].map((circ) {
                    final sel = _circuloFiltro == circ;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        selected: sel,
                        label: Text(circ == 0 ? 'Todos' : '$circº Círculo'),
                        onSelected: (_) =>
                            setState(() => _circuloFiltro = circ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            const SizedBox(height: 12),

            if (magiasFiltradas.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Text(
                  'Nenhuma magia registrada neste filtro. Use "Adicionar Magia" para preencher seu grimório.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
              )
            else
              ...magiasFiltradas.map(
                (magia) => _CardMagiaInterativo(
                  key: ValueKey('magia_card_${magia.id}'),
                  magia: magia,
                  cdTotal: cdInfo.cdTotal,
                  pmDisponivel: p.pmAtual,
                  sobPunicaoDivina: p.punicaoDivinaAtiva,
                  compactoAmpliado: modoAmpliado,
                  onLancar: (custo) =>
                      _lancarMagia(context, cubit, magia, custo),
                  onRemover: () => cubit.removerMagiaConhecida(magia.id),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CardMagiaInterativo extends StatefulWidget {
  final Magia magia;
  final int cdTotal;
  final int pmDisponivel;
  final bool sobPunicaoDivina;
  final bool compactoAmpliado;
  final ValueChanged<int> onLancar;
  final VoidCallback onRemover;

  const _CardMagiaInterativo({
    super.key,
    required this.magia,
    required this.cdTotal,
    required this.pmDisponivel,
    required this.sobPunicaoDivina,
    required this.compactoAmpliado,
    required this.onLancar,
    required this.onRemover,
  });

  @override
  State<_CardMagiaInterativo> createState() => _CardMagiaInterativoState();
}

class _CardMagiaInterativoState extends State<_CardMagiaInterativo> {
  final Set<String> _aprimoramentosIds = {};

  @override
  Widget build(BuildContext context) {
    final m = widget.magia;
    final selecionados = m.aprimoramentos
        .where((ap) => _aprimoramentosIds.contains(ap.id))
        .toList();
    final custoFinal = CalculoFichaService.calcularCustoMagia(m, selecionados);
    final podePagar =
        (!widget.sobPunicaoDivina || custoFinal == 0) &&
        widget.pmDisponivel >= custoFinal;

    return Card(
      margin: EdgeInsets.only(bottom: widget.compactoAmpliado ? 6 : 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: widget.compactoAmpliado ? 0 : 4,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${m.circulo}º',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1D4ED8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                m.nome,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: widget.compactoAmpliado ? 14 : 15,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
            // Gatilho rápido de Lançar / Ativar direto na linha!
            ElevatedButton(
              key: Key('btn_lancar_magia_${m.id}'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(76, 44),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                backgroundColor: podePagar
                    ? const Color(0xFF2563EB)
                    : const Color(0xFFE2E8F0),
                foregroundColor: podePagar
                    ? Colors.white
                    : const Color(0xFF64748B),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              onPressed: () => widget.onLancar(custoFinal),
              child: Text(
                custoFinal == 0 ? 'Truque' : 'Lançar (-$custoFinal PM)',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            '${m.escola.toUpperCase()} • ${m.execucao.detalhes ?? m.execucao.tipo} • Alcance: ${m.alcance.detalhes ?? m.alcance.tipo}${m.resistencia?.tipoTeste != null ? " • ${m.resistencia!.tipoTeste} (CD ${widget.cdTotal})" : ""}',
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
          ),
        ),
        children: [
          const Divider(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              Text(
                'Tipo: ${m.tipo.toUpperCase()}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Duração: ${m.duracao.detalhes ?? m.duracao.tipo}',
                style: const TextStyle(fontSize: 12),
              ),
              if (m.efeito.descricao != null)
                Text(
                  'Efeito: ${m.efeito.descricao}',
                  style: const TextStyle(fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            m.descricao,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Color(0xFF334155),
            ),
          ),
          if (m.aprimoramentos.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Aprimoramentos (marque para somar ao lançamento):',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
              ),
            ),
            const SizedBox(height: 4),
            ...m.aprimoramentos.map((ap) {
              final marcado = _aprimoramentosIds.contains(ap.id);
              return CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: marcado,
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      if (ap.isTruque) _aprimoramentosIds.clear();
                      _aprimoramentosIds.add(ap.id);
                    } else {
                      _aprimoramentosIds.remove(ap.id);
                    }
                  });
                },
                title: Text(
                  ap.isTruque
                      ? 'Truque (0 PM): ${ap.descricao}'
                      : '+${ap.custoAdicionalPM} PM: ${ap.descricao}',
                  style: const TextStyle(fontSize: 12),
                ),
              );
            }),
          ],
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: widget.onRemover,
              icon: const Icon(
                Icons.delete_outline,
                size: 17,
                color: Colors.red,
              ),
              label: const Text(
                'Remover do Grimório',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModalCatalogoMagias extends StatefulWidget {
  final List<Magia> todasMagias;
  final List<String> conhecidasIds;
  final ValueChanged<String> onAdicionar;

  const _ModalCatalogoMagias({
    required this.todasMagias,
    required this.conhecidasIds,
    required this.onAdicionar,
  });

  @override
  State<_ModalCatalogoMagias> createState() => _ModalCatalogoMagiasState();
}

class _ModalCatalogoMagiasState extends State<_ModalCatalogoMagias> {
  String _busca = '';
  int _circulo = 0;

  @override
  Widget build(BuildContext context) {
    final filtradas = widget.todasMagias.where((m) {
      if (_circulo > 0 && m.circulo != _circulo) return false;
      if (_busca.isNotEmpty &&
          !m.nome.toLowerCase().contains(_busca.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Catálogo de Magias (T20)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            TextField(
              onChanged: (v) => setState(() => _busca = v),
              decoration: const InputDecoration(
                hintText: 'Buscar magia por nome...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [0, 1, 2, 3, 4, 5].map((c) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      selected: _circulo == c,
                      label: Text(c == 0 ? 'Todos' : '$cº'),
                      onSelected: (_) => setState(() => _circulo = c),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                itemCount: filtradas.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, idx) {
                  final m = filtradas[idx];
                  final jaConhece = widget.conhecidasIds.contains(m.id);
                  return ListTile(
                    dense: true,
                    title: Text(
                      m.nome,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${m.circulo}º Círculo • ${m.tipo.toUpperCase()} • ${m.escola}',
                    ),
                    trailing: jaConhece
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(
                            Icons.add_circle_outline,
                            color: Color(0xFFD32F2F),
                          ),
                    onTap: jaConhece
                        ? null
                        : () {
                            widget.onAdicionar(m.id);
                            Navigator.pop(context);
                          },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
