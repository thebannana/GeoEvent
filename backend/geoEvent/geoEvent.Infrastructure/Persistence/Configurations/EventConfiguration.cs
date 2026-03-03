using geoEvent.Model.Models;
using MathNet.Numerics.Statistics.Mcmc;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace geoEvent.Infrastructure.Persistence.Configurations
{
    public class EventConfiguration : IEntityTypeConfiguration<Event>
    {
        public void Configure(EntityTypeBuilder<Event> builder)
        {
            builder.HasKey(e => e.EventId);

            builder.HasOne(e => e.Organizer)
                   .WithMany()
                   .HasForeignKey(e => e.OrganizerId)
                   .OnDelete(DeleteBehavior.SetNull);

            builder.HasOne(e => e.Segment)
                   .WithMany()
                   .HasForeignKey(e => e.SegmentId)
                   .OnDelete(DeleteBehavior.SetNull);

            builder.HasOne(e => e.Genre)
                   .WithMany()
                   .HasForeignKey(e => e.GenreId)
                   .OnDelete(DeleteBehavior.SetNull);

            builder.HasOne(e => e.SubGenre)
                   .WithMany()
                   .HasForeignKey(e => e.SubGenreId)
                   .OnDelete(DeleteBehavior.SetNull);

            builder.HasOne(e => e.Venue)
                   .WithMany(v => v.Events)
                   .HasForeignKey(e => e.VenueId)
                   .OnDelete(DeleteBehavior.SetNull);

            builder.HasOne(e => e.City)
                   .WithMany()
                   .HasForeignKey(e => e.CityId)
                   .OnDelete(DeleteBehavior.SetNull);

            builder.HasIndex(e => e.OrganizerId);
            builder.HasIndex(e => e.SegmentId);
            builder.HasIndex(e => e.GenreId);
            builder.HasIndex(e => e.SubGenreId);
            builder.HasIndex(e => e.VenueId);
            builder.HasIndex(e => e.CityId);
            builder.HasIndex(e => e.Status);
            builder.HasIndex(e => e.IsFeatured);
            builder.HasIndex(e => e.StartDateTime);

            builder.HasIndex(e => new { e.CityId, e.StartDateTime });
            builder.HasIndex(e => new { e.CityId, e.Status });
            builder.HasIndex(e => new { e.SegmentId, e.StartDateTime });
            builder.HasIndex(e => new { e.GenreId, e.StartDateTime });
            builder.HasIndex(e => new { e.Status, e.StartDateTime });
            builder.HasIndex(e => new { e.Longitude, e.Latitude });

            builder.HasIndex(e => new { e.ExternalSource, e.ExternalId })
                   .IsUnique()
                   .HasFilter("[ExternalSource] IS NOT NULL AND [ExternalId] IS NOT NULL");

            builder.Property(e => e.Title).HasMaxLength(200).IsRequired();
            builder.Property(e => e.Description).HasMaxLength(5000);
            builder.Property(e => e.Status).HasMaxLength(50).IsRequired();
            builder.Property(e => e.Latitude).HasColumnType("decimal(9,6)");
            builder.Property(e => e.Longitude).HasColumnType("decimal(9,6)");
            builder.Property(e => e.Price).HasColumnType("decimal(18,2)").HasDefaultValue(0);
            builder.Property(e => e.ExternalSource).HasMaxLength(100);
            builder.Property(e => e.ExternalId).HasMaxLength(255);
            builder.Property(e => e.ExternalUrl).HasMaxLength(1000);
            builder.Property(e => e.Tags).HasMaxLength(500);
            builder.Property(e => e.AccessibilityInfo).HasMaxLength(1000);
            builder.Property(e => e.PromoterName).HasMaxLength(200);
            builder.Property(e => e.Locale).HasMaxLength(10).HasDefaultValue("bs-BA");
            builder.Property(e => e.ViewCount).HasDefaultValue(0);
            builder.Property(e => e.LikesCount).HasDefaultValue(0);
            builder.Property(e => e.IsFeatured).HasDefaultValue(false);
            builder.Property(e => e.IsOnline).HasDefaultValue(false);
            builder.Property(e => e.Capacity).HasDefaultValue(0);
        }
    }
}