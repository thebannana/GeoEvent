using DotNetEnv;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using Microsoft.Extensions.Configuration;
using System.IO;

namespace UserService.Infrastructure.Persistence;

public class UserDbContextFactory : IDesignTimeDbContextFactory<UserDbContext>
{
    public UserDbContext CreateDbContext(string[] args)
    {
        var envPath = FindSharedEnvFile(Directory.GetCurrentDirectory());
        if (!string.IsNullOrWhiteSpace(envPath))
            Env.Load(envPath);

        var configuration = new ConfigurationBuilder()
            .AddEnvironmentVariables()
            .Build();

        var connectionString =
            Environment.GetEnvironmentVariable("USER_DB_CONNECTION")
            ?? configuration["USER_DB_CONNECTION"];

        if (string.IsNullOrWhiteSpace(connectionString))
        {
            throw new InvalidOperationException(
                "Could not find USER_DB_CONNECTION environment variable.");
        }

        var optionsBuilder = new DbContextOptionsBuilder<UserDbContext>();
        optionsBuilder.UseSqlServer(connectionString);

        return new UserDbContext(optionsBuilder.Options);
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