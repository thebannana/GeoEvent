using MassTransit;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using TicketService.Application.Interfaces.Services;
using TicketService.Infrastructure.Persistence;
using TicketService.Infrastructure.Repositories;
using TicketService.Infrastructure.Services;

namespace TicketService.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        var ticketDbConnectionString = configuration.GetConnectionString("TicketDb");
        if (string.IsNullOrWhiteSpace(ticketDbConnectionString))
            throw new InvalidOperationException("ConnectionStrings:TicketDb is not configured.");

        services.AddDbContext<TicketDbContext>(options =>
            options.UseSqlServer(
                ticketDbConnectionString,
                sqlOptions => sqlOptions.EnableRetryOnFailure(
                    maxRetryCount: 10,
                    maxRetryDelay: TimeSpan.FromSeconds(15),
                    errorNumbersToAdd: null)));

        services.AddScoped<ITicketRepository, TicketRepository>();
        services.AddScoped<ITicketService, TicketServiceImpl>();
        services.AddScoped<IEventAuthorizationService, EventAuthorizationService>();
        services.AddHttpClient<IPayPalService, PayPalService>();

        var userServiceUrl = configuration["Services:UserService"];
        if (string.IsNullOrWhiteSpace(userServiceUrl))
            throw new InvalidOperationException("Services:UserService is not configured.");

        var eventServiceUrl = configuration["Services:EventService"];
        if (string.IsNullOrWhiteSpace(eventServiceUrl))
            throw new InvalidOperationException("Services:EventService is not configured.");

        services.AddHttpClient<IUserDirectoryService, UserDirectoryService>(client =>
        {
            client.BaseAddress = new Uri(userServiceUrl);
        });

        services.AddHttpClient<IEventDirectoryClient, EventDirectoryClient>(client =>
        {
            client.BaseAddress = new Uri(eventServiceUrl);
        });

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