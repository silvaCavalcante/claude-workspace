# Exemplos de Prompts — Playwright Agent

Referência de prompts prontos para diferentes tipos de teste.

---

## ⭐ Prompt Padrão Recomendado

Este é o formato de referência para testes completos e sistemáticos. Use-o como base para qualquer tela ou módulo.

```
Você é um engenheiro de QA sênior. Sua tarefa é testar a tela de [NOME DA TELA] de forma completa e sistemática.

## Contexto
A documentação da tela está no arquivo anexo. Leia-a integralmente antes de começar qualquer teste.

## Acesso à aplicação
- URL: [URL da aplicação]
- Usuário: [usuário]
- Senha: [senha]

## O que você deve fazer

### 1. Leitura e mapeamento
- Leia toda a documentação anexa
- Mapeie todos os campos, fluxos, ações, validações e regras de negócio descritos
- Identifique todos os cenários de teste possíveis antes de começar

### 2. Verificação de conformidade com a documentação
Para cada elemento da tela (campos, botões, tabelas, filtros, modais, mensagens):
- Verifique se está presente conforme especificado
- Verifique labels, textos e traduções
- Verifique comportamentos e fluxos descritos
- Registre qualquer divergência encontrada

### 3. Execução de cenários de teste
Execute todos os cenários abaixo para cada funcionalidade da tela:

**Cenários de caminho feliz (happy path)**
- Criação de um novo registro com todos os campos obrigatórios preenchidos corretamente
- Edição de um registro existente
- Listagem e visualização de registros
- Busca/filtro (se aplicável)
- Exclusão de um registro (se aplicável)

**Cenários de validação e erro**
- Tentar salvar com campos obrigatórios vazios
- Inserir dados em formato inválido em cada campo
- Inserir valores fora dos limites permitidos (máx/mín de caracteres, valores numéricos, datas)
- Testar campos duplicados (se a documentação mencionar unicidade)

**Cenários de borda (edge cases)**
- Campos com valor mínimo e máximo permitido
- Strings muito longas
- Caracteres especiais e acentuação
- Campos opcionais deixados em branco

**Cenários de navegação e UX**
- Cancelar uma operação e verificar que nenhuma alteração foi salva
- Navegar para fora da tela e voltar
- Verificar mensagens de sucesso e erro

### 4. Relatório final
Ao terminar todos os testes, gere um relatório estruturado contendo:

**Sumário executivo**
- Total de cenários executados
- Total de cenários aprovados
- Total de falhas encontradas
- Avaliação geral (Aprovado / Aprovado com ressalvas / Reprovado)

**Conformidade com a documentação**
- Lista de itens conformes
- Lista de divergências encontradas (com descrição do esperado vs. observado)

**Resultado por cenário de teste**
Para cada cenário: nome, status (✅ passou / ❌ falhou / ⚠️ parcial), e descrição do resultado

**Bugs e divergências detalhados**
Para cada problema encontrado:
- ID sequencial (BUG-001, BUG-002...)
- Descrição clara do problema
- Passos para reproduzir
- Comportamento esperado
- Comportamento observado
- Severidade (Crítico / Alto / Médio / Baixo)

**Observações e melhorias sugeridas**
Qualquer ponto de atenção que não seja necessariamente um bug, mas que mereça revisão.

---
Seja metódico. Documente cada passo. Não pule etapas. Se encontrar um erro que impeça a
continuação de um fluxo, registre e prossiga para o próximo cenário.

@[caminho/para/documentacao.pdf]
```

---

## Por que este prompt funciona bem

- **Persona definida** — "engenheiro de QA sênior" calibra o nível de rigor e linguagem
- **Documentação como fonte da verdade** — o agente lê o DDR/spec antes de agir, evitando suposições
- **Cobertura estruturada** — happy path + erros + edge cases + UX garante amplitude
- **Relatório padronizado** — BUG-001, severidade e passos de reprodução facilitam o rastreamento
- **Instrução de resiliência** — "registre e prossiga" evita que um erro bloqueie toda a execução

---

## Variações por contexto

### Teste rápido (sem documentação)
```
Você é um engenheiro de QA. Acesse [URL], faça login com [usuário] / [senha]
e teste a tela de [NOME DA TELA].

Cubra os seguintes cenários:
1. Listagem — verifique se os dados carregam corretamente
2. Criação — preencha todos os campos e salve
3. Edição — altere um registro existente
4. Validação — tente salvar com campos obrigatórios vazios
5. Exclusão — remova um registro e confirme

Para cada cenário, tire um screenshot e reporte ✅ / ❌ / ⚠️ com descrição do resultado.
```

### Teste de regressão (fluxo específico)
```
Você é um engenheiro de QA. Acesse [URL] e valide APENAS o fluxo de [NOME DO FLUXO].

Contexto: após a última release, o comportamento esperado é [DESCREVA].

Passos para validar:
1. [passo 1]
2. [passo 2]
3. [passo 3]

Critério de aprovação: [o que deve ser verdadeiro ao final]
Reporte o resultado com screenshot do estado final.
```

### Teste de formulário com regras específicas
```
Você é um engenheiro de QA. Teste o formulário de [NOME] em [URL].

Regras de negócio a validar:
- Campo [X] é obrigatório
- Campo [Y] aceita no máximo [N] caracteres
- Campo [Z] deve ser único (não pode duplicar)
- [outras regras]

Execute e reporte cada regra individualmente com ✅ / ❌.
```

---

## Dicas para prompts eficazes

- **Anexe sempre a documentação** — o agente testa com base na spec, não em suposições
- **Defina a persona** — "QA sênior" produz relatórios mais detalhados que "testador"
- **Inclua critérios de severidade** — Crítico / Alto / Médio / Baixo orienta a priorização
- **Peça screenshots** — evidências visuais são essenciais para bugs
- **Use IDs sequenciais** — BUG-001 facilita rastreamento e comunicação com o time
