using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using EventService.Domain.Entities;

namespace EventService.Infrastructure.Persistence.Configurations;

public class PriceZoneConfiguration : IEntityTypeConfiguration<PriceZone>
{
    public void Configure(EntityTypeBuilder<PriceZone> builder)
    {
        builder.HasKey(p => p.PriceZoneId);

        builder.Property(p => p.Name)
            .HasMaxLength(200)
            .IsRequired();

        builder.Property(p => p.Description)
            .HasMaxLength(500);

        builder.Property(p => p.IsActive)
            .HasDefaultValue(true);

        builder.HasOne(p => p.Venue)
            .WithMany(v => v.PriceZones)
            .HasForeignKey(p => p.VenueId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasIndex(p => p.VenueId);
        builder.HasIndex(p => p.IsActive);
        builder.HasIndex(p => new { p.VenueId, p.IsActive });
    }
}
