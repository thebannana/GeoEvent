using TicketService.Domain.Enums;

namespace TicketService.Domain.Entities;

public class Reservation
{
    public int ReservationId { get; set; }
    public DateTime ReservedAt { get; set; } = DateTime.UtcNow;
    public int EventId { get; set; }
    public int UserId { get; set; }
    public int? EventTicketId { get; set; }
    public int Quantity { get; set; }
    public decimal TotalAmount { get; set; }
    public string Currency { get; set; } = "BAM";
    public ReservationStatus Status { get; set; } = ReservationStatus.Pending;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? ConfirmedAt { get; set; }
    public DateTime? CancelledAt { get; set; }
    public DateTime? ExpiredAt { get; set; }
    public DateTime ExpiresAt { get; set; }
    public string? PaymentReference { get; set; }
    public string? Notes { get; set; }

    public EventTicket? EventTicket { get; set; }
    public ICollection<Ticket> Tickets { get; set; } = [];
    public ICollection<PaymentDetail> PaymentDetails { get; set; } = [];

    public bool IsExpired() =>
        Status == ReservationStatus.Pending && DateTime.UtcNow > ExpiresAt;

    public bool CanBeConfirmed() =>
        Status == ReservationStatus.Pending && !IsExpired();

    public bool CanBeCancelled() =>
        Status == ReservationStatus.Pending ||
        Status == ReservationStatus.Confirmed;


    public void Cancel()
    {
        if (!CanBeCancelled())
            throw new InvalidOperationException(
                "Reservation cannot be cancelled in its current state.");
        Status = ReservationStatus.Cancelled;
        CancelledAt = DateTime.UtcNow;
    }

    public void Confirm(string paymentReference)
    {
        if (!CanBeConfirmed())
            throw new InvalidOperationException("Reservation cannot be confirmed in its current state.");

        if (string.IsNullOrWhiteSpace(paymentReference))
            throw new ArgumentException("Payment reference is required.");

        Status = ReservationStatus.Confirmed;
        ConfirmedAt = DateTime.UtcNow;
        PaymentReference = paymentReference;
    }

    public void Expire()
    {
        if (Status != ReservationStatus.Pending)
            throw new InvalidOperationException("Only pending reservations can expire.");

        Status = ReservationStatus.Expired;
        ExpiredAt = DateTime.UtcNow;
    }

    public void Refund()
    {
        if (Status != ReservationStatus.Confirmed)
            throw new InvalidOperationException("Only confirmed reservations can be refunded.");

        Status = ReservationStatus.Refunded;
    }
}
