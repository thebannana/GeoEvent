using MassTransit;
using MessageService.Application.Interfaces.Repositories;
using MessageService.Application.Interfaces.Services;
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
        var messageDbConnectionString = configuration.GetConnectionString("MessageDb");
        if (string.IsNullOrWhiteSpace(messageDbConnectionString))
            throw new InvalidOperationException("ConnectionStrings:MessageDb is not configured.");

        services.AddDbContext<MessageDbContext>(options =>
            options.UseSqlServer(
                messageDbConnectionString,
                sqlOptions => sqlOptions.EnableRetryOnFailure(
                    maxRetryCount: 10,
                    maxRetryDelay: TimeSpan.FromSeconds(15),
                    errorNumbersToAdd: null)));

        var userServiceBaseUrl = configuration["Services:UserServiceBaseUrl"];
        if (string.IsNullOrWhiteSpace(userServiceBaseUrl))
            throw new InvalidOperationException("Services:UserServiceBaseUrl is not configured.");

        var eventServiceBaseUrl = configuration["Services:EventServiceBaseUrl"];
        if (string.IsNullOrWhiteSpace(eventServiceBaseUrl))
            throw new InvalidOperationException("Services:EventServiceBaseUrl is not configured.");

        services.AddHttpClient<IUserDirectoryClient, UserDirectoryClient>(client =>
        {
            client.BaseAddress = new Uri(userServiceBaseUrl);
            client.Timeout = TimeSpan.FromSeconds(10);
        });

        services.AddHttpClient<IEventDirectoryClient, EventDirectoryClient>(client =>
        {
            client.BaseAddress = new Uri(eventServiceBaseUrl);
            client.Timeout = TimeSpan.FromSeconds(10);
        });

        services.AddScoped<IChatRepository, ChatRepository>();
        services.AddScoped<IChatService, ChatServiceImpl>();
        services.AddSingleton<IUserPresenceTracker, InMemoryUserPresenceTracker>();

        var rabbitMqHost = configuration["RabbitMq:Host"];
        var rabbitMqVirtualHost = configuration["RabbitMq:VirtualHost"] ?? "/";
        var rabbitMqUsername = configuration["RabbitMq:Username"];
        var rabbitMqPassword = configuration["RabbitMq:Password"];

        if (string.IsNullOrWhiteSpace(rabbitMqHost))
            throw new InvalidOperationException("RabbitMq:Host is not configured.");
        if (string.IsNullOrWhiteSpace(rabbitMqUsername))
            throw new InvalidOperationException("RabbitMq:Username is not configured.");
        if (string.IsNullOrWhiteSpace(rabbitMqPassword))
            throw new InvalidOperationException("RabbitMq:Password is not configured.");

        services.AddMassTransit(x =>
        {
            x.SetKebabCaseEndpointNameFormatter();

            x.UsingRabbitMq((context, cfg) =>
            {
                cfg.Host(rabbitMqHost, rabbitMqVirtualHost, h =>
                {
                    h.Username(rabbitMqUsername);
                    h.Password(rabbitMqPassword);
                });
            });
        });

        return services;
    }
}