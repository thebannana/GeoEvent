namespace Shared.Contracts.Events;

public record EventBookmarkedMessage(
    int EventId,
    string EventTitle,
    string? EventImageUrl,
    int EventOwnerUserId,
    int BookmarkedByUserId,
    string BookmarkedByDisplayName,
    string? BookmarkedByAvatarUrl,
    DateTime OccurredAt
);