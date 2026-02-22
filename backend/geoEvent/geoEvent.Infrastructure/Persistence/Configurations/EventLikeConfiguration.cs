using geoEvent.Model.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace geoEvent.Infrastructure.Persistence.Configurations
{
    public class EventLikeConfiguration : IEntityTypeConfiguration<EventLike>
    {
        public void Configure(EntityTypeBuilder<EventLike> builder)
        {
            builder.HasKey(l => l.LikeId);

            builder.HasOne(l => l.Event)
                   .WithMany()
                   .HasForeignKey(l => l.EventId)
                   .OnDelete(DeleteBehavior.Cascade);

            builder.HasOne(l => l.User)
                   .WithMany()
                   .HasForeignKey(l => l.UserId)
                   .OnDelete(DeleteBehavior.Cascade);

            builder.HasIndex(l => l.EventId);
            builder.HasIndex(l => l.UserId);
            builder.HasIndex(l => l.LikedAt);

            builder.Property(l => l.LikedAt).IsRequired();
        }
    }
}