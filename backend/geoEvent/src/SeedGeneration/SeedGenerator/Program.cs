using GeoEvent.SeedGenerator.Seeders;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using SeedGeneration.SeedGenerator.Configuration;
using SeedGeneration.SeedGenerator.Interfaces;
using UserService.Infrastructure.Persistence;
using UserService.Infrastructure.Services;
using EventService.Infrastructure.Persistence;
using MessageService.Infrastructure.Persistence;
using NotificationService.Infrastructure.Persistence;
using TicketService.Infrastructure.Persistence;

var builder = Host.CreateApplicationBuilder(args);

builder.Configuration.Sources.Clear();

builder.Configuration
    .SetBasePath(AppContext.BaseDirectory)
    .AddJsonFile(
        "seed-data.json",
        optional: false,
        reloadOnChange: false)
    .AddEnvironmentVariables();

builder.Services.Configure<SeedSettings>(
    builder.Configuration);

var connectionStrings = new Dictionary<string, string>
{
    ["UserDb"] = GetRequiredConnectionString(
        builder.Configuration,
        "UserDb"),

    ["EventDb"] = GetRequiredConnectionString(
        builder.Configuration,
        "EventDb"),

    ["MessageDb"] = GetRequiredConnectionString(
        builder.Configuration,
        "MessageDb"),

    ["NotificationDb"] = GetRequiredConnectionString(
        builder.Configuration,
        "NotificationDb"),

    ["TicketDb"] = GetRequiredConnectionString(
        builder.Configuration,
        "TicketDb")
};

builder.Services.AddDbContext<UserDbContext>(options =>
    options.UseSqlServer(connectionStrings["UserDb"]));

builder.Services.AddDbContext<EventDbContext>(options =>
    options.UseSqlServer(connectionStrings["EventDb"]));

builder.Services.AddDbContext<MessageDbContext>(options =>
    options.UseSqlServer(connectionStrings["MessageDb"]));

builder.Services.AddDbContext<NotificationDbContext>(options =>
    options.UseSqlServer(connectionStrings["NotificationDb"]));

builder.Services.AddDbContext<TicketDbContext>(options =>
    options.UseSqlServer(connectionStrings["TicketDb"]));

builder.Services.AddScoped<PasswordService>();

builder.Services.AddScoped<ISeeder, AdminSeeder>();
builder.Services.AddScoped<ISeeder, UserSeeder>();
builder.Services.AddScoped<ISeeder, PreferenceSeeder>();
builder.Services.AddScoped<ISeeder, ReportSeeder>();
builder.Services.AddScoped<ISeeder, SegmentSeeder>();
builder.Services.AddScoped<ISeeder, GenreSeeder>();
builder.Services.AddScoped<ISeeder, SubGenreSeeder>();
builder.Services.AddScoped<ISeeder, EventSeeder>();
builder.Services.AddScoped<ISeeder, EventImageSeeder>();
builder.Services.AddScoped<ISeeder, EventLikeSeeder>();
builder.Services.AddScoped<ISeeder, BookmarkSeeder>();
builder.Services.AddScoped<ISeeder, CommentSeeder>();
builder.Services.AddScoped<ISeeder, CommentLikeSeeder>();
builder.Services.AddScoped<ISeeder, ChatThreadSeeder>();
builder.Services.AddScoped<ISeeder, ChatMessageSeeder>();
builder.Services.AddScoped<ISeeder, ChatMessageLikeSeeder>();
builder.Services.AddScoped<ISeeder, NotificationSeeder>();
builder.Services.AddScoped<ISeeder, EventTicketSeeder>();
builder.Services.AddScoped<ISeeder, ReservationSeeder>();
builder.Services.AddScoped<ISeeder, PaymentDetailSeeder>();
builder.Services.AddScoped<ISeeder, TicketSeeder>();

using var host = builder.Build();

using var scope = host.Services.CreateScope();

var services = scope.ServiceProvider;

var logger = services
    .GetRequiredService<ILoggerFactory>()
    .CreateLogger("SeedGenerator");

await MigrateAsync<UserDbContext>(
    services,
    logger);

await MigrateAsync<EventDbContext>(
    services,
    logger);

await MigrateAsync<MessageDbContext>(
    services,
    logger);

await MigrateAsync<NotificationDbContext>(
    services,
    logger);

await MigrateAsync<TicketDbContext>(
    services,
    logger);

var seeders = services
    .GetServices<ISeeder>()
    .ToDictionary(
        seeder => seeder.Name,
        StringComparer.OrdinalIgnoreCase);

var command = args.Length == 0
    ? "all"
    : args[0].Trim().ToLowerInvariant();

var executionOrder = new[]
{
    "admins",
    "users",
    "segments",
    "genres",
    "subgenres",
    "preferences",
    "events",
    "eventimages",
    "eventtickets",
    "eventlikes",
    "bookmarks",
    "comments",
    "commentlikes",
    "chatthreads",
    "chatmessages",
    "chatmessagelikes",
    "reservations",
    "paymentdetails",
    "tickets",
    "notifications",
    "reports"
};

if (command == "all")
{
    foreach (var seederName in executionOrder)
    {
        if (!seeders.TryGetValue(
                seederName,
                out var seeder))
        {
            throw new InvalidOperationException(
                $"Seeder '{seederName}' is not registered.");
        }

        await seeder.SeedAsync();
    }
}
else
{
    if (!seeders.TryGetValue(
            command,
            out var selectedSeeder))
    {
        throw new InvalidOperationException(
            $"Unknown seed command: {command}");
    }

    await selectedSeeder.SeedAsync();
}

static string GetRequiredConnectionString(
    IConfiguration configuration,
    string name)
{
    var value = configuration.GetConnectionString(name);

    if (string.IsNullOrWhiteSpace(value))
    {
        throw new InvalidOperationException(
            $"ConnectionStrings:{name} is not configured.");
    }

    return value;
}

static async Task MigrateAsync<TContext>(
    IServiceProvider services,
    ILogger logger,
    CancellationToken cancellationToken = default)
    where TContext : DbContext
{
    const int maxAttempts = 30;

    for (var attempt = 1; attempt <= maxAttempts; attempt++)
    {
        try
        {
            await using var scope =
                services.CreateAsyncScope();

            var db = scope.ServiceProvider
                .GetRequiredService<TContext>();

            await db.Database.MigrateAsync(
                cancellationToken);

            logger.LogInformation(
                "Migrations applied for {Context}.",
                typeof(TContext).Name);

            return;
        }
        catch (Exception ex) when (attempt < maxAttempts)
        {
            logger.LogWarning(
                ex,
                "Migration attempt {Attempt}/{MaxAttempts} failed for {Context}. Retrying in 5 seconds.",
                attempt,
                maxAttempts,
                typeof(TContext).Name);

            await Task.Delay(
                TimeSpan.FromSeconds(5),
                cancellationToken);
        }
    }

    throw new InvalidOperationException(
        $"Failed to migrate {typeof(TContext).Name}.");
}