using geoEvent.Model.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace geoEvent.Infrastructure.Persistence.Configurations
{
    public class CountryConfiguration : IEntityTypeConfiguration<Country>
    {
        public void Configure(EntityTypeBuilder<Country> builder)
        {
            builder.HasOne(c => c.Continent)
               .WithMany()
               .HasForeignKey(c => c.ContinentId)
               .OnDelete(DeleteBehavior.Restrict);
        }
    }
}