using geoEvent.Model.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace geoEvent.Infrastructure.Persistence.Configurations
{
    public class EventImageConfiguration : IEntityTypeConfiguration<EventImage>
    {
        public void Configure(EntityTypeBuilder<EventImage> builder)
        {
            builder.HasKey(i => i.ImageId);

            builder.HasOne(i => i.Event)
                   .WithMany()
                   .HasForeignKey(i => i.EventId)
                   .OnDelete(DeleteBehavior.Cascade);

            builder.HasIndex(i => i.EventId);
            builder.HasIndex(i => i.IsCover);
            builder.HasIndex(i => i.UploadedAt);

            builder.Property(i => i.ImageUrl).HasMaxLength(500).IsRequired();
        }
    }
}