namespace Shared.Contracts.Tickets;

public record ReservationCancelledMessage(
    int ReservationId,
    int EventId,
    int UserId,
    DateTime CancelledAt);