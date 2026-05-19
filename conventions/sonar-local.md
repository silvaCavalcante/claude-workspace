---
title: Análise SonarQube Local
status: active
last-reviewed: 2026-05-18
---

# Convenção — Análise SonarQube Local

Padrão para rodar análise estática SonarQube **localmente, antes de commitar**, em projetos .NET do CoreonCap. Objetivo: pegar issues novos (severidade, code smells, vulnerabilidades) antes do código entrar no repositório remoto.

---

## Quando Usar

> **Regra:** Toda alteração relevante em código .NET (microsserviço novo ou legado) **deve passar pela análise local** antes de ser commitada.

Considere "alteração relevante":

- Implementação de feature (`@specs/features/`)
- Correção de bug (`@specs/bugs/`)
- Refatorações que toquem múltiplos arquivos
- Qualquer mudança em código de produção

**Não é necessário** rodar para: mudanças apenas em `.claude/`, documentação (`.md`), arquivos de configuração isolados (`appsettings.json` sem código associado).

---

## Local dos Arquivos

Todos os artefatos da análise ficam em:

```
.claude/scripts/
├── sonar-analyze.sh         # Script de análise (versionado)
├── .env.sonar.example       # Template de variáveis (versionado)
└── .env.sonar               # Variáveis reais — IGNORADO pelo git
```

---

## Pré-requisitos

| Ferramenta | Comando de instalação |
|---|---|
| .NET SDK 8 | já presente no ambiente do projeto |
| `dotnet-sonarscanner` | `dotnet tool install --global dotnet-sonarscanner` |
| `jq` | `winget install jqlang.jq` ou `choco install jq` |
| `curl` | nativo no Windows 10+ |
| SonarQube local | rodar via Docker em `http://localhost:9000` |

---

## Configuração Inicial (uma vez)

1. Subir o SonarQube local (Docker, porta 9000).
2. Gerar token em: `http://localhost:9000` → **My Account → Security → Generate Token**.
3. Copiar o template:
   ```bash
   cp .claude/script/.env.sonar.example .claude/script/.env.sonar
   ```
4. Editar `.env.sonar` e preencher:
   - `SONAR_TOKEN` — token gerado
   - `SONAR_PROJECT_KEY` — use sufixo com seu usuário pra não colidir com o time (ex.: `coreon-arquivo-gustavo`)
   - `SONAR_PROJECT_NAME` — nome legível
   - `SOLUTION_FILE` — opcional; o script autodetecta o primeiro `.sln`

> `.env.sonar` **nunca** deve ser commitado. Já está coberto pelo `.gitignore` na raiz do repositório.

---

## Fluxo de Uso

### Antes de commitar

```bash
cd .claude/script
./sonar-analyze.sh
```

Saída esperada:

- Build da solution
- Envio dos resultados pro SonarQube
- Aguarda processamento server-side
- Resumo no terminal: **Quality Gate**, **contagem por severidade**, **top 20 issues novos**
- Link pro browser com a lista completa

### Opções do script

| Flag | Uso |
|---|---|
| (nenhuma) | Análise completa: build + scan + relatório |
| `--skip-scan` | Pula o scan e só busca issues já enviados (rápido, pra revisão) |
| `--json` | Saída em JSON puro (útil pra parsing/automação) |
| `-h`, `--help` | Ajuda |

### Critério de aprovação

- **Quality Gate `OK`** → pode commitar.
- **Quality Gate `ERROR`** → corrigir issues `BLOCKER`/`CRITICAL` antes de commitar.
- Issues `MAJOR`/`MINOR` em código novo: avaliar caso a caso. Se a spec não exigir, sinalize no PR.

> O script retorna **exit code 1** quando o Quality Gate falha — pode ser plugado em hooks de pre-commit no futuro.

---

## O Que NÃO Fazer

- ❌ Não commitar `.env.sonar` (já bloqueado pelo `.gitignore`, mas atenção).
- ❌ Não compartilhar token entre desenvolvedores — cada um gera o seu.
- ❌ Não reutilizar a mesma `SONAR_PROJECT_KEY` entre membros do time (uso local, prefixe com seu usuário).
- ❌ Não suprimir issues com `// NOSONAR` sem justificar no PR.
- ❌ Não rodar contra o SonarQube de produção/CI a partir da máquina local.

---

## Troubleshooting

| Erro | Causa provável | Ação |
|---|---|---|
| `SONAR_TOKEN não definido` | `.env.sonar` ausente ou variável vazia | Conferir o arquivo |
| `Não consegui conectar em http://localhost:9000` | SonarQube não está rodando | Subir o container Docker |
| `Nenhum .sln encontrado` | Script rodado fora da raiz da solution | Definir `SOLUTION_FILE` no `.env.sonar` ou rodar a partir da pasta da solution |
| `dotnet-sonarscanner não instalado` | Tool global ausente | O script instala automaticamente; se falhar, instalar manualmente |
| `Build falhou` | Erro de compilação na solution | Conferir `/tmp/sonar-build.log` (Git Bash) ou o log mostrado pelo script |

---

## Referências

- Script: `.claude/script/sonar-analyze.sh`
- Template de configuração: `.claude/script/.env.sonar.example`
- Documentação oficial: https://docs.sonarsource.com/sonarqube-community-build/analyzing-source-code/scanners/dotnet/
