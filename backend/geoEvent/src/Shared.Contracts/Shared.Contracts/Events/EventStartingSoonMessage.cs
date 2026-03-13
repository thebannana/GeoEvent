namespace Shared.Contracts.Events;

public record EventStartingSoonMessage(
    int EventId,
    string Title,
    DateTime StartDateTime,
    int? VenueId,
    string? VenueName
);
