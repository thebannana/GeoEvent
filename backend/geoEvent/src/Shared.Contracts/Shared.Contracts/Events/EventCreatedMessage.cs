namespace Shared.Contracts.Events;

public record EventCreatedMessage(
    int EventId,
    string Title,
    int? CityId,
    int? OrganizerId,
    int? SegmentId,
    int? GenreId,
    int? SubGenreId,
    int? VenueId,
    decimal Price,
    bool IsFree,
    DateTime StartDateTime,
    DateTime EndDateTime,
    DateTime PublishedAt
);
