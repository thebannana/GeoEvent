using MessageService.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MessageService.Infrastructure.Persistence.Configurations;

public class MessageConfiguration : IEntityTypeConfiguration<Message>
{
    public void Configure(EntityTypeBuilder<Message> builder)
    {
        builder.HasKey(m => m.Id);

        builder.Property(m => m.Content)
            .IsRequired()
            .HasMaxLength(4000);

        builder.Property(m => m.SentAt)
            .IsRequired();

        builder.Property(m => m.IsRead)
            .HasDefaultValue(false);

        builder.Property(m => m.IsDeletedBySender)
            .HasDefaultValue(false);

        builder.Property(m => m.IsDeletedByRecipient)
            .HasDefaultValue(false);

        builder.Property(m => m.LikesCount)
            .HasDefaultValue(0);

        // EventId is nullable FK to external service — no navigation, just the column
        builder.Property(m => m.EventId);

        builder.Property(m => m.EditedAt);

        builder.HasIndex(m => m.SenderId);
        builder.HasIndex(m => m.RecipientId);
        builder.HasIndex(m => m.IsRead);
        builder.HasIndex(m => m.SentAt);
        builder.HasIndex(m => m.EventId);
        builder.HasIndex(m => new { m.SenderId, m.RecipientId });
        builder.HasIndex(m => new { m.SenderId, m.RecipientId, m.SentAt });
    }
}
