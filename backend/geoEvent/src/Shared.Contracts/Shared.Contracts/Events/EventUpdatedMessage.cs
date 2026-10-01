namespace Shared.Contracts.Events;

public record EventUpdatedMessage(
    int EventId,
    string Title,
    int? OrganizerId,
    DateTime StartDateTime,
    DateTime EndDateTime,
    int Capacity,
    decimal Price,
    string? ChangeSummary,
    DateTime UpdatedAt
);
