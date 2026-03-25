using System.Threading.RateLimiting;
using MassTransit;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Microsoft.Extensions.Hosting;
using Testcontainers.MsSql;
using UserService.Infrastructure.Persistence;
using UserService.IntegrationTests.Helpers;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.Data.SqlClient;
using Respawn;

namespace UserService.IntegrationTests;

public class CustomWebApplicationFactory : WebApplicationFactory<Program>, IAsyncLifetime
{
    private readonly MsSqlContainer _sqlContainer = new MsSqlBuilder("mcr.microsoft.com/mssql/server:2022-latest")
        .WithPassword("YourStrong@Passw0rd")
        .Build();

    private Respawner _respawner = null!;

    public async Task InitializeAsync()
    {
        await _sqlContainer.StartAsync();

        // Run migrations once via the built app
        using var scope = Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<UserDbContext>();
        await db.Database.MigrateAsync();

        // Initialize Respawner after migrations
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

        builder.ConfigureAppConfiguration((context, config) =>
        {
            config.AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Jwt:Secret"] = "ThisIsAVeryLongSecretKeyUsedOnlyForIntegrationTestingPurposesXYZ123!!",
                ["Jwt:Issuer"] = "geoEvent.UserService",
                ["Jwt:Audience"] = "geoEvent.Client",
                ["Jwt:ExpiryMinutes"] = "15",
                ["Auth:RequireEmailVerification"] = "false"
            });
        });

        builder.ConfigureServices(services =>
        {
            // Remove the real rate limiter
            var rateLimiterDescriptors = services
                .Where(d => d.ServiceType.Namespace?.Contains("RateLimiting") == true ||
                            d.ServiceType.FullName?.Contains("RateLimiter") == true)
                .ToList();
            foreach (var d in rateLimiterDescriptors)
                services.Remove(d);

            services.AddRateLimiter(o =>
                o.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(_ =>
                    RateLimitPartition.GetNoLimiter("test")));

            // Replace DbContext
            services.RemoveAll<DbContextOptions<UserDbContext>>();
            services.AddDbContext<UserDbContext>(options =>
                options.UseSqlServer(_sqlContainer.GetConnectionString()));

            // Remove MassTransit
            var massTransitDescriptors = services
                .Where(d => d.ServiceType?.Namespace?.StartsWith("MassTransit") == true ||
                            d.ImplementationType?.Namespace?.StartsWith("MassTransit") == true)
                .ToList();
            foreach (var d in massTransitDescriptors)
                services.Remove(d);

            // No-op publisher
            services.AddSingleton<IPublishEndpoint, NoOpPublishEndpoint>();

            // ← Remove the db.Database.Migrate() block that was here before
        });
    }
}
