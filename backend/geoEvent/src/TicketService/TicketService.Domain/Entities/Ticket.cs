using TicketService.Domain.Enums;

namespace TicketService.Domain.Entities;

public class Ticket
{
    public int TicketId { get; set; }
    public int ReservationId { get; set; }
    public int UserId { get; set; }
    public int EventId { get; set; }
    public string TicketType { get; set; } = "General";
    public string QrCode { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public string Currency { get; set; } = "BAM";
    public TicketStatus Status { get; set; } = TicketStatus.Active;
    public DateTime IssuedAt { get; set; }
    public DateTime? UsedAt { get; set; }
    public DateTime? CancelledAt { get; set; }
    public string? SeatNumber { get; set; }
    public string? Section { get; set; }

    // Navigation
    public Reservation? Reservation { get; set; }

    // Domain logic
    public bool IsValid() => Status == TicketStatus.Active;

    public void MarkAsUsed()
    {
        Status = TicketStatus.Used;
        UsedAt = DateTime.UtcNow;
    }

    public void Cancel()
    {
        Status = TicketStatus.Cancelled;
        CancelledAt = DateTime.UtcNow;
    }
}
