namespace Shared.Contracts.Events;

public record EventCommentReplyCreatedMessage(
    int EventId,
    string EventTitle,
    string? EventImageUrl,
    int ParentCommentId,
    int ParentCommentOwnerUserId,
    int ReplyCommentId,
    int ReplyAuthorUserId,
    string ReplyAuthorDisplayName,
    string? ReplyAuthorAvatarUrl,
    string ReplyPreview,
    DateTime OccurredAt
);