namespace MessageService.Domain.Entities;

public class ChatMessage
{
    public long Id { get; private set; }
    public long ThreadId { get; private set; }
    public int SenderId { get; private set; }
    public string Content { get; private set; } = string.Empty;
    public DateTime SentAt { get; private set; } = DateTime.UtcNow;
    public DateTime? EditedAt { get; private set; }
    public DateTime? DeletedAt { get; private set; }
    public long? ReplyToMessageId { get; private set; }
    public int LikesCount { get; private set; }

    public ChatThread Thread { get; private set; } = default!;
    public ChatMessage? ReplyToMessage { get; private set; }
    public ICollection<ChatMessage> Replies { get; private set; } = new List<ChatMessage>();
    public ICollection<ChatMessageLike> Likes { get; private set; } = new List<ChatMessageLike>();

    public bool IsDeleted => DeletedAt.HasValue;

    private ChatMessage() { }

    public ChatMessage(long threadId, int senderId, string content, long? replyToMessageId = null)
    {
        if (threadId <= 0)
            throw new InvalidOperationException("Thread ID must be greater than zero.");

        if (senderId <= 0)
            throw new InvalidOperationException("Sender ID must be greater than zero.");

        ThreadId = threadId;
        SenderId = senderId;
        ReplyToMessageId = replyToMessageId;
        Content = NormalizeContent(content);
        SentAt = DateTime.UtcNow;
    }

    public bool CanEdit(int userId) => SenderId == userId && !IsDeleted;
    public bool CanDelete(int userId) => SenderId == userId && !IsDeleted;

    public void Edit(string content)
    {
        if (IsDeleted)
            throw new InvalidOperationException("Deleted messages cannot be edited.");

        Content = NormalizeContent(content);
        EditedAt = DateTime.UtcNow;
    }

    public void SoftDelete()
    {
        if (IsDeleted)
            return;

        DeletedAt = DateTime.UtcNow;
        Content = "[message deleted]";
    }

    public void IncrementLikes()
    {
        LikesCount++;
    }

    public void DecrementLikes()
    {
        if (LikesCount > 0)
            LikesCount--;
    }

    private static string NormalizeContent(string content)
    {
        var trimmed = (content ?? string.Empty).Trim();

        if (string.IsNullOrWhiteSpace(trimmed))
            throw new InvalidOperationException("Message content cannot be empty.");

        if (trimmed.Length > 4000)
            throw new InvalidOperationException("Message content cannot exceed 4000 characters.");

        return trimmed;
    }
}