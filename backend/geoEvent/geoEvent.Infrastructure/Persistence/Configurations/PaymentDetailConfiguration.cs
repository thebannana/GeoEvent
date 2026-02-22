using geoEvent.Model.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace geoEvent.Infrastructure.Persistence.Configurations
{
    public class PaymentDetailConfiguration : IEntityTypeConfiguration<PaymentDetail>
    {
        public void Configure(EntityTypeBuilder<PaymentDetail> builder)
        {
            builder.HasKey(p => p.PaymentId);

            builder.HasOne(p => p.Reservation)
                   .WithMany()
                   .HasForeignKey(p => p.ReservationId)
                   .OnDelete(DeleteBehavior.NoAction);

            builder.HasOne(p => p.User)
                   .WithMany()
                   .HasForeignKey(p => p.UserId)
                   .OnDelete(DeleteBehavior.NoAction);

            builder.HasIndex(p => p.ReservationId);
            builder.HasIndex(p => p.UserId);
            builder.HasIndex(p => p.PaidAt);
            builder.HasIndex(p => p.Status);

            builder.Property(p => p.Status).HasMaxLength(50).IsRequired();
            builder.Property(p => p.Method).HasMaxLength(50).IsRequired();
            builder.Property(e => e.Amount).HasColumnType("decimal(18,2)");
        }
    }
}