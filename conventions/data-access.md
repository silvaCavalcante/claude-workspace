---
title: Convenções de Acesso a Dados
status: active
last-reviewed: 2026-05-18
---

# Convenções de Acesso a Dados

Padrões para entidades EF Core, DTOs, ViewModels, mapeamento e repositórios nos microsserviços .NET 8 do CoreonCap. **Não aplicar** ao código legado em `CoreonCap\net\*` (ADO.NET / SQL direto / Web Forms).

---

## Entidades EF Core

### Localização

```
{Serviço}.Infra.Data/Entities/{Subpasta}/{Nome}.cs
```

Exemplos reais:
- `Coreon.Arquivo.Infra.Data/Entities/TkgsCap/cap_premiacao.cs` (snake_case espelhando a tabela legada).
- `Coreon.Arquivo.Domain/Entities/ImportarArquivoErroEntity.cs` (PascalCase com sufixo `Entity` quando é tabela criada pelo serviço).

> **Padrão misto justificado.** Tabelas pré-existentes do banco TkgsCap mantêm o nome original (`cap_premiacao`, `api_hash_arquivo`, `cli_pessoa`). Tabelas novas criadas pelo serviço usam PascalCase + sufixo `Entity`.

### Estrutura padrão (tabela nova)

```csharp
public class ImportarArquivoErroEntity
{
    public Guid Id { get; set; }
    public Guid ImportarArquivoId { get; set; }
    public string Mensagem { get; set; } = string.Empty;
    public string Status { get; set; } = "A";          // "A" ativo, "D" deletado
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}
```

**Regras (tabelas novas):**
- Soft delete por `Status = "A"/"D"` quando aplicável.
- `CreatedAt` obrigatório; `UpdatedAt` nullable.
- Strings inicializadas com `= string.Empty`.
- Collections inicializadas no campo (`= new List<T>()`).

### Regra absoluta

Entidades **não saem** da camada `Infra.Data`. Sempre converter para DTO antes de subir para `Domain` ou `Api`.

---

## DTOs (transferência interna)

`{Serviço}.Domain/Dto/{Nome}Dto.cs`

```csharp
// Coreon.Arquivo.Domain/Dto/HashRequestDto.cs
public class HashRequestDto
{
    public string Hash { get; set; } = string.Empty;
    public Guid ParceiroId { get; set; }
}
```

Outros exemplos reais: `HashResponseDto`, `ImporteResponseDto`, `ProcessarContempladosDto`, `ContempladoItemDto`.

---

## ViewModels (Request / Response)

```
{Serviço}.Domain/ViewModel/Request/{Nome}Request.cs
{Serviço}.Domain/ViewModel/Response/{Nome}Response.cs
```

Em alguns serviços, request/response são chamados diretamente de `{Nome}Dto` quando o DTO é também o contrato de API — ambos os padrões existem no repo. Quando houver formato distinto entre interno e externo, usar o sufixo `Request`/`Response`.

---

## Mapeamento

**Preferência:** Mapster (`.Adapt<T>()`) para código novo. AutoMapper coexiste no repositório (ex.: `Coreon.Arquivo.Domain/AutoMapper/ArquivoErroMappingProfile.cs`) — não substituir AutoMapper existente sem motivo, mas não introduzir AutoMapper em código novo.

```csharp
using Mapster;

var dto = entity.Adapt<ImportarArquivoDto>();          // Entity → DTO
var dto = request.Adapt<ImportarArquivoDto>();         // Request → DTO
return dto.Adapt<ImporteResponseDto>();                // DTO → Response
var lista = entities.Adapt<List<ImportarArquivoDto>>(); // Lista
```

Configuração custom: `TypeAdapterConfig` no `Infra.IoC` apenas se necessário. Evitar configurações globais.

---

## DbContext

```
{Serviço}.Infra.Data/Context/{Nome}Context.cs
```

Exemplos reais: `Coreon.Premiacao.Repository/Context/CapContext.cs`, `Coreon.Arquivo.Infra.Data/Context/CapContext.cs`.

```csharp
public class CapContext : DbContext
{
    public DbSet<ImportarArquivoErroEntity> ImportarArquivoErros { get; set; }
    public DbSet<api_hash_arquivo> ApiHashArquivos { get; set; }

    public CapContext(DbContextOptions<CapContext> options) : base(options) { }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        modelBuilder.ApplyConfigurationsFromAssembly(Assembly.GetExecutingAssembly());
    }
}
```

Configurações Fluent API em arquivos `IEntityTypeConfiguration<T>` separados, em `Infra.Data/Configurations/`.

---

## Repositórios

```
{Serviço}.Infra.Repository/{Nome}Repository.cs
```

Exemplos reais: `ParceiroRepository`, `HashArquivoRepository`, `ImportarArquivoErroRepository`.

```csharp
public class HashArquivoRepository : IHashArquivoRepository
{
    private readonly CapContext _context;

    public HashArquivoRepository(CapContext context) => _context = context;

    public async Task<PagedResult<HashArquivoDto>> GetAllAsync(PaginationParameters p)
    {
        var query = _context.ApiHashArquivos.AsNoTracking();
        var paged = await query.ApplyPaginationAndOrderingAsync(p);
        return new PagedResult<HashArquivoDto>
        {
            PageNumber = paged.PageNumber,
            PageSize   = paged.PageSize,
            TotalCount = paged.TotalCount,
            TotalPages = paged.TotalPages,
            Data       = paged.Data?.Adapt<List<HashArquivoDto>>()
        };
    }

    public async Task<bool> SoftDeleteAsync(Guid id)
    {
        var entity = await _context.ApiHashArquivos.FindAsync(id);
        if (entity == null) return false;
        entity.Status = "D";
        entity.UpdatedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();
        return true;
    }
}
```

**Regras:**
- Sempre `AsNoTracking()` em queries de leitura.
- `Include` explícito apenas para navigation properties realmente usadas.
- Paginação via extension `ApplyPaginationAndOrderingAsync` (em `Infra.Repository/Extensions/`).
- Soft delete: `Status = "D"` + `UpdatedAt = DateTime.UtcNow`.

---

## Seed

`Infra.Data/DatabaseSeeder.cs` — chamado no `Program.cs`. Só seedear o **mínimo absoluto** que o serviço precisa para subir (ex.: roles iniciais, registros de configuração que o app espera existir).
