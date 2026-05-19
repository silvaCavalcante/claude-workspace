# Comparação: GerarPremiacaoOld vs GeraPremiacaoNew

## Visão Geral

| Aspecto | Old | New |
|---|---|---|
| Paradigma | Síncrono, monolítico | Async, hexagonal |
| Transação | `TransactionScope` (2h timeout) | `UnitOfWork` |
| Cadastro de pessoa | Inline no método | Delegado ao serviço (correto) |

---

## Gaps de Regra de Negócio

### 1. Bloqueio Judicial — CRÍTICO

**Old:**
```csharp
var bloqueioJudicial = ConsultarBloqueioJudicial(dataSistema, request.premiacao, request.CodigoGanhador);

public bool ConsultarBloqueioJudicial(DateTime dataOcorrencia, int codigoPremiacao, string codigoPessoa)
{
    var bj = _context.cli_bloqueio_judicial.FirstOrDefault(bj => bj.cod_pess == codigoPessoa && bj.dta_ini_vig <= dataOcorrencia && bj.dta_fim_vig >= dataOcorrencia);

    if (bj == null)
        return false;

    var premiacao = _context.cap_premiacao.FirstOrDefault(p => p.cod_prm == codigoPremiacao);

    var bjl = _context.cap_bloqueio_judicial_liberar.FirstOrDefault(bjl => bjl.cod_bloq == bj.id_bloq
                && bjl.cod_ctr == premiacao.cod_ctr
                && bjl.cod_ems == premiacao.cod_ems
                && bjl.flg_lib == 1);

    if (bjl == null)
        return true;
    else
        return false;
}

// Status do beneficiário e do portal
cap_ben_prem.cod_sts_pgm_pmc = !bloqueioJudicial ? "SO" : "BJ";

// Registro de bloqueio
if (bloqueioJudicial)
    GravarBloqueioJudicialLiberar(dataSistema, request.premiacao, request.CodigoGanhador, user.Codigo);

private void GravarBloqueioJudicialLiberar(DateTime dataOcorrencia, int codigoPremiacao, string codigoPessoa, string? codigoUsuario)
{
    var bj = _context.cli_bloqueio_judicial.FirstOrDefault(bj => bj.cod_pess == codigoPessoa && bj.dta_ini_vig <= dataOcorrencia && bj.dta_fim_vig >= dataOcorrencia);
    var premiacao = _context.cap_premiacao.FirstOrDefault(p => p.cod_prm == codigoPremiacao);
    var bjl = _context.cap_bloqueio_judicial_liberar.FirstOrDefault(bjl => bjl.cod_bloq == bj.id_bloq
                && bjl.cod_ctr == premiacao.cod_ctr
                && bjl.cod_ems == premiacao.cod_ems);

    if (bjl == null)
    {
        _context.cap_bloqueio_judicial_liberar.Add(new cap_bloqueio_judicial_liberar()
        {
            cod_bloq = bj.id_bloq,
            cod_ori = "GR",
            cod_opr = "PM",
            val_opr = 0,
            cod_ctr = premiacao.cod_ctr,
            cod_ems = premiacao.cod_ems,
            num_tit = 0,
            flg_lib = 0,
            des_motivo = "",
            dta_lib = null,
            dta_inc = DateTime.Now,
            cod_usu_lib = codigoUsuario
        });
    }
}

```

**New:**
```csharp
// Status "SO" hardcoded, sem checagem de bloqueio judicial
var beneficiario = await _beneficiarioService.CreateBeneficiarioPremiacaoPorPagamento(..., "SO");
var portalSolicitacao = await CriarPortalSolicitacao(premiacao, beneficiario, false, "SO");
// GravarBloqueioJudicialLiberar: não existe equivalente
```

**Impacto:** Premiações com bloqueio judicial são processadas como "SO" em vez de "BJ". O registro em `cap_bloqueio_judicial_liberar` nunca é criado.

---

### 2. Pagamento a Terceiro (PagTerceiro) — CRÍTICO

**Old:** Fluxo completo quando `PagTerceiro == "S"`:
- Cria/busca pessoa do terceiro em `cli_pessoa`
- Gerencia dados bancários do terceiro em `cli_dados_financeiros`
- Atualiza JSON com dados do terceiro
- Popula `cap_ben_prem.PagTerceiro`, `CodigoPessoaTerceiro`, `DadosFinanceiroTerceiro`

**New:**
```csharp
PagTerceiro = "N",  // sempre "N", sem qualquer lógica de terceiro
```

**Impacto:** Premiações com pagamento a terceiro não são suportadas.

---

### 3. `GravaCessionarioTitulo` — não chamado

**Old:**
```csharp
var premiacao = _context.cap_premiacao.FirstOrDefault(a => a.cod_prm == request.premiacao);
var capTitulo = _context.cap_titulos.FirstOrDefault(a => a.Proposta == premiacao.cod_ctr && a.Emissao == premiacao.cod_ems);
GravaCessionarioTitulo(request.CodigoGanhador, premiacao.cod_ctr, capTitulo.NumeroTitulo, capTitulo.CodigoSerie);
```

**New:** Nenhuma chamada equivalente existe em `GerarPremiacao` nem em `CriarPortalSolicitacao`.

**Impacto:** `cap_cessionarios_titulo` nunca tem `CodigoPessoa` atualizado com o ganhador.

---

### 4. `cap_premiacao_historico` — não criado

**Old:**
```csharp
var historico = new cap_premiacao_historico()
{
    IdPremiacao = idPremiacaoPortal,
    DataMovimentacao = DateTime.Now,
    IdUsuario = user.CodigoPessoa.ToString(),
    Status = !bloqueioJudicial ? "AN" : "BJ",
    IdRelato = relato.Id
};
_context.cap_premiacao_historico.Add(historico);
```

**New:** Não há criação de `cap_premiacao_historico` no fluxo de `GerarPremiacao` nem em `CriarPortalSolicitacao`.

**Impacto:** Histórico de status da premiação não é registrado.

---

### 5. Fluxo quando `premiacao == 0` — não tratado

**Old:** Caminho alternativo completo com status "SA"/"BJ" e histórico próprio:
```csharp
else // premiacao == 0
{
    idPremiacaoPortal = CriaEntradaPortal(null, null, null, null, ..., !bloqueioJudicial ? "SA" : "BJ", ...);
    var historico = new cap_premiacao_historico { Status = !bloqueioJudicial ? "SA" : "BJ" };
    _context.cap_premiacao_historico.Add(historico);
}
```

**New:** `GerarPremiacao` assume sempre que `CodigoPremiacao != 0`. Caso contrário, o fluxo não é tratado.

---

### 6. `tip_prm_trib` — tipo tributação

**Old:**
```csharp
cap_ben_prem.tip_prm_trib = request.TipoPremiacao == "Bem" ? "B" : "D";
```

**New:**
```csharp
tip_prm_trib = "D",  // sempre "D"
```

**Impacto:** Premiações do tipo "Bem" são tributadas incorretamente como "D".

---

### 7. `tipo_pagamento` — discriminador TED/Conta Corrente

**Old:**
```csharp
cap_ben_prem.tipo_pagamento = request.TipoPremiacao == "TED" || request.TipoPremiacao == tipoResgateContaCorrente ? 2 : null;
```

**New:**
```csharp
tipo_pagamento = null,  // sempre null
```

**Impacto:** TED e Resgate Conta Corrente não são sinalizados com `tipo_pagamento = 2`.

---

### 8. Status do Relato

**Old:** Status baseado em bloqueio judicial + valor líquido do ganhador.

**New (`CriarPortalSolicitacao`):**
```csharp
await _relatoService.CreateRelatoPremiacao(..., isPagamentoImediato ? "PG" : "EP");
// GerarPremiacao passa isPagamentoImediato = false → sempre "EP"
```

**Impacto:** O status do relato ignora bloqueio judicial. Verificar se "EP" cobre os casos que antes eram "AN"/"BJ"/"SA".


## Resumo dos Gaps

| # | Gap | Risco |
|---|---|---|
| 1 | Bloqueio judicial não verificado — status sempre "SO", sem `GravarBloqueioJudicialLiberar` | Alto |
| 2 | Pagamento a terceiro (`PagTerceiro`) não suportado | Alto |
| 3 | `GravaCessionarioTitulo` não chamado | Alto |
| 4 | `cap_premiacao_historico` não criado | Médio |
| 5 | Fluxo `premiacao == 0` não tratado | Alto |
| 6 | `tip_prm_trib` hardcoded "D" — tipo "Bem" não tratado | Médio |
| 7 | `tipo_pagamento` sempre null — TED/CC não sinalizados | Médio |
| 8 | Status do relato ignora bloqueio judicial | Baixo |
