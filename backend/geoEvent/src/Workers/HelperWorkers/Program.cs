using DotNetEnv;
using GeoEvent.HelperWorkers.Consumers;
using GeoEvent.HelperWorkers.Consumers.Messages;
using GeoEvent.HelperWorkers.Consumers.Notifications;
using GeoEvent.HelperWorkers.Consumers.Tickets;
using GeoEvent.HelperWorkers.DTOs;
using GeoEvent.HelperWorkers.Interfaces;
using GeoEvent.HelperWorkers.Options;
using GeoEvent.HelperWorkers.Services;
using MassTransit;
using Microsoft.EntityFrameworkCore;
using TicketService.Infrastructure.Persistence;
using TicketService.Infrastructure.Repositories;
using UserService.Application.Interfaces.Repositories;
using UserService.Application.Interfaces.Services;
using UserService.Infrastructure.Persistence;
using UserService.Infrastructure.Repositories;
using UserService.Infrastructure.Services;

static string? FindSharedEnvFile(string startDirectory)
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

var builder = Host.CreateApplicationBuilder(args);

if (builder.Environment.IsDevelopment())
{
    var sharedEnvPath = FindSharedEnvFile(builder.Environment.ContentRootPath);
    if (!string.IsNullOrWhiteSpace(sharedEnvPath))
    {
        Env.Load(sharedEnvPath);
    }
}

builder.Configuration.AddEnvironmentVariables();

var userDbConnectionString = builder.Configuration.GetConnectionString("UserDb");
if (string.IsNullOrWhiteSpace(userDbConnectionString))
    throw new InvalidOperationException("Missing configuration: ConnectionStrings:UserDb");

builder.Services.AddDbContext<UserDbContext>(options =>
    options.UseSqlServer(
        userDbConnectionString,
        sqlOptions => sqlOptions.EnableRetryOnFailure(
            maxRetryCount: 10,
            maxRetryDelay: TimeSpan.FromSeconds(15),
            errorNumbersToAdd: null)));

var ticketDbConnectionString = builder.Configuration.GetConnectionString("TicketDb");
if (string.IsNullOrWhiteSpace(ticketDbConnectionString))
    throw new InvalidOperationException("Missing configuration: ConnectionStrings:TicketDb");

builder.Services.AddDbContext<TicketDbContext>(options =>
    options.UseSqlServer(
        ticketDbConnectionString,
        sqlOptions => sqlOptions.EnableRetryOnFailure(
            maxRetryCount: 10,
            maxRetryDelay: TimeSpan.FromSeconds(15),
            errorNumbersToAdd: null)));

builder.Services.AddScoped<IUserRepository, UserRepository>();
builder.Services.AddScoped<IUserService, UserServiceImpl>();
builder.Services.AddScoped<PasswordService>();
builder.Services.AddScoped<TokenService>();

builder.Services.AddScoped<ITicketRepository, TicketRepository>();

var eventServiceBaseUrl = builder.Configuration["Services:EventService"];
if (string.IsNullOrWhiteSpace(eventServiceBaseUrl))
    throw new InvalidOperationException("Missing configuration: Services:EventService");

builder.Services.AddHttpClient<IExternalValidationService, ExternalValidationService>(client =>
{
    client.BaseAddress = new Uri(eventServiceBaseUrl);
    client.DefaultRequestHeaders.Accept.Add(
        new System.Net.Http.Headers.MediaTypeWithQualityHeaderValue("application/json"));
});

builder.Services.Configure<SmtpOptions>(builder.Configuration.GetSection("Smtp"));
builder.Services.AddScoped<IEmailSender, SmtpEmailSender>();

var notificationServiceBaseUrl = builder.Configuration["Services:NotificationService:BaseUrl"];
if (string.IsNullOrWhiteSpace(notificationServiceBaseUrl))
    throw new InvalidOperationException("Missing configuration: Services:NotificationService:BaseUrl");

var notificationServiceInternalApiKey = builder.Configuration["Services:NotificationService:InternalApiKey"];
if (string.IsNullOrWhiteSpace(notificationServiceInternalApiKey))
    throw new InvalidOperationException("Missing configuration: Services:NotificationService:InternalApiKey");

builder.Services.Configure<NotificationServiceOptions>(options =>
{
    options.BaseUrl = notificationServiceBaseUrl;
    options.InternalApiKey = notificationServiceInternalApiKey;
});

builder.Services.AddHttpClient<INotificationApiClient, NotificationApiClient>(client =>
{
    client.BaseAddress = new Uri(notificationServiceBaseUrl);
    client.Timeout = TimeSpan.FromSeconds(15);
    client.DefaultRequestHeaders.Accept.Add(
        new System.Net.Http.Headers.MediaTypeWithQualityHeaderValue("application/json"));
    client.DefaultRequestHeaders.Add("X-Internal-Api-Key", notificationServiceInternalApiKey);
});

var messageServiceBaseUrl = builder.Configuration["Services:MessageService:BaseUrl"];
if (string.IsNullOrWhiteSpace(messageServiceBaseUrl))
    throw new InvalidOperationException("Missing configuration: Services:MessageService:BaseUrl");

var messageServiceInternalApiKey = builder.Configuration["Services:MessageService:InternalApiKey"];
if (string.IsNullOrWhiteSpace(messageServiceInternalApiKey))
    throw new InvalidOperationException("Missing configuration: Services:MessageService:InternalApiKey");

builder.Services.AddHttpClient<IMessageChatAdminClient, MessageChatAdminClient>(client =>
{
    client.BaseAddress = new Uri(messageServiceBaseUrl);
    client.Timeout = TimeSpan.FromSeconds(15);
    client.DefaultRequestHeaders.Accept.Add(
        new System.Net.Http.Headers.MediaTypeWithQualityHeaderValue("application/json"));
    client.DefaultRequestHeaders.Add("X-Internal-Api-Key", messageServiceInternalApiKey);
});

var rabbitMqHost = builder.Configuration["RabbitMq:Host"];
var rabbitMqVirtualHost = builder.Configuration["RabbitMq:VirtualHost"] ?? "/";
var rabbitMqUsername = builder.Configuration["RabbitMq:Username"];
var rabbitMqPassword = builder.Configuration["RabbitMq:Password"];

if (string.IsNullOrWhiteSpace(rabbitMqHost))
    throw new InvalidOperationException("Missing configuration: RabbitMq:Host");
if (string.IsNullOrWhiteSpace(rabbitMqUsername))
    throw new InvalidOperationException("Missing configuration: RabbitMq:Username");
if (string.IsNullOrWhiteSpace(rabbitMqPassword))
    throw new InvalidOperationException("Missing configuration: RabbitMq:Password");

builder.Services.AddMassTransit(x =>
{
    x.SetKebabCaseEndpointNameFormatter();

    x.AddConsumer<EventCreatedConsumer>();

    x.AddConsumer<UserRegisteredNotificationConsumer>();
    x.AddConsumer<UserBannedNotificationConsumer>();
    x.AddConsumer<PasswordResetRequestedConsumer>();
    x.AddConsumer<PasswordResetRequestedNotificationConsumer>();
    x.AddConsumer<ReservationCreatedNotificationConsumer>();
    x.AddConsumer<ReservationExpiredNotificationConsumer>();
    x.AddConsumer<TicketPurchasedNotificationConsumer>();
    x.AddConsumer<TicketCancelledNotificationConsumer>();
    x.AddConsumer<PaymentSucceededNotificationConsumer>();
    x.AddConsumer<PaymentFailedNotificationConsumer>();

    x.AddConsumer<EventCreatedNotificationConsumer>();
    x.AddConsumer<EventUpdatedNotificationConsumer>();
    x.AddConsumer<EventCancelledNotificationConsumer>();
    x.AddConsumer<EventLikedNotificationConsumer>();
    x.AddConsumer<EventBookmarkedNotificationConsumer>();
    x.AddConsumer<EventCommentCreatedNotificationConsumer>();
    x.AddConsumer<EventCommentLikedNotificationConsumer>();
    x.AddConsumer<EventCommentReplyCreatedNotificationConsumer>();
    x.AddConsumer<EventReservationCreatedNotificationConsumer>();
    x.AddConsumer<EventReservationPaidNotificationConsumer>();

    x.AddConsumer<ChatMessageSentNotificationConsumer>();
    x.AddConsumer<ChatMessageLikedNotificationConsumer>();
    x.AddConsumer<ChatUserAddedToGroupNotificationConsumer>();

    x.AddConsumer<ReservationConfirmedConsumer>();
    x.AddConsumer<ReservationCancelledIntegrationConsumer>();
    x.AddConsumer<UserDeletedConsumer>();
    x.AddConsumer<UserEventPreferenceInteractionConsumer>();

    x.UsingRabbitMq((context, cfg) =>
    {
        cfg.Host(rabbitMqHost, rabbitMqVirtualHost, h =>
        {
            h.Username(rabbitMqUsername);
            h.Password(rabbitMqPassword);
        });

        cfg.UseMessageRetry(r => r.Interval(3, TimeSpan.FromSeconds(5)));
        cfg.ConfigureEndpoints(context);
    });
});

builder.Services.AddHostedService<WorkerStartupLogger>();

var host = builder.Build();
await host.RunAsync();