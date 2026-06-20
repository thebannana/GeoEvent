using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace GeoEvent.HelperWorkers.Services;

public class WorkerStartupLogger : BackgroundService
{
    private readonly ILogger<WorkerStartupLogger> _logger;
    private readonly IHostEnvironment _environment;

    public WorkerStartupLogger(
        ILogger<WorkerStartupLogger> logger,
        IHostEnvironment environment)
    {
        _logger = logger;
        _environment = environment;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation(
            "GeoEvent.HelperWorkers started in {Environment} environment at {StartedAtUtc}",
            _environment.EnvironmentName,
            DateTime.UtcNow);

        while (!stoppingToken.IsCancellationRequested)
        {
            await Task.Delay(TimeSpan.FromMinutes(5), stoppingToken);
            _logger.LogInformation("GeoEvent.HelperWorkers heartbeat at {UtcNow}", DateTime.UtcNow);
        }
    }
}