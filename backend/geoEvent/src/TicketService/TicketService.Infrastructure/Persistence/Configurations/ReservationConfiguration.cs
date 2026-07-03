using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using TicketService.Domain.Entities;

namespace TicketService.Infrastructure.Persistence.Configurations;

public class ReservationConfiguration : IEntityTypeConfiguration<Reservation>
{
    public void Configure(EntityTypeBuilder<Reservation> builder)
    {
        builder.HasKey(r => r.ReservationId);

        builder.Property(r => r.ExpiredAt);
        builder.Property(r => r.TotalAmount).HasPrecision(18, 2);
        builder.Property(r => r.Currency).HasMaxLength(3).IsRequired();
        builder.Property(r => r.PaymentReference).HasMaxLength(256);
        builder.Property(r => r.Notes).HasMaxLength(500);
        builder.Property(r => r.Status).HasConversion<string>().HasMaxLength(50);

        builder.Property(r => r.PendingProviderOrderId)
            .HasMaxLength(255);

        builder.Property(r => r.PendingPaymentMethod)
            .HasConversion<string>()
            .HasMaxLength(50);

        builder.Property(r => r.PendingPaymentCreatedAt);

        builder.HasOne(r => r.EventTicket)
            .WithMany(t => t.Reservations)
            .HasForeignKey(r => r.EventTicketId)
            .OnDelete(DeleteBehavior.SetNull);

        builder.HasMany(r => r.Tickets)
            .WithOne(t => t.Reservation)
            .HasForeignKey(t => t.ReservationId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(r => r.UserId);
        builder.HasIndex(r => r.EventId);
        builder.HasIndex(r => r.EventTicketId);
        builder.HasIndex(r => new { r.Status, r.ExpiresAt });
        builder.HasIndex(r => r.ExpiresAt);
        builder.HasIndex(r => r.ReservedAt);
        builder.HasIndex(r => r.PendingProviderOrderId);
        builder.Property(r => r.RefundRequestStatus)
    .HasConversion<string>()
    .HasMaxLength(50);

        builder.Property(r => r.RefundReason)
            .HasMaxLength(1000);

        builder.Property(r => r.RefundRequestedAt);

        builder.Property(r => r.RefundReviewedAt);

        builder.Property(r => r.RefundReviewedByUserId);

        builder.Property(r => r.RefundDecisionReason)
            .HasMaxLength(1000);

        builder.HasIndex(r => r.RefundRequestStatus);
    }
}