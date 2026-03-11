namespace TicketService.Application.DTOs;

public class PaymentDetailResponseDto
{
    public int PaymentId { get; set; }
    public int? ReservationId { get; set; }
    public int? UserId { get; set; }
    public string Status { get; set; } = string.Empty;
    public string Method { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public string Currency { get; set; } = string.Empty;
    public string? TransactionId { get; set; }
    public DateTime PaidAt { get; set; }
}
