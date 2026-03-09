using TicketService.Domain.Enums;

namespace TicketService.Domain.Entities;

public class Reservation
{
    public int ReservationId { get; set; }
    public DateTime ReservedAt { get; set; }
    public int EventId { get; set; }
    public int UserId { get; set; }
    public int? EventTicketId { get; set; }
    public int Quantity { get; set; }
    public decimal TotalAmount { get; set; }
    public string Currency { get; set; } = "BAM";
    public ReservationStatus Status { get; set; } = ReservationStatus.Pending;
    public DateTime CreatedAt { get; set; }
    public DateTime? ConfirmedAt { get; set; }
    public DateTime? CancelledAt { get; set; }
    public DateTime ExpiresAt { get; set; }
    public string? PaymentReference { get; set; }
    public string? Notes { get; set; }

    // Navigation
    public EventTicket? EventTicket { get; set; }
    public ICollection<Ticket> Tickets { get; set; } = [];
    public ICollection<PaymentDetail> PaymentDetails { get; set; } = [];

    // Domain logic
    public bool IsExpired() =>
        Status == ReservationStatus.Pending && DateTime.UtcNow > ExpiresAt;

    public void Confirm(string paymentReference)
    {
        Status = ReservationStatus.Confirmed;
        ConfirmedAt = DateTime.UtcNow;
        PaymentReference = paymentReference;
    }

    public void Cancel()
    {
        Status = ReservationStatus.Cancelled;
        CancelledAt = DateTime.UtcNow;
    }

    public void Expire()
    {
        Status = ReservationStatus.Expired;
    }
}
