import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/divindade.dart';
import '../../domain/services/data_services/call_divindades.dart';
import '../../domain/validators/validador_divindade.dart';
import '../controllers/personagem_cubit.dart';
import '../../helpers/deuses_jpeg.dart';

class PaginaSelecaoDivindade extends StatefulWidget {
  final PersonagemState state;

  const PaginaSelecaoDivindade({super.key, required this.state});

  @override
  State<PaginaSelecaoDivindade> createState() => _PaginaSelecaoDivindadeState();
}

class _PaginaSelecaoDivindadeState extends State<PaginaSelecaoDivindade> {
  bool _menuAberto = true;

  @override
  Widget build(BuildContext context) {
    final divindadeSelecionada = widget.state.divindadeSelecionada;
    final cubit = context.read<PersonagemCubit>();
    final modoEstrito = widget.state.modoEstritoDevocao;
    final exigeDevocao = ValidadorDivindade.exigeDevocao(
      widget.state.personagem,
      modoEstrito: modoEstrito,
    );

    return Column(
      children: [
        // HUD Superior Informativo
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.grey[200],
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      divindadeSelecionada != null
                          ? "Devoto de ${divindadeSelecionada.nome}"
                          : (exigeDevocao
                                ? "Devoção Obrigatória (Escolha um Deus)"
                                : "Sem Divindade (Não Devoto)"),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      modoEstrito
                          ? "Modo Estrito (Regras Oficiais T20)"
                          : "Modo Livre (Homebrew Habilitado)",
                      style: TextStyle(
                        fontSize: 11,
                        color: modoEstrito
                            ? Colors.grey[700]
                            : Colors.deepPurple[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Botão de alternar Modo Estrito / Livre
              InkWell(
                onTap: () {
                  cubit.alternarModoEstritoDevocao(!modoEstrito);
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: modoEstrito ? Colors.white : Colors.deepPurple[50],
                    border: Border.all(
                      color: modoEstrito
                          ? Colors.grey[400]!
                          : Colors.deepPurple[400]!,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        modoEstrito ? Icons.gavel : Icons.lock_open_rounded,
                        size: 14,
                        color: modoEstrito
                            ? Colors.grey[800]
                            : Colors.deepPurple[800],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        modoEstrito ? "Estrito" : "Livre",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: modoEstrito
                              ? Colors.grey[800]
                              : Colors.deepPurple[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildBadgeStatus(),
            ],
          ),
        ),
        const Divider(height: 1),

        // Área principal (Menu Lateral + Painel de Detalhes)
        Expanded(
          child: Row(
            children: [
              // Menu Lateral Animado
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: _menuAberto ? 140 : 0,
                color: const Color(0xFFD32F2F),
                child: ClipRect(
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          "Panteão de Arton",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const Divider(color: Colors.white54, height: 1),

                      // Opção 0: Não ser devoto (Pular)
                      GestureDetector(
                        onTap: () {
                          if (exigeDevocao) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Sua classe (${widget.state.personagem.classes[0].classeDefinicao.nome}) "
                                  "exige a escolha obrigatória de uma divindade nas regras oficiais.",
                                ),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                            return;
                          }
                          cubit.selecionarDivindade(null);
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 6,
                          ),
                          decoration: BoxDecoration(
                            color: divindadeSelecionada == null
                                ? Colors.grey[300]
                                : (exigeDevocao
                                      ? Colors.black26
                                      : Colors.transparent),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white38, width: 1),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                exigeDevocao ? Icons.lock : Icons.block,
                                size: 14,
                                color: divindadeSelecionada == null
                                    ? Colors.black
                                    : Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  "Não Devoto",
                                  style: TextStyle(
                                    color: divindadeSelecionada == null
                                        ? Colors.black
                                        : (exigeDevocao
                                              ? Colors.white38
                                              : Colors.white),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(color: Colors.white54, height: 1),

                      // Lista das Divindades
                      Expanded(
                        child: ListView.builder(
                          itemCount: BancoDeDivindades.todas.length,
                          itemBuilder: (context, index) {
                            final divindade = BancoDeDivindades.todas[index];
                            final isSelected =
                                divindadeSelecionada?.id == divindade.id;

                            // Verifica elegibilidade oficial desta divindade
                            final elegibilidade =
                                ValidadorDivindade.validarElegibilidade(
                                  personagem: widget.state.personagem,
                                  divindade: divindade,
                                  modoEstrito: modoEstrito,
                                );

                            return GestureDetector(
                              onTap: () {
                                cubit.selecionarDivindade(divindade);
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.grey[300]
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (!elegibilidade.ehElegivel) ...[
                                      const Icon(
                                        Icons.block,
                                        size: 13,
                                        color: Colors.white70,
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    SimboloDivindade(
                                      idDivindade: divindade.id,
                                      tamanho: 22,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        divindade.nome,
                                        textAlign: TextAlign.start,
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.black
                                              : (!elegibilidade.ehElegivel
                                                    ? Colors.white70
                                                    : Colors.white),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
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
                ),
              ),

              // Botão Retrátil
              GestureDetector(
                onTap: () => setState(() => _menuAberto = !_menuAberto),
                child: Container(
                  width: 24,
                  height: double.infinity,
                  color: const Color(0xFFB71C1C),
                  child: Icon(
                    _menuAberto ? Icons.chevron_left : Icons.chevron_right,
                    color: Colors.white,
                  ),
                ),
              ),

              // Painel de Conteúdo
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: divindadeSelecionada == null
                      ? _buildPainelNaoDevoto(exigeDevocao)
                      : _buildPainelDivindade(divindadeSelecionada, cubit),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeStatus() {
    final divindade = widget.state.divindadeSelecionada;
    final modoEstrito = widget.state.modoEstritoDevocao;
    final exigeDevocao = ValidadorDivindade.exigeDevocao(
      widget.state.personagem,
      modoEstrito: modoEstrito,
    );

    if (divindade == null) {
      if (exigeDevocao) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red[800],
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            "Devoção Exigida",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        );
      }
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green[700],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          "Não Devoto (Pronto)",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
    }

    final elegibilidade = ValidadorDivindade.validarElegibilidade(
      personagem: widget.state.personagem,
      divindade: divindade,
      modoEstrito: modoEstrito,
    );

    if (!elegibilidade.ehElegivel) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red[800],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          "Restrito para sua Classe",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
    }

    // Se é devoto, verifica se precisa escolher canalização
    if (divindade.canalizacaoPermitida == CanalizacaoOpcao.qualquer &&
        widget.state.canalizacaoSelecionada == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange[800],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          "Escolha a Energia",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
    }

    // Validação da cota de poderes concedidos
    final ehDevotoFiel = ValidadorDivindade.ehDevotoFiel(
      widget.state.personagem,
    );
    final cota = ehDevotoFiel ? 2 : 1;
    final selecionados = widget.state.poderesConcedidosSelecionados.length;
    final completo = selecionados == cota;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: completo ? Colors.green[700] : Colors.orange[800],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        completo
            ? (ehDevotoFiel
                  ? "Devoto Fiel: 2/2 Poderes"
                  : "Poder Concedido: 1/1")
            : (ehDevotoFiel
                  ? "Escolha 2 Poderes ($selecionados/2)"
                  : "Escolha 1 Poder Concedido"),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildPainelNaoDevoto(bool exigeDevocao) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              exigeDevocao
                  ? Icons.warning_amber_rounded
                  : Icons.shield_outlined,
              size: 64,
              color: exigeDevocao ? Colors.red[700] : Colors.grey[500],
            ),
            const SizedBox(height: 16),
            Text(
              exigeDevocao
                  ? "Devoção Obrigatória!"
                  : "Aventureiro Livre (Não Devoto)",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: exigeDevocao ? Colors.red[800] : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              exigeDevocao
                  ? "Sua classe (Clérigo, Druida ou Paladino) exige a escolha de um deus padroeiro no Panteão. Selecione uma divindade no menu ao lado para prosseguir."
                  : "Você optou por não seguir nenhum deus do Panteão. Seu personagem não recebe poderes concedidos, mas tem total liberdade moral e não sofre nenhuma Obrigação ou Restrição sagrada.",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[750],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (!exigeDevocao)
              Chip(
                backgroundColor: Colors.green[50],
                side: BorderSide(color: Colors.green[400]!),
                avatar: const Icon(
                  Icons.check_circle,
                  size: 18,
                  color: Colors.green,
                ),
                label: const Text(
                  "Você pode avançar sem escolher um deus",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPainelDivindade(Divindade divindade, PersonagemCubit cubit) {
    final modoEstrito = widget.state.modoEstritoDevocao;
    final elegibilidade = ValidadorDivindade.validarElegibilidade(
      personagem: widget.state.personagem,
      divindade: divindade,
      modoEstrito: modoEstrito,
    );
    final ehDevotoFiel = ValidadorDivindade.ehDevotoFiel(
      widget.state.personagem,
    );
    final canalizacaoAtual = widget.state.canalizacaoSelecionada;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Símbolo Sagrado, Nome e Título da Divindade
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SimboloDivindade(
              idDivindade: divindade.id,
              tamanho: 64,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    divindade.nome,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    divindade.titulo,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.red[900],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Banner Informativo de Elegibilidade / Devoção Fiel
        if (!elegibilidade.ehElegivel)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red[400]!),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline, color: Colors.red[800], size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Restrição de Classe Oficial",
                        style: TextStyle(
                          color: Colors.red[900],
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        elegibilidade.motivoIneligibilidade ?? '',
                        style: TextStyle(color: Colors.red[950], fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Para permitir esta escolha, desative o Modo Estrito no topo (Modo Livre / Homebrew).",
                        style: TextStyle(
                          color: Colors.red[900],
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else if (ehDevotoFiel)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber[700]!),
            ),
            child: Row(
              children: [
                Icon(Icons.stars_rounded, color: Colors.amber[800], size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Devoto Fiel (${widget.state.personagem.classes[0].classeDefinicao.nome})",
                        style: TextStyle(
                          color: Colors.amber[900],
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        "Como devoto fiel (membro do clero ou campeão sagrado), você pode escolher 2 poderes concedidos desta divindade (em vez de apenas 1)!",
                        style: TextStyle(
                          color: Color(0xFF5D4037),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Especificações Rápidas
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            Chip(
              backgroundColor: Colors.grey[100],
              side: BorderSide(color: Colors.grey[300]!),
              avatar: const Icon(
                Icons.auto_awesome,
                size: 16,
                color: Colors.indigo,
              ),
              label: Text(
                "Símbolo: ${divindade.simboloSagrado}",
                style: const TextStyle(fontSize: 12),
              ),
            ),
            Chip(
              backgroundColor: Colors.grey[100],
              side: BorderSide(color: Colors.grey[300]!),
              avatar: const Icon(Icons.colorize, size: 16, color: Colors.brown),
              label: Text(
                "Arma: ${divindade.armaPreferida}",
                style: const TextStyle(fontSize: 12),
              ),
            ),
            Chip(
              backgroundColor: Colors.grey[100],
              side: BorderSide(color: Colors.grey[300]!),
              avatar: const Icon(Icons.bolt, size: 16, color: Colors.amber),
              label: Text(
                "Canalização: ${_nomeCanalizacaoOpcao(divindade.canalizacaoPermitida)}",
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(),

        // Lore / Descrição
        Text(
          divindade.descricao,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            height: 1.35,
          ),
          textAlign: TextAlign.justify,
        ),
        const SizedBox(height: 16),

        // Card de Obrigações & Restrições (Destaque Vermelho)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red[400]!, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.gavel, color: Colors.red[900], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Obrigações & Restrições",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.red[950],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...divindade.obrigacoesERestricoes.map(
                (regra) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "• ",
                        style: TextStyle(
                          color: Colors.red[950],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          regra,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.red[950],
                            height: 1.3,
                          ),
                          textAlign: TextAlign.justify,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Seletor de Canalização de Energia (quando a divindade permite qualquer)
        if (divindade.canalizacaoPermitida == CanalizacaoOpcao.qualquer) ...[
          const Divider(),
          const Text(
            "Canalização de Energia Sagrada",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            "Esta divindade aceita ambas as energias. Você deve escolher qual canaliza:",
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () =>
                      cubit.selecionarCanalizacao(TipoEnergia.positiva),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: canalizacaoAtual == TipoEnergia.positiva
                          ? Colors.green[50]
                          : Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: canalizacaoAtual == TipoEnergia.positiva
                            ? Colors.green[700]!
                            : Colors.grey[300]!,
                        width: canalizacaoAtual == TipoEnergia.positiva ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.favorite,
                          color: canalizacaoAtual == TipoEnergia.positiva
                              ? Colors.green[700]
                              : Colors.grey[500],
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Energia Positiva",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: canalizacaoAtual == TipoEnergia.positiva
                                ? Colors.green[900]
                                : Colors.black87,
                          ),
                        ),
                        Text(
                          "Cura vivos / Fere mortos-vivos",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () =>
                      cubit.selecionarCanalizacao(TipoEnergia.negativa),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: canalizacaoAtual == TipoEnergia.negativa
                          ? Colors.purple[50]
                          : Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: canalizacaoAtual == TipoEnergia.negativa
                            ? Colors.purple[700]!
                            : Colors.grey[300]!,
                        width: canalizacaoAtual == TipoEnergia.negativa ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.dark_mode,
                          color: canalizacaoAtual == TipoEnergia.negativa
                              ? Colors.purple[700]
                              : Colors.grey[500],
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Energia Negativa",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: canalizacaoAtual == TipoEnergia.negativa
                                ? Colors.purple[900]
                                : Colors.black87,
                          ),
                        ),
                        Text(
                          "Dano em vivos / Cura mortos-vivos",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],

        const Divider(),

        // Seletor de Poder Concedido
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Poderes Concedidos",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              ehDevotoFiel
                  ? "Escolha 2 poderes (${widget.state.poderesConcedidosSelecionados.length}/2)"
                  : "Escolha 1 poder (${widget.state.poderesConcedidosSelecionados.length}/1)",
              style: TextStyle(
                fontSize: 12,
                color: ehDevotoFiel ? Colors.green[800] : Colors.grey[700],
                fontWeight: ehDevotoFiel ? FontWeight.bold : FontWeight.normal,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        ...divindade.poderesConcedidos.map((poder) {
          final isSelected = widget.state.poderesConcedidosSelecionados.any(
            (p) => p.key == poder.key,
          );

          // Valida pré-requisitos do poder
          final validacaoPoder = ValidadorDivindade.validarPoderConcedido(
            personagem: widget.state.personagem,
            poder: poder,
          );

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () {
                if (!validacaoPoder.ehElegivel && modoEstrito) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Pré-requisitos não cumpridos: "
                        "${validacaoPoder.pendencias.map((p) => p.descricao).join(', ')}",
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  return;
                }
                cubit.selecionarPoderConcedido(poder);
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (ehDevotoFiel ? Colors.green[50] : Colors.red[50])
                      : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? (ehDevotoFiel ? Colors.green[700]! : Colors.red[700]!)
                        : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2, right: 6),
                      child: Icon(
                        isSelected
                            ? (ehDevotoFiel
                                  ? Icons.check_box_rounded
                                  : Icons.radio_button_checked)
                            : (ehDevotoFiel
                                  ? Icons.check_box_outline_blank_rounded
                                  : Icons.radio_button_unchecked),
                        color: isSelected
                            ? (ehDevotoFiel
                                  ? Colors.green[700]
                                  : Colors.red[800])
                            : Colors.grey[500],
                        size: 22,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                poder.nome,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: ehDevotoFiel
                                        ? Colors.green[100]
                                        : Colors.red[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    ehDevotoFiel
                                        ? "Selecionado (Fiel)"
                                        : "Selecionado",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: ehDevotoFiel
                                          ? const Color(0xFF1B5E20)
                                          : const Color(0xFFB71C1C),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            poder.descricao,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[800],
                              height: 1.25,
                            ),
                          ),
                          if (!validacaoPoder.ehElegivel) ...[
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 4,
                              children: validacaoPoder.pendencias.map((pend) {
                                return Chip(
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  padding: EdgeInsets.zero,
                                  labelPadding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  backgroundColor: Colors.red[100],
                                  label: Text(
                                    "Requer: ${pend.descricao}",
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFFB71C1C),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 20),
      ],
    );
  }

  String _nomeCanalizacaoOpcao(CanalizacaoOpcao opcao) {
    switch (opcao) {
      case CanalizacaoOpcao.apenasPositiva:
        return "Exclusiva Positiva";
      case CanalizacaoOpcao.apenasNegativa:
        return "Exclusiva Negativa";
      case CanalizacaoOpcao.qualquer:
        return "À Escolha (Positiva ou Negativa)";
    }
  }
}
