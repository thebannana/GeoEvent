using geoEvent.Model.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace geoEvent.Infrastructure.Persistence.Configurations
{
    public class ActivityLogConfiguration : IEntityTypeConfiguration<ActivityLog>
    {
        public void Configure(EntityTypeBuilder<ActivityLog> builder)
        {
            builder.HasKey(l => l.LogId);

            builder.HasOne(l => l.User)
                   .WithMany()
                   .HasForeignKey(l => l.UserId)
                   .OnDelete(DeleteBehavior.SetNull);

            builder.HasOne(l => l.Segment)
                   .WithMany()
                   .HasForeignKey(l => l.SegmentId)
                   .OnDelete(DeleteBehavior.SetNull);

            builder.HasOne(l => l.Genre)
                   .WithMany()
                   .HasForeignKey(l => l.GenreId)
                   .OnDelete(DeleteBehavior.SetNull);

            builder.HasIndex(l => l.CreatedAt);
            builder.HasIndex(l => l.UserId);
            builder.HasIndex(l => l.SegmentId);
            builder.HasIndex(l => l.GenreId);
            builder.HasIndex(l => l.SessionId);
            builder.HasIndex(l => new { l.ActionType, l.CreatedAt });
            builder.HasIndex(l => new { l.SegmentId, l.CreatedAt });
            builder.HasIndex(l => new { l.UserId, l.CreatedAt });

            builder.Property(l => l.ActionType).HasMaxLength(50).IsRequired();
            builder.Property(l => l.TargetType).HasMaxLength(50).IsRequired();
            builder.Property(l => l.Metadata).HasMaxLength(1000);
        }
    }
}