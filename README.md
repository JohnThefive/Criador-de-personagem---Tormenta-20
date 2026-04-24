# 🐉 T20 - Criador de Heróis

Um aplicativo robusto desenvolvido com **Flutter** para a criação e gerenciamento de personagens do sistema **Tormenta 20 (T20)**. O projeto utiliza uma arquitetura inspirada em Clean Architecture, garantindo separação de responsabilidades e facilidade de manutenção.

---

## ✨ Funcionalidades Implementadas

### 🧙‍♂️ Wizard de Criação (Fluxo Passo a Passo)
O app guia o usuário através de um fluxo lógico de criação, controlado por um gerenciador de estados centralizado (**Cubit**):

1.  **Definição de Atributos**:
    *   **Compra de Pontos**: Sistema de 10 pontos com custos variados conforme o valor.
    *   **Rolagem de Dados**: Método 4d6 (descarta o menor), garantindo soma mínima de 6. Interface de arrastar/alocar valores nos atributos.
2.  **Escolha de Raça**:
    *   Banco de dados de raças implementado (`Anão`, `Humano`, `Elfo`, `Dahllan`, etc.).
    *   Cálculo automático de modificadores raciais (fixos e variáveis).
3.  **Escolha de Classe**:
    *   Suporte a classes complexas com **Caminhos/Subclasses** (ex: Arcanista: Bruxo, Mago ou Feiticeiro).
    *   Seleção de **Linhagens** para Feiticeiros.
    *   Cálculo automático de PV inicial e ganho por nível.
4.  **Seleção de Perícias**:
    *   Interface para escolha de perícias de classe.
    *   Cálculo dinâmico de perícias extras baseadas no modificador de **Inteligência**.
    *   Validação de limites de escolha.

### 📊 Motor de Regras (Domain Logic)
*   **Cálculo Automático**: PV, PM, Bônus de Treinamento e valores finais de perícias atualizados em tempo real.
*   **Gestão de PM**: Diferenciação de ganho de PM por atributo-chave (INT/CAR) para classes mágicas.
*   **Regras Específicas**: Implementação de regras únicas como o **Foco Mágico** do Bruxo (PV = metade do personagem).

---

## 🛠️ Tecnologias e Arquitetura

O projeto segue padrões modernos de desenvolvimento Flutter:

*   **Gerenciamento de Estado**: `flutter_bloc` (Cubit) para uma UI reativa e desacoplada.
*   **Modelagem de Dados**: `equatable` para comparação eficiente de estados e objetos de domínio.
*   **Arquitetura**:
    *   `lib/domain/entities`: Modelos puros do sistema (Personagem, Atributo, Raça, Classe).
    *   `lib/domain/services`: "Bancos de dados" estáticos e lógica de regras de jogo (Banco de Classes, Perícias, Raças).
    *   `lib/presentation/controllers`: Lógica de UI e orquestração do estado (`PersonagemCubit`).
    *   `lib/presentation/screens`: Telas organizadas por etapas do Wizard.
    *   `lib/presentation/widgets`: Componentes visuais reutilizáveis (AtributoCards, etc).

---

▶️ Como executar o projeto
Pré-requisitos: Flutter SDK instalado.
Instalação: flutter pub get
Execução: flutter run

