# ADR-003: Painel do Mestre, Aventuras, Bestiário, Mapa com Visibilidade e Handouts

- **Status:** Proposto
- **Data:** 3 de novembro de 2026
- **Depende de:** ADR-002 rev. 2 (motor de combate, coordenador, Arena e VTT) e ADR-004 (transporte LAN, plugado depois)

> Este ADR descreve a camada de aplicação do Mestre. Ela funciona offline no aparelho do mestre; o transporte LAN (ADR-004) entra depois, por trás de uma `MesaHostFacade`. O código do projeto não foi revisado: as premissas sobre as entidades existentes (`Monstro`, `Personagem`, `CalculoFichaService`) estão na seção 10.

## 1. Contexto e decisão

Hoje o app é centrado no jogador (a ficha). Este ADR acrescenta o lado do mestre sem quebrar a regra central do ADR-002: **uma única fonte de verdade para o combate (o coordenador) e projeções por papel**.

**Decisões:**

1. O Painel é uma camada de aplicação sobre o `HostSessionCoordinator`. A UI do mestre fala com uma `MesaHostFacade`, com duas implementações: `LocalMesaHost` (sem rede, fichas por importação de arquivo) e `LanMesaHost` (ADR-004).
2. Toda entidade que o jogador pode ou não ver carrega uma `Visibilidade`. O padrão é “somente mestre”, e o botão “Revelar” apenas muda esse campo.
3. A visão do jogador é sempre uma **projeção calculada no aparelho do mestre** (`projectFor`). O aparelho do jogador nunca recebe dado que não deva ver.
4. Preparação (aventuras, bestiário, regras, mapas) funciona 100% offline.

## 2. Requisitos

### 2.1 Funcionais

| ID | Requisito | Critério de aceite |
| --- | --- | --- |
| RF-M1 | Receber, revisar e aprovar fichas | O mestre abre a ficha em modo leitura, com a memória de cálculo, e marca Aprovada, Alterações solicitadas (com nota) ou Recusada. A aprovação fica vinculada ao hash da ficha; se a ficha mudar, vira “Desatualizada” |
| RF-M2 | Anotações do mestre | Notas por personagem, cena ou aventura. Cada nota é privada ou compartilhada. O jogador vê as compartilhadas em “Notas do Mestre” (somente leitura), com indicador de não lida |
| RF-M3 | Criar aventuras e colocar personagens nelas | Aventura → cenas → encontros. Elenco de personagens aprovados. Mapas, handouts, notas e ameaças vinculados |
| RF-M4 | Painel personalizável com regras rápidas | Cartões de regras (condições, efeitos etc.) pesquisáveis, fixáveis e editáveis. Layout salvo por preset |
| RF-M5 | Iniciativa e combate automatizado | Elenco e ameaças entram no combate. Os jogadores agem pelas suas fichas, e o host resolve com níveis de automação |
| RF-M6 | Controle do mapa | Imagem de fundo, calibragem do grid, terreno, tokens, régua e revelação de células |
| RF-M7 | Visão do mestre × visão do jogador | Botão “Revelar” em qualquer elemento revelável e “Ver como jogador X” |
| RF-M8 | Bestiário e combatentes | CRUD de criaturas com a ficha completa, cópia para o encontro e importação/exportação |
| RF-M9 | Handouts | Texto e/ou imagem enviados a um jogador específico (ou a vários), com caixa de handouts no jogador e confirmação de leitura |
| RF-M10 | Preparação offline | Tudo de RF-M2 a RF-M9 é editável sem conexão |

**Interpretação adotada em RF-M2:** o pedido diz que “eles podem fazer anotações e o jogador ver”. Entendi como anotações do mestre visíveis ao jogador. Se também for desejado que o jogador escreva notas visíveis ao mestre, basta acrescentar o autor à nota (seção 10).

### 2.2 Não funcionais

- **Escala:** 1 mestre, até 6 jogadores, até 25 combatentes, bestiário de até \~500 criaturas, aventuras com dezenas de cenas.
- **Responsividade:** listas abrem em menos de 300 ms (índices leves); cada edição persiste em até 1 s (autosave com debounce).
- **Privacidade:** nenhum campo marcado como “somente mestre” aparece em saída destinada a jogador. Há teste automatizado de sentinela (seção 8).
- **Memória:** mapas limitados a 2048 px no lado maior por padrão (ADR-002).

### 2.3 Fora de escopo

- Edição da build do jogador pelo mestre (“God Mode”).
- Visão e fog dinâmicos por token, iluminação e raycasting.
- Áudio e voz; sincronização em nuvem.
- Texto completo das regras do jogo: o app traz cartões básicos a partir dos dados que já possui, e o mestre cria os próprios.

## 3. Modelo de domínio

### 3.1 Visibilidade e projeção

```dart
sealed class Visibilidade { const Visibilidade(); }
final class SomenteMestre extends Visibilidade { const SomenteMestre(); }           // padrão
final class ParaJogadores extends Visibilidade { final Set<String> playerIds; ... }
final class ParaTodos extends Visibilidade { const ParaTodos(); }

sealed class PapelView {}
final class VisaoMestre extends PapelView {}
final class VisaoMestreComoJogador extends PapelView { final String playerId; }    // preview
final class VisaoJogador extends PapelView { final String playerId; }

MesaView projectFor(PapelView papel, MesaState estado);                           // função pura
```

Regras de projeção:

1. Uma entidade “somente mestre” não aparece para jogadores, nem como espaço reservado.
2. Um token oculto não aparece no mapa **nem na ordem de iniciativa**. Ao ser revelado, gera `TOKEN_REVEALED` e entra na iniciativa.
3. Para monstros visíveis, só vale o que foi revelado em `RevelacaoMonstro` (nome, aparência, PV, defesa, ataques, resistências, notas). O PV tem três modos: oculto, **estado** (ileso, ferido, gravemente ferido, caído; padrão) ou exato.
4. Células do mapa não reveladas chegam como bloco opaco, e o terreno dentro delas não é enviado.
5. Notas privadas, rolagens secretas e handouts de outros jogadores nunca entram na projeção.
6. A “visão do mestre como jogador X” usa exatamente a mesma função com o papel do jogador. O preview é, portanto, um teste vivo da projeção.

### 3.2 Entidades

| Entidade | Campos principais | Observações |
| --- | --- | --- |
| `MonstroTemplate` | id, nome, ND, tipo, tamanho, atributos, PV, PM, defesa, resistências, deslocamento, ataques\[\], habilidades\[\], RD, imunidades e vulnerabilidades, imagemSha, tags, notas, comportamento da IA, origem (embutido ou customizado) | Template; o combate usa uma cópia |
| `Aventura` | id, nome, resumo, cenas\[\], elenco\[\], handoutIds\[\], notaIds\[\], schemaVersion | Uma pasta por aventura |
| `Cena` | id, nome, mapaId, encontros\[\], notaIds\[\] |  |
| `Encontro` | id, nome, ameaças \[{templateId, quantidade, posiçãoInicial?}\], nívelDeAutomação |  |
| `ElencoEntry` | characterId, playerId, sheetHashAprovado, pvAtual, pmAtual, efeitos\[\] | “Estado de campanha”: persiste entre encontros |
| `MapaBatalha` | id, assetSha256, grid {colunas, linhas, tamanhoDaCélula, deslocamento}, terreno {célula → tipo}, revelação {células reveladas}, tokens\[\] |  |
| `TokenMapa` | id, combatenteId?, rótulo, posição, tamanho, visibilidade |  |
| `NotaMestre` | id, alvo, texto, visibilidade, atualizadoEm, lidaPor |  |
| `Handout` | id, título, corpo, assetSha256?, destinatários, criadoEm, entregueEm?, lidoPor |  |
| `RegraCard` | id, título, categoria, corpo, tags, origem, fixado |  |
| `PainelLayout` | id, nome do preset, painéis \[{widgetId, x, y, largura, altura}\] |  |
| `FichaRevisao` | characterId, sheetHash, status, nota, revisadoEm |  |

## 4. Funcionalidades em detalhe

### 4.1 Revisão e aprovação de fichas (RF-M1)

- **Chegada:** pela LAN (`/join`, ADR-004) ou por importação de arquivo. Nesse caso o jogador toca em “Compartilhar ficha” (arquivo `.t20ficha.json` via `share_plus`) e o mestre importa com `file_picker`. O payload é o mesmo `FichaSnapshot {schemaVersion, protocolVersion, rulesVersion, characterId, sheetHash, ficha}` nos dois caminhos.
- **Confiança zero no cliente:** o host recalcula todos os valores derivados com o `CalculoFichaService` a partir da ficha. Números calculados pelo aparelho do jogador nunca são usados.
- **Estados:** `Pendente → Aprovada | AlteraçõesSolicitadas | Recusada`; `Aprovada → Desatualizada` quando o hash muda; `Desatualizada → Pendente` quando o jogador reenvia.
- **Elenco:** só fichas Aprovadas entram, com a opção “permitir pendentes” para mesas informais.
- **Tela:** lista com badges de status; detalhe com as abas da ficha (widgets read-only reaproveitados), memória de cálculo expansível e, na v1.1, um diff entre a versão atual e a última aprovada (comparação dos JSONs).
- O mestre **não edita a build**: pede mudanças por nota e “Alterações solicitadas”.

### 4.2 Anotações (RF-M2)

- Escopos: personagem, cena e aventura. Editor de texto simples, com formatação limitada.
- Cada nota tem visibilidade. O botão “Compartilhar com o jogador” gera `NOTE_SHARED`, projetado só para o dono do personagem.
- O cliente guarda as notas recebidas em “Notas do Mestre” (somente leitura) e envia `NOTE_READ` ao abrir.
- Editar uma nota já compartilhada cria uma revisão e marca “atualizada” para o jogador.

### 4.3 Aventuras e elenco (RF-M3, RF-M10)

- Hierarquia aventura → cenas → encontros, criada offline. Encontros podem ser reaproveitados como modelos.
- **Elenco por referência:** entrar na aventura guarda `characterId` e `sheetHashAprovado`, sem copiar a ficha.
- **Estado de campanha:** PV, PM e efeitos persistem entre encontros da mesma aventura no aparelho do mestre. “Descanso” é uma ação manual do mestre que restaura os valores (automação depois). Os jogadores recebem os novos valores como `resourcePatches`.
- “Iniciar sessão” cria a mesa (ADR-004) a partir da aventura selecionada.

### 4.4 Bestiário e combatentes (RF-M8)

- **Fontes:** criaturas embutidas (somente leitura, se o app já tiver esses dados) e customizadas (CRUD completo).
- **Editor com validação:** PV maior que zero; ataques com bônus, dano, crítico, alcance e tipo; defesa e resistências. O editor avisa quais automações ficam indisponíveis quando faltam campos.
- **Produtividade:** duplicar (base para variantes), favoritar, buscar por nome, ND, tipo e tags.
- **Adicionar ao encontro** cria um `CombatenteMonstro` **copiando** o template naquele momento: editar o template depois não altera combates em andamento. PV fixo ou rolado, com numeração automática (“Goblin 1”, “Goblin 2”).
- **Importar e exportar** JSON (arquivo ou compartilhar), com `schemaVersion` e relatório de erros por criatura.
- **Revelação:** cada template define uma `RevelacaoMonstro` padrão (o que o jogador vê ao revelar), ajustável por combatente em tempo real.
- **Imagens:** guardadas por SHA-256 e redimensionadas na importação (tokens com até 512 px).

### 4.5 Iniciativa e combate de mesa (RF-M5)

| Nível de automação | O que o app faz | Quando usar |
| --- | --- | --- |
| Automático | Rola, aplica dano e RD, gasta PM, atualiza PV e condições. O mestre só conduz as ameaças | Padrão |
| Assistido | Mostra a resolução proposta; o mestre confirma ou edita antes de aplicar | Quando o mestre quer arbitrar |
| Manual | O app só rastreia iniciativa, turno e PV; o mestre digita os números (`ApplyManualPatch`) | Regras da casa ou situações sem suporte |

O nível é definido por encontro e pode ser trocado por ação.

**Fluxo:**

1. O mestre escolhe um encontro (ou monta um na hora) e o elenco entra automaticamente (`GM_LOAD_ENCOUNTER`).
2. Posicionamento dos tokens no mapa; ameaças ficam ocultas por padrão.
3. Iniciativa automática para todos. Jogadores podem informar o d20 do dado físico, e o mestre ajusta a ordem.
4. No turno de um jogador, o app dele mostra só as ações do seu personagem (a partir de `ataquesResolvidos`). O comando vai ao host, que valida e resolve.
5. No turno de uma ameaça, o mestre usa o painel (alvo e ataque). No modo “Auto-ameaças”, a `NpcTacticalAiService` (ADR-002) propõe ou executa.
6. O mestre pode sobrescrever uma rolagem (`GM_OVERRIDE_ROLL`), aplicar ajuste manual, **desfazer o último evento** (`UndoLast`), rolar em segredo e pular ou atrasar turnos.
7. Condições e efeitos têm duração e são removidos automaticamente ao fim do turno ou da rodada, com aviso.

Sem LAN, o mestre ainda pode conduzir o combate sozinho: fichas importadas viram combatentes e as rolagens dos jogadores são digitadas por ele.

### 4.6 Mapa de batalha (RF-M6, RF-M7)

- **Editor:** importar imagem (com limite de pixels), calibrar o grid (colunas, linhas, tamanho da célula e deslocamento, arrastando para alinhar), pintar terreno (obstáculo e terreno difícil), posicionar tokens, medir distância e definir o tamanho das criaturas.
- **Camadas:** fundo, grid, terreno, revelação, tokens, anotações do mestre (só mestre) e HUD.
- **Revelação por célula (fog simples):** para jogadores, as células não reveladas são opacas; o mestre revela tocando ou pintando retângulos. Não há linha de visão.
- **Botão “Revelar”** em tokens, células, notas, handouts e campos de monstro. “Ocultar de novo” existe, mas o app avisa que não desfaz o que o jogador já viu.
- Alterações de mapa geram eventos (`MAP_CELLS_REVEALED`, `TERRAIN_CHANGED`, `TOKEN_PLACED` etc.), entram no log e podem ser desfeitas.
- Modelos de área (cone, linha e esfera) na régua ficam para a v1.1.

### 4.7 Painel personalizável e regras rápidas (RF-M4)

- O painel é um conjunto de widgets registrados: Iniciativa, Combatente atual, Condições ativas, Regras rápidas, Notas, Handouts, Bestiário rápido, Resumo das fichas, Rolador e Log.
- Cada widget se registra com `PainelWidgetSpec {id, título, builder, tamanhoMínimo}`. O layout (`PainelLayout`) é salvo por preset: “Combate”, “Exploração”, “Social”.
- **Celular:** abas inferiores e cartões reordenáveis (`ReorderableListView`). **Tablet e desktop:** grade com painéis redimensionáveis lado a lado.
- **Regras rápidas:** `RegraCard` com título, categoria (condição, efeito, ação, terreno, outros), corpo curto e tags. É possível fixar, pesquisar e editar. Os cartões embutidos vêm dos dados que o app já possui (por exemplo, as condições do domínio); os cartões do mestre são livres.
- Uma condição ativa no combate leva ao cartão correspondente com um toque.
- O mestre pode enviar um cartão aos jogadores, o que o transforma em handout de regra.

### 4.8 Handouts (RF-M9)

- **Tipos:** texto, imagem ou ambos. **Destinatários:** sempre uma lista explícita de `playerId` (um, vários ou todos).
- **Entrega:** `HANDOUT_DELIVERED` é projetado **somente** para os destinatários. Se o jogador estiver offline, a entrega fica pendente e é feita ao reconectar (replay filtrado). O mestre vê “aguardando”.
- **Imagem:** asset por SHA-256. O `GET /assets/{sha}` exige token e verifica a ACL do asset (ADR-004). A rev. 1 previa cache “public”; aqui passa a ser `private`.
- **No jogador:** aba “Caixa de handouts”, persistida localmente por mesa (funciona offline depois de recebida), com indicador de não lido. Ao abrir, envia `HANDOUT_READ`, e o mestre vê “lido por…”.
- **Recolher:** o mestre pode revogar um handout, que some da caixa na próxima sincronização. O app não consegue apagar o que o jogador já viu ou copiou, e isso deve estar claro na UI.
- **Limites:** texto até 8 KB; imagem até 1 MB depois de redimensionada (lado maior de 1600 px).

## 5. Arquitetura de aplicação e persistência

```
presentation/mestre/  LobbyScreen, PainelScreen, FichasScreen, AventuraScreen,
                      BestiarioScreen, MapaEditorScreen, HandoutsScreen, RegrasScreen
application/mestre/   MestreMesaCubit, AventuraCubit, BestiarioCubit, RevisaoFichasCubit,
                      HandoutCubit, PainelLayoutCubit, MesaHostFacade
domain/mestre/        Visibilidade, projectFor, Aventura, Cena, Encontro, MonstroTemplate,
                      Handout, NotaMestre, RegraCard, PainelLayout, FichaRevisao
data/mestre/          MestreStorageService (JSON atômico), AssetStore
```

```dart
abstract interface class MesaHostFacade {
  Stream<MesaView> viewDo(PapelView papel);        // projeção para a UI do mestre ou o preview
  Future<void> enviar(CommandEnvelope c);          // comandos do mestre
  Stream<FichaRecebida> get fichasRecebidas;       // LAN ou importação de arquivo
  Future<void> entregarHandout(Handout h);
}
```

```
documents/mestre/
  bestiario/index.json             # lista leve (id, nome, ND, tipo, tags)
  bestiario/monstro_{id}.json
  aventuras/{id}/aventura.json     # cenas, encontros, elenco
  aventuras/{id}/notas.json
  aventuras/{id}/handouts.json
  regras/regras_custom.json
  painel/layouts.json
  mesas/{sessionId}/...            # snapshot + eventos (ADR-004)
documents/assets_cache/{sha256}.bin
```

- Escrita atômica (arquivo temporário + `rename`), com debounce de 500 ms em edições de texto.
- Os índices (`index.json`) evitam varrer centenas de arquivos para montar listas.
- Se o bestiário ou as aventuras crescerem além do esperado, migrar para SQLite (por exemplo, `drift`) é um passo localizado na camada `data`.
- Exportar uma aventura como pacote (JSON + assets) para compartilhar fica para a v1.1.

## 6. Decisões e trade-offs

| Decisão | Ganho | Custo | Revisar quando |
| --- | --- | --- | --- |
| Visibilidade por entidade + projeção no host | Segurança de informação; “Revelar” vira uma operação simples | Todo tipo novo de entidade precisa de visibilidade e de teste | Se surgir visão por personagem (fog dinâmico), evoluir para visão por token |
| `MesaHostFacade` com Local e LAN | O mestre usa o painel antes da rede existir | Duas implementações | Quando a LAN estiver estável, `LocalMesaHost` vira o modo “mestre solo” |
| Importação de ficha por arquivo | Valor antes da rede e fallback quando a LAN falhar | Passo manual | Manter sempre |
| Template vs. instância (copy-on-add) | Combate em andamento imune a edições | Duplicação de dados | Sem gatilho previsto |
| Fog por célula revelada | Simples e rápido, sem raycasting | Sem linha de visão | Se pedirem visão por token, escrever um ADR novo |
| Níveis de automação por encontro | Atende mesas de estilos diferentes | Mais UI e mais caminhos de teste | Se um nível quase não for usado, simplificar |
| Painel por registro de widgets | Extensível e personalizável | Layout adaptativo dá trabalho | Se o custo de manutenção crescer, reduzir para presets fixos |

## 7. Modos de falha e mitigação

| Situação | Comportamento |
| --- | --- |
| Ficha de versão de regras incompatível | Rejeita com mensagem clara; opção “importar mesmo assim, somente leitura” |
| Mestre revela algo por engano | “Ocultar de novo” e “Desfazer”, com aviso de que o jogador pode já ter visto |
| Handout para jogador desconectado | Fica pendente (“aguardando”) e é entregue ao reconectar |
| Criatura com dados incompletos | Avisa quais automações faltam; a criatura entra em modo manual |
| Mapa pesado ou pouca memória | Redimensiona; se falhar, usa o grid sem imagem |
| App do mestre fecha | Tudo está persistido; “Retomar sala” (ADR-004) |
| Layout salvo referencia um widget que não existe mais | Ignora o painel desconhecido e usa o preset padrão |
| Bug de projeção vazando informação | Teste de sentinela no CI e “Ver como jogador” como verificação manual |

## 8. Estratégia de testes

- **Sentinela de privacidade:** criar uma mesa com o marcador `SECRET_X` em todos os campos “somente mestre”, serializar toda saída de `projectFor(VisaoJogador)` e dos eventos projetados e falhar se o marcador aparecer.
- **Matriz de visibilidade:** cada entidade × cada alcance × cada papel.
- **Máquina de aprovação:** transições e invalidação por hash.
- **Bestiário:** validação e round-trip de importação e exportação.
- **Handouts:** entrega só ao destinatário, pendência e reconexão, ACL do asset.
- **Widgets do painel:** phone e tablet, persistência de layout.
- **Golden do mapa:** visão do mestre × visão do jogador.

## 9. Roadmap

| Fase | Entregas | Pronto quando | Esforço |
| --- | --- | --- | --- |
| M1 Bestiário, regras rápidas e aventuras (offline) | CRUD de criaturas, cartões de regras, aventuras, cenas e encontros | O mestre cria uma aventura com 2 cenas e 5 criaturas sem rede; round-trip de importação e exportação | 2 a 3 semanas |
| M2 Mapa, visibilidade e preview | Editor de mapa, camadas, revelar, `projectFor`, “Ver como jogador” | Teste de sentinela verde; golden mestre × jogador | 3 a 4 semanas |
| M3 Revisão de fichas, notas e importação | Máquina de aprovação, notas, caixa “Notas do Mestre” | Fluxo ficha → aprovada → elenco funcionando por arquivo | 2 semanas |
| M4 Combate de mesa | Iniciativa multi-ator, níveis de automação, override, desfazer, ameaças com IA | Encontro completo com 3 heróis importados e 4 ameaças | 2 a 3 semanas |
| M5 Handouts | Editor, destinatários, caixa do jogador, ACL | Entrega só aos destinatários (testes); entrega em rede depende do ADR-004 | 1,5 a 2 semanas |
| M6 Painel personalizável | Registro de widgets, presets, layout adaptativo | Layout persiste e restaura em celular e tablet | 1,5 a 2 semanas |

Total estimado: 12 a 16 semanas-pessoa em dedicação integral. M1 a M4 são úteis sem LAN, com o mestre conduzindo tudo no próprio aparelho.

## 10. Questões em aberto e premissas a verificar

1. O jogador também escreve notas visíveis ao mestre? (RF-M2 foi implementado só no sentido mestre → jogador.)
2. Em mesas presenciais, quem rola os dados: o app ou o dado físico? O protocolo já aceita os dois (`d20Manual`).
3. O app já tem dados embutidos de bestiário e condições com licença para reutilização? Isso define o conteúdo dos cartões embutidos.
4. O descanso entre encontros deve ser automático ou sempre manual?
5. Quantas aventuras e criaturas se espera? Isso decide se JSON basta ou se vale migrar para SQLite.
6. O preset de painel é por mestre ou por aventura?
7. O `MovimentoEngine` já trata criaturas de tamanho maior que 1 célula, diagonais e terreno difícil?
8. A entidade `Monstro` atual tem todos os campos do `MonstroTemplate` (ataques estruturados, RD, resistências)?
 