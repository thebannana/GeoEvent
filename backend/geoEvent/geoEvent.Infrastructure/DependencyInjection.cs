using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using geoEvent.Infrastructure.Persistence;
using geoEvent.Infrastructure.Repositories;
using geoEvent.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace geoEvent.Infrastructure
{
    public static class DependencyInjection
    {
        public static IServiceCollection AddInfrastructure(
            this IServiceCollection services,
            string? connectionString)
        {
            services.AddDbContext<GeoEventDbContext>(options =>
                options.UseSqlServer(connectionString));

            services.AddScoped<IEventRepository, EventRepository>();

            return services;
        }
    }
}
