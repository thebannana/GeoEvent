using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using LocationService.Application.Interfaces.Repositories;
using LocationService.Application.Interfaces.Services;
using LocationService.Infrastructure.Persistence;
using LocationService.Infrastructure.Repositories;
using LocationService.Infrastructure.Services;

namespace LocationService.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(
        this IServiceCollection services, IConfiguration configuration)
    {
        services.AddDbContext<LocationDbContext>(options =>
            options.UseSqlServer(configuration.GetConnectionString("LocationDb")));

        services.AddScoped<ILocationRepository, LocationRepository>();
        services.AddScoped<ILocationService, LocationServiceImpl>();

        return services;
    }
}
