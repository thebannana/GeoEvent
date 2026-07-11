using DotNetEnv;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace EventService.Infrastructure.Persistence;

public class EventDbContextFactory : IDesignTimeDbContextFactory<EventDbContext>
{
    public EventDbContext CreateDbContext(string[] args)
    {
        var envPath = FindSharedEnvFile(Directory.GetCurrentDirectory());
        if (!string.IsNullOrWhiteSpace(envPath))
        {
            Env.Load(envPath);
        }

        var connectionString = Environment.GetEnvironmentVariable("EVENT_DB_CONNECTION");

        if (string.IsNullOrWhiteSpace(connectionString))
            throw new InvalidOperationException("Could not find EVENT_DB_CONNECTION.");

        var optionsBuilder = new DbContextOptionsBuilder<EventDbContext>();
        optionsBuilder.UseSqlServer(connectionString);

        return new EventDbContext(optionsBuilder.Options);
    }

    private static string? FindSharedEnvFile(string startDirectory)
    {
        var directory = new DirectoryInfo(startDirectory);

        while (directory is not null)
        {
            var candidate = Path.Combine(directory.FullName, ".env");
            if (File.Exists(candidate))
                return candidate;

            directory = directory.Parent;
        }

        return null;
    }
}