# Teste Manual — CNPJ Alfanumérico no Portal de Vendas

**Para:** Time de Negócio / QA
**Data:** 2026-05-15
**Por que esse teste:** A Receita Federal vai permitir CNPJ com **letras** a partir de julho/2026. O Portal de Vendas foi ajustado para aceitar esse novo formato. Precisamos validar nas telas reais.

---

## 📌 Antes de começar

### O que mudou
- O CNPJ agora pode ter **letras (A-Z)** nas 12 primeiras posições.
- Os **2 últimos números** continuam sendo dígitos (0-9).
- Exemplo de CNPJ novo: `12.ABC.345/01DE-35`
- Exemplo de CNPJ antigo (continua valendo): `11.222.333/0001-81`

### Como entrar no Portal
1. Acessar o Portal de Vendas no ambiente de **Homologação/DEV**.
2. Logar com o usuário de teste.
3. Selecionar o segmento normalmente.

### CNPJs prontos para usar nos testes

| Apelido | CNPJ | Quando usar |
|---|---|---|
| ✅ **Alfa válido** | `12.ABC.345/01DE-35` | Para validar que aceita o novo formato |
| ✅ **Alfa válido 2** | `AB.123.CD4/56EF-80` | Para criar um cadastro novo (alternativa) |
| ✅ **Numérico antigo** | `11.222.333/0001-81` | Para validar que continua aceitando o formato atual |
| ❌ **Errado (DV)** | `12.ABC.345/01DE-99` | Para verificar que rejeita CNPJ inválido |
| ❌ **Errado (zeros)** | `00.000.000/0000-00` | Para verificar que rejeita CNPJ inválido |

> ⚠️ **Importante:** ao digitar letras no campo CNPJ, elas devem ser aceitas automaticamente em **maiúsculas**, mesmo se você digitar em minúsculas (ex.: `12abc34501de35` deve virar `12.ABC.345/01DE-35`).

---

## ✅ O que testar

> Marque cada item com **OK** ou **FALHOU** e anote observações. Se algo der erro de tela ("Erro encontrado"), tire um print.

---

### 1) Formatação visual do CNPJ nas tabelas (listagens)

> **Por que testar primeiro:** houve uma correção específica para garantir que o CNPJ apareça **formatado com pontuação** nas colunas de tabela das listagens. Essa é a regressão mais visível, então comece por aqui antes de cadastrar/editar.

**Telas onde validar a coluna de documento na tabela:**

| # | Tela | Coluna a conferir |
|---|---|---|
| 1 | Cadastros › Distribuidor › Index | CNPJ |
| 2 | Cadastros › Holding › Index | CNPJ |
| 3 | Cadastros › Loja › Index | CNPJ |
| 4 | Cadastros › Imobiliária › Index | CNPJ |
| 5 | Cadastros › Representante › Index | CNPJ |
| 6 | Cadastros › Produtor › Index | CNPJ |
| 7 | Cadastros › Corretor › Index | CNPJ |
| 8 | Consulta › Título › Index | CPF/CNPJ (campo misto) |
| 9 | Consulta › Dados Fiscais › Index | CPF/CNPJ (campo misto) |
| 10 | Consulta › Cobrança › Index | CPF/CNPJ (campo misto) |
| 11 | Qualquer tela que exiba **Balancete** (ex.: Resgate Cap Aluguel, consultas de subscritor) | CPF/CNPJ no partial de balancete |

**Passos a executar em cada uma das 11 telas acima:**

| # | Passo | Resultado esperado | OK/Falhou |
|---|---|---|---|
| 1 | Acessar a tela e executar a consulta padrão | A coluna **CNPJ** aparece formatada com pontuação para CNPJs numéricos: `11.222.333/0001-81` (e **nunca** sem pontuação como `11222333000181`) | ⬜ |
| 2 | Após executar a seção 2 abaixo (cadastrar PJ alfanumérica), voltar para a listagem | CNPJ novo aparece como `12.ABC.345/01DE-35` (letras maiúsculas e pontuação completa) | ⬜ |
| 3 | Nas telas mistas (Título, Dados Fiscais, Cobrança, Balancete), conferir CPF | CPF continua aparecendo como `XXX.XXX.XXX-XX` (sem regressão) | ⬜ |

---

### 2) Cadastros de empresa (PJ)

**Telas:** Cadastros › Distribuidor / Holding / Loja / Imobiliária / Representante / Produtor / Corretor / Corretor Imobiliário

Faça os passos **em pelo menos 3 dessas telas** — escolha 3 diferentes, e **uma delas deve ser Corretor** (tem fluxo de máscara e validação JS um pouco diferente das demais).

#### 2.1 — Cadastrar uma empresa com CNPJ NOVO (com letras)

| # | Passo | Resultado esperado | OK/Falhou |
|---|---|---|---|
| 1 | Clicar em "Incluir" | Tela de cadastro abre | ⬜ |
| 2 | No campo **CNPJ**, digitar `12abc34501de35` (sem máscara, em minúsculas) | Campo formata automaticamente para `12.ABC.345/01DE-35` (letras maiúsculas, com pontos e barra) | ⬜ |
| 3 | Sair do campo CNPJ (Tab ou clicar em outro campo) | Não aparece mensagem "CNPJ inválido" | ⬜ |
| 4 | Preencher os demais campos obrigatórios (Nome, Endereço, etc.) | Tudo preenche normalmente | ⬜ |
| 5 | Clicar em "Gravar/Salvar" | Mensagem de sucesso aparece, ou cadastro é criado | ⬜ |
| 6 | Voltar à lista (Index) | CNPJ aparece na **coluna da listagem** já formatado: `12.ABC.345/01DE-35` | ⬜ |
| 7 | Abrir o cadastro recém-criado | CNPJ aparece exatamente como `12.ABC.345/01DE-35` (sem perder letras) | ⬜ |

#### 2.2 — Cadastrar uma empresa com CNPJ ANTIGO (só números)

| # | Passo | Resultado esperado | OK/Falhou |
|---|---|---|---|
| 1 | Clicar em "Incluir" | Tela abre | ⬜ |
| 2 | No campo CNPJ, digitar `11222333000181` | Formata para `11.222.333/0001-81` | ⬜ |
| 3 | Concluir cadastro normalmente | Cadastra como antes — sem regressão | ⬜ |

#### 2.3 — Editar uma PJ já cadastrada (regressão)

> Cobertura de retrocompatibilidade — não pode haver regressão para CNPJs já existentes.

| # | Passo | Resultado esperado | OK/Falhou |
|---|---|---|---|
| 1 | Abrir uma PJ já cadastrada com CNPJ legado numérico | Cadastro abre e o CNPJ aparece formatado normalmente | ⬜ |
| 2 | Alterar qualquer campo que **não** seja o CNPJ (ex.: nome ou telefone) e gravar | Edição salva sem erro | ⬜ |
| 3 | Reabrir o cadastro | CNPJ continua exibido como antes (numérico, com máscara) | ⬜ |

#### 2.4 — Auto-preenchimento ao digitar um CNPJ já existente

> Em telas de "Incluir", ao digitar o CNPJ de uma PJ que já está cadastrada, o sistema pode buscar e preencher os demais campos automaticamente. Esse fluxo foi refeito — vale validar.

| # | Passo | Resultado esperado | OK/Falhou |
|---|---|---|---|
| 1 | Em uma tela de Incluir, digitar o CNPJ alfanumérico (`12.ABC.345/01DE-35`) de uma PJ que **já exista** na base | Sistema busca e preenche os demais campos (ou exibe aviso de que já existe). **Não pode dar erro técnico.** | ⬜ |
| 2 | Repetir com CNPJ numérico antigo (`11.222.333/0001-81`) de PJ existente | Mesma busca funciona — sem regressão | ⬜ |

#### 2.5 — Validação de CNPJ inválido

| # | Passo | Resultado esperado | OK/Falhou |
|---|---|---|---|
| 1 | Digitar `00000000000000` no campo CNPJ e sair do campo | Mensagem **"Informe um CNPJ válido"** aparece em vermelho | ⬜ |
| 2 | Digitar `12ABC34501DE99` (final errado) e sair do campo | Mensagem **"Informe um CNPJ válido"** aparece em vermelho | ⬜ |
| 3 | Tentar digitar uma letra na **13ª ou 14ª posição** do CNPJ (depois de `12ABC34501DE`) | Letra **não é aceita** (campo não permite digitar letra ali) | ⬜ |

#### 2.6 — Buscar/filtrar empresa pelo CNPJ alfanumérico

| # | Passo | Resultado esperado | OK/Falhou |
|---|---|---|---|
| 1 | Na lista de Distribuidor/Holding/etc., colar `12.ABC.345/01DE-35` no filtro de CNPJ e clicar Pesquisar | Sistema busca normalmente (mostra o registro se existir, ou "nenhum registro encontrado" — **não pode dar erro**) | ⬜ |
| 2 | No mesmo filtro, digitar em **minúsculas**: `12abc34501de35` | Sistema converte para maiúsculas e busca normalmente | ⬜ |
| 3 | No mesmo filtro, colar com pontuação "estrangeira": `12-ABC.345-01DE/35` | Sistema sanitiza e busca o mesmo CNPJ — **não pode dar erro** | ⬜ |
| 4 | Limpar e buscar pelo CNPJ antigo `11.222.333/0001-81` | Busca funciona como antes | ⬜ |

---

### 3) Premiação — Alterar Ganhador

**Tela:** Premiação › Premiações Solicitadas (ou tela onde se altera o ganhador)

| # | Passo | Resultado esperado | OK/Falhou |
|---|---|---|---|
| 1 | Abrir uma premiação onde seja possível "Alterar Ganhador" | Modal/tela abre | ⬜ |
| 2 | Digitar no campo CNPJ: `12.ABC.345/01DE-35` | Campo aceita o formato com letras | ⬜ |
| 3 | Confirmar a alteração | Sistema aceita o novo ganhador (ou avisa que o CNPJ não está cadastrado — não pode dar erro técnico) | ⬜ |

---

### 4) Resgate Cap Aluguel

**Tela:** Título › Resgate › Cap Aluguel

| # | Passo | Resultado esperado | OK/Falhou |
|---|---|---|---|
| 1 | Abrir a tela e digitar CNPJ do subscritor `12.ABC.345/01DE-35` no campo de busca | Campo aceita o formato com letras | ⬜ |
| 2 | Pesquisar | Sistema busca o título (se houver) ou retorna vazio — **sem erro técnico** | ⬜ |
| 3 | Se a tela exibir o **balancete** do subscritor, conferir o CNPJ no partial | Aparece formatado: `12.ABC.345/01DE-35` (com pontuação) | ⬜ |

---

### 5) Importação de Arquivo

**Tela:** Consulta › Importar Arquivo › Incluir

| # | Passo | Resultado esperado | OK/Falhou |
|---|---|---|---|
| 1 | Acessar a tela de Incluir Importação | Tela abre | ⬜ |
| 2 | No campo **CNPJ Parceiro**, digitar `12.ABC.345/01DE-35` | Campo aceita o formato com letras | ⬜ |
| 3 | Preencher demais campos obrigatórios e submeter (com arquivo de teste) | Sistema processa normalmente | ⬜ |
| 4 | Voltar para listagem de Importação e filtrar pelo CNPJ alfanumérico | Filtro aceita o valor | ⬜ |

---

### 6) Gestão de Hash

**Tela:** Consulta › Gestão de Hash

| # | Passo | Resultado esperado | OK/Falhou |
|---|---|---|---|
| 1 | Acessar a tela | Tela abre normalmente | ⬜ |
| 2 | Acessar "Incluir" da Gestão de Hash | Tela de inclusão abre | ⬜ |
| 3 | No campo **CNPJ Parceiro**, digitar `12.ABC.345/01DE-35` | Campo aceita o formato com letras | ⬜ |
| 4 | Preencher demais campos e submeter | Sistema processa sem erro técnico de CNPJ | ⬜ |

> ⚠️ Há um problema **pré-existente** na busca por CNPJ Parceiro na **listagem** (Index) da Gestão de Hash que ocorre tanto com CNPJ novo quanto antigo. Se ao filtrar a listagem você cair em "Erro encontrado", isso **não é problema desta entrega** — reporte separadamente.

---

### 7) Telas mistas (CPF **ou** CNPJ no mesmo campo)

**Telas:** Consulta › Dados Fiscais, Consulta › Extrato Cobrança, Consulta › Cobrança › Incluir, Consulta › Título (Index)

Essas telas têm um campo que aceita CPF **ou** CNPJ — o sistema deve detectar qual é pelo conteúdo.

| # | Passo | Resultado esperado | OK/Falhou |
|---|---|---|---|
| 1 | Digitar um CPF qualquer (11 dígitos, ex.: `12345678901`) | Formata como CPF: `123.456.789-01` | ⬜ |
| 2 | Limpar e digitar `12ABC34501DE35` | Formata como CNPJ: `12.ABC.345/01DE-35` | ⬜ |
| 3 | Limpar e digitar `11222333000181` (CNPJ antigo) | Formata como CNPJ: `11.222.333/0001-81` | ⬜ |
| 4 | Executar a consulta e conferir a **coluna documento** na tabela | CPF aparece formatado como `XXX.XXX.XXX-XX` e CNPJ como `XX.XXX.XXX/XXXX-XX` na mesma listagem | ⬜ |

---

## 🐛 O que NÃO é problema desta entrega (já existia antes)

Os itens abaixo foram encontrados durante teste automatizado, mas **acontecem também com CNPJ antigo** — não foram causados pelo ajuste de CNPJ alfanumérico:

1. **Consulta › Resgate › Index** (lista de resgates) — abre em "Erro encontrado". Independe do CNPJ.
2. **Consulta › Gestão de Hash › Index** com filtro de CNPJ Parceiro — abre em "Erro encontrado". Acontece tanto com CNPJ alfa quanto com CNPJ antigo (testar para confirmar).

Se encontrarem esses dois durante o teste, reportem **separadamente** ao time, não como bug do CNPJ alfanumérico.

---


## ✅ Checklist final de aprovação

Quando terminar todos os testes acima, marque abaixo:

- [ ] **Formatação visual nas tabelas** — CNPJ aparece formatado (`XX.XXX.XXX/XXXX-XX`) em todas as 11 listagens testadas (Cadastros + Consultas + Balancete).
- [ ] **CPF nas tabelas mistas** continua formatado (`XXX.XXX.XXX-XX`) — sem regressão.
- [ ] Cadastros em pelo menos 3 telas (uma delas Corretor) funcionaram com CNPJ alfanumérico.
- [ ] Cadastros continuam funcionando com CNPJ antigo (só números) — sem regressão.
- [ ] **Edição** de PJ já cadastrada (CNPJ legado) funciona sem regressão.
- [ ] **Auto-preenchimento** ao digitar CNPJ de PJ já existente funciona com formato alfanumérico e numérico.
- [ ] Validação de CNPJ inválido aparece corretamente ("Informe um CNPJ válido").
- [ ] Não é possível digitar letra nas 2 últimas posições do CNPJ.
- [ ] Busca/filtro por CNPJ alfanumérico funciona em todas as variações (com pontos, sem pontos, em minúsculas, com pontuação "estrangeira").
- [ ] Premiação — Alterar Ganhador aceita CNPJ alfanumérico.
- [ ] Resgate Cap Aluguel aceita CNPJ alfanumérico (incluindo balancete formatado).
- [ ] Importação de Arquivo aceita CNPJ Parceiro alfanumérico.
- [ ] Gestão de Hash › Incluir aceita CNPJ Parceiro alfanumérico.
- [ ] Telas mistas (Dados Fiscais / Extrato Cobrança / Cobrança / Título) detectam corretamente CPF vs CNPJ.
