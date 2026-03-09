using Microsoft.EntityFrameworkCore;
using LocationService.Domain.Entities;
using LocationService.Infrastructure.Persistence.Configurations;

namespace LocationService.Infrastructure.Persistence;

public class LocationDbContext : DbContext
{
    public LocationDbContext(DbContextOptions<LocationDbContext> options) : base(options) { }

    public DbSet<Continent> Continents => Set<Continent>();
    public DbSet<Country> Countries => Set<Country>();
    public DbSet<AdministrativeDivision> AdministrativeDivisions => Set<AdministrativeDivision>();
    public DbSet<City> Cities => Set<City>();
    public DbSet<PostalCode> PostalCodes => Set<PostalCode>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfiguration(new ContinentConfiguration());
        modelBuilder.ApplyConfiguration(new CountryConfiguration());
        modelBuilder.ApplyConfiguration(new AdministrativeDivisionConfiguration());
        modelBuilder.ApplyConfiguration(new CityConfiguration());
        modelBuilder.ApplyConfiguration(new PostalCodeConfiguration());
        base.OnModelCreating(modelBuilder);
    }
}
