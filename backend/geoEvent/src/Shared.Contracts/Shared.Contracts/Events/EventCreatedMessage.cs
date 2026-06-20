namespace Shared.Contracts.Events;

public record EventCreatedMessage(
    int EventId,
    string Title,
    int? OrganizerId,
    int? SegmentId,
    int? GenreId,
    int? SubGenreId,
    decimal Latitude,
    decimal Longitude,
    decimal Price,
    bool IsFree,
    int Capacity,
    bool IsOnline,
    DateTime StartDateTime,
    DateTime EndDateTime,
    DateTime PublishedAt
);