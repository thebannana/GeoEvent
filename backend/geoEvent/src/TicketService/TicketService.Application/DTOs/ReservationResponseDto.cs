namespace TicketService.Application.DTOs;

public class ReservationResponseDto
{
    public int ReservationId { get; set; }
    public int UserId { get; set; }
    public int EventId { get; set; }
    public int Quantity { get; set; }
    public decimal TotalAmount { get; set; }
    public string Currency { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public DateTime? ConfirmedAt { get; set; }
    public DateTime ExpiresAt { get; set; }
    public string? PaymentReference { get; set; }
    public string? Notes { get; set; }
    public List<TicketResponseDto> Tickets { get; set; } = [];
}
