using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using NotificationService.Domain.Entities;

namespace NotificationService.Infrastructure.Persistence.Configurations;

public class NotificationQueueConfiguration : IEntityTypeConfiguration<NotificationQueue>
{
    public void Configure(EntityTypeBuilder<NotificationQueue> builder)
    {
        builder.HasKey(q => q.QueueId);

        builder.Property(q => q.Status)
            .HasMaxLength(50)
            .IsRequired();

        builder.Property(q => q.Type)
            .HasMaxLength(50)
            .IsRequired();

        builder.Property(q => q.Payload)
            .HasMaxLength(4000)
            .IsRequired();

        builder.Property(q => q.ErrorMessage)
            .HasMaxLength(1000);

        builder.Property(q => q.AttemptCount)
            .HasDefaultValue(0);

        builder.HasIndex(q => q.UserId);
        builder.HasIndex(q => q.Status);
        builder.HasIndex(q => q.Type);
        builder.HasIndex(q => q.ScheduledAt);
        builder.HasIndex(q => q.ProcessedAt);
    }
}
