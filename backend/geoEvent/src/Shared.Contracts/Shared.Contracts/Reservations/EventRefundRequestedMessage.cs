namespace Shared.Contracts.Reservations;

public sealed record EventRefundRequestedMessage(
    int ReservationId,
    int EventId,
    string EventTitle,
    string? EventImageUrl,
    int OrganizerUserId,
    int RequestedByUserId,
    string RequestedByDisplayName,
    string? RequestedByAvatarUrl,
    int Quantity,
    decimal TotalAmount,
    string Currency,
    string? RefundReason,
    DateTime RequestedAtUtc);