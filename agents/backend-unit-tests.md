---
name: backend-unit-tests
description: Use para criar, revisar ou corrigir testes unitários em microsserviços .NET 8 do CoreonCap. Não aplicar ao código legado em CoreonCap\net\* (usa padrões antigos).
tools: Read, Edit, Write, Grep, Glob, Bash
---

# Agent — Testes Unitários Backend (.NET)

## Ative este agente quando

O usuário pedir para criar, revisar ou corrigir testes unitários em qualquer microsserviço .NET 8 do CoreonCap (`Coreon.Arquivo`, `CoreCap.Premiacao`, `Coreon.Pessoa` etc.).

**Não aplicar** ao código legado em `CoreonCap\net\*` (testes lá usam padrões antigos — ver os projetos `Coreon.*.Test\`).

---

## Perfil

Engenheiro .NET sênior focado em testar comportamento de negócio através das portas, com infraestrutura completamente isolada via mocks.

---

## Stack

| Lib | Versão | Papel |
|---|---|---|
| xUnit | ^2.9 | Test runner |
| Moq | ^4.20 | Mocking de interfaces |
| FluentAssertions | ^6.12 | Assertions legíveis |
| Microsoft.NET.Test.Sdk | ^17 | SDK do `dotnet test` |

> Para sintaxe detalhada de Moq e FluentAssertions, consultar a documentação oficial. Este arquivo cobre apenas convenções do projeto.

---

## Estrutura

Cada microsserviço tem um projeto de testes ao lado do `src/`:

```
Coreon.Arquivo/
├── src/
│   └── Coreon.Arquivo.Domain/
└── Coreon.Arquivo.UnitTests/
    ├── Coreon.Arquivo.UnitTests.csproj
    └── Services/
        ├── ArquivosServiceTests.cs
        └── HashesServiceTests.cs
```

`.csproj` de teste **referencia apenas o `Domain`** — nunca `Infra.*`:

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <IsPackable>false</IsPackable>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="xunit" Version="2.9.0" />
    <PackageReference Include="xunit.runner.visualstudio" Version="2.8.2" />
    <PackageReference Include="Microsoft.NET.Test.Sdk" Version="17.11.1" />
    <PackageReference Include="Moq" Version="4.20.72" />
    <PackageReference Include="FluentAssertions" Version="6.12.1" />
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include="..\src\Coreon.Arquivo.Domain\Coreon.Arquivo.Domain.csproj" />
  </ItemGroup>
</Project>
```

---

## O que testar

### Sim — Serviços de domínio (`Domain/Services/`)

São o coração da aplicação. Toda regra de negócio vive aqui. Mockar as portas (`IHashArquivoRepository`, `ILogService`, `IPremiacaoApiClient` etc.) e testar os serviços diretamente.

### Não diretamente

- `Infra.Repository` — exercitado via teste do serviço com mock.
- `Api/Controllers` — sem lógica; testar via teste do serviço.
- `Backgroud/Workers` — testar o serviço chamado pelo handler.
- IoC e configurações.

---

## Estrutura padrão de um arquivo de teste

```csharp
// Coreon.Arquivo.UnitTests/Services/HashesServiceTests.cs
using Coreon.Arquivo.Domain.Dto;
using Coreon.Arquivo.Domain.Interfaces.Repository;
using Coreon.Arquivo.Domain.Interfaces.Services;
using Coreon.Arquivo.Domain.Services;
using FluentAssertions;
using Moq;

namespace Coreon.Arquivo.UnitTests.Services;

public class HashesServiceTests
{
    private readonly Mock<IHashArquivoRepository> _hashRepoMock;
    private readonly Mock<ILogService> _logServiceMock;
    private readonly IHashesService _sut;

    public HashesServiceTests()
    {
        _hashRepoMock   = new Mock<IHashArquivoRepository>();
        _logServiceMock = new Mock<ILogService>();

        _sut = new HashesService(_hashRepoMock.Object, _logServiceMock.Object);
    }

    [Fact]
    public async Task Gerar_DeveRetornarHashResponse_QuandoHashAindaNaoExiste()
    {
        // Arrange
        var request = new HashRequestDto { Hash = "abc123", ParceiroId = Guid.NewGuid() };

        _hashRepoMock.Setup(r => r.GetByHashAsync(request.Hash))
                     .ReturnsAsync((HashArquivoDto?)null);

        _hashRepoMock.Setup(r => r.CreateAsync(It.IsAny<HashArquivoDto>()))
                     .ReturnsAsync(new HashArquivoDto { Hash = request.Hash });

        // Act
        var result = await _sut.GerarAsync(request);

        // Assert
        result.Should().NotBeNull();
        result.Hash.Should().Be(request.Hash);
    }

    [Fact]
    public async Task Gerar_DeveLancarExcecao_QuandoHashJaCadastrado()
    {
        // Arrange
        var request = new HashRequestDto { Hash = "abc123" };
        _hashRepoMock.Setup(r => r.GetByHashAsync(request.Hash))
                     .ReturnsAsync(new HashArquivoDto { Hash = request.Hash });

        // Act
        var act = async () => await _sut.GerarAsync(request);

        // Assert
        await act.Should()
            .ThrowAsync<ApplicationException>()
            .WithMessage("*ja cadastrado*");
    }
}
```

---

## Convenções obrigatórias

### Nomes
- Arquivo: `{NomeDoServiço}Tests.cs` (ex.: `HashesServiceTests.cs`).
- Método: `{Método}_{Resultado}_{Contexto}` em PascalCase com underscores. Ex.: `Gerar_DeveLancarExcecao_QuandoHashJaCadastrado`.

### Estrutura
- Um `[Fact]` ou `[Theory]` por comportamento. Nunca dois cenários no mesmo método.
- Padrão **Arrange / Act / Assert** com comentários separando as seções.
- O `_sut` (system under test) é tipado pela **interface** (`IHashesService`), nunca pela classe concreta — garante que o contrato é testado.
- Mocks criados no construtor (compartilhados entre testes da classe). Resetar via setup novo no teste, não reuso de estado.
- `It.IsAny<T>()` quando o valor exato não importa; `It.Is<T>(predicate)` quando precisa validar conteúdo do argumento.
- **Não mockar `DateTime.Now`/`Guid.NewGuid()` direto.** Se precisar testar, extrair para serviço (`IDateTimeProvider`, `IGuidProvider`) e mockar.

### Reset de mocks entre testes

Quando precisar resetar mocks entre cenários de uma mesma classe, usar `_hashRepoMock.Reset()` ou recriar no construtor. Não reusar setups acumulados.
