using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using EventService.Domain.Entities;

namespace EventService.Infrastructure.Persistence.Configurations;

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
        builder.Property(v => v.TimeZone).HasMaxLength(100);
        builder.Property(v => v.Locale).HasMaxLength(10);
    }
}
