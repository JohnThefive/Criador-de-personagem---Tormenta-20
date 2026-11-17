import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/entities/entidade_sessao_lan/sessao_lan_modelos.dart';
import '../../../controllers/ficha_controller/ficha_cubit.dart';
import '../../../controllers/ficha_controller/ficha_state.dart';
import '../../../controllers/ficha_controller/sessao_jogador_cubit.dart';
import '../../../controllers/ficha_controller/sessao_jogador_state.dart';
import 'mapa_jogador_screen.dart';

/// Aba "Sessão" da Ficha do Personagem para conexão à mesa LAN do Mestre.
class AbaSessaoView extends StatefulWidget {
  final VoidCallback? onAbrirMapa;

  const AbaSessaoView({super.key, this.onAbrirMapa});

  @override
  State<AbaSessaoView> createState() => _AbaSessaoViewState();
}

class _AbaSessaoViewState extends State<AbaSessaoView> {
  late final TextEditingController _codigoCtrl;
  late final TextEditingController _nomeCtrl;
  late final TextEditingController _hostCtrl;

  @override
  void initState() {
    super.initState();
    final s = context.read<SessaoJogadorCubit>().state;
    _codigoCtrl = TextEditingController(text: s.codigoSala);
    _nomeCtrl = TextEditingController(text: s.nomeJogador);
    _hostCtrl = TextEditingController(text: s.hostManual);
  }

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _nomeCtrl.dispose();
    _hostCtrl.dispose();
    super.dispose();
  }

  void _sincronizarControllers(SessaoJogadorState state) {
    if (_codigoCtrl.text != state.codigoSala && state.codigoSala.isNotEmpty) {
      _codigoCtrl.value = TextEditingValue(
        text: state.codigoSala,
        selection: TextSelection.collapsed(offset: state.codigoSala.length),
      );
    }
    if (_nomeCtrl.text.isEmpty && state.nomeJogador.isNotEmpty) {
      _nomeCtrl.text = state.nomeJogador;
    }
    if (_hostCtrl.text.isEmpty && state.hostManual.isNotEmpty) {
      _hostCtrl.text = state.hostManual;
    }
  }

  Future<void> _confirmarDesconectar(BuildContext context) async {
    final cubit = context.read<SessaoJogadorCubit>();
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desconectar da mesa?'),
        content: const Text(
          'Você deixará de receber atualizações do mapa e enviar alterações da ficha.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Desconectar'),
          ),
        ],
      ),
    );
    if (confirmar == true) {
      await cubit.desconectar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SessaoJogadorCubit, SessaoJogadorState>(
      listener: (context, state) => _sincronizarControllers(state),
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.podeEditarConexao) ...[
                _buildCardFormularioConexao(context, state),
                const SizedBox(height: 12),
                _buildCardPreviaFicha(context),
              ] else ...[
                _buildCardStatusConectado(context, state),
                const SizedBox(height: 12),
                _buildCardPreviaFicha(context),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildCardFormularioConexao(
    BuildContext context,
    SessaoJogadorState state,
  ) {
    final cubit = context.read<SessaoJogadorCubit>();
    final mostrarErroCodigo =
        state.codigoSala.isNotEmpty && !state.codigoValido;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(
                Icons.wifi_tethering_outlined,
                color: Color(0xFFD32F2F),
                size: 22,
              ),
              SizedBox(width: 8),
              Text(
                'Entrar na Sessão do Mestre',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('campo_codigo_sessao'),
            controller: _codigoCtrl,
            textCapitalization: TextCapitalization.characters,
            onChanged: cubit.definirCodigoSala,
            decoration: InputDecoration(
              labelText: 'Código da Sessão',
              hintText: 'T20-0000',
              errorText: mostrarErroCodigo
                  ? 'Use o formato T20-0000 (4 dígitos).'
                  : null,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const Key('campo_nome_jogador_sessao'),
            controller: _nomeCtrl,
            onChanged: cubit.definirNomeJogador,
            decoration: InputDecoration(
              labelText: 'Nome do Jogador',
              hintText: 'Como você aparece para o Mestre',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text(
              'Conexão avançada / manual',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF475569),
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  key: const Key('campo_host_manual_sessao'),
                  controller: _hostCtrl,
                  onChanged: cubit.definirHostManual,
                  decoration: InputDecoration(
                    labelText: 'IP / Host do Mestre (opcional)',
                    hintText: 'Ex.: 192.168.0.10:7777',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (state.estadoConexao == EstadoConexaoJogador.erro &&
              state.mensagemErro != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Color(0xFFDC2626),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.mensagemErro!,
                      style: const TextStyle(
                        color: Color(0xFF991B1B),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const Key('botao_conectar_mesa'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.login_rounded, size: 18),
            label: const Text(
              'Conectar à Mesa',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: state.codigoValido ? cubit.conectar : null,
          ),
        ],
      ),
    );
  }

  Widget _buildCardStatusConectado(
    BuildContext context,
    SessaoJogadorState state,
  ) {
    final (
      String texto,
      Color corFundo,
      Color corTexto,
      IconData icone,
    ) = switch (state.estadoConexao) {
      EstadoConexaoJogador.conectando => (
        'Conectando...',
        const Color(0xFFEFF6FF),
        const Color(0xFF1D4ED8),
        Icons.sync,
      ),
      EstadoConexaoJogador.aguardandoAprovacao => (
        'Aguardando aprovação do Mestre',
        const Color(0xFFFFFBEB),
        const Color(0xFFB45309),
        Icons.hourglass_top_rounded,
      ),
      EstadoConexaoJogador.conectado => (
        'Conectado na sessão ${state.codigoSala}',
        const Color(0xFFF0FDF4),
        const Color(0xFF15803D),
        Icons.check_circle_outline,
      ),
      _ => (
        'Desconectado',
        const Color(0xFFF8FAFC),
        const Color(0xFF475569),
        Icons.link_off,
      ),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: corFundo,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(icone, color: corTexto, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    texto,
                    style: TextStyle(
                      color: corTexto,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (state.notaDoMestre != null && state.notaDoMestre!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              key: const Key('card_nota_do_mestre'),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.mail_outline_rounded,
                    size: 18,
                    color: Color(0xFFB45309),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nota do Mestre',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF92400E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          state.notaDoMestre!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF78350F),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (state.estaConectado && state.ultimoSnapshot != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.map_outlined,
                  size: 16,
                  color: Color(0xFF475569),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Mapa ativo: ${state.ultimoSnapshot!.nomeMapa}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF334155),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Rodada ${state.ultimoSnapshot!.rodadaCombate}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              key: const Key('mini_mapa_aba_sessao'),
              borderRadius: BorderRadius.circular(12),
              child: const SizedBox(
                height: 230,
                child: MapaMesaJogadorWidget(compacto: true),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              key: const Key('botao_abrir_mapa_mesa'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.open_in_full_rounded, size: 17),
              label: const Text(
                'Abrir Mapa da Mesa',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                if (widget.onAbrirMapa != null) {
                  widget.onAbrirMapa!();
                  return;
                }
                final fichaCubit = context.read<FichaCubit>();
                final sessaoCubit = context.read<SessaoJogadorCubit>();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => MultiBlocProvider(
                      providers: [
                        BlocProvider.value(value: fichaCubit),
                        BlocProvider.value(value: sessaoCubit),
                      ],
                      child: const MapaJogadorScreen(),
                    ),
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 10),
          OutlinedButton.icon(
            key: const Key('botao_desconectar_mesa'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
              side: const BorderSide(color: Color(0xFFFCA5A5)),
              minimumSize: const Size.fromHeight(42),
            ),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Desconectar'),
            onPressed: () => _confirmarDesconectar(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCardPreviaFicha(BuildContext context) {
    return BlocBuilder<FichaCubit, FichaState>(
      builder: (context, fichaState) {
        final p = fichaState.personagem;
        final classeResumo = p.classes.isEmpty
            ? 'Aventureiro 1'
            : p.classes
                  .map((c) => '${c.classeDefinicao.nome} ${c.nivel}')
                  .join(' / ');

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dados enviados ao Mestre',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Inclui atributos, perícias, magias, inventário e anotações.',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 8),
              Text(
                '${p.nome} • $classeResumo',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _chipResumo('PV ${p.pvAtual}/${p.pvTotal}'),
                  _chipResumo('PM ${p.pmAtual}/${p.pmTotal}'),
                  _chipResumo('Defesa ${p.defesaFinal}'),
                  _chipResumo('Desl ${p.deslocamentoEfetivoMetros}m'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _chipResumo(String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF334155),
        ),
      ),
    );
  }
}
