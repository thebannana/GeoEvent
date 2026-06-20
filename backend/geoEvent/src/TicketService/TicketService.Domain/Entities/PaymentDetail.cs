using TicketService.Domain.Enums;

namespace TicketService.Domain.Entities;

public class PaymentDetail
{
    public int PaymentId { get; set; }
    public DateTime? PaidAt { get; set; }
    public int? ReservationId { get; set; }
    public int? UserId { get; set; }
    public PaymentStatus Status { get; set; } = PaymentStatus.Pending;
    public PaymentMethod Method { get; set; }
    public decimal Amount { get; set; }
    public string Currency { get; set; } = "BAM";

    public string? ProviderPaymentId { get; set; }
    public string? ProviderOrderId { get; set; }
    public string? TransactionId { get; set; }
    public string? RefundTransactionId { get; set; }

    public Reservation? Reservation { get; set; }

    public bool IsSuccessful() => Status == PaymentStatus.Completed;

    public void Complete(string providerPaymentId, string transactionId)
    {
        if (Status != PaymentStatus.Pending)
            throw new InvalidOperationException("Only pending payments can be completed.");

        if (string.IsNullOrWhiteSpace(providerPaymentId))
            throw new ArgumentException("Provider payment ID is required.");

        if (string.IsNullOrWhiteSpace(transactionId))
            throw new ArgumentException("Transaction ID is required.");

        ProviderPaymentId = providerPaymentId;
        TransactionId = transactionId;
        Status = PaymentStatus.Completed;
        PaidAt = DateTime.UtcNow;
    }

    public void Fail()
    {
        if (Status != PaymentStatus.Pending)
            throw new InvalidOperationException("Only pending payments can fail.");

        Status = PaymentStatus.Failed;
    }

    public void Refund(string refundTransactionId)
    {
        if (Status != PaymentStatus.Completed)
            throw new InvalidOperationException("Only completed payments can be refunded.");

        if (string.IsNullOrWhiteSpace(refundTransactionId))
            throw new ArgumentException("Refund transaction ID is required.");

        RefundTransactionId = refundTransactionId;
        Status = PaymentStatus.Refunded;
    }
}