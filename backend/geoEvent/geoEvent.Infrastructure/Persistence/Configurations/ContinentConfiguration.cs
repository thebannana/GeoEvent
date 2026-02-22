using geoEvent.Model.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace geoEvent.Infrastructure.Persistence.Configurations
{
    public class ContinentConfiguration : IEntityTypeConfiguration<Continent>
    {
        public void Configure(EntityTypeBuilder<Continent> builder)
        {
            builder.HasKey(c => c.ContinentId);

            builder.HasIndex(c => c.ContinentCode);

            builder.Property(c => c.ContinentName).HasMaxLength(50).IsRequired();
            builder.Property(c => c.ContinentCode).HasMaxLength(10).IsRequired();
        }
    }
}