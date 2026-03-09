using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using EventService.Domain.Entities;

namespace EventService.Infrastructure.Persistence.Configurations;

public class EventConfiguration : IEntityTypeConfiguration<Event>
{
    public void Configure(EntityTypeBuilder<Event> builder)
    {
        builder.ToTable("Events");
        builder.HasKey(e => e.EventId);

        builder.Property(e => e.Title).IsRequired().HasMaxLength(200);
        builder.Property(e => e.Description).IsRequired().HasMaxLength(5000);
        builder.Property(e => e.Status).HasConversion<string>().HasMaxLength(50);
        builder.Property(e => e.Latitude).HasPrecision(9, 6);
        builder.Property(e => e.Longitude).HasPrecision(9, 6);
        builder.Property(e => e.Price).HasPrecision(18, 2);
        builder.Property(e => e.Tags).HasMaxLength(500);
        builder.Property(e => e.ExternalUrl).HasMaxLength(1000);
        builder.Property(e => e.ExternalSource).HasMaxLength(100);
        builder.Property(e => e.ExternalId).HasMaxLength(255);
        builder.Property(e => e.Locale).HasMaxLength(10).HasDefaultValue("bs-BA");
        builder.Property(e => e.AccessibilityInfo).HasMaxLength(1000);
        builder.Property(e => e.PromoterName).HasMaxLength(200);

        builder.HasIndex(e => e.Status);
        builder.HasIndex(e => e.StartDateTime);
        builder.HasIndex(e => e.CityId);
        builder.HasIndex(e => e.OrganizerId);
        builder.HasIndex(e => e.IsFeatured);
        builder.HasIndex(e => new { e.ExternalSource, e.ExternalId }).IsUnique()
            .HasFilter("[ExternalSource] IS NOT NULL AND [ExternalId] IS NOT NULL");

        builder.HasOne(e => e.Venue)
            .WithMany(v => v.Events)
            .HasForeignKey(e => e.VenueId)
            .OnDelete(DeleteBehavior.SetNull);
    }
}
