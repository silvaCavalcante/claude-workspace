---
title: Arquitetura Hexagonal — Ports & Adapters
status: active
last-reviewed: 2026-05-18
---

# Arquitetura Hexagonal — Ports & Adapters

Padrão arquitetural adotado nos microsserviços .NET 8 do CoreonCap. **Aplicável a:** `Coreon.Arquivo`, `CoreCap.Premiacao`, `Coreon.Pessoa`, `Coreon.Produto`, `Coreon.AnaliseRisco`, e novos microsserviços. **Não aplicável a:** `CoreonCap\net\*` (legado WCF/.NET Framework, ver `legacy-net-framework.md`), `Portal_Vendas` (Razor Pages), `Coreon.Premiacao` (estrutura mais antiga com `Repository`+`Services`+`WebApi`, sem `Domain` separado).

---

## Estrutura de projetos (canônica)

Referência viva: `Coreon.Arquivo/`.

```
{Serviço}/
├── src/
│   ├── {Serviço}.Domain/              # Núcleo: entidades, DTOs, portas, serviços
│   ├── {Serviço}.Api/                 # Adaptador de entrada: HTTP (controllers, middlewares)
│   ├── {Serviço}.Backgroud/           # Adaptador de entrada: consumers RabbitMQ
│   ├── {Serviço}.Infra.Data/          # Adaptador de saída: DbContext, entidades EF
│   ├── {Serviço}.Infra.Repository/    # Adaptador de saída: implementações de repositório
│   ├── {Serviço}.Infra.IoC/           # Registro de DI (NativeInjectorBootStrapper)
│   └── {Serviço}.Infra.CrossCutting/  # JWT, ClaimsManager, AuthenticatedHttpClientHandler
└── {Serviço}.UnitTests/                # xUnit (opcional, ao lado de src/)
```

> A pasta de Background no `Coreon.Arquivo` está como `Backgroud` (sem o "n"). É o nome real do projeto — não corrigir até que a spec autorize o rename.

---

## Domain

`{Serviço}.Domain` **não tem dependência de nenhum outro projeto** da solução. Tudo o que a aplicação precisa "saber o que fazer" vive aqui.

### Estrutura interna

```
{Serviço}.Domain/
├── Configurations/        # *Settings.cs (RabbitMqSettings, SigningSettings)
├── Dto/                   # DTOs internos (HashRequestDto, ProcessarContempladosDto)
├── Enums/                 # Enums de domínio (ModeloImportacaoEnum)
├── Interfaces/
│   ├── Services/          # Portas de serviço (IArquivosService, IHashesService)
│   ├── Repository/        # Portas de repositório (IHashArquivoRepository)
│   ├── Messaging/         # Portas de publisher RabbitMQ
│   └── RestClient/        # Portas de clientes HTTP externos (IPremiacaoApiClient)
├── Messaging/             # Implementações de publishers
├── Models/                # PagedResult, PaginationParameters
├── Services/              # Implementações dos serviços (ArquivosService)
└── ViewModel/
    ├── Request/
    └── Response/
```

### Portas (interfaces)

Vivem em `Domain/Interfaces/`. A infra implementa, o domínio nunca depende de implementação concreta.

```csharp
public interface IHashesService
{
    Task<HashResponseDto> GerarAsync(HashRequestDto request);
    Task<bool> ValidarAsync(string hash);
}

public interface IHashArquivoRepository
{
    Task<HashArquivoDto?> GetByHashAsync(string hash);
    Task<HashArquivoDto> CreateAsync(HashArquivoDto dto);
}
```

### Serviços de domínio

Implementações em `Domain/Services/`. Orquestram repositórios, publishers e clientes — sempre via interface.

```csharp
public class HashesService : IHashesService
{
    private readonly IHashArquivoRepository _repository;
    private readonly ILogService _logService;

    public HashesService(IHashArquivoRepository repository, ILogService logService)
    {
        _repository = repository;
        _logService = logService;
    }

    public async Task<HashResponseDto> GerarAsync(HashRequestDto request)
    {
        var existing = await _repository.GetByHashAsync(request.Hash);
        if (existing != null)
            throw new ApplicationException("Hash ja cadastrado.");

        var dto = request.Adapt<HashArquivoDto>();
        var created = await _repository.CreateAsync(dto);
        return created.Adapt<HashResponseDto>();
    }
}
```

---

## Infra.Repository

Implementa as portas `IHashArquivoRepository`, `IParceiroRepository` etc. — ver `data-access.md`.

---

## Infra.Data

`DbContext`, entidades EF Core, migrations. Entidades nunca cruzam essa fronteira — ver `data-access.md`.

---

## Infra.IoC

Único ponto de registro de dependências. Expõe `NativeInjectorBootStrapper.RegisterServices(services, configuration)`.

```csharp
public static class NativeInjectorBootStrapper
{
    public static void RegisterServices(IServiceCollection services, IConfiguration configuration)
    {
        // Settings
        services.Configure<RabbitMqSettings>(configuration.GetSection("RabbitMqSettings"));

        // DbContext
        services.AddDbContext<CapContext>(options =>
            options.UseSqlServer(configuration.GetConnectionString("DefaultConnection")),
            ServiceLifetime.Transient);

        // Singletons
        services.AddSingleton<IHttpContextAccessor, HttpContextAccessor>();
        services.AddSingleton<IClaimsManager, ClaimsManager>();

        // Serviços de domínio
        services.AddScoped<IArquivosService, ArquivosService>();
        services.AddScoped<IHashesService, HashesService>();

        // Repositórios
        services.AddTransient<IHashArquivoRepository, HashArquivoRepository>();
        services.AddTransient<IParceiroRepository, ParceiroRepository>();

        // Publishers
        services.AddScoped<IRabbitMqArquivoPublisher, RabbitMqArquivoPublisher>();

        // Clientes HTTP
        services.AddRefitClient<IPremiacaoApiClient>()
            .ConfigureHttpClient(c => c.BaseAddress = new Uri(configuration["PremiacaoApi:BaseUrl"]!));

        services.AddRefitClient<IPessoaClient>()
            .ConfigureHttpClient(c => c.BaseAddress = new Uri(configuration["PessoaApi:BaseUrl"]!))
            .AddHttpMessageHandler<AuthenticatedHttpClientHandler>();

        services.AddTransient<AuthenticatedHttpClientHandler>();
    }
}
```

**Lifetimes padrão:**

| Componente | Lifetime |
|---|---|
| `IHttpContextAccessor`, `IClaimsManager` | Singleton |
| Serviços de domínio | Scoped |
| Publishers RabbitMQ | Scoped |
| Repositórios, `DbContext` | Transient |

---

## Regras de dependência

```
Api           → Domain
Backgroud     → Domain
Domain        → (nenhum projeto interno)
Infra.*       → Domain (implementam portas)
Infra.IoC     → todos (monta o grafo)
```

**Nunca** adicionar referência de `Domain` para `Infra.*`. Esta inversão é o coração da arquitetura. Code review marca como `[BLOCK]`.

---

## Soft Delete

Por convenção, entidades com soft delete usam campo `Status`: `"A"` (ativo) / `"D"` (deletado). Queries filtram `Status == "A"`. Método de repositório: `SoftDeleteAsync`. Nem todas as tabelas legadas (TkgsCap) seguem esse padrão — verificar a coluna real antes.
