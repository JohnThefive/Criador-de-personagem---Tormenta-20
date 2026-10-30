# ADR-001: Arquitetura e Integração do Painel do Personagem (Ficha de Sessão T20)

## Status
**Aceito (Accepted)**

## Data
2026-10-30

---

## 1. Contexto

No ciclo de vida de um RPG de mesa como **Tormenta 20 (Jogo do Ano - JdA)**, existe uma disparidade fundamental de tempo e uso:
- O jogador cria seu personagem em **~5 a 15 minutos**.
- O jogador utiliza a ficha durante **dezenas ou centenas de horas** em sessões ativas de jogo.

A versão anterior da ficha sofria com:
1. **Regras de jogo dispersas na interface (UI)**: lógicas de cálculo de bônus, destreza com armadura pesada e penalidades estavam misturadas em widgets de apresentação.
2. **Atrito em mesa (muitos toques)**: para rolar um teste simples de perícia, o jogador precisava calcular mentalmente ou abrir telas intermediárias.
3. **Falta de transparência dos cálculos**: o jogador não conseguia auditar rapidamente de onde vinha cada ponto do bônus (½ nível, atributo, treino, bônus diversos ou penalidade de armadura).
4. **Falta de persistência automática**: ações de mesa (dano, perda de PM, notas, uso de itens) dependiam de ações manuais de salvamento.
5. **Combate acoplado**: o módulo de combate precisava de uma reformulação completa e estava bloqueando a evolução da ficha de jogo.

---

## 2. Decisão de Arquitetura

Decidiu-se **refatorar integralmente o Painel do Jogador**, adotando uma arquitetura limpa em camadas com separação estrita de responsabilidades:

1. **Camada de Apresentação (UI)**:
   - Focada exclusivamente em renderização responsiva para smartphones (alvos de toque $\ge 44\text{px}$, alinhamento ergonômico, ausência de overflows horizontais).
   - Nenhuma regra de negócio ou fórmula matemática de Tormenta 20 reside nos widgets.
2. **Camada de Gerenciamento de Estado**:
   - Centralizada no [`FichaCubit`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/presentation/controllers/ficha_cubit.dart) (usando `flutter_bloc`), responsável por intermediar os comandos do usuário, emitir estados imutáveis e disparar a persistência contínua (sem botão "Salvar").
3. **Camada de Domínio e Regras Puras**:
   - Entidades imutáveis: [`Personagem`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/domain/entities/personagem/personagem.dart), [`EfeitoTemporario`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/domain/entities/personagem/efeito_temporario.dart), [`ItemVestido`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/domain/entities/equipamento/item_vestido.dart), [`Protecao`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/domain/entities/equipamento/protecao.dart), [`Arma`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/domain/entities/equipamento/arma.dart), [`Magia`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/domain/entities/magia/magia.dart).
   - Serviço central de regras: [`CalculoFichaService`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/domain/services/calculo_ficha_service.dart), que realiza todas as composições de bônus, cálculos de CD, regras de armadura, rolagens com detecção de crítico/falha natural e simulação segura de gasto de PM.
4. **Isolamento do Módulo de Combate**:
   - A aba de combate legada foi ocultada do painel principal para não poluir a experiência.
   - O domínio adiantou a estrutura [`PreviewAtaqueArma`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/domain/services/calculo_ficha_service.dart) para que o futuro módulo de combate seja construído diretamente sobre contratos já testados.

---

## 3. Estrutura do Painel do Personagem

O ponto de entrada é a tela [`PainelJogadorScreen`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/presentation/screens/ficha/painel_jogador_screen.dart), dividida em:

### 3.1. Cabeçalho Fixo de Sessão (Top Header)
- **Identidade Rápida**: Retrato do personagem (câmera/galeria), Nome, Raça e Classes com nível.
- **Alinhamento e Idade no Topo**: Informações essenciais visíveis imediatamente e editáveis em um toque através de modal inline.
- **Rolagem de Iniciativa em 1 Toque**: Botão de atalho rápido no topo com o bônus total de Iniciativa; ao tocar, abre o diálogo de rolagem instantaneamente preenchido.
- **Barras de Recursos Vitais (PV e PM)**:
  - Feedback visual por cores (verde/amarelo/azul).
  - Toque no texto abre diálogo numérico com botões de Dano/Cura ou Gasto/Recuperação.
  - Botões inline `-1` e `+1` para micro-ajustes rápidos durante a rodada.
- **Banner de Evolução Pendente**: Notifica o jogador quando ele subiu de nível e possui poderes pendentes para escolha, permitindo navegar diretamente para a seleção de poderes.

### 3.2. As 6 Abas da Ficha de Jogo

```
┌────────────────────────────────────────────────────────────────────────┐
│                        PainelJogadorScreen                             │
├───────────┬────────────┬─────────────┬───────────┬─────────────┬───────┤
│ [1] Geral │ [2] Perícias│[3] Habilidad.│[4] Magias │[5] Inventário│[6]Notas│
└───────────┴────────────┴─────────────┴───────────┴─────────────┴───────┘
```

1. **Aba Geral ([`AbaGeralView`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/presentation/screens/ficha/aba_geral_view.dart))**:
   - **Defesa Ampliada**: Card de destaque maior que o padrão, detalhando a soma de $10 + \text{DES (limitada se armadura pesada)} + \text{Armadura} + \text{Escudo} + \text{Efeitos} + \text{Outros}$.
   - **Redução de Dano Padrão (RD)**: Campo compacto e editável para a RD contínua da armadura/habilidade básica.
   - **Grade de Atributos**: Exibe FOR, DES, CON, INT, SAB e CAR. Tocar em qualquer atributo rola $1d20 + \text{modificador}$ imediatamente.
   - **Efeitos Temporários**: Lista dinâmica para gerenciar Buffs, Debuffs, Condições de T20 (Abalado, Cego, Debilitado, etc.) e Notas temporárias. Efeitos com `ativo: true` somam automaticamente nas perícias, defesa e RD.

2. **Aba de Perícias ([`AbaPericiasView`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/presentation/screens/ficha/aba_pericias_view.dart))**:
   - **Agrupamento por Atributo**: Perícias organizadas sob FOR, DES, CON, INT, SAB, CAR em ordem alfabética estrita.
   - **Total ao Lado do Nome**: O jogador visualiza instantaneamente o número que precisa somar ao dado (ex: `Acrobacia  +7`).
   - **Decomposição Transparente**: Subtítulo detalhando as parcelas exatas: `½ Nív +2 • DES +3 • Treino +2 • Pen. Armadura -0`.
   - **Campos Interativos na Linha**: Checkbox de Treino (com bloqueio para treinos fixos obrigatórios de classe) e campo para bônus diversos ("Outros").
   - **Rolagem em 1 Toque**: Tocar na linha abre o [`mostrarDialogoRolagemPericia`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/presentation/screens/ficha/dialogo_rolagem_dado.dart) já com $1d20 + \text{total}$, indicando sucessos críticos (20) e falhas críticas (1).

3. **Aba de Habilidades ([`AbaHabilidadesView`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/presentation/screens/ficha/aba_habilidades_view.dart))**:
   - **Habilidades Iniciais**: Agrupa benefícios de Raça, Origem, Devoção a Divindades e Poderes de Classe. As **habilidades de raça são tratadas como inatas e passivas** (como *Graça de Glórienn*, *Sentidos Élficos*, *Couro Rígido*, *Chassi*), aplicando seus bônus diretamente aos cálculos do personagem (deslocamento, perícias, defesas, PMs) sem exigir ativação ou gasto de PM. O botão de ativação com PM é reservado apenas para poderes ou habilidades ativas que exigem custo explícito.
   - **Proficiências & Habilidades Gerais**: Resumo das proficiências (armas simples/marciais/exóticas, armaduras leves/pesadas, escudos), sentidos especiais (visão no escuro, faro), deslocamentos e RDs diversas.
   - **Progressão de Personagem**: Linha do tempo sequencial nível a nível (útil para revisão do Mestre), registrando poderes obtidos e anotações/distinções de cada nível.
   - **Módulos de Classes Específicas**: Preserva atalhos para Forma Selvagem (Druida), Companheiro Animal, Montaria Sagrada (Paladino), Golpes Pessoais (Guerreiro) e Engenhocas (Inventor).

4. **Aba de Magias ([`AbaMagiasView`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/presentation/screens/ficha/aba_magias_view.dart))**:
   - **Conta de CD Estilizada**: Destaque para o Teste de Resistência das magias do personagem: $10 + ½\text{ Nível} + \text{Atributo-Chave} + \text{Outros}$.
   - **Variante Grimório Ampliado**: Toggle otimizado para personagens arcanistas com catálogo extenso de magias.
   - **Lançamento Seguro de PM**: Seletor de aprimoramentos que calcula o custo total dinamicamente (respeitando Truques a $0\text{ PM}$). O botão **"Lançar (-X PM)"** valida o saldo de mana, deduz os pontos e bloqueia tentativas com PM insuficiente ou sob **Punição Divina**.

5. **Aba de Inventário ([`AbaInventarioView`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/presentation/screens/ficha/aba_inventario_view.dart))**:
   - **Capacidade e Carga**: Barra visual de espaços ocupados vs. capacidade máxima e limite absoluto, calculando penalidades de sobrecarga automaticamente.
   - **4 Slots de Itens Vestidos**: Separação clara entre a Armadura Equipada (Slot 1) e os 3 slots extras para itens vestidos (anéis, capas, botas, amuletos), respeitando o teto de 4 itens vestidos de T20 JdA.
   - **Itens Empunhados**: Slots dedicados para Armas ativas e Escudo.
   - **Denominações de Tibares**: Três campos independentes para **Tibares de Cobre (TC)**, **Tibares de Prata (T$)** e **Tibares de Ouro (TO)**, com exibição do patrimônio total consolidado.

6. **Aba de Notas & Biografia ([`AbaHistoriaView`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/presentation/screens/ficha/aba_historia_view.dart))**:
   - Bloco de anotações de sessão livre, com persistência automática durante a digitação.
   - Registro de aparência física e histórico biográfico do aventureiro.

---

## 4. Conexão do Painel com as Outras Partes do Projeto

O diagrama abaixo ilustra como o **Painel do Jogador** se conecta com as demais camadas e subsistemas do aplicativo:

```mermaid
flowchart TD
    subgraph Criação e Evolução
        WIZARD["Wizard de Criação de Personagem\n(lib/presentation/screens/wizard_personagem/)"]
        LEVELUP["Seleção de Poderes / Level Up\n(lib/presentation/screens/wizard_personagem/selecao_poderes_screen.dart)"]
    end

    subgraph Painel do Jogador (Apresentação)
        PANEL["PainelJogadorScreen\n(Scaffold principal)"]
        HEADER["Cabeçalho Fixo (PV/PM, Nível, Iniciativa)"]
        TAB_GERAL["AbaGeralView (Defesa, RD, Atributos, Efeitos)"]
        TAB_PERICIAS["AbaPericiasView (Grupos, Bônus, 1 Toque)"]
        TAB_HABILIDADES["AbaHabilidadesView (Habilidades, Progressão)"]
        TAB_MAGIAS["AbaMagiasView (CD, Grimório, Lançar)"]
        TAB_INVENTARIO["AbaInventarioView (Carga, 4 Slots, Tibares)"]
        TAB_NOTAS["AbaHistoriaView (Anotações Livres)"]
        DIALOG_ROLL["mostrarDialogoRolagemPericia\n(Diálogo de Rolagem Transparente)"]
    end

    subgraph Gerenciamento de Estado
        CUBIT["FichaCubit\n(lib/presentation/controllers/ficha_cubit.dart)"]
        STATE["FichaState\n(Personagem imutável)"]
    end

    subgraph Regras de Domínio
        CALC["CalculoFichaService\n(Cálculos puros, rolagens, CD, PM)"]
        CARGA["RegrasCargaService\n(Espaços, sobrecarga, limite)"]
        COMBATE_PREVIEW["PreviewAtaqueArma\n(Adiantamento do Domínio de Combate)"]
    end

    subgraph Repositório e Persistência
        STORAGE["PersonagemStorageService\n(lib/domain/services/personagem_storage_service.dart)"]
        LOCAL_STORAGE["Sistema de Arquivos Local\n(app_flutter/personagens/*.json)"]
    end

    subgraph Catálogos Estáticos de T20
        DATA_PERICIAS["BancoDePericias (call_pericias.dart)"]
        DATA_MAGIAS["BancoDeMagias (call_magias.dart)"]
        DATA_CLASSES["BancoDeClasses (call_classes.dart)"]
        DATA_RACAS["BancoDeRacas (call_racas.dart)"]
        DATA_ARMAS["BancoDeArmas (call_armas.dart)"]
        DATA_ARMADURAS["BancoDeArmaduras (call_armaduras.dart)"]
    end

    %% Relações de Criação e Navegação
    WIZARD -->|Abre a ficha final| PANEL
    PANEL --> HEADER
    PANEL --> TAB_GERAL
    PANEL --> TAB_PERICIAS
    PANEL --> TAB_HABILIDADES
    PANEL --> TAB_MAGIAS
    PANEL --> TAB_INVENTARIO
    PANEL --> TAB_NOTAS

    HEADER -->|Poderes pendentes| LEVELUP
    LEVELUP -->|Retorna personagem evoluído| CUBIT

    %% Relações de UI com Cubit e Diálogos
    TAB_PERICIAS -->|1 toque| DIALOG_ROLL
    HEADER -->|1 toque| DIALOG_ROLL
    TAB_GERAL -->|1 toque| DIALOG_ROLL

    TAB_GERAL -->|Dispara ações| CUBIT
    TAB_PERICIAS -->|Dispara ações| CUBIT
    TAB_HABILIDADES -->|Dispara ações| CUBIT
    TAB_MAGIAS -->|Dispara ações| CUBIT
    TAB_INVENTARIO -->|Dispara ações| CUBIT
    TAB_NOTAS -->|Dispara ações| CUBIT

    %% Relações do Cubit com Domínio e Persistência
    CUBIT -->|Consulta regras e validações| CALC
    CUBIT -->|Consulta regras de inventário| CARGA
    CUBIT -->|Salva silenciosamente| STORAGE
    CUBIT -->|Emite novo estado| STATE
    STATE -->|Reconstrói UI reativa| PANEL

    %% Relações de Persistência com Disco
    STORAGE --> LOCAL_STORAGE

    %% Relações com Catálogos Estáticos
    CALC --> DATA_PERICIAS
    CALC --> DATA_MAGIAS
    CALC --> COMBATE_PREVIEW
    CARGA --> DATA_ARMADURAS
    CARGA --> DATA_ARMAS
    TAB_HABILIDADES --> DATA_CLASSES
    TAB_HABILIDADES --> DATA_RACAS
```

### 4.1. Pontos de Integração Detalhados

1. **Com o Fluxo de Criação (`WizardPersonagemScreen`)**:
   - Quando o jogador conclui o passo final da criação de personagem, o wizard salva o personagem via `PersonagemStorageService` e navega para `PainelJogadorScreen(personagemInicial: p)`.
   - A ficha é carregada no `FichaCubit` como fonte única da verdade para a sessão.
2. **Com a Evolução de Nível (`SelecaoPoderesScreen`)**:
   - O cabeçalho da ficha monitora se há poderes pendentes (`c.temPoderPendente`).
   - Ao tocar no banner de evolução, a tela de seleção de poderes é empurrada na pilha de navegação. Ao retornar, o `FichaCubit.atualizarPersonagem` absorve a nova árvore de poderes escolhidos.
3. **Com a Persistência de Dados (`IPersonagemRepository`)**:
   - Qualquer mutação realizada pelo jogador (ajustar PV/PM, ativar efeito temporário, marcar treino, escrever uma nota livre ou equipar um acessório) aciona o método de salvamento do repositório em segundo plano.
   - O formato JSON é versionado e retrocompatível, tratando valores nulos e convertendo mapas de bônus com segurança.
4. **Com o Futuro Módulo de Combate**:
   - A função [`CalculoFichaService.prepararPreviewAtaqueArma`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/domain/services/calculo_ficha_service.dart) já processa a arma equipada, a perícia associada (`LUTA` ou `PONTARIA`), o bônus de atributo, a penalidade por falta de proficiência e a fórmula de dano com multiplicador e margem de ameaça.
   - Quando a nova interface de combate for implementada, ela consumirá diretamente esse serviço sem necessidade de reescrever cálculos no domínio.

---

## 5. Consequências e Benefícios

### Positivas
- **Velocidade em Mesa**: Rolagens críticas (Perícias, Iniciativa, Atributos) acontecem em $\le 1$ toque, já com a fórmula resolvida e o resultado na tela.
- **Transparência Total de Regras**: Jogador e Mestre conseguem auditar a memória de cálculo de cada número da ficha.
- **Zero Regras de Jogo na UI**: A camada de visualização é puramente declarativa, tornando o código limpo, testável e manutenível.
- **Alta Cobertura de Testes**: Suíte automatizada com 149 testes unitários e de integração passando com 100% de sucesso.
- **Preparação Segura para Combate**: A separação garantiu que a ficha ficasse pronta e operacional imediatamente, enquanto o módulo de combate pode ser reconstruído do zero de forma independente.

### Compensações (Trade-offs)
- A tela legada de combate (`aba_combate_view.dart`) foi temporariamente desativada do menu principal da ficha até que seu fluxo de ações seja redesenhado.

---

## 6. Referências de Código

- **Tela Principal da Ficha**: [`lib/presentation/screens/ficha/painel_jogador_screen.dart`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/presentation/screens/ficha/painel_jogador_screen.dart)
- **Serviço de Cálculos e Rolagens**: [`lib/domain/services/calculo_ficha_service.dart`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/domain/services/calculo_ficha_service.dart)
- **Gerenciador de Estado da Ficha**: [`lib/presentation/controllers/ficha_cubit.dart`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/presentation/controllers/ficha_cubit.dart)
- **Aba de Perícias (1 Toque)**: [`lib/presentation/screens/ficha/aba_pericias_view.dart`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/presentation/screens/ficha/aba_pericias_view.dart)
- **Aba Geral (Defesa, RD, Efeitos)**: [`lib/presentation/screens/ficha/aba_geral_view.dart`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/presentation/screens/ficha/aba_geral_view.dart)
- **Aba de Habilidades e Progressão**: [`lib/presentation/screens/ficha/aba_habilidades_view.dart`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/presentation/screens/ficha/aba_habilidades_view.dart)
- **Aba de Magias e CD**: [`lib/presentation/screens/ficha/aba_magias_view.dart`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/presentation/screens/ficha/aba_magias_view.dart)
- **Aba de Inventário e Carga**: [`lib/presentation/screens/ficha/aba_inventario_view.dart`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/presentation/screens/ficha/aba_inventario_view.dart)
- **Aba de Anotações e Biografia**: [`lib/presentation/screens/ficha/aba_historia_view.dart`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/presentation/screens/ficha/aba_historia_view.dart)
- **Persistência em Disco**: [`lib/domain/services/personagem_storage_service.dart`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/domain/services/personagem_storage_service.dart)
- **Suíte de Testes Automatizados**: [`test/painel_jogador_ficha_test.dart`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/test/painel_jogador_ficha_test.dart)
