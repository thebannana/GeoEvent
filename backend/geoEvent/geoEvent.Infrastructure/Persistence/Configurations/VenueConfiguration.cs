using geoEvent.Model.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace geoEvent.Infrastructure.Persistence.Configurations
{
    public class VenueConfiguration : IEntityTypeConfiguration<Venue>
    {
        public void Configure(EntityTypeBuilder<Venue> builder)
        {
            builder.HasKey(v => v.VenueId);

            builder.HasOne(v => v.City)
                   .WithMany()
                   .HasForeignKey(v => v.CityId)
                   .OnDelete(DeleteBehavior.SetNull);

            builder.HasMany(v => v.PriceZones)
                   .WithOne(p => p.Venue)
                   .HasForeignKey(p => p.VenueId)
                   .OnDelete(DeleteBehavior.Restrict);

            builder.HasIndex(v => v.CityId);
            builder.HasIndex(v => v.IsVerified);
            builder.HasIndex(v => v.VenueType);
            builder.HasIndex(v => new { v.Longitude, v.Latitude });
            builder.HasIndex(v => new { v.CityId, v.VenueType });
            builder.HasIndex(v => v.Name);

            builder.Property(v => v.Name).HasMaxLength(200).IsRequired();
            builder.Property(v => v.Address).HasMaxLength(500);
            builder.Property(v => v.VenueType).HasMaxLength(100);
            builder.Property(v => v.WebsiteUrl).HasMaxLength(1000);
            builder.Property(v => v.PhoneNumber).HasMaxLength(30);
            builder.Property(v => v.Latitude).HasColumnType("decimal(9,6)");
            builder.Property(v => v.Longitude).HasColumnType("decimal(9,6)");
            builder.Property(v => v.IsVerified).HasDefaultValue(false);
            builder.Property(v => v.Description).HasMaxLength(2000);
            builder.Property(v => v.Locale).HasMaxLength(10);
            builder.Property(v => v.TimeZone).HasMaxLength(50);
        }
    }
}