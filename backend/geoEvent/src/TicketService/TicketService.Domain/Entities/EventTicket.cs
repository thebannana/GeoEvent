namespace TicketService.Domain.Entities;

/// <summary>
/// Ticket type / inventory for an event (monolith "Tickets" table).
/// </summary>
public class EventTicket
{
    public int TicketId { get; set; }
    public int EventId { get; set; }
    public string TicketType { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public int TotalQuantity { get; set; }
    public int SoldQuantity { get; set; }
    public DateTime? SaleStartDate { get; set; }
    public DateTime? SaleEndDate { get; set; }
    public bool IsActive { get; set; } = true;
    public string? Description { get; set; }
    public int? PriceZoneId { get; set; }

    // Navigation
    public ICollection<Reservation> Reservations { get; set; } = [];
}
