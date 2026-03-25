using System.Threading.RateLimiting;
using MassTransit;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Respawn;
using Testcontainers.MsSql;
using TicketService.Infrastructure.Persistence;
using TicketService.IntegrationTests.Helpers;

namespace TicketService.IntegrationTests;

public class CustomWebApplicationFactory : WebApplicationFactory<Program>, IAsyncLifetime
{
    private readonly MsSqlContainer _sqlContainer =
        new MsSqlBuilder("mcr.microsoft.com/mssql/server:2022-latest")
            .WithPassword("YourStrong@Passw0rd")
            .Build();

    private Respawner _respawner = null!;

    public async Task InitializeAsync()
    {
        await _sqlContainer.StartAsync();

        using var scope = Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<TicketDbContext>();
        await db.Database.MigrateAsync();

        using var conn = new SqlConnection(_sqlContainer.GetConnectionString());
        await conn.OpenAsync();
        _respawner = await Respawner.CreateAsync(conn, new RespawnerOptions
        {
            DbAdapter = DbAdapter.SqlServer,
            TablesToIgnore = ["__EFMigrationsHistory"]
        });
    }

    public new async Task DisposeAsync()
        => await _sqlContainer.DisposeAsync();

    public async Task ResetDatabaseAsync()
    {
        using var conn = new SqlConnection(_sqlContainer.GetConnectionString());
        await conn.OpenAsync();
        await _respawner.ResetAsync(conn);
    }

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Testing");

        builder.ConfigureAppConfiguration((_, config) =>
        {
            config.AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Jwt:Secret"] = "ThisIsAVeryLongSecretKeyUsedOnlyForIntegrationTestingPurposesXYZ123!!",
                ["Jwt:Issuer"] = "geoEvent.UserService",
                ["Jwt:Audience"] = "geoEvent.Client",
                ["Jwt:ExpiryMinutes"] = "15"
            });
        });

        builder.ConfigureServices(services =>
        {
            // Remove all existing rate limiter registrations
            var rateLimiterDescriptors = services
                .Where(d => d.ServiceType.Namespace?.Contains("RateLimiting") == true ||
                            d.ServiceType.FullName?.Contains("RateLimiter") == true)
                .ToList();
            foreach (var d in rateLimiterDescriptors) services.Remove(d);

            services.AddRateLimiter(o =>
            {
                // No-op global limiter
                o.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(_ =>
                    RateLimitPartition.GetNoLimiter("test"));

                // No-op named policies matching every [EnableRateLimiting("...")] in the API
                o.AddPolicy("create-reservation", _ =>
                    RateLimitPartition.GetNoLimiter("test"));
                o.AddPolicy("confirm-reservation", _ =>
                    RateLimitPartition.GetNoLimiter("test"));
                o.AddPolicy("cancel-reservation", _ =>
                    RateLimitPartition.GetNoLimiter("test"));
                o.AddPolicy("validate-ticket", _ =>
                    RateLimitPartition.GetNoLimiter("test"));
                o.AddPolicy("cancel-ticket", _ =>
                    RateLimitPartition.GetNoLimiter("test"));

                o.OnRejected = (_, _) => ValueTask.CompletedTask;
            });

            // Replace DB
            services.RemoveAll<DbContextOptions<TicketDbContext>>();
            services.AddDbContext<TicketDbContext>(options =>
                options.UseSqlServer(_sqlContainer.GetConnectionString()));

            // Remove background service (avoid expiry interference during tests)
            var bgService = services.FirstOrDefault(d =>
                d.ImplementationType?.Name == "ReservationExpiryBackgroundService");
            if (bgService != null) services.Remove(bgService);

            // Replace MassTransit
            var massTransitDescriptors = services
                .Where(d => d.ServiceType?.Namespace?.StartsWith("MassTransit") == true ||
                            d.ImplementationType?.Namespace?.StartsWith("MassTransit") == true)
                .ToList();
            foreach (var d in massTransitDescriptors) services.Remove(d);

            services.AddSingleton<IPublishEndpoint, NoOpPublishEndpoint>();
        });
    }
}
