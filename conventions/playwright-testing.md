---
title: Padrão de uso do Playwright para validação interativa
status: active
last-reviewed: 2026-05-19
---

# Padrão de uso do Playwright para validação interativa

Esta convenção define **como o time usa o Playwright (via skill `playwright-agent`) no CoreonCap** para validar features e bugs em browser real, principalmente no Portal_Vendas. O acionamento como gate obrigatório está descrito na skill `coreon-pre-completion` (passo 2.5); aqui ficam os padrões de execução.

---

## Pré-requisitos

- Claude in Chrome **OU** Playwright MCP configurado na máquina do dev.
- Portal_Vendas rodando localmente (`dotnet run --project Coreon.PortalVendas/Portal_Vendas/Portal_Vendas.csproj`).
- `Coreon.PortalVendas/Coreon.PortalVendas.SmokeTests/settings.local.json` presente com credenciais do Role declarado na spec.
- Pasta `.claude/tests/_artifacts/` existente para receber o relatório.

---

## Quando usar (e quando não)

| Situação | Ferramenta correta |
|---|---|
| Validar fluxo de UI de feature/bug com `tem-ui: true` antes de arquivar | `playwright-agent` (este padrão) |
| Smoke regression versionado em CI | `Coreon.PortalVendas.SmokeTests` (Selenium, fora desta convenção) |
| Exploração ad-hoc sem spec | `playwright-agent` em modo livre (sem gate) |
| Backend puro / microsserviço sem UI | Nenhuma das duas — não aplica |

**Regra:** se a spec não declara `tem-ui: true`, este padrão é opcional. Se declara, é obrigatório (gate `coreon-pre-completion` passo 2.5).

---

## Decisão Claude in Chrome vs Playwright MCP

A skill `playwright-agent` suporta duas ferramentas. Critério:

| Cenário | Ferramenta |
|---|---|
| Apenas Chrome disponível na máquina | Claude in Chrome |
| Apenas Playwright MCP disponível | Playwright MCP |
| Ambos disponíveis, validação simples | Claude in Chrome (mais rápido para gate) |
| Ambos disponíveis, gravar `.spec.ts` para reuso futuro | Claude in Chrome para execução + Playwright MCP para geração do `.spec.ts` |

A skill cita as duas ferramentas em `.claude/skills/playwright-agent/SKILL.md` §"Ferramentas disponíveis"; esta convenção acrescenta a matriz de decisão.

---

## Padrão de prompt para o gate

Quando acionada pelo passo 2.5 do `coreon-pre-completion`, a skill recebe um prompt montado a partir da spec da feature/bug. Estrutura obrigatória:

```
# Aplicação
Portal_Vendas (Razor Pages, ASP.NET Core 8)

# URL
<URL local do Portal_Vendas — padrão http://localhost:5000; conferir launchSettings.json se variar>

# Role / credenciais
<Role declarado na spec — Admin | Distribuidor | Holding | Representante | Vendedor | Imobiliaria | CorretorImobiliario>
Credenciais lidas de Coreon.PortalVendas/Coreon.PortalVendas.SmokeTests/settings.local.json
(reuso do roleset existente; não duplicar credenciais)

# Fluxo a ser validado
<copiar passos do "Fluxo de UI" da spec, se houver seção; caso contrário, derivar do "Comportamento esperado">

# Critérios de sucesso (assertion individual por item)
- [ ] <critério 1 da seção "Comportamento esperado" da spec>
- [ ] <critério 2 da seção "Comportamento esperado" da spec>
- [ ] <... cada item da seção, um por linha>

# Evidência exigida
- Screenshot após cada passo crítico (submit, redirect, modal)
- Captura do estado final
- Linha do log de erro em caso de falha

# Diretório de output
.claude/tests/_artifacts/YYYY-MM-DD-<feature-slug>.md
```

A skill `playwright-agent` já tem o `references/prompt-examples.md` com formatos completos. Esta convenção apenas obriga o uso do formato `# Prompt Padrão Recomendado` (engenheiro de QA sênior) quando o gate dispara.

---

## Padrão de relatório

A skill já tem `.claude/skills/playwright-agent/references/report-template.md`. Esta convenção obriga seu uso integral no gate, com adendos:

- Título do arquivo: `YYYY-MM-DD-<slug-da-feature>.md` (mesmo slug da spec).
- Caminho: `.claude/tests/_artifacts/`.
- Screenshots: linkados via caminho relativo (`./screenshots/<step>.png`), ou inline em base64 se único screenshot pequeno. Nunca em pasta externa não-rastreável.
- Seção "Critérios de sucesso" do relatório espelha 1:1 a seção "Comportamento esperado" da spec.
- Seção "Falhas encontradas" usa numeração `BUG-NN` conforme `references/prompt-examples.md` §"Por que este prompt funciona bem".

---

## Padrão de locators

Quando a skill registrar interações (para reaproveitamento futuro em `.spec.ts`), seguir a ordem do `references/playwright-spec-template.md` §"Regras para geração do spec":

1. `getByRole` — preferido (acessível e resiliente)
2. `getByLabel` — para inputs com label
3. `getByText` — para textos visíveis
4. `getByTestId` — se a página usar `data-testid` (raro no Portal_Vendas hoje)
5. `locator('css')` — apenas como último recurso, com motivo no relatório

**Proibido no gate:**
- IDs do tipo `inputEmailAddress`, `inputPassword` (resquícios do Selenium 3 — frágeis para mudanças de markup).
- Seletores por posição (`:nth-child(N)`).
- XPath complexo.
- Esperas com tempo fixo (`Thread.Sleep`, `page.waitForTimeout`); usar auto-wait nativo do Playwright.

---

## Convenção de evidências

| Item | Onde |
|---|---|
| Relatório `.md` por execução | `.claude/tests/_artifacts/YYYY-MM-DD-<feature-slug>.md` |
| Screenshots da execução | mesma pasta, em subpasta `./screenshots/` quando volume > 3 imagens |
| Logs brutos do browser (opcional) | inline no relatório, em bloco ` ```log ` |
| Arquivos `.spec.ts` gerados (opcional, futuro) | `Coreon.PortalVendas/<projeto-futuro-playwright>/` — **fora do `.claude/`** quando existir |

Limite: relatórios em `_artifacts/` ficam no `.claude/.git` local (decisão M6, 2026-05-18), não no repo de produção do CoreonCap. Nunca vazar credenciais reais (mascarar `senha: ********`).

---

## Credenciais e Roles

Reaproveitar o `Coreon.PortalVendas/Coreon.PortalVendas.SmokeTests/settings.local.json` (já existente). Não criar `.env` paralelo em `.claude/`.

Quando o gate dispara, espera-se que `settings.local.json` exista e tenha o Role declarado na spec. Se ausente, o passo aborta apontando para `settings.json` (template não-sensível) como referência. Detalhes de como a skill lê o arquivo ficam no próprio `playwright-agent/SKILL.md` — esta convenção apenas determina a fonte.

Nunca persistir senha em relatório, comentário ou commit.

---

## O Que NÃO Fazer

- ❌ Rodar o gate sem ler o frontmatter `tem-ui` da spec (executa quando não deveria, ou pula quando deveria executar).
- ❌ Aceitar passo com sucesso parcial sem registrar pendência justificada no plano.
- ❌ Salvar relatório fora de `_artifacts/` (perde rastreabilidade com a spec).
- ❌ Reutilizar o relatório de uma execução anterior sem nova data/slug.
- ❌ Mascarar falha em critério de aceite como "warning lateral" — falha em item da seção "Comportamento esperado" da spec sempre é pendência registrada.
- ❌ Usar locators do tipo `By.Id("inputEmailAddress")` ao gerar `.spec.ts` (resquício do Selenium 3, frágil).
- ❌ Acionar `playwright-agent` em sessão Claude sem antes confirmar que o Portal_Vendas está rodando em ambiente local.

---

## Troubleshooting

| Sintoma | Causa provável | Ação |
|---|---|---|
| Skill não acha credenciais para o Role | `settings.local.json` ausente ou Role inexistente | Conferir `Coreon.PortalVendas/Coreon.PortalVendas.SmokeTests/settings.json` (template) e preencher `.local.json` |
| Browser não abre | Claude in Chrome ou Playwright MCP não configurado | Conferir extensão/MCP no settings local; ver pré-requisitos |
| Portal_Vendas retorna 404/500 | Servidor local não está rodando ou roda em porta diferente | Subir Portal_Vendas; conferir `launchSettings.json` para a porta correta |
| Relatório não gerado | Pasta `_artifacts/` ausente ou erro de permissão | Criar pasta manualmente; conferir path no prompt |
| Falha intermitente (flaky) | Auto-wait insuficiente OU dado dependente de outro teste | Aumentar timeout do Playwright; isolar fixture; registrar como warning não-bloqueante |

---

## Relação com outras convenções e skills

- **Skill executora:** `.claude/skills/playwright-agent/` — quem opera o browser.
- **Skill gate:** `.claude/skills/coreon-pre-completion/` passo 2.5 — quem decide quando acionar.
- **Convenção pareada:** `.claude/conventions/sonar-local.md` — mesmo padrão de "ferramenta acionada pela skill de pre-completion".
- **Template das specs:** `.claude/specs/features/_template.md` e `.claude/specs/bugs/_template.md` — origem do campo `tem-ui` que dispara o passo.
- **Relatório base:** `.claude/skills/playwright-agent/references/report-template.md`.
- **Prompt base:** `.claude/skills/playwright-agent/references/prompt-examples.md`.
