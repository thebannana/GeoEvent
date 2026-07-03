using DotNetEnv;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using Microsoft.Extensions.Configuration;
using System.IO;
using System;

namespace NotificationService.Infrastructure.Persistence;

public class NotificationDbContextFactory : IDesignTimeDbContextFactory<NotificationDbContext>
{
    public NotificationDbContext CreateDbContext(string[] args)
    {
        var envPath = FindSharedEnvFile(Directory.GetCurrentDirectory());
        if (!string.IsNullOrWhiteSpace(envPath))
        {
            Env.Load(envPath);
        }

        var configuration = new ConfigurationBuilder()
            .AddEnvironmentVariables()
            .Build();

        var connectionString = configuration.GetConnectionString("NotificationDb") 
            ?? Environment.GetEnvironmentVariable("NOTIFICATION_DB_CONNECTION");

        if (string.IsNullOrWhiteSpace(connectionString))
            throw new InvalidOperationException("Could not find connection string. Checked ConnectionStrings:NotificationDb and NOTIFICATION_DB_CONNECTION.");

        var optionsBuilder = new DbContextOptionsBuilder<NotificationDbContext>();
        optionsBuilder.UseSqlServer(connectionString);

        return new NotificationDbContext(optionsBuilder.Options);
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