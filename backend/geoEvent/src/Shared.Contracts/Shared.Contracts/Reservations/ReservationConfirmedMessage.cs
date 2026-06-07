namespace Shared.Contracts.Reservations;

public record ReservationConfirmedMessage(
    int ReservationId,
    int EventId,
    int UserId,
    int Quantity,
    DateTime ConfirmedAt
);