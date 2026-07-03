namespace Shared.Contracts.Reservations;
public sealed record ReservationRefundApprovedMessage(
    int ReservationId,
    int EventId,
    string EventTitle,
    string? EventImageUrl,
    int UserId,
    int Quantity,
    decimal RefundedAmount,
    string Currency,
    string? RefundTransactionId,
    string? DecisionReason,
    DateTime ApprovedAtUtc);
