using TicketService.Domain.Enums;

public class CompleteCheckoutDto
{
    public int EventId { get; set; }
    public int EventTicketId { get; set; }
    public int Quantity { get; set; }
    public string Currency { get; set; } = "BAM";
    public string PaymentReference { get; set; } = string.Empty;
    public PaymentMethod PaymentMethod { get; set; }
    public decimal Amount { get; set; }
}