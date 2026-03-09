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
            .HasMaxLength(2000);

        builder.Property(m => m.SentAt)
            .IsRequired();

        builder.Property(m => m.IsRead)
            .HasDefaultValue(false);

        builder.Property(m => m.IsDeletedBySender)
            .HasDefaultValue(false);

        builder.Property(m => m.IsDeletedByRecipient)
            .HasDefaultValue(false);

        builder.HasIndex(m => m.SenderId);
        builder.HasIndex(m => m.RecipientId);
        builder.HasIndex(m => m.IsRead);
        builder.HasIndex(m => m.SentAt);
        builder.HasIndex(m => new { m.SenderId, m.RecipientId });
    }
}
