using EventService.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace EventService.Infrastructure.Persistence.Configurations;

public class CommentConfiguration : IEntityTypeConfiguration<Comment>
{
    public void Configure(EntityTypeBuilder<Comment> builder)
    {
        builder.ToTable("Comments");

        builder.HasKey(c => c.CommentId);

        builder.Property(c => c.UserId)
            .IsRequired();

        builder.Property(c => c.EventId)
            .IsRequired();

        builder.Property(c => c.Content)
            .HasMaxLength(1000)
            .IsRequired();

        builder.Property(c => c.LikesCount)
            .HasDefaultValue(0);

        builder.Property(c => c.IsDeleted)
            .HasDefaultValue(false);

        builder.Property(c => c.CreatedAt)
            .IsRequired();

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
        builder.HasIndex(c => new { c.EventId, c.CreatedAt });
    }
}