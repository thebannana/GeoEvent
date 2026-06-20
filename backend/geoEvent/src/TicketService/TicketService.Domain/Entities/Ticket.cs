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
    public DateTime IssuedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UsedAt { get; set; }
    public DateTime? CancelledAt { get; set; }
    public string? SeatNumber { get; set; }
    public string? Section { get; set; }

    public Reservation? Reservation { get; set; }

    public bool IsValid() =>
        Status == TicketStatus.Active;

    public bool CanBeUsed() =>
        Status == TicketStatus.Active;

    public bool CanBeCancelled() =>
        Status == TicketStatus.Active;

    public void MarkAsUsed()
    {
        if (!CanBeUsed())
            throw new InvalidOperationException("Ticket cannot be used in its current state.");
        Status = TicketStatus.Used;
        UsedAt = DateTime.UtcNow;
    }

    public void Cancel()
    {
        if (!CanBeCancelled())
            throw new InvalidOperationException("Ticket cannot be cancelled in its current state.");
        Status = TicketStatus.Cancelled;
        CancelledAt = DateTime.UtcNow;
    }

    public void Expire()
    {
        Status = TicketStatus.Expired;
    }

    public void Refund()
    {
        Status = TicketStatus.Refunded;
    }
}
