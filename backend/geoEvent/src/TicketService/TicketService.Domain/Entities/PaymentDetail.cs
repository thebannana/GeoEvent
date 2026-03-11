using TicketService.Domain.Enums;

namespace TicketService.Domain.Entities;

public class PaymentDetail
{
    public int PaymentId { get; set; }
    public DateTime PaidAt { get; set; }
    public int? ReservationId { get; set; }
    public int? UserId { get; set; }
    public PaymentStatus Status { get; set; } = PaymentStatus.Pending;
    public PaymentMethod Method { get; set; }
    public decimal Amount { get; set; }
    public string? TransactionId { get; set; }
    public string Currency { get; set; } = "EUR";

    // Navigation
    public Reservation? Reservation { get; set; }

    // Domain logic
    public bool IsSuccessful() => Status == PaymentStatus.Completed;

    public void Complete(string transactionId)
    {
        Status = PaymentStatus.Completed;
        TransactionId = transactionId;
        PaidAt = DateTime.UtcNow;
    }

    public void Fail() => Status = PaymentStatus.Failed;

    public void Refund() => Status = PaymentStatus.Refunded;
}
