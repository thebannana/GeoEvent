using geoEvent.Model.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace geoEvent.Infrastructure.Persistence.Configurations
{
    public class TicketConfiguration : IEntityTypeConfiguration<Ticket>
    {
        public void Configure(EntityTypeBuilder<Ticket> builder)
        {
            builder.HasKey(t => t.TicketId);

            builder.HasOne(t => t.Event)
                   .WithMany(e => e.Tickets)
                   .HasForeignKey(t => t.EventId)
                   .OnDelete(DeleteBehavior.Cascade);

            builder.HasIndex(t => t.EventId);
            builder.HasIndex(t => t.IsActive);
            builder.HasIndex(t => new { t.EventId, t.IsActive });
            builder.HasIndex(t => new { t.SaleStartDate, t.SaleEndDate });

            builder.Property(t => t.TicketType).HasMaxLength(100).IsRequired();
            builder.Property(t => t.Price).HasColumnType("decimal(18,2)").IsRequired();
            builder.Property(t => t.TotalQuantity).HasDefaultValue(0);
            builder.Property(t => t.SoldQuantity).HasDefaultValue(0);
            builder.Property(t => t.IsActive).HasDefaultValue(true);
            builder.Property(t => t.Description).HasMaxLength(2000);

            builder.ToTable(t => t.HasCheckConstraint(
                "CK_Ticket_SoldQuantity",
                "[SoldQuantity] >= 0 AND ([TotalQuantity] = 0 OR [SoldQuantity] <= [TotalQuantity])"
            ));
        }
    }

}