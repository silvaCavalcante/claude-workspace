# Fixtures — CNPJs alfanuméricos válidos pré-calculados

DV calculado pelo algoritmo SERPRO (ASCII−48, pesos 2–9, módulo 11).
Pesos DV1 = `[5,4,3,2,9,8,7,6,5,4,3,2]`; pesos DV2 = `[6,5,4,3,2,9,8,7,6,5,4,3,2]`.

## Válidos — uso nos cenários

| ID | Sanitizado | Formatado | Uso |
|---|---|---|---|
| CA-01 | `12ABC34501DE35` | `12.ABC.345/01DE-35` | Canônico (S1, S2.1 Distribuidor) |
| CA-02 | `AB123CD456EF80` | `AB.123.CD4/56EF-80` | S2.2 Holding |
| CA-03 | `COREON00000178` | `CO.REO.N00/0001-78` | S2.3 Loja |
| CA-04 | `QA01PORTAL0169` | `QA.01P.ORT/AL01-69` | S2.4 Imobiliária |
| CA-05 | `WX9YZ8A7B6C562` | `WX.9YZ.8A7/B6C5-62` | S2.5 Representante |
| CA-06 | `11222333AAAA35` | `11.222.333/AAAA-35` | S2.6 Produtor |
| CA-07 | `00ABC11122BB92` | `00.ABC.111/22BB-92` | S5.1 Premiação |
| CA-08 | `TEST0000000186` | `TE.ST0.000/0001-86` | S5.2 ImportarArquivo / S5.4 GestaoHash |

## Numérico legado (retrocompat)

| ID | Sanitizado | Formatado | Uso |
|---|---|---|---|
| CN-01 | `11222333000181` | `11.222.333/0001-81` | S3.* todas as telas |

## Inválidos — uso em asserts de rejeição (S1)

| ID | Valor | Motivo |
|---|---|---|
| INV-01 | `00000000000000` | Sequência repetida |
| INV-02 | `12ABC34501DEAB` | Letras nas posições 13–14 (DV deve ser numérico) |
| INV-03 | `12.ABC.345/01DE-99` | DV correto seria `35`; com `99` é inválido |
| INV-04 | `12ABC` | Comprimento < 14 |
| INV-05 | (vazio) | Comportamento: rule retorna `true` (campo `[Required]` separado é quem rejeita) |

## Helper — gerar mais CNPJs válidos

Cole em `browser_evaluate` (ou em qualquer console JS):

```javascript
((base) => {
  const p1=[5,4,3,2,9,8,7,6,5,4,3,2], p2=[6,5,4,3,2,9,8,7,6,5,4,3,2];
  const calc=(s,p)=>{let v=0;for(let i=0;i<s.length;i++)v+=(s.charCodeAt(i)-48)*p[i];const r=v%11;return r<2?0:11-r;};
  const d1=calc(base,p1), d2=calc(base+d1,p2);
  return base+d1+d2;
})('SUASTRING12C')  // exatamente 12 caracteres A–Z ou 0–9
```

Resultado: 14 caracteres sanitizados (12 base + 2 DV numéricos).
