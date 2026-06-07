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
    int Capacity,
    DateTime StartDateTime,
    DateTime EndDateTime,
    DateTime PublishedAt
);
