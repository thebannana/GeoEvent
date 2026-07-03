namespace Shared.Contracts.Reservations;
public sealed record ReservationRemovedByOrganizerMessage(
    int ReservationId,
    int EventId,
    string EventTitle,
    string? EventImageUrl,
    int UserId,
    int Quantity,
    DateTime RemovedAtUtc);
