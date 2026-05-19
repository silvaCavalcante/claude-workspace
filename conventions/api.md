---
title: Convenções de API
status: active
last-reviewed: 2026-05-18
---

# Convenções de API

Padrões para Controllers, rotas, autorização e respostas HTTP nos microsserviços .NET 8 do CoreonCap (`Coreon.Arquivo.Api`, `Coreon.Premiacao.WebApi`, etc.). **Não aplicar** ao Portal_Vendas (Razor Pages) nem ao código legado em `CoreonCap\net\*` (WCF).

---

## Controllers

### Localização

```
{Serviço}.Api/Controllers/{Nome}Controller.cs
```

Exemplos reais: `Coreon.Arquivo.Api/Controllers/ArquivosController.cs`, `Coreon.Arquivo.Api/Controllers/HashesController.cs`.

### Estrutura padrão

```csharp
[ApiController]
[Route("[controller]")]
[Authorize]
public class ArquivosController : ControllerBase
{
    private readonly IArquivosService _arquivosService;

    public ArquivosController(IArquivosService arquivosService)
    {
        _arquivosService = arquivosService;
    }

    [HttpGet]
    [Route(ApplicationRoute.GET_BY_ID)]
    public async Task<IActionResult> GetById([FromQuery] Guid id)
    {
        if (!User.IsInRole("Arquivo.Get")) return Forbid();
        return Ok(await _arquivosService.GetByIdAsync(id));
    }

    [HttpPost]
    [Route(ApplicationRoute.CREATE)]
    public async Task<IActionResult> Create([FromBody] HashRequestDto request)
    {
        if (!User.IsInRole("Arquivo.Create")) return Forbid();
        return Ok(await _arquivosService.CreateAsync(request));
    }
}
```

**Regras:**
- Herda de `ControllerBase` (não `Controller`).
- `[ApiController]` + `[Route("[controller]")]` obrigatórios.
- `[Authorize]` no nível da classe; endpoints públicos usam `[AllowAnonymous]`.
- Autorização por role: `if (!User.IsInRole("Recurso.Ação")) return Forbid();`
- Sem lógica de negócio no controller — apenas delega ao serviço.
- Retornos: `Ok(...)`, `Forbid()` ou exceção para o middleware.

---

## Rotas

Constantes em `{Serviço}.Api/Utils/ApplicationRoute.cs`:

```csharp
public static class ApplicationRoute
{
    public const string GET_ALL    = "GetAll";
    public const string GET_BY_ID  = "GetById";
    public const string CREATE     = "Create";
    public const string UPDATE     = "Update";
    public const string DELETE     = "Delete";
}
```

Nunca usar strings de rota inline — sempre referenciar `ApplicationRoute`.

---

## Autorização

Roles no formato `{Recurso}.{Ação}` (ex.: `Arquivo.Get`, `Hash.Create`, `Premiacao.Update`). Claims de role extraídos do JWT pelo pipeline de autenticação configurado em `JwtAutenticationConfiguration.cs` e registrados como `ClaimTypes.Role`.

---

## Paginação

Endpoints de listagem recebem `PaginationParameters` via `[FromQuery]`:

```csharp
public class PaginationParameters
{
    public int PageNumber { get; set; } = 1;
    public int PageSize { get; set; } = 10;
    public string OrderBy { get; set; } = string.Empty;
    public bool IsAscending { get; set; } = true;
    public string FilterBy { get; set; } = string.Empty;
    public string FilterValue { get; set; } = string.Empty;
}

public class PagedResult<T>
{
    public int PageNumber { get; set; }
    public int PageSize { get; set; }
    public int TotalPages { get; set; }
    public int TotalCount { get; set; }
    public List<T>? Data { get; set; }
}
```

---

## Tratamento de exceções

Exceções **não** são tratadas no controller — sobem e são capturadas pelo `ExceptionHandlingMiddleware` (ver `cross-cutting.md`). Mapeamento padrão:

| Tipo | HTTP |
|---|---|
| `ApplicationException`, `ValidationException` | 400 |
| Outras | 500 (mensagem genérica) |

Resposta de erro: `{ "message": "..." }`.

---

## Middleware (ordem em `Program.cs`)

```csharp
app.UseAuthentication();
app.UseAuthorization();
app.UseMiddleware<ExceptionHandlingMiddleware>();
app.MapControllers();
```

Customizados em `{Serviço}.Api/Middlewares/`.

---

## Swagger

Configurado via extension em `{Serviço}.Api/Configuration/SwaggerConfiguration.cs`:

```csharp
builder.Services.AddSwaggerConfiguration();
app.UseSwaggerConfiguration();
```
