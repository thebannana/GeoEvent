using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using LocationService.Domain.Entities;

namespace LocationService.Infrastructure.Persistence.Configurations;

public class CityConfiguration : IEntityTypeConfiguration<City>
{
    public void Configure(EntityTypeBuilder<City> builder)
    {
        builder.HasKey(c => c.CityId);

        builder.Property(c => c.CityName)
            .HasMaxLength(255)
            .IsRequired();

        builder.Property(c => c.NormalizedName)
            .HasMaxLength(255)
            .IsRequired();

        builder.Property(c => c.Latitude)
            .HasColumnType("decimal(9,6)");

        builder.Property(c => c.Longitude)
            .HasColumnType("decimal(9,6)");

        builder.HasOne(c => c.Division)
            .WithMany(d => d.Cities)
            .HasForeignKey(c => c.DivisionId)
            .OnDelete(DeleteBehavior.Restrict);


        builder.HasIndex(c => c.NormalizedName);
        builder.HasIndex(c => c.DivisionId);
        builder.HasIndex(c => c.CityName);
        builder.HasIndex(c => c.IsActive);
        builder.HasIndex(c => new { c.DivisionId, c.IsActive });

    }
}
