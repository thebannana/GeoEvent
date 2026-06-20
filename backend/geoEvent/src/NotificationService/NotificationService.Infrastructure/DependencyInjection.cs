using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using NotificationService.Application.Interfaces.Repositories;
using NotificationService.Application.Interfaces.Services;
using NotificationService.Infrastructure.Filters;
using NotificationService.Infrastructure.Persistence;
using NotificationService.Infrastructure.Repositories;
using NotificationService.Infrastructure.Services;

namespace NotificationService.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("NotificationDb");
        if (string.IsNullOrWhiteSpace(connectionString))
            throw new InvalidOperationException("Missing configuration: ConnectionStrings:NotificationDb");

        services.AddDbContext<NotificationDbContext>(options =>
            options.UseSqlServer(
                connectionString,
                sqlOptions =>
                {
                    sqlOptions.MigrationsAssembly(typeof(NotificationDbContext).Assembly.FullName);
                    sqlOptions.EnableRetryOnFailure(
                        maxRetryCount: 10,
                        maxRetryDelay: TimeSpan.FromSeconds(15),
                        errorNumbersToAdd: null);
                }));

        services.AddScoped<INotificationRepository, NotificationRepository>();
        services.AddScoped<INotificationService, NotificationServiceImpl>();
        services.AddScoped<ApiKeyAuthFilter>();

        return services;
    }
}