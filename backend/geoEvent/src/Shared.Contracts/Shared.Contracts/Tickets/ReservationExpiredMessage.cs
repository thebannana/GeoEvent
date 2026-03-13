namespace Shared.Contracts.Tickets;

public record ReservationExpiredMessage(
    int ReservationId,
    int EventId,
    int UserId,
    DateTime ExpiredAt
);
