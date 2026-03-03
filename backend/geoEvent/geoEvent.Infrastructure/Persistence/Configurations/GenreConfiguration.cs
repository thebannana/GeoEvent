using geoEvent.Model.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace geoEvent.Infrastructure.Persistence.Configurations
{
    public class GenreConfiguration : IEntityTypeConfiguration<Genre>
    {
        public void Configure(EntityTypeBuilder<Genre> builder)
        {
            builder.HasKey(g => g.GenreId);

            builder.HasOne(g => g.Segment)
                   .WithMany(s => s.Genres)
                   .HasForeignKey(g => g.SegmentId)
                   .OnDelete(DeleteBehavior.Restrict);

            builder.HasMany(g => g.SubGenres)
                   .WithOne(sg => sg.Genre)
                   .HasForeignKey(sg => sg.GenreId)
                   .OnDelete(DeleteBehavior.Restrict);

            builder.HasIndex(g => g.Name);
            builder.HasIndex(g => g.SegmentId);
            builder.HasIndex(g => g.IsActive);
            builder.HasIndex(g => new { g.SegmentId, g.IsActive });

            builder.Property(g => g.Name).HasMaxLength(100).IsRequired();
            builder.Property(g => g.IsActive).HasDefaultValue(true);
        }
    }

}