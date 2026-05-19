---
name: playwright-agent
description: >
  Use this skill whenever the user wants to test, explore, or automate a web application
  using natural language specs. Triggers when the user says things like "testa minha aplicação",
  "acessa localhost e verifica se...", "executa o fluxo de login", "valida que o formulário funciona",
  "abre meu app e testa...", or any variation of wanting Claude to act as a QA agent navigating
  a real browser. Also triggers when the user provides a URL + a description of what should happen.
  Always use this skill when the user wants Claude to act as a browser agent for testing purposes,
  even if they don't explicitly mention Playwright or QA.
---

# Playwright Agent Skill

Este skill transforma Claude em um agente de QA que navega e testa aplicações web diretamente
no browser do usuário, usando linguagem natural como especificação de teste.

---

## Ferramentas disponíveis

Este skill usa duas ferramentas em conjunto:

- **Claude in Chrome** — controla o browser real do usuário (navegação, cliques, formulários, screenshots)
- **Playwright MCP** — executa automação headless e gera testes `.spec.ts` reproduzíveis (se configurado)

Se apenas o Chrome estiver disponível, use-o para toda a execução.
Se ambos estiverem disponíveis, use o Chrome para exploração e o Playwright MCP para automação.

---

## Fluxo de execução

### 1. Receber a spec
Extraia do prompt do usuário:
- **URL** da aplicação
- **Fluxo** a ser testado (ações em ordem)
- **Critérios de sucesso** (o que deve ser verdadeiro ao final)
- **Credenciais** ou dados de teste (se necessário)

Se algum item estiver faltando, pergunte antes de começar.

### 2. Explorar a aplicação
Antes de executar o teste, faça uma passagem rápida para:
- Confirmar que a URL está acessível
- Identificar os elementos principais (botões, inputs, labels)
- Verificar se há modais, loaders ou redirecionamentos esperados

### 3. Executar o teste
Siga o fluxo passo a passo:
- Execute cada ação descrita na spec
- Após cada ação crítica, tire um screenshot
- Registre o resultado: ✅ sucesso ou ❌ falha

### 4. Reportar o resultado
Ao final, apresente um relatório claro. Veja o formato em `references/report-template.md`.

---

## Regras de execução

- **Nunca assuma** que um elemento existe — sempre verifique antes de interagir
- **Sempre tire screenshot** após ações críticas (submit, redirecionamento, erro)
- **Em caso de falha**, documente: o que era esperado, o que aconteceu, e o estado da tela
- **Não invente resultados** — se um elemento não foi encontrado, reporte como falha
- **Respeite timeouts** — se um elemento não aparecer em 5s, considere falha e documente
- **Dados sensíveis** — nunca armazene ou exiba senhas em texto plano no relatório

---

## Prompt padrão para receber do usuário

Oriente o usuário a fornecer specs neste formato:

```
# Aplicação
[Descrição breve]

# URL
http://localhost:3000

# Credenciais (se necessário)
usuário: ...
senha: ...

# Fluxo de teste
1. [ação 1]
2. [ação 2]
3. [ação 3]

# Critérios de sucesso
- [ ] [o que deve ser verdadeiro]
- [ ] [o que deve ser verdadeiro]
```

Se o usuário não seguir esse formato, extraia as informações do que foi dito e confirme antes de executar.

---

## Geração de teste Playwright (opcional)

Se o usuário pedir para **salvar o teste**, após a execução gere um arquivo `.spec.ts`.
Leia `references/playwright-spec-template.md` para o template correto.

---

## Referências

- `references/report-template.md` — formato do relatório de execução
- `references/playwright-spec-template.md` — template para gerar arquivos `.spec.ts`
- `references/prompt-examples.md` — exemplos de prompts para diferentes tipos de teste
