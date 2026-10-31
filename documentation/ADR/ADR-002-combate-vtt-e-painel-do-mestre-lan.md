# ADR-002: Arquitetura do Módulo de Combate VTT 2D, Sandbox Offline e Painel do Mestre via LAN WebSocket

## Status
**Proposto (Proposed — System Design Baseline)**

## Data
2026-10-31

## Diagrama Arquitetural Renderizado
- **Diagrama Interativo (HTML + SVG Dark-Theme com exportação PNG/PDF):** [`documentation/diagrams/arquitetura-combate-vtt-mestre.html`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/documentation/diagrams/arquitetura-combate-vtt-mestre.html)

---

## 1. Problema e Escopo

**Em uma frase:** Um subsistema unificado de **Combate Tático 2D (Virtual Tabletop — VTT) e Gestão de Sessão** para Tormenta 20 (JdA) onde o **mesmo motor de domínio em Dart puro** opera tanto em **Modo Offline (Arena de Treino contra NPCs)** quanto em **Modo LAN Autoritativo (Painel do Mestre no Wi-Fi/Hotspot local via WebSocket)**, permitindo ao Mestre auditar fichas de jogadores e conduzir encontros sincronizados em tempo real sem depender de servidores em nuvem.

### 1.1. Requisitos Funcionais (Core)
1. **Hospedar Sala como Mestre (LAN):** Iniciar um servidor HTTP + WebSocket embutido (`dart:io`) no dispositivo do Mestre (Android ou Desktop), gerando um código IP:Porta + PIN de 4–6 dígitos e QR Code de conexão rápida.
2. **Conectar Ficha e Avaliação pelo Mestre:** Permitir que o jogador selecione um [`Personagem`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/domain/entities/personagem/personagem.dart) local e entre na sala; o Mestre visualiza a ficha completa em **modo auditoria/leitura** (com toda a memória de cálculo do [`CalculoFichaService`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/domain/services/calculo_ficha_service.dart)) e aprova sua participação na mesa.
3. **Combate no VTT 2D Enxuto:** Evoluir [`GridMapa`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/domain/entities/combate/grid_tatico.dart) e [`MovimentoEngine`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/domain/services/movimento_engine.dart) com imagem de fundo opcional, tokens de heróis e ameaças ([`Monstro`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/domain/entities/combate/monstro.dart)), obstáculos/terreno difícil, régua de alcance T20 ($1{,}5\text{m}$ adjacente, $9\text{m}$ curto, $30\text{m}$ médio, $90\text{m}$ longo), fila de iniciativa e economia de ações (Padrão, Movimento, Completa, Livre, Reação).
4. **Sincronização Autoritativa de Sessão:** Resolver ataques (integrando [`CalculoFichaService.prepararPreviewAtaqueArma`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/domain/services/calculo_ficha_service.dart#L766-L798)), conjurações, danos, Redução de Dano (RD), curas, gasto de PM e condições no nó líder (Mestre), propagando deltas imediatos para o [`FichaCubit`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/presentation/controllers/ficha_cubit.dart) dos jogadores sem jamais alterar a build estrutural permanente da ficha.
5. **Arena Offline de Treino contra NPCs (Sandbox):** Executar combates solo contra ameaças controladas por heurística tática local (`NpcTacticalAiService`) sobre um **clone descartável em memória** da ficha, reutilizando 100% das telas de VTT e regras sem consumir PV/PM permanentes da campanha.

### 1.2. Restrições Não-Funcionais (Quantificadas)
- **Escala inicial:** $1\text{ a }5$ mesas independentes (isoladas por rede local), com $1$ Mestre + até $6$ jogadores por sala ($N \le 7$ dispositivos conectados) e até $25$ combatentes simultâneos em grids de até $30 \times 30$ células.
- **Latência em LAN:** $p99 < 50\text{ ms}$ para confirmação e broadcast de comandos de turno/rolagem no Wi-Fi local; carregamento único de imagem de mapa $< 500\text{ ms}$.
- **Consistência:** **Single-Leader Linearizable (CP na sala)** para estado de combate/sessão (o Mestre ordena toda mutação com número de sequência monotônico `seq`); **isolamento estrito de propriedade** para atributos, classes e poderes do jogador.
- **Durabilidade e Resiliência:** RPO $= 0$ para eventos confirmados na mesa (persistência atômica a cada evento no dispositivo do Mestre); reconexão transparente após bloqueio de tela do smartphone em $< 2\text{ s}$.
- **Custo operacional:** `R$ 0` (zero servidores em nuvem, zero banco externo, funcionamento 100% offline/LAN).

### 1.3. Fora de Escopo (Out of Scope explícito nesta versão)
- **Servidor Relay em Nuvem / Mesas Remotas via Internet:** Adiado para etapa futura, porém desacoplado desde já atrás da interface `CombatSessionTransport`.
- **Edição Remota de Build pelo Mestre ("God Mode"):** O Mestre não altera atributos base, níveis de classe ou poderes escolhidos na ficha do jogador.
- **Iluminação Dinâmica, Raycasting de Visão Individual (Fog of War complexo) e Áudio/Voz:** Fora do VTT enxuto v1 (no máximo ocultação simples de tokens invisíveis/escondidos pelo Mestre).
- **Hospedagem de Sala no Flutter Web:** Navegadores não permitem abrir `HttpServer` TCP bruto (`dart:io`); o Host Mestre roda em Android, Windows ou Linux (clientes Web podem conectar à LAN via WS plano).
- **Motor Completo de Evolução (Níveis 2–20 e Multiclasse):** Sequenciado como a **Fase 2** imediatamente após a entrega deste módulo.

---

## 2. Estimativas de Escala — Back-of-the-Envelope (BOTEC)

**Premissas explícitas (por sala LAN):**
- $6$ clientes WebSocket simultâneos conectados ao aparelho do Mestre; sessão de $4\text{ horas}$ ($14.400\text{ s}$).
- Frequência média na mesa: $12\text{ ações/min} = 0{,}2\text{ comandos/s}$. Pico (movimentação passo a passo ou dano em área em vários alvos): $\text{fator de pico} = 25\times \Rightarrow 5\text{ comandos/s}$.

| Métrica | Cálculo / Premissa | Valor Estimado | Decisão Arquitetural Forçada |
|---|---|---|---|
| **QPS de Comandos (Escrita no Host)** | Média $0{,}2\text{ cmd/s}$; Pico $5\text{ cmd/s}$ | **$0{,}2\text{ a }5\text{ cmd/s}$** | Event loop único do Dart no celular do Mestre suporta $> 1.000\text{ req/s}$; dispensa filas externas ou múltiplos workers. |
| **Fan-out de Eventos WS (Egress)** | $5\text{ cmd/s (pico)} \times 6\text{ clientes}$ | **$30\text{ frames/s}$** (pico) | Broadcast direto em memória (`for (socket in clients)`) em $< 1\text{ ms}$. |
| **Tamanho dos Payloads JSON** | Delta WS: $\sim 1\text{ KB}$; Ficha: $\sim 18\text{ KB}$; Snapshot sala: $\sim 45\text{ KB}$ | **$1\text{ KB} \text{ a } 45\text{ KB}$** | JSON textual puro sobra em performance; dispensa Protobuf/binário nesta escala. |
| **Armadilha de Mídia (Mapa + Fotos)** | Mapa PNG/JPG $\approx 3\text{ MB}$; $6$ retratos $\approx 300\text{ KB}$ cada | **$\sim 5\text{ MB}$ brutos** | **Proibido trafegar imagens em Base64 no WebSocket** ($5\text{ MB} \times 6 = 30\text{ MB}$ por sync causaria *jank* e GC). Força endpoint HTTP separado com cache por hash SHA-256. |
| **Banda Total WS em 4h** | $0{,}2\text{ evt/s} \times 14.400\text{ s} \times 1\text{ KB} \times 6\text{ clientes}$ | **$\approx 17{,}3\text{ MB / 4h}$** ($\sim 1{,}2\text{ KB/s}$) | Consumo de bateria e Wi-Fi desprezível em celulares intermediários. |
| **Armazenamento por Sessão (Mestre)** | Snapshot ($45\text{ KB}$) + Log de $2.880$ eventos ($\sim 2{,}9\text{ MB}$) + Mapa ($3\text{ MB}$) | **$\approx 6\text{ MB / sessão}$** | $50$ sessões ocupam $\sim 300\text{ MB}$ locais; arquivos JSON atômicos + pasta de assets resolvem sem SGBD pesado. |

---

## 3. Contratos de Interface e Protocolo (API Design)

O segredo para suportar **Treino Offline**, **LAN Local** e **Futuro Relay em Nuvem** sem reescrever regras é a interface única `CombatSessionTransport`:

```
[CombateCubit / UI] ──(CommandEnvelope)──▶ [CombatSessionTransport] ──(EventEnvelope seq++)──▶ [CombateCubit / FichaSessionBridge]
                                                   │
                        ┌──────────────────────────┴──────────────────────────┐
                        ▼                                                     ▼
          LoopbackSessionTransport                              LanWebSocketClientTransport
     (RAM 0ms + NpcTacticalAiService)                        (WS JSON ↔ LanEmbeddedServer :47200)
```

### 3.1. Endpoints HTTP Locais no Host do Mestre (`dart:io` porta `:47200`)

1. **`POST /api/v1/session/join`** — Handshake, validação de PIN e envio inicial da ficha para avaliação:
   ```json
   // Request
   {
     "pin": "4812",
     "clientDeviceId": "dev_9a81f2",
     "playerName": "João",
     "portraitSha256": "e3b0c44298fc...",
     "characterSheet": { "schemaVersion": 2, "id": "char_01", "nome": "Artoniano", "...": "..." }
   }

   // Response 200 OK
   {
     "sessionId": "mesa_77a",
     "sessionToken": "st_hmac_88f1...",
     "assignedRole": "PLAYER",
     "wsEndpoint": "/api/v1/ws",
     "currentSeq": 18,
     "mapAssetSha256": "a94a8fe5ccb1..."
   }
   ```
2. **`GET /api/v1/assets/{sha256}` e `PUT /api/v1/assets/{sha256}`** — Transferência binária de mapas e retratos (limite rígido de `5 MB` por payload, cabeçalho `Cache-Control: public, max-age=31536000, immutable`).
3. **`GET /api/v1/ws?token={sessionToken}&lastSeq={n}`** — Upgrade para conexão WebSocket persistente com *heartbeat* (`pingInterval: 10s`).
4. **Envelope Padrão de Erro (estável em toda rota HTTP e `COMMAND_REJECTED` no WS):**
   ```json
   {
     "error": {
       "code": "OUT_OF_RANGE",
       "message": "Alvo está a 12m (alcance máximo da arma curta: 9m).",
       "commandId": "cmd_7c9e6679",
       "retryable": false
     }
   }
   ```

### 3.2. Contrato de Mensagens WebSocket e Idempotência

- **Comandos (`Client → Host`) — sempre com `commandId` (UUID v4) para idempotência:**
  ```json
  {
    "type": "COMMAND",
    "commandId": "cmd_7c9e6679-7425-40de-944b-e07fc1f90ae7",
    "expectedSeq": 18,
    "actorId": "char_01",
    "action": "EXECUTE_ATTACK",
    "payload": {
      "armaId": "espada_bastarda",
      "alvoId": "mon_lefou_02",
      "custoPmHabilidades": 1,
      "bonusSituacional": 2,
      "ataqueNaoLetal": false
    }
  }
  ```
  *Regra de Idempotência:* O `HostSessionCoordinator` mantém um `LinkedHashMap<String, EventEnvelope>` limitado aos últimos $500$ `commandId`s. Reenvios por instabilidade de Wi-Fi retornam o mesmo resultado já computado, **impedindo duplo gasto de PM ou duplo dano**.

- **Eventos Autoritativos (`Host → Broadcast Clientes`) — ordenados por `seq` monotônico:**
  ```json
  {
    "type": "EVENT",
    "seq": 19,
    "commandId": "cmd_7c9e6679-7425-40de-944b-e07fc1f90ae7",
    "event": "ATTACK_RESOLVED",
    "payload": {
      "atacanteId": "char_01",
      "alvoId": "mon_lefou_02",
      "rolagemAtaque": { "d20": 18, "bonus": 9, "total": 27, "critico": true, "acertou": true },
      "rolagemDano": { "dados": [8, 6], "bonus": 5, "rdAplicada": 2, "danoFinal": 17, "tipo": "corte" },
      "resourcePatches": [
        { "targetId": "char_01", "pvAtual": 24, "pmAtual": 5 },
        { "targetId": "mon_lefou_02", "pvAtual": 3, "estadoVida": "ativo" }
      ]
    }
  }
  ```

- **Catálogo Enxuto de Ações v1:**
  - *Sessão e Auditoria:* `SYNC_SHEET_SNAPSHOT`, `GM_REVIEW_SHEET` (`APPROVED` | `CHANGES_REQUESTED` + nota), `REQUEST_RESYNC`.
  - *Fluxo Tático:* `GM_LOAD_ENCOUNTER`, `ROLL_INITIATIVE`, `END_TURN`, `DELAY_INITIATIVE`, `MOVE_TOKEN`, `EXECUTE_ATTACK`, `CAST_SPELL_COMBAT`, `APPLY_MANUAL_PATCH` (dano/cura/condição arbitrada pelo Mestre).

---

## 4. Arquitetura de Alto Nível e Integração com o Código Existente

Consulte o diagrama completo em [`arquitetura-combate-vtt-mestre.html`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/documentation/diagrams/arquitetura-combate-vtt-mestre.html). Cada componente existe para atender um requisito explícito das seções §1–§2:

1. **Unificação `CalculoFichaService` + `CombateEngine` (Domínio Dart Puro):**
   - Atualmente, [`CombateEngine.executarAtaque`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/domain/services/combate_engine.dart#L94-L120) lê modificadores crus (`modLuta`), enquanto [`CalculoFichaService.prepararPreviewAtaqueArma`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/domain/services/calculo_ficha_service.dart#L766-L798) já resolve proficiência (`-2`), margem de ameaça, multiplicador de crítico e atributo de dano.
   - **Integração:** [`Combatente`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/domain/entities/combate/combatente.dart) passa a expor `List<PerfilAtaqueResolvido> ataquesResolvidos` e `int reducaoDeDano`. Para `CombatenteJogador`, ambos vêm diretamente do `CalculoFichaService`; para `CombatenteMonstro`, vêm da ficha de [`Monstro`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/domain/entities/combate/monstro.dart).
   - O `CombateEngine` valida automaticamente a distância em metros via [`Posicao2D.distanciaMetros`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/domain/entities/combate/grid_tatico.dart#L54) contra o alcance da arma/magia ($1{,}5\text{m}$, $9\text{m}$, $30\text{m}$, $90\text{m}$).
2. **`HostSessionCoordinator` (Autoridade Single-Leader):**
   - Classe Dart pura que recebe um `CommandEnvelope`, valida turno/alcance/PM no `CombateEngine`, incrementa `seq`, gera o `EventEnvelope` e persiste o snapshot. Roda **no aparelho do Mestre** (modo LAN) ou **em memória no aparelho do Jogador** (modo Arena Offline).
3. **`FichaSessionBridge` (Fronteira Segura com a Ficha do Jogador):**
   - Conecta o stream de `EventEnvelope` ao [`FichaCubit`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/presentation/controllers/ficha_cubit.dart) quando em sessão de campanha LAN, aplicando **exclusivamente** mutações transitórias de sessão (`pvAtual`, `pmAtual`, `efeitosTemporarios`). No modo Arena Offline, essa ponte fica desconectada do [`PersonagemStorageService`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/domain/services/personagem_storage_service.dart).
4. **Telas Novas / Reestruturadas (`lib/presentation/screens/`):**
   - **Acesso Rápido na Ficha ([`AbaGeralView`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/presentation/screens/ficha/aba_geral_view.dart)):** Seção *"Ataques Equipados"* em 1 toque (para mesas presenciais que quiserem apenas rolar ataque rápido sem abrir o grid) + botão no topo/menu *"Conectar à Mesa (LAN)"* / *"Testar em Arena (Offline)"*.
   - **Lobby & Painel do Mestre (`screens/mestre/`):** Tela para criar/retomar mesa LAN, exibir QR Code/PIN, inspecionar fichas conectadas (reutilizando widgets read-only da ficha com badge de aprovação), gerenciar Bestiário/NPCs e controlar o `VttBoardWidget`.
   - **`VttBoardWidget` Compartilhado (`widgets/vtt/`):** `InteractiveViewer` (pinça/zoom suave em celular e mouse no desktop) renderizando imagem de fundo opcional + `CustomPainter` para o grid T20, células alcançáveis ([`MovimentoEngine`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/domain/services/movimento_engine.dart)), obstáculos, régua de alcance e tokens.

---

## 5. Modelo de Dados e Persistência

Sem banco externo pesado (YAGNI para $< 5\text{ cmd/s}$), mantendo arquivos JSON versionados com chaves explícitas:

1. **Ficha do Jogador (`app_flutter/personagens/personagem_{characterId}.json`):**
   - **Chave primária:** `characterId` (UUID).
   - **Evolução de contrato:** Adicionar campo `"schemaVersion": 2` no [`PersonagemStorageService`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/domain/services/personagem_storage_service.dart) com migração transparente de arquivos v1 (onde `schemaVersion == null`).
2. **Estado da Mesa do Mestre (`app_flutter/mesas/mesa_{sessionId}.json`):**
   - **Chave primária:** `sessionId`.
   - **Conteúdo:** `{ schemaVersion: 1, sessionId, nomeMesa, pinAtual, currentSeq, gridMapa, backgroundAssetSha256, combatState, fichasEspelhadasReadOnly, aprovacoesPorPersonagemId, ultimosEventos[200] }`.
   - **Durabilidade atômica:** Toda gravação escreve primeiro em `mesa_{sessionId}.json.tmp` e executa `File.rename` atômico no sistema de arquivos POSIX/NTFS, eliminando corrupção de JSON caso a bateria acabe durante o salvamento.
3. **Cache de Mídia (`app_flutter/assets_cache/{sha256}.bin`):**
   - **Chave primária:** Hash `SHA-256` do conteúdo binário da imagem (desduplicação automática e invalidação zero: mudou o mapa, mudou o hash).

---

## 6. Decisões de Engenharia e Trade-offs

| Decisão | O que Resolve (Solves) | O que Agrava / Custa (Worsens) | Mudar esta Decisão Quando (Breaking Point) |
|---|---|---|---|
| **1. Servidor WS + HTTP embutido no aparelho do Mestre (`dart:io`)** | Custo `R$ 0`, latência LAN $< 10\text{ ms}$, funciona sem internet (sítio/evento/hotspot local), zero cadastro/login externo. | Não atravessa redes distintas pela internet (NAT/CGNAT); Host não pode rodar em navegador Web; depende da bateria/OS do Mestre. | Quando o grupo quiser jogar **remoto via Discord** → implementar `CloudRelaySessionTransport` plugado na mesma interface `CombatSessionTransport`. |
| **2. Autoridade Single-Leader no Mestre (CP na sala)** | Ordem única de iniciativa, posições sem colisão e saldo exato de PV/PM (`seq++`), eliminando *split-brain* e disputas de regra. | O dispositivo do Mestre é o SPOF do combate ao vivo; se o Mestre cair, a resolução automática no VTT pausa até reconectar. | Se no futuro houver campanhas assíncronas ("Play-by-Post" sem Mestre online) → persistir fila de comandos num servidor sempre ativo. |
| **3. Mestre Read-Only na Build + Autoritativo na Sessão** | Permite ao Mestre auditar combos/regras e conduzir PV/PM/condições sem risco de corromper ou sobrescrever a ficha permanente do jogador. | Se o Mestre quiser dar um item permanente ou XP, envia uma "Proposta de Recompensa" que o jogador aceita em 1 toque (1 passo extra fora de combate). | Se mesas iniciantes pedirem edição assistida pelo Mestre → adicionar toggle explícito no celular do jogador: *"Permitir edição temporária pelo Mestre"*. |
| **4. WebSocket p/ Deltas JSON + HTTP p/ Imagens (SHA-256)** | Mantém frames WS minúsculos ($< 2\text{ KB}$), zero *jank* na UI e cache em disco automático de mapas de vários megabytes. | Exige rotear tanto HTTP quanto Upgrade WS na mesma porta `:47200` do `HttpServer`. | Apenas ao escalar para centenas de salas na nuvem → mover `/assets` para Object Storage + CDN (`Cloudflare R2` / `Firebase Storage`). |
| **5. `LoopbackSessionTransport` p/ Arena Offline vs. NPCs** | 100% de reuso do motor tático, validações e tela VTT entre modo solo e multiplayer; zero risco de gastar recursos reais da ficha (clone em RAM). | Exige escrever uma heurística tática mínima (`NpcTacticalAiService`: mover até alcance e usar melhor ataque) para que os NPCs reajam sozinhos. | Se a IA tática ficar complexa demais com magias avançadas → adicionar modo "Controle Manual dos Dois Lados" na Arena de Treino para testar interações específicas. |

---

## 7. Modos de Falha, Degradação Graciosa e Recuperação

1. **Bloqueio de Tela do Celular do Jogador / Oscilação de Wi-Fi:**
   - *O que acontece:* Android/iOS suspende sockets em background após alguns segundos de tela apagada.
   - *Mitigação e Recuperação (sem Retry Storm):* Ao retornar ao foreground (`AppLifecycleState.resumed`), o `LanWebSocketClientTransport` reconecta usando *exponential backoff com jitter aleatório* ($300\text{ ms} \to 600\text{ ms} \to 1{,}2\text{ s} \to \text{teto } 4\text{ s}$, máx. $6$ tentativas automáticas antes de botão manual), enviando `lastSeq`. Se `currentSeq - lastSeq <= 200`, o Mestre envia apenas o *replay* dos eventos faltantes; caso contrário, envia `FULL_SNAPSHOT` ($45\text{ KB}$).
   - *Degradação Graciosa:* Enquanto desconectado, o jogador vê um chip discreto `"Reconectando à Mesa..."` e **continua com 100% da ficha local desbloqueada** para consultar magias, perícias e rolar dados localmente na mesa física.
2. **Suspensão ou Queda de Bateria no Dispositivo do Mestre (SPOF da Sala):**
   - *Mitigação:* Ativar `Wakelock` opcional enquanto a tela do VTT do Mestre estiver aberta + gravação atômica de `mesa_{sessionId}.json` a cada mutação confirmada.
   - *Recuperação:* Se o app do Mestre fechar ou reiniciar, tocar em **"Retomar Sala"** reabre a porta `:47200` com o mesmo `sessionId` e `currentSeq` em $< 100\text{ ms}$; os celulares dos jogadores reconectam automaticamente e retomam o turno exato onde pararam.
3. **Wi-Fi Público / Universitário com *AP Client Isolation*:**
   - *O que acontece:* Roteadores públicos bloqueiam tráfego direto entre dois dispositivos na mesma rede Wi-Fi (tanto broadcast UDP quanto TCP direto falham com timeout de `3s`).
   - *Degradação / Contorno Operacional:* O app detecta timeout na porta `:47200` e exibe instrução clara na tela de conexão: *"Roteador com isolamento entre aparelhos detectado. Ative o Roteador/Hotspot Wi-Fi do celular do Mestre (não consome franquia 4G/internet) e conectem nele."*
4. **Duplo Toque Acidental em "Atacar / Lançar Magia" sob Lag:**
   - *Mitigação:* UI desabilita o botão de confirmação enquanto aguarda `ACK` do `commandId` (timeout local de `3s`) + deduplicação de `commandId` no `HostSessionCoordinator`. Zero chance de descontar PM em dobro.

---

## 8. Evolução de Escala e Varredura de Cobertura (Coverage Sweep)

### 8.1. Próximo Degrau de Escala (`scaling-evolution`)
- **Gargalo atual deliberado:** A topologia LAN exige que todos estejam no mesmo Wi-Fi/Hotspot (limite físico de roteador doméstico: $\sim 10\text{–}20$ dispositivos).
- **Como evoluir para Mesas Remotas (Discord) e 100+ salas simultâneas:**
  1. Extrair `HostSessionCoordinator` + `CombateEngine` (já em Dart puro!) para rodar dentro de um servidor leve em nuvem (`dart_frog` / `shelf` em um único container de `512 MB RAM`, que suporta facilmente $> 200$ salas simultâneas de $6$ jogadores $\approx 1.200$ sockets ociosos e $\sim 40\text{ evt/s}$ agregados).
  2. Implementar `CloudRelaySessionTransport` implementando `CombatSessionTransport` — **zero alteração** no `CombateCubit`, `VttBoardWidget`, `FichaCubit` ou regras de T20!

### 8.2. Varredura de Cobertura de Blocos (`Coverage Sweep`)
- **Objetos Grandes / Mídia (`blob-store`):** Endereçado via servidor HTTP local por hash `SHA-256` separado do WebSocket (§2, §3.1, §5).
- **Geração de IDs (`sequencer`):** Endereçado — `UUID v4` gerado no cliente para `commandId`/`characterId` + inteiro monotônico `seq` (`1, 2, 3...`) emitido pelo líder único da sala.
- **Observabilidade (`observability`):** Endereçado proporcionalmente — badge de status (`Online / Reconectando`) e RTT (`ms` do ping/pong) por jogador no Painel do Mestre + exportação do log de eventos JSON da sessão para depuração de cálculos.
- **DNS, Load Balancing, CDN, Sharded Counters, Distributed Search e Task Scheduling:** Explicitamente adiados (YAGNI) — topologia local de $1\text{–}6$ clientes resolve endereço via QR Code/IP local sem infraestrutura intermediária.

---

## 9. Roadmap de Implementação e Ponte para a Fase 2 (Evolução 2–20)

Para entregar valor contínuo sem quebrar os **149 testes existentes**:

- **Subfase 1A — Unificação do Domínio de Combate + Ataque Rápido na Ficha:**
  - Conectar [`CalculoFichaService.prepararPreviewAtaqueArma`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/domain/services/calculo_ficha_service.dart#L766-L798), Redução de Dano (RD) e validação de alcance T20 ao [`CombateEngine`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/domain/services/combate_engine.dart). Adicionar card de **Ataques em 1 Toque** na ficha para uso imediato.
- **Subfase 1B — Protocolo `CombatSessionTransport` + `HostSessionCoordinator` + Arena Offline (Sandbox):**
  - Criar os envelopes `Command/Event`, o transporte `LoopbackSessionTransport`, a IA tática básica `NpcTacticalAiService` e o `VttBoardWidget` 2D enxuto (imagem de fundo, terreno, alcance, iniciativa) operando sobre clone descartável da ficha.
- **Subfase 1C — Painel do Mestre + Avaliador de Fichas + `LanEmbeddedServer` (`dart:io`):**
  - Implementar o servidor HTTP+WS local na porta `:47200`, entrada via PIN/QR Code, tela de inspeção/aprovação de fichas pelo Mestre, cache HTTP de mapas por `SHA-256` e persistência atômica `MesaStorageService`.
- **Subfase 1D — `FichaSessionBridge` + Testes de Estresse de Reconexão:**
  - Sincronizar PV/PM/Condições ao vivo com o [`FichaCubit`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/presentation/controllers/ficha_cubit.dart) e cobrir reconexão `lastSeq` e idempotência `commandId` com testes automatizados.
- **Fase 2 (Próximo Marco após Combate) — Motor Completo de Evolução (Níveis 2–20):**
  - Fluxo completo de Level Up, Multiclasse, Poderes Gerais + Poderes da Tormenta no level-up, Magias de 2º a 5º círculos e Itens Superiores/Mágicos (cujos modificadores alimentarão automaticamente o `CalculoFichaService` e, por tabela, o VTT e o Avaliador do Mestre!).

---

## 10. Autoavaliação de Qualidade do Design (`Score & Diagnose`)

| Dimensão | Nota (0–5) | Justificativa e Diagnóstico |
|---|---|---|
| **Fundamentos Distribuídos** | **5/5** | Posição CAP explícita (Single-Leader CP para combate, isolamento local para build, `seq` monotônico e idempotência por `commandId`). |
| **Domínio dos Building Blocks** | **5/5** | Separação deliberada entre WS JSON ($< 2\text{ KB}$) e HTTP Assets (`SHA-256`) evitando bloqueio de event loop e GC em mobile. |
| **Escopo e Requisitos** | **5/5** | Requisitos funcionais, metas quantificadas e exclusões explícitas alinhados antes do desenho. |
| **Articulação de Trade-offs** | **5/5** | Todas as 5 decisões estruturais documentam ganho, custo real e gatilho objetivo de mudança. |
| **Senso de Escala (Números)** | **5/5** | Estimativas completas com unidades (QPS, fan-out, banda em 4h e disco) justificando zero infraestrutura externa. |
| **Modos de Falha e Degradação** | **4.5/5** | Reconexão com jitter + replay `lastSeq`, gravação atômica e fallback de *AP Isolation* cobertos. **Ponto mais fraco atual:** caso o celular do Mestre quebre permanentemente no meio da sessão, a migração de Host para outro aparelho exige exportar o arquivo de sessão manualmente (mitigável futuramente replicando o último `SessionSnapshot` passivamente nos clientes para "Promover Novo Mestre"). |
| **Colaboração e Evolução** | **5/5** | Adaptação direta às restrições de LAN, uso em grupo fechado e preparação limpa para a Fase 2 (Evolução). |

**Total: 34.5 / 35** — *Dimensão a elevar se necessário no futuro: replicação passiva do `SessionSnapshot` nos clientes para failover de Mestre em 1 clique.*
