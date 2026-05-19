---
title: Convenções de Mensageria — RabbitMQ
status: active
last-reviewed: 2026-05-18
---

# Convenções de Mensageria — RabbitMQ

Mensageria do CoreonCap usa exclusivamente **RabbitMQ**. **Não usar Kafka.**

Filas reais em uso (referência):
- `processar-gerar-premiacao` — producer: `Coreon.Arquivo.Backgroud`; consumer: `CoreCap.Premiacao.Background` (`GerarPremiacaoBackgroundService`).
- `resultado-processar-gerar-premiacao` — feedback do `CoreCap.Premiacao` para `Coreon.Arquivo`.

DLQ é tratada pelo `CoreonCap.Framework`. Confirmar antes de declarar DLQ manualmente.

---

## Publishers

```
{Serviço}.Domain/Interfaces/Messaging/IRabbitMq{Serviço}Publisher.cs    (porta)
{Serviço}.Domain/Messaging/RabbitMq{Serviço}Publisher.cs                 (implementação)
```

Padrão:

```csharp
public interface IRabbitMqArquivoPublisher
{
    Task PublicarProcessarGerarPremiacaoAsync(ProcessarContempladosDto dto);
}

public class RabbitMqArquivoPublisher : IRabbitMqArquivoPublisher
{
    private readonly RabbitMqSettings _settings;

    public RabbitMqArquivoPublisher(IOptions<RabbitMqSettings> settings)
        => _settings = settings.Value;

    public async Task PublicarProcessarGerarPremiacaoAsync(ProcessarContempladosDto dto)
        => await PublishAsync(_settings.ProcessarGerarPremiacaoQueue, dto);

    private async Task PublishAsync<T>(string queue, T message)
    {
        var factory = new ConnectionFactory
        {
            HostName    = _settings.HostName,
            UserName    = _settings.UserName,
            Password    = _settings.Password,
            VirtualHost = _settings.VirtualHost
        };

        using var connection = await factory.CreateConnectionAsync();
        using var channel    = await connection.CreateChannelAsync();

        await channel.QueueDeclareAsync(queue, durable: true, exclusive: false,
            autoDelete: false, arguments: null);

        var body  = Encoding.UTF8.GetBytes(JsonSerializer.Serialize(message));
        var props = new BasicProperties { Persistent = true };

        await channel.BasicPublishAsync(
            exchange: string.Empty,
            routingKey: queue,
            basicProperties: props,
            body: body);
    }
}
```

> **Antes de duplicar este boilerplate:** verifique `CoreonCap.Framework` — pode haver `BasePublisher` ou helper já pronto. Use-o se existir.

---

## Consumers (BackgroundService)

```
{Serviço}.Backgroud/Workers/{Nome}BackgroundService.cs
```

Exemplo real: `CoreCap.Premiacao.Background/Workers/GerarPremiacaoBackgroundService.cs`.

```csharp
public class GerarPremiacaoBackgroundService : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly RabbitMqSettings _settings;

    public GerarPremiacaoBackgroundService(
        IServiceProvider serviceProvider,
        IOptions<RabbitMqSettings> settings)
    {
        _serviceProvider = serviceProvider;
        _settings = settings.Value;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var factory = new ConnectionFactory
        {
            HostName    = _settings.HostName,
            UserName    = _settings.UserName,
            Password    = _settings.Password,
            VirtualHost = _settings.VirtualHost
        };

        using var connection = await factory.CreateConnectionAsync(stoppingToken);
        using var channel    = await connection.CreateChannelAsync(cancellationToken: stoppingToken);

        await channel.QueueDeclareAsync(
            queue: _settings.ProcessarGerarPremiacaoQueue,
            durable: true, exclusive: false, autoDelete: false,
            arguments: new Dictionary<string, object?>
            {
                { "x-dead-letter-exchange", $"{_settings.ProcessarGerarPremiacaoQueue}-dlq" }
            });

        var consumer = new AsyncEventingBasicConsumer(channel);

        consumer.ReceivedAsync += async (sender, ea) =>
        {
            using var scope   = _serviceProvider.CreateScope();
            var      service = scope.ServiceProvider.GetRequiredService<IProcessarPremiacaoService>();

            try
            {
                var body    = ea.Body.ToArray();
                var message = JsonSerializer.Deserialize<ProcessarContempladosDto>(
                    Encoding.UTF8.GetString(body));

                await service.ProcessarContemplacoesAsync(message!);

                await channel.BasicAckAsync(ea.DeliveryTag, multiple: false, stoppingToken);
            }
            catch (Exception)
            {
                await channel.BasicNackAsync(
                    ea.DeliveryTag, multiple: false, requeue: false, stoppingToken);
            }
        };

        await channel.BasicConsumeAsync(
            queue: _settings.ProcessarGerarPremiacaoQueue,
            autoAck: false,
            consumer: consumer,
            cancellationToken: stoppingToken);

        await Task.Delay(Timeout.Infinite, stoppingToken);
    }
}
```

**Regras obrigatórias do consumer:**
- `autoAck: false` — ACK manual após sucesso. Sem isso, mensagens são perdidas em caso de exceção.
- `IServiceProvider.CreateScope()` dentro do handler para resolver dependências `Scoped` (incluindo `DbContext`).
- `BasicNack` com `requeue: false` — envia para DLQ em vez de reentrar em loop.
- `x-dead-letter-exchange` declarado no `arguments` da fila.

### Registro

No `Program.cs` do projeto `Backgroud`:

```csharp
builder.Services.AddHostedService<GerarPremiacaoBackgroundService>();
```

---

## Mensagens

POCO simples, sem herança ou atributos:

```csharp
public class ProcessarContempladosDto
{
    public Guid ImportarArquivoId { get; set; }
    public string CodigoOperacao { get; set; } = string.Empty;
    public List<ContempladoItemDto> Contemplados { get; set; } = new();
}
```

**Serialização:** `System.Text.Json.JsonSerializer`. **Não** usar Newtonsoft.Json em código novo (o legado em `CoreonCap\net\*` ainda usa Newtonsoft — manter).

> **Cuidado com DTOs duplicados.** Se a mesma classe de mensagem existe em dois projetos (producer e consumer) por cópia manual, qualquer mudança de schema quebra silenciosamente. Item flagado em `analyses/2026-04-30-consumer-processar-gerar-premiacao.md`. A solução de longo prazo é um pacote compartilhado de contratos — não introduzir sem spec.

---

## Configuração

```csharp
// {Serviço}.Domain/Configurations/RabbitMqSettings.cs
public class RabbitMqSettings
{
    public string HostName    { get; set; } = string.Empty;
    public string UserName    { get; set; } = string.Empty;
    public string Password    { get; set; } = string.Empty;
    public string VirtualHost { get; set; } = "/";

    public string ProcessarGerarPremiacaoQueue          { get; set; } = string.Empty;
    public string ResultadoProcessarGerarPremiacaoQueue { get; set; } = string.Empty;
}
```

```json
// appsettings.json
{
  "RabbitMqSettings": {
    "HostName": "localhost",
    "UserName": "guest",
    "Password": "guest",
    "VirtualHost": "/",
    "ProcessarGerarPremiacaoQueue": "processar-gerar-premiacao",
    "ResultadoProcessarGerarPremiacaoQueue": "resultado-processar-gerar-premiacao"
  }
}
```

```csharp
// IoC
services.Configure<RabbitMqSettings>(configuration.GetSection("RabbitMqSettings"));
services.AddScoped<IRabbitMqArquivoPublisher, RabbitMqArquivoPublisher>();
```
