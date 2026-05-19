# Verificação: GerarPremiacao

> Substitua os parâmetros antes de executar.
>
> | Parâmetro | Descrição |
> |---|---|
> | `{cod_prm}` | Código da premiação |
> | `{cod_ctr}` | Código do contrato/proposta |
> | `{cod_ems}` | Código de emissão |
> | `{cod_pess}` | Código de pessoa do ganhador |
> | `{data_sistema}` | Data do processamento (formato: `'YYYY-MM-DD'`) |

---

## 1. `cap_premiacao` — Status da premiação atualizado

Após o processo, a premiação deve ter `cod_sts_srd = 'SO'`, IR total calculado e valor bruto sem IR preenchidos.

```sql
SELECT
    cod_prm,
    cod_sts_srd,
    cod_usr_cfr_pmc,
    val_ire_tot,
    val_pmc_brt_sir,
    val_pre_sto_brt
FROM cap_premiacao
WHERE cod_prm = {cod_prm};
```

**Esperado:**
- `cod_sts_srd = 'SO'`
- `cod_usr_cfr_pmc` preenchido (`'0001'`)
- `val_ire_tot` = soma dos IRs do beneficiário
- `val_pmc_brt_sir` = `val_pre_sto_brt - val_ire_tot`

---

## 2. `cap_beneficiarios_premiacao` — Beneficiário criado corretamente

Verifica se o registro do beneficiário foi gerado com os campos críticos corretos.

```sql
SELECT
    cod_prm,
    num_seq_bfr_pmc,
    cod_psa_pmd,
    cod_sts_pgm_pmc,
    tip_prm_trib,
    tipo_pagamento,
    PagTerceiro,
    CodigoPessoaTerceiro,
    DadosFinanceiroTerceiro,
    val_pre_brt,
    val_pre_lqd,
    val_ire,
    val_ire2,
    dat_sts_pgm_pmc
FROM cap_beneficiarios_premiacao
WHERE cod_prm = {cod_prm}
ORDER BY num_seq_bfr_pmc DESC;
```

**Esperado (cenário sem bloqueio, pagamento em dinheiro, sem TED):**
- `cod_sts_pgm_pmc = 'SO'`
- `tip_prm_trib = 'D'`
- `tipo_pagamento = NULL`
- `PagTerceiro = 'N'`

**Esperado (cenário com bloqueio judicial):**
- `cod_sts_pgm_pmc = 'BJ'`

**Esperado (premiação do tipo "Bem"):**
- `tip_prm_trib = 'B'`

**Esperado (pagamento via TED — FormaPagamento = 5):**
- `tipo_pagamento = 2`

---

## 3. `portal_solicitacao_premiacao` — Portal criado com status correto

Verifica se a solicitação foi registrada no portal com o status correspondente ao cenário.

```sql
SELECT
    Id,
    Premiacao,
    Proposta,
    Emissao,
    CodigoPessoa,
    cod_sts_pgm_pmc,
    ValorTotal,
    ValorLiquido,
    ImpostodeRenda,
    DataSolicitacao
FROM portal_solicitacao_premiacao
WHERE Premiacao = {cod_prm}
ORDER BY DataSolicitacao DESC;
```

**Esperado:**
- Registro presente com `Premiacao = {cod_prm}`
- `cod_sts_pgm_pmc = 'SO'` (sem bloqueio) ou `'BJ'` (com bloqueio)
- `CodigoPessoa` = código do ganhador
- `ValorTotal`, `ValorLiquido` e `ImpostodeRenda` preenchidos

---

## 4. `cap_relato` — Relato criado

Verifica se o relato vinculado à solicitação foi gerado.

```sql
SELECT
    r.Id,
    r.Proposta,
    r.Motivo,
    r.Descricao,
    r.DataInclusao,
    r.UsuarioInclusao
FROM cap_relato r
INNER JOIN portal_solicitacao_premiacao p ON p.Id = r.Id
WHERE p.Premiacao = {cod_prm}
ORDER BY r.DataInclusao DESC;
```

**Esperado:**
- Pelo menos 1 registro presente
- `Proposta = {cod_ctr}`

---

## 5. `cap_premiacao_historico` — Histórico com status correto

Verifica se o histórico foi criado com o status adequado ao cenário.

```sql
SELECT
    h.Id,
    h.IdPremiacao,
    h.Status,
    h.DataMovimentacao,
    h.IdUsuario,
    h.IdRelato
FROM cap_premiacao_historico h
INNER JOIN portal_solicitacao_premiacao p ON p.Id = h.IdPremiacao
WHERE p.Premiacao = {cod_prm}
ORDER BY h.DataMovimentacao DESC;
```

**Esperado:**
- `Status = 'AN'` (premiação sem bloqueio judicial)
- `Status = 'BJ'` (premiação com bloqueio judicial)
- `IdRelato` referenciando o relato criado

---

## 6. `cli_bloqueio_judicial` — Bloqueio judicial vigente na data

Use para confirmar se a pessoa possui bloqueio ativo na data do processamento antes de verificar os próximos passos.

```sql
SELECT
    id_bloq,
    cod_pess,
    flg_sit,
    dta_ini_vig,
    dta_fim_vig,
    dsc_obs
FROM cli_bloqueio_judicial
WHERE cod_pess = '{cod_pess}'
  AND dta_ini_vig <= '{data_sistema}'
  AND dta_fim_vig >= '{data_sistema}';
```

**Esperado:**
- **Com bloqueio:** retorna 1 registro (confirma que o cenário BJ deve ter sido ativado)
- **Sem bloqueio:** retorna 0 registros (confirma cenário SO)

---

## 7. `cap_bloqueio_judicial_liberar` — Registro de pendência gerado

Quando há bloqueio, o processo deve ter criado um registro com `flg_lib = 0` sinalizando pendência de liberação.

```sql
SELECT
    bjl.id_idf,
    bjl.cod_bloq,
    bjl.cod_ori,
    bjl.cod_opr,
    bjl.cod_ctr,
    bjl.cod_ems,
    bjl.flg_lib,
    bjl.des_motivo,
    bjl.dta_inc,
    bjl.cod_usu_lib
FROM cap_bloqueio_judicial_liberar bjl
INNER JOIN cli_bloqueio_judicial bj ON bj.id_bloq = bjl.cod_bloq
WHERE bj.cod_pess = '{cod_pess}'
  AND bjl.cod_ctr = {cod_ctr}
  AND bjl.cod_ems = {cod_ems}
ORDER BY bjl.dta_inc DESC;
```

**Esperado (cenário com bloqueio):**
- Registro presente com `flg_lib = 0`
- `cod_ori = 'GR'`
- `cod_opr = 'PM'`
- `cod_ctr = {cod_ctr}` e `cod_ems = {cod_ems}`

**Esperado (cenário sem bloqueio):**
- Nenhum registro novo deve ter sido inserido

---

## 8. `cap_cessionarios_titulo` — CodigoPessoa preenchido com o ganhador

Verifica se o campo `CodigoPessoa` do cessionário do título foi atualizado com o código do ganhador.

```sql
SELECT
    Id,
    NumeroProposta,
    NumeroTitulo,
    CodigoPessoa,
    TipoCessionario,
    StatusTitularesCessionarios,
    DataAlteracao
FROM cap_cessionarios_titulo
WHERE NumeroProposta = {cod_ctr}
ORDER BY DataAlteracao DESC;
```

**Esperado:**
- `CodigoPessoa = '{cod_pess}'` (ganhador preenchido)
- Se já estava preenchido antes do processo: não deve ter sido alterado (a lógica só preenche quando `CodigoPessoa IS NULL`)
