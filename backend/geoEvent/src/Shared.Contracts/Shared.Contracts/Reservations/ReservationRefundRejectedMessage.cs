namespace Shared.Contracts.Reservations;
public sealed record ReservationRefundRejectedMessage(
    int ReservationId,
    int EventId,
    string EventTitle,
    string? EventImageUrl,
    int UserId,
    string? DecisionReason,
    DateTime RejectedAtUtc);
