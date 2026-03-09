namespace Shared.Contracts.Events;

public record EventCreatedMessage(
    int EventId,
    string Title,
    int? CityId,
    int? OrganizerId,
    int? SegmentId,
    int? GenreId,
    decimal Price,
    DateTime StartDateTime,
    DateTime PublishedAt
);
