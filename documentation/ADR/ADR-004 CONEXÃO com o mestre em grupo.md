# ADR-004: Conexão LAN entre Mestre e Jogadores (servidor embutido, protocolo e Android)

- **Status:** Proposto
- **Data:** 3 de novembro de 2026
- **Depende de:** ADR-002 rev. 2 (`CombatSessionTransport` e coordenador) e ADR-003 (`MesaHostFacade`, visibilidade e projeção)
- **Substitui:** as seções de rede da rev. 1 do ADR-002 (endpoints, protocolo e modos de falha)

> Os pontos de plataforma Android foram conferidos em documentação e relatos públicos em 3/11/2026 (marcados como [fonte N], lista no final). O restante é projeto. O código do projeto não foi revisado.

---

## 1. Contexto e decisão

O aparelho do mestre é o host autoritativo: ele roda um servidor HTTP + WebSocket (`dart:io`) na rede local, e os jogadores se conectam a ele. Não há internet, nuvem nem conta externa.

**Decisões:**

1. Um único servidor `dart:io` (HTTP com upgrade para WebSocket) na porta 47200 por padrão (configurável; o QR sempre informa a porta).
2. Protocolo JSON versionado, com `seq` global, entrega por destinatário com cadeia `prev` e **variantes projetadas gravadas no log** (nada de reprojetar no replay).
3. Autenticação em dois passos: PIN para entrar, token opaco por dispositivo depois.
4. Mídia por HTTP com ACL, fora do WebSocket.
5. No Android, o host sobrevive em segundo plano por meio de um foreground service, e a rede é validada em spikes antes de codar.
6. O cliente sempre reconecta, e **o host vence** em qualquer divergência de estado.

---

## 2. Requisitos

### 2.1 Funcionais

- **RF-L1** Abrir e retomar uma sala (IP, porta, PIN e QR).
- **RF-L2** Entrar escaneando o QR ou digitando IP e PIN, e enviar a ficha para revisão.
- **RF-L3** Canal em tempo real de comandos e eventos, com projeção por papel.
- **RF-L4** Reconexão transparente após bloqueio de tela ou oscilação de Wi-Fi.
- **RF-L5** Transferência de mapas, retratos e imagens de handout.
- **RF-L6** Entrega dirigida (handouts e notas) a destinatários, com pendência quando offline.
- **RF-L7** Persistência no host e retomada da sala.
- **RF-L8** Diagnóstico de rede legível.

### 2.2 Não funcionais

| Meta | Valor | Observação |
| --- | --- | --- |
| Escala | 1 mestre + até 6 jogadores; até 25 combatentes; grid até 30×30 | Mesma da rev. 1 |
| Latência percebida | Comando → evento: p95 < 300 ms e p99 < 1 s em hotspot | Substitui o p99 < 50 ms da rev. 1, que não é garantível com Wi-Fi em economia de energia e é desnecessário em jogo por turnos. A medir |
| Reconexão | Online em < 3 s na média, se o host estiver acessível | A medir na matriz de aparelhos |
| Payloads | Frame WS ≤ 64 KB; snapshot ≈ 50 KB; mapa ≤ 5 MB; retrato ≤ 1 MB | |
| Durabilidade | Nenhum evento confirmado se perde com kill do processo; em queda de energia, no máximo o evento em voo | Ver seção 9 |
| Custo | R$ 0, sem servidor externo | |

### 2.3 Fora de escopo

- Internet, relay em nuvem e mesas remotas.
- Wi-Fi Direct e Nearby.
- TLS na v1 (decisão registrada na seção 10, com caminho para v2).
- Cliente Web (página HTTPS não abre `ws://`, e `dart:io` não compila para Web).
- Failover automático do mestre.

---

## 3. Topologias de rede

| Cenário | Funciona? | Observações |
| --- | --- | --- |
| A. Hotspot do celular do mestre | Sim (recomendado) | Não precisa de internet. O IP e o nome da interface variam por aparelho. Ver roteamento na seção 7.3 |
| B. Wi-Fi doméstico | Sim | O IP por DHCP pode mudar entre sessões; ao retomar a sala o QR pode precisar ser lido de novo |
| C. Wi-Fi público ou universitário com isolamento de clientes | Não | O app detecta o timeout do `/hello` e orienta a usar o cenário A |
| D. Dados móveis (CGNAT) | Não | Exige relay, fora de escopo |
| E. Wi-Fi Direct ou Nearby | Não na v1 | Alternativa futura se o hotspot for um problema |
| F. Host em desktop (Linux ou Windows) | Sim | Ótimo para desenvolvimento e para mestres com notebook |

---

## 4. Pilha técnica

| Necessidade | Escolha | Detalhe |
| --- | --- | --- |
| Servidor HTTP e WS | `dart:io`: `HttpServer` + `WebSocketTransformer.upgrade` | Sem dependências; roteador mínimo próprio. Alternativa: `shelf`, `shelf_router` e `shelf_web_socket`, se o roteamento crescer |
| Cliente HTTP e WS | `HttpClient` e `WebSocket.connect` | Aceitam cabeçalhos (`Authorization`) e `pingInterval` |
| Modelos e JSON | Sealed classes com `toJson`/`fromJson` (manual ou `json_serializable`) | Pattern matching exaustivo sobre comandos e eventos |
| IDs e tokens | `uuid` (v4) para `commandId`; `Random.secure()` para tokens | |
| Hash | `crypto` (SHA-256 em streaming para assets) | |
| QR | `qr_flutter` (gerar) e `mobile_scanner` (ler) | A leitura exige permissão de câmera |
| Permissões | `permission_handler` | Câmera, notificações e, com `targetSdk` 37, rede local |
| Serviço em primeiro plano | `flutter_foreground_task` ou serviço Kotlin próprio | Tipo definido no spike S5 |
| Tela ligada | `wakelock_plus` | Só mantém a tela; não substitui o serviço |
| Rede | `NetworkInterface.list()`, `connectivity_plus` e um MethodChannel Kotlin | Descoberta de IPs, mudança de rede e `bindProcessToNetwork` |
| Persistência | `path_provider`, JSON e JSONL | |
| Imagens | `image_picker` ou `file_picker`; `image` (em isolate) ou `flutter_image_compress` | Redimensionar antes de enviar |
| Estado | `flutter_bloc` | Já em uso |
| Testes | `flutter_test`, `mocktail`, `fake_async` | Servidor real em loopback |

Confirmar versões e manutenção de cada pacote no pub.dev no momento da implementação.

---

## 5. Protocolo

### 5.1 Versionamento e handshake

- `protocolVersion` (inteiro; incompatível = rejeita), `rulesVersion` (identifica a versão dos dados e regras, por exemplo um hash dos dados embutidos) e `appVersion` (informativo).
- `GET /api/v1/hello` (sem autenticação, com rate limit) devolve `{ protocolVersion, minProtocol, rulesVersion, nomeMesa, exigePin }`. O cliente compara **antes** de pedir o PIN e, se incompatível, informa qual lado precisa atualizar.

### 5.2 Entrada na sala

```
POST /api/v1/session/join
{ pin: '482910', deviceId: 'dev_9a81f2', playerName: 'João', protocolVersion: 1, rulesVersion: 'r42',
  ficha: FichaSnapshot,            // opcional, ≤ 64 KB
  retratoSha256: 'e3b0c442...' }   // opcional

200 -> { sessionId, playerId, sessionToken, role: 'PLAYER', wsPath: '/api/v1/ws', currentSeq, statusRevisao }
Erros: PIN_INVALID (401), RATE_LIMITED (429), VERSION_MISMATCH (426), ROOM_FULL (409)
```

- **Token:** 256 bits aleatórios (`Random.secure()`), guardado no host apenas como hash SHA-256 em `tokens.json`, vinculado a `deviceId` e `playerId`, revogável pelo mestre (“Expulsar”) e **persistido** para sobreviver a “Retomar sala”. Isso corrige a rev. 1, que não dizia onde ficava o segredo do HMAC.
- **PIN:** 6 dígitos por padrão (mínimo 4, configurável). Cinco tentativas erradas por IP em 60 s bloqueiam o IP por 60 s (progressivo). Comparação em tempo constante. O mestre pode girar o PIN a qualquer momento sem invalidar tokens existentes. O PIN pode ficar fora do QR (“exigir digitar”).

### 5.3 Envelopes (notação ilustrativa)

```
Cliente -> Host
{ v: 1, type: 'COMMAND', commandId: 'uuid', actorId: 'char_01', action: 'EXECUTE_ATTACK', turnRev: 7, payload: {...} }
{ v: 1, type: 'RESYNC', lastApplied: 118 }
{ v: 1, type: 'PING', t: 12345 }
{ v: 1, type: 'ACK_READ', kind: 'HANDOUT', id: 'h_3' }

Host -> Cliente
{ v: 1, type: 'WELCOME', sessionId, playerId, currentSeq }
{ v: 1, type: 'EVENT', seq: 120, prev: 118, commandId, event: 'ATTACK_RESOLVED', payload: {...} }
{ v: 1, type: 'SNAPSHOT', seq: 120, state: {...} }      // já projetado para este jogador
{ v: 1, type: 'REJECTED', commandId, error: { code: 'OUT_OF_RANGE', message, retryable: false } }
{ v: 1, type: 'PONG', t: 12345 }
{ v: 1, type: 'BYE', code: 4003, reason: 'ROOM_CLOSED' }
```

Códigos de fechamento do WebSocket: **4001** token inválido ou revogado; **4002** versão incompatível; **4003** sala encerrada; **4004** substituída por nova conexão do mesmo dispositivo; **4008** limite de taxa; **4009** consumidor lento (precisa de resync).

### 5.4 Ordem, projeção e a cadeia `prev`

**Problema:** com projeção por destinatário, cada cliente recebe só um subconjunto dos eventos. O `seq` global fica com buracos e o cliente não distingue perda de filtragem.

**Solução:**

- O coordenador emite o `seq` global monotônico.
- Para cada cliente, o host guarda o último `seq` entregue. Cada `EVENT` leva `prev`, o último `seq` entregue **a esse cliente**. O cliente só aplica se `prev == lastApplied`; senão envia `RESYNC`.
- **Variantes gravadas no log:** ao emitir um evento, o coordenador calcula uma vez as variantes e as grava no `EventRecord`. O replay entrega a variante gravada e **nunca reprojeta** com o estado atual, o que evita vazamento quando a visibilidade muda depois.

```dart
class EventRecord {
  final int seq; final String? commandId; final Audience audience;
  final Map<String, Map<String, Object?>> variantes;   // 'gm', 'player', 'player:{id}'
}
sealed class Audience {}   // Todos | SomenteMestre | Jogadores(ids)
```

- `SNAPSHOT` é a projeção do estado atual para o papel do cliente, com o `seq` corrente. O cliente descarta o estado local e reinicia a cadeia.

### 5.5 Idempotência e comandos

- Todo comando traz `commandId`. O coordenador (fila serial, ADR-002) guarda `commandId → seq`, e um reenvio devolve o mesmo resultado sem reexecutar. O índice (janela das últimas ~1.000 entradas) é reconstruído do log ao retomar a sala.
- `turnRev` substitui o `expectedSeq` da rev. 1. Só os comandos que dependem do turno carregam o campo, e um valor defasado gera `STALE_TURN` (retentável após resync). Assim, ações concorrentes que não dependem do turno não são rejeitadas à toa.
- UI: o botão de ação fica desabilitado até chegar o evento do `commandId` (timeout de 3 s, com a mensagem “sem resposta, tentar de novo?”).

### 5.6 Limites, consumidor lento e heartbeat

- **Por conexão:** frame ≤ 64 KB; 20 comandos/s (rajada de 40); fila de saída ≤ 200 mensagens. Estourou: fecha com 4009, e o cliente reconecta e ressincroniza por snapshot.
- **Conexões simultâneas:** máximo de 12 (margem para reconexões fantasmas).
- **Heartbeat:** `pingInterval` de 10 s no `WebSocket`, em host e cliente. Um `PING`/`PONG` de aplicação a cada 15 s mede o RTT com `Stopwatch` (nunca com relógio de parede).
- Uma conexão nova do mesmo `deviceId` **substitui** a anterior (a antiga fecha com 4004). Um socket morto pode levar até ~20 s para ser detectado no host, e a regra “última conexão vence” elimina o efeito disso.

### 5.7 Reconexão (cliente)

Máquina de estados: `Desconectado → Descobrindo → Conectando → Autenticando → Sincronizando → Online`.

```dart
Duration _espera(int tentativa) {
  final base = const [300, 600, 1200, 2400, 4000][tentativa.clamp(0, 4)];
  return Duration(milliseconds: base + _rng.nextInt(base ~/ 2));    // jitter
}
```

- **Sem limite de tentativas enquanto o app estiver em foreground.** A rev. 1 parava em 6 tentativas (~12 s), menos do que leva para o mestre reabrir o app. Em segundo plano o cliente pausa e retoma em `AppLifecycleState.resumed`.
- Ao voltar ao foreground, valida o socket com um `PING` antes de confiar nele.
- Depois do `WELCOME`, o cliente envia `RESYNC` com o `lastApplied`. O host responde com replay (se estiver na janela do log) ou com `SNAPSHOT`.
- A UI mostra o chip “Reconectando à mesa…”, e a ficha continua consultável.
- **PV e PM:** durante a sessão a ficha local fica travada para esses campos (“controlado pela mesa”). Offline, o jogador pode consultar e rolar dados, mas, ao reconectar, **o valor do host vence**, com aviso se houve divergência.

---

## 6. Endpoints HTTP

| Método e caminho | Autenticação | Limite de corpo | Função |
| --- | --- | --- | --- |
| `GET /api/v1/hello` | Nenhuma (rate limit por IP) | n/a | Versões e nome da mesa |
| `POST /api/v1/session/join` | PIN | 64 KB | Entrada e envio da ficha |
| `GET /api/v1/ws` | Bearer | upgrade | Canal em tempo real |
| `GET /api/v1/assets/{sha256}` | Bearer + ACL | n/a | Mapas, retratos e imagens de handout, com `Cache-Control: private, max-age=31536000, immutable` |
| `PUT /api/v1/assets/{sha256}` | Bearer (jogador) | 1 MB | Somente o retrato do próprio jogador |
| `POST /api/v1/session/leave` | Bearer | 1 KB | Saída voluntária |

Regras:

- `sha256` só aceita 64 caracteres hexadecimais, o que evita path traversal.
- No `PUT`, o host calcula o SHA-256 do corpo em streaming, **aborta ao passar do limite** (sem bufferizar tudo), compara com o caminho e valida o tipo pela assinatura do arquivo (PNG, JPEG ou WebP). Qualquer divergência responde 400.
- No `GET`, a ACL vale por tipo: mapa e retratos para todos os jogadores da mesa; imagem de handout só para os destinatários (ADR-003). Mapas e imagens de handout pertencem ao host, então o mestre nunca faz `PUT`.
- Envelope de erro padrão: `{ error: { code, message, commandId?, retryable } }`.

---

## 7. Android: o que a plataforma exige

### 7.1 Manifest (esboço)

```xml
<uses-permission android:name='android.permission.INTERNET'/>
<uses-permission android:name='android.permission.ACCESS_NETWORK_STATE'/>
<uses-permission android:name='android.permission.ACCESS_WIFI_STATE'/>
<uses-permission android:name='android.permission.CAMERA'/>                  <!-- QR -->
<uses-permission android:name='android.permission.POST_NOTIFICATIONS'/>     <!-- notificação do serviço (Android 13+) -->
<uses-permission android:name='android.permission.WAKE_LOCK'/>
<uses-permission android:name='android.permission.FOREGROUND_SERVICE'/>
<uses-permission android:name='android.permission.FOREGROUND_SERVICE_...'/> <!-- conforme o tipo escolhido -->
<!-- somente ao subir o targetSdk para 37 -->
<uses-permission android:name='android.permission.ACCESS_LOCAL_NETWORK'/>
```

### 7.2 Serviço em primeiro plano (host)

- Apps que miram Android 14 precisam declarar o tipo do serviço no manifesto; sem isso, o sistema lança `MissingForegroundServiceTypeException` em `startForeground()` [fonte 2].
- Nenhum tipo é encaixe perfeito para “servidor de jogo”. Candidatos: `connectedDevice` (tem pré-requisitos de execução), `specialUse` (exige justificativa na Play Store) e `dataSync`. A decisão sai do spike S5 e, se o app for publicado na Play Store, da política vigente.
- O plugin `flutter_foreground_task` implementa o serviço com comunicação bidirecional entre serviço e UI [fonte 6], e o serviço roda numa isolate própria. Opções: **(a)** servidor na isolate principal, com o serviço só mantendo o processo vivo; **(b)** servidor dentro da isolate do serviço. Recomendação da v1: (a), pela simplicidade de compartilhar estado. Revisar no spike.
- Notificação persistente: “Mesa {nome}: {n} jogadores conectados”, com a ação “Encerrar sala”.
- `stopWithTask`: na v1, remover o app dos recentes encerra a sala (evita servidor zumbi). “Retomar sala” cobre a volta.
- `WifiLock` (alto desempenho ou baixa latência) via MethodChannel enquanto a sala estiver aberta, e `wakelock_plus` com a tela do painel aberta.
- Fabricantes com gerenciador de bateria agressivo (Xiaomi, Samsung, Motorola, comuns no Brasil) podem matar o processo mesmo com o serviço. Uma tela de ajuda orienta a retirar o app da otimização de bateria. Se o app for publicado na Play Store, evitar pedir `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` diretamente (política restritiva; verificar).

### 7.3 Rede

- **Wi-Fi sem internet.** Desde o Lollipop, o Android não roteia requisições para uma rede Wi-Fi sem conectividade com a internet, e a API recomendada para forçar o tráfego do app para ela é `bindProcessToNetwork` [fonte 3]. O cenário crítico é o hotspot do mestre sem dados móveis e jogadores com dados ligados. Implementação: MethodChannel `t20/net` em Kotlin; `requestNetwork` com `TRANSPORT_WIFI`; em `onAvailable` (responder ao canal uma única vez), chamar `bindProcessToNetwork(network)`; `bindProcessToNetwork(null)` ao sair da sala. Efeito colateral: durante a sessão, todo o tráfego do processo usa o Wi-Fi (aceitável aqui). É um esboço a validar no spike S2, e o comportamento varia por fabricante.
- **Descoberta dos IPs do host.** `NetworkInterface.list(type: InternetAddressType.IPv4)`, mantendo só endereços privados (10/8, 172.16/12 e 192.168/16) e descartando `lo` e interfaces de dados móveis (`rmnet*`, `ccmni*`). O nome da interface do hotspot varia por aparelho (por exemplo `wlan1`, `ap0`, `swlan0`), então **não** se assume um IP fixo: listam-se todos e todos vão no QR.
- **Cleartext (`ws://` e `http://`).** A documentação do Flutter diz que IPs específicos não são aceitos na política de rede; a única forma de liberar IPs é permitir cleartext no app todo [fonte 4]. Na prática, relatos de um fórum da comunidade indicam que o `dart:io`, por usar sockets crus, não é afetado pelo `usesCleartextTraffic` [fonte 5]. Se algum plugin baseado em OkHttp, cronet ou WebView falar com o host, será preciso liberar. Confirmar em build release (S2).
- **Permissão de rede local (Android 17).** Para apps com `targetSdk` 37 ou superior, o acesso à rede local fica bloqueado por padrão e exige a permissão `ACCESS_LOCAL_NETWORK` em runtime; apps com target abaixo de 37 recebem a concessão implícita [fonte 1]. Host e cliente precisarão solicitá-la quando o `targetSdk` subir. Prever uma tela explicando o motivo antes do pedido e, se negada, o diagnóstico deve mostrar “rede local bloqueada”.

### 7.4 Ciclo de vida

| Evento | Host | Cliente |
| --- | --- | --- |
| App em segundo plano | O serviço mantém o servidor; notificação visível | Pausa a reconexão; ao voltar, `PING` e resync |
| Tela bloqueada | Serviço + `WifiLock` | O socket pode cair; reconecta no resume |
| Recriação da Activity (rotação) | O estado vive no coordenador, fora da árvore de widgets | Idem |
| Remover dos recentes | Encerra a sala (v1) | Reconecta ao reabrir |
| Mudança de rede (`connectivity_plus`) | Recalcula IPs e atualiza QR e diagnóstico | Volta ao estado `Descobrindo` |

---

## 8. Formato do QR Code e carga de conexão

O QR Code gerado pelo Host encapsula os dados para descoberta e conexão sem necessidade de resolução de nomes mDNS ou DNS local.

### 8.1 Estrutura da URI

```text
t20mesa://join?v=1&sid=<sessionId>&name=<nomeMesaUrlEncoded>&ips=<ip1>,<ip2>&port=47200&pin=<pinOpcional>
```

- **Parâmetros:**
  - `v`: Versão do esquema do QR Code (inteiro, padrão `1`).
  - `sid`: Identificador da sessão ativa (UUID v4).
  - `name`: Nome da mesa sanitizado (UTF-8, codificado para URI).
  - `ips`: Lista separada por vírgulas de endereços IPv4 privados válidos descobertos no host (ex.: `192.168.43.1,192.168.1.15`).
  - `port`: Porta do servidor (padrão `47200`).
  - `pin`: PIN numérico (opcional; omitido se o mestre optar por "Exigir digitação").

### 8.2 Fluxo de descoberta rápida (cliente)

1. O cliente faz o scan do payload pelo leitor de QR.
2. Dispara requisições paralelas `GET http://<ip>:<port>/api/v1/hello` com timeout individual curto (800 ms) para todos os IPs informados.
3. A primeira rota que responder `200 OK` com `sessionId` coincidente é salva como a rota ativa preferencial.
4. Caso nenhuma rota responda dentro do limite, o app abre o fallback manual para conferência de IP e diagnóstico.

---

## 9. Persistência e durabilidade no host

O host opera com persistência baseada em log de eventos sequencial para garantir que uma sessão possa ser retomada após um kill do processo ou reinicialização.

### 9.1 Estrutura em disco

Localizado no diretório da aplicação (`getApplicationDocumentsDirectory()` do `path_provider`):

```text
mesa_sessions/<sessionId>/
  ├── session.json      # Metadados da mesa (PIN hash, regras, nome, porta)
  ├── tokens.json       # deviceId -> hash do sessionToken + playerId
  ├── events.jsonl      # Log sequencial (append-only) de EventRecords com variantes
  ├── snapshot.json     # Último snapshot de estado consolidado
  └── assets/           # Imagens cacheadas e persistidas nomeadas por <sha256>
```

### 9.2 Garantias e fluxo de recuperação

- **Log append-only (`events.jsonl`):** Cada evento processado pelo coordenador gera uma linha JSON terminada em `\n` com flush síncrono (`flush: true` em `dart:io`).
- **Snapshots periódicos:** A cada 100 eventos gravados, um novo `snapshot.json` é gravado atomicamente (escrita em arquivo temporário `.tmp` seguida de renomeação).
- **Ao retomar a sala:**
  1. Carrega `snapshot.json`.
  2. Executa o replay linear apenas dos registros em `events.jsonl` que possuam `seq > snapshot.seq`.
  3. Reconstrói o índice `commandId -> seq` em memória (janela das últimas 1.000 entradas) sem impacto na latência de resposta.

---

## 10. Considerações de segurança

- **Ausência de TLS na v1:** O uso de TLS com certificados autoassinados em redes locais sem DNS exigiria trust-store customizada no cliente ou confirmação explícita de exceção de segurança pelo jogador, aumentando o atrito de entrada via hotspot. Como o tráfego se limita estritamente à rede local dos participantes fisicamente presentes na mesa, cleartext (`http://` e `ws://`) é aceito na v1. TLS e pinning via QR são caminho para a v2.
- **Prevenção de Path Traversal:** Identificadores em `/api/v1/assets/{sha256}` são estritamente validados contra a regex `^[a-f0-9]{64}$`. Qualquer requisição que viole essa regra é descartada com `400 Bad Request` antes de qualquer consulta ao sistema de arquivos.
- **Proteção contra DoS local:**
  - Teto de conexões ativas simultâneas (máximo 12).
  - Rate limiting de 20 comandos/s por conexão e bloqueio temporário por tentativas consecutivas de PIN incorreto.
  - Streaming no cálculo de SHA-256 no endpoint `PUT /api/v1/assets/{sha256}` abortando imediatamente a conexão se o payload exceder 1 MB, impedindo exaustão de memória heap no host.

---

## 11. Spikes de validação técnica

Antes de implementar as classes de produção, os seguintes spikes devem ser validados na matriz de aparelhos físicos:

- **S1 (`dart:io` sob carga):** Medir consumo de CPU e memória do servidor `HttpServer` + `WebSocket` rodando no aparelho em segundo plano atendendo 6 clientes simulados.
- **S2 (Cleartext e `bindProcessToNetwork`):** Validar envio de pacotes HTTP e frames WS conectando o cliente a um hotspot sem internet pública em aparelhos com Android 11 a 15, confirmando que o tráfego não é descartado pelo sistema operacional.
- **S3 (Ciclo de vida e Doze Mode):** Mensurar o comportamento do socket e a precisão do heartbeat com `Stopwatch` quando os clientes entram em suspensão profunda de tela.
- **S4 (Transferência concorrente de mídia):** Avaliar a taxa de download de mapas (até 5 MB) via HTTP enquanto eventos em tempo real trafegam no WebSocket, medindo jitter e perda de frames.
- **S5 (Tipo do Foreground Service):** Testar a longevidade do processo no host com Android 14+ usando os tipos `connectedDevice`, `specialUse` e `dataSync`, avaliando viabilidade de publicação e regras de política.

---

## 12. Consequências

### 12.1 Positivas

- **Zero dependência de infraestrutura externa:** A mesa funciona em locais remotos, convenções ou redes sem internet.
- **Modelo de concorrência simplificado:** Com o host sendo a autoridade central e mantendo log sequencial append-only com variantes pré-calculadas, elimina-se a necessidade de algoritmos de sincronização distribuída complexos (como CRDTs ou OT).
- **Sem custos operacionais:** Custo de servidores, infraestrutura em nuvem e relays de conectividade é zero.

### 12.2 Negativas e riscos

- **Single Point of Failure físico:** O ciclo de vida da sala depende da integridade do aparelho do mestre. Se a bateria acabar ou o SO matar o app, o jogo para até a reabertura da sala.
- **Gerenciamento de bateria em fabricantes específicos:** Modelos com otimização de bateria agressiva podem encerrar o processo do host mesmo com serviço em primeiro plano ativo, exigindo intervenção manual do mestre nas configurações do sistema.
- **Tráfego em texto plano (v1):** Em redes compartilhadas (ex.: Wi-Fi doméstico com terceiros), qualquer cliente na mesma subnet consegue inspecionar o tráfego JSON e imagens trafegadas.

---

## 13. Referências e fontes consultadas

- **[fonte 1]** Android Developers — Documentação da permissão `ACCESS_LOCAL_NETWORK` para targetSdk 37.
- **[fonte 2]** Android Developers — Exigência de declaração de tipos de Foreground Service no Android 14 (API 34) e `MissingForegroundServiceTypeException`.
- **[fonte 3]** Android Developers Reference — `ConnectivityManager.bindProcessToNetwork` para redirecionamento de tráfego de processo em redes sem internet.
- **[fonte 4]** Flutter Documentation — Configurações de tráfego de rede e restrições de Cleartext (`usesCleartextTraffic`) em plataformas Android.
- **[fonte 5]** Dart SDK Issue Tracker — Comportamento de sockets puros (`dart:io`) em relação às políticas de rede da plataforma.
- **[fonte 6]** Pub.dev — Documentação técnica do pacote `flutter_foreground_task` (isolates e controle de serviços em background).