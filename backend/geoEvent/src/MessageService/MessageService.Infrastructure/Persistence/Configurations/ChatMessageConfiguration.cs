using MessageService.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MessageService.Infrastructure.Persistence.Configurations;

public class ChatMessageConfiguration : IEntityTypeConfiguration<ChatMessage>
{
    public void Configure(EntityTypeBuilder<ChatMessage> builder)
    {
        builder.ToTable("ChatMessages");

        builder.HasKey(x => x.Id);

        builder.Property(x => x.Content)
            .IsRequired()
            .HasMaxLength(4000);

        builder.Property(x => x.SentAt)
            .IsRequired();

        builder.Property(x => x.EditedAt);

        builder.Property(x => x.DeletedAt);

        builder.Property(x => x.LikesCount)
            .HasDefaultValue(0);

        builder.HasIndex(x => new { x.ThreadId, x.SentAt });
        builder.HasIndex(x => x.ThreadId);
        builder.HasIndex(x => x.SenderId);

        builder.HasOne(x => x.Thread)
            .WithMany(x => x.Messages)
            .HasForeignKey(x => x.ThreadId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(x => x.ReplyToMessage)
            .WithMany(x => x.Replies)
            .HasForeignKey(x => x.ReplyToMessageId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}