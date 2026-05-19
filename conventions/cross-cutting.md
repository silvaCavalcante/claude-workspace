---
title: Convenções de Cross-Cutting
status: active
last-reviewed: 2026-05-18
---

# Convenções de Cross-Cutting

Padrões para JWT, logging de auditoria, clientes HTTP externos (Refit) e middlewares — componentes que atravessam múltiplas camadas dos microsserviços .NET 8 do CoreonCap.

---

## JWT e Claims

### Extração de claims

`IClaimsManager` (em `{Serviço}.Infra.CrossCutting/BuildOptions/`) é a porta para acessar claims do token dentro de serviços de domínio. **Nunca** acessar `IHttpContextAccessor` direto a partir do `Domain`.

```csharp
public interface IClaimsManager
{
    string GetClaimValue(string claimType);
}

public class ClaimsManager : IClaimsManager
{
    private readonly IHttpContextAccessor _httpContextAccessor;

    public ClaimsManager(IHttpContextAccessor httpContextAccessor)
        => _httpContextAccessor = httpContextAccessor;

    public string GetClaimValue(string claimType)
    {
        var identity = _httpContextAccessor.HttpContext?.User.Identity as ClaimsIdentity;
        return identity?.Claims.FirstOrDefault(c => c.Type == claimType)?.Value ?? string.Empty;
    }
}
```

Uso em serviços:

```csharp
var userId = _claimsManager.GetClaimValue("UserId");
var email  = _claimsManager.GetClaimValue("Email");
```

### Configuração JWT

Em `{Serviço}.Api/Configurations/JwtAutenticationConfiguration.cs`. Pontos não-óbvios:

- `ValidateIssuerSigningKey`, `ValidateIssuer`, `ValidateAudience`, `ValidateLifetime` todos `true`.
- Claims de role chegam **separadas por vírgula** num único claim do tipo `http://schemas.microsoft.com/ws/2008/06/identity/claims/role`. O evento `OnTokenValidated` faz o split e adiciona como `ClaimTypes.Role`. Sem isso, `User.IsInRole(...)` falha.
- Settings (chave, issuer, audience) em `SigningSettings` lido de `appsettings.json` seção `SigningSettings`.

---

## Logging de auditoria

Logs de auditoria de negócio são publicados via RabbitMQ usando `ILogService` — **não** usar `ILogger<T>` para isso.

```csharp
await _logService.LogAsync("arquivo-logs", new LogModel
{
    Message       = "Arquivo importado",
    EntityId      = arquivo.Id.ToString(),
    OldEntityData = null,
    NewEntityData = JsonSerializer.Serialize(arquivo)
});
```

Campos de `LogModel`: `Message`, `EntityId`, `OldEntityData`, `NewEntityData`. `UserId`, `UserEmail`, `Ip` são injetados pelo `ILogService` via `IClaimsManager`.

`ILogger<T>` continua válido para logs técnicos (Serilog/Console). Auditoria de negócio = `ILogService`.

---

## Clientes HTTP externos (Refit)

Interfaces em `{Serviço}.Domain/Interfaces/RestClient/`. Exemplo real:

```csharp
// Coreon.Arquivo.Domain/Interfaces/RestClient/IPremiacaoApiClient.cs
public interface IPremiacaoApiClient
{
    [Get("/")]
    Task<BuscarPremiacaoPorCertificadoResponseDto> BuscarPorCertificadoAsync(
        [Query] short codigoProduto,
        [Query] int edicao,
        [Query] string certificado,
        [Query] DateTime dataSorteio);
}
```

### Registro

```csharp
// Em NativeInjectorBootStrapper.cs
services.AddRefitClient<IPremiacaoApiClient>()
    .ConfigureHttpClient(c => c.BaseAddress = new Uri(configuration["PremiacaoApi:BaseUrl"]!));

// Com propagação de Bearer token (chamadas entre microsserviços internos):
services.AddRefitClient<IPessoaClient>()
    .ConfigureHttpClient(c => c.BaseAddress = new Uri(configuration["PessoaApi:BaseUrl"]!))
    .AddHttpMessageHandler<AuthenticatedHttpClientHandler>();

services.AddTransient<AuthenticatedHttpClientHandler>();
```

### AuthenticatedHttpClientHandler

Em `{Serviço}.Infra.CrossCutting/Extensions/`. Lê o header `Authorization` do request entrante e propaga para o request saínte. **Usar em todo cliente HTTP que chama outro microsserviço Coreon.** **Não usar** em APIs externas públicas.

```csharp
public class AuthenticatedHttpClientHandler : DelegatingHandler
{
    private readonly IHttpContextAccessor _httpContextAccessor;
    public AuthenticatedHttpClientHandler(IHttpContextAccessor http) => _httpContextAccessor = http;

    protected override async Task<HttpResponseMessage> SendAsync(
        HttpRequestMessage request, CancellationToken ct)
    {
        var token = _httpContextAccessor.HttpContext?
            .Request.Headers["Authorization"].ToString().Replace("Bearer ", "");
        if (!string.IsNullOrEmpty(token))
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        return await base.SendAsync(request, ct);
    }
}
```

> **Pendente (spec future):** retry HTTP transitório via Polly nos `RestClient` Refit — ver `specs/features/future/2026-05-04-retry-http-transitorio-rest-clients.md`. Não usar implementação ad-hoc enquanto a spec não for executada.

---

## ExceptionHandlingMiddleware

Em `{Serviço}.Api/Middlewares/ExceptionHandlingMiddleware.cs`. Deve ser registrado **antes** de `MapControllers`:

```csharp
public class ExceptionHandlingMiddleware
{
    private readonly RequestDelegate _next;
    public ExceptionHandlingMiddleware(RequestDelegate next) => _next = next;

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            context.Request.EnableBuffering();
            await _next(context);
        }
        catch (ApplicationException ex)
        {
            await Write(context, ex.Message, StatusCodes.Status400BadRequest);
        }
        catch (Exception)
        {
            await Write(context, "Ocorreu um erro interno no servidor.",
                StatusCodes.Status500InternalServerError);
        }
    }

    private static Task Write(HttpContext ctx, string msg, int code)
    {
        ctx.Response.StatusCode = code;
        ctx.Response.ContentType = "application/json";
        return ctx.Response.WriteAsJsonAsync(new { message = msg });
    }
}
```
