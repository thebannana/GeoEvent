using geoEvent.Model.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace geoEvent.Infrastructure.Persistence.Configurations
{
    public class ReservationConfiguration : IEntityTypeConfiguration<Reservation>
    {
        public void Configure(EntityTypeBuilder<Reservation> builder)
        {
            builder.HasKey(r => r.ReservationId);

            builder.HasOne(r => r.Event)
                   .WithMany(e => e.Reservations)
                   .HasForeignKey(r => r.EventId)
                   .OnDelete(DeleteBehavior.Cascade);

            builder.HasOne(r => r.Ticket)
                   .WithMany(t => t.Reservations)
                   .HasForeignKey(r => r.TicketId)
                   .OnDelete(DeleteBehavior.NoAction);

            builder.HasOne(r => r.User)
                   .WithMany()
                   .HasForeignKey(r => r.UserId)
                   .OnDelete(DeleteBehavior.Cascade);

            builder.HasIndex(r => r.EventId);
            builder.HasIndex(r => r.UserId);
            builder.HasIndex(r => r.ReservedAt);
            builder.HasIndex(r => r.Status);

            builder.Property(r => r.Status).HasMaxLength(50).IsRequired();
        }
    }
}