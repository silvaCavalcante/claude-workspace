---
title: Retenção de Artefatos completed/
status: active
last-reviewed: 2026-05-18
---

# Convenção — Retenção de Artefatos `completed/`

Política de retenção e higiene para os diretórios `completed/` em `specs/features/`, `specs/bugs/` e `plans/`.

---

## Regra Geral

Specs e planos concluídos são **evidência histórica do raciocínio**: por que algo foi feito, com quais trade-offs. Não devem ser apagados por estética.

> Mantemos `completed/` para preservar o histórico do projeto.

---

## O que vai para `completed/`

- **Specs (`specs/features/`, `specs/bugs/`):** mover quando a feature/bug está em produção e estabilizada (≥ 1 sprint sem regressão).
- **Planos (`plans/`):** mover quando todos os itens do plano foram executados e revisados.
- **Movimentação manual:** Claude não move sozinho. O autor da feature/bug move ao concluir.

---

## O que NÃO vai para `completed/`

- ❌ Análises (`analyses/`) — análises são pontuais; não usam `completed/`.
- ❌ Convenções (`conventions/`) — sempre vivas; revisar in-place.
- ❌ Documentação (`docs/`) — idem.

---

## Limpeza

- **Nunca apagar** especs/planos em `completed/` apenas para reduzir contagem. Histórico tem custo zero em disco.
- **Naming malformado** em `completed/` (ex.: sem prefixo `YYYY-MM-DD-`) pode ser renomeado *in-place* sem perda de histórico, desde que não haja links externos quebrando.
- **Reciclagem ocasional:** se um item em `completed/` ainda estiver sendo referenciado em discussões/specs ativas, considerar movê-lo de volta para a pasta-pai e re-marcar como `status: in-progress` no frontmatter.

---

## Indícios de drift (acionar limpeza)

- Mais de 50% dos itens da pasta-pai estão em `completed/` por > 6 meses sem atualização.
- Naming antigo divergente do padrão atual (`YYYY-MM-DD-kebab-case.md`).
- Arquivos `.md` em `completed/` sem frontmatter (após adoção do schema definido em spec filha B1).

Quando esses sinais aparecerem, abrir uma análise pontual em `analyses/` antes de mover/renomear em lote.
