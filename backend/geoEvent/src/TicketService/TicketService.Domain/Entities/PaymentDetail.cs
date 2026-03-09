namespace TicketService.Domain.Entities;

public class PaymentDetail
{
    public int PaymentId { get; set; }
    public DateTime PaidAt { get; set; }
    public int? ReservationId { get; set; }
    public int? UserId { get; set; }
    public string Status { get; set; } = string.Empty;
    public string Method { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public string? TransactionId { get; set; }
    public string Currency { get; set; } = "EUR";

    // Navigation
    public Reservation? Reservation { get; set; }
}
