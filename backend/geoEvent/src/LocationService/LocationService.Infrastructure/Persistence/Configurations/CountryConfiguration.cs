using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using LocationService.Domain.Entities;

namespace LocationService.Infrastructure.Persistence.Configurations;

public class CountryConfiguration : IEntityTypeConfiguration<Country>
{
    public void Configure(EntityTypeBuilder<Country> builder)
    {
        builder.HasKey(c => c.CountryId);

        builder.Property(c => c.CountryName)
            .HasMaxLength(100)
            .IsRequired();

        builder.Property(c => c.CountryCodeAlpha2)
            .HasMaxLength(2)
            .IsRequired();

        builder.Property(c => c.CountryCodeAlpha3)
            .HasMaxLength(3)
            .IsRequired();

        builder.HasOne(c => c.Continent)
            .WithMany(co => co.Countries)
            .HasForeignKey(c => c.ContinentId)
            .OnDelete(DeleteBehavior.SetNull);

        builder.HasIndex(c => c.CountryCodeAlpha2).IsUnique();
        builder.HasIndex(c => c.CountryCodeAlpha3).IsUnique();
        builder.HasIndex(c => c.CountryCodeNumeric).IsUnique();
        builder.HasIndex(c => c.CountryName);
        builder.HasIndex(c => c.IsActive);
        builder.HasIndex(c => c.ContinentId);
    }
}
