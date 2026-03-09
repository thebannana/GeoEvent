using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using TicketService.Domain.Entities;

namespace TicketService.Infrastructure.Persistence.Configurations;

public class EventTicketConfiguration : IEntityTypeConfiguration<EventTicket>
{
    public void Configure(EntityTypeBuilder<EventTicket> builder)
    {
        builder.ToTable("Tickets", tb => tb.HasCheckConstraint(
            "CK_Tickets_SoldQuantity",
            "[SoldQuantity] >= 0 AND ([TotalQuantity] = 0 OR [SoldQuantity] <= [TotalQuantity])"));

        builder.HasKey(t => t.TicketId);

        builder.Property(t => t.TicketType).HasMaxLength(100).IsRequired();
        builder.Property(t => t.Price).HasPrecision(18, 2);
        builder.Property(t => t.Description).HasMaxLength(2000);

        builder.HasIndex(t => t.EventId);
        builder.HasIndex(t => new { t.EventId, t.IsActive });
        builder.HasIndex(t => t.IsActive);
        builder.HasIndex(t => new { t.SaleStartDate, t.SaleEndDate });
    }
}
