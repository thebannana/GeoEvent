using geoEvent.Model.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace geoEvent.Infrastructure.Persistence.Configurations
{
    public class CommentConfiguration : IEntityTypeConfiguration<Comment>
    {
        public void Configure(EntityTypeBuilder<Comment> builder)
        {
            builder.HasKey(c => c.CommentId);

            builder.HasOne(c => c.User)
                   .WithMany()
                   .HasForeignKey(c => c.UserId)
                   .OnDelete(DeleteBehavior.SetNull);

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

            builder.Property(c => c.Content).HasMaxLength(2000).IsRequired();
            builder.Property(c => c.LikesCount).HasDefaultValue(0);
        }
    }
}