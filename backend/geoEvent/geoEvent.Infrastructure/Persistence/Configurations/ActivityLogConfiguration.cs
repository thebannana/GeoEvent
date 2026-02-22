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

            builder.HasOne(l => l.Category)
                   .WithMany()
                   .HasForeignKey(l => l.CategoryId)
                   .OnDelete(DeleteBehavior.SetNull);

            builder.HasIndex(l => l.CreatedAt);
            builder.HasIndex(l => l.UserId);
            builder.HasIndex(l => new { l.ActionType, l.CreatedAt });
            builder.HasIndex(l => l.SessionId);

            builder.Property(l => l.ActionType).HasMaxLength(50).IsRequired();
            builder.Property(l => l.TargetType).HasMaxLength(50).IsRequired();
            builder.Property(l => l.Metadata).HasMaxLength(1000);
        }
    }
}