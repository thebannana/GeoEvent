using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using EventService.Domain.Entities;

namespace EventService.Infrastructure.Persistence.Configurations;

public class CommentLikeConfiguration : IEntityTypeConfiguration<CommentLike>
{
    public void Configure(EntityTypeBuilder<CommentLike> builder)
    {
        builder.ToTable("CommentLikes");
        builder.HasKey(l => l.LikeId);

        builder.HasIndex(l => new { l.UserId, l.CommentId })
            .IsUnique()
            .HasFilter("UserId IS NOT NULL AND CommentId IS NOT NULL");

        builder.HasIndex(l => l.CommentId);
        builder.HasIndex(l => l.UserId);

        builder.HasOne(l => l.Comment)
            .WithMany()
            .HasForeignKey(l => l.CommentId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}