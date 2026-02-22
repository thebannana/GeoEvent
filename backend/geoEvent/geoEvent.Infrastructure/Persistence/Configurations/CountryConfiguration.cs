using geoEvent.Model.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace geoEvent.Infrastructure.Persistence.Configurations
{
    public class CountryConfiguration : IEntityTypeConfiguration<Country>
    {
        public void Configure(EntityTypeBuilder<Country> builder)
        {
            builder.HasKey(c => c.CountryId);

            builder.HasOne(c => c.Continent)
                   .WithMany()
                   .HasForeignKey(c => c.ContinentId)
                   .OnDelete(DeleteBehavior.SetNull);

            builder.HasIndex(c => c.CountryCodeAlpha2);
            builder.HasIndex(c => c.CountryCodeAlpha3);
            builder.HasIndex(c => c.CountryCodeNumeric);

            builder.Property(c => c.CountryName).HasMaxLength(100).IsRequired();
            builder.Property(c => c.CountryCodeAlpha2).HasMaxLength(2).IsRequired();
            builder.Property(c => c.CountryCodeAlpha3).HasMaxLength(3).IsRequired();
        }
    }
}