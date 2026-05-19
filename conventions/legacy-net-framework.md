---
title: Código Legado .NET Framework (CoreonCap\net\*)
status: active
last-reviewed: 2026-05-18
---

# Convenções — Código Legado .NET Framework (`CoreonCap\net\*`)

**Regra padrão: não tocar.** Aplique uma mudança aqui apenas se a spec pedir explicitamente.

---

## O que existe

Pasta `CoreonCap\net\` contém dezenas de projetos .NET Framework 4.x:

- **WCF Services** (`*.WcfService`, `*.Contract`, `*.Proxy`) — comunicação entre módulos via SOAP/binary.
- **Web Forms / ASP.NET MVC** legado — telas administrativas antigas.
- **Console apps** de processamento batch.
- **Camadas espelhadas por domínio**: `*.Business`, `*.Context`, `*.Data`, `*.Entity`, `*.Mapper`, `*.Presenter`, `*.Proxy`, `*.Service` — não é arquitetura hexagonal; é o padrão antigo de N-camadas com WCF como fronteira.

Solução: `CoreonCap\CoreonCap.sln`. Build via Visual Studio 2022 ou `msbuild`. **`dotnet build` não funciona** nesses projetos.

---

## O que NÃO fazer

- ❌ **Não refatorar para hexagonal.** Não vale o esforço; o ROI é negativo. Esses módulos estão em manutenção corretiva, não evolutiva.
- ❌ **Não trocar bibliotecas** (Newtonsoft.Json, AutoMapper antigo, Unity, etc.) por equivalentes novos sem spec.
- ❌ **Não criar microsserviço novo aqui.** Microsserviços novos vão para sua própria solução em `Coreon.{NomeDoServiço}\`.
- ❌ **Não reaproveitar código legado em projetos novos.** Sempre reimplementar segundo as convenções modernas.
- ❌ **Não introduzir EF Core ou .NET 8 features.** A stack é EF6 / ADO.NET / WCF.

---

## O que fazer quando a spec pedir

- Bug fix isolado: alterar o mínimo necessário, sem "limpar de passagem".
- Seguir as convenções **já presentes** no arquivo que está sendo editado (estilo, nomes, padrões de chamada).
- `Newtonsoft.Json` é o JSON aqui — não trocar para `System.Text.Json`.
- WCF binding e config: não mexer em `app.config` / `web.config` sem confirmar com o usuário.
- Antes de `git commit`, validar build pelo Visual Studio (não confiar em CI/scripts ainda).

---

## Comunicação entre legado e moderno

Microsserviços novos (.NET 8) chamam o legado via:
- HTTP REST exposto por algum WCF migrado para REST, ou
- RabbitMQ (`CoreonCap.Framework.Webhook` / publisher dedicado).

Nunca o moderno consome WCF SOAP diretamente. Se a spec exigir essa integração, sinalizar antes.
