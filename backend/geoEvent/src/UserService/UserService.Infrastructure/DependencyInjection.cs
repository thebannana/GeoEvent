using System.Net.Http.Headers;
using MassTransit;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using UserService.Application.Interfaces.Repositories;
using UserService.Application.Interfaces.Services;
using UserService.Infrastructure.Persistence;
using UserService.Infrastructure.Repositories;
using UserService.Infrastructure.Services;

namespace UserService.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        services.AddDbContext<UserDbContext>(options =>
            options.UseSqlServer(
                configuration.GetConnectionString("UserDb"),
                sqlOptions => sqlOptions.EnableRetryOnFailure(
                    maxRetryCount: 10,
                    maxRetryDelay: TimeSpan.FromSeconds(15),
                    errorNumbersToAdd: null)));

        services.AddScoped<IUserRepository, UserRepository>();
        services.AddScoped<IAuthService, AuthService>();
        services.AddScoped<IUserService, UserServiceImpl>();
        services.AddScoped<PasswordService>();
        services.AddScoped<TokenService>();

        var eventServiceBaseUrl = configuration["Services:EventServiceBaseUrl"];
        if (string.IsNullOrWhiteSpace(eventServiceBaseUrl))
            throw new InvalidOperationException(
                "Missing configuration: Services:EventServiceBaseUrl");

        services.AddHttpClient<IExternalValidationService, ExternalValidationService>(client =>
        {
            client.BaseAddress = new Uri(eventServiceBaseUrl);
        });

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