# ADR-002 (rev. 2): Núcleo de Combate Tático e Modo Arena (solo/offline)

- **Status:** Proposto (rev. 2). Substitui a rev. 1, de 31/10/2026.
- **Data:** 3 de novembro de 2026
- **Relacionados:** ADR-003 (Painel do Mestre, Aventuras, Bestiário e Handouts) e ADR-004 (Conexão LAN Mestre ↔ Jogadores)

> Escrito a partir da rev. 1 e de uma revisão crítica dela. O código do projeto não foi revisado: tudo o que se afirma sobre `CombateEngine`, `GridMapa`, `Combatente`, `MovimentoEngine`, `CalculoFichaService` e os 149 testes é premissa a confirmar (seção 9).

## 0. O que mudou em relação à rev. 1

| Tema | Rev. 1 | Rev. 2 |
| --- | --- | --- |
| Escopo | Arena, Painel do Mestre e LAN num só ADR | Este ADR cobre o núcleo de combate e a Arena. Painel e LAN foram para os ADR-003 e ADR-004 |
| Motor | `CombateEngine` lendo modificadores crus | Redutor puro `(estado, comando, dados) → (estado, eventos)`, com RNG injetado e ataques vindos do `CalculoFichaService` |
| Persistência | JSON inteiro reescrito a cada evento | Snapshot periódico + log JSONL append-only |
| Coordenador | Broadcast direto | Fila serial, idempotência reconstruível do log e `projectFor(papel)` desde o início |
| Versionamento | `schemaVersion` só na ficha | `protocolVersion` e `rulesVersion` nos envelopes e no handshake |
| Efeitos e condições | Ponte aplicava `efeitosTemporarios` na ficha | Efeitos ativos vivem no estado de combate; atributos derivados são recalculados sob demanda |
| Arena | Clone descartável + IA básica | Clone + relatório de desempenho + replay com seed + simulação em lote |
| Metas de latência | p99 < 50 ms | Metas por experiência (seção 2.2) |

## 1. Contexto e decisão

O jogador precisa de um lugar seguro para treinar: escolher o personagem, enfrentar ameaças e ver, com números, como a build se comporta. O mesmo motor de regras e o mesmo tabuleiro devem depois servir à mesa com mestre (ADR-003 e ADR-004), sem reescrever nada.

**Decisão:**

1. Um núcleo de combate em Dart puro, estruturado como redutor de eventos.
2. Uma interface `CombatSessionTransport` com a implementação `LoopbackSessionTransport` para a Arena (a implementação LAN vem no ADR-004).
3. A Arena roda sobre um clone descartável da ficha e produz um relatório de desempenho.

## 2. Requisitos

### 2.1 Funcionais da Arena

- **RF-A1** Escolher um personagem salvo e iniciar a Arena com um clone em memória. O original nunca é tocado.
- **RF-A2** Montar o encontro: escolher ameaças (bestiário embutido; o bestiário completo está no ADR-003), quantidade, mapa predefinido e posições iniciais automáticas.
- **RF-A3** Combate por turnos: iniciativa, economia de ações (padrão, movimento, completa, livre, reação), movimento no grid, ataques, magias suportadas, dano, RD, cura, gasto de PM e condições.
- **RF-A4** Régua de alcance T20 (1,5 m adjacente, 9 m curto, 30 m médio, 90 m longo), validada pelo motor.
- **RF-A5** Ameaças controladas por IA tática local.
- **RF-A6** Relatório de desempenho durante e ao fim do combate.
- **RF-A7** Replay: reexibir um combate salvo a partir do log e da seed; retomar uma arena interrompida.
- **RF-A8** Simulação em lote: N combates automáticos com estatísticas.
- **RF-A9** Regra sem automação disponível deve avisar e oferecer “aplicar manualmente”. Nunca falhar em silêncio.
- **RF-A10** Desfazer a última ação (somente na Arena).
- **RF-A11** Rolagem manual opcional (dado físico): o jogador informa o d20 em vez de deixar o app rolar.

### 2.2 Não funcionais

| Meta | Valor | Observação |
| --- | --- | --- |
| Fluidez do tabuleiro | 60 fps com 25 combatentes em grid 30×30 | Medir em aparelho intermediário (3 GB de RAM) |
| Resolver um comando no motor | < 5 ms | Meta de projeto; validar com benchmark |
| Decisão da IA por turno | < 100 ms, com watchdog de 500 ms | Estourou o watchdog: `EndTurn` e aviso no log |
| Memória do mapa | ≤ 32 MB decodificado | Lado maior limitado a 2048 px (4096 px como máximo configurável) |
| Determinismo | Mesma seed + mesmos comandos = mesmo log | Base de replay, testes e simulação |
| Rede e permissões | Nenhuma | A Arena funciona em modo avião |
| Simulação em lote | 1.000 combates sem travar a UI | Em isolate, com progresso; tempo total a medir |

### 2.3 Fora de escopo

- Painel do Mestre, bestiário editável, handouts e LAN (ADR-003 e ADR-004).
- IA com planejamento de vários turnos.
- Automação de magias de círculos altos ou efeitos complexos: ficam em modo “aplicar manualmente”.
- Fog of war, iluminação e áudio.
- Evolução de níveis 2–20 e multiclasse (Fase 2). O motor consome o que a ficha calcular.

## 3. Arquitetura

### 3.1 Camadas

```
presentation  ArenaScreen, VttBoardWidget, RelatorioScreen
application   ArenaCubit, HostSessionCoordinator, CombatSessionTransport
domain        CombateEngine (redutor), CombatState, Combatente, EfeitoAtivo,
(Dart puro)   NpcTacticalAiService, ArenaStatsCollector, MovimentoEngine, GridMapa
data          ArenaStorageService (pasta arena/), BestiarioEmbutido (somente leitura)
```

Regra de dependência: `domain` não importa `flutter`, `dart:io` nem `dart:ui`. Isso mantém o motor testável com `dart test` e reaproveitável em isolates (simulação em lote) e, no futuro, num servidor.

### 3.2 Modelo de domínio (esboço)

```dart
sealed class Combatente {
  String id; String nome; Lado lado;        // heroi | ameaca
  Posicao2D pos; int tamanho;                // tamanho em células (1, 2, 3...)
  int pvAtual, pvMax, pmAtual;
  List<EfeitoAtivo> efeitos;                 // condição + duração + origem
}
final class CombatenteJogador extends Combatente { final Personagem ficha; }
final class CombatenteMonstro extends Combatente { final MonstroTemplate base; }

class CombatState {            // imutável
  int rev;                     // incrementa a cada mudança de turno
  int rodada;
  List<String> ordemIniciativa; int turnoIdx;
  Map<String, Combatente> combatentes;
  GridMapa grid;
  EconomiaAcoes economia;      // do combatente da vez
}
```

**Atributos derivados sob demanda.** Uma `StatsResolver` calcula `ataquesResolvidos`, `reducaoDeDano`, defesa e bônus a partir da ficha (via `CalculoFichaService`) ou do template do monstro, **aplicando os efeitos ativos**. O resultado é cacheado por `(combatenteId, hashDosEfeitos)`. Assim, uma condição que muda o ataque é refletida na próxima rolagem, em vez de usar valores congelados no início do combate.

### 3.3 Comandos e eventos (catálogo v1 da Arena)

| Comando | Evento(s) | Validações principais |
| --- | --- | --- |
| `StartEncounter` | `ENCOUNTER_STARTED` | ao menos 1 herói e 1 ameaça; posições válidas |
| `RollInitiative` | `INITIATIVE_ROLLED` | aceita `d20Manual` |
| `MoveToken` | `TOKEN_MOVED` | célula alcançável (`MovimentoEngine`), custo de movimento, ação disponível |
| `ExecuteAttack` | `ATTACK_RESOLVED` | turno, alcance, ação padrão, PM das habilidades |
| `CastSpellCombat` | `SPELL_RESOLVED` ou `SPELL_MANUAL_REQUIRED` | PM, alcance, alvo |
| `EndTurn`, `DelayInitiative` | `TURN_ENDED`, `INITIATIVE_DELAYED` | turno atual |
| `ApplyManualPatch` | `PATCH_APPLIED` | dano, cura ou condição arbitrados |
| `UndoLast` | `EVENT_REVERTED` | evento compensatório; o log nunca é apagado |

Campos comuns do envelope de comando: `v` (versão do protocolo), `commandId` (UUID v4), `actorId`, `turnRev` (obrigatório nos comandos que dependem do turno; se estiver defasado, o comando é rejeitado com `STALE_TURN`) e, opcionalmente, `d20Manual`.

### 3.4 Motor como redutor puro

```dart
abstract interface class DiceRoller { int d(int faces); }   // SeededDice(seed) nos testes

final class ApplyResult {
  final CombatState estado;
  final List<CombatEvent> eventos;
  final Rejeicao? rejeicao;                                   // ex.: OUT_OF_RANGE
}

ApplyResult apply(CombatState s, CombatCommand c, DiceRoller dice);
```

Regras do redutor:

- Sem efeitos colaterais, sem I/O e sem `DateTime.now()` (carimbos de tempo vêm do coordenador).
- Mesmas entradas, mesmas saídas. O RNG é injetado, e `d20Manual` substitui a rolagem.
- Um comando produz um único registro de evento com todos os efeitos (por exemplo, dano em área gera uma lista de `resourcePatches`), mantendo a atomicidade por `seq`.
- Migração: manter uma `LegacyEngineAdapter` com a API antiga do `CombateEngine` até os 149 testes serem portados, evitando quebra em massa.

### 3.5 Coordenador

O `HostSessionCoordinator` é o único dono do estado. Pontos que a rev. 1 deixou em aberto:

```dart
final class HostSessionCoordinator {
  Future<void> _fila = Future.value();
  Future<void> handle(CommandEnvelope c) =>
      _fila = _fila.then((_) => _processar(c)).catchError(_registrarErro);

  Future<void> _processar(CommandEnvelope c) async {
    final repetido = _porCommandId[c.commandId];
    if (repetido != null) return _emit(repetido);            // idempotência
    final r = engine.apply(_estado, c, dice);                // puro e síncrono
    if (r.rejeicao != null) return _emitirRejeicao(c, r.rejeicao!);
    _estado = r.estado;
    final rec = EventRecord(seq: ++_seq, commandId: c.commandId, eventos: r.eventos);
    await _log.append(rec);                                  // log antes de emitir
    _porCommandId[c.commandId] = rec;
    _emit(rec);
  }
}
```

- **Fila serial:** cada `await` abriria uma janela para dois comandos se intercalarem. O estado só muda dentro da fila.
- **Idempotência reconstruível:** o índice `commandId → seq` é refeito a partir do log ao retomar uma sessão.
- **`projectFor(papel)`:** na Arena o papel é único (jogador + mestre da simulação), então a projeção é a identidade. O ponto de extensão já existe para o ADR-003 e o ADR-004, onde ele é obrigatório.

### 3.5.1 Transporte

```dart
abstract interface class CombatSessionTransport {
  Stream<EventRecord> get events;
  Future<void> send(CommandEnvelope command);
  Future<void> close();
}

class LoopbackSessionTransport implements CombatSessionTransport {
  LoopbackSessionTransport(this._host);
  final HostSessionCoordinator _host;
  @override Stream<EventRecord> get events => _host.events;
  @override Future<void> send(CommandEnvelope c) => _host.handle(c);
  @override Future<void> close() async {}
}
```

O `CombateCubit` só conhece essa interface. Trocar Loopback por LAN (ADR-004) não muda UI nem regras.

### 3.6 IA tática (`NpcTacticalAiService` v0)

```dart
abstract interface class TacticalPolicy {
  List<CombatCommand> planejarTurno(CombatState s, String combatenteId);
}
```

Algoritmo da v0:

1. Listar alvos válidos (heróis vivos).
2. Para cada alvo alcançável, estimar o valor esperado do melhor ataque: `P(acerto) × dano médio × (1 + chance de crítico × (multiplicador − 1))`.
3. Escolher o alvo de maior valor, desempatando pelo menor custo de deslocamento. Se nenhum for alcançável, aproximar-se pelo caminho de menor custo (A\* sobre o `MovimentoEngine`), evitando terreno difícil quando possível.
4. Emitir a sequência `MoveToken → ExecuteAttack → EndTurn`, com o papel de mestre.
5. Watchdog: se o planejamento passar de 500 ms, emitir `EndTurn` e registrar o aviso.

A mesma interface permite uma `HeroAutopilotPolicy` para a simulação em lote e, mais tarde, políticas mais ricas.

### 3.7 Isolamento do sandbox

- O clone nasce de um round-trip JSON da ficha (`Personagem.fromJson(jsonDecode(jsonEncode(p.toJson())))`, se o domínio permitir) e vive só em RAM.
- A Arena roda num escopo de injeção **sem** `PersonagemStorageService` e sem `FichaSessionBridge`. Não há caminho de código que escreva na ficha.
- Teste de guarda: um `FakeStorage` que lança erro em qualquer escrita, mais a comparação de `lastModified` e do hash dos arquivos `personagem_*.json` antes e depois de uma arena completa.
- A UI exibe um indicador fixo: “ARENA: nada é salvo na ficha”.

### 3.8 Relatório de desempenho

Um `ArenaStatsCollector` consome o stream de eventos (o mesmo que a UI) e calcula:

| Métrica | Definição |
| --- | --- |
| Resultado e rodadas | Vitória, derrota ou fuga; número de rodadas |
| DPR | Dano total causado pelo herói ÷ rodadas |
| Taxa de acerto e de crítico | Acertos ÷ ataques; críticos ÷ acertos |
| Dano médio por acerto | Média do dano final já com RD aplicada |
| PV perdidos por rodada e PV restantes (%) | Pressão recebida e folga ao final |
| PM gastos | Total e por rodada |
| Turnos ociosos | Turnos sem ataque, movimento útil ou magia |
| Tempo até o primeiro dano | Em rodadas |

**Simulação em lote (RF-A8):** roda N combates (seeds derivadas de uma seed-mãe) em `Isolate.run`, com o herói controlado pela `HeroAutopilotPolicy` e progresso via `ReceivePort`. Saída: taxa de vitória, média, mediana e p90 de rodadas, histograma de PV restantes e DPR médio com desvio. O resultado é **indicativo**: a política de piloto automático é uma heurística, e a tela deve dizer isso. Uma comparação A/B entre duas versões do mesmo personagem é uma extensão natural.

### 3.9 `VttBoardWidget`

- **Camadas:** fundo (imagem opcional), grid, terreno, alcance/células alcançáveis, tokens e HUD, cada uma em seu `RepaintBoundary`, desenhadas por `CustomPainter` com `repaint: Listenable`.
- **Navegação:** `InteractiveViewer` com `minScale` e `maxScale`, e auto-zoom ao selecionar um token.
- **Interação no celular:** um grid de 30×30 numa tela de 360 dp dá \~12 dp por célula, longe dos 48 dp recomendados para toque. Por isso o modelo é **tocar no token (seleciona e mostra o alcance) → tocar no destino (pré-visualiza caminho e custo) → confirmar**. Arrastar é opcional. O toque usa área expandida e escolhe a célula mais próxima.
- **Imagem de fundo:** `ResizeImage` ou `cacheWidth`, com lado maior limitado a 2048 px, para controlar a memória decodificada (um PNG de 4096×4096 ocupa \~64 MB).
- **HUD:** barra de iniciativa, economia de ações do combatente da vez, régua com as faixas de alcance T20, log de eventos legível.

## 4. Persistência da Arena

```
documents/arena/
  arena_{id}.json          # configuração: personagem (id + hash), ameaças, grid, seed, schemaVersion
  arena_{id}.events.jsonl  # um EventRecord por linha
  arena_{id}.report.json   # métricas finais
```

- Escrita de snapshot via arquivo temporário + `rename`; o log recebe `append` com `flush: true`.
- Retenção: as 20 arenas mais recentes.
- “Retomar arena” reconstrói o estado por replay do log com a mesma seed.
- Nada disso entra na pasta `personagens/`.

## 5. Decisões e trade-offs

| Decisão | Ganho | Custo | Revisar quando |
| --- | --- | --- | --- |
| Redutor puro + log de eventos | Testes determinísticos, replay, desfazer e simulação em lote quase de graça | Disciplina (nenhum estado oculto) e refatoração do motor atual | Se a cópia de estados imutáveis aparecer como gargalo no benchmark |
| Loopback + coordenador local | Mesmo código da Arena e da mesa | Pequena sobrecarga de fila | Improvável: tudo em memória |
| Clone descartável | Zero risco para a ficha real | Pode divergir se algum campo não serializar bem | Se o round-trip JSON perder dados |
| IA heurística v0 com `TacticalPolicy` | Entrega rápida e comportamento previsível | Ameaças pouco “espertas” | Quando a IA virar foco, adicionar busca de 1 a 2 turnos |
| Simulação em lote em isolate | Mostra desempenho estatístico, não só uma luta | Resultado depende da heurística do herói | Só entregar após o motor estar estável |
| Atributos derivados sob demanda | Efeitos e condições sempre refletidos | Recálculo (mitigado pelo cache) | Se o cache gerar bugs de invalidação |

## 6. Modos de falha

| Situação | Comportamento |
| --- | --- |
| App morto durante a Arena | Ao reabrir, oferecer “Retomar arena” por replay do log |
| Regra ou magia sem automação | Evento `*_MANUAL_REQUIRED` + painel de ajuste manual; o combate continua |
| IA estoura o watchdog | `EndTurn` automático, aviso no log, sem travar a UI |
| Mapa grande ou pouca memória | Redimensiona para o limite de pixels; se falhar, usa o grid sem imagem |
| Ficha inválida ou incompleta | Bloqueia o início com a lista de campos faltantes |
| Divergência entre seed e log | Replay marca o primeiro evento divergente e para |

## 7. Estratégia de testes

- **Golden do motor:** crítico (margem de ameaça e multiplicador), RD, alcance, custo de PM, economia de ações, condições que alteram o ataque.
- **Propriedade de replay:** aplicar o log do início produz exatamente o estado final.
- **Determinismo:** mesma seed e mesmos comandos geram o mesmo log (inclusive entre dois isolates).
- **Guarda do sandbox:** nenhuma escrita em `personagens/`.
- **IA:** nunca emite comando inválido; sempre termina o turno dentro do watchdog.
- **VTT:** golden tests do tabuleiro (grid, alcance, tokens) e teste de toque (seleção, destino, confirmação).
- **Benchmark:** 25 combatentes e o tempo de 1.000 simulações.

## 8. Roadmap e critérios de pronto

| Fase | Entregas | Pronto quando | Esforço |
| --- | --- | --- | --- |
| A0 Spikes | Mapa 4096² em aparelho de 3 GB; protótipo de toque 30×30 | Decisões de limite de pixels e de interação registradas | 2 a 3 dias |
| A1 Domínio | Redutor, comandos e eventos como sealed classes, `StatsResolver`, RD, alcance, card “Ataques em 1 toque” | 149 testes verdes, casos golden e teste de replay passando | 1,5 a 2,5 semanas |
| A2 Arena jogável | Coordenador, Loopback, IA v0, VTT, clone, desfazer, retomar | Arena completa de 1 herói contra 3 ameaças, offline; golden tests; teste de guarda | 3 a 4 semanas |
| A3 Relatório e replay | Coletor, tela de relatório, salvar e reexibir | A mesma seed reproduz o mesmo relatório | 1 a 1,5 semana |
| A4 Simulação em lote (opcional) | Isolate, progresso e estatísticas | 1.000 combates sem travar a UI; aviso de heurística visível | 1 a 1,5 semana |

Total estimado: 7 a 10 semanas-pessoa em dedicação integral, sem ter visto o código. A **A2 já é um marco entregável** sozinho.

## 9. Premissas a verificar no código

1. O `CombateEngine` atual guarda estado mutável? Qual é a API exposta aos 149 testes (define o tamanho da `LegacyEngineAdapter`)?
2. `Personagem` tem `toJson`/`fromJson` com round-trip fiel, inclusive campos opcionais e listas aninhadas?
3. O `CalculoFichaService` aceita efeitos ou condições como parâmetro? Se não, será preciso estendê-lo.
4. `Monstro` já tem ataques estruturados (bônus, dano, crítico, alcance, tipo de dano) e RD?
5. O `MovimentoEngine` trata diagonais, terreno difícil e criaturas de tamanho maior que 1 célula?
6. Quais magias do escopo têm automação viável? As demais entram em modo manual.
7. Qual mecanismo de injeção de dependências está em uso (para criar o escopo da Arena sem o `PersonagemStorageService`)?
