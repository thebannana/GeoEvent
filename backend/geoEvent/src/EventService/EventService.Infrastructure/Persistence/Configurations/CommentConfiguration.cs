using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using EventService.Domain.Entities;

namespace EventService.Infrastructure.Persistence.Configurations;

public class CommentConfiguration : IEntityTypeConfiguration<Comment>
{
    public void Configure(EntityTypeBuilder<Comment> builder)
    {
        builder.HasKey(c => c.CommentId);

        builder.Property(c => c.Content)
            .HasMaxLength(2000)
            .IsRequired();

        builder.Property(c => c.LikesCount)
            .HasDefaultValue(0);

        builder.HasOne(c => c.Event)
            .WithMany(e => e.Comments)
            .HasForeignKey(c => c.EventId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(c => c.ParentComment)
            .WithMany(c => c.Replies)
            .HasForeignKey(c => c.ParentCommentId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasIndex(c => c.EventId);
        builder.HasIndex(c => c.UserId);
        builder.HasIndex(c => c.CreatedAt);
        builder.HasIndex(c => c.ParentCommentId);
    }
}
