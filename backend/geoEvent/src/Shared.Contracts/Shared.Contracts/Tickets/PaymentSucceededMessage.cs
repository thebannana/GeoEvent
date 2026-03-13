namespace Shared.Contracts.Tickets;

public record PaymentSucceededMessage(
    int PaymentId,
    int ReservationId,
    int UserId,
    decimal Amount,
    string Currency,
    string TransactionId,
    DateTime PaidAt
);
