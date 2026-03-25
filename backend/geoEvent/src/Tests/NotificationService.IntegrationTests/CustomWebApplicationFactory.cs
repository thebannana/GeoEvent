using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using NotificationService.Application.Interfaces.Services;
using NotificationService.Infrastructure.Persistence;
using NotificationService.IntegrationTests.Helpers;
using Respawn;
using Testcontainers.MsSql;

namespace NotificationService.IntegrationTests;

public class CustomWebApplicationFactory : WebApplicationFactory<Program>, IAsyncLifetime
{
    private readonly MsSqlContainer _sqlContainer =
        new MsSqlBuilder("mcr.microsoft.com/mssql/server:2022-latest")
            .WithPassword("YourStrong@Passw0rd")
            .Build();

    private Respawner _respawner = null!;
    public const string InternalApiKey = "test-internal-api-key";

    public async Task InitializeAsync()
    {
        await _sqlContainer.StartAsync();

        using var scope = Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<NotificationDbContext>();
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
                ["Jwt:ExpiryMinutes"] = "15",
                ["InternalApi:Key"] = InternalApiKey
            });
        });

        builder.ConfigureServices(services =>
        {
            // Replace DB
            services.RemoveAll<DbContextOptions<NotificationDbContext>>();
            services.AddDbContext<NotificationDbContext>(options =>
                options.UseSqlServer(_sqlContainer.GetConnectionString()));

            // Replace SMTP with no-op
            services.RemoveAll<IEmailSender>();
            services.AddScoped<IEmailSender, NoOpEmailSender>();

            // Remove MassTransit / background services to avoid RabbitMQ dependency
            var massTransitDescriptors = services
                .Where(d => d.ServiceType?.Namespace?.StartsWith("MassTransit") == true ||
                            d.ImplementationType?.Namespace?.StartsWith("MassTransit") == true)
                .ToList();
            foreach (var d in massTransitDescriptors) services.Remove(d);

            var hostedDescriptors = services
                .Where(d => d.ImplementationType?.Name == "QueueProcessorBackgroundService")
                .ToList();
            foreach (var d in hostedDescriptors) services.Remove(d);
        });
    }
}
