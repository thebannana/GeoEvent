using TicketService.Domain.Exceptions;

namespace TicketService.Domain.Entities;

public class EventTicket
{
    public int TicketId { get; set; }
    public int EventId { get; private set; }
    public string TicketType { get; private set; } = string.Empty;
    public decimal Price { get; private set; }
    public int TotalQuantity { get; private set; }
    public int SoldQuantity { get; private set; }
    public DateTime? SaleStartDate { get; private set; }
    public DateTime? SaleEndDate { get; private set; }
    public bool IsActive { get; private set; } = true;
    public string? Description { get; private set; }
    public int? PriceZoneId { get; private set; }

    public ICollection<Reservation> Reservations { get; set; } = [];

    public int AvailableQuantity => Math.Max(0, TotalQuantity - SoldQuantity);

    private EventTicket()
    {
    }

    public EventTicket(
        int eventId,
        string ticketType,
        decimal price,
        int totalQuantity,
        DateTime? saleStartDate,
        DateTime? saleEndDate,
        string? description = null,
        int? priceZoneId = null)
    {
        if (eventId <= 0)
            throw new BusinessException("Event ID must be valid.");

        if (string.IsNullOrWhiteSpace(ticketType))
            throw new BusinessException("Ticket type is required.");

        if (price < 0)
            throw new BusinessException("Price cannot be negative.");

        if (totalQuantity < 0)
            throw new BusinessException("Total quantity cannot be negative.");

        if (saleStartDate.HasValue && saleEndDate.HasValue && saleEndDate < saleStartDate)
            throw new BusinessException("Sale end date cannot be before sale start date.");

        EventId = eventId;
        TicketType = ticketType.Trim();
        Price = price;
        TotalQuantity = totalQuantity;
        SaleStartDate = saleStartDate;
        SaleEndDate = saleEndDate;
        Description = string.IsNullOrWhiteSpace(description) ? null : description.Trim();
        PriceZoneId = priceZoneId;
    }

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
            throw new BusinessException("Quantity must be greater than zero.");

        if (!IsAvailable())
            throw new BusinessException("Ticket is not currently available for sale.");

        if (quantity > AvailableQuantity)
            throw new BusinessException($"Only {AvailableQuantity} tickets available.");

        SoldQuantity += quantity;
    }

    public void Release(int quantity)
    {
        if (quantity <= 0)
            throw new BusinessException("Quantity must be greater than zero.");

        SoldQuantity = Math.Max(0, SoldQuantity - quantity);
    }

    public void UpdateDetails(
        string ticketType,
        decimal price,
        int totalQuantity,
        DateTime? saleStartDate,
        DateTime? saleEndDate,
        string? description,
        int? priceZoneId,
        bool isActive)
    {
        if (string.IsNullOrWhiteSpace(ticketType))
            throw new BusinessException("Ticket type is required.");

        if (price < 0)
            throw new BusinessException("Price cannot be negative.");

        if (totalQuantity < SoldQuantity)
            throw new BusinessException("Total quantity cannot be lower than sold quantity.");

        if (saleStartDate.HasValue && saleEndDate.HasValue && saleEndDate < saleStartDate)
            throw new BusinessException("Sale end date cannot be before sale start date.");

        TicketType = ticketType.Trim();
        Price = price;
        TotalQuantity = totalQuantity;
        SaleStartDate = saleStartDate;
        SaleEndDate = saleEndDate;
        Description = string.IsNullOrWhiteSpace(description) ? null : description.Trim();
        PriceZoneId = priceZoneId;
        IsActive = isActive;
    }

    public void Activate() => IsActive = true;

    public void Deactivate() => IsActive = false;
}