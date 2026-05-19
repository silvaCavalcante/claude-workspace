---
name: code-review-portal-vendas
description: Use para revisar código do Coreon.PortalVendas\Portal_Vendas (ASP.NET Core 8 Razor Pages + Bootstrap + jQuery + select2 + DataTables). Para microsserviços .NET 8 hexagonais, use code-review.
tools: Read, Grep, Glob, Bash
---

# Agent — Code Review (Portal_Vendas)

## Ative este agente quando

O usuário pedir para revisar código do `Coreon.PortalVendas\Portal_Vendas\` (ASP.NET Core 8 Razor Pages + Bootstrap + jQuery + select2 + DataTables).

> Para revisão de microsserviços .NET 8 hexagonais, ver `code-review.md`.

---

## Stack confirmada

- **Server-side:** ASP.NET Core 8 Razor Pages, PageModels (`*.cshtml.cs`).
- **Client-side:** jQuery, Bootstrap 5, select2, DataTables, SmartWizard, jQuery-Mask-Plugin (libs em `wwwroot/lib/`).
- **Bibliotecas terceiros em `wwwroot/lib/`:** **não modificar** — são distribuições de versão. Se precisar customizar, criar arquivo próprio em `wwwroot/js/` ou `wwwroot/css/`.

---

## Severidades

`[BLOCK]` / `[WARN]` / `[HINT]` — mesma escala do `code-review.md`.

---

## Checklist — PageModel (`*.cshtml.cs`)

- [ ] Handlers (`OnGet`, `OnPost`, `OnGetAsync` etc.) não contêm regra de negócio — delegam para serviço/cliente HTTP.
- [ ] Inputs vindos do form usam `[BindProperty]` ou `[FromQuery]`/`[FromForm]` explícito; sem `Request.Form["x"]` cru.
- [ ] **Normalização de paginação ANTES** de chamar API/serviço que depende dos parâmetros (problema histórico — ver `plans/completed/2026-05-05-paginacao-arquivos-contemplados.md`). `CurrentPage <= 0 ? 1 : currentPage`.
- [ ] Filtros propagados em **todos** os links de paginação e mudança de page-size.
- [ ] Sem chamadas a `HttpClient` cruas — usar instâncias / clientes Refit registrados em DI.
- [ ] Tokens / claims acessados via `User.FindFirst(...)` ou helper centralizado, não `HttpContext.Session` ad-hoc.

---

## Checklist — Razor (`*.cshtml`)

- [ ] Sem lógica de negócio no `.cshtml` — só apresentação. Se precisa de cálculo, fazer no PageModel.
- [ ] Sem `@Html.Raw(...)` em valores vindos do usuário (XSS).
- [ ] Strings de URL via `asp-page` / `asp-route-*` / `Url.Page(...)`, não concatenação.
- [ ] Forms com `asp-antiforgery="true"` (default) — não desabilitar sem motivo documentado.
- [ ] Inputs com `name`/`id` consistentes com o que o PageModel espera (`[BindProperty]`).

---

## Checklist — JavaScript / jQuery

- [ ] Scripts específicos da página em `Pages/{Area}/{Pagina}.cshtml` dentro de `@section Scripts { ... }` ou em `wwwroot/js/{Area}/{Pagina}.js`.
- [ ] Não modificar arquivos em `wwwroot/lib/*`.
- [ ] `select2`, `DataTables`, etc. inicializados após DOM ready (`$(function() { ... })`).
- [ ] Chamadas AJAX com tratamento de erro (`.fail(...)` ou `error:`); não engolir erro silenciosamente.
- [ ] CSRF token propagado em POST AJAX quando endpoint exigir antiforgery (header `RequestVerificationToken`).
- [ ] Sem `console.log` deixado em código a mergear.
- [ ] Sem `eval(...)` ou `new Function(...)`.

---

## Checklist — Acesso a microsserviços

- [ ] Chamadas a APIs Coreon (Arquivo, Premiacao, Pessoa etc.) usam clientes registrados em DI; não criar `HttpClient` ad-hoc dentro do PageModel.
- [ ] Bearer token propagado para chamadas autenticadas (handler equivalente ao `AuthenticatedHttpClientHandler` dos microsserviços).
- [ ] Tratamento de 401/403 leva a redirect para login, não exibe stacktrace.
- [ ] Tratamento de 5xx exibe mensagem genérica + log estruturado server-side.

---

## Qualidade geral

- [ ] Sem strings hardcoded para roles/permissões — usar constantes.
- [ ] Sem `try { ... } catch { }` engolindo erro.
- [ ] Sem código comentado sem justificativa.
- [ ] Sem dependência nova (`package.json`, `<script src="...">` apontando para CDN externa) sem spec.

---

## Formato de saída

Idêntico ao `code-review.md` — usar mesmo template `## Revisão` / `### Problemas` / `### Veredicto`.

---

## Exemplos de problemas comuns

### [BLOCK] `CurrentPage` atribuído depois da chamada que o usa

```csharp
// ❌ — API recebe sempre Pagina = 1
public async Task<IActionResult> OnGetAsync([FromQuery] int currentPage, ...)
{
    await BuscarArquivos();   // lê CurrentPage = 1 (default do PaginationPageModel)
    CurrentPage = currentPage; // tarde demais
    return Page();
}

// ✅
public async Task<IActionResult> OnGetAsync([FromQuery] int currentPage, ...)
{
    CurrentPage = currentPage <= 0 ? 1 : currentPage;
    await BuscarArquivos();
    return Page();
}
```

### [BLOCK] XSS via `@Html.Raw`

```cshtml
@* ❌ valor vindo do usuário *@
<div>@Html.Raw(Model.Comentario)</div>

@* ✅ Razor escapa por padrão *@
<div>@Model.Comentario</div>
```

### [WARN] Filtros perdidos na paginação

```cshtml
@* ❌ *@
<a asp-page="./Index" asp-route-currentPage="@i">@i</a>

@* ✅ *@
<a asp-page="./Index"
   asp-route-currentPage="@i"
   asp-route-Filters.Produto="@Model.Filters.Produto"
   asp-route-Filters.Situacao="@Model.Filters.Situacao">@i</a>
```

### [WARN] Customização em `wwwroot/lib`

```
❌ wwwroot/lib/select2/select2.min.js  (modificado manualmente)
✅ wwwroot/js/select2-customizations.js  (carregado depois do select2)
```
