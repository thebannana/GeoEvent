using geoEvent.Model.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace geoEvent.Infrastructure.Persistence.Configurations
{
    public class UserPreferenceConfiguration : IEntityTypeConfiguration<UserPreference>
    {
        public void Configure(EntityTypeBuilder<UserPreference> builder)
        {
            builder.HasKey(p => p.PrefId);

            builder.HasOne(p => p.User)
                   .WithMany()
                   .HasForeignKey(p => p.UserId)
                   .OnDelete(DeleteBehavior.Cascade);

            builder.HasOne(p => p.Segment)
                   .WithMany()
                   .HasForeignKey(p => p.SegmentId)
                   .OnDelete(DeleteBehavior.Cascade);

            builder.HasOne(p => p.Genre)
                   .WithMany()
                   .HasForeignKey(p => p.GenreId)
                   .OnDelete(DeleteBehavior.SetNull);

            builder.HasIndex(p => p.UserId);
            builder.HasIndex(p => p.SegmentId);
            builder.HasIndex(p => p.GenreId);
            builder.HasIndex(p => p.LastUpdated);

            builder.HasIndex(p => new { p.UserId, p.SegmentId, p.GenreId })
                   .IsUnique()
                   .HasFilter("[UserId] IS NOT NULL AND [SegmentId] IS NOT NULL");

            builder.Property(p => p.Score).IsRequired();
            builder.Property(p => p.Score).HasDefaultValue(0.0);
        }
    }
}