namespace Shared.Contracts.Reservations;

public record EventReservationCreatedMessage(
    int ReservationId,
    int EventId,
    string EventTitle,
    string? EventImageUrl,
    int OrganizerUserId,
    int ReservedByUserId,
    string ReservedByDisplayName,
    string? ReservedByAvatarUrl,
    int Quantity,
    decimal TotalAmount,
    string Currency,
    string Status,
    DateTime ReservedAt
);