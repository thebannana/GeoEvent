using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using EventService.Application.Interfaces.Repositories;
using EventService.Application.Interfaces.Services;
using EventService.Infrastructure.Persistence;
using EventService.Infrastructure.Repositories;
using EventService.Infrastructure.Services;

namespace EventService.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        services.AddDbContext<EventDbContext>(options =>
            options.UseSqlServer(configuration.GetConnectionString("EventDb")));

        services.AddScoped<IEventRepository, EventRepository>();
        services.AddScoped<IEventService, EventServiceImpl>();

        return services;
    }
}
