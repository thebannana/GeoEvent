namespace Shared.Contracts.Events;

public record EventUpdatedMessage(
    int EventId,
    string Title,
    int? OrganizerId,
    DateTime StartDateTime,
    DateTime EndDateTime,
    string? ChangeSummary,
    DateTime UpdatedAt
);
