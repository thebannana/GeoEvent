namespace Shared.Contracts.Tickets;

/// <summary>
/// Published when an attendee cancels their own reservation.
/// Carries everything needed to notify the event organizer (the other relevant party)
/// and to record who cancelled, when, and why.
/// </summary>
public record ReservationCancelledMessage(
    int ReservationId,
    int EventId,
    int UserId,
    DateTime CancelledAt,
    string? CancellationReason = null,
    int? OrganizerUserId = null,
    string? EventTitle = null,
    string? EventImageUrl = null,
    string? CancelledByDisplayName = null,
    string? CancelledByAvatarUrl = null,
    int Quantity = 0);