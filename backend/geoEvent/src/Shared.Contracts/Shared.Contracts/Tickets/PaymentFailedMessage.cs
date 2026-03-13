namespace Shared.Contracts.Tickets;

public record PaymentFailedMessage(
    int ReservationId,
    int UserId,
    decimal Amount,
    string Currency,
    string FailureReason,
    DateTime FailedAt
);
