using geoEvent.Model.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace geoEvent.Infrastructure.Persistence.Configurations
{
    public class PaymentDetailConfiguration : IEntityTypeConfiguration<PaymentDetail>
    {
        public void Configure(EntityTypeBuilder<PaymentDetail> builder)
        {
                builder.HasOne(p => p.User)
                       .WithMany()
                       .HasForeignKey(p => p.UserId)
                       .OnDelete(DeleteBehavior.Restrict);

                builder.HasOne(p => p.Reservation)
                       .WithMany()
                       .HasForeignKey(p => p.ReservationId)
                       .OnDelete(DeleteBehavior.Restrict);

                builder.Property(e => e.Amount).HasColumnType("decimal(18,2)");
        }
    }
}