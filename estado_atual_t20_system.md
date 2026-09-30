# Documentação do Estado Atual do Projeto: T20 Creator (Criador de Heróis)

Este documento descreve detalhadamente o estado atual do código-fonte do projeto **t20_creator**, cobrindo a arquitetura, entidades de domínio, regras implementadas, catálogo de dados estáticos, controladores de estado (Cubit/BLoC), telas, componentes e recursos existentes.

---

## 1. Informações Gerais e Configuração do Projeto

* **Nome do Pacote:** `t20_creator`
* **Versão:** `1.0.0+1`
* **SDK Dart:** `^3.10.8` (Flutter SDK)
* **Arquivo de Configuração:** [pubspec.yaml](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/pubspec.yaml)
* **Dependências de Produção:**
  * `flutter`: SDK oficial
  * `flutter_bloc`: `^9.1.1`
  * `equatable`: `^2.0.8`
  * `cupertino_icons`: `^1.0.8`
* **Dependências de Desenvolvimento:**
  * `flutter_test`: SDK oficial
  * `flutter_lints`: `^6.0.0`
* **Recursos Declarados em `assets`:**
  * `assets/images/classes/`
  * `assets/data/`
* **Ponto de Entrada:** [main.dart](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/main.dart)
  * Inicializa bindings com `WidgetsFlutterBinding.ensureInitialized()`.
  * Executa `await BancoDePoderes.carregar()` antes da inicialização visual.
  * Injeta globalmente `HomeCubit` e `PersonagemCubit` através de `MultiBlocProvider`.
  * Configura `MaterialApp` com tema `useMaterial3: true`, cor primária vermelha (`Color(0xFFD32F2F)`) e tela inicial definida como [`HomeScreen`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/presentation/screens/home_screen.dart).

---

## 2. Estrutura de Diretórios do Código-Fonte

```
lib/
├── main.dart
├── domain/
│   ├── entities/
│   │   ├── atributos.dart
│   │   ├── classe.dart
│   │   ├── classe_do_personagem.dart
│   │   ├── linhagem_arcanista.dart
│   │   ├── pericias.dart
│   │   ├── personagem.dart
│   │   ├── poder.dart
│   │   ├── proficiencias.dart
│   │   └── raca.dart
│   ├── services/
│   │   ├── banco_classes.dart
│   │   ├── banco_pericias.dart
│   │   ├── banco_poderes.dart
│   │   ├── banco_racas.dart
│   │   └── regras_atributos.dart
│   └── validators/            (diretório vazio)
├── presentation/
│   ├── controllers/
│   │   ├── home_cubit.dart
│   │   └── personagem_cubit.dart
│   ├── screens/
│   │   ├── char_creation_screen.dart
│   │   ├── home_screen.dart
│   │   ├── pagina_pericias.dart
│   │   ├── pagina_racas.dart
│   │   └── pagina_selecao_classe.dart
│   └── widgets/
│       ├── atributo_card.dart
│       └── atributo_card_compra.dart
assets/
├── data/
│   └── banco_poderes_classe.json
└── images/
    └── classes/
        ├── arcanista_image.png
        └── barbaro.png
test/                          (diretório vazio)
```

---

## 3. Camada de Domínio (`lib/domain/`)

### 3.1. Entidades (`lib/domain/entities/`)

#### [`Atributo`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/domain/entities/atributos.dart)
* **Propriedades:** `String nome`, `int valor`.
* **Regras de Negócio:**
  * Getter `modificador`: retorna o próprio `valor` (sistema Tormenta 20 adota o valor como o modificador direto).
  * Método `copyWith({int? valor})` para geração imutável de instâncias.

#### [`Raca`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/domain/entities/raca.dart)
* **Propriedades:**
  * `String nome`: identificador nominal da raça.
  * `String descricaoRaca`: texto descritivo e histórico/lore.
  * `String imagemRaca`: caminho do asset visual.
  * `Map<String, int> modificadores`: bônus e penalidades fixos indexados pelas siglas (`FOR`, `DES`, `CON`, `INT`, `SAB`, `CAR`).
  * `Map<String, String> habilidadesRaca`: mapa de habilidades concedidas no formato `{"Nome": "Descrição"}`.
  * `bool ehFlexivel`: indica se a raça permite distribuição de bônus livres (ex: Humano, Lefou). Padrão: `false`.
  * `List<String> atributosBloqueados`: siglas de atributos que não podem receber bônus livre em raças flexíveis (ex: Lefou bloqueia `CAR`, Osteon bloqueia `CON`).

#### [`TipoProficiencia`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/domain/entities/proficiencias.dart)
* **Enum:** valores `armasSimples`, `armasMarciais`, `armadurasLeves`, `armadurasPesadas`, `escudos`.

#### [`CaminhoDeClasse` e `Classe`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/domain/entities/classe.dart)
* **Classe `CaminhoDeClasse`:**
  * Representa especializações de 1º nível (ex: Bruxo, Feiticeiro, Mago).
  * Propriedades: `nome`, `atributoChave` (sigla do atributo usado como base mágica), `descricao`, `temFocoMagico` (bool), `temLinhagem` (bool), `temGrimorio` (bool).
* **Classe `Classe`:**
  * Propriedades: `idClasse`, `nome`, `pvInicial`, `pvPorNivel`, `pmInicial`, `pmPorNivel`, `descricaoclasse`, `proficiencias` (`List<TipoProficiencia>`), `periciasFixas` (`List<String>`), `periciasOpcoes` (`List<String>`), `qtdPericiasEscolha` (`int`), `caminhoImagem`, `tabelaDeProgressao` (`Map<int, List<String>>`), `caminhosDisponiveis` (`List<CaminhoDeClasse>`), `habilidadesFixas` (`Map<String, String>`).

#### [`Linhagem`, `LinhagemDraconica`, `LinhagemFeerica`, `LinhagemRubra`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/domain/entities/linhagem_arcanista.dart)
* **Enum `TipoDanoDraconico`:** `acido`, `eletricidade`, `fogo`, `frio`.
* **Classe Abstrata `Linhagem`:**
  * Propriedades: `nome`, `descricaoBasica`, `descricaoAprimorada`, `descricaoSuperior`.
* **Implementações Concretas:**
  * `LinhagemDraconica`: possui `tipoDanoEscolhido` (`TipoDanoDraconico`).
  * `LinhagemFeerica`: possui `magiaBonusEncantamentoOuIlusao` (`String`).
  * `LinhagemRubra`: possui a flag `interageComTormenta = true`.

#### [`Poder`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/domain/entities/poder.dart)
* **Propriedades:** `key`, `nome`, `descricao`, `preRequisitoTexto`, `nivelMinimo`, `caminhosExigidos`, `poderesExigidos`, `atributosExigidos`, `periciasExigidas`.
* **Construtor Factory:** `Poder.fromJson(Map<String, dynamic> json)` para desserialização direta do banco em JSON.

#### [`Pericia`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/domain/entities/pericias.dart)
* **Propriedades:** `key` (identificador em caixa alta), `label` (nome exibido), `atributoChave` (sigla do atributo), `somenteTreinada` (booleano), `penalidadeArmadura` (booleano), `descricao`, `acoesExecutadas`.

#### [`ClasseDoPersonagem`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/domain/entities/classe_do_personagem.dart)
* **Propriedades:** `classeDefinicao` (`Classe`), `nivel` (`int`), `poderesEscolhidos` (`List<Poder>`), `caminhoEscolhido` (`CaminhoDeClasse?`), `linhagemEscolhida` (`Linhagem?`).
* **Getters de Herança:**
  * `possuiHerancaBasica`: retorna se `linhagemEscolhida != null`.
  * `possuiHerancaAprimorada`: valida se `poderesEscolhidos` contém "Herança Aprimorada".
  * `possuiHerancaSuperior`: valida se `poderesEscolhidos` contém "Herança Superior".
* **Método:** `copyWith(...)`.

#### [`Personagem`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/domain/entities/personagem.dart)
* **Propriedades:**
  * `String nome`
  * `Map<String, Atributo> atributos` (valores base)
  * `Raca? raca`
  * `List<ClasseDoPersonagem> classes` (índice 0 representa a classe inicial)
  * `List<String> periciasTreinadas`
* **Construtor Factory `Personagem.inicial()`:**
  * Nome padrão: "Novo Aventureiro".
  * Atributos iniciais zerados (`FOR`, `DES`, `CON`, `INT`, `SAB`, `CAR` todos com valor 0).
  * `raca` nula e listas vazias.
* **Cálculos e Métodos Mecânicos:**
  * `getValorFinal(String sigla, {List<String> bonusVariaveis = const []})`:
    * Soma: `base + bonusFixoRaca + bonusVariavel` (retorna +1 se a sigla constar em `bonusVariaveis`).
  * `nivelPersonagem`:
    * Retorna 0 se `classes.isEmpty`. Caso contrário, soma os níveis de todas as classes (`fold`).
  * `pvTotal`:
    * Calcula o PV considerando a Constituição final (`getValorFinal('CON')`).
    * Classe inicial (índice 0, nível 1): `pvInicial + con`.
    * Níveis subsequentes da classe inicial: `(pvPorNivel + con).clamp(min: 1) * (nivel - 1)`.
    * Multiclasse (índices > 0): `(pvPorNivel + con).clamp(min: 1) * nivel`.
  * `pmTotal`:
    * Para a classe inicial: `pmInicial + pmPorNivel * (nivel - 1)`.
    * Para multiclasse: `pmPorNivel * nivel`.
    * Bônus de Atributo-Chave: se a classe tiver `caminhoEscolhido != null`, adiciona o valor final do atributo-chave especificado pelo caminho.
  * `pvDoFocoMagico`:
    * Se alguma classe possuir `caminhoEscolhido?.temFocoMagico == true` (Bruxo), retorna `(pvTotal / 2).floor()`; caso contrário, retorna 0.
  * `bonusTreinamento`:
    * Nível >= 15: retorna +6.
    * Nível >= 7: retorna +4.
    * Menor que 7: retorna +2.
  * `getValorPericia(String periciaKey, {int penalidadeArmaduraAtual = 0})`:
    * Fórmula: `metadeNivel + modAtributo + bonusTreino - penalidade`.
    * `metadeNivel`: `(nivelPersonagem / 2).floor()`.
    * `modAtributo`: `getValorFinal(pericia.atributoChave)`.
    * `bonusTreino`: `bonusTreinamento` se treinada, 0 se não treinada.
    * `penalidade`: aplicada somente se `pericia.penalidadeArmadura` for verdadeira.

---

### 3.2. Serviços e Catálogos de Regras (`lib/domain/services/`)

#### [`RegrasAtributos`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/domain/services/regras_atributos.dart)
* **Compra de Pontos:**
  * `pontosIniciais`: 10 pontos.
  * Tabela `custoPontos`:
    * `-1`: -1 ponto (gera 1 ponto adicional)
    * `0`: 0 pontos
    * `1`: 1 ponto
    * `2`: 2 pontos
    * `3`: 4 pontos
    * `4`: 7 pontos
  * Método `valorEhValidoParaCompra(int valor)`: valida limites baseados nas chaves da tabela.
* **Rolagem de Dados:**
  * Método `converterRolagemParaModificador(int somaDados)`:
    * $\le 7 \rightarrow -2$
    * $8 \text{ a } 9 \rightarrow -1$
    * $10 \text{ a } 11 \rightarrow 0$
    * $12 \text{ a } 13 \rightarrow +1$
    * $14 \text{ a } 15 \rightarrow +2$
    * $16 \text{ a } 17 \rightarrow +3$
    * $\ge 18 \rightarrow +4$
  * Método `rolar4d6DropMenor()`: gera 4 dados de 1 a 6, ordena, descarta o menor valor e soma os 3 restantes.
  * Método `gerarKitRolagem()`: gera 6 atributos convertidos em modificadores e garante que a soma de todos os modificadores seja $\ge 6$. Caso contrário, rerrola o menor valor até atingir o critério.

#### [`BancoDeClasses`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/domain/services/banco_classes.dart)
Catálogo estático `BancoDeClasses.todas` contendo 5 classes cadastradas:
1. **Arcanista** (`idClasse: "arcanista"`):
   * PV Inicial: 8 | PV/Nível: 2 | PM Inicial: 6 | PM/Nível: 6
   * Proficiências: nenhuma
   * Perícias Fixas: `MISTICISMO`, `VONTADE`
   * Perícias de Escolha: 2 entre 11 opções
   * Caminhos: Bruxo (INT, foco mágico), Feiticeiro (CAR, linhagem), Mago (INT, grimório)
   * Tabela de progressão completa do nível 1 ao 20
   * Habilidades: Magias, Poder do Arcanista, Alta Arcana
2. **Bárbaro** (`idClasse: "barbaro"`):
   * PV Inicial: 24 | PV/Nível: 6 | PM Inicial: 3 | PM/Nível: 3
   * Proficiências: armas simples, armas marciais, armaduras leves, escudos
   * Perícias Fixas: `FORTITUDE`, `LUTA`
   * Perícias de Escolha: 4 entre 10 opções
   * Caminhos: nenhum
   * Tabela de progressão completa do nível 1 ao 20
   * Habilidades: Fúria, Instinto Selvagem, Redução de Dano, Fúria Titânica
3. **Bardo** (`idClasse: "bardo"`):
   * PV Inicial: 12 | PV/Nível: 3 | PM Inicial: 4 | PM/Nível: 4
   * Proficiências: armas marciais
   * Perícias Fixas: `Atuação`, `Reflexos`
   * Perícias de Escolha: 6 entre 17 opções
   * Tabela de progressão completa do nível 1 ao 20
   * Habilidades: Inspiração, Magias, Eclético, Artista Completo
4. **Bucaneiro** (`idClasse: "bucaneiro"`):
   * PV Inicial: 16 | PV/Nível: 4 | PM Inicial: 3 | PM/Nível: 3
   * Proficiências: armas marciais
   * Perícias Fixas: `LUTA_OU_PONTARIA`, `REFLEXOS`
   * Perícias de Escolha: 4 entre 13 opções
   * Tabela de progressão completa do nível 1 ao 20
   * Habilidades: Audácia, Insolência, Evasão, Esquiva Sagaz, Panache, Evasão Aprimorada, Sorte de Nimb
5. **Caçador** (`idClasse: "caçador"`):
   * PV Inicial: 16 | PV/Nível: 4 | PM Inicial: 4 | PM/Nível: 4
   * Proficiências: armas marciais, escudos
   * Perícias Fixas: `LUTA_OU_PONTARIA`, `SOBREVIVÊNCIA`
   * Perícias de Escolha: 6 entre 13 opções
   * Tabela de progressão completa do nível 1 ao 20
   * Habilidades: Marca da Presa, Rastreador, Explorador, Caminho do Explorador, Mestre Caçador

#### [`BancoDeRacas`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/domain/services/banco_racas.dart)
Catálogo estático `BancoDeRacas.todas` contendo 18 raças:
* **Raças com modificadores fixos (14 raças):**
  * Anão (`CON +2`, `SAB +1`, `DES -1`)
  * Dahllan (`SAB +2`, `DES +1`, `INT -1`)
  * Elfo (`INT +2`, `DES +1`, `CON -1`)
  * Goblin (`DES +2`, `INT +1`, `CAR -1`)
  * Minotauro (`FOR +2`, `CON +1`, `SAB -1`)
  * Qareen (`CAR +2`, `INT +1`, `SAB -1`)
  * Golem (`FOR +2`, `CON +1`, `CAR -1`)
  * Hynne (`DES +2`, `CAR +1`, `FOR -1`)
  * Kliren (`INT +2`, `CAR +1`, `FOR -1`)
  * Medusa (`DES +2`, `CAR +1`)
  * Sílfide (`CAR +2`, `DES +1`, `FOR -2`)
  * Suraggel (Aggelus) (`SAB +2`, `CAR +1`)
  * Suraggel (Sulfure) (`DES +2`, `INT +1`)
  * Trog (`CON +2`, `FOR +1`, `INT -1`)
* **Raças flexíveis (`ehFlexivel: true`) (4 raças):**
  * Humano: +1 em 3 atributos livres (`atributosBloqueados: []`).
  * Lefou: +1 em 3 atributos livres exceto Carisma (`CAR -1`, `atributosBloqueados: ['CAR']`).
  * Osteon: +1 em 3 atributos livres exceto Constituição (`CON -1`, `atributosBloqueados: ['CON']`).
  * Sereia / Tritão: +1 em 3 atributos livres (`atributosBloqueados: []`).

#### [`BancoDePericias`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/domain/services/banco_pericias.dart)
Catálogo estático `BancoDePericias.todas` contendo as 29 perícias do sistema:
* `ACROBACIA` (DES, penalidade armadura: sim)
* `ADESTRAMENTO` (CAR, somente treinada: sim)
* `ATLETISMO` (FOR)
* `ATUACAO` (CAR, somente treinada: sim)
* `CAVALGAR` (DES)
* `CONHECIMENTO` (INT, somente treinada: sim)
* `CURA` (SAB)
* `DIPLOMACIA` (CAR)
* `ENGANACAO` (CAR)
* `FORTITUDE` (CON)
* `FURTIVIDADE` (DES, penalidade armadura: sim)
* `GUERRA` (INT, somente treinada: sim)
* `INICIATIVA` (DES)
* `INTIMIDACAO` (CAR)
* `INTUICAO` (SAB)
* `INVESTIGACAO` (INT)
* `JOGATINA` (CAR, somente treinada: sim)
* `LADINAGEM` (DES, somente treinada: sim, penalidade armadura: sim)
* `LUTA` (FOR)
* `MISTICISMO` (INT, somente treinada: sim)
* `NOBREZA` (INT, somente treinada: sim)
* `OFICIO` (INT)
* `PERCEPCAO` (SAB)
* `PILOTAGEM` (DES, somente treinada: sim)
* `PONTARIA` (DES)
* `REFLEXOS` (DES)
* `RELIGIAO` (SAB, somente treinada: sim)
* `SOBREVIVENCIA` (SAB)
* `VONTADE` (SAB)
* Método `getByKey(String key)`: busca por chave com fallback de instância "UNKNOWN" para prevenir exceções de elemento não encontrado.

#### [`BancoDePoderes`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/domain/services/banco_poderes.dart)
* Gerencia o carregamento de `assets/data/banco_poderes_classe.json` via `rootBundle`.
* Normaliza chaves das classes para caixa alta.
* Métodos:
  * `carregar()`: faz o parse assíncrono do JSON para `Map<String, List<Poder>>`.
  * `poderesDaClasse(String idClasse)`: retorna a lista de poderes para a classe informada.
  * `getByKey(String key)`: busca poder por chave em todas as listas de classes.

---

## 4. Camada de Apresentação (`lib/presentation/`)

### 4.1. Gerenciadores de Estado (`lib/presentation/controllers/`)

#### [`HomeCubit` e `HomeState`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/presentation/controllers/home_cubit.dart)
* Gerencia a lista de personagens salvos exibidos na tela inicial.
* No estado atual, inicializa com dados mockados contendo dois personagens:
  * "Satoru Gojo (T20 Version)"
  * "Machado de Assis"
* Método `adicionarPersonagem(Personagem p)`: adiciona um novo personagem à lista mantida no estado.

#### [`PersonagemCubit`, `PersonagemState`, `MetodoAtributos`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/presentation/controllers/personagem_cubit.dart)
* **Enum `MetodoAtributos`:** `nenhum`, `compra`, `rolagem`.
* **Classe `PersonagemState`:**
  * `Personagem personagem`: modelo atual em criação.
  * `int etapaAtual`: índice da etapa no wizard (0: Atributos, 1: Raça, 2: Classe, 3: Perícias, 4: Origem, 5: Finalização).
  * `MetodoAtributos metodoAtributos`: método de atribuição selecionado na etapa 0.
  * `List<int> valoresRolados`: lista com os 6 valores gerados pelo método 4d6.
  * `Map<String, int> alocacaoIndices`: mapeamento de qual índice de dado foi atribuído a qual atributo.
  * `int pontosRestantesCompra`: saldo de pontos na compra (inicial: 10).
  * `List<String> atributosVariaveisRaca`: siglas de atributos selecionados em raças flexíveis (máximo 3).
  * `List<String> selecoesPericiaClasse`: perícias escolhidas dentre as opções da classe.
  * `List<String> selecoesPericiaInteligencia`: perícias extras escolhidas com base na Inteligência positiva.
* **Métodos do `PersonagemCubit`:**
  * `resetarCriacao()`: restaura o estado inicial do personagem.
  * `escolherMetodoAtributos(MetodoAtributos metodo)`: reinicia atributos para zero, redefine 10 pontos e limpa rolagens.
  * `avancarEtapa()`: incrementa `etapaAtual`.
  * `voltarEtapa()`: decrementa `etapaAtual`. Ao retroceder da etapa 1 (Raça) para a etapa 0 (Atributos), realiza um reset rígido de atributos e alocações. Se estiver na etapa 0 com método escolhido, retorna para `MetodoAtributos.nenhum`.
  * `alterarAtributoCompra(String chave, int delta)`: altera o valor do atributo se estiver na faixa permitida e se o saldo de pontos for suficiente.
  * `rolarDados()`: gera o kit de 6 dados ordenados decrescentemente.
  * `alocarDado(String atributoKey, int indexDoDado)`: associa o dado rolado ao atributo e atualiza a ficha.
  * `selecionarRaca(Raca raca)`: vincula a raça ao personagem e reseta `atributosVariaveisRaca`.
  * `toggleAtributoRacial(String sigla)`: adiciona ou remove seleção de bônus flexível de raça (respeitando limite de 3 e bloqueios raciais).
  * `selecionarClasse(Classe classeDefinicao)`: cria uma instância de `ClasseDoPersonagem` de nível 1 e aloca no índice 0 de `classes`.
  * `selecionarCaminhoDaClasse(CaminhoDeClasse caminho)`: atualiza o caminho da classe do índice 0.
  * `selecionarLinhagem(Linhagem linhagem)`: atualiza a linhagem da classe do índice 0.
  * `togglePericiaClasse(String siglaPericia)`: seleciona ou remove perícia da lista da classe (bloqueia se for fixa, se já estiver em INT ou se atingir o limite da classe).
  * `togglePericiaInteligencia(String siglaPericia)`: seleciona ou remove perícia extra de Inteligência (bloqueia se for fixa, se estiver na classe ou se atingir o modificador positivo de INT).
  * `consolidarPericias()`: mescla fixas + escolhas da classe + escolhas de inteligência na lista `periciasTreinadas` do personagem.

---

### 4.2. Telas (`lib/presentation/screens/`)

#### [`HomeScreen`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/presentation/screens/home_screen.dart)
* Tela inicial vermelha (`t20Red = Color.fromARGB(255, 255, 0, 0)`).
* `BottomAppBar` preta com entalhe circular para `FloatingActionButton`.
* `FloatingActionButton` centralizado com ícone de dado de cassino (`Icons.casino`).
* Lista vertical com:
  * Banner de boas-vindas: "Bem Vindo ao criador de herois !!".
  * Card de ação "Criar Personagem" no índice 0 (navega para [`CharacterCreatorScreen`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/presentation/screens/char_creation_screen.dart)).
  * Cards dos personagens existentes via componente interno `_CharacterCard`.

#### [`CharacterCreatorScreen`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/presentation/screens/char_creation_screen.dart)
* Orquestrador do fluxo em etapas via `PageView` com física `NeverScrollableScrollPhysics` e `PageController`.
* Intercepta navegação do sistema através de `PopScope(canPop: false)`.
* `AppBar`:
  * Título dinâmico por etapa: "Definir Atributos" (0), "Escolher Raça" (1), "Escolher Classe" (2), "Criação de Personagem" (padrão).
  * Botão "Próximo" condicional implementado em `_deveMostrarBotaoAvancar(state)`:
    * Etapa 0: exige `pontosRestantesCompra == 0` (Compra) ou `alocacaoIndices.length == 6` (Rolagem).
    * Etapa 1: exige `raca != null`.
    * Etapa 2: exige classe selecionada, caminho selecionado (se houver caminhos) e linhagem selecionada (se o caminho for Feiticeiro).
    * Etapa 3: exige preenchimento exato da cota da classe (`selecoesPericiaClasse.length == qtdPericiasEscolha`) e da cota de Inteligência (`selecoesPericiaInteligencia.length == modInt`).
* Páginas do `PageView`:
  1. `_PaginaAtributos(state: state)`
  2. `PaginaSelecaoRaca(state: state)`
  3. `PaginaSelecaoClasse(state: state)`
  4. `PaginaSelecaoPericias(state: state)`
  5. `Center(child: Text("Etapa 3: Origem (Em Breve)"))` (Placeholder no índice 4)
  6. `_PaginaFinalizacao()` (Botão "SALVAR PERSONAGEM FINAL" com ação comentada)

#### [`PaginaSelecaoRaca`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/presentation/screens/pagina_racas.dart)
* Cabeçalho fixo no topo com HUD de atributos, exibindo valores finais com destaque de cores (verde para aumentado, vermelho para reduzido).
* Layout em colunas divididas:
  * Menu lateral retrátil com largura animada (130px aberto / 0px fechado), controlado por botão de divisa com chevron.
  * Lista de todas as raças do `BancoDeRacas`.
  * Painel de detalhes com imagem da raça (`Image.asset`), descrição de lore, chips de modificadores e sanfona `ExpansionTile` das habilidades raciais.
* Função `_mostrarSeletorDeAtributos`: abre modal bottom sheet não descartável para raças com `ehFlexivel = true`, exibindo chips para distribuição de +1 em 3 atributos, desabilitando atributos bloqueados (com texto tachado).

#### [`PaginaSelecaoClasse`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/presentation/screens/pagina_selecao_classe.dart)
* Menu lateral retrátil com listagem de classes do `BancoDeClasses`.
* Painel de visualização com:
  * Tag de fonte "Fonte: Tormenta 20".
  * Imagem da classe (`caminhoImagem`).
  * Descrição detalhada da classe.
  * Botão de "Equipamento inicial".
  * Exibição de fórmulas de PV e PM de 1º nível.
  * Seleção de `CaminhoDeClasse` através de cards interativos.
  * Seletor de `Linhagem` (visível apenas quando o caminho é Feiticeiro): cards para Dracônica, Feérica e Rubra. A seleção Dracônica aciona `_mostrarModalDraconico` para escolha do tipo de dano via `TipoDanoDraconico`.
  * Sanfona `ExpansionTile` de Habilidades de Classe fixas.
  * Sanfona `ExpansionTile` de Poderes de Classe carregados dinamicamente via `BancoDePoderes`.

#### [`PaginaSelecaoPericias`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/presentation/screens/pagina_pericias.dart)
* Organiza a seleção em três blocos verticais:
  1. **Perícias Fixas da Classe:** exibe cartões com ícone de cadeado e fundo bloqueado indicando treinamento automático.
  2. **Escolhas da Classe:** exibe contador de seleções (`selecoes / limite`), cards selecionáveis e bloqueio cruzado de perícias já marcadas no bloco de Inteligência.
  3. **Perícias Extras (Inteligência):** renderizado condicionalmente caso `modInt > 0`. Exibe contador (`selecoes / modInt`) e lista todas as perícias do sistema, exceto as fixas da classe e as já selecionadas nas opções de classe.
* Componente interno `_PericiaCard`: exibe nome, badge com sigla do atributo-chave, descrição resumida de até 3 linhas e estado visual de seleção, bloqueio ou fixação.

---

### 4.3. Componentes Visuais Reutilizáveis (`lib/presentation/widgets/`)

#### [`AtributoCard`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/presentation/widgets/atributo_card.dart)
* Componente para ajuste genérico de atributo com botões de incremento/decremento manuais e indicador de modificador colorido (verde para $\ge 0$, vermelho para $< 0$).

#### [`AtributoCardCompra`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/presentation/widgets/atributo_card_compra.dart)
* Componente específico para a etapa de compra de pontos:
  * Exibe sigla e nome do atributo.
  * Botões `onDecrement` (vermelho) e `onIncrement` (verde).
  * Exibe o valor bruto e o modificador formatado em container estilizado.

---

## 5. Dados Estáticos em Assets (`assets/`)

### 5.1. [`banco_poderes_classe.json`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/assets/data/banco_poderes_classe.json)
Arquivo com 1170 linhas de definição em JSON estruturado contendo listas de poderes divididas por classe:
* **`ARCANISTA`:** 36 poderes catalogados (ex: Arcano de Batalha, Raio Arcano, Tinta do Mago, Caldeirão do Bruxo, Alta Arcana, etc.).
* **`BARBARO`:** 23 poderes catalogados (ex: Alma de Bronze, Brado Assustador, Fúria Espumante, Golpe Poderoso, etc.).
* **`BARDO`:** 25 poderes catalogados (ex: Arte Mágica, Canção Assustadora, Dança das Lâminas, Golpe Mágico, Fascinar, etc.).
* **`BUCANEIRO`:** 25 poderes catalogados (ex: Arma Secundária Grande, Aventureiro Ávido, Bravata Audaz, Esgrima, Flagelo dos Mares, etc.).
* **`CACADOR`:** 26 poderes catalogados (ex: Alvo em Movimento, Armadilha, Companheiro Animal, Disparo Rápido, Olho do Falcão, etc.).

Cada poder possui a estrutura:
```json
{
  "key": "IDENTIFICADOR_UNICO",
  "nome": "Nome do Poder",
  "descricao": "Texto descritivo das regras",
  "preRequisitoTexto": "Texto amigável de pré-requisitos",
  "nivelMinimo": 1,
  "caminhosExigidos": [],
  "poderesExigidos": [],
  "atributosExigidos": {},
  "periciasExigidas": []
}
```

---

## 6. Resumo do Fluxo do Wizard de Criação

O fluxo implementado dentro de [char_creation_screen.dart](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/lib/presentation/screens/char_creation_screen.dart) obedece à seguinte sequência de páginas:

| Etapa | Índice | Tela / Widget | Requisitos para Avançar |
|---|---|---|---|
| **0. Atributos** | `0` | `_PaginaAtributos` | Compra de pontos zerada (`pontosRestantesCompra == 0`) ou todos os 6 dados alocados (`alocacaoIndices.length == 6`). |
| **1. Raça** | `1` | `PaginaSelecaoRaca` | Raça selecionada (`personagem.raca != null`). |
| **2. Classe** | `2` | `PaginaSelecaoClasse` | Classe selecionada; se possuir caminhos, caminho selecionado; se caminho for Feiticeiro, linhagem selecionada. |
| **3. Perícias** | `3` | `PaginaSelecaoPericias` | Todas as perícias de classe selecionadas e todas as perícias extras de Inteligência selecionadas. |
| **4. Origem** | `4` | `Center(child: Text("Etapa 3: Origem (Em Breve)"))` | Placeholder sem validação. |
| **5. Finalização** | `5` | `_PaginaFinalizacao` | Botão "SALVAR PERSONAGEM FINAL" (chamada ao Cubit comentada no código). |
