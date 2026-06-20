using EventService.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace EventService.Infrastructure.Persistence.Configurations;

public class EventLikeConfiguration : IEntityTypeConfiguration<EventLike>
{
    public void Configure(EntityTypeBuilder<EventLike> builder)
    {
        builder.ToTable("EventLikes");

        builder.HasKey(l => l.LikeId);

        builder.Property(l => l.EventId)
            .IsRequired();

        builder.Property(l => l.UserId)
            .IsRequired();

        builder.Property(l => l.LikedAt)
            .IsRequired();

        builder.HasIndex(l => l.UserId);
        builder.HasIndex(l => l.EventId);
        builder.HasIndex(l => l.LikedAt);
        builder.HasIndex(l => new { l.UserId, l.EventId })
            .IsUnique();

        builder.HasOne(l => l.Event)
            .WithMany(e => e.Likes)
            .HasForeignKey(l => l.EventId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}