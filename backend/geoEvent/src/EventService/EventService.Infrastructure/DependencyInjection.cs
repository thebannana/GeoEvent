using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using EventService.Application.Interfaces.Repositories;
using EventService.Application.Interfaces.Services;
using EventService.Infrastructure.Persistence;
using EventService.Infrastructure.Repositories;
using EventService.Infrastructure.Services;
using MassTransit;
using EventService.Application.Common.Settings;

namespace EventService.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        services.Configure<SupabaseStorageSettings>(
        configuration.GetSection(SupabaseStorageSettings.SectionName));

        services.AddHttpClient<IImageStorageService, SupabaseImageStorageService>();
        services.AddHttpClient<IUserProfileService, UserProfileService>(client =>
        {
            client.BaseAddress = new Uri("http://user-service:8080/");
        });

        services.AddDbContext<EventDbContext>(options =>
            options.UseSqlServer(
                configuration.GetConnectionString("EventDb"),
                sqlOptions => sqlOptions.EnableRetryOnFailure(
                    maxRetryCount: 10,
                    maxRetryDelay: TimeSpan.FromSeconds(15),
                    errorNumbersToAdd: null
                )
            )
        );

        services.AddScoped<IEventRepository, EventRepository>();
        services.AddScoped<IEventService, EventServiceImpl>();

        services.AddMassTransit(x =>
        {
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
