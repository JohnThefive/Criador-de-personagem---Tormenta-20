name: "T20 Creator - Flutter & Agent Development Guide"
description: "Specific development guide for T20 Creator, focusing on Tormenta 20 rules engine, Riverpod state management, Freezed models, clean architecture, and reactive character calculations."
category: "Game Companion / RPG Utilities"
author: "João Gabriel"
tags:
  [
    "flutter",
    "dart",
    "tormenta20",
    "t20",
    "riverpod",
    "clean-architecture",
    "rpg-rules",
  ]
lastUpdated: "2026-10-15"
---

# T20 Creator - Flutter Development Guide

## Project Overview

T20 Creator is a specialized companion app for the tabletop RPG **Tormenta 20 (T20)**, built using Flutter, Dart, and Riverpod. The project implements complex RPG mechanics, including dynamic attribute calculation (Base + Racial Fixed + Racial Flexible + Wild Shape), class progression trees, skills training validation, encumbrance rules, and inventory management.

## Tech Stack & Core Rules

- **Framework**: Flutter 3.16+
- **Language**: Dart 3.2+
- **State Management**: Riverpod (Notifier & AsyncNotifier)
- **Rules Domain**: Tormenta 20 Core Rulebook (Ficha de Personagem, Perícias, Raças, Classes, Poderes)
- **Data Source**: Local JSON assets (`assets/data/classes_data/`, `assets/data/racas_data/`)

---

## Architecture & Code Conventions for T20 Creator

### 1. Character Entity & Calculations (`Personagem`)
- **Immutability & CopyWith:** A entidade `Personagem` é imutável. Qualquer modificação de estado (atributos, raça, PV, PM, equipamentos) deve ser feita estritamente através do método `.copyWith(...)`.
- **Atributos Variáveis (Raças Flexíveis):** Raças como Humano, Osteon, Lefou e Sereia/Tritão possuem atributos flexíveis (`atributosVariaveisRaca: List<String>`). 
  - *Regra:* Esses bônus devem ser gravados permanentemente na entidade `Personagem` e considerados automaticamente nos getters de cálculo (`getValorFinal`, `pvTotal`, `pmTotal`, `defesaFinal`, `limiteCarga`).
- **Getters Reativos:** Sempre calcule valores derivados (`pvTotal`, `pmTotal`, `defesaFinal`, `getValorPericia`) dinamicamente baseados nos atributos finais e modificadores ativos, sem armazenar estados derivados redundantes no JSON de salvamento.

### 2. Classes and Exclusive Skills (`Classe` & `ClasseDoPersonagem`)
- **Escolhas Exclusivas:** Algumas classes (ex: Guerreiro, Bucaneiro, Caçador) possuem escolhas condicionais nas perícias fixas (ex: `"LUTA_OU_PONTARIA"`). 
  - *Regra:* Nunca injete strings corrompidas ou inválidas (`UNKNOWN`) diretamente em `periciasTreinadas`. Trate-as separadamente mapeando para `periciasEscolhaExclusiva` e salvando a escolha real do jogador em `ClasseDoPersonagem.periciasExclusivasEscolhidas`.
- **Parser de JSON:** Ao carregar dados de classes de `banco_classe.json`, filtre e trate chaves compostas para evitar que quebrem o `BancoDePericias.getByKey()`.

### 3. Responsiveness and UI Layout (Crucial for Mobile RPG Sheets)
- **Sem Overflow:** Fichas de RPG possuem muitos campos e blocos dinâmicos. Nenhuma tela de ficha (`PainelJogadorScreen`, `PaginaRacas`, `PaginaPericias`) pode estourar pixels (`Overflowed by X pixels`).
- **Padrão de Rolagem e Teclado:** Sempre utilize `SingleChildScrollView` combinado com `LayoutBuilder` e `ConstrainedBox` (`minHeight: constraints.maxHeight`) em formulários e modais para que o layout se ajuste perfeitamente quando o teclado virtual abrir ou em telas de celulares compactos.
- **Componentes Modulares:** Prefira criar widgets privados menores (ex: `_ProfileContent`, `_UserAvatar`) no mesmo arquivo estruturados em seções claras em vez de métodos `_build...()`.

### 4. Riverpod & State Management Rules
- Utilize preferencialmente `@riverpod` e geradores (`AsyncNotifier` / `Notifier`).
- Evite o uso de `StateProvider` ou `ChangeNotifierProvider` legados.
- Ao atualizar o estado de um personagem no Cubit/Provider, garanta que tanto o estado da UI quanto a instância interna de `Personagem` sejam sincronizados simultaneamente.

### 5. Localization and Domain Context
- **Idioma:** Todo o conteúdo da interface, descrições de regras, erros e logs deve estar estritamente em **Português do Brasil (PT-BR)**, alinhado à terminologia oficial do Tormenta 20.
- **Regras de T20:** Em caso de dúvidas de implementação sobre penalidades de armadura, sobrecarga, limite de engenhocas ou magias, siga rigorosamente as diretrizes do livro básico do Tormenta 20.