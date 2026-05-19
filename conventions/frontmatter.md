---
title: Frontmatter padronizado em .md operacionais
status: active
last-reviewed: 2026-05-19
---

# Frontmatter padronizado em `.md` operacionais

Schema YAML 1.2 obrigatório nos `.md` ativos (fora de `completed/`). Validação automática virá via hook B7; este arquivo é descritivo.

## Schema por tipo

Notação: `*` = obrigatório. Tipos de valor entre `( )`.

- **`specs/features/`**: `title*` (string sem `[...]`), `status*` (draft|aprovado|em-implementação|concluído), `created*` (YYYY-MM-DD), `tem-ui*` (true|false — `true` dispara passo 2.5 do `coreon-pre-completion`), `spec-pai`, `plano`, `owner`.

- **`specs/bugs/`**: igual a features (inclui `tem-ui*`), mais `severidade*` (baixa|média|alta|crítica).

- **`plans/`**: `title*`, `status*` (draft|em-execução|concluído), `created*` (YYYY-MM-DD), `spec*` (path relativo à spec mãe), `owner`.

- **`analyses/`**: `title*`, `status*` (draft|concluído), `created*` (YYYY-MM-DD), `owner`, `tipo` (diagnóstico|snapshot|estudo).

- **`conventions/`**: `title*`, `status*` (active|deprecated), `last-reviewed*` (YYYY-MM-DD). Aplicado via B3.

## Antipatterns

- ❌ Usar `[Placeholder]` em valores YAML — vira sequence. Use string simples.
- ❌ Misturar EN/PT em status. Padrão: PT com cedilha.
- ❌ Aplicar em `completed/` — fora do escopo.
- ❌ Adicionar campo não-canônico sem atualizar este arquivo.

## Relação

B3 (concluído) aplicou em `conventions/`. B7 (pendente) consumirá este schema no hook. b9 (concluído 2026-05-19) introduziu `tem-ui`.
