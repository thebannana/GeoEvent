using EventService.Application.Common.Settings;
using EventService.Application.Interfaces.Repositories;
using EventService.Application.Interfaces.Services;
using EventService.Infrastructure.Persistence;
using EventService.Infrastructure.Repositories;
using EventService.Infrastructure.Services;
using MassTransit;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace EventService.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        services.AddHttpContextAccessor();
        services.AddScoped<ICurrentUserService, CurrentUserService>();

        services.Configure<ImageKitSettings>(
            configuration.GetSection(ImageKitSettings.SectionName));

        services.AddHttpClient<IImageStorageService, ImageKitImageStorageService>();

        var connectionString = configuration.GetConnectionString("EventDb")
            ?? throw new InvalidOperationException("Connection string 'EventDb' is not configured.");

        services.AddDbContext<EventDbContext>(options =>
            options.UseSqlServer(
                connectionString,
                sqlOptions => sqlOptions.EnableRetryOnFailure(
                    maxRetryCount: 10,
                    maxRetryDelay: TimeSpan.FromSeconds(15),
                    errorNumbersToAdd: null)));

        services.AddTransient<ServiceAuthHandler>();

        var userServiceBaseUrl = configuration["Services:UserServiceBaseUrl"]
            ?? throw new InvalidOperationException("Services:UserServiceBaseUrl is not configured.");

        services.AddHttpClient<IUserProfileService, UserProfileService>(client =>
        {
            client.BaseAddress = new Uri(userServiceBaseUrl);
        })
        .AddHttpMessageHandler<ServiceAuthHandler>();

        services.AddScoped<IEventRepository, EventRepository>();
        services.AddScoped<IEventService, EventServiceImpl>();

        services.AddMassTransit(x =>
        {
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