using EventService.Domain.Entities;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Microsoft.EntityFrameworkCore;

public class VenueConfiguration : IEntityTypeConfiguration<Venue>
{
    public void Configure(EntityTypeBuilder<Venue> builder)
    {
        builder.ToTable("Venues");
        builder.HasKey(v => v.VenueId);
        builder.Property(v => v.Name).IsRequired().HasMaxLength(200);
        builder.Property(v => v.Address).HasMaxLength(500);
        builder.Property(v => v.Description).HasMaxLength(2000);
        builder.Property(v => v.Latitude).HasPrecision(9, 6);
        builder.Property(v => v.Longitude).HasPrecision(9, 6);
        builder.Property(v => v.VenueType).HasMaxLength(100);
        builder.Property(v => v.WebsiteUrl).HasMaxLength(1000);
        builder.Property(v => v.PhoneNumber).HasMaxLength(30);
        builder.Property(v => v.TimeZone).HasMaxLength(50);   // fix: was 100
        builder.Property(v => v.Locale).HasMaxLength(10);
        builder.Property(v => v.IsVerified).HasDefaultValue(false);

        // Missing indexes — all present in migration
        builder.HasIndex(v => v.Name);
        builder.HasIndex(v => v.CityId);
        builder.HasIndex(v => v.IsVerified);
        builder.HasIndex(v => v.VenueType);
        builder.HasIndex(v => new { v.CityId, v.VenueType });
        builder.HasIndex(v => new { v.Longitude, v.Latitude });
    }
}
