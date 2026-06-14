namespace Shared.Contracts.Events;

public record EventCommentLikedMessage(
    int EventId,
    string EventTitle,
    string? EventImageUrl,
    int CommentId,
    int CommentOwnerUserId,
    int LikedByUserId,
    string LikedByDisplayName,
    string? LikedByAvatarUrl,
    string CommentPreview,
    DateTime OccurredAt
);