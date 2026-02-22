using geoEvent.Model.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace geoEvent.Infrastructure.Persistence.Configurations
{
    public class NotificationQueueConfiguration : IEntityTypeConfiguration<NotificationQueue>
    {
        public void Configure(EntityTypeBuilder<NotificationQueue> builder)
        {
            builder.HasKey(q => q.QueueId);

            builder.HasOne(q => q.User)
                   .WithMany()
                   .HasForeignKey(q => q.UserId)
                   .OnDelete(DeleteBehavior.SetNull);

            builder.HasIndex(q => q.UserId);
            builder.HasIndex(q => q.ScheduledAt);
            builder.HasIndex(q => q.ProcessedAt);
            builder.HasIndex(q => q.Status);
            builder.HasIndex(q => q.Type);

            builder.Property(q => q.Status).HasMaxLength(50).IsRequired();
            builder.Property(q => q.Type).HasMaxLength(50).IsRequired();
            builder.Property(q => q.payload).HasColumnName("Payload").HasMaxLength(4000);
            builder.Property(q => q.ErrorMessage).HasMaxLength(1000);
        }
    }
}