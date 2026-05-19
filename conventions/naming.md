---
title: Convenções de Nomenclatura
status: active
last-reviewed: 2026-05-18
---

# Convenções de Nomenclatura

Padrões de nomes para os microsserviços .NET 8 do CoreonCap (`Coreon.Arquivo`, `Coreon.Premiacao`, `CoreCap.Premiacao`, `Coreon.Pessoa`, `Coreon.Produto` etc.). Seguir para manter consistência. **Não aplicar** ao código legado em `CoreonCap\net\*` (WCF/.NET Framework).

---

## Classes e Interfaces

| Elemento | Padrão | Exemplo |
|---|---|---|
| Interface de serviço (porta) | `I{Nome}Service` | `IArquivosService`, `IHashesService` |
| Interface de repositório (porta) | `I{Nome}Repository` | `IHashArquivoRepository`, `IImportarArquivoErroRepository` |
| Interface de publisher RabbitMQ | `IRabbitMq{Serviço}Publisher` | `IRabbitMqArquivoPublisher` |
| Interface de cliente REST | `I{ServiçoExterno}Api` ou `I{ServiçoExterno}Client` | `IPremiacaoApiClient`, `IPessoaClient` |
| Implementação de serviço | `{Nome}Service` | `ArquivosService`, `ProcessarPremiacaoService` |
| Implementação de repositório | `{Nome}Repository` | `HashArquivoRepository`, `ParceiroRepository` |
| Entidade de banco (EF Core) | `{Nome}Entity` (PascalCase) **ou** snake_case espelhando a tabela | `ImportarArquivoErroEntity` (PascalCase); `cap_premiacao`, `api_hash_arquivo` (snake_case) |
| DTO (transferência interna) | `{Nome}Dto` | `HashRequestDto`, `ProcessarContempladosDto` |
| Request (entrada de API) | `{Nome}Request` ou `{Nome}RequestDto` | `HashRequestDto` |
| Response (saída de API) | `{Nome}Response` ou `{Nome}ResponseDto` | `HashResponseDto`, `ImporteResponseDto` |
| Mensagem RabbitMQ | `{Nome}Message` | `ResultadoProcessarGerarPremiacaoQueueMessage` |
| Classe de configuração | `{Nome}Settings` | `RabbitMqSettings` |
| Consumer (BackgroundService) | `{Nome}BackgroundService` | `GerarPremiacaoBackgroundService` |
| Controller | `{Nome}Controller` | `ArquivosController`, `HashesController` |
| Enum | `{Nome}` ou `{Nome}Enum` | `ModeloImportacaoEnum`, `Cargo`, `TipoPagamento` |

---

## Namespaces

Namespaces espelham a estrutura de pastas, sem abreviações:

```csharp
namespace Coreon.Arquivo.Domain.Interfaces.Services;
namespace Coreon.Arquivo.Infra.Data.Entities.TkgsCap;
namespace Coreon.Premiacao.Services.Dto.SolicitarPagamento;
```

- Nunca abreviar o nome do serviço no namespace (ex.: não usar `Cap.` para `Capitalizacao.` ou `Premio.` para `Premiacao.`).
- O namespace raiz é o nome do projeto (`Coreon.Arquivo`, `Coreon.Premiacao`, `CoreCap.Premiacao` etc.).

---

## Métodos

Métodos assíncronos terminam com `Async`:

```csharp
Task<PagedResult<UserDto>> GetAllAsync(PaginationParameters paginationParams);
Task<UserDto?> GetByIdAsync(Guid id);
Task<UserDto> CreateAsync(UserDto dto);
Task<bool> SoftDeleteAsync(Guid id);
Task SendEmailAsync(...);
```

Métodos de serviço de domínio (não repositório) não usam `Async` no nome da interface, mas podem ser async na implementação:

```csharp
// Interface de serviço
Task<UserResponse> Create(UserRequest user);
Task<bool> Delete(Guid id);

// Interface de repositório
Task<UserDto> CreateAsync(UserDto dto);
Task<bool> SoftDeleteAsync(Guid id);
```

---

## Arquivos

- Um arquivo por classe/interface
- Nome do arquivo = nome da classe
- Sem prefixos ou sufixos extras além dos definidos na tabela acima

---

## Constantes de rota

Definidas em `{Serviço}.WebApi/Utils/ApplicationRoute.cs` como `static class` com `const string`:

```csharp
public static class ApplicationRoute
{
    public const string GET_ALL     = "GetAll";
    public const string GET_BY_ID   = "GetById";
    public const string GET_BY_IDS  = "GetByIds";
    public const string CREATE      = "Create";
    public const string UPDATE      = "Update";
    public const string UPDATE_PARTIAL = "UpdatePartial";
    public const string DELETE      = "Delete";
}
```
