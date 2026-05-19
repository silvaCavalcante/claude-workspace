---
name: clarify-spec
description: >
  Use esta skill ENTRE a leitura da spec e a escrita do plano, sempre que houver
  ambiguidade ou item em aberto. Triggers when the user says "vou planejar",
  "antes do plano", "vou escrever o plano", "esclarecer spec", "tem ambiguidade",
  "tem dúvida na spec", "vamos refinar a spec", "lê a spec e me diz", "spec
  está pronta?". A skill extrai perguntas estruturadas a partir da seção
  "Ambiguidades / Perguntas em aberto" da spec (e de leitura crítica do
  restante), pergunta ao usuário e REGISTRA as respostas na própria spec antes
  de liberar o plano. SEMPRE ativar quando o usuário indica que vai começar
  a planejar uma feature/bug do CoreonCap, mesmo que não mencione "clarify".
---

# Clarify Spec — CoreonCap

Esta skill é o **degrau entre `specs/` e `plans/`**. Garante que toda ambiguidade da spec seja resolvida com o usuário antes de qualquer linha de plano ser escrita.

A skill **não escreve plano** e **não toca em código**. Ela só:

1. Lê a spec.
2. Identifica perguntas.
3. Apresenta as perguntas ao usuário (de forma estruturada).
4. Registra as respostas na própria spec.
5. Libera o passo seguinte (`writing-plans` / criação de plano em `plans/`).

---

## Quando ativar

- Usuário sinaliza início de planejamento ("vou planejar", "vou escrever o plano", "antes do plano").
- Spec recém-criada tem itens não-marcados em `## Ambiguidades / Perguntas em aberto`.
- Usuário pede revisão crítica de uma spec ("lê a spec e me diz se está pronta").
- Antes de invocar a skill `writing-plans` ou qualquer comando que crie `.md` em `plans/`.

Não ativar quando:

- A tarefa não tem spec (ex.: ajuste ad hoc autorizado pelo usuário).
- A spec é puramente declarativa de "estado encerrado" (ex.: spec de análise sem implementação).
- O usuário pediu explicitamente para pular (`"pula o clarify, já alinhei offline"`).

---

## Fluxo de execução

### 1. Localizar a spec

- Identifique o caminho exato em `.claude/specs/features/<arquivo>.md` ou `.claude/specs/bugs/<arquivo>.md`.
- Se houver mais de um candidato, pergunte qual antes de prosseguir.
- Recuse continuar se a spec não existir — sinalize ao usuário e ofereça criar (delegando para o fluxo normal de criação).

### 2. Extrair ambiguidades

Combine duas fontes:

- **Fonte explícita:** seção `## Ambiguidades / Perguntas em aberto` da spec (template novo). Cada `- [ ]` aberto é uma pergunta a fazer.
- **Fonte implícita (leitura crítica):** percorra o resto da spec procurando sinais como:
  - Verbos vagos ("validar", "tratar", "ajustar") sem critério mensurável.
  - Listas de "Fora de escopo" curtas para um objetivo amplo.
  - Critérios de aceite com prosa em vez de checklist verificável.
  - Decisões arquiteturais marcadas como "a definir" / "TBD" / "?".
  - Dependências citadas sem versão / sem endpoint / sem owner.
  - Termos de domínio com mais de uma interpretação plausível.

Consolide tudo em uma lista numerada interna (não exibida ainda).

### 3. Apresentar perguntas ao usuário

- Use a ferramenta `AskUserQuestion` quando houver até 4 perguntas com poucas opções discretas (multipla escolha).
- Use texto livre + numeração quando houver mais de 4 perguntas ou quando as respostas exigirem descrição.
- **Uma pergunta por vez** se cada resposta puder mudar o escopo das próximas. Caso contrário, agrupe em uma rodada única.
- Cada pergunta deve ter:
  - Contexto (1 linha do trecho da spec que gerou a dúvida).
  - Opções concretas quando possível (`A) X | B) Y | C) outro`).
  - Default sugerido com justificativa, se aplicável.

### 4. Registrar respostas na spec

- Atualize a seção `## Ambiguidades / Perguntas em aberto` da spec com:
  - Texto da pergunta (ou referência ao item original).
  - Marcação `- [x]` quando resolvida.
  - Resposta do usuário literal, sem reinterpretação.
  - Data da resposta (`YYYY-MM-DD`).
- Se a resposta alterar escopo / critério de aceite / "Fora de escopo", **atualize também a seção afetada** da spec — não deixe a resposta isolada.
- Não altere `## Objetivo` sem confirmação explícita.

### 5. Veredicto

**Se todas as ambiguidades estão resolvidas:**

> ✅ **Spec esclarecida.** Pode partir para `plans/` ou invocar `superpowers:writing-plans`.

**Se ainda há ambiguidade aberta após a rodada (ex.: usuário precisa consultar terceiros):**

> ⏸ **Plano bloqueado.** Pendências:
> - [Item 1]
> - [Item 2]
>
> Spec permanece em `draft`. Re-rodar `clarify-spec` quando tiver as respostas.

---

## Regras

- **Nunca** invente respostas. Se o usuário não respondeu, fica aberto.
- **Nunca** mova a spec para `completed/` — clarify acontece em `draft`/`review`.
- **Nunca** escreva o plano dentro desta skill. Quem escreve o plano é outra skill.
- **Sempre** registre a resposta na spec, não só no chat — o histórico precisa sobreviver à sessão.
- **Sempre** preserve o texto original da pergunta na spec (não reescreva pós-resposta).

---

## Antipatterns

- ❌ Perguntar tudo de uma vez quando uma resposta muda as próximas perguntas.
- ❌ Assumir uma resposta padrão "porque é óbvio" — registre como pergunta mesmo assim.
- ❌ Encerrar com `- [ ]` aberto e seguir para `plans/`.
- ❌ Reescrever o objetivo da spec sem o usuário pedir.
- ❌ Tratar resposta verbal como suficiente — sempre persistir na spec.
- ❌ Fundir esta skill com `coreon-pre-completion` (clarify é pré-plano; pre-completion é pós-implementação).

---

## Relação com outras skills

- **Antes:** `superpowers:brainstorming` (criação da spec).
- **Esta:** `clarify-spec` (refino da spec antes do plano).
- **Depois:** `superpowers:writing-plans` (geração do plano em `plans/`).
- **Muito depois:** `coreon-pre-completion` (gate antes de mover para `completed/`).
