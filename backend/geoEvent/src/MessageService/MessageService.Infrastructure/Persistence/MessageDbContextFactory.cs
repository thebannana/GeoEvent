using DotNetEnv;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using Microsoft.Extensions.Configuration;
using System.IO;
using System;

namespace MessageService.Infrastructure.Persistence;

public class MessageDbContextFactory : IDesignTimeDbContextFactory<MessageDbContext>
{
    public MessageDbContext CreateDbContext(string[] args)
    {
        var envPath = FindSharedEnvFile(Directory.GetCurrentDirectory());
        if (!string.IsNullOrWhiteSpace(envPath))
        {
            Env.Load(envPath);
        }

        var configuration = new ConfigurationBuilder()
            .AddEnvironmentVariables()
            .Build();

        var connectionString = configuration.GetConnectionString("MessageDb") 
            ?? Environment.GetEnvironmentVariable("MESSAGE_DB_CONNECTION");

        if (string.IsNullOrWhiteSpace(connectionString))
            throw new InvalidOperationException("Could not find connection string. Checked ConnectionStrings:MessageDb and MESSAGE_DB_CONNECTION.");

        var optionsBuilder = new DbContextOptionsBuilder<MessageDbContext>();
        optionsBuilder.UseSqlServer(connectionString);

        return new MessageDbContext(optionsBuilder.Options);
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
