using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using Microsoft.Extensions.Configuration;
using System.IO;

namespace UserService.Infrastructure.Persistence;

public class UserDbContextFactory : IDesignTimeDbContextFactory<UserDbContext>
{
    public UserDbContext CreateDbContext(string[] args)
    {
        var basePath = Path.Combine(Directory.GetCurrentDirectory(), "..", "UserService.API");

        var configuration = new ConfigurationBuilder()
            .SetBasePath(basePath)
            .AddJsonFile("appsettings.json", optional: true)
            .AddJsonFile("appsettings.Development.json", optional: true)
            .AddEnvironmentVariables()
            .Build();

        var connectionString =
            configuration.GetConnectionString("DefaultConnection") ??
            configuration.GetConnectionString("UserDb") ??
            throw new InvalidOperationException("No UserService connection string found.");

        var optionsBuilder = new DbContextOptionsBuilder<UserDbContext>();
        optionsBuilder.UseSqlServer(connectionString);

        return new UserDbContext(optionsBuilder.Options);
    }
}