using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Storage;

namespace UserService.API.Extensions;

public static class DatabaseStartupExtensions
{
    public static async Task InitializeDatabaseAsync<TContext>(
     this IServiceProvider services,
     IConfiguration configuration,
     IHostEnvironment environment)
     where TContext : DbContext
    {
        await using var scope = services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<TContext>();
        var logger = scope.ServiceProvider.GetRequiredService<ILogger<TContext>>();

        var allowRebuild = configuration.GetValue<bool>("Database:AllowRebuild");
        var maxRetries = configuration.GetValue<int?>("Database:StartupRetries") ?? 3;
        var delaySeconds = configuration.GetValue<int?>("Database:RetryDelaySeconds") ?? 5;

        for (var attempt = 1; attempt <= maxRetries; attempt++)
        {
            try
            {
                logger.LogInformation(
                    "Database init attempt {Attempt}/{MaxRetries} for {Context}",
                    attempt, maxRetries, typeof(TContext).Name);

                await db.Database.MigrateAsync();

                logger.LogInformation(
                    "Migrations applied successfully for {Context}.",
                    typeof(TContext).Name);

                return;
            }
            catch (SqlException ex) when (IsDatabaseAlreadyExists(ex))
            {
                logger.LogError(ex,
                    "Migration attempted to create an existing database. This usually means the database already exists but is not aligned with EF migration history.");
                throw;
            }
            catch (Exception ex)
            {
                var isLast = attempt == maxRetries;

                logger.LogWarning(ex,
                    "Database initialization failed on attempt {Attempt}/{MaxRetries}.",
                    attempt, maxRetries);

                if (isLast)
                {
                    if (environment.IsDevelopment() && allowRebuild)
                    {
                        logger.LogWarning("Development rebuild is enabled. Rebuilding database...");
                        await RebuildDatabaseAsync(db, logger);
                        await db.Database.MigrateAsync();
                        logger.LogInformation("Database rebuilt and migrated successfully.");
                        return;
                    }

                    throw;
                }

                await Task.Delay(TimeSpan.FromSeconds(delaySeconds));
            }
        }
    }

    private static bool IsDatabaseAlreadyExists(SqlException ex) => ex.Number == 1801;

    private static async Task RebuildDatabaseAsync<TContext>(TContext db, ILogger logger)
        where TContext : DbContext
    {
        var csb = new SqlConnectionStringBuilder(db.Database.GetConnectionString());
        var dbName = csb.InitialCatalog;

        if (string.IsNullOrWhiteSpace(dbName))
            throw new InvalidOperationException("Database name not found in connection string.");

        var masterCsb = new SqlConnectionStringBuilder(csb.ConnectionString)
        {
            InitialCatalog = "master"
        };

        await using var conn = new SqlConnection(masterCsb.ConnectionString);
        await conn.OpenAsync();

        var sql = $@"
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = N'{dbName}')
BEGIN
    ALTER DATABASE [{dbName}] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [{dbName}];
END";

        await using var cmd = new SqlCommand(sql, conn);
        await cmd.ExecuteNonQueryAsync();

        logger.LogWarning("Dropped database {DatabaseName}.", dbName);
    }
}