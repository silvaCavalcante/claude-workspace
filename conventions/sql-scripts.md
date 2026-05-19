---
title: Convenções de Scripts SQL
status: active
last-reviewed: 2026-05-18
---

# Convenções de Scripts SQL

Padrões para criação, organização e armazenamento de scripts SQL no projeto CoreonCap.

---

## Local de Armazenamento

> **Regra obrigatória:** Todo script SQL criado no projeto **deve ser salvo** na pasta:
>
> ```
> C:\reposit\CoreonCap\CoreonCap\sql
> ```

Nenhum script SQL deve ser mantido fora dessa pasta. Isso garante rastreabilidade, versionamento centralizado e facilidade de manutenção.

---

## Estrutura de Pastas

Os scripts devem ser organizados dentro da pasta `sql` conforme a sua natureza:

```
sql/
├── DDL/          # Definição de estrutura do banco (CREATE, ALTER, DROP de tabelas, índices, constraints)
├── DML/          # Manipulação de dados (INSERT, UPDATE, DELETE)
├── Functions/    # Criação e manutenção de funções escalares e de tabela (CREATE/ALTER FUNCTION)
├── Manual/       # Scripts de execução manual e pontual, como correções ou ajustes operacionais
├── Procedures/   # Criação e manutenção de stored procedures (CREATE/ALTER PROCEDURE)
└── Views/        # Criação e manutenção de views (CREATE/ALTER VIEW)
```

### Descrição das Categorias

| Pasta | Tipo | Descrição |
|---|---|---|
| `DDL` | Data Definition Language | Scripts que definem ou alteram a estrutura do banco: criação de tabelas, colunas, índices, constraints e drops. |
| `DML` | Data Manipulation Language | Scripts que inserem, atualizam ou removem dados das tabelas. |
| `Functions` | Funções | Definições de funções SQL reutilizáveis, sejam escalares (retornam um valor) ou de tabela (retornam um conjunto de linhas). |
| `Manual` | Execução Manual | Scripts pontuais para correções, ajustes operacionais ou tarefas que não se encaixam nas demais categorias. Devem ser documentados com contexto de uso. |
| `Procedures` | Stored Procedures | Definições de procedures armazenadas no banco, encapsulando lógica de negócio ou operações complexas. |
| `Views` | Views | Definições de visões (views) que abstraem consultas complexas e expõem dados de forma estruturada. |

---

## Nomenclatura de Arquivos

Os arquivos devem seguir o padrão:

```
{YYYY-MM-DD}_{versao}_{descricao-curta}.sql
```

| Elemento | Descrição | Exemplo |
|---|---|---|
| `YYYY-MM-DD` | Data de criação do script | `2025-04-30` |
| `versao` | Versão sequencial do script no mesmo dia (`v1`, `v2`...) | `v1` |
| `descricao-curta` | Resumo em kebab-case do que o script faz | `add-column-status-user` |

**Exemplo de nome válido:**
```
2025-04-30_v1_add-column-status-user.sql
```

---

## Cabeçalho Obrigatório

Todo script deve iniciar com o seguinte cabeçalho comentado:

```sql
-- ============================================================
-- Autor:      {Nome do autor}
-- Data:       {YYYY-MM-DD}
-- Descrição:  {Descrição clara do que o script faz}
-- Categoria:  {DDL | DML | Functions | Manual | Procedures | Views}
-- ============================================================
```

---

## Boas Práticas

- Sempre use transações (`BEGIN TRANSACTION` / `COMMIT` / `ROLLBACK`) em scripts destrutivos ou de alteração de dados.
- Inclua condições de segurança em `ALTER TABLE` e `DROP` para evitar erros em reexecuções (ex: `IF NOT EXISTS`, `IF EXISTS`).
- Scripts de `DDL` devem ser idempotentes sempre que possível.
- Nunca inclua credenciais, connection strings ou dados sensíveis dentro dos scripts.
- Prefira nomes de colunas e tabelas em `snake_case`, alinhado ao padrão do projeto.
- Scripts em `Manual` devem conter no cabeçalho o motivo e o contexto da execução.

---

## Exemplo de Script Válido

```sql
-- ============================================================
-- Autor:      João Silva
-- Data:       2025-04-30
-- Descrição:  Adiciona coluna 'status' na tabela 'users'
-- Categoria:  DDL
-- ============================================================

BEGIN TRANSACTION;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'users' AND COLUMN_NAME = 'status'
)
BEGIN
    ALTER TABLE users
    ADD status NVARCHAR(50) NOT NULL DEFAULT 'active';
END;

COMMIT;
```
