# Documentação Técnica do Projeto (T20 Creator)

Este diretório centraliza a documentação arquitetural, guias e registros de decisões de engenharia do aplicativo **T20 Creator** (Tormenta 20 - Jogo do Ano).

---

## Estrutura da Documentação

- **[`ADR/`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/documentation/ADR)**: *Architecture Decision Records* (Registros de Decisões de Arquitetura).
  - [ADR-001: Arquitetura e Integração do Painel do Personagem (Ficha de Sessão T20)](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/documentation/ADR/ADR-001-painel-do-personagem-e-integracao-de-arquitetura.md)
  - [ADR-002: Arquitetura do Módulo de Combate VTT 2D, Sandbox Offline e Painel do Mestre via LAN WebSocket](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/documentation/ADR/ADR-002-combate-vtt-e-painel-do-mestre-lan.md)
- **[`diagrams/`](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/documentation/diagrams)**: Diagramas de arquitetura auto-contidos (HTML + SVG com exportação PNG/PDF).
  - [Diagrama ADR-002: Combate VTT, Sandbox Offline & Painel do Mestre (LAN)](file:///home/joao/%C3%81rea%20de%20trabalho/Projetos%20/Tormenta-criador_personagem/t20_creator/documentation/diagrams/arquitetura-combate-vtt-mestre.html)

---

## Padrões Adotados
1. **Separação UI vs Domínio**: Widgets de apresentação não devem conter fórmulas ou regras do sistema de RPG.
2. **Imutabilidade**: Entidades de domínio utilizam padrão imutável com métodos `copyWith`.
3. **Persistência Contínua**: Alterações realizadas durante a sessão são salvas automaticamente em segundo plano.
4. **Alvos de Toque e Acessibilidade**: Controles táteis dimensionados para uso ágil em celulares ($\ge 44\text{px}$).
