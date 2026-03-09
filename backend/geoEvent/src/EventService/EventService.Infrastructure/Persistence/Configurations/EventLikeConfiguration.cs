using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using EventService.Domain.Entities;

namespace EventService.Infrastructure.Persistence.Configurations;

public class EventLikeConfiguration : IEntityTypeConfiguration<EventLike>
{
    public void Configure(EntityTypeBuilder<EventLike> builder)
    {
        builder.ToTable("EventLikes");
        builder.HasKey(l => l.LikeId);

        builder.HasIndex(l => new { l.UserId, l.EventId })
            .IsUnique()
            .HasFilter("[UserId] IS NOT NULL AND [EventId] IS NOT NULL");
        builder.HasIndex(l => l.UserId);

        builder.HasOne(l => l.Event)
            .WithMany(e => e.Likes)
            .HasForeignKey(l => l.EventId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
