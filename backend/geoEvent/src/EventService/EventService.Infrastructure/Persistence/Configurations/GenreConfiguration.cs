using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using EventService.Domain.Entities;

namespace EventService.Infrastructure.Persistence.Configurations;

public class GenreConfiguration : IEntityTypeConfiguration<Genre>
{
    public void Configure(EntityTypeBuilder<Genre> builder)
    {
        builder.HasKey(g => g.GenreId);

        builder.Property(g => g.Name)
            .HasMaxLength(100)
            .IsRequired();

        builder.Property(g => g.IsActive)
            .HasDefaultValue(true);

        builder.HasOne(g => g.Segment)
            .WithMany(s => s.Genres)
            .HasForeignKey(g => g.SegmentId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasIndex(g => g.Name);
        builder.HasIndex(g => g.IsActive);
        builder.HasIndex(g => g.SegmentId);
        builder.HasIndex(g => new { g.SegmentId, g.IsActive });
    }
}
