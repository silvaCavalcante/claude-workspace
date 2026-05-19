---
title: Hook PostToolUse de validação de .md operacionais
status: active
last-reviewed: 2026-05-19
---

# Hook PostToolUse — validação de naming e frontmatter

Hook **warning-only permanente** disparado por `Write`, `Edit` e `MultiEdit` em `.md` dentro de pastas operacionais. Implementado em `scripts/validate-md.sh`.

## O que valida

- **Naming:** `YYYY-MM-DD-kebab-case.md` em `specs/{features,bugs}/`, `plans/`, `analyses/`. Em `conventions/`: `kebab-case.md` (sem data).
- **Frontmatter:** campos obrigatórios + enum de `status` por tipo, conforme `conventions/frontmatter.md`.

## Exclusões

- Subpastas `completed/` e `future/` em qualquer pasta operacional.
- Pastas não-operacionais (`agents/`, `skills/`, `docs/`, `tests/`, `scripts/`).
- Arquivos `^_.*\.md$`, `README.md`, `INDEX.md` — exceção de naming (frontmatter ainda validado se aplicável).

## Comportamento

- Sucesso: exit 0 silencioso.
- Falha: exit 0 + warnings em stderr (texto puro, PT). **Nunca bloqueia** o tool use.
- Bloqueio efetivo continua via skill `coreon-pre-completion`.

## Sincronização com schema

O script tem schema hardcoded. Quando `conventions/frontmatter.md` mudar, atualizar o comentário "Última sincronização" no topo de `validate-md.sh`.
