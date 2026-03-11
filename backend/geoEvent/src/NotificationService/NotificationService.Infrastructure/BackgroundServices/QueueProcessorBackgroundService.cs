using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using NotificationService.Application.Interfaces.Services;
using Microsoft.Extensions.Logging;

namespace NotificationService.Infrastructure.BackgroundServices;

public class QueueProcessorBackgroundService : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<QueueProcessorBackgroundService> _logger;

    public QueueProcessorBackgroundService(
        IServiceScopeFactory scopeFactory,
        ILogger<QueueProcessorBackgroundService> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var service = scope.ServiceProvider
                    .GetRequiredService<INotificationService>();

                await service.ProcessQueueAsync(batchSize: 20);
                await service.RetryFailedAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Queue processor error: {Message}", ex.Message);
            }

            await Task.Delay(TimeSpan.FromSeconds(30), stoppingToken);
        }
    }
}