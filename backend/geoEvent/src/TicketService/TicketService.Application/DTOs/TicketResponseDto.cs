namespace TicketService.Application.DTOs;

public class TicketResponseDto
{
    public int TicketId { get; set; }
    public int ReservationId { get; set; }
    public int UserId { get; set; }
    public int EventId { get; set; }
    public string TicketType { get; set; } = string.Empty;
    public string QrCode { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public string Currency { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public DateTime IssuedAt { get; set; }
    public DateTime? UsedAt { get; set; }
    public string? SeatNumber { get; set; }
    public string? Section { get; set; }
}
