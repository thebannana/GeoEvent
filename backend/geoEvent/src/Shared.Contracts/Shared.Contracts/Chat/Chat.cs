namespace Shared.Contracts.Chat;

public sealed record ChatMessageSentIntegrationEvent
{
    public Guid IntegrationEventId { get; init; } = Guid.NewGuid();
    public DateTime OccurredAtUtc { get; init; } = DateTime.UtcNow;
    public long ThreadId { get; init; }
    public string ThreadTitle { get; init; } = string.Empty;
    public string? ThreadImageUrl { get; init; }
    public int SenderUserId { get; init; }
    public string SenderDisplayName { get; init; } = string.Empty;
    public string? SenderAvatarUrl { get; init; }
    public IReadOnlyCollection<int> RecipientUserIds { get; init; } = Array.Empty<int>();
    public bool IsGroupThread { get; init; }
    public string MessagePreview { get; init; } = string.Empty;
}

public sealed record ChatMessageLikedIntegrationEvent
{
    public Guid IntegrationEventId { get; init; } = Guid.NewGuid();
    public DateTime OccurredAtUtc { get; init; } = DateTime.UtcNow;
    public long ThreadId { get; init; }
    public string ThreadTitle { get; init; } = string.Empty;
    public string? ThreadImageUrl { get; init; }
    public long MessageId { get; init; }
    public int MessageOwnerUserId { get; init; }
    public int LikedByUserId { get; init; }
    public string LikedByDisplayName { get; init; } = string.Empty;
    public string? LikedByAvatarUrl { get; init; }
    public string MessagePreview { get; init; } = string.Empty;
}

public sealed record ChatUserAddedToGroupIntegrationEvent
{
    public Guid IntegrationEventId { get; init; } = Guid.NewGuid();
    public DateTime OccurredAtUtc { get; init; } = DateTime.UtcNow;
    public long ThreadId { get; init; }
    public int AddedUserId { get; init; }
    public int? AddedByUserId { get; init; }
    public string AddedByDisplayName { get; init; } = string.Empty;
    public string? AddedByAvatarUrl { get; init; }
    public int? RelatedEventId { get; init; }
    public string GroupTitle { get; init; } = string.Empty;
    public string? GroupImageUrl { get; init; }
}