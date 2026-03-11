namespace TicketService.Application.DTOs;

public class EventTicketResponseDto
{
    public int TicketId { get; set; }
    public int EventId { get; set; }
    public string TicketType { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public int TotalQuantity { get; set; }
    public int SoldQuantity { get; set; }
    public int AvailableQuantity { get; set; }
    public bool IsAvailable { get; set; }
    public DateTime? SaleStartDate { get; set; }
    public DateTime? SaleEndDate { get; set; }
    public bool IsActive { get; set; }
    public string? Description { get; set; }
    public int? PriceZoneId { get; set; }
}
