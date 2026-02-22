using geoEvent.Model.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace geoEvent.Infrastructure.Persistence.Configurations
{
    public class MessageConfiguration : IEntityTypeConfiguration<Message>
    {
        public void Configure(EntityTypeBuilder<Message> builder)
        {
            builder.HasKey(m => m.MessageId);

            builder.HasOne(m => m.Sender)
                   .WithMany()
                   .HasForeignKey(m => m.SenderId)
                   .OnDelete(DeleteBehavior.NoAction);

            builder.HasOne(m => m.Receiver)
                   .WithMany()
                   .HasForeignKey(m => m.ReceiverId)
                   .OnDelete(DeleteBehavior.NoAction);

            builder.HasOne(m => m.Event)
                   .WithMany()
                   .HasForeignKey(m => m.EventId)
                   .OnDelete(DeleteBehavior.NoAction);

            builder.HasIndex(m => m.ReceiverId);
            builder.HasIndex(m => m.SenderId);
            builder.HasIndex(m => m.EventId);
            builder.HasIndex(m => m.SentAt);
            builder.HasIndex(m => m.IsRead);

            builder.Property(m => m.Content).HasMaxLength(4000).IsRequired();
        }
    }
}