namespace SeedGeneration.SeedGenerator.Configuration;

public class SeedPaymentDetailOptions
{
    public int ReservationId { get; set; }
    public int UserId { get; set; }
    public string Method { get; set; } = "Cash";
    public decimal Amount { get; set; }
    public string Currency { get; set; } = "BAM";
    public string Status { get; set; } = "Completed";
    public DateTime? PaidAt { get; set; }
    public string? ProviderPaymentId { get; set; }
    public string? ProviderOrderId { get; set; }
    public string? TransactionId { get; set; }
    public string? RefundTransactionId { get; set; }
}