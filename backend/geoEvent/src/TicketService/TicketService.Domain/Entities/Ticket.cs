using TicketService.Domain.Enums;
using TicketService.Domain.Exceptions;

namespace TicketService.Domain.Entities;

public class Ticket
{
    public int TicketId { get; private set; }
    public int ReservationId { get; private set; }
    public int UserId { get; private set; }
    public int EventId { get; private set; }
    public string TicketType { get; private set; } = "General";
    public string QrCode { get; private set; } = string.Empty;
    public decimal Amount { get; private set; }
    public string Currency { get; private set; } = "BAM";
    public TicketStatus Status { get; private set; } = TicketStatus.Active;
    public DateTime IssuedAt { get; private set; }
    public DateTime? UsedAt { get; private set; }
    public DateTime? CancelledAt { get; private set; }
    public string? SeatNumber { get; private set; }
    public string? Section { get; private set; }

    public Reservation? Reservation { get; set; }

    private Ticket()
    {
    }

    public static Ticket Issue(
        int reservationId,
        int userId,
        int eventId,
        string ticketType,
        string qrCode,
        decimal amount,
        string currency,
        string? seatNumber = null,
        string? section = null)
    {
        if (reservationId <= 0)
            throw new BusinessException("Reservation ID is required.");

        if (userId <= 0)
            throw new BusinessException("User ID is required.");

        if (eventId <= 0)
            throw new BusinessException("Event ID is required.");

        if (string.IsNullOrWhiteSpace(ticketType))
            throw new BusinessException("Ticket type is required.");

        if (string.IsNullOrWhiteSpace(qrCode))
            throw new BusinessException("QR code is required.");

        if (amount < 0)
            throw new BusinessException("Amount cannot be negative.");

        if (string.IsNullOrWhiteSpace(currency))
            throw new BusinessException("Currency is required.");

        return new Ticket
        {
            ReservationId = reservationId,
            UserId = userId,
            EventId = eventId,
            TicketType = ticketType.Trim(),
            QrCode = qrCode.Trim(),
            Amount = amount,
            Currency = currency.Trim().ToUpperInvariant(),
            Status = TicketStatus.Active,
            IssuedAt = DateTime.UtcNow,
            SeatNumber = string.IsNullOrWhiteSpace(seatNumber) ? null : seatNumber.Trim(),
            Section = string.IsNullOrWhiteSpace(section) ? null : section.Trim()
        };
    }

    public bool IsValid() => Status == TicketStatus.Active;
    public bool CanBeUsed() => Status == TicketStatus.Active;
    public bool CanBeCancelled() => Status == TicketStatus.Active;

    public void MarkAsUsed()
    {
        if (!CanBeUsed())
            throw new BusinessException("Ticket cannot be used in its current state.");

        Status = TicketStatus.Used;
        UsedAt = DateTime.UtcNow;
    }

    public void Cancel()
    {
        if (!CanBeCancelled())
            throw new BusinessException("Ticket cannot be cancelled in its current state.");

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