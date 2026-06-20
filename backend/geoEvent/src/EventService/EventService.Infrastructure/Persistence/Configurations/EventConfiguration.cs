using EventService.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace EventService.Infrastructure.Persistence.Configurations;

public class EventConfiguration : IEntityTypeConfiguration<Event>
{
    public void Configure(EntityTypeBuilder<Event> builder)
    {
        builder.ToTable("Events");

        builder.HasKey(e => e.EventId);

        builder.Property(e => e.OrganizerId)
            .IsRequired();

        builder.Property(e => e.SegmentId)
            .IsRequired();

        builder.Property(e => e.GenreId)
            .IsRequired();

        builder.Property(e => e.Title)
            .IsRequired()
            .HasMaxLength(200);

        builder.Property(e => e.Description)
            .IsRequired()
            .HasMaxLength(4000);

        builder.Property(e => e.Status)
            .HasConversion<string>()
            .HasMaxLength(50)
            .IsRequired();

        builder.Property(e => e.Latitude)
            .HasPrecision(9, 6);

        builder.Property(e => e.Longitude)
            .HasPrecision(9, 6);

        builder.Property(e => e.Capacity)
            .IsRequired();

        builder.Property(e => e.Price)
            .HasPrecision(18, 2)
            .IsRequired();

        builder.Property(e => e.IsOnline)
            .HasDefaultValue(false);

        builder.Property(e => e.IsFeatured)
            .HasDefaultValue(false);

        builder.Property(e => e.ViewCount)
            .HasDefaultValue(0);

        builder.Property(e => e.LikesCount)
            .HasDefaultValue(0);

        builder.Property(e => e.Tags)
            .HasMaxLength(500);

        builder.Property(e => e.ExternalUrl)
            .HasMaxLength(1000);

        builder.Property(e => e.ExternalSource)
            .HasMaxLength(100);

        builder.Property(e => e.ExternalId)
            .HasMaxLength(255);

        builder.Property(e => e.Locale)
            .HasMaxLength(10)
            .HasDefaultValue("bs-BA")
            .IsRequired();

        builder.Property(e => e.AccessibilityInfo)
            .HasMaxLength(1000);

        builder.Property(e => e.PromoterName)
            .HasMaxLength(200);

        builder.Property(e => e.CreatedAt)
            .IsRequired();

        builder.HasIndex(e => e.Status);
        builder.HasIndex(e => e.StartDateTime);
        builder.HasIndex(e => e.OrganizerId);
        builder.HasIndex(e => e.IsFeatured);
        builder.HasIndex(e => e.SegmentId);
        builder.HasIndex(e => e.GenreId);
        builder.HasIndex(e => e.SubGenreId);
        builder.HasIndex(e => new { e.Status, e.StartDateTime });
        builder.HasIndex(e => new { e.SegmentId, e.StartDateTime });
        builder.HasIndex(e => new { e.GenreId, e.StartDateTime });
        builder.HasIndex(e => new { e.Longitude, e.Latitude });
        builder.HasIndex(e => new { e.ExternalSource, e.ExternalId })
            .IsUnique()
            .HasFilter("[ExternalSource] IS NOT NULL AND [ExternalId] IS NOT NULL");

        builder.HasOne(e => e.Segment)
            .WithMany(s => s.Events)
            .HasForeignKey(e => e.SegmentId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(e => e.Genre)
            .WithMany(g => g.Events)
            .HasForeignKey(e => e.GenreId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(e => e.SubGenre)
            .WithMany(s => s.Events)
            .HasForeignKey(e => e.SubGenreId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}