using EventService.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace EventService.Infrastructure.Persistence.Configurations;

public class CommentLikeConfiguration : IEntityTypeConfiguration<CommentLike>
{
    public void Configure(EntityTypeBuilder<CommentLike> builder)
    {
        builder.ToTable("CommentLikes");

        builder.HasKey(l => l.LikeId);

        builder.Property(l => l.CommentId)
            .IsRequired();

        builder.Property(l => l.UserId)
            .IsRequired();

        builder.Property(l => l.LikedAt)
            .IsRequired();

        builder.HasIndex(l => l.CommentId);
        builder.HasIndex(l => l.UserId);
        builder.HasIndex(l => l.LikedAt);
        builder.HasIndex(l => new { l.UserId, l.CommentId })
            .IsUnique();

        builder.HasOne(l => l.Comment)
            .WithMany()
            .HasForeignKey(l => l.CommentId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}