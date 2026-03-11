using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using EventService.Domain.Entities;

namespace EventService.Infrastructure.Persistence.Configurations;

public class BookmarkConfiguration : IEntityTypeConfiguration<Bookmark>
{
    public void Configure(EntityTypeBuilder<Bookmark> builder)
    {
        builder.HasKey(b => b.BookmarkId);

        builder.Property(b => b.ImageUrl)
            .HasMaxLength(500)
            .IsRequired();

        builder.Property(b => b.Memo)
            .HasMaxLength(500)
            .IsRequired(false);

        builder.HasOne(b => b.Event)
            .WithMany(e => e.Bookmarks)
            .HasForeignKey(b => b.EventId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(b => b.UserId);
        builder.HasIndex(b => b.EventId);
        builder.HasIndex(b => b.SavedAt);
        builder.HasIndex(b => new { b.UserId, b.EventId }).IsUnique()
            .HasFilter("[UserId] IS NOT NULL AND [EventId] IS NOT NULL");
    }
}
