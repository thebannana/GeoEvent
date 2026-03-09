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
    public static IServiceCollection AddInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        services.AddDbContext<MessageDbContext>(options =>
            options.UseSqlServer(configuration.GetConnectionString("MessageDb")));

        services.AddScoped<IMessageRepository, MessageRepository>();
        services.AddScoped<IMessageService, MessageServiceImpl>();

        return services;
    }
}
