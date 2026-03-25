using System.Threading.RateLimiting;
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
using LocationService.Infrastructure.Persistence;
using Microsoft.AspNetCore.Builder;
using Microsoft.VisualStudio.TestPlatform.TestHost;

namespace LocationService.IntegrationTests;

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
        var db = scope.ServiceProvider.GetRequiredService<LocationDbContext>();
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
            var rateLimiterDescriptors = services
                .Where(d => d.ServiceType.Namespace?.Contains("RateLimiting") == true ||
                            d.ServiceType.FullName?.Contains("RateLimiter") == true)
                .ToList();
            foreach (var d in rateLimiterDescriptors) services.Remove(d);

            services.AddRateLimiter(o =>
            {
                o.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(_ =>
                    RateLimitPartition.GetNoLimiter("test"));
                o.OnRejected = (_, _) => ValueTask.CompletedTask;
            });

            services.RemoveAll<DbContextOptions<LocationDbContext>>();
            services.AddDbContext<LocationDbContext>(options =>
                options.UseSqlServer(_sqlContainer.GetConnectionString()));
        });
    }
}
