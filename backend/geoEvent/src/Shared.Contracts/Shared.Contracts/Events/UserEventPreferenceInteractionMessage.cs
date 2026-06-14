namespace Shared.Contracts.Events;

public record UserEventPreferenceInteractionMessage(
    Guid InteractionId,
    int UserId,
    int EventId,
    int? SegmentId,
    int? GenreId,
    int? SubGenreId,
    string InteractionType,
    DateTime OccurredAt);