using GeoEvent.HelperWorkers.Interfaces;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace GeoEvent.HelperWorkers.Services;

public sealed class EventLifecycleWorker : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<EventLifecycleWorker> _logger;

    public EventLifecycleWorker(
        IServiceScopeFactory scopeFactory,
        ILogger<EventLifecycleWorker> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(
        CancellationToken stoppingToken)
    {
        _logger.LogInformation(
            "Event lifecycle worker started.");

        await RunOnceAsync(stoppingToken);

        using var timer = new PeriodicTimer(
            TimeSpan.FromMinutes(1));

        while (await timer.WaitForNextTickAsync(stoppingToken))
        {
            await RunOnceAsync(stoppingToken);
        }
    }

    private async Task RunOnceAsync(
        CancellationToken cancellationToken)
    {
        try
        {
            await using var scope =
                _scopeFactory.CreateAsyncScope();

            var ticketClient =
                scope.ServiceProvider
                    .GetRequiredService<
                        ITicketInternalClient>();

            var eventClient =
                scope.ServiceProvider
                    .GetRequiredService<
                        IEventInternalClient>();

            await ticketClient.ExpireReservationsAsync(
                cancellationToken);

            var now = DateTime.UtcNow;

            var candidates =
                await eventClient.GetReadyToCompleteAsync(
                    now,
                    cancellationToken);

            foreach (var candidate in candidates)
            {
                await eventClient.CompleteAsync(
                    candidate.EventId,
                    cancellationToken);
            }

            _logger.LogInformation(
                "Lifecycle check completed at {Now}. " +
                "Events completed: {Count}.",
                now,
                candidates.Count);
        }
        catch (OperationCanceledException)
            when (cancellationToken.IsCancellationRequested)
        {
            _logger.LogInformation(
                "Event lifecycle worker is stopping.");
        }
        catch (Exception ex)
        {
            _logger.LogError(
                ex,
                "Lifecycle check failed.");
        }
    }
}