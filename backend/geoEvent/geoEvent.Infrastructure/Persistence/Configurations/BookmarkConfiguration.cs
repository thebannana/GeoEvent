using geoEvent.Model.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace geoEvent.Infrastructure.Persistence.Configurations
{
    public class BoomarkConfiguration : IEntityTypeConfiguration<Bookmark>
    {
        public void Configure(EntityTypeBuilder<Bookmark> builder)
        {
            builder.HasKey(b => b.BookmarkId);

            builder.HasOne(b => b.Event)
                   .WithMany()
                   .HasForeignKey(b => b.EventId)
                   .OnDelete(DeleteBehavior.Cascade);

            builder.HasOne(b => b.User)
                   .WithMany()
                   .HasForeignKey(b => b.UserId)
                   .OnDelete(DeleteBehavior.Cascade);

            builder.HasIndex(b => b.UserId);
            builder.HasIndex(b => b.EventId);
            builder.HasIndex(b => b.SavedAt);

            builder.Property(b => b.ImageUrl).HasMaxLength(500).IsRequired();
            builder.Property(b => b.Memo).HasMaxLength(500);
        }
    }
}