using geoEvent.Model.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace geoEvent.Infrastructure.Persistence.Configurations
{
    public class PriceZoneConfiguration : IEntityTypeConfiguration<PriceZone>
    {
        public void Configure(EntityTypeBuilder<PriceZone> builder)
        {
            builder.HasKey(p => p.PriceZoneId);

            builder.HasOne(p => p.Venue)
                   .WithMany()
                   .HasForeignKey(p => p.VenueId)
                   .OnDelete(DeleteBehavior.Restrict);

            builder.HasIndex(p => p.VenueId);
            builder.HasIndex(p => p.IsActive);
            builder.HasIndex(p => new { p.VenueId, p.IsActive });

            builder.Property(p => p.Name).HasMaxLength(200).IsRequired();
            builder.Property(p => p.Description).HasMaxLength(500);
            builder.Property(p => p.IsActive).HasDefaultValue(true);
        }
    }
}