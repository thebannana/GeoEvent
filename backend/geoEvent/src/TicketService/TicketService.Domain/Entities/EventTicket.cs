using TicketService.Domain.Enums;

namespace TicketService.Domain.Entities;

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

    // Domain logic
    public int AvailableQuantity => TotalQuantity - SoldQuantity;

    public bool IsAvailable() =>
        IsActive &&
        AvailableQuantity > 0 &&
        (SaleStartDate == null || DateTime.UtcNow >= SaleStartDate) &&
        (SaleEndDate == null || DateTime.UtcNow <= SaleEndDate);

    public bool IsOnSale() =>
        IsActive &&
        (SaleStartDate == null || DateTime.UtcNow >= SaleStartDate) &&
        (SaleEndDate == null || DateTime.UtcNow <= SaleEndDate);

    public void Reserve(int quantity)
    {
        if (quantity <= 0)
            throw new ArgumentException("Quantity must be greater than zero.");
        if (quantity > AvailableQuantity)
            throw new InvalidOperationException(
                $"Only {AvailableQuantity} tickets available.");
        SoldQuantity += quantity;
    }

    public void Release(int quantity)
    {
        if (quantity <= 0)
            throw new ArgumentException("Quantity must be greater than zero.");
        SoldQuantity = Math.Max(0, SoldQuantity - quantity);
    }
}
