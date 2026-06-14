namespace Shared.Contracts.Events;

public record EventLikedMessage(
    int EventId,
    string EventTitle,
    string? EventImageUrl,
    int EventOwnerUserId,
    int LikedByUserId,
    string LikedByDisplayName,
    string? LikedByAvatarUrl,
    DateTime OccurredAt
);