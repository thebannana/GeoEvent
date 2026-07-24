using GeoEvent.SeedGenerator.Seeders;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using SeedGeneration.SeedGenerator.Configuration;
using SeedGeneration.SeedGenerator.Interfaces;
using UserService.Infrastructure.Persistence;
using UserService.Infrastructure.Services;

var builder = Host.CreateApplicationBuilder(args);

builder.Configuration.Sources.Clear();

var compatibilityMappings = new Dictionary<string, string?>
{
    ["ConnectionStrings:UserDb"] = Environment.GetEnvironmentVariable("USER_DB_CONNECTION")
};

var inMemoryOverrides = compatibilityMappings
    .Where(x => !string.IsNullOrWhiteSpace(x.Value))
    .Select(x => new KeyValuePair<string, string?>(x.Key, x.Value));

builder.Configuration
    .SetBasePath(AppContext.BaseDirectory)
    .AddJsonFile("appsettings.json", optional: true, reloadOnChange: false)
    .AddJsonFile($"appsettings.{builder.Environment.EnvironmentName}.json", optional: true, reloadOnChange: false)
    .AddInMemoryCollection(inMemoryOverrides)
    .AddEnvironmentVariables();

builder.Services.Configure<SeedSettings>(builder.Configuration);

var userDbConnection = builder.Configuration["ConnectionStrings:UserDb"];

if (string.IsNullOrWhiteSpace(userDbConnection))
{
    throw new InvalidOperationException("ConnectionStrings:UserDb is not configured.");
}

builder.Services.AddDbContext<UserDbContext>(options =>
    options.UseSqlServer(userDbConnection));

builder.Services.AddScoped<PasswordService>();
builder.Services.AddScoped<ISeeder, AdminSeeder>();

using var host = builder.Build();
using var scope = host.Services.CreateScope();

var services = scope.ServiceProvider;
var seeders = services.GetServices<ISeeder>()
    .ToDictionary(x => x.Name, StringComparer.OrdinalIgnoreCase);

var command = args.Length > 0 ? args[0].Trim().ToLowerInvariant() : "admins";

if (command == "all")
{
    foreach (var seeder in seeders.Values)
    {
        await seeder.SeedAsync();
    }

    return;
}

if (!seeders.TryGetValue(command, out var selectedSeeder))
{
    throw new InvalidOperationException($"Unknown seed command: {command}");
}

await selectedSeeder.SeedAsync();