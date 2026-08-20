namespace SeedGeneration.SeedGenerator.Configuration;

public class SeedReservationOptions
{
    public int EventId { get; set; }
    public int UserId { get; set; }
    public int EventTicketId { get; set; }
    public int Quantity { get; set; } = 1;
    public decimal TotalAmount { get; set; }
    public string Currency { get; set; } = "BAM";
    public string Status { get; set; } = "Confirmed";
    public DateTime? ExpiresAt { get; set; }
    public DateTime? ConfirmedAt { get; set; }
    public DateTime? CancelledAt { get; set; }
    public string? PaymentReference { get; set; }
    public string? Notes { get; set; }
    public string? PendingProviderOrderId { get; set; }
    public string? PendingPaymentMethod { get; set; }
    public string? RefundReason { get; set; }
    public string? RefundRequestStatus { get; set; }
    public DateTime? RefundRequestedAt { get; set; }
    public DateTime? RefundReviewedAt { get; set; }
    public int? RefundReviewedByUserId { get; set; }
    public string? RefundDecisionReason { get; set; }
    public string? RefundModeratorAction { get; set; }
}