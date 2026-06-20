using EventService.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace EventService.Infrastructure.Persistence.Configurations;

public class SegmentConfiguration : IEntityTypeConfiguration<Segment>
{
    public void Configure(EntityTypeBuilder<Segment> builder)
    {
        builder.ToTable("Segments");

        builder.HasKey(s => s.SegmentId);

        builder.Property(s => s.Name)
            .HasMaxLength(100)
            .IsRequired();

        builder.Property(s => s.IconUrl)
            .HasMaxLength(1000);

        builder.Property(s => s.Color)
            .HasMaxLength(20);

        builder.Property(s => s.IsActive)
            .HasDefaultValue(true);

        builder.HasIndex(s => s.Name)
            .IsUnique();

        builder.HasIndex(s => s.IsActive);
    }
}