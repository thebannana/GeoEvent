namespace MessageService.Domain.Entities;

public class ChatMessageLike
{
    public long MessageId { get; private set; }
    public int UserId { get; private set; }
    public DateTime LikedAt { get; private set; } = DateTime.UtcNow;

    public ChatMessage Message { get; private set; } = default!;

    private ChatMessageLike() { }

    public ChatMessageLike(long messageId, int userId)
    {
        if (messageId <= 0)
            throw new InvalidOperationException("Message ID must be greater than zero.");

        if (userId <= 0)
            throw new InvalidOperationException("User ID must be greater than zero.");

        MessageId = messageId;
        UserId = userId;
        LikedAt = DateTime.UtcNow;
    }
}