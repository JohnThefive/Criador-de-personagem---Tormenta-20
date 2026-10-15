# 🐉 T20 - Criador de Heróis

Um aplicativo robusto desenvolvido com **Flutter** para a criação, evolução e gerenciamento dinâmico de personagens do sistema **Tormenta 20 (T20 Jogo do Ano)**. O projeto adota princípios de **Clean Architecture** e **SOLID**, garantindo separação rigorosa de responsabilidades, alta testabilidade e facilidade de manutenção.

---

## ✨ Funcionalidades Implementadas

### 🧙‍♂️ Wizard de Criação (Fluxo Passo a Passo)
O app guia o usuário através de um fluxo lógico de criação, controlado por um gerenciador de estados centralizado (`PersonagemCubit`):

1. **Definição de Atributos**:
   * **Compra de Pontos**: Sistema de 10 pontos com custos progressivos de T20 JDA.
   * **Rolagem de Dados**: Método 4d6 (descarta o menor valor), garantindo soma mínima e interface ergonômica de alocação de valores.
2. **Escolha de Raça**:
   * Banco de dados completo de raças (`Humano`, `Anão`, `Elfo`, `Dahllan`, `Lefou`, `Qareen`, etc.).
   * Aplicação automática de atributos e habilidades raciais (incluindo bônus de PV para Anão e PM para Elfo).
3. **Escolha de Classe**:
   * Suporte a classes com caminhos/subclasses (ex: Arcanista Bruxo, Mago ou Feiticeiro; Cavaleiro no 5º nível).
   * Seleção de linhagens para Feiticeiros e escolas para Magos.
   * Cálculo automático de PV e PM inicial e por nível.
4. **Seleção de Origem & Divindade**:
   * Seleção de Origens com concessão de perícias e poderes gerais.
   * Desativação inteligente de perícias já treinadas pela classe para evitar perda de benefícios.
   * Sistema de Devoção a Divindades do Panteão (Obrigações & Restrições, Canalização de Energia e Poderes Concedidos).
5. **Seleção de Perícias e Equipamentos**:
   * Cálculo dinâmico de perícias extras baseadas no modificador de **Inteligência**.
   * Filtro automático de equipamentos marciais e exóticos conforme proficiências de classe.

---

### 🛡️ Painel do Jogador / Ficha de Personagem (Modular & Reativo)
A tela da ficha de personagem (`PainelJogadorScreen`) foi completamente desacoplada e fatiada em uma arquitetura modular orientada a componentes, controlada pelo `FichaCubit`:

* **`FichaCubit` (`lib/presentation/controllers/ficha_cubit.dart`)**:
  * Gerencia o estado imutável da ficha ativa (`FichaState`).
  * Processa aumento e redução de nível (nível 1 a 20) com recálculo de limites de PV e PM.
  * Controle de dano e cura de PV, consumo e recuperação de PM.
  * Regras de **Descanso** de Tormenta 20 (Normal, Confortável e Completo).
  * Gestão de **Punição Divina** pelo Mestre (bloqueio de PM e suspensão de poderes concedidos).
  * Persistência desacoplada e assíncrona através do contrato `IPersonagemRepository`.

* **Abas Isoladas da Ficha (`lib/presentation/screens/ficha/`)**:
  * **`AbaGeralView`**: Barra de XP, resumo de Atributos com testes de d20, consulta rápida de Raça e Classe, dados físicos (Peso, Altura, Idade) e atalhos rápidos.
  * **`AbaCombateView`**: Simulador tático de combate integrado com motor `CombateEngine` e oponente IA de treino.
  * **`AbaHabilidadesView`**: Poderes de classe e pendências de evolução, poderes raciais, de divindade, de origem e subsistemas complexos (Forma Selvagem do Druida, Companheiro Animal e Montaria Sagrada do Cavaleiro/Paladino).
  * **`AbaMagiasView`**: Grimório do herói com visualização por círculos, escolas, tipos de execução, aprimoramentos e controle de consumo de PM.
  * **`AbaInventarioView`**: Mochila de equipamentos com adição/remoção de itens em tempo real.
  * **`AbaHistoriaView`**: Biografia, alinhamento, tamanho e notas de interpretação.

---

### ⚔️ Modo Mestre & Combatentes Polimórficos (`lib/domain/entities/combate/`)
Para suportar o futuro **Modo Mestre** e encontros dinâmicos com fichas assimétricas:
* Abstração polimórfica `Combatente` (`sealed class Combatente`).
* **`CombatenteJogador`**: Ficha rica e completa de herói (`Personagem`).
* **`CombatenteMonstro`**: Ficha simplificada para ameaças e criaturas (ND, papel tático de Lacaio/Solo/Chefe e blocos de ataques diretos).

---

## 🛠️ Tecnologias e Arquitetura

* **Linguagem & Framework**: Flutter 3 (Dart 3 com sealed classes, switch expressions, pattern matching e records).
* **Modernização de Código (Dart 3 & Flutter 3.7+)**:
  * **Switch Expressions & Pattern Matching**: Utilização de tuplas/records `(classeId, caminhoId)` e pattern matching exaustivo em `AprendizadoMagiaService` e `ValidadorDivindade`.
  * **APIs de Renderização Impeller**: Eliminação de `Color.withOpacity()` em favor de `Color.withValues(alpha: ...)`, garantindo precisão de canal alpha e compatibilidade com o motor gráfico Impeller.
  * **Otimização de Rebuilds de Tela**: Substituição de `MediaQuery.of(context).size` por `MediaQuery.sizeOf(context)` em modais e painéis, evitando reconstruções desnecessárias da árvore de widgets por eventos que não afetam as dimensões físicas.
  * **Renderização Preguiçosa (Lazy Loading) com Slivers**:
    * **`PaginaSelecaoPericias`**: Substituição de `ListView` e múltiplos `Wrap(children: ...map)` por `CustomScrollView` com `SliverGrid` e `SliverChildBuilderDelegate`. Elimina a instanciação síncrona de dezenas de cartões de perícias na memória, reciclando células dinamicamente na viewport com `SliverGridDelegateWithMaxCrossAxisExtent` responsivo.
    * **Modais de Equipamento (`_ModalSeletorArmas` e `_ModalSeletorProtecoes`)**: Construção sob demanda com `ListView.separated` e controle de quebras de texto (`maxLines: 2, overflow: TextOverflow.ellipsis`), garantindo rolagem a 60/120 FPS sem jank e sem retenção desnecessária de memória nativa.
  * **Indexação O(1) em Bancos de Dados Estáticos**:
    * **`BancoDePoderes`**: Eliminação do laço duplo sequencial $O(N)$ sobre centenas de poderes. Introdução de tabela Hash `_indexPorChave` preenchida no boot, tornando a recuperação de poderes instantânea durante desserializações de fichas e validações de pré-requisitos.
    * **`BancoDeMagias` & `BancoDePericias`**: Busca em tempo constante $O(1)$ por ID e chave (`_indexPorId` e `_indexPorKey`), acelerando a renderização do Grimório e recálculo de perícias.
    * **Equipamentos e Catálogos**: `BancoDeArmas`, `BancoDeArmaduras`, `BancoDeClasses`, `BancoDeRacas`, `BancoDeOrigens`, `BancoDeDivindades`, `BancoDeFormasSelvagens`, `BancoDeCompanheiros` e `BancoDeEfeitosGolpePessoal` com índices em `Map`, eliminando overhead de `.where(...).firstOrNull`.
* **Gerenciamento de Estado**: `flutter_bloc` (`Cubit` + `State` imutável com `Equatable`).
* **Contratos de Persistência (DIP / SOLID)**:
  * `IPersonagemRepository` (`lib/domain/repositories/i_personagem_repository.dart`): Interface abstrata para operações de CRUD de fichas.
  * `PersonagemStorageService`: Implementação padrão sobre I/O local assíncrono.
  * Permite substituição transparente por SQLite (`drift`), `Hive` ou Nuvem (`Firebase`/`Supabase`), além de testes em memória instantâneos (`InMemoryPersonagemRepository`).
* **Estrutura de Pastas**:
  * `lib/domain/entities`: Modelos puros e imutáveis de regras de negócio (Personagem, Atributo, Raça, Classe, Poder, Combatente).
  * `lib/domain/repositories`: Contratos e interfaces de repositório.
  * `lib/domain/services`: Motores de regras, tabelas de progressão e serviços de I/O.
  * `lib/presentation/controllers`: Cubits reativos (`PersonagemCubit`, `FichaCubit`, `HomeCubit`, `EvolucaoCubit`, `CombateCubit`).
  * `lib/presentation/screens/ficha`: Componentes e abas especializadas da ficha.
  * `lib/presentation/widgets`: Componentes gráficos e diálogos reutilizáveis.

---

## ▶️ Como Executar o Projeto

### Pré-requisitos
* Flutter SDK (versão estável mais recente).
* Dispositivo físico Android conectado ou emulador configurado.

### Executando localmente
```bash
# 1. Instalar as dependências
flutter pub get

# 2. Executar a suíte de testes unitários
flutter test

# 3. Rodar a aplicação
flutter run
```
