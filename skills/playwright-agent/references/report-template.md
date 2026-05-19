# Report Template — Playwright Agent

Use este formato ao apresentar o resultado de uma execução de teste.

---

## Formato do relatório

```
## 🧪 Relatório de Teste — [Nome do Fluxo]
**Aplicação:** [URL]
**Data/Hora:** [timestamp]
**Resultado geral:** ✅ Passou / ❌ Falhou / ⚠️ Passou com ressalvas

---

### Etapas executadas

| # | Ação | Resultado | Observação |
|---|------|-----------|------------|
| 1 | Acessou [URL] | ✅ | Página carregou em ~1s |
| 2 | Preencheu campo Email | ✅ | — |
| 3 | Clicou em "Entrar" | ✅ | — |
| 4 | Verificou redirecionamento para /dashboard | ✅ | URL confirmada |
| 5 | Verificou texto "Bem-vindo, João" | ❌ | Texto não encontrado na tela |

---

### Critérios de sucesso

- [x] Página de login acessível
- [x] Formulário aceita credenciais válidas
- [ ] Redirecionamento para /dashboard após login ← FALHOU
- [ ] Nome do usuário exibido no header ← FALHOU

---

### Falhas encontradas

#### ❌ Falha 1: Redirecionamento não ocorreu
- **Esperado:** URL muda para `/dashboard`
- **Obtido:** URL permaneceu em `/login`
- **Screenshot:** [anexado]
- **Possível causa:** Erro de autenticação ou bug no redirect handler

---

### Resumo
- Total de etapas: 5
- Passou: 3
- Falhou: 2
- Taxa de sucesso: 60%
```

---

## Regras para o relatório

1. **Seja objetivo** — liste fatos, não suposições
2. **Inclua screenshots** nas falhas e nas etapas críticas
3. **Diferencie bug de elemento não encontrado** — são causas raiz diferentes
4. **Sugira próximos passos** quando houver falhas
5. **Não omita etapas** — mesmo as que passaram devem estar na tabela
