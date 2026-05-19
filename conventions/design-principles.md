---
title: Princípios de Design e Patterns
status: active
last-reviewed: 2026-05-18
---

# Convenção — Princípios de Design e Patterns

Princípios e padrões aplicáveis ao código C#/.NET 8 do CoreonCap (microsserviços novos). Para o legado em `CoreonCap\net\*`, ver `legacy-net-framework.md`.

---

## SOLID

Aplique os cinco princípios em toda implementação:

- **S — Single Responsibility:** cada classe/serviço tem uma única razão para mudar.
- **O — Open/Closed:** aberto para extensão, fechado para modificação. Prefira extensão via herança/composição.
- **L — Liskov Substitution:** subtipos devem ser substituíveis pelos seus tipos base sem quebrar o comportamento.
- **I — Interface Segregation:** interfaces pequenas e coesas. Não force implementações desnecessárias.
- **D — Dependency Inversion:** dependa de abstrações, nunca de implementações concretas.

---

## Design Patterns

Use os padrões abaixo **quando o problema os exigir**. Nunca aplique um pattern por costume — justifique na spec ou no plano.

### Padrões permitidos (e quando usar)

**Criacionais**

- `Factory Method` / `Abstract Factory` — criação de objetos com variação de implementação.
- `Builder` — construção de objetos complexos com múltiplos parâmetros opcionais.

**Estruturais**

- `Adapter` — integração entre interfaces incompatíveis (fundamental na Arquitetura Hexagonal — ver `hexagonal-architecture.md`).
- `Decorator` — adicionar comportamento sem alterar a classe base.
- `Facade` — simplificar acesso a subsistemas complexos.

**Comportamentais**

- `Strategy` — encapsular algoritmos/regras intercambiáveis.
- `Observer` / `Event-driven` — desacoplamento via eventos (alinhado ao RabbitMQ — ver `rabbitmq.md`).
- `Chain of Responsibility` — pipelines de validação ou processamento.
- `Template Method` — fluxos fixos com etapas variáveis.

### Padrões arquiteturais em uso

- **Repository** — abstração de acesso a dados. Não exponha detalhes de infraestrutura no domínio.
- **Unit of Work** — controle de transações em operações compostas.

---

## O que NÃO fazer com patterns

- ❌ Não crie abstrações sem necessidade real (over-engineering).
- ❌ Não aplique patterns que não constem nesta lista sem sinalizar antes na spec ou no plano.
- ❌ Não invente variações dos padrões — use a forma canônica.
