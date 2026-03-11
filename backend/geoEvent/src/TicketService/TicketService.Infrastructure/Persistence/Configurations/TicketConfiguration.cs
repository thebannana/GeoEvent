using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using TicketService.Domain.Entities;

namespace TicketService.Infrastructure.Persistence.Configurations;

public class TicketConfiguration : IEntityTypeConfiguration<Ticket>
{
    public void Configure(EntityTypeBuilder<Ticket> builder)
    {
        builder.ToTable("IssuedTickets");

        builder.HasKey(t => t.TicketId);

        builder.Property(t => t.CancelledAt);
        builder.Property(t => t.Amount).HasPrecision(18, 2);
        builder.Property(t => t.Currency).HasMaxLength(3).IsRequired();
        builder.Property(t => t.QrCode).HasMaxLength(512).IsRequired();
        builder.Property(t => t.TicketType).HasMaxLength(100).IsRequired();
        builder.Property(t => t.SeatNumber).HasMaxLength(20);
        builder.Property(t => t.Section).HasMaxLength(50);
        builder.Property(t => t.Status).HasConversion<string>().HasMaxLength(50);

        builder.HasIndex(t => t.QrCode).IsUnique();
        builder.HasIndex(t => t.UserId);
        builder.HasIndex(t => t.EventId);
        builder.HasIndex(t => t.ReservationId);
        builder.HasIndex(t => t.Status);
        builder.HasIndex(t => t.IssuedAt);
    }
}
