namespace Shared.Contracts.Events;

public record EventCommentCreatedMessage(
    int EventId,
    string EventTitle,
    string? EventImageUrl,
    int EventOwnerUserId,
    int CommentId,
    int CommentAuthorUserId,
    string CommentAuthorDisplayName,
    string? CommentAuthorAvatarUrl,
    string CommentPreview,
    DateTime OccurredAt
);