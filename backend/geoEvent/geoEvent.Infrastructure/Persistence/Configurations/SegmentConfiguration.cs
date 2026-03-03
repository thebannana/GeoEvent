using geoEvent.Model.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace geoEvent.Infrastructure.Persistence.Configurations
{
    public class SegmentConfiguration : IEntityTypeConfiguration<Segment>
    {
        public void Configure(EntityTypeBuilder<Segment> builder)
        {
            builder.HasKey(s => s.SegmentId);

            builder.HasMany(s => s.Genres)
                   .WithOne(g => g.Segment)
                   .HasForeignKey(g => g.SegmentId)
                   .OnDelete(DeleteBehavior.Restrict);

            builder.HasIndex(s => s.Name).IsUnique();
            builder.HasIndex(s => s.IsActive);

            builder.Property(s => s.Name).HasMaxLength(100).IsRequired();
            builder.Property(s => s.IconUrl).HasMaxLength(500);
            builder.Property(s => s.Color).HasMaxLength(7);
            builder.Property(s => s.IsActive).HasDefaultValue(true);
        }
    }

}