using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using EventService.Domain.Entities;

namespace EventService.Infrastructure.Persistence.Configurations;

public class EventImageConfiguration : IEntityTypeConfiguration<EventImage>
{
    public void Configure(EntityTypeBuilder<EventImage> builder)
    {
        builder.ToTable("EventImages");
        builder.HasKey(i => i.ImageId);

        builder.Property(i => i.ImageUrl).IsRequired().HasMaxLength(500);
        builder.Property(i => i.IsCover).HasDefaultValue(false);

        builder.HasIndex(i => i.EventId);
        builder.HasIndex(i => new { i.EventId, i.IsCover });

        builder.HasOne(i => i.Event)
            .WithMany(e => e.Images)
            .HasForeignKey(i => i.EventId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
