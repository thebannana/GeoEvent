using geoEvent.Model.Models;
using Microsoft.EntityFrameworkCore;

namespace geoEvent.Infrastructure.Persistence
{
    public class GeoEventDbContext : DbContext
    {
        public GeoEventDbContext(DbContextOptions<GeoEventDbContext> options)
            : base(options) { }

        public DbSet<Event> Events => Set<Event>();

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);
            modelBuilder.ApplyConfigurationsFromAssembly(typeof(GeoEventDbContext).Assembly);
        }
    }
}
