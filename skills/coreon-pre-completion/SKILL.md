---
name: coreon-pre-completion
description: >
  Use esta skill ANTES de marcar qualquer feature ou bug spec do CoreonCap como concluída.
  Triggers when the user says "vou concluir", "fechar essa feature", "marcar como concluído",
  "mover para completed", "tô finalizando", "feature pronta", "bug resolvido", "terminei",
  "pode arquivar". Coordena code review (via agent code-review ou code-review-portal-vendas)
  e análise SonarQube local (via scripts/sonar-analyze.sh) e valida a definição de pronto
  antes de aprovar o arquivamento. SEMPRE ativar quando o usuário sinaliza fim de implementação
  de feature/bug no CoreonCap, mesmo que ele não mencione code review ou Sonar explicitamente.
---

# Pre-Completion Check — CoreonCap

Esta skill é o **portão obrigatório** entre execução de feature/bug e arquivamento em `completed/`. Garante que toda mudança em código `.NET` passe por code-review e análise Sonar local antes de ser declarada pronta.

A skill não move arquivos sozinha — apenas coordena os checks e devolve ao usuário um verdito "pronto para arquivar" ou "bloqueado por X".

---

## Quando ativar

- Usuário sinaliza fim de implementação ("vou concluir", "tô finalizando", "feature pronta", "terminei", "pode arquivar").
- Antes de qualquer comando que mova `.md` de `specs/features/` ou `specs/bugs/` para `completed/`.
- Antes de aprovar mover plano para `plans/completed/`.

Não ativar quando:

- A tarefa é apenas documentação (sem mudança em `.cs`/`.cshtml`) **E** o usuário pede explicitamente para pular ("pula o code review, é só doc").
- Não há spec/plano envolvido (ex.: ajuste ad hoc).

---

## Fluxo de execução

### 1. Identificar o que está sendo concluído

Determine:

- Qual spec (`specs/features/<arquivo>.md` ou `specs/bugs/<arquivo>.md`)?
- Qual plano associado (`plans/<arquivo>.md`)?
- Quais arquivos foram alterados? (`git -C C:\reposit\CoreonCap\.claude diff` para o workspace; `git -C <repo-do-microsservico> status` para o código real)

Se não conseguir identificar, pergunte ao usuário antes de prosseguir.

### 1.5. Cross-artifact analyze (sempre que houver código tocado)

Validar **consistência cruzada** entre os três artefatos antes de invocar code review e Sonar. Divergência sem justificativa registrada → veredicto = ❌ bloqueado.

Três comparações obrigatórias:

**1.5a. Spec ↔ Plano**

- Cada item da seção `## Comportamento esperado` (ou critério de aceite) da spec tem etapa correspondente no plano?
- Cada `- [x]` marcado no plano resolve algum critério da spec?
- Algum item de `## Fora de escopo` da spec foi violado por uma etapa do plano?

**1.5b. Plano ↔ Código tocado**

- Cada etapa marcada como concluída tem mudança refletida no diff do microsserviço (`git -C <repo> diff`)?
- Há arquivo `.cs`/`.cshtml`/`.cshtml.cs` alterado sem etapa correspondente no plano?
- Há etapa concluída no plano sem código correspondente (over-marking)?

**1.5c. Spec ↔ "Ambiguidades / Perguntas em aberto"**

- Todos os `- [ ]` daquela seção da spec foram resolvidos (estão `- [x]` com resposta)?
- Se algum ficou aberto, o veredicto é ❌ até a skill `clarify-spec` rodar e fechar.

**Onde registrar justificativa de desvio:** seção `## Notas técnicas` ou `## Decisões` do plano, antes de re-rodar esta skill. Sem justificativa, a divergência **bloqueia o arquivamento**.

**Pular este passo quando:** a tarefa é apenas documentação (sem `.cs`/`.cshtml.cs` tocados).

### 2. Code review (sempre)

Escolher o agent conforme o tipo de código tocado:

| Código tocado | Agent |
|---|---|
| `.cs` em microsserviço .NET 8 (`Coreon.*`, `CoreCap.*`) | `code-review` |
| `.cshtml`/`.cshtml.cs` em `Coreon.PortalVendas\Portal_Vendas\` | `code-review-portal-vendas` |
| Ambos | rodar os dois sequencialmente |
| Apenas `.md` ou config | pular o code review e seguir para o passo 4 |
| Código legado em `CoreonCap\net\*` | `code-review` (mas seguir `@conventions/legacy-net-framework.md`) |

Dispatch via `Agent` tool com `subagent_type` apropriado, OU ativar o agent inline carregando `@agents/code-review.md` ou `@agents/code-review-portal-vendas.md`.

O review deve cobrir:

- Aderência às convenções em `@conventions/` (arquitetura, naming, data-access, api, rabbitmq).
- SOLID e patterns (ver `@conventions/design-principles.md`).
- Cobertura de testes proporcional à mudança.
- Sem regressão em outros fluxos.
- Sem código copiado de microsserviços (`tests/compare/` não recebe `.cs`).

### 3. Análise Sonar local (condicional)

**Rodar SE** houver mudança em `.cs` ou `.cshtml.cs`. Pular SE for apenas `.md`/config.

Executar via terminal:

```bash
bash C:/reposit/CoreonCap/.claude/scripts/sonar-analyze.sh
```

(Detalhes em `@conventions/sonar-local.md`.)

Verificar no relatório:

- **Nenhum issue novo** de severidade Crítica ou Alta introduzido.
- Code smells novos justificados (ou suprimidos com motivo no comentário).
- Vulnerabilidades = 0.

Se houver issues novos Críticos/Altos, **não aprovar conclusão**. Documentar achados no plano antes de re-revisar.

### 4. Verificar definição de pronto

Conferir o checklist da §7 do `docs/claude-workspace-usage-guide.md`:

- [ ] Spec/plano com frontmatter completo (`title`, `status`, `created`).
- [ ] Comportamento esperado da spec satisfeito (rodar suíte de testes do microsserviço).
- [ ] Passo 1.5 (analyze cruzado) sem divergências não justificadas.
- [ ] Code review do passo 2 passou (sem severidade Crítica/Alta não-resolvida).
- [ ] Sonar local do passo 3 sem novos issues Críticos/Altos (se aplicável).
- [ ] Testes proporcionais à mudança (cobertura mínima conforme `@agents/backend-unit-tests.md` ou `@agents/frontend-unit-tests.md`).
- [ ] Nenhum binário ou secret commitado.

### 5. Veredicto

**Se todos os passos passaram:**

Devolver ao usuário:

> ✅ **Pronto para arquivar.** Mova manualmente:
> - Spec → `specs/{features|bugs}/completed/<arquivo>.md`
> - Plano → `plans/completed/<arquivo>.md`
>
> Não comito por você (regra "Não commitar" do CLAUDE.md).

**Se algum passo falhou:**

Devolver ao usuário:

> ❌ **Bloqueado.** Pendências:
> - [Lista específica do que falhou]
>
> Próximo passo sugerido: [ação concreta].
>
> Spec/plano **continua fora de** `completed/` até resolver.

---

## Regras

- **Sempre** executar code review quando há mudança em código (`.cs`/`.cshtml.cs`).
- **Nunca** mover arquivos para `completed/` sozinho — usuário move manualmente.
- **Nunca** aprovar com Sonar reportando Críticos/Altos novos sem justificativa documentada.
- **Não substitui** revisão humana — a skill executa o checklist; o usuário decide arquivar.

---

## Antipatterns

- ❌ Pular code review "porque a mudança é pequena" — toda mudança em `.cs`/`.cshtml` passa pelo agent.
- ❌ Aceitar Sonar com Críticos/Altos novos sem registrar justificativa no plano.
- ❌ Considerar pronto sem rodar a suíte de testes do microsserviço.
- ❌ Considerar pronto sem rodar o analyze cruzado (passo 1.5) quando há código tocado.
- ❌ Marcar como pronto sem o usuário confirmar.
- ❌ Rodar code review **depois** de mover para `completed/` (perde o gate).
