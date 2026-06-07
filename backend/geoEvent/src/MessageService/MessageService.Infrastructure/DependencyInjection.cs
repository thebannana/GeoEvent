using MassTransit;
using MessageService.Application.Interfaces.Repositories;
using MessageService.Application.Interfaces.Services;
using MessageService.Infrastructure.Consumers;
using MessageService.Infrastructure.Persistence;
using MessageService.Infrastructure.Repositories;
using MessageService.Infrastructure.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace MessageService.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddDbContext<MessageDbContext>(options =>
            options.UseSqlServer(
                configuration.GetConnectionString("MessageDb"),
                sqlOptions => sqlOptions.EnableRetryOnFailure(
                    maxRetryCount: 10,
                    maxRetryDelay: TimeSpan.FromSeconds(15),
                    errorNumbersToAdd: null)));

        services.AddHttpClient<IUserDirectoryClient, UserDirectoryClient>(client =>
        {
            var baseUrl = configuration["Services:UserServiceBaseUrl"] ?? "http://user-service:8080";
            client.BaseAddress = new Uri(baseUrl);
            client.Timeout = TimeSpan.FromSeconds(10);
        });

        services.AddHttpClient<IEventDirectoryClient, EventDirectoryClient>(client =>
        {
            var baseUrl = configuration["Services:EventServiceBaseUrl"] ?? "http://event-service:8080";
            client.BaseAddress = new Uri(baseUrl);
            client.Timeout = TimeSpan.FromSeconds(10);
        });

        services.AddScoped<IChatRepository, ChatRepository>();
        services.AddScoped<IChatService, ChatServiceImpl>();
        services.AddSingleton<IUserPresenceTracker, InMemoryUserPresenceTracker>();

        services.AddMassTransit(x =>
        {
            x.AddConsumer<UserDeletedConsumer>();
            x.AddConsumer<ReservationConfirmedConsumer>();
            x.AddConsumer<ReservationCancelledIntegrationConsumer>();

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