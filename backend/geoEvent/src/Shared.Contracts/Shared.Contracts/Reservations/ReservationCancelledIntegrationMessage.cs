namespace Shared.Contracts.Reservations;

public record ReservationCancelledIntegrationMessage(
    int ReservationId,
    int EventId,
    int UserId,
    DateTime CancelledAt
);