namespace SeedGeneration.SeedGenerator.Configuration;

public class SeedTicketOptions
{
    public int ReservationId { get; set; }
    public int UserId { get; set; }
    public int EventId { get; set; }
    public string TicketType { get; set; } = "General";
    public string QrCode { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public string Currency { get; set; } = "BAM";
    public string Status { get; set; } = "Active";
    public DateTime? UsedAt { get; set; }
    public DateTime? CancelledAt { get; set; }
    public string? SeatNumber { get; set; }
    public string? Section { get; set; }
}