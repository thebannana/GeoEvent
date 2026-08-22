using System.Net.Http.Headers;
using GeoEvent.HelperWorkers.Consumers;
using GeoEvent.HelperWorkers.Consumers.Messages;
using GeoEvent.HelperWorkers.Consumers.Notifications;
using GeoEvent.HelperWorkers.Consumers.Tickets;
using GeoEvent.HelperWorkers.Interfaces;
using GeoEvent.HelperWorkers.Options;
using GeoEvent.HelperWorkers.Services;
using MassTransit;
using Microsoft.Extensions.DependencyInjection;
using NotificationService.Worker.Options;

var builder = Host.CreateApplicationBuilder(args);

builder.Configuration.AddEnvironmentVariables();

builder.Services.Configure<SmtpOptions>(builder.Configuration.GetSection("Smtp"));
builder.Services.AddScoped<IEmailSender, SmtpEmailSender>();

static Uri GetRequiredAbsoluteUri(IConfiguration configuration, string key)
{
    var value = configuration[key];

    if (string.IsNullOrWhiteSpace(value))
        throw new InvalidOperationException($"Missing configuration: {key}");

    if (!Uri.TryCreate(value, UriKind.Absolute, out var uri))
        throw new InvalidOperationException($"Invalid configuration: {key} must be an absolute URL");

    return uri;
}

static string GetRequiredSetting(IConfiguration configuration, string key)
{
    var value = configuration[key];

    if (string.IsNullOrWhiteSpace(value))
        throw new InvalidOperationException($"Missing configuration: {key}");

    return value;
}

var notificationServiceUri = GetRequiredAbsoluteUri(
    builder.Configuration,
    "Services:NotificationService:BaseUrl");

var notificationServiceInternalApiKey = GetRequiredSetting(
    builder.Configuration,
    "Services:NotificationService:InternalApiKey");

builder.Services.Configure<NotificationServiceOptions>(options =>
{
    options.BaseUrl = notificationServiceUri.ToString();
    options.InternalApiKey = notificationServiceInternalApiKey;
});

builder.Services.AddHttpClient<INotificationApiClient, NotificationApiClient>(client =>
{
    client.BaseAddress = notificationServiceUri;
    client.Timeout = TimeSpan.FromSeconds(15);
    client.DefaultRequestHeaders.Accept.Add(
        new MediaTypeWithQualityHeaderValue("application/json"));
    client.DefaultRequestHeaders.Add("X-Api-Key", notificationServiceInternalApiKey);
});

var messageServiceUri = GetRequiredAbsoluteUri(
    builder.Configuration,
    "Services:MessageService:BaseUrl");

var messageServiceInternalApiKey = GetRequiredSetting(
    builder.Configuration,
    "Services:MessageService:InternalApiKey");

builder.Services.AddHttpClient<IMessageChatAdminClient, MessageChatAdminClient>(client =>
{
    client.BaseAddress = messageServiceUri;
    client.Timeout = TimeSpan.FromSeconds(15);
    client.DefaultRequestHeaders.Accept.Add(
        new MediaTypeWithQualityHeaderValue("application/json"));
    client.DefaultRequestHeaders.Add("X-Api-Key", messageServiceInternalApiKey);
});

var ticketServiceUri = GetRequiredAbsoluteUri(
    builder.Configuration,
    "Services:TicketService:BaseUrl");

var ticketServiceInternalApiKey = GetRequiredSetting(
    builder.Configuration,
    "Services:TicketService:InternalApiKey");

builder.Services.AddHttpClient<ITicketInternalClient, TicketInternalClient>(client =>
{
    client.BaseAddress = ticketServiceUri;
    client.Timeout = TimeSpan.FromSeconds(15);
    client.DefaultRequestHeaders.Accept.Add(
        new MediaTypeWithQualityHeaderValue("application/json"));
    client.DefaultRequestHeaders.Add("X-Api-Key", ticketServiceInternalApiKey);
});

var userServiceUri = GetRequiredAbsoluteUri(
    builder.Configuration,
    "Services:UserService:BaseUrl");

var userServiceInternalApiKey = GetRequiredSetting(
    builder.Configuration,
    "Services:UserService:InternalApiKey");

builder.Services.AddHttpClient<IUserPreferenceInternalClient, UserPreferenceInternalClient>(client =>
{
    client.BaseAddress = userServiceUri;
    client.Timeout = TimeSpan.FromSeconds(15);
    client.DefaultRequestHeaders.Accept.Add(
        new MediaTypeWithQualityHeaderValue("application/json"));
    client.DefaultRequestHeaders.Add("X-Api-Key", userServiceInternalApiKey);
});

var eventServiceUri = GetRequiredAbsoluteUri(
    builder.Configuration,
    "Services:EventService:BaseUrl");

var eventServiceInternalApiKey = GetRequiredSetting(
    builder.Configuration,
    "Services:EventService:InternalApiKey");

builder.Services.AddHttpClient<
    IEventInternalClient,
    EventInternalClient>(client =>
    {
        client.BaseAddress = eventServiceUri;
        client.Timeout = TimeSpan.FromSeconds(30);
        client.DefaultRequestHeaders.Accept.Add(
            new MediaTypeWithQualityHeaderValue(
                "application/json"));
        client.DefaultRequestHeaders.Add(
            "X-Api-Key",
            eventServiceInternalApiKey);
    });

var rabbitMqHost = GetRequiredSetting(builder.Configuration, "RabbitMq:Host");
var rabbitMqVirtualHost = builder.Configuration["RabbitMq:VirtualHost"] ?? "/";
var rabbitMqUsername = GetRequiredSetting(builder.Configuration, "RabbitMq:Username");
var rabbitMqPassword = GetRequiredSetting(builder.Configuration, "RabbitMq:Password");

builder.Services.AddMassTransit(x =>
{
    x.SetKebabCaseEndpointNameFormatter();

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
    x.AddConsumer<EventReservationCashPendingNotificationConsumer>();

    x.AddConsumer<ChatMessageSentNotificationConsumer>();
    x.AddConsumer<ChatMessageLikedNotificationConsumer>();
    x.AddConsumer<ChatUserAddedToGroupNotificationConsumer>();

    x.AddConsumer<ReservationConfirmedConsumer>();
    x.AddConsumer<ReservationCancelledIntegrationConsumer>();
    x.AddConsumer<UserDeletedConsumer>();

    x.AddConsumer<EventRefundRequestedNotificationConsumer>();
    x.AddConsumer<ReservationRefundApprovedNotificationConsumer>();
    x.AddConsumer<ReservationRefundRejectedNotificationConsumer>();
    x.AddConsumer<ReservationRemovedByOrganizerNotificationConsumer>();

    x.AddConsumer<EventCreatedConsumer>();
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
builder.Services.AddHostedService<EventLifecycleWorker>();

var host = builder.Build();
await host.RunAsync();