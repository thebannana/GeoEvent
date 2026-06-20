using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using TicketService.Domain.Entities;

namespace TicketService.Infrastructure.Persistence.Configurations;

public class PaymentDetailConfiguration : IEntityTypeConfiguration<PaymentDetail>
{
    public void Configure(EntityTypeBuilder<PaymentDetail> builder)
    {
        builder.HasKey(p => p.PaymentId);

        builder.Property(p => p.Status)
            .HasConversion<string>()
            .HasMaxLength(50)
            .IsRequired();

        builder.Property(p => p.Method)
            .HasConversion<string>()
            .HasMaxLength(50)
            .IsRequired();

        builder.Property(p => p.Amount).HasPrecision(18, 2);
        builder.Property(p => p.TransactionId).HasMaxLength(255);
        builder.Property(p => p.Currency).HasMaxLength(3).HasDefaultValue("BAM");

        builder.HasOne(p => p.Reservation)
            .WithMany(r => r.PaymentDetails)
            .HasForeignKey(p => p.ReservationId)
            .OnDelete(DeleteBehavior.SetNull);

        builder.HasIndex(p => p.PaidAt);
        builder.HasIndex(p => p.ReservationId);
        builder.HasIndex(p => p.UserId);
        builder.HasIndex(p => p.Status);
        builder.HasIndex(p => p.TransactionId).IsUnique().HasFilter("[TransactionId] IS NOT NULL");
    }
}
