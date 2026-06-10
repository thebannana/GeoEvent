using MassTransit;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using TicketService.Application.Interfaces.Repositories;
using TicketService.Application.Interfaces.Services;
using TicketService.Infrastructure.Persistence;
using TicketService.Infrastructure.Repositories;
using TicketService.Infrastructure.Services;
using TicketService.Infrastructure.Consumers;

namespace TicketService.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        services.AddDbContext<TicketDbContext>(options =>
            options.UseSqlServer(
                configuration.GetConnectionString("TicketDb"),
                sqlOptions => sqlOptions.EnableRetryOnFailure(
                    maxRetryCount: 10,
                    maxRetryDelay: TimeSpan.FromSeconds(15),
                    errorNumbersToAdd: null)));

        services.AddScoped<ITicketRepository, TicketRepository>();
        services.AddScoped<ITicketService, TicketServiceImpl>();
        services.AddScoped<IEventAuthorizationService, EventAuthorizationService>();

        var userServiceUrl = configuration["Services:UserService"];
        if (string.IsNullOrWhiteSpace(userServiceUrl))
            throw new InvalidOperationException("Services:UserService is not configured.");

        services.AddHttpClient<IUserDirectoryService, UserDirectoryService>(client =>
        {
            client.BaseAddress = new Uri(configuration["Services:UserService"]!);
        });

        services.AddMassTransit(x =>
        {
            x.AddConsumer<EventCreatedConsumer>();

            x.UsingRabbitMq((ctx, cfg) =>
            {
                cfg.Host(
                    configuration["RabbitMq:Host"],
                    configuration["RabbitMq:VirtualHost"],
                    h =>
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