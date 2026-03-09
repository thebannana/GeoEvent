namespace Shared.Contracts.Events;

public record EventCancelledMessage(
    int EventId,
    string Title,
    int? OrganizerId,
    DateTime CancelledAt,
    string Reason
);
