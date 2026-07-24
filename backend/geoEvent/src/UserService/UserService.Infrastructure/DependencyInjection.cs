using System.Net.Http.Headers;
using MassTransit;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using UserService.Application.Interfaces.Repositories;
using UserService.Application.Interfaces.Services;
using UserService.Infrastructure.Options;
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
        var connectionString = configuration.GetConnectionString("UserDb");
        if (string.IsNullOrWhiteSpace(connectionString))
            throw new InvalidOperationException("Missing configuration: ConnectionStrings:UserDb");

        services.AddDbContext<UserDbContext>(options =>
            options.UseSqlServer(
                connectionString,
                sqlOptions => sqlOptions.EnableRetryOnFailure(
                    maxRetryCount: 10,
                    maxRetryDelay: TimeSpan.FromSeconds(15),
                    errorNumbersToAdd: null)));

        services.Configure<JwtOptions>(configuration.GetSection(JwtOptions.SectionName));

        services.AddScoped<IUserRepository, UserRepository>();
        services.AddScoped<IAuthService, AuthService>();
        services.AddScoped<IUserService, UserServiceImpl>();
        services.AddScoped<PasswordService>();
        services.AddScoped<TokenService>();

        var eventServiceBaseUrl = configuration["Services:EventService"];
        if (string.IsNullOrWhiteSpace(eventServiceBaseUrl))
            throw new InvalidOperationException("Missing configuration: Services:EventService");

        var internalApiKey = configuration["InternalApi:Key"];
        if (string.IsNullOrWhiteSpace(internalApiKey))
            throw new InvalidOperationException("Missing configuration: InternalApi:Key");

        services.AddHttpClient<IExternalValidationService, ExternalValidationService>(client =>
        {
            client.BaseAddress = new Uri(eventServiceBaseUrl);
            client.DefaultRequestHeaders.Accept.Add(
                new MediaTypeWithQualityHeaderValue("application/json"));
            client.DefaultRequestHeaders.Add("X-Api-Key", internalApiKey);
        });

        var rabbitMqHost = configuration["RabbitMq:Host"];
        var rabbitMqVirtualHost = configuration["RabbitMq:VirtualHost"] ?? "/";
        var rabbitMqUsername = configuration["RabbitMq:Username"];
        var rabbitMqPassword = configuration["RabbitMq:Password"];

        if (string.IsNullOrWhiteSpace(rabbitMqHost))
            throw new InvalidOperationException("Missing configuration: RabbitMq:Host");
        if (string.IsNullOrWhiteSpace(rabbitMqUsername))
            throw new InvalidOperationException("Missing configuration: RabbitMq:Username");
        if (string.IsNullOrWhiteSpace(rabbitMqPassword))
            throw new InvalidOperationException("Missing configuration: RabbitMq:Password");

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