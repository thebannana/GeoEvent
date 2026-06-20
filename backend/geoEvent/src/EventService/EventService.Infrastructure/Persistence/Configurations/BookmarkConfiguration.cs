using EventService.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace EventService.Infrastructure.Persistence.Configurations;

public class BookmarkConfiguration : IEntityTypeConfiguration<Bookmark>
{
    public void Configure(EntityTypeBuilder<Bookmark> builder)
    {
        builder.ToTable("Bookmarks");

        builder.HasKey(b => b.BookmarkId);

        builder.Property(b => b.EventId)
            .IsRequired();

        builder.Property(b => b.UserId)
            .IsRequired();

        builder.Property(b => b.SavedAt)
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
        builder.HasIndex(b => new { b.UserId, b.EventId })
            .IsUnique();
    }
}