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
                b => b.MigrationsAssembly(typeof(NotificationDbContext).Assembly.FullName)));

        services.AddScoped<INotificationRepository, NotificationRepository>();
        services.AddScoped<INotificationService, NotificationServiceImpl>();
        services.AddScoped<INotificationProcessor, NotificationProcessor>();
        services.AddScoped<IEmailSender, SmtpEmailSender>();
        services.AddScoped<ApiKeyAuthFilter>();
        services.AddHostedService<QueueProcessorBackgroundService>();

        return services;
    }

}
