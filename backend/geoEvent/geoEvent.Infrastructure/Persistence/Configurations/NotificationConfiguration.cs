using geoEvent.Model.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace geoEvent.Infrastructure.Persistence.Configurations
{
    public class NotificationConfiguration : IEntityTypeConfiguration<Notification>
    {
        public void Configure(EntityTypeBuilder<Notification> builder)
        {
            builder.HasKey(n => n.NotificationId);

            builder.HasOne(n => n.User)
                   .WithMany()
                   .HasForeignKey(n => n.UserId)
                   .OnDelete(DeleteBehavior.Cascade);

            builder.HasIndex(n => n.UserId);
            builder.HasIndex(n => n.CreatedAt);
            builder.HasIndex(n => n.IsRead);
            builder.HasIndex(n => n.Type);

            builder.Property(n => n.Type).HasMaxLength(50).IsRequired();
            builder.Property(n => n.Title).HasMaxLength(200).IsRequired();
            builder.Property(n => n.Description).HasMaxLength(1000);
        }
    }
}