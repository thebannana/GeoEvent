namespace Shared.Contracts.Tickets;

public record EventReservationCashPendingMessage(
    int ReservationId,
    int EventId,
    string EventTitle,
    string? EventImageUrl,
    int OrganizerUserId,
    int AttendeeUserId,
    string AttendeeDisplayName,
    string? AttendeeAvatarUrl,
    int Quantity,
    decimal Amount,
    string Currency,
    string ReservationStatus,
    DateTime ConfirmedAt
);