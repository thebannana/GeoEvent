using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using TicketService.Application.Interfaces.Services;

namespace TicketService.Infrastructure.BackgroundServices;

public class ReservationExpiryBackgroundService : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<ReservationExpiryBackgroundService> _logger;

    public ReservationExpiryBackgroundService(
        IServiceScopeFactory scopeFactory,
        ILogger<ReservationExpiryBackgroundService> logger)
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
                    .GetRequiredService<ITicketService>();
                await service.ExpireReservationsAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Reservation expiry error: {Message}", ex.Message);
            }

            await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken);
        }
    }
}