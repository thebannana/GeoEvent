using MessageService.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MessageService.Infrastructure.Persistence.Configurations;

public class ChatMessageLikeConfiguration : IEntityTypeConfiguration<ChatMessageLike>
{
    public void Configure(EntityTypeBuilder<ChatMessageLike> builder)
    {
        builder.ToTable("ChatMessageLikes");

        builder.HasKey(x => new { x.MessageId, x.UserId });

        builder.Property(x => x.LikedAt)
            .IsRequired();

        builder.HasOne(x => x.Message)
            .WithMany(x => x.Likes)
            .HasForeignKey(x => x.MessageId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(x => new { x.UserId, x.LikedAt });
    }
}