using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using NotificationService.Application.Interfaces.Repositories;
using NotificationService.Application.Interfaces.Services;
using NotificationService.Infrastructure.Persistence;
using NotificationService.Infrastructure.Repositories;
using NotificationService.Infrastructure.Services;
using NotificationService.Infrastructure.BackgroundServices;
using NotificationService.Infrastructure.Filters;
using MassTransit;
using NotificationService.Infrastructure.Consumers;

namespace NotificationService.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(
    this IServiceCollection services,
    IConfiguration configuration)
    {
        services.AddDbContext<NotificationDbContext>(options =>
            options.UseSqlServer(
                configuration.GetConnectionString("NotificationDb"),
                sqlOptions =>
                {
                    sqlOptions.MigrationsAssembly(typeof(NotificationDbContext).Assembly.FullName);
                    sqlOptions.EnableRetryOnFailure(
                        maxRetryCount: 10,
                        maxRetryDelay: TimeSpan.FromSeconds(15),
                        errorNumbersToAdd: null
                    );
                }
            )
        );

        services.AddScoped<INotificationRepository, NotificationRepository>();
        services.AddScoped<INotificationService, NotificationServiceImpl>();
        services.AddScoped<INotificationProcessor, NotificationProcessor>();
        services.AddScoped<IEmailSender, SmtpEmailSender>();
        services.AddScoped<ApiKeyAuthFilter>();
        services.AddHostedService<QueueProcessorBackgroundService>();

        services.AddMassTransit(x =>
        {
            x.AddConsumer<UserRegisteredConsumer>();
            x.AddConsumer<UserBannedConsumer>();
            x.AddConsumer<EmailVerificationRequestedConsumer>();
            x.AddConsumer<PasswordResetRequestedConsumer>();
            x.AddConsumer<EventCreatedConsumer>();
            x.AddConsumer<EventUpdatedConsumer>();
            x.AddConsumer<EventCancelledConsumer>();
            x.AddConsumer<EventStartingSoonConsumer>();
            x.AddConsumer<ReservationCreatedConsumer>();
            x.AddConsumer<ReservationExpiredConsumer>();
            x.AddConsumer<TicketPurchasedConsumer>();
            x.AddConsumer<TicketCancelledConsumer>();
            x.AddConsumer<PaymentSucceededConsumer>();
            x.AddConsumer<PaymentFailedConsumer>();

            x.AddConsumer<ChatMessageSentConsumer>();
            x.AddConsumer<ChatMessageLikedConsumer>();
            x.AddConsumer<ChatUserAddedToGroupConsumer>();

            x.AddConsumer<EventCommentLikedConsumer>();
            x.AddConsumer<EventCommentCreatedConsumer>();
            x.AddConsumer<EventCommentReplyCreatedConsumer>();
            x.AddConsumer<EventLikedConsumer>();
            x.AddConsumer<EventBookmarkedConsumer>();

            x.UsingRabbitMq((ctx, cfg) =>
            {
                cfg.Host(configuration["RabbitMq:Host"], configuration["RabbitMq:VirtualHost"], h =>
                {
                    h.Username(configuration["RabbitMq:Username"]!);
                    h.Password(configuration["RabbitMq:Password"]!);
                });

                cfg.ConfigureEndpoints(ctx);
            });
        });

        return services;
    }

}
